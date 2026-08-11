mspl_test_control <- function(multi_start = 2L) {
  drm_control(
    se = FALSE,
    optimizer_preset = "careful",
    multi_start = multi_start
  )
}

mspl_independent_nll_penalty <- function(fit, par) {
  native <- fit$obj$env$parList(par)
  X <- fit$model$X$mu
  beta <- as.numeric(native$beta_mu)
  eta <- drop(fit$model$offset$mu + X %*% beta)
  log_weight <- log(fit$model$weights * fit$model$trials) -
    pmax(eta, 0) - log1p(exp(-abs(eta))) -
    pmax(-eta, 0) - log1p(exp(-abs(eta)))
  anchor <- max(log_weight)
  scaled_information <- crossprod(X, X * exp(log_weight - anchor))
  determinant <- determinant(scaled_information, logarithm = TRUE)
  stopifnot(determinant$sign > 0)
  jeffreys <- 0.5 * (as.numeric(determinant$modulus) + ncol(X) * anchor)

  log_sd <- as.numeric(native$log_sd_mu)
  coordinates <- if (identical(fit$mspl$q, 1L)) {
    log_sd[[1L]]
  } else {
    z <- as.numeric(native$eta_cor_mu)[[1L]]
    log_sech <- log(2) - abs(z) - log1p(exp(-2 * abs(z)))
    c(log_sd[[1L]], log_sd[[2L]] + log_sech, exp(log_sd[[2L]]) * tanh(z))
  }
  negative_huber <- ifelse(
    abs(coordinates) <= 1,
    -0.5 * coordinates^2,
    -abs(coordinates) + 0.5
  )
  -fit$mspl$c_n * (jeffreys + sum(negative_huber))
}

mspl_q1_fixture <- function(kind = c("overlap", "complete", "mirrored", "quasi")) {
  kind <- match.arg(kind)
  if (identical(kind, "quasi")) {
    group <- factor(rep(seq_len(15), each = 6L))
    x <- rep(c(-1, -1, 0, 0, 1, 1), 15L)
    y <- rep(c(0, 0, 0, 1, 1, 1), 15L)
    return(data.frame(y, x, group))
  }
  group <- factor(rep(seq_len(12), each = 4L))
  x <- rep(c(-2, -1, 1, 2), 12L)
  if (identical(kind, "overlap")) {
    y <- rep(c(0, 1, 0, 1), 12L)
  } else {
    y <- as.integer(x > 0)
    if (identical(kind, "mirrored")) y <- 1L - y
  }
  data.frame(y, x, group)
}

test_that("default and explicit ML remain equivalent", {
  dat <- mspl_q1_fixture("overlap")
  default <- drmTMB(
    bf(y ~ x + (1 | group)), binomial(), dat,
    control = drm_control(se = FALSE)
  )
  explicit <- drmTMB(
    bf(y ~ x + (1 | group)), binomial(), dat,
    estimator = "ml", control = drm_control(se = FALSE)
  )
  expect_identical(default$estimator, "ML")
  expect_identical(explicit$estimator, "ML")
  expect_equal(default$opt$par, explicit$opt$par, tolerance = 0)
  expect_equal(default$opt$objective, explicit$opt$objective, tolerance = 0)
  expect_null(default$mspl)
})

test_that("the estimator a fit reports is accepted back by drmTMB() (#983)", {
  # The round trip is the point: `fit$estimator` is upper case, so a user who
  # reads it off a fit and passes it back must not hit an error.
  expect_identical(drm_match_estimator("ML"), "ml")
  expect_identical(drm_match_estimator("MSPL"), "mspl")
  expect_identical(drm_match_estimator("ml"), "ml")
  expect_identical(drm_match_estimator("mspl"), "mspl")
  expect_identical(drm_match_estimator("Ml"), "ml")
  expect_identical(drm_match_estimator(c("ml", "mspl")), "ml")
  expect_error(drm_match_estimator("reml"))
  expect_error(drm_match_estimator("nonsense"))

  dat <- mspl_q1_fixture("overlap")
  fit <- drmTMB(
    bf(y ~ x + (1 | group)), binomial(), dat,
    control = drm_control(se = FALSE)
  )
  expect_identical(fit$estimator, "ML")
  round_trip <- drmTMB(
    bf(y ~ x + (1 | group)), binomial(), dat,
    estimator = fit$estimator, control = drm_control(se = FALSE)
  )
  expect_identical(round_trip$estimator, "ML")
  expect_equal(round_trip$opt$par, fit$opt$par, tolerance = 0)
})

test_that("the optional fixed-X detector has a deterministic unavailable receipt", {
  dat <- mspl_q1_fixture("overlap")
  fit <- drmTMB(
    bf(y ~ x + (1 | group)), binomial(), dat,
    estimator = "mspl", control = mspl_test_control(1L)
  )
  fallback <- drmTMB:::drm_mspl_detector(
    fit$model, detector_available = FALSE
  )
  expect_false(fallback$available)
  expect_identical(fallback$status, "unavailable")
  expect_match(fallback$message, "Install.*detectseparation")
})

