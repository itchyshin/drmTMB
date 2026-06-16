# Penalized / MAP phylogenetic estimator (Phase 3, slice 1).
#
# The penalty puts a PC-prior (exponential on the SD, with the log-Jacobian) on
# the phylogenetic SD endpoints and an optional N(0, cor_sd) on the live phylo
# correlation. Plain ML stays the default and bit-identical when penalty = NULL.

source_phase18_phylo_mu_slope <- function(env = parent.frame()) {
  paths <- c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/R/sim_aggregate.R",
    "sim/R/sim_uncertainty.R",
    "sim/dgp/sim_dgp_phylo_mu_slope.R"
  )
  for (path in paths) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

phylo_penalty_fixture <- function(cell_id = "pen_001") {
  source_phase18_phylo_mu_slope()
  dat <- phase18_dgp_phylo_mu_slope(
    n_tip = 8L, n_each = 6L, seed = 244L, cell_id = cell_id, replicate = 1L
  )
  list(data = dat, tree = attr(dat, "truth")$tree)
}

test_that("drm_phylo_penalty validates inputs and computes the PC-prior rate", {
  p <- drm_phylo_penalty(sd_u = 1, sd_alpha = 0.05)
  expect_s3_class(p, "drm_phylo_penalty")
  expect_equal(p$rate, -log(0.05) / 1)
  expect_null(p$cor_sd)

  p2 <- drm_phylo_penalty(sd_u = 0.5, sd_alpha = 0.01, cor_sd = 2)
  expect_equal(p2$rate, -log(0.01) / 0.5)
  expect_equal(p2$cor_sd, 2)

  expect_error(drm_phylo_penalty(sd_u = 0), "sd_u")
  expect_error(drm_phylo_penalty(sd_alpha = 0), "sd_alpha")
  expect_error(drm_phylo_penalty(sd_alpha = 1), "sd_alpha")
  expect_error(drm_phylo_penalty(cor_sd = 0), "cor_sd")
})

test_that("penalty = NULL leaves the phylo fit unpenalized (estimator ML)", {
  skip_on_cran()
  fx <- phylo_penalty_fixture()
  tree <- fx$tree
  fit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
    data = fx$data
  )
  expect_equal(fit$estimator, "ML")
  expect_null(fit$penalty)
  pen <- if (is.null(fit$phylo_penalty)) 0 else fit$phylo_penalty
  expect_equal(pen, 0)
  rep <- fit$obj$report()
  expect_true(is.null(rep$phylo_penalty) || isTRUE(rep$phylo_penalty == 0))
})

test_that("penalty shrinks the phylo SD, labels MAP, and keeps logLik unpenalized", {
  skip_on_cran()
  fx <- phylo_penalty_fixture("pen_002")
  tree <- fx$tree
  form <- bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)

  fit_ml <- drmTMB(form, data = fx$data)
  fit_map <- drmTMB(
    form,
    data = fx$data,
    penalty = drm_phylo_penalty(sd_u = 0.25, sd_alpha = 0.01)
  )

  expect_equal(fit_map$estimator, "MAP")
  expect_s3_class(fit_map$penalty, "drm_phylo_penalty")

  # PC-prior shrinks the phylogenetic location SD toward zero.
  sd_ml <- as.numeric(fit_ml$sdpars$mu[[1L]])
  sd_map <- as.numeric(fit_map$sdpars$mu[[1L]])
  expect_lt(sd_map, sd_ml)

  # The reported penalty is positive and recovers the unpenalized logLik:
  # penalized objective = -logLik(unpenalized) + penalty.
  pen <- fit_map$phylo_penalty
  expect_gt(pen, 0)
  expect_equal(-fit_map$opt$objective, fit_map$logLik - pen, tolerance = 1e-6)

  # Penalty value matches the analytic PC-prior (exponential-on-SD + Jacobian).
  rep <- fit_map$obj$report()
  lam <- fit_map$penalty$rate
  log_sd <- as.numeric(rep$log_sd_phylo)
  expected_pen <- sum(lam * exp(log_sd) - log_sd - log(lam))
  expect_equal(pen, expected_pen, tolerance = 1e-6)
})
