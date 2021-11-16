# Custom Templates for Sqitch

We have a number of custom templates that we use for Sqitch. In the examples
below, remember that if Sqitch is not installed, the commands should run as
`./run sqitch`.

### Available Templates

The following templates are available:

- `table`: A default table creator.

  - Default columns: `inserted_at`, `updated_at`
  - Scalars: `table`, `schema`, `pktype`, `syntheticpk`, `softdelete`
  - Lists: `fk`/`ref`, `column`/`type`, `json`

- `content`: A catalog-partitioned content table generator.

  - Default columns: `id` (synthetic primary key), `catalog_id` (foreign key to
    `catalogs`), `code` (catalog-specific external reference key), and
    `revision_marker` (an indicator of the last modification), `data`,
    `images`, `urls`, `inserted_at`, `updated_at`
  - Scalars: `table`, `schema`, `pktype`, `softdelete`
  - Lists: `fk`/`ref`, `column`/`type`, `json`

- `translation`: A translation table for any table.

  - Default columns: _parent_id_ (a derived column for the parent table primary
    key), `locale`, `data`, `images`, `urls`, `inserted_at`, `updated_at`.
  - Scalars: `table`, `schema`, `pktype`, `parent_table`, `parent`,
    `syntheticpk`
  - Lists: `column`/`type`, `json`

- `join`: A join table between two (or more) other tables. The primary key (or
  a unique key if `syntheticpk` is not specified), is based on the `fk` list.

  - Scalars: `table`, `schema`, `pktype`, `syntheticpk`, `timestamps`
  - Lists: `fk`/`ref`, `column`/`type`, `json`

- `tree`: A closure table for hierarchical tree structure representation. The
  primary key (or a unique key if `syntheticpk` is not specified) is
  `ancestor_id` and `descendant_id`, which are foreign keys to the
  `parent_table`.

  - Default columns: `ancestor_id`, `descendant_id`, `generation`
  - Scalars: `table`, `schema`, `pktype`, `syntheticpk`, `parent_table`

- `enum`: An enum type generator. Creates only if not already created.
  - Scalars: `enum`
  - Lists: `label`

### Supported Scalar Variables

The scalar variables described below are not intended to be set more than
once, and unless otherwise noted, work in all templates (including the
implicit `pg` engine template).

#### `pktype`

An optional value describing the type of the primary key to be created. If
not specified, the default is `uuid`. The use of `bigserial` is recommended
over `integer`.

#### `table`

An optional value describing the name of the table to be created. This should
be specified if the name of the table is different than the name of the
`change` being added. This would be used, for example, to say that the table
being created is `items` in a change named `create_items`.

```bash
sqitch add --template content \
  create_items -n 'Table: items' \
  -r catalogs \
  -r categories \
  -s table=items
```

#### `schema`

An optional value describing the schema where the table will be created. If not
set, PostgreSQL will assume `public`.

```bash
sqitch add --template content \
  items -n 'Table: items' \
  -r catalogs \
  -r categories \
  -s schema=items
```

This can be set globally in `defaults.tmpl`:

```perl
[%- SET schema='items' UNLESS schema -%]
```

#### `parent_table`

> Used in `translation` and `tree` templates.

The name of the parent table for a translation or tree table. Defaults to the
_last_ required change identifier (`-r categories` would result in
`parent_table` being `categories`). If no requirements are specified, defaults
to `<PARENT_TABLE>`.

```bash
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

```bash
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

- `content` templates always include a `catalog_id` foreign key.
- `translation` templates do not use `fk` relations.

> These lists are not used in `translation` templates, and the contents of the
> `fk` list will be used to create the primary key constraint in `join`
> templates.

```bash
sqitch add --template content \
  item_variants -n 'Table: item_variants' \
  -r items \
  -s fk=item_id -s ref=items
```

#### `column` + `type`

The lists `column` and `type` can be used to add additional normal columns. The
`column` names the column and the `type` describes the type of the column. If
there is no matching `type`, the column is `TEXT`.

```bash
sqitch add --template content \
  item_variants -n 'Table: items' \
  -r items \
  -s column=publish_date -s type="TIMESTAMP WITHOUT TIME ZONE"
```

#### `json`

The list `json` can be used to add additional JSONB columns.

```bash
sqitch add --template content \
  items -n 'Table: items' \
  -r catalogs \
  -s json=contact
```

### Template Examples

#### Join template

Joining two tables together without any other fields or synthetic key.

```bash
sqitch add --template join product_variant_user_resources \
  -n 'Create product_variant_user_resources' \
  -r product_variants -r user_resources \
  -s fk=product_variant_id -s ref=product_variants \
  -s fk=user_resource_id -s ref=user_resources
```
