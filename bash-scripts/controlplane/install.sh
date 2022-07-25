#!/bin/bash

mkdir -p /home/tebeco/setup-kube/setup-controlplane/
tar -xvzf /home/tebeco/setup-kube/setup-controlplane.tar.gz --one-top-level

cd setup-controlplane || exit
chmod +x ./common/install-prerequisites.sh
chmod +x ./install-controlplane.sh

./common/install-prerequisites.sh
./install.sh
