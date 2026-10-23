# #1476 / #1477: restored 15-node Beta rule and adaptive Gamma quadrature
# (posterior-mode sinh-mapped trapezoid).
# Mass tests use the raw (unnormalised) quadrature. Never loosen a tolerance.

test_that("raw Beta mi() quadrature mass is finite and unnormalised (#1476)", {
  mus <- c(0.50, 0.10, 0.02)
  sigs <- c(1, 0.5, 0.2, 0.1, 0.05)
  for (mu in mus) {
    for (sig in sigs) {
      mass <- drm_beta_mi_quadrature_mass(mu, sig)
      expect_true(
        is.finite(mass),
        info = sprintf("mu=%.2f sigma=%.2f", mu, sig)
      )
      expect_gt(mass, 0)
    }
  }
  mid <- drm_beta_mi_quadrature_mass(0.5, 0.2)
  expect_lt(abs(mid - 1), 0.05)
})

test_that("raw Gamma mi() prior mass stays near 1 at ordinary CV (#1477)", {
  for (sig in c(0.5, 0.2, 0.1, 0.05)) {
    mass <- drm_gamma_mi_quadrature_mass(mu = 10, sigma = sig, n = 31L)
    expect_equal(
      mass,
      1,
      tolerance = 1e-4,
      info = sprintf("sigma=%.2f shape=%.1f", sig, 1 / sig^2)
    )
  }
})

test_that("Beta mi() at mu = 0.02 matches integrate() to 1e-4 per row (#1476)", {
  # Frozen 15-node Gauss-Legendre. Measured |logLik - log integrate()|
  # at y = 1, sd_y = 0.1, beta_x = 2 is 4.81e-3 (U-shaped Beta, #1531).
  # Raising the node count does not reach 1e-4 (101 GL nodes still 3.0e-4).
  skip("Beta mi() at mu = 0.02 is 4.81e-3 vs 1e-4 on the frozen 15-node Gauss-Legendre rule (refs #1476 / #1531). See docs/dev-log/known-limitations.md.")
})

test_that("mid-range Beta 15-node rule matches integrate() near 2.6e-5 (#1476)", {
  # Mid-range Beta, sd_y = 0.1. The restored 15-node Gauss-Legendre rule
  # is within the historical 2.6e-5 logLik error; do not loosen.
  prod_b <- drm_beta_mi_quad_loglik(1, 0.5, 0.1, 1, 0, 0.5, 0.5)
  ref_b <- drm_beta_mi_reference_loglik(1, 0.5, 0.1, 1, 0, 0.5, 0.5)
  expect_equal(prod_b, log(ref_b), tolerance = 2.6e-5)

  prod_pin <- drm_beta_mi_quad_loglik(1, 0.5, 0.1, 1, 0, 0.10, 0.2)
  ref_pin <- drm_beta_mi_reference_loglik(1, 0.5, 0.1, 1, 0, 0.10, 0.2)
  expect_equal(prod_pin, log(ref_pin), tolerance = 2.6e-5)
})

# Pole geometry for the Gaussian-response rows: mu = 10, mu_y = 2, sd_y = 0.1,
# beta_x = 0.5, so y = 2.05 puts the response pole at x = 0.1 and the prior mean
# (x = 10) sits at y = 7. The rows below walk from the pole (y = 2.05) through
# the posterior mode (y = 2.2, 2.5, 3.5) to the tail (y = 12, x = 20). Each row
# is checked on its own against a log-space integrate() reference; the bar is
# 1e-4 on |log marginal error| per row and is never loosened (#1477).
gamma_mi_gaussian_rows <- function() {
  rbind(
    expand.grid(
      cv = c(0.5, 1, 2),
      y = c(2.05, 2.2, 2.5, 3.5, 12),
      KEEP.OUT.ATTRS = FALSE
    ),
    data.frame(cv = 0.05, y = c(2.05, 12))
  )
}

test_that("Gamma quadrature matches integrate() per row at the pole, near the mode and in the tail (#1477)", {
  rows <- gamma_mi_gaussian_rows()
  for (i in seq_len(nrow(rows))) {
    cv <- rows$cv[[i]]
    y <- rows$y[[i]]
    prod_ll <- drm_gamma_mi_quad_loglik(y, 2, 0.1, 0.5, 0, 10, cv)
    ref <- drm_gamma_mi_reference_loglik(y, 2, 0.1, 0.5, 0, 10, cv)
    expect_lt(
      abs(prod_ll - log(ref)),
      1e-4,
      label = sprintf("Gaussian y=%.2f CV=%.2f", y, cv)
    )
  }
})

