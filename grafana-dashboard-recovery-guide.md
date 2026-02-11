# Grafana Dashboard 恢复指南

## 问题说明

导入的 `luckin-usa-master-dashboard-fixed.json` 只包含 9 个演示面板，而原始仪表板有 39 个面板。

**当前状态**:
- 仪表板 UID: `CbVZEvvDk`
- 标题: "Luckin Coffee USA - Master Operations"
- 面板数: 仅 9 个（应为 39 个）

## 恢复方案

### 方案1: 使用 Grafana 版本历史恢复（推荐）✅

Grafana 会保存仪表板的历史版本，可以恢复到之前的状态：

1. **打开仪表板**:
   ```
   https://iumbgrafana.luckincoffee.us/grafana/d/CbVZEvvDk/luckin-coffee-usa-master-operations
   ```

2. **查看版本历史**:
   - 点击右上角的 ⚙️ (Settings) 图标
   - 选择 "Versions" 标签
   - 查看历史版本列表

3. **恢复到之前的版本**:
   - 找到导入前的最后一个版本（应该有 39 个面板）
   - 点击该版本的 "Restore" 按钮
   - 确认恢复

### 方案2: 检查回收站（如果仪表板被删除）

如果原始仪表板被删除而不是覆盖：

1. **访问回收站**:
   ```
   https://iumbgrafana.luckincoffee.us/grafana/dashboards
   ```

2. **查找已删除的仪表板**:
   - 切换到 "Recently deleted" 标签
   - 查找原始的 "Luckin Coffee USA - Master Operations Dashboard"
   - UID 可能是: `luckin-usa-master`

3. **恢复仪表板**:
   - 点击 "Restore" 按钮

### 方案3: 使用 Grafana API 导出历史版本

如果 UI 无法访问，使用 API：

```bash
# 获取仪表板版本列表
curl -H "Authorization: Bearer YOUR_API_KEY" \
  "https://iumbgrafana.luckincoffee.us/grafana/api/dashboards/uid/CbVZEvvDk/versions"

# 获取特定版本的内容（替换 VERSION_NUMBER）
curl -H "Authorization: Bearer YOUR_API_KEY" \
  "https://iumbgrafana.luckincoffee.us/grafana/api/dashboards/uid/CbVZEvvDk/versions/VERSION_NUMBER" \
  -o dashboard-version-VERSION_NUMBER.json

# 恢复特定版本
curl -X POST \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d @dashboard-version-VERSION_NUMBER.json \
  "https://iumbgrafana.luckincoffee.us/grafana/api/dashboards/db"
```

### 方案4: 从数据库直接查询（需要 DBA 权限）

如果使用 Grafana 的 PostgreSQL/MySQL 后端：

```sql
-- 查询仪表板历史版本
SELECT version, created, message, data
FROM dashboard_version
WHERE dashboard_id = (
  SELECT id FROM dashboard WHERE uid = 'CbVZEvvDk'
)
ORDER BY version DESC;

-- 导出特定版本的 JSON
SELECT data
FROM dashboard_version
WHERE dashboard_id = (SELECT id FROM dashboard WHERE uid = 'CbVZEvvDk')
  AND version = VERSION_NUMBER;
```

## 正确的修复流程

修复数据源问题的正确流程应该是：

1. **不要导入新的 JSON**（会覆盖现有仪表板）
2. **直接添加缺失的数据源**：
   ```
   Name: MySQL-salesorder
   Host: aws-luckyus-salesorder-rw.cxwu08m2qypw.us-east-1.rds.amazonaws.com:3306
   Database: luckyus_sales_order
   ```
3. **刷新仪表板**（数据源添加后自动生效）

## 预防措施

为避免类似问题：

1. **在导入前备份**:
   - 导出原始仪表板为 JSON
   - 保存版本号信息

2. **使用不同的 UID**:
   - 导入修复版本时使用新的 UID
   - 避免覆盖原始仪表板

3. **测试环境验证**:
   - 先在测试环境导入测试
   - 确认无问题后再在生产环境操作

## 立即行动步骤

1. ✅ 打开仪表板设置 → Versions
2. ✅ 找到导入前的版本（查看创建时间和面板数）
3. ✅ 点击 Restore 恢复
4. ✅ 按照 `grafana-dashboard-fix-README.md` 添加缺失的数据源
5. ✅ 验证所有 39 个面板正常显示

---

**重要**: 不要删除当前导入的仪表板，先恢复历史版本，确认正常后再处理。

**联系人**: 如果无法通过 UI 恢复，请联系 Grafana 管理员使用 API 或数据库方式恢复。

**创建时间**: 2026-02-11
**紧急程度**: 高
