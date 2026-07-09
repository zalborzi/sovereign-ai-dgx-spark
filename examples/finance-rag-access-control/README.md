# Finance RAG Access-Control Demo

A synthetic finance RAG demo for the **Sovereign AI on NVIDIA DGX Spark** project.

The goal is to show that the same local LLM can serve different users while respecting knowledge access boundaries.

Demo story:

```text
Same local Mistral model.
Same DGX Spark backend.
Different users.
Different knowledge access.
```

Example users:

```text
admin   = admin
finance-user = finance user
normal-user  = normal user
```

Expected behavior:

- finance-user can access the restricted synthetic finance document.
- normal-user cannot access the restricted synthetic finance document.
- The base model is shared.
- The restricted data is controlled at the Open WebUI knowledge/RAG layer.

This is not a real finance dataset. All numbers are fictional.

---

## Files

```text
examples/finance-rag-access-control/
├── README.md
├── restricted-finance-q3-2026.md
├── access-control-setup.md
├── system-prompt.md
├── test-prompts.md
├── red-team-tests.md
└── demo-script.md
```

---

## Prerequisites

The DGX Spark demo stack should already be running:

```bash
./scripts/start-demo.sh
```

Open WebUI should be available at:

```text
http://dgx-demo.test:18080
```

Recommended model:

```text
mistralai/Mistral-7B-Instruct-v0.3
```

---

## Core setup

In Open WebUI:

1. Create users:
   - admin
   - finance-user
   - normal-user

2. Create a group:

```text
Finance Analysts
```

3. Add only finance-user to:

```text
Finance Analysts
```

4. Upload this file as a restricted knowledge base:

```text
restricted-finance-q3-2026.md
```

5. Restrict the knowledge base to:

```text
Finance Analysts
```

6. Keep the base model public.

Do **not** make the base model private. If the base model is private, wrapper models or users may get `Model not found`.

---

## Recommended Open WebUI model

Create a workspace model:

```text
Name: Finance Mistral
Base model: mistralai/Mistral-7B-Instruct-v0.3
Knowledge: Restricted Finance Q3 2026
Access: Finance Analysts
Function Calling: Legacy / Disabled
```

Use `system-prompt.md` as the system prompt.

---

## What this demonstrates

This demo demonstrates:

```text
Local LLM inference + restricted RAG + user/group-based knowledge access
```

It does not claim:

- cryptographic data isolation
- production-grade authorization
- confidential computing
- enterprise SSO
- audit-grade governance

This is a local demo of access-aware RAG behavior inside Open WebUI.

---

## Strong demo line

Use this wording:

```text
The model is shared; the data is not.
finance-user and normal-user use the same local Mistral model on DGX Spark.
finance-user can retrieve the restricted finance document because she is in the Finance group.
normal-user cannot retrieve it because he is not in that group.
```
