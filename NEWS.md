# cagedr 0.1.0

Initial release.

* `caged_available()` lists the reference months published on the PDET/MTE
  FTP server, with folder modification dates.
* `caged_download()` fetches the `MOV`, `FOR` and `EXC` archives of one or
  more months into an idempotent local cache (`caged_cache_dir()`,
  `caged_cache_list()`, `caged_cache_clear()`).
* `caged_read()` stream-reads a national `.7z` archive, filtering by state
  and selecting columns chunk by chunk, with normalised column names and
  typed codes; `caged_fetch()` combines download and read for several months.
* `caged_balance()` consolidates admissions, separations and net balance by
  `competenciamov`, inverting the sign of exclusion records.
* `caged_layout()` documents the 30 columns of the official record layout.
* Sample archives in `inst/extdata` allow every reading function to be tried
  offline.
