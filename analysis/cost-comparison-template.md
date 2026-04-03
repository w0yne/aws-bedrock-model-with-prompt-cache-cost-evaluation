# Cost Comparison Template

Use this template to compare costs between different cache TTL configurations.

## Test Configuration

| Parameter | Scenario A | Scenario B |
|---|---|---|
| **Cache TTL** | 5 minutes (default) | 1 hour |
| **Model** | | |
| **Region** | | |
| **Task** | | |
| **Date** | | |

## Raw Metrics (from CloudWatch queries)

| Metric | Scenario A | Scenario B |
|---|---|---|
| Total invocations | | |
| Input tokens | | |
| Cache read tokens | | |
| Cache write tokens | | |
| Output tokens | | |
| Total tokens | | |

## Cache Efficiency

| Metric | Scenario A | Scenario B |
|---|---|---|
| Cache hit rate (%) | | |
| Cache write waste (tokens written but never read) | | |
| Avg cache reads per write | | |

## Cost Analysis

Fill in using your model's pricing from [`pricing/bedrock-claude-pricing.md`](../pricing/bedrock-claude-pricing.md).

| Cost Component | Scenario A | Scenario B |
|---|---|---|
| Input cost | $ | $ |
| Cache write cost | $ | $ |
| Cache read cost | $ | $ |
| Output cost | $ | $ |
| **Total actual cost** | **$** | **$** |
| Hypothetical cost (no cache) | $ | $ |
| **Savings vs no cache** | **%** | **%** |

## Interpretation

### When Short TTL (5 min) Is Better

- Continuous, dense interactions with no gaps > 5 minutes
- Lower cache write overhead (less data cached speculatively)
- Cost-efficient when every write gets multiple reads

### When Long TTL (1 hour) Is Better

- Intermittent usage with gaps of 5-60 minutes (e.g., code review → coffee → resume)
- Multi-step workflows where the user pauses to test or think
- Higher upfront cache write cost, but avoids expensive re-caching after short breaks

### Break-Even Guidance

A cache write costs 1.25x input. A cache read costs 0.1x input.

- If a cached prefix is read **≥1 time** before expiry → caching saves money
- At **2 reads per write** → saves ~52%
- At **5 reads per write** → saves ~71%
- At **10+ reads per write** → saves ~80%+

If your sessions have frequent gaps that exceed the TTL, **extending the TTL prevents cache thrashing** (repeated write → expire → write cycles) at the cost of longer cache retention billing.
