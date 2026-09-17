#!/bin/bash
set -e

# create two VPCs
VPCP1_ID=$(aws ec2 create-vpc \
    --cidr-block 10.1.0.0/16 \
    --tag-specifications ResourceType=vpc,Tags=[{Key=Name,Value=VPC-P1}] \
    --query 'Vpc.VpcId' \
    --output text)

VPCP2_ID=$(aws ec2 create-vpc \
    --cidr-block 10.2.0.0/16 \
    --tag-specifications ResourceType=vpc,Tags=[{Key=Name,Value=VPC-P2}] \
    --query 'Vpc.VpcId' \
    --output text)
echo "VPC1 created: $VPCP1_ID"
echo "VPC2 created: $VPCP2_ID"

# Create and attach internet gateway

IGW1_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications ResourceType=internet-gateway,Tags=[{Key=Name,Value=IGW_P1}] \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)

IGW2_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications ResourceType=internet-gateway,Tags=[{Key=Name,Value=IGW_P2}] \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)  

aws ec2 attach-internet-gateway \
    --internet-gateway-id $IGW1_ID \
    --vpc-id VPCP1_ID

aws ec2 attach-internet-gateway \
    --internet-gateway-id $IGW2_ID \
    --vpc-id VPCP2_ID

echo "IGW1 created & attached: $IGW1_ID"
echo "IGW2 created & attached: $IGW2_ID"

# Create public subnet in each vpc

PUB_SUB1_ID=$(aws ec2 create-subnet \
    --vpc-id $VPCP1_ID \
    --cidr-block 10.1.1.0/24 \
    --query 'Subnet.SubnetId' \
    --output text \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public-VPCP1}]')

PUB_SUB2_ID=$(aws ec2 create-subnet \
    --vpc-id $VPCP2_ID \
    --cidr-block 10.2.1.0/24 \
    --query 'Subnet.SubnetId' \
    --output text \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public-VPCP2}]')

#  All instances launched into this subnet are assigned a public IPv4 address

aws ec2 modify-subnet-attribute \
    --subnet-id PUB_SUB1_ID \
    --map-public-ip-on-launch

aws ec2 modify-subnet-attribute \
    --subnet-id PUB_SUB2_ID \
    --map-public-ip-on-launch

echo "Public subnet1 created: $PUB_SUB1_ID"
echo "Public subnet2 created: $PUB_SUB2_ID"

# Create public route table and associate with IGW

PUB_RT1_ID=$(aws ec2 create-route-table \
    --vpc-id $VPCP1_ID \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=My-Public-RouteTable_P1}]' \
    --query 'RouteTable.RouteTableId' \
    --output text)


PUB_RT2_ID=$(aws ec2 create-route-table \
    --vpc-id $VPCP2_ID \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=My-Public-RouteTable_P2}]' \
    --query 'RouteTable.RouteTableId' \
    --output text)

# Route public traffice to IGW
aws ec2 create-route \
    --route-table-id PUB_RT1_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id IGW1_ID > /dev/null

aws ec2 create-route \
    --route-table-id PUB_RT2_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id IGW2_ID > /dev/null

# Associate route table to public subnet

aws ec2 associate-route-table \
    --route-table-id PUB_RT1_ID \
    --subnet-id PUB_SUB1_ID > /dev/null

aws ec2 associate-route-table \
    --route-table-id PUB_RT2_ID \
    --subnet-id PUB_SUB2_ID > /dev/null

echo "Public Route Table created & associated with IGW routes"

# create private subnet in each vpc
PRIV_SUB1_ID=$(aws ec2 create-subnet \
    --vpc-id $VPCP1_ID \
    --cidr-block 10.1.2.0/24 \
    --query 'Subnet.SubnetId' \
    --output text \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private-VPCP1}]')

PRIV_SUB2_ID=$(aws ec2 create-subnet \
    --vpc-id $VPCP2_ID \
    --cidr-block 10.2.2.0/24 \
    --query 'Subnet.SubnetId' \
    --output text \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private-VPCP2}]')
echo "Private subnet1 created: $PRIV_SUB1_ID"
echo "Private subnet2 created: $PRIV_SUB2_ID"

# create and associate route table for private subnets

PRIV_RT1_ID=$(aws ec2 create-route-table \
    --vpc-id $VPCP1_ID \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=My-Private-RouteTable_P1}]' \
    --query 'RouteTable.RouteTableId' \
    --output text)

PRIV_RT2_ID=$(aws ec2 create-route-table \
    --vpc-id $VPCP2_ID \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=My-Private-RouteTable_P2}]' \
    --query 'RouteTable.RouteTableId' \
    --output text)

aws ec2 associate-route-table \
    --subnet-id $PRIV_SUB1_ID \
    --route-table-id $PRIV_RT1_ID > /dev/null

aws ec2 associate-route-table \
    --subnet-id $PRIV_SUB2_ID \
    --route-table-id $PRIV_RT2_ID > /dev/null

echo "Route table association completed"

# Establish VPC Peering

PEERING_ID=$(aws ec2 create-vpc-peering-connection \
    --vpc-id $VPCP1_ID \
    --peer-vpc-id $VPCP2_ID \
    --query 'VpcPeeringConnection.VpcPeeringConnectionId' \
    --output text)

aws ec2 accept-vpc-peering-connection \
    --vpc-peering-connection-id $PEERING_ID > /dev/null

echo "VPC Peering connection established: $PEERING_ID"

# Route VPC Peering with route tables

aws ec2 create-route \
    --route-table-id $PRIV_RT1_ID \
    --destination-cidr-block 10.2.0.0/16 \
    --vpc-peering-connection-id $PEERING_ID > /dev/null

aws ec2 create-route \
    --route-table-id $PRIV_RT2_ID \
    --destination-cidr-block 10.1.0.0/16 \
    --vpc-peering-connection-id $PEERING_ID > /dev/null

echo "Route VPC Peering & Route Table completed"
