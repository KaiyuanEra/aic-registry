SHELL := /bin/bash

PYTHON ?= python3
REGISTRY := aic-skills
VERSION_FILE := VERSION
AIC_VERSION_FILE := AIC_VERSION
VERSION ?= $(shell if [[ -f $(VERSION_FILE) ]]; then cat $(VERSION_FILE); else echo v0.1.0; fi)
AIC_VERSION ?= $(shell if [[ -f $(AIC_VERSION_FILE) ]]; then cat $(AIC_VERSION_FILE); else echo v1.0.0; fi)

.PHONY: help index validate version aic-version set-version set-aic-version check-version check-aic-version

index:
	$(PYTHON) ./scripts/indexgen/indexgen.py --repo-root . --registry-version "$(VERSION)" --aic-version "$(AIC_VERSION)"

validate: index
	@echo "$(REGISTRY) registry validated"

version:
	@echo "$(VERSION)"

aic-version:
	@echo "$(AIC_VERSION)"

check-version:
	@if [[ -z "$(VERSION)" ]]; then \
		echo "ERROR: VERSION cannot be empty"; \
		exit 1; \
	fi
	@if [[ "$(VERSION)" != v* ]]; then \
		echo "ERROR: VERSION must start with v, got $(VERSION)"; \
		exit 1; \
	fi

check-aic-version:
	@if [[ -z "$(AIC_VERSION)" ]]; then \
		echo "ERROR: AIC_VERSION cannot be empty"; \
		exit 1; \
	fi
	@if [[ "$(AIC_VERSION)" != v* ]]; then \
		echo "ERROR: AIC_VERSION must start with v, got $(AIC_VERSION)"; \
		exit 1; \
	fi

set-version: check-version
	@printf '%s\n' "$(VERSION)" > $(VERSION_FILE)
	@$(PYTHON) ./scripts/indexgen/indexgen.py --repo-root . --registry-version "$(VERSION)" --aic-version "$(AIC_VERSION)" --metadata-only
	@echo "set $(REGISTRY) version to $(VERSION)"

set-aic-version: check-aic-version
	@printf '%s\n' "$(AIC_VERSION)" > $(AIC_VERSION_FILE)
	@$(PYTHON) ./scripts/indexgen/indexgen.py --repo-root . --registry-version "$(VERSION)" --aic-version "$(AIC_VERSION)" --metadata-only
	@echo "set required aic version to $(AIC_VERSION)"

help:
	@echo "$(REGISTRY) Makefile targets"
	@echo "  make index                  - regenerate registry indexes"
	@echo "  make validate               - regenerate indexes and validate metadata"
	@echo "  make version                - print registry version"
	@echo "  make set-version VERSION=vX - update VERSION and registry.yaml"
	@echo "  make aic-version            - print required aic version"
	@echo "  make set-aic-version AIC_VERSION=vX - update AIC_VERSION and registry.yaml"
