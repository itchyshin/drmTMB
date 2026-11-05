# Tight, drmTMB-independent Laplace oracle for the Poisson correlated q2 SD
# regression route. The older test checks the likelihood against a 20 x 20
# Gauss-Hermite integral at tolerance 0.5; the oracle here is the same
# approximation drmTMB uses (Laplace), so the agreement tolerance is fixed in
# advance at 1e-4 absolute. Scope: native TMB, Poisson, one unlabelled q2
# intercept-slope block, two group-constant SD predictors on different
# variables. This is a likelihood-evaluation check at fitted parameters, not a
# recovery, calibration or coverage claim.

poisson_q2_oracle_fixture <- function(seed, groups = 160L, repeats = 32L) {
  set.seed(seed)
  id <- factor(rep(seq_len(groups), each = repeats))
  x <- rep(seq(-1, 1, length.out = repeats), times = groups)
  w_group <- seq(-1, 1, length.out = groups)
  v_group <- sample(rep(c(-1, 1), length.out = groups))
  w <- rep(w_group, each = repeats)
  v <- rep(v_group, each = repeats)
  rho <- 0.4
  z0 <- stats::rnorm(groups)
  z1 <- stats::rnorm(groups)
  tau0 <- exp(-0.45 + 0.4 * w_group)
  tau1 <- exp(-0.85 - 0.35 * v_group)
  b0 <- tau0 * z0
  b1 <- tau1 * (rho * z0 + sqrt(1 - rho^2) * z1)
  eta <- -0.2 + 0.55 * x + b0[as.integer(id)] + b1[as.integer(id)] * x
  list(
    data = data.frame(count = stats::rpois(length(id), exp(eta)), x, w, v, id),
    w_group = w_group, v_group = v_group
  )
}

# Dense Laplace marginal log-likelihood: per group q = 2, damped Newton on the
# joint log-density, exact Hessian Z' diag(mu) Z + Sigma^-1.
poisson_q2_laplace_oracle <- function(data, beta, sd_intercept, sd_slope, rho) {
  ids <- as.integer(data$id)
  total <- 0
  for (g in seq_len(max(ids))) {
    rows <- which(ids == g)
    y <- data$count[rows]
    Z <- cbind(1, data$x[rows])
    offset <- beta[[1L]] + beta[[2L]] * data$x[rows]
    s0 <- sd_intercept[[g]]
    s1 <- sd_slope[[g]]
    Sigma <- matrix(c(s0^2, rho * s0 * s1, rho * s0 * s1, s1^2), 2L, 2L)
    P <- solve(Sigma)
    joint <- function(b) {
      eta <- offset + drop(Z %*% b)
      sum(y * eta - exp(eta) - lgamma(y + 1)) - 0.5 * drop(t(b) %*% P %*% b)
    }
    b <- c(0, 0)
    for (iter in 1:200) {
      mu <- exp(offset + drop(Z %*% b))
      grad <- drop(crossprod(Z, y - mu)) - drop(P %*% b)
      H <- crossprod(Z, mu * Z) + P
      step <- drop(solve(H, grad))
      f0 <- joint(b)
      scale <- 1
      while (joint(b + scale * step) < f0 && scale > 1e-12) scale <- scale / 2
      b <- b + scale * step
      if (max(abs(scale * step)) < 1e-12) break
    }
    mu <- exp(offset + drop(Z %*% b))
    H <- crossprod(Z, mu * Z) + P
    total <- total + joint(b) -
      0.5 * as.numeric(determinant(Sigma, logarithm = TRUE)$modulus) -
      0.5 * as.numeric(determinant(H, logarithm = TRUE)$modulus)
  }
  total
}

for (seed in c(20261027L, 20261101L)) {
  test_that(paste0("Poisson correlated q2 SD: Laplace oracle agrees, seed ", seed), {
    sim <- poisson_q2_oracle_fixture(seed)
    dat <- sim$data
    key_intercept <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
    key_slope <- 'sd(id, dpar = "mu", coef = "x")'
    fit <- drmTMB(
      bf(
        count ~ x + (1 + x | id),
        sd(id, dpar = "mu", coef = "(Intercept)") ~ w,
        sd(id, dpar = "mu", coef = "x") ~ v
      ),
      family = stats::poisson(), data = dat,
      control = drm_control(se = FALSE)
    )
    expect_equal(fit$opt$convergence, 0L)

    sd_intercept <- predict(fit, dpar = key_intercept,
                            newdata = data.frame(w = sim$w_group))
    sd_slope <- predict(fit, dpar = key_slope,
                        newdata = data.frame(v = sim$v_group))
    beta <- coef(fit, "mu")
    rho <- unname(fit$corpars$mu[[1L]])
    # The SD formulas must genuinely differ across groups and between terms.
    expect_gt(stats::sd(log(sd_intercept)), 0.1)
    expect_gt(stats::sd(log(sd_slope)), 0.1)

    reference <- poisson_q2_laplace_oracle(dat, beta, sd_intercept, sd_slope, rho)
    expect_equal(as.numeric(logLik(fit)), reference, tolerance = 1e-4,
                 scale = 1)

    # Emulated bugs: each must move the oracle by more than 1 log-lik unit.
    swapped <- poisson_q2_laplace_oracle(dat, beta, sd_slope, sd_intercept, rho)
    flipped <- poisson_q2_laplace_oracle(dat, beta, sd_intercept, sd_slope, -rho)
    shift <- function(v) v[c(length(v), seq_len(length(v) - 1L))]
    misaligned <- poisson_q2_laplace_oracle(
      dat, beta, shift(sd_intercept), shift(sd_slope), rho
    )
    expect_gt(abs(swapped - reference), 1)
    expect_gt(abs(flipped - reference), 1)
    expect_gt(abs(misaligned - reference), 1)
  })
}
