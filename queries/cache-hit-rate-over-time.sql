-- 缓存命中率时间趋势
-- 按 5 分钟时间桶展示缓存命中率变化，用于识别缓存过期（命中率骤降为 0）的时间点。
-- 在 CloudWatch Logs Insights 控制台中，请选择你配置的 Bedrock 模型调用日志组（下文以 <YOUR_LOG_GROUP> 代替）。

fields @timestamp, @message
| parse @message '"modelId":"*"' as modelId
| parse @message '"inputTokens":*,' as inputTokens
| parse @message '"cacheReadInputTokens":*,' as cacheReadTokens
| parse @message '"cacheWriteInputTokens":*,' as cacheWriteTokens
| stats
    count() as 调用次数,
    sum(cacheReadTokens) as 缓存读取,
    sum(cacheWriteTokens) as 缓存写入,
    sum(inputTokens) as 普通输入,
    sum(cacheReadTokens) * 100.0 / sum(cacheReadTokens + cacheWriteTokens + inputTokens) as 缓存命中率百分比
  by bin(5m) as 时间桶, modelId
| sort 时间桶 asc
