# Wave 1 of Russell Dinnage's independent evaluation of drmTMB 0.7.0
# (rdinnager/drmTMB_eval, pinned at 945da24f, report dated 2026-08-29).
# One test block per finding fixed in this lane.

test_that("Md-F: capability table lists non-Gaussian one-binary mi() routes (Dinnage audit)", {
  vignette <- testthat::test_path("..", "..", "vignettes", "capability-and-limits.Rmd")
  text <- readLines(vignette, warn = FALSE)
  row <- grep(
    "^\\| `binomial\\(\\)`, `poisson\\(\\)`, `nbinom2\\(\\)`, `beta\\(\\)`",
    text,
    value = TRUE
  )

  expect_length(row, 1L)
  expect_match(row, "`lognormal()`", fixed = TRUE)
  expect_match(row, "`Gamma(link = \"log\")`", fixed = TRUE)
  expect_match(row, "`student()`", fixed = TRUE)
  expect_match(row, "`beta_binomial()`", fixed = TRUE)
  expect_match(row, "one binary predictor", fixed = TRUE)
})

test_that("remaining A1 help pages document Dinnage audit caveats", {
  rd_text <- function(file) {
    paste(readLines(testthat::test_path("..", "..", "man", file), warn = FALSE),
      collapse = "\n"
    )
  }

  drm_help <- rd_text("drmTMB.Rd")
  expect_match(drm_help, "conf.status = \"wald_unavailable\"", fixed = TRUE)
  expect_match(drm_help, "method = \"bootstrap\"", fixed = TRUE)

  predict_help <- rd_text("predict.drmTMB.Rd")
  expect_match(predict_help, "not always \\code{E[Y]}", fixed = TRUE)
  expect_match(predict_help, "fitted-row response means", fixed = TRUE)

  summary_help <- rd_text("summary.drmTMB.Rd")
  expect_match(summary_help, "\\pkg{emmeans}", fixed = TRUE)

  residuals_help <- rd_text("residuals.drmTMB.Rd")
  expect_match(residuals_help, "DHARMa::createDHARMa", fixed = TRUE)
  expect_match(residuals_help, "Student-t scale", fixed = TRUE)
  expect_match(residuals_help, "sqrt(mu * (1 - mu) * sigma^2 / (1 + sigma^2))",
    fixed = TRUE
  )

  sigma_help <- rd_text("sigma.drmTMB.Rd")
  expect_match(sigma_help, "one scale value per observation", fixed = TRUE)
  expect_match(sigma_help, "insight::get_sigma()", fixed = TRUE)

  phylo_help <- rd_text("phylo.Rd")
  expect_match(phylo_help, "does not silently rescale the tree to unit height",
    fixed = TRUE
  )
})

test_that("M1: a constant weight leaves the mi() MLE unchanged (Dinnage audit)", {
  # weights(i) previously multiplied each leaf density BEFORE logspace_add()
  # combined them inside the mi() two-point mixture (mi_family == 1), which
  # computes log(p1*f1^w + p0*f0^w) instead of the correct
  # w*log(p1*f1 + p0*f0) -- a constant weight moved the MLE on the mi(x)
  # coefficient. Reproduces Russell's illustrative shape: a Bernoulli-imputed
  # binary covariate, missing at random, in a plain Gaussian mean model
  # (model_type == 1, the simplest mi() route).
  set.seed(42)
  n <- 200
  z <- stats::rnorm(n)
  x <- stats::rbinom(n, 1, stats::plogis(0.3 * z))
  y <- 1 + 0.8 * x + stats::rnorm(n, 0, 0.6)
  xm <- x
  miss <- sample(seq_len(n), 30)
  xm[miss] <- NA
  dat <- data.frame(y = y, x = xm, z = z)

  fit_coef <- function(data, weights = NULL) {
    fit <- allow_nonconvergence(drmTMB(
      bf(y ~ mi(x)),
      family = gaussian(),
      data = data,
      impute = list(x = impute_model(x ~ z, family = binomial())),
      missing = miss_control(predictor = "model"),
      weights = weights
    ))
    coef(fit)$mu
  }

  coef_w1 <- fit_coef(dat, rep(1, n))
  coef_w2 <- fit_coef(dat, rep(2, n))
  # The pre-fix code drifts by ~0.03 on the mi(x) slope across this weight
  # range (see the negative control in this finding's commit message);
  # post-fix the two must agree to a tight tolerance.
  expect_equal(coef_w1, coef_w2, tolerance = 1e-6)

  # weights = 2 must also match literal row duplication (the general weight
  # contract the report confirms holds everywhere except inside mi()).
  coef_dup <- fit_coef(rbind(dat, dat))
  expect_equal(coef_dup, coef_w2, tolerance = 1e-5)
})

