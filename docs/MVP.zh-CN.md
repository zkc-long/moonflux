# MoonFlux 十月黑客松 MVP

## 一句话目标

用纯 MoonBit 提供一个可用的 InfluxDB v2 客户端、Line Protocol 工具和 CLI，让 MoonBit 用户能够完成“构造数据 -> 写入 InfluxDB -> Flux 查询 -> 解析 annotated CSV”的最小闭环。

## MVP 范围

### 已完成

- `Point` 数据模型，支持 measurement、tag、field 和纳秒时间戳
- Line Protocol 编码，覆盖整数、无符号整数、浮点、布尔和字符串字段
- Line Protocol 解析，覆盖转义、引号字段、tag 和可选 timestamp
- Point 校验，拒绝空 measurement、空字段集、空 key、重复 key 和非有限浮点数
- InfluxDB annotated CSV 解析，保留 `#datatype`、`#group`、`#default` 元数据
- InfluxDB v2 HTTP 客户端
  - `GET /health`
  - `POST /api/v2/write`
  - `POST /api/v2/query`
- URL 参数百分号编码，支持带空格或斜杠的 org、bucket 和 precision
- 写失败时返回状态码和服务端错误正文，而不是把 4xx/5xx 当作成功
- CLI 的 `ping`、`write`、`query`、`encode` 命令
- CLI 支持 `--file` 批量写入 Line Protocol 文件和 `--precision`
- CLI 支持 `INFLUX_URL`、`INFLUX_TOKEN`、`INFLUX_ORG`、`INFLUX_BUCKET`
- GitHub Actions 执行 `moon check` 和 `moon test`
- GitHub Actions 使用 Docker 启动真实 InfluxDB v2 执行 write/query 集成验收

### MVP 边界

- 当前只支持 InfluxDB v2 token 认证，不支持 OAuth、用户名密码或 InfluxDB 1.x
- 当前不支持 InfluxDB 3 的 Flight、SQL、Arrow 或 Parquet 接口
- 当前不实现自动重试、gzip 请求压缩和连接池调优
- annotated CSV 当前提供结构化解码，不把 `_value` 自动转成强类型枚举
- 当前只提供 native CLI，不提供独立发布的单文件二进制

这些边界不阻塞十月 MVP，但应在比赛申报和演示中明确说明。

## 验收标准

1. `moon check` 无错误。
2. `moon test` 全部通过。
3. 对真实 InfluxDB v2 执行 `write` 成功返回 2xx。
4. 对真实 InfluxDB v2 执行 `query` 能得到 annotated CSV 并打印结果。
5. 错误 token、错误 bucket 或非法 Line Protocol 返回非零状态和可读错误。
6. GitHub Actions 的 `ci` workflow 为绿色。

## 真实环境验收

仓库提供 `docker-compose.yml` 和 `scripts/integration.sh`。在安装 Docker、MoonBit 和 C 编译器的环境中运行：

```text
docker compose up -d
bash scripts/integration.sh
docker compose down
```

脚本会等待 InfluxDB 就绪，然后通过 MoonFlux CLI 写入两个 point，并用 Flux 查询其中一个 measurement。

## 后续优先级

### P1

- 增加 annotated CSV 强类型转换辅助函数
- 增加 LINE PROTOCOL 文件读取和行号错误信息
- 增加查询结果到 JSON 的输出命令

### P2

- InfluxDB 3 Flight/Arrow 支持
- 重试、退避、请求限流
- 发布 Mooncakes 包和版本变更日志
- 提供 Windows、Linux、macOS 单文件 CLI

## 比赛材料建议

- 演示 1：用 CLI 的 `encode` 展示纯 MoonBit Line Protocol 编码
- 演示 2：用 `--file` 向真实 InfluxDB 批量写入
- 演示 3：用 Flux 查询并在终端展示 annotated CSV 解析结果
- 演示 4：故意写入非法 field，展示客户端返回服务端错误正文
- 展示 GitHub Actions 的单元测试和集成测试结果
