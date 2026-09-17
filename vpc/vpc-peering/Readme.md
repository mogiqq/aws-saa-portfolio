Part 1: VPC Peering 

# Deploy VPC Peering
chmod +x 01-deploy-peering.sh
./01-deploy-peering.sh


# Deploy Security Group and EC2 instance





Part 2: VPC Endpoint & Private Link

# Delete vpc-p2 to isolate the test environment
# create S3 bucket and upload test.txt

# Launch an EC2 instance in the private subnet without a public IP or Internet/NAT Gateway.

# Create a Gateway Endpoint for S3 and associate it with the private route table

# Create an Interface Endpoint (AWS PrivateLink) for SSM / AWS services and assign a dedicated Security Group

# Verify private connectivity by accessing the S3 bucket and EC2 instance via AWS backbone network.
