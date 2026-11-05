# Batch 29 (lane b) companion to test-poisson-correlated-q2-sd.R and
# test-nbinom2-correlated-q2-sd.R (evidence ids
# native-poisson-correlated-q2-sd-20261027-m26,
# native-nbinom2-correlated-q2-sd-20261027-m26).
#
# Reviewer deficiencies closed: (Poisson) the Gauss-Hermite oracle was compared
# with a relative tolerance of 0.5, against an observed oracle-versus-fit gap of
# 4.6 and swap gaps of 71-78, so it could not separate the emulated bugs; (NB2)
# recovery bounds only, no likelihood oracle, no sensitivity.
# Here a base-R dense per-group Laplace marginal (observed information, the same
# approximation the package makes) is evaluated at the fitted parameters with
# the two coefficient-specific SD vectors built by hand from the coefficients
# (exp(intercept + slope * selector)), and compared at 1e-6 absolute on logLik.
# Emulated bugs (swapped coefficient sets, swapped intercept/slope SD vectors,
# reversed SD vectors, flipped rho, rho = 0) must each move the oracle by more
# than 0.1 (100000x the tolerance). Scope: likelihood assembly and selector
# alignment at one seed; no calibration, coverage or parity claim.

b29b_q2_fixture <- function(family, seed, groups = 90L, repeats = 14L) {
  set.seed(seed)
  id <- factor(rep(seq_len(groups), each = repeats))
  x <- rep(seq(-1, 1, length.out = repeats), times = groups)
  w_group <- seq(-1, 1, length.out = groups)          # continuous selector
  v_group <- sample(rep(c(-1, 1), length.out = groups))  # two-valued selector
  z0 <- stats::rnorm(groups)
  z1 <- stats::rnorm(groups)
  tau0 <- exp(-0.3 + 0.5 * w_group)
  tau1 <- exp(-0.55 - 0.5 * v_group)
  b0 <- tau0 * z0
  b1 <- tau1 * (0.7 * z0 + sqrt(1 - 0.7^2) * z1)
  gi <- as.integer(id)
  eta <- -0.2 + 0.5 * x + b0[gi] + b1[gi] * x
  y <- if (identical(family, "poisson")) {
    stats::rpois(length(id), exp(eta))
  } else {
    stats::rnbinom(length(id), size = 1 / exp(-0.55)^2, mu = exp(eta))
  }
  list(data = data.frame(count = y, x = x, w0 = rep(w_group, each = repeats),
                         w1 = rep(v_group, each = repeats), id = id),
       w_group = w_group, v_group = v_group)
}

b29b_q2_oracle <- function(data, beta, sd0, sd1, rho, family, size = NULL) {
  sum(vapply(seq_along(sd0), function(g) {
    rows <- which(as.integer(data$id) == g)
    x <- data$x[rows]
    deriv <- if (identical(family, "poisson")) {
      sb26_deriv_poisson(data$count[rows])
    } else {
      sb26_deriv_nb2(data$count[rows], size)
    }
    S <- diag(c(sd0[[g]], sd1[[g]])) %*% matrix(c(1, rho, rho, 1), 2L) %*%
      diag(c(sd0[[g]], sd1[[g]]))
    sb26_laplace(deriv, beta[[1L]] + beta[[2L]] * x, cbind(1, x), S)
  }, numeric(1L)))
}

b29b_q2_check <- function(family) {
  fx <- b29b_q2_fixture(family, if (family == "poisson") 29701L else 29702L)
  fml <- if (identical(family, "poisson")) {
    bf(count ~ x + (1 + x | id),
       sd(id, dpar = "mu", coef = "(Intercept)") ~ w0,
       sd(id, dpar = "mu", coef = "x") ~ w1)
  } else {
    bf(count ~ x + (1 + x | id), sigma ~ 1,
       sd(id, dpar = "mu", coef = "(Intercept)") ~ w0,
       sd(id, dpar = "mu", coef = "x") ~ w1)
  }
  fit <- drmTMB(fml, family = if (identical(family, "poisson")) stats::poisson() else nbinom2(),
                data = fx$data, control = drm_control(se = FALSE))
  expect_identical(fit$opt$convergence, 0L)
  c0 <- coef(fit, 'sd(id, dpar = "mu", coef = "(Intercept)")')
  c1 <- coef(fit, 'sd(id, dpar = "mu", coef = "x")')
  expect_named(c0, c("(Intercept)", "w0"))
  expect_named(c1, c("(Intercept)", "w1"))
  curve <- function(co, z) unname(exp(co[[1L]] + co[[2L]] * z))
  beta <- unname(coef(fit, "mu"))
  rho <- unname(fit$corpars$mu[[1L]])
  size <- if (identical(family, "nbinom2")) {
    1 / exp(unname(coef(fit, "sigma")[["(Intercept)"]]))^2
  }
  sd0 <- curve(c0, fx$w_group)
  sd1 <- curve(c1, fx$v_group)
  expect_gt(stats::sd(log(sd0)), 0.1)
  expect_gt(stats::sd(log(sd1)), 0.1)
  # The by-hand SD vectors agree with the package prediction (a consistency
  # check, not the oracle).
  expect_equal(unname(predict(fit, dpar = 'sd(id, dpar = "mu", coef = "(Intercept)")',
                              newdata = data.frame(w0 = fx$w_group))),
               sd0, tolerance = 1e-6)
  oracle <- function(sd0 = sd0_, sd1 = sd1_, rho = rho_) {
    b29b_q2_oracle(fx$data, beta, sd0, sd1, rho, family, size)
  }
  sd0_ <- sd0
  sd1_ <- sd1
  rho_ <- rho
  ref <- oracle()
  ll <- as.numeric(logLik(fit))
  expect_lt(abs(ll - ref), 1e-6)
  bugs <- c(
    swapped_coef_sets = oracle(sd0 = curve(c1, fx$w_group), sd1 = curve(c0, fx$v_group)),
    swapped_sd_vectors = oracle(sd0 = sd1, sd1 = sd0),
    reversed_sd0 = oracle(sd0 = rev(sd0)),
    reversed_sd1 = oracle(sd1 = rev(sd1)),
    flipped_rho = oracle(rho = -rho),
    rho_zero = oracle(rho = 0)
  )
  expect_gt(abs(rho), 0.15)
  for (nm in names(bugs)) {
    expect_gt(abs(bugs[[nm]] - ref), 0.1, label = paste(family, nm))
  }
  if (nzchar(Sys.getenv("B29B_SHOW_GAPS"))) {
    cat(sprintf("GAP %s | ll-ref %.2e | rho %.3f | gaps %s\n", family, ll - ref, rho,
                paste(sprintf("%s=%.2f", names(bugs), abs(bugs - ref)), collapse = " ")))
  }
}

test_that("Poisson correlated q2 SDs with distinct selectors: dense per-group Laplace oracle and bug sensitivity", {
  skip_on_cran()
  b29b_q2_check("poisson")
})

test_that("NB2 correlated q2 SDs with distinct selectors: dense per-group Laplace oracle and bug sensitivity", {
  skip_on_cran()
  b29b_q2_check("nbinom2")
})
