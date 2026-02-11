# 导入故障排查指南

## 🔍 请先回答以下问题

### 1. 导入时的具体表现

导入时您看到的是什么？

- [ ] A. 导入页面显示 **"Dashboard imported"** 或 **"导入成功"**
- [ ] B. 导入页面显示 **红色错误提示**
- [ ] C. 导入后跳转到新页面，但页面是**空白的**
- [ ] D. 其他情况：__________________

### 2. 导入后的仪表板列表

在 Dashboards 列表中：

- [ ] A. 可以看到一个新的仪表板（标题: "Luckin Coffee USA - Master Operations (COMPLETE 39 PANELS)"）
- [ ] B. 看不到任何新的仪表板
- [ ] C. 不确定，列表太多了

### 3. 使用的文件

您导入的是哪个文件？

- [ ] A. `luckin-usa-dashboard-FIXED-VERSION.json` (73KB)
- [ ] B. `luckin-usa-dashboard-COMPLETE-39-PANELS-UI-IMPORT.json` (74KB)
- [ ] C. 其他文件：__________________

### 4. 导入方式

您是如何导入的？

- [ ] A. Dashboards → Import → Upload JSON file → 选择文件
- [ ] B. Dashboards → Import → 粘贴 JSON 内容
- [ ] C. 其他方式：__________________

### 5. 浏览器控制台

按 F12 打开浏览器开发者工具，切换到 **Console** 标签，有没有**红色错误**？

- [ ] A. 有红色错误
- [ ] B. 没有错误
- [ ] C. 不确定怎么看

---

## 🔧 可能的解决方案

### 方案1: 使用纯Dashboard格式（推荐尝试）

我刚刚创建了一个**不带包装的纯dashboard版本**：

**文件**: `luckin-usa-dashboard-PURE.json` (68KB)

**与之前的区别**:
```json
// ❌ 之前的格式（带包装）
{
  "dashboard": {
    "annotations": {...},
    "panels": [...]
  }
}

// ✅ 新格式（纯dashboard）
{
  "annotations": {...},
  "panels": [...]
}
```

某些Grafana版本的UI导入可能只接受纯dashboard格式。

### 方案2: 检查JSON格式

确认下载的JSON文件：
1. 用文本编辑器打开文件
2. 检查第一行是否是 `{`
3. 检查最后一行是否是 `}`
4. 文件大小应该是 68KB-74KB 之间

### 方案3: 使用API导入（如果UI一直失败）

如果UI导入一直不成功，可以尝试使用Grafana API：

```bash
# 使用curl命令导入
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d @luckin-usa-dashboard-FIXED-VERSION.json \
  https://iumbgrafana.luckincoffee.us/grafana/api/dashboards/db
```

### 方案4: 清除浏览器缓存

有时候浏览器缓存会导致问题：
1. 按 Ctrl+Shift+Delete (或 Cmd+Shift+Delete)
2. 清除浏览器缓存
3. 重新登录 Grafana
4. 再次尝试导入

---

## 🎯 下一步

**请您先告诉我上面"问题1-5"的答案**，特别是：
1. 导入时是否显示成功？
2. 是否有错误提示？
3. 浏览器控制台是否有错误？

根据您的回答，我可以提供更准确的解决方案。

如果您愿意尝试，可以先试试**方案1**：导入新的 `luckin-usa-dashboard-PURE.json` 文件。

---

**创建日期**: 2026-02-11
**目的**: 诊断和解决导入后面板不显示的问题
