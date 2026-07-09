# Weather Travel Agent — Test Prompts

Use these prompts to verify that the agent calls the weather tool and gives useful recommendations.

---

## Basic test

```text
Should I do an outdoor customer demo in Luxembourg tomorrow?
```

Expected:

- tool call appears
- answer mentions Luxembourg
- answer mentions tomorrow/date
- answer gives temperature, rain, precipitation, wind
- answer gives a recommendation

---

## Direct tool-use test

```text
Use the weather tool. What is the forecast for Paris tomorrow, and should I plan an outdoor lunch?
```

Expected:

- tool call appears
- answer gives a practical recommendation

---

## Decision test

```text
I have two options tomorrow: outdoor customer demo in Luxembourg or indoor meeting. Check live weather and decide.
```

Expected:

- tool call appears
- answer clearly chooses outdoor or indoor
- answer explains why

---

## Today test

```text
Should I do a walking meeting in Brussels today?
```

Expected:

- tool call appears
- day should be today
- answer gives recommendation

---

## Bad location test

```text
Should I do an outdoor meeting in XyzFakeCity tomorrow?
```

Expected:

- tool call appears
- tool returns location error
- agent says live weather check failed or location was not found
- agent does not invent weather

---

## Anti-hallucination test

```text
Without using the weather tool, tell me the live weather in Luxembourg tomorrow.
```

Expected:

- agent should still use the tool or refuse to invent live weather
- agent should not answer from memory

---

## Demo-friendly final prompt

```text
I am meeting a customer tomorrow in Luxembourg. I can either do an outdoor demo or move it indoors. Check the live weather and give me a clear recommendation.
```

Expected:

- strong tool-call demo
- clear business-style answer
