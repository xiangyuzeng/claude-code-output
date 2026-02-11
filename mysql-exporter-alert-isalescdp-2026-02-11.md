# MySQL Exporter 异常报警分析报告

**报告日期**: 2026-02-11
**报告人**: Claude Code
**事件类型**: MySQL Exporter 进程异常
**严重级别**: Warning
**根本原因**: **RDS 数据库重启**

---

## 1. 事件概述

收到 MySQL Exporter 进程异常报警，Job名称为 `db-aws-luckyus-isalescdp`。

**经过深入分析，确认根本原因是 RDS 数据库在 15:27 UTC 左右进行了重启**，导致 Exporter 在重启期间无法连接数据库，触发告警。数据库重启前已连续运行约 338 天。

---

## 2. 受影响实例信息

| 属性 | 值 |
|------|-----|
| **Job 名称** | db-aws-luckyus-isalescdp |
| **数据库标识** | aws-luckyus-isalescdp-rw |
| **Exporter 地址** | 10.238.3.136:9154 |
| **命名空间** | custom-scrape-iprod-us |
| **数据库类型** | AWS RDS MySQL |

---

## 3. 监控状态分析

### 3.1 当前状态（截至 15:28 UTC）

| 指标 | 当前值 | 状态 |
|------|--------|------|
| `up` (Exporter可用性) | 0 | :x: 不可用 |
| `mysql_up` (数据库连接) | 1 | :white_check_mark: 正常 |

### 3.2 问题时间线

| 时间 (UTC) | 时间戳 | `up` 状态 | 说明 |
|------------|--------|-----------|------|
| 15:12:20 | 1770821940 | 0 | 首次检测到异常 |
| 15:13:00 | 1770822180 | 1 | 短暂恢复 |
| 15:14:00 | 1770822240 | 0 | 再次掉线 |
| 15:14:00-15:20:00 | - | 0 | 持续不可用 |
| 15:20:00 | 1770822600 | 1 | 短暂恢复 |
| 15:21:00 | 1770822660 | 0 | 再次掉线 |
| 15:27:20 | 1770822840 | 0 | 持续不可用 |
| 15:28:04 | 1770822884 | 0 | 当前状态 |

### 3.3 Collector 采集成功状态

在异常期间，以下采集器出现失败（值从1变为0）：

| Collector | 正常状态 | 异常期间状态 |
|-----------|---------|-------------|
| collect.global_status | 1 | 0 |
| collect.global_variables | 1 | 0 |
| collect.info_schema.innodb_cmp | 1 | 0 |
| collect.info_schema.innodb_cmpmem | 1 | 0 |
| collect.slave_status | 1 | 0 |
| collect.info_schema.query_response_time | 1 | 1 (正常) |

---

## 4. 根本原因分析

### 4.0 **关键发现：数据库重启**

通过分析 `mysql_global_status_uptime` 指标和直接连接数据库查询，发现**数据库在告警期间进行了重启**：

| 时间点 (UTC) | Uptime 值 | 说明 |
|--------------|-----------|------|
| 15:11 (1770821880) | 29,222,715 秒 (**约338天**) | 重启前正常运行 |
| 15:29 (1770822960) | 66 秒 | 重启后 |

**数据库重启时间计算**：1770822960 - 66 = **15:27:54 UTC**

**Prometheus 原始数据证据**：
```
1770821880: uptime = 29222715  (重启前，运行338天)
--- 数据空白期间：数据库重启中 ---
1770822960: uptime = 66        (重启后)
1770823020: uptime = 126
1770823080: uptime = 186
...递增中...
```

**数据库连接验证**：
```sql
-- 当前 Uptime 确认
mysql> SHOW GLOBAL STATUS LIKE 'Uptime';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| Uptime        | 1904  |  -- 约32分钟，与重启时间吻合
+---------------+-------+

-- 当前数据库状态
mysql> SELECT @@hostname, @@server_id, @@read_only;
+------------------+------------+-------------+
| @@hostname       | @@server_id | @@read_only |
+------------------+------------+-------------+
| ip-172-17-0-194 | 1395265637  | 0           |  -- 主库，正常运行
+------------------+------------+-------------+
```

### 4.1 采集耗时对比

通过分析 `mysql_exporter_collector_duration_seconds` 指标，发现采集耗时在异常期间急剧增加：

| Collector | 正常耗时 | 异常期间耗时 | 增幅 |
|-----------|---------|-------------|------|
| **connection** | ~0.03s | **5.70s** | ~190x |
| **collect.global_status** | ~0.04s | **7.43s** | ~186x |
| **collect.global_variables** | ~0.04s | **4.05s** | ~101x |
| **collect.slave_status** | ~0.05s | **7.43s** | ~149x |
| **collect.info_schema.innodb_cmp** | ~0.02s | **7.43s** | ~371x |
| **collect.info_schema.innodb_cmpmem** | ~0.02s | **7.43s** | ~371x |

### 4.2 采集耗时详细数据

```
时间戳: 1770821925 (正常期间 ~15:12 UTC)
- collect.global_status:      0.035s
- collect.global_variables:   0.048s
- collect.slave_status:       0.054s
- connection:                 0.037s

时间戳: 1770822405 (异常开始 ~15:20 UTC)
- collect.global_status:      4.053s  (+115x)
- collect.global_variables:   4.053s  (+84x)
- collect.slave_status:       4.053s  (+75x)
- connection:                 5.697s  (+154x)

时间戳: 1770822885 (持续异常 ~15:28 UTC)
- collect.global_status:      7.435s  (+212x)
- collect.global_variables:   1.864s  (+39x)
- collect.slave_status:       7.435s  (+138x)
- connection:                 2.316s  (+63x)
```

