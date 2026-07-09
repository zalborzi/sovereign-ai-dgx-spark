# Weather Travel Agent

A small Open WebUI tool-calling demo for the **Sovereign AI on NVIDIA DGX Spark** project.

The agent answers practical travel and outdoor-planning questions by calling the live Open-Meteo weather API and returning a simple recommendation.

Example question:

```text
Should I do an outdoor customer demo in Luxembourg tomorrow?
```

Expected behavior:

```text
User question
→ Weather Travel Agent
→ Open-Meteo weather tool call
→ weather JSON
→ practical recommendation
```

This is intentionally simple and demo-friendly:

- no API key
- no OAuth
- no Booking.com scraping
- no Google Flights scraping
- no production secrets
- low risk for a local demo

---

## Files

```text
examples/weather-travel-agent/
├── README.md
├── open_meteo_weather_tool.py
├── system-prompt.md
├── test-prompts.md
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

The weather tool needs internet access because it calls Open-Meteo.

---

## 1. Test internet from the Open WebUI pod

Use `-i`. Without `-i`, the heredoc will not be passed into the pod correctly.

```bash
kubectl -n ui exec -i deployment/openwebui -- python - <<'PY'
import urllib.request

url = "https://geocoding-api.open-meteo.com/v1/search?name=Luxembourg&count=1&language=en&format=json"
print(urllib.request.urlopen(url, timeout=10).read()[:500].decode())
PY
```

Expected: JSON containing Luxembourg.

If this fails, the tool will not work.

---

## 2. Create the Open WebUI tool

In Open WebUI:

```text
Admin user → Workspace → Tools → Create Tool
```

Remove the sample code and paste the full content of:

```text
open_meteo_weather_tool.py
```

Save the tool as:

```text
Open-Meteo Weather Tool
```

---

## 3. Create the Weather Travel Agent model

In Open WebUI:

```text
Workspace → Models → Create Model
```

Recommended settings:

```text
Name: Weather Travel Agent
Base model: mistralai/Mistral-7B-Instruct-v0.3
Visibility: Public
Knowledge: none
Tools: Open-Meteo Weather Tool
Function Calling: Legacy
```

Use the content of:

```text
system-prompt.md
```

as the system prompt.

Important:

```text
Use Legacy function calling for this demo.
```

Do not use native tool calling unless you deliberately want to debug vLLM tool parsers.

---

## 4. Test

Start a new chat.

Select:

```text
Weather Travel Agent
```

Ask:

```text
Should I do an outdoor customer demo in Luxembourg tomorrow?
```

Expected:

- a visible tool call appears
- answer mentions location, date, temperature, rain probability, precipitation, wind
- answer gives one of:
  - Go ahead
  - Go ahead with caution
  - Move indoors
  - Reschedule

The tool call line should look similar to:

```text
open_meteo_weather_tool/weather_travel_advice
```

---

## 5. Good demo story

Say this during the demo:

```text
This is still the same local Mistral model running on DGX Spark.
For this use case, the model is allowed to call one external weather tool.
The LLM does not know the live weather itself; it calls the tool, receives structured data, and turns that into a practical recommendation.
```

This demonstrates:

```text
Local LLM + controlled tool use + live external data + decision support
```

---

## 6. Security note

Open WebUI tools execute Python code on the Open WebUI server.

Only admins should create or edit tools.

Do not paste untrusted tool code into Open WebUI.
