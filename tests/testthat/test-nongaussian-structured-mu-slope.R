# Row-87 admission: non-count family structured mu ONE-SLOPE cells.
#
# These are native TMB ML/Laplace point-fit and extractor cells for non-count
# `mu` one-slope structured dependence: Gamma x relmat, Student x spatial, and
# beta x animal. This is recovery-only evidence. It does NOT imply retained
# denominators, intervals, coverage, labelled covariance, multiple structured
# slopes, scale/shape/inflation structured slopes, REML, AI-REML, bridge
# support, or public-support promotion, all of which remain planned.

beta_animal_mu_nll <- function(fit, par) {
  data <- fit$model$tmb_data
  n_level <- nrow(data$Q_phylo)
  u <- matrix(par$u_phylo, nrow = n_level)
  eta_mu <- as.vector(data$offset_mu + data$X_mu %*% par$beta_mu)
  for (k in seq_len(ncol(u))) {
    eta_mu <- eta_mu + data$phylo_mu_value[, k] *
      u[data$phylo_mu_node_index + 1L, k]
  }
  quadratic <- vapply(seq_len(ncol(u)), function(k) {
    sum(u[, k] * as.vector(data$Q_phylo %*% u[, k]))
  }, numeric(1L))
  prior <- sum(0.5 * (
    n_level * log(2 * pi) + 2 * n_level * par$log_sd_phylo -
      data$log_det_Q_phylo + exp(-2 * par$log_sd_phylo) * quadratic
  ))
  log_sigma <- as.vector(data$X_sigma %*% par$beta_sigma)
  mu <- stats::plogis(eta_mu)
  phi <- exp(-2 * log_sigma)
  observed <- as.logical(data$observed_y)
  prior - sum(data$weights[observed] * stats::dbeta(
    data$y[observed], shape1 = mu[observed] * phi[observed],
    shape2 = (1 - mu[observed]) * phi[observed], log = TRUE
  ))
}

beta_animal_central_gradient <- function(fn, par, step = 1e-6) {
  vapply(seq_along(par), function(i) {
    plus <- minus <- par
    plus[[i]] <- plus[[i]] + step
    minus[[i]] <- minus[[i]] - step
    (fn(plus) - fn(minus)) / (2 * step)
  }, numeric(1L))
}

beta_animal_sigma_nll <- function(fit, par) {
  data <- fit$model$tmb_data
  eta_mu <- as.vector(data$offset_mu + data$X_mu %*% par$beta_mu)
  log_sigma <- as.vector(data$X_sigma %*% par$beta_sigma)
  log_sigma <- log_sigma + data$phylo_mu_value[, 1L] *
    par$u_phylo[data$phylo_mu_node_index + 1L]
  quadratic <- sum(par$u_phylo * as.vector(data$Q_phylo %*% par$u_phylo))
  prior <- 0.5 * (
    nrow(data$Q_phylo) * log(2 * pi) +
      2 * nrow(data$Q_phylo) * par$log_sd_phylo -
      data$log_det_Q_phylo + exp(-2 * par$log_sd_phylo) * quadratic
  )
  mu <- stats::plogis(eta_mu)
  phi <- exp(-2 * log_sigma)
  observed <- as.logical(data$observed_y)
  prior - sum(data$weights[observed] * stats::dbeta(
    data$y[observed], shape1 = mu[observed] * phi[observed],
    shape2 = (1 - mu[observed]) * phi[observed], log = TRUE
  ))
}

