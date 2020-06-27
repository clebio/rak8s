#!/usr/bin/env bash

if [[ ! "${RESET}x" -eq 'x' ]]; then rm certs/* kubeconfigs/*; fi

./04-create-certs.sh
./05-config-files.sh
./06-encryption-keys.sh
# ./07-etcd.sh

pushd ..
ansible-playbook kthw/install.yaml
popd