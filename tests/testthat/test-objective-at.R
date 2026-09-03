# Objective-At-A-Point (docs/design/35-optimizer-start-map-multistart.md,
# "Objective At A Point"). `objective_at(fit, at = list(...))` evaluates the
# fitted model's TMB objective at a supplied point, keyed by the same public
# start labels as `drm_control(start = ...)`, without refitting and without
# mutating the fitted object.

objective_at_fixef_data <- function() {
  set.seed(20260901)
  n <- 120
  x <- stats::rnorm(n)
  data.frame(y = -0.4 + 1.2 * x + stats::rnorm(n, 0, 0.8), x = x)
}

objective_at_sd_data <- function() {
  set.seed(20260902)
  id <- factor(rep(seq_len(8L), each = 5L))
  x <- stats::rnorm(40L)
  u <- stats::rnorm(8L, sd = 0.3)
  data.frame(
    id = id,
    x = x,
    y = 0.4 + 0.3 * x + u[id] + stats::rnorm(40L, sd = 0.2)
  )
}

test_that("objective_at is an exported generic with a drmTMB method", {
  expect_true(exists("objective_at", mode = "function"))
  expect_true(is.function(getS3method("objective_at", "drmTMB")))
})

test_that("objective_at reproduces -logLik at the fit's own optimum (self-consistency anchor)", {
  dat <- objective_at_fixef_data()
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  fx <- fixef(fit)
  at <- list()
  for (dp in names(fx)) {
    for (nm in names(fx[[dp]])) {
      at[[paste0("fixef:", dp, ":", nm)]] <- unname(fx[[dp]][[nm]])
    }
  }

  got <- objective_at(fit, at = at)
  expect_length(got, 1L)
  expect_equal(as.numeric(got), -as.numeric(stats::logLik(fit)), tolerance = 1e-8)
})

test_that("objective_at does not mutate the fitted object", {
  dat <- objective_at_fixef_data()
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  vcov_before <- stats::vcov(fit)
  invisible(objective_at(fit, at = list("fixef:mu:(Intercept)" = 0.2)))
  vcov_after <- stats::vcov(fit)

  expect_equal(vcov_after, vcov_before)
  expect_equal(as.numeric(stats::logLik(fit)), as.numeric(stats::logLik(fit)))
})

test_that("objective_at moves away from the optimum objective when perturbed", {
  dat <- objective_at_fixef_data()
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  at_optimum <- unname(fixef(fit)$mu[["(Intercept)"]])
  nll_hat <- objective_at(fit, at = list("fixef:mu:(Intercept)" = at_optimum))
  nll_off <- objective_at(fit, at = list("fixef:mu:(Intercept)" = at_optimum + 1))

  expect_equal(as.numeric(nll_hat), -as.numeric(stats::logLik(fit)), tolerance = 1e-8)
  expect_gt(as.numeric(nll_off), as.numeric(nll_hat))
})

test_that("objective_at supports sd: labels on the natural (positive) scale", {
  dat <- objective_at_sd_data()
  fit <- drmTMB(bf(y ~ x + (1 | id), sigma ~ 1), family = gaussian(), data = dat)

  sd_hat <- fit$sdpars$mu[["(1 | id)"]]
  nll_hat <- objective_at(fit, at = list("sd:mu:(1 | id)" = unname(sd_hat)))
  expect_equal(as.numeric(nll_hat), -as.numeric(stats::logLik(fit)), tolerance = 1e-6)
})

test_that("objective_at errors before evaluation on unknown labels", {
  dat <- objective_at_fixef_data()
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  expect_error(
    objective_at(fit, at = list("fixef:mu:not_a_column" = 0.1)),
    class = "rlang_error"
  )
})

test_that("objective_at requires a named list", {
  dat <- objective_at_fixef_data()
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  expect_error(objective_at(fit, at = list(0.1)), class = "rlang_error")
  expect_error(objective_at(fit, at = NULL), class = "rlang_error")
})

