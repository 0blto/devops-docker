#!/bin/bash

INTERFACE=$1

if [ -z "$INTERFACE" ]; then
    echo "Usage: $0 <interface> (e.g. enp0s3)"
    exit 1
fi

cat <<EOF | sudo tee /etc/netplan/00-netcfg.yaml
network:
  version: 2
  ethernets:
    $INTERFACE:
      dhcp4: no
      addresses: [192.168.1.198/24]
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
      routes:
        - to: default
          via: 192.168.1.1
EOF

sudo chmod 600 /etc/netplan/00-netcfg.yaml
sudo netplan apply

sudo apt update
sudo apt install -y openssh-server
sudo systemctl enable --now ssh

sudo snap install cqlsh