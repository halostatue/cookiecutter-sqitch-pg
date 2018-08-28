# Sqitch pg Schema Management for `{{ cookiecutter.project_slug }}`

## Installation

Sqitch must be installed to use it; pgTAP is recommended for running unit
tests. Both Sqitch and pgTAP can be installed with `./setup.sh` (`sudo
./setup.sh` on Linux).

### Linux

```
sudo apt-get install libdbd-pg-perl postgresql-client cpanminus
sudo cpanm --quiet --notest App::Sqitch Template
```

### Mac OS X

```
brew tap theory/sqitch
brew install sqitch_pg cpanminus
cpanm --quiet --notest -l $(brew --prefix) Template
```

Note that the Homebrew packages for `sqitch_pg` and `pgtap` have a conflict on
the Perl package `DBD::Pg`. If installing both, use these instructions instead:

```
brew tap theory/sqitch
brew install sqitch pgtap cpanminus
cpanm --quiet --notest -l $(brew --prefix) Template
```

## Deploying Migrations

```
sqitch deploy development
sqitch deploy test
```

Targets defined in sqitch.conf are "development" and "test".

## Adding New Migrations

The default `sqitch add` command works well, but we provide additional
templates to speed up development of certain common patterns.

### Available Templates

The following templates are available:

* `table`: A default table creator.
  * Default columns: `inserted_at`, `updated_at`
  * Scalars: `table`, `schema`, `pktype`, `syntheticpk`, `softdelete`
  * Lists: `fk`/`ref`, `column`/`type`, `json`

* `content`: A catalog-partitioned content table generator.
  * Default columns: `id` (synthetic primary key), `catalog_id` (foreign key to
    `catalogs`), `code` (catalog-specific external reference key), and
    `revision_marker` (an indicator of the last modification), `data`,
    `images`, `urls`, `inserted_at`, `updated_at`
  * Scalars: `table`, `schema`, `pktype`, `softdelete`
  * Lists: `fk`/`ref`, `column`/`type`, `json`

* `translation`: A translation table for any table.
  * Default columns: *parent_id* (a derived column for the parent table primary
    key), `locale`, `data`, `images`, `urls`, `inserted_at`, `updated_at`.
  * Scalars: `table`, `schema`, `pktype`, `parent_table`, `parent`,
    `syntheticpk`
  * Lists: `column`/`type`, `json`

* `join`: A join table between two (or more) other tables. The primary key (or
  a unique key if `syntheticpk` is not specified), is based on the `fk` list.
  * Scalars: `table`, `schema`, `pktype`, `syntheticpk`, `timestamps`
  * Lists: `fk`/`ref`, `column`/`type`, `json`

* `tree`: A closure table for hierarchical tree structure representation. The
  primary key (or a unique key if `syntheticpk` is not specified) is
  `ancestor_id` and `descendant_id`, which are foreign keys to the
  `parent_table`.
  * Default columns: `ancestor_id`, `descendant_id`, `generation`
  * Scalars: `table`, `schema`, `pktype`, `syntheticpk`, `parent_table`

* `enum`: An enum type generator. Creates only if not already created.
  * Scalars: `enum`
  * Lists: `label`

### Supported Scalar Variables

The scalar variables described below are not intended to be set more than once,
and unless otherwise noted, work in all templates (including the implicit `pg`
engine template).

#### `pktype`

An optional value describing the type of the primary key to be created. If not
specified, the default is `uuid`. The use of `bigserial` is recommended over
`integer`.

#### `table`

An optional value describing the name of the table to be created. This should
be specified if the name of the table is different than the name of the
`change` being added. This would be used, for example, to say that the table
being created is `items` in a change named `create_items`.

```
sqitch add --template content \
  create_items -n 'Table: items' \
  -r catalogs \
  -r categories \
  -s table=items
```

#### `schema`

An optional value describing the schema where the table will be created. If not
set, PostgreSQL will assume `public`.

```
sqitch add --template content \
  items -n 'Table: items' \
  -r catalogs \
  -r categories \
  -s schema=items
```

This can be set globally in `defaults.tmpl`:

```
[%- SET schema='items' UNLESS schema -%]
```

#### `parent_table`

> Used in `translation` and `tree` templates.

The name of the parent table for a translation or tree table. Defaults to the
*last* required change identifier (`-r categories` would result in
`parent_table` being `categories`). If no requirements are specified, defaults
to `<PARENT_TABLE>`.

