# Architecture

This document explains the architecture of the **Sovereign AI on NVIDIA DGX Spark** demo.

The goal is to run a local AI assistant stack on NVIDIA DGX Spark with:

- **k3s** for lightweight local Kubernetes
- **NVIDIA GPU Operator** for GPU exposure inside Kubernetes
- **vLLM** for OpenAI-compatible model serving
- **Open WebUI** for the browser-based chat interface
- optional reusable demo scenarios such as finance RAG access control and a weather tool agent

The architecture is intentionally simple. It is designed for local demos, learning, and sovereign AI experimentation on DGX Spark. It is not a hardened production architecture.

---

## 1. High-level architecture

```text
User Browser
    |
    | http://dgx-demo.test:18080
    |
Local kubectl port-forward
    |
    v
Open WebUI Service
    |
    | OpenAI-compatible API
    | http://mistral.llm.svc.cluster.local:8000/v1
    |
    v
vLLM Service
    |
    v
Mistral 7B Instruct
    |
    v
NVIDIA GB10 GPU
```

---

## 2. Main components

### 2.1 NVIDIA DGX Spark

The hardware platform provides:

- NVIDIA GB10 GPU
- ARM64 architecture
- Ubuntu 24.04
- NVIDIA driver and CUDA stack
- local compute for LLM inference

DGX Spark uses a unified/shared memory architecture. vLLM can allocate GPU memory aggressively, so the deployment uses a lower GPU memory utilization setting.

Recommended setting:

```yaml
- "--gpu-memory-utilization=0.7"
```

If the pod crashes with memory pressure, reduce it:

```yaml
- "--gpu-memory-utilization=0.6"
```

---

### 2.2 k3s

k3s provides the local Kubernetes layer.

It is used for:

- namespaces
- deployments
- services
- persistent volumes
- container runtime integration

Default kubeconfig:

```text
/etc/rancher/k3s/k3s.yaml
```

The scripts use:

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

---

### 2.3 NVIDIA GPU Operator

The NVIDIA GPU Operator exposes the DGX Spark GPU to Kubernetes.

vLLM requests the GPU using:

```yaml
resources:
  limits:
    nvidia.com/gpu: 1
  requests:
    nvidia.com/gpu: 1
```

The vLLM pod also uses:

```yaml
runtimeClassName: nvidia
```

Verify GPU availability:

```bash
kubectl get nodes -o json | jq '.items[].status.allocatable'
```

Expected output includes:

```json
"nvidia.com/gpu": "1"
```

---

### 2.4 vLLM

vLLM serves the local model through an OpenAI-compatible API.

Namespace:

```text
llm
```

Deployment:

```text
mistral
```

Service:

```text
mistral
```

Internal URL:

```text
http://mistral.llm.svc.cluster.local:8000/v1
```

Default model:

```text
mistralai/Mistral-7B-Instruct-v0.3
```

Important DGX Spark settings:

```yaml
replicas: 1

strategy:
  type: Recreate
```

`Recreate` is important because the machine has one GPU. It avoids Kubernetes temporarily running an old vLLM pod and a new vLLM pod at the same time.

Recommended vLLM runtime settings:

```yaml
imagePullPolicy: IfNotPresent

args:
- "mistralai/Mistral-7B-Instruct-v0.3"
- "--host=0.0.0.0"
- "--max-model-len=8192"
- "--gpu-memory-utilization=0.7"
- "--tokenizer-mode=mistral"
```

---

### 2.5 Hugging Face model cache

The model cache is stored in a Kubernetes PVC:

```text
hf-cache
```

Mounted inside the vLLM container at:

```text
/root/.cache/huggingface
```

This allows model files to survive pod restarts.

Hard rule:

```text
Do not delete the hf-cache PVC unless you want to download the model again.
```

---

### 2.6 Open WebUI

Open WebUI provides the browser interface.

Namespace:

```text
ui
```

Deployment:

```text
openwebui
```

Service:

