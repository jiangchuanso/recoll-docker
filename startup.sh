#!/bin/sh
set -e

# 启动 Apache2 服务
echo "Starting Apache2..."
apache2ctl -D FOREGROUND &  # 后台运行但不使用 daemon 模式
APACHE_PID=$!

# 等待 Apache2 完全启动
sleep 2

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
