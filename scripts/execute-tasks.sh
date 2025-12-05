#!/bin/bash
# 执行告警任务脚本

CONFIG_FILE="config/tasks.json"
CURRENT_UTC_HOUR=$(date -u +%H)
CURRENT_UTC_MINUTE=$(date -u +%M)
CURRENT_UTC_DAY=$(date -u +%d)

# 将 UTC 时间转换为东八区时间
CURRENT_DAY=$((10#$CURRENT_UTC_DAY))
CURRENT_HOUR=$((10#$CURRENT_UTC_HOUR + 8))
if [ $CURRENT_HOUR -ge 24 ]; then
  CURRENT_HOUR=$((CURRENT_HOUR - 24))
  CURRENT_DAY=$((CURRENT_DAY + 1))
fi
CURRENT_MINUTE=$((10#$CURRENT_UTC_MINUTE))

echo "当前时间（东八区）: ${CURRENT_DAY}日 ${CURRENT_HOUR}:${CURRENT_MINUTE}"

# 检查是否为手动触发
MANUAL_MODE=false
TASK_ID_FILTER=""
if [ "$1" = "manual" ]; then
  MANUAL_MODE=true
  TASK_ID_FILTER="$2"  # 第二个参数是任务ID（可选）
fi

# 使用 Python 解析 JSON 并执行任务（更可靠）
export MANUAL_MODE
export TASK_ID_FILTER
python3 << 'PYTHON_SCRIPT'
import json
import os
import sys
import urllib.parse
import urllib.request
from datetime import datetime

config_file = "config/tasks.json"
manual_mode = os.environ.get("MANUAL_MODE", "false").lower() == "true"
task_id_filter = os.environ.get("TASK_ID_FILTER", "").strip()

# 获取当前时间
utc_now = datetime.utcnow()
current_day = utc_now.day
current_hour = utc_now.hour
current_minute = utc_now.minute

# 转换为东八区时间
beijing_hour = current_hour + 8
beijing_day = current_day
if beijing_hour >= 24:
    beijing_hour -= 24
    beijing_day += 1

print(f"当前时间（东八区）: {beijing_day}日 {beijing_hour}:{current_minute:02d}")

try:
    with open(config_file, 'r', encoding='utf-8') as f:
        config = json.load(f)
    
    executed = False
    for task in config.get("tasks", []):
        if not task.get("enabled", True):
            continue
        
        task_id = task.get("id")
        task_name = task.get("name")
        schedule = task.get("schedule", {})
        notification = task.get("notification", {})
        
        # 如果指定了任务ID过滤，只执行匹配的任务
        if task_id_filter and task_id != task_id_filter:
            continue
        
        should_execute = False
        
        if manual_mode:
            should_execute = True
            if task_id_filter:
                print(f"\n[手动触发-指定任务] 执行任务: {task_name} ({task_id})")
            else:
                print(f"\n[手动触发-全部任务] 执行任务: {task_name} ({task_id})")
        else:
            # 检查是否匹配调度时间
            task_day = schedule.get("day")
            if task_day != beijing_day:
                continue
            
            # 处理单个时间点
            if "minute" in schedule and "hour" in schedule:
                task_hour = schedule.get("hour")
                task_minute = schedule.get("minute")
                if task_hour == beijing_hour and task_minute == current_minute:
                    should_execute = True
                    print(f"\n[定时触发] 执行任务: {task_name} ({task_id})")
            
            # 处理多个时间点
            elif "minutes" in schedule and "hours" in schedule:
                task_hours = schedule.get("hours", [])
                task_minutes = schedule.get("minutes", [])
                if beijing_hour in task_hours and current_minute in task_minutes:
                    should_execute = True
                    print(f"\n[定时触发] 执行任务: {task_name} ({task_id})")
        
        if should_execute:
            executed = True
            url = notification.get("url", "")
            method = notification.get("method", "GET").upper()  # 默认 GET
            params = notification.get("params", {})  # GET 请求的 query 参数或 POST 请求的 body
            body = notification.get("body", None)  # POST 请求的 body（优先级高于 params）
            headers = notification.get("headers", {})  # 自定义请求头
            
            try:
                # 准备请求
                if method == "GET":
                    # GET 请求：参数放在 URL query string
                    if params:
                        query_string = urllib.parse.urlencode(params)
                        full_url = f"{url}?{query_string}" if "?" not in url else f"{url}&{query_string}"
                    else:
                        full_url = url
                    print(f"  请求方法: GET")
                    print(f"  请求 URL: {full_url}")
                    
                    request = urllib.request.Request(full_url, method="GET")
                
                elif method == "POST":
                    # POST 请求：参数放在 body
                    print(f"  请求方法: POST")
                    print(f"  请求 URL: {url}")
                    
                    # 确定 body 内容
                    if body is not None:
                        # 如果指定了 body，直接使用
                        if isinstance(body, dict):
                            body_data = json.dumps(body).encode('utf-8')
                            content_type = "application/json"
                        elif isinstance(body, str):
                            body_data = body.encode('utf-8')
                            content_type = "application/json"
                        else:
                            body_data = str(body).encode('utf-8')
                            content_type = "application/json"
                    elif params:
                        # 如果没有 body 但有 params，将 params 作为 JSON body
                        body_data = json.dumps(params).encode('utf-8')
                        content_type = "application/json"
                    else:
                        body_data = None
                        content_type = None
                    
                    # 设置请求头
                    request_headers = {}
                    if content_type:
                        request_headers["Content-Type"] = content_type
                    
                    # 添加自定义请求头
                    if headers:
                        request_headers.update(headers)
                    
                    print(f"  请求 Body: {body_data.decode('utf-8') if body_data else '(empty)'}")
                    if request_headers:
                        print(f"  请求头: {request_headers}")
                    
                    request = urllib.request.Request(url, data=body_data, headers=request_headers, method="POST")
                
                else:
                    # 其他 HTTP 方法（PUT, DELETE 等）
                    print(f"  请求方法: {method}")
                    print(f"  请求 URL: {url}")
                    
                    body_data = None
                    if body is not None:
                        if isinstance(body, dict):
                            body_data = json.dumps(body).encode('utf-8')
                        elif isinstance(body, str):
                            body_data = body.encode('utf-8')
                    
                    request_headers = {}
                    if body_data:
                        request_headers["Content-Type"] = "application/json"
                    if headers:
                        request_headers.update(headers)
                    
                    request = urllib.request.Request(url, data=body_data, headers=request_headers, method=method)
                
                # 发送请求
                with urllib.request.urlopen(request, timeout=10) as response:
                    result = response.read().decode('utf-8')
                    print(f"  响应状态: {response.status}")
                    print(f"  响应内容: {result[:200]}...")
                    
            except Exception as e:
                print(f"  执行失败: {str(e)}")
                import traceback
                traceback.print_exc()
    
    if not executed and not manual_mode:
        print("当前时间没有需要执行的任务")
        
except FileNotFoundError:
    print(f"错误: 配置文件 {config_file} 不存在")
    sys.exit(1)
except json.JSONDecodeError as e:
    print(f"错误: 配置文件 JSON 格式错误: {str(e)}")
    sys.exit(1)
except Exception as e:
    print(f"错误: {str(e)}")
    sys.exit(1)
PYTHON_SCRIPT

