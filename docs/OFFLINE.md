# Offline Mode

This document explains how to make the DGX Spark demo work without fetching the model again.

Core rule:

```text
The model must be downloaded and cached once while internet is available.
After that, vLLM can start from the persistent Hugging Face cache.
```

---

## 1. What offline mode means

Offline mode means:

- vLLM should not contact Hugging Face during startup
- the model should load from the local PVC
- Open WebUI should use existing local data/cache
- container images should already exist locally
- Kubernetes should not pull images again unless necessary

Offline mode does not download missing files.

If the model cache is incomplete, offline startup will fail.

---

## 2. Critical persistent volumes

### 2.1 vLLM model cache

PVC:

```text
hf-cache
```

Mounted at:

```text
/root/.cache/huggingface
```

This stores model files.

Hard rule:

```text
Do not delete hf-cache unless you want to download the model again.
```

### 2.2 Open WebUI data

PVC:

```text
openwebui-data
```

Mounted at:

```text
/app/backend/data
```

This stores users, settings, tools, knowledge bases, and Open WebUI configuration.

Hard rule:

```text
Do not delete openwebui-data unless you want to reset Open WebUI.
```

---

## 3. Required vLLM settings

The vLLM deployment should include:

```yaml
imagePullPolicy: IfNotPresent
```

and:

```yaml
env:
- name: HF_HOME
  value: "/root/.cache/huggingface"
- name: HF_HUB_OFFLINE
  value: "1"
- name: TRANSFORMERS_OFFLINE
  value: "1"
```

The cache mount should be:

```yaml
volumeMounts:
- name: hf-cache
  mountPath: /root/.cache/huggingface
```

The PVC should be:

```yaml
volumes:
- name: hf-cache
  persistentVolumeClaim:
    claimName: hf-cache
```

---

## 4. Required Open WebUI settings

The Open WebUI deployment should include:

```yaml
imagePullPolicy: IfNotPresent
```

Recommended environment variables:

```yaml
env:
- name: HF_HUB_OFFLINE
  value: "1"
- name: TRANSFORMERS_OFFLINE
  value: "1"
```

This helps avoid unnecessary online fetches.

---

## 5. Warm the cache once

Keep internet connected.

From the repository root:

```bash
./scripts/start-demo.sh
```

Wait until:

- Mistral starts successfully
- Open WebUI opens
- chat works

Then stop:

```bash
./scripts/stop-demo.sh
```

At this point, the model should be cached in `hf-cache`.

---

## 6. Test offline mode

Disconnect internet.

Start again:

```bash
./scripts/start-demo.sh
```

Expected:

- no Hugging Face download
- vLLM starts from local cache
- Open WebUI opens

Verify recent logs:

```bash
kubectl -n llm logs deployment/mistral --tail=120 | grep -i huggingface || echo "No Hugging Face access in recent logs"
```

Good result:

```text
No Hugging Face access in recent logs
```

Bad result:

```text
Failed to resolve 'huggingface.co'
```

If you see DNS failures for Hugging Face, vLLM is still trying to fetch something.

---

## 7. Check model cache size

```bash
kubectl -n llm exec deployment/mistral -- du -sh /root/.cache/huggingface/
```

You should see a large cache.

If the cache is tiny, the model was not fully downloaded.

---

## 8. Inspect cache contents

```bash
kubectl -n llm exec deployment/mistral -- find /root/.cache/huggingface -maxdepth 4 -type d | head -50
```

You should see Hugging Face hub cache directories and Mistral-related paths.

---

## 9. Why startup can still be slow offline

Offline startup can still take time because vLLM may need to:

- load model files from disk
- initialize GPU kernels
- compile/capture CUDA graphs
- allocate memory
- pass health checks

This is not a download.

Watch logs:

```bash
kubectl -n llm logs deployment/mistral -f
```

Wait for:

```text
Application startup complete
```

---

## 10. Common offline failures

### 10.1 Model cache incomplete

Symptoms:

```text
Failed to resolve 'huggingface.co'
```

or:

```text
Cannot find config.json
```

Fix:

1. reconnect internet
2. temporarily allow online mode if needed
3. start the model once
4. verify it works
5. stop
6. test offline again

### 10.2 PVC was deleted

Symptoms:

- model downloads again
- startup takes 15–30 minutes
- cache appears empty

Fix:

- let it download once again
- do not delete `hf-cache`

### 10.3 Image was removed

Symptom:

```text
ImagePullBackOff
```

while offline.

Fix:

- reconnect internet
- pull images once
- keep `imagePullPolicy: IfNotPresent`

### 10.4 Open WebUI cache missing

Symptoms:

- Open WebUI starts but RAG or tools behave differently
- logs mention external model download

Fix:

- start once with internet
- let Open WebUI initialize
- then test offline again

---

## 11. Temporary online mode for recovery

If offline mode blocks startup before the cache is complete, temporarily disable offline variables.

Change:

```yaml
- name: HF_HUB_OFFLINE
  value: "1"
- name: TRANSFORMERS_OFFLINE
  value: "1"
```

to:

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

After successful startup, restore both values to `"1"` and apply again.

---

## 12. Final offline checklist

Before a customer or boss demo:

```bash
./scripts/start-demo.sh
```

Confirm chat works.

Then:

```bash
./scripts/stop-demo.sh
```

Disconnect internet.

Then:

```bash
./scripts/start-demo.sh
```

Verify:

```bash
kubectl -n llm logs deployment/mistral --tail=120 | grep -i huggingface || echo "No Hugging Face access in recent logs"
```

Test in Open WebUI:

```text
Say hello in one sentence.
```

If that works, the demo is offline-ready.

---

## 13. Hard rule

Do not use this for normal shutdown:

```bash
sudo ./scripts/cleanup.sh
```

Use this:

```bash
./scripts/stop-demo.sh
```

`cleanup.sh` removes local Kubernetes state and will remove the PVCs.
