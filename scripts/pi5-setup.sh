#!/usr/bin/env bash
set -euo pipefail

# pi5-setup.sh: Configure NVMe swap, compressed zram, and kernel tunables on Raspberry Pi 5 (8GB RAM) running Ubuntu 24.10.

usage() {
  cat <<EOF
Usage: $0
This script configures:
  - Mount /dev/nvme0n1p2 to /mnt/nvme0 and creates a 32G NVMe-backed swapfile
  - Configures systemd-zram-generator for a zram device (~RAM/4)
  - Applies kernel sysctl tunables for vm.swappiness and vfs cache pressure
  - Verifies the swap and zram setup

Ensure /dev/nvme0n1p2 exists and is formatted as ext4. Run with sudo privileges when prompted.
EOF
  exit 1
}

if [[ "${1:-}" =~ ^-h|--help$ ]]; then
  usage
fi

echo "== Pre-flight checks =="
free -h
echo
lsblk -o NAME,SIZE,MOUNTPOINT,MODEL | grep -E 'nvme|swap' || true
echo
swapon --show=NAME,TYPE,SIZE,USED,PRIO --bytes || true
echo
grep -v '^#' /etc/fstab || true

echo "== Mount spare NVMe partition =="
sudo mkdir -p /mnt/nvme0
sudo mount /dev/nvme0n1p2 /mnt/nvme0
if ! grep -q '/dev/nvme0n1p2' /etc/fstab; then
  echo '/dev/nvme0n1p2 /mnt/nvme0 ext4 defaults 0 2' | sudo tee -a /etc/fstab
fi

echo "== Create & enable NVMe swapfile =="
sudo fallocate -l 32G /mnt/nvme0/swapfile
sudo chmod 600 /mnt/nvme0/swapfile
sudo mkswap /mnt/nvme0/swapfile
sudo swapon --discard=pages --priority 10 /mnt/nvme0/swapfile
if ! grep -q '/mnt/nvme0/swapfile' /etc/fstab; then
  echo '/mnt/nvme0/swapfile none swap sw,pri=10,discard=pages 0 0' | sudo tee -a /etc/fstab
fi

echo "== Remove default swapfile =="
sudo swapoff /swapfile || true
sudo rm -f /swapfile
sudo sed -i '/\/swapfile/d' /etc/fstab

echo "== Install & configure systemd-zram-generator =="
sudo apt update
sudo apt install -y systemd-zram-generator
sudo tee /etc/systemd/zram-generator.conf > /dev/null 
[zram0]
zram-size = ram / 4
compression-algorithm = lz4
swap-priority = 120
EOF
sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0.service

echo "== Apply kernel tunables =="
sudo tee /etc/sysctl.d/99-swap.conf > /dev/null <<'EOF'
vm.swappiness=30
vm.vfs_cache_pressure=50
EOF
sudo sysctl -p /etc/sysctl.d/99-swap.conf

echo "== Verification =="
echo "===== free ====="
free -h
echo
swapon --show=NAME,TYPE,SIZE,USED,PRIO --bytes
echo
grep -E 'swapfile|nvme0n1p2|zram' /etc/fstab

echo
echo "Setup complete. Reboot and re-run verification to confirm persistence."

exit 0