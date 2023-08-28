#!/bin/bash
# Script-Name:	buildiso
# Description:	Guided creation of an ISO File for Subiquity deployment
# Author:		Jan-Philipp Jürgens
# Version:		1.2.2
# Last changed:	28MAR23
# Permissions:	This script is in no need of sudo permissions!

echo "----------------------------------------------"
echo "---Subiquity Auto Installation ISO Repacker---"
echo "--------BOOT via EFI and MBR likewise---------"
echo "----------------------------------------------"
echo "To make use of the Canonical HWE-Kernel you"
echo "need to modify the grub.cfg on dir above!"
echo "----------------------------------------------"
echo ""
echo "--------ATTENTION ATTENTION ATTENTION---------"
echo "THIS SCRIPT WILL PRODUCE AN ISO WHICH WILL"
echo "AUTOMATICALLY BOOT AND REMOVE ANY DATA ON THE"
echo "PRIMARY DRIVE DEFINED IN THE USER-DATA FILE!"
echo "--------ATTENTION ATTENTION ATTENTION---------"
echo ""
echo "HAVE YOU UNDERSTOOD THAT THIS IS DANGEROUS IF HANDLED INCORRECTLY?"
read -p "(yes/no) " securityq
case "$securityq" in
	yes|YES ) echo "Confirmed";;
	* ) echo "User aborted the execution" & exit 188;;
esac

echo ""
echo "Extracting script path..."

scriptPath="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
if [ -z "$scriptPath" ]; then
	echo "CRIT: Path can not be read! Check directory structure or run from home directory!"
	exit 3
else
	echo "Path found: ${scriptPath}"
fi
echo "Setting up predefined variables..."

ISOcargo=NULL
branding=YOUR_BRAND_HERE
checkAptBased=$(cat /etc/os-release | grep -i ID_Like=debian);
checkOne=0
checkPort=443
checkTwo=0
checkWWW1="ubuntu.com"
checkWWW2="google.com"
cleanup=NULL
dlIso=1
efiImage="${isoName}.efi"
efiPart='--interval:appended_partition_2:all::'
isoName=jammy-live-server-amd64
isoPathServer=https://cdimage.ubuntu.com/ubuntu-server/jammy/daily-live/current/jammy-live-server-amd64.iso
mbrImage="${isoName}.mbr"
mbrPathUnpacked="${unpackedSourceISO}/boot/grub/i386-pc/eltorito.img"
origIsoPath="${scriptPath}/../${isoName}.iso"
testing=NULL
unpackedSourceISO="${scriptPath}/source-files/"
useIso=NULL
vidName=U2204SUBI #Volume-ID NOT filename of ISO!

echo "Predefined variables set"

if test -z $checkAptBased; then
	echo ""
	printf 'CRIT:10:unsupported distro: Your distribution is not of the debian kind, script will likely fail without manual adjustments!/n'
	exit 10
else
	echo ""
fi

if version=$(dpkg-query -W -f='${Version}' xorriso 2>/dev/null); then
	if dpkg --compare-versions "$version" 'le' 1.5.4; then
		echo ""
		echo "CRIT:65:prerequisite:version: XORRISO is below version 1.5.4 which means it likely is flawed with an issue common to interfere with this scripts purpose!"
		exit 65
	else
		echo ""
	fi
else
	echo "CRIT:65: Your are missing the required package xorriso"
	echo "install via: sudo apt install xorriso"
	exit 65
fi

if version=$(dpkg-query -W -f='${Version}' p7zip-full 2>/dev/null); then

       echo ""

else
        echo "CRIT:65: Your are missing the required package p7zip"
        echo "install via: sudo apt install p7zip-full"
	exit 65
fi

if test -f "${scriptPath}/../${isoName}.iso"; then
	echo ""
	echo "----USER INPUT REQUESTED----"
	echo "A source ISO file is already present, should it be used?"
	read -p "(Y/n) " useIso
	case "$useIso" in
		y|Y ) dlIso=0;;
		"" ) dlIso=0;;
		* ) dlIso=1;;
	esac
