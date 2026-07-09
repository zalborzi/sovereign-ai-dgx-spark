# Contributing

Thank you for considering a contribution to **Sovereign AI on NVIDIA DGX Spark**.

This project is a local demo and learning stack for running a sovereign AI assistant on NVIDIA DGX Spark with k3s, NVIDIA GPU Operator, vLLM, and Open WebUI.

The project values contributions that make the stack more reliable, easier to understand, safer to run, and easier to demo.

---

## Ways to contribute

Useful contributions include:

- fixing Kubernetes manifests
- improving start, stop, or cleanup scripts
- improving offline startup behavior
- improving documentation
- adding troubleshooting cases
- adding safe reusable examples
- improving Open WebUI demo instructions
- correcting inaccurate technical details
- making the project easier to install from a clean machine

---

## Repository structure

```text
sovereign-ai-dgx-spark/
├── manifests/
├── scripts/
├── docs/
└── examples/
```

Use the existing structure:

- platform manifests go in `manifests/`
- operational scripts go in `scripts/`
- general documentation goes in `docs/`
- reusable demo scenarios go in `examples/`

---

## Before opening an issue

Before opening an issue, please check:

1. existing issues
2. `docs/TROUBLESHOOTING.md`
3. `docs/INSTALL.md`
4. `docs/OFFLINE.md`

When reporting a problem, include:

- DGX Spark / machine details
- Ubuntu version
- NVIDIA driver version
- CUDA version
- k3s version
- exact command used
- relevant logs
- whether the system was online or offline
- whether the model cache already existed

Useful commands:

```bash
nvidia-smi
kubectl get nodes -o wide
kubectl get nodes -o json | jq '.items[].status.allocatable'
kubectl -n llm get pods,deploy,svc,pvc
kubectl -n ui get pods,deploy,svc,pvc
kubectl -n llm logs deployment/mistral --tail=120
kubectl -n ui logs deployment/openwebui --tail=120
```

Do not paste real tokens or secrets.

---

## Before opening a pull request

Before opening a pull request:

1. keep the change focused
2. update documentation if behavior changes
3. test the relevant commands if possible
4. avoid committing generated logs
5. avoid committing real secrets, tokens, customer data, or internal documents

For manifest changes, test:

```bash
kubectl apply -f manifests/
```

For demo operation changes, test:

```bash
./scripts/start-demo.sh
./scripts/stop-demo.sh
```

For offline-related changes, test:

```bash
kubectl -n llm logs deployment/mistral --tail=120 | grep -i huggingface || echo "No Hugging Face access in recent logs"
```

---

## Commit message style

Use Conventional Commits:

```text
<type>: <short description>
```

Recommended types:

```text
feat:     new capability
fix:      bug fix or reliability fix
docs:     documentation-only change
chore:    maintenance or repository hygiene
refactor: code restructuring without behavior change
test:     test-related change
```

Examples:

```text
fix: harden vLLM deployment for offline restart
feat: add one-click demo start and stop scripts
docs: add offline operation guide
chore: improve cleanup script for full reset
```

Avoid vague messages:

```text
update
changes
misc
final
```

---

## Documentation style

Documentation should be:

- direct
- reproducible
- command-oriented
- honest about limitations
- clear about what is demo-only vs production-ready

Use exact commands where possible.

Avoid claims such as:

- production-ready
- enterprise-secure
- fully compliant
- guaranteed offline

unless the repository actually implements those guarantees.

---

## Demo data policy

All demo data must be synthetic.

Do not contribute:

- real financial data
- real customer data
- internal company documents
- private emails
- access tokens
- private keys
- confidential project material

The finance RAG example must remain fictional.

---

## Open WebUI tools policy

Open WebUI tools execute Python code on the Open WebUI server.

Tool contributions must be simple, readable, and safe.

Do not contribute tools that:

- execute arbitrary shell commands
- read unrelated local files
- exfiltrate environment variables
- transmit secrets
- scrape fragile websites without permission
- perform destructive actions
- hide network calls

Prefer tools that use:

- public APIs
- no API key
- clear timeouts
- explicit error handling
- narrow purpose

---

## Pull request checklist

Before submitting, check:

- [ ] The change is focused.
- [ ] Documentation is updated if needed.
- [ ] No real secrets or tokens are committed.
- [ ] No real customer or company data is committed.
- [ ] Scripts are executable if needed.
- [ ] Commands were tested where practical.
- [ ] The change does not make the demo less reproducible.
