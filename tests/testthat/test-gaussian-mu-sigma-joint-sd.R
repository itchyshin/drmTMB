# Native Gaussian joint mu and sigma ordinary random effects, each with its own
# SD formula, on different grouping factors:
#   y ~ x + (1 | id),  sigma ~ 1 + (0 + z | site) [or (1 | site)]
#   sd(id) ~ w,        sd(site, dpar = "sigma", coef = "z") ~ v
# A Gaussian with a sigma random effect has no closed-form marginal, so the
# oracle is a dense Laplace approximation evaluated at the fitted parameters
# (the same approximation TMB reports), plus the constant-SD limit against the
# existing mu-plus-sigma random-effect fit.

gaussian_mu_sigma_joint_fixture <- function(
  seed = 20261101L,
  n_id = 50L,
  n_site = 80L,
  n_each = 32L,
  alpha_mu = c("(Intercept)" = log(0.6), w = 0.4),
  alpha_sigma = c("(Intercept)" = log(0.35), v = 0.6),
  slope = TRUE
) {
  set.seed(seed)
  n <- n_id * n_each
  row <- seq_len(n)
  id <- factor(sprintf("id%02d", (row - 1L) %/% n_each + 1L))
  site <- factor(sprintf("s%02d", (row - 1L) %% n_site + 1L))
  w_id <- seq(-1, 1, length.out = n_id)
  v_site <- seq(-1, 1, length.out = n_site)
  sd_id <- exp(alpha_mu[["(Intercept)"]] + alpha_mu[["w"]] * w_id)
  sd_site <- exp(alpha_sigma[["(Intercept)"]] + alpha_sigma[["v"]] * v_site)
  a <- stats::rnorm(n_id, sd = sd_id)
  b <- stats::rnorm(n_site, sd = sd_site)
  x <- stats::rnorm(n)
  z <- if (slope) stats::rnorm(n) else rep(1, n)
  gi <- as.integer(id)
  gs <- as.integer(site)
  eta <- log(0.5) + b[gs] * z
  y <- 0.2 + 0.5 * x + a[gi] + stats::rnorm(n, sd = exp(eta))
  names(w_id) <- levels(id)
  names(v_site) <- levels(site)
  list(
    data = data.frame(
      y = y, x = x, z = z, id = id, site = site,
      w = w_id[gi], v = v_site[gs]
    ),
    w_id = w_id, v_site = v_site,
    alpha_mu = alpha_mu, alpha_sigma = alpha_sigma
  )
}

# Dense Laplace marginal log likelihood for
#   y_i = X beta + a[id_i] + exp(s0 + b[site_i] z_i) e_i,
#   a_g ~ N(0, sd_id_g^2), b_j ~ N(0, sd_site_j^2),
# with u = (a, b) integrated by a Laplace approximation about the exact mode.
gaussian_joint_laplace_oracle <- function(
  y, X, z, gi, gs, beta, s0, sd_id, sd_site
) {
  n_a <- length(sd_id)
  n_b <- length(sd_site)
  mu0 <- as.numeric(X %*% beta)
  parts <- function(u) {
    a <- u[seq_len(n_a)]
    b <- u[n_a + seq_len(n_b)]
    r <- y - mu0 - a[gi]
    eta <- s0 + b[gs] * z
    list(a = a, b = b, r = r, eta = eta, ie = exp(-2 * eta))
  }
  neg_joint <- function(u) {
    p <- parts(u)
    sum(p$eta + 0.5 * p$r^2 * p$ie + 0.5 * log(2 * pi)) +
      sum(0.5 * p$a^2 / sd_id^2 + log(sd_id) + 0.5 * log(2 * pi)) +
      sum(0.5 * p$b^2 / sd_site^2 + log(sd_site) + 0.5 * log(2 * pi))
  }
  gradient <- function(u) {
    p <- parts(u)
    g_eta <- 1 - p$r^2 * p$ie
    c(
      as.numeric(rowsum(-p$r * p$ie, gi)) + p$a / sd_id^2,
      as.numeric(rowsum(g_eta * z, gs)) + p$b / sd_site^2
    )
  }
  hessian <- function(u) {
    p <- parts(u)
    H <- matrix(0, n_a + n_b, n_a + n_b)
    haa <- as.numeric(rowsum(p$ie, gi)) + 1 / sd_id^2
    hbb <- as.numeric(rowsum(2 * p$r^2 * p$ie * z^2, gs)) + 1 / sd_site^2
    diag(H)[seq_len(n_a)] <- haa
    diag(H)[n_a + seq_len(n_b)] <- hbb
    hab <- 2 * p$r * p$ie * z
    for (i in seq_along(y)) {
      H[gi[i], n_a + gs[i]] <- H[gi[i], n_a + gs[i]] + hab[i]
      H[n_a + gs[i], gi[i]] <- H[n_a + gs[i], gi[i]] + hab[i]
    }
    H
  }
  start <- rep(0, n_a + n_b)
  coarse <- stats::nlminb(start, neg_joint, gradient)
  u <- coarse$par
  for (k in seq_len(50L)) {
    g <- gradient(u)
    if (max(abs(g)) < 1e-10) break
    step <- solve(hessian(u), g)
    u <- u - step
  }
  H <- hessian(u)
  list(
    loglik = -neg_joint(u) + 0.5 * (n_a + n_b) * log(2 * pi) -
      0.5 * as.numeric(determinant(H, logarithm = TRUE)$modulus),
    max_grad = max(abs(gradient(u))),
    min_eig = min(eigen(H, symmetric = TRUE, only.values = TRUE)$values)
  )
}

