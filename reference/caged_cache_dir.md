# Cache directory used by cagedr

Downloaded archives are stored in a local cache so that a reference
month is never downloaded twice. The location is resolved in this order:

## Usage

``` r
caged_cache_dir(cache_dir = NULL)
```

## Arguments

- cache_dir:

  Optional path. When given, it is returned as is (after creating the
  folder).

## Value

The cache directory path, created if needed.

## Details

1.  the `cache_dir` argument;

2.  the `CAGEDR_CACHE_DIR` environment variable;

3.  the `cagedr.cache_dir` R option;

4.  a session-scoped folder under
    [`tempdir()`](https://rdrr.io/r/base/tempfile.html), which R removes
    when the session ends.

Set one of the first three to keep the archives between sessions. Files
published by the Ministry are large (about 55 MB per month) and change
only when a month is re-published, so a persistent cache is recommended
for repeated work.

## Examples

``` r
caged_cache_dir()
#> [1] "/tmp/RtmprUHn4y/cagedr-cache"
if (FALSE) { # \dontrun{
# Persistent cache for every session:
Sys.setenv(CAGEDR_CACHE_DIR = "~/dados/caged")
} # }
```
