# NB2 joint mu plus sigma ordinary random intercepts on the SAME grouping
# factor, each with its own SD formula:
#   bf(y ~ x + (1 | id), sigma ~ 1 + (1 | id),
#      sd(id) ~ w, sd(id, dpar = "sigma") ~ z)
# The mu and sigma effects of a group are two independent N(0, 1) draws scaled
# by their own SDs (no mu-sigma correlation is modelled).
#
# Fixed tolerances (set before the first run):
#   logLik versus the dense Laplace oracle at the fitted parameters: 1e-3
#   oracle gradient at the fitted optimum:                            1e-2
#   independent-MLE coefficients (constant-SD case):                  2e-2
#   independent-MLE logLik (constant-SD case):                        1e-3
#   emulated-bug gap must exceed 100 * 1e-3 = 0.1
#
# The oracle uses only base R (dense 2G-dimensional Laplace, finite-difference
# Hessian of an analytic gradient). It does not call drmTMB or TMB.

sg_tol_ll <- 1e-3
sg_tol_coef <- 2e-2
sg_tol_grad <- 1e-2
sg_bug_gap <- 100 * sg_tol_ll

sg_fixture <- function(G = 40L, n = 800L, seed = 2026110111L,
                       alpha_mu = c(-0.5, 0.3), alpha_sigma = c(-0.7, 0.3)) {
  set.seed(seed)
  lev_id <- sample(sprintf("i%02d", seq_len(G)))  # shuffled levels
  id <- factor(sample(rep_len(lev_id, n)), levels = lev_id)
  w_level <- stats::setNames(stats::rnorm(G), lev_id)
  z_level <- stats::setNames(stats::rnorm(G), lev_id)
  a <- stats::rnorm(G) * exp(alpha_mu[1L] + alpha_mu[2L] * w_level)
  cc <- stats::rnorm(G) * exp(alpha_sigma[1L] + alpha_sigma[2L] * z_level)
  x <- stats::rnorm(n)
  eta <- 1 + 0.3 * x + a[as.integer(id)]
  sigma_i <- exp(-0.6 + cc[as.integer(id)])
  y <- stats::rnbinom(n, size = 1 / sigma_i^2, mu = exp(eta))
  list(
    data = data.frame(y = y, x = x, id = id,
                      w = w_level[as.character(id)],
                      z = z_level[as.character(id)]),
    w_level = w_level, z_level = z_level
  )
}

# Dense Laplace log marginal. sd_a / sd_c are SD vectors in factor-level order of id.
nb2sg_laplace <- function(data, beta_mu, beta_sigma, sd_a, sd_c) {
  y <- data$y
  x <- data$x
  # Same-group case: both effects index the same grouping factor `id`.
  ia <- as.integer(data$id)
  ig <- ia
  G <- nlevels(data$id)
  H <- G
  m <- G + H
  h <- function(b) {
    a <- b[seq_len(G)]
    cc <- b[G + seq_len(H)]
    eta <- beta_mu[1L] + beta_mu[2L] * x + sd_a[ia] * a[ia]
    ls <- beta_sigma + sd_c[ig] * cc[ig]
    k <- exp(-2 * ls)
    -sum(stats::dnbinom(y, size = k, mu = exp(eta), log = TRUE)) -
      sum(stats::dnorm(a, log = TRUE)) - sum(stats::dnorm(cc, log = TRUE))
  }
  gr <- function(b) {
    a <- b[seq_len(G)]
    cc <- b[G + seq_len(H)]
    eta <- beta_mu[1L] + beta_mu[2L] * x + sd_a[ia] * a[ia]
    ls <- beta_sigma + sd_c[ig] * cc[ig]
    k <- exp(-2 * ls)
    mu <- exp(eta)
    g_eta <- (y - mu) * k / (k + mu)
    d_k <- digamma(y + k) - digamma(k) + log(k / (k + mu)) + 1 -
      (y + k) / (k + mu)
    g_ls <- d_k * (-2 * k)
    c(
      -as.vector(rowsum(g_eta * sd_a[ia], ia)) + a,
      -as.vector(rowsum(g_ls * sd_c[ig], ig)) + cc
    )
  }
  fit <- stats::nlminb(rep(0, m), h, gr, control = list(rel.tol = 1e-14,
                                                       x.tol = 1e-12,
                                                       iter.max = 500))
  b <- fit$par
  hess <- function(b) {
    eps <- 1e-5
    out <- matrix(0, m, m)
    for (j in seq_len(m)) {
      up <- b
      dn <- b
      up[j] <- up[j] + eps
      dn[j] <- dn[j] - eps
      out[, j] <- (gr(up) - gr(dn)) / (2 * eps)
    }
    (out + t(out)) / 2
  }
  for (it in 1:3) {
    b <- b - solve(hess(b), gr(b))
  }
  H0 <- hess(b)
  logdet <- as.numeric(determinant(H0, logarithm = TRUE)$modulus)
  -h(b) - 0.5 * logdet + 0.5 * m * log(2 * pi)
}

