#!/bin/bash

# create vpc (10.0.0.0/16)
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)
echo "VPC created: $VPC_ID"

# create public subnet (10.0.1.0/24)
PUB_SUB_ID=$(aws ec2 create-subnet \
--vpc-id $VPC_ID \
--cidr-block 10.0.1.0/24 \
--query 'Subnet.SubnetId' \
--output text \
--tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=my-Public-Subnet}]')
echo "Public subnet created: $PUB_SUB_ID"

# create private subnet (10.0.2.0/24)
PRIV_SUB_ID=$(aws ec2 create-subnet \
--vpc-id $VPC_ID \
--cidr-block 10.0.2.0/24 \
--query 'Subnet.SubnetId' \
--output text \
--tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=my-Private-Subnet}]')
echo "Private subnet created: $PRIV_SUB_ID"


echo "VPC_ID=$VPC_ID" > variables.txt
echo "PUB_SUB_ID=$PUB_SUB_ID" >> variables.txt
echo "PRIV_SUB_ID=$PRIV_SUB_ID" >> variables.txt