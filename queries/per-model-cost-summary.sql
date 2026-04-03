-- 按模型汇总成本
-- 按模型聚合 token 用量和估算费用，适合对比不同模型的缓存效果。
-- 在 CloudWatch Logs Insights 控制台中，请选择你配置的 Bedrock 模型调用日志组（下文以 <YOUR_LOG_GROUP> 代替）。

fields @timestamp, @message
| parse @message '"modelId":"*"' as modelId
| parse @message '"inputTokens":*,' as inputTokens
| parse @message '"outputTokens":*,' as outputTokens
| parse @message '"cacheReadInputTokens":*,' as cacheReadTokens
| parse @message '"cacheWriteInputTokens":*,' as cacheWriteTokens
| stats
    count() as 调用次数,
    sum(inputTokens) as 输入Token,
    sum(cacheReadTokens) as 缓存读取Token,
    sum(cacheWriteTokens) as 缓存写入Token,
    sum(outputTokens) as 输出Token,
    sum(inputTokens + cacheReadTokens + cacheWriteTokens + outputTokens) as 总Token
  by modelId
| sort 调用次数 desc