sg_sd_names <- function(fit) {
  list(mu = coef(fit, dpar = "sd(id)"),
       sigma = coef(fit, dpar = 'sd(id, dpar = "sigma")'))
}

sg_oracle_at_fit <- function(fit, sim, swap = FALSE, w_level = sim$w_level,
                             z_level = sim$z_level) {
  s <- sg_sd_names(fit)
  sd_a <- exp(s$mu[[1L]] + s$mu[[2L]] * w_level)
  sd_c <- exp(s$sigma[[1L]] + s$sigma[[2L]] * z_level)
  if (swap) {
    sd_a <- exp(s$sigma[[1L]] + s$sigma[[2L]] * w_level)
    sd_c <- exp(s$mu[[1L]] + s$mu[[2L]] * z_level)
  }
  lv <- levels(sim$data$id)
  nb2sg_laplace(
    sim$data,
    beta_mu = unname(coef(fit, dpar = "mu")),
    beta_sigma = unname(coef(fit, dpar = "sigma")),
    sd_a = sd_a[lv], sd_c = sd_c[lv]
  )
}

sg_formula <- function() {
  bf(
    y ~ x + (1 | id),
    sigma ~ 1 + (1 | id),
    sd(id) ~ w,
    sd(id, dpar = "sigma") ~ z
  )
}

sg_ctrl <- list(eval.max = 800, iter.max = 800)

test_that("NB2 same-group joint mu and sigma SD regression matches the dense Laplace oracle", {
  sim <- sg_fixture()
  fit <- drmTMB(sg_formula(), family = nbinom2(), data = sim$data,
                control = sg_ctrl)
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_named(coef(fit, dpar = "sd(id)"), c("(Intercept)", "w"))
  expect_named(coef(fit, dpar = 'sd(id, dpar = "sigma")'),
               c("(Intercept)", "z"))

  oracle <- sg_oracle_at_fit(fit, sim)
  expect_lt(abs(as.numeric(logLik(fit)) - oracle), sg_tol_ll)

  lv <- levels(sim$data$id)
  par0 <- unname(c(
    coef(fit, dpar = "mu"), coef(fit, dpar = "sigma"),
    coef(fit, dpar = "sd(id)"), coef(fit, dpar = 'sd(id, dpar = "sigma")')
  ))
  f_par <- function(p) {
    nb2sg_laplace(
      sim$data, beta_mu = p[1:2], beta_sigma = p[3],
      sd_a = exp(p[4] + p[5] * sim$w_level)[lv],
      sd_c = exp(p[6] + p[7] * sim$z_level)[lv]
    )
  }
  step <- 1e-3
  grad <- vapply(seq_along(par0), function(j) {
    up <- par0
    dn <- par0
    up[j] <- up[j] + step
    dn[j] <- dn[j] - step
    (f_par(up) - f_par(dn)) / (2 * step)
  }, numeric(1L))
  expect_lt(max(abs(grad)), sg_tol_grad)

  # Both random-effect contributions are present and distinct.
  mu_link <- predict(fit, dpar = "mu", type = "link")
  fixed_mu <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  expect_equal(mu_link - fixed_mu,
               drmTMB:::mu_random_effect_contribution(fit, dpar = "mu"),
               tolerance = 1e-8)
  expect_gt(stats::sd(mu_link - fixed_mu), 0)
  sigma_link <- predict(fit, dpar = "sigma", type = "link")
  fixed_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  expect_equal(sigma_link - fixed_sigma,
               drmTMB:::sigma_random_effect_contribution(fit, dpar = "sigma"),
               tolerance = 1e-8)
  expect_gt(stats::sd(sigma_link - fixed_sigma), 0)
})

