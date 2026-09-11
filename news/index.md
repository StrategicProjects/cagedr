# Changelog

## cagedr 0.1.0

Initial release.

- [`caged_available()`](https://strategicprojects.github.io/cagedr/reference/caged_available.md)
  lists the reference months published on the PDET/MTE FTP server, with
  folder modification dates.
- [`caged_download()`](https://strategicprojects.github.io/cagedr/reference/caged_download.md)
  fetches the `MOV`, `FOR` and `EXC` archives of one or more months into
  an idempotent local cache
  ([`caged_cache_dir()`](https://strategicprojects.github.io/cagedr/reference/caged_cache_dir.md),
  [`caged_cache_list()`](https://strategicprojects.github.io/cagedr/reference/caged_cache_list.md),
  [`caged_cache_clear()`](https://strategicprojects.github.io/cagedr/reference/caged_cache_clear.md)).
- [`caged_read()`](https://strategicprojects.github.io/cagedr/reference/caged_read.md)
  stream-reads a national `.7z` archive, filtering by state and
  selecting columns chunk by chunk, with normalised column names and
  typed codes;
  [`caged_fetch()`](https://strategicprojects.github.io/cagedr/reference/caged_fetch.md)
  combines download and read for several months.
- [`caged_balance()`](https://strategicprojects.github.io/cagedr/reference/caged_balance.md)
  consolidates admissions, separations and net balance by
  `competenciamov`, inverting the sign of exclusion records.
- [`caged_layout()`](https://strategicprojects.github.io/cagedr/reference/caged_layout.md)
  documents the 30 columns of the official record layout.
- Sample archives in `inst/extdata` allow every reading function to be
  tried offline.
