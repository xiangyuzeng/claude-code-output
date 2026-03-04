# OpenSearch Dashboard 优化建议报告

**报告日期**: 2026-03-04
**报告人**: DBA/Infrastructure Team
**问题类别**: OpenSearch 性能保护 / Grafana Dashboard 优化
**紧急程度**: 高（已影响 OpenSearch 服务稳定性）

---

## 1. 问题背景

【域名指标监控】文件夹下的两个 LFE 域名监控 Dashboard，在用户选择较大时间范围时，会向 OpenSearch 发送大量高开销聚合查询，导致 OpenSearch 集群负载激增甚至服务不可用。

**涉及 Dashboard：**

| Dashboard | UID | 面板数 | 查询数 | 标签 |
|-----------|-----|--------|--------|------|
| 【LUCKY】LFE域名简版 | `vTPcQSI7z` | 8 | ~9 | LFE, 15天数据, 全量细节查询 |
| LFE域名详版 | `CoeHpTMHk` | 40 | ~35 | LFE, 15天数据, 不对外开放, 全量细节查询 |

**数据源**: `Elasticsearch-lfe` (UID: `d0qWL4oNk`)
**OpenSearch 地址**: `vpc-luckylfe-log-eh3n6nwo4c43eofoz36j35kni4.us-east-1.es.amazonaws.com`
**索引模式**: `ufenginx-*`（Nginx 访问日志）
**创建者**: ronghai.ye
**最后更新**: David.Zhou (2025-12-30)

---

## 2. 根因分析

### 2.1 核心问题：硬编码 `interval: 1s`

多个面板的 `date_histogram` 聚合 interval 被硬编码为 `1s`，而非 Grafana 推荐的 `auto`。当用户将时间范围从默认的 1h 拉大到数天时，bucket 数量呈线性爆炸：

| 时间范围 | interval=1s 时的 bucket 数 | interval=auto 时的 bucket 数（约） |
|----------|---------------------------|----------------------------------|
| 1 小时 | 3,600 | 3,600 (≈1s) |
| 6 小时 | 21,600 | 1,080 (≈20s) |
| 1 天 | 86,400 | 1,440 (≈1m) |
| 7 天 | **604,800** | 1,680 (≈6m) |
| 15 天 | **1,296,000** | 1,800 (≈12m) |

带 `terms` 嵌套聚合的面板更为严重：`terms(TOP 10) × date_histogram(1s)` 在 7 天范围下产生 **604,800 × 10 = 6,048,000** 个 bucket。

### 2.2 受影响面板清单

#### 简版 (vTPcQSI7z) — 3 个面板

| Panel ID | 面板名称 | interval | 聚合类型 | 风险等级 |
|----------|----------|----------|----------|----------|
| 74 | QPS | `1s` | count + date_histogram | 高 |
| 88 | 请求量URI占比(TOP 5) | `1s` | terms(URI) × date_histogram | 高 |
| 71 | 流量 | `1s` | sum(bytes) + date_histogram | 高 |

#### 详版 (CoeHpTMHk) — 6 个面板

| Panel ID | 面板名称 | interval | 聚合类型 | 风险等级 |
|----------|----------|----------|----------|----------|
| 76 | QPS | `1s` | count + date_histogram | 高 |
| 78 | 网络流量 | `1s` | sum(bytes) + date_histogram | 高 |
| 38 | QPS TOP 10 URI | `1s` | terms(URI) × date_histogram | **极高** |
| 48 | QPS TOP 10 用户源IP | `1s` | terms(clientip) × date_histogram | **极高** |
| 50 | 流量 TOP 10 URI | `1s` | terms(URI) × date_histogram | **极高** |
| 49 | 流量 TOP 10 用户源IP | `1s` | terms(clientip) × date_histogram | **极高** |

### 2.3 次要问题：`terms.size: 0`（详版独有）

详版中 2 个面板的 `terms` 聚合 `size` 设置为 `0`，表示返回**所有唯一值**，无上限。高基数字段在大时间范围下可能返回数万条记录。

| Panel ID | 面板名称 | 字段 | terms.size | 风险 |
|----------|----------|------|------------|------|
| 73 | xff 真实IP来源 | `xff` | `0`（无限制） | 高 |
| 74 | referrer | `referrer` | `0`（无限制） | 高 |

### 2.4 次要问题：详版查询并发过高

详版 40 个面板在 Dashboard 加载时**同时**向 OpenSearch 发送约 35 个查询。5 个 Row 分组均为展开状态，所有面板无论是否在可视区域内都会立即执行查询。

---

## 3. 修改建议

### 3.1 【优先级 1】将硬编码 `interval: 1s` 改为 `auto`

**改动内容**: 将以下 9 个面板的 `date_histogram` 的 `interval` 从 `"1s"` 修改为 `"auto"`。

**简版 (vTPcQSI7z)**:
1. Panel 74 (QPS) — `bucketAggs[].settings.interval`: `"1s"` → `"auto"`
2. Panel 88 (请求量URI占比 TOP 5) — `bucketAggs[].settings.interval`: `"1s"` → `"auto"`
3. Panel 71 (流量) — `bucketAggs[].settings.interval`: `"1s"` → `"auto"`

