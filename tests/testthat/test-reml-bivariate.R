# REML for the bivariate Gaussian LOCATION model (fixed-effect mu1/mu2).
#
# REML restricts the likelihood for both mean blocks (beta_mu1, beta_mu2). With
# identical regressors in mu1 and mu2 the GLS mean estimates equal the per-
# response OLS estimates (a seemingly-unrelated-regressions result), so the REML
# residual covariance is exactly the OLS-residual cross-products divided by
# (n - p): sigma1 = sqrt(SSE1/(n-p)), sigma2 = sqrt(SSE2/(n-p)), and rho12 is the
# residual correlation (the (n-p) factor cancels, so REML rho12 = ML rho12).
# drmTMB's bivariate REML must match this exact reference.

biv_reml_fixture <- function(n = 150L, seed = 3L) {
  set.seed(seed)
  x <- stats::rnorm(n)
  S <- chol(matrix(c(1, 0.4, 0.4, 1), 2, 2))
  e <- matrix(stats::rnorm(2 * n), n, 2) %*% S
  data.frame(
    y1 = 0.3 + 0.5 * x + 0.8 * e[, 1],
    y2 = 0.1 + 0.2 * x + 0.9 * e[, 2],
    x = x
  )
}

biv_reml_reference <- function(y1, y2, X) {
  n <- length(y1)
  p <- ncol(X)
  hat <- X %*% solve(t(X) %*% X) %*% t(X)
  resid_maker <- diag(n) - hat
  e1 <- as.vector(resid_maker %*% y1)
  e2 <- as.vector(resid_maker %*% y2)
  b1 <- as.vector(solve(t(X) %*% X, t(X) %*% y1))
  b2 <- as.vector(solve(t(X) %*% X, t(X) %*% y2))
  list(
    sigma1 = sqrt(sum(e1^2) / (n - p)),
    sigma2 = sqrt(sum(e2^2) / (n - p)),
    rho12 = sum(e1 * e2) / sqrt(sum(e1^2) * sum(e2^2)),
    beta = c(b1, b2)
  )
}

test_that("bivariate fixed-effect REML matches an exact restricted-likelihood reference", {
  skip_on_cran()
  dat <- biv_reml_fixture()
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
    family = biv_gaussian(),
    data = dat,
    REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  )
  expect_equal(fit$estimator, "REML")
  expect_equal(fit$opt$convergence, 0L)

  X <- stats::model.matrix(~x, dat)
  ref <- biv_reml_reference(dat$y1, dat$y2, X)

  expect_equal(
    exp(as.numeric(fit$par$sigma1[1L])),
    ref$sigma1,
    tolerance = 1e-3
  )
  expect_equal(
    exp(as.numeric(fit$par$sigma2[1L])),
    ref$sigma2,
    tolerance = 1e-3
  )
  # rho12 is read on the response scale (fit$par$rho12 is the atanh-scale
  # coefficient); rho12() returns the constant response-scale correlation.
  expect_equal(as.numeric(rho12(fit))[1L], ref$rho12, tolerance = 1e-3)
  expect_equal(
    c(as.numeric(fit$par$mu1), as.numeric(fit$par$mu2)),
    ref$beta,
    tolerance = 1e-3
  )
})

test_that("bivariate REML df counts both marginalised mean blocks", {
  skip_on_cran()
  dat <- biv_reml_fixture()
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
    family = biv_gaussian(),
    data = dat,
    REML = TRUE
  )
  # 3 fixed (sigma1, sigma2, rho12 intercepts) + 4 marginalised (mu1, mu2 each x2)
  expect_equal(attr(stats::logLik(fit), "df"), length(fit$opt$par) + 4L)
})

test_that("bivariate REML now ADMITS ordinary random-intercept means (rung 1)", {
  skip_on_cran()
  set.seed(5)
  n_id <- 40
  n <- n_id * 4
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = 4)),
    x = stats::rnorm(n)
  )
  u <- stats::rnorm(n_id, 0, 0.7)
  dat$y1 <- 0.3 + 0.5 * dat$x + u[dat$id] + stats::rnorm(n, 0, 0.6)
  dat$y2 <- 0.1 + 0.2 * dat$x + u[dat$id] + stats::rnorm(n, 0, 0.6)
  fit <- drmTMB(
    bf(mu1 = y1 ~ x + (1 | p | id), mu2 = y2 ~ x + (1 | p | id),
       sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
    family = biv_gaussian(), data = dat, REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  )
  expect_equal(fit$estimator, "REML")
  expect_equal(fit$opt$convergence, 0L)
  # 3 fixed (sigma1, sigma2, rho12) + 4 marginalised mean coefs (mu1, mu2 each x2)
  expect_equal(attr(stats::logLik(fit), "df"), length(fit$opt$par) + 4L)
})