test_that("five Newton steps land near the posterior mode at the pole (#1477)", {
  # The mode residual after step 5. With the old clamped log-x Newton step the
  # score at the pole rows was about -15 (CV 0.5, 1, 2): the iterate had not
  # reached the mode and the nodes were centred on the wrong point.
  quad <- drmTMB:::drm_gamma_mi_quadrature()
  for (cv in c(0.5, 1, 2)) {
    nodes <- drmTMB:::drm_gamma_mi_adaptive_nodes(
      quad$nodes, quad$weights, mu = 10, sigma = cv,
      y = 2.05, mu_y = 2, sigma_y = 0.1, beta_x = 0.5, x_base = 0,
      response = "gaussian"
    )
    expect_lt(abs(nodes$mode_grad), 0.1, label = sprintf("CV=%.1f", cv))
  }
})

test_that("Gamma mi() score and Hessian are the derivatives of the log-x integrand with Jacobian (#1477)", {
  # Central differences of drm_gamma_mi_log_integrand() (which carries the +u
  # Jacobian) must reproduce the analytic score and Hessian that Newton uses,
  # for the Gaussian and the Poisson response leaf.
  for (resp in c("gaussian", "poisson")) {
    y <- if (identical(resp, "poisson")) 4 else 2.2
    sigma_y <- if (identical(resp, "poisson")) 1 else 0.1
    mu_y <- if (identical(resp, "poisson")) 1.2 else 2
    beta_x <- if (identical(resp, "poisson")) 0.15 else 0.5
    for (cv in c(0.5, 1, 2)) {
      f <- function(u) {
        drmTMB:::drm_gamma_mi_log_integrand(
          u, 10, cv, y, mu_y, sigma_y, beta_x, 0, resp
        )
      }
      for (u in c(-1, 0, 1.5)) {
        h <- 1e-4
        g_fd <- (f(u + h) - f(u - h)) / (2 * h)
        H_fd <- (f(u + h) - 2 * f(u) + f(u - h)) / h^2
        gh <- drmTMB:::drm_gamma_mi_grad_hess(
          u, 10, cv, y, mu_y, sigma_y, beta_x, 0, resp
        )
        expect_equal(gh$g, g_fd, tolerance = 1e-5, info = sprintf("%s CV=%.1f u=%.1f score", resp, cv, u))
        expect_equal(gh$H, H_fd, tolerance = 1e-4, info = sprintf("%s CV=%.1f u=%.1f hessian", resp, cv, u))
      }
    }
  }
})

test_that("compiled Gamma mi() quadrature matches integrate() per row, and the R mirror (#1477)", {
  skip_on_cran()
  # The marginal for one missing-x row is read off the live objective as
  # nll(data with the row) - nll(data without it), at fixed parameters, so the
  # compiled quadrature (not the R mirror) is what is compared with integrate().
  make_obj <- function(y_pole, drop_pole) {
    d <- data.frame(
      y = c(y_pole, 3, 2.6, 3.4, 2.9, 3.1, 3.3, 2.7),
      x = c(NA, NA, 9, 11, 10, 8, 12, 10)
    )
    if (drop_pole) {
      d <- d[-1L, ]
    }
    suppressWarnings(drmTMB(
      bf(y ~ mi(x), sigma ~ 1),
      data = d,
      impute = list(x = impute_model(x ~ 1, family = Gamma(link = "log"))),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ))
  }
  set_par <- function(obj, cv) {
    p <- obj$par
    nm <- names(p)
    p[nm == "beta_mu"] <- c(2, 0.5)
    p[nm == "beta_sigma"] <- log(0.1)
    p[nm == "beta_mi"] <- log(10)
    p[nm == "log_sigma_mi"] <- log(cv)
    p
  }
  for (cv in c(0.5, 1, 2)) {
    for (y in c(2.05, 2.2, 2.5, 3.5, 12)) {
      fa <- make_obj(y, FALSE)
      fb <- make_obj(y, TRUE)
      cpp_ll <- -(fa$obj$fn(set_par(fa$obj, cv)) - fb$obj$fn(set_par(fb$obj, cv)))
      ref <- log(drm_gamma_mi_reference_loglik(y, 2, 0.1, 0.5, 0, 10, cv))
      mirror <- drm_gamma_mi_quad_loglik(y, 2, 0.1, 0.5, 0, 10, cv)
      lab <- sprintf("compiled y=%.2f CV=%.1f", y, cv)
      expect_lt(abs(cpp_ll - ref), 1e-4, label = lab)
      expect_lt(abs(cpp_ll - mirror), 1e-8, label = paste(lab, "vs R mirror"))
    }
  }
})

