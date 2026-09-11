# Download the monthly archives of the Novo CAGED

Fetches the `.7z` archives of one or more reference months from the
PDET/MTE FTP server into the local cache (see
[`caged_cache_dir()`](https://strategicprojects.github.io/cagedr/reference/caged_cache_dir.md)).
Archives already in the cache are not downloaded again unless
`force = TRUE`.

## Usage

``` r
caged_download(
  period,
  files = c("MOV", "FOR", "EXC"),
  cache_dir = NULL,
  force = FALSE,
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

- files:

  Which files to download: any subset of `c("MOV", "FOR", "EXC")`.

- cache_dir:

  Optional cache directory (see
  [`caged_cache_dir()`](https://strategicprojects.github.io/cagedr/reference/caged_cache_dir.md)).

- force:

  Re-download archives already in the cache?

- timeout:

  Timeout in seconds for each file. The Ministry's FTP is slow at times;
  the default allows 15 minutes per file.

- verbose:

  Emit progress messages? Defaults to
  `getOption("cagedr.verbose", TRUE)`.

## Value

A tibble with one row per (`period`, `file`) and columns `period`,
`file`, `path` (local path, `NA` when not available), `status`
(`"downloaded"`, `"cached"`, `"not_found"` or `"error"`) and `url`.

## Details

Every reference month has up to three files, all national:

- `MOV` (`CAGEDMOV<AAAAMM>.7z`): movements declared on time for that
  month, the bulk of the data (about 55 MB compressed, 4 to 5 million
  records);

- `FOR` (`CAGEDFOR<AAAAMM>.7z`): movements declared **late**, which
  refer to earlier reference months (`competenciamov < AAAAMM`);

- `EXC` (`CAGEDEXC<AAAAMM>.7z`): **exclusions**, movements cancelled by
  the employer, also referring to earlier months.

The first months of the series (January to March 2020) have no `FOR` or
`EXC` files; those are reported as `not_found`, not as errors.

## See also

[`caged_read()`](https://strategicprojects.github.io/cagedr/reference/caged_read.md)
to read a downloaded archive,
[`caged_fetch()`](https://strategicprojects.github.io/cagedr/reference/caged_fetch.md)
for download and read in one call.

## Examples

``` r
# \donttest{
# Requires network access; downloads about 1 MB (the EXC file is small).
res <- tryCatch(
  caged_download(202401, files = "EXC", cache_dir = tempdir()),
  error = function(e) NULL
)
#> ℹ Downloading EXC 202401...
#> ✔ EXC 202401: 93,559 bytes.
res
#> # A tibble: 1 × 5
#>   period file  path                              status     url                 
#>    <int> <chr> <chr>                             <chr>      <chr>               
#> 1 202401 EXC   /tmp/RtmpQtVEGr/CAGEDEXC202401.7z downloaded ftp://ftp.mtps.gov.…
# }
```