# Exact restricted-likelihood reference for the biv phylo-MEAN model (1 obs/species):
# stack y = (y1; y2); V = G kron A (phylo loc-loc) + R kron I (residual). REML restricts
# for beta_mu1, beta_mu2. drmTMB's biv phylo REML must match this maximiser. Recovery
# across n is in docs/design/221-native-reml-finish.md (ladder: bias -> 0 with n, REML
# debiases the variance components, REML/ML SEs agree).
biv_phylo_reml_fixture <- function(n_tip = 150L, seed = 4L) {
  set.seed(seed)
  tree <- ape::rcoal(n_tip); tree$tip.label <- paste0("sp_", seq_len(n_tip))
  A <- ape::vcv(tree, corr = TRUE); L <- t(chol(A))
  # Strong, well-identified phylo block (phylo SD > residual SD) so the exact-match
  # test converges cleanly at moderate n; recovery across realistic signal/n is the
  # ladder in doc 221 (a weak block under-identifies at small n, as expected).
  G <- matrix(c(1.0^2, 0.5 * 1.0 * 0.8, 0.5 * 1.0 * 0.8, 0.8^2), 2, 2)
  R <- matrix(c(0.5^2, 0.3 * 0.5 * 0.5, 0.3 * 0.5 * 0.5, 0.5^2), 2, 2)
  M <- L %*% matrix(stats::rnorm(n_tip * 2), n_tip, 2) %*% chol(G)
  E <- matrix(stats::rnorm(n_tip * 2), n_tip, 2) %*% chol(R)
  x <- stats::rnorm(n_tip)
  list(
    data = data.frame(
      sp = factor(tree$tip.label, levels = tree$tip.label), x = x,
      y1 = 0.3 + 0.5 * x + M[, 1] + E[, 1], y2 = 0.1 + 0.2 * x + M[, 2] + E[, 2]),
    tree = tree, A = A)
}

biv_phylo_reml_reference <- function(y1, y2, X, A) {
  n <- nrow(A); p <- 2 * ncol(X); In <- diag(n)
  Xb <- rbind(cbind(X, matrix(0, n, ncol(X))), cbind(matrix(0, n, ncol(X)), X))
  y <- c(y1, y2)
  dl <- function(m) as.numeric(determinant(m, logarithm = TRUE)$modulus)
  Vof <- function(par) {
    sp1 <- exp(par[1]); sp2 <- exp(par[2]); rp <- tanh(par[3])
    sr1 <- exp(par[4]); sr2 <- exp(par[5]); r12 <- tanh(par[6])
    rbind(cbind(sp1^2 * A + sr1^2 * In, rp * sp1 * sp2 * A + r12 * sr1 * sr2 * In),
          cbind(rp * sp1 * sp2 * A + r12 * sr1 * sr2 * In, sp2^2 * A + sr2^2 * In))
  }
  nll <- function(par) {
    V <- Vof(par); Vi <- solve(V); XtViX <- t(Xb) %*% Vi %*% Xb
    b <- solve(XtViX, t(Xb) %*% Vi %*% y); r <- y - Xb %*% b
    0.5 * ((2 * n - p) * log(2 * pi) + dl(V) + dl(XtViX) + as.numeric(t(r) %*% Vi %*% r))
  }
  opt <- stats::optim(
    c(log(1.0), log(0.8), atanh(0.5), log(0.5), log(0.5), atanh(0.3)),
    nll, method = "Nelder-Mead", control = list(reltol = 1e-11, maxit = 20000))
  V <- Vof(opt$par); Vi <- solve(V)
  b <- solve(t(Xb) %*% Vi %*% Xb, t(Xb) %*% Vi %*% y)
  list(sd_phylo1 = exp(opt$par[1]), sd_phylo2 = exp(opt$par[2]), cor_phylo = tanh(opt$par[3]),
       sigma1 = exp(opt$par[4]), sigma2 = exp(opt$par[5]), rho12 = tanh(opt$par[6]),
       beta = as.numeric(b))
}