test_that("MSPL retains finite point estimates in both complete tails and quasi separation", {
  fits <- lapply(c("complete", "mirrored", "quasi"), function(kind) {
    drmTMB(
      bf(y ~ x + (1 | group)), binomial(), mspl_q1_fixture(kind),
      estimator = "mspl", control = mspl_test_control()
    )
  })
  slopes <- vapply(fits, function(fit) coef(fit, "mu")[["x"]], numeric(1L))
  expect_true(all(is.finite(slopes)))
  expect_gt(slopes[[1L]], 0)
  expect_lt(slopes[[2L]], 0)
  expect_gt(slopes[[3L]], 0)
  if (requireNamespace("detectseparation", quietly = TRUE)) {
    expect_true(all(vapply(fits, function(fit) fit$mspl$detector$outcome, logical(1L))))
  } else {
    expect_true(all(vapply(
      fits,
      function(fit) identical(fit$mspl$detector$status, "unavailable"),
      logical(1L)
    )))
  }
  expect_true(all(vapply(fits, function(fit) fit$opt$convergence == 0L, logical(1L))))
  expect_true(all(vapply(
    fits,
    function(fit) fit$mspl$numerical$gradient_max_abs < 1e-3,
    logical(1L)
  )))
  expect_true(all(vapply(
    fits,
    function(fit) abs(fit$mspl$objective_identity_error) < 1e-7,
    logical(1L)
  )))
  ml <- suppressWarnings(drmTMB(
    bf(y ~ x + (1 | group)), binomial(), mspl_q1_fixture("complete"),
    estimator = "ml", control = mspl_test_control(1L)
  ))
  expect_gt(abs(coef(ml, "mu")[["x"]]), abs(slopes[[1L]]))
  expect_true(all(vapply(
    fits,
    function(fit) isTRUE(fit$mspl$numerical$hessian_positive_definite),
    logical(1L)
  )))
})

test_that("grouped counts, Bernoulli expansion, frequency, offsets, and row order agree", {
  group <- factor(rep(seq_len(10), each = 4L))
  x <- rep(c(-1.5, -0.5, 0.5, 1.5), 10L)
  trials <- rep(c(2L, 3L, 2L, 4L), 10L)
  successes <- rep(c(0L, 1L, 1L, 3L), 10L)
  frequency <- rep(c(1L, 2L, 1L, 1L), 10L)
  off <- rep(c(-0.25, 0.1, 0.2, -0.1), 10L)
  grouped <- data.frame(successes, failures = trials - successes, x, group, off, frequency)
  grouped_fit <- drmTMB(
    bf(cbind(successes, failures) ~ x + offset(off) + (1 | group)),
    binomial(), grouped, weights = frequency,
    estimator = "mspl", control = mspl_test_control()
  )

  expanded <- do.call(rbind, lapply(seq_len(nrow(grouped)), function(i) {
    data.frame(
      y = rep(c(1L, 0L), c(successes[[i]], trials[[i]] - successes[[i]])),
      x = grouped$x[[i]], group = grouped$group[[i]], off = grouped$off[[i]]
    )[rep(seq_len(trials[[i]]), frequency[[i]]), , drop = FALSE]
  }))
  expanded$group <- factor(expanded$group, levels = levels(grouped$group))
  expanded_fit <- drmTMB(
    bf(y ~ x + offset(off) + (1 | group)), binomial(), expanded,
    estimator = "mspl", control = mspl_test_control()
  )
  expect_equal(coef(grouped_fit, "mu"), coef(expanded_fit, "mu"), tolerance = 2e-5)
  expect_equal(grouped_fit$sdpars$mu, expanded_fit$sdpars$mu, tolerance = 2e-5)
  expect_equal(
    grouped_fit$mspl$components$mspl_log_objective_bonus,
    expanded_fit$mspl$components$mspl_log_objective_bonus,
    tolerance = 2e-6
  )
  expect_equal(grouped_fit$mspl$n_eff, nrow(expanded))
  grouped_constant <- sum(frequency * lchoose(trials, successes))
  expect_equal(
    grouped_fit$mspl$unpenalized_laplace_logLik - grouped_constant,
    expanded_fit$mspl$unpenalized_laplace_logLik,
    tolerance = 2e-6
  )

  perm <- rev(seq_len(nrow(grouped)))
  reordered <- drmTMB(
    bf(cbind(successes, failures) ~ x + offset(off) + (1 | group)),
    binomial(), grouped[perm, ], weights = frequency,
    estimator = "mspl", control = mspl_test_control()
  )
  expect_equal(coef(reordered, "mu"), coef(grouped_fit, "mu"), tolerance = 2e-5)
  expect_equal(reordered$sdpars$mu, grouped_fit$sdpars$mu, tolerance = 2e-5)

  with_zero <- rbind(
    grouped,
    data.frame(successes = 999L, failures = 0L, x = 999, group = group[[1L]], off = 0, frequency = 0L)
  )
  zero_fit <- drmTMB(
    bf(cbind(successes, failures) ~ x + offset(off) + (1 | group)),
    binomial(), with_zero, weights = with_zero$frequency,
    estimator = "mspl", control = mspl_test_control()
  )
  expect_equal(coef(zero_fit, "mu"), coef(grouped_fit, "mu"), tolerance = 1e-8)
})

