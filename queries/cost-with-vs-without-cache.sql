-- 有/无缓存成本对比
-- 对比实际成本（含缓存定价）与假设无缓存的成本（所有 token 按普通输入价格计算）。
-- 示例价格使用 Claude Opus 4.6 标准定价，请根据你使用的模型调整费率。
--
-- 定价参考（每百万 token，Claude Opus 4.6 on Bedrock）：
--   输入：       $15.00
--   缓存写入：   $18.75（输入的 1.25 倍）
--   缓存读取：   $1.50（输入的 0.1 倍）
--   输出：       $75.00
--
-- 在 CloudWatch Logs Insights 控制台中，请选择你配置的 Bedrock 模型调用日志组（下文以 <YOUR_LOG_GROUP> 代替）。

fields @timestamp, @message
| parse @message '"modelId":"*"' as modelId
| parse @message '"inputTokens":*,' as inputTokens
| parse @message '"outputTokens":*,' as outputTokens
| parse @message '"cacheReadInputTokens":*,' as cacheReadTokens
| parse @message '"cacheWriteInputTokens":*,' as cacheWriteTokens
| stats
    count() as 调用次数,
    sum(inputTokens) as 总输入Token,
    sum(cacheReadTokens) as 总缓存读取Token,
    sum(cacheWriteTokens) as 总缓存写入Token,
    sum(outputTokens) as 总输出Token,

    -- 有缓存的实际费用
    (sum(inputTokens) * 15.00 / 1000000)
    + (sum(cacheWriteTokens) * 18.75 / 1000000)
    + (sum(cacheReadTokens) * 1.50 / 1000000)
    + (sum(outputTokens) * 75.00 / 1000000)
    as 实际费用USD,

    -- 假设无缓存的费用（缓存 token 全部按普通输入计价）
    (sum(inputTokens + cacheReadTokens + cacheWriteTokens) * 15.00 / 1000000)
    + (sum(outputTokens) * 75.00 / 1000000)
    as 无缓存假设费用USD,

    -- 缓存命中率
    sum(cacheReadTokens) * 100.0 / sum(cacheReadTokens + cacheWriteTokens + inputTokens) as 缓存命中率百分比

  by modelId
| sort 实际费用USD desc
