# Luckin USA Master Dashboard 修复方案

## 问题诊断

### 仪表板信息
- **名称**: Luckin Coffee USA - Master Operations Dashboard
- **UID**: `luckin-usa-master`
- **URL**: https://iumbgrafana.luckincoffee.us/grafana/d/luckin-usa-master/luckin-coffee-usa-master-operations-dashboard
- **面板总数**: 39个

### 根本原因

仪表板配置了3个MySQL数据源变量，但只有1个变量能找到匹配的数据源：

| 变量名 | 匹配规则 | 状态 | 实际数据源 |
|--------|---------|------|-----------|
| DS_ILUCKYHEALTH | `.*iluckyhealth.*` | ✅ 正常 | MySQL-luckyhealth (UID: 3x14XnENk) |
| DS_SALESORDER | `.*salesorder.*` | ❌ 缺失 | 无匹配数据源 |
| DS_OPSHOP | `.*opshop.*` | ❌ 缺失 | 无匹配数据源 |

### 数据库依赖分析

#### 1. luckyus_iluckyhealth (✅ 可用)
- **表**:
  - t_collect_order_inter (订单汇总数据)
  - t_collect_shop_inter (店铺状态数据)
  - t_collect_payment_inter (支付数据)
  - t_collect_crm_inter (会员数据)
- **连接**: aws-luckyus-iluckyhealth-rw.cxwu08m2qypw.us-east-1.rds.amazonaws.com
- **数据源**: MySQL-luckyhealth

#### 2. luckyus_sales_order (❌ 缺失)
- **表**:
  - t_order (订单详细数据)
- **需要用于**:
  - Revenue Today (今日收入)
  - Avg Order Value (平均订单价值)
  - Top 10 Stores by Orders (按订单量排名前10的店铺)
  - Store Performance Table (店铺绩效表)
  - Store Orders Over Time (店铺订单趋势)
  - 3P Orders by Store (第三方平台订单按店铺)

## 影响的面板

### 🔴 需要 luckyus_sales_order 的面板 (6个)
1. **Revenue Today** (Panel ID: 2) - 今日收入统计
2. **Avg Order Value** (Panel ID: 3) - 平均订单价值
3. **Top 10 Stores by Orders** (Panel ID: 14) - 订单量前10店铺
4. **Store Performance Table** (Panel ID: 15) - 店铺绩效表
5. **Store Orders Over Time** (Panel ID: 16) - 店铺订单趋势
6. **3P Orders by Store** (Panel ID: 19) - 第三方订单按店铺

### ✅ 使用 luckyus_iluckyhealth 的面板 (25个)
所有其他面板都可以正常工作

## 修复方案

### 方案1: 添加缺失的数据源 (推荐) ✅ 已确认数据库位置

需要在 Grafana 中创建一个新的 MySQL 数据源：

**数据源配置**:
- **名称**: `MySQL-salesorder` (或包含 "salesorder" 的任何名称)
- **类型**: MySQL
- **主机**: `aws-luckyus-salesorder-rw.cxwu08m2qypw.us-east-1.rds.amazonaws.com`
- **端口**: `3306`
- **数据库**: `luckyus_sales_order`
- **用户**: [需要提供只读用户]
- **密码**: [需要提供密码]

**创建步骤**:
1. 登录 Grafana
2. 进入 Configuration → Data sources
3. 点击 "Add data source"
4. 选择 "MySQL"
5. 填写上述配置信息
6. 点击 "Save & test"
7. 刷新仪表板 `luckin-usa-master`

### 方案2: 临时修复 - 禁用缺失数据的面板

将无法获取数据的面板标记为"数据源缺失"状态，保留其他正常工作的面板。

已创建修复后的配置文件：
- `luckin-usa-master-dashboard-fixed.json` - 部分修复版本（演示）
- 删除了数据源变量
- 直接使用MySQL-luckyhealth的UID (3x14XnENk)
- 标记需要salesorder数据源的面板

### 方案3: 检查MySQL-Ldas数据源

MySQL-Ldas数据源连接到 `luckyus_db_collection` 数据库。需要确认：
1. 该数据库是否包含 `t_order` 表？
2. 如果包含，可以修改变量匹配规则或创建新数据源

