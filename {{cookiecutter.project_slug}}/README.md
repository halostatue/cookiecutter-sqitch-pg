# Sqitch pg Schema Management for `{{ cookiecutter.project_slug }}`

## Deploying Migrations

Most of the time, migrations will be deployed using the included `Makefile`.

```bash
make            # Same as `make test`
make deploy     # Deploys to the Sqitch target
make test       # Deploys to the Sqitch target then runs schema unit tests.
make dump       # Dumps the current Sqitch target database schema
make clean_dump # Dumps a clean version of the Sqitch schema
```

By default, these will run against the [Sqitch][] target in `$SQITCH_TARGET`,
`$MIX_ENV`, `$RAILS_ENV`, or the default target (`development` or `dev`; see the
`sqitch.conf`). There are also additional targets.

It is also possible to run Sqitch directly:

```bash
sqitch deploy dev   # or ./run sqitch deploy dev
sqitch deploy test  # or ./run sqitch deploy dev
```

## Running `sqitch`, `pg_prove`, and Database Commands

This repository no longer requires Sqitch or [pgTAP][] be installed on the local
system. All example command-lines in this documentation use `sqitch`, but if
Sqitch is not installed on the local system, use `./run sqitch`.

### `run`

The `run` script will run `sqitch`, `pg_prove` and other PostgreSQL client tools
using a Docker image (`kineticcafe/sqitch-pgtap`).

- `./run sh`: A shell inside the Docker image. The repository is in `/repo`.
- `./run sqitch`: The Sqitch executable.
- `./run pg_prove`: The `pg_prove` (pgTAP) runner; the same as `./run pgtap pg_prove`.
- `./run pgtap`: A helper around pgtap. Accepts four subcommands:

  - `install`: Installs pgTAP
  - `uninstall`: Uninstalls pgTAP
  - `pg_prove`: Runs `pg_prove`
  - `test`: Installs pgTAP, runs `pg_prove`, and then uninstalls pgTAP.

The following PostgreSQL command-line functions are also enabled by running
`./run COMMAND`:

- `createdb`
- `dropdb`
- `pg_archivecleanup`
- `pg_basebackup`
- `pg_config`
- `pg_controldata`
- `pg_ctl`
- `pg_dump`
- `pg_dumpall`
- `pg_isready`
- `pg_receivexlog`
- `pg_recvlogical`
- `pg_resetxlog`
- `pg_restore`
- `pg_rewind`
- `pg_standby`
- `pg_test_fsync`
- `pg_test_timing`
- `pg_upgrade`
- `pg_xlogdump`
- `psql`

## Adding New Migrations

The default `sqitch add` command works well enough, but we provide additional
templates to speed up development of certain common patterns. See
[Templates.md](Templates.md) for more details.

[pgtap]: https://pgtap.org
[sqitch]: https://sqitch.org
