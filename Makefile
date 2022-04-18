SHELL = /usr/bin/env bash

VERSION ?= 0.1.0
VERSION := $(VERSION)
VCS_REF ?= $(shell git rev-parse HEAD)
VCS_REF := $(VCS_REF)
BUILD_DATE ?= $(shell date --rfc-3339=date)
BUILD_DATE := $(BUILD_DATE)
BUILD_DIR ?= build
BUILD_DIR := $(BUILD_DIR)
CI_BIND_MOUNT ?= $(shell pwd)
CI_BIND_MOUNT := $(CI_BIND_MOUNT)
DOCKER_BASE_NAME ?= docker_latex
DOCKER_BASE_NAME := $(DOCKER_BASE_NAME)
DOCKER_IMAGE_NAME := rudenkornk/$(DOCKER_BASE_NAME)
DOCKER_IMAGE_TAG := $(DOCKER_IMAGE_NAME):$(VERSION)
DOCKER_IMAGE := $(BUILD_DIR)/$(DOCKER_BASE_NAME)_image_$(VERSION)
DOCKER_CONTAINER_NAME ?= $(DOCKER_BASE_NAME)_container
DOCKER_CONTAINER_NAME := $(DOCKER_CONTAINER_NAME)
DOCKER_CONTAINER := $(BUILD_DIR)/$(DOCKER_CONTAINER_NAME)_$(VERSION)

DOCKER_DEPS :=
DOCKER_DEPS += Dockerfile
DOCKER_DEPS += install_texlive.sh
DOCKER_DEPS += install_drawio.sh
DOCKER_DEPS += install_support.sh
DOCKER_DEPS += config_user.sh
DOCKER_DEPS += entrypoint.sh
DOCKER_DEPS += entrypoint_usermod.sh

.PHONY: docker_image
docker_image: $(DOCKER_IMAGE)

DOCKER_IMAGE_ID = $(shell docker images --quiet $(DOCKER_IMAGE_TAG))
DOCKER_IMAGE_CREATE_STATUS = $(shell [[ -z "$(DOCKER_IMAGE_ID)" ]] && echo "$(DOCKER_IMAGE)_not_created")
.PHONY: $(DOCKER_IMAGE)_not_created
$(DOCKER_IMAGE): $(DOCKER_DEPS) $(DOCKER_IMAGE_CREATE_STATUS)
	docker build \
		--build-arg IMAGE_NAME="$(DOCKER_IMAGE_NAME)" \
		--build-arg VERSION="$(VERSION)" \
		--build-arg VCS_REF="$(VCS_REF)" \
		--build-arg BUILD_DATE="$(BUILD_DATE)" \
		--tag $(DOCKER_IMAGE_TAG) .
	mkdir --parents $(BUILD_DIR) && touch $@

.PHONY: docker_container
docker_container: $(DOCKER_CONTAINER)

DOCKER_CONTAINER_ID = $(shell docker container ls --quiet --all --filter name=^/$(DOCKER_CONTAINER_NAME)$)
DOCKER_CONTAINER_CREATE_STATUS = $(shell [[ -z "$(DOCKER_CONTAINER_ID)" ]] && echo "$(DOCKER_CONTAINER)_not_created")
.PHONY: $(DOCKER_CONTAINER)_not_created
$(DOCKER_CONTAINER): $(DOCKER_IMAGE) $(DOCKER_CONTAINER_CREATE_STATUS)
ifneq ($(DOCKER_CONTAINER_ID),)
	docker container rename $(DOCKER_CONTAINER_NAME) $(DOCKER_CONTAINER_NAME)_$(DOCKER_CONTAINER_ID)
endif
	docker run --interactive --tty --detach \
		--env CI_UID="$$(id --user)" --env CI_GID="$$(id --group)" \
		--name $(DOCKER_CONTAINER_NAME) \
		--mount type=bind,source="$(CI_BIND_MOUNT)",target=/home/repo \
		$(DOCKER_IMAGE_TAG)
	mkdir --parents $(BUILD_DIR) && touch $@