test_that("MSPL point fits are equivariant to predictor rescaling and factor contrasts", {
  dat <- mspl_q1_fixture("overlap")
  base <- drmTMB(
    bf(y ~ x + (1 | group)), binomial(), dat,
    estimator = "mspl", control = mspl_test_control()
  )
  dat$x_scaled <- dat$x / 5
  scaled <- drmTMB(
    bf(y ~ x_scaled + (1 | group)), binomial(), dat,
    estimator = "mspl", control = mspl_test_control()
  )
  expect_equal(coef(scaled, "mu")[[1L]], coef(base, "mu")[[1L]], tolerance = 2e-5)
  expect_equal(coef(scaled, "mu")[[2L]] / 5, coef(base, "mu")[[2L]], tolerance = 2e-5)
  expect_equal(predict(scaled), predict(base), tolerance = 2e-5)
  expect_equal(
    predict(base, type = "response", re.form = NULL),
    stats::plogis(predict(base, type = "link", re.form = NULL)),
    tolerance = 1e-12
  )

  dat$band <- factor(rep(c("low", "middle", "high", "middle"), 12L))
  treatment <- drmTMB(
    bf(y ~ band + (1 | group)), binomial(), dat,
    estimator = "mspl", control = mspl_test_control()
  )
  sum_dat <- dat
  contrasts(sum_dat$band) <- contr.sum(3L)
  sum_coded <- drmTMB(
    bf(y ~ band + (1 | group)), binomial(), sum_dat,
    estimator = "mspl", control = mspl_test_control()
  )
  expect_equal(predict(sum_coded), predict(treatment), tolerance = 2e-5)
})

test_that("q2 MSPL uses the paper Cholesky coordinates and permits point output only", {
  set.seed(20260808)
  n_group <- 24L
  n_each <- 7L
  group <- factor(rep(seq_len(n_group), each = n_each))
  x <- rep(seq(-1, 1, length.out = n_each), n_group)
  z1 <- rnorm(n_group)
  z2 <- rnorm(n_group)
  sd1 <- 0.65
  sd2 <- 0.35
  rho <- -0.45
  u1 <- sd1 * z1
  u2 <- sd2 * (rho * z1 + sqrt(1 - rho^2) * z2)
  eta <- -0.1 + 0.75 * x + u1[group] + x * u2[group]
  trials <- rep(3L, length(x))
  successes <- rbinom(length(x), trials, plogis(eta))
  dat <- data.frame(successes, failures = trials - successes, x, group)
  fit <- drmTMB(
    bf(cbind(successes, failures) ~ x + (1 + x | group)),
    binomial(), dat, estimator = "mspl", control = mspl_test_control(3L)
  )
  native <- fit$obj$env$parList(fit$opt$par)
  oracle <- mspl_penalty_components(
    X = fit$model$X$mu,
    beta = unname(native$beta_mu),
    variance = c(unname(native$log_sd_mu), unname(native$eta_cor_mu)),
    q = 2L,
    offset = fit$model$offset$mu,
    trials = fit$model$trials,
    frequency = fit$model$weights
  )
  expect_true(oracle$ok)
  expect_equal(fit$mspl$components$mspl_jeffreys, oracle$jeffreys_bonus, tolerance = 1e-8)
  expect_equal(
    fit$mspl$components$mspl_variance_negative_huber,
    oracle$variance_negative_huber,
    tolerance = 1e-8
  )
  expect_equal(unname(fit$corpars$mu), tanh(native$eta_cor_mu), tolerance = 1e-12)
  expect_true(fit$mspl$numerical$hessian_positive_definite)
  expect_lt(fit$mspl$numerical$gradient_max_abs, 1e-3)
  expect_false(fit$mspl$boundary$optimizer_bound_contact)
  expect_false(fit$mspl$boundary$logsigma_clamp_active)

  probes <- lapply(
    list(
      c(log_sd = -6, eta = -8, beta = 0),
      c(log_sd = 4, eta = 8, beta = 0),
      c(log_sd = 4, eta = -8, beta = 12)
    ),
    function(probe) {
      par <- fit$opt$par
      par[grepl("^log_sd_mu", names(par))] <- probe[["log_sd"]]
      par[grepl("^eta_cor_mu", names(par))] <- probe[["eta"]]
      par[grepl("^beta_mu", names(par))] <- probe[["beta"]]
      fit$obj$fn(par)
    }
  )
  expect_true(all(is.finite(unlist(probes))))
  expect_true(all(unlist(probes) > fit$opt$objective))

  single_start <- drmTMB(
    bf(cbind(successes, failures) ~ x + (1 + x | group)),
    binomial(), dat, estimator = "mspl", control = mspl_test_control(1L)
  )
  expect_equal(single_start$opt$par, fit$opt$par, tolerance = 2e-4)
  expect_equal(single_start$opt$objective, fit$opt$objective, tolerance = 1e-6)
  expect_true(all(is.finite(predict(fit, type = "response"))))
  conditional_link <- predict(fit, type = "link", re.form = NULL)
  expect_equal(
    predict(fit, type = "response", re.form = NULL),
    stats::plogis(conditional_link),
    tolerance = 1e-12
  )
  expect_s3_class(simulate(fit, nsim = 1L, seed = 8L, re.form = NULL), "data.frame")
  expect_error(logLik(fit), class = "drmTMB_mspl_inference_unsupported")
  expect_error(AIC(fit), class = "drmTMB_mspl_inference_unsupported")
  expect_error(BIC(fit), class = "drmTMB_mspl_inference_unsupported")
  expect_error(anova(fit, fit), class = "drmTMB_mspl_inference_unsupported")
  # vcov() and summary()$coefficients$std_error are UNLOCKED for MSPL fits
  # (design doc 251 sec 5, a Phase 4 amendment to 250's Phase 3 blanket
  # fence): they report the inverse observed information of the
  # *unpenalized* Laplace likelihood at the MSPL estimate, not a withheld or
  # fabricated number. This q2 fixture's unpenalized Hessian passes the SPD
  # gate, so both surfaces should be finite, positive, and name-indexable.
  V <- vcov(fit)
  expect_true(is.matrix(V))
  expect_identical(dim(V), c(5L, 5L))
  expect_true(all(is.finite(V)))
  expect_identical(
    rownames(V),
    c("mu:(Intercept)", "mu:x", "log_sd_mu", "log_sd_mu.1", "eta_cor_mu")
  )
  expect_identical(colnames(V), rownames(V))
  expect_true(all(diag(V) > 0))
  expect_error(confint(fit), class = "drmTMB_mspl_inference_unsupported")
  expect_error(profile(fit, parm = "sd:mu:(1 + x | group)"), class = "drmTMB_mspl_inference_unsupported")
  expect_error(summary(fit, conf.int = TRUE), class = "drmTMB_mspl_inference_unsupported")
  coefficients_table <- summary(fit)$coefficients
  expect_true(all(is.finite(coefficients_table$std_error)))
  expect_true(all(coefficients_table$std_error > 0))
  expect_equal(
    coefficients_table$std_error,
    unname(sqrt(diag(V))[c("mu:(Intercept)", "mu:x")]),
    tolerance = 1e-10
  )
  expect_true(is_converged(fit, include_hessian = TRUE))
  diagnostics <- check_drm(fit)
  hessian <- diagnostics[diagnostics$check == "hessian_positive_definite", ]
  expect_identical(hessian$status, "ok")
  expect_identical(hessian$value, "TRUE")
  expect_true(is.na(fit$logLik))
  expect_invisible(print(fit))
})

