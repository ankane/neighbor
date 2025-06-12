## 0.6.0 (2025-06-12)

- Added support for MariaDB 11.8
- Dropped experimental support for MariaDB 11.7
- Dropped support for Ruby < 3.2 and Active Record < 7.1

## 0.5.2 (2025-01-05)

- Improved support for Postgres arrays

## 0.5.1 (2024-12-03)

- Added experimental support for MariaDB 11.7
- Dropped experimental support for MariaDB 11.6 Vector

## 0.5.0 (2024-10-07)

- Added experimental support for SQLite (sqlite-vec)
- Added experimental support for MariaDB 11.6 Vector
- Added experimental support for MySQL 9
- Changed `normalize` option to use Active Record normalization
- Fixed connection leasing for Active Record 7.2
- Dropped support for Active Record < 7

## 0.4.3 (2024-09-02)

- Added `rrf` method

## 0.4.2 (2024-08-27)

- Fixed error with `nil` values

## 0.4.1 (2024-08-26)

- Added `precision` option
- Added support for `bit` dimensions to model generator
- Fixed error with Numo arrays

## 0.4.0 (2024-06-25)

- Added support for `halfvec` and `sparsevec` types
- Added support for `taxicab`, `hamming`, and `jaccard` distances with `vector` extension
- Added deserialization for `cube` and `vector` columns without `has_neighbor`
- Added support for composite primary keys
- Changed `nearest_neighbors` to replace previous `order` scopes
- Changed `normalize` option to use `before_save` callback
- Changed dimensions and finite values checks to use Active Record validations
- Fixed issue with `nearest_neighbors` scope overriding `select` values
- Removed default attribute name
- Dropped support for Ruby < 3.1

## 0.3.2 (2023-12-12)

- Added deprecation warning for `has_neighbors` without an attribute name
- Added deprecation warning for `nearest_neighbors` without an attribute name

## 0.3.1 (2023-09-25)

- Added support for passing multiple attributes to `has_neighbors`
- Fixed error with `nearest_neighbors` scope with Ruby 3.2 and Active Record 6.1

## 0.3.0 (2023-07-24)

- Dropped support for Ruby < 3 and Active Record < 6.1

## 0.2.3 (2023-04-02)

- Added support for dimensions to model generator

## 0.2.2 (2022-07-13)

- Added support for configurable attribute name
- Added support for multiple attributes per model

## 0.2.1 (2021-12-15)

- Added support for Active Record 7

## 0.2.0 (2021-04-21)

- Added support for pgvector
- Added `normalize` option
- Made `dimensions` optional
- Raise an error if `nearest_neighbors` already defined
- Raise an error for non-finite values
- Fixed NaN with zero vectors and cosine distance

Breaking changes

- The `distance` option has been moved from `has_neighbors` to `nearest_neighbors`, and there is no longer a default

## 0.1.2 (2021-02-21)

- Added `nearest_neighbors` scope

## 0.1.1 (2021-02-16)

- Fixed `Could not dump table` error

## 0.1.0 (2021-02-15)

- First release
