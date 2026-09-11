sample <- function(kind) {
  system.file("extdata", sprintf("CAGED%s202301_sample.7z", kind), package = "cagedr")
}

test_that("balance aggregates by competenciamov with the exclusion rule", {
  mov <- caged_read(sample("MOV"), verbose = FALSE)
  b <- caged_balance(mov)
  expect_s3_class(b, "tbl_df")
  expect_equal(b$admissions, sum(mov$saldomovimentacao > 0))
  expect_equal(b$separations, sum(mov$saldomovimentacao < 0))
  expect_equal(b$net, b$admissions - b$separations)
  expect_equal(b$records, nrow(mov))
  expect_equal(b$admission_salary, sum(mov$salario[mov$saldomovimentacao > 0]))

  exc <- caged_read(sample("EXC"), verbose = FALSE)
  both <- cagedr:::.bind_rows_fill(list(mov, exc))
  expect_equal(nrow(both), nrow(mov) + nrow(exc))
  expect_true(all(is.na(both$competenciaexc[both$caged_file == "MOV"])))
  b2 <- caged_balance(both)
  # An exclusion of an admission (+1) counts as -1 after inversion.
  inv <- -exc$saldomovimentacao
  expect_equal(sum(b2$admissions), sum(mov$saldomovimentacao > 0) + sum(inv > 0))
  expect_equal(sum(b2$separations), sum(mov$saldomovimentacao < 0) + sum(inv < 0))
})

test_that("extra grouping columns are honoured", {
  mov <- caged_read(sample("MOV"), verbose = FALSE)
  b <- caged_balance(mov, by = "uf")
  expect_equal(nrow(b), 2L)
  expect_setequal(b$uf, c(26L, 29L))
  expect_equal(sum(b$records), nrow(mov))
  b3 <- caged_balance(mov, by = c("uf", "municipio"))
  expect_equal(sum(b3$records), nrow(mov))
  expect_true(all(c("competenciamov", "uf", "municipio") %in% names(b3)))
})

test_that("missing columns are reported", {
  expect_error(caged_balance(data.frame(a = 1)), "caged_read")
  mov <- caged_read(sample("MOV"), verbose = FALSE)
  expect_error(caged_balance(mov, by = "nope"), "not in")
})
