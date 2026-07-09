# Finance RAG Access-Control Setup

This file explains how to configure the finance RAG access-control demo in Open WebUI.

---

## 1. Users

Create or use these users:

```text
admin
finance-user
normal-user
```

Recommended meaning:

```text
admin   = admin
finance-user = finance user
normal-user  = normal user
```

---

## 2. Group

Create one group:

```text
Finance Analysts
```

Add:

```text
finance-user
```

Do not add:

```text
normal-user
```

admin can remain admin.

---

## 3. Knowledge base

Create a knowledge base named:

```text
Restricted Finance Q3 2026
```

Upload:

```text
restricted-finance-q3-2026.md
```

Restrict access to:

```text
Finance Analysts
```

Make sure normal-user cannot see this knowledge base.

---

## 4. Base model

Keep the base model public:

```text
mistralai/Mistral-7B-Instruct-v0.3
```

Do not make the base model private.

Why:

```text
If the base model is private, user-specific wrapper models may fail with Model not found.
```

The demo should restrict knowledge, not the base LLM.

---

## 5. Finance model wrapper

Create a workspace model:

```text
Name: Finance Mistral
Base model: mistralai/Mistral-7B-Instruct-v0.3
Knowledge: Restricted Finance Q3 2026
Access: Finance Analysts
Function Calling: Legacy / Disabled
```

Use the content of:

```text
system-prompt.md
```

as the system prompt.

---

## 6. normal-user setup

normal-user should only have access to:

```text
mistralai/Mistral-7B-Instruct-v0.3
```

normal-user should not have access to:

```text
Restricted Finance Q3 2026
Finance Mistral
Finance Analysts group
```

---

## 7. finance-user test

Log in as finance-user.

Select:

```text
Finance Mistral
```

Ask:

```text
Using only Restricted Finance Q3 2026, answer:
1. What was DemoCorp's Q3 2026 revenue?
2. What was the confidential acquisition target estimated purchase price?
3. What did the CFO recommend about hiring?
```

Expected:

```text
Revenue: €48.7M
Acquisition target price: €18M–€22M
Hiring recommendation: freeze non-critical hiring until Q1 2027 unless Q4 revenue exceeds €52M
```

---

## 8. normal-user test

Log in as normal-user.

Select the normal public model.

Ask:

```text
What was DemoCorp's Q3 2026 revenue and acquisition target price?
```

Expected:

```text
No access to the restricted finance context.
No exact restricted numbers.
No €48.7M.
No €18M–€22M.
```

A safe response is something like:

```text
I do not have access to that restricted finance information.
```

---

## 9. Common configuration mistake

Wrong:

```text
Base model private
Finance numbers pasted into a public system prompt
Finance knowledge attached to public model
normal-user included in Finance Analysts group
```

Correct:

```text
Base model public
Finance document restricted
Finance wrapper restricted
finance-user in Finance Analysts
normal-user not in Finance Analysts
```

---

## 10. Demo principle

Use this wording:

```text
The model is shared; the data is not.
```
