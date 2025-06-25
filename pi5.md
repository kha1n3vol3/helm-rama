# Raspberry Pi 5 · Ubuntu 24.10 · Dual-NVMe  
## 32 GB NVMe Swap + Compressed zram Tier

Author-tested: 2025-04-25 (kernel 6.11, systemd 255)  
This README gives you a reliable, reproducible recipe to:

1. Move the installer’s tiny `/swapfile` to an **NVMe-backed 32 GB swapfile**  
2. Add a **fast, compressed zram** layer (¼ × RAM, priority 120)  
3. Apply sane kernel tunables, monitoring and rollback commands

Designed for engineers who will repeat the setup on fresh Pi 5 nodes that run
k3s / CI / dev workloads.

---

## 0.  Hardware / OS assumptions

| Item | Value |
|------|-------|
| Board | Raspberry Pi 5 (8 GB RAM) |
| OS | Ubuntu 24.10 (oracular) |
| Drives | `nvme1` = root (`/`), `nvme0` = free 1 TB ext4 (`/dev/nvme0n1p2`) |
| Kernel | 6.11 or newer (zram builtin) |

If your layout differs, adapt device names and mount-points.

---

## 1.  Why this two-tier swap design?

| Tier | Device | Size | Priority | Purpose |
|------|--------|------|----------|---------|
| 0 | `/dev/zram0` | 25 % of RAM (≈ 2 GiB) | 120 | Ultra-fast “breathing room”, no flash wear |
| 1 | `/mnt/nvme0/swapfile` | 32 GiB | 10 | Large safety net, survives hibernate |

Benefits  
• Keeps latency low: kernel hits zram first, NVMe only when truly needed  
• Extends life of NVMe: zram absorbs short spikes, `discard=pages` trims flash  
• Works well with containerised workloads: OOM-kills still obey cgroup limits

---

## 2.  Pre-flight checks

```bash
echo "== RAM ==";  free -h
echo;             lsblk -o NAME,SIZE,MOUNTPOINT,MODEL | grep -E 'nvme|swap'
echo;             swapon --show
echo;             grep -v '^#' /etc/fstab
```

You should see a 1 GiB `/swapfile` on `nvme1` and an unused `nvme0n1p2`.

---

## 3.  Create & activate the 32 GB NVMe swapfile

```bash
# 3.1  Mount spare partition (persistent)
sudo mkdir -p /mnt/nvme0
sudo mount /dev/nvme0n1p2 /mnt/nvme0
grep -q '/dev/nvme0n1p2' /etc/fstab || \
echo '/dev/nvme0n1p2 /mnt/nvme0 ext4 defaults 0 2' | sudo tee -a /etc/fstab

# 3.2  Create swapfile
sudo fallocate -l 32G /mnt/nvme0/swapfile
sudo chmod 600       /mnt/nvme0/swapfile
sudo mkswap          /mnt/nvme0/swapfile

# 3.3  Activate with discard + priority
sudo swapon --discard=pages --priority 10 /mnt/nvme0/swapfile

# 3.4  Persist in fstab
echo '/mnt/nvme0/swapfile none swap sw,pri=10,discard=pages 0 0' \
| sudo tee -a /etc/fstab

# 3.5  Remove the old 1 GB swapfile
sudo swapoff /swapfile
sudo rm      /swapfile
sudo sed -i '/\/swapfile/d' /etc/fstab
```

---

## 4.  Add fast compressed zram (systemd-zram-generator)

```bash
sudo apt update
sudo apt install systemd-zram-generator   # ~30 kB, pulls no daemons
```

Create strict, comment-free config:

```bash
sudo tee /etc/systemd/zram-generator.conf >/dev/null <<'EOF'
[zram0]
zram-size = ram / 4
compression-algorithm = lz4
swap-priority = 120
EOF
```

Load now (or simply reboot):

```bash
sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0.service
```

Note: no `enable` needed—generator auto-creates the device every boot.

---

## 5.  Kernel tunables (optional but recommended)

```bash
sudo tee /etc/sysctl.d/99-swap.conf >/dev/null <<'EOF'
vm.swappiness=30          # prefer RAM/zram, still allow NVMe under pressure
vm.vfs_cache_pressure=50  # keep FS metadata hot (good for overlayfs layers)
EOF
sudo sysctl -p /etc/sysctl.d/99-swap.conf
```

Adjust `vm.swappiness` to 40-60 if you want the kernel to enter zram sooner.

---

## 6.  Verification script

```bash
echo "===== free =====";        free -h
echo;                          swapon --show=NAME,TYPE,SIZE,USED,PRIO --bytes
echo;                          grep -E 'swapfile|nvme0n1p2|zram' /etc/fstab
```

Expected:

```
NAME                 TYPE        SIZE        USED PRIO
/dev/zram0           partition   ≈2079 MB        0  120
/mnt/nvme0/swapfile  file        34359734272   <20 MB  10
```

No `/swapfile` entry in `fstab`.

Reboot once and re-run the script to confirm persistence.

---

## 7.  Monitoring & testing

Real-time:

```bash
watch -n 2 'free -h && echo && swapon --show=NAME,SIZE,USED,PRIO'
```

Stress test (optional):

```bash
sudo apt install stress-ng
stress-ng --vm 1 --vm-bytes 6G --timeout 120s
```

Wear/I-O stats:

```bash
sudo apt install iotop
sudo iotop -ao            # cumulative writes per process
```

---

## 8.  Troubleshooting quick table

| Problem | Command | Fix |
|---------|---------|-----|
| zram unit fails | `journalctl -xeu systemd-zram-setup@zram0` | Check for syntax errors in `.conf`, ensure `modprobe zram` works |
| Wrong priority order | `swapon --show=…PRIO` | Edit `pri=` or `swap-priority` & `swapoff + swapon` |
| “busy” error when re-adding options | `sudo swapoff <device>` | Re-enable with new flags or edit `/etc/fstab` |

---

## 9.  swapon cheat-sheet

```bash
# Show swap with priorities (bytes):
swapon --show=NAME,TYPE,SIZE,USED,PRIO --bytes

# Activate a device with options (when currently OFF):
sudo swapon --discard=pages --priority 10 /mnt/nvme0/swapfile

# Deactivate temporarily:
sudo swapoff /dev/zram0
```

fstab exemplar:

```
/mnt/nvme0/swapfile none swap sw,pri=10,discard=pages 0 0
/dev/zram0          none swap defaults,pri=120         0 0
```

---

## 10.  Rollback / uninstall

```bash
# Remove zram
sudo swapoff /dev/zram0
sudo rm /etc/systemd/zram-generator.conf
sudo systemctl daemon-reload

# Remove NVMe swapfile
sudo swapoff /mnt/nvme0/swapfile
sudo rm      /mnt/nvme0/swapfile
sudo sed -i '/swapfile/d' /etc/fstab
```

---

### Your Raspberry Pi 5 is now ready for k3s – happy clustering! 🚀
