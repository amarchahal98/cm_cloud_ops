#!/bin/bash
source vars.sh
source state_file


elastic_ip_allocation_id=$(aws ec2 allocate-address  --domain vpc  --query AllocationId  --output text)
echo "elastic_ip_allocation_id=$elastic_ip_allocation_id" >> state_file

elastic_ip=$(aws ec2 describe-addresses \
                          --allocation-ids $elastic_ip_allocation_id \
                          --query Addresses[*].PublicIp \
                          --output text)
echo "elastic_ip=$elastic_ip" >> state_file

aws ec2 create-key-pair --key-name $ssh_key_name --query 'KeyMaterial' --output text > ${ssh_key_name}
chmod 400 $ssh_key_name
