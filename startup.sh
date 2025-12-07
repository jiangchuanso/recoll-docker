#!/bin/bash
set -e

# 启动 Apache2 服务（后台运行）
/usr/sbin/apache2ctl start

# 启动 RecollWebUI（作为前台进程，保持容器运行）
exec /usr/bin/python3 /recollwebui/webui-standalone.py -a 0.0.0.0
