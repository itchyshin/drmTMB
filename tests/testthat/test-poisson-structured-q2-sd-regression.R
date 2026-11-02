# Poisson animal intercept-plus-slope (q = 2) with one predictor-dependent SD
# formula per coefficient. Scope: native TMB, log link, unlabelled
# `animal(1 + x | id, A = A)`, group-constant SD predictors. The oracle is a
# dense Laplace marginal likelihood computed in plain R at the fitted
# parameters; it shares no code with the C++ objective. Tolerances are fixed in
# advance: 1e-4 absolute for oracle agreement, 1 log-likelihood unit for the
# emulated-bug sensitivity check. This is a likelihood-evaluation check, not a
# recovery, calibration or parity claim.

poisson_animal_q2_fixture <- function(seed, groups = 36L, repeats = 14L) {
  set.seed(seed)
  ids <- sprintf("an%02d", seq_len(groups))
  C <- outer(seq_len(groups), seq_len(groups), function(i, j) 0.35^abs(i - j))
  d <- sample(seq(0.8, 1.6, length.out = groups))
  A_natural <- diag(d) %*% C %*% diag(d)  # non-unit diagonal
  dimnames(A_natural) <- list(ids, ids)
  shuffled <- sample(ids)
  A <- A_natural[shuffled, shuffled]      # rows/columns not in data level order
  w_group <- stats::setNames(sample(rep(c(-1, 1), length.out = groups)), ids)
  v_group <- stats::setNames(sample(rep(c(-1, 1), each = groups / 2L)), ids)
  s0 <- exp(-0.9 + 0.5 * w_group)
  s1 <- exp(-1.1 - 0.5 * v_group)
  L <- t(chol(A_natural))
  b0 <- s0 * drop(L %*% stats::rnorm(groups))
  b1 <- s1 * drop(L %*% stats::rnorm(groups))
  id <- factor(rep(ids, each = repeats), levels = ids)
  x <- rep(seq(-1.2, 1.2, length.out = repeats), times = groups)
  eta <- 0.3 + 0.25 * x + b0[as.character(id)] + b1[as.character(id)] * x
  data <- data.frame(
    y = stats::rpois(length(eta), exp(eta)), x = x, id = id,
    w = unname(w_group[as.character(id)]),
    v = unname(v_group[as.character(id)])
  )
  list(data = data, A = A, A_natural = A_natural, w_group = w_group,
       v_group = v_group)
}

poisson_animal_q2_sd_formulas <- function(A) {
  f <- y ~ x + animal(1 + x | id, A = A)
  environment(f) <- environment()
  bf(
    f,
    sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ w,
    sd(id, level = "animal", dpar = "mu", coef = "x") ~ v
  )
}

poisson_animal_q2_fit_cache <- new.env(parent = emptyenv())
poisson_animal_q2_fit <- function(seed) {
  key <- as.character(seed)
  if (is.null(poisson_animal_q2_fit_cache[[key]])) {
    sim <- poisson_animal_q2_fixture(seed)
    A <- sim$A
    poisson_animal_q2_fit_cache[[key]] <- list(
      sim = sim,
      fit = drmTMB(
        poisson_animal_q2_sd_formulas(A),
        family = stats::poisson(), data = sim$data,
        control = drm_control(se = FALSE)
      )
    )
  }
  poisson_animal_q2_fit_cache[[key]]
}

