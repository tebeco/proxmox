#!/bin/bash

MASTER_IP="10.0.0.10"
POD_CIDR="192.168.0.0/16"

sudo kubeadm init --apiserver-advertise-address=$MASTER_IP --apiserver-cert-extra-sans=$MASTER_IP --pod-network-cidr=$POD_CIDR --node-name=$(hostname -s)

sudo mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

curl https://docs.projectcalico.org/manifests/calico.yaml -O
kubectl apply -f calico.yaml

sudo kubeadm token create --print-join-command > ./join.sh
