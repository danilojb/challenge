IMAGE_PREFIX ?=
SERVICES := analytics-service auth-service evaluation-service flag-service targeting-service

.PHONY: build-all build clean

build-all:
	@for s in $(SERVICES); do \
		printf "\n==> Building $$s\n"; \
		docker build -t $(IMAGE_PREFIX)$$s:local ./$$s; \
	done

build:
	@$(MAKE) build-all

clean:
	@echo "No artifacts to clean in this Makefile. Use 'docker rmi' to remove images."
