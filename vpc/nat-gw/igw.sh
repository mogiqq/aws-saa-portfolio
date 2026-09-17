#!/bin/bash

source variables.txt

# create IGW 
IGW_ID=$(aws ec2 create-internet-gateway \
--query 'InternetGateway.InternetGatewayId' \
--output text \
--tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=my-igw-pub}]')

aws ec2 attach-internet-gateway \
    --internet-gateway-id $IGW_ID \
    --vpc-id $VPC_ID

echo "internet gateway attached to VPC: $IGW_ID"

MAIN_RT_ID=$(aws ec2 describe-route-tables \
--filters "Name=vpc-id, Values=$VPC_ID" "Name=association.main, Values=true" \
--query "RouteTables[0].RouteTableId" \
--output text)


aws ec2 create-route \
--route-table-id $MAIN_RT_ID \
--destination-cidr-block 0.0.0.0/0 \
--gateway-id $IGW_ID