**详版 (CoeHpTMHk)**:
1. Panel 76 (QPS) — `bucketAggs[].settings.interval`: `"1s"` → `"auto"`
2. Panel 78 (网络流量) — `bucketAggs[].settings.interval`: `"1s"` → `"auto"`
3. Panel 38 (QPS TOP 10 URI) — `bucketAggs[].settings.interval`: `"1s"` → `"auto"`
4. Panel 48 (QPS TOP 10 用户源IP) — `bucketAggs[].settings.interval`: `"1s"` → `"auto"`
5. Panel 50 (流量 TOP 10 URI) — `bucketAggs[].settings.interval`: `"1s"` → `"auto"`
6. Panel 49 (流量 TOP 10 用户源IP) — `bucketAggs[].settings.interval`: `"1s"` → `"auto"`

**对实时监控的影响**:
- 时间范围 15min~1h（日常监控场景）：Grafana 自动计算粒度约为 1~5s，**与现状几乎无差异**
- 时间范围 6h+（问题排查场景）：粒度自动降至 20s~1min，**有效保护 OpenSearch**

**预期效果**: 消除大时间范围下的 bucket 爆炸问题，查询开销降低 **90%以上**（以 7 天为例）。

---

### 3.2 【优先级 2】修复 `terms.size: 0` 无限制问题

**改动内容**: 详版 (CoeHpTMHk) 中 2 个面板的 `terms` 聚合 `size` 从 `"0"` 改为有限值。

| Panel ID | 面板名称 | 字段 | 修改前 | 修改后 |
|----------|----------|------|--------|--------|
| 73 | xff 真实IP来源 | `xff` | `"size": "0"` | `"size": "20"` |
| 74 | referrer | `referrer` | `"size": "0"` | `"size": "20"` |

**对监控效果的影响**: 只展示 TOP 20，覆盖绝大多数排查需求，无实质影响。

**预期效果**: 避免高基数字段的 terms 聚合返回无限量数据。

---

### 3.3 【优先级 3】详版 Row 默认收起

**改动内容**: 详版 (CoeHpTMHk) 的 5 个 Row 分组中，保留第一个 Row 展开，其余 4 个默认设为**收起状态**（collapsed）。

| Row | Panel ID | 面板名称 | 建议状态 | 内含查询数 |
|-----|----------|----------|----------|-----------|
| 1 | 88 | 域名总览 | 展开（保持现状） | ~10 |
| 2 | 35 | QPS、流量分析 | **收起** | ~4 |
| 3 | 29 | 响应时间分析 | **收起** | ~6 |
| 4 | 21 | 可用性错误分布分析 | **收起** | ~8 |
| 5 | 16 | 流量分布 | **收起** | ~3 |
| 6 | 42 | 客户端分析 | **收起** | ~6 |

**对监控效果的影响**: 首屏仍展示核心指标（QPS、流量、响应时间、错误趋势、P95），用户按需点开其他分组即可。

**预期效果**: Dashboard 首次加载时并发查询数从 ~35 降至 ~10，**减少约 70%**。

---

### 3.4 【优先级 4】数据源全局 Min Interval 保底

**改动内容**: 在 Grafana 数据源配置中，为 `Elasticsearch-lfe` (UID: `d0qWL4oNk`) 设置 `Min time interval: 5s`。

**操作路径**: Grafana → Configuration → Data Sources → Elasticsearch-lfe → Min time interval → 填入 `5s`

**对监控效果的影响**: 仅在极短时间范围（如 < 5min）时限制最小粒度为 5s，日常 1h 范围完全无感。

**预期效果**: 作为全局保底，防止任何使用该数据源的 Dashboard 出现过细粒度查询。此设置对所有引用 `Elasticsearch-lfe` 的 Dashboard 生效。

---

## 4. 实施计划

| 阶段 | 内容 | 风险 | 耗时 |
|------|------|------|------|
| 第一阶段 | 优先级 1：9 个面板 interval 改 auto | 低 | 30 分钟 |
| 第一阶段 | 优先级 2：2 个面板 terms.size 改 20 | 低 | 10 分钟 |
| 第二阶段 | 优先级 3：4 个 Row 默认收起 | 低 | 15 分钟 |
| 第二阶段 | 优先级 4：数据源 Min Interval | 低 | 5 分钟 |

**建议在低峰期（如凌晨或周末）实施，修改后在 Grafana 上用不同时间范围验证效果。**

---

## 5. 长期建议

| 措施 | 说明 | 优先级 |
|------|------|--------|
| **OpenSearch `max_buckets` 限制** | 集群级别设置 `search.max_buckets: 65535`，从服务端防止单个查询创建过多 bucket | 中 |
| **OpenSearch ISM 生命周期策略** | 超过 7 天的 `ufenginx-*` 索引自动转 warm/cold 节点，降低热节点压力 | 中 |
| **OpenSearch Rollup Index** | 对 `ufenginx-*` 创建按 1min 预聚合的 rollup 索引，大时间范围查询走 rollup | 中 |
| **指标下沉到 Prometheus** | 通过 Nginx Exporter 或 OpenTelemetry 将 QPS、错误率、P95 等聚合指标推送到 Prometheus，Dashboard 直接查 Prometheus 而非每次从原始日志实时聚合 | 低（架构改造） |
| **排查同类 Dashboard** | 检查同文件夹下其他域名监控 Dashboard（如 apigateway、fe、waf）是否存在相同问题 | 中 |

---

## 附录：数据源详情

```
名称:           Elasticsearch-lfe
UID:            d0qWL4oNk
类型:           grafana-opensearch-datasource
ES 版本:        7.10.0
索引模式:       ufenginx-*
时间字段:       @timestamp
最大并发分片请求: 5
URL:            vpc-luckylfe-log-eh3n6nwo4c43eofoz36j35kni4.us-east-1.es.amazonaws.com
认证方式:       Basic Auth (luckylfe)
```
