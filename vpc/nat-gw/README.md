Build a VPC with a private subnet, route outbound traffic through a NAT Gateway, and enable secure connection via a Public Bastion Host.

# create vpc with a private and public subnet 
chmod +x create-vpc.sh
./create-vpc.sh

# Internet Gateway routing for public subnets
chmod +x igw.sh
./igw.sh

# create NAT Gateway and allocate EIP
# Route private subnet traffic through a NAT Gateway
chmod +x nat-gw.sh
./nat-gw.sh

# create security group for public EC2 and configure inbound rule for SSH 22
aws ec2 create-security-group \
--group-name MyBastion-SG \
--description "Security group for Public EC2 testing" \
--vpc-id vpc-07ddc50012f643f97 \
--tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=MyBastion-SG}]'


# create EC2 in public subnet with Auto-assign public IP / MyBastion-SG / key-pair
i-03937ca33318cee4a

# upload .pem file and connect to SSH
chmod 400 "my-aws-key.pem"
ssh -i "my-aws-key.pem" ec2-user@44.223.81.32

# Create private SG for private EC2 and configure inbound rule for SSH 22 & MyBastion-SG
aws ec2 create-security-group \
--group-name MyPrivate-ec2-sg \
--description "Security group for Private EC2" \
--vpc-id vpc-07ddc50012f643f97 \
--tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=MyPrivate-ec2-sg}]'

# create EC2 in private subnet with MyPrivate-ec2-sg / same key-pair with public EC2
i-01695169c7243b8e2
Private IPv4: 10.0.4.215

# Upload the .pem file to the public EC2
nano my-aws-key.pem

# Connect to the private EC2 via SSH from the bastion host
chmod 400 "my-aws-key.pem"
ssh -i "my-aws-key.pem" ec2-user@10.0.4.215

# Verify NAT Gateway outbound routing
curl -I https://www.google.com

**Expected Output:**
```text
HTTP/2 200
```
# Verify Private EC2 Isolation
ssh -i "my-aws-key.pem" ec2-user@10.0.4.215

6. 出網測試：在 Private EC2 執行 curl [https://www.google.com](https://www.google.com) 或 ping 外網，確認能成功出網。

7. 入網保護：嘗試從你的電腦直接連線 Private EC2，確認完全無法連入。 