test_that("bivariate phylo-mean REML matches an exact restricted-likelihood reference", {
  skip_on_cran()
  fx <- biv_phylo_reml_fixture()
  dat <- fx$data
  tree <- fx$tree
  fit <- drmTMB(
    bf(mu1 = y1 ~ x + phylo(1 | p | sp, tree = tree),
       mu2 = y2 ~ x + phylo(1 | p | sp, tree = tree),
       sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
    family = biv_gaussian(), data = dat, REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  )
  expect_equal(fit$estimator, "REML")
  expect_equal(fit$opt$convergence, 0L)
  X <- stats::model.matrix(~x, dat)
  ref <- biv_phylo_reml_reference(dat$y1, dat$y2, X, fx$A)
  v <- setNames(summary(fit)$parameters$estimate, summary(fit)$parameters$parm)
  g1 <- function(rx) unname(v[grep(rx, names(v))][1])
  expect_equal(g1("^sd:mu:mu1"), ref$sd_phylo1, tolerance = 2e-2)
  expect_equal(g1("^sd:mu:mu2"), ref$sd_phylo2, tolerance = 2e-2)
  expect_equal(g1("^cor:phylo"), ref$cor_phylo, tolerance = 5e-2)
  expect_equal(unname(v["sigma1"]), ref$sigma1, tolerance = 1e-2)
  expect_equal(unname(v["sigma2"]), ref$sigma2, tolerance = 1e-2)
  expect_equal(unname(v["rho12"]), ref$rho12, tolerance = 2e-2)
  expect_equal(c(as.numeric(fit$par$mu1), as.numeric(fit$par$mu2)), ref$beta, tolerance = 1e-2)
})

test_that("bivariate REML ADMITS phylogenetic direct-SD scale (rung 2)", {
  skip_on_cran()
  fx <- biv_phylo_reml_fixture(n_tip = 200L)
  dat <- fx$data
  tree <- fx$tree
  fit <- drmTMB(
    bf(mu1 = y1 ~ x + phylo(1 | p | sp, tree = tree),
       mu2 = y2 ~ x + phylo(1 | p | sp, tree = tree),
       sigma1 = ~1, sigma2 = ~1,
       sd_phylo1(sp) ~ x, sd_phylo2(sp) ~ x, rho12 = ~1),
    family = biv_gaussian(), data = dat, REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  )
  expect_equal(fit$estimator, "REML")
  # sd_phylo coefficient SEs must be finite under REML (vcov cov.fixed fallback)
  cf <- summary(fit)$coefficients
  sd_rows <- grep("^sd_phylo", rownames(cf))
  expect_true(length(sd_rows) >= 1L)
  expect_true(all(is.finite(cf[sd_rows, "std_error"])))
})

test_that("bivariate REML ADMITS the block-diagonal location-scale phylo layout, rejects dense (S3)", {
  skip_on_cran()
  skip_if_not_installed("ape")
  # Block-diagonal q4: a phylo MEAN block (label p) is INDEPENDENT of a phylo SCALE
  # block (label ps) -- no mean-scale cross-covariance. This is identifiable under
  # REML WITH per-group replication; the scale-side random phylo collapses at 1
  # obs/species (use a fixed sd_phylo scale for species-mean data). Evidence: the
  # replication ladder scratchpad/reml_blockdiag_replication_ladder.R (2026-07-07)
  # -- n_each>=5 -> 100% pdHess and biases -> 0 at n_tip>=150. This fixture uses
  # n_each=5. We assert ADMISSION + convergence + estimable variance components
  # (not the weakly-identified scale correlation, and -- per the pdHess-is-a-want
  # doctrine -- not pdHess), plus the dense-layout negative control.
  set.seed(3L)
  n_tip <- 100L; n_each <- 5L; n <- n_tip * n_each
  tree <- ape::rcoal(n_tip); tree$tip.label <- paste0("sp_", seq_len(n_tip))
  A <- ape::vcv(tree, corr = TRUE); L <- t(chol(A))
  Gl <- chol(matrix(c(.6^2, .4 * .6 * .5, .4 * .6 * .5, .5^2), 2, 2))
  Gs <- chol(matrix(c(.4^2, .3 * .4 * .3, .3 * .4 * .3, .3^2), 2, 2))
  Am <- L %*% matrix(stats::rnorm(n_tip * 2), n_tip, 2) %*% Gl
  As <- L %*% matrix(stats::rnorm(n_tip * 2), n_tip, 2) %*% Gs
  tip <- rep(seq_len(n_tip), each = n_each)
  s1 <- exp(log(.5) + As[tip, 1]); s2 <- exp(log(.6) + As[tip, 2])
  dat <- data.frame(
    sp = factor(tree$tip.label[tip], levels = tree$tip.label),
    y1 = 0.3 + Am[tip, 1] + stats::rnorm(n, 0, s1),
    y2 = 0.7 + Am[tip, 2] + stats::rnorm(n, 0, s2)
  )
  block_diag <- bf(
    mu1 = y1 ~ 1 + phylo(1 | p | sp, tree = tree),
    mu2 = y2 ~ 1 + phylo(1 | p | sp, tree = tree),
    sigma1 = ~ 1 + phylo(1 | ps | sp, tree = tree),
    sigma2 = ~ 1 + phylo(1 | ps | sp, tree = tree),
    rho12 = ~ 1
  )
  fit <- suppressWarnings(drmTMB(
    block_diag, family = biv_gaussian(), data = dat, REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  ))
  expect_identical(fit$estimator, "REML")
  expect_identical(fit$opt$convergence, 0L)
  v <- setNames(summary(fit)$parameters$estimate, summary(fit)$parameters$parm)
  sds <- v[grepl("^sd:mu:", names(v))]
  expect_length(sds, 4L)
  expect_true(all(is.finite(sds) & sds > 0))

  # Negative control: the DENSE full-q4 layout (one shared label on all four
  # endpoints -> mean-scale cross-covariance) stays REJECTED under REML.
  dense <- bf(
    mu1 = y1 ~ 1 + phylo(1 | p | sp, tree = tree),
    mu2 = y2 ~ 1 + phylo(1 | p | sp, tree = tree),
    sigma1 = ~ 1 + phylo(1 | p | sp, tree = tree),
    sigma2 = ~ 1 + phylo(1 | p | sp, tree = tree),
    rho12 = ~ 1
  )
  expect_error(
    drmTMB(dense, family = biv_gaussian(), data = dat, REML = TRUE),
    "block-diagonal location-scale layout only"
  )
})
