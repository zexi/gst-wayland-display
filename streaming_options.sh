#!/bin/bash

# GStreamer Wayland 显示流媒体选项脚本
# 使用方法: ./streaming_options.sh [选项]

set -e

# 默认参数
WIDTH=1280
HEIGHT=720
FPS=30
BITRATE=2000
HOST="0.0.0.0"
UDP_PORT=5000
TCP_PORT=8080
RTMP_URL="rtmp://localhost:1935/live/stream"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_usage() {
    echo -e "${BLUE}使用方法:${NC}"
    echo "  $0 [选项]"
    echo ""
    echo -e "${BLUE}选项:${NC}"
    echo "  udp          - UDP RTP 流输出 (默认)"
    echo "  tcp          - TCP HTTP 流输出"
    echo "  rtmp         - RTMP 流输出"
    echo "  rtmp-server  - 启动 RTMP 服务器"
    echo "  file         - 保存到文件"
    echo "  help         - 显示此帮助信息"
    echo ""
    echo -e "${BLUE}参数:${NC}"
    echo "  WIDTH=$WIDTH HEIGHT=$HEIGHT FPS=$FPS BITRATE=$BITRATE $0 udp"
    echo ""
    echo -e "${BLUE}示例:${NC}"
    echo "  $0 udp                    # UDP 流输出到端口 5000"
    echo "  $0 tcp                    # TCP 流输出到端口 8080"
    echo "  $0 rtmp-server            # 启动 RTMP 服务器"
    echo "  $0 rtmp                   # RTMP 流输出"
    echo "  $0 file                   # 保存到文件"
    echo "  WIDTH=1920 HEIGHT=1080 $0 udp  # 自定义分辨率"
}

stop_existing() {
    echo -e "${YELLOW}停止现有的 GStreamer 进程...${NC}"
    pkill -f "gst-launch-1.0 waylanddisplaysrc" || true
    sleep 1
}

start_udp_stream() {
    echo -e "${GREEN}启动 UDP RTP 流输出...${NC}"
    echo -e "${BLUE}分辨率: ${WIDTH}x${HEIGHT}@${FPS}fps${NC}"
    echo -e "${BLUE}UDP 端口: ${UDP_PORT}${NC}"
    echo -e "${BLUE}比特率: ${BITRATE}kbps${NC}"
    echo ""
    echo -e "${YELLOW}客户端播放命令:${NC}"
    echo "gst-launch-1.0 udpsrc port=${UDP_PORT} ! application/x-rtp,encoding-name=H264,payload=96 ! rtph264depay ! h264parse ! openh264dec ! autovideosink"
    echo ""
    echo -e "${YELLOW}VLC 播放:${NC}"
    echo "vlc rtp://@:${UDP_PORT}"
    echo ""
    
    GST_PLUGIN_PATH=/usr/local/lib/gstreamer-1.0 gst-launch-1.0 \
        waylanddisplaysrc ! \
        "video/x-raw,width=${WIDTH},height=${HEIGHT},format=RGBx,framerate=${FPS}/1" ! \
        videoconvert ! \
        openh264enc bitrate=${BITRATE} ! \
        rtph264pay ! \
        queue ! \
        udpsink host=${HOST} port=${UDP_PORT} &
    
    echo -e "${GREEN}UDP 流已启动，PID: $!${NC}"
}

YOUR_SERVER_IP=192.168.6.60

start_tcp_stream() {
    echo -e "${GREEN}启动 TCP HTTP 流输出...${NC}"
    echo -e "${BLUE}分辨率: ${WIDTH}x${HEIGHT}@${FPS}fps${NC}"
    echo -e "${BLUE}TCP 端口: ${TCP_PORT}${NC}"
    echo -e "${BLUE}比特率: ${BITRATE}kbps${NC}"
    echo ""
    echo -e "${YELLOW}客户端播放命令:${NC}"
    echo "gst-launch-1.0 tcpclientsrc host=${YOUR_SERVER_IP} port=${TCP_PORT} ! application/x-rtp,encoding-name=H264,payload=96 ! rtph264depay ! h264parse ! openh264dec ! autovideosink"
    echo ""
    echo -e "${YELLOW}VLC 播放:${NC}"
    echo "vlc tcp://${YOUR_SERVER_IP}:${TCP_PORT}"
    echo ""
    
    GST_PLUGIN_PATH=/usr/local/lib/gstreamer-1.0 gst-launch-1.0 \
        waylanddisplaysrc ! \
        "video/x-raw,width=${WIDTH},height=${HEIGHT},format=RGBx,framerate=${FPS}/1" ! \
        videoconvert ! \
        openh264enc bitrate=${BITRATE} ! \
        h264parse ! \
        rtph264pay ! \
        queue ! \
        tcpserversink host=${HOST} port=${TCP_PORT} protocol=none &
    
    echo -e "${GREEN}TCP 流已启动，PID: $!${NC}"
}

