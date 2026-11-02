gamma_animal_correlated_data <- function(seed = 20261101L, rho = 0.5) {
  set.seed(seed)
  n_group <- 40L
  n_each <- 16L
  id_levels <- sprintf("animal_%02d", seq_len(n_group))
  A <- 0.45^abs(outer(seq_len(n_group), seq_len(n_group), "-"))
  dimnames(A) <- list(id_levels, id_levels)
  L <- t(chol(A))
  z0 <- drop(L %*% stats::rnorm(n_group))
  z1 <- drop(L %*% stats::rnorm(n_group))
  # Unit-scale latent fields with cross-coefficient correlation rho.
  f0 <- z0
  f1 <- rho * z0 + sqrt(1 - rho^2) * z1
  s0_group <- rep(c(-1, 1), each = n_group / 2L)
  s1_group <- rep(c(-1, 1), times = n_group / 2L)
  alpha0 <- c(`(Intercept)` = log(0.40), s0 = 0.35)
  alpha1 <- c(`(Intercept)` = log(0.32), s1 = -0.40)
  b0 <- exp(alpha0[[1L]] + alpha0[[2L]] * s0_group) * f0
  b1 <- exp(alpha1[[1L]] + alpha1[[2L]] * s1_group) * f1
  gi <- rep(seq_len(n_group), each = n_each)
  x <- rep(seq(-1.2, 1.2, length.out = n_each), times = n_group)
  mu <- exp(0.25 + 0.2 * x + b0[gi] + x * b1[gi])
  shape <- 0.4^-2
  data.frame(
    y = stats::rgamma(length(mu), shape = shape, rate = shape / mu),
    x = x,
    id = factor(id_levels[gi], levels = id_levels),
    s0 = s0_group[gi],
    s1 = s1_group[gi]
  ) -> dat
  list(data = dat, A = A, rho = rho)
}

gamma_animal_corr_formula <- function(A, label = "p") {
  term <- if (is.null(label)) {
    "animal(1 + x | id, A = A)"
  } else {
    sprintf("animal(1 + x | %s | id, A = A)", label)
  }
  stats::as.formula(paste("y ~ x +", term)) -> mu_form
  environment(mu_form) <- environment()
  bf(
    mu_form,
    sigma ~ 1,
    sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ s0,
    sd(id, level = "animal", dpar = "mu", coef = "x") ~ s1
  )
}

# Fits are deterministic given the seed; cache them so the recovery test and
# the likelihood test do not refit the same model.
gamma_animal_fit_cache <- new.env(parent = emptyenv())
gamma_animal_fit <- function(seed, label) {
  key <- paste(seed, if (is.null(label)) "none" else label)
  if (is.null(gamma_animal_fit_cache[[key]])) {
    sim <- gamma_animal_correlated_data(seed)
    A <- sim$A
    gamma_animal_fit_cache[[key]] <- list(
      sim = sim,
      fit = drmTMB(
        gamma_animal_corr_formula(A, label = label),
        family = stats::Gamma(link = "log"), data = sim$data, engine = "tmb"
      )
    )
  }
  gamma_animal_fit_cache[[key]]
}