gaussian_joint_oracle_from_fit <- function(fit, fx, key_mu, key_sigma) {
  data <- fx$data
  alpha_mu <- stats::coef(fit, key_mu)
  alpha_sigma <- stats::coef(fit, key_sigma)
  sd_id <- exp(alpha_mu[["(Intercept)"]] + alpha_mu[["w"]] * fx$w_id)
  sd_site <- exp(alpha_sigma[["(Intercept)"]] + alpha_sigma[["v"]] * fx$v_site)
  gaussian_joint_laplace_oracle(
    y = data$y,
    X = cbind(1, data$x),
    z = data$z,
    gi = as.integer(data$id),
    gs = as.integer(data$site),
    beta = unname(stats::coef(fit, "mu")),
    s0 = unname(stats::coef(fit, "sigma"))[[1L]],
    sd_id = unname(sd_id),
    sd_site = unname(sd_site)
  )
}

gaussian_joint_key_mu <- "sd(id)"
gaussian_joint_key_slope <- 'sd(site, dpar = "sigma", coef = "z")'
gaussian_joint_key_int <- 'sd(site, dpar = "sigma")'

test_that("Gaussian mu intercept and sigma slope each take an SD formula", {
  skip_on_cran()
  fx <- gaussian_mu_sigma_joint_fixture()
  fit <- drmTMB(
    bf(
      y ~ x + (1 | id),
      sigma ~ 1 + (0 + z | site),
      sd(id) ~ w,
      sd(site, dpar = "sigma", coef = "z") ~ v
    ),
    family = stats::gaussian(), data = fx$data,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_named(stats::coef(fit, gaussian_joint_key_mu), names(fx$alpha_mu))
  expect_named(stats::coef(fit, gaussian_joint_key_slope), names(fx$alpha_sigma))

  # Recovery: tolerances fixed before the first run.
  expect_lt(max(abs(
    stats::coef(fit, gaussian_joint_key_mu) - fx$alpha_mu
  )), 0.5)
  expect_gt(stats::coef(fit, gaussian_joint_key_slope)[["v"]], 0)
  expect_lt(max(abs(
    stats::coef(fit, gaussian_joint_key_slope) - fx$alpha_sigma
  )), 0.6)

  # Name-aligned predictions on the group scale.
  sd_id_hat <- stats::predict(fit, dpar = gaussian_joint_key_mu, type = "response")
  sd_site_hat <- stats::predict(fit, dpar = gaussian_joint_key_slope, type = "response")
  alpha_mu <- stats::coef(fit, gaussian_joint_key_mu)
  alpha_sigma <- stats::coef(fit, gaussian_joint_key_slope)
  expect_named(sd_id_hat, levels(fx$data$id))
  expect_named(sd_site_hat, levels(fx$data$site))
  expect_equal(
    unname(sd_id_hat),
    unname(exp(alpha_mu[["(Intercept)"]] + alpha_mu[["w"]] * fx$w_id)),
    tolerance = 1e-8
  )
  expect_equal(
    unname(sd_site_hat),
    unname(exp(alpha_sigma[["(Intercept)"]] + alpha_sigma[["v"]] * fx$v_site)),
    tolerance = 1e-8
  )
  expect_length(stats::predict(fit, dpar = "mu", type = "response"), nrow(fx$data))
  sigma_hat <- stats::predict(fit, dpar = "sigma", type = "response")
  expect_length(sigma_hat, nrow(fx$data))
  expect_true(all(is.finite(sigma_hat) & sigma_hat > 0))

  # Dense Laplace oracle at the fitted parameters; abs. tolerance 1e-4.
  oracle <- gaussian_joint_oracle_from_fit(
    fit, fx, gaussian_joint_key_mu, gaussian_joint_key_slope
  )
  expect_lt(oracle$max_grad, 1e-8)
  expect_gt(oracle$min_eig, 0)
  expect_lt(abs(as.numeric(stats::logLik(fit)) - oracle$loglik), 1e-4)
})

test_that("Gaussian mu intercept and sigma intercept each take an SD formula", {
  skip_on_cran()
  fx <- gaussian_mu_sigma_joint_fixture(
    seed = 20261102L, n_id = 40L, n_site = 60L, n_each = 30L, slope = FALSE
  )
  fit <- drmTMB(
    bf(
      y ~ x + (1 | id),
      sigma ~ 1 + (1 | site),
      sd(id) ~ w,
      sd(site, dpar = "sigma") ~ v
    ),
    family = stats::gaussian(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  expect_named(stats::coef(fit, gaussian_joint_key_mu), names(fx$alpha_mu))
  expect_named(stats::coef(fit, gaussian_joint_key_int), names(fx$alpha_sigma))
  expect_named(
    stats::predict(fit, dpar = gaussian_joint_key_int, type = "response"),
    levels(fx$data$site)
  )
  oracle <- gaussian_joint_oracle_from_fit(
    fit, fx, gaussian_joint_key_mu, gaussian_joint_key_int
  )
  expect_lt(oracle$max_grad, 1e-8)
  expect_lt(abs(as.numeric(stats::logLik(fit)) - oracle$loglik), 1e-4)
})

test_that("constant joint mu and sigma SD formulas match the existing two-term fit", {
  skip_on_cran()
  fx <- gaussian_mu_sigma_joint_fixture(
    seed = 20261103L, n_id = 30L, n_site = 40L, n_each = 20L
  )
  base_fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1 + (0 + z | site)),
    family = stats::gaussian(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  const_fit <- drmTMB(
    bf(
      y ~ x + (1 | id),
      sigma ~ 1 + (0 + z | site),
      sd(id) ~ 1,
      sd(site, dpar = "sigma", coef = "z") ~ 1
    ),
    family = stats::gaussian(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  # Absolute logLik tolerance 1e-5; coefficient tolerance 1e-3.
  expect_lt(abs(
    as.numeric(stats::logLik(const_fit)) - as.numeric(stats::logLik(base_fit))
  ), 1e-5)
  expect_equal(
    unname(stats::coef(const_fit, "mu")), unname(stats::coef(base_fit, "mu")),
    tolerance = 1e-3
  )
  expect_equal(
    unname(stats::coef(const_fit, "sigma")), unname(stats::coef(base_fit, "sigma")),
    tolerance = 1e-3
  )
  sd_id <- stats::predict(const_fit, dpar = gaussian_joint_key_mu, type = "response")
  sd_site <- stats::predict(const_fit, dpar = gaussian_joint_key_slope, type = "response")
  expect_equal(
    unname(sd_id),
    rep(exp(stats::coef(const_fit, gaussian_joint_key_mu)[["(Intercept)"]]), nlevels(fx$data$id)),
    tolerance = 1e-8
  )
  expect_equal(
    unname(sd_site),
    rep(exp(stats::coef(const_fit, gaussian_joint_key_slope)[["(Intercept)"]]), nlevels(fx$data$site)),
    tolerance = 1e-8
  )
})

test_that("joint mu and sigma SD predictors must still be constant within group", {
  fx <- gaussian_mu_sigma_joint_fixture(n_id = 10L, n_site = 20L, n_each = 8L)
  bad <- fx$data
  bad$w[[2L]] <- bad$w[[2L]] + 0.1
  expect_error(
    drmTMB(
      bf(
        y ~ x + (1 | id), sigma ~ 1 + (0 + z | site),
        sd(id) ~ w, sd(site, dpar = "sigma", coef = "z") ~ v
      ),
      family = stats::gaussian(), data = bad, control = drm_control(se = FALSE)
    ),
    "varies within id level"
  )
  bad <- fx$data
  bad$v[[3L]] <- bad$v[[3L]] + 0.1
  expect_error(
    drmTMB(
      bf(
        y ~ x + (1 | id), sigma ~ 1 + (0 + z | site),
        sd(id) ~ w, sd(site, dpar = "sigma", coef = "z") ~ v
      ),
      family = stats::gaussian(), data = bad, control = drm_control(se = FALSE)
    ),
    "varies within site level"
  )
})
