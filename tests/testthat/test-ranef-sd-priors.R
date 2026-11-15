test_that("Gamma SD prior resolves the named random intercept", {
  d <- data.frame(y = 1:6, x = rep(-1:1, 2), site = factor(rep(1:2, each = 3)))
  p <- drm_priors(drm_prior_sd_gamma(dpar = "mu", group = "site",
    coef = "(Intercept)", shape = 2, rate = 3))
  target <- drm_resolve_priors(bf(mu = y ~ x + (1 | site), sigma = ~ x),
                               gaussian(), d, p)
  expect_equal(target$group, "site")
  expect_equal(target$shape, 2)
  expect_equal(target$rate, 3)
})

test_that("native objective and derivatives match the frozen dense Gaussian oracle", {
  oracle <- Sys.getenv("DRM_SD_ORACLE", unset = "")
  if (!nzchar(oracle)) oracle <- testthat::test_path("fixtures", "ranef-sd-prior-oracle")
  expect_true(dir.exists(oracle), info = paste("frozen oracle fixtures:", oracle))
  skip_if_not_installed("jsonlite")
  skip_if_not_installed("numDeriv")
  fixture <- jsonlite::fromJSON(file.path(oracle, "fixture.json"), simplifyVector = FALSE)
  optima <- jsonlite::fromJSON(file.path(oracle, "fitted_optima.json"), simplifyVector = FALSE)$fits
  for (setup in list(list(shape = 2, rate = 3, file = "expected.json"),
                     list(shape = 2.5, rate = 1.7, file = "expected_noninteger.json"))) {
    expected <- jsonlite::fromJSON(file.path(oracle, setup$file), simplifyVector = FALSE)$results
    for (case in seq_along(fixture$cases)) {
      dat <- fixture$cases[[case]]
      d <- data.frame(y = unlist(dat$y), x = unlist(dat$x), site = factor(unlist(dat$group)))
      p <- drm_priors(drm_prior_sd_gamma(group = "site", shape = setup$shape, rate = setup$rate))
      fit <- suppressWarnings(drmTMB(bf(mu = y ~ x + (1 | site), sigma = ~ x), data = d, priors = p))
      positions <- c(which(names(fit$obj$par) == "beta_mu"), which(names(fit$obj$par) == "beta_sigma"),
                     which(names(fit$obj$par) == "log_sd_mu"))
      expect_length(positions, 5L)
      optimum <- optima[[which(vapply(optima, function(z) z$case == case - 1L && z$shape == setup$shape, logical(1)))]]
      score <- max(abs(fit$obj$gr(fit$opt$par)))
      expect_true(is.finite(score))
      expect_lte(score, 1e-6)
      expect_lte(abs(fit$opt$objective - optimum$objective), 1e-7 * max(1, abs(optimum$objective)))
      if (isTRUE(optimum$refinement$success) && isTRUE(optimum$parameter_comparison_eligible) &&
          identical(as.integer(fit$opt$convergence), 0L) && is.finite(score) && score <= 1e-6) {
        expect_lte(max(abs(unname(fit$opt$par[positions]) - unlist(optimum$coordinates))), 1e-5)
      } else {
        message(sprintf("Optimum comparison: case=%d shape=%g native_code=%s native_score=%.3g oracle_success=%s; objective and score only",
                        case - 1L, setup$shape, fit$opt$convergence, score, optimum$refinement$success))
      }
      for (k in seq_along(fixture$points)) {
        point <- unlist(fixture$points[[k]])
        ref <- expected[[which(vapply(expected, function(z) z$case == case - 1L && z$point == k - 1L, logical(1)))]]
        par <- fit$obj$par; par[positions] <- point
        fn <- function(v) { q <- par; q[positions] <- v; fit$obj$fn(q) }
        gr <- function(v) { q <- par; q[positions] <- v; fit$obj$gr(q)[positions] }
        obj <- fn(point); g <- gr(point); h <- numDeriv::jacobian(gr, point)
        h_ref <- do.call(rbind, lapply(ref$hessian, function(x) as.numeric(unlist(x))))
        expect_lte(abs(obj - as.numeric(ref$objective)), 1e-8 * max(1, abs(as.numeric(ref$objective))))
        expect_lte(max(abs(g - as.numeric(unlist(ref$gradient)))), 1e-6)
        expect_lte(max(abs(h - h_ref) / pmax(1, abs(h_ref))), 1e-5)
      }
    }
  }
})