test_that("q2 MSPL remains finite for separated and mirrored fixed-X directions", {
  group <- factor(rep(seq_len(24L), each = 6L))
  x <- rep(c(-2, -1, -0.25, 0.25, 1, 2), 24L)
  fixtures <- list(
    complete = as.integer(x > 0),
    mirrored = as.integer(x < 0),
    quasi = rep(c(0L, 0L, 0L, 1L, 1L, 1L), 24L)
  )
  fits <- lapply(fixtures, function(y) {
    drmTMB(
      bf(y ~ x + (1 + x | group)), binomial(), data.frame(y, x, group),
      estimator = "mspl", control = mspl_test_control(2L)
    )
  })
  slopes <- vapply(fits, function(fit) coef(fit, "mu")[["x"]], numeric(1L))
  expect_true(all(is.finite(slopes)))
  expect_gt(slopes[["complete"]], 0)
  expect_lt(slopes[["mirrored"]], 0)
  expect_gt(slopes[["quasi"]], 0)
  expect_true(all(vapply(fits, is_converged, logical(1L), include_hessian = TRUE)))
  expect_true(all(vapply(
    fits,
    function(fit) fit$mspl$numerical$gradient_max_abs < 1e-3,
    logical(1L)
  )))
  expect_true(all(vapply(
    fits,
    function(fit) abs(fit$mspl$objective_identity_error) < 1e-7,
    logical(1L)
  )))
  if (requireNamespace("detectseparation", quietly = TRUE)) {
    expect_true(all(vapply(fits, function(fit) fit$mspl$detector$outcome, logical(1L))))
  } else {
    expect_true(all(vapply(
      fits,
      function(fit) identical(fit$mspl$detector$status, "unavailable"),
      logical(1L)
    )))
  }

  ml <- suppressWarnings(drmTMB(
    bf(y ~ x + (1 + x | group)), binomial(),
    data.frame(y = fixtures$complete, x, group),
    estimator = "ml", control = mspl_test_control(1L)
  ))
  expect_gt(abs(coef(ml, "mu")[["x"]]), abs(slopes[["complete"]]))
})

test_that("MSPL Wald standard errors agree with ML sdreport standard errors when the penalty is negligible", {
  # design 251 sec 9 test 1 -- the oracle. The MSPL soft-penalty scale
  # c_n = 2*sqrt(p / n_eff) shrinks with n_eff, so its influence on the
  # unpenalized-Hessian-based covariance should vanish as n grows. This
  # fixture (30 groups x 6 rows, alternating non-separated y across an
  # x range of [-2, 2]) is not separated: every x level has both y = 0 and
  # y = 1 present across groups. Exploration at n = 48 / 180 / 480 / 960 gave
  # relative |MSPL SE - ML SE| / ML SE of 1.7% / 0.4% / 0.1% / 0.04%,
  # monotonically shrinking with n as expected if the two agree in the
  # zero-penalty limit. 2% is roughly 5x the measured 0.4%-0.01% gap at this
  # n = 180 size, tight enough to catch a materially wrong Hessian while
  # tolerating ordinary penalty-induced drift.
  n_group <- 30L
  n_each <- 6L
  group <- factor(rep(seq_len(n_group), each = n_each))
  x <- rep(seq(-2, 2, length.out = n_each), n_group)
  y <- rep(as.integer(seq_len(n_each) %% 2 == 0), n_group)
  dat <- data.frame(y, x, group)

  ml <- drmTMB(
    bf(y ~ x + (1 | group)), binomial(), dat,
    estimator = "ml", control = drm_control(optimizer_preset = "careful")
  )
  mspl <- drmTMB(
    bf(y ~ x + (1 | group)), binomial(), dat,
    estimator = "mspl", control = mspl_test_control()
  )
  se_ml <- summary(ml)$coefficients$std_error
  se_mspl <- summary(mspl)$coefficients$std_error
  expect_true(all(is.finite(se_ml)))
  expect_true(all(is.finite(se_mspl)))
  expect_equal(se_mspl, se_ml, tolerance = 0.02)
})

