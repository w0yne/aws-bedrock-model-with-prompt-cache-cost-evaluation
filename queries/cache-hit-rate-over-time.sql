-- Cache Hit Rate Over Time
-- Shows cache hit rate in 5-minute buckets to visualize cache effectiveness.
-- Useful for identifying periods where cache expired (hit rate drops to 0).
--
-- Log group: /aws/bedrock/model-invocations

fields @timestamp, @message
| parse @message '"modelId":"*"' as modelId
| parse @message '"inputTokens":*,' as inputTokens
| parse @message '"cacheReadInputTokens":*,' as cacheReadTokens
| parse @message '"cacheWriteInputTokens":*,' as cacheWriteTokens
| stats
    count() as invocations,
    sum(cacheReadTokens) as cacheRead,
    sum(cacheWriteTokens) as cacheWrite,
    sum(inputTokens) as freshInput,
    sum(cacheReadTokens) * 100.0 / sum(cacheReadTokens + cacheWriteTokens + inputTokens) as cacheHitRatePct
  by bin(5m) as timeBucket, modelId
| sort timeBucket asc
