-- Per-Invocation Detail
-- Shows every individual Bedrock invocation with full token breakdown.
-- Useful for understanding cache behavior turn by turn.
--
-- Log group: /aws/bedrock/model-invocations

fields @timestamp, @message
| parse @message '"modelId":"*"' as modelId
| parse @message '"inputTokens":*,' as inputTokens
| parse @message '"outputTokens":*,' as outputTokens
| parse @message '"cacheReadInputTokens":*,' as cacheReadTokens
| parse @message '"cacheWriteInputTokens":*,' as cacheWriteTokens
| parse @message '"stopReason":"*"' as stopReason
| display @timestamp, modelId, inputTokens, cacheReadTokens, cacheWriteTokens, outputTokens, stopReason
| sort @timestamp asc
| limit 500