test_that("the MSPL Wald covariance carries the correct sign convention (positive definite, not negated)", {
  # design 251 sec 6/9 test 2. For a TMB object with `random =` retained,
  # `obj$fn` is the NEGATIVE Laplace log-likelihood, so
  # `optimHess(theta_tilde, uobj$fn, uobj$gr)` already IS the observed
  # information and design 251 requires NO further sign flip: `V = solve(H)`
  # directly.
  #
  # How this test actually catches a negation (Noether, C5 review): near a
  # concave optimum of l_L the true H is positive definite, so negating it makes
  # it negative definite and `chol()` inside the SPD gate FAILS. The observable
  # symptom is therefore `spd = FALSE` with NA standard errors -- a loud refusal
  # -- rather than a returned negative-definite "covariance". Both assertions
  # below fail against the bug; the `spd` one fires first.
  dat <- mspl_q1_fixture("overlap")
  fit <- drmTMB(
    bf(y ~ x + (1 | group)), binomial(), dat,
    estimator = "mspl", control = mspl_test_control()
  )
  expect_true(fit$mspl$wald$spd)
  V <- vcov(fit)
  eigenvalues <- eigen((V + t(V)) / 2, symmetric = TRUE, only.values = TRUE)$values
  expect_true(all(eigenvalues > 0))
  se <- summary(fit)$coefficients$std_error
  expect_true(all(is.finite(se)))
  expect_true(all(se > 0))
})

test_that("the reported MSPL vcov derives from the unpenalized Hessian, not the penalized one", {
  # design 251 sec 2/9 test 3. `fit$mspl$numerical$hessian` is the
  # PENALIZED objective's Hessian (an optimizer diagnostic, design 251
  # sec 2); `fit$mspl$wald$hessian` is the UNPENALIZED likelihood's
  # Hessian, which is what the reported `vcov()` must invert.
  dat <- mspl_q1_fixture("overlap")
  fit <- drmTMB(
    bf(y ~ x + (1 | group)), binomial(), dat,
    estimator = "mspl", control = mspl_test_control()
  )
  penalized <- fit$mspl$numerical$hessian
  unpenalized <- fit$mspl$wald$hessian
  expect_gt(max(abs(penalized - unpenalized)), 1e-3)

  vcov_from_unpenalized <- chol2inv(chol((unpenalized + t(unpenalized)) / 2))
  expect_equal(
    unname(vcov_from_unpenalized), unname(vcov(fit)),
    tolerance = 1e-8
  )
  vcov_from_penalized <- chol2inv(chol((penalized + t(penalized)) / 2))
  expect_gt(max(abs(vcov_from_penalized - vcov_from_unpenalized)), 1e-4)
})

test_that("under separation, MSPL Wald SEs are large-and-finite or NA-with-warning, never silently small", {
  # design 251 sec 4/9 test 4. Two separated fixtures give the two honest
  # outcomes the design permits:
  #  - q1 "complete" separation (random intercept only): exploration shows
  #    the unpenalized-Hessian SPD gate PASSES (the random intercept
  #    partially absorbs the separation), giving large finite SEs
  #    (intercept 1.60, slope 1.72, log_sd 2.01) versus ~0.2-0.3 in the
  #    non-separated "overlap" fixture used elsewhere in this file. 1 is a
  #    threshold well below the observed values and well above ordinary
  #    non-separated SEs.
  #  - q2 complete separation on the (1 + x | group) block: exploration
  #    shows the gate FAILS (status "hessian_not_positive_definite"), so
  #    the reported SEs are NA and the typed warning fires.
  # Neither path is a small, fabricated number.
  fit_finite <- drmTMB(
    bf(y ~ x + (1 | group)), binomial(), mspl_q1_fixture("complete"),
    estimator = "mspl", control = mspl_test_control()
  )
  expect_true(fit_finite$mspl$wald$spd)
  se_finite <- summary(fit_finite)$coefficients$std_error
  expect_true(all(is.finite(se_finite)))
  expect_true(all(se_finite > 1))

  group <- factor(rep(seq_len(24L), each = 6L))
  x <- rep(c(-2, -1, -0.25, 0.25, 1, 2), 24L)
  y <- as.integer(x > 0)
  fit_na <- drmTMB(
    bf(y ~ x + (1 + x | group)), binomial(), data.frame(y, x, group),
    estimator = "mspl", control = mspl_test_control(2L)
  )
  expect_false(fit_na$mspl$wald$spd)
  expect_warning(vcov(fit_na), class = "drmTMB_mspl_wald_unavailable")
  expect_true(all(is.na(suppressWarnings(vcov(fit_na)))))
  expect_warning(summary(fit_na), class = "drmTMB_mspl_wald_unavailable")
  expect_true(all(is.na(suppressWarnings(summary(fit_na))$coefficients$std_error)))
})

test_that("the unpenalized-likelihood gradient diagnostic is recorded and non-zero by construction", {
  # design 251 sec 3/9 test 5. theta_tilde maximises the PENALIZED
  # criterion, not the unpenalized likelihood, so grad(ell_L)(theta_tilde)
  # != 0 in general (the textbook Wald argument's stationarity does not
  # transfer unmodified). A recorded value of exactly 0 here would mean the
  # wrong (penalized) objective was differentiated.
  dat <- mspl_q1_fixture("overlap")
  fit <- drmTMB(
    bf(y ~ x + (1 | group)), binomial(), dat,
    estimator = "mspl", control = mspl_test_control()
  )
  g <- fit$mspl$wald$unpenalized_gradient_max_abs
  expect_true(is.finite(g))
  expect_gt(g, 0)
})

