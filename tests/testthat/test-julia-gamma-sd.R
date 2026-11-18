test_that("public Julia Gamma SD outputs retain the fitted group target", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(1811)
  groups <- 40L
  repeats <- 12L
  id <- factor(rep(seq_len(groups), each = repeats))
  z_group <- rep(rep(c(-1, 1), each = groups / 2L), each = repeats)
  x <- rnorm(length(id))
  b <- exp(-0.55 + 0.35 * rep(c(-1, 1), each = groups / 2L)) *
    rnorm(groups)
  mu <- exp(0.25 + 0.2 * x + b[as.integer(id)])
  shape <- 1 / 0.35^2
  y <- rgamma(length(id), shape = shape, rate = shape / mu)
  dat <- data.frame(y, x, z = z_group, id)
  formula <- bf(y ~ x + (1 | id), sigma ~ 1,
                sd(id, coef = "(Intercept)") ~ z)

  fit_tmb <- drmTMB(
    formula, family = Gamma(link = "log"), data = dat, engine = "tmb"
  )
  sd_dpar <- grep("^sd\\(", names(fit_tmb$coefficients), value = TRUE)
  expect_length(sd_dpar, 1L)
  expect_named(coef(fit_tmb, dpar = sd_dpar), c("(Intercept)", "z"))
  expect_equal(sign(coef(fit_tmb, dpar = sd_dpar)[["z"]]), 1)
  expect_length(fit_tmb$sdpars[[sd_dpar]], groups)

  fit <- drmTMB(
    formula,
    family = Gamma(link = "log"), data = dat, engine = "julia"
  )

  expect_named(coef(fit, dpar = sd_dpar), c("(Intercept)", "z"))
  expect_equal(sign(coef(fit, dpar = sd_dpar)[["z"]]), 1)
  expect_equal(length(fit$sdpars[[sd_dpar]]), groups)
  expect_true(all(is.finite(fit$sdpars[[sd_dpar]])))
  expect_equal(
    unname(predict(fit, dpar = sd_dpar)),
    unname(fit$sdpars[[sd_dpar]]),
    tolerance = 1e-10
  )
  row_sd <- predict(fit, newdata = dat, dpar = sd_dpar)
  expect_length(row_sd, nrow(dat))
  expect_equal(unname(row_sd), unname(fit$sdpars[[sd_dpar]])[as.integer(id)])
  table <- predict_parameters(fit, dpar = sd_dpar, include_newdata = FALSE)
  expect_identical(unique(table$dpar), sd_dpar)
  expect_equal(nrow(table), groups)
  expect_setequal(table$row_label, levels(id))
  expect_setequal(names(fit$bridge$dpars), c("mu", "sigma"))

  path <- tempfile(fileext = ".rds")
  saveRDS(fit, path)
  restored <- readRDS(path)
  expect_equal(restored$sdpars[[sd_dpar]], fit$sdpars[[sd_dpar]])
})

test_that("Julia bridge fits a Gamma independent random-slope SD formula", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(2118)
  groups <- 80L
  repeats <- 25L
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_index)
  z_group <- rep(c(-1, 1), each = groups / 2L)
  z <- z_group[id_index]
  x <- rnorm(length(id_index))
  sd_group <- exp(-0.75 + 0.5 * z_group)
  slope <- sd_group * rnorm(groups)
  mu <- exp(0.4 + 0.3 * x + slope[id_index] * x)
  sigma <- 0.3
  shape <- 1 / sigma^2
  y <- rgamma(length(id_index), shape = shape, rate = shape / mu)
  dat <- data.frame(y, x, z, id)

  formula <- bf(y ~ x + (0 + x | id), sigma ~ 1,
                sd(id, coef = "x") ~ z)
  fit_tmb <- drmTMB(
    formula,
    family = Gamma(link = "log"), data = dat, engine = "tmb"
  )
  sd_dpar <- grep("^sd\\(", names(fit_tmb$coefficients), value = TRUE)
  expect_length(sd_dpar, 1L)
  expect_true(is_converged(fit_tmb))

  fit <- drmTMB(
    formula,
    family = Gamma(link = "log"), data = dat, engine = "julia"
  )

  expect_true(is_converged(fit))
  expect_named(coef(fit, dpar = sd_dpar), c("(Intercept)", "z"))
  expect_gt(coef(fit, dpar = sd_dpar)[['z']], 0)
  expect_lt(abs(coef(fit, dpar = sd_dpar)[['z']] - 0.5), 0.6)
  expect_equal(length(fit$sdpars[[sd_dpar]]), groups)
  expect_true(all(is.finite(fit$sdpars[[sd_dpar]])))
  expect_equal(
    unname(coef(fit, dpar = sd_dpar)),
    unname(coef(fit_tmb, dpar = sd_dpar)),
    tolerance = 0.2
  )
  row_sd <- predict(fit, newdata = dat, dpar = sd_dpar)
  expect_length(row_sd, nrow(dat))
  expect_equal(
    unname(row_sd),
    unname(fit$sdpars[[sd_dpar]])[as.integer(id)],
    tolerance = 1e-10
  )
  expect_setequal(names(fit$bridge$dpars), c("mu", "sigma"))
})

