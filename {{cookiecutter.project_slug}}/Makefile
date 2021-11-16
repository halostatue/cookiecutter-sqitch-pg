# Note: this Makefile depends on GNU Make extensions.

all: test
test: test_database verify_dump
deploy: deploy_database
dump: deploy_database dump_database

TIMESTAMP := $(shell date -u +%Y%m%d%H%M%S)
REPO_REL := $(shell git rev-parse --show-cdup)
REPO_ROOT := $(shell cd "$(PWD)/$(REPO_REL)" && pwd)
REPO_URL := $(shell git remote get-url origin)
REPO_PATH := $(notdir $(basename $(REPO_URL)))

UPLOAD_BUCKET := {{ cookiecutter.upload_bucket }}
UPLOAD_REGION := {{ cookiecutter.upload_region }}

ci-test:
	./setup
	$(MAKE) createdb
	$(MAKE) test
	$(MAKE) dropdb


targets:
	@$(REPO_ROOT)/run targets

target:
	@$(REPO_ROOT)/run target

name:
	@$(REPO_ROOT)/run dbname

createdb:
	@$(REPO_ROOT)/run createdb

dropdb:
	@$(REPO_ROOT)/run dropdb

resetdb: dropdb createdb

test_database: deploy_database
	@$(REPO_ROOT)/run test-sqitch

deploy_database:
	@$(REPO_ROOT)/run deploy-sqitch

dump_database:
	@$(REPO_ROOT)/run dump-database

clean_dump:
	@$(REPO_ROOT)/run dump-clean

verify_dump:
	@$(REPO_ROOT)/run verify-dump

bundle:
	@$(REPO_ROOT)/run bundle

TARBALL_NAME := $(REPO_PATH)-$(TIMESTAMP).tar.gz
RELEASE_TARBALL := release/$(TARBALL_NAME)

$(RELEASE_TARBALL): bundle
	@$(REPO_ROOT)/run release $@ $<

release: $(RELEASE_TARBALL)

upload_release: $(RELEASE_TARBALL)
	@$(REPO_ROOT)/run upload $(RELEASE_TARBALL) $(UPLOAD_BUCKET) $(UPLOAD_REGION)

remote_release: $(RELEASE_TARBALL)
	@$(REPO_ROOT)/run remote-release $(RELEASE_TARBALL) $(UPLOAD_BUCKET) $(UPLOAD_REGION)

.PHONY: all \
	ci-test \
	clean_dump \
	createdb \
	deploy \
	deploy_database \
	dropdb \
	dump \
	dump_database \
	name \
	release \
	remote_release \
	resetdb \
	targets \
	test \
	test_database \
	upload_release \
	verify_dump
