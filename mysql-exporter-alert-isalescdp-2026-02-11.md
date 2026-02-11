# MySQL Exporter 异常报警分析报告

**报告日期**: 2026-02-11
**报告人**: Claude Code
**事件类型**: MySQL Exporter 进程异常
**严重级别**: Warning

---

## 1. 事件概述

收到 MySQL Exporter 进程异常报警，Job名称为 `db-aws-luckyus-isalescdp`。经过详细分析，确认 exporter 存在间歇性采集超时问题，但底层 MySQL 数据库本身运行正常。

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

## 5. 可能原因

### 5.1 数据库层面

| 可能原因 | 可能性 | 说明 |
|---------|-------|------|
| 数据库负载过高 | 高 | CPU/内存压力导致查询响应变慢 |
| 锁等待/死锁 | 中 | 大事务或锁竞争阻塞 exporter 查询 |
| 连接池耗尽 | 中 | 可用连接不足导致连接建立缓慢 |
| 大查询/慢查询 | 中 | 资源密集型查询占用数据库资源 |

### 5.2 网络层面

| 可能原因 | 可能性 | 说明 |
|---------|-------|------|
| 网络延迟增加 | 低 | EKS 到 RDS 网络路径拥塞 |
| 网络丢包 | 低 | 导致 TCP 重传 |

### 5.3 Exporter 层面

| 可能原因 | 可能性 | 说明 |
|---------|-------|------|
| Pod 资源不足 | 低 | CPU/内存限制导致处理缓慢 |
| 连接泄漏 | 低 | Exporter 内部连接管理问题 |

---

## 6. 建议操作

### 6.1 立即检查

1. **检查 RDS 实例性能指标**
   ```
   - CPUUtilization
   - DatabaseConnections
   - ReadLatency / WriteLatency
   - FreeableMemory
   ```

2. **检查当前活跃连接和锁**
   ```sql
   -- 查看当前连接数
   SHOW STATUS LIKE 'Threads_connected';

   -- 查看锁等待
   SELECT * FROM information_schema.innodb_lock_waits;

   -- 查看长时间运行的查询
   SELECT * FROM information_schema.processlist
   WHERE TIME > 10 ORDER BY TIME DESC;
   ```

3. **检查 Exporter Pod 状态**
   ```bash
   kubectl get pods -n custom-scrape-iprod-us | grep isalescdp
   kubectl describe pod <pod-name> -n custom-scrape-iprod-us
   ```

### 6.2 短期修复

1. 如果发现长时间运行的查询，考虑终止
2. 如果连接数过高，检查是否有连接泄漏
3. 如果问题持续，重启 exporter Pod

### 6.3 长期优化

1. 调整 Prometheus scrape_timeout 配置（如果合理）
2. 优化 exporter 采集的指标集合
3. 为 RDS 实例配置性能告警阈值
4. 考虑数据库读写分离，减轻主库压力

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