test_that("MSPL vcov and summary std_error agree exactly and vcov is indexable by name", {
  # design 251 sec 9 test 6.
  dat <- mspl_q1_fixture("overlap")
  fit <- drmTMB(
    bf(y ~ x + (1 | group)), binomial(), dat,
    estimator = "mspl", control = mspl_test_control()
  )
  V <- vcov(fit)
  labels <- drmTMB:::coefficient_labels(fit)
  expect_identical(rownames(V)[seq_along(labels)], labels)
  expect_identical(colnames(V), rownames(V))
  expect_length(unique(rownames(V)), length(rownames(V)))
  expect_equal(
    unname(sqrt(diag(V))[seq_along(labels)]),
    summary(fit)$coefficients$std_error,
    tolerance = 1e-10
  )
  expect_identical(V["mu:x", "mu:x"], V[2L, 2L])
})

test_that("independent q1 and q2 penalty values and gradients match TMB", {
  skip_if_not_installed("numDeriv")
  q1_data <- mspl_q1_fixture("overlap")
  q1 <- drmTMB(
    bf(y ~ x + (1 | group)), binomial(), q1_data,
    estimator = "mspl", control = mspl_test_control(1L)
  )

  group <- factor(rep(seq_len(16L), each = 6L))
  x <- rep(c(-1.5, -0.75, -0.2, 0.2, 0.75, 1.5), 16L)
  y <- rep(c(0L, 1L, 0L, 1L, 1L, 0L), 16L)
  q2 <- drmTMB(
    bf(y ~ x + (1 + x | group)), binomial(), data.frame(y, x, group),
    estimator = "mspl", control = mspl_test_control(1L)
  )

  for (fit in list(q1, q2)) {
    unpenalized <- drmTMB:::drm_mspl_unpenalized_objective(
      fit$model, list(par = fit$opt$par)
    )$object
    probe <- fit$opt$par + 0.01 * seq_along(fit$opt$par)
    tmb_penalty <- fit$obj$fn(probe) - unpenalized$fn(probe)
    direct_penalty <- mspl_independent_nll_penalty(fit, probe)
    expect_equal(
      as.numeric(tmb_penalty), as.numeric(direct_penalty), tolerance = 1e-8
    )

    tmb_gradient <- fit$obj$gr(probe) - unpenalized$gr(probe)
    direct_gradient <- numDeriv::grad(
      function(par) mspl_independent_nll_penalty(fit, par),
      probe
    )
    expect_lt(max(abs(tmb_gradient - direct_gradient)), 2e-5)
  }
})

test_that("MSPL rejects every unvalidated estimator and structure combination", {
  dat <- mspl_q1_fixture("overlap")
  base_formula <- bf(y ~ x + (1 | group))
  expect_error(
    drmTMB(base_formula, binomial(), dat, estimator = "AI-REML"),
    "one of.*ml.*mspl"
  )
  expect_error(
    drmTMB(base_formula, binomial(link = "probit"), dat, estimator = "mspl"),
    "logit"
  )
  expect_error(
    drmTMB(base_formula, binomial(link = "cloglog"), dat, estimator = "mspl"),
    "logit"
  )
  expect_error(
    drmTMB(base_formula, binomial(), dat, estimator = "mspl", engine = "julia"),
    'engine = "tmb"'
  )
  expect_error(
    drmTMB(
      base_formula, binomial(), dat, estimator = "mspl",
      penalty = drm_phylo_penalty(sd_u = 1)
    ),
    "penalty"
  )
  expect_error(
    drmTMB(bf(y ~ x + (1 | group)), gaussian(), dat, estimator = "mspl"),
    "binomial"
  )
  expect_error(
    drmTMB(
      bf(cbind(y, 1 - y) ~ x + (1 | group)), beta_binomial(), dat,
      estimator = "mspl"
    ),
    "binomial"
  )
  dat$y2 <- dat$y
  expect_error(
    drmTMB(
      bf(mu1 = y ~ x, mu2 = y2 ~ x), biv_gaussian(), dat,
      estimator = "mspl"
    ),
    "binomial"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | group), zi ~ 1), binomial(), dat,
      estimator = "mspl"
    )
  )
  expect_error(
    drmTMB(base_formula, binomial(), dat, estimator = "mspl", REML = TRUE),
    "cannot be combined"
  )
  expect_error(
    drmTMB(bf(y ~ x), binomial(), dat, estimator = "mspl"),
    "q = 1 or correlated q = 2"
  )
  expect_error(
    drmTMB(bf(y ~ x + (0 + x | group)), binomial(), dat, estimator = "mspl"),
    "q = 1 or correlated q = 2"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | group) + (0 + x | group)), binomial(), dat,
      estimator = "mspl"
    ),
    "q = 1 or correlated q = 2"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + (1 + x | p | group)), binomial(), dat,
      estimator = "mspl"
    ),
    "unlabelled intercept-slope block"
  )
  dat$group2 <- factor(rep(seq_len(6), each = 8L))
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | group) + (1 | group2)), binomial(), dat,
      estimator = "mspl"
    ),
    "q = 1 or correlated q = 2"
  )
  expect_error(
    drmTMB(base_formula, binomial(), dat, weights = rep(1.5, nrow(dat)), estimator = "mspl"),
    "integer frequency"
  )
  expect_error(
    drmTMB(base_formula, binomial(), dat, weights = rep(-1, nrow(dat)), estimator = "mspl"),
    "non-negative integer"
  )
  expect_error(
    drmTMB(base_formula, binomial(), dat, weights = rep(0, nrow(dat)), estimator = "mspl"),
    "at least one row"
  )
  expect_error(
    drmTMB(base_formula, binomial(), dat, weights = rep(Inf, nrow(dat)), estimator = "mspl"),
    "non-negative integer"
  )
  rank_deficient <- transform(dat, duplicate_x = x)
  expect_error(
    drmTMB(
      bf(y ~ x + duplicate_x + (1 | group)), binomial(), rank_deficient,
      estimator = "mspl"
    ),
    "full-column-rank"
  )
  dat$z <- dat$x^2
  expect_error(
    drmTMB(
      bf(y ~ x + (1 + x + z | group)), binomial(), dat,
      estimator = "mspl"
    ),
    "multiple random slopes|q = 1 or correlated q = 2"
  )

  q2_formula <- bf(y ~ x + (1 + x | group))
  expect_error(
    drmTMB(q2_formula, binomial(), dat, REML = TRUE),
    "q = 2.*REML"
  )
  missing_dat <- dat
  missing_dat$y[[1L]] <- NA_real_
  expect_error(
    drmTMB(
      q2_formula, binomial(), missing_dat, estimator = "mspl",
      missing = miss_control(response = "include")
    ),
    "missing-data integration|missing-response"
  )
  expect_error(
    drmTMB(
      base_formula, binomial(), missing_dat, estimator = "mspl",
      missing = miss_control(response = "include")
    ),
    "missing-data integration"
  )
  expect_error(
    drmTMB(
      base_formula, binomial(), dat, estimator = "mspl",
      impute = list()
    ),
    "missing-data integration"
  )
})

