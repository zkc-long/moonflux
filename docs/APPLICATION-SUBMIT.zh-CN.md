# MoonFlux 项目申报书

## 1. 项目名称

MoonFlux：MoonBit 的 InfluxDB v2 时序数据协议工具链

## 2. 项目简介

MoonFlux 为 MoonBit 生态补齐 InfluxDB v2 时序数据接入能力。项目不只是 HTTP 请求封装，而是独立实现 Line Protocol 编解码、Point 校验、Flux 查询结果协议解释和 annotated CSV 多表语义处理。MoonBit 服务、边缘采集程序、CI 性能监控和数据处理工具可以直接复用该库或 CLI。

## 3. 项目方向与通用性

项目属于工具库、数据处理和开发者工具方向。它不绑定具体业务模型，提供可复用的 Point 模型、协议编码器、HTTP 客户端、Flux 查询结果模型和 CLI，可用于任何需要 InfluxDB v2 的 MoonBit 项目。

## 4. 预期使用场景

1. 服务端监控：将请求量、延迟和内存指标写入 InfluxDB，再通过 Flux 查询生成监控报表。
2. 边缘采集：MoonBit 程序采集传感器数据，按 Line Protocol 上报，并查询历史趋势和异常区间。
3. 构建与性能分析：CI 或基准测试将编译时间、测试耗时写入 InfluxDB，查询多表结果定位性能回退。
4. 数据处理工具：其他 MoonBit 库复用 Point、Line Protocol 和 Flux 结果语义，构建导入、清洗和可视化工具。

## 5. 核心功能与边界

- 类型化 Point：measurement、tag、field、timestamp。
- Line Protocol：编码、解析、转义、引号字段、批量行和 Point 校验。
- InfluxDB v2 客户端：`/health`、`/api/v2/write`、`/api/v2/query`。
- Flux 结果语义：多表 section、`table` 列逻辑表切换、每表独立 schema、`#datatype`、`#group`、`#default`、typed cells、group key 和 JSON 输出。
- 多表案例：支持 `group()`、`union()`、`aggregateWindow()` 等查询产生的多 measurement、多 host、多窗口结果。
- CLI：`ping`、`write`、`query`、`encode`、文件批量写入、precision、环境变量和 `--format json`。

范围边界：暂不支持 InfluxDB 3 Flight/Arrow、InfluxDB 1.x、OAuth、自动重试和 gzip；这些不影响当前协议闭环。

## 6. 技术路线与验证

采用 MoonBit 分层实现：`moonflux.mbt` 负责数据模型，`line_protocol.mbt`/`escape.mbt` 负责协议编解码，`flux_result.mbt` 负责多表查询语义，`client/` 负责网络接口，`cmd/main/` 提供 CLI。核心测试覆盖单表、多表、类型错误、转义、校验和 JSON 输出；CI 使用真实 InfluxDB v2 执行写入、分组查询和多表断言。

## 7. 原创性与开源说明

MoonFlux 是原创项目，不是移植项目，没有复制其他 InfluxDB 客户端代码。项目依据 InfluxDB v2 官方 HTTP API、Line Protocol 和 annotated CSV 公开规范实现，使用 `moonbitlang/async` 作为通用异步依赖，许可证为 Apache-2.0。

## 8. GitHub 仓库

https://github.com/zkc-long/moonflux

仓库保留公开开发历史、README、可运行示例、单元测试、native 测试、Docker Compose 验收环境和真实 InfluxDB 集成测试。当前已有超过 10 个有效 commit，最新 CI 的单元测试与真实服务集成任务均通过。
