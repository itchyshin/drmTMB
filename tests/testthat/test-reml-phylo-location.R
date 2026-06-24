# REML for the phylogenetic Gaussian LOCATION model (intercept-only sigma).
#
# REML restricts the likelihood for the mean fixed effects. For a Gaussian
# phylo mixed model y ~ Xb + phylo + iid resid, the restricted likelihood is
# exact, so drmTMB's REML estimates must match a hand-computed
# restricted-likelihood reference, and the phylo SD must be no more
# downward-biased than ML (REML corrects ML's variance-component bias).

reml_phylo_location_fixture <- function(n_tip = 30L, n_each = 3L, seed = 7L) {
  set.seed(seed)
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("sp_", seq_len(n_tip))
  A <- ape::vcv(tree, corr = TRUE)
  u <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip)) * 0.6 # true phylo SD ~ 0.6
  tip <- rep(seq_len(n_tip), each = n_each)
  n <- n_tip * n_each
  x <- stats::rnorm(n)
  y <- 0.4 + 0.7 * x + u[tip] + stats::rnorm(n, 0, 0.5) # true resid SD 0.5
  list(
    data = data.frame(
      y = y,
      x = x,
      species = factor(tree$tip.label[tip], levels = tree$tip.label)
    ),
    tree = tree,
    A = A,
    tip = tip
  )
}

# Hand restricted (REML) log-likelihood maximiser for y ~ Xb + phylo + iid resid,
# V = s2p * Z A Z' + s2r * I.
reml_reference <- function(y, X, Z, A) {
  n <- length(y)
  p <- ncol(X)
  ZAZt <- Z %*% A %*% t(Z)
  neg_restricted_ll <- function(par) {
    s2p <- exp(par[1])
    s2r <- exp(par[2])
    V <- s2p * ZAZt + s2r * diag(n)
    Vi <- solve(V)
    XtViX <- t(X) %*% Vi %*% X
    b <- solve(XtViX, t(X) %*% Vi %*% y)
    r <- y - X %*% b
    0.5 *
      ((n - p) *
        log(2 * pi) +
        as.numeric(determinant(V, logarithm = TRUE)$modulus) +
        as.numeric(determinant(XtViX, logarithm = TRUE)$modulus) +
        as.numeric(t(r) %*% Vi %*% r))
  }
  opt <- stats::optim(
    c(log(0.3), log(0.3)),
    neg_restricted_ll,
    method = "Nelder-Mead",
    control = list(reltol = 1e-11, maxit = 5000)
  )
  s2p <- exp(opt$par[1])
  s2r <- exp(opt$par[2])
  V <- s2p * ZAZt + s2r * diag(n)
  Vi <- solve(V)
  b <- solve(t(X) %*% Vi %*% X, t(X) %*% Vi %*% y)
  list(sd_phylo = sqrt(s2p), sigma = sqrt(s2r), beta = as.numeric(b))
}

test_that("REML for a phylo location model matches a hand-computed restricted likelihood", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- reml_phylo_location_fixture()
  tree <- fx$tree
  fit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
    data = fx$data,
    REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  )
  expect_equal(fit$estimator, "REML")
  expect_equal(fit$opt$convergence, 0L)

  X <- stats::model.matrix(~x, fx$data)
  n_tip <- length(tree$tip.label)
  Z <- matrix(0, nrow(fx$data), n_tip)
  Z[cbind(seq_len(nrow(fx$data)), fx$tip)] <- 1
  ref <- reml_reference(fx$data$y, X, Z, fx$A)

  expect_equal(as.numeric(fit$sdpars$mu[[1L]]), ref$sd_phylo, tolerance = 2e-2)
  expect_equal(
    exp(as.numeric(fit$par$sigma[1L])),
    ref$sigma,
    tolerance = 2e-2
  )
  # Under REML the mean fixed effects are marginalised into the random set, so
  # their REML point estimates are the GLS/BLUE modes recovered via parList().
  expect_equal(as.numeric(fit$par$mu), ref$beta, tolerance = 2e-2)
})

test_that("REML phylo SD is not more downward-biased than ML", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- reml_phylo_location_fixture()
  tree <- fx$tree
  form <- bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)
  fit_ml <- drmTMB(
    form,
    data = fx$data,
    control = drm_control(optimizer_preset = "robust")
  )
  fit_reml <- drmTMB(
    form,
    data = fx$data,
    REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  )
  # REML corrects ML's downward variance-component bias: the REML phylo SD is
  # at least as large as the ML one.
  expect_gte(
    as.numeric(fit_reml$sdpars$mu[[1L]]),
    as.numeric(fit_ml$sdpars$mu[[1L]]) - 1e-6
  )
})

test_that("REML still rejects a scale-side phylogenetic effect", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- reml_phylo_location_fixture()
  tree <- fx$tree
  expect_error(
    drmTMB(
      bf(
        y ~ x,
        sigma ~ phylo(1 | species, tree = tree)
      ),
      data = fx$data,
      REML = TRUE
    ),
    "scale-side"
  )
  expect_error(
    drmTMB(
      bf(
        y ~ x + phylo(1 | p | species, tree = tree),
        sigma ~ 1 + phylo(1 | p | species, tree = tree)
      ),
      data = fx$data,
      REML = TRUE
    ),
    "scale-side"
  )
})
