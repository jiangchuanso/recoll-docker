FROM ubuntu:22.04
LABEL maintainer="joatd"

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies and Recoll from Ubuntu repository
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        antiword \
        apache2 \
        aspell \
        aspell-en \
        file \
        git \
        libxml2 \
        net-tools \
        poppler-utils \
        python3 \
        python3-pip \
        python3-libxml2 \
        python3-lxml \
        python3-chm \
        unrtf \
        unzip \
        vim \
        recoll \
        python3-recoll && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip3 install --no-cache-dir waitress jieba

# Copy application scripts
COPY recollstatus.py /usr/bin/recollstatus
RUN chmod a+x /usr/bin/recollstatus

# Create Recoll configuration directory
# 注意：/root/.recoll 会被声明为 VOLUME，若用户以 -v 挂载外部目录会遮蔽镜像内文件。
# 因此把默认配置放到非卷路径 /opt/recoll.conf，由 startup.sh 在运行时按需写入卷内。
RUN mkdir -p /root/.recoll
COPY recoll.conf /opt/recoll.conf

# Clone recollwebui
RUN cd / && git clone --depth 1 https://framagit.org/medoc92/recollwebui.git 

# Create docs directory and symlink for Apache
RUN mkdir -p /docs /var/www/html && \
    ln -sf /docs /var/www/html/docs

# Copy and prepare startup script
COPY startup.sh /startup.sh
RUN chmod a+x /startup.sh

# Define volumes
VOLUME ["/docs", "/root/.recoll"]

# Expose ports
EXPOSE 80 8080

# Default command
CMD ["/startup.sh"]
