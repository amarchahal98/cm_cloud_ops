#!/bin/bash - 
#===============================================================================
#
#          FILE: pxe_server_create.sh
# 
#         USAGE: ./pxe_server_create.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: Assumes that virtual machine doesn't already exist.
#        AUTHOR: Thomas Lane
#  ORGANIZATION: 
#       CREATED: 11/07/16 16:22
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

declare script_path="$(readlink -f $0)"
declare script_dir=$(dirname "${script_path}")

declare vm_name="cm_co_pxe_server" 
declare install_iso="${script_dir}/../software/CentOS-7-x86_64-Minimal-1708_w_ks.iso"
declare vm_group="nasp_cm_co"
declare nat_network="nasp_cm_co"

#verify that script isn't running as root
if [[ "$EUID" -eq 0 ]]; then
    echo "ERROR: Sorry, don't run this as root"
    exit 1
fi

#create vm in specified folder
vboxmanage createvm --name "${vm_name}" --register

#Cludge to get the path of the directory where the vbox file is stored: creates file adjacent to vbox file
# vboxmanage showvminfo displays line with the path to the config file -> grep "Config file" returns it
# the extended regex `(/[^/]+)+' matches everything that is a path i.e. / followed  by anthing not / 
# this is then parsed by dirname to get the directory of the file
declare vm_info=$(vboxmanage showvminfo "${vm_name}")
declare vm_conf_line=$(echo "${vm_info}" | grep "Config file")
declare vm_conf_file=$( echo "${vm_conf_line}" | grep -oE '(/[^/]+)+')
declare vbox_directory=$(dirname "${vm_conf_file}")

#create virtual hard disk
declare hd_file="${vbox_directory}/${vm_name}.vdi"
vboxmanage createhd --filename "${hd_file}" --size 10000 --variant Standard

#add storage controllers for the optical and hard disks
vboxmanage storagectl "${vm_name}" --name ide_ctrlr --add ide --bootable on
vboxmanage storagectl "${vm_name}" --name sata_ctrlr --add sata --bootable on

#attach the installation iso this has an embemded kick start file and a custom boot option to invoke it
vboxmanage storageattach "${vm_name}" --storagectl ide_ctrlr --port 0 --device 0 --type dvddrive --medium "${install_iso}"
#attach the virtualbox guest additions iso file - used to install guest additions (done in the kickstarter) file
vboxmanage storageattach "${vm_name}" --storagectl ide_ctrlr --port 0 --device 1 --type dvddrive --medium "/usr/share/virtualbox/VBoxGuestAdditions.iso"

#attach the hard disk and specify that its an SSD 
vboxmanage storageattach "${vm_name}" --storagectl sata_ctrlr --port 0 --device 0 --type hdd --medium "${hd_file}" --nonrotational on

#configure the vm
vboxmanage modifyvm "${vm_name}"\
    --groups "/${vm_group}"\
    --ostype "RedHat_64"\
    --cpus 1\
    --hwvirtex on\
    --nestedpaging on\
    --largepages on\
    --firmware efi\
    --nic1 natnetwork\
    --nat-network1 "${nat_network}"\
    --nictype1 virtio\
    --cableconnected1 on\
    --audio none\
    --boot1 disk\
    --boot2 dvd\
    --boot3 none\
    --boot4 none\
    --natdnshostresolver1 on\
    --memory 1024 

#start the vm
vboxmanage startvm "${vm_name}" --type gui
