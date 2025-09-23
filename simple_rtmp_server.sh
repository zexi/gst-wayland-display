#!/bin/bash

# 简单的 RTMP 服务器启动脚本
# 使用 GStreamer 内置的 HTTP 流服务器

echo "启动简单的 RTMP 服务器..."

# 检查是否有可用的 RTMP 服务器
if command -v nginx &> /dev/null; then
    echo "使用 nginx RTMP 服务器..."
    nginx -c "$(pwd)/nginx-rtmp.conf" &
    echo "RTMP 服务器已启动，PID: $!"
    echo "RTMP URL: rtmp://localhost:1935/live/stream"
elif command -v docker &> /dev/null; then
    echo "使用 Docker RTMP 服务器..."
    docker run -d -p 1935:1935 --name rtmp-server tiangolo/nginx-rtmp
    echo "Docker RTMP 服务器已启动"
    echo "RTMP URL: rtmp://localhost:1935/live/stream"
else
    echo "没有找到 nginx 或 Docker，使用 GStreamer HTTP 流服务器..."
    echo "启动 HTTP 流服务器在端口 8080..."
    
    # 使用 GStreamer 的 HTTP 流服务器
    GST_PLUGIN_PATH=/usr/local/lib/gstreamer-1.0 gst-launch-1.0 \
        waylanddisplaysrc ! \
        "video/x-raw,width=1280,height=720,format=RGBx,framerate=30/1" ! \
        videoconvert ! \
        openh264enc bitrate=2000 ! \
        h264parse ! \
        mp4mux ! \
        tcpserversink host=0.0.0.0 port=8080 &
    
    echo "HTTP 流服务器已启动，PID: $!"
    echo "HTTP URL: http://localhost:8080"
    echo "客户端播放: vlc http://localhost:8080"
fi

echo ""
echo "现在可以启动流媒体客户端来播放内容"

