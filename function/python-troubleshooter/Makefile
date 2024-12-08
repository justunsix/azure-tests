SHELL := /bin/bash

.PHONY: help
help: ## Show this help
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Initialize project with Python venv
	uv venv

first-init: ## Initialize project from scratch
	uv init
	uv venv
	uv sync
	func init --python
	func new --name HttpExample --template "HTTP trigger" --authlevel "anonymous"
	echo "Activate the venv to continue development"