# Independent observed-data oracle for Student-t structured terms.  The shared
# structured container is named `phylo` for historical reasons; `spatial()` is
# stored in the same Q/data fields.  The endpoint code decides where each
# column contributes: 0 = mu, 1 = log(sigma), and 2 = eta(nu).
student_structured_nll <- function(fit, par) {
  data <- fit$model$tmb_data
  n_level <- nrow(data$Q_phylo)
  u <- matrix(par$u_phylo, nrow = n_level)
  mu <- as.vector(data$offset_mu + data$X_mu %*% par$beta_mu)
  log_sigma <- as.vector(data$X_sigma %*% par$beta_sigma)
  eta_nu <- as.vector(data$X_nu %*% par$beta_nu)
  prior <- 0
  for (k in seq_len(ncol(u))) {
    contribution <- data$phylo_mu_value[, k] *
      u[data$phylo_mu_node_index + 1L, k]
    code <- data$phylo_mu_dpar[[k]]
    if (code == 0L) mu <- mu + contribution
    if (code == 1L) log_sigma <- log_sigma + contribution
    if (code == 2L) eta_nu <- eta_nu + contribution
    quadratic <- sum(u[, k] * as.vector(data$Q_phylo %*% u[, k]))
    prior <- prior + 0.5 * (
      n_level * log(2 * pi) + 2 * n_level * par$log_sd_phylo[[k]] -
        data$log_det_Q_phylo + exp(-2 * par$log_sd_phylo[[k]]) * quadratic
    )
  }
  observed <- as.logical(data$observed_y)
  sigma <- exp(log_sigma)
  nu <- 2 + exp(eta_nu)
  prior - sum(data$weights[observed] * (
    stats::dt((data$y[observed] - mu[observed]) / sigma[observed],
      df = nu[observed], log = TRUE
    ) - log_sigma[observed]
  ))
}

student_spatial_fixture <- function(
  slope = FALSE, n_level = 64L, n_each = 40L, seed = 2026081801L
) {
  set.seed(seed)
  levels_id <- paste0("st", seq_len(n_level))
  id <- factor(rep(levels_id, each = n_each), levels = levels_id)
  x <- stats::rnorm(length(id))
  theta <- seq(0, 1.9 * pi, length.out = n_level)
  coords <- data.frame(x = cos(theta), y = sin(theta), row.names = levels_id)
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords, site = levels_id, group = "site"
  )
  covariance <- solve(as.matrix(precision$precision))
  draw_field <- function(sd) {
    field <- as.vector(t(chol(covariance)) %*% stats::rnorm(n_level, sd = sd))
    stats::setNames(field, levels_id)
  }
  intercept <- draw_field(0.55)
  slope_field <- if (slope) draw_field(0.35) else stats::setNames(rep(0, n_level), levels_id)
  beta_mu <- c("(Intercept)" = 0.2, x = 0.5)
  beta_sigma <- log(0.28)
  beta_nu <- log(10)
  mu <- beta_mu[[1L]] + beta_mu[[2L]] * x +
    intercept[as.character(id)] + slope_field[as.character(id)] * x
  y <- mu + exp(beta_sigma) * stats::rt(length(id), df = 2 + exp(beta_nu))
  list(
    data = data.frame(y = y, x = x, id = id), coords = coords,
    beta_mu = beta_mu, beta_sigma = beta_sigma, beta_nu = beta_nu,
    sd_intercept = 0.55, sd_slope = 0.35
  )
}

student_phylo_nu_fixture <- function(
  n_tip = 48L, n_each = 200L, seed = 2026081805L
) {
  set.seed(seed)
  tree <- ape::chronos(ape::rtree(n_tip), lambda = 1, quiet = TRUE)
  levels_id <- tree$tip.label
  precision <- drmTMB:::drm_phylo_augmented_precision(tree, species = levels_id)
  latent <- as.vector(
    t(chol(solve(as.matrix(precision$precision)))) %*%
      stats::rnorm(nrow(precision$precision), sd = 0.85)
  )
  names(latent) <- rownames(precision$precision)
  id <- factor(rep(levels_id, each = n_each), levels = levels_id)
  x <- stats::rnorm(length(id))
  beta_mu <- c("(Intercept)" = 0.2, x = 0.45)
  beta_sigma <- log(0.28)
  beta_nu <- log(8)
  eta_nu <- beta_nu + latent[as.character(id)]
  y <- beta_mu[[1L]] + beta_mu[[2L]] * x + exp(beta_sigma) * stats::rt(
    length(id), df = 2 + exp(eta_nu)
  )
  list(
    data = data.frame(y = y, x = x, id = id), tree = tree,
    beta_mu = beta_mu, beta_sigma = beta_sigma, beta_nu = beta_nu,
    sd_nu = 0.85
  )
}

