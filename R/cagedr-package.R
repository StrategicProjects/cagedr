#' @keywords internal
"_PACKAGE"

#' @importFrom rlang %||%
#' @importFrom tibble tibble as_tibble
#' @importFrom cli cli_abort cli_warn cli_inform cli_alert_info
#' @importFrom cli cli_alert_success cli_alert_warning
NULL

# Column names used in non-standard evaluation (silence R CMD check NOTEs)
utils::globalVariables(c(
  "competenciamov", "saldomovimentacao", "salario", "caged_file", "uf"
))
