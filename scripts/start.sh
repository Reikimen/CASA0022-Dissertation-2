#!/bin/bash
set -e

echo "===== 启动AI语音助手服务 ====="

# 启动Ollama服务
echo "启动Ollama服务..."
/bin/ollama serve &
OLLAMA_PID=$!

# 等待Ollama服务启动
echo "等待Ollama服务启动..."
sleep 5

# 检查模型是否存在，不存在则拉取
OLLAMA_MODEL=${OLLAMA_MODEL:-"llama3"}
echo "检查Ollama模型: $OLLAMA_MODEL"
if ! /bin/ollama list | grep -q "$OLLAMA_MODEL"; then
    echo "模型不存在，正在拉取 $OLLAMA_MODEL..."
    /bin/ollama pull $OLLAMA_MODEL
fi

# 检查Whisper模型文件是否存在
echo "设置Whisper模型: $WHISPER_MODEL"
# Whisper会在首次使用时自动下载模型

# 检查TTS模型
if [ ! -f "$TTS_MODEL_PATH" ]; then
    echo "警告: TTS模型不存在，请确保已正确配置模型路径"
    echo "您可能需要手动下载模型文件到./models/tts/目录"
fi

# 创建日志目录
mkdir -p /app/logs

# 启动Jupyter Lab（如果启用）
if [ "$JUPYTER_ENABLE" = "true" ]; then
    echo "启动Jupyter Lab服务..."
    JUPYTER_TOKEN=${JUPYTER_TOKEN:-"aivoiceassistant"}
    cd /app/notebooks
    jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token="$JUPYTER_TOKEN" &
    JUPYTER_PID=$!
    echo "Jupyter Lab已启动，访问地址: http://localhost:8888/lab?token=$JUPYTER_TOKEN"
fi

# 启动主服务
echo "启动语音助手主服务..."
cd /app
python3 -m scripts.main &
MAIN_PID=$!

# 捕获信号
trap 'kill $OLLAMA_PID $MAIN_PID $JUPYTER_PID; exit' SIGINT SIGTERM

# 等待子进程
wait $MAIN_PID
wait $OLLAMA_PID
if [ "$JUPYTER_ENABLE" = "true" ]; then
    wait $JUPYTER_PID
fi