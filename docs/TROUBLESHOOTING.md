# Troubleshooting

This document lists common problems and fixes for the DGX Spark sovereign AI demo.

Run commands from the repository root unless stated otherwise.

---

## 1. `kubectl` cannot connect

### Symptom

```text
The connection to the server localhost:8080 was refused
```

or:

```text
error: stat /etc/rancher/k3s/k3s.yaml: permission denied
```

### Fix

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

If permission is the issue:

```bash
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
```

Check k3s:

```bash
sudo systemctl status k3s
```

Start it if needed:

```bash
sudo systemctl start k3s
```

Test:

```bash
kubectl get nodes
```

---

## 2. GPU not visible in Kubernetes

### Symptom

vLLM pod cannot schedule, or no GPU resource appears.

### Check

```bash
nvidia-smi
```

```bash
kubectl get nodes -o json | jq '.items[].status.allocatable'
```

Expected:

```json
"nvidia.com/gpu": "1"
```

Check GPU Operator:

```bash
kubectl get pods -n gpu-operator
```

Check node labels:

```bash
kubectl get node --show-labels | tr ',' '
' | grep nvidia
```

### Fix

If GPU Operator pods are failing:

```bash
kubectl describe pod -n gpu-operator
```

If k3s does not show NVIDIA runtime entries:

```bash
grep nvidia /var/lib/rancher/k3s/agent/etc/containerd/config.toml
```

Re-check the GPU Operator installation command in `docs/INSTALL.md`.

---

## 3. vLLM pod stuck in `Pending`

### Symptom

```bash
kubectl -n llm get pods
```

shows:

```text
Pending
```

### Check

```bash
kubectl -n llm describe pod -l app=mistral
```

Common causes:

- GPU not available
- old vLLM pod still using GPU
- resource request too high
- GPU Operator not ready

### Fix

Delete stale Mistral pods:

```bash
kubectl -n llm delete pod -l app=mistral --force --grace-period=0
```

Then restart:

```bash
kubectl -n llm rollout restart deployment/mistral
```

---

## 4. vLLM pod stuck in `ContainerCreating`

### Check

```bash
kubectl -n llm describe pod -l app=mistral
```

Possible causes:

- image pull is still running
- volume is attaching
- container runtime issue

First image pull can take time.

Watch:

```bash
kubectl -n llm get pods -w
```

---

## 5. vLLM crashes with OOM or CUDA memory errors

### Symptom

Logs mention memory, CUDA, allocation, or OOM.

### Check

```bash
kubectl -n llm logs deployment/mistral --tail=150
```

### Fix

Reduce:

```yaml
- "--gpu-memory-utilization=0.7"
```

to:

```yaml
- "--gpu-memory-utilization=0.6"
```

in:

```text
manifests/02-mistral-vllm.yaml
```

Apply:

```bash
kubectl apply -f manifests/02-mistral-vllm.yaml
kubectl -n llm rollout restart deployment/mistral
```

---

## 6. Start script waits at `0 of 1 updated replicas are available`

### Meaning

This is not always an error.

With startup/readiness probes, Kubernetes waits until vLLM really answers `/health`.

### Watch logs

```bash
kubectl -n llm logs deployment/mistral -f
```

Wait for:

```text
Application startup complete
```

If it takes more than 8–10 minutes on a warm cache, check logs.

---

## 7. vLLM tries to fetch Hugging Face again

### Symptom

Logs show:

```text
Failed to resolve 'huggingface.co'
```

or:

```text
resolve/main/config.json
```

### Meaning

The model cache is incomplete, or offline variables are forcing offline mode before all files exist.

### Check

```bash
kubectl -n llm logs deployment/mistral --tail=150 | grep -i huggingface
```

Check cache size:

```bash
kubectl -n llm exec deployment/mistral -- du -sh /root/.cache/huggingface/
```

### Fix

Reconnect internet.

Temporarily disable offline mode if needed:

```yaml
- name: HF_HUB_OFFLINE
  value: "0"
- name: TRANSFORMERS_OFFLINE
  value: "0"
```

Apply:

```bash
kubectl apply -f manifests/02-mistral-vllm.yaml
kubectl -n llm rollout restart deployment/mistral
kubectl -n llm logs deployment/mistral -f
```

Wait until the model works.

Then set both values back to `"1"` and apply again.

---

## 8. `kubectl exec` into vLLM fails

### Symptom

```text
error: unable to upgrade connection: container not found ("vllm")
```

### Meaning

The pod is not running yet, or the container crashed before exec could attach.

### Check

```bash
kubectl -n llm get pods -l app=mistral
kubectl -n llm describe pod -l app=mistral
kubectl -n llm logs deployment/mistral --tail=150
```

---

## 9. Old vLLM process still appears in `nvidia-smi`

### Symptom

After stopping, `nvidia-smi` still shows:

```text
VLLM::EngineCore
```

### Fix

Wait a short time first.

Then check pods:

```bash
kubectl -n llm get pods -l app=mistral
```

Force delete if needed:

```bash
kubectl -n llm delete pod -l app=mistral --force --grace-period=0
```

Check again:

```bash
nvidia-smi
```

---

## 10. Open WebUI cannot connect to vLLM

### Check internal DNS

```bash
kubectl -n ui exec deployment/openwebui --   curl -s http://mistral.llm.svc.cluster.local:8000/v1/models
```

If this fails, check Mistral:

```bash
kubectl -n llm get pods,svc
kubectl -n llm logs deployment/mistral --tail=120
```

Open WebUI connection should be:

```text
http://mistral.llm.svc.cluster.local:8000/v1
```

API key can be:

```text
sk-dummy
```

---

## 11. Browser cannot open `dgx-demo.test:18080`

### Check hosts entry

```bash
grep dgx-demo.test /etc/hosts
```

Expected:

```text
127.0.0.1 dgx-demo.test
```

Add manually if missing:

```bash
echo "127.0.0.1 dgx-demo.test" | sudo tee -a /etc/hosts
```

### Check port-forward process

```bash
ps -ef | grep "port-forward svc/openwebui"
```

### Check port-forward log

```bash
cat scripts/openwebui-portforward.log
```

### Restart tunnel manually

```bash
pkill -f "kubectl -n ui port-forward svc/openwebui 18080:80" || true

kubectl -n ui port-forward svc/openwebui 18080:80 --address 127.0.0.1
```

Open:

```text
http://dgx-demo.test:18080
```

---

## 12. Port 18080 already in use

### Check

```bash
ss -ltnp | grep 18080
```

or:

```bash
lsof -i :18080
```

### Fix

```bash
pkill -f "kubectl -n ui port-forward svc/openwebui 18080:80" || true
```

Then restart:

```bash
./scripts/start-demo.sh
```

---

## 13. Firefox opens but wrong profile or old tab remains

The start script uses a dedicated Firefox profile:

```text
.demo/firefox-profile
```

The stop script closes only that profile.

If it gets stuck:

```bash
pkill -f ".demo/firefox-profile" || true
```

Then start again:

```bash
./scripts/start-demo.sh
```

---

## 14. Open WebUI model says `Model not found`

Common causes:

- base model was made private
- wrapper model points to a base model the user cannot access
- Open WebUI connection is not saved
- Open WebUI needs refresh/restart

Recommended setup:

- base model public
- restricted knowledge private
- access controlled at knowledge/workspace model level

Check connection:

```text
Admin Panel → Settings → Connections
```

Use:

```text
http://mistral.llm.svc.cluster.local:8000/v1
```

Then refresh Open WebUI.

---

## 15. Finance RAG: finance-user sees data but normal-user also sees data

### Meaning

Access control is wrong.

### Check

- finance knowledge base access
- group membership
- model visibility
- whether restricted numbers were pasted into a public system prompt
- whether normal-user is using a public chat where context was already injected

