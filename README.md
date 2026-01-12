# Sovereign AI on NVIDIA DGX Spark

Deploy a local, sovereign AI stack on NVIDIA DGX Spark using k3s, vLLM, and Open WebUI.

![NVIDIA DGX Spark](https://img.shields.io/badge/NVIDIA-DGX%20Spark-76B900?style=flat&logo=nvidia)
![Kubernetes](https://img.shields.io/badge/k3s-v1.34-326CE5?style=flat&logo=kubernetes)
![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)

## Overview

This project provides a complete guide for deploying Mistral 7B (or other LLMs) on NVIDIA DGX Spark hardware using:

- **k3s** — Lightweight Kubernetes distribution
- **NVIDIA GPU Operator** — Automated GPU management for Kubernetes
- **vLLM** — High-performance LLM inference engine
- **Open WebUI** — ChatGPT-style interface for local models

### Hardware

| Component | Specification |
|-----------|---------------|
| Platform | NVIDIA DGX Spark |
| GPU | NVIDIA GB10 (Blackwell) |
| Architecture | ARM64 |
| OS | Ubuntu 24.04 |
| CUDA | 13.0 |
| Driver | 580.95.05 |

## Prerequisites

Before starting, verify your GPU setup:

```bash
# Driver check
nvidia-smi

# Container toolkit check
nvidia-container-cli info
```

Both commands must succeed before proceeding.

## Quick Start

### 1. Install k3s

```bash
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

Verify:
```bash
kubectl get nodes
# Should show node as "Ready"

grep nvidia /var/lib/rancher/k3s/agent/etc/containerd/config.toml
# Should show nvidia runtime entries
```

### 2. Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### 3. Install NVIDIA GPU Operator

```bash
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update

helm install gpu-operator nvidia/gpu-operator \
  --namespace gpu-operator \
  --create-namespace \
  --set driver.enabled=false \
  --set toolkit.env[0].name=CONTAINERD_CONFIG \
  --set toolkit.env[0].value=/var/lib/rancher/k3s/agent/etc/containerd/config.toml \
  --set toolkit.env[1].name=CONTAINERD_SOCKET \
  --set toolkit.env[1].value=/run/k3s/containerd/containerd.sock
```

Wait for all pods to be ready (~2-5 minutes):
```bash
kubectl get pods -n gpu-operator -w
```

Verify GPU is exposed to Kubernetes:
```bash
kubectl get nodes -o json | jq '.items[].status.allocatable'
# Should show: "nvidia.com/gpu": "1"
```

### 4. Deploy vLLM with Mistral 7B

Create namespace and resources:

```bash
kubectl create ns llm
```

#### PersistentVolumeClaim for model cache

```yaml
# manifests/01-hf-cache-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: hf-cache
  namespace: llm
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 50Gi
```

```bash
kubectl apply -f manifests/01-hf-cache-pvc.yaml
```

#### HuggingFace Token Secret

Get your token from https://huggingface.co/settings/tokens (required for gated models like Mistral).

```bash
kubectl -n llm create secret generic hf-token \
  --from-literal=token=hf_YOUR_TOKEN_HERE
```

#### vLLM Deployment

> **Important for DGX Spark:** Use `--gpu-memory-utilization=0.7` to avoid OOM errors on unified memory architecture.

```yaml
# manifests/02-mistral-vllm.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mistral
  namespace: llm
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mistral
  template:
    metadata:
      labels:
        app: mistral
    spec:
      runtimeClassName: nvidia
      volumes:
      - name: hf-cache
        persistentVolumeClaim:
          claimName: hf-cache
      - name: shm
        emptyDir:
          medium: Memory
          sizeLimit: 2Gi
      containers:
      - name: vllm
        image: nvcr.io/nvidia/vllm:25.11-py3
        command: ["vllm", "serve"]
        args:
        - "mistralai/Mistral-7B-Instruct-v0.3"
        - "--host=0.0.0.0"
        - "--max-model-len=8192"
        - "--gpu-memory-utilization=0.7"
        env:
        - name: HF_TOKEN
          valueFrom:
            secretKeyRef:
              name: hf-token
              key: token
        ports:
        - containerPort: 8000
        resources:
          limits:
            nvidia.com/gpu: 1
            memory: 24Gi
          requests:
            nvidia.com/gpu: 1
            memory: 12Gi
        volumeMounts:
        - name: hf-cache
          mountPath: /root/.cache/huggingface
        - name: shm
          mountPath: /dev/shm
---
apiVersion: v1
kind: Service
metadata:
  name: mistral
  namespace: llm
spec:
  selector:
    app: mistral
  ports:
  - port: 8000
    targetPort: 8000
```

```bash
kubectl apply -f manifests/02-mistral-vllm.yaml
kubectl -n llm get pods -w
```

First startup takes 15-30 minutes (image pull + model download + CUDA graph compilation).

#### Test the API

```bash
kubectl -n llm port-forward svc/mistral 8000:8000
```

```bash
curl http://127.0.0.1:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model":"mistralai/Mistral-7B-Instruct-v0.3",
    "messages":[{"role":"user","content":"Say hello in one sentence."}],
    "max_tokens":50
  }'
```

### 5. Deploy Open WebUI

```yaml
# manifests/10-openwebui.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ui
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: openwebui-data
  namespace: ui
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: openwebui
  namespace: ui
spec:
  replicas: 1
  selector:
    matchLabels:
      app: openwebui
  template:
    metadata:
      labels:
        app: openwebui
    spec:
      containers:
      - name: openwebui
        image: ghcr.io/open-webui/open-webui:main
        ports:
        - containerPort: 8080
        env:
        - name: WEBUI_SECRET_KEY
          value: "change-me-in-production"
        volumeMounts:
        - name: data
          mountPath: /app/backend/data
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: openwebui-data
---
apiVersion: v1
kind: Service
metadata:
  name: openwebui
  namespace: ui
spec:
  selector:
    app: openwebui
  ports:
  - port: 80
    targetPort: 8080
```

```bash
kubectl apply -f manifests/10-openwebui.yaml
kubectl -n ui get pods -w
```

Access the UI:
```bash
kubectl -n ui port-forward svc/openwebui 8080:80
```

Open http://127.0.0.1:8080 in your browser.

#### Configure Open WebUI

1. Create an admin account (first user)
2. Go to **Admin Panel → Settings → Connections**
3. Under **OpenAI API**, click **+** to add connection:
   - **URL:** `http://mistral.llm.svc.cluster.local:8000/v1`
   - **API Key:** `sk-dummy` (vLLM doesn't require auth)
4. Click **Save** and refresh the page
5. Select `mistralai/Mistral-7B-Instruct-v0.3` from the model dropdown

## Demo

### Backend - vLLM serving Mistral 7B

<video src="https://github.com/zalborzi/sovereign-ai-dgx-spark/raw/main/demo/Back.webm" controls width="100%"></video>

### Frontend - Open WebUI

<video src="https://github.com/zalborzi/sovereign-ai-dgx-spark/raw/main/demo/Front.webm" controls width="100%"></video>

## Project Structure

```
sovereign-ai-dgx-spark/
├── README.md
├── manifests/
│   ├── 00-gpu-smoke.yaml          # GPU sanity test pod
│   ├── 01-hf-cache-pvc.yaml       # Model cache storage
│   ├── 02-mistral-vllm.yaml       # vLLM deployment
│   └── 10-openwebui.yaml          # Open WebUI deployment
└── scripts/
    └── cleanup.sh                  # Full cleanup script
```

## Troubleshooting

### GPU not visible in Kubernetes

```bash
# Check GPU Operator pods
kubectl get pods -n gpu-operator

# Check node labels
kubectl get node --show-labels | tr ',' '\n' | grep nvidia

# Verify nvidia.com/gpu in allocatable
kubectl get nodes -o json | jq '.items[].status.allocatable'
```

### vLLM pod stuck in ContainerCreating

```bash
# Check events
kubectl -n llm describe pod -l app=mistral

# Image pull takes 10-15 minutes for the first time (~6GB image)
```

### vLLM OOM errors

DGX Spark has unified memory. Reduce GPU memory utilization:
```yaml
args:
  - "--gpu-memory-utilization=0.6"  # Try lower values
```

### Model download progress

```bash
kubectl -n llm exec deployment/mistral -- du -sh /root/.cache/huggingface/
```

### Open WebUI can't connect to vLLM

Verify internal DNS works:
```bash
kubectl -n ui exec deployment/openwebui -- \
  curl -s http://mistral.llm.svc.cluster.local:8000/v1/models
```

## Cleanup

To completely remove everything:

```bash
# Uninstall k3s (removes all Kubernetes resources)
/usr/local/bin/k3s-uninstall.sh

# Remove Helm
sudo rm -f /usr/local/bin/helm

# Clean up directories
sudo rm -rf /etc/rancher /var/lib/rancher
rm -rf ~/.config/helm ~/.cache/helm ~/.kube

# Remove project files
rm -rf ~/sovereign-ai-dgx-spark
```

## DGX Spark-Specific Notes

From [NVIDIA vLLM Release Notes](https://docs.nvidia.com/deeplearning/frameworks/vllm-release-notes/):

> vllm serve uses aggressive GPU memory allocation by default. On systems with shared/unified GPU memory (e.g. DGX Spark or Jetson platforms), this can lead to out-of-memory errors. Use `--gpu-memory-utilization 0.7` or lower.

> On DGX Spark, workloads utilizing FP8 models may fail with CUDA stream capture errors due to illegal synchronization operations in FlashInfer kernels.

## References

- [k3s Documentation](https://docs.k3s.io/)
- [k3s NVIDIA Container Runtime Support](https://docs.k3s.io/advanced#nvidia-container-runtime)
- [NVIDIA GPU Operator](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/getting-started.html)
- [vLLM Documentation](https://docs.vllm.ai/)
- [Open WebUI](https://github.com/open-webui/open-webui)

## License

Apache License 2.0 — see [LICENSE](LICENSE) for details.

## Author

Zia — NTT DATA Luxembourg
