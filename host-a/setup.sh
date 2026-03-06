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
      addresses: [192.168.1.197/24]
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

sudo apt install -y docker.io docker-compose-v2
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker

docker network create -d ipvlan \
    --subnet=192.168.1.0/24 \
    --gateway=192.168.1.1 \
    -o parent=$INTERFACE \
    cassandra_network

cd cassandra-cluster
docker compose up -d
cd ..

sudo ip link add ipvlan-shim link $INTERFACE type ipvlan mode l2
sudo ip addr add 192.168.1.250/24 dev ipvlan-shim
sudo ip link set ipvlan-shim up
sudo ip route add 192.168.1.200 dev ipvlan-shim

