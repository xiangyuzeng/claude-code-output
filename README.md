# Claude Code Output Repository

> 自动化运维调查、脚本和文档的集中存储仓库

## 📁 仓库结构

```
claude-code-output/
├── .claude-workspace.json          # Claude工作区配置
├── git-push.sh                     # Git自动推送脚本
├── README.md                       # 本文件
├── elasticsearch-ops-luckycommon.md # ES luckycommon磁盘清理手册
└── es_cleanup_luckycommon.py       # ES自动化清理脚本
```

## 🔧 工作流程

### Claude自动工作流

1. **文件创建**: 所有新文件默认创建在 `/app/claude-code-output/`
2. **Git跟踪**: 自动跟踪所有更改
3. **推送到GitHub**: 使用便捷脚本一键推送

### 手动推送文件到GitHub

```bash
cd /app/claude-code-output

# 方法1: 使用自动化脚本（推荐）
./git-push.sh "Add new investigation report"

# 方法2: 标准git命令
git add .
git commit -m "Your commit message"
git push origin main
```

## 📝 文件组织建议

### 调查报告
- 文件名格式: `{service}-{type}-{date}.md`
- 例如: `elasticsearch-investigation-20260128.md`

### 自动化脚本
- 文件名格式: `{service}_{action}_{cluster}.py`
- 例如: `es_cleanup_luckycommon.py`

### 文档
- 操作手册: `{service}-ops-{cluster}.md`
- 配置指南: `{service}-config-guide.md`

## 🔐 安全注意事项

- ⚠️ **不要提交敏感信息**: 密码、Token、密钥等
- ✅ **使用环境变量**: 敏感配置使用环境变量
- ✅ **添加.gitignore**: 排除临时文件和敏感数据

## 📚 已完成的调查

### 2026-01-28: Elasticsearch luckycommon磁盘空间不足
- **文件**: `elasticsearch-ops-luckycommon.md`, `es_cleanup_luckycommon.py`
- **集群**: luckycommon (AWS Account: 257394478466, us-east-1)
- **问题**: 磁盘空间低于10GB阈值 (9.96GB可用, 91.9%使用率)
- **解决方案**:
  - P0: 删除旧索引 + Force merge (预计释放4-7GB)
  - P1: 实施ILM策略（30天自动删除）
  - P2: EBS扩容至50GB/节点

## 🔗 相关链接

- **GitHub Repository**: https://github.com/xiangyuzeng/claude-code-output
- **工作目录**: `/app/claude-code-output`

## 📞 联系方式

如有问题，请联系仓库维护者。

---

*Last updated: 2026-01-28*
*Maintained with Claude Code*
