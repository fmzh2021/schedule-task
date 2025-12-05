# GitHub Actions 告警平台

本项目使用 GitHub Actions 实现定时任务调度和告警平台，所有时间均使用**东八区（北京时间）**。

## 📋 目录

- [快速开始](#快速开始)
- [定时调度设置](#定时调度设置) ⭐ **重要：首次使用必读**
- [告警平台配置](#告警平台配置)
- [手动触发任务](#手动触发任务)
- [任务列表](#任务列表)
- [文件结构](#文件结构)
- [配置说明](#配置说明)

## 🚀 快速开始

### 方式一：使用告警平台（推荐）

告警平台基于配置文件管理任务，便于维护和扩展。

1. **编辑配置文件** `config/tasks.json`
2. **提交并推送**到 GitHub
3. 任务会自动按配置的时间执行

### 方式二：使用传统工作流

使用 `monthly-notification.yml` 工作流，直接在 YAML 文件中配置任务。

## ⏰ 定时调度设置

### GitHub Actions 会自动执行吗？

**是的！** GitHub Actions 的定时调度会自动执行，但需要满足以下条件：

#### ✅ 前提条件

1. **仓库类型**
   - ✅ **公开仓库（Public）**：完全免费，定时任务自动执行
   - ⚠️ **私有仓库（Private）**：需要 GitHub Pro/Team/Enterprise 账户
     - 免费账户的私有仓库不支持定时调度，但可以手动触发

2. **工作流文件位置**
   - 文件必须在 `.github/workflows/` 目录下
   - 必须推送到**默认分支**（`main` 或 `master`）

3. **启用 Actions**
   - 仓库 Settings → Actions → General
   - 确保 Actions permissions 已启用

#### 🚀 设置步骤

1. **推送代码到 GitHub**
   ```bash
   git add .
   git commit -m "添加告警平台"
   git push origin main
   ```

2. **验证工作流**
   - 进入仓库的 **Actions** 标签页
   - 应该能看到 "告警平台定时任务" 工作流

3. **手动测试（推荐）**
   - 点击 "Run workflow" 手动触发一次
   - 确认任务正常执行

4. **等待自动执行**
   - 定时任务会在下一个调度时间自动触发
   - 当前配置每分钟执行一次，最多等待 1 分钟就能看到执行记录

#### 📝 详细说明

更多关于定时调度的设置和常见问题，请查看：[GitHub Actions 定时调度设置指南](docs/GITHUB_ACTIONS_SETUP.md)

## ⚙️ 告警平台配置

### 配置文件位置

所有任务配置都在 `config/tasks.json` 文件中。

### 配置格式说明

```json
{
  "timezone": "Asia/Shanghai",
  "tasks": [
    {
      "id": "task-001",                    // 任务唯一ID
      "name": "任务名称",                   // 任务显示名称
      "enabled": true,                     // 是否启用（true/false）
      "schedule": {
        "day": 5,                          // 每月几号执行
        "hour": 10,                        // 几点执行（东八区时间）
        "minute": 0                        // 几分执行
        // 或者使用多个时间点：
        // "hours": [10],
        // "minutes": [0, 10, 30]
      },
      "notification": {
        "method": "GET",                    // HTTP 方法：GET（默认）或 POST
        "url": "http://notice.xmwefun.cn/",
        "params": {                         // GET 请求的 query 参数，或 POST 请求的 body（当没有 body 时）
          "msg": "消息内容",
          "type": "xchat",
          "title": "标题",
          "chatid": "0000001534"
        },
        "body": {},                         // POST 请求的 body（可选，优先级高于 params）
        "headers": {}                       // 自定义请求头（可选）
      }
    }
  ]
}
```

### 添加新任务

1. 打开 `config/tasks.json`
2. 在 `tasks` 数组中添加新任务配置
3. 设置 `enabled: true` 启用任务
4. 配置调度时间和通知参数
5. 提交并推送到 GitHub

### 禁用任务

将任务的 `enabled` 字段设置为 `false` 即可禁用，无需删除配置。

### 配置示例

#### 示例1：单次执行任务
```json
{
  "id": "task-001",
  "name": "每月5号通知",
  "enabled": true,
  "schedule": {
    "day": 5,
    "hour": 10,
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

#### 示例2：多次执行任务
```json
{
  "id": "task-002",
  "name": "每月15号复盘",
  "enabled": true,
  "schedule": {
    "day": 15,
    "hours": [10],
    "minutes": [0, 10, 30]
  },
  "notification": {
    "url": "http://notice.xmwefun.cn",
    "params": {
      "type": "xchat",
      "bot": "weiliao-personal",
      "title": "每月复盘"
    }
  }
}
```

#### 示例3：POST 请求（使用 body）
```json
{
  "id": "task-003",
  "name": "POST请求示例",
  "enabled": true,
  "schedule": {
    "day": 1,
    "hour": 10,
    "minute": 0
  },
  "notification": {
    "method": "POST",
    "url": "http://api.example.com/webhook",
    "body": {
      "event": "monthly_report",
      "data": {
        "month": "2024-01",
        "status": "completed"
      }
    },
    "headers": {
      "Authorization": "Bearer your-token-here",
      "Content-Type": "application/json"
    }
  }
}
```

#### 示例4：POST 请求（使用 params 作为 body）
```json
{
  "id": "task-004",
  "name": "POST请求使用params",
  "enabled": true,
  "schedule": {
    "day": 1,
    "hour": 10,
    "minute": 0
  },
  "notification": {
    "method": "POST",
    "url": "http://api.example.com/webhook",
    "params": {
      "message": "使用params作为POST body",
      "type": "notification"
    }
  }
}
```

## 🎯 手动触发任务

### 方法一：GitHub Actions 页面手动触发（推荐）

1. **打开 GitHub 仓库**
   - 进入你的 GitHub 仓库页面

2. **进入 Actions 标签页**
   - 点击仓库顶部的 "Actions" 标签

3. **选择工作流**
   - 在左侧工作流列表中选择 "告警平台定时任务"（notification-platform）

4. **手动触发**
   - 点击右侧的 "Run workflow" 按钮
   - 选择分支（通常是 `main` 或 `master`）
   - （可选）输入任务ID，留空则执行所有启用的任务
   - 点击绿色的 "Run workflow" 按钮

5. **查看执行结果**
   - 点击运行记录查看执行日志
   - 可以看到每个任务的执行状态和响应

### 方法二：使用 GitHub CLI

```bash
# 执行所有任务
gh workflow run "告警平台定时任务.yml"

# 执行指定任务（需要工作流支持）
gh workflow run "告警平台定时任务.yml" -f task_id=task-001
```

### 方法三：使用 API

```bash
# 使用 curl 调用 GitHub API
curl -X POST \
  -H "Authorization: token YOUR_GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/OWNER/REPO/actions/workflows/notification-platform.yml/dispatches \
  -d '{"ref":"main"}'
```

### 手动触发说明

- **执行所有任务**：不输入任务ID，会执行所有 `enabled: true` 的任务
- **执行指定任务**：输入任务ID（如 `task-001`），只执行该任务
- **查看日志**：在 Actions 页面可以查看详细的执行日志和响应结果

## 📝 任务列表

### 任务1：每月5号通知
- **任务ID**：`task-001`
- **执行时间**：每月5号 10:00（东八区时间）
- **执行内容**：调用通知接口发送 GitHub Actions 测试消息
- **接口地址**：`http://notice.xmwefun.cn/?msg=github-actions&type=xchat&title=github-actions&chatid=0000001534`

### 任务2：每月15号复盘通知
- **任务ID**：`task-002`
- **执行时间**：每月15号 10:00、10:10、10:30（东八区时间，共3次）
- **执行内容**：调用通知接口发送每月复盘消息
- **接口地址**：`http://notice.xmwefun.cn?type=xchat&bot=weiliao-personal&title=每月复盘&msg=...`

## 📁 文件结构

```
schedule-task/
├── .github/
│   └── workflows/
│       ├── monthly-notification.yml      # 传统工作流（已废弃，保留作为参考）
│       └── notification-platform.yml    # 告警平台工作流（推荐使用）
├── config/
│   └── tasks.json                        # 任务配置文件（核心配置）
├── scripts/
│   ├── execute-tasks.sh                  # 任务执行脚本
│   └── generate-cron.sh                  # Cron表达式生成脚本（辅助工具）
└── README.md                             # 本说明文档
```

## 🔧 配置说明

### 时区说明

- **配置文件时间**：所有时间均使用**东八区（北京时间）**
- **GitHub Actions**：使用 UTC 时间，系统会自动转换
- **转换规则**：北京时间 = UTC + 8小时

### 调度时间格式

#### 单次执行
```json
"schedule": {
  "day": 5,        // 每月5号
  "hour": 10,      // 10点
  "minute": 0      // 0分
}
```

#### 多次执行
```json
"schedule": {
  "day": 15,                    // 每月15号
  "hours": [10],                // 10点
  "minutes": [0, 10, 30]        // 0分、10分、30分（共3次）
}
```

### 通知参数配置

#### GET 请求（默认）

GET 请求的参数通过 URL query string 传递：

```json
"notification": {
  "method": "GET",  // 可选，默认为 GET
  "url": "http://notice.xmwefun.cn/",
  "params": {
    "msg": "消息内容",
    "type": "xchat",
    "title": "标题",
    "chatid": "0000001534"
  }
}
```

实际请求：`http://notice.xmwefun.cn/?msg=消息内容&type=xchat&title=标题&chatid=0000001534`

#### POST 请求（使用 body）

POST 请求的参数通过请求体（body）传递，支持 JSON 格式：

```json
"notification": {
  "method": "POST",
  "url": "http://api.example.com/webhook",
  "body": {
    "event": "notification",
    "data": {
      "message": "消息内容",
      "type": "alert"
    }
  },
  "headers": {
    "Authorization": "Bearer your-token",
    "Content-Type": "application/json"
  }
}
```

**说明：**
- `body`：POST 请求的请求体，可以是对象或字符串
- `headers`：自定义请求头（可选）
- 如果指定了 `body`，会使用 `body` 作为请求体
- 如果没有 `body` 但有 `params`，会将 `params` 作为 JSON body

#### POST 请求（使用 params 作为 body）

如果没有指定 `body`，`params` 会被转换为 JSON 作为 POST 请求体：

```json
"notification": {
  "method": "POST",
  "url": "http://api.example.com/webhook",
  "params": {
    "message": "消息内容",
    "type": "notification"
  }
}
```

实际请求体：`{"message": "消息内容", "type": "notification"}`

#### 支持的 HTTP 方法

- `GET`：默认方法，参数通过 URL query string 传递
- `POST`：参数通过请求体传递
- `PUT`、`DELETE`、`PATCH` 等：也支持，参数通过请求体传递

## ⚠️ 注意事项

1. **任务执行失败不会中断 workflow**，确保其他任务可以正常执行
2. **配置文件格式**：必须使用有效的 JSON 格式，建议使用 JSON 验证工具检查
3. **时间精度**：告警平台支持分钟级精度，可以精确到分钟
4. **任务启用**：只有 `enabled: true` 的任务才会被执行
5. **手动触发**：手动触发会执行所有启用的任务，不受时间限制
6. **执行频率**：工作流每分钟执行一次，但只有匹配时间的任务才会真正执行

## 🔍 故障排查

### 任务未执行

1. 检查任务 `enabled` 是否为 `true`
2. 检查配置文件 JSON 格式是否正确
3. 查看 Actions 执行日志
4. 确认时间配置是否正确（东八区时间）

### 手动触发无响应

1. 确认工作流文件已正确提交到 GitHub
2. 检查 Actions 权限设置
3. 查看执行日志中的错误信息

### URL 调用失败

1. 检查 URL 和参数是否正确
2. 查看执行日志中的错误信息
3. 确认网络连接正常

## 📚 相关资源

- [GitHub Actions 定时调度设置指南](docs/GITHUB_ACTIONS_SETUP.md) - 详细的设置说明和常见问题
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Cron 表达式说明](https://crontab.guru/)
- [JSON 格式验证](https://jsonlint.com/)
