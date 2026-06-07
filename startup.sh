#!/bin/sh
set -e

# 启动 Apache2 服务
echo "Starting Apache2..."
apache2ctl -D FOREGROUND &
APACHE_PID=$!

# 等待 Apache2 完全启动
sleep 2

# 验证 Apache 进程是否成功运行
if ! kill -0 $APACHE_PID 2>/dev/null; then
    echo "ERROR: Apache2 failed to start!"
    exit 1
fi
echo "Apache2 started successfully (PID: $APACHE_PID)"

# 后台监控 Apache 进程状态
(
    while kill -0 $APACHE_PID 2>/dev/null; do
        sleep 5
    done
    echo "ERROR: Apache2 process died unexpectedly! Triggering container shutdown..."
    kill -TERM 1 2>/dev/null || true
) &
MONITOR_PID=$!

# 初始化 Recoll 索引（如果尚未建立）
if [ ! -f /root/.recoll/xapiandb/flintlock ]; then
    echo "Initializing Recoll index..."
    recollindex -c /root/.recoll
fi

# 启动 Recoll 实时索引监控（后台）
echo "Starting Recoll index monitor..."
recollindex -m -c /root/.recoll &
RECOLLINDEX_PID=$!

# 启动 Recoll Web UI（前台运行，作为容器主进程）
echo "Starting Recoll Web UI..."
exec /usr/bin/python3 /recollwebui/webui-standalone.py -a 0.0.0.0 -p 8080
