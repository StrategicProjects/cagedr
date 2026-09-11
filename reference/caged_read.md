# Read a Novo CAGED archive as a stream

Reads the `.txt` inside a monthly `.7z` archive without extracting it to
disk and without loading the national file in memory: the text is
decompressed as a stream and parsed in chunks, and each chunk is
filtered by state and reduced to the requested columns before being
kept. This is what makes it practical to extract one state (a few
hundred thousand records) from a national file of several million
records on a modest machine.

## Usage

``` r
caged_read(
  path,
  uf = NULL,
  columns = NULL,
  types = TRUE,
  chunk_size = 500000L,
  verbose = NULL
)
```

## Arguments

- path:

  Path to a `CAGEDMOV`, `CAGEDFOR` or `CAGEDEXC` archive, as returned by
  [`caged_download()`](https://strategicprojects.github.io/cagedr/reference/caged_download.md).

- uf:

  Optional vector of state codes to keep, as IBGE two-digit numbers (for
  example `26` for Pernambuco, `c(26, 25)` for Pernambuco and Paraiba).
  `NULL` keeps every state.

- columns:

  Optional character vector of columns to keep, using the normalised
  names listed by
  [`caged_layout()`](https://strategicprojects.github.io/cagedr/reference/caged_layout.md).
  `NULL` keeps all columns. The `uf` column is always read (it is needed
  for filtering) but is only returned when requested or when `columns`
  is `NULL`.

- types:

  Convert the numeric columns of the layout (codes, salary) to
  integer/double? If `FALSE` every column is returned as character.

- chunk_size:

  Number of lines parsed per chunk. Larger chunks are faster but use
  more memory; the default (500,000 lines) uses well under 1 GB.

- verbose:

  Emit progress messages? Defaults to
  `getOption("cagedr.verbose", TRUE)`.

## Value

A tibble with the selected records and columns, plus two columns added
by the package: `caged_file` (`"MOV"`, `"FOR"` or `"EXC"`, detected from
the archive name) and `caged_period` (the reference month of the
**archive**, which for `FOR` and `EXC` differs from the `competenciamov`
of the records). Column names are normalised: accents removed and lower
case (`competenciamov`, `municipio`, `salario`). Returns an empty tibble
when no record matches.

## See also

[`caged_layout()`](https://strategicprojects.github.io/cagedr/reference/caged_layout.md)
for the meaning of every column,
[`caged_fetch()`](https://strategicprojects.github.io/cagedr/reference/caged_fetch.md)
for download and read in one call.

## Examples

``` r
# A small sample archive ships with the package (Pernambuco and Bahia rows).
f <- system.file("extdata", "CAGEDMOV202301_sample.7z", package = "cagedr")
x <- caged_read(f, verbose = FALSE)
dim(x)
#> [1] 32 30

# One state, a few columns
pe <- caged_read(f, uf = 26,
                 columns = c("competenciamov", "municipio", "saldomovimentacao", "salario"),
                 verbose = FALSE)
pe
#> # A tibble: 24 × 6
#>    competenciamov municipio saldomovimentacao salario caged_file caged_period
#>             <int>     <int>             <int>   <dbl> <chr>             <int>
#>  1         202301    261160                -1   1415. MOV              202301
#>  2         202301    261420                -1    651  MOV              202301
#>  3         202301    261160                -1   1302  MOV              202301
#>  4         202301    260410                 1   1407. MOV              202301
#>  5         202301    261160                 1   1302  MOV              202301
#>  6         202301    261070                -1   2000  MOV              202301
#>  7         202301    260290                 1   1435  MOV              202301
#>  8         202301    261160                 1   1236. MOV              202301
#>  9         202301    261160                -1   1205  MOV              202301
#> 10         202301    260410                 1   1350  MOV              202301
#> # ℹ 14 more rows
```