test_that("MSPL rejects structured binomial random effects", {
  skip_if_not_installed("ape")
  tree <- ape::rtree(12L)
  group <- factor(rep(tree$tip.label, each = 4L), levels = tree$tip.label)
  x <- rep(c(-1, -0.25, 0.25, 1), 12L)
  y <- rep(c(0L, 1L, 0L, 1L), 12L)
  dat <- data.frame(y, x, group)
  expect_error(
    drmTMB(
      bf(y ~ x + phylo(1 | group, tree = tree)), binomial(), dat,
      estimator = "mspl"
    )
  )
})

# ---------------------------------------------------------------------------
# q2 EXTERNAL STANDARD-ERROR ORACLE
#
# Closes the gap the C5 review named: q1 had an external ML-`sdreport()` oracle
# while q2 had only internal `vcov()`-vs-`summary()` self-consistency, so the
# two were NOT evidenced to the same standard.
#
# Two arms, deliberately at different strengths.
#
#   Arm 1 -- drmTMB `estimator = "ml"`. Same package, but a genuinely different
#   machinery: ML standard errors come through TMB's `sdreport()` delta method,
#   MSPL's through `optimHess()` + `chol2inv()`. Agreement cross-checks the
#   inversion.
#
#   Arm 2 -- `lme4::glmer(..., nAGQ = 1)`. A separate codebase, also Laplace, so
#   it can catch a bug shared across the TMB path that Arm 1 structurally cannot.
#
# MEASURED LADDER (non-separated q2 DGP, sd_int 0.6 / sd_slope 0.4), max relative
# difference in fixed-effect SEs:
#
#     G     n     vs drmTMB-ML   vs glmer
#    10    80        10.13%       10.13%
#    20   200         1.85%        1.81%
#    40   480         0.69%        2.42%
#    80  1120         0.14%        1.16%
#
# The ML arm converges MONOTONICALLY, which is the actual evidence: the penalty
# scale c_n = 2*sqrt(p/n_eff) vanishes with n, so MSPL -> ML. The glmer arm does
# NOT converge monotonically and plateaus around 1-2% -- an irreducible
# implementation difference (different optimizer and parameterisation), not a
# defect. It is therefore a SANITY arm and is given a deliberately loose bound;
# tightening it would be measuring lme4, not drmTMB.
#
# Note the q2 gap is genuinely LARGER than q1's (1.85% at n=200 here, versus
# 0.38% at n=180 for q1). Reusing the q1 tolerance would fail. That is expected:
# c_n grows with p, and the negative-Huber term acts on the covariance Cholesky,
# which is doing real work even without separation because it holds the
# correlation off the boundary.
#
# Tolerances below are ~3x the measured value at the size asserted, chosen from
# the ladder rather than fitted to pass.
# ---------------------------------------------------------------------------

mspl_q2_oracle_fixture <- function(G = 40L, npg = 12L, seed = 103L) {
  set.seed(seed)
  d <- data.frame(
    group = factor(rep(seq_len(G), each = npg)),
    x = rep(seq(-2, 2, length.out = npg), times = G)
  )
  u0 <- rnorm(G, 0, 0.6)
  u1 <- rnorm(G, 0, 0.4)
  eta <- 0.4 + 0.6 * d$x +
    u0[as.integer(d$group)] + u1[as.integer(d$group)] * d$x
  d$y <- rbinom(nrow(d), 1, plogis(eta))
  d
}

