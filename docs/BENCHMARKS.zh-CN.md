# MoonFlux 基准数据

## 运行方式

基准程序位于 `bench/main.mbt`，输入数据由程序确定性生成，不依赖网络、数据库或随机种子。

```text
moon run --target native bench
```

Windows 本机也验证了 wasm-gc 后端：

```text
moon run --target wasm-gc bench
```

## 本机结果

采集日期：2026-11-02  
后端：wasm-gc  
MoonBit：0.1.20261012  
操作单位：微秒/次，`mean` 为 5 次运行的平均值

| 基准 | mean | median | std dev | 近似吞吐 |
| --- | ---: | ---: | ---: | ---: |
| 编码 10,000 个 Point | 17,089.22 | 16,565.47 | 1,537.53 | 585,000 points/s |
| 解析 10,000 行 Line Protocol | 40,979.25 | 39,142.77 | 5,529.00 | 244,000 lines/s |
| 解析 10,000 行多表 annotated CSV | 22,928.43 | 23,651.30 | 1,895.65 | 436,000 rows/s |

CI Linux native 结果（与 wasm-gc 使用同一输入，GitHub Actions `ubuntu-latest`）：

| 基准 | mean | median | std dev | 近似吞吐 |
| --- | ---: | ---: | ---: | ---: |
| 编码 10,000 个 Point | 35,594.64 | 35,612.62 | 39.53 | 281,000 points/s |
| 解析 10,000 行 Line Protocol | 76,582.45 | 75,085.78 | 4,033.01 | 131,000 lines/s |
| 解析 10,000 行多表 annotated CSV | 33,785.07 | 34,194.16 | 758.04 | 296,000 rows/s |

原始结果分别保存在：

- `bench/results/wasm-gc-2026-11-02.json`
- `bench/results/native-linux-2026-11-02.json`

原始 JSON 输出保存在运行日志中；CI 的 `benchmark` job 会使用 Linux native 后端再次执行同一输入。基准结果用于版本间回归对比，不作为跨机器绝对性能承诺。
