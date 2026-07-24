source(
  system.file("sim/fit/sim_meta_v_lss_oracle.R", package = "drmTMB", mustWork = TRUE),
  local = TRUE
)

meta_v_oracle_draw <- function(mean, covariance) {
  drop(mean + t(chol(covariance)) %*% stats::rnorm(length(mean)))
}

meta_v_oracle_loglik_from_fit <- function(
  fit,
  V,
  study = NULL,
  effect = NULL
) {
  args <- list(
    y = fit$model$y,
    X_mu = fit$model$X$mu,
    beta_mu = stats::coef(fit, dpar = "mu"),
    V = V,
    X_sigma = fit$model$X$sigma,
    beta_sigma = stats::coef(fit, dpar = "sigma")
  )
  if (!is.null(study)) {
    args$study <- study
    args$X_sd_study <- fit$model$X[["sd(study)"]]
    args$beta_sd_study <- stats::coef(fit, dpar = "sd(study)")
  }
  if (!is.null(effect)) {
    args$effect <- effect
    args$X_sd_effect <- fit$model$X[["sd(effect)"]]
    args$beta_sd_effect <- stats::coef(fit, dpar = "sd(effect)")
  }
  do.call(meta_v_lss_oracle_loglik, args)
}

test_that("meta_V LS diagonal likelihood matches the direct Gaussian oracle", {
  set.seed(2026072401)
  n <- 72L
  dat <- data.frame(
    x = stats::rnorm(n),
    z = seq(-0.7, 0.7, length.out = n),
    vi = seq(0.012, 0.032, length.out = n)
  )
  mean <- 0.15 + 0.45 * dat$x
  sigma <- exp(-0.95 + 0.30 * dat$z)
  dat$yi <- stats::rnorm(n, mean = mean, sd = sqrt(dat$vi + sigma^2))

  fit <- drmTMB(
    bf(yi ~ x + meta_V(V = vi), sigma ~ z),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    as.numeric(stats::logLik(fit)),
    meta_v_oracle_loglik_from_fit(fit, V = dat$vi),
    tolerance = 1e-6
  )
})

test_that("meta_V LSS dense likelihood includes the direct-SD study layer", {
  set.seed(2026072402)
  n_study <- 12L
  n_each <- 6L
  n <- n_study * n_each
  study <- factor(rep(seq_len(n_study), each = n_each))
  study_z <- rep(seq(-0.6, 0.6, length.out = n_study), each = n_each)
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n),
    study = study,
    study_z = study_z
  )
  V <- 0.016 * outer(seq_len(n), seq_len(n), function(i, j) 0.35^abs(i - j))
  sigma <- exp(-1.05 + 0.18 * dat$z)
  study_sd <- exp(-1.05 + 0.32 * seq(-0.6, 0.6, length.out = n_study))
  study_effect <- study_sd * stats::rnorm(n_study)
  mean <- 0.10 + 0.40 * dat$x + study_effect[study]
  dat$yi <- meta_v_oracle_draw(mean, V + diag(sigma^2, n))

  fit <- drmTMB(
    bf(
      yi ~ x + (1 | study) + meta_V(V = V),
      sigma ~ z,
      sd(study) ~ study_z
    ),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    as.numeric(stats::logLik(fit)),
    meta_v_oracle_loglik_from_fit(fit, V = V, study = dat$study),
    tolerance = 1e-6
  )
})

test_that("meta_V LSSS diagonal likelihood adds two direct-SD group layers", {
  set.seed(2026072403)
  n_study <- 12L
  n_effect <- 7L
  n_rep <- 2L
  study <- factor(rep(rep(seq_len(n_study), each = n_effect), each = n_rep))
  effect_within <- factor(rep(seq_len(n_effect), each = n_rep, times = n_study))
  effect <- interaction(study, effect_within, drop = TRUE)
  n <- length(study)
  study_z <- rep(seq(-0.5, 0.5, length.out = n_study), each = n_effect * n_rep)
  effect_z <- rep(seq(-0.45, 0.45, length.out = n_effect), each = n_rep)
  effect_z <- rep(effect_z, times = n_study)
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n),
    study = study,
    effect = effect,
    study_z = study_z,
    effect_z = effect_z,
    vi = seq(0.010, 0.030, length.out = n)
  )
  sigma <- exp(-1.15 + 0.16 * dat$z)
  study_sd <- exp(-1.10 + 0.28 * seq(-0.5, 0.5, length.out = n_study))
  effect_sd <- exp(-1.25 - 0.20 * as.numeric(tapply(effect_z, effect, unique)))
  mean <- 0.20 + 0.35 * dat$x +
    study_sd[study] * stats::rnorm(n_study)[study] +
    effect_sd[effect] * stats::rnorm(nlevels(effect))[effect]
  dat$yi <- stats::rnorm(n, mean = mean, sd = sqrt(dat$vi + sigma^2))

  fit <- drmTMB(
    bf(
      yi ~ x + (1 | study) + (1 | effect) + meta_V(V = vi),
      sigma ~ z,
      sd(study) ~ study_z,
      sd(effect) ~ effect_z
    ),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    as.numeric(stats::logLik(fit)),
    meta_v_oracle_loglik_from_fit(
      fit,
      V = dat$vi,
      study = dat$study,
      effect = dat$effect
    ),
    tolerance = 1e-6
  )
})
