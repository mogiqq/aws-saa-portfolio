#!/bin/bash

# create NAT Gateway and allocate EIP
source variables.txt

# allocate EIP
EIP_ID=$(aws ec2 allocate-address \
--query 'AllocationId' \
--output text)
echo "EIP allocated: $EIP_ID"

# create nat gateway
NAT_GW_ID=$(aws ec2 create-nat-gateway \
--subnet-id $PUB_SUB_ID \
--allocation-id $EIP_ID \
--query 'NatGateway.NatGatewayId' \
--output text)
echo "NAT Gatway created: $NAT_GW_ID"

echo "Waiting for NAT Gateway to be available..."
aws ec2 wait nat-gateway-available \
    --nat-gateway-ids $NAT_GW_ID
echo "NAT Gateway is now ready!"

# Route private subnet traffic through a NAT Gateway

PRIV_RT_ID=$(aws ec2 create-route-table \
--vpc-id $VPC_ID \
--tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=My-Private-RouteTable}]' \
--query 'RouteTable.RouteTableId' \
--output text)
echo "Private route table created: $PRIV_RT_ID"

aws ec2 create-route \
--route-table-id $PRIV_RT_ID \
--destination-cidr-block 0.0.0.0/0 \
--nat-gateway-id $NAT_GW_ID

aws ec2 associate-route-table \
--route-table-id $PRIV_RT_ID \
--subnet-id $PRIV_SUB_ID
