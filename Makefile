.DEFAULT_GOAL := help

# ANSI escape codes
BOLD := \033[1m
RESET := \033[0m
REVERSE := \033[7m
RED := \033[0;31m

.PHONY: help
help:
	@echo ""
	@echo "venv                   create python virtual env"
	@echo "requirements           generate requirements file from base requirements"
	@echo ""
	@echo "changelog_entry        create changelog entry"
	@echo "changelog_update       update changelog from recent entries"
	@echo ""
	@echo "hooks                  install Git hooks"
	@echo ""
	@echo "lint                   linting checks through flake8 and pylint"
	@echo "flake8                 lint using flake8"
	@echo "pylint                 lint using pylint"
	@echo ""
	@echo "release                upload new pypi release using twine"
	@echo ""

VENV_PATH := $(PWD)/env

.PHONY: venv
venv:
	python3 -m venv $(VENV_PATH)
	$(VENV_PATH)/bin/pip install -r requirements.txt

.PHONY: requirements
requirements:
	@echo "Generating requirements.txt from core dependencies in requirements_base.txt ..."
	python3 -m venv temp_venv
	temp_venv/bin/pip install --upgrade pip
	temp_venv/bin/pip install -r requirements_base.txt
	echo '# generated via "make requirements"' > requirements.txt
	temp_venv/bin/pip freeze -r requirements_base.txt >> requirements.txt
	rm -rf temp_venv
	@echo "requirements.txt has been updated 🍉"

.PHONY: hooks
hooks:
	@echo "Installing git hooks..."
	cp ./git_hooks/{commit-msg,pre-commit*} .git/hooks/
	chmod +x .git/hooks/*
	@echo "Hooks installed"

.PHONY: changelog_entry
changelog_entry:
	scriv create

.PHONY: changelog_update
changelog_update:
	@VERSION=`python -c "from curvesim import __version__; print(__version__)"`; \
	scriv collect --version=$${VERSION}

.PHONY: release
release:
	pip install build twine
	python -m build
	twine upload dist/*
	rm -fr dist curvesim.egg-info

.PHONY: lint
lint:
	@echo ""
	@make flake8
	@echo ""
	@make pylint
	@echo ""
	@echo "Linting checks passed 🏆"

.PHONY: black
black:
	@echo "$(REVERSE)Running$(RESET) $(BOLD)black$(RESET)..."
	@black --version
	@black .

.PHONY: flake8
flake8:
	@echo "$(REVERSE)Running$(RESET) $(BOLD)flake8$(RESET)..."
	@flake8 --version
	@if ! flake8 .; then \
	    echo "$(BOLD)flake8$(RESET): $(RED)FAILED$(RESET) checks" ;\
	    exit 1 ;\
	fi
	@echo "flake8 passed 🍄"

.PHONY: pylint
pylint:
	@echo "$(REVERSE)Running$(RESET) $(BOLD)pylint$(RESET)..."
	@echo ""
	@./check_pylint_score.py curvesim test
	@echo ""
	@echo "pylint passed ⚙️"

.PHONY: coverage
coverage:
	coverage run -m pytest
	coverage run -m test.ci
	coverage combine
	coverage report
	# coverage report --format=total

.PHONY: coverage_html
coverage_html:
	coverage html
	python -m http.server --directory htmlcov
