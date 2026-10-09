# MoonFlux

MoonFlux is a pure MoonBit InfluxDB v2 toolkit:

- typed `Point` builder and InfluxDB Line Protocol encoder
- Line Protocol parser with escape and quoted-string handling
- annotated CSV parser for Flux query responses
- small HTTP client for `/health`, `/api/v2/write`, and `/api/v2/query`
- command-line interface for ping, write, query, and encode

## Install

```text
moon add zkc-long/moonflux
```

## Library

```moonbit
let point = @moonflux.new_point("weather")
  .add_tag("location", "shanghai")
  .add_field("temperature", @moonflux.DoubleValue(21.5))
  .add_field("ok", @moonflux.BoolValue(true))

let line = @moonflux.encode_point(point).unwrap()
let parsed = @moonflux.parse_line(line).unwrap()
```

For HTTP access:

```moonbit
let config = @client.ClientConfig(
  url="http://localhost:8086",
  token="my-token",
  org="my-org",
  bucket="my-bucket",
)
let client = @client.new_client(config)
let status = client.write(line)
```

## CLI

```text
moon run cmd/main -- ping --url http://localhost:8086
moon run cmd/main -- write --url http://localhost:8086 --token my-token --org my-org --bucket my-bucket --data "weather,location=shanghai temperature=21.5"
moon run cmd/main -- query --url http://localhost:8086 --token my-token --org my-org --query "from(bucket: \"my-bucket\")"
moon run cmd/main -- encode --measurement weather --field 21.5
```

## Development

```text
moon check
moon test
```

Native builds require a system C compiler. Library tests run on the default backend.
