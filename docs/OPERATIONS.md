# Operations

This document explains how to operate the DGX Spark sovereign AI demo day to day.

Use this for normal demo usage.

Do not use `cleanup.sh` unless you want a full reset.

---

## 1. Normal start

From the repository root:

```bash
./scripts/start-demo.sh
```

The script will:

1. detect the project folder
2. verify Kubernetes access
3. apply manifests
4. start Mistral/vLLM
5. start Open WebUI
6. wait for readiness
7. start a local port-forward
8. open Firefox

The browser URL is:

```text
http://dgx-demo.test:18080
```

---

## 2. Normal stop

From the repository root:

```bash
./scripts/stop-demo.sh
```

The script will:

1. close the dedicated demo Firefox window
2. stop the local port-forward
3. scale Open WebUI to zero
4. scale Mistral/vLLM to zero
5. keep k3s installed
6. keep PVCs and data intact

This is the correct command for daily shutdown.

---

## 3. Full cleanup

Use only for full reset or handover:

```bash
sudo ./scripts/cleanup.sh
```

This removes:

- k3s
- Kubernetes resources
- Rancher/k3s state
- Helm binary
- local kube/helm config
- local demo launchers
- demo browser profile
- local port-forward state

It does not remove the NVIDIA driver.

Non-interactive cleanup:

```bash
sudo FORCE=1 ./scripts/cleanup.sh
```

---

## 4. Local URL

The demo uses:

```text
http://dgx-demo.test:18080
```

This is mapped in `/etc/hosts`:

```text
127.0.0.1 dgx-demo.test
```

The start script adds this automatically if missing.

The URL works through a local port-forward:

```bash
kubectl -n ui port-forward svc/openwebui 18080:80 --address 127.0.0.1
```

This is intentionally used instead of Ingress or NodePort because it is more reliable for a local demo.

---

## 5. Check status

### Kubernetes nodes

```bash
kubectl get nodes
```

### GPU Operator

```bash
kubectl get pods -n gpu-operator
```

### LLM namespace

```bash
kubectl -n llm get pods,deploy,svc,pvc
```

### UI namespace

```bash
kubectl -n ui get pods,deploy,svc,pvc
```

### GPU

```bash
nvidia-smi
```

---

## 6. Check logs

### Mistral/vLLM logs

```bash
kubectl -n llm logs deployment/mistral --tail=120
```

Follow live:

```bash
kubectl -n llm logs deployment/mistral -f
```

Look for:

```text
Application startup complete
```

### Open WebUI logs

```bash
kubectl -n ui logs deployment/openwebui --tail=120
```

Follow live:

```bash
kubectl -n ui logs deployment/openwebui -f
```

### Start script log

```bash
cat scripts/start-demo.log
```

### Stop script log

```bash
cat scripts/stop-demo.log
```

### Port-forward log

```bash
cat scripts/openwebui-portforward.log
```

---

## 7. Manual port-forward recovery

If the browser does not open but Open WebUI is running:

```bash
pkill -f "kubectl -n ui port-forward svc/openwebui 18080:80" || true

kubectl -n ui port-forward svc/openwebui 18080:80 --address 127.0.0.1
```

Then open:

```text
http://dgx-demo.test:18080
```

---

## 8. Internal API tests

### Test vLLM from inside Open WebUI pod

```bash
kubectl -n ui exec deployment/openwebui --   curl -s http://mistral.llm.svc.cluster.local:8000/v1/models
```

Expected:

- JSON response
- model ID appears

### Test vLLM locally

In one terminal:

```bash
kubectl -n llm port-forward svc/mistral 8000:8000
```

In another terminal:

```bash
curl http://127.0.0.1:8000/v1/chat/completions   -H "Content-Type: application/json"   -d '{
    "model":"mistralai/Mistral-7B-Instruct-v0.3",
    "messages":[{"role":"user","content":"Say hello in one sentence."}],
    "max_tokens":50
  }'
```

---

## 9. Demo users

Recommended demo users:

```text
admin   = admin
finance-user = finance user
normal-user  = normal user
```

Demo story:

```text
Same local model.
Same local DGX Spark backend.
Different access to knowledge.
```

---

## 10. Finance RAG demo operation

Recommended structure:

```text
examples/finance-rag-access-control/
```

Recommended Open WebUI setup:

- base model public
- restricted finance knowledge visible only to Finance Analysts group
- finance-user in Finance Analysts group
- normal-user not in Finance Analysts group

Do not make the base model private. If the base model is private, wrapper models or users may show `Model not found`.

Recommended test for finance-user:

```text
Using only Restricted Finance Q3 2026, answer:
1. What was DemoCorp's Q3 2026 revenue?
2. What was the confidential acquisition target estimated purchase price?
3. What did the CFO recommend about hiring?
```

Expected:

- answers with restricted numbers
- uses retrieved finance context

Recommended test for normal-user:

```text
What was DemoCorp's Q3 2026 revenue and acquisition target price?
```

Expected:

- no restricted numbers
- no access to the finance knowledge base

---

## 11. Weather Travel Agent operation

Recommended structure:

```text
examples/weather-travel-agent/
```

The weather agent calls Open-Meteo through an Open WebUI tool.

This needs internet.

Recommended test:

```text
Should I do an outdoor customer demo in Luxembourg tomorrow?
```

Expected:

- tool call appears
- agent gives weather-based recommendation

The tool call line should look similar to:

```text
open_meteo_weather_tool/weather_travel_advice
```

---

## 12. Start/stop expectation

### First start

Can take 15–30 minutes if model/image download is needed.

### Normal warm start

Usually a few minutes.

### Offline warm start

Can still take a few minutes because vLLM loads the model and initializes GPU kernels.

Wait for:

```text
Application startup complete
```

---

## 13. Before a live demo

Run:

```bash
./scripts/start-demo.sh
```

Verify:

```bash
kubectl -n llm logs deployment/mistral --tail=80
kubectl -n ui logs deployment/openwebui --tail=80
curl --noproxy '*' -I http://dgx-demo.test:18080
```

In Open WebUI, test:

```text
Say hello in one sentence.
```

Then test:

```text
Should I do an outdoor customer demo in Luxembourg tomorrow?
```

If finance RAG is part of the demo, test finance-user and normal-user before showing it.

---

## 14. After a live demo

Use:

```bash
./scripts/stop-demo.sh
```

Do not use cleanup unless the machine must be reset.

---

## 15. Useful aliases

Optional:

```bash
echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> ~/.bashrc
```

Optional shell aliases:

```bash
echo 'alias k="kubectl"' >> ~/.bashrc
echo 'alias llmlogs="kubectl -n llm logs deployment/mistral -f"' >> ~/.bashrc
echo 'alias uilogs="kubectl -n ui logs deployment/openwebui -f"' >> ~/.bashrc
```
