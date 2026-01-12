# TYPO3 Extension Makefile
# Docker-based testing following TYPO3 core conventions
# Use runTests.sh for CI-compatible containerized test execution
#
# CUSTOMIZATION: Update extension name in help text

.PHONY: help all check test unit functional e2e fuzz mutation lint phpstan cs fix rector docs clean update

.DEFAULT_GOAL := help

RUNTESTS = Build/Scripts/runTests.sh

help:
	@echo "TYPO3 Extension Development Commands"
	@echo ""
	@echo "  Quick Start:"
	@echo "    make all        Run EVERYTHING (checks + tests + mutation)"
	@echo "    make check      Run ALL quality checks (lint, cs, phpstan)"
	@echo "    make test       Run ALL tests (unit, functional, e2e, fuzz)"
	@echo ""
	@echo "  Individual Tests:"
	@echo "    make unit       Run unit tests"
	@echo "    make functional Run functional tests (SQLite)"
	@echo "    make e2e        Run E2E tests (Playwright, requires DDEV)"
	@echo "    make fuzz       Run fuzz tests"
	@echo "    make mutation   Run mutation tests (slow)"
	@echo ""
	@echo "  Individual Checks:"
	@echo "    make lint       Check PHP syntax"
	@echo "    make phpstan    Run static analysis"
	@echo "    make cs         Check code style"
	@echo ""
	@echo "  Fixes:"
	@echo "    make fix        Fix code style"
	@echo "    make rector     Apply Rector rules"
	@echo ""
	@echo "  Other:"
	@echo "    make docs       Render documentation"
	@echo "    make clean      Remove build artifacts"
	@echo "    make update     Update Docker images"

# === Main Targets ===
all: check test mutation
	@echo ""
	@echo "=== ALL CHECKS, TESTS AND MUTATION PASSED ==="

check: lint cs phpstan
	@echo ""
	@echo "=== ALL QUALITY CHECKS PASSED ==="

test: unit functional fuzz
	@echo ""
	@echo "=== ALL TESTS PASSED ==="

# === Individual Tests ===
unit:
	$(RUNTESTS) -s unit

functional:
	$(RUNTESTS) -s functional

# For faster parallel functional tests (SQLite only)
functional-fast:
	$(RUNTESTS) -s functionalParallel

e2e:
	$(RUNTESTS) -s e2e

fuzz:
	$(RUNTESTS) -s fuzz

mutation:
	$(RUNTESTS) -s mutation

# === Individual Checks ===
lint:
	$(RUNTESTS) -s lint

phpstan:
	$(RUNTESTS) -s phpstan

cs:
	$(RUNTESTS) -s cgl -n

# === Fixes ===
fix:
	$(RUNTESTS) -s cgl

rector:
	$(RUNTESTS) -s rector

# === Documentation ===
docs:
	$(RUNTESTS) -s renderDocumentation

# === Maintenance ===
clean:
	$(RUNTESTS) -s clean

update:
	$(RUNTESTS) -u
