# MoonFlux 项目申报书

## 基本信息

- 项目名称：MoonFlux：纯 MoonBit 的 InfluxDB v2 客户端与 Line Protocol 工具链
- 参赛者：朱科承
- GitHub ID：zkc-long
- GitHub 仓库链接：https://github.com/zkc-long/moonflux
- 项目方向：MoonBit 数据基础设施 / 网络协议客户端 / 开发者工具
- 项目性质：原创项目，非移植项目

## 项目简介

MoonFlux 为 MoonBit 生态补齐 InfluxDB v2 客户端与 Line Protocol 基础设施，使 MoonBit 程序能够直接完成时序数据点的构造、编码、写入、Flux 查询和 annotated CSV 结果解析。项目面向 MoonBit 服务端程序、CLI、边缘数据采集、构建与基准测试等需要在真实时序数据库中持久化和分析数据的场景。

目前项目已实现纯 MoonBit 的 Line Protocol 编解码与校验、InfluxDB v2 的 `/health`、`/api/v2/write`、`/api/v2/query` 客户端、annotated CSV 解析器，以及 `ping`、`write`、`query`、`encode` 四个 CLI 命令。项目通过 GitHub Actions 对真实 InfluxDB v2 实例执行写入和查询集成测试。

## 项目方向与通用性

MoonFlux 定位为 MoonBit 的通用时序数据接入层。它不依赖特定业务模型，也不改变 InfluxDB 协议，而是提供可复用的 Point 模型、协议编码器、HTTP 客户端和查询结果解析器。库包可被原生 MoonBit 应用、CLI、Web 后端和其他 MoonBit 库直接复用，CLI 则可用于脚本、CI 和本地调试。

## 预期使用场景

1. 服务端运行时指标采集：MoonBit 服务将请求量、延迟、内存等指标构造成 Point，批量写入 InfluxDB，再通过 Flux 查询并生成监控报表。
2. 边缘设备与传感器数据上报：MoonBit 编写的采集程序读取传感器数据，按 Line Protocol 写入 InfluxDB，并使用查询接口获取历史趋势和异常区间。
3. 构建与性能基准分析：MoonBit 项目的 CI 或基准测试脚本把编译时间、测试耗时和内存数据写入 InfluxDB，查询后自动生成趋势数据，用于定位性能回退。
4. 时序数据处理工具开发：其他 MoonBit 库可以复用 MoonFlux 的 Point、Line Protocol 和 annotated CSV 模块，构建数据导入、数据清洗或可视化工具。

## 拟实现与已完成的核心功能

- 提供类型安全的 Point 模型，支持 measurement、tag、field 和纳秒时间戳；
- 实现 InfluxDB Line Protocol 编码与解析，覆盖整数、无符号整数、浮点数、布尔值和字符串字段；
- 实现转义、引号字段、重复 key、空 key 和非有限浮点数校验；
- 实现 InfluxDB v2 HTTP 客户端的健康检查、写入和 Flux 查询接口；
- 实现查询失败与服务端错误正文反馈，支持 URL 参数编码和 timestamp precision；
- 实现 annotated CSV 解析器，保留列类型、group 和 default 元数据；
- 提供 CLI，支持 `ping`、`write`、`query`、`encode`、文件批量写入和环境变量配置；
- 提供单元测试、格式检查、严格静态检查和真实 InfluxDB v2 集成测试；
- 提供 README、MVP 验收文档和 Docker Compose 验收环境。

## 原创性与参考说明

MoonFlux 是原创项目，不是已有项目的移植，也没有复制其他语言的 InfluxDB 客户端代码。项目依据 InfluxDB v2 官方 HTTP API、Line Protocol 和 annotated CSV 公开规范独立实现；使用 `moonbitlang/async` 作为 MoonBit 网络与异步基础设施依赖。项目采用 Apache-2.0 许可证。

## 后续计划

- 将 MoonFlux 发布到 Mooncakes；
- 增加 annotated CSV 到强类型结果的转换辅助函数；
- 补充重试、超时、gzip 和构建性能基准；
- 增加更多真实 InfluxDB 版本的兼容性测试。
