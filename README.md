# Kubernetes on Rasberry Pi

A cluster of Raspberry Pis (a [bramble][]*) running Kubernetes (k8s), provisioned via Ansible.

![Meatspace cluster](bramble.jpg)

## Prerequisites

### Hardware

* Three or more Raspberry Pi 3 or 4
  * For the master node(s), I strongly recommend a Pi with at least 2GB RAM
* Class 10 SD Cards
* [Power](https://www.amazon.com/gp/product/B00P936188), [space](https://www.amazon.com/gp/product/B07MW24S61) and cooling
* Network switch and short ethernet cables
* Network connection

### Software

* [Raspbian](https://www.raspberrypi.org/downloads/raspbian/) (installed on each Raspberry Pi)
* Raspberry Pis should have static IPs
    * Requirement for Kubernetes and Ansible inventory
    * You can set these via OS configuration or DHCP reservations (your choice)
* Ability to SSH into all Raspberry Pis and escalate privileges with sudo
    * The pi user is fine just change its password
* [Ansible](http://docs.ansible.com/ansible/latest/intro_installation.html) 2.2 or higher
* [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/) should be available on the system you intend to use to interact with the Kubernetes cluster.
    * If you are going to login to one of the Raspberry Pis to interact with the cluster `kubectl` is installed and configured by default on the master Kubernetes master.
    * If you are administering the cluster from a remote machine (your laptop, desktop, server, bastion host, etc.) `kubectl` will not be installed on the remote machine but it will be configured to interact with the newly built cluster once `kubectl` is installed.
* Setup SSH key pairs so your password is not required every time Ansible runs

## Usage

Clone the repo

    git clone git@github.com:clebio/k8s-bramble.git

Modify the `inventory` file to suit your environment. Change the names
to your liking and the IPs to the addresses of your Raspberry Pis. If
your SSH user on the Raspberry Pis are not the Raspbian default `pi`
user modify `remote_user` in the `ansible.cfg`.

Confirm Ansible is working with your Raspberry Pis:

    ansible -m ping all

Configure the cluster:

    ansible-playbook cluster.yml

Set your kubeconfig (the config file is fetched in `cluster.yml` though):

    ansible bramble4 -m fetch -a 'src=/etc/kubernetes/admin.conf dest=./kube.config'
    export KUBECONFIG=kube.config/bramble4/etc/kubernetes/admin.conf
    kubectl cluster-info

Test your Kubernetes cluster is up and running:

    kubectl get nodes

To power the whole thing down,

    ansible all -m command -a shutdown

## Kubernetes manifests

Once you have a working cluster, there are a few resources I recommend installing:

[MetalLB][metallb] provides a standard LoadBalancer service:

    kubectl apply -f manifests/metallb.yaml -f mainfests/metallb-config.yaml

I use the [NFS client example][nfs-client] to provide persistent volume claims (PVC) via my Synology NAS:

    kubectl apply -f manifests/nfs-client.yaml

## References & Credits

These playbooks were assembled using a handful of very helpful guides:

* Thanks to [Jeff Geerling for the "bramble" reference][geerling].
* This repo is derived from [rak8s](https://github.com/rak8s/rak8s).
* [K8s on (vanilla) Raspbian Lite](https://gist.github.com/alexellis/fdbc90de7691a1b9edb545c17da2d975) by [Alex Ellis](https://www.alexellis.io/)
* [Installing kubeadm](https://kubernetes.io/docs/setup/independent/install-kubeadm/)
* [kubernetes/dashboard - Access control - Admin privileges](https://github.com/kubernetes/dashboard/wiki/Access-control#admin-privileges)
* [Install using the convenience script](https://docs.docker.com/engine/installation/linux/docker-ce/debian/#install-using-the-convenience-script)
* A very special thanks to [**Alex Ellis**](https://www.alexellis.io/) and the [OpenFaaS](https://www.openfaas.com/) community for their assitance in answering questions and making sense of some errors.

[bramble]: https://elinux.org/Bramble
[geerling]: https://www.jeffgeerling.com/project/raspberry-pi-dramble
[metallb]: https://metallb.universe.tf/
[nfs-client]: https://github.com/kubernetes-incubator/external-storage/tree/master/nfs-client

# Nomad

Everything in thie repository related to the Hashistack is a fork of [Timothy Perrett's hashpi repo][haspi]. I've merged that entire repo into this one via `--allow-unrelated-histories`. The following is borrowed from that repo's readme.

[haspi]: https://github.com/timperrett/hashpi

These instructions assume you are running *Raspbian Lite*, Jesse or later (this requires [systemd](https://www.freedesktop.org/wiki/Software/systemd/)). You can download [Raspbian Lite from here](https://www.raspberrypi.org/downloads/raspbian/), and I would strongly recomend checking out resin.io [Ether](https://etcher.io/) for a quick and convenient way to flash your SD cards from OSX, with the vanilla Raspbian image you are downloading.

There is a set of initial setup that must be done manually to get the Pi's accessible remotely (and availalbe for automatic provisioning). I used the following steps to get the nodes going:

```
# set a new root password
$ sudo passwd root
<enter new password>

# set your the password for the `pi` user
$ sudo passwd pi
<enter new password>

$ sudo reboot

# update the system, disable avahi and bluetooth
$ sudo systemctl enable ssh && \
  sudo systemctl start ssh

# optionally install a few useful utilities
$ sudo apt-get install -y htop

```

Now we have our four Pi's running SSH and have disabled the features we wont be using in this cluster build out (e.g. bluetooth). Now we are ready to deploy the bulk of the software! This repo makes use of [Ansible](https://www.ansible.com/) as its provisioning system; in order to automate the vast majority of operations we conduct on the cluster. This makes them repeatable and testable. Please checkout the Ansible documentation if you are not familiar with the tool.

#### Bootstrap Playbook

The bootstrap playbook setups up core functionality so that we can run more complicated playbooks on the Pis themselves, and also get access to the cluster nodes without having to SSH with an explicit username and password (add your key to the `user` roles `vars` file). After first turning on the cluster and enabling SSH, the following should be executed in the root of the repository:

```
./bootstrap.yml
```

This mainly kills avahai-daemon and several other processes we will not be needing, going forward.

#### Site Playbook

Once you've bootstrapped your cluster and you can SSH into the nodes with your key, then we can simply run the ansible site plays, and let it install all the nessicary gubbins.

```
./site.yml
```

Any other time you update the cluster using the `site.yml` playbook, be sure to run with the following option:

```
./site.yml --skip-tags=consul-servers,bootstrap
```

This will ensure that the consul servers used to corrdinate everything don't get screwed up during the deployment of new software.

This set of playbooks installs the following software (in order).

+ Debugging Utils (htop, nslookup, telnet etc)
+ [Consul](https://www.consul.io/) (runs on 3 nodes as a quorum)
+ [Vault](https://www.vaultproject.io/) (uses Consul as its secure backend; runs on rpi01)
+ [Nomad](https://www.nomadproject.io/) (only rpi01 has the `server` component of Nomad installed)
+ [Prometheus](https://prometheus.io) (only runs on rpi01)
+ [Grafana](http://grafana.org/)
+ [Docker](https://docker.com/)

Whilst the setup is vastly automated, there are a few manual steps. When first installing Vault, there is a set of keys that are generated which cannot be automated away, because they are required for vault initialization. The steps to first setup the vault are [documented in this blog post](https://www.vaultproject.io/intro/getting-started/deploy.html) but the TL;DR is:

```
$ ssh pi@<baron-ip>
$ export VAULT_ADDR="http://`ip -4 route get 8.8.8.8 | awk '{print $7}' | xargs echo -n`:8200"
$ vault init

# be sure to keep the generated keys in a safe place, and absolutely do not check them in anywhere!

$ vault -tls-skip-verify unseal

```