# Joint (data + latent prior) negative log likelihood at the fitted parameters,
# recomputed in plain R from the fitted coefficients and latent fields. It
# uses dense A (not Q_phylo, not log_det_Q) and stats::dgamma, so it shares no
# code with the C++ objective. `rho` is the prior correlation; 0 for the
# unlabelled independent-fields fit. `perturb` emulates a specific bug so the
# test can show the oracle is able to disagree with the correct fit.
gamma_animal_joint_oracle <- function(fit, sim, rho, perturb = "none") {
  env <- fit$obj$env
  par <- env$last.par.best
  pl <- env$parList(x = par[-env$random], par = par)
  d <- sim$data
  n <- nlevels(d$id)
  gi <- as.integer(d$id)
  u1 <- pl$u_phylo[seq_len(n)]
  u2 <- pl$u_phylo[n + seq_len(n)]
  b <- unname(pl$beta_sd_mu)
  # coefficient-specific SD formulas: intercept SD on s0, slope SD on s1
  sd0 <- exp(b[1L] + b[2L] * d$s0)
  sd1 <- exp(b[3L] + b[4L] * d$s1)
  if (perturb == "swap_sd_formulas") {
    sd0 <- exp(b[3L] + b[4L] * d$s0)
    sd1 <- exp(b[1L] + b[2L] * d$s1)
  }
  f0 <- if (perturb == "swap_fields") u2 else u1
  f1 <- if (perturb == "swap_fields") u1 else u2
  eta <- pl$beta_mu[[1L]] + pl$beta_mu[[2L]] * d$x +
    sd0 * f0[gi] + d$x * sd1 * f1[gi]
  shape <- exp(pl$beta_sigma)^-2
  data_nll <- -sum(stats::dgamma(
    d$y, shape = shape, rate = shape / exp(eta), log = TRUE
  ))
  A <- sim$A
  logdet_A <- as.numeric(determinant(A, logarithm = TRUE)$modulus)
  Ainv <- solve(A)
  q11 <- sum(u1 * (Ainv %*% u1))
  q12 <- sum(u1 * (Ainv %*% u2))
  q22 <- sum(u2 * (Ainv %*% u2))
  if (perturb == "drop_rho") rho <- 0
  one <- 1 - rho^2
  cross <- (if (perturb == "cross_sign") -1 else 1) * 2 * rho * q12
  # log det(R (x) A) = n log(1 - rho^2) + 2 log det(A); "logdet_once" counts
  # the A part once, i.e. log_det_Q once instead of twice.
  logdet <- n * log(one) +
    (if (perturb == "logdet_once") 1 else 2) * logdet_A
  prior <- 0.5 * (2 * n * log(2 * pi) + logdet + (q11 + q22 - cross) / one)
  data_nll + prior
}

test_that("labelled Gamma animal q2 SD regression estimates the cross-coefficient correlation", {
  skip_on_cran()
  fx <- gamma_animal_fit(20261101L, "p")
  sim <- fx$sim
  fit_corr <- fx$fit
  fit_ind <- gamma_animal_fit(20261101L, NULL)$fit
  # The no-warning expectation is in its own test below, because this test
  # uses cached fits.

  expect_true(is_converged(fit_corr))
  expect_true(is_converged(fit_ind))

  key <- "cor(mu:(Intercept),mu:x | p | id)"
  expect_named(fit_corr$corpars$animal, key)
  rho_hat <- unname(fit_corr$corpars$animal[[key]])
  expect_true(is.finite(rho_hat))
  expect_lt(abs(rho_hat), 1)
  # Fixed-seed recovery band, not a calibration claim; the next test repeats
  # it for two further fixed seeds.
  expect_lt(abs(rho_hat - sim$rho), 0.4)
  expect_true(is.finite(fit_corr$obj$report()$rho_phylo))

  # The reported rho must be evaluated at the optimum. obj$report() with no
  # argument uses env$last.par, the last objective evaluation, which depends on
  # call history and need not be the optimum (on a freshly built fit it gave
  # 0.5239 against 0.5246 at the optimum), so the optimum is requested
  # explicitly via last.par.best.
  rho_report <- fit_corr$obj$report(fit_corr$obj$env$last.par.best)$rho_phylo
  expect_equal(rho_report, rho_hat, tolerance = 1e-8)

  # The independent fit is nested in the correlated one, so a free rho that
  # the likelihood actually uses cannot lower the maximised log likelihood,
  # and with true rho = 0.5 it must raise it.
  expect_gt(
    as.numeric(logLik(fit_corr)), as.numeric(logLik(fit_ind)) + 1e-6
  )

  # Both coefficient-specific SD regressions stay reported and signed.
  key0 <- 'sd_animal(id, dpar = "mu", coef = "(Intercept)")'
  key1 <- 'sd_animal(id, dpar = "mu", coef = "x")'
  expect_named(coef(fit_corr, key0), c("(Intercept)", "s0"))
  expect_named(coef(fit_corr, key1), c("(Intercept)", "s1"))
  expect_gt(coef(fit_corr, key0)[["s0"]], 0)
  expect_lt(coef(fit_corr, key1)[["s1"]], 0)
})

