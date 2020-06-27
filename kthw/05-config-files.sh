#!/usr/bin/env bash
# set -x
CLUSTER_NAME=bramble
KUBERNETES_PUBLIC_ADDRESS="127.0.0.1"
nodes="bramble4 bramble5 bramble6 bramble7"
controllers="bramble4"

CA_PATH=../certs
CA_PEM=${CA_PATH}/ca.pem

mkdir kubeconfigs
pushd kubeconfigs

create_kube_config() {
	CONTEXT=$1
	PREFIX=$2
	SERVER=$3

	if [[ -e "${PREFIX}.kubeconfig" ]]; then return; fi
	
	kubectl config set-cluster ${CLUSTER_NAME} \
		--certificate-authority=${CA_PEM} \
		--embed-certs=true \
		--server=${SERVER} \
		--kubeconfig=${PREFIX}.kubeconfig

	kubectl config set-credentials $CONTEXT:${PREFIX} \
		--client-certificate=${CA_PATH}/${PREFIX}.pem \
		--client-key=${CA_PATH}/${PREFIX}-key.pem \
		--embed-certs=true \
		--kubeconfig=${PREFIX}.kubeconfig

	kubectl config set-context default \
		--cluster=${CLUSTER_NAME} \
		--user=system:${PREFIX} \
		--kubeconfig=${PREFIX}.kubeconfig

	kubectl config use-context default --kubeconfig=${PREFIX}.kubeconfig
	}



for node in $nodes; do
	create_kube_config system $node "https://${KUBERNETES_PUBLIC_ADDRESS}:6443"
	# create_kube_config system $node "https://${node}:6443"
done

create_kube_config system kube-proxy "https://${KUBERNETES_PUBLIC_ADDRESS}:6443"
create_kube_config system kube-controller-manager "https://127.0.0.1:6443"
create_kube_config system kube-scheduler "https://127.0.0.1:6443"
create_kube_config admin admin "https://127.0.0.1:6443"

# Moved to Ansible playbook:
# for node in $nodes; do
#   echo "Install kubeconfig on $node"
#   # scp ${node}.kubeconfig kube-proxy.kubeconfig ${node}:~/
# done


# for node in $controllers; do
# 	echo "Install kubeconfig on $node"
# 	# scp admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ${node}:~/
# done

popd