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
api_server_certificate $EXTERNAL_IP ${NODE_IPS}

service_account_keypair

for node in $nodes
do
	kubelet_client_certificates $node
	# scp ca.pem ${instance}-key.pem ${instance}.pem ${node}:~/
	# ssh ${node} bash -c "mv ${node}:ca.crt  /usr/local/share/ca-certificates/kubernetes.crt"
	# ssh ${node} bash -c 'sudo update-ca-certificates'
done

for instance in $controllers
do
	echo $instance
	# scp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
	#   service-account-key.pem service-account.pem ${instance}:~/
done


popd
# clean server