test_that("Gamma SD selectors fail closed", {
  d <- data.frame(y = 1:6, x = rep(-1:1, 2), site = factor(rep(1:2, each = 3)))
  f <- bf(mu = y ~ x + (1 | site), sigma = ~ x)
  expect_error(drm_prior_sd_gamma(group = "site", shape = 1, rate = 3), "shape")
  expect_error(drm_prior_sd_gamma(group = "site", shape = 2, rate = Inf), "rate")
  expect_error(drm_prior_sd_gamma(group = "site", shape = NA_real_, rate = 3), "shape")
  expect_error(drm_prior_sd_gamma(group = "site", coef = "x", shape = 2, rate = 3), "Intercept")
  wrong <- drm_priors(drm_prior_sd_gamma(group = "wrong", shape = 2, rate = 3))
  expect_error(drm_resolve_priors(f, gaussian(), d, wrong), "target")
  p <- drm_prior_sd_gamma(group = "site", shape = 2, rate = 3)
  expect_error(drm_resolve_priors(f, gaussian(), d, drm_priors(p, p)), "one SD prior")
  expect_error(drm_resolve_priors(bf(y ~ x), gaussian(), d, drm_priors(p)), "intercept")
})

test_that("SD prior bridge weights are evaluated and validated in the data", {
  d <- data.frame(w = c(1, 1, 1))
  check <- drmTMB:::drm_julia_sd_prior_weights
  expect_equal(check(quote(w), d, environment()), c(1, 1, 1))
  expect_error(check(quote(c(1, NA, 1)), d, environment()), "unit weights")
  expect_error(check(quote(c(1, 2, 1)), d, environment()), "unit weights")
  expect_error(check(quote(c(1, 1)), d, environment()), "one value per row")
  expect_error(check(quote(NULL), d, environment()), "unit weights")
})

test_that("a nonstationary or numerically underflowed SD is not successful", {
  opt <- list(par = c(log_sd_mu = -30), convergence = 0L, message = "relative convergence")
  checked <- drmTMB:::drm_sd_prior_check_score(opt, c(-1))
  expect_false(identical(as.integer(checked$convergence), 0L))
  expect_match(checked$message, "score")
  expect_identical(drmTMB:::drm_sd_prior_check_score(opt, c(0))$convergence, 0L)
  tiny <- list(par = c(log_sd_mu = -400), convergence = 0L, message = "relative convergence")
  expect_false(identical(as.integer(drmTMB:::drm_sd_prior_check_score(tiny, c(-1e-8))$convergence), 0L))
})

