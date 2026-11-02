# NB2 animal intercept-plus-slope (q2) with coefficient-specific, predictor-
# dependent SDs. Native TMB route. Two forms are admitted:
#   unlabelled  animal(1 + x | id, A = A)      independent unit-scale fields
#   labelled    animal(1 + x | p | id, A = A)  one cross-coefficient correlation
# Each coefficient has its own sd(id, level = "animal", coef = ...) formula.
#
# Oracles share no code with the C++ objective: dense A (not Q_phylo, not
# log_det_Q), stats::dnbinom, and an analytic dense Hessian for the Laplace
# objective. A has a non-unit diagonal and the factor levels of `id` are
# shuffled relative to the rows and columns of A, so alignment is by name.

nb2_animal_q2_data <- function(seed = 20261101L, rho = 0.5) {
  set.seed(seed)
  n_group <- 48L
  n_each <- 20L
  id_levels <- sprintf("animal_%02d", seq_len(n_group))
  # Non-unit diagonal kernel: D C D with D varying across animals.
  d_scale <- exp(0.3 * rep(c(-1, 1), length.out = n_group))
  C <- 0.45^abs(outer(seq_len(n_group), seq_len(n_group), "-"))
  A <- outer(d_scale, d_scale) * C
  dimnames(A) <- list(id_levels, id_levels)
  L <- t(chol(A))
  z0 <- drop(L %*% stats::rnorm(n_group))
  z1 <- drop(L %*% stats::rnorm(n_group))
  f0 <- z0
  f1 <- rho * z0 + sqrt(1 - rho^2) * z1
  s0_group <- rep(c(-1, 1), each = n_group / 2L)
  s1_group <- rep(c(-1, 1), times = n_group / 2L)
  alpha0 <- c(log(0.40), 0.35)
  alpha1 <- c(log(0.32), -0.40)
  b0 <- exp(alpha0[[1L]] + alpha0[[2L]] * s0_group) * f0
  b1 <- exp(alpha1[[1L]] + alpha1[[2L]] * s1_group) * f1
  gi <- rep(seq_len(n_group), each = n_each)
  x <- rep(seq(-1.2, 1.2, length.out = n_each), times = n_group)
  mu <- exp(1.0 + 0.2 * x + b0[gi] + x * b1[gi])
  sigma <- 0.4
  dat <- data.frame(
    y = stats::rnbinom(length(mu), size = sigma^-2, mu = mu),
    x = x,
    id = factor(id_levels[gi], levels = sample(id_levels)),
    s0 = s0_group[gi],
    s1 = s1_group[gi]
  )
  list(data = dat, A = A, rho = rho)
}

nb2_animal_q2_formula <- function(A, label = "p", sd0 = ~ s0, sd1 = ~ s1) {
  term <- if (is.null(label)) {
    "animal(1 + x | id, A = A)"
  } else {
    sprintf("animal(1 + x | %s | id, A = A)", label)
  }
  mu_form <- stats::as.formula(paste("y ~ x +", term))
  environment(mu_form) <- environment()
  lhs0 <- quote(sd(id, level = "animal", dpar = "mu", coef = "(Intercept)"))
  lhs1 <- quote(sd(id, level = "animal", dpar = "mu", coef = "x"))
  f0 <- stats::as.formula(call("~", lhs0, sd0[[2L]]))
  f1 <- stats::as.formula(call("~", lhs1, sd1[[2L]]))
  bf(mu_form, sigma ~ 1, f0, f1)
}

nb2_animal_q2_cache <- new.env(parent = emptyenv())
nb2_animal_q2_fit <- function(seed, label) {
  key <- paste(seed, if (is.null(label)) "none" else label)
  if (is.null(nb2_animal_q2_cache[[key]])) {
    sim <- nb2_animal_q2_data(seed)
    nb2_animal_q2_cache[[key]] <- list(
      sim = sim,
      fit = drmTMB(
        nb2_animal_q2_formula(sim$A, label = label),
        family = nbinom2(), data = sim$data, engine = "tmb"
      )
    )
  }
  nb2_animal_q2_cache[[key]]
}

