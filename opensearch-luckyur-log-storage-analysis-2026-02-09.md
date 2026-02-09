# OpenSearch luckyur-log 存储空间分析报告

**日期**: 2026-02-09
**分析人**: Claude (AI Assistant)
**域名**: luckyur-log
**区域**: us-east-1

---

## 1. 执行摘要

luckyur-log OpenSearch 域当前处于**严重存储告警**状态，存储使用率已达 **96.4%**，仅剩约 41 GB 可用空间。需要立即采取清理措施以避免集群进入只读模式。

### 关键指标

| 指标 | 值 |
|------|-----|
| 总存储空间 | ~1,115 GB |
| 已使用空间 | ~1,074 GB |
| 可用空间 | ~41 GB |
| 使用率 | 96.4% |
| 状态 | 🔴 严重 |

---

## 2. AWS OpenSearch 域总览

本次检查涵盖了 4 个 OpenSearch 域的存储状态：

| 域名 | 可用空间 | 使用率 | 状态 |
|------|----------|--------|------|
| luckycommon | ~50 GB | 69.7% | ✅ 正常 |
| luckylfe-log | ~23 GB | 87.5% | ⚠️ 警告 |
| **luckyur-log** | **~41 GB** | **96.4%** | **🔴 严重** |
| luckyus-opensearch-dify | ~24 GB | ~0% | ✅ 空闲 |

---

## 3. luckyur-log 索引分析

### 3.1 存储分布 TOP 10

| 索引 | 文档数 | 存储大小 | 占比 |
|------|--------|----------|------|
| iprod_tomcat_lucky_k8s | ~2.5亿 | ~537 GB | 48.2% |
| skywalking_idx_segment | ~3.2亿 | ~156 GB | 14.0% |
| prod-worker01-eks-us-baseservices-cloud-dify | ~1.2亿 | ~106 GB | 9.5% |
| iprod_tomcat_lucky_k8s-2025.09.* (历史) | ~5000万 | ~80 GB | 7.2% |
| skywalking_idx_segment-2025.09.* (历史) | ~4000万 | ~45 GB | 4.0% |
| 其他索引 | - | ~190 GB | 17.1% |

### 3.2 关键发现

1. **主要存储消耗者**:
   - `iprod_tomcat_lucky_k8s` 系列索引占据近一半存储空间
   - Skywalking 追踪数据约占 14%
   - Dify 服务日志约占 9.5%

2. **历史数据问题**:
   - 发现 2025年9月的旧索引仍存在（已有 5 个月历史）
   - 这些索引约占用 **100+ GB** 存储空间
   - 建议立即清理这些过期数据

3. **ILM 策略缺失**:
   - 未发现有效的索引生命周期管理策略
   - 导致历史索引无法自动清理

---

## 4. 可回收空间估算

| 清理项目 | 预估可回收空间 | 优先级 |
|----------|---------------|--------|
| 2025.09.* 历史索引 | ~100 GB | P0 - 立即执行 |
| 2025.10.* 历史索引 | ~50 GB | P1 - 高优先级 |
| Skywalking 旧数据 | ~30 GB | P2 - 中优先级 |
| **总计** | **~180 GB** | - |

清理后预计存储使用率将降至 **~80%**，恢复至健康状态。

---

## 5. 建议操作

### 5.1 立即执行（P0）

```bash
# 在 OpenSearch Dev Tools 中执行

# 1. 查看所有 2025.09 的索引
GET _cat/indices/*2025.09*?v&s=store.size:desc

# 2. 确认后删除 2025.09 的索引（谨慎操作）
DELETE *2025.09*

# 或者分批删除特定索引
DELETE iprod_tomcat_lucky_k8s-2025.09.*
DELETE skywalking_idx_segment-2025.09.*
```

### 5.2 配置 ILM 策略（P1）

```json
PUT _ilm/policy/log-retention-30d
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_age": "1d",
            "max_size": "50gb"
          }
        }
      },
      "delete": {
        "min_age": "30d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

### 5.3 持续监控

1. 设置 CloudWatch 告警:
   - FreeStorageSpace < 50 GB → 警告
   - FreeStorageSpace < 20 GB → 严重

2. 每周检查存储使用情况

---

## 6. 风险说明

### 存储空间耗尽的影响

当 OpenSearch 存储空间使用率超过 **90%** 时：
- 索引写入可能变慢
- 超过 **95%** 时集群可能进入只读模式
- 新日志将无法写入，影响日志收集和分析

### 清理操作风险

- 删除索引是**不可逆**操作
- 执行前请确认：
  1. 数据是否需要归档
  2. 是否有合规要求需要保留
  3. 团队已知晓清理计划

---

## 7. 附录

### 7.1 查询命令参考

```bash
# 查看所有索引（按大小排序）
GET _cat/indices?v&s=store.size:desc&h=index,docs.count,store.size,pri.store.size

# 查看集群健康状态
GET _cluster/health

# 查看磁盘使用情况
GET _cat/allocation?v

# 查看 ILM 策略
GET _ilm/policy

# 按日期模式查找索引
GET _cat/indices/*2025.09*?v
GET _cat/indices/*2025.10*?v
```

### 7.2 联系信息

如需协助执行清理操作，请联系 DevOps 团队。

---

*报告生成时间: 2026-02-09*
*下次检查建议: 清理后立即验证，之后每周检查*
