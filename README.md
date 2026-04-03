# AWS Bedrock Prompt Cache Cost Evaluation

Evaluate the cost impact of **prompt caching** on Amazon Bedrock with different cache TTL settings. This repo provides a methodology, CloudWatch Logs Insights queries, and analysis templates to measure how prompt caching saves money in real-world AI coding and agent workflows.

## Why This Matters

When using Claude models on Amazon Bedrock, **prompt caching** can dramatically reduce costs. In multi-turn conversations (like AI coding sessions), the same system prompt + conversation history is resent on every API call. With prompt caching enabled, Bedrock caches these repeated prefixes — and cache reads cost **90% less** than regular input tokens.

**Real-world example**: A full-day AI coding session processed ~397M tokens. With 95.7% cache hit rate, the actual cost was **$303** instead of **~$1,991** — an **85% savings**.

But cache has a TTL. If your interactions are spaced far apart, the cache expires and you pay full price for cache writes that never get reused. **The optimal TTL depends on your usage pattern.**

## How Prompt Caching Works on Bedrock

### Token Types & Pricing (Claude models)

| Token Type | Description | Relative Cost |
|---|---|---|
| **Input** | Fresh tokens, no cache | 1x (baseline) |
| **Cache Write** | First time a prefix is cached | 1.25x (25% premium) |
| **Cache Read** | Subsequent hits on cached prefix | 0.1x (90% discount) |
| **Output** | Model-generated tokens | Standard output pricing |

### Cache Behavior

- Cache is based on **exact prefix matching** — the beginning of your prompt must match exactly
- Default TTL: **5 minutes** from last use (each cache hit refreshes the TTL)
- Extended TTL: Configurable via `cachePointConfig` in the Bedrock API (e.g., 1 hour)
- Cache is **per-model, per-region** — different models or regions maintain separate caches

### Why AI Coding Tools Benefit Most

Tools like Claude Code, Kiro, and AI agents using Bedrock send the full conversation context on every turn:

```
Turn 1: [system prompt] + [user message 1]
Turn 2: [system prompt] + [user message 1] + [assistant response 1] + [user message 2]
Turn 3: [system prompt] + [user message 1] + [assistant response 1] + [user message 2] + [assistant response 2] + [user message 3]
...
```

The prefix grows but always starts the same way → high cache hit potential.

## Evaluation Methodology

### Goal

Compare the cost efficiency of different cache TTL settings for your specific usage pattern.

### Approach

1. **Run the same workload twice** with different cache TTL settings (e.g., 5 min vs 1 hour)
2. **Collect token-level metrics** from CloudWatch Logs
3. **Calculate actual vs hypothetical costs** to measure savings

### Steps

#### 1. Enable Bedrock Model Invocation Logging

In the AWS Console → Amazon Bedrock → Settings → Model invocation logging:

- Enable **CloudWatch Logs**
- Select a log group (e.g., `/aws/bedrock/model-invocations`)
- Enable **Log request metadata** (includes token counts)

Or via CLI:

```bash
aws bedrock put-model-invocation-logging-configuration \
  --logging-config '{
    "cloudWatchConfig": {
      "logGroupName": "/aws/bedrock/model-invocations",
      "roleArn": "arn:aws:iam::<ACCOUNT_ID>:role/<BEDROCK_LOGGING_ROLE>"
    },
    "textDataDeliveryEnabled": true,
    "imageDataDeliveryEnabled": false,
    "embeddingDataDeliveryEnabled": false
  }'
```

#### 2. Run Your Workload

Run the **same task** (e.g., a code review, feature implementation, or multi-turn coding session) under each cache TTL configuration. Keep variables consistent:

- Same model (e.g., `anthropic.claude-sonnet-4-6`)
- Same codebase and task
- Same region

#### 3. Query CloudWatch Logs

Use the queries in [`queries/`](./queries/) to extract token metrics.

#### 4. Analyze Results

Use the analysis template in [`analysis/`](./analysis/) to compare costs.

## CloudWatch Logs Insights Queries

See the [`queries/`](./queries/) directory for ready-to-use queries. Quick reference:

### Per-Model Cost Summary

```
# See queries/per-model-cost-summary.sql
```

### Cache Hit Rate Over Time

```
# See queries/cache-hit-rate-over-time.sql
```

### Cost With vs Without Cache

```
# See queries/cost-with-vs-without-cache.sql
```

## Analysis Template

The [`analysis/`](./analysis/) directory contains a spreadsheet-friendly template for comparing:

- **Scenario A** (short TTL, e.g., 5 min): Good for continuous, dense interactions
- **Scenario B** (long TTL, e.g., 1 hour): Better for intermittent usage with gaps

### Key Metrics to Compare

| Metric | What It Tells You |
|---|---|
| **Cache Hit Rate** | % of input tokens served from cache |
| **Cache Write Waste** | Tokens written to cache but never read (TTL expired) |
| **Effective Input Cost** | Blended cost per input token (accounting for cache mix) |
| **Break-Even Point** | How many cache reads justify the cache write premium |

### Break-Even Analysis

Cache write costs 1.25x regular input. Cache read costs 0.1x. Therefore:

- **1 write + 1 read** = 1.25 + 0.1 = 1.35x (vs 2x without cache) → **saves 32.5%**
- **1 write + 2 reads** = 1.25 + 0.2 = 1.45x (vs 3x without cache) → **saves 52%**
- **1 write + 5 reads** = 1.25 + 0.5 = 1.75x (vs 6x without cache) → **saves 71%**
- **1 write + 10 reads** = 1.25 + 1.0 = 2.25x (vs 11x without cache) → **saves 80%**

**Rule of thumb**: If a cached prefix is read at least **once** before expiry, caching saves money. The more reads per write, the bigger the savings.

## Project Structure

```
aws-bedrock-model-with-prompt-cache-cost-evaluation/
├── README.md                              # This file
├── queries/
│   ├── per-model-cost-summary.sql         # Aggregate cost by model
│   ├── cache-hit-rate-over-time.sql       # Cache hit rate in time buckets
│   ├── cost-with-vs-without-cache.sql     # Compare actual vs no-cache cost
│   ├── per-invocation-detail.sql          # Per-call token breakdown
│   └── session-level-analysis.sql         # Group by session/conversation
├── analysis/
│   └── cost-comparison-template.md        # Template for comparing TTL scenarios
├── pricing/
│   └── bedrock-claude-pricing.md          # Current Bedrock Claude pricing reference
└── LICENSE
```

## Pricing Reference

See [`pricing/bedrock-claude-pricing.md`](./pricing/bedrock-claude-pricing.md) for current Bedrock Claude model pricing including cache token rates.

## Contributing

Issues and PRs welcome. If you run this evaluation on a specific use case, consider sharing your anonymized results.

## License

[MIT](./LICENSE)
