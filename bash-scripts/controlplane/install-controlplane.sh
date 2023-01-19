#!/bin/bash

mapfile -d " " -t < <(hostname -I)
for ip in "${MAPFILE[@]}";
do
  if [[ $ip == "192.168."* ]]; then
    PRIVATE_IP=$ip
    echo "using $PRIVATE_IP"
    break;
  fi
done

POD_CIDR="192.168.0.0/16"

sudo kubeadm init --apiserver-advertise-address="$PRIVATE_IP" --apiserver-cert-extra-sans="$PRIVATE_IP" --pod-network-cidr=$POD_CIDR --node-name="$(hostname -s)"

sudo mkdir -p "$HOME/.kube"
sudo cp /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u)":"$(id -g)" "$HOME/.kube/config"

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.5/config/manifests/metallb-native.yaml
sleep 10
kubectl apply -f ./metallb-l2.yml

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.6.0/aio/deploy/recommended.yaml
kubectl apply -f ./dashboard.yml

sudo kubeadm token create --print-join-command | tee ./join.sh
chmod +x ./join.sh
