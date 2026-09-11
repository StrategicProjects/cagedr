# Consolidate admissions, separations and net balance

Applies the accounting rule of the Novo CAGED to a set of records read
with
[`caged_read()`](https://strategicprojects.github.io/cagedr/reference/caged_read.md)
or
[`caged_fetch()`](https://strategicprojects.github.io/cagedr/reference/caged_fetch.md)
and aggregates them. Movements declared on time (`MOV`) and late (`FOR`)
count with their own sign; **exclusions** (`EXC`) cancel a previously
declared movement, so their `saldomovimentacao` is inverted before
summing. The aggregation is always by `competenciamov`, the reference
month of the movement, which is what the Ministry's published totals
use.

## Usage

``` r
caged_balance(data, by = NULL)
```

## Arguments

- data:

  A tibble returned by
  [`caged_read()`](https://strategicprojects.github.io/cagedr/reference/caged_read.md)
  or
  [`caged_fetch()`](https://strategicprojects.github.io/cagedr/reference/caged_fetch.md).
  Must contain `competenciamov`, `saldomovimentacao` and `caged_file`.

- by:

  Character vector of additional grouping columns (for example
  `"municipio"`, `"uf"`, `"secao"`). `competenciamov` is always
  included.

## Value

A tibble with the grouping columns and `admissions` (records with
positive sign after the exclusion rule), `separations` (negative sign),
`net` (`admissions - separations`) and `records` (number of records
aggregated). When the data contain `salario`, also `admission_salary`
(sum of the salaries of the admissions) and `mean_admission_salary`.

## Details

Because `FOR` and `EXC` archives of month *M* carry records of earlier
months, the balance of a given month keeps changing as later archives
are published. To reproduce the Ministry's figure for a month, read
every archive published up to the date of interest.

## Examples

``` r
f <- system.file("extdata", "CAGEDMOV202301_sample.7z", package = "cagedr")
x <- caged_read(f, verbose = FALSE)
caged_balance(x, by = "uf")
#> # A tibble: 2 × 8
#>   competenciamov    uf admissions separations   net records admission_salary
#>            <int> <int>      <int>       <int> <int>   <int>            <dbl>
#> 1         202301    26         10          14    -4      24           23969.
#> 2         202301    29          4           4     0       8           13513.
#> # ℹ 1 more variable: mean_admission_salary <dbl>
```
