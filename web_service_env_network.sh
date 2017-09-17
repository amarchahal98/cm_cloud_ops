#!/bin/bash
# VARIABLES #
name="wordpress"
nat_name="nasp_cm_co"

# Host Firewall Configuration
sudo firewall-cmd --zone=public --add-port=50022/tcp --permanent
sudo firewall-cmd --zone=public --add-port=50080/tcp --permanent
sudo firewall-cmd --zone=public --add-port=50443/tcp --permanent

# Virtual Box Network Configuration
vboxmanage natnetwork add --netname "${nat_name}" --network "192.168.254.0/24" --dhcp off


#IPV4 Port Forwards
vboxmanage natnetwork modify --netname nasp_cm_co --port-forward-4 "ssh:tcp:[]:50022:[192.168.254.10]:22"
vboxmanage natnetwork modify --netname nasp_cm_co --port-forward-4 "http:tcp:[]:50080:[192.168.254.10]:80"
vboxmanage natnetwork modify --netname nasp_cm_co --port-forward-4 "https:tcp:[]:50443:[192.168.254.10]:443"