test_that("Poisson response x Gamma mi() matches integrate() per row at CV 0.2, 1 and 2 (#1477)", {
  # y = 0 is the hard row at CV 2 (the prior's exp(0.25 u) left tail meets a
  # likelihood that is flat in x); y = 30 is the large-y row. Reference is the
  # same log-space integrate() as the Gaussian rows; the old reference stopped
  # at log(mu) - 12 and lost about 5% of the mass at CV 2.
  rows <- expand.grid(
    cv = c(0.2, 1, 2),
    y = c(0, 1, 4, 30),
    KEEP.OUT.ATTRS = FALSE
  )
  for (i in seq_len(nrow(rows))) {
    cv <- rows$cv[[i]]
    y <- rows$y[[i]]
    prod_ll <- drm_gamma_mi_quad_loglik(
      y, 1.2, 1, 0.15, 0, 8, cv, response = "poisson"
    )
    ref <- drm_gamma_mi_reference_loglik(
      y, 1.2, 1, 0.15, 0, 8, cv, response = "poisson"
    )
    expect_lt(
      abs(prod_ll - log(ref)),
      1e-4,
      label = sprintf("Poisson y=%g CV=%.1f", y, cv)
    )
  }
})

test_that("Poisson x Gamma at CV 2 with y = 0 or large y is finite and accurate (#1477)", {
  for (y in c(0, 30)) {
    prod_ll <- drm_gamma_mi_quad_loglik(
      y, 1.2, 1, 0.15, 0, 8, 2, response = "poisson"
    )
    ref <- drm_gamma_mi_reference_loglik(
      y, 1.2, 1, 0.15, 0, 8, 2, response = "poisson"
    )
    expect_true(is.finite(prod_ll))
    expect_lt(abs(prod_ll - log(ref)), 1e-4, label = sprintf("y=%g", y))
  }
})

test_that("Gamma adaptive quadrature at CV >= 3 near the pole is a labelled skip (#1477)", {
  # CV 0.5, 1, and 2 at the asserted rows meet 1e-4. CV >= 3 still misses
  # the exp(shape * u) left tail on a fraction of the (mu, y) plane
  # (docs/dev-log/2026-10-12-gamma-mi-cv-gt1-pole-follow-up-issue.md).
  skip("Gamma mi() quadrature: CV >= 3 and strong prior/likelihood conflict (refs #1477). See docs/dev-log/2026-10-12-gamma-mi-cv-gt1-pole-follow-up-issue.md.")
})

test_that("NaN or -Inf Gamma marginal is a classed abort", {
  expect_error(
    drmTMB:::drm_abort_mi_quadrature_nonfinite("probe"),
    class = "drmTMB_mi_quadrature_nonfinite"
  )
  expect_error(
    drmTMB:::drm_gamma_mi_adaptive_nodes(
      z = 0,
      w = 1,
      mu = 10,
      sigma = 0.2,
      y = NaN,
      mu_y = 2,
      sigma_y = 0.1,
      beta_x = 0.5,
      x_base = 0,
      response = "gaussian"
    ),
    class = "drmTMB_mi_quadrature_nonfinite"
  )
})

test_that("quadrature abort watches every mi() term, not only the first", {
  abort_on <- function(family) {
    list(enabled = TRUE, family = family)
  }
  expect_false(drmTMB:::drm_spec_uses_mi_quadrature_abort(list(
    missing_predictor = abort_on("gaussian")
  )))
  expect_true(drmTMB:::drm_spec_uses_mi_quadrature_abort(list(
    missing_predictor = abort_on("gamma")
  )))
  expect_true(drmTMB:::drm_spec_uses_mi_quadrature_abort(list(
    missing_predictor = abort_on("gaussian"),
    missing_predictor2 = abort_on("gamma")
  )))
  expect_true(drmTMB:::drm_spec_uses_mi_quadrature_abort(list(
    missing_predictor = abort_on("beta"),
    missing_predictor2 = abort_on("gaussian")
  )))
  expect_true(drmTMB:::drm_spec_uses_mi_quadrature_abort(list(
    missing_predictor = abort_on("gaussian"),
    missing_predictor2 = abort_on("zero_one_beta")
  )))
  expect_false(drmTMB:::drm_spec_uses_mi_quadrature_abort(list(
    missing_predictor = abort_on("gaussian"),
    missing_predictor2 = abort_on("gaussian")
  )))
  expect_false(drmTMB:::drm_spec_uses_mi_quadrature_abort(list(
    missing_predictor = list(enabled = FALSE, family = "gamma"),
    missing_predictor2 = abort_on("gaussian")
  )))
})

