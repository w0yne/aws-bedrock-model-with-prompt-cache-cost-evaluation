# Bedrock Claude Model Pricing Reference

> Pricing as of early 2026. Always verify at [Amazon Bedrock Pricing](https://aws.amazon.com/bedrock/pricing/).

## Claude Opus 4.6

| Token Type | Price per 1M tokens |
|---|---|
| Input | $15.00 |
| Output | $75.00 |
| Cache Write | $18.75 (1.25x input) |
| Cache Read | $1.50 (0.1x input) |

## Claude Sonnet 4.6

| Token Type | Price per 1M tokens |
|---|---|
| Input | $3.00 |
| Output | $15.00 |
| Cache Write | $3.75 (1.25x input) |
| Cache Read | $0.30 (0.1x input) |

## Claude Haiku 4.5

| Token Type | Price per 1M tokens |
|---|---|
| Input | $0.80 |
| Output | $4.00 |
| Cache Write | $1.00 (1.25x input) |
| Cache Read | $0.08 (0.1x input) |

## Cache Pricing Formula

For any Claude model on Bedrock:

- **Cache Write** = Input price × 1.25
- **Cache Read** = Input price × 0.10

## Cost Calculation

```
Total Cost = (input_tokens × input_price / 1M)
           + (cache_write_tokens × cache_write_price / 1M)
           + (cache_read_tokens × cache_read_price / 1M)
           + (output_tokens × output_price / 1M)
```

## Hypothetical No-Cache Cost

```
No-Cache Cost = ((input_tokens + cache_read_tokens + cache_write_tokens) × input_price / 1M)
              + (output_tokens × output_price / 1M)
```

## Savings Calculation

```
Savings % = (no_cache_cost - actual_cost) / no_cache_cost × 100
```
