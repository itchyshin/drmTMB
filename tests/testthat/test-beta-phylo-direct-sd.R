new_beta_phylo_direct_sd_data <- function(
  n_tip = 20L,
  n_each = 10L,
  seed = 2026071672L,
  alpha_sd = c(`(Intercept)` = log(0.30), z_species = 0.30)
) {
  set.seed(seed)
  tree <- ape::rcoal(n_tip)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_species <- as.numeric(scale(stats::rnorm(n_tip)))
  names(z_species) <- tree$tip.label
  tau <- exp(alpha_sd[[1L]] + alpha_sd[[2L]] * z_species)
  unit_tip <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip))
  names(unit_tip) <- tree$tip.label

  species <- rep(tree$tip.label, each = n_each)
  x_mu <- stats::rnorm(length(species))
  x_sigma <- stats::rnorm(length(species))
  beta_mu <- c(`(Intercept)` = -0.20, x_mu = 0.35)
  beta_sigma <- c(`(Intercept)` = log(0.25), x_sigma = 0.15)
  eta_mu <- beta_mu[[1L]] + beta_mu[[2L]] * x_mu +
    tau[species] * unit_tip[species]
  log_sigma <- beta_sigma[[1L]] + beta_sigma[[2L]] * x_sigma
  mu <- stats::plogis(eta_mu)
  phi <- exp(-2 * log_sigma)

  list(
    data = data.frame(
      y = stats::rbeta(length(mu), mu * phi, (1 - mu) * phi),
      x_mu,
      x_sigma,
      z_species = unname(z_species[species]),
      species
    ),
    tree = tree,
    A = A,
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    alpha_sd = alpha_sd,
    tau = tau,
    unit_tip = unit_tip
  )
}

beta_phylo_direct_sd_joint_nll <- function(
  fit,
  par,
  wrong_phi = FALSE,
  double_scale = FALSE
) {
  data <- fit$model$tmb_data
  n_phylo <- nrow(data$Q_phylo)
  eta_mu <- as.vector(data$X_mu %*% par$beta_mu)
  log_sigma <- as.vector(data$X_sigma %*% par$beta_sigma)
  log_tau <- as.vector(data$X_sd_phylo %*% par$beta_sd_mu)
  tau <- exp(log_tau)
  if (double_scale) {
    tau <- tau^2
  }
  effect_index <- data$phylo_mu_node_index + 1L
  sd_row <- data$phylo_mu_sd_row + 1L
  eta_mu <- eta_mu +
    data$phylo_mu_value[, 1L] * tau[sd_row] * par$u_phylo[effect_index]

  Q_u <- as.vector(data$Q_phylo %*% par$u_phylo)
  prior <- 0.5 * (
    n_phylo * log(2 * pi) - data$log_det_Q_phylo +
      sum(par$u_phylo * Q_u)
  )
  mu_eps <- 1e-12
  mu <- mu_eps + (1 - 2 * mu_eps) * stats::plogis(eta_mu)
  phi <- if (wrong_phi) exp(2 * log_sigma) else exp(-2 * log_sigma)
  shape1 <- pmax(mu * phi, 1e-8)
  shape2 <- pmax((1 - mu) * phi, 1e-8)
  prior - sum(
    data$weights *
      stats::dbeta(data$y, shape1 = shape1, shape2 = shape2, log = TRUE)
  )
}

beta_direct_sd_central_gradient <- function(fn, par) {
  vapply(
    seq_along(par),
    function(i) {
      step <- 1e-6 * max(1, abs(par[[i]]))
      plus <- minus <- par
      plus[[i]] <- plus[[i]] + step
      minus[[i]] <- minus[[i]] - step
      (fn(plus) - fn(minus)) / (2 * step)
    },
    numeric(1L)
  )
}

