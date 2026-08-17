# Dotfiles developer tasks.
#
# These wrap the checks CI runs, so `make check` locally is equivalent to a
# green pipeline. Run `make help` for the full list.

SHELL := /bin/bash
.DEFAULT_GOAL := help

# Every shell script tracked in this repo, excluding submodules.
SCRIPTS := install.sh $(wildcard lib/*.sh) $(wildcard bin/*.sh) \
           $(wildcard config/shell/*.sh) $(wildcard profiles/*.profile) \
           tests/helpers/common.bash .githooks/pre-commit

.PHONY: help
help: ## Show this help
	@echo "Dotfiles — available targets:"
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

.PHONY: check
check: lint syntax dry-run test ## Run every check CI runs

.PHONY: test
test: ## Run the bats test suite
	@command -v bats >/dev/null || { \
		echo "bats not installed: https://github.com/bats-core/bats-core"; \
		echo "  quick install: git clone --depth 1 https://github.com/bats-core/bats-core.git /tmp/bats && sudo /tmp/bats/install.sh /usr/local"; \
		exit 1; }
	@bats tests/*.bats

.PHONY: test-parallel
test-parallel: ## Run the test suite across 4 jobs
	@bats --jobs 4 tests/*.bats

.PHONY: test-verbose
test-verbose: ## Run the test suite with per-test output
	@bats --verbose-run tests/*.bats

.PHONY: lint
lint: ## Lint all shell scripts with shellcheck
	@command -v shellcheck >/dev/null || { echo "shellcheck not installed"; exit 1; }
	@shellcheck --severity=warning $(SCRIPTS)
	@echo "shellcheck: clean"

.PHONY: syntax
syntax: ## Parse every script without executing it
	@for f in $(SCRIPTS); do bash -n "$$f" || exit 1; done
	@echo "syntax: clean"

.PHONY: dry-run
dry-run: ## Smoke-test the installer without touching the filesystem
	@./install.sh --dry-run --all >/dev/null
	@./install.sh --dry-run --server --all >/dev/null
	@./install.sh --dry-run --minimal --all >/dev/null
	@./install.sh --help >/dev/null
	@echo "dry-run: clean"

.PHONY: health
health: ## Verify the current installation
	@./install.sh --health-check

.PHONY: install
install: ## Full install on this machine
	@./install.sh --all

.PHONY: hooks
hooks: ## Install the repo's git hooks
	@git config core.hooksPath .githooks
	@echo "git hooks enabled (core.hooksPath=.githooks)"

.PHONY: secrets
secrets: ## Scan the working tree for committed secrets
	@command -v gitleaks >/dev/null || { echo "gitleaks not installed: https://github.com/gitleaks/gitleaks"; exit 1; }
	@gitleaks detect --no-banner --redact --config .gitleaks.toml

.PHONY: fmt
fmt: ## Format shell scripts with shfmt (if installed)
	@command -v shfmt >/dev/null || { echo "shfmt not installed"; exit 1; }
	@shfmt -i 4 -ci -w $(SCRIPTS)
	@echo "shfmt: formatted"
