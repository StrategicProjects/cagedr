# Columns typed as integer / double after reading. Everything else stays
# character. Names are the normalised ones (see .normalise_names()).
.caged_int_cols <- c(
  "competenciamov", "competenciadec", "competenciaexc", "regiao", "uf",
  "municipio", "saldomovimentacao", "categoria", "graudeinstrucao", "idade",
  "horascontratuais", "racacor", "sexo", "tipoempregador", "tipoestabelecimento",
  "tipomovimentacao", "tipodedeficiencia", "indtrabintermitente", "indtrabparcial",
  "tamestabjan", "indicadoraprendiz", "origemdainformacao",
  "indicadordeforadoprazo", "indicadordeexclusao", "unidadesalariocodigo",
  "cbo2002ocupacao"
)
.caged_dbl_cols <- c("salario", "valorsalariofixo")

#' Read a Novo CAGED archive as a stream
#'
#' Reads the `.txt` inside a monthly `.7z` archive without extracting it to
#' disk and without loading the national file in memory: the text is
#' decompressed as a stream and parsed in chunks, and each chunk is filtered
#' by state and reduced to the requested columns before being kept. This is
#' what makes it practical to extract one state (a few hundred thousand
#' records) from a national file of several million records on a modest
#' machine.
#'
#' @param path Path to a `CAGEDMOV`, `CAGEDFOR` or `CAGEDEXC` archive, as
#'   returned by [caged_download()].
#' @param uf Optional vector of state codes to keep, as IBGE two-digit
#'   numbers (for example `26` for Pernambuco, `c(26, 25)` for Pernambuco
#'   and Paraiba). `NULL` keeps every state.
#' @param columns Optional character vector of columns to keep, using the
#'   normalised names listed by [caged_layout()]. `NULL` keeps all columns.
#'   The `uf` column is always read (it is needed for filtering) but is only
#'   returned when requested or when `columns` is `NULL`.
#' @param types Convert the numeric columns of the layout (codes, salary) to
#'   integer/double? If `FALSE` every column is returned as character.
#' @param chunk_size Number of lines parsed per chunk. Larger chunks are
#'   faster but use more memory; the default (500,000 lines) uses well under
#'   1 GB.
#' @param verbose Emit progress messages? Defaults to
#'   `getOption("cagedr.verbose", TRUE)`.
#'
#' @return A tibble with the selected records and columns, plus two columns
#'   added by the package: `caged_file` (`"MOV"`, `"FOR"` or `"EXC"`,
#'   detected from the archive name) and `caged_period` (the reference month
#'   of the **archive**, which for `FOR` and `EXC` differs from the
#'   `competenciamov` of the records). Column names are normalised: accents
#'   removed and lower case (`competenciamov`, `municipio`, `salario`).
#'   Returns an empty tibble when no record matches.
#' @export
#' @seealso [caged_layout()] for the meaning of every column,
#'   [caged_fetch()] for download and read in one call.
#' @examples
#' # A small sample archive ships with the package (Pernambuco and Bahia rows).
#' f <- system.file("extdata", "CAGEDMOV202301_sample.7z", package = "cagedr")
#' x <- caged_read(f, verbose = FALSE)
#' dim(x)
#'
#' # One state, a few columns
#' pe <- caged_read(f, uf = 26,
#'                  columns = c("competenciamov", "municipio", "saldomovimentacao", "salario"),
#'                  verbose = FALSE)
#' pe
caged_read <- function(path, uf = NULL, columns = NULL, types = TRUE,
                       chunk_size = 500000L, verbose = NULL) {
  verbose <- .verbose(verbose)
  if (!is.character(path) || length(path) != 1L || !file.exists(path)) {
    cli::cli_abort("{.arg path} must be the path of an existing archive.")
  }
  kind   <- .detect_file(path)
  period <- .detect_period(path)

  entries <- archive::archive(path)
  txt <- entries$path[grepl("\\.txt$", entries$path, ignore.case = TRUE)]
  if (length(txt) == 0L) cli::cli_abort("No {.file .txt} entry inside {.file {basename(path)}}.")

  # Header: normalised names, BOM removed.
  con <- archive::archive_read(path, file = txt[[1]])
  header <- readLines(con, n = 1L, encoding = "UTF-8", warn = FALSE)
  close(con)
  nms <- .normalise_names(strsplit(header, ";", fixed = TRUE)[[1]])
  if (!"uf" %in% nms) cli::cli_abort("Unexpected layout: no {.field uf} column in {.file {basename(path)}}.")

  if (!is.null(columns)) {
    missing_cols <- setdiff(columns, nms)
    if (length(missing_cols)) {
      cli::cli_abort(c("Column{?s} not in this file: {.val {missing_cols}}.",
                       "i" = "See {.fn caged_layout} for the available columns."))
    }
  }
  keep <- if (is.null(columns)) nms else union(columns, "uf")
  uf_keep <- if (is.null(uf)) NULL else as.character(as.integer(uf))

  cb <- function(chunk, pos) {
    if (!is.null(uf_keep)) chunk <- chunk[chunk$uf %in% uf_keep, , drop = FALSE]
    chunk[, keep, drop = FALSE]
  }

  con <- archive::archive_read(path, file = txt[[1]])
  on.exit(try(close(con), silent = TRUE), add = TRUE)
  out <- readr::read_delim_chunked(
    con,
    callback   = readr::DataFrameCallback$new(cb),
    chunk_size = chunk_size,
    delim      = ";",
    col_names  = nms,
    skip       = 1L,
    col_types  = readr::cols(.default = readr::col_character()),
    locale     = readr::locale(encoding = "UTF-8", decimal_mark = ",", grouping_mark = "."),
    trim_ws    = TRUE,
    progress   = FALSE
  )
  if (is.null(out) || nrow(out) == 0L) {
    out <- as.data.frame(stats::setNames(replicate(length(keep), character(), simplify = FALSE), keep))
  }
  out <- tibble::as_tibble(out)

  if (isTRUE(types)) {
    for (cl in intersect(names(out), .caged_int_cols)) {
      out[[cl]] <- suppressWarnings(as.integer(out[[cl]]))
    }
    for (cl in intersect(names(out), .caged_dbl_cols)) {
      out[[cl]] <- suppressWarnings(as.numeric(sub(",", ".", out[[cl]], fixed = TRUE)))
    }
  }
  if (!is.null(columns) && !"uf" %in% columns) out$uf <- NULL

  out$caged_file   <- kind
  out$caged_period <- period
  if (verbose) {
    cli::cli_alert_success(
      "{basename(path)}: {format(nrow(out), big.mark = ',')} record{?s} kept{if (!is.null(uf)) paste0(' (uf ', paste(uf, collapse = ', '), ')') else ''}."
    )
  }
  out
}

