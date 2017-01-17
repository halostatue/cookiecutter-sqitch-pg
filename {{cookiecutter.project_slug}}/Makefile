# Note: this Makefile depends on some GNU Make extensions.

test: test_database verify_dump
deploy: deploy_database
dump: deploy_database dump_database

SQITCH_TARGET := $(shell sqitch config --get engine.pg.target)
SQITCH_DBNAME := $(shell sqitch config --get target.$(SQITCH_TARGET).uri | sed -e 's/^db:pg://')
VERIFY_PID = $(shell echo "$${PPID}")
DUMP_TARGET = structure.sql

name:
	@echo $(SQITCH_DBNAME)

test_database: deploy_database
	@pg_prove -d $(SQITCH_DBNAME) test/*.sql

deploy_database:
	@sqitch deploy $(SQITCH_TARGET); true
	@sqitch status $(SQITCH_TARGET) >/dev/null 2>&1

dump_database:
	@psql -q -d $(SQITCH_DBNAME) -c "DROP EXTENSION IF EXISTS pgtap;" 2> /dev/null
	@pg_dump -s -O -x -d $(SQITCH_DBNAME) > $(DUMP_TARGET)

has_dump:
	@[ -f $(DUMP_TARGET) ] || (echo "No $(DUMP_TARGET)"; false)

dump_to_temp:
	@make DUMP_TARGET=/tmp/$(DUMP_TARGET).$(VERIFY_PID) dump_database

verify_dump: has_dump deploy_database dump_to_temp
ifdef CI
	@GIT_PAGER= PAGER= git diff --no-index $(DUMP_TARGET) /tmp/$(DUMP_TARGET).$(VERIFY_PID) || (echo "WARNING: $(DUMP_TARGET) may be out of date (or there are PostgreSQL version differences showing)"; true)
else
	@git diff --no-index $(DUMP_TARGET) /tmp/$(DUMP_TARGET).$(VERIFY_PID)
endif