test_that("Beta direct phylogenetic SD has D_tau A D_tau covariance", {
  skip_if_not_installed("ape")
  sim <- new_beta_phylo_direct_sd_data(n_tip = 6L, n_each = 2L)
  D_tau <- diag(unname(sim$tau))
  expected <- D_tau %*% sim$A %*% D_tau
  elementwise <- tcrossprod(unname(sim$tau)) * sim$A
  wrong_double_scale <- tcrossprod(unname(sim$tau)^2) * sim$A
  set.seed(2026071673L)
  n_draw <- 50000L
  unit_draw <- t(chol(sim$A)) %*%
    matrix(stats::rnorm(nrow(sim$A) * n_draw), nrow = nrow(sim$A))
  scaled_draw <- unname(sim$tau) * unit_draw
  empirical <- tcrossprod(sweep(scaled_draw, 1L, rowMeans(scaled_draw))) /
    (n_draw - 1L)

  expect_equal(unname(elementwise), unname(expected), tolerance = 1e-12)
  expect_equal(diag(expected), unname(sim$tau)^2, tolerance = 1e-12)
  expect_equal(unname(empirical), unname(expected), tolerance = 0.015)
  expect_gt(max(abs(wrong_double_scale - expected)), 1e-3)
})

test_that("Beta q1 admits exact phylogenetic direct-SD regression", {
  skip_if_not_installed("ape")
  sim <- new_beta_phylo_direct_sd_data(n_tip = 24L, n_each = 10L)
  tree <- sim$tree
  fit <- drmTMB(
    bf(
      y ~ x_mu + phylo(1 | species, tree = tree),
      sigma ~ x_sigma,
      sd(species, level = "phylogenetic") ~ z_species
    ),
    family = beta(),
    data = sim$data,
    control = drm_control(optimizer = list(eval.max = 1000, iter.max = 1000))
  )

  dpar <- "sd_phylo(species)"
  sd_hat <- predict(fit, dpar = dpar)
  sd_link <- predict(fit, dpar = dpar, type = "link")
  targets <- profile_targets(fit)
  sd_targets <- targets[
    grepl("^fixef:sd_phylo\\(species\\):", targets$parm),
    ,
    drop = FALSE
  ]
  random <- ranef(fit, "phylo_mu")
  tip_node <- match(tree$tip.label, fit$model$structured$phylo_mu$node_labels)
  smry <- summary(fit)
  direct_rows <- grep("^sd_phylo\\(species\\):", rownames(smry$coefficients))
  species_rows <- sim$data[!duplicated(sim$data$species), , drop = FALSE]
  prediction_rows <- species_rows[c(1L, nrow(species_rows)), , drop = FALSE]
  sd_new <- predict(fit, newdata = prediction_rows, dpar = dpar)
  expected_sd_new <- exp(as.vector(
    stats::model.matrix(~z_species, prediction_rows) %*% coef(fit, dpar)
  ))

  expect_equal(fit$opt$convergence, 0L)
  expect_true(fit$sdr$pdHess)
  expect_length(direct_rows, 2L)
  expect_true(all(is.finite(smry$coefficients[direct_rows, "std_error"])))
  expect_equal(fit$model$random_scale$phylo$n_models, 1L)
  expect_named(coef(fit, dpar), names(sim$alpha_sd))
  expect_named(fit$sdpars, dpar)
  expect_equal(exp(sd_link), sd_hat, tolerance = 1e-10)
  expect_equal(unname(sd_new), expected_sd_new, tolerance = 1e-10)
  expect_equal(length(sd_hat), length(tree$tip.label))
  expect_equal(sd_targets$tmb_parameter, rep("beta_sd_mu", 2L))
  expect_equal(sd_targets$index, c(1L, 2L))
  expect_true(all(sd_targets$profile_ready))
  expect_equal(
    random$values[tip_node],
    random$latent[tip_node] * sd_hat[tree$tip.label],
    tolerance = 1e-10
  )
  expect_true(all(is.na(random$values[-tip_node])))
  expect_equal(
    predict(fit, dpar = "mu", type = "link"),
    as.vector(fit$model$X$mu %*% coef(fit, "mu")) +
      drmTMB:::phylo_mu_contribution(fit),
    tolerance = 1e-8
  )
  expect_equal(
    predict(fit, dpar = "sigma", type = "link"),
    fit$obj$report()$log_sigma,
    tolerance = 1e-10
  )
  expect_equal(
    predict(fit, dpar = "sigma"),
    exp(fit$obj$report()$log_sigma),
    tolerance = 1e-10
  )
  expect_true(any(grepl(dpar, capture.output(print(smry)), fixed = TRUE)))
  expect_false(any(check_drm(fit)$status == "error"))
})

