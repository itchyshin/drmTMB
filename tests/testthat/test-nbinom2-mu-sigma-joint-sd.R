# NB2 joint mu plus sigma ordinary random intercepts, each with its own SD
# formula:
#   bf(y ~ x + (1 | id), sigma ~ 1 + (1 | g),
#      sd(id) ~ w, sd(g, dpar = "sigma") ~ z)
#
# Fixed tolerances (set before the first run):
#   logLik versus the dense Laplace oracle at the fitted parameters: 1e-3
#   independent-MLE coefficients (constant-SD case):                  2e-2
#   independent-MLE logLik (constant-SD case):                        1e-3
#   oracle gradient at the fitted optimum:                            1e-2
#   emulated-bug gap must exceed 100 * 1e-3 = 0.1
#
# The oracle uses only base R: it finds the joint mode of all id and g random
# effects (a dense (G + H)-dimensional problem, since id and g are crossed)
# and evaluates the Laplace marginal with a dense finite-difference Hessian of
# an analytic gradient. It does not call drmTMB or TMB.

nb2_joint_tol_ll <- 1e-3
nb2_joint_tol_coef <- 2e-2
nb2_joint_tol_grad <- 1e-2
nb2_joint_bug_gap <- 100 * nb2_joint_tol_ll

nb2_joint_fixture <- function(G = 40L, H = 30L, n = 800L, seed = 2026110101L,
                              alpha_mu = c(-0.5, 0.3),
                              alpha_sigma = c(-0.7, 0.3)) {
  set.seed(seed)
  # Shuffled level order, so level order is not row-appearance order.
  lev_id <- sample(sprintf("i%02d", seq_len(G)))
  lev_g <- sample(sprintf("g%02d", seq_len(H)))
  id <- factor(sample(rep_len(lev_id, n)), levels = lev_id)
  g <- factor(sample(rep_len(lev_g, n)), levels = lev_g)
  w_level <- stats::setNames(stats::rnorm(G), lev_id)
  z_level <- stats::setNames(stats::rnorm(H), lev_g)
  sd_mu_level <- exp(alpha_mu[1L] + alpha_mu[2L] * w_level)
  sd_sigma_level <- exp(alpha_sigma[1L] + alpha_sigma[2L] * z_level)
  a <- stats::rnorm(G) * sd_mu_level
  cc <- stats::rnorm(H) * sd_sigma_level
  x <- stats::rnorm(n)
  eta <- 1 + 0.3 * x + a[as.integer(id)]
  sigma_i <- exp(-0.6 + cc[as.integer(g)])
  y <- stats::rnbinom(n, size = 1 / sigma_i^2, mu = exp(eta))
  list(
    data = data.frame(
      y = y, x = x, id = id, g = g,
      w = w_level[as.character(id)], z = z_level[as.character(g)]
    ),
    w_level = w_level, z_level = z_level,
    lev_id = lev_id, lev_g = lev_g
  )
}

