# cagedr

**cagedr** downloads and reads the public, non-identified microdata of
the **Novo CAGED** (*Cadastro Geral de Empregados e Desempregados*), the
monthly registry of formal employment movements published by the
Brazilian Ministry of Labour and Employment on the PDET FTP server.

| Function | What it does |
|:---|:---|
| [`caged_available()`](https://strategicprojects.github.io/cagedr/reference/caged_available.md) | Lists the reference months published on the server, with their modification date |
| [`caged_download()`](https://strategicprojects.github.io/cagedr/reference/caged_download.md) | Downloads the `MOV`, `FOR` and `EXC` archives of a month into an idempotent local cache |
| [`caged_read()`](https://strategicprojects.github.io/cagedr/reference/caged_read.md) | Reads a national `.7z` archive **as a stream**, filtering by state and selecting columns before anything is kept in memory |
| [`caged_fetch()`](https://strategicprojects.github.io/cagedr/reference/caged_fetch.md) | Download and read in one call, several months at once |
| [`caged_balance()`](https://strategicprojects.github.io/cagedr/reference/caged_balance.md) | Admissions, separations and net balance by reference month, applying the exclusion rule |
| [`caged_layout()`](https://strategicprojects.github.io/cagedr/reference/caged_layout.md) | The official record layout: every column, its type and meaning |

The files are national and large (about 55 MB compressed and 4 to 5
million records per month). Reading one state out of them takes 20 to 30
seconds and well under 1 GB of memory, because the archive is
decompressed on the fly and filtered chunk by chunk.

[TABLE]

## Installation

``` r

# From CRAN (when available):
install.packages("cagedr")

# Development version:
# remotes::install_github("StrategicProjects/cagedr")
```

`cagedr` reads `.7z` archives through the
[archive](https://CRAN.R-project.org/package=archive) package
(libarchive). Binaries for Windows and macOS bundle it; on Linux install
`libarchive-dev` (Debian/Ubuntu) or `libarchive-devel` (Fedora) first.

## Quick start

``` r

library(cagedr)

# Which months are on the server?
caged_available(year = 2026)

# Pernambuco (IBGE code 26), one month, the three files
pe <- caged_fetch(202607, uf = 26)
table(pe$caged_file)

# Net balance by municipality and reference month
caged_balance(pe, by = "municipio")

# A whole year, a few columns, persistent cache
Sys.setenv(CAGEDR_CACHE_DIR = "~/dados/caged")
pe_2025 <- caged_fetch(
  caged_periods(202501, 202512),
  uf = 26,
  columns = c("competenciamov", "municipio", "secao", "saldomovimentacao", "salario")
)
```

Everything that reads data can be tried offline with the sample archives
shipped in `inst/extdata`:

``` r

f <- system.file("extdata", "CAGEDMOV202301_sample.7z", package = "cagedr")
caged_read(f, uf = 26)
```

## The three monthly files

| File | Content | Note |
|:---|:---|:---|
| `CAGEDMOV<AAAAMM>.7z` | Movements declared on time for the month | The bulk of the data |
| `CAGEDFOR<AAAAMM>.7z` | Movements declared **late** | Refer to earlier `competenciamov` |
| `CAGEDEXC<AAAAMM>.7z` | **Exclusions**: cancelled movements | Sign inverted by [`caged_balance()`](https://strategicprojects.github.io/cagedr/reference/caged_balance.md) |

Because `FOR` and `EXC` carry records of earlier months, the balance of
any month keeps being revised as later archives are published. Aggregate
by `competenciamov` and recompute from all archives after each monthly
update. See
[`vignette("streaming-and-cache")`](https://strategicprojects.github.io/cagedr/articles/streaming-and-cache.md).

## Network requirements

The server is an FTP server. Outbound access to `ftp.mtps.gov.br` on
port 21 **and** to the high ports used by passive mode is required;
corporate firewalls often block one or both.
[`caged_available()`](https://strategicprojects.github.io/cagedr/reference/caged_available.md)
returns an empty tibble with a warning when the server cannot be
reached.

## Related packages

- [datacaged](https://CRAN.R-project.org/package=datacaged) downloads
  the same files from a HuggingFace mirror and loads them into DuckDB.
  `cagedr` reads from the Ministry’s server directly and filters by
  state while streaming.
- [tesouror](https://CRAN.R-project.org/package=tesouror),
  [comexr](https://CRAN.R-project.org/package=comexr) and
  [pixr](https://github.com/StrategicProjects/pixr) cover other
  Brazilian public data sources with the same conventions.

## License

MIT, see `LICENSE.md`.