test_that("Beta direct-SD joint NLL and every gradient match independent oracles", {
  skip_if_not_installed("ape")
  sim <- new_beta_phylo_direct_sd_data(n_tip = 7L, n_each = 3L)
  tree <- sim$tree
  fit <- drmTMB(
    bf(
      y ~ x_mu + phylo(1 | species, tree = tree),
      sigma ~ x_sigma,
      sd(species, level = "phylogenetic") ~ z_species
    ),
    family = beta(),
    data = sim$data,
    control = drm_control(se = FALSE)
  )
  full_obj <- TMB::MakeADFun(
    data = fit$model$tmb_data,
    parameters = fit$model$start,
    map = fit$model$map,
    DLL = "drmTMB",
    silent = TRUE
  )
  probe <- full_obj$par
  probe[seq_along(probe)] <- probe +
    seq(-0.06, 0.06, length.out = length(probe))
  par <- full_obj$env$parList(probe)
  oracle <- beta_phylo_direct_sd_joint_nll(fit, par)

  expect_equal(full_obj$fn(probe), oracle, tolerance = 1e-8)
  expect_equal(
    as.numeric(full_obj$gr(probe)),
    beta_direct_sd_central_gradient(full_obj$fn, probe),
    tolerance = 3e-5
  )
  expect_gt(
    abs(oracle - beta_phylo_direct_sd_joint_nll(fit, par, wrong_phi = TRUE)),
    0.01
  )
  expect_gt(
    abs(oracle - beta_phylo_direct_sd_joint_nll(fit, par, double_scale = TRUE)),
    0.01
  )
})

test_that("Beta intercept-only direct SD is equivalent to scalar phylogenetic SD", {
  skip_if_not_installed("ape")
  sim <- new_beta_phylo_direct_sd_data(
    n_tip = 64L,
    n_each = 8L,
    alpha_sd = c(`(Intercept)` = log(0.80), z_species = 0)
  )
  dat <- sim$data
  tree <- sim$tree
  fit_scalar <- drmTMB(
    bf(y ~ x_mu + phylo(1 | species, tree = tree), sigma ~ x_sigma),
    family = beta(),
    data = dat,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 1000, iter.max = 1000)
    )
  )
  fit_direct <- drmTMB(
    bf(
      y ~ x_mu + phylo(1 | species, tree = tree),
      sigma ~ x_sigma,
      sd(species, level = "phylogenetic") ~ 1
    ),
    family = beta(),
    data = dat,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 1000, iter.max = 1000)
    )
  )

  expect_equal(fit_scalar$opt$convergence, 0L)
  expect_equal(fit_direct$opt$convergence, 0L)
  expect_equal(
    as.numeric(stats::logLik(fit_direct)),
    as.numeric(stats::logLik(fit_scalar)),
    tolerance = 2e-5
  )
  expect_equal(coef(fit_direct, "mu"), coef(fit_scalar, "mu"), tolerance = 2e-5)
  expect_equal(
    coef(fit_direct, "sigma"),
    coef(fit_scalar, "sigma"),
    tolerance = 2e-5
  )
  expect_equal(
    unname(coef(fit_direct, "sd_phylo(species)")[[1L]]),
    log(unname(fit_scalar$sdpars$mu[["phylo(1 | species)"]])),
    tolerance = 1e-4
  )

  scalar_obj <- TMB::MakeADFun(
    data = fit_scalar$model$tmb_data,
    parameters = fit_scalar$model$start,
    map = fit_scalar$model$map,
    DLL = "drmTMB",
    silent = TRUE
  )
  direct_obj <- TMB::MakeADFun(
    data = fit_direct$model$tmb_data,
    parameters = fit_direct$model$start,
    map = fit_direct$model$map,
    DLL = "drmTMB",
    silent = TRUE
  )
  scalar_probe <- scalar_obj$par
  direct_probe <- direct_obj$par
  beta_mu_probe <- c(-0.12, 0.28)
  beta_sigma_probe <- c(log(0.27), 0.11)
  log_tau_probe <- -0.35
  n_phylo <- nrow(fit_scalar$model$tmb_data$Q_phylo)
  scaled_field <- seq(-0.30, 0.30, length.out = n_phylo)
  unit_field <- scaled_field / exp(log_tau_probe)

  scalar_probe[names(scalar_probe) == "beta_mu"] <- beta_mu_probe
  scalar_probe[names(scalar_probe) == "beta_sigma"] <- beta_sigma_probe
  scalar_probe[names(scalar_probe) == "log_sd_phylo"] <- log_tau_probe
  scalar_probe[names(scalar_probe) == "u_phylo"] <- scaled_field
  direct_probe[names(direct_probe) == "beta_mu"] <- beta_mu_probe
  direct_probe[names(direct_probe) == "beta_sigma"] <- beta_sigma_probe
  direct_probe[names(direct_probe) == "beta_sd_mu"] <- log_tau_probe
  direct_probe[names(direct_probe) == "u_phylo"] <- unit_field

  # p_a(a) = p_v(v) / tau^n for a = tau v, so the scalar-field NLL is
  # the unit-field NLL plus n * log(tau) at matched displaced parameters.
  expect_equal(
    scalar_obj$fn(scalar_probe),
    direct_obj$fn(direct_probe) + n_phylo * log_tau_probe,
    tolerance = 1e-8
  )
})

