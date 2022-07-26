#!/bin/bash

mapfile -d " " -t < <(hostname -I)
for ip in "${MAPFILE[@]}";
do
  if [[ $ip == "10.0."* ]]; then
    PRIVATE_IP=$ip
    echo "using $PRIVATE_IP"
    break;
  fi
done

echo "Using MASTER_IP: $MASTER_IP"
POD_CIDR="192.168.0.0/16"

sudo kubeadm init --apiserver-advertise-address="$PRIVATE_IP" --apiserver-cert-extra-sans="$PRIVATE_IP" --pod-network-cidr=$POD_CIDR --node-name="$(hostname -s)"

sudo mkdir -p "$HOME/.kube"
sudo cp /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u)":"$(id -g)" "$HOME/.kube/config"

curl https://docs.projectcalico.org/manifests/calico.yaml -O
kubectl apply -f calico.yaml

sudo kubeadm token create --print-join-command | tee ./join.sh