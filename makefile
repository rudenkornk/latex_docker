SHELL = /usr/bin/env bash

CACHE_FROM ?=

PROJECT_NAME := latex_image
BUILD_DIR := __build__
TESTS_DIR := tests

IMAGE_TAG := 2.0.0
IMAGE_NAME := rudenkornk/$(PROJECT_NAME)
IMAGE_NAMETAG := $(IMAGE_NAME):$(IMAGE_TAG)
CONTAINER_NAME := latex
VCS_REF != git rev-parse HEAD
BUILD_DATE != date --rfc-3339=date

DEPS :=
DEPS += Containerfile
DEPS += install_texlive.sh
DEPS += install_drawio.sh
DEPS += config_system.sh
DEPS += license.md

.PHONY: image
image: $(BUILD_DIR)/image

.PHONY: container
container: $(BUILD_DIR)/container

.PHONY: image_name
image_name:
	$(info $(IMAGE_NAME))

.PHONY: image_nametag
image_nametag:
	$(info $(IMAGE_NAMETAG))

.PHONY: image_tag
image_tag:
	$(info $(IMAGE_TAG))

.PHONY: $(BUILD_DIR)/not_ready

IMAGE_CREATE_STATUS != podman image exists $(IMAGE_NAMETAG) || echo "$(BUILD_DIR)/not_ready"
$(BUILD_DIR)/image: $(DEPS) $(IMAGE_CREATE_STATUS)
	podman build \
		--cache-from '$(CACHE_FROM)' \
		--label "org.opencontainers.image.created=$(BUILD_DATE)" \
		--label "org.opencontainers.image.ref.name=$(IMAGE_NAME)" \
		--label "org.opencontainers.image.revision=$(VCS_REF)" \
		--label "org.opencontainers.image.source=https://github.com/$(IMAGE_NAME)" \
		--label "org.opencontainers.image.version=$(IMAGE_TAG)" \
		--tag $(IMAGE_NAMETAG) .
	mkdir --parents $(BUILD_DIR) && touch $@

CONTAINER_ID != podman container ls --quiet --all --filter name=^$(CONTAINER_NAME)$
CONTAINER_STATE != podman container ls --format {{.State}} --all --filter name=^$(CONTAINER_NAME)$
CONTAINER_RUN_STATUS != [[ ! "$(CONTAINER_STATE)" =~ ^Up ]] && echo "$(BUILD_DIR)/not_ready"
$(BUILD_DIR)/container: $(BUILD_DIR)/image $(CONTAINER_RUN_STATUS)
ifneq ($(CONTAINER_ID),)
	podman container rename $(CONTAINER_NAME) $(CONTAINER_NAME)_$(CONTAINER_ID)
endif
	podman run --interactive --tty --detach \
		--cap-add=SYS_ADMIN `# For drawio` \
		--env "TERM=xterm-256color" \
		--mount type=bind,source="$$(pwd)",target="$$(pwd)" \
		--name $(CONTAINER_NAME) \
		--userns keep-id \
		--workdir "$$HOME" \
		$(IMAGE_NAMETAG)
	podman exec --user root $(CONTAINER_NAME) \
		bash -c "chown $$(id -u):$$(id -g) $$HOME"
	mkdir --parents $(BUILD_DIR)/tests
	mkdir --parents $(BUILD_DIR) && touch $@

$(BUILD_DIR)/tests/drawio_test.pdf: $(BUILD_DIR)/container $(TESTS_DIR)/drawio_test.xml
	podman exec --workdir "$$(pwd)" $(CONTAINER_NAME) \
		bash -c "drawio --export --output $@ $(TESTS_DIR)/drawio_test.xml"
	[[ $$(stat --format "%U" $@) == $$(id --user --name) ]]
	[[ $$(stat --format "%G" $@) == $$(id --group --name) ]]
	pdfinfo $@

$(BUILD_DIR)/tests/latex_test.pdf: $(BUILD_DIR)/container $(TESTS_DIR)/latex_test.tex
	podman exec --workdir "$$(pwd)" $(CONTAINER_NAME) \
		bash -c "latexmk -pdf --output-directory=$(BUILD_DIR)/tests $(TESTS_DIR)/latex_test.tex"
	[[ $$(stat --format "%U" $@) == $$(id --user --name) ]]
	[[ $$(stat --format "%G" $@) == $$(id --group --name) ]]
	touch $@ # touch file in case latexmk decided not to recompile
	pdfinfo $@

$(BUILD_DIR)/tests/latexindent_test.tex: $(BUILD_DIR)/container $(TESTS_DIR)/latex_test.tex $(TESTS_DIR)/latexindent_test.tex
	podman exec --workdir "$$(pwd)" $(CONTAINER_NAME) \
		bash -c "latexindent $(TESTS_DIR)/latex_test.tex &> $@"
	[[ $$(stat --format "%U" $@) == $$(id --user --name) ]]
	[[ $$(stat --format "%G" $@) == $$(id --group --name) ]]
	cmp $@ $(TESTS_DIR)/latexindent_test.tex
	touch $@

$(BUILD_DIR)/tests/username_test: $(BUILD_DIR)/container
	container_name=$$(podman exec --workdir "$$(pwd)" $(CONTAINER_NAME) \
		bash -c "id --user --name") && \
	[[ "$$container_name" == "$$(id --user --name)" ]]
	touch $@

$(BUILD_DIR)/tests/readme_test: readme.md
	readme_version=$$(grep --perl-regexp --only-matching "$(IMAGE_NAME):\K\d+\.\d+\.\d+" readme.md) && \
	[[ "$$readme_version" == "$(IMAGE_TAG)" ]]
	touch $@

.PHONY: check
check: \
	$(BUILD_DIR)/tests/drawio_test.pdf \
	$(BUILD_DIR)/tests/latex_test.pdf \
	$(BUILD_DIR)/tests/latexindent_test.tex \
	$(BUILD_DIR)/tests/username_test \
	$(BUILD_DIR)/tests/readme_test \


.PHONY: clean
clean:
	rm --force $(BUILD_DIR)/*.aux
	rm --force $(BUILD_DIR)/*.bbl
	rm --force $(BUILD_DIR)/*.fdb_latexmk
	rm --force $(BUILD_DIR)/*.fls
	rm --force $(BUILD_DIR)/*.log
	podman container ls --quiet --filter name=^$(CONTAINER_NAME) | xargs podman stop || true
	podman container ls --quiet --filter name=^$(CONTAINER_NAME) --all | xargs podman rm || true

