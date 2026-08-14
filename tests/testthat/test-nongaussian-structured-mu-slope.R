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
  source(file.path("tools", "arc2-beta-animal-fixtures.R"), local = TRUE)
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