test_that("non-count structured mu one-slope cells fit and expose intercept + slope SDs", {
  testthat::skip_if_not_installed("ape")

  ## --- Gamma x relmat(1 + x | id, K) ---
  set.seed(2026070601)
  gl <- paste0("g", seq_len(8L))
  gid <- factor(rep(gl, each = 12L), levels = gl)
  gx <- stats::rnorm(length(gid))
  g_int <- stats::rnorm(8L, sd = 0.30)
  g_slp <- stats::rnorm(8L, sd = 0.20)
  names(g_int) <- gl
  names(g_slp) <- gl
  gmu <- exp(0.4 + 0.25 * gx + g_int[as.character(gid)] + g_slp[as.character(gid)] * gx)
  dat_gamma <- data.frame(
    y = stats::rgamma(length(gid), shape = 25, scale = gmu / 25),
    x = gx,
    id = gid
  )
  K_gamma <- diag(8L)
  dimnames(K_gamma) <- list(gl, gl)

  fit_gamma <- drmTMB(
    bf(y ~ x + relmat(1 + x | id, K = K_gamma), sigma ~ 1),
    family = stats::Gamma(link = "log"),
    data = dat_gamma,
    control = drm_control(se = FALSE)
  )
  expect_s3_class(fit_gamma, "drmTMB")
  expect_equal(as.integer(fit_gamma$opt$convergence), 0L)
  expect_true("relmat_mu" %in% names(fit_gamma$random_effects))
  expect_true("relmat(1 | id)" %in% names(fit_gamma$sdpars$mu))
  expect_true("relmat(0 + x | id)" %in% names(fit_gamma$sdpars$mu))

  ## --- Student x spatial(1 + x | id, coords) ---
  set.seed(2026070602)
  sl <- paste0("s", seq_len(8L))
  sid <- factor(rep(sl, each = 20L), levels = sl)
  sx <- stats::rnorm(length(sid))
  s_int <- stats::rnorm(8L, sd = 0.25)
  s_slp <- stats::rnorm(8L, sd = 0.20)
  names(s_int) <- sl
  names(s_slp) <- sl
  smu <- 0.2 + 0.5 * sx + s_int[as.character(sid)] + s_slp[as.character(sid)] * sx
  dat_student <- data.frame(
    y = smu + 0.25 * stats::rt(length(sid), df = 12),
    x = sx,
    id = sid
  )
  coords_student <- data.frame(
    x = rep(seq_len(4L), each = 2L),
    y = rep(seq_len(2L), times = 4L),
    row.names = sl
  )

  fit_student <- drmTMB(
    bf(y ~ x + spatial(1 + x | id, coords = coords_student), sigma ~ 1),
    family = student(),
    data = dat_student,
    control = drm_control(se = FALSE)
  )
  expect_s3_class(fit_student, "drmTMB")
  expect_equal(as.integer(fit_student$opt$convergence), 0L)
  expect_true("spatial_mu" %in% names(fit_student$random_effects))
  expect_true("spatial(1 | id)" %in% names(fit_student$sdpars$mu))
  expect_true("spatial(0 + x | id)" %in% names(fit_student$sdpars$mu))

  ## --- beta x animal(1 + x | id, pedigree) ---
  set.seed(2026070603)
  bl <- paste0("b", seq_len(8L))
  bid <- factor(rep(bl, each = 20L), levels = bl)
  bx <- stats::rnorm(length(bid))
  b_int <- stats::rnorm(8L, sd = 0.30)
  b_slp <- stats::rnorm(8L, sd = 0.20)
  names(b_int) <- bl
  names(b_slp) <- bl
  blink <- -0.2 + 0.45 * bx + b_int[as.character(bid)] + b_slp[as.character(bid)] * bx
  bmu <- stats::plogis(blink)
  phi <- 8
  by <- stats::rbeta(length(bid), shape1 = bmu * phi, shape2 = (1 - bmu) * phi)
  by <- pmin(pmax(by, 1e-4), 1 - 1e-4)
  dat_beta <- data.frame(y = by, x = bx, id = bid)
  ped_beta <- data.frame(id = bl, dam = NA_character_, sire = NA_character_)

  fit_beta <- drmTMB(
    bf(y ~ x + animal(1 + x | id, pedigree = ped_beta), sigma ~ 1),
    family = beta(),
    data = dat_beta,
    control = drm_control(se = FALSE)
  )
  expect_s3_class(fit_beta, "drmTMB")
  expect_equal(as.integer(fit_beta$opt$convergence), 0L)
  expect_true("animal_mu" %in% names(fit_beta$random_effects))
  expect_true("animal(1 | id)" %in% names(fit_beta$sdpars$mu))
  expect_true("animal(0 + x | id)" %in% names(fit_beta$sdpars$mu))

  ## --- Boundary preserved: multiple slopes and labelled covariance stay rejected ---
  dat_gamma$z <- stats::rnorm(nrow(dat_gamma))
  expect_error(
    drmTMB(
      bf(y ~ x + z + relmat(1 + x + z | id, K = K_gamma), sigma ~ 1),
      family = stats::Gamma(link = "log"),
      data = dat_gamma
    ),
    "intercept and one-slope"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + relmat(1 + x | p | id, K = K_gamma), sigma ~ 1),
      family = stats::Gamma(link = "log"),
      data = dat_gamma
    ),
    "unlabelled q=1"
  )
})

