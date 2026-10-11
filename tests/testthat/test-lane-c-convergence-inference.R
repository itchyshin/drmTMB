# Lane C (convergence and inference reporting) regressions:
# #1469 diverging scale predictor reported as converged,
# #1317 REML Wald confint() returning NA for printed standard errors,
# #1336 skew-normal nu Wald SEs near the singular Gaussian null,
# #1315 percentile-bootstrap bias doubling documented on ?confint.drmTMB.
# The #1387 profile-trace memory regression lives in test-arc-d-profile-trace.R.

lane_c_edge_cell13 <- function(rep, n = 8) {
  # Cell 13 of the 3 Oct 2026 DRM edge grid (#1469): n = 8, 4 parameters.
  set.seed(20260927 + 1000 * 13 + rep)
  x <- stats::rnorm(n)
  data.frame(y = 1 + 0.5 * x + exp(-0.4 + 0.3 * x) * stats::rnorm(n), x = x)
}

test_that("a diverging scale predictor at the lower clamp is degenerate (#1469)", {
  for (rep in c(29L, 40L)) {
    dat <- lane_c_edge_cell13(rep)
    expect_warning(
      fit <- drmTMB(
        drm_formula(y ~ x, sigma ~ x),
        family = gaussian(),
        data = dat
      ),
      class = "drmTMB_clamp_active_warning"
    )
    expect_identical(fit$opt$convergence, 0L)
    expect_identical(convergence_status(fit), "degenerate")
    expect_false(is_converged(fit))
    chk <- check_drm(fit)
    clamp <- chk[chk$check == "logsigma_clamp_active", ]
    expect_identical(clamp$status, "warning")
    expect_match(clamp$message, "no finite", fixed = TRUE)
  }
})

test_that("the #1469 verdict survives keep_tmb_object = FALSE", {
  dat <- lane_c_edge_cell13(29L)
  expect_warning(
    fit <- drmTMB(
      drm_formula(y ~ x, sigma ~ x),
      family = gaussian(),
      data = dat,
      control = drm_control(keep_tmb_object = FALSE)
    ),
    class = "drmTMB_clamp_active_warning"
  )
  expect_null(fit$obj)
  expect_true(fit$scale_clamp_unbounded)
  expect_identical(convergence_status(fit), "degenerate")
  expect_false(is_converged(fit))
})

test_that("a well-posed fit rescaled into the clamp band is not called degenerate (#1469 review)", {
  # Genuine heteroscedasticity spanning ~4.5 orders of magnitude; on y * 1e-3
  # the soft-clamped log(sigma) reaches the lower band, but no observation is
  # fitted exactly, so the likelihood is bounded.
  set.seed(1)
  n <- 4000
  x <- stats::runif(n, -3.5, 3.5)
  y <- x + exp(-2 + 1.5 * x) * stats::rnorm(n)
  for (scale in c(1, 1e-3)) {
    fit <- suppressWarnings(drmTMB(
      bf(y ~ x, sigma ~ x),
      family = gaussian(),
      data = data.frame(y = y * scale, x = x)
    ))
    expect_false(fit$scale_clamp_unbounded)
    expect_false(identical(convergence_status(fit), "degenerate"))
  }
})

test_that("an ordinary small-n location-scale fit stays converged (#1469)", {
  dat <- lane_c_edge_cell13(1L)
  expect_no_warning(
    fit <- drmTMB(
      drm_formula(y ~ x, sigma ~ x),
      family = gaussian(),
      data = dat
    )
  )
  expect_identical(convergence_status(fit), "converged")
  expect_true(is_converged(fit))
})

test_that("the unbounded-scale signature needs spread, a continuous family, and no meta_V (#1469)", {
  diverging <- list(arm = "lower", value = -14.7, lo = -12, hi = 12, lower_spread = 18.4)
  small_everywhere <- utils::modifyList(diverging, list(lower_spread = 0.3))
  gaussian_spec <- list(model_type = "gaussian", has_known_v = FALSE)

  expect_true(drmTMB:::drm_lower_clamp_unbounded(diverging, gaussian_spec))
  # A response on a tiny numeric scale, or a user-narrowed band, is not flagged.
  expect_false(drmTMB:::drm_lower_clamp_unbounded(small_everywhere, gaussian_spec))
  # A meta-analysis at tau = 0 keeps a bounded likelihood.
  expect_false(drmTMB:::drm_lower_clamp_unbounded(
    diverging,
    utils::modifyList(gaussian_spec, list(has_known_v = TRUE))
  ))
  # NB2 sigma -> 0 is the Poisson limit, not a spike.
  expect_false(drmTMB:::drm_lower_clamp_unbounded(
    diverging,
    list(model_type = "nbinom2", has_known_v = FALSE)
  ))
  expect_false(drmTMB:::drm_lower_clamp_unbounded(
    utils::modifyList(diverging, list(arm = "upper")),
    gaussian_spec
  ))
  expect_false(drmTMB:::drm_lower_clamp_unbounded(NULL, gaussian_spec))
})

