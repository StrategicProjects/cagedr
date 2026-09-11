sample_mov <- function() system.file("extdata", "CAGEDMOV202301_sample.7z", package = "cagedr")
sample_exc <- function() system.file("extdata", "CAGEDEXC202301_sample.7z", package = "cagedr")

test_that("a sample archive is read with normalised names and types", {
  x <- caged_read(sample_mov(), verbose = FALSE)
  expect_s3_class(x, "tbl_df")
  expect_equal(nrow(x), 32L)
  expect_true(all(c("competenciamov", "municipio", "salario", "caged_file", "caged_period") %in% names(x)))
  expect_false(any(grepl("[^a-z0-9_]", names(x))))
  expect_type(x$competenciamov, "integer")
  expect_type(x$saldomovimentacao, "integer")
  expect_type(x$salario, "double")
  expect_true(all(x$saldomovimentacao %in% c(-1L, 1L)))
  expect_equal(unique(x$caged_file), "MOV")
  expect_equal(unique(x$caged_period), 202301L)
  expect_setequal(unique(x$uf), c(26L, 29L))
})

test_that("uf filter and column selection work and uf is dropped when not asked", {
  pe <- caged_read(sample_mov(), uf = 26, verbose = FALSE)
  expect_equal(nrow(pe), 24L)
  expect_equal(unique(pe$uf), 26L)

  both <- caged_read(sample_mov(), uf = c(26, 29), verbose = FALSE)
  expect_equal(nrow(both), 32L)

  sel <- caged_read(sample_mov(), uf = 29, columns = c("competenciamov", "municipio"), verbose = FALSE)
  expect_equal(names(sel), c("competenciamov", "municipio", "caged_file", "caged_period"))
  expect_equal(nrow(sel), 8L)

  with_uf <- caged_read(sample_mov(), columns = c("uf", "salario"), verbose = FALSE)
  expect_equal(names(with_uf), c("uf", "salario", "caged_file", "caged_period"))
})

test_that("small chunks give the same result as one chunk", {
  a <- caged_read(sample_mov(), chunk_size = 5L, verbose = FALSE)
  b <- caged_read(sample_mov(), chunk_size = 100000L, verbose = FALSE)
  expect_equal(a, b)
})

test_that("no match returns an empty tibble with the expected columns", {
  x <- caged_read(sample_mov(), uf = 99, verbose = FALSE)
  expect_equal(nrow(x), 0L)
  expect_true("competenciamov" %in% names(x))
})

test_that("types = FALSE keeps everything as character", {
  x <- caged_read(sample_mov(), types = FALSE, verbose = FALSE)
  expect_type(x$salario, "character")
  expect_true(any(grepl(",", x$salario, fixed = TRUE)))
})

test_that("the EXC layout has its two extra columns", {
  x <- caged_read(sample_exc(), verbose = FALSE)
  expect_true(all(c("competenciaexc", "indicadordeexclusao") %in% names(x)))
  expect_equal(unique(x$caged_file), "EXC")
  expect_equal(nrow(x), 7L)
})

test_that("errors are actionable", {
  expect_error(caged_read("does-not-exist.7z"), "existing archive")
  expect_error(caged_read(sample_mov(), columns = "nope", verbose = FALSE), "caged_layout")
})

test_that("the layout documents every column of the sample files", {
  lay <- caged_layout()
  mov <- caged_read(sample_mov(), verbose = FALSE)
  exc <- caged_read(sample_exc(), verbose = FALSE)
  cols <- setdiff(union(names(mov), names(exc)), c("caged_file", "caged_period"))
  expect_setequal(cols, lay$column)
  expect_equal(nrow(lay), 30L)
  expect_equal(sum(lay$files == "EXC"), 2L)
})
