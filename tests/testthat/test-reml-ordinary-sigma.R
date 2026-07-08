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

test_that("REML admits a CORRELATED residual-scale intercept+slope block", {
  skip_on_cran()
  # `sigma ~ x + (1 + x | id)` is implemented as of 2026-07-08 (new same-dpar
  # conditioning in the univariate C++ likelihood). Recovery of (sd_int, sd_slope, rho)
  # is validated in scratchpad/correlated_scale_slope_recovery.R.
  d <- make_dhglm(n_id = 60L, n_each = 10L, seed = 4L)
  fit <- suppressWarnings(drmTMB(
    bf(y ~ x + (1 | id), sigma ~ x + (1 + x | id)),
    family = gaussian(), data = d, REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  ))
  expect_identical(fit$estimator, "REML")
  expect_identical(fit$opt$convergence, 0L)
  v <- setNames(summary(fit)$parameters$estimate, summary(fit)$parameters$parm)
  # two scale-side SDs (intercept + slope) and their correlation are estimated
  expect_length(v[grepl("^sd:sigma", names(v))], 2L)
  expect_true(any(grepl("^cor", names(v)) & grepl("sigma", names(v))))
})

test_that("the relaxation stays bounded: LABELLED residual-scale slope blocks remain rejected", {
  skip_on_cran()
  d <- make_dhglm()
  # Unlabelled correlated residual-scale blocks are implemented; the LABELLED
  # univariate residual-scale slope covariance block remains planned.
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | id), sigma ~ 1 + (1 + x | p | id)),
      family = gaussian(), data = d, REML = TRUE
    ),
    "Labelled residual-scale random-slope covariance blocks"
  )
})

test_that("REML admits a bivariate labelled scale-side sigma block", {
  skip_on_cran()
  # Bivariate ordinary sigma random effects: a labelled scale-side block (1|s|id) on
  # sigma1/sigma2. Admitted under REML (biv gate relaxed 2026-07-08); a biv recovery
  # ladder (scratchpad/reml_biv_sigma_re_probe.R) shows both scale-RE SDs recover
  # under ML and REML with REML at least as good. A biv MEAN-scale correlation stays
  # rejected (not validated).
  set.seed(2L)
  n_id <- 40L; n_each <- 8L; n <- n_id * n_each
  id <- rep(seq_len(n_id), each = n_each); x <- stats::rnorm(n)
  Ss <- chol(matrix(c(.4^2, .3 * .4 * .35, .3 * .4 * .35, .35^2), 2, 2))
  a <- matrix(stats::rnorm(n_id * 2), n_id, 2) %*% Ss
  d <- data.frame(
    id = factor(id), x = x,
    y1 = .3 + .5 * x + stats::rnorm(n, 0, exp(log(.5) + a[id, 1])),
    y2 = .6 + .2 * x + stats::rnorm(n, 0, exp(log(.6) + a[id, 2]))
  )
  fit <- suppressWarnings(drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x,
       sigma1 = ~ 1 + (1 | s | id), sigma2 = ~ 1 + (1 | s | id), rho12 = ~ 1),
    family = biv_gaussian(), data = d, REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  ))
  expect_identical(fit$estimator, "REML")
  expect_identical(fit$opt$convergence, 0L)
  v <- setNames(summary(fit)$parameters$estimate, summary(fit)$parameters$parm)
  sds <- v[grepl("^sd:sigma:", names(v))]
  expect_length(sds, 2L)
  expect_true(all(is.finite(sds) & sds > 0))
})
