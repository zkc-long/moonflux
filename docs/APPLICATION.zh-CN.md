# MoonFlux 项目申报书

## 一、项目目标与应用场景

MoonFlux 的目标是在 MoonBit 生态中补齐 InfluxDB v2 时序数据接入协议，而不是只提供一层 HTTP 请求封装。项目要让 MoonBit 程序能够独立完成时序数据建模、Line Protocol 编码、InfluxDB 写入、Flux 查询以及多表 annotated CSV 结果解释。它服务于 MoonBit 服务端、边缘采集程序、CI 性能监控、运维工具和其他数据处理库。

## 二、项目基本信息

- 项目名称：MoonFlux：MoonBit 的 InfluxDB v2 时序数据协议工具链
- 参赛者：朱科承
- GitHub ID：zkc-long
- GitHub 仓库链接：https://github.com/zkc-long/moonflux
- 项目方向：MoonBit 数据基础设施 / 网络协议语义 / 开发者工具
- 项目性质：原创项目，非移植项目
- 许可证：Apache-2.0

## 三、交付物说明

### 1. 核心功能范围

- Point 数据模型：measurement、tag、field、timestamp 和类型化字段；
- Line Protocol 编解码：转义、引号字段、整数、无符号整数、浮点数、布尔、时间戳和批量行；
- Point 校验：空 key、重复 tag/field key、非有限浮点数和协议边界错误；
- InfluxDB v2 HTTP 客户端：`/health`、`/api/v2/write`、`/api/v2/query`；
- 查询协议语义：多表 annotated CSV、每表独立 schema、`#datatype`、`#group`、`#default`、table 边界、类型化单元格和 group key；
- 查询结果输出：终端多表视图、原始 JSON、CLI 文件写入和环境变量配置；
- 工程交付：README、示例、单元测试、native 测试、真实 InfluxDB 集成测试和 Docker 验收脚本。

### 2. 功能边界

首个版本聚焦 InfluxDB v2 token 认证、Line Protocol 和 Flux/annotated CSV 协议语义；暂不实现 InfluxDB 3 Flight/Arrow、OAuth、InfluxDB 1.x 兼容、自动重试和 gzip。这些边界在 README 和验收文档中明确列出，避免把“未实现”误认为“已支持”。

### 3. 预期使用方式

库用户通过 `Point` 构造数据，通过 `encode_point` 或 `encode_points` 生成 Line Protocol，通过 `Client::write_with_precision` 写入 InfluxDB，再通过 `Client::query_flux` 获得 `FluxQueryResult`。CLI 用户使用 `ping`、`write`、`query`、`encode` 命令完成本地调试、批量写入和多表查询展示。

### 4. 测试与文档规划

测试分为三层：Line Protocol 和 CSV 状态机单元测试、HTTP 客户端参数与错误路径测试、真实 InfluxDB v2 的 Docker 集成测试。文档覆盖 README 快速开始、MVP 范围、多表查询案例、开发历程和验收命令。测试计划文档见 [FLUX_QUERY_SEMANTICS.zh-CN.md](FLUX_QUERY_SEMANTICS.zh-CN.md)。

## 四、多表查询协议语义案例

MoonFlux 新增的多表结果模型不把 annotated CSV 当成普通字符串矩阵，而是按照 Flux 返回协议处理：

- 每个空行表示一个结果表的结束，下一个 `#datatype` 表示新表；
- 每张表拥有独立列 schema、group key 和 default 值；
- `#datatype` 决定单元格是 string、long、unsignedLong、double、boolean、dateTime、duration 或 base64Binary；
- `#group` 决定哪些列为分组键，可用于还原 `group()`、`union()` 和 `aggregateWindow()` 的表结构；
- 相同查询可以返回多个 measurement、多个 field 或多个 host 的独立表；
- CLI 会打印 `tables: N`、每张表的 group key、列名和类型化行值，也支持 `--format json`。

示例查询：

```flux
from(bucket: "telemetry")
  |> range(start: -1h)
  |> filter(fn: (r) => r._measurement == "weather" or r._measurement == "air")
  |> group(columns: ["_measurement", "host"])
  |> mean()
```

该查询会生成 weather/host-a、weather/host-b、air/host-a、air/host-b 等多张结果表。MoonFlux 的集成脚本会对真实 InfluxDB 执行该查询，并验证表数量、measurement 覆盖和 JSON 输出。更详细的协议说明见 [FLUX_QUERY_SEMANTICS.zh-CN.md](FLUX_QUERY_SEMANTICS.zh-CN.md)。

## 五、技术路线与模块划分

- `moonflux.mbt`：Point、FieldValue 和 builder；
- `line_protocol.mbt`、`escape.mbt`：Line Protocol 编码、解析和校验；
- `flux_result.mbt`：多表 CSV 状态机、类型解析、FluxTable/FluxQueryResult 和 JSON 输出；
- `client/`：InfluxDB v2 HTTP 客户端、URL 编码、错误正文和查询接口；
- `cmd/main/`：面向人的 CLI 入口；
- `.github/workflows/ci.yml`、`scripts/integration.sh`、`docker-compose.yml`：可复现质量门禁和真实服务验收。

开发过程中使用大模型和智能体辅助需求拆解、边界样例生成、代码审查和集成脚本编写；所有协议语义、接口取舍、测试断言和最终代码由参赛者审核。项目参考 InfluxDB v2 官方 HTTP API、Line Protocol 和 annotated CSV 公开规范，不复制其他客户端的实现代码。

## 六、风险分析与应对方案

- 协议边界风险：通过多表、不同 schema、default、空值和类型错误样例测试，而不是只覆盖单表 happy path；
- 真实服务兼容风险：通过 Docker InfluxDB v2 集成任务验证真实 write/query，而不是只做 mock；
- 网络和平台风险：客户端与 CLI 显式限制 native/js 目标，纯协议库保持 wasm 可构建；
- 范围膨胀风险：将 InfluxDB 3、重试和压缩列为后续版本，不阻塞核心协议闭环；
- AI 可解释性风险：保留开发历程文章、提交记录、模块职责和关键取舍说明。

## 七、相关研究与实践基础

相关实践包括 InfluxDB v2 HTTP API、Line Protocol、Flux 查询协议、annotated CSV 协议和 MoonBit 的 async/native 工具链。项目对现有开源客户端只做协议与接口层面的理解，不复制其实现；MoonBit 侧使用 `moonbitlang/async` 作为通用异步依赖，其余协议模型、解析状态机和错误处理由 MoonFlux 实现。

## 八、个人背景与项目匹配度

参赛者 GitHub ID 为 `zkc-long`，已在公开仓库中完成本项目从仓库初始化、协议实现、测试、CI、真实 InfluxDB 验收和文档建设的连续开发记录。项目工作与参赛者在 MoonBit 数据接入、网络协议和开发工具方向的实践目标匹配。

## 九、审核要求对应材料

- MoonBit 为主：仓库主体为 MoonBit 源码，测试和示例均使用 MoonBit；
- 公开可追踪：GitHub 仓库保留连续 commits、CI 记录和集成结果；
- 可运行可复现：README、Docker Compose、integration script 和 CI 命令可直接执行；
- 测试：单元测试、native 测试、严格检查和真实 InfluxDB 集成测试；
- 原创说明：原创项目，参考公开协议，不复制参考实现，许可证为 Apache-2.0；
- 可解释性：提供开发历程文章和模块架构说明；
- 用户体验：提供 CLI、JSON 输出、环境变量、文件输入和清晰错误正文。
