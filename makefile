SHELL = /usr/bin/env bash

PROJECT_NAME := docker_latex
BUILD_DIR ?= build
TESTS_DIR := tests
VCS_REF != git rev-parse HEAD
BUILD_DATE != date --rfc-3339=date
KEEP_CI_USER_SUDO ?= false
DOCKER_IMAGE_VERSION := 1.1.0
DOCKER_IMAGE_NAME := rudenkornk/$(PROJECT_NAME)
DOCKER_IMAGE_TAG := $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_VERSION)
DOCKER_CACHE_FROM ?=
DOCKER_CONTAINER_NAME := $(PROJECT_NAME)_container

DOCKER_DEPS :=
DOCKER_DEPS += Dockerfile
DOCKER_DEPS += install_texlive.sh
DOCKER_DEPS += install_drawio.sh
DOCKER_DEPS += config_system.sh
DOCKER_DEPS += config_user.sh
DOCKER_DEPS += config_github_actions.sh

.PHONY: image
image: $(BUILD_DIR)/image

.PHONY: container
container: $(BUILD_DIR)/container

.PHONY: docker_image_name
docker_image_name:
	$(info $(DOCKER_IMAGE_NAME))

.PHONY: docker_image_tag
docker_image_tag:
	$(info $(DOCKER_IMAGE_TAG))

.PHONY: docker_image_version
docker_image_version:
	$(info $(DOCKER_IMAGE_VERSION))

IF_DOCKERD_UP := command -v docker &> /dev/null && docker image ls &> /dev/null

DOCKER_IMAGE_ID != $(IF_DOCKERD_UP) && docker images --quiet $(DOCKER_IMAGE_TAG)
DOCKER_IMAGE_CREATE_STATUS != [[ -z "$(DOCKER_IMAGE_ID)" ]] && echo "image_not_created"
DOCKER_CACHE_FROM_OPTION != [[ ! -z "$(DOCKER_CACHE_FROM)" ]] && echo "--cache-from $(DOCKER_CACHE_FROM)"
.PHONY: image_not_created
$(BUILD_DIR)/image: $(DOCKER_DEPS) $(DOCKER_IMAGE_CREATE_STATUS)
	docker build \
		$(DOCKER_CACHE_FROM_OPTION) \
		--build-arg IMAGE_NAME="$(DOCKER_IMAGE_NAME)" \
		--build-arg VERSION="$(DOCKER_IMAGE_VERSION)" \
		--build-arg VCS_REF="$(VCS_REF)" \
		--build-arg BUILD_DATE="$(BUILD_DATE)" \
		--tag $(DOCKER_IMAGE_TAG) .
	mkdir --parents $(BUILD_DIR) && touch $@

DOCKER_CONTAINER_ID != $(IF_DOCKERD_UP) && docker container ls --quiet --all --filter name=^/$(DOCKER_CONTAINER_NAME)$
DOCKER_CONTAINER_STATE != $(IF_DOCKERD_UP) && docker container ls --format {{.State}} --all --filter name=^/$(DOCKER_CONTAINER_NAME)$
DOCKER_CONTAINER_RUN_STATUS != [[ "$(DOCKER_CONTAINER_STATE)" != "running" ]] && echo "container_not_running"
.PHONY: container_not_running
$(BUILD_DIR)/container: $(BUILD_DIR)/image $(DOCKER_CONTAINER_RUN_STATUS)
ifneq ($(DOCKER_CONTAINER_ID),)
	docker container rename $(DOCKER_CONTAINER_NAME) $(DOCKER_CONTAINER_NAME)_$(DOCKER_CONTAINER_ID)
endif
	docker run --interactive --tty --detach \
		--user ci_user \
		--env KEEP_CI_USER_SUDO=$(KEEP_CI_USER_SUDO) \
		--env CI_UID="$$(id --user)" --env CI_GID="$$(id --group)" \
		--env "TERM=xterm-256color" \
		--name $(DOCKER_CONTAINER_NAME) \
		--mount type=bind,source="$$(pwd)",target=/home/repo \
		$(DOCKER_IMAGE_TAG)
	sleep 1
	mkdir --parents $(BUILD_DIR) && touch $@

$(BUILD_DIR)/drawio_test.pdf: $(BUILD_DIR)/container $(TESTS_DIR)/drawio_test.xml
	docker exec \
		$(DOCKER_CONTAINER_NAME) \
		bash -c "drawio --export --output $@ $(TESTS_DIR)/drawio_test.xml"
	pdfinfo $@

$(BUILD_DIR)/latex_test.pdf: $(BUILD_DIR)/container $(TESTS_DIR)/latex_test.tex
	docker exec \
		$(DOCKER_CONTAINER_NAME) \
		bash -c "latexmk -pdf --output-directory=$(BUILD_DIR) $(TESTS_DIR)/latex_test.tex"
	touch $@ # touch file in case latexmk decided not to recompile
	pdfinfo $@

$(BUILD_DIR)/latexindent_test: $(BUILD_DIR)/container $(TESTS_DIR)/latex_test.tex $(TESTS_DIR)/latexindent_test.tex
	docker exec \
		$(DOCKER_CONTAINER_NAME) \
		bash -c "latexindent $(TESTS_DIR)/latex_test.tex &> $(BUILD_DIR)/latexindent_test.tex"
	cmp $(BUILD_DIR)/latexindent_test.tex $(TESTS_DIR)/latexindent_test.tex
	touch $@

.PHONY: check
check: \
	$(BUILD_DIR)/drawio_test.pdf \
	$(BUILD_DIR)/latex_test.pdf \
	$(BUILD_DIR)/latexindent_test \


.PHONY: clean
clean:
	rm --force $(BUILD_DIR)/*.aux
	rm --force $(BUILD_DIR)/*.bbl
	rm --force $(BUILD_DIR)/*.fdb_latexmk
	rm --force $(BUILD_DIR)/*.fls
	rm --force $(BUILD_DIR)/*.log
	docker container ls --quiet --filter name=$(DOCKER_CONTAINER_NAME)_ | \
		ifne xargs docker stop
	docker container ls --quiet --filter name=$(DOCKER_CONTAINER_NAME)_ --all | \
		ifne xargs docker rm

