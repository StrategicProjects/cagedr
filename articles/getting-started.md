# Getting started with cagedr

## What the Novo CAGED is

The CAGED (*Cadastro Geral de Empregados e Desempregados*) is the
monthly registry of admissions and separations of formal workers in
Brazil, published by the Ministry of Labour and Employment. Since
January 2020 the series is the **Novo CAGED**, built from eSocial
declarations, and its public, non-identified microdata are published on
the PDET FTP server, one folder per reference month:

    ftp://ftp.mtps.gov.br/pdet/microdados/NOVO CAGED/<AAAA>/<AAAAMM>/
        CAGEDMOV<AAAAMM>.7z   movements declared on time
        CAGEDFOR<AAAAMM>.7z   movements declared late (earlier reference months)
        CAGEDEXC<AAAAMM>.7z   exclusions (cancelled movements)

Each file is **national**: about 55 MB compressed, 600 MB of text and 4
to 5 million records for the `MOV` file. The Ministry publishes a month
around the end of the following month and occasionally re-publishes
earlier months.

`cagedr` does three things with these files:

1.  **lists** the reference months available on the server;
2.  **downloads** them into an idempotent local cache;
3.  **reads** them as a stream, filtering by state and selecting columns
    *before* anything is kept in memory.

The third point is what makes the package useful on an ordinary laptop:
one state is typically 2 to 3 % of the national file, and you never hold
the other 97 % in memory.

## Installation

``` r

# From CRAN (when available):
install.packages("cagedr")

# Development version:
# remotes::install_github("StrategicProjects/cagedr")
```

The package reads `.7z` archives through the `archive` package, which
needs `libarchive`. It is bundled on Windows and macOS binaries; on
Linux install `libarchive-dev` (Debian/Ubuntu) or `libarchive-devel`
(Fedora) first.

## A sample archive ships with the package

Every function that reads data can be tried offline with the small
archives in `inst/extdata`, which keep the exact layout of the
Ministry’s files (accented header, `;` separator, decimal comma) for a
handful of records from Pernambuco and Bahia.

``` r

library(cagedr)

f <- system.file("extdata", "CAGEDMOV202301_sample.7z", package = "cagedr")
x <- caged_read(f, verbose = FALSE)
x
#> # A tibble: 32 × 30
#>    competenciamov regiao    uf municipio secao subclasse saldomovimentacao
#>             <int>  <int> <int>     <int> <chr> <chr>                 <int>
#>  1         202301      2    26    261160 N     8112500                  -1
#>  2         202301      2    26    261420 C     1071600                  -1
#>  3         202301      2    26    261160 S     9602501                  -1
#>  4         202301      2    26    260410 C     2512800                   1
#>  5         202301      2    26    261160 F     4120400                   1
#>  6         202301      2    26    261070 M     7112000                  -1
#>  7         202301      2    26    260290 G     4713004                   1
#>  8         202301      2    26    261160 N     7830200                   1
#>  9         202301      2    26    261160 G     4530701                  -1
#> 10         202301      2    26    260410 G     4771701                   1
#> # ℹ 22 more rows
#> # ℹ 23 more variables: cbo2002ocupacao <int>, categoria <int>,
#> #   graudeinstrucao <int>, idade <int>, horascontratuais <int>, racacor <int>,
#> #   sexo <int>, tipoempregador <int>, tipoestabelecimento <int>,
#> #   tipomovimentacao <int>, tipodedeficiencia <int>, indtrabintermitente <int>,
#> #   indtrabparcial <int>, salario <dbl>, tamestabjan <int>,
#> #   indicadoraprendiz <int>, origemdainformacao <int>, competenciadec <int>, …
```

Column names come back normalized (accents removed, lower case), the
codes are integers and the salary is a number. Two columns are added by
the package: `caged_file` tells which of the three files the record came
from and `caged_period` is the reference month of the *archive*.

``` r

caged_layout()[, c("column", "original", "type")]
#> # A tibble: 30 × 3
#>    column            original          type     
#>    <chr>             <chr>             <chr>    
#>  1 competenciamov    competênciamov    integer  
#>  2 regiao            região            integer  
#>  3 uf                uf                integer  
#>  4 municipio         município         integer  
#>  5 secao             seção             character
#>  6 subclasse         subclasse         character
#>  7 saldomovimentacao saldomovimentação integer  
#>  8 cbo2002ocupacao   cbo2002ocupação   integer  
#>  9 categoria         categoria         integer  
#> 10 graudeinstrucao   graudeinstrução   integer  
#> # ℹ 20 more rows
```

## Reading one state

Pass the two-digit IBGE code of the state in `uf`, and optionally the
columns you need. Both filters are applied chunk by chunk while the
archive is being decompressed.

``` r

pe <- caged_read(
  f,
  uf = 26,
  columns = c("competenciamov", "municipio", "secao", "saldomovimentacao", "salario"),
  verbose = FALSE
)
pe
#> # A tibble: 24 × 7
#>    competenciamov municipio secao saldomovimentacao salario caged_file
#>             <int>     <int> <chr>             <int>   <dbl> <chr>     
#>  1         202301    261160 N                    -1   1415. MOV       
#>  2         202301    261420 C                    -1    651  MOV       
#>  3         202301    261160 S                    -1   1302  MOV       
#>  4         202301    260410 C                     1   1407. MOV       
#>  5         202301    261160 F                     1   1302  MOV       
#>  6         202301    261070 M                    -1   2000  MOV       
#>  7         202301    260290 G                     1   1435  MOV       
#>  8         202301    261160 N                     1   1236. MOV       
#>  9         202301    261160 G                    -1   1205  MOV       
#> 10         202301    260410 G                     1   1350  MOV       
#> # ℹ 14 more rows
#> # ℹ 1 more variable: caged_period <int>
```

## Admissions, separations and net balance

`saldomovimentacao` is `+1` for an admission and `-1` for a separation.
Records in the exclusions file cancel a movement declared earlier, so
their sign is inverted before summing.
[`caged_balance()`](https://strategicprojects.github.io/cagedr/reference/caged_balance.md)
applies that rule and aggregates by the reference month of the movement,
`competenciamov`, plus any grouping columns you ask for:

``` r

caged_balance(x, by = "uf")
#> # A tibble: 2 × 8
#>   competenciamov    uf admissions separations   net records admission_salary
#>            <int> <int>      <int>       <int> <int>   <int>            <dbl>
#> 1         202301    26         10          14    -4      24           23969.
#> 2         202301    29          4           4     0       8           13513.
#> # ℹ 1 more variable: mean_admission_salary <dbl>
```

## Working with the server

The functions below need network access to `ftp.mtps.gov.br` (port 21
and the passive-mode data ports). They are not evaluated in this
vignette.

``` r

# Which months are published?
caged_available(year = 2026)

# Download the three files of one month into the cache
caged_download(202607)

# Download and read in one go: Pernambuco, three months, three files
pe <- caged_fetch(caged_periods(202605, 202607), uf = 26)

# Net balance by municipality and reference month
caged_balance(pe, by = "municipio")
```

By default the cache lives under
[`tempdir()`](https://rdrr.io/r/base/tempfile.html) and disappears with
the R session. For repeated work set a persistent location once:

``` r

Sys.setenv(CAGEDR_CACHE_DIR = "~/dados/caged")
caged_cache_list()
```

See
[`vignette("streaming-and-cache")`](https://strategicprojects.github.io/cagedr/articles/streaming-and-cache.md)
for the details of how files are read and cached, and for the vintage
behavior of the `FOR` and `EXC` files.
