#!/bin/bash

docker run -it --net=host \
	-v $(pwd):/gst-wayland-display \
	--gpus=all \
	registry.cn-beijing.aliyuncs.com/zexi/gstreamer:build-env.1 bash
