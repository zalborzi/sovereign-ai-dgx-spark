import json
import requests
from pydantic import Field


class Tools:
    def __init__(self):
        pass

    def weather_travel_advice(
        self,
        location: str = Field(
            ...,
            description="City or place name, for example Luxembourg, Paris, Brussels, or London.",
        ),
        day: str = Field(
            "tomorrow",
            description="Use 'today' or 'tomorrow'.",
        ),
        activity: str = Field(
            "outdoor customer demo",
            description="The planned activity, for example outdoor customer demo, walking meeting, lunch, or travel.",
        ),
    ) -> str:
        """
        Get live weather from Open-Meteo and return structured travel/outdoor activity advice.

        This tool uses:
        - Open-Meteo Geocoding API
        - Open-Meteo Forecast API

        No API key is required.
        """

        try:
            selected_day = day.lower().strip()

            if selected_day not in ["today", "tomorrow"]:
                selected_day = "tomorrow"

            # 1. Convert location name to coordinates.
            geo_response = requests.get(
                "https://geocoding-api.open-meteo.com/v1/search",
                params={
                    "name": location,
                    "count": 1,
                    "language": "en",
                    "format": "json",
                },
                timeout=10,
            )
            geo_response.raise_for_status()
            geo = geo_response.json()

            if not geo.get("results"):
                return json.dumps(
                    {
                        "status": "error",
                        "message": f"No location found for: {location}",
                    },
                    indent=2,
                )

            place = geo["results"][0]
            lat = place["latitude"]
            lon = place["longitude"]
            name = place.get("name", location)
            country = place.get("country", "")

            # 2. Fetch daily forecast.
            forecast_response = requests.get(
                "https://api.open-meteo.com/v1/forecast",
                params={
                    "latitude": lat,
                    "longitude": lon,
                    "daily": ",".join(
                        [
                            "temperature_2m_max",
                            "temperature_2m_min",
                            "precipitation_probability_max",
                            "precipitation_sum",
                            "wind_speed_10m_max",
                        ]
                    ),
                    "forecast_days": 3,
                    "timezone": "auto",
                },
                timeout=10,
            )
            forecast_response.raise_for_status()
            forecast = forecast_response.json()

            daily = forecast["daily"]

            if selected_day == "today":
                idx = 0
                label = "today"
            else:
                idx = 1
                label = "tomorrow"

            forecast_date = daily["time"][idx]
            temp_min = daily["temperature_2m_min"][idx]
            temp_max = daily["temperature_2m_max"][idx]
            rain_probability = daily["precipitation_probability_max"][idx]
            precipitation_mm = daily["precipitation_sum"][idx]
            wind_speed = daily["wind_speed_10m_max"][idx]

            # 3. Recommendation logic.
            if rain_probability >= 70 or precipitation_mm >= 5:
                recommendation = "Move indoors"
                reason = "high rain risk"
            elif rain_probability >= 40 or precipitation_mm > 1:
                recommendation = "Go ahead with caution"
                reason = "some rain risk"
            elif wind_speed >= 35:
                recommendation = "Go ahead with caution"
                reason = "wind may be uncomfortable"
            elif temp_max >= 32:
                recommendation = "Go ahead with caution"
                reason = "hot weather may be uncomfortable"
            elif temp_max <= 3:
                recommendation = "Go ahead with caution"
                reason = "cold weather may be uncomfortable"
            else:
                recommendation = "Go ahead"
                reason = "weather looks acceptable"

            result = {
                "status": "ok",
                "location": f"{name}, {country}".strip(", "),
                "activity": activity,
                "day": label,
                "date": forecast_date,
                "temperature_min_c": temp_min,
                "temperature_max_c": temp_max,
                "rain_probability_max_percent": rain_probability,
                "precipitation_mm": precipitation_mm,
                "wind_speed_max_kmh": wind_speed,
                "recommendation": recommendation,
                "reason": reason,
            }

            return json.dumps(result, indent=2)

        except requests.RequestException as e:
            return json.dumps(
                {
                    "status": "error",
                    "message": f"Live weather check failed: {str(e)}",
                },
                indent=2,
            )

        except Exception as e:
            return json.dumps(
                {
                    "status": "error",
                    "message": f"Unexpected weather tool error: {str(e)}",
                },
                indent=2,
            )