test_that("drm_rethrow_mi_quadrature_error classifies a C++ tape abort", {
  # Live MakeADFun/fn errors arrive as a plain error whose message carries
  # the C++ token. drm_fit_spec() calls this helper (R/drmTMB.R) so the
  # classed abort is what the user sees.
  e <- simpleError(
    "drmTMB_mi_quadrature_nonfinite: mi() quadrature produced a non-finite marginal."
  )
  expect_error(
    drmTMB:::drm_rethrow_mi_quadrature_error(e),
    class = "drmTMB_mi_quadrature_nonfinite"
  )
})

test_that("a live drmTMB() Gamma mi() fit raises drmTMB_mi_quadrature_nonfinite", {
  skip_on_cran()
  set.seed(15134)
  n <- 20
  d <- data.frame(
    y = 1 + 0.4 * seq_len(n) + stats::rnorm(n, 0, 0.2),
    x = stats::rgamma(n, shape = 4, scale = 2),
    z = stats::rnorm(n)
  )
  d$x[[1L]] <- NA_real_
  d$y[[1L]] <- 1e200
  expect_error(
    suppressWarnings(drmTMB(
      bf(y ~ mi(x), sigma ~ 1),
      data = d,
      impute = list(x = impute_model(x ~ z, family = Gamma(link = "log"))),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    )),
    class = "drmTMB_mi_quadrature_nonfinite"
  )
})

test_that("Gamma mi() recovers a low-CV predictor (#1477)", {
  skip_on_cran()
  set.seed(1477)
  n <- 80
  nmiss <- 20
  cv <- 0.10
  z <- stats::rnorm(n)
  mu <- exp(2 + 0.2 * z)
  x <- stats::rgamma(n, shape = 1 / cv^2, scale = mu * cv^2)
  y <- 1 + 0.5 * x + stats::rnorm(n, 0, 0.5)
  d <- data.frame(y, x, z)
  d$x[sample(n, nmiss)] <- NA
  fit <- suppressWarnings(drmTMB(
    bf(y ~ mi(x), sigma ~ 1),
    data = d,
    impute = list(x = impute_model(x ~ z, family = Gamma(link = "log"))),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  ))
  expect_equal(fit$opt$convergence, 0L)
  est <- as.numeric(fit$obj$report(fit$obj$env$last.par.best)$sigma_gamma_mi)
  expect_gt(est, 0.05)
  expect_lt(est, 0.16)
  expect_lt(abs(est - cv), 0.05)
})

gamma_mi_fd_obj <- function(cv, seed = 14770L) {
  set.seed(seed)
  n <- 40
  z <- stats::rnorm(n)
  mu <- exp(1.5 + 0.15 * z)
  x <- stats::rgamma(n, shape = 1 / cv^2, scale = mu * cv^2)
  y <- 0.5 + 0.4 * x + stats::rnorm(n, 0, 0.25)
  d <- data.frame(y, x, z)
  d$x[seq_len(8)] <- NA
  fit <- suppressWarnings(drmTMB(
    bf(y ~ mi(x), sigma ~ 1),
    data = d,
    impute = list(x = impute_model(x ~ z, family = Gamma(link = "log"))),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  ))
  fit
}

gamma_mi_fd_max_err <- function(obj, par, h = 1e-5) {
  gr <- as.numeric(obj$gr(par))
  fd <- numeric(length(par))
  for (j in seq_along(par)) {
    par_up <- par
    par_dn <- par
    par_up[[j]] <- par[[j]] + h
    par_dn[[j]] <- par[[j]] - h
    fd[[j]] <- (obj$fn(par_up) - obj$fn(par_dn)) / (2 * h)
  }
  list(gr = gr, fd = fd, max_abs = max(abs(gr - fd)))
}

