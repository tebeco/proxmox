#!/bin/bash

# avoid "Permission are too opened" error message over SSH
# TODO:
# * Clean ~/.ssh/knwownhost
# * delete old SSH key
# * call openssl
# * generate new key
# * sed s/KEY_PLACEHOLDER/$(cat -n <keyfilehere>) ./cloudinit-template.yml | tee ./cloudinit.yml
chmod 400 ~/.ssh/kube-key-ecdsa


cd ./infra || exit
./deploy.sh

cd ./controlplane || exit
./deploy.sh