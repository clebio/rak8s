#!/usr/bin/env bash

set -x
# https://kubernetes.io/docs/concepts/cluster-administration/certificates/


CONFIG_FILE=config.json
CA_PREFIX=ca
CA_FILE=${CA_PREFIX}.csr
EXTERNAL_IP=${K8S_IP:-127.0.0.1}

. methods-certs.sh
. env.sh

WORKDIR=certs
mkdir ${WORKDIR}
pushd ${WORKDIR}


certificate_authority
admin_client_certificate admin
controller_manager_certificate
proxy_client_certificate	
scheduler_client_certificate


# for node in $nodes; do NODE_IPS=$NODE_IPS:${node["ip"]}; done
NODE_IPS=172.16.11.204,172.16.11.205,172.16.11.206,172.16.11.207
api_server_certificate $EXTERNAL_IP $NODE_IPS,$(echo $nodes |  tr ' ' ',')

service_account_keypair

for node in $nodes
do
	kubelet_client_certificates $node
done




popd
# clean server
