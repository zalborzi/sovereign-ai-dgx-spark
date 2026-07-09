# Security Policy

## Supported versions

This repository is maintained as a demo and learning project.

Security fixes are applied to the default branch:

```text
main
```

Older commits, forks, or modified deployments are not actively supported.

---

## Reporting a vulnerability

Please do **not** report security vulnerabilities in public GitHub issues.

Use one of these options:

1. Open a private security advisory on GitHub if available for this repository.
2. Contact the maintainer privately through GitHub.

When reporting a vulnerability, include:

- affected file or component
- clear description of the issue
- steps to reproduce
- potential impact
- suggested fix, if known

Do not include real secrets, tokens, customer data, or confidential information in the report.

---

## Scope

In scope:

- unsafe repository scripts
- unsafe Kubernetes manifests
- unsafe Open WebUI tool examples
- accidental secret exposure in repository files
- misleading security claims in documentation
- insecure demo defaults that can be reasonably fixed

Out of scope:

- vulnerabilities in upstream projects unless caused by this repository's configuration
- vulnerabilities in NVIDIA drivers or CUDA
- vulnerabilities in k3s
- vulnerabilities in NVIDIA GPU Operator
- vulnerabilities in vLLM
- vulnerabilities in Open WebUI
- vulnerabilities in Mistral model weights
- vulnerabilities caused by local modifications not present in this repository
- production hardening requests for environments beyond this demo

Please report upstream vulnerabilities to the relevant upstream project.

---

## Demo security boundaries

This repository is not a production security architecture.

It does not provide by default:

- enterprise SSO
- production TLS
- network policies
- hardened multi-tenant isolation
- confidential computing attestation
- audit-grade logging
- external secret management
- backup and restore
- production monitoring

The finance RAG example demonstrates Open WebUI knowledge-access behavior with synthetic data. It is not a cryptographic access-control system.

The weather agent demonstrates controlled external tool use. It requires internet access and calls Open-Meteo.

---

## Secrets policy

Do not commit:

- Hugging Face tokens
- API keys
- SSH keys
- private certificates
- production credentials
- customer data
- internal company data
- real finance data

The Hugging Face token should be created locally as a Kubernetes Secret:

```bash
kubectl -n llm create secret generic hf-token   --from-literal=token=hf_YOUR_TOKEN_HERE
```

Never commit the real value.

---

## Open WebUI tools warning

Open WebUI tools execute Python code on the Open WebUI server.

Only trusted admins should create or edit tools.

Tool examples in this repository should be treated as demo code and reviewed before use.

---

## Disclosure expectations

The maintainer will try to acknowledge valid security reports in a reasonable time.

Fix timing depends on severity, reproducibility, and maintainer availability.

Please do not publicly disclose a vulnerability before the maintainer has had a reasonable opportunity to investigate and respond.