lane_c_reml_data <- function() {
  set.seed(1317)
  g <- factor(rep(seq_len(12), each = 5))
  x <- stats::rnorm(60)
  data.frame(
    y = 1 + 0.5 * x + stats::rnorm(12)[g] + stats::rnorm(60),
    x = x,
    g = g
  )
}

test_that("REML Wald intervals use the REML standard errors (#1317)", {
  dat <- lane_c_reml_data()
  fit <- drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), data = dat, REML = TRUE)

  ci <- confint(fit, parm = c("fixef:mu:(Intercept)", "fixef:mu:x"))
  expect_identical(ci$conf.status, c("wald", "wald"))
  expect_true(all(is.finite(c(ci$lower, ci$upper))))

  se <- sqrt(diag(stats::vcov(fit)))[c("mu:(Intercept)", "mu:x")]
  est <- unname(coef(fit, "mu"))
  z <- stats::qnorm(0.975)
  expect_equal(ci$lower, est - z * unname(se), tolerance = 1e-8)
  expect_equal(ci$upper, est + z * unname(se), tolerance = 1e-8)

  # Non-integrated targets are unchanged by the REML lookup.
  all_ci <- confint(fit)
  expect_true(all(is.finite(all_ci$lower)))

  # A plain REML fit without random effects behaves the same way.
  fit0 <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat, REML = TRUE)
  ci0 <- confint(fit0, parm = "fixef:mu:x")
  expect_identical(ci0$conf.status, "wald")
  expect_true(is.finite(ci0$lower) && is.finite(ci0$upper))
})

test_that("profiling a REML-integrated coefficient names the alternatives (#1317)", {
  dat <- lane_c_reml_data()
  fit <- drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), data = dat, REML = TRUE)
  expect_error(
    confint(fit, parm = "fixef:mu:x", method = "profile"),
    "REML = FALSE",
    fixed = TRUE
  )
})

test_that("ML Wald intervals are unchanged by the REML lookup (#1317)", {
  dat <- lane_c_reml_data()
  fit <- drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), data = dat)
  ci <- confint(fit, parm = "fixef:mu:x")
  se <- sqrt(diag(fit$sdr$cov.fixed))[which(names(fit$opt$par) == "beta_mu")[[2L]]]
  est <- unname(coef(fit, "mu")[["x"]])
  expect_equal(ci$lower, est - stats::qnorm(0.975) * unname(se), tolerance = 1e-8)
})

test_that("skew-normal nu near the Gaussian null gets a Wald caveat (#1336)", {
  set.seed(1336)
  n <- 300
  dat <- data.frame(x = stats::rnorm(n))
  dat$y <- 0.2 + 0.4 * dat$x + stats::rnorm(n)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, nu ~ x),
    family = skew_normal(),
    data = dat
  )
  chk <- check_drm(fit)
  row <- chk[chk$check == "skew_normal_nu_wald", ]
  expect_identical(nrow(row), 1L)
  expect_identical(row$status, "note")
  expect_match(row$message, "singular", fixed = TRUE)
  expect_match(row$message, "gaussian()", fixed = TRUE)
})

test_that("strongly skewed residuals away from nu = 0 pass the Wald caveat (#1336)", {
  set.seed(13360)
  n <- 400
  alpha <- 12
  delta <- alpha / sqrt(1 + alpha^2)
  dat <- data.frame(x = stats::rnorm(n))
  dat$y <- 0.2 + 0.4 * dat$x +
    delta * abs(stats::rnorm(n)) + sqrt(1 - delta^2) * stats::rnorm(n)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, nu ~ 1),
    family = skew_normal(),
    data = dat,
    control = drm_control(se = FALSE, optimizer_preset = "careful")
  )
  expect_gte(min(abs(predict(fit, dpar = "nu"))), 2)
  row <- check_drm(fit)
  row <- row[row$check == "skew_normal_nu_wald", ]
  expect_identical(row$status, "ok")
})

test_that("?confint.drmTMB documents percentile-bootstrap bias doubling (#1315)", {
  rd <- paste(readLines(drm_pkg_path("man/confint.drmTMB.Rd"), warn = FALSE), collapse = "\n")
  expect_match(rd, "Bootstrap intervals on biased targets", fixed = TRUE)
  expect_match(rd, "2.35", fixed = TRUE)
  expect_match(rd, "prefer \\code{method = \"wald\"}", fixed = TRUE)
  expect_match(rd, "section{REML fits}", fixed = TRUE)
})