```
sqitch add --template translation \
  item_translations -n 'Table: item_translations' \
  -r items \
  -s parent_table=items
```

#### `parent`

> Used in `translation` templates.

The name of the parent object for a translation. Used to construct a
`parent_id`. The parent id will be shown as `<PARENT_TABLE_ID>` if not
otherwise set.

```
sqitch add --template translation \
  item_translations -n 'Table: item_translations' \
  -r items \
  -s parent=item
```

#### `syntheticpk`

This creates a synthetic primary key for the table being generated if one would
not otherwise be generated.

> `content` templates always use synthetic primary keys.

In addition to the synthetic primary key `id`, `join` and `translation`
templates generate a unique constraint to emulate the effect of a natural
compound primary key. On `join` templates, this constraint is on all provided
foreign keys; on `translation` templates, it is on the `parent_id` and
`locale`.

#### `softdelete`

> Used in `content` and `table` templates.

Creates a `deleted_at` timestamp column for use with systems that recognize
soft-deletion. The default is set to `0001-01-01` in order to permit a single
`deleted_at` index, not partial indexes.

#### `timestamps`

> Used in `join` templates.

Creates `inserted_at` and `updated_at` timestamp columns.

### Supported List Variables

#### `fk` + `ref`

The lists `fk` and `ref` can be used to add foreign keys. The `fk` names the
column holding the foreign key, and the corresponding `ref` instance names the
table the key references. If there is no matching `ref`, the value is written
as `<TABLE>`.

* `content` templates always include a `catalog_id` foreign key.
* `translation` templates do not use `fk` relations.

> These lists are not used in `translation` templates, and the contents of the
> `fk` list will be used to create the primary key constraint in `join`
> templates.

```
sqitch add --template content \
  item_variants -n 'Table: item_variants' \
  -r items \
  -s fk=item_id -s ref=items
```

#### `column` + `type`

The lists `column` and `type` can be used to add additional normal columns. The
`column` names the column and the `type` describes the type of the column. If
there is no matching `type`, the column is `TEXT`.

```
sqitch add --template content \
  item_variants -n 'Table: items' \
  -r items \
  -s column=publish_date -s type="TIMESTAMP WITHOUT TIME ZONE"
```

#### `json`

The list `json` can be used to add additional JSONB columns.

```
sqitch add --template content \
  items -n 'Table: items' \
  -r catalogs \
  -s json=contact
```

### Template Examples

#### Join template

Joining two tables together without any other fields or synthetic key.

```
sqitch add --template join product_variant_user_resources \
  -n 'Create product_variant_user_resources' \
  -r product_variants -r user_resources \
  -s fk=product_variant_id -s ref=product_variants \
  -s fk=user_resource_id -s ref=user_resources
```

## Makefile

The included `Makefile` provides three primary Sqitch-related targets:

*   `deploy`: Deploy to `SQITCH_TARGET`.
*   `test`: Deploys, then runs unit tests with `pg_prove` against
    `SQITCH_DBNAME`. See [Unit Tests with pgTAP](#unit-tests-with-pgtap)
    for more information.
*   `dump`: Deploys, then runs `pg_dump` against `SQITCH_DBNAME`. This
    should be run when change development is complete prior to pull
    request submission.

There are three additional database helpers, `createdb`, `dropdb`, and
`resetdb`. These will create, drop, and drop-then-create the `SQITCH_DBNAME`
for the target.

There are two configuration variables:

*   `SQITCH_TARGET`: the defined target, defaulting to `development`
*   `SQITCH_DBNAME`: the name of the database to use, defaulting to the
    URI of the `SQITCH_TARGET`.

## Unit Tests with pgTAP

There are unit tests (defined with [pgTAP][]) defined in the `test`
directories, and added for each Sqitch change created. To run these, pgTAP
must be installed.

### Linux

An older version (0.95) of pgTAP may be installed on Ubuntu (16.04) as
`postgresql-9.5-pgtap`; Ubuntu 12.04 and 14.04 do not have packages for
pgTAP.

### Mac OS X

A current version may be installed from Homebrew, but has a conflict with
`sqitch_pg` on the Perl package `DBD::Pg`. If you have previously installed
`sqitch_pg`, it must be uninstalled. Again, this will be handled automatically
by `./setup.sh`.

```
brew uninstall sqitch_pg
brew install pgtap
```

[Sequel]: http://sequel.jeremyevans.net/
[application-use]: #using-constraint-validations-in-an-application
[pgTAP]: http://pgtap.org
