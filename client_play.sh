#!/bin/bash

# 客户端播放脚本
# 支持多种解码器和播放方式

set -e

# 默认参数
UDP_PORT=5000
TCP_PORT=8080
SERVER_IP="192.168.6.60"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_usage() {
    echo -e "${BLUE}客户端播放脚本${NC}"
    echo ""
    echo -e "${BLUE}使用方法:${NC}"
    echo "  $0 [选项] [服务器IP]"
    echo ""
    echo -e "${BLUE}选项:${NC}"
    echo "  udp          - UDP RTP 流播放 (默认)"
    echo "  tcp          - TCP RTP 流播放"
    echo "  vlc-udp      - 使用 VLC 播放 UDP 流"
    echo "  vlc-tcp      - 使用 VLC 播放 TCP 流"
    echo "  ffplay-udp   - 使用 FFplay 播放 UDP 流"
    echo "  ffplay-tcp   - 使用 FFplay 播放 TCP 流"
    echo "  mpv-udp      - 使用 MPV 播放 UDP 流"
    echo "  mpv-tcp      - 使用 MPV 播放 TCP 流"
    echo "  help         - 显示此帮助信息"
    echo ""
    echo -e "${BLUE}示例:${NC}"
    echo "  $0 udp                    # UDP 流播放"
    echo "  $0 tcp 192.168.1.100     # TCP 流播放，指定服务器IP"
    echo "  $0 vlc-udp               # VLC UDP 播放"
    echo "  $0 ffplay-tcp 10.0.0.1   # FFplay TCP 播放"
}

check_decoder() {
    local decoder=$1
    if gst-inspect-1.0 "$decoder" &> /dev/null; then
        echo "$decoder"
        return 0
    else
        return 1
    fi
}

find_best_decoder() {
    # 按优先级检查可用的解码器
    local decoders=("openh264dec" "nvh264dec" "vulkanh264dec")
    
    for decoder in "${decoders[@]}"; do
        if check_decoder "$decoder"; then
            echo "$decoder"
            return 0
        fi
    done
    
    echo -e "${RED}错误: 没有找到可用的 H.264 解码器${NC}"
    echo -e "${YELLOW}请安装以下包之一:${NC}"
    echo "  sudo pacman -S gst-plugins-bad  # OpenH264"
    echo "  sudo pacman -S gst-plugins-nvcodec  # NVIDIA"
    echo "  sudo pacman -S gst-plugins-vulkan  # Vulkan"
    return 1
}

play_udp_gstreamer() {
    local server_ip=${1:-localhost}
    local decoder=$(find_best_decoder)
    
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo -e "${GREEN}使用 GStreamer 播放 UDP 流...${NC}"
    echo -e "${BLUE}服务器: ${server_ip}:${UDP_PORT}${NC}"
    echo -e "${BLUE}解码器: ${decoder}${NC}"
    echo ""
    
    gst-launch-1.0 udpsrc port=${UDP_PORT} ! \
        application/x-rtp,encoding-name=H264,payload=96 ! \
        rtph264depay ! \
        h264parse ! \
        ${decoder} ! \
        autovideosink
}

play_tcp_gstreamer() {
    local server_ip=${1:-localhost}
    local decoder=$(find_best_decoder)
    
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    echo -e "${GREEN}使用 GStreamer 播放 TCP 流...${NC}"
    echo -e "${BLUE}服务器: ${server_ip}:${TCP_PORT}${NC}"
    echo -e "${BLUE}解码器: ${decoder}${NC}"
    echo ""
    
    gst-launch-1.0 tcpclientsrc host=${server_ip} port=${TCP_PORT} ! \
        application/x-rtp,encoding-name=H264,payload=96 ! \
        rtph264depay ! \
        h264parse ! \
        ${decoder} ! \
        autovideosink
}

play_vlc_udp() {
    local server_ip=${1:-localhost}
    echo -e "${GREEN}使用 VLC 播放 UDP 流...${NC}"
    echo -e "${BLUE}服务器: ${server_ip}:${UDP_PORT}${NC}"
    echo ""
    
    vlc rtp://${server_ip}:${UDP_PORT}
}

play_vlc_tcp() {
    local server_ip=${1:-localhost}
    echo -e "${GREEN}使用 VLC 播放 TCP 流...${NC}"
    echo -e "${BLUE}服务器: ${server_ip}:${TCP_PORT}${NC}"
    echo ""
    
    vlc tcp://${server_ip}:${TCP_PORT}
}

play_ffplay_udp() {
    local server_ip=${1:-localhost}
    echo -e "${GREEN}使用 FFplay 播放 UDP 流...${NC}"
    echo -e "${BLUE}服务器: ${server_ip}:${UDP_PORT}${NC}"
    echo ""
    
    ffplay udp://${server_ip}:${UDP_PORT}
}

play_ffplay_tcp() {
    local server_ip=${1:-localhost}
    echo -e "${GREEN}使用 FFplay 播放 TCP 流...${NC}"
    echo -e "${BLUE}服务器: ${server_ip}:${TCP_PORT}${NC}"
    echo ""
    
    ffplay tcp://${server_ip}:${TCP_PORT}
}

play_mpv_udp() {
    local server_ip=${1:-localhost}
    echo -e "${GREEN}使用 MPV 播放 UDP 流...${NC}"
    echo -e "${BLUE}服务器: ${server_ip}:${UDP_PORT}${NC}"
    echo ""
    
    mpv udp://${server_ip}:${UDP_PORT}
}

play_mpv_tcp() {
    local server_ip=${1:-localhost}
    echo -e "${GREEN}使用 MPV 播放 TCP 流...${NC}"
    echo -e "${BLUE}服务器: ${server_ip}:${TCP_PORT}${NC}"
    echo ""
    
    mpv tcp://${server_ip}:${TCP_PORT}
}

# 主程序
case "${1:-udp}" in
    "udp")
        play_udp_gstreamer "$2"
        ;;
    "tcp")
        play_tcp_gstreamer "$2"
        ;;
    "vlc-udp")
        play_vlc_udp "$2"
        ;;
    "vlc-tcp")
        play_vlc_tcp "$2"
        ;;
    "ffplay-udp")
        play_ffplay_udp "$2"
        ;;
    "ffplay-tcp")
        play_ffplay_tcp "$2"
        ;;
    "mpv-udp")
        play_mpv_udp "$2"
        ;;
    "mpv-tcp")
        play_mpv_tcp "$2"
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
