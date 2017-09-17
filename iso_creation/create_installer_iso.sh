#!/usr/bin/env bash
#===============================================================================
#
#          FILE: create_installer_iso.sh
# 
#         USAGE: ./create_installer_iso.sh 
# 
#   DESCRIPTION: Creates a CentOS installer ISO that incorporates:
#                * custom EFI/BOOT/grub.cfg that specifies a kickstart file
#                * kickstart file
#                * the creation and population of a setup directory on the iso
#                  this directory stores any files used in pre / post installation
#                  scripts within the kickstart installation
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: Must be run from the directory that holds the script
#        AUTHOR: Thomas Lane
#  ORGANIZATION: BCIT
#       CREATED: 25/07/16 12:52
#===============================================================================
set -o nounset                              # Treat unset variables as an error

# get the abosolute path of the current script and its directory 
# us this to setup relative paths
declare script_path="$(readlink -f $0)"
declare script_dir=$(dirname "${script_path}")

declare mirror_site="http://mirror.its.sfu.ca/mirror/CentOS/7/isos/x86_64/"
declare iso_name="CentOS-7-x86_64-Minimal-1611"
declare software_dir="${script_dir}/../software"
declare iso_mount="${script_dir}/iso_mount"
declare iso_content="${script_dir}/iso_content"
declare kickstart_file="${script_dir}/../pxe_server_config/kickstart/pxe_server.ks"
declare setup_content="${script_dir}/../pxe_server_config/setup"

#Create a place to store ISO's if you don't have one
if [[ ! -d "${software_dir}" ]] ; then
  mkdir "${software_dir}"
fi

#Download Install ISO if you don't already have it
if [[ ! -f "${software_dir}/${iso_name}.iso" ]] ; then

  curl "${mirror_site}/${iso_name}.iso" --output "${software_dir}/${iso_name}.iso"
  curl "${mirror_site}/sha256sum.txt" --output "${software_dir}/sha256sum.txt"
  
  # Verify download and exit if it isn't ok
  
  pushd "${software_dir}"

  # get the correct file name : digest pair from file and 
  # pipe it to sha256sum to check "-c" if it matches a generated sum for any 
  # matching filenames in the current directory
  grep "${iso_name}.iso" sha256sum.txt | sha256sum -c
  
  # If digest check fails tell user and exit 
  if [[ $? != 0 ]]  ; then
    echo "sha256sum failed"
    exit 1
  fi

  popd

fi

#if necessary clear then create a directory to mount the installation ISO 
if [[ -d "${iso_mount}" ]] ; then
  rm -rf "${iso_mount}"
fi

mkdir "${iso_mount}"

#if necessary clear the directory that will store the installation ISO contents
if [[ -d "${iso_content}" ]] ; then
  rm -rf "${iso_content}"
fi

#Generate writable copy of ISO contents by copying ISO to writable directory
sudo mount -t iso9660 -o loop,ro "${software_dir}/${iso_name}.iso" "${iso_mount}"
cp -pRf "${iso_mount}" "${iso_content}"

#Cleanup ISO: unmount and delete directory the mount directory
sudo umount "${iso_mount}"
rm -rf "${iso_mount}"

#Make modifications to ISO content
cp "${kickstart_file}" "${iso_content}"/kickstart.ks
cp "${script_dir}/iso_updates/grub.cfg" "${iso_content}"/EFI/BOOT/grub.cfg

#Copy files into Setup directory for use by kickstart file
cp -r "${setup_content}" "${iso_content}/"

#Generate New ISO image 
genisoimage -U -r -v -T -J -joliet-long\
  -V "CentOS 7 x86_64"\
  -volset "CentOS 7 x86_64"\
  -A "CentOS 7 x86_64"\
  -b isolinux/isolinux.bin\
  -c isolinux/boot.cat\
  -no-emul-boot\
  -boot-load-size 4\
  -boot-info-table\
  -eltorito-alt-boot\
  -e images/efiboot.img\
  -no-emul-boot\
  -o "${software_dir}/${iso_name}_w_ks.iso" "${iso_content}"

# Notes:
# -U - allows the use of untranslated file names
# -r - sets the uid, and gid to zero for all files, zeros all write bits, 
#     sets read, and executable bits on all files
# -v - verbose exectution
# -T - generate a translation table  TRANS.TBL for use in certain systems
# -J - generate joliet directory records in addition to ISO file names - useful
#      on Windows machines
# -jolient-long - allow file names up to 103 unicode chagracters.
# -V volume_id - specifies the volume id (aka name) used by Solaris, MacOS, 
#    Windows this can only be 32 characters long
# -volset volset_id - specifies the volume set name
# -A - string that is written to the volume header, space for 128 characters
# -b eltorito_boot_image - used to provide bootable components on cd image
# -c boot_catalog - needed for bootable cd
# -no-emul-boot - don't attempt to emulate a disk drive
# -boot-load-size 4 - specifieds the number of "virtual" sectors to load
# -boot-info-table specifies the creation of a 56-byte table of CD ROM layout 
#      will be patched in at offeset 8 of the boot file. 
# -eltorito-alt-boot - Start with a new set of El Torito boot parameters
# -e efi_boot_file - EFI boot file name
# -no-emul-boot - specifies that no translations will be performed on boot image
# -o output_file_name - path to output iso

#Remove all iso_content
rm -rf "${iso_content}"
