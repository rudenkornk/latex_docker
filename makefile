SHELL = /usr/bin/env bash

CACHE_FROM ?=

BASE_NAME := latex_ubuntu

ANCHOR := 6532d0d3418365b917ce95335d05c31e263ba8a3
OFFSET := 0
PATCH != echo $$(($$(git rev-list $(ANCHOR)..HEAD --count --first-parent) - $(OFFSET)))
IMAGE_TAG := 22.0.$(PATCH)

CONTAINERFILE := Containerfile

PROJECT := rudenkornk/latex_image
BUILD_DIR := __build__/$(BASE_NAME)/$(IMAGE_TAG)
BUILD_TESTS := $(BUILD_DIR)/tests
CONTAINER_NAME := $(BASE_NAME)_cont
IMAGE_NAME := rudenkornk/$(BASE_NAME)
IMAGE_NAMETAG := $(IMAGE_NAME):$(IMAGE_TAG)
TESTS_DIR := tests
VCS_REF != git rev-parse HEAD

DEPS != grep --perl-regexp --only-matching "COPY \K.*?(?= \S+$$)" $(CONTAINERFILE)
DEPS += $(CONTAINERFILE)

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

.PHONY: readme_nametag
readme_nametag:
	echo $$(grep --perl-regexp --only-matching "$(IMAGE_NAME):\d+\.\d+\.\d+" readme.md)

.PHONY: format
format: $(BUILD_DIR)/node_modules
	npx prettier --ignore-path <(cat .gitignore .prettierignore) --write .

$(BUILD_DIR)/node_modules: package.json package-lock.json
	npm install --save-exact;
	mkdir --parents $(BUILD_DIR) && touch $@

.PHONY: $(BUILD_DIR)/not_ready

IMAGE_CREATE_STATUS != podman image exists $(IMAGE_NAMETAG) || echo "$(BUILD_DIR)/not_ready"
$(BUILD_DIR)/image: $(DEPS) $(IMAGE_CREATE_STATUS)
	podman build \
		--cache-from '$(CACHE_FROM)' \
		--label "org.opencontainers.image.ref.name=$(IMAGE_NAME)" \
		--label "org.opencontainers.image.revision=$(VCS_REF)" \
		--label "org.opencontainers.image.source=https://github.com/$(PROJECT)" \
		--label "org.opencontainers.image.version=$(IMAGE_TAG)" \
		--tag $(IMAGE_NAMETAG) \
		--file $(CONTAINERFILE) .
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
	mkdir --parents $(BUILD_TESTS)
	mkdir --parents $(BUILD_DIR) && touch $@

$(BUILD_TESTS)/drawio_test.pdf: $(BUILD_DIR)/container $(TESTS_DIR)/drawio_test.xml
	podman exec --workdir "$$(pwd)" $(CONTAINER_NAME) \
		bash -c "drawio --export --output $@ $(TESTS_DIR)/drawio_test.xml"
	[[ $$(stat --format "%U" $@) == $$(id --user --name) ]]
	[[ $$(stat --format "%G" $@) == $$(id --group --name) ]]
	pdfinfo $@

$(BUILD_TESTS)/latex_test.pdf: $(BUILD_DIR)/container $(TESTS_DIR)/latex_test.tex
	podman exec --workdir "$$(pwd)" $(CONTAINER_NAME) \
		bash -c "latexmk -pdf --output-directory=$(BUILD_TESTS) $(TESTS_DIR)/latex_test.tex"
	[[ $$(stat --format "%U" $@) == $$(id --user --name) ]]
	[[ $$(stat --format "%G" $@) == $$(id --group --name) ]]
	touch $@ # touch file in case latexmk decided not to recompile
	pdfinfo $@

$(BUILD_TESTS)/latexindent_test.tex: $(BUILD_DIR)/container $(TESTS_DIR)/latex_test.tex $(TESTS_DIR)/latexindent_test.tex
	podman exec --workdir "$$(pwd)" $(CONTAINER_NAME) \
		bash -c "latexindent $(TESTS_DIR)/latex_test.tex &> $@"
	[[ $$(stat --format "%U" $@) == $$(id --user --name) ]]
	[[ $$(stat --format "%G" $@) == $$(id --group --name) ]]
	cmp $@ $(TESTS_DIR)/latexindent_test.tex
	touch $@

$(BUILD_TESTS)/username_test: $(BUILD_DIR)/container
	container_name=$$(podman exec --workdir "$$(pwd)" $(CONTAINER_NAME) \
		bash -c "id --user --name") && \
	[[ "$$container_name" == "$$(id --user --name)" ]]
	touch $@

.PHONY: check
check: \
	$(BUILD_TESTS)/drawio_test.pdf \
	$(BUILD_TESTS)/latex_test.pdf \
	$(BUILD_TESTS)/latexindent_test.tex \
	$(BUILD_TESTS)/username_test \


.PHONY: clean
clean:
	rm --force $(BUILD_DIR)/*.aux
	rm --force $(BUILD_DIR)/*.bbl
	rm --force $(BUILD_DIR)/*.fdb_latexmk
	rm --force $(BUILD_DIR)/*.fls
	rm --force $(BUILD_DIR)/*.log
	podman container ls --quiet --filter name=^$(CONTAINER_NAME) | xargs podman stop || true
	podman container ls --quiet --filter name=^$(CONTAINER_NAME) --all | xargs podman rm || true

