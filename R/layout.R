#' Record layout of the Novo CAGED microdata
#'
#' The columns of the monthly files, with the original (accented) name used
#' by the Ministry, the normalised name returned by [caged_read()], the type
#' assigned when `types = TRUE`, the files in which the column appears and a
#' short description. The official layout (the "Layout Nao-identificado Novo
#' Caged Movimentacao" spreadsheet) is published in the same FTP folder as the data.
#'
#' Two columns exist only in the exclusions file (`EXC`): `competenciaexc`
#' and `indicadordeexclusao`.
#'
#' @return A tibble with columns `column` (normalised name), `original`
#'   (name in the file), `type`, `files` and `description`.
#' @export
#' @examples
#' caged_layout()
#' subset(caged_layout(), files != "MOV, FOR, EXC")
caged_layout <- function() {
  tibble::tribble(
    ~column,                  ~original,                ~type,       ~files,           ~description,
    "competenciamov",         "compet\u00eanciamov",    "integer",   "MOV, FOR, EXC",  "Reference month of the movement (AAAAMM). In FOR and EXC files it is earlier than the archive month.",
    "regiao",                 "regi\u00e3o",            "integer",   "MOV, FOR, EXC",  "IBGE region code (1 North to 5 Centre-West).",
    "uf",                     "uf",                     "integer",   "MOV, FOR, EXC",  "IBGE state code (two digits, e.g. 26 = Pernambuco).",
    "municipio",              "munic\u00edpio",         "integer",   "MOV, FOR, EXC",  "IBGE municipality code with six digits (the seven-digit IBGE code without its check digit).",
    "secao",                  "se\u00e7\u00e3o",        "character", "MOV, FOR, EXC",  "CNAE 2.0 section (letter A to U) of the establishment.",
    "subclasse",              "subclasse",              "character", "MOV, FOR, EXC",  "CNAE 2.0 subclass (seven digits) of the establishment.",
    "saldomovimentacao",      "saldomovimenta\u00e7\u00e3o", "integer", "MOV, FOR, EXC", "+1 for an admission, -1 for a separation.",
    "cbo2002ocupacao",        "cbo2002ocupa\u00e7\u00e3o", "integer", "MOV, FOR, EXC",  "Occupation code (CBO 2002).",
    "categoria",              "categoria",              "integer",   "MOV, FOR, EXC",  "Worker category code (e.g. 101 = urban employee under CLT).",
    "graudeinstrucao",        "graudeinstru\u00e7\u00e3o", "integer", "MOV, FOR, EXC",  "Education level code (1 illiterate to 11 doctorate; 80 not identified).",
    "idade",                  "idade",                  "integer",   "MOV, FOR, EXC",  "Worker age in years.",
    "horascontratuais",       "horascontratuais",       "integer",   "MOV, FOR, EXC",  "Weekly contractual hours.",
    "racacor",                "ra\u00e7acor",           "integer",   "MOV, FOR, EXC",  "Race/colour code (1 white, 2 black, 3 brown, 4 yellow, 5 indigenous, 6 not informed, 9 not identified).",
    "sexo",                   "sexo",                   "integer",   "MOV, FOR, EXC",  "Sex (1 male, 3 female, 9 not identified).",
    "tipoempregador",         "tipoempregador",         "integer",   "MOV, FOR, EXC",  "Employer type (0 CNPJ root, 2 CPF, 9 not identified).",
    "tipoestabelecimento",    "tipoestabelecimento",    "integer",   "MOV, FOR, EXC",  "Establishment type (1 CNPJ, 3 CAEPF, 4 CNO, 5 CEI, 9 not identified).",
    "tipomovimentacao",       "tipomovimenta\u00e7\u00e3o", "integer", "MOV, FOR, EXC", "Movement type code (10 first job, 20 re-employment, 31 dismissal without cause, 40 resignation, ...).",
    "tipodedeficiencia",      "tipodedefici\u00eancia", "integer",   "MOV, FOR, EXC",  "Disability type (0 none, 1 physical, 2 hearing, 3 visual, 4 intellectual, 5 multiple, 6 rehabilitated, 9 not identified).",
    "indtrabintermitente",    "indtrabintermitente",    "integer",   "MOV, FOR, EXC",  "Intermittent work indicator (0 no, 1 yes, 9 not identified).",
    "indtrabparcial",         "indtrabparcial",         "integer",   "MOV, FOR, EXC",  "Part-time work indicator (0 no, 1 yes, 9 not identified).",
    "salario",                "sal\u00e1rio",           "double",    "MOV, FOR, EXC",  "Monthly salary in BRL (decimal comma in the file, converted to a number).",
    "tamestabjan",            "tamestabjan",            "integer",   "MOV, FOR, EXC",  "Establishment size band in January (1 zero to 10 more than 1,000 employees; 99 not identified).",
    "indicadoraprendiz",      "indicadoraprendiz",      "integer",   "MOV, FOR, EXC",  "Apprentice indicator (0 no, 1 yes, 9 not identified).",
    "origemdainformacao",     "origemdainforma\u00e7\u00e3o", "integer", "MOV, FOR, EXC", "Source system of the record (1 eSocial, 2 CAGED, 3 Empregador Web).",
    "competenciadec",         "compet\u00eanciadec",    "integer",   "MOV, FOR, EXC",  "Month in which the movement was declared (AAAAMM).",
    "competenciaexc",         "compet\u00eanciaexc",    "integer",   "EXC",            "Month in which the exclusion was declared (AAAAMM).",
    "indicadordeexclusao",    "indicadordeexclus\u00e3o", "integer", "EXC",            "Exclusion indicator (1 = the record cancels a previously declared movement).",
    "indicadordeforadoprazo", "indicadordeforadoprazo", "integer",   "MOV, FOR, EXC",  "Late declaration indicator (0 on time, 1 late).",
    "unidadesalariocodigo",   "unidadesal\u00e1rioc\u00f3digo", "integer", "MOV, FOR, EXC", "Salary unit code (1 hour, 2 day, 3 week, 4 fortnight, 5 month, 6 task, 7 variable, 99 not identified).",
    "valorsalariofixo",       "valorsal\u00e1riofixo",  "double",    "MOV, FOR, EXC",  "Fixed salary amount in the declared unit (decimal comma in the file)."
  )
}