start_rtmp_stream() {
    echo -e "${GREEN}启动 RTMP 流输出...${NC}"
    echo -e "${BLUE}分辨率: ${WIDTH}x${HEIGHT}@${FPS}fps${NC}"
    echo -e "${BLUE}RTMP URL: ${RTMP_URL}${NC}"
    echo -e "${BLUE}比特率: ${BITRATE}kbps${NC}"
    echo ""
    echo -e "${YELLOW}注意: 需要 RTMP 服务器 (如 nginx-rtmp-module)${NC}"
    echo -e "${YELLOW}客户端播放:${NC}"
    echo "ffplay ${RTMP_URL}"
    echo "vlc ${RTMP_URL}"
    echo ""
    echo -e "${YELLOW}启动 RTMP 服务器:${NC}"
    echo "nginx -c $(pwd)/nginx-rtmp.conf"
    echo ""
    
    GST_PLUGIN_PATH=/usr/local/lib/gstreamer-1.0 gst-launch-1.0 \
        waylanddisplaysrc ! \
        "video/x-raw,width=${WIDTH},height=${HEIGHT},format=RGBx,framerate=${FPS}/1" ! \
        videoconvert ! \
        openh264enc bitrate=${BITRATE} ! \
        h264parse ! \
        flvmux ! \
        queue ! \
        rtmpsink location="${RTMP_URL}" &
    
    echo -e "${GREEN}RTMP 流已启动，PID: $!${NC}"
}

start_rtmp_server() {
    echo -e "${GREEN}启动 RTMP 服务器...${NC}"
    echo -e "${BLUE}端口: 1935${NC}"
    echo -e "${BLUE}配置文件: $(pwd)/nginx-rtmp.conf${NC}"
    echo ""
    
    # 检查 nginx 是否安装
    if ! command -v nginx &> /dev/null; then
        echo -e "${RED}错误: nginx 未安装${NC}"
        echo -e "${YELLOW}请安装 nginx 和 nginx-rtmp-module:${NC}"
        echo "sudo pacman -S nginx-rtmp-module"
        echo "或者使用 Docker:"
        echo "docker run -d -p 1935:1935 tiangolo/nginx-rtmp"
        return 1
    fi
    
    # 启动 nginx RTMP 服务器
    nginx -c "$(pwd)/nginx-rtmp.conf" &
    echo -e "${GREEN}RTMP 服务器已启动，PID: $!${NC}"
    echo ""
    echo -e "${YELLOW}现在可以启动 RTMP 流:${NC}"
    echo "./streaming_options.sh rtmp"
}

start_file_output() {
    local filename="wayland_display_$(date +%Y%m%d_%H%M%S).mp4"
    echo -e "${GREEN}启动文件录制...${NC}"
    echo -e "${BLUE}分辨率: ${WIDTH}x${HEIGHT}@${FPS}fps${NC}"
    echo -e "${BLUE}文件名: ${filename}${NC}"
    echo -e "${BLUE}比特率: ${BITRATE}kbps${NC}"
    echo ""
    echo -e "${YELLOW}按 Ctrl+C 停止录制${NC}"
    echo ""
    
    GST_PLUGIN_PATH=/usr/local/lib/gstreamer-1.0 gst-launch-1.0 \
        waylanddisplaysrc ! \
        "video/x-raw,width=${WIDTH},height=${HEIGHT},format=RGBx,framerate=${FPS}/1" ! \
        videoconvert ! \
        openh264enc bitrate=${BITRATE} ! \
        h264parse ! \
        mp4mux ! \
        filesink location="${filename}"
}

show_status() {
    echo -e "${BLUE}当前运行的 GStreamer 进程:${NC}"
    ps aux | grep "gst-launch-1.0 waylanddisplaysrc" | grep -v grep || echo "没有运行的进程"
    echo ""
    echo -e "${BLUE}网络连接状态:${NC}"
    netstat -tuln | grep -E ":(${UDP_PORT}|${TCP_PORT})" || echo "没有监听的端口"
}

# 主程序
case "${1:-udp}" in
    "udp")
        stop_existing
        start_udp_stream
        ;;
    "tcp")
        stop_existing
        start_tcp_stream
        ;;
    "rtmp")
        stop_existing
        start_rtmp_stream
        ;;
    "rtmp-server")
        start_rtmp_server
        ;;
    "file")
        stop_existing
        start_file_output
        ;;
    "status")
        show_status
        ;;
    "stop")
        stop_existing
        echo -e "${GREEN}已停止所有流媒体进程${NC}"
        ;;
    "help"|"-h"|"--help")
        print_usage
        ;;
    *)
        echo -e "${RED}未知选项: $1${NC}"
        print_usage
        exit 1
        ;;
esac
