# REML for ORDINARY (non-phylo) sigma random effects.
#
# drm_validate_reml_spec previously rejected any sigma random effect or mu-sigma
# correlation under REML ("supports ordinary mu random effects only"). These are
# now ADMITTED (2026-07-08): beta_sigma is marginalized in drm_apply_estimator_spec,
# so the restricted likelihood adjusts for the scale intercept and debiases the
# scale-side variance component -- with adequate within-group REPLICATION. Recovery
# ladders (scratchpad/reml_ordinary_sigma_re_probe.R): uniform across intercept,
# slope, and correlated blocks, REML debiases the scale-RE SD vs ML at n_each >= ~8;
# at n_each = 3 the component is weakly identified and REML underperforms ML. These
# tests assert ADMISSION + convergence + estimable variance components (recovery is
# the ladder's job), plus the univariate scoping (the bivariate cell stays gated).

make_dhglm <- function(n_id = 40L, n_each = 8L, seed = 1L, correlated = FALSE) {
  set.seed(seed)
  if (correlated) {
    S <- chol(matrix(c(.6^2, .3 * .6 * .4, .3 * .6 * .4, .4^2), 2, 2))
    b <- matrix(stats::rnorm(n_id * 2), n_id, 2) %*% S
    b_mu <- b[, 1]; b_sg <- b[, 2]
  } else {
    b_mu <- stats::rnorm(n_id, 0, .6); b_sg <- stats::rnorm(n_id, 0, .4)
  }
  id <- rep(seq_len(n_id), each = n_each); n <- n_id * n_each; x <- stats::rnorm(n)
  y <- .3 + .5 * x + b_mu[id] + stats::rnorm(n, 0, exp(log(.5) + b_sg[id]))
  data.frame(y = y, x = x, id = factor(id))
}

test_that("REML admits an ordinary sigma random intercept", {
  skip_on_cran()
  d <- make_dhglm()
  fit <- suppressWarnings(drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1 + (1 | id)),
    family = gaussian(), data = d, REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  ))
  expect_identical(fit$estimator, "REML")
  expect_identical(fit$opt$convergence, 0L)
  v <- setNames(summary(fit)$parameters$estimate, summary(fit)$parameters$parm)
  sd_sigma <- v[grepl("^sd:sigma", names(v))][1]
  expect_true(is.finite(sd_sigma) && sd_sigma > 0)
})

test_that("REML admits an independent sigma random slope", {
  skip_on_cran()
  d <- make_dhglm()
  fit <- suppressWarnings(drmTMB(
    bf(y ~ x + (1 | id), sigma ~ x + (0 + x | id)),
    family = gaussian(), data = d, REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  ))
  expect_identical(fit$estimator, "REML")
  expect_identical(fit$opt$convergence, 0L)
})

test_that("REML admits a correlated mu-sigma block (1 | p | id)", {
  skip_on_cran()
  d <- make_dhglm(correlated = TRUE)
  fit <- suppressWarnings(drmTMB(
    bf(y ~ x + (1 | p | id), sigma ~ 1 + (1 | p | id)),
    family = gaussian(), data = d, REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  ))
  expect_identical(fit$estimator, "REML")
  expect_identical(fit$opt$convergence, 0L)
  v <- setNames(summary(fit)$parameters$estimate, summary(fit)$parameters$parm)
  expect_true(any(grepl("^cor.*id", names(v))))
})

test_that("the REML relaxation stays bounded: q>2 scale covariance blocks remain rejected", {
  skip_on_cran()
  d <- make_dhglm()
  d$x2 <- stats::rnorm(nrow(d))
  # Relaxing the REML gate admitted ordinary intercept / independent-slope /
  # correlated scale REs -- NOT larger (q > 2) scale covariance blocks, which stay
  # unsupported (a general residual-scale limitation, under ML and REML alike).
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id), sigma ~ 1 + (1 + x + x2 | id)),
      family = gaussian(), data = d, REML = TRUE
    ),
    "random intercept|independent|q > 2|covariance"
  )
})
