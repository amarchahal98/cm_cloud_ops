#!/bin/bash
source vars.sh

# SCRIPT #
vpc_id=$(aws ec2 create-vpc --cidr-block $vpc_cidr --query Vpc.VpcId --output text)
echo "vpc_id=$vpc_id" > state_file

aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value=$vpc_name

subnet_id=$(aws ec2 create-subnet  --vpc-id $vpc_id --cidr-block $subnet_cidr --query Subnet.SubnetId  --output text)
echo "subnet_id=$subnet_id" >> state_file

aws ec2 create-tags --resources $subnet_id --tags Key=Name,Value=$subnet_name

gateway_id=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)
echo "gateway_id=$gateway_id" >> state_file

aws ec2 create-tags --resources $gateway_id --tags Key=Name,Value=$gateway_name

aws ec2 attach-internet-gateway --internet-gateway-id $gateway_id --vpc-id $vpc_id

route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id --query RouteTable.RouteTableId --output text)
echo "route_table_id=$route_table_id" >> state_file

aws ec2 create-tags  --resources $route_table_id  --tags Key=Name,Value=$route_table_name

rt_association_id=$(aws ec2 associate-route-table --route-table-id $route_table_id --subnet-id $subnet_id --query AssociationId --output text)
echo "rt_association_id=$rt_association_id" >> state_file

aws ec2 create-route --route-table-id $route_table_id --destination-cidr-block $default_cidr --gateway-id $gateway_id --output text

security_group_id=$(aws ec2 create-security-group --group-name "$security_group_name" --description "$security_group_desc" --vpc-id $vpc_id --query GroupId --output text)
echo "security_group_id=$security_group_id" >> state_file

aws ec2 authorize-security-group-ingress --group-id $security_group_id --protocol tcp --port 22 --cidr $bcit_cidr

