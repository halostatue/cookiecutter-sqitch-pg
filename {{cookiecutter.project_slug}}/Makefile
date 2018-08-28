# Note: this Makefile depends on GNU Make extensions.

all: test
test: test_database verify_dump
deploy: deploy_database
dump: deploy_database dump_database

default_target := $(shell sqitch config --get engine.pg.target)
SQITCH_TARGET := $(or ${MIX_ENV},${RAILS_ENV},$(default_target))
SQITCH_DBNAME := $(shell sqitch config --get target.$(SQITCH_TARGET).uri | sed -e 's/^db:pg://')
VERIFY_PID = $(shell echo "$${PPID}")
DUMP_TARGET = structure.sql
TIMESTAMP := $(shell date +%Y%m%d%H%M%S)
SSH_COMMAND := "ssh ${SSH_USER} -o 'StrictHostKeyChecking=no' -o 'ForwardAgent=yes'"

REPO_REL := $(shell git rev-parse --show-cdup)
REPO_ROOT := $(shell cd "$(PWD)/$(REPO_REL)" && pwd)
REPO_URL := $(shell git remote get-url origin)
REPO_PATH := $(notdir $(basename $(REPO_URL)))

targets:
	@sqitch config --get-regexp '^target\.' | cut -f1 -d= | cut -f2 -d.

target:
	@echo $(SQITCH_TARGET)

name:
	@echo $(SQITCH_DBNAME)

createdb:
	@createdb $(SQITCH_DBNAME)

dropdb:
	@dropdb $(SQITCH_DBNAME)

resetdb: dropdb createdb

test_database: deploy_database
	@pg_prove -d $(SQITCH_DBNAME) --shuffle test/*.sql

deploy_database:
	@-sqitch deploy $(SQITCH_TARGET)
	@sqitch status $(SQITCH_TARGET) >/dev/null 2>&1

dump_database:
	@psql -q -d $(SQITCH_DBNAME) -c "DROP EXTENSION IF EXISTS pgtap;" 1> /dev/null 2>&1
	@pg_dump -s -O -x -d $(SQITCH_DBNAME) > $(DUMP_TARGET)

has_dump:
	@[ -f $(DUMP_TARGET) ] || (echo "No $(DUMP_TARGET)"; false)

dump_to_temp:
	@$(MAKE) DUMP_TARGET=/tmp/$(DUMP_TARGET).$(VERIFY_PID) dump_database

verify_dump: has_dump deploy_database dump_to_temp
ifdef CI
	@GIT_PAGER= PAGER= git diff --no-index $(DUMP_TARGET) /tmp/$(DUMP_TARGET).$(VERIFY_PID) || echo "WARNING: $(DUMP_TARGET) may be out of date (there may be PostgreSQL version differences showing)"
else
	@git diff --no-index $(DUMP_TARGET) /tmp/$(DUMP_TARGET).$(VERIFY_PID)
endif

bundle:
	@sqitch bundle

TARBALL_NAME := $(REPO_PATH)-$(TIMESTAMP).tar.gz
RELEASE_TARBALL := release/$(TARBALL_NAME)

$(RELEASE_TARBALL): bundle
	@mkdir -p release
	@tar cfz $@ -C $< .
	@rm -rf bundle
	@echo "Bundle created at $@"

release: $(RELEASE_TARBALL)

upload_release: $(RELEASE_TARBALL)
	@aws s3 cp $(RELEASE_TARBALL) s3://kcp-pkg/$(TARBALL_NAME) --region us-west-1

define SSH_CONFIG

Host *$(shell echo '${SSH_USER}' | sed 's/.*@//')*
  StrictHostKeyChecking no
	UserKnownHostsFile=/dev/null
	ForwardAgent yes
endef
export SSH_CONFIG

ssh_config:
	@echo "$$SSH_CONFIG" >> ~/.ssh/config

remote_release: ssh_config $(RELEASE_TARBALL)
	@scp $(RELEASE_TARBALL) ${SSH_USER}:.
	@ssh "${SSH_USER}" 'aws s3 cp "$(TARBALL_NAME)" "s3://kcp-pkg/$(TARBALL_NAME)" --region us-west-1'

.PHONY: all \
	test test_database \
	deploy deploy_database \
	dump dump_database verify_dump has_dump dump_to_temp \
	targets name \
	createdb dropdb resetdb \
	semaphore_cache semaphore_deps \
	release upload_release remote_bundle \
	ssh_config
