#!/usr/bin/env bash

ETCD_VER=v3.4.0
ARCH=arm64
wget -q --show-progress --https-only --timestamping \
	"https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-${ARCH}.tar.gz"


tar -xvf etcd-${ETCD_VER}-linux-${ARCH}.tar.gz
sudo mv etcd-${ETCD_VER}-linux-${ARCH}/etcd* /usr/local/bin/

sudo mkdir -p /etc/etcd /var/lib/etcd
sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/

INTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" \
	http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)

ETCD_NAME=$(hostname -s)

# sudo systemctl daemon-reload
# sudo systemctl enable etcd
# sudo systemctl start etcd

# sudo ETCDCTL_API=3 etcdctl member list \
# 	--endpoints=https://127.0.0.1:2379 \
# 	--cacert=/etc/etcd/ca.pem \
# 	--cert=/etc/etcd/kubernetes.pem \
# 	--key=/etc/etcd/kubernetes-key.pem
