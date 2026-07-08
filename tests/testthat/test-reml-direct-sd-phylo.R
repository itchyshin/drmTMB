# REML for the phylogenetic direct-SD (heteroscedastic phylo variance) model:
# `sd_phylo(sp) ~ predictors`. The phylo random effect has SD exp(Zsd gamma), so its
# marginal covariance is D A D with D = diag(exp(Zsd gamma)); with an iid residual,
# V = D A D + sigma^2 I. REML restricts for the mean fixed effects, so drmTMB's REML
# must match an exact restricted-likelihood reference. The second test guards the REML
# coefficient standard errors: the sd_phylo betas are NOT ADREPORTed into sdr$value, so
# vcov() falls back to cov.fixed for them (regression guard for that fix).

sdphylo_fixture <- function(n_tip = 150L, seed = 5L) {
  set.seed(seed)
  tree <- ape::rcoal(n_tip); tree$tip.label <- paste0("sp_", seq_len(n_tip))
  A <- ape::vcv(tree, corr = TRUE); L <- t(chol(A))
  x <- stats::rnorm(n_tip)
  g <- c(log(0.8), 0.5)                              # sd_phylo = exp(g0 + g1 x), identified
  sdp <- exp(g[1] + g[2] * x)
  a <- sdp * as.vector(L %*% stats::rnorm(n_tip))    # Cov(a) = D A D
  y <- 0.3 + 0.7 * x + a + stats::rnorm(n_tip, 0, 0.4)
  list(data = data.frame(sp = factor(tree$tip.label, levels = tree$tip.label), x = x, y = y),
       tree = tree, A = A, g = g)
}

sdphylo_reml_reference <- function(y, X, A, Zsd) {
  n <- length(y); p <- ncol(X); k <- ncol(Zsd)
  dl <- function(m) as.numeric(determinant(m, logarithm = TRUE)$modulus)
  nll <- function(par) {
    d <- exp(as.vector(Zsd %*% par[seq_len(k)]))
    V <- outer(d, d) * A + exp(2 * par[k + 1L]) * diag(n)
    Vi <- solve(V); XtViX <- t(X) %*% Vi %*% X
    b <- solve(XtViX, t(X) %*% Vi %*% y); r <- y - X %*% b
    0.5 * ((n - p) * log(2 * pi) + dl(V) + dl(XtViX) + as.numeric(t(r) %*% Vi %*% r))
  }
  opt <- stats::optim(c(log(0.8), 0.5, log(0.4)), nll, method = "Nelder-Mead",
                      control = list(reltol = 1e-11, maxit = 15000))
  list(g = opt$par[seq_len(k)], log_sigma = opt$par[k + 1L])
}

test_that("phylogenetic direct-SD REML matches an exact restricted-likelihood reference", {
  skip_on_cran()
  fx <- sdphylo_fixture()
  dat <- fx$data; tree <- fx$tree
  fit <- drmTMB(bf(y ~ x + phylo(1 | sp, tree = tree), sigma ~ 1, sd_phylo(sp) ~ x),
                family = gaussian(), data = dat, REML = TRUE,
                control = drm_control(optimizer_preset = "robust"))
  expect_equal(fit$estimator, "REML")
  expect_equal(fit$opt$convergence, 0L)
  X <- stats::model.matrix(~x, dat); Zsd <- stats::model.matrix(~x, dat)
  ref <- sdphylo_reml_reference(dat$y, X, fx$A, Zsd)
  cf <- summary(fit)$coefficients
  expect_equal(cf["sd_phylo(sp):(Intercept)", "estimate"], ref$g[1], tolerance = 3e-2)
  expect_equal(cf["sd_phylo(sp):x", "estimate"], ref$g[2], tolerance = 3e-2)
  expect_equal(cf["sigma:(Intercept)", "estimate"], ref$log_sigma, tolerance = 2e-2)
})

test_that("REML sd_phylo coefficient SEs are finite in summary()/vcov (cov.fixed fallback)", {
  skip_on_cran()
  fx <- sdphylo_fixture()
  dat <- fx$data; tree <- fx$tree
  fit <- drmTMB(bf(y ~ x + phylo(1 | sp, tree = tree), sigma ~ 1, sd_phylo(sp) ~ x),
                family = gaussian(), data = dat, REML = TRUE,
                control = drm_control(optimizer_preset = "robust"))
  cf <- summary(fit)$coefficients
  sd_rows <- grep("^sd_phylo", rownames(cf))
  expect_true(length(sd_rows) >= 1L)
  expect_true(all(is.finite(cf[sd_rows, "std_error"])))
  vc <- vcov(fit)
  expect_true(all(is.finite(diag(vc)[grep("^sd_phylo", rownames(vc))])))
})
