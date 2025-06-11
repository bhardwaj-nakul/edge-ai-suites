#!/bin/bash

# Get HOST_IP from command line argument or .env file
if [ $# -ge 1 ]; then
  HOST_IP="$1"
  echo "Using HOST_IP from command line: $HOST_IP"
else
  echo "Error: No command line argument provided!"
  exit 1
fi

# Check for required variables
if [ -z "$HOST_IP" ]; then
  echo "Error: HOST_IP environment variable is not set."
  exit 1
fi

#############################################
# Update dashboard JSON files IP address  #
#############################################

# Prefer the new folder, then legacy grafana folder
if [ -d "./grafana/dashboards" ]; then
  DASH_DIR="./grafana/dashboards"
  echo "Found dashboards folder: $DASH_DIR"
elif [ -d "./grafana/dashboards" ]; then
  DASH_DIR="./grafana/dashboards"
  echo "Using legacy grafana dashboards folder: $DASH_DIR"
else
  echo "Warning: No dashboards folder found."
  DASH_DIR=""
fi

if [ -n "$DASH_DIR" ]; then
  for file in "$DASH_DIR"/*.json; do
    [ -f "$file" ] && sed -i "s|\"url\": *\"http://[0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}:|\"url\": \"http://$HOST_IP:|g" "$file" 
    sed -i "s|\"mqttLink\": *\"ws://[0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}:|\"mqttLink\": \"ws://$HOST_IP:|g" "$file" 
  sed -i "s|\"webrtcUrl\": *\"http://[0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}:|\"webrtcUrl\": \"http://$HOST_IP:|g" "$file"
  done
fi