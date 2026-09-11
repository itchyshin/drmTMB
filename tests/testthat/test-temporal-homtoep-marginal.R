pkgload::load_all(".", compile = TRUE, quiet = TRUE)

source(testthat::test_path("helper-temporal-homtoep-reference.R"))

homtoep_marginal_data <- function() {
  set.seed(2026091101)
  n_id <- 30L
  occasion <- rep(0:5, n_id)
  id <- factor(rep(sprintf("s%02d", seq_len(n_id)), each = 6L))
  between <- rep(rep(c(-0.5, 0.5), length.out = n_id), each = 6L)
  within <- unlist(lapply(seq_len(n_id), function(i) {
    sample(rep(c(-0.5, 0.5), length.out = 6L))
  }), use.names = FALSE)
  rho <- c(1, 0.55^(1:5))
  root <- chol(stats::toeplitz(rho))
  temporal <- unlist(lapply(seq_len(n_id), function(i) {
    as.vector(t(root) %*% rnorm(6L, sd = 0.8))
  }), use.names = FALSE)
  data.frame(
    y = 0.2 + 0.4 * between - 0.3 * within + temporal,
    id = id, occasion = occasion, between = between, within = within
  )
}

test_that("homtoep is an identified marginal Toeplitz covariance model", {
  dat <- homtoep_marginal_data()
  fit <- drmTMB::drmTMB(
    drmTMB::bf(
      y ~ between + within + temporal(1 | id, time = occasion, structure = "homtoep"),
      sigma ~ 1
    ),
    data = dat, family = gaussian(), REML = FALSE
  )
  rho <- c(1, unname(fit$corpars$temporal))
  expect_true(isTRUE(fit$sdr$pdHess))
  expect_false("temporal" %in% names(fit$random_effects))
  expect_equal(
    -as.numeric(stats::logLik(fit)),
    homtoep_dense_marginal_nll(
      y = dat$y, X = stats::model.matrix(~ between + within, dat),
      beta = unname(stats::coef(fit)$mu), id = dat$id, occasion = dat$occasion,
      sd_total = unname(stats::sigma(fit)[[1L]]), rho = rho
    ),
    tolerance = 1e-6
  )
})
