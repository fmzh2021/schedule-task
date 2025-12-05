#!/bin/bash
# 从配置文件生成 cron 表达式

CONFIG_FILE="config/tasks.json"
OUTPUT_FILE=".github/workflows/generated-cron.txt"

# 读取配置文件
if [ ! -f "$CONFIG_FILE" ]; then
  echo "错误: 配置文件 $CONFIG_FILE 不存在"
  exit 1
fi

# 使用 jq 解析 JSON（如果可用）
if command -v jq &> /dev/null; then
  echo "# 自动生成的 cron 表达式（东八区时间）" > "$OUTPUT_FILE"
  echo "# 此文件由 scripts/generate-cron.sh 自动生成，请勿手动编辑" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  
  # 遍历所有启用的任务
  jq -r '.tasks[] | select(.enabled == true) | 
    if .schedule.minutes then
      # 单个时间点
      "\(.schedule.minute) \(.schedule.hour - 8 | if . < 0 then . + 24 else . end) \(.schedule.day) * * # \(.name)"
    else
      # 多个时间点
      .schedule.minutes[] as $min |
      "\($min) \(.schedule.hours[0] - 8 | if . < 0 then . + 24 else . end) \(.schedule.day) * * # \(.name) - \($min)分"
    end' "$CONFIG_FILE" >> "$OUTPUT_FILE"
  
  echo "Cron 表达式已生成到 $OUTPUT_FILE"
else
  echo "警告: jq 未安装，无法自动生成 cron 表达式"
  echo "请安装 jq: brew install jq (macOS) 或 apt-get install jq (Linux)"
fi

