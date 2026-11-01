# Gaussian mixes admitted by the sigma-endpoint SD guard but never tested alone:
#   (a) mu correlated q2 block (1 + x | id) with sd(id, coef = "x") ~ w PLUS a
#       sigma random intercept (1 | g) with sd(g, dpar = "sigma") ~ z;
#   (b) same-group mu and sigma intercepts, y ~ (1 | id), sigma ~ (1 | id),
#       each with an SD formula;
#   (c) each of the above and a mu plus sigma pair on different groups, with
#       meta_V(V = V) (known sampling variances added to the residual variance).
# A Gaussian with a sigma random effect has no closed-form marginal, so the
# oracle is a dense Laplace approximation over the JOINT mu and sigma random
# effects, evaluated at the fitted parameters. Tolerances fixed before the
# first run: abs. logLik 1e-4 against the oracle, oracle mode gradient < 1e-8,
# oracle Hessian positive definite; constant-SD limit abs. logLik 1e-5.
# Scope: likelihood agreement at the fitted parameters only. No recovery,
# coverage or calibration claim is made here.

gsem_fixture <- function(seed = 20261201L, n_id = 40L, n_each = 25L,
                         n_g = 60L) {
  set.seed(seed)
  n <- n_id * n_each
  row <- seq_len(n)
  id <- factor(sprintf("id%02d", (row - 1L) %/% n_each + 1L))
  g <- factor(sprintf("g%02d", (row - 1L) %% n_g + 1L))
  w_id <- seq(-1, 1, length.out = n_id)
  z_g <- seq(-1, 1, length.out = n_g)
  x <- stats::rnorm(n)
  V <- stats::runif(n, 0.05, 0.3)
  gi <- as.integer(id)
  gg <- as.integer(g)
  a0 <- stats::rnorm(n_id, sd = exp(log(0.5) + 0.3 * w_id))
  a1 <- stats::rnorm(n_id, sd = exp(log(0.4) + 0.4 * w_id))
  b_g <- stats::rnorm(n_g, sd = exp(log(0.45) + 0.5 * z_g))
  b_id <- stats::rnorm(n_id, sd = exp(log(0.45) + 0.5 * w_id))
  y <- 0.2 + 0.5 * x + a0[gi] + a1[gi] * x +
    stats::rnorm(n, sd = exp(log(0.5) + b_g[gg]))
  y_same <- 0.2 + 0.5 * x + a0[gi] +
    stats::rnorm(n, sd = exp(log(0.5) + b_id[gi]))
  list(
    data = data.frame(
      y = y, y_same = y_same, x = x, id = id, g = g, w = w_id[gi],
      z = z_g[gg], V = V,
      ym = y + stats::rnorm(n, sd = sqrt(V)),
      ym_same = y_same + stats::rnorm(n, sd = sqrt(V))
    ),
    n_id = n_id, n_g = n_g
  )
}

# Dense Laplace marginal log likelihood. Per observation
#   r_i = y_i - X_i beta - (Zm u)_i,  eta_i = s0 + (Zs u)_i,
#   T_i = exp(2 eta_i) + V_i,  nll_i = 0.5 log(2 pi) + 0.5 log T_i + 0.5 r_i^2 / T_i,
# and u ~ N(0, Sigma_u) with precision P and log det Sigma_u supplied.
# V = 0 gives the ordinary Gaussian; V > 0 is meta_V(V = V).
gsem_laplace_oracle <- function(y, X, beta, s0, V, Zm, Zs, P, logdet_cov) {
  m <- ncol(Zm)
  mu0 <- as.numeric(X %*% beta)
  obs <- function(u) {
    r <- y - mu0 - as.numeric(Zm %*% u)
    eta <- s0 + as.numeric(Zs %*% u)
    s <- exp(2 * eta)
    list(r = r, s = s, T = s + V)
  }
  neg_joint <- function(u) {
    o <- obs(u)
    sum(0.5 * log(2 * pi) + 0.5 * log(o$T) + 0.5 * o$r^2 / o$T) +
      0.5 * sum(u * (P %*% u)) + 0.5 * logdet_cov + 0.5 * m * log(2 * pi)
  }
  gradient <- function(u) {
    o <- obs(u)
    f_r <- o$r / o$T
    f_eta <- o$s / o$T - o$r^2 * o$s / o$T^2
    as.numeric(-crossprod(Zm, f_r) + crossprod(Zs, f_eta) + P %*% u)
  }
  hessian <- function(u) {
    o <- obs(u)
    f_rr <- 1 / o$T
    f_re <- -2 * o$r * o$s / o$T^2
    f_ee <- 2 * o$s * V / o$T^2 - 2 * o$r^2 * o$s * (V - o$s) / o$T^3
    cross <- crossprod(Zm, f_re * Zs)
    crossprod(Zm, f_rr * Zm) - cross - t(cross) +
      crossprod(Zs, f_ee * Zs) + P
  }
  u <- stats::nlminb(rep(0, m), neg_joint, gradient)$par
  for (k in seq_len(50L)) {
    g <- gradient(u)
    if (max(abs(g)) < 1e-10) break
    u <- u - solve(hessian(u), g)
  }
  H <- hessian(u)
  list(
    loglik = -neg_joint(u) + 0.5 * m * log(2 * pi) -
      0.5 * as.numeric(determinant(H, logarithm = TRUE)$modulus),
    max_grad = max(abs(gradient(u))),
    min_eig = min(eigen(H, symmetric = TRUE, only.values = TRUE)$values)
  )
}