## 下一步操作

### 立即修复（推荐）✅

1. **在 Grafana 中创建新数据源**:
   - 名称: `MySQL-salesorder`
   - 主机: `aws-luckyus-salesorder-rw.cxwu08m2qypw.us-east-1.rds.amazonaws.com`
   - 数据库: `luckyus_sales_order`
   - 用户: [需要DBA提供只读用户]
   - 测试连接成功后保存

2. **验证修复**:
   - 打开仪表板: https://iumbgrafana.luckincoffee.us/grafana/d/luckin-usa-master/
   - 检查以下面板是否显示数据:
     - Revenue Today
     - Avg Order Value
     - Top 10 Stores by Orders
     - Store Performance Table
     - Store Orders Over Time
     - 3P Orders by Store

### 临时方案

3. **使用修复后的JSON（如果无法创建数据源）**:
   - 导入 `luckin-usa-master-dashboard-fixed.json`
   - 新UID为 `luckin-usa-master-fixed`
   - 标记了所有缺失数据源的面板，其他25个面板正常工作

## 当前可用的MySQL数据源

```
1. MySQL-luckyhealth (UID: 3x14XnENk)
   - Database: luckyus_iluckyhealth
   - Host: aws-luckyus-iluckyhealth-rw.cxwu08m2qypw.us-east-1.rds.amazonaws.com

2. MySQL-Ldas (UID: LJ7ObqYNk)
   - Database: luckyus_db_collection
   - Host: aws-luckyus-ldas01-rw.cxwu08m2qypw.us-east-1.rds.amazonaws.com

3. MySQL-iriskcontrol (UID: BdRo02LNk)

4. Doris-iriskcontrol (UID: T-FUz9aNz)
```

## 检查清单

- [x] ~~确认 luckyus_sales_order 数据库的RDS实例地址~~ ✅ 已确认
  - 主机: `aws-luckyus-salesorder-rw.cxwu08m2qypw.us-east-1.rds.amazonaws.com`
- [ ] 获取数据库只读用户凭证（联系DBA）
- [ ] 在 Grafana 中创建新的 MySQL 数据源
  - 名称必须包含 "salesorder"
  - 使用上述主机地址
  - 数据库名: `luckyus_sales_order`
- [ ] 测试数据源连接（Save & test）
- [ ] 刷新仪表板确认所有面板正常显示数据
- [ ] 验证以下6个关键面板:
  - [ ] Revenue Today
  - [ ] Avg Order Value
  - [ ] Top 10 Stores by Orders
  - [ ] Store Performance Table
  - [ ] Store Orders Over Time
  - [ ] 3P Orders by Store

## 快速修复指南

### 命令参考（供DBA使用）

如果需要创建只读用户：
```sql
-- 在 aws-luckyus-salesorder-rw RDS 实例上执行
CREATE USER 'grafana_salesorder_ro'@'%' IDENTIFIED BY 'YOUR_SECURE_PASSWORD';
GRANT SELECT ON luckyus_sales_order.* TO 'grafana_salesorder_ro'@'%';
FLUSH PRIVILEGES;
```

### Grafana 数据源配置（快速复制）

```
Name: MySQL-salesorder
Type: MySQL
Host: aws-luckyus-salesorder-rw.cxwu08m2qypw.us-east-1.rds.amazonaws.com:3306
Database: luckyus_sales_order
User: grafana_salesorder_ro (或其他只读用户)
Password: [从密码管理器获取]
```

### 测试查询
创建数据源后，可以用这个查询测试：
```sql
SELECT COUNT(*) as order_count, SUM(pay_money) as total_revenue
FROM luckyus_sales_order.t_order
WHERE tenant = 'LKUS' AND status = 90 AND DATE(create_time) = CURDATE();
```

---

**日期**: 2026-02-11
**更新**: 已确认 salesorder 数据库位置
**问题分类**: 数据源配置缺失
**严重程度**: 中等 (影响6个关键业务指标面板)
**预计修复时间**: 5-10分钟（创建数据源后立即生效）
