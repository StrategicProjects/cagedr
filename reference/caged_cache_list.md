# List the archives currently in the cache

List the archives currently in the cache

## Usage

``` r
caged_cache_list(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Optional path. When given, it is returned as is (after creating the
  folder).

## Value

A tibble with columns `path`, `period`, `file` (`MOV`, `FOR` or `EXC`),
`size_bytes` and `modified`.

## Examples

``` r
caged_cache_list()
#> # A tibble: 0 × 5
#> # ℹ 5 variables: path <chr>, period <int>, file <chr>, size_bytes <dbl>,
#> #   modified <dttm>
```