```text
openwebui
```

Open WebUI connects to vLLM using the internal Kubernetes DNS name:

```text
http://mistral.llm.svc.cluster.local:8000/v1
```

Open WebUI data is persisted with:

```text
openwebui-data
```

Mounted at:

```text
/app/backend/data
```

This stores:

- users
- settings
- knowledge bases
- tools
- model wrappers
- Open WebUI configuration

Hard rule:

```text
Do not delete the openwebui-data PVC unless you want to reset Open WebUI.
```

---

## 3. Local browser access

The demo does not rely on Ingress or NodePort.

Instead, the start script creates a local port-forward:

```bash
kubectl -n ui port-forward svc/openwebui 18080:80 --address 127.0.0.1
```

The browser URL is:

```text
http://dgx-demo.test:18080
```

The hostname is mapped in `/etc/hosts`:

```text
127.0.0.1 dgx-demo.test
```

This is intentionally simple and reliable for a local machine demo.

---

## 4. Daily operation model

Normal start:

```bash
./scripts/start-demo.sh
```

Normal stop:

```bash
./scripts/stop-demo.sh
```

`start-demo.sh`:

- checks k3s
- applies manifests
- scales Mistral to 1
- scales Open WebUI to 1
- waits for readiness
- starts local port-forward
- opens Firefox

`stop-demo.sh`:

- closes the dedicated demo Firefox window
- stops the port-forward
- scales Open WebUI to 0
- scales Mistral to 0
- keeps k3s and persistent data intact

`cleanup.sh` is destructive and intended only for full reset or handover.

---

## 5. Demo scenarios

The platform should remain clean and reusable.

Recommended structure:

```text
examples/
├── finance-rag-access-control/
└── weather-travel-agent/
```

### 5.1 Finance RAG access-control demo

Purpose:

```text
Same local model.
Different users.
Different knowledge access.
```

Example users:

- Zia: admin
- Katja: finance user
- Ralf: normal user

Expected behavior:

- Katja can access the restricted synthetic finance knowledge base.
- Ralf cannot access it.
- The model is shared.
- Data access is controlled at the retrieval/knowledge layer.

This demonstrates:

```text
Local sovereign LLM + permission-aware RAG
```

### 5.2 Weather Travel Agent

Purpose:

```text
Small live tool-calling agent.
```

The agent calls Open-Meteo and gives a practical recommendation.

Example:

```text
Should I do an outdoor customer demo in Luxembourg tomorrow?
```

Expected flow:

```text
User question
→ Open WebUI tool call
→ Open-Meteo weather API
→ weather summary
→ practical recommendation
```

This demonstrates:

```text
Local LLM + external tool + decision support
```

---

## 6. Security boundaries

This demo is not a production security architecture.

Current boundaries:

- local machine
- local Kubernetes
- Open WebUI users and groups
- Open WebUI knowledge access controls
- Kubernetes namespaces
- Hugging Face token stored as Kubernetes Secret

Not included by default:

- enterprise identity provider
- OAuth/OIDC SSO
- production ingress
- TLS certificates
- Kubernetes NetworkPolicies
- audit-grade logging
- hardened multi-tenant isolation
- backup and restore
- confidential computing attestation
- external secret management

For production, add:

- TLS
- SSO
- NetworkPolicies
- proper secret management
- monitoring
- image pinning and scanning
- backup strategy
- access logs
- security review of Open WebUI tools and functions

---

## 7. Repository separation recommendation

Keep the platform and reusable demos in the same repository for now:

```text
sovereign-ai-dgx-spark/
├── manifests/
├── scripts/
├── docs/
└── examples/
```

Create a second repository only when demos become:

- customer-specific
- confidential
- sales-specific
- independently reusable
- too large for the platform repo

Possible future split:

```text
sovereign-ai-dgx-spark          # platform
sovereign-ai-dgx-spark-demos    # polished demo scenarios
```

Current recommendation:

```text
Do not split yet. Use examples/ first.
```
