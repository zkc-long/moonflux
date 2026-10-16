# 官方要求对应表

依据 MoonBit 2026 黑客松官方页面和申报表，当前项目对应关系如下。

十月赛报名与验收截止时间为 2026 年 10 月 31 日；十月最多提交或修改 3 次，未通过审核的项目可以继续修改。当前官方验收口径不以代码行数为唯一指标，重点看清晰边界、工程结构、测试、文档、真实可用性和可解释性。

| 官方要求 | MoonFlux 证据 |
| --- | --- |
| MoonBit 为主要实现语言 | 根包、client、CLI、测试均为 MoonBit 源码 |
| 公开仓库和连续开发记录 | GitHub `zkc-long/moonflux`，连续 commit、CI 和集成任务 |
| 清晰 README | `README.mbt.md` 包含目标、功能、安装、库 API、CLI 和验收 |
| 可运行示例 | `examples/line_protocol.mbt`、CLI 示例、Docker 集成脚本 |
| 必要测试 | Line Protocol、校验、CSV、多表 Flux 结果、native 测试和真实 InfluxDB 集成 |
| 项目目标与应用场景 | 申报书第一节和场景列表 |
| 交付物与 Scope | 申报书第三节，明确已实现和暂不支持范围 |
| 技术路线与模块划分 | 申报书第五节和 `FLUX_QUERY_SEMANTICS.zh-CN.md` |
| 风险分析 | 申报书第六节 |
| 相关研究和实践基础 | 申报书第七节 |
| 原创、移植或参考说明 | 原创项目，Apache-2.0，参考公开协议，不复制客户端实现 |
| AI 可解释性 | `DEVELOPMENT_LOG.zh-CN.md` 记录 AI 使用方式和人工审核边界 |
| 多表查询协议语义案例 | `FLUX_QUERY_SEMANTICS.zh-CN.md` 和 `flux_result.mbt` |
| 十月赛方向：工具库/数据处理/开发者工具 | InfluxDB v2 协议库、数据查询结果处理和 CLI |
| 十月赛最多 3 次提交 | 申报材料应只提交稳定的审核版本，提交前保留完整 Git 记录 |

## 尚未完成的外部动作

以下事项不是代码质量问题，但提交前需要完成：

- 使用参赛者账号登录 Mooncakes 并发布 MoonFlux 包；
- 保持公开仓库的提交、Issues、PR 和更新记录可追溯；
- 按赛事要求填写报名表并加入赛事群；
- 准备开发历程文章的最终个人心得版本。
