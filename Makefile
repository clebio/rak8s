.phone: install,run

install:
	ansible-playbook -l all cluster.yml --tags "all,provision"

run:
	ansible-playbook -l all cluster.yml