# Dense Laplace marginal log-likelihood. The latent vector u = (u0, u1) is the
# unit-scale field with prior blockdiag(A, A); the coefficient SDs enter as the
# diagonal scaling eta = offset + Z diag(s) u. Laplace is invariant to this
# linear reparameterisation, so the value equals the Laplace marginal for
# b = diag(s) u with covariance blockdiag(D0 A D0, D1 A D1), but is far better
# conditioned when an SD is small.
poisson_animal_q2_oracle <- function(data, A, beta, s0, s1) {
  G <- nlevels(data$id)
  gi <- as.integer(data$id)
  y <- data$y
  Zg <- outer(gi, seq_len(G), function(i, g) as.numeric(i == g))
  Z <- cbind(Zg %*% diag(s0), (Zg * data$x) %*% diag(s1))
  offset <- beta[[1L]] + beta[[2L]] * data$x
  Pa <- solve(A)
  P <- matrix(0, 2L * G, 2L * G)
  P[seq_len(G), seq_len(G)] <- Pa
  P[G + seq_len(G), G + seq_len(G)] <- Pa
  logdet_prior <- 2 * as.numeric(determinant(A, logarithm = TRUE)$modulus)
  joint <- function(u) {
    eta <- offset + drop(Z %*% u)
    sum(y * eta - exp(eta) - lgamma(y + 1)) - 0.5 * drop(t(u) %*% P %*% u)
  }
  u <- rep(0, 2L * G)
  for (iter in 1:200) {
    mu <- exp(offset + drop(Z %*% u))
    grad <- drop(crossprod(Z, y - mu)) - drop(P %*% u)
    H <- crossprod(Z, mu * Z) + P
    step <- drop(solve(H, grad))
    f0 <- joint(u)
    scale <- 1
    while (joint(u + scale * step) < f0 && scale > 1e-12) scale <- scale / 2
    u <- u + scale * step
    if (max(abs(scale * step)) < 1e-11) break
  }
  mu <- exp(offset + drop(Z %*% u))
  H <- crossprod(Z, mu * Z) + P
  joint(u) - 0.5 * logdet_prior -
    0.5 * as.numeric(determinant(H, logarithm = TRUE)$modulus)
}

poisson_animal_q2_sds <- function(fit, sim) {
  key0 <- 'sd_animal(id, dpar = "mu", coef = "(Intercept)")'
  key1 <- 'sd_animal(id, dpar = "mu", coef = "x")'
  b0 <- coef(fit, key0)
  b1 <- coef(fit, key1)
  list(
    s0 = unname(exp(b0[["(Intercept)"]] + b0[["w"]] * sim$w_group)),
    s1 = unname(exp(b1[["(Intercept)"]] + b1[["v"]] * sim$v_group)),
    b0 = b0, b1 = b1
  )
}

test_that("Poisson animal q2 SD regression matches a dense Laplace oracle", {
  skip_on_cran()
  for (seed in c(20261101L, 20261102L, 20261103L)) {
    fx <- poisson_animal_q2_fit(seed)
    fit <- fx$fit
    sim <- fx$sim
    expect_equal(fit$opt$convergence, 0L)
    sds <- poisson_animal_q2_sds(fit, sim)
    # Distinct SD surfaces for the two coefficients.
    expect_gt(stats::sd(log(sds$s0)), 0.1)
    expect_gt(stats::sd(log(sds$s1)), 0.1)
    expect_named(sds$b0, c("(Intercept)", "w"))
    expect_named(sds$b1, c("(Intercept)", "v"))

    ids <- levels(sim$data$id)
    A_aligned <- sim$A[ids, ids]
    beta <- coef(fit, "mu")
    reference <- poisson_animal_q2_oracle(
      sim$data, A_aligned, beta, sds$s0, sds$s1
    )
    expect_lt(abs(as.numeric(logLik(fit)) - reference), 1e-4)

    # Emulated bugs must move the oracle by far more than the tolerance.
    swapped <- poisson_animal_q2_oracle(
      sim$data, A_aligned, beta, sds$s1, sds$s0
    )
    shift <- function(v) v[c(length(v), seq_len(length(v) - 1L))]
    shifted <- poisson_animal_q2_oracle(
      sim$data, A_aligned, beta, shift(sds$s0), shift(sds$s1)
    )
    unaligned <- poisson_animal_q2_oracle(
      sim$data, unname(sim$A), beta, sds$s0, sds$s1
    )
    one_sd_for_both <- poisson_animal_q2_oracle(
      sim$data, A_aligned, beta, sds$s0, sds$s0
    )
    expect_gt(abs(swapped - reference), 1)
    expect_gt(abs(shifted - reference), 1)
    expect_gt(abs(unaligned - reference), 1)
    expect_gt(abs(one_sd_for_both - reference), 1)
  }
})

test_that("Poisson animal q2 SD regression reports SDs per coefficient and group", {
  skip_on_cran()
  fx <- poisson_animal_q2_fit(20261101L)
  fit <- fx$fit
  sim <- fx$sim
  sds <- poisson_animal_q2_sds(fit, sim)
  key0 <- 'sd_animal(id, dpar = "mu", coef = "(Intercept)")'
  key1 <- 'sd_animal(id, dpar = "mu", coef = "x")'
  p0 <- predict(fit, dpar = key0)
  p1 <- predict(fit, dpar = key1)
  expect_setequal(names(p0), levels(sim$data$id))
  expect_equal(unname(p0[names(sim$w_group)]), sds$s0, tolerance = 1e-6)
  expect_equal(unname(p1[names(sim$v_group)]), sds$s1, tolerance = 1e-6)
  simulated <- simulate(fit, nsim = 1L, seed = 20261104L, re.form = NULL)
  expect_length(simulated[[1L]], nrow(sim$data))
  expect_true(all(is.finite(simulated[[1L]])))
})

