SHELL = /usr/bin/env bash

PROJECT_NAME := docker_latex
VCS_REF ?= $(shell git rev-parse HEAD)
VCS_REF := $(VCS_REF)
BUILD_DATE ?= $(shell date --rfc-3339=date)
BUILD_DATE := $(BUILD_DATE)
BUILD_DIR ?= build
BUILD_DIR := $(BUILD_DIR)
TESTS_DIR ?= tests
TESTS_DIR := $(TESTS_DIR)
CI_BIND_MOUNT ?= $(shell pwd)
CI_BIND_MOUNT := $(CI_BIND_MOUNT)
KEEP_CI_USER_SUDO ?= false
KEEP_CI_USER_SUDO := $(KEEP_CI_USER_SUDO)
DOCKER_IMAGE_VERSION ?= 1.0.1
DOCKER_IMAGE_VERSION := $(DOCKER_IMAGE_VERSION)
DOCKER_IMAGE_NAME := rudenkornk/$(PROJECT_NAME)
DOCKER_IMAGE_TAG := $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_VERSION)
DOCKER_IMAGE := $(BUILD_DIR)/$(PROJECT_NAME)_image_$(DOCKER_IMAGE_VERSION)
DOCKER_CACHE_FROM ?=
DOCKER_CACHE_FROM := $(DOCKER_CACHE_FROM)
DOCKER_CONTAINER_NAME ?= $(PROJECT_NAME)_container
DOCKER_CONTAINER_NAME := $(DOCKER_CONTAINER_NAME)
DOCKER_CONTAINER := $(BUILD_DIR)/$(DOCKER_CONTAINER_NAME)_$(DOCKER_IMAGE_VERSION)
DOCKER_TEST_CONTAINER_NAME := $(PROJECT_NAME)_test_container
DOCKER_TEST_CONTAINER := $(BUILD_DIR)/$(DOCKER_TEST_CONTAINER_NAME)_$(DOCKER_IMAGE_VERSION)

DOCKER_DEPS :=
DOCKER_DEPS += Dockerfile
DOCKER_DEPS += install_texlive.sh
DOCKER_DEPS += install_drawio.sh
DOCKER_DEPS += config_system.sh
DOCKER_DEPS += config_user.sh
DOCKER_DEPS += config_github_actions.sh

.PHONY: $(DOCKER_IMAGE_NAME)
$(DOCKER_IMAGE_NAME): $(DOCKER_IMAGE)

.PHONY: docker_image_name
docker_image_name:
	$(info $(DOCKER_IMAGE_NAME))

.PHONY: docker_image_tag
docker_image_tag:
	$(info $(DOCKER_IMAGE_TAG))

.PHONY: docker_image_version
docker_image_version:
	$(info $(DOCKER_IMAGE_VERSION))

DOCKER_IMAGE_ID = $(shell docker images --quiet $(DOCKER_IMAGE_TAG))
DOCKER_IMAGE_CREATE_STATUS = $(shell [[ -z "$(DOCKER_IMAGE_ID)" ]] && echo "$(DOCKER_IMAGE)_not_created")
DOCKER_CACHE_FROM_COMMAND = $(shell [[ ! -z "$(DOCKER_CACHE_FROM)" ]] && echo "--cache-from $(DOCKER_CACHE_FROM)")
.PHONY: $(DOCKER_IMAGE)_not_created
$(DOCKER_IMAGE): $(DOCKER_DEPS) $(DOCKER_IMAGE_CREATE_STATUS)
	docker build \
		$(DOCKER_CACHE_FROM_COMMAND) \
		--build-arg IMAGE_NAME="$(DOCKER_IMAGE_NAME)" \
		--build-arg VERSION="$(DOCKER_IMAGE_VERSION)" \
		--build-arg VCS_REF="$(VCS_REF)" \
		--build-arg BUILD_DATE="$(BUILD_DATE)" \
		--tag $(DOCKER_IMAGE_TAG) .
	mkdir --parents $(BUILD_DIR) && touch $@

.PHONY: $(DOCKER_CONTAINER_NAME)
$(DOCKER_CONTAINER_NAME): $(DOCKER_CONTAINER)

DOCKER_CONTAINER_ID = $(shell docker container ls --quiet --all --filter name=^/$(DOCKER_CONTAINER_NAME)$)
DOCKER_CONTAINER_STATE = $(shell docker container ls --format {{.State}} --all --filter name=^/$(DOCKER_CONTAINER_NAME)$)
DOCKER_CONTAINER_RUN_STATUS = $(shell [[ "$(DOCKER_CONTAINER_STATE)" != "running" ]] && echo "$(DOCKER_CONTAINER)_not_running")
.PHONY: $(DOCKER_CONTAINER)_not_running
$(DOCKER_CONTAINER): $(DOCKER_IMAGE) $(DOCKER_CONTAINER_RUN_STATUS)
ifneq ($(DOCKER_CONTAINER_ID),)
	docker container rename $(DOCKER_CONTAINER_NAME) $(DOCKER_CONTAINER_NAME)_$(DOCKER_CONTAINER_ID)
endif
	docker run --interactive --tty --detach \
		--user ci_user \
		--env KEEP_CI_USER_SUDO=$(KEEP_CI_USER_SUDO) \
		--env CI_UID="$$(id --user)" --env CI_GID="$$(id --group)" \
		--name $(DOCKER_CONTAINER_NAME) \
		--mount type=bind,source="$(CI_BIND_MOUNT)",target=/home/repo \
		$(DOCKER_IMAGE_TAG)
	sleep 1
	mkdir --parents $(BUILD_DIR) && touch $@

