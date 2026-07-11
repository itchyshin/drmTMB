# Recovery + regression tests for the 0.4.0 fix that routes nbinom2 structured
# `sigma` terms onto the scale predictor (log_sigma) instead of the mean (eta_mu).
#
# Before 0.4.0, `sigma ~ phylo/spatial/animal/relmat(...)` for nbinom2 was accepted
# and reported a `*_sigma` SD, but src/drmTMB.cpp model_type 7 added the structured
# effect to eta_mu (no phylo_mu_dpar == 1 branch, unlike beta model_type 10). The fit
# was therefore numerically identical to a mean-phylo model. See
# docs/dev-log/known-limitations.md and the census entry.

nb2_sigma_phylo_data <- function(seed, where = c("sigma", "mean"),
                                 n_sp = 45, n_each = 18, sd_u = 1.2) {
  where <- match.arg(where)
  set.seed(seed)
  tree <- ape::rcoal(n_sp)
  tree$tip.label <- paste0("sp", seq_len(n_sp))
  V <- ape::vcv(tree)
  V <- V / max(V)
  u <- as.numeric(MASS::mvrnorm(1, rep(0, n_sp), sd_u^2 * V))
  names(u) <- tree$tip.label
  sp <- rep(tree$tip.label, each = n_each)
  x <- rnorm(n_sp * n_each)
  if (where == "sigma") {
    mu_true <- exp(1.4 + 0.3 * x)               # constant-structure mean
    size <- exp(0.4 + u[sp])                    # dispersion varies by species
  } else {
    mu_true <- exp(0.6 + 0.3 * x + u[sp])       # phylo signal on the mean
    size <- rep(3, length(mu_true))
  }
  y <- rnbinom(length(mu_true), mu = mu_true, size = size)
  list(data = data.frame(y = y, x = x, sp = sp), tree = tree,
       true_log_size = tapply(log(size), sp, mean))
}

fit_ll <- function(f) tryCatch(as.numeric(logLik(f)), error = function(e) NA_real_)

test_that("nbinom2 structured sigma recovers scale structure (0.4.0 routing fix)", {
  skip_on_cran()
  skip_fragile_recovery()
  skip_if_not_installed("ape")
  skip_if_not_installed("MASS")
  d <- nb2_sigma_phylo_data(202, where = "sigma")
  tree <- d$tree
  dat <- d$data
  ctrl <- drm_control(se = FALSE)
  f0 <- drmTMB(bf(y ~ x), family = nbinom2(), data = dat, control = ctrl)
  fM <- drmTMB(bf(y ~ x + phylo(1 + x | sp, tree = tree)),
               family = nbinom2(), data = dat, control = ctrl)
  fS <- drmTMB(bf(y ~ x, sigma ~ phylo(1 + x | sp, tree = tree)),
               family = nbinom2(), data = dat, control = ctrl)

  # scale-structured data: sigma~phylo must explain far more than mu~phylo
  expect_gt(fit_ll(fS) - fit_ll(f0), 15)
  expect_gt((fit_ll(fS) - fit_ll(f0)) - (fit_ll(fM) - fit_ll(f0)), 10)

  # the fitted per-species sigma must vary and track the true dispersion
  ps <- predict(fS, dpar = "sigma")
  by_sp <- tapply(as.numeric(ps), dat$sp, mean)
  expect_gt(sd(by_sp), 0.05)
  expect_gt(abs(suppressWarnings(cor(by_sp, d$true_log_size[names(by_sp)]))), 0.6)
})

test_that("nbinom2 structured sigma does NOT absorb a mean-phylo signal (mis-wire guard)", {
  skip_on_cran()
  skip_fragile_recovery()
  skip_if_not_installed("ape")
  skip_if_not_installed("MASS")
  d <- nb2_sigma_phylo_data(101, where = "mean")
  tree <- d$tree
  dat <- d$data
  ctrl <- drm_control(se = FALSE)
  f0 <- drmTMB(bf(y ~ x), family = nbinom2(), data = dat, control = ctrl)
  fM <- drmTMB(bf(y ~ x + phylo(1 + x | sp, tree = tree)),
               family = nbinom2(), data = dat, control = ctrl)
  fS <- drmTMB(bf(y ~ x, sigma ~ phylo(1 + x | sp, tree = tree)),
               family = nbinom2(), data = dat, control = ctrl)

  # a mean-phylo signal must be captured by mu~phylo, not by sigma~phylo
  expect_gt(fit_ll(fM) - fit_ll(f0), 5)
  # sigma~phylo must NOT recover the mean signal (would indicate the mis-wire returned)
  expect_lt(fit_ll(fS) - fit_ll(f0), 3)
})