### Fix

- keep finance KB restricted
- keep synthetic finance numbers only inside restricted KB
- create Finance group
- add finance-user to Finance group
- keep normal-user outside Finance group
- start a new chat for each user test

---

## 16. Finance RAG: finance-user does not retrieve finance data

### Check

- finance-user is in the Finance group
- KB is attached to the correct model
- KB is indexed
- chat uses the right model
- query mentions the exact document/topic

Test prompt:

```text
Using only Restricted Finance Q3 2026, answer:
1. What was DemoCorp's Q3 2026 revenue?
2. What was the confidential acquisition target estimated purchase price?
3. What did the CFO recommend about hiring?
```

---

## 17. Weather agent tool does not run

### Check internet from Open WebUI pod

Use `-i` with heredoc:

```bash
kubectl -n ui exec -i deployment/openwebui -- python - <<'PY'
import urllib.request

url = "https://geocoding-api.open-meteo.com/v1/search?name=Luxembourg&count=1&language=en&format=json"
print(urllib.request.urlopen(url, timeout=10).read()[:500].decode())
PY
```

Expected: JSON containing Luxembourg.

### Check model setup

- tool is saved
- tool is attached to Weather Travel Agent
- Function Calling is Legacy
- new chat started after saving
- system prompt tells the model to use the tool

Test prompt:

```text
Should I do an outdoor customer demo in Luxembourg tomorrow?
```

Expected: visible tool call similar to:

```text
open_meteo_weather_tool/weather_travel_advice
```

---

## 18. Weather agent returns fake weather without calling tool

### Fix

Strengthen the system prompt:

```text
When the user asks about weather, travel planning, outdoor meetings, customer visits, or demo planning, use the weather_travel_advice tool before answering.

Do not answer weather questions from memory.
Do not invent weather.
If the tool fails, say the live weather check failed.
```

Start a new chat and test again.

---

## 19. Native tool calling error from vLLM

### Symptom

Error mentions:

```text
"auto" tool choice requires --enable-auto-tool-choice
```

### Recommended fix

Use Open WebUI **Legacy** tool/function calling for this demo.

Do not add native vLLM tool-calling flags unless you deliberately want to debug tool parsers.

Stable demo recommendation:

```text
Function Calling: Legacy
```

---

## 20. `zenity` Yaru accent warning

### Symptom

```text
Adwaita-WARNING **: No known Yaru accent 'nvidia'
```

### Meaning

Harmless GNOME/Ubuntu theme warning.

Ignore it.

---

## 21. Need a clean restart

Use:

```bash
./scripts/stop-demo.sh
```

Then:

```bash
kubectl -n llm delete pod -l app=mistral --force --grace-period=0 || true
kubectl -n ui delete pod -l app=openwebui --force --grace-period=0 || true
```

Then:

```bash
./scripts/start-demo.sh
```

---

## 22. Need a full reset

Destructive:

```bash
sudo ./scripts/cleanup.sh
```

This removes k3s and Kubernetes state.

After cleanup, reinstall using `docs/INSTALL.md`.

---

## 23. Fast diagnostic bundle

Run:

```bash
echo "=== Nodes ==="
kubectl get nodes -o wide

echo "=== GPU allocatable ==="
kubectl get nodes -o json | jq '.items[].status.allocatable'

echo "=== GPU Operator ==="
kubectl get pods -n gpu-operator

echo "=== LLM ==="
kubectl -n llm get pods,deploy,svc,pvc

echo "=== UI ==="
kubectl -n ui get pods,deploy,svc,pvc

echo "=== Mistral logs ==="
kubectl -n llm logs deployment/mistral --tail=120 || true

echo "=== Open WebUI logs ==="
kubectl -n ui logs deployment/openwebui --tail=120 || true

echo "=== GPU ==="
nvidia-smi || true

echo "=== Port-forward ==="
ps -ef | grep "port-forward svc/openwebui" | grep -v grep || true
```
