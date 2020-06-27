#!/usr/bin/env bash

controllers=""

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)


cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

for node in $controllers; do
  echo "Copy encryption config to $node"
	scp encryption-config.yaml ${node}:~/
done