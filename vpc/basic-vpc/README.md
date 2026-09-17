Built an isolated AWS VPC with a public subnet, configured route tables via IGW, and verified external connectivity using an EC2 instance

# create vpc
aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=MyVpc}]'

# create public subnet
aws ec2 create-subnet \
    --vpc-id vpc-0beadb5c29e2a37de \
    --cidr-block 10.0.0.0/24 \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=myPublicSubnet}]'

# create IGW 
aws ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=my-fun-igw}]'


# attach IGW
aws ec2 attach-internet-gateway \
    --internet-gateway-id igw-0c7ca728fdc7cfc9e \
    --vpc-id vpc-0beadb5c29e2a37de


# create route table for public
aws ec2 create-route-table \
    --vpc-id vpc-0beadb5c29e2a37de \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=MyPublicRouteTable}]'

# create route
aws ec2 create-route \
    --route-table-id rtb-0da72e615ab85f85f \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id igw-0c7ca728fdc7cfc9e


# associate route table
aws ec2 associate-route-table \
    --subnet-id subnet-013f0dc2f57226a3f \
    --route-table-id rtb-0da72e615ab85f85f

# create security group
aws ec2 create-security-group \
    --group-name MyPublicEC2-SG \
    --description "Security group for Public EC2 testing" \
    --vpc-id vpc-0beadb5c29e2a37de \
    --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=MyPublicEC2-SG}]'


# enable SSH (port 22)
aws ec2 authorize-security-group-ingress \
    --group-id sg-07ff5f49a995b1828 \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

# enable HTTP (port 80)
aws ec2 authorize-security-group-ingress \
    --group-id sg-07ff5f49a995b1828 \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

# create EC2
i-0b6bc26a6cc83d938

# use EC2 instance connect
> Switch to root and update system packages
  sudo yum update -y
> Install Apache HTTP Server (httpd)
  sudo yum install -y httpd
> Create a sample index.html page
  echo "<h1>Hello\! My AWS VPC Web Server is working\!</h1>" | sudo tee /var/www/html/index.html
> Enable and start the Apache web service
  sudo systemctl start httpd

![alt text](image-1.png)