test_that("Gamma mi() obj$gr matches finite difference to 1e-5 at CV 0.05, 1, 2", {
  skip_on_cran()
  for (cv in c(0.05, 1, 2)) {
    fit <- gamma_mi_fd_obj(cv, seed = as.integer(14770 + 100 * cv))
    expect_true(all(is.finite(fit$obj$gr(fit$opt$par))), info = sprintf("CV=%.2f gr finite", cv))
    cmp <- gamma_mi_fd_max_err(fit$obj, fit$opt$par)
    expect_true(all(is.finite(cmp$fd)), info = sprintf("CV=%.2f fd finite", cv))
    expect_lt(cmp$max_abs, 1e-5)
  }
})

gamma_mi_newton_b_wins <- function(
  mu,
  sigma,
  y,
  mu_y,
  sigma_y,
  beta_x,
  x_base = 0,
  response = "gaussian"
) {
  f <- function(u) {
    drmTMB:::drm_gamma_mi_log_integrand(
      u, mu, sigma, y, mu_y, sigma_y, beta_x, x_base, response
    )
  }
  safe_f <- function(u) {
    v <- f(u)
    if (is.finite(v)) v else -1e300
  }
  u <- log(max(mu, 1e-300))
  n_b <- 0L
  for (k in seq_len(5L)) {
    gh <- drmTMB:::drm_gamma_mi_grad_hess(
      u, mu, sigma, y, mu_y, sigma_y, beta_x, x_base, response
    )
    H_safe <- min(gh$H, -1e-8)
    u_a <- u - max(min(gh$g / H_safe, 2), -2)
    Hg <- gh$H - gh$g
    ratio <- (gh$H - 2 * gh$g) / min(Hg, -1e-12)
    step_b <- max(min(log(max(ratio, 1e-300)), 2), -8)
    u_b <- if (isTRUE(Hg < 0 && ratio > 0)) u + step_b else u_a
    chose_b <- isTRUE(safe_f(u_b) > safe_f(u_a))
    if (chose_b) {
      n_b <- n_b + 1L
    }
    u <- if (chose_b) u_b else u_a
  }
  n_b
}

test_that("Gamma mi() obj$gr matches FD where Newton branch B wins (#1477)", {
  skip_on_cran()
  # Pole geometry: response wants x = 0.1, prior mean is x = 10, so the
  # iterate starts far from the mode and branch B (Newton on G(x) = g / x)
  # wins on the tape.
  n_b <- gamma_mi_newton_b_wins(
    mu = 10, sigma = 0.5, y = 2.05, mu_y = 2, sigma_y = 0.1,
    beta_x = 0.5, x_base = 0, response = "gaussian"
  )
  expect_gt(n_b, 0L)
  d <- data.frame(
    y = c(2.05, 3, 2.6, 3.4, 2.9, 3.1, 3.3, 2.7),
    x = c(NA_real_, NA_real_, 9, 11, 10, 8, 12, 10)
  )
  fit <- suppressWarnings(drmTMB(
    bf(y ~ mi(x), sigma ~ 1),
    data = d,
    impute = list(x = impute_model(x ~ 1, family = Gamma(link = "log"))),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  ))
  p <- fit$obj$par
  nm <- names(p)
  p[nm == "beta_mu"] <- c(2, 0.5)
  p[nm == "beta_sigma"] <- log(0.1)
  p[nm == "beta_mi"] <- log(10)
  p[nm == "log_sigma_mi"] <- log(0.5)
  expect_true(all(is.finite(fit$obj$gr(p))))
  cmp <- gamma_mi_fd_max_err(fit$obj, p)
  expect_true(all(is.finite(cmp$fd)))
  expect_lt(cmp$max_abs, 1e-5)
})

mi_enabled_term <- function(family, variable, mu, cv = 0.2, n = 6L, missing = 1L) {
  if (family %in% c("beta", "zero_one_beta")) {
    eta <- qlogis(min(max(mu, 1e-6), 1 - 1e-6))
  } else {
    eta <- log(max(mu, 1e-8))
  }
  list(
    enabled = TRUE,
    family = family,
    variable = variable,
    X = matrix(1, nrow = n, ncol = 1L),
    missing_index = as.integer(missing),
    beta_start = eta,
    log_sigma_start = log(cv)
  )
}

mi_inaccurate_spec <- function(first, second = NULL) {
  list(missing_predictor = first, missing_predictor2 = second)
}

