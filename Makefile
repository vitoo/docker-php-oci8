.PHONY: help build test clean build-all test-all

# Default values
PHP_VERSION ?= 8.5
ORACLE_VERSION ?= 21
IMAGE_NAME = php-oci8
TAG = $(PHP_VERSION)-oracle$(ORACLE_VERSION)

help:
	@echo "PHP OCI8 Docker Image - Available targets:"
	@echo ""
	@echo "  make build              - Build image with PHP $(PHP_VERSION) and Oracle $(ORACLE_VERSION)"
	@echo "  make test               - Run tests on the built image"
	@echo "  make run                - Run interactive PHP shell"
	@echo "  make bash               - Run bash shell in container"
	@echo "  make modules            - List PHP modules"
	@echo "  make build-all          - Build all supported versions"
	@echo "  make test-all           - Test all supported versions"
	@echo "  make clean              - Remove all built images"
	@echo ""
	@echo "Quick build shortcuts:"
	@echo "  make php85, php84, php83, php82, php81, php80, php74"
	@echo ""
	@echo "Build with custom versions:"
	@echo "  make build PHP_VERSION=8.4 ORACLE_VERSION=21"
	@echo ""

build:
	@echo "Building $(IMAGE_NAME):$(TAG)..."
	docker build \
		--build-arg PHP_VERSION=$(PHP_VERSION) \
		--build-arg ORACLE_VERSION=$(ORACLE_VERSION) \
		-t $(IMAGE_NAME):$(TAG) \
		-t $(IMAGE_NAME):latest \
		.

test:
	@echo "Running tests on $(IMAGE_NAME):$(TAG)..."
	docker run --rm $(IMAGE_NAME):$(TAG) php /usr/local/bin/test-oci8.php

run:
	@echo "Starting interactive PHP shell..."
	docker run -it --rm $(IMAGE_NAME):$(TAG) php -a

bash:
	@echo "Starting bash shell..."
	docker run -it --rm $(IMAGE_NAME):$(TAG) bash

modules:
	@echo "Listing PHP modules..."
	docker run --rm $(IMAGE_NAME):$(TAG) php -m

clean:
	@echo "Removing all php-oci8 images..."
	docker images | grep php-oci8 | awk '{print $$3}' | xargs -r docker rmi -f

# Specific version targets
php84:
	$(MAKE) build PHP_VERSION=8.4 ORACLE_VERSION=21

php83:
	$(MAKE) build PHP_VERSION=8.3 ORACLE_VERSION=21

php82:
	$(MAKE) build PHP_VERSION=8.2 ORACLE_VERSION=21

php81:
	$(MAKE) build PHP_VERSION=8.1 ORACLE_VERSION=21

php80:
	$(MAKE) build PHP_VERSION=8.0 ORACLE_VERSION=21

php74:
	$(MAKE) build PHP_VERSION=7.4 ORACLE_VERSION=21
