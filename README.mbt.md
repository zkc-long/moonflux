# MoonFlux

MoonFlux is a pure MoonBit InfluxDB v2 toolkit:

- typed `Point` builder and InfluxDB Line Protocol encoder
- Line Protocol parser with escape and quoted-string handling
- annotated CSV parser for Flux query responses
- multi-table Flux result model with typed cells and group keys
- small HTTP client for `/health`, `/api/v2/write`, and `/api/v2/query`
- command-line interface for ping, write, query, and encode
- Docker-based integration smoke test against a real InfluxDB v2 instance

## Install

```text
moon add zkc-long/moonflux
```

## Library

```moonbit nocheck
///|
let point = @moonflux.new_point("weather")
  .add_tag("location", "shanghai")
  .add_field("temperature", @moonflux.DoubleValue(21.5))
  .add_field("ok", @moonflux.BoolValue(true))

///|
let line = @moonflux.encode_point(point).unwrap()

///|
let parsed = @moonflux.parse_line(line).unwrap()
```

For HTTP access:

```moonbit nocheck
///|
let config = @client.ClientConfig(
  url="http://localhost:8086",
  token="my-token",
  org="my-org",
  bucket="my-bucket",
)

///|
let client = @client.new_client(config)

///|
let status = client.write(line)
```

The client also exposes `write_with_precision` for `ns`, `us`, `ms`, or `s`
timestamp precision.

For full Flux result semantics:

```moonbit nocheck
///|
match client.query_flux("from(bucket: \"my-bucket\") |> range(start: -1h)") {
  Ok(result) => println(result.table_count())
  Err(error) => println(error)
}
```

## CLI

```text
moon run --target native cmd/main -- ping --url http://localhost:8086
moon run --target native cmd/main -- write --url http://localhost:8086 --token my-token --org my-org --bucket my-bucket --data "weather,location=shanghai temperature=21.5"
moon run --target native cmd/main -- write --url http://localhost:8086 --token my-token --org my-org --bucket my-bucket --file points.lp --precision ns
moon run --target native cmd/main -- query --url http://localhost:8086 --token my-token --org my-org --query "from(bucket: \"my-bucket\")"
moon run --target native cmd/main -- query --format json --url http://localhost:8086 --token my-token --org my-org --query "from(bucket: \"my-bucket\") |> group(columns: [\"host\"])"
moon run --target native cmd/main -- encode --measurement weather --field 21.5
```

CLI options fall back to `INFLUX_URL`, `INFLUX_TOKEN`, `INFLUX_ORG`, and
`INFLUX_BUCKET`.

## InfluxDB Smoke Test

The MVP scope, acceptance criteria, and known boundaries are documented in
`docs/MVP.zh-CN.md`.

The Chinese project application draft is available at
`docs/APPLICATION.zh-CN.md`.

Multi-table query semantics are documented in
`docs/FLUX_QUERY_SEMANTICS.zh-CN.md`, and the official requirement map is in
`docs/OFFICIAL_REQUIREMENTS.zh-CN.md`.

```text
docker compose up -d
bash scripts/integration.sh
docker compose down
```

## Development

```text
moon check
moon test
```

Native builds require a system C compiler. Library tests run on the default backend.