test_that("Beta animal mu intercept-slope response mask has oracle and recovery evidence", {
  source(
    file.path(testthat::test_path(), "..", "..", "tools", "arc2-beta-animal-fixtures.R"),
    local = TRUE
  )
  sim <- beta_animal_mu_slope_fixture(n_each = 40L, seed = 2026081773L)
  dat <- sim$data
  dat$y[seq(1L, nrow(dat), by = 40L)] <- NA_real_
  observed <- !is.na(dat$y)
  pedigree <- sim$pedigree
  formula <- bf(y ~ x + animal(1 + x | id, pedigree = pedigree), sigma ~ 1)
  fit_masked <- drmTMB(
    formula, family = beta(), data = dat,
    missing = miss_control(response = "include"), control = drm_control(se = FALSE)
  )
  fit_observed <- drmTMB(
    formula, family = beta(), data = dat[observed, , drop = FALSE],
    control = drm_control(se = FALSE)
  )
  obj <- TMB::MakeADFun(
    data = fit_masked$model$tmb_data, parameters = fit_masked$model$start,
    map = fit_masked$model$map, DLL = "drmTMB", silent = TRUE
  )
  probe <- obj$par + seq(-0.04, 0.04, length.out = length(obj$par))
  par <- obj$env$parList(probe)

  expect_equal(fit_masked$opt$convergence, 0L)
  expect_equal(fit_observed$opt$convergence, 0L)
  expect_equal(nobs(fit_masked), sum(observed))
  expect_equal(fit_masked$missing_data$observed_y, observed)
  expect_equal(obj$fn(probe), beta_animal_mu_nll(fit_masked, par), tolerance = 1e-7)
  expect_equal(
    as.numeric(obj$gr(probe)), beta_animal_central_gradient(obj$fn, probe),
    tolerance = 5e-5
  )
  expect_missing_response_sentinel_invariant(fit_masked, sentinels = c(0.2, 0.8))
  expect_equal(coef(fit_masked, "mu"), coef(fit_observed, "mu"), tolerance = 1e-6)
  expect_equal(coef(fit_masked, "sigma"), coef(fit_observed, "sigma"), tolerance = 1e-6)
  expect_equal(fit_masked$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-6)
  expect_lt(abs(coef(fit_masked, "mu")[["x"]] - sim$beta_x), 0.18)
  expect_lt(abs(coef(fit_masked, "sigma")[[1L]] - log(1 / sqrt(sim$phi))), 0.15)
  expect_lt(abs(fit_masked$sdpars$mu[["animal(1 | id)"]] - sim$sd_intercept), 0.22)
  expect_lt(abs(fit_masked$sdpars$mu[["animal(0 + x | id)"]] - sim$sd_slope), 0.22)
})

