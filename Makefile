#
# Makefile by Carl J. Nobile
#

include include.mk

PREFIX		= $(shell pwd)
PACKAGE_DIR	= $(shell echo $${PWD\#\#*/})
DISTNAME	= $(PACKAGE_DIR)-$(VERSION)
LOGS_DIR	= $(PREFIX)/logs
DOCS_DIR	= $(PREFIX)/docs
TODAY		= $(shell date +"%Y-%m-%d_%H%M")
RM_REGEX	= '(^.*.pyc$$)|(^.*.wsgic$$)|(^.*~$$)|(.*\#$$)|(^.*,cover$$)'
RM_CMD		= find $(PREFIX) -regextype posix-egrep -regex $(RM_REGEX) \
                  -exec rm {} \;
COVERAGE_DIR	= $(PREFIX)/.coverage_tests
COVERAGE_FILE	= $(PREFIX)/.coveragerc
PIP_ARGS	= # Pass var for pip install.
TEST_PATH	= # The path to run tests on.
TEST_TAG	= # The path to run tests on.

#----------------------------------------------------------------------
all	: help

#----------------------------------------------------------------------
.PHONY:	help
help	:
	@LC_ALL=C $(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : \
                2>/dev/null | awk -v RS= \
                -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data \
                     base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | grep \
                -E -v -e '^[^[:alnum:]]' -e '^$@$$'

.PHONY	: tar
tar	: clean
	@(cd ..; tar -czvf $(DISTNAME).tar.gz --exclude=".git" \
          --exclude="__pycache__" --exclude="logs/*.log" --exclude="dist/*" \
          $(PACKAGE_DIR))

#----------------------------------------------------------------------
# Run all tests
# $ make tests
#
# Run all tests in a specific test file.
# $ make tests TEST_PATH=tests/test_bases.py
#
# Run all tests in a specific test file and class.
# $ make tests TEST_PATH=tests/test_bases.py::TestBases
#
# Run just one test in a specific test file and class.
# $ make tests TEST_PATH=tests/test_bases.py::TestBases::test_version
.PHONY	: tests
tests	: clean
	@rm -rf $(DOCS_DIR)/htmlcov
	@mkdir -p $(LOGS_DIR)
	@coverage erase --rcfile=$(COVERAGE_FILE)
	@coverage run --rcfile=$(COVERAGE_FILE) -m pytest --capture=fd -s \
         $(TEST_PATH)
	@coverage report --rcfile=$(COVERAGE_FILE)
	@coverage html --rcfile=$(COVERAGE_FILE)
	@echo $(TODAY)

.PHONY	: flake8
flake8	:
        # Error on syntax errors or undefined names.
	flake8 . --select=E9,F7,F63,F82 --show-source
        # Warn on everything else.
	flake8 . --exit-zero

#----------------------------------------------------------------------
# To add a pre-release candidate such as 'rc1' to a test package name an
# environment variable needs to be set that setup.py can read.
#
# make build TEST_TAG=rc1
# make upload-test TEST_TAG=rc1
#
# The tarball would then be named python-daemon-2.0.0rc1.tar.gz
#
.PHONY	: build
build	: export PR_TAG=$(TEST_TAG)
build	: clobber
	@./config.py
	hatch build dist

.PHONY	: upload
upload	: build
	hatch publish --repo main dist/*
#	twine upload --repository pypi dist/*

.PHONY	: upload-test
upload-test: build
	hatch publish --repo test dist/*
#	twine upload --verbose --repository testpypi dist/*

#----------------------------------------------------------------------
.PHONY	: install-dev
install-dev:
	pip install $(PIP_ARGS) -r requirements/development.txt

#----------------------------------------------------------------------
.PHONY	: clean
clean	:
	$(shell $(RM_CMD))
	@rm -rf *.egg-info
	@rm -rf dist

.PHONY	: clobber
clobber	: clean
	@rm -f $(LOGS_DIR)/*.log
	@rm -f $(LOGS_DIR)/*.pid
	@rm -f $(LOGS_DIR)/*.txt
	@rm -rf __pycache__
	@rm -rf build *.egg-info