# Adversarial-pass fix (2026-09-01): the anchor was verified only on
# unpenalized fixed-effect Gaussian fits, which cannot expose a penalty
# convention mismatch. `fit$logLik` is stored unpenalized
# (`-opt$objective + phylo_penalty`, R/drmTMB.R); `obj$fn()` returns the
# penalized objective. These tests cover the two fit types that escaped the
# first pass: a penalized (MAP) phylo fit, and an MSPL fit.

objective_at_phylo_penalty_fixture <- function() {
  paths <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_phylo_mu_slope.R"
  )
  for (path in paths) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = environment())
  }
  dat <- phase18_dgp_phylo_mu_slope(
    n_tip = 8L, n_each = 6L, seed = 244L, cell_id = "objective_at_pen", replicate = 1L
  )
  list(data = dat, tree = attr(dat, "truth")$tree)
}

objective_at_mspl_fixture <- function() {
  group <- factor(rep(seq_len(12), each = 4L))
  x <- rep(c(-2, -1, 1, 2), 12L)
  y <- rep(c(0, 1, 0, 1), 12L)
  data.frame(y = y, x = x, group = group)
}

test_that("objective_at anchors on the unpenalized (logLik) convention for a penalized MAP phylo fit", {
  skip_on_cran()
  fx <- objective_at_phylo_penalty_fixture()
  tree <- fx$tree
  fit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
    data = fx$data,
    penalty = drm_phylo_penalty(sd_u = 0.25, sd_alpha = 0.01)
  )
  expect_equal(fit$estimator, "MAP")
  expect_gt(fit$phylo_penalty, 0)

  fx_fixef <- fixef(fit)
  at <- list()
  for (dp in names(fx_fixef)) {
    for (nm in names(fx_fixef[[dp]])) {
      at[[paste0("fixef:", dp, ":", nm)]] <- unname(fx_fixef[[dp]][[nm]])
    }
  }

  got <- objective_at(fit, at = at)
  # The pre-fix defect: `obj$fn()` alone returns the *penalized* objective, so
  # `got` would equal `-logLik(fit) + fit$phylo_penalty`, not `-logLik(fit)`.
  expect_equal(as.numeric(got), -as.numeric(stats::logLik(fit)), tolerance = 1e-6)
})

test_that("objective_at errors on MSPL fits, matching logLik()", {
  skip_on_cran()
  dat <- objective_at_mspl_fixture()
  fit <- drmTMB(
    bf(y ~ x + (1 | group)),
    family = binomial(),
    data = dat,
    estimator = "mspl",
    control = drm_control(se = FALSE, optimizer_preset = "careful", multi_start = 1L)
  )
  expect_equal(fit$estimator, "MSPL")
  expect_error(stats::logLik(fit), class = "drmTMB_mspl_inference_unsupported")
  expect_error(
    objective_at(fit, at = list("fixef:mu:(Intercept)" = 0)),
    class = "drmTMB_mspl_inference_unsupported"
  )
})

# rho12 and phylo block labels (design 35, "Phylo Covariance Block"; A5 gap,
# N3 2026-09-03). A5's cross-engine receipt found `objective_at()` could not
# name `biv_gaussian`'s `rho12` fixed effect or the q4 dense phylogenetic
# covariance block and had to substitute internal TMB parameter names
# directly. This fixture is a small (16-tip, 3 obs/tip) synthetic dense-q4
# biv_gaussian REML fit, matching the shape of the A5/DRM.jl parity fixture
# but self-contained (no DRM.jl, no `DRM_JL_PATH`).
objective_at_biv_q4_phylo_fixture <- function() {
  set.seed(575)
  tree <- ape::rcoal(16L, tip.label = sprintf("sp%02d", seq_len(16L)))
  species <- factor(rep(tree$tip.label, each = 3L), levels = tree$tip.label)
  n <- length(species)
  dat <- data.frame(
    y1 = stats::rnorm(n),
    y2 = stats::rnorm(n),
    x = stats::rnorm(n),
    species = species
  )
  form <- bf(
    mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
    mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
    sigma1 = ~ 1 + phylo(1 | p | species, tree = tree),
    sigma2 = ~ 1 + phylo(1 | p | species, tree = tree),
    rho12 = ~1
  )
  list(data = dat, tree = tree, formula = form)
}