#' Download and read Novo CAGED microdata in one call
#'
#' Convenience wrapper: [caged_download()] followed by [caged_read()] on
#' every archive found, with the results stacked. Missing files (for
#' example `FOR`/`EXC` in early 2020) are skipped with a message.
#'
#' @inheritParams caged_download
#' @inheritParams caged_read
#'
#' @return A tibble with the records of every archive read (see
#'   [caged_read()] for the columns), or an empty tibble when nothing was
#'   available. The attribute `"download"` holds the tibble returned by
#'   [caged_download()], so that `not_found` and `error` files can be
#'   inspected.
#' @export
#' @examples
#' \donttest{
#' # Requires network access. Pernambuco, one month, the three files:
#' pe <- tryCatch(
#'   caged_fetch(202401, uf = 26, cache_dir = tempdir(), verbose = FALSE),
#'   error = function(e) NULL
#' )
#' if (!is.null(pe)) table(pe$caged_file)
#' }
caged_fetch <- function(period, uf = NULL, files = c("MOV", "FOR", "EXC"),
                        columns = NULL, cache_dir = NULL, force = FALSE,
                        types = TRUE, chunk_size = 500000L, timeout = 900,
                        verbose = NULL) {
  verbose <- .verbose(verbose)
  dl <- caged_download(period, files = files, cache_dir = cache_dir, force = force,
                       timeout = timeout, verbose = verbose)
  ok <- dl[!is.na(dl$path), , drop = FALSE]
  parts <- lapply(ok$path, function(p) {
    caged_read(p, uf = uf, columns = columns, types = types,
               chunk_size = chunk_size, verbose = verbose)
  })
  out <- .bind_rows_fill(parts)
  attr(out, "download") <- dl
  out
}
