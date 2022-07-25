#!/bin/bash

CONTAINERD_VERSION="1.6.6"
RUNC_VERSION="1.1.3"
CNI_VERSION="1.1.1"
KUBERNETES_VERSION="1.24.0-00"

echo $(hostname -I | awk '{print $2}') $(hostname) | sudo tee -a /etc/hosts2

sudo apt-get update -y
sudo apt-get install -y ca-certificates \
                        curl \
                        apt-transport-https \
                        libseccomp2
                        
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s-cri-containerd.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

curl -LO https://github.com/containerd/containerd/releases/download/v$CONTAINERD_VERSION/containerd-$CONTAINERD_VERSION-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local containerd-$CONTAINERD_VERSION-linux-amd64.tar.gz
curl -LO https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo cp containerd.service /lib/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now containerd
curl -LO https://github.com/opencontainers/runc/releases/download/v$RUNC_VERSION/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc
curl -LO https://github.com/containernetworking/plugins/releases/download/v$CNI_VERSION/cni-plugins-linux-amd64-v$CNI_VERSION.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v$CNI_VERSION.tgz
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd

sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet=$KUBERNETES_VERSION \
                        kubeadm=$KUBERNETES_VERSION \
                        kubectl=$KUBERNETES_VERSION
sudo apt-mark hold kubelet=$KUBERNETES_VERSION kubeadm=$KUBERNETES_VERSION kubectl=$KUBERNETES_VERSION

cat <<EOF | sudo tee /etc/systemd/system/kubelet.service.d/0-containerd.conf
[Service]
Environment="KUBELET_EXTRA_ARGS=--container-runtime=remote --runtime-request-timeout=15m --container-runtime-endpoint=unix:///run/containerd/containerd.sock"
EOF

sudo systemctl daemon-reload
