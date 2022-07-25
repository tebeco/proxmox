#!/bin/bash

qm stop 1000
qm stop 1001
qm stop 1002
qm destroy 1000 -purge -destroy-unreferenced-disks 1
qm destroy 1001 -purge -destroy-unreferenced-disks 1
qm destroy 1002 -purge -destroy-unreferenced-disks 1
qm destroy 9001 -purge -destroy-unreferenced-disks 1

UBUNU_IMGDISK="/root/focal-server-cloudimg-amd64.img"

VMNAME="kube-control-plane-0"
LAST_OCTET_START=140
REBUILD_TEMPLATE=0
VMID_BASE=1000
COUNT=3
TMPL_ID=9001
TMPL_STORAGE="local-lvm"

if [ $REBUILD_TEMPLATE == 1 ]
then
  qm destroy $TMPL_ID -purge -destroy-unreferenced-disks 1
fi

if [ ! -f /etc/pve/nodes/proxmox/qemu-server/$TMPL_ID.conf ]
then
  cp -f userconfig-cisien2.yml /var/lib/vz/snippets/

  qm create $TMPL_ID --name template \
      --memory 2048 \
      --cores 2 \
      --net0 virtio,bridge=vmbr0 \
      --net1 virtio,bridge=vmbr1

  qm importdisk $TMPL_ID $UBUNU_IMGDISK $TMPL_STORAGE
  qm set $TMPL_ID --ostype l26
  qm set $TMPL_ID --scsihw virtio-scsi-pci --scsi0 $TMPL_STORAGE:vm-$TMPL_ID-disk-0,size=64G
  qm set $TMPL_ID --boot c --bootdisk scsi0
  qm set $TMPL_ID --ide2 $TMPL_STORAGE:cloudinit
  qm set $TMPL_ID --serial0 socket --vga serial0
  qm set $TMPL_ID --agent enabled=1
  qm set $TMPL_ID --cicustom "user=local:snippets/userconfig-cisien2.yml"
  qm set $TMPL_ID --nameserver 192.168.104.1
  # qm set $TMPL_ID --searchdomain local.cisien.com
  qm template $TMPL_ID
fi

for (( i=0; i<$COUNT; i++ ))
do
  VMID=$(($VMID_BASE + $i))
  LAST_OCTET=$(($LAST_OCTET_START + $i))
  # TARGET_NODE=$((($i % 3) + 1))

  HOSTNAME="$VMNAME$(($i + 1))"
  echo $HOSTNAME
  qm clone $TMPL_ID $VMID --name $HOSTNAME
  qm set $VMID --ipconfig0 ip=192.168.104.$LAST_OCTET/24,gw=192.168.104.1
  qm set $VMID --ipconfig1 ip=10.200.0.$LAST_OCTET/24
  qm set $VMID --smbios1 base64=1,serial=$(echo -n "ds=nocloud;h=$HOSTNAME" | base64)
  # qm resize $VMID scsi0 64G
  qm start $VMID
  # qm migrate $VMID "pve-0$TARGET_NODE" --online

done