# Remove archives from the cache

Remove archives from the cache

## Usage

``` r
caged_cache_clear(period = NULL, cache_dir = NULL)
```

## Arguments

- period:

  Optional reference months (`AAAAMM`) to remove. `NULL` removes every
  cached archive.

- cache_dir:

  Optional path. When given, it is returned as is (after creating the
  folder).

## Value

Invisibly, the number of files removed.

## Examples

``` r
caged_cache_clear()
```
