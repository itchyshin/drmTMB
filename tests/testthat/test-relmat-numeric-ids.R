# #1485: whole-number ids stored as double (100000) must match matrix and
# pedigree labels written as plain digits, as the same ids stored as integer do.

test_that("drm_id_labels() writes whole-number doubles as plain digits", {
  expect_identical(
    drmTMB:::drm_id_labels(c(100000, 2e5, 1e6, 12)),
    c("100000", "200000", "1000000", "12")
  )
  expect_identical(drmTMB:::drm_id_labels(c(1.5, NA)), c("1.5", NA))
  expect_identical(drmTMB:::drm_id_labels(c(100000L, 3L)), c("100000", "3"))
  expect_identical(drmTMB:::drm_id_labels(factor(c("a", "b"))), c("a", "b"))
  expect_identical(drmTMB:::drm_id_labels(c("1e+05", "x")), c("100000", "x"))
})

new_numeric_id_relmat_data <- function() {
  set.seed(1)
  ids <- c(100000, 200000, 300000, 400000, 500000, 600000)
  lab <- format(ids, scientific = FALSE, trim = TRUE)
  K <- outer(seq_along(ids), seq_along(ids), function(i, j) 0.3^abs(i - j))
  diag(K) <- diag(K) + 0.2
  dimnames(K) <- list(lab, lab)
  u <- as.vector(t(chol(K)) %*% stats::rnorm(length(ids), sd = 0.5))
  d <- data.frame(line = rep(ids, each = 6), x = stats::rnorm(36))
  d$y <- 0.3 + 0.5 * d$x + rep(u, each = 6) + stats::rnorm(36, sd = 0.3)
  list(data = d, K = K)
}

test_that("relmat() matches double ids such as 100000 to matrix labels", {
  sim <- new_numeric_id_relmat_data()
  K <- sim$K
  fit_double <- drmTMB(
    bf(y ~ x + relmat(1 | line, K = K)),
    data = sim$data
  )
  d_int <- sim$data
  d_int$line <- as.integer(d_int$line)
  fit_int <- drmTMB(bf(y ~ x + relmat(1 | line, K = K)), data = d_int)
  expect_equal(logLik(fit_double), logLik(fit_int), tolerance = 1e-8)
  expect_equal(fit_double$opt$par, fit_int$opt$par, tolerance = 1e-6)
})

test_that("animal() matches double ids to integer pedigree ids", {
  set.seed(3)
  ped <- data.frame(
    id = c(100000L, 200000L, 300000L, 400000L, 500000L, 600000L),
    dam = c(NA, NA, 100000L, 100000L, 300000L, 300000L),
    sire = c(NA, NA, 200000L, 200000L, 400000L, 400000L)
  )
  d <- data.frame(id = rep(as.double(ped$id), each = 6), x = stats::rnorm(36))
  d$y <- 0.2 + 0.4 * d$x + rep(stats::rnorm(6, sd = 0.4), each = 6) +
    stats::rnorm(36, sd = 0.3)
  fit_double <- drmTMB(bf(y ~ x + animal(1 | id, pedigree = ped)), data = d)
  d_int <- d
  d_int$id <- as.integer(d_int$id)
  fit_int <- drmTMB(bf(y ~ x + animal(1 | id, pedigree = ped)), data = d_int)
  expect_equal(logLik(fit_double), logLik(fit_int), tolerance = 1e-8)
})

test_that("drm_id_labels() rewrites scientific-notation labels of whole numbers", {
  expect_identical(
    drmTMB:::drm_id_labels(c("1e+05", "2E5", "1.5e+00", "a1e5", "007")),
    c("100000", "200000", "1.5e+00", "a1e5", "007")
  )
  expect_identical(drmTMB:::drm_id_labels(factor("1e+05")), "100000")
})

test_that("relmat() matches double ids to matrix labels written by R as 1e+05", {
  sim <- new_numeric_id_relmat_data()
  ids <- c(100000, 200000, 300000, 400000, 500000, 600000)
  K <- unname(sim$K)
  dimnames(K) <- list(ids, ids)
  expect_identical(rownames(K)[1:2], c("1e+05", "2e+05"))
  fit_sci <- drmTMB(bf(y ~ x + relmat(1 | line, K = K)), data = sim$data)
  K_plain <- sim$K
  fit_plain <- drmTMB(
    bf(y ~ x + relmat(1 | line, K = K_plain)),
    data = sim$data
  )
  expect_equal(logLik(fit_sci), logLik(fit_plain), tolerance = 1e-8)

  d_int <- sim$data
  d_int$line <- as.integer(d_int$line)
  fit_int <- drmTMB(bf(y ~ x + relmat(1 | line, K = K)), data = d_int)
  expect_equal(logLik(fit_int), logLik(fit_plain), tolerance = 1e-8)
})

test_that("animal() matches double ids to a character pedigree holding 1e+05", {
  set.seed(3)
  ids <- c(100000, 200000, 300000, 400000, 500000, 600000)
  ped <- data.frame(
    id = as.character(ids),
    dam = c(NA, NA, as.character(ids[c(1, 1, 3, 3)])),
    sire = c(NA, NA, as.character(ids[c(2, 2, 4, 4)])),
    stringsAsFactors = FALSE
  )
  expect_identical(ped$id[1], "1e+05")
  d <- data.frame(id = rep(ids, each = 6), x = stats::rnorm(36))
  d$y <- 0.2 + 0.4 * d$x + rep(stats::rnorm(6, sd = 0.4), each = 6) +
    stats::rnorm(36, sd = 0.3)
  expect_no_error(
    drmTMB(bf(y ~ x + animal(1 | id, pedigree = ped)), data = d)
  )
})