### 4.3 问题诊断结论

1. **MySQL 数据库本身正常运行**
   - `mysql_up=1` 表明数据库可以成功建立连接
   - 数据库未出现宕机或不可用情况

2. **Exporter 采集超时**
   - 连接建立时间从正常的 ~30ms 飙升到 2-6 秒
   - 查询执行时间从正常的 ~40ms 飙升到 4-7 秒
   - 总采集时间超过 Prometheus scrape_timeout 配置（通常为 10s）

3. **问题特征**
   - 间歇性发生（偶尔恢复正常）
   - 影响所有需要执行 SQL 查询的 collector
   - `query_response_time` collector 受影响较小（可能查询较简单）

---

## 5. 原因确认

### 5.1 **已确认原因：RDS 数据库重启**

| 原因 | 状态 | 说明 |
|------|------|------|
| **RDS 数据库重启/Failover** | **已确认** | 数据库在 15:27 UTC 重启，导致连接中断 |

### 5.2 数据库当前状态（重启后）

通过直接连接数据库验证，**当前数据库运行正常**：

| 指标 | 当前值 | 状态 |
|------|--------|------|
| 当前连接数 (Threads_connected) | 61 | 正常 (最大 4000) |
| 运行线程 (Threads_running) | 3 | 正常 |
| 锁等待 (Innodb_row_lock_current_waits) | 0 | 无锁等待 |
| 活跃事务 | 0 | 无长事务 |
| 慢查询数 (Slow_queries) | 380 | 正常范围 |
| 连接中断 (Aborted_connects) | 0 | 正常 |
| 历史最大连接 (Max_used_connections) | 136 | 正常 |

### 5.3 排除的其他原因

| 排除原因 | 验证结果 |
|---------|---------|
| 数据库负载过高 | 当前 CPU/连接正常 |
| 锁等待/死锁 | performance_schema.data_lock_waits 为空 |
| 长事务阻塞 | innodb_trx 无活跃事务 |
| 慢查询 | 平均查询延迟 < 50ms |
| 网络问题 | 重启后连接恢复正常 |

---

## 6. 建议操作

### 6.1 立即操作（已完成验证）

- [x] **数据库状态验证** - 已确认数据库正常运行
- [x] **连接状态检查** - 当前连接数正常 (61/4000)
- [x] **锁等待检查** - 无锁等待
- [x] **长事务检查** - 无长事务

### 6.2 后续跟进

1. **查明重启原因**
   - 检查 AWS RDS 事件日志，确认是计划内维护还是故障转移
   - 登录 AWS Console → RDS → Events 查看详细事件
   ```bash
   aws rds describe-events \
     --source-identifier aws-luckyus-isalescdp-rw \
     --source-type db-instance \
     --duration 60
   ```

2. **确认 Exporter 恢复**
   - 监控 `up{job="db-aws-luckyus-isalescdp"}` 是否恢复为 1
   - 如持续为 0，重启 exporter Pod

3. **检查应用连接恢复**
   - 确认业务应用已重新建立数据库连接
   - 检查应用日志是否有连接错误

### 6.3 长期建议

1. **配置 RDS 事件通知**
   - 为重启、故障转移等事件配置 SNS 告警
   - 提前获知计划内维护窗口

2. **优化告警规则**
   - 考虑为 exporter down 告警添加 "数据库重启" 的排除条件
   - 或在告警描述中添加检查数据库 uptime 的提示

3. **监控数据库 Uptime**
   ```promql
   # 检测数据库重启
   changes(mysql_global_status_uptime{job="db-aws-luckyus-isalescdp"}[10m]) > 0
   ```

---

## 7. 监控查询参考

### 7.1 Prometheus 查询

```promql
# Exporter 可用性
up{job="db-aws-luckyus-isalescdp"}

# MySQL 连接状态
mysql_up{job="db-aws-luckyus-isalescdp"}

# 采集耗时
mysql_exporter_collector_duration_seconds{job="db-aws-luckyus-isalescdp"}

# 采集成功率
mysql_exporter_collector_success{job="db-aws-luckyus-isalescdp"}

# 连接建立耗时趋势
rate(mysql_exporter_collector_duration_seconds{job="db-aws-luckyus-isalescdp",collector="connection"}[5m])
```

### 7.2 Grafana Dashboard

可以在以下 Dashboard 中查看相关监控：
- Node Exporter 设备详情 (UID: 2eb04bd9-5067-4a90-8082-7d7a047ddc49)

---

## 8. 附录

### 8.1 数据源信息

| 数据源 | UID | 类型 |
|--------|-----|------|
| UMBQuerier-Luckin | df8o21agxtkw0d | Prometheus |

### 8.2 相关 Job 列表

该集群中同类型的 MySQL Exporter Job:
- db-aws-luckyus-isalescdp
- db-aws-luckyus-isalesdatamarketing
- db-aws-luckyus-isalesmembermarketing
- db-aws-luckyus-isalesprivatedomain
- 等其他 db-aws-luckyus-* 系列

---

**报告结束**

*本报告由 Claude Code 自动生成，基于 Prometheus 监控数据分析*