gsem_indicator <- function(index, n_level) {
  out <- matrix(0, length(index), n_level)
  out[cbind(seq_along(index), index)] <- 1
  out
}

# Case (a) and its meta_V twin: u = (a0, a1, b); q2 block on id, sigma
# intercept on g.
gsem_oracle_a <- function(fit, fx, response, use_V) {
  d <- fx$data
  gi <- as.integer(d$id)
  gg <- as.integer(d$g)
  sd0 <- unname(fit$sdpars$mu)
  sd1 <- unname(stats::predict(fit, dpar = 'sd(id, coef = "x")', type = "response"))
  sdb <- unname(stats::predict(fit, dpar = 'sd(g, dpar = "sigma")', type = "response"))
  rho <- unname(fit$corpars$mu[[1L]])
  ni <- fx$n_id
  ng <- fx$n_g
  Ii <- gsem_indicator(gi, ni)
  Zm <- cbind(Ii, d$x * Ii, matrix(0, nrow(d), ng))
  Zs <- cbind(matrix(0, nrow(d), 2L * ni), gsem_indicator(gg, ng))
  P <- matrix(0, 2L * ni + ng, 2L * ni + ng)
  logdet <- 0
  for (k in seq_len(ni)) {
    S <- diag(c(sd0, sd1[k])) %*% matrix(c(1, rho, rho, 1), 2L) %*%
      diag(c(sd0, sd1[k]))
    idx <- c(k, ni + k)
    P[idx, idx] <- solve(S)
    logdet <- logdet + as.numeric(determinant(S, logarithm = TRUE)$modulus)
  }
  idx_b <- 2L * ni + seq_len(ng)
  P[cbind(idx_b, idx_b)] <- 1 / sdb^2
  logdet <- logdet + sum(log(sdb^2))
  gsem_laplace_oracle(
    y = d[[response]], X = cbind(1, d$x),
    beta = unname(stats::coef(fit, "mu")),
    s0 = unname(stats::coef(fit, "sigma"))[[1L]],
    V = if (use_V) d$V else rep(0, nrow(d)),
    Zm = Zm, Zs = Zs, P = P, logdet_cov = logdet
  )
}

# Case (b) and its meta_V twin: u = (a, b), both on id, independent.
gsem_oracle_b <- function(fit, fx, response, use_V) {
  d <- fx$data
  gi <- as.integer(d$id)
  sda <- unname(stats::predict(fit, dpar = "sd(id)", type = "response"))
  sdb <- unname(stats::predict(fit, dpar = 'sd(id, dpar = "sigma")', type = "response"))
  ni <- fx$n_id
  Ii <- gsem_indicator(gi, ni)
  gsem_laplace_oracle(
    y = d[[response]], X = cbind(1, d$x),
    beta = unname(stats::coef(fit, "mu")),
    s0 = unname(stats::coef(fit, "sigma"))[[1L]],
    V = if (use_V) d$V else rep(0, nrow(d)),
    Zm = cbind(Ii, matrix(0, nrow(d), ni)),
    Zs = cbind(matrix(0, nrow(d), ni), Ii),
    P = diag(c(1 / sda^2, 1 / sdb^2)),
    logdet_cov = sum(log(sda^2)) + sum(log(sdb^2))
  )
}

# Case (c1): meta_V with mu intercept on id and sigma intercept on g.
gsem_oracle_c1 <- function(fit, fx) {
  d <- fx$data
  gi <- as.integer(d$id)
  gg <- as.integer(d$g)
  sda <- unname(stats::predict(fit, dpar = "sd(id)", type = "response"))
  sdb <- unname(stats::predict(fit, dpar = 'sd(g, dpar = "sigma")', type = "response"))
  ni <- fx$n_id
  ng <- fx$n_g
  gsem_laplace_oracle(
    y = d$ym, X = cbind(1, d$x),
    beta = unname(stats::coef(fit, "mu")),
    s0 = unname(stats::coef(fit, "sigma"))[[1L]],
    V = d$V,
    Zm = cbind(gsem_indicator(gi, ni), matrix(0, nrow(d), ng)),
    Zs = cbind(matrix(0, nrow(d), ni), gsem_indicator(gg, ng)),
    P = diag(c(1 / sda^2, 1 / sdb^2)),
    logdet_cov = sum(log(sda^2)) + sum(log(sdb^2))
  )
}

gsem_expect_oracle <- function(fit, oracle) {
  expect_equal(fit$opt$convergence, 0L)
  expect_lt(oracle$max_grad, 1e-8)
  expect_gt(oracle$min_eig, 0)
  expect_lt(abs(as.numeric(stats::logLik(fit)) - oracle$loglik), 1e-4)
}

