# MoonFlux 开发历程

## 目标确定

项目从一个具体生态缺口开始：MoonBit 已有 MongoDB、Neo4j、ClickHouse 等接入库，但没有 InfluxDB v2 客户端。MoonFlux 因此选择时序数据协议方向，目标是补齐从数据建模、Line Protocol 写入到 Flux 查询结果解释的完整链路。

## 第一阶段：协议基础

先实现 Point 模型、Line Protocol 转义、编码、解析和 Point 校验。此阶段重点处理容易在真实服务端失败的边界：逗号、等号、空格、引号字符串、重复 key 和非有限浮点数。

## 第二阶段：查询客户端

接入 MoonBit async HTTP 能力，实现 `/health`、`/api/v2/write`、`/api/v2/query`。URL 参数进行百分号编码，非 2xx 响应返回状态码和服务端正文，CLI 支持文件批量写入、precision 和环境变量。

## 第三阶段：真实服务验收

使用 Docker 启动真实 InfluxDB v2，由 CI 执行 native 测试、写入、查询和断言。这个阶段暴露并修正了依赖注册、default target、CLI native target 和集成脚本顺序问题。

## 第四阶段：审核反馈与协议深化

初审反馈指出项目不能停留在轻量编解码和接口封装。随后补充了 Flux 多表 annotated CSV 语义：表边界、独立 schema、`#datatype`、`#group`、`#default`、类型化单元格、table id、group key 和 JSON 输出，并把 union、group、aggregateWindow 等查询案例纳入测试和集成验收。

## AI 工具使用方式

开发过程中使用大模型辅助梳理官方要求、生成边界测试样例、审查 MoonBit 语法和编写集成脚本；协议设计、模块边界、错误语义、测试预期和最终提交由参赛者审核并负责。AI 不是项目目标的替代品，项目目标是把真实时序数据接口做成可运行、可验证、可维护的 MoonBit 系统。

## 后续计划

- 将 MoonFlux 发布到 Mooncakes；
- 增加更多多表、pivot、join 和错误响应样例；
- 增加覆盖率和性能基准；
- 补充实际业务接入示例和应用反馈。
