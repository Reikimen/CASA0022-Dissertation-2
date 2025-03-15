FROM ollama/ollama:latest

# 设置工作目录
WORKDIR /app

# 设置时区为非交互式模式
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# 安装依赖项
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    build-essential \
    git \
    wget \
    ffmpeg \
    libsndfile1 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 创建符号链接确保python命令可用
RUN ln -sf /usr/bin/python3 /usr/bin/python

# 安装Python依赖
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# 安装Jupyter支持
RUN pip3 install jupyter jupyterlab ipywidgets

# 启动ollama服务
RUN mkdir -p /etc/ollama

# 端口配置
EXPOSE 11434 8000/udp 8080 8888 1883

# 设置卷挂载点
VOLUME ["/app/models", "/app/audio", "/app/config", "/root/.ollama", "/app/notebooks"]

# 创建必要的目录
RUN mkdir -p /app/models/whisper /app/audio/input /app/audio/output /app/logs /app/notebooks

# 启动脚本
COPY scripts/start.sh /app/
RUN chmod +x /app/start.sh

# 设置环境变量
ENV OLLAMA_HOST=0.0.0.0:11434
ENV WHISPER_MODEL=small
ENV EDGE_TTS_VOICE="zh-CN-XiaoxiaoNeural"
ENV JUPYTER_ENABLE=true

# 覆盖原始ENTRYPOINT
ENTRYPOINT []
CMD ["/app/start.sh"]