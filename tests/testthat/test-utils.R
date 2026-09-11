test_that("column names are normalised like the Ministry's layout", {
  raw <- c("\ufeffcompet\u00eanciamov", "munic\u00edpio", "se\u00e7\u00e3o",
           "sal\u00e1rio", "unidadesal\u00e1rioc\u00f3digo", "uf")
  expect_equal(
    cagedr:::.normalise_names(raw),
    c("competenciamov", "municipio", "secao", "salario", "unidadesalariocodigo", "uf")
  )
})

test_that("periods are validated and expanded", {
  expect_equal(caged_periods(202301, 202303), c(202301L, 202302L, 202303L))
  expect_equal(caged_periods("202412"), 202412L)
  expect_equal(caged_periods(202011, 202102), c(202011L, 202012L, 202101L, 202102L))
  expect_error(caged_periods(202313), "AAAAMM")
  expect_error(caged_periods(201912), "starts in")
  expect_error(caged_periods(202305, 202301), "earlier than")
  expect_error(cagedr:::.as_period(NULL), "at least one")
})

test_that("archive URLs follow the FTP folder structure", {
  expect_equal(
    cagedr:::.caged_url(202607L, "MOV"),
    "ftp://ftp.mtps.gov.br/pdet/microdados/NOVO%20CAGED/2026/202607/CAGEDMOV202607.7z"
  )
  expect_equal(basename(cagedr:::.caged_url(202001L, "exc")), "CAGEDEXC202001.7z")
  expect_error(cagedr:::.caged_url(202001L, "XYZ"))
})

test_that("file kind and period are detected from archive names", {
  expect_equal(cagedr:::.detect_file("/x/CAGEDFOR202605.7z"), "FOR")
  expect_equal(cagedr:::.detect_file("cagedexc202605.7z"), "EXC")
  expect_true(is.na(cagedr:::.detect_file("other.7z")))
  expect_equal(cagedr:::.detect_period("CAGEDMOV202301_sample.7z"), 202301L)
})

test_that("IIS-style FTP listings are parsed", {
  txt <- paste(
    "06-16-26  02:51PM       <DIR>          202601",
    "08-28-26  02:31PM       <DIR>          202607",
    "08-31-22  11:59AM               293931 Layout N\u00e3o-identificado Novo Caged Movimenta\u00e7\u00e3o.xlsx",
    "",
    sep = "\r\n"
  )
  e <- cagedr:::.parse_ftp_listing(txt)
  expect_equal(nrow(e), 3L)
  expect_equal(e$name[1:2], c("202601", "202607"))
  expect_true(all(e$is_dir[1:2]))
  expect_false(e$is_dir[3])
  expect_equal(e$size[3], 293931)
  expect_equal(format(e$modified[2], "%Y-%m-%d %H:%M"), "2026-08-28 14:31")
  expect_equal(nrow(cagedr:::.parse_ftp_listing("")), 0L)
  expect_equal(nrow(cagedr:::.parse_ftp_listing(NULL)), 0L)
})