# Dense Laplace log marginal. sd_a / sd_c are SD vectors in factor-level order.
nb2_joint_laplace <- function(data, beta_mu, beta_sigma, sd_a, sd_c) {
  y <- data$y
  x <- data$x
  ia <- as.integer(data$id)
  ig <- as.integer(data$g)
  G <- nlevels(data$id)
  H <- nlevels(data$g)
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

nb2_joint_oracle_at_fit <- function(fit, sim, data = sim$data,
                                    w_level = sim$w_level,
                                    z_level = sim$z_level,
                                    swap = FALSE) {
  am <- coef(fit, dpar = "sd(id)")
  as <- coef(fit, dpar = 'sd(g, dpar = "sigma")')
  sd_a <- exp(am[[1L]] + am[[2L]] * w_level)
  sd_c <- exp(as[[1L]] + as[[2L]] * z_level)
  if (swap) {
    sd_a <- exp(as[[1L]] + as[[2L]] * w_level)
    sd_c <- exp(am[[1L]] + am[[2L]] * z_level)
  }
  nb2_joint_laplace(
    data,
    beta_mu = unname(coef(fit, dpar = "mu")),
    beta_sigma = unname(coef(fit, dpar = "sigma")),
    sd_a = sd_a[levels(data$id)],
    sd_c = sd_c[levels(data$g)]
  )
}

nb2_joint_formula <- function() {
  bf(
    y ~ x + (1 | id),
    sigma ~ 1 + (1 | g),
    sd(id) ~ w,
    sd(g, dpar = "sigma") ~ z
  )
}

nb2_joint_ctrl <- list(eval.max = 800, iter.max = 800)

test_that("NB2 joint mu and sigma SD regression matches the dense Laplace oracle", {
  sim <- nb2_joint_fixture()
  fit <- drmTMB(nb2_joint_formula(), family = nbinom2(), data = sim$data,
                control = nb2_joint_ctrl)

  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_named(coef(fit, dpar = "sd(id)"), c("(Intercept)", "w"))
  expect_named(coef(fit, dpar = 'sd(g, dpar = "sigma")'),
               c("(Intercept)", "z"))
  expect_true(all(is.finite(vcov(fit, dpar = "sd(id)"))))
  expect_true(all(is.finite(vcov(fit, dpar = 'sd(g, dpar = "sigma")'))))

  oracle <- nb2_joint_oracle_at_fit(fit, sim)
  expect_lt(abs(as.numeric(logLik(fit)) - oracle), nb2_joint_tol_ll)

  # The oracle surface is stationary in the fixed parameters at the fitted
  # optimum (central differences of the oracle, not of TMB).
  par0 <- c(
    coef(fit, dpar = "mu"), coef(fit, dpar = "sigma"),
    coef(fit, dpar = "sd(id)"), coef(fit, dpar = 'sd(g, dpar = "sigma")')
  )
  f_par <- function(p) {
    nb2_joint_laplace(
      sim$data,
      beta_mu = p[1:2], beta_sigma = p[3],
      sd_a = exp(p[4] + p[5] * sim$w_level)[levels(sim$data$id)],
      sd_c = exp(p[6] + p[7] * sim$z_level)[levels(sim$data$g)]
    )
  }
  step <- 1e-3
  grad <- vapply(seq_along(par0), function(j) {
    up <- unname(par0)
    dn <- unname(par0)
    up[j] <- up[j] + step
    dn[j] <- dn[j] - step
    (f_par(up) - f_par(dn)) / (2 * step)
  }, numeric(1L))
  expect_lt(max(abs(grad)), nb2_joint_tol_grad)

  # SD predictions follow the group-level formulas, named by level.
  am <- coef(fit, dpar = "sd(id)")
  expect_equal(
    unname(predict(fit, dpar = "sd(id)")),
    unname(exp(am[[1L]] + am[[2L]] * sim$w_level)[
      names(predict(fit, dpar = "sd(id)"))
    ]),
    tolerance = 1e-8
  )

  # Both random-effect contributions enter their own linear predictor.
  mu_link <- predict(fit, dpar = "mu", type = "link")
  fixed_mu <- as.vector(fit$model$X$mu %*% coef(fit, "mu"))
  expect_equal(
    mu_link - fixed_mu,
    drmTMB:::mu_random_effect_contribution(fit, dpar = "mu"),
    tolerance = 1e-8
  )
  expect_gt(stats::sd(mu_link - fixed_mu), 0)
  sigma_link <- predict(fit, dpar = "sigma", type = "link")
  fixed_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  expect_equal(
    sigma_link - fixed_sigma,
    drmTMB:::sigma_random_effect_contribution(fit, dpar = "sigma"),
    tolerance = 1e-8
  )
  expect_gt(stats::sd(sigma_link - fixed_sigma), 0)
})

test_that("the joint oracle is sensitive to emulated wiring bugs", {
  sim <- nb2_joint_fixture()
  fit <- drmTMB(nb2_joint_formula(), family = nbinom2(), data = sim$data,
                control = nb2_joint_ctrl)
  good <- nb2_joint_oracle_at_fit(fit, sim)
  ll <- as.numeric(logLik(fit))
  expect_lt(abs(ll - good), nb2_joint_tol_ll)

  # Bug 1: the mu and sigma SD formulas swapped between the two blocks.
  swapped <- nb2_joint_oracle_at_fit(fit, sim, swap = TRUE)
  expect_gt(abs(ll - swapped), nb2_joint_bug_gap)

  # Bug 2: SD predictor rows assigned to the wrong groups (level order used
  # as if it were row order).
  w_bad <- stats::setNames(unname(sim$w_level)[rev(seq_along(sim$w_level))],
                           names(sim$w_level))
  z_bad <- stats::setNames(unname(sim$z_level)[rev(seq_along(sim$z_level))],
                           names(sim$z_level))
  scrambled <- nb2_joint_oracle_at_fit(fit, sim, w_level = w_bad,
                                       z_level = z_bad)
  expect_gt(abs(ll - scrambled), nb2_joint_bug_gap)

  # Bug 3: the sigma random effect dropped from the likelihood.
  am <- coef(fit, dpar = "sd(id)")
  no_sigma_re <- nb2_joint_laplace(
    sim$data,
    beta_mu = unname(coef(fit, dpar = "mu")),
    beta_sigma = unname(coef(fit, dpar = "sigma")),
    sd_a = exp(am[[1L]] + am[[2L]] * sim$w_level)[levels(sim$data$id)],
    sd_c = rep(0, nlevels(sim$data$g))
  )
  expect_gt(abs(ll - no_sigma_re), nb2_joint_bug_gap)
})

test_that("constant-SD joint NB2 fit matches an independent oracle MLE", {
  sim <- nb2_joint_fixture(G = 16L, H = 12L, n = 320L, seed = 2026110102L)
  fit <- drmTMB(
    bf(
      y ~ x + (1 | id),
      sigma ~ 1 + (1 | g),
      sd(id) ~ 1,
      sd(g, dpar = "sigma") ~ 1
    ),
    family = nbinom2(), data = sim$data, control = nb2_joint_ctrl
  )
  expect_equal(fit$opt$convergence, 0)

  # No formula-free joint fit exists (the joint mu + sigma route is refused
  # without SD formulas), so the reference is an independent maximisation of
  # the dense Laplace marginal from a cold start.
  neg <- function(p) {
    -nb2_joint_laplace(
      sim$data,
      beta_mu = p[1:2], beta_sigma = p[3],
      sd_a = rep(exp(p[4]), nlevels(sim$data$id)),
      sd_c = rep(exp(p[5]), nlevels(sim$data$g))
    )
  }
  ref <- stats::nlminb(c(0, 0, -0.5, -1, -1), neg,
                       control = list(rel.tol = 1e-12, iter.max = 200))
  est <- c(
    coef(fit, dpar = "mu"), coef(fit, dpar = "sigma"),
    coef(fit, dpar = "sd(id)"),
    coef(fit, dpar = 'sd(g, dpar = "sigma")')
  )
  expect_lt(abs(as.numeric(logLik(fit)) + ref$objective), nb2_joint_tol_ll)
  expect_lt(max(abs(unname(est) - unname(ref$par))), nb2_joint_tol_coef)
})

test_that("neighbouring NB2 mu plus sigma random-effect routes stay refused", {
  sim <- nb2_joint_fixture(G = 12L, H = 10L, n = 120L, seed = 2026110103L)
  d <- sim$data

  # Joint random effects without SD formulas.
  expect_error(
    drm_build_nbinom2_spec(
      bf(y ~ x + (1 | id), sigma ~ 1 + (1 | g)), d
    ),
    "cannot be combined with.*mu.*random effects"
  )
  # Only one of the two SD formulas.
  expect_error(
    drm_build_nbinom2_spec(
      bf(y ~ x + (1 | id), sigma ~ 1 + (1 | g), sd(id) ~ w), d
    ),
    "cannot be combined with.*mu.*random effects"
  )
  expect_error(
    drm_build_nbinom2_spec(
      bf(y ~ x + (1 | id), sigma ~ 1 + (1 | g),
         sd(g, dpar = "sigma") ~ z), d
    ),
    "cannot be combined with.*mu.*random effects"
  )
  # Mean random slope beside a sigma random intercept.
  expect_error(
    drm_build_nbinom2_spec(
      bf(y ~ x + (0 + x | id), sigma ~ 1 + (1 | g),
         sd(id) ~ w, sd(g, dpar = "sigma") ~ z), d
    ),
    "cannot be combined with.*mu.*random effects"
  )
  # Sigma random slope beside a mean random intercept.
  expect_error(
    drm_build_nbinom2_spec(
      bf(y ~ x + (1 | id), sigma ~ 1 + (0 + x | g),
         sd(id) ~ w, sd(g, dpar = "sigma") ~ z), d
    ),
    "cannot be combined with.*mu.*random effects"
  )
  # Zero-inflated joint route.
  expect_error(
    drm_build_nbinom2_spec(
      bf(y ~ x + (1 | id), sigma ~ 1 + (1 | g), zi ~ 1,
         sd(id) ~ w, sd(g, dpar = "sigma") ~ z), d
    ),
    "zero-inflated NB2"
  )
  # Missing-response integration.
  expect_error(
    drm_build_nbinom2_spec(
      nb2_joint_formula(), d, missing = miss_control(response = "include")
    ),
    "requires complete data"
  )
  # Two mean random intercepts beside a sigma random intercept.
  d$id2 <- d$g
  expect_error(
    drm_build_nbinom2_spec(
      bf(y ~ x + (1 | id) + (1 | id2), sigma ~ 1 + (1 | g),
         sd(id) ~ w, sd(g, dpar = "sigma") ~ z), d
    ),
    "cannot be combined with.*mu.*random effects"
  )
  # Group-constant SD predictor requirement still applies.
  d_bad <- d
  d_bad$z <- seq_len(nrow(d_bad))
  expect_error(
    drm_build_nbinom2_spec(nb2_joint_formula(), d_bad),
    "constant within"
  )
})
