BASE_NAME := latex_ubuntu
ANCHOR := 6532d0d3418365b917ce95335d05c31e263ba8a3
OFFSET := 0
PATCH != echo $$(($$(git rev-list $(ANCHOR)..HEAD --count --first-parent) - $(OFFSET)))
IMAGE_TAG := 22.0.$(PATCH)
CONTAINERFILE := src/Containerfile
