-- Per-Model Cost Summary
-- Aggregates token usage and estimated cost by model across a time range.
-- Adjust the time range in the CloudWatch console or add | filter @timestamp >= ...
--
-- Log group: /aws/bedrock/model-invocations (or your configured log group)

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
    sum(inputTokens + cacheReadTokens + cacheWriteTokens + outputTokens) as totalTokens
  by modelId
| sort invocations desc
