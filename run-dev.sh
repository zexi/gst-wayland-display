#!/bin/bash

docker run -it --net=host \
	-v $(pwd):/gst-wayland-display \
	-e NVIDIA_DRIVER_CAPABILITIES=all \
    -e NVIDIA_VISIBLE_DEVICES=all \
    --gpus=all \
    --device /dev/dri/ \
    --device /dev/uinput \
    --device /dev/uhid \
    -v /dev:/dev:rw \
    -v /run/udev:/run/udev:rw \
	registry.cn-beijing.aliyuncs.com/zexi/gstreamer:build-env.1 bash