test_that("rescaling the response and rate preserves the SD-density transformation", {
  d <- data.frame(x = rep(c(-1, 0, 1), 4), site = factor(rep(1:4, each = 3)))
  d$y <- 0.3 + 0.5*d$x + rep(c(-0.5, 0.2, 0.4, -0.1), each = 3) + rep(c(0.1, -0.2, 0.15), 4)
  scale <- 2.4
  p <- drm_priors(drm_prior_sd_gamma(group = "site", shape = 2.5, rate = 1.7))
  fit <- suppressWarnings(drmTMB(bf(mu = y ~ x + (1 | site), sigma = ~ x), data = d, priors = p))
  d$y <- scale * d$y
  ps <- drm_priors(drm_prior_sd_gamma(group = "site", shape = 2.5, rate = 1.7 / scale))
  scaled <- suppressWarnings(drmTMB(bf(mu = y ~ x + (1 | site), sigma = ~ x), data = d, priors = ps))
  pos <- function(f, name) which(names(f$obj$par) == name)
  point <- fit$obj$par
  point[pos(fit, "beta_mu")] <- c(0.8, 0.3)
  point[pos(fit, "beta_sigma")] <- c(-0.1, 0.12)
  point[pos(fit, "log_sd_mu")] <- -0.35
  q <- scaled$obj$par
  q[pos(scaled, "beta_mu")] <- scale * point[pos(fit, "beta_mu")]
  q[pos(scaled, "beta_sigma")] <- point[pos(fit, "beta_sigma")] + c(log(scale), 0)
  q[pos(scaled, "log_sd_mu")] <- point[pos(fit, "log_sd_mu")] + log(scale)
  expect_equal(as.numeric(scaled$obj$fn(q) - fit$obj$fn(point)), (nrow(d) + 1) * log(scale), tolerance = 1e-8)
  g <- fit$obj$gr(point); gs <- scaled$obj$gr(q)
  gs[pos(scaled, "beta_mu")] <- scale * gs[pos(scaled, "beta_mu")]
  expect_equal(unname(gs), unname(g), tolerance = 1e-6)
  skip_if_not_installed("numDeriv")
  h <- numDeriv::jacobian(fit$obj$gr, point)
  hs <- numDeriv::jacobian(scaled$obj$gr, q)
  factors <- rep(1, length(q)); factors[pos(scaled, "beta_mu")] <- scale
  hs <- hs * outer(factors, factors)
  expect_lte(max(abs(hs - h) / pmax(1, abs(h))), 1e-5)
})

test_that("SD and fixed penalties compose and keep likelihood separate", {
  d <- data.frame(x = rep(c(-1, 0, 1), 4), site = factor(rep(1:4, each = 3)))
  d$y <- 0.3 + 0.5*d$x + rep(c(-0.5, 0.2, 0.4, -0.1), each = 3) + rep(c(0.1, -0.2, 0.15), 4)
  p <- drm_priors(drm_prior_sd_gamma(group = "site", shape = 2.5, rate = 1.7),
                  drm_prior_normal("mu", "x", sd = 2))
  f <- suppressWarnings(drmTMB(bf(mu = y ~ x + (1 | site), sigma = ~ 1), data = d, priors = p))
  eta <- unname(f$opt$par[which(names(f$opt$par) == "log_sd_mu")])
  expect_equal(f$sd_prior_penalty, -dgamma(exp(eta), 2.5, rate = 1.7, log = TRUE), tolerance = 1e-9)
  expect_equal(f$penalized_objective, -f$logLik + f$fixed_prior_penalty + f$sd_prior_penalty, tolerance = 1e-8)
  expect_equal(f$estimator, "MAP")
  expect_error(confint(f), "prior")
  expect_error(AIC(f), "prior")
  expect_error(drmTMB:::drm_abort_fixed_prior_inference(f, "bootstrap"), "prior")
  sd_only <- f
  sd_only$resolved_priors <- NULL
  expect_true(drmTMB:::drm_has_fixed_priors(sd_only))
  replay <- suppressWarnings(update(f))
  expect_equal(replay$sd_prior_penalty, f$sd_prior_penalty, tolerance = 1e-8)
  expect_equal(replay$penalized_objective, f$penalized_objective, tolerance = 1e-8)
  zero <- drm_priors(drm_prior_ridge("mu", "x", lambda = 0),
                     drm_prior_sd_gamma(group = "site", shape = 2.5, rate = 1.7))
  z <- suppressWarnings(drmTMB(bf(mu = y ~ x + (1 | site), sigma = ~ 1), data = d, priors = zero))
  expect_equal(z$estimator, "MAP")
  expect_error(confint(z), "prior")
})
