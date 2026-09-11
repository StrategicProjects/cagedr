sample_path <- function(kind) {
  system.file("extdata", sprintf("CAGED%s202301_sample.7z", kind), package = "cagedr")
}

# Pretend to download: copy the sample archive of the same kind, or report
# the file as missing / failing, without touching the network.
fake_download <- function(behavior = c("ok", "not_found", "error")) {
  behavior <- match.arg(behavior)
  function(url, destfile, timeout = 900, retries = 3L) {
    if (behavior != "ok") return(behavior)
    kind <- cagedr:::.detect_file(url)
    file.copy(sample_path(kind), destfile, overwrite = TRUE)
    "ok"
  }
}

test_that("download populates the cache and reuses it", {
  dir <- withr::local_tempdir()
  testthat::local_mocked_bindings(.caged_curl_download = fake_download("ok"), .package = "cagedr")

  d1 <- caged_download(202301, cache_dir = dir, verbose = FALSE)
  expect_equal(nrow(d1), 3L)
  expect_equal(d1$file, c("MOV", "FOR", "EXC"))
  expect_true(all(d1$status == "downloaded"))
  expect_true(all(file.exists(d1$path)))

  d2 <- caged_download(202301, cache_dir = dir, verbose = FALSE)
  expect_true(all(d2$status == "cached"))

  lst <- caged_cache_list(dir)
  expect_equal(nrow(lst), 3L)
  expect_setequal(lst$file, c("MOV", "FOR", "EXC"))
  expect_equal(unique(lst$period), 202301L)

  expect_equal(caged_cache_clear(202301, cache_dir = dir), 3L)
  expect_equal(nrow(caged_cache_list(dir)), 0L)
})

test_that("files missing on the server are reported, not raised", {
  dir <- withr::local_tempdir()
  testthat::local_mocked_bindings(.caged_curl_download = fake_download("not_found"), .package = "cagedr")
  d <- caged_download(202001, files = "FOR", cache_dir = dir, verbose = FALSE)
  expect_equal(d$status, "not_found")
  expect_true(is.na(d$path))
})

test_that("download errors warn and are reported", {
  dir <- withr::local_tempdir()
  testthat::local_mocked_bindings(.caged_curl_download = fake_download("error"), .package = "cagedr")
  expect_warning(d <- caged_download(202301, files = "MOV", cache_dir = dir, verbose = FALSE),
                 "download failed")
  expect_equal(d$status, "error")
})

test_that("fetch downloads, reads, filters and stacks", {
  dir <- withr::local_tempdir()
  testthat::local_mocked_bindings(.caged_curl_download = fake_download("ok"), .package = "cagedr")
  x <- caged_fetch(202301, uf = 26, cache_dir = dir, verbose = FALSE)
  expect_s3_class(x, "tbl_df")
  expect_setequal(unique(x$caged_file), c("MOV", "FOR", "EXC"))
  expect_equal(unique(x$uf), 26L)
  expect_equal(nrow(x), 24L + 6L + 5L)
  dl <- attr(x, "download")
  expect_equal(nrow(dl), 3L)
  # EXC-only columns are NA for MOV/FOR rows after stacking
  expect_true(all(is.na(x$competenciaexc[x$caged_file == "MOV"])))
})

test_that("the cache directory is resolved from argument, env var, option, tempdir", {
  withr::local_envvar(CAGEDR_CACHE_DIR = "")
  withr::local_options(cagedr.cache_dir = NULL)
  expect_equal(caged_cache_dir(), file.path(tempdir(), "cagedr-cache"))
  d <- withr::local_tempdir()
  expect_equal(caged_cache_dir(d), d)
  withr::local_options(cagedr.cache_dir = d)
  expect_equal(caged_cache_dir(), d)
  d2 <- withr::local_tempdir()
  withr::local_envvar(CAGEDR_CACHE_DIR = d2)
  expect_equal(caged_cache_dir(), d2)
})

test_that("caged_available returns an empty tibble with a warning when offline", {
  testthat::local_mocked_bindings(.ftp_listing = function(url, timeout = 30) NULL, .package = "cagedr")
  expect_warning(a <- caged_available(verbose = FALSE), "Could not reach")
  expect_equal(nrow(a), 0L)
  expect_equal(names(a), c("period", "year", "month", "modified", "url"))
})

test_that("caged_available parses a mocked server", {
  listings <- list(
    root = paste("08-08-25  09:52AM       <DIR>          2025",
                 "01-29-26  02:31PM       <DIR>          2026",
                 "11-30-21  03:56PM                 1084 Leia-me.txt", sep = "\r\n"),
    y2025 = "01-29-26  02:31PM       <DIR>          202512\r\n",
    y2026 = paste("06-16-26  02:51PM       <DIR>          202601",
                  "08-28-26  02:31PM       <DIR>          202607", sep = "\r\n")
  )
  testthat::local_mocked_bindings(
    .ftp_listing = function(url, timeout = 30) {
      if (grepl("/2025$", url)) listings$y2025 else if (grepl("/2026$", url)) listings$y2026 else listings$root
    },
    .package = "cagedr"
  )
  a <- caged_available(verbose = FALSE)
  expect_equal(a$period, c(202607L, 202601L, 202512L))
  expect_equal(a$year, c(2026L, 2026L, 2025L))
  expect_equal(a$month, c(7L, 1L, 12L))
  expect_match(a$url[1], "/2026/202607$")
  a26 <- caged_available(year = 2026, verbose = FALSE)
  expect_equal(nrow(a26), 2L)
})