test_that("Beta animal sigma response mask has oracle and recovery evidence", {
  source(
    file.path(testthat::test_path(), "..", "..", "tools", "arc2-beta-animal-fixtures.R"),
    local = TRUE
  )
  sim <- beta_animal_sigma_intercept_fixture(n_each = 60L, seed = 2026081774L)
  dat <- sim$data
  dat$y[seq(1L, nrow(dat), by = 60L)] <- NA_real_
  observed <- !is.na(dat$y)
  pedigree <- sim$pedigree
  formula <- bf(y ~ x, sigma ~ animal(1 | id, pedigree = pedigree))
  fit_masked <- drmTMB(
    formula, family = beta(), data = dat,
    missing = miss_control(response = "include"), control = drm_control(se = FALSE)
  )
  fit_observed <- drmTMB(
    formula, family = beta(), data = dat[observed, , drop = FALSE],
    control = drm_control(se = FALSE)
  )
  obj <- TMB::MakeADFun(
    data = fit_masked$model$tmb_data, parameters = fit_masked$model$start,
    map = fit_masked$model$map, DLL = "drmTMB", silent = TRUE
  )
  probe <- obj$par + seq(-0.04, 0.04, length.out = length(obj$par))
  par <- obj$env$parList(probe)

  expect_equal(fit_masked$opt$convergence, 0L)
  expect_equal(fit_observed$opt$convergence, 0L)
  expect_equal(nobs(fit_masked), sum(observed))
  expect_equal(fit_masked$missing_data$observed_y, observed)
  expect_equal(obj$fn(probe), beta_animal_sigma_nll(fit_masked, par), tolerance = 1e-7)
  expect_equal(
    as.numeric(obj$gr(probe)), beta_animal_central_gradient(obj$fn, probe),
    tolerance = 5e-5
  )
  expect_missing_response_sentinel_invariant(fit_masked, sentinels = c(0.2, 0.8))
  expect_equal(coef(fit_masked, "mu"), coef(fit_observed, "mu"), tolerance = 1e-6)
  expect_equal(coef(fit_masked, "sigma"), coef(fit_observed, "sigma"), tolerance = 1e-6)
  expect_equal(fit_masked$sdpars$sigma, fit_observed$sdpars$sigma, tolerance = 1e-6)
  expect_lt(abs(coef(fit_masked, "mu")[["x"]] - sim$beta_x), 0.15)
  expect_lt(abs(coef(fit_masked, "sigma")[[1L]] - log(sim$sigma0)), 0.18)
  expect_lt(abs(fit_masked$sdpars$sigma[["animal(1 | id)"]] - sim$sd_animal_sigma), 0.20)
})

test_that("Beta animal mu intercept response mask has oracle and recovery evidence", {
  source(
    file.path(testthat::test_path(), "..", "..", "tools", "arc2-beta-animal-fixtures.R"),
    local = TRUE
  )
  sim <- beta_animal_mu_slope_fixture(
    n_each = 60L, sd_slope = 0, seed = 2026081775L
  )
  dat <- sim$data
  dat$y[seq(1L, nrow(dat), by = 60L)] <- NA_real_
  observed <- !is.na(dat$y)
  pedigree <- sim$pedigree
  formula <- bf(y ~ x + animal(1 | id, pedigree = pedigree), sigma ~ 1)
  fit_masked <- drmTMB(
    formula, family = beta(), data = dat,
    missing = miss_control(response = "include"), control = drm_control(se = FALSE)
  )
  fit_observed <- drmTMB(
    formula, family = beta(), data = dat[observed, , drop = FALSE],
    control = drm_control(se = FALSE)
  )
  obj <- TMB::MakeADFun(
    data = fit_masked$model$tmb_data, parameters = fit_masked$model$start,
    map = fit_masked$model$map, DLL = "drmTMB", silent = TRUE
  )
  probe <- obj$par + seq(-0.04, 0.04, length.out = length(obj$par))
  par <- obj$env$parList(probe)

  expect_equal(fit_masked$opt$convergence, 0L)
  expect_equal(fit_observed$opt$convergence, 0L)
  expect_equal(nobs(fit_masked), sum(observed))
  expect_equal(fit_masked$missing_data$observed_y, observed)
  expect_equal(obj$fn(probe), beta_animal_mu_nll(fit_masked, par), tolerance = 1e-7)
  expect_equal(
    as.numeric(obj$gr(probe)), beta_animal_central_gradient(obj$fn, probe),
    tolerance = 5e-5
  )
  expect_missing_response_sentinel_invariant(fit_masked, sentinels = c(0.2, 0.8))
  expect_equal(coef(fit_masked, "mu"), coef(fit_observed, "mu"), tolerance = 2e-6)
  expect_equal(coef(fit_masked, "sigma"), coef(fit_observed, "sigma"), tolerance = 1e-6)
  expect_equal(fit_masked$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-6)
  expect_lt(abs(coef(fit_masked, "mu")[["x"]] - sim$beta_x), 0.15)
  expect_lt(abs(coef(fit_masked, "sigma")[[1L]] - log(1 / sqrt(sim$phi))), 0.15)
  expect_lt(abs(fit_masked$sdpars$mu[["animal(1 | id)"]] - sim$sd_intercept), 0.18)
})

