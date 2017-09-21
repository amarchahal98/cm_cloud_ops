#!/bin/bash

# VARIABLES #
name="wordpress"
nat_name="nasp_cm_co"

# Configure Virtual Machine #
vboxmanage createvm \
	--name $name \
	--ostype "RedHat_64" \
	--register 
vboxmanage modifyvm $name \
	--cpus 1 \
	--firmware bios \
	--nic1 natnetwork \
        --nat-network1 "$nat_name" \
        --cableconnected1 on \
        --audio none \
        --boot1 disk \
        --boot2 net \
        --memory 2048 \
        --vram 128 \
	--macaddress1 B6E979DC5D18


VBoxManage storagectl $name --name "IDE Controller" --add ide
VBoxManage storagectl $name --name "SATA Controller" --add sata

VBoxManage createhd --filename ~/VirtualBox\ VMs/$name/$name.vdi --size 20480

VBoxManage storageattach $name --storagectl "IDE Controller" --port 0 --device 1 --type hdd --medium ~/VirtualBox\ VMs/$name/$name.vdi > /dev/null 2>&1 
VBoxManage storageattach $name --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium /usr/share/virtualbox/VBoxGuestAdditions.iso # Attach the VirtualBox Guest Additions CD


# It Begins #
vboxmanage startvm $name
