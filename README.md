# postgres_adapter [![Build Status](https://travis-ci.org/waterlink/postgres_adapter.cr.svg?branch=master)](https://travis-ci.org/waterlink/postgres_adapter.cr)

Postgres adapter for
[active_record.cr](https://github.com/waterlink/active_record.cr). Uses
[crystal-pg](https://github.com/will/crystal-pg) driver.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  postgres_adapter:
    github: waterlink/postgres_adapter.cr
    version: 0.3.0
```

## Usage

```crystal
require "active_record"
require "postgres_adapter"

class User < ActiveRecord::Model
  adapter postgres
  # ...
end
```

### Providing postgres connection details

Currently it is done through environment variables:

Either `PG_URL`:

```bash
PG_URL=postgres://<user>:<password>@<host>:<port>/<database>?sslmode=<sslmode>
```

Or by corresponding components:

```bash
PG_USER=<user>
PG_PASS=<password>
PG_HOST=<host>
PG_DATABASE=<database>
PG_SSL_MODE=<sslmode>
```

## Development

After cloning run `crystal deps` or `crystal deps update`.

Just use normal TDD cycle. To run tests use:

```bash
./bin/test
```

This will run unit test in `spec/` and integration spec in `integration/`.

## Contributing

1. Fork it ( https://github.com/waterlink/postgres_adapter.cr/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [waterlink](https://github.com/waterlink) Oleksii Fedorov - creator, maintainer
