# List the reference months published on the PDET/MTE FTP server

Queries the public FTP server of the Ministry of Labour and Employment
and returns the reference months (`AAAAMM`) of the Novo CAGED that are
currently published, with the date each folder was last modified. The
Ministry publishes a reference month around the end of the following
month, and occasionally re-publishes earlier months.

## Usage

``` r
caged_available(year = NULL, timeout = 30, verbose = NULL)
```

## Arguments

- year:

  Optional integer vector of years to restrict the listing (for example
  `2025:2026`). `NULL` (the default) lists every year since 2020.

- timeout:

  Connection timeout in seconds for each FTP request.

- verbose:

  Emit progress messages? Defaults to
  `getOption("cagedr.verbose", TRUE)`.

## Value

A tibble with one row per reference month and columns `period` (integer
`AAAAMM`), `year`, `month`, `modified` (`POSIXct`, folder modification
time on the server) and `url` (the folder URL). Sorted from the most
recent to the oldest month. Returns an empty tibble, with a warning,
when the server cannot be reached.

## See also

[`caged_download()`](https://strategicprojects.github.io/cagedr/reference/caged_download.md)
to fetch the files of a month,
[`caged_periods()`](https://strategicprojects.github.io/cagedr/reference/caged_periods.md)
to build a sequence of months offline.

## Examples

``` r
# \donttest{
# Requires network access to ftp.mtps.gov.br
months <- tryCatch(caged_available(year = 2026), error = function(e) NULL)
#> ✔ 7 reference months on the server (202601 to 202607).
if (!is.null(months)) head(months)
#> # A tibble: 6 × 5
#>   period  year month modified            url                                    
#>    <int> <int> <int> <dttm>              <chr>                                  
#> 1 202607  2026     7 2026-08-28 14:31:00 ftp://ftp.mtps.gov.br/pdet/microdados/…
#> 2 202606  2026     6 2026-07-29 14:33:00 ftp://ftp.mtps.gov.br/pdet/microdados/…
#> 3 202605  2026     5 2026-06-30 14:21:00 ftp://ftp.mtps.gov.br/pdet/microdados/…
#> 4 202604  2026     4 2026-06-16 14:54:00 ftp://ftp.mtps.gov.br/pdet/microdados/…
#> 5 202603  2026     3 2026-06-16 14:53:00 ftp://ftp.mtps.gov.br/pdet/microdados/…
#> 6 202602  2026     2 2026-06-16 14:52:00 ftp://ftp.mtps.gov.br/pdet/microdados/…
# }
```
