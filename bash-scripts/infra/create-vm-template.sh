#!/bin/bash

USE_DEBIAN=0
FORCE=1
TMPL_ID=9000  
TMPL_STORAGE="local-lvm"

IMG_PATH="/root/iso"
DISTRO_NAME="focal"

function download-ubuntu-image () {
  TARGET_FOLDER=$1
  DISTRO_NAME=$2

  mkdir -p "$TARGET_FOLDER"
  TARGET_IMG_FULLPATH="$TARGET_FOLDER/$DISTRO_NAME-server-cloudimg-amd64.img"
  if [ ! -f "$TARGET_IMG_FULLPATH" ]; then
      wget -O "$TARGET_IMG_FULLPATH" "https://cloud-images.ubuntu.com/$DISTRO_NAME/current/$DISTRO_NAME-server-cloudimg-amd64.img"
  fi
}

download-ubuntu-image "$IMG_PATH" "$DISTRO_NAME"

ORIGINAL_IMGDISK="$IMG_PATH/$DISTRO_NAME-server-cloudimg-amd64.img"
ORIGINAL_FILENAME=$(basename -- "$ORIGINAL_IMGDISK")
ORIGINAL_FILENAME_NOEXT=${ORIGINAL_FILENAME%%.*}
IMGDISK="${ORIGINAL_IMGDISK%%.*}-modified.img"

cp -f "$ORIGINAL_IMGDISK" "$IMGDISK"

if [ -z ${TEMPLATE_NAME+x} ]
then
  TEMPLATE_NAME=$ORIGINAL_FILENAME_NOEXT-template
fi

if [ $USE_DEBIAN == 1 ]
then
  virt-customize -a "$IMGDISK" --run-command 'sed -i s/dhcp/static/ /etc/network/cloud-interfaces-template'
fi

if [ $FORCE == 1 ]
then
  qm destroy $TMPL_ID -purge -destroy-unreferenced-disks 1
fi

virt-customize -a "$IMGDISK" --install qemu-guest-agent


if [ ! -f /etc/pve/nodes/proxmox/qemu-server/$TMPL_ID.conf ]
then
  cp -f userconfig.yml /var/lib/vz/snippets/userconfig.yml

  qm create $TMPL_ID \
      --name "$TEMPLATE_NAME" \
      --memory 2048 \
      --cores 2 \
      --net0 virtio,bridge=vmbr0 \
      --net1 virtio,bridge=vmbr1

  qm importdisk $TMPL_ID "$IMGDISK" $TMPL_STORAGE
  qm set $TMPL_ID --ostype l26
  qm set $TMPL_ID --scsihw virtio-scsi-pci --scsi0 $TMPL_STORAGE:vm-$TMPL_ID-disk-0,size=24G
  qm set $TMPL_ID --ide2 $TMPL_STORAGE:cloudinit
  qm set $TMPL_ID --boot c --bootdisk scsi0
  qm set $TMPL_ID --serial0 socket --vga serial0
  qm set $TMPL_ID --agent enabled=1
  qm set $TMPL_ID --cicustom "user=local:snippets/userconfig.yml"

  qm set $TMPL_ID --nameserver 192.168.104.1
  # qm set $TMPL_ID --searchdomain local.cisien.com

  qm template $TMPL_ID
fi
