#' List the reference months published on the PDET/MTE FTP server
#'
#' Queries the public FTP server of the Ministry of Labour and Employment and
#' returns the reference months (`AAAAMM`) of the Novo CAGED that are
#' currently published, with the date each folder was last modified. The
#' Ministry publishes a reference month around the end of the following
#' month, and occasionally re-publishes earlier months.
#'
#' @param year Optional integer vector of years to restrict the listing
#'   (for example `2025:2026`). `NULL` (the default) lists every year since
#'   2020.
#' @param timeout Connection timeout in seconds for each FTP request.
#' @param verbose Emit progress messages? Defaults to
#'   `getOption("cagedr.verbose", TRUE)`.
#'
#' @return A tibble with one row per reference month and columns `period`
#'   (integer `AAAAMM`), `year`, `month`, `modified` (`POSIXct`, folder
#'   modification time on the server) and `url` (the folder URL). Sorted
#'   from the most recent to the oldest month. Returns an empty tibble, with
#'   a warning, when the server cannot be reached.
#' @export
#' @seealso [caged_download()] to fetch the files of a month,
#'   [caged_periods()] to build a sequence of months offline.
#' @examples
#' \donttest{
#' # Requires network access to ftp.mtps.gov.br
#' months <- tryCatch(caged_available(year = 2026), error = function(e) NULL)
#' if (!is.null(months)) head(months)
#' }
caged_available <- function(year = NULL, timeout = 30, verbose = NULL) {
  verbose <- .verbose(verbose)
  empty <- tibble::tibble(period = integer(), year = integer(), month = integer(),
                          modified = as.POSIXct(character()), url = character())

  base <- .caged_ftp_base   # local: cli reads a leading dot as a style
  root <- .ftp_listing(base, timeout = timeout)
  if (is.null(root)) {
    cli::cli_warn(c(
      "Could not reach the PDET/MTE FTP server ({.url {base}}).",
      "i" = "Outbound FTP (port 21 plus passive-mode ports) may be blocked on this network."
    ))
    return(empty)
  }
  years <- .parse_ftp_listing(root)
  years <- years$name[years$is_dir & grepl("^\\d{4}$", years$name)]
  years <- as.integer(years)
  if (!is.null(year)) years <- intersect(years, as.integer(year))
  years <- sort(years)
  if (length(years) == 0L) return(empty)

  rows <- lapply(years, function(y) {
    txt <- .ftp_listing(paste0(.caged_ftp_base, "/", y), timeout = timeout)
    if (is.null(txt)) return(NULL)
    e <- .parse_ftp_listing(txt)
    e <- e[e$is_dir & grepl("^\\d{6}$", e$name), , drop = FALSE]
    if (nrow(e) == 0L) return(NULL)
    tibble::tibble(
      period   = as.integer(e$name),
      modified = e$modified,
      url      = paste0(.caged_ftp_base, "/", y, "/", e$name)
    )
  })
  out <- do.call(rbind, rows)
  if (is.null(out) || nrow(out) == 0L) return(empty)

  out$year  <- out$period %/% 100L
  out$month <- out$period %% 100L
  out <- out[order(-out$period), c("period", "year", "month", "modified", "url")]
  if (verbose) {
    cli::cli_alert_success(
      "{nrow(out)} reference month{?s} on the server ({min(out$period)} to {max(out$period)})."
    )
  }
  tibble::as_tibble(out)
}

#' Build a sequence of reference months
#'
#' Offline helper that expands a range of reference months in `AAAAMM`
#' format. Useful to request several months from [caged_download()] or
#' [caged_fetch()] without querying the server first.
#'
#' @param from,to First and last reference month, as integers or strings in
#'   `AAAAMM` format (for example `202001` and `202612`). `to` defaults to
#'   `from`.
#'
#' @return An integer vector of reference months, in increasing order.
#' @export
#' @examples
#' caged_periods(202301, 202306)
#' caged_periods("202412")
caged_periods <- function(from, to = from) {
  .period_seq(from, to)
}
