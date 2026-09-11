# Build a sequence of reference months

Offline helper that expands a range of reference months in `AAAAMM`
format. Useful to request several months from
[`caged_download()`](https://strategicprojects.github.io/cagedr/reference/caged_download.md)
or
[`caged_fetch()`](https://strategicprojects.github.io/cagedr/reference/caged_fetch.md)
without querying the server first.

## Usage

``` r
caged_periods(from, to = from)
```

## Arguments

- from, to:

  First and last reference month, as integers or strings in `AAAAMM`
  format (for example `202001` and `202612`). `to` defaults to `from`.

## Value

An integer vector of reference months, in increasing order.

## Examples

``` r
caged_periods(202301, 202306)
#> [1] 202301 202302 202303 202304 202305 202306
caged_periods("202412")
#> [1] 202412
```
