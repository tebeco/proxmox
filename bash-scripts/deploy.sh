#!/bin/bash

# avoid "Permission are too opened" error message over SSH
# TODO:
# * Clean ~/.ssh/knwownhost
# * delete old SSH key
# * call openssl
# * generate new key
# * sed s/KEY_PLACEHOLDER/$(cat -n <keyfilehere>) ./cloudinit-template.yml | tee ./cloudinit.yml
chmod 400 ~/.ssh/kube-key-ecdsa

################ Create VM Cluster
cd ./infra || exit
./deploy.sh
cd - || exit

################ Remote deploy of Control Plane
SOURCE_FILES="./controlplane/files.txt"
TARGET_USER="tebeco"
TARGET_HOST="192.168.104.10"
TARGET_FOLDER="/home/tebeco/instal-cp"

./common/remote-deploy.sh "$(readlink -f "$SOURCE_FILES")" "$TARGET_USER" "$TARGET_HOST" "$TARGET_FOLDER"

################ Remote deploy of Workers Nodes
# SOURCE_FILES="./worker/files.txt"
# TARGET_USER="tebeco"
# TARGET_HOST=(192.168.104.20 192.168.104.21)"
# TARGET_FOLDER="/home/tebeco/instal-worker"

# ./common/remote-deploy.sh "$(readlink -f "$SOURCE_FILES")" "$TARGET_USER" "$TARGET_HOST" "$TARGET_FOLDER"