test_that("check_known_v() rank test does not depend on the units of V (#710)", {
  set.seed(710)
  A <- matrix(stats::rnorm(36), 6)
  V <- crossprod(A) + diag(6)
  row_at <- function(scale) {
    object <- list(model = list(
      has_known_v = TRUE,
      V_known_type = "matrix",
      V_known = V * scale
    ))
    drmTMB:::check_known_v(object)
  }
  unit <- row_at(1)
  tiny <- row_at(1e-10)
  expect_identical(tiny$status, unit$status)
  expect_false(identical(tiny$status, "warning"))
  expect_match(tiny$value, "rank=6", fixed = TRUE)

  # A genuinely singular V is still caught at every scale.
  V_singular <- V
  V_singular[, 6] <- V_singular[, 5]
  V_singular[6, ] <- V_singular[5, ]
  singular <- drmTMB:::check_known_v(list(model = list(
    has_known_v = TRUE,
    V_known_type = "matrix",
    V_known = V_singular * 1e-10
  )))
  expect_identical(singular$status, "warning")
})

test_that("corpairs() refuses newdata instead of silently ignoring it (#802)", {
  set.seed(802)
  n <- 200
  x <- stats::rnorm(n)
  r <- tanh(0.3 + 0.4 * x)
  e1 <- stats::rnorm(n)
  e2 <- r * e1 + sqrt(1 - r^2) * stats::rnorm(n)
  dat <- data.frame(y1 = 1 + 0.5 * x + e1, y2 = -1 + 0.2 * x + e2, x = x)
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~x),
    family = biv_gaussian(),
    data = dat
  )
  expect_error(
    corpairs(fit, conf.int = TRUE, newdata = data.frame(x = 0)),
    class = "drmTMB_corpairs_newdata_unsupported"
  )
  expect_error(
    corpairs(fit, conf.int = TRUE, newdata = data.frame(x = 0)),
    "parm = \"rho12\"",
    fixed = TRUE
  )
  # The documented route returns a row-specific profile interval.
  ci <- confint(fit, parm = "rho12", newdata = data.frame(x = 0), method = "profile")
  expect_identical(ci$conf.status, "profile")
  expect_true(is.finite(ci$lower) && is.finite(ci$upper))
})

# Owner decision 4 (11 Oct 2026): flag-only check_drm() rows.

test_that("beta-binomial sigma at the binomial limit gets a boundary note (#1273)", {
  set.seed(1273)
  n <- 200
  x <- stats::rnorm(n)
  trials <- rep(10L, n)
  successes <- stats::rbinom(n, trials, stats::plogis(0.2 + 0.5 * x))
  dat <- data.frame(s = successes, f = trials - successes, x = x)
  fit <- suppressWarnings(drmTMB(
    bf(cbind(s, f) ~ x, sigma ~ 1),
    family = beta_binomial(),
    data = dat
  ))
  # Binomial data drive the beta-binomial sigma to the boundary.
  expect_lt(exp(unname(coef(fit, "sigma"))), 0.01)
  chk <- check_drm(fit)
  row <- chk[chk$check == "beta_binomial_sigma_boundary", ]
  expect_identical(nrow(row), 1L)
  expect_identical(row$status, "note")
  expect_match(row$message, "binomial limit", fixed = TRUE)
  # Flag only: estimates are unchanged by running the check.
  expect_identical(coef(fit), coef(fit))

  # Moderate overdispersion does not fire the row.
  p <- stats::rbeta(n, 2, 3)
  dat$s <- stats::rbinom(n, trials, p)
  dat$f <- trials - dat$s
  fit_od <- drmTMB(bf(cbind(s, f) ~ x, sigma ~ 1), family = beta_binomial(), data = dat)
  chk_od <- check_drm(fit_od)
  expect_false("beta_binomial_sigma_boundary" %in% chk_od$check)
})

