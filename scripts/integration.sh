#!/usr/bin/env bash
set -euo pipefail

MOONFLUX_URL="${MOONFLUX_URL:-http://localhost:8086}"
MOONFLUX_TOKEN="${MOONFLUX_TOKEN:-moonflux-token}"
MOONFLUX_ORG="${MOONFLUX_ORG:-moonflux}"
MOONFLUX_BUCKET="${MOONFLUX_BUCKET:-telemetry}"

for _ in $(seq 1 60); do
  if curl -fsS "$MOONFLUX_URL/health" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

curl -fsS "$MOONFLUX_URL/health" >/dev/null 2>&1
moon update

moon run --target native cmd/main -- write \
  --url "$MOONFLUX_URL" \
  --token "$MOONFLUX_TOKEN" \
  --org "$MOONFLUX_ORG" \
  --bucket "$MOONFLUX_BUCKET" \
  --data "weather,host=host-a temperature=21.5,ok=true"

moon run --target native cmd/main -- write \
  --url "$MOONFLUX_URL" \
  --token "$MOONFLUX_TOKEN" \
  --org "$MOONFLUX_ORG" \
  --bucket "$MOONFLUX_BUCKET" \
  --data "air,host=host-a pm25=35i"

moon run --target native cmd/main -- write \
  --url "$MOONFLUX_URL" \
  --token "$MOONFLUX_TOKEN" \
  --org "$MOONFLUX_ORG" \
  --bucket "$MOONFLUX_BUCKET" \
  --data "weather,host=host-b temperature=22.5,ok=true"

moon run --target native cmd/main -- write \
  --url "$MOONFLUX_URL" \
  --token "$MOONFLUX_TOKEN" \
  --org "$MOONFLUX_ORG" \
  --bucket "$MOONFLUX_BUCKET" \
  --data "air,host=host-b pm25=48i"

QUERY="from(bucket: \"$MOONFLUX_BUCKET\") |> range(start: -1h) |> filter(fn: (r) => r._measurement == \"weather\" or r._measurement == \"air\") |> group(columns: [\"_measurement\", \"host\"]) |> mean()"

OUTPUT="$(moon run --target native cmd/main -- query \
  --url "$MOONFLUX_URL" \
  --token "$MOONFLUX_TOKEN" \
  --org "$MOONFLUX_ORG" \
  --query "$QUERY")"

printf '%s\n' "$OUTPUT"

if ! printf '%s' "$OUTPUT" | grep -Eq "tables: [2-9]"; then
  echo "integration query did not return multiple tables" >&2
  exit 1
fi

if ! printf '%s' "$OUTPUT" | grep -q "weather" ||
  ! printf '%s' "$OUTPUT" | grep -q "air"; then
  echo "integration query did not return both measurements" >&2
  exit 1
fi

JSON_OUTPUT="$(moon run --target native cmd/main -- query \
  --format json \
  --url "$MOONFLUX_URL" \
  --token "$MOONFLUX_TOKEN" \
  --org "$MOONFLUX_ORG" \
  --query "$QUERY")"

if ! printf '%s' "$JSON_OUTPUT" | grep -q "\"tables\""; then
  echo "JSON query output is missing tables" >&2
  exit 1
fi

echo "MoonFlux InfluxDB integration test passed"
