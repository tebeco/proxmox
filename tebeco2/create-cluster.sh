#!/bin/bash

SOURCE_DEBIAN_IMGDISK="/root/debian-11-genericcloud-amd64.raw"
MODIFIED_DEBIAN_IMGDISK="/root/debian-11-genericcloud-amd64-staticip.raw"
IMGDISK=$MODIFIED_DEBIAN_IMGDISK

FORCE=1
TMPL_ID=9000  
TMPL_STORAGE="local-lvm"

CPLANE_COUNT=1
CPLANE_VMNAME="kube-control-plane-0"
CPLANE_LAST_OCTET_START=10
CPLANE_VMID_BASE=$((1000 + $CPLANE_LAST_OCTET_START))

NODE_COUNT=2
NODE_VMNAME="kube-node-0"
NODE_LAST_OCTET_START=20
NODE_VMID_BASE=$((1000 + $NODE_LAST_OCTET_START))

if [ $FORCE == 1 ]
then
  rm $MODIFIED_DEBIAN_IMGDISK

  qm destroy $TMPL_ID -purge -destroy-unreferenced-disks 1

  for (( i=0; i<$CPLANE_COUNT; i++ ))
  do
    qm stop $(($i + $CPLANE_VMID_BASE))
    qm destroy $(($i + $CPLANE_VMID_BASE)) -purge -destroy-unreferenced-disks 1
  done

  for (( i=0; i<$NODE_COUNT; i++ ))
  do
    qm stop $(($i + $NODE_VMID_BASE))
    qm destroy $(($i + $NODE_VMID_BASE)) -purge -destroy-unreferenced-disks 1
  done
fi

cp -f $SOURCE_DEBIAN_IMGDISK $MODIFIED_DEBIAN_IMGDISK
# virt-edit -a $MODIFIED_DEBIAN_IMGDISK /etc/network/cloud-interfaces-template -e 's/dhcp/static/'
virt-customize -a $MODIFIED_DEBIAN_IMGDISK --run-command 'sed -i s/dhcp/static/ /etc/network/cloud-interfaces-template'
virt-customize -a $MODIFIED_DEBIAN_IMGDISK --run-command 'echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg'
IMGDISK=$MODIFIED_DEBIAN_IMGDISK

if [ ! -f /etc/pve/nodes/proxmox/qemu-server/$TMPL_ID.conf ]
then
  cp -f userconfig-tebeco2.yml /var/lib/vz/snippets/userconfig-tebeco2.yml
  qm create $TMPL_ID \
      --name template \
      --memory 2048 \
      --cores 2 \
      --net0 virtio,bridge=vmbr0 \
      --net1 virtio,bridge=vmbr1

  qm importdisk $TMPL_ID $IMGDISK $TMPL_STORAGE
  qm set $TMPL_ID --ostype l26
  qm set $TMPL_ID --scsihw virtio-scsi-pci --scsi0 $TMPL_STORAGE:vm-$TMPL_ID-disk-0,size=24G
  qm set $TMPL_ID --boot c --bootdisk scsi0
  qm set $TMPL_ID --ide2 $TMPL_STORAGE:cloudinit
  qm set $TMPL_ID --serial0 socket --vga serial0
  qm set $TMPL_ID --agent enabled=1
  qm set $TMPL_ID --cicustom "user=local:snippets/userconfig-tebeco2.yml"

  qm set $TMPL_ID --nameserver 192.168.104.1
  # qm set $TMPL_ID --searchdomain local.cisien.com

  qm template $TMPL_ID
fi

############# CONTROL PLANE #############

for (( i=0; i<$CPLANE_COUNT; i++ ))
do
  HOSTNAME="$CPLANE_VMNAME$(($i + 1))"
  VMID=$(($CPLANE_VMID_BASE + $i))
  LAST_OCTET=$(($CPLANE_LAST_OCTET_START + $i))

  qm clone $TMPL_ID $VMID --name $HOSTNAME
  qm set $VMID --ipconfig0 ip=192.168.104.$LAST_OCTET/24,gw=192.168.104.1
  qm set $VMID --ipconfig1 ip=10.0.0.$LAST_OCTET/24
  qm set $VMID --smbios1 base64=1,serial=$(echo -n "ds=nocloud;h=$HOSTNAME" | base64)

  qm resize $VMID scsi0 24G
  qm start $VMID
done