gsem_fit <- function(formula, data) {
  drmTMB(formula, family = stats::gaussian(), data = data,
         control = drm_control(se = FALSE))
}

test_that("(a) mu correlated q2 SD plus a sigma intercept SD matches the joint Laplace oracle", {
  skip_on_cran()
  fx <- gsem_fixture()
  fit <- gsem_fit(
    bf(y ~ x + (1 + x | id), sigma ~ 1 + (1 | g),
       sd(id, coef = "x") ~ w, sd(g, dpar = "sigma") ~ z),
    fx$data
  )
  expect_named(fit$sdpars, c('sd(id, coef = "x")', "mu", 'sd(g, dpar = "sigma")'),
               ignore.order = TRUE)
  gsem_expect_oracle(fit, gsem_oracle_a(fit, fx, "y", use_V = FALSE))
})

test_that("(b) same-group mu and sigma intercept SDs match the joint Laplace oracle", {
  skip_on_cran()
  fx <- gsem_fixture()
  fit <- gsem_fit(
    bf(y_same ~ x + (1 | id), sigma ~ 1 + (1 | id),
       sd(id) ~ w, sd(id, dpar = "sigma") ~ w),
    fx$data
  )
  expect_named(fit$sdpars, c("sd(id)", 'sd(id, dpar = "sigma")'),
               ignore.order = TRUE)
  gsem_expect_oracle(fit, gsem_oracle_b(fit, fx, "y_same", use_V = FALSE))
})

test_that("(c) meta_V with mu and sigma intercept SDs on different groups matches the oracle", {
  skip_on_cran()
  fx <- gsem_fixture()
  fit <- gsem_fit(
    bf(ym ~ x + (1 | id) + meta_V(V = V), sigma ~ 1 + (1 | g),
       sd(id) ~ w, sd(g, dpar = "sigma") ~ z),
    fx$data
  )
  gsem_expect_oracle(fit, gsem_oracle_c1(fit, fx))
})

test_that("(c) meta_V with the q2 mu block and a sigma intercept matches the oracle", {
  skip_on_cran()
  fx <- gsem_fixture()
  fit <- gsem_fit(
    bf(ym ~ x + (1 + x | id) + meta_V(V = V), sigma ~ 1 + (1 | g),
       sd(id, coef = "x") ~ w, sd(g, dpar = "sigma") ~ z),
    fx$data
  )
  gsem_expect_oracle(fit, gsem_oracle_a(fit, fx, "ym", use_V = TRUE))
})

test_that("(c) meta_V with same-group mu and sigma intercept SDs matches the oracle", {
  skip_on_cran()
  fx <- gsem_fixture()
  fit <- gsem_fit(
    bf(ym_same ~ x + (1 | id) + meta_V(V = V), sigma ~ 1 + (1 | id),
       sd(id) ~ w, sd(id, dpar = "sigma") ~ w),
    fx$data
  )
  gsem_expect_oracle(fit, gsem_oracle_b(fit, fx, "ym_same", use_V = TRUE))
})

test_that("meta_V changes the likelihood: the V-free oracle does not match a meta_V fit", {
  skip_on_cran()
  fx <- gsem_fixture()
  fit <- gsem_fit(
    bf(ym_same ~ x + (1 | id) + meta_V(V = V), sigma ~ 1 + (1 | id),
       sd(id) ~ w, sd(id, dpar = "sigma") ~ w),
    fx$data
  )
  wrong <- gsem_oracle_b(fit, fx, "ym_same", use_V = FALSE)
  expect_gt(abs(as.numeric(stats::logLik(fit)) - wrong$loglik), 1)
})

test_that("constant SD formulas reproduce the ordinary fits for every mix", {
  skip_on_cran()
  fx <- gsem_fixture(n_id = 30L, n_each = 20L, n_g = 40L, seed = 20261202L)
  d <- fx$data
  cases <- list(
    a = list(
      base = bf(y ~ x + (1 + x | id), sigma ~ 1 + (1 | g)),
      sdf = bf(y ~ x + (1 + x | id), sigma ~ 1 + (1 | g),
               sd(id, coef = "x") ~ 1, sd(g, dpar = "sigma") ~ 1)
    ),
    b = list(
      base = bf(y_same ~ x + (1 | id), sigma ~ 1 + (1 | id)),
      sdf = bf(y_same ~ x + (1 | id), sigma ~ 1 + (1 | id),
               sd(id) ~ 1, sd(id, dpar = "sigma") ~ 1)
    ),
    c3 = list(
      base = bf(ym_same ~ x + (1 | id) + meta_V(V = V), sigma ~ 1 + (1 | id)),
      sdf = bf(ym_same ~ x + (1 | id) + meta_V(V = V), sigma ~ 1 + (1 | id),
               sd(id) ~ 1, sd(id, dpar = "sigma") ~ 1)
    )
  )
  for (nm in names(cases)) {
    base_fit <- gsem_fit(cases[[nm]]$base, d)
    sd_fit <- gsem_fit(cases[[nm]]$sdf, d)
    expect_lt(
      abs(as.numeric(stats::logLik(sd_fit)) - as.numeric(stats::logLik(base_fit))),
      1e-5
    )
  }
})
