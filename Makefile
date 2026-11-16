.DEFAULT_GOAL := help
PACKAGE_DIR := ./src
VENV_DIR := ./.venv


define CACHE_PATHS
__pycache__ \
*.pyc \
.ruff_cache \
.mypy_cache \
.pytest_cache \
.DS_Store \
.cache \
.agents_cache \
.benchmarks
endef


##@ Help


.PHONY: help
help: ## Display this message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)


##@ Development


.PHONY: env
env: ## Activate the development environment
	@poetry env activate


.PHONY: init
init: ## Initialize new project, usage "make init python=version"
	@poetry \
		--dev-dependency="pre-commit@^4.5.1" \
		--dev-dependency="ruff@~0.15.7" \
		--dev-dependency="pytest@^9.0.2" \
		--dev-dependency="pytest-coverage@~0.0" \
		init
	@poetry env use python$(python)


ifneq ($(filter clone,$(MAKECMDGOALS)),)
CLONE_DEST := $(word 2,$(MAKECMDGOALS))
.PHONY: $(CLONE_DEST)
$(CLONE_DEST): ; @:
endif

.PHONY: clone
clone: ## Create a new project from this boilerplate, usage "make clone ~/path/NewProject"
	@set -e; \
	dest="$(CLONE_DEST)"; \
	if [ -z "$$dest" ]; then echo "error: destination is required, usage: make clone <path>" >&2; exit 1; fi; \
	if [ -e "$$dest" ]; then echo "error: '$$dest' already exists" >&2; exit 1; fi; \
	mkdir -p "$$dest"; \
	git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf - | tar -xf - -C "$$dest"; \
	cd "$$dest"; \
	: > README.md; \
	: > AGENTS.md; \
	ln -s AGENTS.md CLAUDE.md; \
	git init --quiet; \
	poetry \
		--dev-dependency="pre-commit@^4.5.1" \
		--dev-dependency="ruff@~0.15.7" \
		--dev-dependency="pytest@^9.0.2" \
		--dev-dependency="pytest-coverage@~0.0" \
		init --license Apache-2.0; \
	echo "Project created: $$dest"


.PHONY: install-env
install-env: ## Install the development environment if it doesn't exists
	@poetry install
	@poetry run pre-commit install --hook-type commit-msg --hook-type pre-push --hook-type pre-commit


##@ Quality


.PHONY: lint
lint: ## Check code style with ruff
	@poetry run pre-commit run --all-files


.PHONY: test
test: ## Run tests using pytest
	@set -e; poetry run pytest -v -s $(path)
	@poetry run pytest --cov=${PACKAGE_DIR}


##@ Maintenance


.PHONY: clean
clean: ## Clean temporary files and build artifacts
	@rm --force --recursive "${CACHE_PATHS[@]}"
	@poetry run pre-commit clean
	@poetry run pre-commit gc


.PHONY: build
build: test ## Build new version wheel
	@set -e; poetry build
