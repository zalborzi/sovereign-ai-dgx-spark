# Installation

This document explains how to install the **Sovereign AI on NVIDIA DGX Spark** demo from a clean machine.

Clone the repository:

```bash
git clone https://github.com/zalborzi/sovereign-ai-dgx-spark.git
cd sovereign-ai-dgx-spark
```

Do not assume the project is in `~/chatbot`. The scripts automatically detect the repository root.

---

## 1. Verify NVIDIA driver and container toolkit

Check the NVIDIA driver:

```bash
nvidia-smi
```

Expected:

- GPU is visible
- driver is loaded
- command does not fail

Check the NVIDIA container runtime:

```bash
nvidia-container-cli info
```

Expected:

- command succeeds
- GPU information is printed

If these fail, fix the NVIDIA driver or NVIDIA container toolkit first. Do not continue until they work.

---

## 2. Install k3s

Install k3s with a readable kubeconfig:

```bash
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
```

Set kubeconfig for the current shell:

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

Optional but useful:

```bash
echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> ~/.bashrc
```

Verify:

```bash
kubectl get nodes
```

Expected:

```text
STATUS
Ready
```

Check that k3s containerd has NVIDIA runtime entries:

```bash
grep nvidia /var/lib/rancher/k3s/agent/etc/containerd/config.toml
```

If this shows no NVIDIA runtime entries, the GPU Operator may not expose the GPU correctly.

---

## 3. Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Verify:

```bash
helm version
```

---

## 4. Install NVIDIA GPU Operator

Add the NVIDIA Helm repository:

```bash
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update
```

Install the GPU Operator for k3s:

```bash
helm install gpu-operator nvidia/gpu-operator   --namespace gpu-operator   --create-namespace   --set driver.enabled=false   --set toolkit.env[0].name=CONTAINERD_CONFIG   --set toolkit.env[0].value=/var/lib/rancher/k3s/agent/etc/containerd/config.toml   --set toolkit.env[1].name=CONTAINERD_SOCKET   --set toolkit.env[1].value=/run/k3s/containerd/containerd.sock
```

Wait until pods are ready:

```bash
kubectl get pods -n gpu-operator -w
```

Verify GPU allocation:

```bash
kubectl get nodes -o json | jq '.items[].status.allocatable'
```

Expected output includes:

```json
"nvidia.com/gpu": "1"
```

---

## 5. Create Hugging Face token secret

Mistral 7B Instruct is a gated model. You need a Hugging Face token with access to the model.

Create the namespace:

```bash
kubectl create namespace llm --dry-run=client -o yaml | kubectl apply -f -
```

Create the secret:

```bash
kubectl -n llm create secret generic hf-token   --from-literal=token=hf_YOUR_TOKEN_HERE
```

To replace an existing token:

```bash
kubectl -n llm delete secret hf-token
kubectl -n llm create secret generic hf-token   --from-literal=token=hf_YOUR_TOKEN_HERE
```

Do not commit a real Hugging Face token to GitHub.

---

## 6. Apply Kubernetes manifests

### First install only: allow the model download

The manifests default to offline mode. `manifests/02-mistral-vllm.yaml` sets:

```yaml
- name: HF_HUB_OFFLINE
  value: "1"
- name: TRANSFORMERS_OFFLINE
  value: "1"
```

On a clean machine the model cache is still empty, so the first start must be allowed to download the model. Before applying the manifests for the first time, edit `manifests/02-mistral-vllm.yaml` and set both values to `"0"`.

After the first successful start (chat works), set both values back to `"1"` and apply:

```bash
kubectl apply -f manifests/02-mistral-vllm.yaml
kubectl -n llm rollout restart deployment/mistral
```

See `docs/OFFLINE.md` section 11 for details.

### Apply the manifests

From the repository root:

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

kubectl apply -f manifests/01-hf-cache-pvc.yaml
kubectl apply -f manifests/02-mistral-vllm.yaml
kubectl apply -f manifests/10-openwebui.yaml
```

Check resources:

```bash
kubectl -n llm get pvc
kubectl -n llm get deployment,svc
kubectl -n ui get pvc
kubectl -n ui get deployment,svc
```

---

## 7. Make scripts executable

```bash
chmod +x scripts/start-demo.sh scripts/stop-demo.sh scripts/cleanup.sh
```

---

## 8. Start the demo

```bash
./scripts/start-demo.sh
```

The script will:

- start k3s if needed
- apply manifests
- start vLLM/Mistral
- start Open WebUI
- start local port-forward
- open Firefox

The browser URL is:

```text
http://dgx-demo.test:18080
```

First startup can take a long time because it may include:

- image pull
- model download
- model loading
- CUDA graph compilation

After the model is cached, startup should be much faster.

---

## 9. Configure Open WebUI

Open:

```text
http://dgx-demo.test:18080
```

The first user becomes admin.

Configure the OpenAI-compatible connection:

```text
Admin Panel → Settings → Connections → OpenAI API
```

Use:

```text
URL: http://mistral.llm.svc.cluster.local:8000/v1
API Key: sk-dummy
```

vLLM does not require a real API key in this local setup.

Save, refresh, and select:

```text
mistralai/Mistral-7B-Instruct-v0.3
```

Test:

```text
Say hello in one sentence.
```

---

## 10. Stop the demo

For normal shutdown:

```bash
./scripts/stop-demo.sh
```

This keeps:

- k3s installed
- GPU Operator installed
- model cache
- Open WebUI users and settings

It only stops the demo workloads.

---

## 11. Full cleanup

Only use cleanup for full reset or handover:

```bash
sudo ./scripts/cleanup.sh
```

Non-interactive:

```bash
sudo FORCE=1 ./scripts/cleanup.sh
```

This removes k3s and local Kubernetes state.

It does not remove the NVIDIA driver.

---

## 12. Post-install verification

Check vLLM logs:

```bash
kubectl -n llm logs deployment/mistral --tail=80
```

Look for:

```text
Application startup complete
```

Check Open WebUI logs:

```bash
kubectl -n ui logs deployment/openwebui --tail=80
```

Check the internal model endpoint:

```bash
kubectl -n ui exec deployment/openwebui --   curl -s http://mistral.llm.svc.cluster.local:8000/v1/models
```

Expected: JSON with the model ID.

Check the local browser tunnel:

```bash
curl --noproxy '*' -I http://dgx-demo.test:18080
```

Expected: HTTP response from Open WebUI.
