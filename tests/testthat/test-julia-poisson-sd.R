test_that("public Julia Poisson SD outputs retain the fitted group target", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(1810)
  groups <- 24L
  repeats <- 10L
  id <- factor(rep(seq_len(groups), each = repeats))
  z_group <- rep(rep(c(0, 1), each = groups / 2L), each = repeats)
  x <- rnorm(length(id))
  b <- exp(-0.45 + 0.4 * rep(c(0, 1), each = groups / 2L)) *
    rnorm(groups)
  y <- rpois(length(id), exp(0.55 + 0.25 * x + b[as.integer(id)]))
  dat <- data.frame(y, x, z = z_group, id)

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sd(id, coef = "(Intercept)") ~ z),
    family = stats::poisson(), data = dat, engine = "julia"
  )
  sd_dpar <- "sd(id, coef = \"(Intercept)\")"

  expect_named(coef(fit, dpar = sd_dpar), c("(Intercept)", "z"))
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
  expect_named(fit$bridge$dpars, "mu")
  expect_length(sigma(fit), 0L)

  params <- fitted_distribution_params(fit, newdata = NULL, dpars = "mu")
  expect_named(params, "mu")
  expect_equal(nrow(params), nrow(dat))
  distribution <- fitted_distribution(fit)
  expect_s3_class(distribution, "drm_fitted_distribution")
  expect_named(distribution$params, "mu")
})

test_that("native and Julia Poisson independent-slope SD fits agree on seeded data", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261019L)
  groups <- 48L
  repeats <- 24L
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_index)
  z_group <- rep(c(0, 1), each = groups / 2L)
  z <- z_group[id_index]
  x <- rnorm(length(id_index))
  alpha <- c(-0.45, 0.4)
  b <- exp(alpha[[1L]] + alpha[[2L]] * z_group) * rnorm(groups)
  y <- rpois(length(id_index), exp(0.55 + 0.25 * x + b[id_index] * x))
  dat <- data.frame(y, x, z, id)
  formula <- bf(y ~ x + (0 + x | id), sd(id, coef = "x") ~ z)

  fit_tmb <- drmTMB(
    formula, family = stats::poisson(), data = dat, engine = "tmb"
  )
  sd_dpar <- grep("^sd\\(", names(fit_tmb$coefficients), value = TRUE)
  expect_length(sd_dpar, 1L)
  fit_julia <- drmTMB(
    formula, family = stats::poisson(), data = dat, engine = "julia"
  )

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  expect_named(coef(fit_julia, dpar = sd_dpar), c("(Intercept)", "z"))
  expect_gt(coef(fit_julia, dpar = sd_dpar)[["z"]], 0)
  expect_equal(
    unname(coef(fit_julia, dpar = sd_dpar)),
    unname(coef(fit_tmb, dpar = sd_dpar)),
    tolerance = 0.25
  )
  expect_equal(length(fit_julia$sdpars[[sd_dpar]]), groups)
  row_sd <- predict(fit_julia, newdata = dat, dpar = sd_dpar)
  expect_equal(
    unname(row_sd),
    unname(fit_julia$sdpars[[sd_dpar]])[id_index],
    tolerance = 1e-10
  )
})

test_that("Julia Poisson phylogenetic SDs use the native tree scale", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  skip_if_not_installed("ape")
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261020L)
  n_tip <- 36L
  n_each <- 30L
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("species_", seq_len(n_tip))
  height <- max(ape::node.depth.edgelength(tree)[seq_len(n_tip)])
  tree$edge.length <- tree$edge.length / height * 2.5
  covariance <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_species <- as.numeric(scale(stats::rnorm(n_tip)))
  names(z_species) <- tree$tip.label
  alpha <- c(`(Intercept)` = log(0.35), z = 0.55)
  tau <- exp(alpha[[1L]] + alpha[[2L]] * z_species)
  unit_field <- as.vector(t(chol(covariance)) %*% stats::rnorm(n_tip))
  group <- rep(seq_len(n_tip), each = n_each)
  x <- stats::rnorm(length(group))
  eta <- 0.55 + 0.25 * x + tau[group] * unit_field[group]
  y <- stats::rpois(length(group), lambda = exp(eta))
  dat <- data.frame(
    y,
    x,
    species = factor(tree$tip.label[group], levels = tree$tip.label),
    z = z_species[group]
  )
  formula <- bf(
    y ~ x + phylo(1 | species, tree = tree),
    sd(species, level = "phylogenetic") ~ z
  )

  fit_tmb <- drmTMB(
    formula,
    family = stats::poisson(),
    data = dat,
    engine = "tmb",
    control = drm_control(se = FALSE)
  )
  fit_julia <- drmTMB(
    formula, family = stats::poisson(), data = dat, engine = "julia"
  )

  sd_dpar <- "sd_phylo(species)"
  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  expect_equal(
    unname(coef(fit_julia, sd_dpar)),
    unname(coef(fit_tmb, sd_dpar)),
    tolerance = 3e-4
  )
  expect_equal(
    unname(fit_julia$structured_sd_scales[["phylo(1 | species)"]]),
    sqrt(2.5),
    tolerance = 1e-8
  )
  expect_equal(
    as.numeric(logLik(fit_julia)),
    as.numeric(logLik(fit_tmb)),
    tolerance = 2e-5
  )

  tip_data <- data.frame(
    species = factor(tree$tip.label, levels = tree$tip.label),
    z = unname(z_species[tree$tip.label])
  )
  expected_sd <- exp(as.vector(
    stats::model.matrix(~ z, tip_data) %*% coef(fit_julia, sd_dpar)
  ))
  expect_equal(
    unname(predict(fit_julia, newdata = tip_data, dpar = sd_dpar)),
    expected_sd,
    tolerance = 1e-8
  )
  expect_equal(
    unname(fit_julia$sdpars[[sd_dpar]]),
    expected_sd,
    tolerance = 1e-8
  )
})
