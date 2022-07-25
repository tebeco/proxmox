#!/bin/bash

TMPL_ID=9000  
FORCE_TEMPLATE=1

if [ $FORCE_TEMPLATE == 1 ]
then
  ./create-template.sh
fi

FORCE=1

CPLANE_COUNT=1
CPLANE_VMNAME="kube-control-plane-"
CPLANE_LAST_OCTET_START=10
CPLANE_VMID_BASE=$((1000 + CPLANE_LAST_OCTET_START))

NODE_COUNT=2
NODE_VMNAME="kube-node-"
NODE_LAST_OCTET_START=20
NODE_VMID_BASE=$((1000 + NODE_LAST_OCTET_START))

if [ $FORCE == 1 ]
then
  for (( i=0; i < CPLANE_COUNT; i++ ))
  do
    qm stop $((i + CPLANE_VMID_BASE))
    qm destroy $((i + CPLANE_VMID_BASE)) -purge -destroy-unreferenced-disks 1
  done

  for (( i=0; i < NODE_COUNT; i++ ))
  do
    qm stop $((i + NODE_VMID_BASE))
    qm destroy $((i + NODE_VMID_BASE)) -purge -destroy-unreferenced-disks 1
  done
fi

function createVm() {
  TMPL_ID=$1
  VMID=$2
  HOSTNAME=$3
  ETH0_IPV4=$4
  ETH0_GW=$5
  ETH1_IPV4=$6

  qm clone "$TMPL_ID" "$VMID" --name "$HOSTNAME"
  qm set "$VMID" --ipconfig0 "$(echo -n "ip=$ETH0_IPV4,gw=$ETH0_GW")"
  qm set "$VMID" --ipconfig1 "$(echo -n "ip=$ETH1_IPV4")"
  qm set "$VMID" --smbios1 base64=1,serial="$(echo -n "ds=nocloud;h=$HOSTNAME" | base64)"

  qm resize "$VMID" scsi0 24G
  qm start "$VMID"
}

function createManyVm() {
  COUNT=$1
  VM_NAME_PREFIX=$2
  VMID_BASE=$3
  LAST_OCTET_START=$4

  for (( i=0; i < COUNT; i++ ))
  do
    VM_NAME_SUFFIX=$(printf "%02d" $((i + 1)))

    HOSTNAME="$VM_NAME_PREFIX$VM_NAME_SUFFIX"
    VMID=$((VMID_BASE + i))
    LAST_OCTET=$((LAST_OCTET_START + i))
    ETH0_IPV4=192.168.104.$LAST_OCTET/24
    ETH0_GW=192.168.104.1
    ETH1_IPV4=10.0.0.$LAST_OCTET/24

    createVm "$TMPL_ID" "$VMID" "$HOSTNAME" "$ETH0_IPV4" "$ETH0_GW" "$ETH1_IPV4"
  done
}

############# CONTROL PLANE #############

createManyVm "$CPLANE_COUNT" "$CPLANE_VMNAME" "$CPLANE_VMID_BASE" "$CPLANE_LAST_OCTET_START"

# for (( i=0; i < CPLANE_COUNT; i++ ))
# do
#   HOSTNAME="$CPLANE_VMNAME$((i + 1))"
#   VMID=$((CPLANE_VMID_BASE + i))
#   LAST_OCTET=$((CPLANE_LAST_OCTET_START + i))
#   ETH0_IPV4=192.168.104.$LAST_OCTET/24
#   ETH1_IPV4=10.0.0.$LAST_OCTET

#   createVm "$TMPL_ID" "$VMID" "$HOSTNAME" "$ETH0_IPV4" "$ETH0_GW" "$ETH1_IPV4"

#   qm resize $VMID scsi0 24G
#   qm start $VMID
# done


############# NODE POOL #############

createManyVm "$NODE_COUNT" "$NODE_VMNAME" "$NODE_VMID_BASE" "$NODE_LAST_OCTET_START"

# for (( i=0; i < NODE_COUNT; i++ ))
# do
#   HOSTNAME="$NODE_VMNAME$((i + 1))"
#   VMID=$((NODE_VMID_BASE + i))
#   LAST_OCTET=$((NODE_LAST_OCTET_START + i))

#   qm clone $TMPL_ID $VMID --name $HOSTNAME
#   qm set $VMID --ipconfig0 ip=192.168.104.$LAST_OCTET/24,gw=192.168.104.1
#   qm set $VMID --ipconfig1 ip=10.0.0.$LAST_OCTET/24
#   qm set $VMID --smbios1 base64=1,serial="$(echo -n "ds=nocloud;h=$HOSTNAME" | base64)"

#   qm resize $VMID scsi0 24G
#   qm start $VMID
# done
