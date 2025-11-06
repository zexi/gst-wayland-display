TAG := build-env.1

image:
	docker buildx build --platform linux/amd64 --push \
		-t registry.cn-beijing.aliyuncs.com/zexi/gstreamer:$(TAG) \
		-f ./Dockerfile .