test_that("labelled Gamma animal q2 fit builds without warnings", {
  skip_on_cran()
  sim <- gamma_animal_correlated_data()
  expect_no_warning(
    drmTMB(
      gamma_animal_corr_formula(sim$A, label = "p"),
      family = stats::Gamma(link = "log"), data = sim$data, engine = "tmb"
    )
  )
})

test_that("Gamma animal q2 joint objective matches an independent R computation", {
  skip_on_cran()
  # Tolerances fixed before the first run: the oracle must agree with the
  # TMB joint objective (data + latent prior, random effects as parameters)
  # to 1e-6 absolute (objective is ~4e2, double precision gives ~1e-11), and
  # each emulated bug must move the oracle by more than 1e-3.
  tol_exact <- 1e-6
  tol_sensitive <- 1e-3
  bugs <- c(
    "logdet_once", "cross_sign", "drop_rho",
    "swap_sd_formulas", "swap_fields"
  )

  for (seed in c(20261101L, 20261102L, 20261103L)) {
    fx <- gamma_animal_fit(seed, "p")
    fit <- fx$fit
    env <- fit$obj$env
    joint <- env$f(env$last.par.best)
    rho <- fit$obj$report(env$last.par.best)$rho_phylo
    expect_lt(
      abs(gamma_animal_joint_oracle(fit, fx$sim, rho) - joint), tol_exact
    )
    # Non-vacuity: each emulated bug disagrees with the real objective.
    for (bug in bugs) {
      expect_gt(
        abs(gamma_animal_joint_oracle(fit, fx$sim, rho, bug) - joint),
        tol_sensitive
      )
    }
  }

  # The unlabelled fit has independent unit-scale fields, i.e. rho = 0; the
  # same oracle must reproduce its joint objective, so the labelled and
  # unlabelled prior terms share one independent reference.
  fx_ind <- gamma_animal_fit(20261101L, NULL)
  env_ind <- fx_ind$fit$obj$env
  expect_lt(
    abs(
      gamma_animal_joint_oracle(fx_ind$fit, fx_ind$sim, rho = 0) -
        env_ind$f(env_ind$last.par.best)
    ),
    tol_exact
  )
})

test_that("labelled Gamma animal q2 recovery holds on three fixed seeds", {
  skip_on_cran()
  # Seeds fixed in advance (no selection); rho = 0.5; same 0.4 band as above.
  for (seed in c(20261101L, 20261102L, 20261103L)) {
    fx <- gamma_animal_fit(seed, "p")
    expect_true(is_converged(fx$fit))
    rho_hat <- unname(fx$fit$corpars$animal[[1L]])
    expect_lt(abs(rho_hat - fx$sim$rho), 0.4)
  }
})

test_that("labelled Gamma animal q2 refusals are designed errors", {
  skip_on_cran()
  sim <- gamma_animal_correlated_data()
  A <- sim$A
  d <- sim$data
  d$z <- cos(seq_len(nrow(d)))
  gam <- stats::Gamma(link = "log")
  sd_int <- sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ s0
  sd_x <- sd(id, level = "animal", dpar = "mu", coef = "x") ~ s1

  # Labelled, no sd() formulas.
  f_lab <- y ~ x + animal(1 + x | p | id, A = A)
  expect_error(
    drmTMB(bf(f_lab, sigma ~ 1), family = gam, data = d, engine = "tmb"),
    "requires\\s+predictor-dependent\\s+SD\\s+formulas"
  )

  # Labelled slope-only term, even with an sd() formula on the slope.
  f_slope <- y ~ x + animal(0 + x | p | id, A = A)
  expect_error(
    drmTMB(bf(f_slope, sigma ~ 1, sd_x), family = gam, data = d, engine = "tmb"),
    "support\\s+a\\s+covariance\\s+label\\s+only\\s+on\\s+one\\s+intercept\\s+plus\\s+one\\s+numeric\\s+slope"
  )

  # Labelled block with more than an intercept and one slope.
  f_three <- y ~ x + z + animal(1 + x + z | p | id, A = A)
  expect_error(
    drmTMB(
      bf(f_three, sigma ~ 1, sd_int, sd_x,
         sd(id, level = "animal", dpar = "mu", coef = "z") ~ 1),
      family = gam, data = d, engine = "tmb"
    ),
    "support\\s+only\\s+an\\s+unlabelled\\s+q=1\\s+intercept"
  )

  # Labelled with an sd() formula on only one coefficient (either one).
  pattern_one <- "requires\\s+one\\s+SD\\s+formula\\s+for\\s+each\\s+coefficient"
  expect_error(
    drmTMB(bf(f_lab, sigma ~ 1, sd_int), family = gam, data = d, engine = "tmb"),
    pattern_one
  )
  expect_error(
    drmTMB(bf(f_lab, sigma ~ 1, sd_x), family = gam, data = d, engine = "tmb"),
    pattern_one
  )
})