objective_at_biv_q4_phylo_fit <- function() {
  fx <- objective_at_biv_q4_phylo_fixture()
  suppressWarnings(drmTMB(
    fx$formula,
    family = biv_gaussian(),
    data = fx$data,
    engine = "tmb",
    REML = TRUE,
    control = drm_control(optimizer_preset = "robust", keep_tmb_object = TRUE)
  ))
}

# Builds the `fixef:rho12:...`/`phylo_sd:...`/`phylo_cor:...` start from a
# fit's OWN optimum, matching the axis order `phylo_mu_endpoint_dpars()` uses
# for `log_sd_phylo`/`report()$phylo_q4_covariance` (mu1, mu2, sigma1, sigma2)
# and the `theta_phylo` Cholesky fill order documented at
# `drm_phylo_mu_dense_theta_index()` (R/drmTMB.R).
objective_at_biv_q4_phylo_start_at_fit <- function(fit) {
  par <- fit$opt$par
  log_sd_phylo <- unname(par[names(par) == "log_sd_phylo"])
  theta_phylo <- unname(par[names(par) == "theta_phylo"])
  rho12_hat <- as.numeric(coef(fit)$rho12[["(Intercept)"]])
  axes <- c("mu1", "mu2", "sigma1", "sigma2")
  pairs <- list(
    c("mu1", "mu2"), c("mu1", "sigma1"), c("mu2", "sigma1"),
    c("mu1", "sigma2"), c("mu2", "sigma2"), c("sigma1", "sigma2")
  )
  at <- list("fixef:rho12:(Intercept)" = rho12_hat)
  for (i in seq_along(axes)) {
    at[[paste0("phylo_sd:", axes[[i]])]] <- exp(log_sd_phylo[[i]])
  }
  for (i in seq_along(pairs)) {
    at[[paste0("phylo_cor:", pairs[[i]][[1L]], ":", pairs[[i]][[2L]])]] <- theta_phylo[[i]]
  }
  at
}

test_that("objective_at reaches rho12 and the q4 phylo block: reproduces -logLik at the fit's own optimum", {
  fit <- objective_at_biv_q4_phylo_fit()
  at <- objective_at_biv_q4_phylo_start_at_fit(fit)

  got <- objective_at(fit, at = at)
  expect_equal(as.numeric(got), -as.numeric(stats::logLik(fit)), tolerance = 1e-8)
})

test_that("objective_at with a displaced rho12/phylo block start (phylo block) is finite and larger than the anchor", {
  fit <- objective_at_biv_q4_phylo_fit()
  at <- objective_at_biv_q4_phylo_start_at_fit(fit)
  anchor <- objective_at(fit, at = at)

  displaced <- at
  displaced[["fixef:rho12:(Intercept)"]] <- displaced[["fixef:rho12:(Intercept)"]] + 0.3
  displaced[["phylo_sd:mu1"]] <- displaced[["phylo_sd:mu1"]] * 1.5

  got <- objective_at(fit, at = displaced)
  expect_true(is.finite(got))
  expect_gt(got, anchor)
})

test_that("objective_at rejects an unknown phylo block axis, listing the available axes", {
  fit <- objective_at_biv_q4_phylo_fit()
  expect_error(
    objective_at(fit, at = list("phylo_sd:mu3" = 0.2)),
    regexp = "Unknown public start label"
  )
  expect_error(
    objective_at(fit, at = list("phylo_cor:mu1:bogus" = 0.1)),
    regexp = "Unknown public start label"
  )
})
