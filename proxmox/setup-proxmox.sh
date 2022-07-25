#!/bin/bash

############################################################
############### disable enterprise feed
############################################################
sed -i 's/^\s*\(deb .*enterprise.proxmox.com.*\)/# \1/' /etc/apt/sources.list.d/pve-enterprise.list

############################################################
############### update/upgrade + install git
############################################################
apt-get update -y
apt-get upgrade -y
apt-get install -y \
    git \
    libguestfs-tools \
    nginx

##############################################################
############### Add NGinx / add http(s)s / add https redirect
##############################################################
rm -f /etc/nginx/sites-enabled/default

cp ./proxmox.conf /etc/nginx/conf.d/proxmox.conf
sed -i s/FQDN_PLACEHOLDER/$(hostname -f)/ /etc/nginx/conf.d/proxmox.conf

nginx -t
systemctl restart nginx
systemctl enable nginx

##############################################################
############### Add vSWtich VMBR1
##############################################################

if ! grep -q "iface vmbr1" "/etc/network/interfaces";
then

    cat <<EOF >> /etc/network/interfaces

auto vmbr1
iface vmbr1 inet static
    address 10.0.0.0/24
    bridge-ports none
    bridge-stp off
    bridge-fd 0
EOF

fi