test_that("q2 MSPL standard errors agree with the drmTMB ML sdreport oracle", {
  dat <- mspl_q2_oracle_fixture()

  ml <- drmTMB(bf(y ~ x + (1 + x | group)), family = binomial(), data = dat)
  mspl <- drmTMB(
    bf(y ~ x + (1 + x | group)),
    family = binomial(), data = dat,
    estimator = "mspl", control = mspl_test_control()
  )

  se_ml <- summary(ml)$coefficients$std_error
  se_mspl <- summary(mspl)$coefficients$std_error

  expect_true(all(is.finite(se_ml)))
  expect_true(all(is.finite(se_mspl)))
  expect_true(all(se_mspl > 0))
  expect_equal(length(se_mspl), length(se_ml))

  # Fixed effects only: the variance-component entries live on
  # (log_sd, eta_cor) coordinates and have no comparable ML/glmer counterpart.
  relative <- max(abs(se_mspl - se_ml) / se_ml)
  expect_lt(relative, 0.02)
})

test_that("q2 MSPL standard errors are consistent with an external lme4 fit", {
  skip_if_not_installed("lme4")
  dat <- mspl_q2_oracle_fixture()

  mspl <- drmTMB(
    bf(y ~ x + (1 + x | group)),
    family = binomial(), data = dat,
    estimator = "mspl", control = mspl_test_control()
  )
  gl <- lme4::glmer(
    y ~ x + (1 + x | group),
    family = binomial, data = dat, nAGQ = 1L
  )

  se_mspl <- summary(mspl)$coefficients$std_error
  se_glmer <- coef(summary(gl))[, "Std. Error"]

  expect_equal(length(se_mspl), length(se_glmer))
  expect_true(all(is.finite(se_glmer)))

  # Loose by design -- see the header note. This arm asserts "no systematic
  # divergence from an independent implementation", not numerical equality.
  relative <- max(abs(se_mspl - se_glmer) / se_glmer)
  expect_lt(relative, 0.06)
})

# ---------------------------------------------------------------------------
# EQUIVARIANCE UNDER CONTRASTS
#
# Sterzinger & Kosmidis (2023) prove MSPL fixed-effect estimates are EXACTLY
# equivariant under linear reparameterisation of the fixed-effect design, and
# make the point by exhibiting a competitor that is not: `blme`/`bglmer`, whose
# independent normal/t priors on the fixed effects give non-matching estimates
# of the same quantity under a change of reference category (their Table 2
# reports gamma_1 = 5.75 against -beta_4 = -4.73 for what is algebraically one
# number). The brain's ENGINEERING-NOTEBOOK entry for that paper lists this
# explicitly as a check any penalty implementation should be run against.
#
# Why it can fail, and so why it is worth asserting: the Jeffreys term is
# 0.5 * log|X'WX|. Under X -> XA the determinant changes by the constant |A|^2,
# which shifts the objective without moving its argmax -- equivariance is a
# CONSEQUENCE of that structure. An implementation that built the penalty on a
# rescaled, centred, or otherwise reparameterised design, or that let the
# scaling constant c_n depend on the parameterisation, would break it while
# still producing plausible-looking estimates. Nothing else in this file would
# catch that.
#
# Run on a SEPARATED fixture on purpose: there the penalty is doing real work,
# so the property is actually being exercised rather than holding trivially
# because the penalty is negligible.
#
# MEASURED: |beta_d + gamma_a| = 4.9e-06 for MSPL, and 5.2e-05 for ML. MSPL is
# the tighter of the two -- ML's agreement is bounded by wherever the optimizer
# stopped on an almost-flat likelihood, whereas MSPL has a finite optimum to
# converge to. Tolerance 1e-4 gives ~20x headroom over the measured value.
# ---------------------------------------------------------------------------

mspl_separated_contrast_fixture <- function(G = 12L, seed = 20260809L) {
  set.seed(seed)
  d <- data.frame(
    block = factor(rep(seq_len(G), each = 8L)),
    trt = factor(rep(c("a", "b", "c", "d"), times = 2L * G))
  )
  u <- rnorm(G, 0, 0.8)
  eta <- c(a = 0.5, b = 1.2, c = -0.3, d = -50)[as.character(d$trt)] +
    u[as.integer(d$block)]
  d$y <- rbinom(nrow(d), 1, plogis(eta))
  d
}

test_that("MSPL fixed effects are equivariant under a change of reference level", {
  base <- mspl_separated_contrast_fixture()

  d_ref_a <- base
  d_ref_a$trt <- relevel(d_ref_a$trt, ref = "a")
  d_ref_d <- base
  d_ref_d$trt <- relevel(d_ref_d$trt, ref = "d")

  fit_one <- function(dat) {
    drmTMB(
      bf(y ~ trt + (1 | block)),
      family = binomial(), data = dat,
      estimator = "mspl", control = mspl_test_control()
    )
  }

  ca <- summary(fit_one(d_ref_a))$coefficients
  cd <- summary(fit_one(d_ref_d))$coefficients

  # The paper's own check: beta_d under reference "a" is algebraically the
  # negative of gamma_a under reference "d".
  beta_d <- ca[grep("trtd$", rownames(ca)), "estimate"]
  gamma_a <- cd[grep("trta$", rownames(cd)), "estimate"]
  expect_equal(length(beta_d), 1L)
  expect_equal(length(gamma_a), 1L)
  expect_lt(abs(beta_d + gamma_a), 1e-4)

  # Stronger form: every fitted cell mean on the link scale must agree, not
  # just the one contrast the paper happens to print.
  cell_means <- function(cf, levels_in_order) {
    b <- cf[, "estimate"]
    stats::setNames(c(b[[1L]], b[[1L]] + b[-1L]), levels_in_order)
  }
  ma <- cell_means(ca, c("a", "b", "c", "d"))
  md <- cell_means(cd, c("d", "a", "b", "c"))[c("a", "b", "c", "d")]
  expect_lt(max(abs(ma - md)), 1e-4)
})