fi

if [[ $dlIso -eq 1 ]]; then
	echo "checking for internet connection..."
	if (nc -z -w2 -v $checkWWW1 $checkPort); then
		checkOne=1
		echo "R: The internet appears to be available"
	else
		checkOne=0
		echo "First connection failed, trying second..."
		if (nc -z -w2 -v $checkWWW2 $checkPort); then
			checkTwo=1
			echo "R: The internet appears to be available"
		else
			checkTwo=0
		fi
	fi
	if [[ $checkOne+$checkTwo -eq 0 ]]; then
		echo "CRIT: This machine seems to have no connection to the internet, aborting!"
		exit 404
	else
		echo "Downloading current daily server from:"
		echo "${isoPathServer}"
		wget -N ${isoPathServer}
		mv ${scriptPath}/*.iso ${scriptPath}/../${isoName}.iso
	fi
fi

echo ""
echo "Removing old source-files directory if present"
if test -d "${scriptPath}/source-files"; then
	rm -rf ${scriptPath}/source-files
fi

echo "Unpacking ISO container to ${scriptPath}/source-files..."
echo ""
7z -y x ${scriptPath}/../${isoName}.iso -o${scriptPath}/source-files

if test -d "${scriptPath}/source-files/boot/grub/x86_64-efi"; then
	echo ""
	echo "Unpacked ISO content found..."
	echo "Creating nocloud directory in source-files..."
	mkdir ${scriptPath}/source-files/nocloud
else
	echo ""
	echo "----USER INPUT REQUESTED----"
	echo "CRIT: No structure found in unpacked ISO matching Ubuntu 22.04.1 original ISO tree!"
	echo "Do you wish to execute anyway?"
	read -p "(Y/n) " override
	case "$override" in
		y|Y ) echo "Continuing...";;
		"" ) echo "Continuing...";;
		* ) exit 3;;
	esac
fi

if test -f "${scriptPath}/../user-data"; then
	echo ""
	echo "A user-data file has been found in head directory, copying to source-files"
	cp ${scriptPath}/../user-data ${scriptPath}/source-files/nocloud
else
	echo ""
	echo "CRIT: This script requires a user-data file present in ../."
	exit 2
fi
echo ""
echo "Creating empty meta-data file"
touch ${scriptPath}/source-files/nocloud/meta-data

if test -f "${scriptPath}/../grub.cfg"; then
	echo ""
	echo "A grub.cfg was found, copying ..."
	cp ${scriptPath}/../grub.cfg ${scriptPath}/source-files/boot/grub
	echo "replacing ISO loopback.cfg with grub.cfg duplicate..."
	cp ${scriptPath}/../grub.cfg ${scriptPath}/source-files/boot/grub/loopback.cfg
else
	echo ""
	echo "CRIT: This script requires a grub.cfg file present in ../."
	exit 2
fi

if test -f "${scriptPath}/${isoName}.mbr"; then
	echo ""
	echo "An old MBR Image was found, moving to .mbr.old"
	mv ${scriptPath}/${isoName}.mbr ${scriptPath}/${isoName}.mbr.old
fi
echo "Extracting MBR Boot-'Image' from source ISO..."
dd if=${scriptPath}/../${isoName}.iso bs=1 count=446 of=${scriptPath}/${isoName}.mbr

if test -f "${scriptPath}/*.efi"; then
	echo "An old EFI Image was found, moving to .efi.old"
	mv ${scriptPath}/${efiImage}.efi ${scriptPath}/${efiImage}.old
fi

echo "Extracting EFI Boot-'Image' from source ISO..."
skip=$(/sbin/fdisk -l "$origIsoPath" | fgrep '.iso2 ' | awk '{print $2}')
size=$(/sbin/fdisk -l "$origIsoPath" | fgrep '.iso2 ' | awk '{print $4}')
dd if="$origIsoPath" bs=512 skip="$skip" count="$size" of=${scriptPath}/"$efiImage"

echo ""
echo "----USER INPUT REQUESTED----"
echo "Is the repacked ISO thought for testing purposes?"
read -p "(y/N) " testing
case "$testing" in
	y|Y ) outName=${branding}-${isoName}-testing;;
	"" ) outName=${branding}-${isoName};;
	* ) outName=${branding}-${isoName};;
esac

echo ""
echo "Searching user-data and meta-data files in source-files directory..."
if test -f "${unpackedSourceISO}/nocloud/user-data"; then
	echo "user-data file found"
else
	echo "CRIT: user-data file not present!"
	exit 2
fi

if test -f "${unpackedSourceISO}/nocloud/meta-data"; then
	echo "meta-data file found"
else
	echo "CRIT: meta-data file not present!"
	exit 2
fi

echo ""
echo "----USER INPUT REQUESTED----"
echo "If you have placed files in the head dicrectory cargo folder"
echo "Do you want these to be included in the repacked ISO?"
read -p "(y/N) " cargoq
case "$cargoq" in
	y|Y ) ISOcargo=1;;
	"" ) ISOcargo=0;;
	* ) ISOcargo=0;;
esac

if [ $ISOcargo -eq 1 ]; then
	echo "All files contained in ../cargo will be copied to: ISOroot/cargo/"
	echo "These files will be available in cloud-init via /cdrom/cargo/yourfile"
	if [ ! -d "${unpackedSourceISO}/cargo" ]; then
		mkdir "${unpackedSourceISO}/cargo"
	fi
	cp ${scriptPath}/../cargo/* ${unpackedSourceISO}/cargo/
	echo "done copying."
else
	echo "Custom cargo will not be transfered!"
fi

echo ""
echo "Starting ISO repacking..."

xorriso -as mkisofs -r -V ${vidName} -J -joliet-long -l -iso-level 3 -o ./${outName}.iso --grub2-mbr ${scriptPath}/${mbrImage} -partition_offset 16 --mbr-force-bootable -append_partition 2 0xEF ./${efiImage} -appended_part_as_gpt -c '/boot.catalog' -b ${mbrPathUnpacked} -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info -eltorito-alt-boot -e ${efiPart} -no-emul-boot ${unpackedSourceISO}

if test -f "${scriptPath}/${outName}.iso"; then
	echo ""
	echo "Repacked ISO found. Initiating final CleanUP."
else
	echo ""
	echo "CRIT: There is no ISO File where a repacked ISO File should be :<"
	echo "Something went wrong! Check files and structure and rerun."
	exit 2
fi

echo "CleanUP..."
echo "MBR Image"
rm ${scriptPath}/${mbrImage}
echo "EFI Image"
rm ${scriptPath}/${efiImage}
echo ""
echo "----USER INPUT REQUESTED----"
echo "Should the produced source-files directory be removed?"
read -p "(Y/n) " cleanup
case "$cleanup" in
	y|Y ) rm -rf ${scriptPath}/source-files;;
	"" ) rm -rf ${scriptPath}/source-files;;
	* ) echo ""; echo "source-files directory will not be removed";;
esac
echo "Clean up finished."

echo ""
echo "--------------------------------------------------------------------------------------"
echo "To make the ISO file available to QEMU/KVM via virt-manager use the following command:"
echo "   sudo cp ./${outName}.iso /var/lib/libvirt/images"
echo "--------------------------------------------------------------------------------------"
echo "Thank you for using the Subiquity Auto Installation ISO Repacker!"
echo "If you encountered problems or want a feature added visit:"
echo "https://github.com/PaxJaromeMalues/ubuntu-server-autoinstall-iso-repacker"
echo "--------------------------------------------------------------------------------------"

exit 0
