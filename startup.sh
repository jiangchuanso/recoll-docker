#!/bin/sh
set -e

# 启动 Apache2 服务
echo "Starting Apache2..."
apache2ctl -D FOREGROUND &
APACHE_PID=$!

# 等待 Apache2 完全启动（轮询检测，避免慢启动被误判为失败）
apache_ready=0
for _ in $(seq 1 10); do
    if kill -0 "$APACHE_PID" 2>/dev/null; then
        apache_ready=1
        break
    fi
    sleep 1
done

if [ "$apache_ready" -ne 1 ]; then
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

# 确保 Recoll 配置文件存在
# 当 /root/.recoll 被外部卷（-v）挂载时，镜像内拷贝的配置会被隐藏，
# 因此在索引前若缺失则写入默认配置，保证 Recoll 使用正确的 topdirs / 分词等设置。
if [ ! -f /root/.recoll/recoll.conf ]; then
    echo "Provisioning default recoll.conf..."
    mkdir -p /root/.recoll
    cp /opt/recoll.conf /root/.recoll/recoll.conf
fi

# 初始化 Recoll 索引（仅在尚未成功建立过索引时）
# 使用完成哨兵文件判断，避免首次索引被中断（flintlock 已生成但库不完整）
# 后，因误判而永远不再重建索引。
INDEX_DONE="/root/.recoll/.index_ok"
if [ ! -f "$INDEX_DONE" ]; then
    echo "Initializing Recoll index..."
    if recollindex -c /root/.recoll; then
        touch "$INDEX_DONE"
    else
        echo "WARNING: Initial Recoll index failed; will retry on next start."
    fi
fi

# 启动 Recoll 实时索引监控（后台）
echo "Starting Recoll index monitor..."
recollindex -m -c /root/.recoll &
RECOLLINDEX_PID=$!

# 启动 Recoll Web UI（前台运行，作为容器主进程）
echo "Starting Recoll Web UI..."
exec /usr/bin/python3 /recollwebui/webui-standalone.py -a 0.0.0.0 -p 8080
