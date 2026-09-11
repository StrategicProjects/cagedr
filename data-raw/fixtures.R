# Gera as fixtures em inst/extdata a partir de registros reais de PE do
# arquivo CAGEDMOV/EXC 202301 (microdado público não identificado) mais linhas
# sintéticas da BA, no layout exato do MTE (cabeçalho acentuado, ';', UTF-8).
suppressMessages({library(arrow); library(dplyr)})
set.seed(1)
raw <- "~/Github/condepe/data/iaempe/raw/caged"
hdr_mov <- c("competênciamov","região","uf","município","seção","subclasse","saldomovimentação",
  "cbo2002ocupação","categoria","graudeinstrução","idade","horascontratuais","raçacor","sexo",
  "tipoempregador","tipoestabelecimento","tipomovimentação","tipodedeficiência","indtrabintermitente",
  "indtrabparcial","salário","tamestabjan","indicadoraprendiz","origemdainformação","competênciadec",
  "indicadordeforadoprazo","unidadesaláriocódigo","valorsaláriofixo")
hdr_exc <- append(hdr_mov, c("competênciaexc","indicadordeexclusão"), after = 25)
norm <- function(x) gsub("[^a-z0-9]", "", tolower(stringi::stri_trans_general(x, "Latin-ASCII")))
fmt_num <- function(x) ifelse(is.na(x), "", sub(".", ",", format(x, nsmall = 2, trim = TRUE, scientific = FALSE), fixed = TRUE))
build <- function(tipo, hdr, n_pe, n_ba, out) {
  d <- read_parquet(file.path(raw, sprintf("caged_pe_%s202301.parquet", tipo)))
  d <- d[sample(nrow(d), n_pe), norm(hdr)]
  ba <- d[sample(nrow(d), n_ba), ]; ba$uf <- 29L; ba$regiao <- 2L
  ba$municipio <- sample(c(292740L, 290570L, 291080L), n_ba, replace = TRUE)
  x <- bind_rows(d, ba) |> mutate(across(everything(), as.character))
  x$salario <- fmt_num(as.numeric(x$salario)); x$valorsalariofixo <- fmt_num(as.numeric(x$valorsalariofixo))
  lines <- c(paste(hdr, collapse = ";"), do.call(paste, c(x, sep = ";")))
  txt <- file.path(tempdir(), sprintf("CAGED%s202301.txt", tipo))
  writeLines(lines, txt, useBytes = TRUE)
  archive::archive_write_files(out, txt, format = "7zip")
  cat(out, ":", length(lines) - 1, "linhas,", file.size(out), "bytes\n")
}
build("MOV", hdr_mov, 24, 8, "inst/extdata/CAGEDMOV202301_sample.7z")
build("EXC", hdr_exc, 5, 2, "inst/extdata/CAGEDEXC202301_sample.7z")
build("FOR", hdr_mov, 6, 2, "inst/extdata/CAGEDFOR202301_sample.7z")