test_that("unlabelled Gamma animal q2 SD regression stays independent", {
  skip_on_cran()
  # Not tested here: that the unlabelled path is bit-for-bit unchanged by the
  # labelled-block work. This test only shows it still converges and reports
  # no cross-coefficient correlation; the joint-objective test above checks
  # its objective against an independent rho = 0 computation, which is
  # agreement to 1e-6, not bit identity.
  fit <- gamma_animal_fit(20261101L, NULL)$fit
  expect_true(is_converged(fit))
  expect_null(fit$corpars$animal)
})

test_that("Gamma animal q2 joint objective uses the raw non-unit-diagonal A", {
  skip_on_cran()
  # G1 review C6: the fixtures above use a unit-diagonal A, so a refactor that
  # normalised A to a correlation matrix would pass them. Here A = D A0 D with
  # a visibly non-unit diagonal, passed to drmTMB in shuffled row/column order
  # while the oracle indexes latent nodes in the supplied A order (the fitted
  # u_phylo follows the rows of A, observations map by name). Tolerances fixed before the
  # first run: agreement 1e-6 absolute; the "normalised A" bug must move the
  # oracle by more than 1e-3; the diagonal must differ from 1 by more than 0.3.
  tol_exact <- 1e-6
  tol_sensitive <- 1e-3
  sim <- gamma_animal_correlated_data(20261101L)
  n <- nlevels(sim$data$id)
  set.seed(77L)
  scale_d <- exp(stats::runif(n, log(0.6), log(1.8)))
  A_ord <- sim$A * outer(scale_d, scale_d)
  expect_gt(max(abs(diag(A_ord) - 1)), 0.3)
  perm <- sample.int(n)
  expect_false(identical(perm, seq_len(n)))
  A_shuf <- A_ord[perm, perm]
  expect_identical(rownames(A_shuf), rownames(A_ord)[perm])

  fit <- drmTMB(
    gamma_animal_corr_formula(A_shuf, label = "p"),
    family = stats::Gamma(link = "log"), data = sim$data, engine = "tmb"
  )
  expect_true(is_converged(fit))
  env <- fit$obj$env
  joint <- env$f(env$last.par.best)
  rho <- fit$obj$report(env$last.par.best)$rho_phylo
  d_node <- sim$data
  d_node$id <- factor(as.character(d_node$id), levels = rownames(A_shuf))
  sim_raw <- list(data = d_node, A = A_shuf)
  expect_lt(abs(gamma_animal_joint_oracle(fit, sim_raw, rho) - joint), tol_exact)
  sim_norm <- list(data = d_node, A = stats::cov2cor(A_shuf))
  expect_gt(
    abs(gamma_animal_joint_oracle(fit, sim_norm, rho) - joint), tol_sensitive
  )
})

test_that("Gamma animal q2 SD route has no constant structured SD parameter free", {
  skip_on_cran()
  # G1 review C6: with per-coefficient SD formulas the constant log_sd_phylo
  # must be mapped off (src/drmTMB.cpp reads only beta_sd_mu rows), for both
  # the labelled and the unlabelled q2 fit.
  for (label in list("p", NULL)) {
    fit <- gamma_animal_fit(20261101L, label)$fit
    expect_false("log_sd_phylo" %in% names(fit$obj$par))
    expect_true("beta_sd_mu" %in% names(fit$obj$par))
  }
})
