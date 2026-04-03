# AWS Bedrock Prompt Cache 成本评估

评估 Amazon Bedrock 上不同缓存 TTL 设置对 **Prompt Cache（提示缓存）** 成本的影响。本 repo 提供了一套方法论、CloudWatch Logs Insights 查询语句和分析模板，用于量化提示缓存在 AI 编程和 Agent 工作流中的节省效果。

## 为什么 Prompt Cache 很重要

在 Amazon Bedrock 上使用 Claude 模型时，**Prompt Cache** 可以大幅降低成本。在多轮对话（例如 AI 编程会话）中，每次 API 调用都会重复发送相同的 system prompt + 历史对话。开启缓存后，Bedrock 会缓存这些重复前缀，缓存命中的 token 费用仅为普通输入的 **10%**（节省 90%）。

但缓存有 TTL（过期时间）。如果两次交互之间间隔较长，缓存会过期，你就白付了缓存写入费用。**最优 TTL 取决于你的使用模式。**

## Prompt Cache 工作机制

### Token 类型与定价（Claude 模型）

| Token 类型 | 说明 | 相对费用 |
|---|---|---|
| **Input（输入）** | 普通输入，无缓存 | 1x（基准） |
| **Cache Write（缓存写入）** | 第一次缓存前缀时 | 1.25x（溢价 25%） |
| **Cache Read（缓存读取）** | 后续命中缓存时 | 0.1x（优惠 90%） |
| **Output（输出）** | 模型生成的 token | 标准输出价格 |

### 缓存行为

- 基于**前缀精确匹配**——提示词开头必须完全一致才能命中缓存
- 默认 TTL：**5 分钟**（每次缓存命中会刷新 TTL）
- 扩展 TTL：通过 Bedrock API 的 `cachePointConfig` 配置（例如 1 小时）
- 缓存**按模型、按区域**隔离——不同模型或不同区域各自维护独立缓存

### 为什么 AI 编程工具最受益

Claude Code、Kiro、AI Agent 等工具每次 tool call 都会把完整对话上下文重新发给 API：

```
第 1 轮: [system prompt] + [用户消息 1]
第 2 轮: [system prompt] + [用户消息 1] + [助手回复 1] + [用户消息 2]
第 3 轮: [system prompt] + [用户消息 1] + [助手回复 1] + [用户消息 2] + [助手回复 2] + [用户消息 3]
...
```

前缀不断增长，但开头始终相同 → 缓存命中率极高。

## 评估方法论

### 目标

对比不同缓存 TTL 设置下，相同工作负载的实际成本差异。

### 思路

1. **用不同 TTL 跑相同的任务**（例如：5 分钟 vs 1 小时）
2. **从 CloudWatch Logs 采集 token 级别指标**
3. **计算实际成本 vs 假设无缓存的成本**，量化节省效果

### 步骤

#### 1. 开启 Bedrock 模型调用日志

AWS 控制台 → Amazon Bedrock → 设置 → 模型调用日志：

- 开启 **CloudWatch Logs**
- 选择你的日志组（名称由你在创建时指定，本文以 `<YOUR_LOG_GROUP>` 代替）
- 开启 **记录请求元数据**（包含 token 数量）

或通过 CLI：

```bash
aws bedrock put-model-invocation-logging-configuration \
  --logging-config '{
    "cloudWatchConfig": {
      "logGroupName": "<YOUR_LOG_GROUP>",
      "roleArn": "arn:aws:iam::<ACCOUNT_ID>:role/<BEDROCK_LOGGING_ROLE>"
    },
    "textDataDeliveryEnabled": true,
    "imageDataDeliveryEnabled": false,
    "embeddingDataDeliveryEnabled": false
  }'
```

> **注意**：日志组名称完全由你决定，Bedrock 不强制要求特定名称。使用 `queries/` 目录下的查询时，请将 `<YOUR_LOG_GROUP>` 替换为你实际配置的日志组名称。

#### 2. 运行工作负载

在每种 TTL 配置下跑**相同的任务**（例如：代码审查、功能实现、多轮编程会话）。保持控制变量一致：

- 相同模型（例如 `anthropic.claude-sonnet-4-6`）
- 相同代码库和任务
- 相同区域

#### 3. 查询 CloudWatch Logs

使用 [`queries/`](./queries/) 目录中的查询语句提取 token 指标。

#### 4. 分析结果

使用 [`analysis/`](./analysis/) 中的分析模板对比不同 TTL 场景的成本。

## CloudWatch Logs Insights 查询

参见 [`queries/`](./queries/) 目录，包含以下即用查询：

- **per-model-cost-summary** — 按模型汇总 token 用量和估算费用
- **cache-hit-rate-over-time** — 按时间桶展示缓存命中率变化
- **cost-with-vs-without-cache** — 对比实际成本 vs 假设无缓存的成本
- **per-invocation-detail** — 逐条调用的 token 明细
- **session-level-analysis** — 按会话（小时级）分组分析

> 所有查询中的日志组名称均用 `<YOUR_LOG_GROUP>` 表示，使用前请替换为你的实际值。

## 分析模板

[`analysis/`](./analysis/) 目录包含一个对比模板，用于比较：

- **场景 A**（短 TTL，例如 5 分钟）：适合连续、高密度的交互
- **场景 B**（长 TTL，例如 1 小时）：适合有间歇停顿的使用模式

### 关键指标对比

| 指标 | 含义 |
|---|---|
| **缓存命中率** | 从缓存读取的输入 token 占比 |
| **缓存写入浪费** | 写入但在过期前从未被读取的 token |
| **平均每次写入被读取次数** | 衡量缓存复用效率 |
| **有效输入成本** | 综合缓存混合后的每 token 实际成本 |
| **盈亏平衡点** | 多少次缓存读取能覆盖写入溢价 |

### 盈亏平衡分析

缓存写入费用为普通输入的 1.25 倍，缓存读取为 0.1 倍。因此：

- **1 次写入 + 1 次读取** = 1.25 + 0.1 = 1.35x（vs 不缓存的 2x）→ **节省 32.5%**
- **1 次写入 + 2 次读取** = 1.25 + 0.2 = 1.45x（vs 不缓存的 3x）→ **节省 52%**
- **1 次写入 + 5 次读取** = 1.25 + 0.5 = 1.75x（vs 不缓存的 6x）→ **节省 71%**
- **1 次写入 + 10 次读取** = 1.25 + 1.0 = 2.25x（vs 不缓存的 11x）→ **节省 80%**

**经验法则**：只要一个缓存前缀在过期前被读取**至少 1 次**，使用缓存就是合算的。读取次数越多，节省越显著。

## 项目结构

```
aws-bedrock-model-with-prompt-cache-cost-evaluation/
├── README.md                              # 本文件
├── queries/
│   ├── per-model-cost-summary.sql         # 按模型汇总成本
│   ├── cache-hit-rate-over-time.sql       # 缓存命中率时间趋势
│   ├── cost-with-vs-without-cache.sql     # 有/无缓存成本对比
│   ├── per-invocation-detail.sql          # 逐条调用明细
│   └── session-level-analysis.sql         # 按会话（小时）分组分析
├── analysis/
│   └── cost-comparison-template.md        # TTL 场景对比模板
├── pricing/
│   └── bedrock-claude-pricing.md          # Bedrock Claude 定价参考
└── LICENSE
```

## 定价参考

参见 [`pricing/bedrock-claude-pricing.md`](./pricing/bedrock-claude-pricing.md)，包含当前 Bedrock Claude 模型定价及缓存 token 费率。

## 贡献

欢迎提 Issue 和 PR。

## License

[MIT](./LICENSE)