test_that("Md-D: mi() is rejected outside the mu formula (Dinnage audit)", {
  # mi() is public API only for the univariate mean formula. Its stub is
  # `function(x) x`, so on every OTHER parameter it was silently parsed as an
  # ordinary covariate and discarded (no error, no missing-data handling):
  # `sigma ~ mi(z)` gave a bit-identical logLik to `sigma ~ z`.
  set.seed(1)
  n <- 60
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  dat <- data.frame(
    y = stats::rgamma(n, shape = 3, rate = 3 / exp(0.4 + 0.3 * x)),
    x = x,
    z = z
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ mi(z)),
      family = stats::Gamma(link = "log"),
      data = dat
    ),
    "mi"
  )

  # mi() in mu (the supported route) must still work -- a regression guard
  # for this fix's dpar == "mu" carve-out. Gamma-response mi() supports one
  # binary missing predictor.
  zb <- stats::rbinom(n, 1, stats::plogis(0.3 * x))
  zb[sample.int(n, 8)] <- NA
  dat_missing <- data.frame(y = dat$y, x = x, z = zb)
  fit_mi <- drmTMB(
    bf(y ~ x + mi(z)),
    family = stats::Gamma(link = "log"),
    data = dat_missing,
    impute = list(z = impute_model(z ~ x, family = binomial())),
    missing = miss_control(predictor = "model")
  )
  expect_true(is.finite(as.numeric(logLik(fit_mi))))
})

test_that("Md-E: an unused factor level no longer zeroes out every SE (Dinnage audit)", {
  # A design-matrix column of all zeros (from an unused factor level, e.g.
  # left over from `subset()` without `droplevels()`) made the fit's Hessian
  # singular: point estimates were exactly right, but every standard error
  # came back NA (`sdreport_non_pd_hessian`), even for coefficients unrelated
  # to the unused level.
  set.seed(2)
  n <- 80
  g <- factor(sample(c("a", "b"), n, replace = TRUE), levels = c("a", "b", "c"))
  x <- stats::rnorm(n)
  y <- 1 + 0.5 * x + ifelse(g == "b", 0.3, 0) + stats::rnorm(n, 0, 0.4)
  dat <- data.frame(y = y, x = x, g = g)

  fit <- drmTMB(bf(y ~ x + g), family = gaussian(), data = dat)
  se <- summary(fit)$coefficients$std_error
  expect_true(all(is.finite(se)))
  # The unused level "c" is dropped up front, so it never becomes its own
  # (all-zero) coefficient column.
  expect_false("mu:gc" %in% rownames(summary(fit)$coefficients))
})

test_that("Md-N: dropped_rows reflects MSPL-discarded rows (Dinnage audit)", {
  # check_drm()'s dropped_rows row reads spec$keep, which the family builders
  # compute relative to the (already MSPL-filtered) data -- so a row MSPL
  # discarded because of a zero frequency weight was invisible to it, and it
  # printed "no rows were dropped" even though MSPL had discarded one.
  group <- factor(rep(seq_len(10), each = 4L))
  x <- rep(c(-1.5, -0.5, 0.5, 1.5), 10L)
  trials <- rep(c(2L, 3L, 2L, 4L), 10L)
  successes <- rep(c(0L, 1L, 1L, 3L), 10L)
  frequency <- rep(c(1L, 2L, 1L, 1L), 10L)
  off <- rep(c(-0.25, 0.1, 0.2, -0.1), 10L)
  grouped <- data.frame(
    successes, failures = trials - successes, x, group, off, frequency
  )
  with_zero <- rbind(
    grouped,
    data.frame(
      successes = 999L, failures = 0L, x = 999, group = group[[1L]],
      off = 0, frequency = 0L
    )
  )
  zero_fit <- drmTMB(
    bf(cbind(successes, failures) ~ x + offset(off) + (1 | group)),
    binomial(), with_zero,
    weights = with_zero$frequency,
    estimator = "mspl",
    control = drm_control(se = FALSE, optimizer_preset = "careful", multi_start = 2L)
  )
  chk <- check_drm(zero_fit)
  row <- chk[chk$check == "dropped_rows", ]
  expect_equal(nrow(row), 1L)
  expect_match(row$value, "dropped=1", fixed = TRUE)
})

test_that("Md-M: skew_normal's far tail matches pnorm(log.p = TRUE) (Dinnage audit)", {
  # skew_normal floored its skew-CDF factor with pnorm(...) + 1e-300 instead
  # of the package's own tail-safe drm_log_pnorm() (used elsewhere, e.g. the
  # binomial probit link). At alpha = 10, z = -40 (alpha*z = -400, deep past
  # where pnorm() underflows to exactly 0), the floor saturates the
  # log-density to log(1e-300) ~ -690.8 regardless of how far in the tail the
  # point is; the correct value is a further ~80000 nats more negative.
  alpha <- 10
  mu <- 0
  log_sigma <- 0
  sigma <- exp(log_sigma)
  delta <- alpha / sqrt(1 + alpha^2)
  mean_shift <- delta * sqrt(2 / pi)
  variance_factor <- 1 - mean_shift^2
  omega <- sigma / sqrt(variance_factor)
  xi <- mu - omega * mean_shift
  target_z <- -40
  y_target <- xi + target_z * omega

  fit <- allow_nonconvergence(drmTMB(
    bf(y ~ 1, sigma ~ 1, nu ~ 1),
    family = skew_normal(),
    data = data.frame(y = y_target),
    control = drm_control(se = FALSE)
  ))
  par <- fit$opt$par
  par[names(par) == "beta_mu"] <- mu
  par[names(par) == "beta_sigma"] <- log_sigma
  par[names(par) == "beta_nu"] <- alpha
  nll_pkg <- fit$obj$fn(par)
  expect_true(is.finite(nll_pkg))

  z <- (y_target - xi) / omega
  log_density_ref <-
    log(2) - log(omega) + stats::dnorm(z, log = TRUE) +
    stats::pnorm(alpha * z, log.p = TRUE)
  expect_equal(as.numeric(nll_pkg), -log_density_ref, tolerance = 1e-6)
})
