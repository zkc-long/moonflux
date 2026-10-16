# Flux 多表查询语义案例

## 为什么需要多表解析

InfluxDB v2 的 Flux 查询不是单张固定表结果。`group()`、`union()`、`aggregateWindow()`、`pivot()` 等操作会改变输出表的边界、列集合和 group key。把 annotated CSV 当成单个二维数组，会丢失以下协议信息：

- 一个响应中的多个结果表；
- 每张表独立的列定义；
- `#datatype` 指定的值类型；
- `#group` 指定的分组键；
- `#default` 在空单元格上的语义；
- table 标识、result 标识和 measurement/field 元数据。

MoonFlux 使用 `FluxQueryResult`、`FluxTable`、`FluxColumn`、`FluxCell` 和 `FluxValue` 表达这些信息。

## 查询案例一：按 measurement 和 host 分组

```flux
from(bucket: "telemetry")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "weather" or r._measurement == "air")
  |> group(columns: ["_measurement", "host"])
  |> mean()
```

响应可能包含多个表，每个表对应一个 `(_measurement, host)` 组合。MoonFlux 的 `group_pairs(row)` 会返回当前行的 `_measurement` 和 `host`，而不是把 group 信息丢弃。

## 查询案例二：union 后 schema 不同的两张表

```flux
weather = from(bucket: "telemetry")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "weather")

air = from(bucket: "telemetry")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "air")

union(tables: [weather, air])
```

union 结果可能保留不同的列和数据类型。MoonFlux 使用每张表的 `columns` 单独表示 schema，不要求所有表共享同一行长度或同一类型。

## 查询案例三：aggregateWindow 的多窗口表

```flux
from(bucket: "telemetry")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "weather")
  |> aggregateWindow(every: 10m, fn: mean, createEmpty: false)
```

每张表可以有一个或多个窗口行。`table_id()`、`row_count()` 和 `group_key_string()` 可用于在 CLI 或上层应用中区分窗口组。

## MoonBit API

```moonbit
match client.query_flux(query) {
  Ok(result) => {
    println("tables: " + result.table_count().to_string())
    for table in result.tables {
      println(table.group_key_string(0))
      println(table.column_names().join(","))
      for row in table.rows {
        println(row.map(cell => @moonflux.flux_value_display(cell.value)).join(","))
      }
    }
  }
  Err(error) => println(error)
}
```

`query_flux()` 与旧版 `query()` 并存，旧接口继续接受单表 annotated CSV，新接口用于需要解释完整 Flux 查询协议的场景。

## CLI

```text
moon run --target native cmd/main -- query \
  --url http://localhost:8086 \
  --token moonflux-token \
  --org moonflux \
  --query 'from(bucket: "telemetry") |> range(start: -1h) |> group(columns: ["_measurement", "host"]) |> mean()'

moon run --target native cmd/main -- query \
  --format json \
  --url http://localhost:8086 \
  --token moonflux-token \
  --org moonflux \
  --query '...'
```

终端模式会打印 `tables: N` 和每张表的 group key；JSON 模式会保留 table、column、datatype、group、default 和类型化 value。
