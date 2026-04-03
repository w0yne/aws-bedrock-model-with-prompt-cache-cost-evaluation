-- Session-Level Analysis
-- Groups invocations into sessions based on time gaps (>10 min gap = new session).
-- Useful for understanding cache behavior across different coding sessions.
--
-- Note: CloudWatch Logs Insights doesn't support session windowing natively.
-- This query provides per-hour aggregation as a proxy.
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
    sum(cacheReadTokens) * 100.0 / sum(cacheReadTokens + cacheWriteTokens + inputTokens) as cacheHitRatePct,
    min(@timestamp) as sessionStart,
    max(@timestamp) as sessionEnd
  by bin(1h) as hourBucket, modelId
| sort hourBucket asc
