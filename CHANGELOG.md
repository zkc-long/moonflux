# Changelog

## 0.1.2

- Align generated package interfaces with the current MoonBit Int32 representation.
- Preserve reproducible package checks after adding batching and benchmarks.

## 0.1.1

- Add multi-table Flux result semantics, typed cells, group keys, and JSON output.
- Split logical tables by the annotated CSV `table` column.
- Add bounded Line Protocol batching by point count and byte size.
- Expand protocol boundary tests to 25 cases.
- Add deterministic 10,000-row benchmarks and CI benchmark job.
- Fix packaged-package checks for whitebox tests and restrict the filesystem CLI to native.

## 0.1.0

- Initial InfluxDB v2 client, Line Protocol toolkit, annotated CSV parser,
  CLI, Docker integration test, and GitHub Actions pipeline.
