#' Consolidate admissions, separations and net balance
#'
#' Applies the accounting rule of the Novo CAGED to a set of records read
#' with [caged_read()] or [caged_fetch()] and aggregates them. Movements
#' declared on time (`MOV`) and late (`FOR`) count with their own sign;
#' **exclusions** (`EXC`) cancel a previously declared movement, so their
#' `saldomovimentacao` is inverted before summing. The aggregation is always
#' by `competenciamov`, the reference month of the movement, which is what
#' the Ministry's published totals use.
#'
#' Because `FOR` and `EXC` archives of month *M* carry records of earlier
#' months, the balance of a given month keeps changing as later archives are
#' published. To reproduce the Ministry's figure for a month, read every
#' archive published up to the date of interest.
#'
#' @param data A tibble returned by [caged_read()] or [caged_fetch()]. Must
#'   contain `competenciamov`, `saldomovimentacao` and `caged_file`.
#' @param by Character vector of additional grouping columns (for example
#'   `"municipio"`, `"uf"`, `"secao"`). `competenciamov` is always included.
#'
#' @return A tibble with the grouping columns and `admissions` (records
#'   with positive sign after the exclusion rule), `separations` (negative
#'   sign), `net` (`admissions - separations`) and `records` (number of
#'   records aggregated). When the data contain `salario`, also
#'   `admission_salary` (sum of the salaries of the admissions) and
#'   `mean_admission_salary`.
#' @export
#' @examples
#' f <- system.file("extdata", "CAGEDMOV202301_sample.7z", package = "cagedr")
#' x <- caged_read(f, verbose = FALSE)
#' caged_balance(x, by = "uf")
caged_balance <- function(data, by = NULL) {
  need <- c("competenciamov", "saldomovimentacao", "caged_file")
  missing_cols <- setdiff(need, names(data))
  if (length(missing_cols)) {
    cli::cli_abort("{.arg data} lacks column{?s} {.val {missing_cols}}; read it with {.fn caged_read}.")
  }
  by <- unique(c("competenciamov", by))
  bad <- setdiff(by, names(data))
  if (length(bad)) cli::cli_abort("Grouping column{?s} not in {.arg data}: {.val {bad}}.")

  sign <- ifelse(data$caged_file == "EXC", -1L, 1L)
  saldo <- as.integer(data$saldomovimentacao) * sign
  adm <- saldo > 0
  sep <- saldo < 0
  keys <- data[, by, drop = FALSE]
  g <- interaction(keys, drop = TRUE, lex.order = TRUE)

  out <- unique(keys[order(g), , drop = FALSE])
  out <- out[!duplicated(out), , drop = FALSE]
  idx <- match(interaction(out, drop = TRUE, lex.order = TRUE), levels(g))
  sum_by <- function(x) as.numeric(tapply(x, g, sum, na.rm = TRUE))[idx]

  out$admissions  <- as.integer(sum_by(as.integer(adm)))
  out$separations <- as.integer(sum_by(as.integer(sep)))
  out$net         <- out$admissions - out$separations
  out$records     <- as.integer(sum_by(rep(1L, length(saldo))))
  if ("salario" %in% names(data)) {
    sal <- as.numeric(data$salario)
    out$admission_salary <- sum_by(ifelse(adm, sal, 0))
    n_sal <- sum_by(as.integer(adm & !is.na(sal)))
    out$mean_admission_salary <- ifelse(n_sal > 0, out$admission_salary / n_sal, NA_real_)
  }
  rownames(out) <- NULL
  tibble::as_tibble(out)
}