# Joint negative log density (data + latent prior) and Laplace objective,
# recomputed in plain R from the fitted parameters and latent fields.
# `perturb` emulates one specific bug so the test can show that the oracle
# disagrees with the correct fit when the implementation is wrong.
nb2_animal_q2_oracle <- function(fit, sim, rho, perturb = "none") {
  env <- fit$obj$env
  par <- env$last.par.best
  pl <- env$parList(x = par[-env$random], par = par)
  d <- sim$data
  labels <- fit$model$structured$phylo_mu$node_labels
  stopifnot(setequal(labels, rownames(sim$A)), length(labels) == nrow(sim$A))
  n <- length(labels)
  gi <- match(as.character(d$id), labels)
  A <- sim$A[labels, labels]
  u1 <- pl$u_phylo[seq_len(n)]
  u2 <- pl$u_phylo[n + seq_len(n)]
  b <- unname(pl$beta_sd_mu)
  sd0 <- exp(b[1L] + b[2L] * d$s0)
  sd1 <- exp(b[3L] + b[4L] * d$s1)
  if (perturb == "swap_sd_formulas") {
    sd0 <- exp(b[3L] + b[4L] * d$s0)
    sd1 <- exp(b[1L] + b[2L] * d$s1)
  }
  f0 <- if (perturb == "swap_fields") u2 else u1
  f1 <- if (perturb == "swap_fields") u1 else u2
  gi_eta <- if (perturb == "misaligned_levels") (gi %% n) + 1L else gi
  c0 <- sd0
  c1 <- d$x * sd1
  eta <- pl$beta_mu[[1L]] + pl$beta_mu[[2L]] * d$x +
    c0 * f0[gi_eta] + c1 * f1[gi_eta]
  size <- exp(pl$beta_sigma)^-2
  mu <- exp(eta)
  data_nll <- -sum(stats::dnbinom(d$y, size = size, mu = mu, log = TRUE))

  Ainv <- solve(A)
  logdet_A <- as.numeric(determinant(A, logarithm = TRUE)$modulus)
  q11 <- sum(u1 * (Ainv %*% u1))
  q12 <- sum(u1 * (Ainv %*% u2))
  q22 <- sum(u2 * (Ainv %*% u2))
  if (perturb == "drop_rho") rho <- 0
  one <- 1 - rho^2
  cross <- (if (perturb == "cross_sign") -1 else 1) * 2 * rho * q12
  logdet <- n * log(one) + (if (perturb == "logdet_once") 1 else 2) * logdet_A
  prior <- 0.5 * (2 * n * log(2 * pi) + logdet + (q11 + q22 - cross) / one)
  joint <- data_nll + prior

  # Laplace: joint + 0.5 log det H - (2n / 2) log(2 pi); H is the analytic
  # Hessian in the latent fields. For NB2 with a log link,
  # -d2 loglik / d eta2 = (y + size) mu size / (mu + size)^2.
  w <- (d$y + size) * mu * size / (mu + size)^2
  Cmat <- matrix(0, nrow(d), 2L * n)
  Cmat[cbind(seq_len(nrow(d)), gi_eta)] <- c0
  Cmat[cbind(seq_len(nrow(d)), n + gi_eta)] <- c1
  Hdata <- crossprod(Cmat, w * Cmat)
  R_inv <- matrix(c(1, -rho, -rho, 1), 2L, 2L) / one
  P <- kronecker(R_inv, Ainv)
  logdet_H <- as.numeric(determinant(Hdata + P, logarithm = TRUE)$modulus)
  laplace <- joint + 0.5 * logdet_H - n * log(2 * pi)
  c(joint = joint, laplace = laplace)
}

