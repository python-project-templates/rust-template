#########
# BUILD #
#########
.PHONY: develop-py develop-rust develop
develop-py:
	python -m pip install -e .[develop]

develop-rust:
	make -C rust develop

develop: develop-rust develop-py  ## setup project for development

.PHONY: build-py build-rust build
build-py:
	maturin build

build-rust:
	make -C rust build

dev: build  ## lightweight in-place build for iterative dev
	$(_CP_COMMAND)

build: build-rust build-py  ## build the project

.PHONY: install
install:  ## install python library
	python -m pip install .

UNAME := $(shell uname)
ifeq ($(UNAME), Darwin)
	_CP_COMMAND := cp target/debug/librust_template.dylib rust_template/rust_template.abi3.so
else
	_CP_COMMAND := cp target/debug/librust_template.so rust_template/rust_template.abi3.so
endif

#########
# LINTS #
#########
.PHONY: lint-py lint-rust lint lints
lint-py:  ## run python linter with ruff
	python -m ruff check rust_template
	python -m ruff format --check rust_template

lint-rust:  ## run the rust linter
	make -C rust lint

lint: lint-rust lint-py  ## run project linters
# alias
lints: lint

.PHONY: fix-py fix-rust fix format
fix-py:  ## fix python formatting with ruff
	python -m ruff check --fix rust_template
	python -m ruff format rust_template

fix-rust:  ## fix rust formatting
	make -C rust fix

fix: fix-rust fix-py  ## run project autoformatters
# alias
format: fix

################
# Other Checks #
################
.PHONY: check-manifest checks check annotate

check-manifest:  ## check python sdist manifest with check-manifest
	check-manifest -v

checks: check-manifest

# alias
check: checks

annotate:  ## run python type annotation checks with mypy
	python -m mypy ./rust_template

#########
# TESTS #
#########
.PHONY: test test-py coverage-py tests

test-py:  ## run python tests
	python -m pytest -v rust_template/tests --junitxml=junit.xml
# alias
tests-py: test-py

coverage-py:  ## run python tests and collect test coverage
	python -m pytest -v rust_template/tests --junitxml=junit.xml --cov=rust_template --cov-branch --cov-fail-under=50 --cov-report term-missing --cov-report xml

test-rust:  ## run rust tests
	make -C rust test
# alias
tests-rust: test-rust

coverage-rust:  ## run rust tests and collect test coverage
	make -C rust coverage

test: test-py test-rust  ## run all tests
coverage: coverage-py coverage-rust  ## run all tests and collect test coverage
# alias
tests: test

###########
# VERSION #
###########
.PHONY: show-version patch minor major

show-version:  ## show current library version
	@bump-my-version show current_version

patch:  ## bump a patch version
	@bump-my-version bump patch

minor:  ## bump a minor version
	@bump-my-version bump minor

major:  ## bump a major version
	@bump-my-version bump major

########
# DIST #
########
.PHONY: dist dist-build dist-sdist dist-local-wheel publish

dist-build-py:  # build python dists
	python -m build -w -s

dist-build-rust:  # build rust dists
	make -C rust dist

dist-check:  ## run python dist checker with twine
	python -m twine check dist/*

dist: clean build dist-build-rust dist-build-py dist-check  ## build all dists

publish: dist  # publish python assets

#########
# CLEAN #
#########
.PHONY: deep-clean clean

deep-clean: ## clean everything from the repository
	git clean -fdx

clean: ## clean the repository
	rm -rf .coverage coverage cover htmlcov logs build dist *.egg-info

############################################################################################

.PHONY: help

# Thanks to Francoise at marmelab.com for this
.DEFAULT_GOAL := help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

print-%:
	@echo '$*=$($*)'
