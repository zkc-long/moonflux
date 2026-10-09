#!/usr/bin/env bash
set -euo pipefail

MOONFLUX_URL="${MOONFLUX_URL:-http://localhost:8086}"
MOONFLUX_TOKEN="${MOONFLUX_TOKEN:-moonflux-token}"
MOONFLUX_ORG="${MOONFLUX_ORG:-moonflux}"
MOONFLUX_BUCKET="${MOONFLUX_BUCKET:-telemetry}"

for _ in $(seq 1 60); do
  if curl -fsS "$MOONFLUX_URL/health" >/dev/null; then
    break
  fi
  sleep 2
done

curl -fsS "$MOONFLUX_URL/health" >/dev/null

moon run cmd/main -- write \
  --url "$MOONFLUX_URL" \
  --token "$MOONFLUX_TOKEN" \
  --org "$MOONFLUX_ORG" \
  --bucket "$MOONFLUX_BUCKET" \
  --data "weather,location=shanghai temperature=21.5,ok=true"

moon run cmd/main -- write \
  --url "$MOONFLUX_URL" \
  --token "$MOONFLUX_TOKEN" \
  --org "$MOONFLUX_ORG" \
  --bucket "$MOONFLUX_BUCKET" \
  --data "weather,location=shanghai temperature=22.5,ok=true"

OUTPUT="$(moon run cmd/main -- query \
  --url "$MOONFLUX_URL" \
  --token "$MOONFLUX_TOKEN" \
  --org "$MOONFLUX_ORG" \
  --query 'from(bucket: "telemetry") |> range(start: -1h) |> filter(fn: (r) => r._measurement == "weather")')"

printf '%s\n' "$OUTPUT"

if ! printf '%s' "$OUTPUT" | grep -q "temperature"; then
  echo "integration query did not return the expected field" >&2
  exit 1
fi

echo "MoonFlux InfluxDB integration test passed"