test_that("Student spatial mu intercept response mask has oracle and recovery evidence", {
  sim <- student_spatial_fixture(n_each = 40L, seed = 2026081802L)
  dat <- sim$data
  dat$y[seq(1L, nrow(dat), by = 40L)] <- NA_real_
  observed <- !is.na(dat$y)
  coords <- sim$coords
  formula <- bf(y ~ x + spatial(1 | id, coords = coords), sigma ~ 1)
  fit_masked <- drmTMB(
    formula, family = student(), data = dat,
    missing = miss_control(response = "include"), control = drm_control(se = FALSE)
  )
  fit_observed <- drmTMB(
    formula, family = student(), data = dat[observed, , drop = FALSE],
    control = drm_control(se = FALSE)
  )
  obj <- TMB::MakeADFun(
    data = fit_masked$model$tmb_data, parameters = fit_masked$model$start,
    map = fit_masked$model$map, DLL = "drmTMB", silent = TRUE
  )
  probe <- obj$par + seq(-0.04, 0.04, length.out = length(obj$par))
  par <- obj$env$parList(probe)

  expect_equal(fit_masked$opt$convergence, 0L)
  expect_equal(fit_observed$opt$convergence, 0L)
  expect_equal(nobs(fit_masked), sum(observed))
  expect_equal(fit_masked$missing_data$observed_y, observed)
  expect_equal(obj$fn(probe), student_structured_nll(fit_masked, par), tolerance = 1e-7)
  expect_equal(
    as.numeric(obj$gr(probe)), beta_animal_central_gradient(obj$fn, probe),
    tolerance = 5e-5
  )
  expect_missing_response_sentinel_invariant(fit_masked, sentinels = c(-2, 2))
  expect_equal(coef(fit_masked, "mu"), coef(fit_observed, "mu"), tolerance = 1e-6)
  expect_equal(coef(fit_masked, "sigma"), coef(fit_observed, "sigma"), tolerance = 1e-6)
  expect_equal(coef(fit_masked, "nu"), coef(fit_observed, "nu"), tolerance = 1e-6)
  expect_equal(fit_masked$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-6)
  expect_lt(abs(coef(fit_masked, "mu")[["x"]] - sim$beta_mu[["x"]]), 0.12)
  expect_lt(abs(coef(fit_masked, "sigma")[[1L]] - sim$beta_sigma), 0.12)
  expect_lt(abs(coef(fit_masked, "nu")[[1L]] - sim$beta_nu), 0.35)
  expect_lt(abs(fit_masked$sdpars$mu[["spatial(1 | id)"]] - sim$sd_intercept), 0.25)
})

