SHELL := /bin/bash

PYTHON ?= python3
REGISTRY := aic-skills
VERSION_FILE := VERSION
VERSION ?= $(shell if [[ -f $(VERSION_FILE) ]]; then cat $(VERSION_FILE); else echo v0.1.0; fi)

.PHONY: help index validate version set-version check-version

index:
	$(PYTHON) ./scripts/indexgen/indexgen.py --repo-root . --registry-version "$(VERSION)"

validate: index
	@echo "$(REGISTRY) registry validated"

version:
	@echo "$(VERSION)"

check-version:
	@if [[ -z "$(VERSION)" ]]; then \
		echo "ERROR: VERSION cannot be empty"; \
		exit 1; \
	fi
	@if [[ "$(VERSION)" != v* ]]; then \
		echo "ERROR: VERSION must start with v, got $(VERSION)"; \
		exit 1; \
	fi

set-version: check-version
	@printf '%s\n' "$(VERSION)" > $(VERSION_FILE)
	@$(PYTHON) ./scripts/indexgen/indexgen.py --repo-root . --registry-version "$(VERSION)" --metadata-only
	@echo "set $(REGISTRY) version to $(VERSION)"

help:
	@echo "$(REGISTRY) Makefile targets"
	@echo "  make index                  - regenerate registry indexes"
	@echo "  make validate               - regenerate indexes and validate metadata"
	@echo "  make version                - print registry version"
	@echo "  make set-version VERSION=vX - update VERSION and registry.yaml"
