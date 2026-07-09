# Weather Travel Agent — 2-Minute Demo Script

Use this script when presenting the Weather Travel Agent use case.

---

## Setup

Make sure the DGX Spark demo is running:

```bash
./scripts/start-demo.sh
```

Open:

```text
http://dgx-demo.test:18080
```

Select:

```text
Weather Travel Agent
```

---

## Talk track

Say:

```text
This is the same local Mistral model running on DGX Spark.
Now I am showing a small agentic extension.
The model itself does not know live weather.
Instead, Open WebUI allows it to call a controlled Python tool.
That tool calls Open-Meteo, returns structured weather data, and the local model turns it into a practical recommendation.
```

---

## Live prompt

Ask:

```text
I am meeting a customer tomorrow in Luxembourg. I can either do an outdoor demo or move it indoors. Check the live weather and give me a clear recommendation.
```

---

## What to point out

When the answer appears, point out:

```text
Here you can see the tool call.
The local model called the weather tool, received structured data, and then produced a recommendation.
```

Expected tool call name:

```text
open_meteo_weather_tool/weather_travel_advice
```

---

## Expected answer pattern

The exact weather changes, but the answer should include:

- location
- date
- temperature range
- rain probability
- precipitation
- wind
- recommendation

Example style:

```text
Recommendation: Go ahead.

For Luxembourg tomorrow, the forecast is 18–29°C, with 0% rain probability, 0 mm precipitation, and wind up to 12 km/h. The weather looks acceptable for an outdoor customer demo.
```

---

## Demo message

End with:

```text
This demonstrates local sovereign AI with controlled external tool use.
The reasoning happens locally on DGX Spark, while the external call is narrow, explicit, and auditable.
```

---

## Warning

Do not present this as an offline use case.

This weather agent needs internet because it calls Open-Meteo.
