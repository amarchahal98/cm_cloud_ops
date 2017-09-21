#!/bin/bash
source vars.sh
source state_file

#Force deletion of EBS disk when instances terminates - block-device-mappings
instance_id=$(aws ec2 run-instances \
         --image-id $centos_7_ami_id \
         --count 1 \
         --instance-type $instance_type \
         --block-device-mappings "DeviceName=/dev/sda1,Ebs={DeleteOnTermination=true}" \
         --key-name $ssh_key_name \
         --security-group-ids $security_group_id \
         --subnet-id $subnet_id \
         --private-ip-address $instance_ip \
         --user-data file://ec2_userdata.yml \
         --query 'Instances[*].InstanceId' \
         --output text)


while state=$(aws ec2 describe-instances \
                        --instance-ids $instance_id \
                        --query 'Reservations[*].Instances[*].State.Name' \
                        --output text );\
      [[ $state = "pending" ]]; do
     echo -n '.' # Show we are working on something
     sleep 3s    # Wait three seconds before checking again
done

echo -e "\n$instance_id: $state"

addr_association_id=$(aws ec2 associate-address \
                           --instance-id $instance_id \
                           --allocation-id $elastic_ip_allocation_id \
                           --query AssociationId \
                           --output text)
