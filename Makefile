SHELL := /bin/bash

.PHONY: help setup setup-dev format lint test security audit sbom verify build run clean ci

PYTHON ?= python3
VENV ?= .venv
PIP := $(VENV)/bin/python -m pip
PY := $(VENV)/bin/python

help:
	@printf '%s\n' \
	  'Targets:' \
	  '  setup      Create production virtualenv and install dependencies' \
	  '  setup-dev  Create development virtualenv and install dev dependencies' \
	  '  format     Apply Ruff formatting/fixes' \
	  '  lint       Run Ruff checks' \
	  '  test       Run pytest' \
	  '  security   Run Bandit security scan' \
	  '  audit      Audit production dependencies with pip-audit' \
	  '  sbom       Generate CycloneDX SBOM' \
	  '  verify     Run repository security verification script' \
	  '  build      Build Docker image' \
	  '  run        Run development server' \
	  '  clean      Remove local generated caches/artifacts' \
	  '  ci         Run local CI/security gate'

$(VENV)/bin/python:
	$(PYTHON) -m venv $(VENV)

setup: $(VENV)/bin/python
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt

setup-dev: $(VENV)/bin/python
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements-dev.txt

format: setup-dev
	$(PY) -m ruff format .
	$(PY) -m ruff check . --fix

lint: setup-dev
	$(PY) -m ruff check .
	$(PY) -m ruff format --check .

test: setup-dev
	$(PY) -m pytest -q

security: setup-dev
	$(PY) -m bandit -q -r app -x tests

audit: setup-dev
	$(PY) -m pip_audit -r requirements.txt --strict

sbom: setup-dev
	$(VENV)/bin/cyclonedx-py requirements requirements.txt --output-file sbom.json

verify:
	./scripts/security_check.sh

build:
	docker build --pull -t zsecure:local .

run: setup-dev
	$(VENV)/bin/uvicorn app.main:app --reload --host 127.0.0.1 --port 8000

clean:
	rm -rf .pytest_cache .ruff_cache .coverage htmlcov sbom.json
	find . -type d -name __pycache__ -prune -exec rm -rf {} +

ci: lint test security audit verify
