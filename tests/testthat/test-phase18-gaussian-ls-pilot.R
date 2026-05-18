test_that("Phase 18 Gaussian location-scale conditions define pilot cells", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file(
      "sim/dgp/sim_dgp_gaussian_ls.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  conditions <- phase18_gaussian_ls_conditions(
    n = c(40L, 80L),
    sigma_slope = c(0.1, 0.3),
    collinearity = c(0, 0.5)
  )

  expect_equal(nrow(conditions), 8L)
  expect_named(
    conditions,
    c(
      "n",
      "sigma_slope",
      "collinearity",
      "beta_mu_intercept",
      "beta_mu_x",
      "beta_sigma_intercept"
    )
  )
  expect_true(all(conditions$n %in% c(40L, 80L)))
})

test_that("Phase 18 Gaussian location-scale DGP is seeded and self-describing", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file(
      "sim/dgp/sim_dgp_gaussian_ls.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  dat <- phase18_dgp_gaussian_ls(
    n = 32,
    beta_mu = c(0.1, 0.4),
    beta_sigma = c(-0.2, 0.25),
    collinearity = 0.4,
    seed = 211,
    cell_id = "gaussian_ls_001",
    replicate = 2
  )
  dat_again <- phase18_dgp_gaussian_ls(
    n = 32,
    beta_mu = c(0.1, 0.4),
    beta_sigma = c(-0.2, 0.25),
    collinearity = 0.4,
    seed = 211,
    cell_id = "gaussian_ls_001",
    replicate = 2
  )
  truth <- attr(dat, "truth")

  expect_equal(dat, dat_again)
  expect_equal(nrow(dat), 32L)
  expect_named(
    dat,
    c(
      "y",
      "x",
      "z",
      "mu",
      "sigma",
      "log_sigma",
      "cell_id",
      "replicate"
    )
  )
  expect_equal(dat$cell_id, rep("gaussian_ls_001", 32L))
  expect_equal(dat$replicate, rep(2, 32L))
  expect_equal(dat$mu, 0.1 + 0.4 * dat$x)
  expect_equal(dat$sigma, exp(dat$log_sigma))
  expect_true(all(dat$sigma > 0))
  expect_identical(truth$surface, "gaussian_ls")
  expect_named(truth$beta_mu, c("(Intercept)", "x"))
  expect_named(truth$beta_sigma, c("(Intercept)", "z"))
})

test_that("Phase 18 Gaussian location-scale pilot summariser records errors", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file(
      "sim/dgp/sim_dgp_gaussian_ls.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/fit/sim_summarise_gaussian_ls.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  dat <- phase18_dgp_gaussian_ls(
    n = 280,
    beta_mu = c("(Intercept)" = 0.15, x = 0.45),
    beta_sigma = c("(Intercept)" = -0.20, z = 0.30),
    collinearity = 0.15,
    seed = 2026211,
    cell_id = "gaussian_ls_001",
    replicate = 1L
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ z),
    family = gaussian(),
    data = dat
  )
  summary <- phase18_summarise_gaussian_ls_fit(
    fit,
    attr(dat, "truth"),
    cell_id = "gaussian_ls_001",
    replicate = 1L,
    elapsed = 0.01
  )

  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(
    summary$parameter,
    c(
      "mu:(Intercept)",
      "mu:x",
      "sigma:(Intercept)",
      "sigma:z"
    )
  )
  expect_equal(summary$cell_id, rep("gaussian_ls_001", 4L))
  expect_equal(summary$replicate, rep(1L, 4L))
  expect_equal(summary$nobs, rep(280L, 4L))
  expect_true(all(summary$converged))
  expect_true(all(summary$pdHess))
  expect_true(all(is.finite(summary$estimate)))
  expect_lt(max(abs(summary$error)), 0.35)
})

test_that("Phase 18 Gaussian location-scale helpers reject malformed inputs", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )
  source(
    system.file(
      "sim/dgp/sim_dgp_gaussian_ls.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )
  source(
    system.file(
      "sim/fit/sim_summarise_gaussian_ls.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = TRUE
  )

  expect_error(phase18_dgp_gaussian_ls(0), "positive whole number")
  expect_error(phase18_dgp_gaussian_ls(10, beta_mu = 1), "length 2")
  expect_error(
    phase18_dgp_gaussian_ls(
      10,
      beta_sigma = c(a = -0.2, b = 0.1)
    ),
    "beta_sigma"
  )
  expect_error(phase18_dgp_gaussian_ls(10, collinearity = 1), "below 1")
  expect_error(
    phase18_summarise_gaussian_ls_fit(list(), list(surface = "meta")),
    "Gaussian location-scale truth"
  )
})
