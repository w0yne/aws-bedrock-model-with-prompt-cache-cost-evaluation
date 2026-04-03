-- 逐条调用明细
-- 展示每一次 Bedrock 调用的完整 token 分类，用于逐轮分析缓存命中行为。
-- 在 CloudWatch Logs Insights 控制台中，请选择你配置的 Bedrock 模型调用日志组（下文以 <YOUR_LOG_GROUP> 代替）。

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
