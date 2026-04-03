-- 按会话分组分析
-- 按小时聚合调用数据，近似模拟"会话"粒度的缓存效果分析。
-- （CloudWatch Logs Insights 不原生支持基于时间间隔的会话切分，此处以小时桶作为替代。）
-- 在 CloudWatch Logs Insights 控制台中，请选择你配置的 Bedrock 模型调用日志组（下文以 <YOUR_LOG_GROUP> 代替）。

fields @timestamp, @message
| parse @message '"modelId":"*"' as modelId
| parse @message '"inputTokens":*,' as inputTokens
| parse @message '"outputTokens":*,' as outputTokens
| parse @message '"cacheReadInputTokens":*,' as cacheReadTokens
| parse @message '"cacheWriteInputTokens":*,' as cacheWriteTokens
| stats
    count() as 调用次数,
    sum(inputTokens) as 普通输入Token,
    sum(cacheReadTokens) as 缓存读取Token,
    sum(cacheWriteTokens) as 缓存写入Token,
    sum(outputTokens) as 输出Token,
    sum(cacheReadTokens) * 100.0 / sum(cacheReadTokens + cacheWriteTokens + inputTokens) as 缓存命中率百分比,
    min(@timestamp) as 会话开始,
    max(@timestamp) as 会话结束
  by bin(1h) as 小时桶, modelId
| sort 小时桶 asc