test_that("live Julia Gamma phylogenetic SD estimates agree with native TMB", {
  skip_if_not_installed("ape")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261027L)
  n_tip <- 24L
  n_each <- 16L
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("species_", seq_len(n_tip))
  tip_height <- max(ape::node.depth.edgelength(tree)[seq_len(n_tip)])
  tree$edge.length <- tree$edge.length / tip_height
  K <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_tip <- as.numeric(scale(stats::rnorm(n_tip)))
  names(z_tip) <- tree$tip.label
  alpha <- c(`(Intercept)` = log(0.45), z = 0.35)
  tau <- exp(alpha[[1L]] + alpha[[2L]] * z_tip)
  field <- as.vector(t(chol(K)) %*% stats::rnorm(n_tip))
  tip_index <- rep(seq_len(n_tip), each = n_each)
  x <- stats::rnorm(length(tip_index))
  mu <- exp(0.3 + 0.2 * x + tau[tip_index] * field[tip_index])
  sigma <- 0.4
  shape <- sigma^-2
  dat <- data.frame(
    y = stats::rgamma(length(mu), shape = shape, rate = shape / mu),
    x = x,
    species = factor(tree$tip.label[tip_index], levels = tree$tip.label),
    z = z_tip[tip_index]
  )
  form <- bf(
    y ~ x + phylo(1 | species, tree = tree),
    sigma ~ 1,
    sd(species, level = "phylogenetic") ~ z
  )

  fit_tmb <- drmTMB(
    form, family = Gamma(link = "log"), data = dat, engine = "tmb",
    control = drm_control(se = FALSE)
  )
  fit_julia <- drmTMB(
    form, family = Gamma(link = "log"), data = dat, engine = "julia"
  )
  dpar <- "sd_phylo(species)"
  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  expect_named(coef(fit_tmb, dpar), names(alpha))
  expect_named(coef(fit_julia, dpar), names(alpha))
  expect_equal(coef(fit_julia, dpar), coef(fit_tmb, dpar), tolerance = 0.15)
  expect_equal(
    unname(predict(fit_julia, dpar = dpar)),
    unname(predict(fit_tmb, dpar = dpar)),
    tolerance = 0.15
  )
})

test_that("Gamma animal SD coef labels use the fitted SD block", {
  ids <- c("animal_1", "animal_2")
  A <- matrix(c(1, 0.4, 0.4, 1), 2L, 2L,
              dimnames = list(ids, ids))
  dat <- data.frame(y = c(1, 2), x = c(-1, 1), id = factor(ids), z = c(-1, 1))
  form <- bf(
    y ~ x + animal(1 | id, A = A),
    sigma ~ 1,
    sd(id, level = "animal") ~ z
  )
  labels <- drm_julia_bridge_payload_coef_labels(
    form, dat, environment(), family_type = "gamma"
  )
  expect_true("sd" %in% names(labels))
  expect_false("resd" %in% names(labels))

  form_ambiguous <- bf(
    y ~ x + animal(1 + x | id, A = A),
    sigma ~ 1,
    sd(id, level = "animal") ~ z
  )
  labels_ambiguous <- drm_julia_bridge_payload_coef_labels(
    form_ambiguous, dat, environment(), family_type = "gamma"
  )
  expect_true("resd" %in% names(labels_ambiguous))
})

