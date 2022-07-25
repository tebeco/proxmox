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
LAST_OCTET_START=10
REBUILD_TEMPLATE=0
VMID_BASE=1000
COUNT=3
TMPLID=9001
TMPL_STORAGE="local-lvm"

if [ $REBUILD_TEMPLATE == 1 ]
then
  qm destroy $TMPLID -purge -destroy-unreferenced-disks 1
fi

if [ ! -f /etc/pve/nodes/proxmox/qemu-server/$TMPLID.conf ]
then
  cp -f userconfig-base.yml /var/lib/vz/snippets/
  qm create $TMPLID --name template \
      --memory 2048 \
      --cores 2 \
      --net0 virtio,bridge=vmbr0 \
      --net1 virtio,bridge=vmbr1
  qm importdisk $TMPLID $UBUNU_IMGDISK $TMPL_STORAGE
  qm set $TMPLID --ostype l26
  qm set $TMPLID --scsihw virtio-scsi-pci --scsi0 $TMPL_STORAGE:vm-$TMPLID-disk-0,size=64G
  qm set $TMPLID --boot c --bootdisk scsi0
  qm set $TMPLID --ide2 $TMPL_STORAGE:cloudinit
  qm set $TMPLID --serial0 socket --vga serial0
  qm set $TMPLID --agent enabled=1
  qm set $TMPLID --cicustom "user=local:snippets/userconfig-base.yml"
  qm set $TMPLID --nameserver 192.168.104.1
  # qm set $TMPLID --nameserver 172.16.0.1
  # qm set $TMPLID --searchdomain local.cisien.com
  qm template $TMPLID

fi

for (( i=0; i<$COUNT; i++ ))
do

  VMID=$(($VMID_BASE + $i))
  LAST_OCTET=$(($LAST_OCTET_START + $i))
  # TARGET_NODE=$((($i % 3) + 1))

  HOSTNAME="$VMNAME$(($i + 1))"
  echo $HOSTNAME
  
  qm clone $TMPLID $VMID --name $HOSTNAME
  qm set $VMID --ipconfig0 ip=192.168.104.$LAST_OCTET/24,gw=192.168.104.1
  qm set $VMID --ipconfig1 ip=10.200.0.$LAST_OCTET/24
  qm set $VMID --smbios1 base64=1,serial=$(echo -n "ds=nocloud;h=$HOSTNAME" | base64)
  # qm resize $VMID scsi0 64G
  qm start $VMID
  # qm migrate $VMID "pve-0$TARGET_NODE" --online

done