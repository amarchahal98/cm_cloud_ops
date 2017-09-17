#version=DEVEL

###### Installer Configuration #####################################################
# Use network installation replace with basesearch and releasever variables
url --url="https://mirror.its.sfu.ca/mirror/CentOS/7/os/x86_64/"

# License agreement
eula --agreed

#enable EPEL in order to install additional packages
repo --name="epel" --baseurl=http://download.fedoraproject.org/pub/epel/$releasever/$basearch

# Use graphical install
graphical

#Turn up logging
logging level=debug

# Reboot after installation
reboot

#Don't run keyboard / language / location / network setup on first boot
firstboot --disable
###### End Installer Configuration #################################################

###### Locale Configuration ########################################################
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'

# System language
lang en_CA.UTF-8

# System timezone
timezone America/Vancouver --isUtc
###### End Locale Configuration ####################################################

###### User and Auth Configuration #################################################
# System authorization information
auth --passalgo=sha512 --useshadow

# Root password : nasp19
rootpw --iscrypted PEO6a6IsNWw/U

# admin password : nasp19
user --name=admin --password=PEO6a6IsNWw/U --iscrypted --gecos="admin" --groups="wheel"

###### End User and Auth Configuration #################################################

###### Network Configuration #######################################################
network  --bootproto=static --device=eth0 --gateway=192.168.254.1 --ip=192.168.254.5 --nameserver=8.8.8.8 --netmask=255.255.255.0 --ipv6=auto --activate
network  --hostname=pxe.i1.cm.nasp

###### End Network Configuration ###################################################

###### Disk Setup ##################################################################
ignoredisk --only-use=sda
clearpart --drives=sda --all 
autopart --type=btrfs

# System bootloader configuration (note location=mbr puts boot loader in ESP since UEFI)
bootloader --append="rhgb crashkernel=auto" --location=mbr #--driveorder=/dev/sda

###### End Disk Setup ##################################################################

###### Addons: kernel dump #############################################################
%addon com_redhat_kdump --enable --reserve-mb='auto'

%end
###### End Addons: kernel dump #########################################################

###### Security Configuration ######################################################
firewall --enabled --http --ssh --service=tftp
selinux --permissive
###### End Security Configuration ##################################################

###### System services #############################################################
services --enabled=sshd,ntpd,chronyd,nginx,xinetd,dhcpd
###### End System services #########################################################


###### Pre-Installation Script #########################################################
###### End Pre-Installation Script #####################################################

###### Package Installation ############################################################
%packages
@core
@base 
epel-release
vim
chrony
git
kernel-devel
kernel-headers
dkms
gcc
gcc-c++
kexec-tools
ntp
dhcp
syslinux-tftpboot
tftp-server
xinetd
nginx
%end
###### End Package Installation ########################################################

###### Post-Installation Script ########################################################
%post --nochroot --log=/mnt/sysimage/root/ks-post-nochroot.log 
#This section isn't chroot'd allowing access to source ISO to move files

#create mount point to cdrom to access setup files
mkdir /mnt/iso_mnt
mount -o loop,ro /dev/cdrom /mnt/iso_mnt

#copy ssh files for passwordless operation
mkdir /mnt/sysimage/home/admin/.ssh
cp /mnt/iso_mnt/setup/authorized_keys /mnt/sysimage/home/admin/.ssh/authorized_keys

#copy dhcp configuration
cp /mnt/iso_mnt/setup/dhcpd.conf /mnt/sysimage/etc/dhcp/dhcpd.conf

#copy tftp configuration
cp /mnt/iso_mnt/setup/tftp /mnt/sysimage/etc/xinetd.d/tftp

#copy nginx configuration
cp /mnt/iso_mnt/setup/nginx.conf /mnt/sysimage/etc/nginx/nginx.conf

#copy pxeboot default configuration
mkdir /mnt/sysimage/var/lib/tftpboot/pxelinux.cfg
cp /mnt/iso_mnt/setup/default /mnt/sysimage/var/lib/tftpboot/pxelinux.cfg/default

#copy boot image and initrd from iso to server for use by tftp-pxe boot
cp /mnt/iso_mnt/images/pxeboot/{vmlinuz,initrd.img}  /mnt/sysimage/var/lib/tftpboot/

%end

%post --log=/root/ks-post.log
#!/bin/bash

#Update System
yum -y update

#Copy ssh authorized keys to new image
#Set ownership and permission of admin authorized keys
chmod -R u=rw,g=,o= /home/admin/.ssh
chown -R admin /home/admin/.ssh
chgrp -R admin /home/admin/.ssh
chmod u=rwx,g=,o= /home/admin/.ssh

#Turn Down Swapiness since its an SSD disk
echo "vm.swappiness = 10" >> /etc/sysctl.conf

#Install Virtualbox Guest Additions
mkdir vbox_cd
mount /dev/sr1 ./vbox_cd
./vbox_cd/VBoxLinuxAdditions.run
umount ./vbox_cd
rmdir ./vbox_cd

#Sudo Modifications
#Allow all wheel members to sudo all commands without a password by uncommenting line from /etc/sudoers
sed -i 's/^#\s*\(%wheel\s*ALL=(ALL)\s*NOPASSWD:\s*ALL\)/\1/' /etc/sudoers
#Enable sudo over ssh without a terminal
sed -i 's/^\(Defaults    requiretty\)/#\1/' /etc/sudoers

#tftp configuration: enable tftp by changing disabled from yes to no
sed -i 's/\s*\(disable =\s*\)yes/\1no/' /etc/xinetd.d/tftp

#Demonstration of copying remote file 
curl -o /root/rhel_7_installation_manual.pdf https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/pdf/System_Administrators_Guide/Red_Hat_Enterprise_Linux-7-System_Administrators_Guide-en-US.pdf

#Allow read and write by admin to /usr/share/nginx/html
chown -R nginx:wheel /usr/share/nginx/html
chmod -R ug+w /usr/share/nginx/html
 
%end
###### End Post-Installation Script ####################################################


