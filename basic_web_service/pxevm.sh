#!/bin/bash
#VirtualBox configuration script based on configuration tasks
#required by NASP 19

if [[ "$EUID" -eq 0 ]]; then
    echo "ERROR: Sorry, don't run this as root"
    exit 1
fi


declare vbox_name=Wordpress_Host
declare network_name=nasp_cm_co
vboxmanage unregistervm $vbox_name --delete
VBoxManage natnetwork remove --netname $network_name


vboxmanage createvm --name $vbox_name --ostype RedHat_64 --basefolder /home/dmaclennan/Desktop/HDD/Virtual\ Machines/Cloud --register
vboxmanage createhd --filename /home/dmaclennan/Desktop/HDD/Virtual\ Machines/Cloud/${vbox_name}/${vbox_name}.vdi --size 10000 -variant Standard

vboxmanage storagectl $vbox_name \
  --name IDE_Controller --add ide --bootable on

vboxmanage storagectl $vbox_name \
  --name SATA_Controller --add sata --bootable on

vboxmanage storageattach $vbox_name \
  --storagectl IDE_Controller --port 0 --device 0 --type dvddrive \
  --medium "none"

vboxmanage storageattach $vbox_name \
  --storagectl IDE_Controller --port 1 --device 0 --type dvddrive \
  --medium "/usr/share/virtualbox/VBoxGuestAdditions.iso"

vboxmanage storageattach $vbox_name \
  --storagectl SATA_Controller  --port 0 --device 0 --type hdd \
  --medium /home/dmaclennan/Desktop/HDD/Virtual\ Machines/Cloud/${vbox_name}/${vbox_name}.vdi --nonrotational on

vboxmanage natnetwork add --netname $network_name \
  --network "192.168.254.0/24" --dhcp off --enable

vboxmanage modifyvm $vbox_name \
  --memory 1280 --cpus 1 --firmware bios --nic1 natnetwork --nictype1 virtio \
  --nat-network1 $network_name  --audio none \
  --boot1 disk  --boot2 net \
  --macaddress1 B6E979DC5D18