test_that("labelled NB2 animal q2 SD regression estimates the cross-coefficient correlation", {
  skip_on_cran()
  fx <- nb2_animal_q2_fit(20261101L, "p")
  fit_corr <- fx$fit
  fit_ind <- nb2_animal_q2_fit(20261101L, NULL)$fit

  expect_true(is_converged(fit_corr))
  expect_true(is_converged(fit_ind))
  key <- "cor(mu:(Intercept),mu:x | p | id)"
  expect_named(fit_corr$corpars$animal, key)
  rho_hat <- unname(fit_corr$corpars$animal[[key]])
  expect_true(is.finite(rho_hat))
  expect_lt(abs(rho_hat), 1)
  # Fixed-seed recovery band, not a calibration claim.
  expect_lt(abs(rho_hat - fx$sim$rho), 0.5)
  rho_report <- fit_corr$obj$report(fit_corr$obj$env$last.par.best)$rho_phylo
  expect_equal(rho_report, rho_hat, tolerance = 1e-8)
  # The independent fit is nested in the correlated one.
  expect_gte(
    as.numeric(logLik(fit_corr)), as.numeric(logLik(fit_ind)) - 1e-6
  )
  key0 <- 'sd_animal(id, dpar = "mu", coef = "(Intercept)")'
  key1 <- 'sd_animal(id, dpar = "mu", coef = "x")'
  expect_named(coef(fit_corr, key0), c("(Intercept)", "s0"))
  expect_named(coef(fit_corr, key1), c("(Intercept)", "s1"))
  expect_null(fit_ind$corpars$animal)
})

test_that("NB2 animal q2 fits build without warnings", {
  skip_on_cran()
  sim <- nb2_animal_q2_data()
  for (label in list("p", NULL)) {
    expect_no_warning(
      drmTMB(
        nb2_animal_q2_formula(sim$A, label = label),
        family = nbinom2(), data = sim$data, engine = "tmb"
      )
    )
  }
})

test_that("NB2 animal q2 joint and Laplace objectives match an independent R computation", {
  skip_on_cran()
  # Tolerances fixed before the first run. Joint objective (~1.5e3, double
  # precision): 1e-6 absolute. Laplace objective: 1e-5 absolute (TMB inner
  # optimum is converged to ~1e-8 in the gradient). Each emulated bug must
  # move the oracle by more than 1e-3 on both quantities.
  tol_joint <- 1e-6
  tol_laplace <- 1e-5
  tol_sensitive <- 1e-3
  bugs <- c(
    "logdet_once", "cross_sign", "drop_rho",
    "swap_sd_formulas", "swap_fields", "misaligned_levels"
  )
  for (seed in c(20261101L, 20261102L, 20261103L)) {
    fx <- nb2_animal_q2_fit(seed, "p")
    fit <- fx$fit
    env <- fit$obj$env
    joint <- env$f(env$last.par.best)
    rho <- fit$obj$report(env$last.par.best)$rho_phylo
    ref <- nb2_animal_q2_oracle(fit, fx$sim, rho)
    expect_lt(abs(ref[["joint"]] - joint), tol_joint)
    expect_lt(abs(ref[["laplace"]] - fit$opt$objective), tol_laplace)
    for (bug in bugs) {
      bad <- nb2_animal_q2_oracle(fit, fx$sim, rho, bug)
      expect_gt(abs(bad[["joint"]] - joint), tol_sensitive)
      expect_gt(abs(bad[["laplace"]] - fit$opt$objective), tol_sensitive)
    }
  }
  # Unlabelled fit: independent unit-scale fields, i.e. rho = 0.
  fx_ind <- nb2_animal_q2_fit(20261101L, NULL)
  env_ind <- fx_ind$fit$obj$env
  ref_ind <- nb2_animal_q2_oracle(fx_ind$fit, fx_ind$sim, rho = 0)
  expect_lt(abs(ref_ind[["joint"]] - env_ind$f(env_ind$last.par.best)), tol_joint)
  expect_lt(abs(ref_ind[["laplace"]] - fx_ind$fit$opt$objective), tol_laplace)
})

test_that("labelled NB2 animal q2 recovery holds on three fixed seeds", {
  skip_on_cran()
  for (seed in c(20261101L, 20261102L, 20261103L)) {
    fx <- nb2_animal_q2_fit(seed, "p")
    expect_true(is_converged(fx$fit))
    rho_hat <- unname(fx$fit$corpars$animal[[1L]])
    expect_lt(abs(rho_hat - fx$sim$rho), 0.5)
  }
})

