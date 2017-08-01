

build:
	docker build fluentd/docker-image/ -t humio/kubernetes2humio

push: build
	docker push humio/kubernetes2humio

.PHONY: build push