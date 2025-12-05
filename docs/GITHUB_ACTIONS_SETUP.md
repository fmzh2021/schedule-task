# GitHub Actions 定时调度设置指南

## 📌 概述

GitHub Actions 的定时调度（`schedule`）**会自动执行**，但需要满足一些前提条件。

## ✅ 自动执行的前提条件

### 1. 仓库类型要求

- ✅ **公开仓库（Public）**：完全免费，定时任务自动执行
- ✅ **私有仓库（Private）**：需要 GitHub Pro/Team/Enterprise 账户
  - 免费账户的私有仓库**不支持**定时调度
  - 但可以手动触发（`workflow_dispatch`）

### 2. 工作流文件位置

- 工作流文件必须位于：`.github/workflows/` 目录下
- 文件扩展名必须是：`.yml` 或 `.yaml`
- 文件必须推送到**默认分支**（通常是 `main` 或 `master`）

### 3. GitHub Actions 必须启用

- 仓库的 Actions 功能必须处于启用状态
- 默认情况下，公开仓库的 Actions 是启用的

## 🚀 设置步骤

### 步骤 1：检查仓库设置

1. 进入你的 GitHub 仓库
2. 点击 **Settings**（设置）
3. 在左侧菜单找到 **Actions** → **General**
4. 确保 **Actions permissions** 设置为：
   - ✅ "Allow all actions and reusable workflows"（推荐）
   - 或 "Allow local actions and reusable workflows"

### 步骤 2：推送工作流文件

确保工作流文件已推送到默认分支：

```bash
# 检查当前分支
git branch

# 如果不在默认分支，切换到默认分支
git checkout main  # 或 master

# 添加文件
git add .github/workflows/notification-platform.yml
git add config/tasks.json
git add scripts/execute-tasks.sh

# 提交并推送
git commit -m "添加告警平台定时任务"
git push origin main
```

### 步骤 3：验证工作流

1. 进入仓库的 **Actions** 标签页
2. 你应该能看到 "告警平台定时任务" 工作流
3. 点击工作流，查看是否显示在列表中

### 步骤 4：等待首次执行

- GitHub Actions 的定时任务**不会立即执行**
- 首次执行会在下一个调度时间点触发
- 当前配置是每分钟执行一次（`* * * * *`），所以最多等待 1 分钟就能看到执行记录

### 步骤 5：手动测试（推荐）

在等待定时执行之前，建议先手动触发一次测试：

1. 进入 **Actions** 标签页
2. 选择 "告警平台定时任务" 工作流
3. 点击右侧的 **Run workflow** 按钮
4. 选择分支，点击 **Run workflow**
5. 查看执行日志，确认任务正常执行

## ⚙️ 定时调度说明

### Cron 表达式格式

```
┌───────────── 分钟 (0 - 59)
│ ┌───────────── 小时 (0 - 23) UTC时间
│ │ ┌───────────── 日 (1 - 31)
│ │ │ ┌───────────── 月 (1 - 12)
│ │ │ │ ┌───────────── 星期 (0 - 6) (0是星期日)
│ │ │ │ │
* * * * *
```

### 当前配置

当前工作流配置为每分钟执行一次：

```yaml
schedule:
  - cron: '* * * * *'  # 每分钟执行
```

**为什么每分钟执行？**

- 这样可以支持**分钟级精度**的任务调度
- 脚本内部会判断当前时间是否匹配任务配置
- 只有匹配的任务才会真正执行，不会造成资源浪费

### 时区说明

⚠️ **重要**：GitHub Actions 的 cron 使用 **UTC 时间**（协调世界时）

- 北京时间 = UTC + 8 小时
- 例如：北京时间 10:00 = UTC 02:00
- 我们的脚本会自动处理时区转换

## 🔍 验证定时任务是否运行

### 方法 1：查看 Actions 历史

1. 进入仓库的 **Actions** 标签页
2. 查看 "告警平台定时任务" 的执行历史
3. 应该能看到每分钟都有新的执行记录（即使没有任务执行）

### 方法 2：查看执行日志

1. 点击任意一次执行记录
2. 查看日志输出：
   - 如果当前时间有任务，会显示 "执行任务: xxx"
   - 如果没有任务，会显示 "当前时间没有需要执行的任务"

### 方法 3：设置测试任务

在 `config/tasks.json` 中添加一个测试任务：

```json
{
  "id": "test-task",
  "name": "测试任务",
  "enabled": true,
  "schedule": {
    "day": 31,  // 设置为今天或明天的日期
    "hour": 14, // 设置为当前时间后1-2小时
    "minute": 0
  },
  "notification": {
    "url": "http://notice.xmwefun.cn/",
    "params": {
      "msg": "测试消息",
      "type": "xchat"
    }
  }
}
```

## ❌ 常见问题

### Q1: 定时任务没有执行？

**可能原因：**
1. 仓库是私有的，且账户是免费版
   - **解决方案**：改为公开仓库，或升级到 Pro 账户
2. 工作流文件不在默认分支
   - **解决方案**：确保文件在 `main` 或 `master` 分支
3. Actions 功能被禁用
   - **解决方案**：在仓库设置中启用 Actions

### Q2: 如何知道任务是否在运行？

- 查看 Actions 标签页的执行历史
- 每分钟应该有一条新的执行记录
- 点击记录查看详细日志

### Q3: 可以修改执行频率吗？

可以！修改 `.github/workflows/notification-platform.yml` 中的 cron 表达式：

```yaml
# 每5分钟执行一次
- cron: '*/5 * * * *'

# 每小时执行一次
- cron: '0 * * * *'

# 每天凌晨2点执行（UTC时间）
- cron: '0 2 * * *'
```

**注意**：执行频率越低，任务的时间精度也越低。

### Q4: 免费账户可以使用定时任务吗？

- ✅ **公开仓库**：完全免费，无限制
- ❌ **私有仓库**：需要付费账户（Pro/Team/Enterprise）
- ✅ **手动触发**：免费账户的私有仓库也可以手动触发

## 📊 执行频率建议

| 需求 | Cron 表达式 | 说明 |
|------|------------|------|
| 分钟级精度 | `* * * * *` | 当前配置，支持精确到分钟 |
| 5分钟精度 | `*/5 * * * *` | 每5分钟检查一次 |
| 小时级精度 | `0 * * * *` | 每小时整点执行 |
| 每天执行 | `0 2 * * *` | 每天 UTC 02:00（北京时间 10:00）|

**建议**：如果任务都是整点或固定时间执行，可以使用更低的频率（如每小时），减少 GitHub Actions 的使用量。

## 🔗 相关资源

- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [GitHub Actions 定价](https://github.com/pricing)
- [Cron 表达式生成器](https://crontab.guru/)