test_that("Student spatial mu intercept-slope response mask has oracle and recovery evidence", {
  sim <- student_spatial_fixture(slope = TRUE, n_each = 48L, seed = 2026081803L)
  dat <- sim$data
  dat$y[seq(1L, nrow(dat), by = 48L)] <- NA_real_
  observed <- !is.na(dat$y)
  coords <- sim$coords
  formula <- bf(y ~ x + spatial(1 + x | id, coords = coords), sigma ~ 1)
  fit_masked <- drmTMB(
    formula, family = student(), data = dat,
    missing = miss_control(response = "include"), control = drm_control(se = FALSE)
  )
  fit_observed <- drmTMB(
    formula, family = student(), data = dat[observed, , drop = FALSE],
    control = drm_control(se = FALSE)
  )
  obj <- TMB::MakeADFun(
    data = fit_masked$model$tmb_data, parameters = fit_masked$model$start,
    map = fit_masked$model$map, DLL = "drmTMB", silent = TRUE
  )
  probe <- obj$par + seq(-0.04, 0.04, length.out = length(obj$par))
  par <- obj$env$parList(probe)

  expect_equal(fit_masked$opt$convergence, 0L)
  expect_equal(fit_observed$opt$convergence, 0L)
  expect_equal(nobs(fit_masked), sum(observed))
  expect_equal(fit_masked$missing_data$observed_y, observed)
  expect_equal(obj$fn(probe), student_structured_nll(fit_masked, par), tolerance = 1e-7)
  expect_equal(
    as.numeric(obj$gr(probe)), beta_animal_central_gradient(obj$fn, probe),
    tolerance = 5e-5
  )
  expect_missing_response_sentinel_invariant(fit_masked, sentinels = c(-2, 2))
  expect_equal(coef(fit_masked, "mu"), coef(fit_observed, "mu"), tolerance = 1e-6)
  expect_equal(coef(fit_masked, "sigma"), coef(fit_observed, "sigma"), tolerance = 1e-6)
  expect_equal(coef(fit_masked, "nu"), coef(fit_observed, "nu"), tolerance = 1e-6)
  expect_equal(fit_masked$sdpars$mu, fit_observed$sdpars$mu, tolerance = 1e-6)
  expect_lt(abs(coef(fit_masked, "mu")[["x"]] - sim$beta_mu[["x"]]), 0.15)
  expect_lt(abs(coef(fit_masked, "sigma")[[1L]] - sim$beta_sigma), 0.15)
  expect_lt(abs(coef(fit_masked, "nu")[[1L]] - sim$beta_nu), 0.40)
  expect_lt(abs(fit_masked$sdpars$mu[["spatial(1 | id)"]] - sim$sd_intercept), 0.28)
  expect_lt(abs(fit_masked$sdpars$mu[["spatial(0 + x | id)"]] - sim$sd_slope), 0.28)
})

test_that("Student phylo nu response mask has oracle and recovery evidence", {
  testthat::skip_if_not_installed("ape")
  sim <- student_phylo_nu_fixture()
  dat <- sim$data
  dat$y[seq(1L, nrow(dat), by = 200L)] <- NA_real_
  observed <- !is.na(dat$y)
  tree <- sim$tree
  formula <- bf(y ~ x, sigma ~ 1, nu ~ phylo(1 | id, tree = tree))
  fit_masked <- drmTMB(
    formula, family = student(), data = dat,
    missing = miss_control(response = "include"), control = drm_control(se = FALSE)
  )
  fit_observed <- drmTMB(
    formula, family = student(), data = dat[observed, , drop = FALSE],
    control = drm_control(se = FALSE)
  )
  obj <- TMB::MakeADFun(
    data = fit_masked$model$tmb_data, parameters = fit_masked$model$start,
    map = fit_masked$model$map, DLL = "drmTMB", silent = TRUE
  )
  probe <- obj$par + seq(-0.04, 0.04, length.out = length(obj$par))
  par <- obj$env$parList(probe)

  expect_equal(fit_masked$opt$convergence, 0L)
  expect_equal(fit_observed$opt$convergence, 0L)
  expect_equal(nobs(fit_masked), sum(observed))
  expect_equal(fit_masked$missing_data$observed_y, observed)
  expect_equal(obj$fn(probe), student_structured_nll(fit_masked, par), tolerance = 1e-7)
  expect_equal(
    as.numeric(obj$gr(probe)), beta_animal_central_gradient(obj$fn, probe),
    tolerance = 5e-5
  )
  expect_missing_response_sentinel_invariant(fit_masked, sentinels = c(-2, 2))
  expect_equal(coef(fit_masked, "mu"), coef(fit_observed, "mu"), tolerance = 1e-6)
  expect_equal(coef(fit_masked, "sigma"), coef(fit_observed, "sigma"), tolerance = 1e-6)
  expect_equal(coef(fit_masked, "nu"), coef(fit_observed, "nu"), tolerance = 1e-6)
  expect_equal(fit_masked$sdpars$nu, fit_observed$sdpars$nu, tolerance = 1e-6)
  expect_lt(abs(coef(fit_masked, "mu")[["x"]] - sim$beta_mu[["x"]]), 0.10)
  expect_lt(abs(coef(fit_masked, "sigma")[[1L]] - sim$beta_sigma), 0.10)
  expect_lt(abs(coef(fit_masked, "nu")[[1L]] - sim$beta_nu), 0.35)
  expect_lt(abs(fit_masked$sdpars$nu[["phylo(1 | id)"]] - sim$sd_nu), 0.30)
})
