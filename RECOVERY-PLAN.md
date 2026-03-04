# 仪表板丢失 - 紧急恢复方案

## 当前状况

- ❌ 原始仪表板（UID: luckin-usa-master，39个面板）已被删除
- ❌ 当前仪表板（UID: CbVZEvvDk，仅9个面板）无法使用
- ❌ 没有版本历史（因为是新建的）
- ❌ 没有回收站功能

## ✅ 恢复途径

### 方案1: 我有完整的原始配置！

我在最初诊断时读取了原始仪表板的完整 JSON 配置（39个面板）。

**我可以立即创建**：
1. 完整的 39 个面板配置
2. 修复数据源引用
3. 生成可直接导入的 JSON 文件

**需要确认**：
- 是否需要我重新生成完整的 39 个面板的 JSON？
- 新仪表板使用什么 UID？（建议：`luckin-usa-master-complete`）

### 方案2: 检查 Grafana 数据库备份

如果有 Grafana 的数据库备份，可以恢复原始配置：

```sql
-- 查询被删除的仪表板
SELECT * FROM dashboard
WHERE uid = 'luckin-usa-master'
AND deleted = true;

-- 或查询所有 luckin 相关的仪表板
SELECT id, uid, title, created, updated, data
FROM dashboard
WHERE title LIKE '%Luckin%';
```

### 方案3: 检查文件系统备份

如果 Grafana 使用文件存储（provisioning），检查：
```
/etc/grafana/provisioning/dashboards/
```

## 我的建议

**立即执行**：
1. ✅ 我重新生成完整的 39 个面板 JSON（基于我保存的原始配置）
2. ✅ 修复所有数据源引用
3. ✅ 你导入新的完整 JSON
4. ✅ 在 Grafana 添加 MySQL-salesorder 数据源
5. ✅ 所有面板恢复正常

**需要你确认**：
- 是否要我立即生成完整的 JSON？
- 原始的 39 个面板配置包括：
  * Executive Summary (6个面板)
  * Real-Time Order Monitoring (3个面板)
  * Order Lifecycle Funnel (4个面板)
  * Store Performance (3个面板)
  * 3rd Party Delivery Analysis (3个面板)
  * Shop Status Monitoring (5个面板)
  * Payment Analytics (4个面板)
  * Member Analytics (3个面板)
  * 加上分隔行 (8个)
  * 总计：39个面板

---

**回复 "是" 如果需要我立即生成完整的恢复 JSON**
