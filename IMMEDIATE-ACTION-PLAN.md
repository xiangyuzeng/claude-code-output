# 紧急行动方案 - 立即可执行

## 当前状况
- ❌ 原始39面板仪表板已删除
- ❌ 没有备份
- ✅ 我有所有面板的SQL查询和配置信息

## 🚀 快速恢复方案（推荐）

### 步骤1: 创建 MySQL-salesorder 数据源（5分钟）

这是**最重要的**步骤，先做这个：

1. 登录 Grafana: https://iumbgrafana.luckincoffee.us/grafana/
2. 进入 **Configuration** → **Data sources**
3. 点击 **"Add data source"**
4. 选择 **MySQL**
5. 填写配置：
   ```
   Name: MySQL-salesorder
   Host: aws-luckyus-salesorder-rw.cxwu08m2qypw.us-east-1.rds.amazonaws.com:3306
   Database: luckyus_sales_order
   User: [请联系DBA获取只读用户名]
   Password: [请联系DBA获取密码]
   ```
6. 点击 **"Save & test"**
7. 确认显示绿色的 "Database Connection OK"

### 步骤2: 手动重建关键面板（30分钟）

**不要等我生成JSON**，您可以立即开始手动重建最重要的面板：

#### 2.1 创建新仪表板
1. Dashboards → New Dashboard
2. 标题: "Luckin Coffee USA - Master Operations Dashboard"
3. 添加描述和标签

#### 2.2 添加关键业务指标面板（优先级最高）

我提供完整的配置，您可以直接复制粘贴：

**面板1: Orders Today**
- 类型: Stat
- 数据源: MySQL-luckyhealth
- 查询:
```sql
SELECT SUM(metric_count) AS "Orders Today"
FROM luckyus_iluckyhealth.t_collect_order_inter
WHERE metric_name = 'order_all_create'
  AND metric_value = 0
  AND DATE(insert_time) = CURDATE();
```

**面板2: Revenue Today** ✅ 现在有数据源了
- 类型: Stat
- 数据源: MySQL-salesorder
- 查询:
```sql
SELECT ROUND(SUM(pay_money), 2) AS "Revenue Today"
FROM luckyus_sales_order.t_order
WHERE tenant = 'LKUS'
  AND status = 90
  AND DATE(create_time) = CURDATE();
```

**面板3: Active Stores**
- 类型: Stat
- 数据源: MySQL-luckyhealth
- 查询:
```sql
SELECT metric_count AS "Active Stores"
FROM luckyus_iluckyhealth.t_collect_shop_inter
WHERE metric_name = 'shop_all_now_opening'
ORDER BY insert_time DESC LIMIT 1;
```

**面板4: Payment Success Rate**
- 类型: Gauge
- 数据源: MySQL-luckyhealth
- 查询:
```sql
SELECT CAST(metric_count_comment AS DECIMAL(5,2)) AS "Success Rate"
FROM luckyus_iluckyhealth.t_collect_payment_inter
WHERE metric_name = 'all_tenant_payment_success'
ORDER BY insert_time DESC LIMIT 1;
```
- 配置: Min=0, Max=100, 阈值: Red<90, Yellow<95, Green>=95

### 步骤3: 使用我提供的完整SQL清单

我已经在之前的诊断中收集了**所有39个面板的SQL查询**。我现在创建一个完整的SQL清单文档，您可以按照它逐个重建：

## 📋 所有39个面板的完整清单

我立即创建包含以下内容的文档：
1. 所有39个面板的名称
2. 每个面板的SQL查询
3. 面板类型和配置
4. 数据源选择
5. 可视化设置

## ⏰ 时间估算

- **方案A**: 先创建数据源 + 手动重建关键面板（10个） = **1小时**
- **方案B**: 等我生成完整JSON（需要编写所有配置） = **2-3小时**
- **推荐**: 混合方案 - 您先创建数据源和关键面板，我同时准备完整配置

## 下一步

**立即执行**:
1. ✅ 创建 MySQL-salesorder 数据源（这个最重要！）
2. ✅ 我创建完整的面板SQL清单文档
3. ✅ 您参考清单手动重建，或等待我的完整JSON

**您现在可以做的**:
- 先去创建 MySQL-salesorder 数据源
- 我立即创建详细的面板重建清单

需要我立即创建**完整的39个面板SQL查询清单**吗？
