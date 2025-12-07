FROM ubuntu:22.04
LABEL maintainer="joatd"

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies and Recoll from Ubuntu repository
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        antiword \
        apache2 \
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
RUN pip3 install --no-cache-dir waitress

# Copy application scripts
COPY recollstatus.py /usr/bin/recollstatus
RUN chmod a+x /usr/bin/recollstatus

# Create Recoll configuration directory
RUN mkdir -p /root/.recoll
COPY recoll.conf /root/.recoll/recoll.conf

# Clone recollwebui
RUN cd / && git clone https://framagit.org/medoc92/recollwebui.git

# Copy custom template
COPY result.tpl /recollwebui/views/result.tpl
RUN chown root: /recollwebui/views/result.tpl && \
    chmod 644 /recollwebui/views/result.tpl

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
