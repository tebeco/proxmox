#!/bin/bash

CPLANE_IP=192.168.104.10

rm -f ./setup-controlplane.tar.gz
tar -cvzf setup-controlplane.tar.gz -T ./files.txt

ssh tebeco@$CPLANE_IP 'rm -rf /home/tebeco/setup-kube'
ssh tebeco@$CPLANE_IP 'mkdir -p /home/tebeco/setup-kube'

scp setup-controlplane.tar.gz tebeco@$CPLANE_IP:/home/tebeco/setup-kube
scp install.sh tebeco@$CPLANE_IP:/home/tebeco/setup-kube/install.sh
ssh tebeco@$CPLANE_IP 'cd /home/tebeco/setup-kube && chmod +x ./install.sh && ./install.sh'
scp tebeco@$CPLANE_IP:/home/tebeco/join.sh ./join.sh