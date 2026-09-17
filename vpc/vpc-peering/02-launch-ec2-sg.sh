#!/bin/bash
set -e

# Fetch created VPC and Subnet IDs

VPCP1_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name, Values=VPC-P1" --query 'Vpcs[0].VpcId' --output text)
VPCP2_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name, Values=VPC-P2" --query 'Vpcs[0].VpcId' --output text)

PUB_SUB1_ID=$(aws ec2 describe-subnets \
    --filters "Name=tag:Name,Values=Public-VPCP1" \
    --query "Subnets[0].SubnetId" \
    --output text)
PRIV_SUB2_ID=$(aws ec2 describe-subnets \
    --filters "Name=tag:Name,Values=Private-VPCP2" \
    --query "Subnets[0].SubnetId" \
    --output text)

# create security group in VPC-P1

SGP1_ID=$(aws ec2 create-security-group \
    --group-name SG-VPCP1-Test \
    --description "SG for VPCP1" \
    --vpc-id $VPCP1_ID \
    --tag-specifications 'ResourceType=security-group, Tags=[{Key=Name,Value=SG-VPCP1}]' \
    --query 'GroupId' \
    --output text)
    
# Allow external SSH (0.0.0.0/0) and all traffic from VPC-P2 (10.2.0.0/16)

aws ec2 authorize-security-group-ingress --group-id $SGP1_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 > /dev/null
aws ec2 authorize-security-group-ingress --group-id $SGP1_ID --protocol all --cidr 10.2.0.0/16 > /dev/null

# Create security group in VPC-P2

SGP2_ID=$(aws ec2 create-security-group \
    --group-name SG-VPCP2-Test \
    --description "SG for VPCP2" \
    --vpc-id $VPCP2_ID \
    --tag-specifications 'ResourceType=security-group, Tags=[{Key=Name,Value=SG-VPCP2}]' \
    --query 'GroupId' \
    --output text)

# Allow ICMP (Ping) and all internal protocols from VPC-P1 (10.1.0.0/16).
aws ec2 authorize-security-group-ingress --group-id $SGP2_ID --protocol icmp --port -1 --cidr 10.1.0.0/16 > /dev/null
aws ec2 authorize-security-group-ingress --group-id $SGP2_ID --protocol tcp --port 22 --cidr 10.1.0.0/16 > /dev/null

# Get the latest Amazon Linux 2023 AMI ID automatically 
AMI_ID=$(aws ssm get-parameters \
  --names /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-arm64 \
  --query "Parameters[0].Value" \
  --output text)

echo "Lastest AMI ID: $AMI_ID"

# Launch EC2 in VPC-P1's public subnet
EC2_VPCP1_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --subnet-id $PUB_SUB1_ID \
    --security-group-ids $SGP1_ID \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=PublicEC2-VPCP1}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

# Launch EC2 in VPC-P2's private subnet

EC2_VPCP2_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --subnet-id $PRIV_SUB2_ID \
    --security-group-ids $SGP2_ID \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=PrivateC2-VPCP2}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Waiting for EC2 to be running..."
aws ec2 wait instance-running --instance-ids $EC2_VPCP1_ID, $EC2_VPCP2_ID
echo "EC2 Launched: PublicEC2-VPCP1: $EC2_VPCP1_ID, PrivateC2-VPCP2: $EC2_VPCP2_ID"

# get IP of EC2
PUB_EC2_IP=$(aws ec2 describe-instances \
    --instance-ids $EC2_VPCP1_ID \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)
PRIV_EC2_IP=$(aws ec2 describe-instances \
    --instance-ids $EC2_VPCP2_ID \
    --query "Reservations[0].Instances[0].PrivateIpAddress" \
    --output text)

echo "EC2-VPCP1 (Public)  -> Public IP: $PUB_EC2_IP"
echo "EC2-VPCP2 (Private) -> Private IP: $PRIV_EC2_IP"

echo "1. SSH into the VPCP1 test server : ssh ec2-user@$PUB_EC2_IPP"
echo "2. Run a ping test from VPCP1 to verify internal connectivity: ping $PRIV_EC2_IP"