test_that("Poisson animal q2 constant SD formulas match the formula-free fit", {
  skip_on_cran()
  sim <- poisson_animal_q2_fixture(20261101L)
  A <- sim$A
  f <- y ~ x + animal(1 + x | id, A = A)
  constant_fit <- drmTMB(
    bf(
      f,
      sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ 1,
      sd(id, level = "animal", dpar = "mu", coef = "x") ~ 1
    ),
    family = stats::poisson(), data = sim$data,
    control = drm_control(se = FALSE)
  )
  base_fit <- drmTMB(
    bf(f), family = stats::poisson(), data = sim$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(constant_fit$opt$convergence, 0L)
  expect_equal(base_fit$opt$convergence, 0L)
  expect_equal(as.numeric(logLik(constant_fit)), as.numeric(logLik(base_fit)),
               tolerance = 1e-5)
})

test_that("neighbouring Poisson structured q2 SD routes stay refused", {
  skip_on_cran()
  sim <- poisson_animal_q2_fixture(20261101L)
  A <- sim$A
  d <- sim$data
  K <- sim$A_natural
  pois <- stats::poisson()
  sd_int <- sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ w
  sd_x <- sd(id, level = "animal", dpar = "mu", coef = "x") ~ v

  # Only one of the two coefficients gets an SD formula.
  expect_error(
    drmTMB(bf(y ~ x + animal(1 + x | id, A = A), sd_int),
           family = pois, data = d),
    "requires\\s+one\\s+SD\\s+formula\\s+for\\s+each\\s+coefficient"
  )
  expect_error(
    drmTMB(bf(y ~ x + animal(1 + x | id, A = A), sd_x),
           family = pois, data = d),
    "requires\\s+one\\s+SD\\s+formula\\s+for\\s+each\\s+coefficient"
  )

  # Labelled covariance block with SD formulas.
  expect_error(
    drmTMB(bf(y ~ x + animal(1 + x | p | id, A = A), sd_int, sd_x),
           family = pois, data = d),
    "require\\s+one\\s+structured\\s+coefficient"
  )

  # Ordinary sd() beside a structured q2 block.
  d$site <- factor(rep(seq_len(12L), length.out = nrow(d)))
  expect_error(
    drmTMB(
      bf(y ~ x + (1 | site) + animal(1 + x | id, A = A),
         sd(site) ~ 1, sd_int, sd_x),
      family = pois, data = d
    ),
    "non-inflated\\s+model\\s+with\\s+complete\\s+responses"
  )

  # Labelled relmat q2 with coefficient SDs is admitted (see
  # test-count-labelled-relmat-q2-sd.R); with zero inflation it stays closed.
  expect_error(
    drmTMB(
      bf(y ~ x + relmat(1 + x | p | id, K = K), zi ~ 1,
         sd(id, level = "relmat", dpar = "mu", coef = "(Intercept)") ~ w,
         sd(id, level = "relmat", dpar = "mu", coef = "x") ~ v),
      family = pois, data = d
    ),
    "non-inflated\\s+model\\s+with\\s+complete\\s+responses"
  )

  # Zero-inflated and missing-response variants keep the complete-data gate.
  expect_error(
    drmTMB(bf(y ~ x + animal(1 + x | id, A = A), zi ~ 1, sd_int, sd_x),
           family = pois, data = d),
    "non-inflated\\s+model\\s+with\\s+complete\\s+responses"
  )
  d_miss <- d
  d_miss$y[c(3L, 40L)] <- NA
  # The animal q2 block with coefficient SDs now admits include (see
  # test-q2-sd-missing-include.R); the relmat q2 block stays closed.
  expect_error(
    drmTMB(bf(y ~ x + relmat(1 + x | id, K = K),
              sd(id, level = "relmat", dpar = "mu", coef = "(Intercept)") ~ w,
              sd(id, level = "relmat", dpar = "mu", coef = "x") ~ v),
           family = pois, data = d_miss,
           missing = miss_control(response = "include")),
    "non-inflated\\s+model\\s+with\\s+complete\\s+responses"
  )
})
