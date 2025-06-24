# Instructions

- Make a Docker image with python3, java, unzip, and the Rama release archive (e.g. rama-1.1.0.zip) at /home/rama/. See helpers/Dockerfile for a minimal example meeting these requirements (base image ubuntu:24.10 for ARM64).
- Configure k8s to allow swap space. When updating modules, Rama launches a new worker process for the new module instance alongside each existing worker and transitions responsibilities between them. So there's a temporary need for additional memory during this period, and configuring swap space ensures the pod won't run out of memory. See https://kubernetes.io/blog/2023/08/24/swap-linux-beta/
- Zookeeper cluster must be launched separately (e.g. with bitnami zookeeper helm chart)
- zookeeper.servers must be filled in values.yaml with list of all Zookeeper server names
- Persistent volumes must be allocated for each Rama node. It's recommended to have one class for the conductor and another class for the supervisors. This will make it easier on future cluster upgrades when associating the volume with a new pod for the upgraded Rama version.

## Kubernetes and k3s verification
- Verify that your Raspberry Pi5 (ARM64) node is running Ubuntu 24.10 with k3s installed:
  ```bash
  ./scripts/verify_k3s.sh [REQUIRED_VERSION]
  ```
- Ensure pods are scheduled to ARM64 nodes by setting:
  ```bash
  helm install rama . --set nodeSelector.kubernetes.io/arch=arm64
  ```

## Default image repository
- The chart defaults to the ARM64 image variant (`rama-arm64`) in values.yaml. Adjust `.Values.image.repository` if using a different registry or architecture.
