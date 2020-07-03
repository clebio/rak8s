# Let's script Kubernetes the Hard Way

Based directly upon [Kubernetes the Hard Way][kthw]

[kthw]: https://github.com/kelseyhightower/kubernetes-the-hard-way

## Prerequisites

The default Raspbian image is 32bit, ARMv7. The Pi 4 architecture is [ARMv8][spec], but in order to make use of that, you'll need the [beta ARMv8 OS image][beta]. This is necessary because the container binaries we use are built for ARMv8.

It [might be possible][1947] to [compile for ARMv7][compiling], but building `runc` requires Go 1.13, which wants v8. Here be dragons.

[compiling]: https://github.com/containerd/containerd/blob/master/BUILDING.md#build-runc
[1947]: https://github.com/opencontainers/runc/issues/1947
[spec]: https://www.raspberrypi.org/products/raspberry-pi-4-model-b/specifications/
[beta]: https://www.raspberrypi.org/forums/viewtopic.php?f=117&t=275370

## Scratch Notes

* https://github.com/containerd/containerd/issues/3664

wget -q --show-progress --https-only --timestamping \
  https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.15.0/crictl-v1.15.0-linux-arm.tar.gz \
  https://github.com/opencontainers/runc/releases/download/v1.0.0-rc8/runc.arm \
  https://github.com/containernetworking/plugins/releases/download/v0.8.2/cni-plugins-linux-arm-v0.8.2.tgz \
  https://github.com/containerd/containerd/suites/870991982/artifacts/10127877 \
  https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/arm/kubectl \
  https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/arm/kube-proxy \
  https://storage.googleapis.com/kubernetes-release/release/v1.15.3/bin/linux/arm/kubelet

## Using

```bash
# Set environment
export nodes="bramble4 bramble5 bramble6 bramble7"
export controllers="bramble4"

run.sh
```