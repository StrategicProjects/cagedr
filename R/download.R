# -- Cache directory -----------------------------------------------------------

#' Cache directory used by cagedr
#'
#' Downloaded archives are stored in a local cache so that a reference month
#' is never downloaded twice. The location is resolved in this order:
#'
#' 1. the `cache_dir` argument;
#' 2. the `CAGEDR_CACHE_DIR` environment variable;
#' 3. the `cagedr.cache_dir` R option;
#' 4. a session-scoped folder under [tempdir()], which R removes when the
#'    session ends.
#'
#' Set one of the first three to keep the archives between sessions. Files
#' published by the Ministry are large (about 55 MB per month) and change
#' only when a month is re-published, so a persistent cache is recommended
#' for repeated work.
#'
#' @param cache_dir Optional path. When given, it is returned as is (after
#'   creating the folder).
#'
#' @return The cache directory path, created if needed.
#' @export
#' @examples
#' caged_cache_dir()
#' \dontrun{
#' # Persistent cache for every session:
#' Sys.setenv(CAGEDR_CACHE_DIR = "~/dados/caged")
#' }
caged_cache_dir <- function(cache_dir = NULL) {
  env <- Sys.getenv("CAGEDR_CACHE_DIR", unset = "")
  dir <- cache_dir %||%
    (if (nzchar(env)) env else NULL) %||%
    getOption("cagedr.cache_dir") %||%
    file.path(tempdir(), "cagedr-cache")
  dir <- path.expand(dir)
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  dir
}

#' List the archives currently in the cache
#'
#' @inheritParams caged_cache_dir
#' @return A tibble with columns `path`, `period`, `file` (`MOV`, `FOR` or
#'   `EXC`), `size_bytes` and `modified`.
#' @export
#' @examples
#' caged_cache_list()
caged_cache_list <- function(cache_dir = NULL) {
  dir <- caged_cache_dir(cache_dir)
  paths <- list.files(dir, pattern = "^CAGED(MOV|FOR|EXC)\\d{6}\\.7z$",
                      recursive = TRUE, full.names = TRUE)
  info <- file.info(paths)
  tibble::tibble(
    path       = paths,
    period     = vapply(paths, .detect_period, integer(1), USE.NAMES = FALSE),
    file       = vapply(paths, .detect_file, character(1), USE.NAMES = FALSE),
    size_bytes = as.numeric(info$size),
    modified   = info$mtime
  )
}

#' Remove archives from the cache
#'
#' @inheritParams caged_cache_dir
#' @param period Optional reference months (`AAAAMM`) to remove. `NULL`
#'   removes every cached archive.
#' @return Invisibly, the number of files removed.
#' @export
#' @examples
#' caged_cache_clear()
caged_cache_clear <- function(period = NULL, cache_dir = NULL) {
  cached <- caged_cache_list(cache_dir)
  if (!is.null(period)) cached <- cached[cached$period %in% .as_period(period), ]
  if (nrow(cached) > 0L) unlink(cached$path)
  invisible(nrow(cached))
}

# -- Download ------------------------------------------------------------------

#' One curl download with retries. Returns "ok", "not_found" or "error".
#' Wrapped in its own function so tests can mock it.
#' @noRd
.caged_curl_download <- function(url, destfile, timeout = 900, retries = 3L) {
  for (attempt in seq_len(retries)) {
    res <- tryCatch({
      h <- curl::new_handle(connecttimeout = 30L, timeout = timeout)
      curl::curl_download(url, destfile, handle = h, quiet = TRUE)
      "ok"
    }, error = function(e) {
      msg <- conditionMessage(e)
      if (grepl("550|RETR response|not found|does not exist", msg, ignore.case = TRUE)) {
        "not_found"
      } else {
        attr(msg, "kind") <- "error"
        msg
      }
    })
    if (identical(res, "ok") && file.exists(destfile) && file.size(destfile) > 0) return("ok")
    if (file.exists(destfile)) unlink(destfile)
    if (identical(res, "not_found")) return("not_found")
    if (attempt < retries) Sys.sleep(5 * attempt)
  }
  "error"
}

