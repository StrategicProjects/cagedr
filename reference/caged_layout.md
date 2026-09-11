# Record layout of the Novo CAGED microdata

The columns of the monthly files, with the original (accented) name used
by the Ministry, the normalized name returned by
[`caged_read()`](https://strategicprojects.github.io/cagedr/reference/caged_read.md),
the type assigned when `types = TRUE`, the files in which the column
appears and a short description. The official layout (the "Layout
Nao-identificado Novo Caged Movimentacao" spreadsheet) is published in
the same FTP folder as the data.

## Usage

``` r
caged_layout()
```

## Value

A tibble with columns `column` (normalized name), `original` (name in
the file), `type`, `files` and `description`.

## Details

Two columns exist only in the exclusions file (`EXC`): `competenciaexc`
and `indicadordeexclusao`.

## Examples

``` r
caged_layout()
#> # A tibble: 30 × 5
#>    column            original          type      files         description      
#>    <chr>             <chr>             <chr>     <chr>         <chr>            
#>  1 competenciamov    competênciamov    integer   MOV, FOR, EXC Reference month …
#>  2 regiao            região            integer   MOV, FOR, EXC IBGE region code…
#>  3 uf                uf                integer   MOV, FOR, EXC IBGE state code …
#>  4 municipio         município         integer   MOV, FOR, EXC IBGE municipalit…
#>  5 secao             seção             character MOV, FOR, EXC CNAE 2.0 section…
#>  6 subclasse         subclasse         character MOV, FOR, EXC CNAE 2.0 subclas…
#>  7 saldomovimentacao saldomovimentação integer   MOV, FOR, EXC +1 for an admiss…
#>  8 cbo2002ocupacao   cbo2002ocupação   integer   MOV, FOR, EXC Occupation code …
#>  9 categoria         categoria         integer   MOV, FOR, EXC Worker category …
#> 10 graudeinstrucao   graudeinstrução   integer   MOV, FOR, EXC Education level …
#> # ℹ 20 more rows
subset(caged_layout(), files != "MOV, FOR, EXC")
#> # A tibble: 2 × 5
#>   column              original            type    files description             
#>   <chr>               <chr>               <chr>   <chr> <chr>                   
#> 1 competenciaexc      competênciaexc      integer EXC   Month in which the excl…
#> 2 indicadordeexclusao indicadordeexclusão integer EXC   Exclusion indicator (1 …
```
