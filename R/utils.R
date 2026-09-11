# Internal utilities for cagedr. Nothing here is exported.

# -- Constants -----------------------------------------------------------------

#' Base URL of the PDET/MTE FTP folder for the Novo CAGED (2020 onwards).
#' The folder name contains a space ("NOVO CAGED"), hence the %20.
#' @noRd
.caged_ftp_base <- "ftp://ftp.mtps.gov.br/pdet/microdados/NOVO%20CAGED"

#' The three monthly files published for every reference month.
#' @noRd
.caged_files <- c("MOV", "FOR", "EXC")

#' First reference month of the Novo CAGED series.
#' @noRd
.caged_first_period <- 202001L

# -- Verbosity -----------------------------------------------------------------

#' Are progress messages enabled? Controlled by `options(cagedr.verbose)`.
#' @noRd
.verbose <- function(verbose = NULL) {
  verbose %||% getOption("cagedr.verbose", TRUE)
}

# -- Periods -------------------------------------------------------------------

#' Validate and normalise reference months given as `AAAAMM` (integer or
#' character). Returns an integer vector.
#' @noRd
.as_period <- function(x, arg = "period") {
  if (is.null(x) || length(x) == 0L) {
    cli::cli_abort("{.arg {arg}} must have at least one reference month.")
  }
  p <- suppressWarnings(as.integer(as.character(x)))
  bad <- is.na(p) | p %/% 100L < 1900L | p %% 100L < 1L | p %% 100L > 12L
  if (any(bad)) {
    cli::cli_abort(c(
      "{.arg {arg}} must be reference months in {.code AAAAMM} format.",
      "x" = "Invalid value{?s}: {.val {x[bad]}}."
    ))
  }
  first <- .caged_first_period   # local: cli reads a leading dot as a style
  if (any(p < first)) {
    early <- p[p < first]
    cli::cli_abort(c(
      "The Novo CAGED series starts in {.val {first}}.",
      "x" = "Earlier month{?s} requested: {.val {early}}."
    ))
  }
  p
}

#' Sequence of reference months (AAAAMM) between two months, inclusive.
#' @noRd
.period_seq <- function(from, to) {
  from <- .as_period(from, "from")
  to   <- .as_period(to, "to")
  if (to < from) cli::cli_abort("{.arg to} ({to}) is earlier than {.arg from} ({from}).")
  d <- seq(as.Date(sprintf("%d-%02d-01", from %/% 100L, from %% 100L)),
           as.Date(sprintf("%d-%02d-01", to %/% 100L, to %% 100L)),
           by = "month")
  as.integer(format(d, "%Y%m"))
}

# -- URLs ----------------------------------------------------------------------

#' URL of one monthly archive on the FTP server.
#' @noRd
.caged_url <- function(period, file = "MOV") {
  file <- match.arg(toupper(file), .caged_files)
  sprintf("%s/%d/%d/CAGED%s%d.7z", .caged_ftp_base, period %/% 100L, period, file, period)
}

# -- FTP listing ---------------------------------------------------------------

#' Fetch the raw text of an FTP directory listing. Returns NULL when the
#' directory does not exist or the server is unreachable.
#' @noRd
.ftp_listing <- function(url, timeout = 30) {
  h <- curl::new_handle(connecttimeout = timeout, timeout = timeout * 4)
  res <- tryCatch(curl::curl_fetch_memory(paste0(url, "/"), handle = h),
                  error = function(e) NULL)
  if (is.null(res) || res$status_code >= 400L) return(NULL)
  # The server root has file names in Latin-1: decode before splitting.
  iconv(rawToChar(res$content), from = "latin1", to = "UTF-8", sub = "?")
}

#' Parse an IIS-style FTP listing (`MM-DD-YY HH:MMAM <DIR> name` or
#' `MM-DD-YY HH:MMAM size name`) into a tibble of entries.
#' @noRd
.parse_ftp_listing <- function(txt) {
  lines <- strsplit(txt %||% "", "\r?\n")[[1]]
  lines <- lines[nzchar(trimws(lines))]
  if (length(lines) == 0L) {
    return(tibble::tibble(name = character(), is_dir = logical(),
                          size = numeric(), modified = as.POSIXct(character())))
  }
  m <- regmatches(lines, regexec(
    "^\\s*(\\d{2}-\\d{2}-\\d{2})\\s+(\\d{2}:\\d{2}[AP]M)\\s+(<DIR>|\\d+)\\s+(.*?)\\s*$",
    lines))
  ok <- lengths(m) == 5L
  m <- m[ok]
  if (length(m) == 0L) {
    return(tibble::tibble(name = character(), is_dir = logical(),
                          size = numeric(), modified = as.POSIXct(character())))
  }
  date  <- vapply(m, `[[`, "", 2L)
  time  <- vapply(m, `[[`, "", 3L)
  what  <- vapply(m, `[[`, "", 4L)
  name  <- vapply(m, `[[`, "", 5L)
  # Locale-independent 12-hour clock: "%p" does not parse AM/PM outside
  # English locales, so convert to 24 h by hand.
  hh <- as.integer(substr(time, 1L, 2L)) %% 12L + ifelse(grepl("PM$", time), 12L, 0L)
  mm <- substr(time, 4L, 5L)
  tibble::tibble(
    name     = name,
    is_dir   = what == "<DIR>",
    size     = ifelse(what == "<DIR>", NA_real_, suppressWarnings(as.numeric(what))),
    modified = as.POSIXct(sprintf("%s %02d:%s", date, hh, mm), format = "%m-%d-%y %H:%M", tz = "UTC")
  )
}

# -- Column names --------------------------------------------------------------

#' Normalise the MTE column names: strip accents, lower case, keep only
#' `[a-z0-9]`. `competenciamov` (with accent in the file) stays `competenciamov`, `salario` likewise;
#' `salario`, and so on. Also removes a leading UTF-8 BOM.
#' @noRd
.normalise_names <- function(x) {
  x <- sub("^\ufeff", "", x)
  x <- stringi::stri_trans_general(x, "Latin-ASCII")
  x <- tolower(x)
  gsub("[^a-z0-9]", "", x)
}

#' Detect the file kind (MOV / FOR / EXC) from an archive file name.
#' @noRd
.detect_file <- function(path) {
  nm <- toupper(basename(path))
  if (grepl("CAGEDMOV", nm, fixed = TRUE)) return("MOV")
  if (grepl("CAGEDFOR", nm, fixed = TRUE)) return("FOR")
  if (grepl("CAGEDEXC", nm, fixed = TRUE)) return("EXC")
  NA_character_
}

#' Detect the reference month (AAAAMM) from an archive file name.
#' @noRd
.detect_period <- function(path) {
  m <- regmatches(basename(path), regexpr("\\d{6}", basename(path)))
  if (length(m) == 0L) NA_integer_ else as.integer(m)
}

# -- Row binding ---------------------------------------------------------------

#' Stack data frames whose columns differ (MOV/FOR vs EXC), filling missing
#' columns with NA. Column order follows first appearance.
#' @noRd
.bind_rows_fill <- function(parts) {
  parts <- parts[vapply(parts, function(p) !is.null(p) && nrow(p) > 0L, logical(1))]
  if (length(parts) == 0L) return(tibble::tibble())
  cols <- unique(unlist(lapply(parts, names)))
  parts <- lapply(parts, function(p) {
    for (cl in setdiff(cols, names(p))) p[[cl]] <- rep(NA, nrow(p))
    p[, cols, drop = FALSE]
  })
  tibble::as_tibble(do.call(rbind, parts))
}
