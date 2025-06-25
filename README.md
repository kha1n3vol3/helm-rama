# Instructions

## Refactoring Plan

For details on the refactoring plan, prerequisites, and milestones, see [docs/REFRACTOR_PLAN.md](docs/REFRACTOR_PLAN.md).

- Build a container image (ARM64/ubuntu:24.10) that includes python3, java, unzip, and the Rama release archive (v1.1.0) in `/home/rama/`, and adds a non-root user `rama`. See `helpers/Dockerfile` for a minimal example. You can use Docker or Podman. On Ubuntu, install Podman with:

```bash
sudo apt-get update && sudo apt-get install -y podman
```

To build with Docker or Podman:

```bash
docker build -t rama-arm64 -f helpers/Dockerfile .
# or
podman build -t rama-arm64 -f helpers/Dockerfile .
```
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
To verify your Raspberry Pi 5 (ARM64) node is running Ubuntu 24.10 with k3s installed and meets a version requirement, run:

```bash
# Default: verify against the current k3s version
./scripts/verify_k3s.sh
# Or to test a legacy prefix:
./scripts/verify_k3s.sh v1.20.0
```

### Configure kubectl

```bash
# Copy k3s kubeconfig into your home directory (run once):
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
# Point kubectl/helm to the new config:
export KUBECONFIG=$HOME/.kube/config
```

### Install the chart

Run Helm as your regular user (not via sudo) so it picks up your kubeconfig:

```bash
# Note: override k3s.minVersion to a valid version string (default "1.x.y" is a placeholder).
helm upgrade --install rama . \
  --set nodeSelector."kubernetes\\.io/arch"=arm64 \
  --set k3s.minVersion="$(k3s --version | head -n1 | awk '{print $3}')"
```

Alternatively, set the nodeSelector in values.yaml:

```yaml
nodeSelector:
  kubernetes.io/arch: arm64
```

## Default image repository
- The chart defaults to the ARM64 image variant (`rama-arm64`) in values.yaml. Adjust `.Values.image.repository` if using a different registry or architecture.

## Action Items for K3s Deployment on ARM64

- **Prepare Pi5 nodes**: Run the Pi5 setup script to configure NVMe swap, zram, and kernel tunables:

```bash
./scripts/pi5-setup.sh
```

- **Verify k3s installation**: Ensure k3s is installed and meets a version requirement (defaults to the current version; pass a legacy prefix to test an older requirement):

```bash
# Default (current version):
./scripts/verify_k3s.sh

# Or to test a legacy version:
./scripts/verify_k3s.sh v1.20.0
```

- **Configure kubectl**: Ensure Helm and kubectl can reach your k3s API server:

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

To make this permanent for your user (so you don't have to export every shell), copy the file:

```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
# Update your KUBECONFIG to point to the new config file
export KUBECONFIG=$HOME/.kube/config
```

- **Run as non-root**: Ensure Helm runs as your normal user (so $KUBECONFIG is respected); do not prefix with sudo.
- **Deploy the chart**: Install the Rama Helm chart with ARM64 nodeSelector and k3s version gating (set to current or legacy version prefix):

```bash
# Default (current version):
helm install rama . \
  --set nodeSelector."kubernetes\\.io/arch"=arm64 \
  --set k3s.minVersion=$(k3s --version | head -n1 | awk '{print $3}')

# Or to test a legacy version:
helm install rama . \
  --set nodeSelector."kubernetes\\.io/arch"=arm64 \
  --set k3s.minVersion=v1.20.0
```

- **Confirm scheduling**: Ensure pods are running on ARM64 nodes:

```bash
kubectl get pods -l app=rama -o wide
```

- **Monitor resources**: Watch memory and swap usage on nodes:

```bash
watch -n 2 'free -h && swapon --show=NAME,SIZE,USED,PRIO'
```
