#!/usr/bin/env bash

# Get the external IP address using ipecho.net
EXTIP="$(curl -s https://ipecho.net/plain)"

# Get the latitude and longitude based on the IP address
LOCATION="$(curl -s http://ip-api.com/json/)"
LAT=$(echo "$LOCATION" | jq -r '.lat')
LON=$(echo "$LOCATION" | jq -r '.lon')

# Fetch weather data from Open-Meto API
WEATHER=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&current_weather=true&daily=temperature_2m_max,temperature_2m_min,weathercode")

# Extract the current temperature
TEMP=$(echo "$WEATHER" | jq -r '.current_weather.temperature')

# Convert to Fahrenheit
fahrenheit=$(echo "scale=2; ($TEMP * 9 / 5) + 32" | bc)

# Extract the citny and country from the location data
city=$(echo "$LOCATION" | jq -r '.city')
country=$(echo "$LOCATION" | jq -r '.country')

# Display the results
echo "Current weather in $city, $country:"
echo "Temperature: $TEMP°C ($fahrenheit°F)"
