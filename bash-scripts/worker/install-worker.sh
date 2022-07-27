#!/bin/bash

mkdir -p "$HOME/.kube"
cp ./config "$HOME/.kube/config"

sudo ./join.sh

kubectl label node "$(hostname -s)" node-role.kubernetes.io/worker=worker-node
