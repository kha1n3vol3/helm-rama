# Instructions

- Make a Docker image with python3, java, unzip, and the Rama release archive (e.g. rama-1.1.0.zip) at /home/rama/. See helpers/Dockerfile for a minimal example meeting these requirements (base image ubuntu:24.10 for ARM64).
- Configure k8s to allow swap space. When updating modules, Rama launches a new worker process for the new module instance alongside each existing worker and transitions responsibilities between them. So there's a temporary need for additional memory during this period, and configuring swap space ensures the pod won't run out of memory. See https://kubernetes.io/blog/2023/08/24/swap-linux-beta/
- Zookeeper cluster must be launched separately (e.g. with bitnami zookeeper helm chart)
- zookeeper.servers must be filled in values.yaml with list of all Zookeeper server names
- Persistent volumes must be allocated for each Rama node. It's recommended to have one class for the conductor and another class for the supervisors. This will make it easier on future cluster upgrades when associating the volume with a new pod for the upgraded Rama version.

## Raspberry Pi 5 · Ubuntu 24.10 · Dual-NVMe

Tested on Raspberry Pi 5 (8 GB RAM) running Ubuntu 24.10 with dual NVMe swap and zram. See [pi5.md](pi5.md) for hardware/OS assumptions and detailed instructions.

To automate swap, zram, and kernel tunables setup, run:

```bash
./scripts/pi5-setup.sh
```

To rollback / uninstall changes:

```bash
sudo swapoff /dev/zram0
sudo rm /etc/systemd/zram-generator.conf
sudo systemctl daemon-reload

sudo swapoff /mnt/nvme0/swapfile
sudo rm /mnt/nvme0/swapfile
sudo sed -i '/\/swapfile/d' /etc/fstab
```

## Kubernetes and k3s verification
- Verify that your Raspberry Pi5 (ARM64) node is running Ubuntu 24.10 with k3s installed:
  ```bash
  ./scripts/verify_k3s.sh [REQUIRED_VERSION]
  ```
- Ensure pods are scheduled to ARM64 nodes by setting a nodeSelector:

```bash
helm install rama . --set nodeSelector.kubernetes.io/arch=arm64
```

Or by setting in values.yaml:

```yaml
nodeSelector:
  kubernetes.io/arch: arm64
```

## Default image repository
- The chart defaults to the ARM64 image variant (`rama-arm64`) in values.yaml. Adjust `.Values.image.repository` if using a different registry or architecture.