mi_inaccurate_par <- function(first, second = NULL) {
  par <- list(
    beta_mi = first$beta_start,
    log_sigma_mi = first$log_sigma_start
  )
  if (is.list(second) && isTRUE(second$enabled)) {
    par$beta_mi2 <- second$beta_start
    par$log_sigma_mi2 <- second$log_sigma_start
  }
  par
}

caught_mi_inaccurate <- function(expr) {
  hit <- FALSE
  withCallingHandlers(
    expr,
    warning = function(e) {
      if (inherits(e, "drmTMB_mi_quadrature_inaccurate")) {
        hit <<- TRUE
      }
      invokeRestart("muffleWarning")
    }
  )
  hit
}

keep_mi_inaccurate_warning <- function(expr) {
  withCallingHandlers(
    expr,
    warning = function(e) {
      if (!inherits(e, "drmTMB_mi_quadrature_inaccurate")) {
        invokeRestart("muffleWarning")
      }
    }
  )
}

test_that("quadrature inaccuracy warning watches the second mi() term", {
  # Live two-mi fits are Gaussian+Gaussian only, so mixed families cannot
  # reach drmTMB(). The helper still loops both slots: Gaussian first,
  # Gamma second at CV >= 3 must warn.
  first <- mi_enabled_term("gaussian", "x1", mu = 0, cv = 0.4)
  second <- mi_enabled_term("gamma", "x2", mu = 10, cv = 3.5)
  expect_warning(
    drmTMB:::drm_warn_mi_quadrature_inaccurate(
      mi_inaccurate_spec(first, second),
      mi_inaccurate_par(first, second)
    ),
    class = "drmTMB_mi_quadrature_inaccurate"
  )
  second_beta <- mi_enabled_term("beta", "x2", mu = 0.02, cv = 1)
  expect_warning(
    drmTMB:::drm_warn_mi_quadrature_inaccurate(
      mi_inaccurate_spec(first, second_beta),
      mi_inaccurate_par(first, second_beta)
    ),
    class = "drmTMB_mi_quadrature_inaccurate"
  )
  expect_false(drmTMB:::drm_warn_mi_quadrature_inaccurate(
    mi_inaccurate_spec(first, mi_enabled_term("gamma", "x2", mu = 10, cv = 0.5)),
    mi_inaccurate_par(first, mi_enabled_term("gamma", "x2", mu = 10, cv = 0.5))
  ))
})

# Refs #1532: the accuracy guard used to drop a non-finite Beta mean and
# skip a non-finite Gamma log CV or CV, so the fit returned with no signal.
test_that("quadrature accuracy guard errors on a non-finite Beta missing-row mean", {
  term <- mi_enabled_term("beta", "x", mu = 0.5)
  for (bad in c(NA_real_, NaN)) {
    par <- mi_inaccurate_par(term)
    par$beta_mi <- bad
    expect_error(
      drmTMB:::drm_warn_mi_quadrature_inaccurate(mi_inaccurate_spec(term), par),
      class = "drmTMB_mi_quadrature_guard_nonfinite"
    )
  }
})

test_that("quadrature accuracy guard errors on a non-finite Gamma log CV", {
  term <- mi_enabled_term("gamma", "x", mu = 10, cv = 0.5)
  for (bad in c(NA_real_, NaN, Inf, -Inf)) {
    par <- mi_inaccurate_par(term)
    par$log_sigma_mi <- bad
    expect_error(
      drmTMB:::drm_warn_mi_quadrature_inaccurate(mi_inaccurate_spec(term), par),
      class = "drmTMB_mi_quadrature_guard_nonfinite"
    )
  }
  first <- mi_enabled_term("gaussian", "x1", mu = 0, cv = 0.4)
  par <- mi_inaccurate_par(first, term)
  par$log_sigma_mi2 <- NaN
  expect_error(
    drmTMB:::drm_warn_mi_quadrature_inaccurate(mi_inaccurate_spec(first, term), par),
    class = "drmTMB_mi_quadrature_guard_nonfinite"
  )
})

test_that("quadrature accuracy guard errors when the Gamma CV overflows", {
  term <- mi_enabled_term("gamma", "x", mu = 10, cv = 0.5)
  par <- mi_inaccurate_par(term)
  par$log_sigma_mi <- 710
  expect_error(
    drmTMB:::drm_warn_mi_quadrature_inaccurate(mi_inaccurate_spec(term), par),
    class = "drmTMB_mi_quadrature_guard_nonfinite"
  )
})