test_that("the same-group oracle is sensitive to emulated wiring bugs", {
  sim <- sg_fixture()
  fit <- drmTMB(sg_formula(), family = nbinom2(), data = sim$data,
                control = sg_ctrl)
  ll <- as.numeric(logLik(fit))
  expect_lt(abs(ll - sg_oracle_at_fit(fit, sim)), sg_tol_ll)

  # Bug 1: mu and sigma SD formulas swapped.
  expect_gt(abs(ll - sg_oracle_at_fit(fit, sim, swap = TRUE)), sg_bug_gap)

  # Bug 2: SD predictor rows assigned to the wrong groups.
  w_bad <- stats::setNames(unname(sim$w_level)[rev(seq_along(sim$w_level))],
                           names(sim$w_level))
  z_bad <- stats::setNames(unname(sim$z_level)[rev(seq_along(sim$z_level))],
                           names(sim$z_level))
  expect_gt(abs(ll - sg_oracle_at_fit(fit, sim, w_level = w_bad,
                                      z_level = z_bad)), sg_bug_gap)

  # Bug 3: sigma random effect dropped.
  s <- sg_sd_names(fit)
  lv <- levels(sim$data$id)
  no_sigma <- nb2sg_laplace(
    sim$data, beta_mu = unname(coef(fit, dpar = "mu")),
    beta_sigma = unname(coef(fit, dpar = "sigma")),
    sd_a = exp(s$mu[[1L]] + s$mu[[2L]] * sim$w_level)[lv],
    sd_c = rep(0, length(lv))
  )
  expect_gt(abs(ll - no_sigma), sg_bug_gap)

  # Bug 4: the sigma effect tied to the mu effect (one shared draw per group
  # instead of two independent draws). Emulated by a Laplace with a single
  # effect b entering both predictors.
  y <- sim$data$y; x <- sim$data$x; ia <- as.integer(sim$data$id)
  sd_a <- exp(s$mu[[1L]] + s$mu[[2L]] * sim$w_level)[lv]
  sd_c <- exp(s$sigma[[1L]] + s$sigma[[2L]] * sim$z_level)[lv]
  bm <- unname(coef(fit, dpar = "mu")); bs <- unname(coef(fit, dpar = "sigma"))
  h <- function(b) {
    eta <- bm[1] + bm[2] * x + sd_a[ia] * b[ia]
    k <- exp(-2 * (bs + sd_c[ia] * b[ia]))
    -sum(stats::dnbinom(y, size = k, mu = exp(eta), log = TRUE)) -
      sum(stats::dnorm(b, log = TRUE))
  }
  opt <- stats::optim(rep(0, length(lv)), h, method = "BFGS",
                      hessian = TRUE, control = list(reltol = 1e-12,
                                                     maxit = 500))
  tied <- -opt$value - 0.5 * as.numeric(determinant(opt$hessian)$modulus) +
    0.5 * length(lv) * log(2 * pi)
  expect_gt(abs(ll - tied), sg_bug_gap)
})

test_that("constant-SD same-group NB2 fit matches an independent oracle MLE", {
  sim <- sg_fixture(G = 16L, n = 320L, seed = 2026110112L)
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1 + (1 | id),
       sd(id) ~ 1, sd(id, dpar = "sigma") ~ 1),
    family = nbinom2(), data = sim$data, control = sg_ctrl
  )
  expect_equal(fit$opt$convergence, 0)
  G <- nlevels(sim$data$id)
  neg <- function(p) {
    -nb2sg_laplace(sim$data, beta_mu = p[1:2], beta_sigma = p[3],
                   sd_a = rep(exp(p[4]), G), sd_c = rep(exp(p[5]), G))
  }
  ref <- stats::nlminb(c(0, 0, -0.5, -1, -1), neg,
                       control = list(rel.tol = 1e-12, iter.max = 200))
  est <- c(coef(fit, dpar = "mu"), coef(fit, dpar = "sigma"),
           coef(fit, dpar = "sd(id)"),
           coef(fit, dpar = 'sd(id, dpar = "sigma")'))
  expect_lt(abs(as.numeric(logLik(fit)) + ref$objective), sg_tol_ll)
  expect_lt(max(abs(unname(est) - unname(ref$par))), sg_tol_coef)
})

test_that("same-group NB2 routes without both SD formulas stay refused", {
  d <- sg_fixture(G = 12L, n = 120L, seed = 2026110113L)$data
  expect_error(
    drm_build_nbinom2_spec(bf(y ~ x + (1 | id), sigma ~ 1 + (1 | id)), d),
    "cannot be combined with.*mu.*random effects"
  )
  expect_error(
    drm_build_nbinom2_spec(
      bf(y ~ x + (1 | id), sigma ~ 1 + (1 | id), sd(id) ~ w), d
    ),
    "cannot be combined with.*mu.*random effects"
  )
  expect_error(
    drm_build_nbinom2_spec(
      bf(y ~ x + (1 | id), sigma ~ 1 + (1 | id),
         sd(id, dpar = "sigma") ~ z), d
    ),
    "cannot be combined with.*mu.*random effects"
  )
  d_bad <- d
  d_bad$z <- seq_len(nrow(d_bad))
  expect_error(drm_build_nbinom2_spec(sg_formula(), d_bad), "constant within")
})
