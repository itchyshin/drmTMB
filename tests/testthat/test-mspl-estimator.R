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
  expect_error(vcov(fit), class = "drmTMB_mspl_inference_unsupported")
  expect_error(confint(fit), class = "drmTMB_mspl_inference_unsupported")
  expect_error(profile(fit, parm = "sd:mu:(1 + x | group)"), class = "drmTMB_mspl_inference_unsupported")
  expect_error(summary(fit, conf.int = TRUE), class = "drmTMB_mspl_inference_unsupported")
  expect_true(all(is.na(summary(fit)$coefficients$std_error)))
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