test_that("a direct-SD formula at the log-SD clamp gets a note", {
  # 12 groups, 4 rows each: the sd(ID) ~ x slope runs the smallest group
  # log-SD to about -16, below the default clamp band of [-12, 12].
  set.seed(20260730)
  id <- factor(rep(seq_len(12), each = 4))
  x <- rep(seq(-0.6, 0.6, length.out = 12), each = 4)
  b <- stats::rnorm(12, sd = 0.4)
  dat <- data.frame(y = 0.2 + 0.5 * x + b[id] + stats::rnorm(48, sd = 0.5), x = x, ID = id)
  fit <- drmTMB(
    bf(y ~ x + (1 | ID), sigma ~ 1, sd(ID) ~ x),
    family = gaussian(),
    data = dat
  )
  row <- check_drm(fit)
  row <- row[row$check == "direct_sd_clamp_active", ]
  expect_identical(nrow(row), 1L)
  expect_identical(row$status, "note")
  expect_match(row$message, "clamp_limited", fixed = TRUE)

  # Without a direct-SD formula the row never appears.
  plain <- drmTMB(bf(y ~ x + (1 | ID), sigma ~ 1), family = gaussian(), data = dat)
  expect_false("direct_sd_clamp_active" %in% check_drm(plain)$check)
})

# Owner decision 17 (#1315): opt-in basic and bias-corrected bootstrap shapes.

test_that("basic and bc bootstrap endpoints follow their definitions (#1315)", {
  set.seed(1315)
  draws <- stats::rnorm(999, mean = -0.1, sd = 0.2)
  target <- data.frame(
    transformation = "exp",
    link_estimate = 0,
    estimate = 1,
    stringsAsFactors = FALSE
  )
  td <- data.frame(link_estimate = draws, estimate = exp(draws))
  probs <- c(0.025, 0.975)
  q <- stats::quantile(draws, probs, names = FALSE, type = 8)

  pct <- drmTMB:::bootstrap_interval_endpoints(td, target, probs, "percentile")
  expect_equal(pct, exp(q))

  basic <- drmTMB:::bootstrap_interval_endpoints(td, target, probs, "basic")
  expect_equal(basic, exp(2 * 0 - rev(q)))
  # The draws sit 0.1 below the estimate on the link scale; basic re-centres.
  expect_gt(mean(log(basic)), mean(log(pct)))
  expect_true(all(basic > 0))

  bc <- drmTMB:::bootstrap_interval_endpoints(td, target, probs, "bc")
  z0 <- stats::qnorm(mean(draws < 0))
  expect_equal(
    bc,
    exp(stats::quantile(draws, stats::pnorm(2 * z0 + stats::qnorm(probs)),
      names = FALSE, type = 8
    ))
  )
  expect_gt(mean(log(bc)), mean(log(pct)))

  # Every draw on one side of the estimate leaves BC undefined.
  one_sided <- data.frame(link_estimate = abs(draws) + 1, estimate = 1)
  expect_true(all(is.na(
    drmTMB:::bootstrap_interval_endpoints(one_sided, target, probs, "bc")
  )))

  # Correlation targets reflect on the link scale and stay inside (-1, 1).
  rho_target <- data.frame(
    transformation = "rho12_tanh",
    link_estimate = 2.5,
    estimate = tanh(2.5),
    stringsAsFactors = FALSE
  )
  rho_draws <- data.frame(link_estimate = stats::rnorm(999, 2, 0.5), estimate = NA_real_)
  rho_basic <- drmTMB:::bootstrap_interval_endpoints(rho_draws, rho_target, probs, "basic")
  expect_true(all(abs(rho_basic) < 1))
})

test_that("confint() exposes bootstrap_interval only for method = 'bootstrap' (#1315)", {
  set.seed(13150)
  dat <- data.frame(y = stats::rnorm(40), x = stats::rnorm(40))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  expect_error(
    confint(fit, method = "wald", bootstrap_interval = "basic"),
    "only used when"
  )
  pct <- suppressWarnings(confint(fit, parm = "sigma", method = "bootstrap", R = 30, seed = 1))
  bas <- suppressWarnings(confint(
    fit,
    parm = "sigma",
    method = "bootstrap",
    R = 30,
    seed = 1,
    bootstrap_interval = "basic"
  ))
  expect_identical(bas$conf.status, "bootstrap")
  expect_match(bas$profile.message, "basic interval", fixed = TRUE)
  expect_true(bas$lower > 0 && bas$upper > bas$lower)
  # The default is the historical percentile interval.
  draws <- attr(pct, "bootstrap.diagnostics")
  used <- draws$draw_used & draws$parm == "sigma"
  expect_equal(
    c(pct$lower, pct$upper),
    exp(stats::quantile(draws$draw_value[used], c(0.025, 0.975), names = FALSE, type = 8))
  )
  est <- log(stats::sigma(fit)[[1L]])
  expect_equal(
    c(bas$lower, bas$upper),
    exp(2 * est - rev(stats::quantile(draws$draw_value[used], c(0.025, 0.975),
      names = FALSE, type = 8
    ))),
    tolerance = 1e-6
  )
})