.PHONY: $(DOCKER_TEST_CONTAINER_NAME)
$(DOCKER_TEST_CONTAINER_NAME): $(DOCKER_TEST_CONTAINER)

DOCKER_TEST_CONTAINER_ID = $(shell docker container ls --quiet --all --filter name=^/$(DOCKER_TEST_CONTAINER_NAME)$)
DOCKER_TEST_CONTAINER_STATE = $(shell docker container ls --format {{.State}} --all --filter name=^/$(DOCKER_TEST_CONTAINER_NAME)$)
DOCKER_TEST_CONTAINER_RUN_STATUS = $(shell [[ "$(DOCKER_TEST_CONTAINER_STATE)" != "running" ]] && echo "$(DOCKER_TEST_CONTAINER)_not_running")
.PHONY: $(DOCKER_TEST_CONTAINER)_not_running
$(DOCKER_TEST_CONTAINER): $(DOCKER_IMAGE) $(DOCKER_TEST_CONTAINER_RUN_STATUS)
ifneq ($(DOCKER_TEST_CONTAINER_ID),)
	docker container rename $(DOCKER_TEST_CONTAINER_NAME) $(DOCKER_TEST_CONTAINER_NAME)_$(DOCKER_TEST_CONTAINER_ID)
endif
	docker run --interactive --tty --detach \
		--user ci_user \
		--env CI_UID="$$(id --user)" --env CI_GID="$$(id --group)" \
		--name $(DOCKER_TEST_CONTAINER_NAME) \
		--mount type=bind,source="$$(pwd)",target=/home/repo \
		$(DOCKER_IMAGE_TAG)
	sleep 1
	mkdir --parents $(BUILD_DIR) && touch $@

$(BUILD_DIR)/drawio_test.pdf: $(DOCKER_TEST_CONTAINER) $(TESTS_DIR)/drawio_test.xml
	docker exec \
		$(DOCKER_TEST_CONTAINER_NAME) \
		bash -c "source ~/.profile && \$$DRAWIO_CMD --export --output $@ $(TESTS_DIR)/drawio_test.xml --no-sandbox"
	pdfinfo $@

$(BUILD_DIR)/latex_test.pdf: $(DOCKER_TEST_CONTAINER) $(TESTS_DIR)/latex_test.tex
	docker exec \
		$(DOCKER_TEST_CONTAINER_NAME) \
		bash -c "source ~/.profile && latexmk -pdf --output-directory=$(BUILD_DIR) $(TESTS_DIR)/latex_test.tex"
	touch $@ # touch file in case latexmk decided not to recompile
	pdfinfo $@

$(BUILD_DIR)/latexindent_test: $(DOCKER_TEST_CONTAINER) $(TESTS_DIR)/latex_test.tex $(TESTS_DIR)/latexindent_test.tex
	docker exec \
		$(DOCKER_TEST_CONTAINER_NAME) \
		bash -c "source ~/.profile && latexindent $(TESTS_DIR)/latex_test.tex &> $(BUILD_DIR)/latexindent_test.tex"
	cmp $(BUILD_DIR)/latexindent_test.tex $(TESTS_DIR)/latexindent_test.tex
	touch $@

$(BUILD_DIR)/env_test: $(DOCKER_IMAGE) $(DOCKER_TEST_CONTAINER)
	docker exec \
		--user ci_user \
		$(DOCKER_TEST_CONTAINER_NAME) \
		bash -c "source ~/.profile && env" | grep --quiet DRAWIO_CMD
	docker run \
		--user ci_user \
		--name $(DOCKER_TEST_CONTAINER_NAME)_tmp_$$RANDOM \
		$(DOCKER_IMAGE_TAG) \
		env | grep --quiet DRAWIO_CMD
	
	docker exec \
		--user root \
		--env GITHUB_ACTIONS=true --env GITHUB_ENV=/root/env \
		$(DOCKER_TEST_CONTAINER_NAME) \
		bash -c "/home/ci_user/config_github_actions.sh &> /dev/null && cat /root/env" \
		| grep --quiet DRAWIO_CMD
	docker run \
		--user root \
		--name $(DOCKER_TEST_CONTAINER_NAME)_tmp_$$RANDOM \
		--env GITHUB_ACTIONS=true --env GITHUB_ENV=/root/env \
		$(DOCKER_IMAGE_TAG) \
		"/home/ci_user/config_github_actions.sh &> /dev/null && cat /root/env" \
		| grep --quiet DRAWIO_CMD
	
	mkdir --parents $(BUILD_DIR) && touch $@

.PHONY: check
check: \
	$(BUILD_DIR)/drawio_test.pdf \
	$(BUILD_DIR)/latex_test.pdf \
	$(BUILD_DIR)/latexindent_test \
	$(BUILD_DIR)/env_test \


.PHONY: clean
clean:
	rm --force $(BUILD_DIR)/*.aux
	rm --force $(BUILD_DIR)/*.bbl
	rm --force $(BUILD_DIR)/*.fdb_latexmk
	rm --force $(BUILD_DIR)/*.fls
	rm --force $(BUILD_DIR)/*.log
	docker container ls --quiet --filter name=$(DOCKER_TEST_CONTAINER_NAME)_ | \
		ifne xargs docker stop
	docker container ls --quiet --filter name=$(DOCKER_TEST_CONTAINER_NAME)_ --all | \
		ifne xargs docker rm