#' Download the monthly archives of the Novo CAGED
#'
#' Fetches the `.7z` archives of one or more reference months from the
#' PDET/MTE FTP server into the local cache (see [caged_cache_dir()]).
#' Archives already in the cache are not downloaded again unless
#' `force = TRUE`.
#'
#' Every reference month has up to three files, all national:
#'
#' * `MOV` (`CAGEDMOV<AAAAMM>.7z`): movements declared on time for that
#'   month, the bulk of the data (about 55 MB compressed, 4 to 5 million
#'   records);
#' * `FOR` (`CAGEDFOR<AAAAMM>.7z`): movements declared **late**, which refer
#'   to earlier reference months (`competenciamov < AAAAMM`);
#' * `EXC` (`CAGEDEXC<AAAAMM>.7z`): **exclusions**, movements cancelled by
#'   the employer, also referring to earlier months.
#'
#' The first months of the series (January to March 2020) have no `FOR` or
#' `EXC` files; those are reported as `not_found`, not as errors.
#'
#' @param period Reference months in `AAAAMM` format (integer or character
#'   vector). See [caged_periods()] and [caged_available()].
#' @param files Which files to download: any subset of `c("MOV", "FOR",
#'   "EXC")`.
#' @param cache_dir Optional cache directory (see [caged_cache_dir()]).
#' @param force Re-download archives already in the cache?
#' @param timeout Timeout in seconds for each file. The Ministry's FTP is
#'   slow at times; the default allows 15 minutes per file.
#' @param verbose Emit progress messages? Defaults to
#'   `getOption("cagedr.verbose", TRUE)`.
#'
#' @return A tibble with one row per (`period`, `file`) and columns `period`,
#'   `file`, `path` (local path, `NA` when not available), `status`
#'   (`"downloaded"`, `"cached"`, `"not_found"` or `"error"`) and `url`.
#' @export
#' @seealso [caged_read()] to read a downloaded archive, [caged_fetch()] for
#'   download and read in one call.
#' @examples
#' \donttest{
#' # Requires network access; downloads about 1 MB (the EXC file is small).
#' res <- tryCatch(
#'   caged_download(202401, files = "EXC", cache_dir = tempdir()),
#'   error = function(e) NULL
#' )
#' res
#' }
caged_download <- function(period, files = c("MOV", "FOR", "EXC"),
                           cache_dir = NULL, force = FALSE, timeout = 900,
                           verbose = NULL) {
  verbose <- .verbose(verbose)
  period  <- .as_period(period)
  files   <- match.arg(toupper(files), .caged_files, several.ok = TRUE)
  dir     <- caged_cache_dir(cache_dir)

  grid <- expand.grid(file = files, period = period, stringsAsFactors = FALSE)
  grid <- grid[order(grid$period, match(grid$file, .caged_files)), ]

  rows <- lapply(seq_len(nrow(grid)), function(i) {
    p <- grid$period[i]; f <- grid$file[i]
    url  <- .caged_url(p, f)
    dest <- file.path(dir, sprintf("CAGED%s%d.7z", f, p))
    if (file.exists(dest) && file.size(dest) > 0 && !force) {
      return(tibble::tibble(period = p, file = f, path = dest, status = "cached", url = url))
    }
    if (verbose) cli::cli_alert_info("Downloading {f} {p}...")
    st <- .caged_curl_download(url, dest, timeout = timeout)
    if (st == "ok") {
      if (verbose) {
        cli::cli_alert_success("{f} {p}: {format(file.size(dest), big.mark = ',')} bytes.")
      }
      tibble::tibble(period = p, file = f, path = dest, status = "downloaded", url = url)
    } else {
      if (verbose && st == "not_found") cli::cli_alert_warning("{f} {p}: not on the server.")
      if (st == "error") cli::cli_warn("{f} {p}: download failed after retries ({.url {url}}).")
      tibble::tibble(period = p, file = f, path = NA_character_, status = st, url = url)
    }
  })
  out <- do.call(rbind, rows)
  tibble::as_tibble(out)
}
