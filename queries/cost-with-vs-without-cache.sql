-- Cost With vs Without Cache
-- Compares actual cost (with cache pricing) against hypothetical cost (all tokens at standard input rate).
-- Uses Claude Opus 4.6 pricing as example — adjust rates for your model.
--
-- Pricing (per 1M tokens, Claude Opus 4.6 on Bedrock):
--   Input:       $15.00
--   Cache Write: $18.75  (1.25x input)
--   Cache Read:  $1.50   (0.1x input)
--   Output:      $75.00
--
-- Log group: /aws/bedrock/model-invocations

fields @timestamp, @message
| parse @message '"modelId":"*"' as modelId
| parse @message '"inputTokens":*,' as inputTokens
| parse @message '"outputTokens":*,' as outputTokens
| parse @message '"cacheReadInputTokens":*,' as cacheReadTokens
| parse @message '"cacheWriteInputTokens":*,' as cacheWriteTokens
| stats
    count() as invocations,
    sum(inputTokens) as totalInput,
    sum(cacheReadTokens) as totalCacheRead,
    sum(cacheWriteTokens) as totalCacheWrite,
    sum(outputTokens) as totalOutput,

    -- Actual cost with cache
    (sum(inputTokens) * 15.00 / 1000000)
    + (sum(cacheWriteTokens) * 18.75 / 1000000)
    + (sum(cacheReadTokens) * 1.50 / 1000000)
    + (sum(outputTokens) * 75.00 / 1000000)
    as actualCostUSD,

    -- Hypothetical cost without cache (all cache tokens charged as regular input)
    (sum(inputTokens + cacheReadTokens + cacheWriteTokens) * 15.00 / 1000000)
    + (sum(outputTokens) * 75.00 / 1000000)
    as noCacheCostUSD,

    -- Cache hit rate
    sum(cacheReadTokens) * 100.0 / sum(cacheReadTokens + cacheWriteTokens + inputTokens) as cacheHitRatePct

  by modelId
| sort actualCostUSD desc