test_that("constant coefficient SD formulas reproduce the formula-free animal q2 fit", {
  skip_on_cran()
  sim <- nb2_animal_q2_data(20261101L)
  A <- sim$A
  fit_const <- drmTMB(
    nb2_animal_q2_formula(A, label = NULL, sd0 = ~ 1, sd1 = ~ 1),
    family = nbinom2(), data = sim$data, engine = "tmb"
  )
  fit_free <- drmTMB(
    bf(y ~ x + animal(1 + x | id, A = A), sigma ~ 1),
    family = nbinom2(), data = sim$data, engine = "tmb"
  )
  expect_true(is_converged(fit_const))
  expect_true(is_converged(fit_free))
  # Tolerances fixed in advance: same model, different parameterisation.
  expect_equal(
    as.numeric(logLik(fit_const)), as.numeric(logLik(fit_free)),
    tolerance = 1e-3
  )
  expect_equal(
    unname(coef(fit_const, "mu")), unname(coef(fit_free, "mu")),
    tolerance = 1e-2
  )
  expect_equal(
    unname(coef(fit_const, "sigma")), unname(coef(fit_free, "sigma")),
    tolerance = 1e-2
  )
})

test_that("NB2 animal q2 refusals are designed errors", {
  skip_on_cran()
  sim <- nb2_animal_q2_data()
  A <- sim$A
  d <- sim$data
  d$z <- cos(seq_len(nrow(d)))
  K <- A
  nb <- nbinom2()
  sd_int <- sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ s0
  sd_x <- sd(id, level = "animal", dpar = "mu", coef = "x") ~ s1

  # Labelled, no sd() formulas: animal labelled q2 stays closed without SDs.
  expect_error(
    drmTMB(bf(y ~ x + animal(1 + x | p | id, A = A), sigma ~ 1),
           family = nb, data = d, engine = "tmb"),
    "only\\s+the\\s+implemented\\s+labelled\\s+covariance\\s+forms"
  )
  # One SD formula for a q2 block.
  expect_error(
    drmTMB(bf(y ~ x + animal(1 + x | p | id, A = A), sigma ~ 1, sd_int),
           family = nb, data = d, engine = "tmb"),
    "intercept\\s+plus\\s+one\\s+slope\\s+with\\s+one\\s+SD\\s+formula\\s+per\\s+coefficient"
  )
  # Two SD formulas on the same coefficient.
  expect_error(
    drmTMB(
      bf(y ~ x + animal(1 + x | id, A = A), sigma ~ 1, sd_int,
         sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ s1),
      family = nb, data = d, engine = "tmb"
    ),
    "requires\\s+one\\s+SD\\s+formula\\s+for\\s+each\\s+coefficient"
  )
  # Neighbours that stay closed: relmat q2 with SD formulas.
  expect_error(
    drmTMB(
      bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1,
         sd(id, level = "relmat", dpar = "mu", coef = "(Intercept)") ~ s0,
         sd(id, level = "relmat", dpar = "mu", coef = "x") ~ s1),
      family = nb, data = d, engine = "tmb"
    ),
    "currently\\s+supports\\s+one\\s+animal"
  )
  # Ordinary random effect beside the animal q2 block.
  expect_error(
    drmTMB(
      bf(y ~ x + animal(1 + x | id, A = A) + (1 | id), sigma ~ 1,
         sd_int, sd_x),
      family = nb, data = d, engine = "tmb"
    ),
    "cannot\\s+be\\s+combined\\s+with\\s+ordinary"
  )
  # Zero-inflated NB2 stays closed.
  expect_error(
    drmTMB(
      bf(y ~ x + animal(1 + x | id, A = A), sigma ~ 1, zi ~ 1, sd_int, sd_x),
      family = nbinom2(), data = d, engine = "tmb"
    ),
    "currently\\s+supports\\s+one\\s+animal|zero-inflat"
  )
  # Three coefficients stay closed.
  expect_error(
    drmTMB(
      bf(y ~ x + z + animal(1 + x + z | id, A = A), sigma ~ 1, sd_int, sd_x),
      family = nb, data = d, engine = "tmb"
    ),
    "reserves\\s+only\\s+intercept\\s+and\\s+one-slope"
  )
})
