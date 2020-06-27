#!/usr/bin/env bash

clean() {
	rm -r ${WORKDIR}/
}

certificate_authority() {
	if [[ -e ${CA_FILE} ]]; then return; fi

	envsubst > ${CONFIG_FILE} <<-EOF
	{
		"signing": {
			"default": {
				"expiry": "8760h"
			},
			"profiles": {
				"kubernetes": {
					"usages": [
						"signing",
						"key encipherment",
						"server auth",
						"client auth"
					],
					"expiry": "8760h"
				}
			}
		}
	}
	EOF

	envsubst > ${CA_PREFIX}-csr.json <<-EOF
	{
		"CN": "kubernetes",
		"key": {
			"algo": "rsa",
			"size": 2048
		},
		"names":[{
			"C": "${COUNTRY}",
			"ST": "${STATE}",
			"L": "${CITY}",
			"O": "${ORG}",
			"OU": "${OU}"
		}]
	}
	EOF

	cfssl gencert -initca ${CA_PREFIX}-csr.json | cfssljson -bare ${CA_PREFIX}
}

admin_client_certificate() {
	OUT_PREFIX=$1
	SERVER_FILE=${OUT_PREFIX}-csr.json
	if [[ -e "${OUT_PREFIX}-key.pem" ]]; then return; fi

	envsubst > ${SERVER_FILE} <<-EOF
	{
		"CN": "admin",
		"key": {
			"algo": "rsa",
			"size": 2048
		},
		"names": [
			{
				"C": "${COUNTRY}",
				"L": "${CITY}",
				"O": "system:masters",
				"OU": "${OU}",
				"ST": "${STATE}"
			}
		]
	}
	EOF

	cfssl gencert \
		-ca=${CA_PREFIX}.pem \
		-ca-key=${CA_PREFIX}-key.pem \
		-config=${CONFIG_FILE} \
		-profile=kubernetes \
		${SERVER_FILE} | cfssljson -bare ${OUT_PREFIX}
}

kubelet_client_certificates() {
	# https://kubernetes.io/docs/reference/access-authn-authz/node/
	node=$1
	if [[ -e "${node}-key.pem" ]]; then return; fi

	echo ">> Creating client certificate for ${node}"

	envsubst > ${node}-csr.json <<-EOF
		{
		"CN": "system:node:${node}",
		"key": {
			"algo": "rsa",
			"size": 2048
		},
		"names": [
			{
				"C": "${COUNTRY}",
				"ST": "${STATE}",
				"L": "${CITY}",
				"O": "system:nodes",
				"OU": "${OU}"
			}
		]
		}
	EOF

	cfssl gencert \
		-ca=${CA_PREFIX}.pem \
		-ca-key=${CA_PREFIX}-key.pem \
		-config=${CONFIG_FILE} \
		-hostname=${node},${EXTERNAL_IP} \
		-profile=kubernetes \
		${node}-csr.json | cfssljson -bare ${node}

}

controller_manager_certificate() {
	PREFIX=kube-controller-manager
	if [[ -e "${PREFIX}-key.pem" ]]; then return; fi
	envsubst > ${PREFIX}-csr.json <<-EOF
		{
		"CN": "system:${PREFIX}",
		"key": {
			"algo": "rsa",
			"size": 2048
		},
		"names": [
			{
				"C": "${COUNTRY}",
				"ST": "${STATE}",
				"L": "${CITY}",
				"OU": "${OU}",
				"O": "system:${PREFIX}"
			}
		]
		}
	EOF

		cfssl gencert \
			-ca=${CA_PREFIX}.pem \
			-ca-key=${CA_PREFIX}-key.pem \
			-config=${CONFIG_FILE} \
			-profile=kubernetes \
			${PREFIX}-csr.json | cfssljson -bare ${PREFIX}

}

proxy_client_certificate() {
	PREFIX=kube-proxy
	if [[ -e "${PREFIX}-key.pem" ]]; then return; fi

	envsubst > ${PREFIX}-csr.json <<-EOF
		{
		"CN": "system:${PREFIX}",
		"key": {
			"algo": "rsa",
			"size": 2048
		},
		"names": [
			{
				"C": "${COUNTRY}",
				"ST": "${STATE}",
				"L": "${CITY}",
				"OU": "${OU}",
				"O": "system:node-proxier"
			}
		]
		}
		EOF

		cfssl gencert \
			-ca=${CA_PREFIX}.pem \
			-ca-key=${CA_PREFIX}-key.pem \
			-config=${CONFIG_FILE} \
			-profile=kubernetes \
			${PREFIX}-csr.json | cfssljson -bare ${PREFIX}

	}

scheduler_client_certificate() {
	PREFIX=kube-scheduler
	if [[ -e "${PREFIX}-key.pem" ]]; then return; fi

	envsubst > ${PREFIX}-csr.json <<-EOF
		{
			"CN": "system:${PREFIX}",
			"key": {
				"algo": "rsa",
				"size": 2048
			},
			"names": [
				{
				"C": "${COUNTRY}",
				"ST": "${STATE}",
				"L": "${CITY}",
				"OU": "${OU}",
				"O": "system:${PREFIX}"
				}
			]
		}
		EOF

		cfssl gencert \
			-ca=${CA_PREFIX}.pem \
			-ca-key=${CA_PREFIX}-key.pem \
			-config=${CONFIG_FILE} \
			-profile=kubernetes \
			${PREFIX}-csr.json | cfssljson -bare ${PREFIX}
}

api_server_certificate () {
	PREFIX=kubernetes
	if [[ -e "${PREFIX}-key.pem" ]]; then return; fi
	KUBERNETES_PUBLIC_ADDRESS=$1
	ADDITIONAL_HOSTNAMES=$2
	KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local

	envsubst > ${PREFIX}-csr.json <<-EOF
	{
		"CN": "${PREFIX}",
		"key": {
			"algo": "rsa",
			"size": 2048
		},
		"names": [
			{
				"C": "${COUNTRY}",
				"ST": "${STATE}",
				"L": "${CITY}",
				"OU": "${OU}"
			}
		]
	}
	EOF

	ALL_HOSTNAMES=${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,${KUBERNETES_HOSTNAMES},${ADDITIONAL_HOSTNAMES}

	cfssl gencert \
		-ca=${CA_PREFIX}.pem \
		-ca-key=${CA_PREFIX}-key.pem \
		-config=${CONFIG_FILE} \
		-hostname=${ALL_HOSTNAMES} \
		-profile=kubernetes \
		${PREFIX}-csr.json | cfssljson -bare ${PREFIX}
}

service_account_keypair() {
	PREFIX=service-account
	if [[ -e "${PREFIX}-key.pem" ]]; then return; fi
	envsubst > ${PREFIX}-csr.json <<-EOF
	{
		"CN": "${PREFIX}s",
		"key": {
			"algo": "rsa",
			"size": 2048
		},
		"names": [
			{
				"C": "${COUNTRY}",
				"ST": "${STATE}",
				"L": "${CITY}",
				"OU": "${OU}"
			}
		]
	}
	EOF

	cfssl gencert \
		-ca=${CA_PREFIX}.pem \
		-ca-key=${CA_PREFIX}-key.pem \
		-config=${CONFIG_FILE} \
		-profile=kubernetes \
		${PREFIX}-csr.json | cfssljson -bare ${PREFIX}
}