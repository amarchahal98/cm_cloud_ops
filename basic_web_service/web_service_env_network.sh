#!/bin/bash
# VARIABLES #
name="wordpress"
nat_name="nasp_cm_co"

# Host Firewall Configuration
for var in 50022 50080 50443; do sudo firewall-cmd --zone=public --add-port=${var}/tcp --permanent; done

# Virtual Box Network Configuration
vboxmanage natnetwork add --netname "${nat_name}" --network "192.168.254.0/24" --dhcp off


#IPV4 Port Forwards
vboxmanage natnetwork modify --netname nasp_cm_co --port-forward-4 "ssh:tcp:[]:50022:[192.168.254.10]:22"
vboxmanage natnetwork modify --netname nasp_cm_co --port-forward-4 "http:tcp:[]:50080:[192.168.254.10]:80"
vboxmanage natnetwork modify --netname nasp_cm_co --port-forward-4 "https:tcp:[]:50443:[192.168.254.10]:443"

