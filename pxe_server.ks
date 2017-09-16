#version=DEVEL
url --url="https://mirror.its.sfu.ca/mirror/CentOS/7/os/x86_64/"

eula --agreed

repo --name="epel" --baseurl=http://download.fedoraproject.org/pub/epel/$releasever/$basearch

logging level=debug

reboot

firstboot --disable

keyboard --vckeymap=us --xlayouts='us'

lang en_CA.UTF-8

timezone America/Vancouver --isUtc

auth --passalgo=sha512 --useshadow

rootpw --iscrypted PEO6a6IsNWw/U

cmdline

user --name=admin --password=PEO6a6IsNWw/U --iscrypted --gecos="admin" --groups="wheel"

network  --bootproto=dhcp --device=eth0 --gateway=192.168.254.1 --ip=192.168.254.5 --nameserver=8.8.8.8 --netmask=255.255.255.0 --ipv6=auto --activate
network  --hostname=wordpress

ignoredisk --only-use=sda
clearpart --drives=sda --all 
autopart --type=btrfs

bootloader --append="rhgb crashkernel=auto" --location=mbr #--driveorder=/dev/sda

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

firewall --enabled --http --ssh --port=443
selinux --permissive

services --enabled=sshd,ntpd,chronyd,nginx,xinetd,dhcpd,mariadb,php-fpm

repo --name=epel --baseurl=http://dl.fedoraproject.org/pub/epel/6/x86_64/

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
mariadb-server
mariadb
php
php-mysql
php-fpm
kernel-devel
kernel-headers
dkms
gcc
gcc-c++
kexec-tools
wget
rsync

%end

%post --nochroot --log=/mnt/sysimage/root/ks-post-nochroot.log 

mkdir /mnt/sysimage/home/admin/.ssh



%end

%post --log=/root/ks-post.log
#!/bin/bash
#Update System
yum -y update

chmod -R u=rw,g=,o= /home/admin/.ssh
chown -R admin /home/admin/.ssh
chgrp -R admin /home/admin/.ssh
chmod u=rwx,g=,o= /home/admin/.ssh

sed -i 's/^#\s*\(%wheel\s*ALL=(ALL)\s*NOPASSWD:\s*ALL\)/\1/' /etc/sudoers
sed -i 's/^\(Defaults    requiretty\)/#\1/' /etc/sudoers

curl -o mariadb_security_config.sql 192.168.254.5/mariadb_security_config.sql
curl -o php.ini 192.168.254.5/php.ini
curl -o wp_mariadb_config.sql 192.168.254.5/wp_mariadb_config.sql
curl -o nginx.conf 192.168.254.5/nginx.conf
curl -o www.conf 192.168.254.5/www.conf
curl -o wp-config.php 192.168.254.5/wp-config.php

/usr/bin/cp nginx.conf /etc/nginx/nginx.conf
/usr/bin/cp php.ini /etc/php.ini
/usr/bin/cp www.conf /etc/php-fpm.d/www.conf


curl -L http://wordpress.org/latest.tar.gz | tar xzvf
sudo cp wordpress/wp-config-sample.php wordpress/wp-config.php


rsync -avP wordpress/ /usr/share/nginx/html
mkdir /usr/share/nginx/html/wp-content/uploads
chown -R admin:nginx /usr/share/nginx/html/*




mkdir vbox_cd
mount /dev/sr1 ./vbox_cd
./vbox_cd/VBoxLinuxAdditions.run
umount ./vbox_cd
rmdir ./vbox_cd

 
%end