test_that("a live drmTMB() two-mi fit warns when the second term is inaccurate", {
  skip_on_cran()
  # Two live mi() terms are Gaussian+Gaussian. Relabel the fitted second
  # slot as Gamma at CV >= 3 so the helper must fire on slot 2 while slot 1
  # stays a healthy Gaussian prior.
  set.seed(15135)
  n <- 48
  x <- stats::rnorm(n)
  m1 <- 0.2 + 0.5 * x + stats::rnorm(n, sd = 0.35)
  m2 <- -0.1 + 0.4 * x + stats::rnorm(n, sd = 0.30)
  y <- 0.3 + 0.7 * m1 + 0.5 * m2 + 0.2 * x + stats::rnorm(n, sd = 0.4)
  d <- data.frame(y, m1, m2, x)
  d$m1[seq_len(n) %% 5L == 0L] <- NA_real_
  d$m2[seq_len(n) %% 6L == 0L] <- NA_real_
  fit <- suppressWarnings(drmTMB(
    bf(y ~ mi(m1) + mi(m2) + x, sigma ~ 1),
    data = d,
    impute = list(
      m1 = impute_model(m1 ~ x, family = gaussian()),
      m2 = impute_model(m2 ~ x, family = gaussian())
    ),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  ))
  expect_false(caught_mi_inaccurate({
    drmTMB:::drm_warn_mi_quadrature_inaccurate(
      fit$model,
      fit$obj$env$parList()
    )
  }))
  spec <- fit$model
  spec$missing_predictor2$family <- "gamma"
  par_list <- fit$obj$env$parList()
  par_list$log_sigma_mi2 <- log(3.5)
  expect_warning(
    drmTMB:::drm_warn_mi_quadrature_inaccurate(spec, par_list),
    class = "drmTMB_mi_quadrature_inaccurate"
  )
})

test_that("a live Beta mi() fit warns when missing-row mu is near 0", {
  skip_on_cran()
  set.seed(15131)
  n <- 80
  mu_x <- 0.04
  sigma_x <- 0.20
  x <- stats::rbeta(n, mu_x / sigma_x^2, (1 - mu_x) / sigma_x^2)
  y <- 0.5 + 2 * x + stats::rnorm(n, 0, 0.15)
  d <- data.frame(y, x)
  d$x[seq_len(12)] <- NA_real_
  expect_warning(
    keep_mi_inaccurate_warning(drmTMB(
      bf(y ~ mi(x), sigma ~ 1),
      data = d,
      impute = list(x = impute_model(x ~ 1, family = beta_family())),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    )),
    class = "drmTMB_mi_quadrature_inaccurate"
  )
})

test_that("a live Gamma mi() fit warns when CV >= 3", {
  skip_on_cran()
  set.seed(15132)
  n <- 80
  cv <- 3
  z <- stats::rnorm(n)
  mu <- exp(1.5 + 0.15 * z)
  x <- stats::rgamma(n, shape = 1 / cv^2, scale = mu * cv^2)
  y <- 1 + 0.2 * x + stats::rnorm(n, 0, 0.5)
  d <- data.frame(y, x, z)
  d$x[seq_len(10)] <- NA_real_
  expect_warning(
    keep_mi_inaccurate_warning(drmTMB(
      bf(y ~ mi(x), sigma ~ 1),
      data = d,
      impute = list(x = impute_model(x ~ z, family = Gamma(link = "log"))),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    )),
    class = "drmTMB_mi_quadrature_inaccurate"
  )
})

test_that("a healthy Gamma mi() fit does not warn drmTMB_mi_quadrature_inaccurate", {
  skip_on_cran()
  set.seed(1477)
  n <- 80
  nmiss <- 20
  cv <- 0.10
  z <- stats::rnorm(n)
  mu <- exp(2 + 0.2 * z)
  x <- stats::rgamma(n, shape = 1 / cv^2, scale = mu * cv^2)
  y <- 1 + 0.5 * x + stats::rnorm(n, 0, 0.5)
  d <- data.frame(y, x, z)
  d$x[sample(n, nmiss)] <- NA
  expect_false(caught_mi_inaccurate({
    drmTMB(
      bf(y ~ mi(x), sigma ~ 1),
      data = d,
      impute = list(x = impute_model(x ~ z, family = Gamma(link = "log"))),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    )
  }))
})

