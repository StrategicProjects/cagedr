# Download and read Novo CAGED microdata in one call

Convenience wrapper:
[`caged_download()`](https://strategicprojects.github.io/cagedr/reference/caged_download.md)
followed by
[`caged_read()`](https://strategicprojects.github.io/cagedr/reference/caged_read.md)
on every archive found, with the results stacked. Missing files (for
example `FOR`/`EXC` in early 2020) are skipped with a message.

## Usage

``` r
caged_fetch(
  period,
  uf = NULL,
  files = c("MOV", "FOR", "EXC"),
  columns = NULL,
  cache_dir = NULL,
  force = FALSE,
  types = TRUE,
  chunk_size = 500000L,
  timeout = 900,
  verbose = NULL
)
```

## Arguments

- period:

  Reference months in `AAAAMM` format (integer or character vector). See
  [`caged_periods()`](https://strategicprojects.github.io/cagedr/reference/caged_periods.md)
  and
  [`caged_available()`](https://strategicprojects.github.io/cagedr/reference/caged_available.md).

- uf:

  Optional vector of state codes to keep, as IBGE two-digit numbers (for
  example `26` for Pernambuco, `c(26, 25)` for Pernambuco and Paraiba).
  `NULL` keeps every state.

- files:

  Which files to download: any subset of `c("MOV", "FOR", "EXC")`.

- columns:

  Optional character vector of columns to keep, using the normalized
  names listed by
  [`caged_layout()`](https://strategicprojects.github.io/cagedr/reference/caged_layout.md).
  `NULL` keeps all columns. The `uf` column is always read (it is needed
  for filtering) but is only returned when requested or when `columns`
  is `NULL`.

- cache_dir:

  Optional cache directory (see
  [`caged_cache_dir()`](https://strategicprojects.github.io/cagedr/reference/caged_cache_dir.md)).

- force:

  Re-download archives already in the cache?

- types:

  Convert the numeric columns of the layout (codes, salary) to
  integer/double? If `FALSE` every column is returned as character.

- chunk_size:

  Number of lines parsed per chunk. Larger chunks are faster but use
  more memory; the default (500,000 lines) uses well under 1 GB.

- timeout:

  Timeout in seconds for each file. The Ministry's FTP is slow at times;
  the default allows 15 minutes per file.

- verbose:

  Emit progress messages? Defaults to
  `getOption("cagedr.verbose", TRUE)`.

## Value

A tibble with the records of every archive read (see
[`caged_read()`](https://strategicprojects.github.io/cagedr/reference/caged_read.md)
for the columns), or an empty tibble when nothing was available. The
attribute `"download"` holds the tibble returned by
[`caged_download()`](https://strategicprojects.github.io/cagedr/reference/caged_download.md),
so that `not_found` and `error` files can be inspected.

## Examples

``` r
# \donttest{
# Requires network access. Pernambuco, one month, the three files:
pe <- tryCatch(
  caged_fetch(202401, uf = 26, cache_dir = tempdir(), verbose = FALSE),
  error = function(e) NULL
)
if (!is.null(pe)) table(pe$caged_file)
#> 
#>   EXC   FOR   MOV 
#>   286  1635 96586 
# }
```