test_that("Beta direct phylogenetic SD keeps malformed neighbours closed", {
  skip_if_not_installed("ape")
  sim <- new_beta_phylo_direct_sd_data(n_tip = 8L, n_each = 4L)
  dat <- sim$data
  tree <- sim$tree
  dat$z_bad <- seq_len(nrow(dat))
  dat$other_species <- dat$species
  dat$block <- rep(letters[1:4], length.out = nrow(dat))

  expect_error(
    drmTMB(
      bf(
        y ~ x_mu + phylo(1 | species, tree = tree),
        sigma ~ x_sigma,
        sd(species, level = "phylogenetic") ~ z_bad
      ),
      family = beta(), data = dat
    ),
    "varies within"
  )
  expect_error(
    drmTMB(
      bf(
        y ~ x_mu + phylo(1 | species, tree = tree),
        sigma ~ x_sigma,
        sd(other_species, level = "phylogenetic") ~ z_species
      ),
      family = beta(), data = dat
    ),
    "does not match"
  )
  expect_error(
    drmTMB(
      bf(
        y ~ x_mu,
        sigma ~ x_sigma,
        sd(species, level = "phylogenetic") ~ z_species
      ),
      family = beta(), data = dat
    ),
    "No phylogenetic location random-effect term matches"
  )
  expect_error(
    drmTMB(
      bf(
        y ~ x_mu + phylo(1 | species, tree = tree),
        sigma ~ x_sigma,
        sd(species, level = "phylogenetic") ~ 1 + (1 | block)
      ),
      family = beta(), data = dat
    ),
    "unsupported model terms"
  )
  dat_missing <- dat
  dat_missing$y[[1L]] <- NA_real_
  expect_error(
    drmTMB(
      bf(
        y ~ x_mu + phylo(1 | species, tree = tree),
        sigma ~ x_sigma,
        sd(species, level = "phylogenetic") ~ z_species
      ),
      family = beta(),
      data = dat_missing,
      missing = miss_control(response = "include")
    ),
    "not implemented with missing-data routes"
  )
  dat_mi <- dat
  dat_mi$treatment <- factor(as.integer(dat_mi$x_mu > 0), levels = c(0, 1))
  dat_mi$treatment[c(2L, 7L)] <- NA
  expect_error(
    drmTMB(
      bf(
        y ~ mi(treatment) + phylo(1 | species, tree = tree),
        sigma ~ x_sigma,
        sd(species, level = "phylogenetic") ~ z_species
      ),
      family = beta(),
      data = dat_mi,
      impute = list(
        treatment = impute_model(treatment ~ x_sigma, family = binomial())
      ),
      missing = miss_control(predictor = "model")
    ),
    "not implemented with missing-data routes"
  )
  expect_error(
    drmTMB(
      bf(
        y ~ x_mu + phylo(1 | species, tree = tree),
        sigma ~ x_sigma,
        sd(species, level = "phylogenetic") ~ z_species
      ),
      family = zero_one_beta(), data = dat
    ),
    "Unsupported parameter"
  )
  expect_error(
    drmTMB(
      bf(
        y ~ x_mu + phylo(1 | species, tree = tree),
        sigma ~ x_sigma,
        sd(species) ~ z_species
      ),
      family = beta(), data = dat
    ),
    "Random-effect scale"
  )
  expect_error(
    drmTMB(
      bf(
        y ~ x_mu + phylo(1 | species, tree = tree),
        sigma ~ x_sigma,
        sd(species, level = "phylogenetic") ~ z_species
      ),
      family = beta(), data = dat, REML = TRUE
    ),
    "REML.*only"
  )
})