test_that("live Julia Gamma animal SD estimates agree with native TMB", {
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261028L)
  n_group <- 32L
  n_each <- 16L
  id_levels <- sprintf("animal_%02d", seq_len(n_group))
  A <- 0.5^abs(outer(seq_len(n_group), seq_len(n_group), "-"))
  dimnames(A) <- list(id_levels, id_levels)
  z_group <- rep(c(-1, 1), each = n_group / 2L)
  alpha <- c(`(Intercept)` = log(0.5), z = 0.4)
  sd_group <- exp(alpha[[1L]] + alpha[[2L]] * z_group)
  animal_index <- rep(seq_len(n_group), each = n_each)
  latent <- as.vector(t(chol(A)) %*% stats::rnorm(n_group)) * sd_group
  x <- stats::rnorm(length(animal_index))
  mu <- exp(0.25 + 0.2 * x + latent[animal_index])
  sigma <- 0.35
  shape <- sigma^-2
  dat <- data.frame(
    y = stats::rgamma(length(mu), shape = shape, rate = shape / mu),
    x = x,
    id = factor(id_levels[animal_index], levels = id_levels),
    z = z_group[animal_index]
  )
  form <- bf(
    y ~ x + animal(1 | id, A = A),
    sigma ~ 1,
    sd(id, level = "animal") ~ z
  )
  fit_tmb <- drmTMB(
    form, family = Gamma(link = "log"), data = dat, engine = "tmb",
    control = drm_control(se = FALSE)
  )
  fit_julia <- drmTMB(
    form, family = Gamma(link = "log"), data = dat, engine = "julia"
  )
  dpar <- "sd_animal(id)"
  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  expect_named(coef(fit_tmb, dpar), names(alpha))
  expect_named(coef(fit_julia, dpar), names(alpha))
  expect_equal(coef(fit_julia, dpar), coef(fit_tmb, dpar), tolerance = 0.2)
  expect_equal(
    unname(predict(fit_julia, dpar = dpar)),
    unname(predict(fit_tmb, dpar = dpar)),
    tolerance = 0.2
  )
})

test_that("live Julia Gamma animal slope SD estimates agree with native TMB", {
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261029L)
  n_group <- 40L
  n_each <- 16L
  id_levels <- sprintf("animal_%02d", seq_len(n_group))
  A <- 0.4^abs(outer(seq_len(n_group), seq_len(n_group), "-"))
  dimnames(A) <- list(id_levels, id_levels)
  z_group <- rep(c(-1, 1), each = n_group / 2L)
  alpha <- c(`(Intercept)` = log(0.55), z = 0.4)
  sd_group <- exp(alpha[[1L]] + alpha[[2L]] * z_group)
  animal_index <- rep(seq_len(n_group), each = n_each)
  animal_slope <- as.vector(t(chol(A)) %*% stats::rnorm(n_group)) * sd_group
  x <- rep(seq(-1.1, 1.1, length.out = n_each), times = n_group)
  mu <- exp(0.2 + 0.25 * x + animal_slope[animal_index] * x)
  sigma <- 0.35
  shape <- sigma^-2
  dat <- data.frame(
    y = stats::rgamma(length(mu), shape = shape, rate = shape / mu),
    x = x,
    id = factor(id_levels[animal_index], levels = id_levels),
    z = z_group[animal_index]
  )
  form <- bf(
    y ~ x + animal(0 + x | id, A = A),
    sigma ~ 1,
    sd(id, level = "animal") ~ z
  )
  fit_tmb <- drmTMB(
    form, family = Gamma(link = "log"), data = dat, engine = "tmb",
    control = drm_control(se = FALSE)
  )
  fit_julia <- drmTMB(
    form, family = Gamma(link = "log"), data = dat, engine = "julia"
  )

  dpar <- "sd_animal(id)"
  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  expect_named(coef(fit_tmb, dpar), names(alpha))
  expect_named(coef(fit_julia, dpar), names(alpha))
  expect_gt(coef(fit_tmb, dpar)[["z"]], 0)
  expect_gt(coef(fit_julia, dpar)[["z"]], 0)
  expect_equal(coef(fit_julia, dpar), coef(fit_tmb, dpar), tolerance = 0.25)
  expect_equal(
    as.numeric(logLik(fit_julia)), as.numeric(logLik(fit_tmb)),
    tolerance = 1e-3
  )
  expect_equal(
    unname(predict(fit_julia, dpar = dpar)),
    unname(predict(fit_tmb, dpar = dpar)),
    tolerance = 0.25
  )
  row_sd <- predict(fit_julia, newdata = dat, dpar = dpar)
  expect_length(row_sd, nrow(dat))
  expect_equal(
    unname(row_sd),
    unname(fit_julia$sdpars[[dpar]])[animal_index],
    tolerance = 1e-10
  )
})
