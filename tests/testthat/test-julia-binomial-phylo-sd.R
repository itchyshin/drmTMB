test_that("Julia phylogenetic SD targets reach public extraction and prediction", {
  tree <- structure(list(), class = "phylo")
  dat <- data.frame(
    y = c(0L, 1L, 0L, 1L, 1L, 0L),
    x = c(-1, 0, 1, -1, 0, 1),
    w = c(-1, -1, -1, 1, 1, 1),
    species = factor(rep(c("low", "high"), each = 3L),
                     levels = c("low", "high"))
  )
  form <- bf(
    y ~ x + phylo(1 | species, tree = tree),
    sd(species, level = "phylogenetic") ~ w
  )
  coefficients <- list(
    mu = c(`(Intercept)` = 0, x = 0.2),
    sd_phylo = c(`(Intercept)` = log(0.5), w = log(2))
  )
  expected <- c(log(0.5) - log(2), log(0.5) + log(2))
  names(expected) <- c("sd_phylo(species):low", "sd_phylo(species):high")

  object <- list(formula = form, data = dat, coefficients = coefficients)
  link <- drm_julia_predict_sd(
    object, "sd_phylo(species)", type = "link"
  )
  expect_named(link, names(expected))
  expect_equal(unname(link), unname(expected))
  expect_equal(
    drm_julia_sdpars(coefficients, form, dat)[["sd_phylo(species)"]],
    exp(expected)
  )

  public_object <- structure(
    list(
      formula = form,
      data = dat,
      coefficients = coefficients,
      model = list(model_type = "binomial")
    ),
    class = "drmTMB_julia"
  )
  expect_equal(coef(public_object, "sd_phylo(species)"), coefficients$sd_phylo)
  public_prediction <- predict(
    public_object, dpar = "sd_phylo(species)"
  )
  expect_named(public_prediction, c("low", "high"))
  expect_equal(unname(public_prediction), unname(exp(expected)))
  parameter_predictions <- predict_parameters(
    public_object,
    dpar = "sd_phylo(species)"
  )
  expect_identical(unique(parameter_predictions$dpar), "sd_phylo(species)")
  expect_equal(parameter_predictions$estimate, unname(exp(expected)))
  newdata <- dat[c(4L, 1L, 5L, 2L), , drop = FALSE]
  expect_equal(
    unname(predict(
      public_object, newdata = newdata, dpar = "sd_phylo(species)"
    )),
    c(exp(expected[[2L]]), exp(expected[[1L]]),
      exp(expected[[2L]]), exp(expected[[1L]]))
  )
  newdata_predictions <- predict_parameters(
    public_object,
    newdata = newdata,
    dpar = "sd_phylo(species)"
  )
  expect_equal(
    newdata_predictions$estimate,
    c(exp(expected[[2L]]), exp(expected[[1L]]),
      exp(expected[[2L]]), exp(expected[[1L]]))
  )
  expect_identical(as.character(newdata_predictions$species), as.character(newdata$species))
})

test_that("Julia phylogenetic SD regression uses the native tree scale", {
  dat <- data.frame(
    y = c(0L, 1L, 0L, 1L),
    x = c(-1, 1, -1, 1),
    w = c(-1, -1, 1, 1),
    species = factor(rep(c("low", "high"), each = 2L),
                     levels = c("low", "high"))
  )
  tree <- structure(list(), class = "phylo")
  form <- bf(
    y ~ x + phylo(1 | species, tree = tree),
    sd(species, level = "phylogenetic") ~ w
  )
  coef_names <- c(
    "mu_(Intercept)", "mu_x",
    "sd_phylo_(Intercept)", "sd_phylo_w"
  )
  raw_sd <- c(`(Intercept)` = log(0.5), w = log(2))
  tree_scale <- sqrt(2.5)
  fit <- new_drmTMB_julia(
    result = list(
      coef_names = coef_names,
      coefficients = c(0, 0.2, raw_sd),
      vcov = diag(4L),
      loglik = -4,
      aic = 16,
      bic = 18,
      df = 4L,
      nobs = nrow(dat),
      fitted = rep(0.5, nrow(dat)),
      residuals = rep(0, nrow(dat)),
      sigma = numeric(),
      corpairs = list(),
      converged = TRUE,
      opt = list(convergence = 0L)
    ),
    call = quote(drmTMB(form, data = dat, engine = "julia")),
    formula = form,
    family = stats::binomial(),
    data = dat,
    family_type = "binomial",
    structured_sd_scales = c("phylo(1 | species)" = tree_scale)
  )
  expected_sd_coef <- raw_sd
  expected_sd_coef[["(Intercept)"]] <-
    expected_sd_coef[["(Intercept)"]] + log(tree_scale)
  expect_equal(coef(fit, "sd_phylo(species)"), expected_sd_coef)

  expected <- exp(c(
    expected_sd_coef[["(Intercept)"]] - expected_sd_coef[["w"]],
    expected_sd_coef[["(Intercept)"]] + expected_sd_coef[["w"]]
  ))
  expect_equal(unname(fit$sdpars[["sd_phylo(species)"]]), expected)
  expect_equal(
    unname(predict(fit, dpar = "sd_phylo(species)")),
    expected
  )
  ci <- confint(fit, method = "wald")
  intercept_row <- ci$parm == "fixef:sd_phylo:(Intercept)"
  expect_true(any(intercept_row))
  expect_equal(
    mean(c(ci$lower[intercept_row], ci$upper[intercept_row])),
    expected_sd_coef[["(Intercept)"]]
  )

  target <- drm_julia_wald_targets(fit)
  target <- target[target$parm == "fixef:sd_phylo:(Intercept)", , drop = FALSE]
  raw_interval <- c(lower = raw_sd[["(Intercept)"]] - 0.2,
                    upper = raw_sd[["(Intercept)"]] + 0.2)
  profile_ci <- drm_julia_fixef_inference_confint_row(
    target = target,
    result = list(
      lower = raw_interval[["lower"]],
      upper = raw_interval[["upper"]],
      status = "ok",
      message = "",
      threaded = FALSE,
      worker_threads = 1L,
      julia_threads = 1L,
      blas_threads = 1L,
      elapsed = 0.01,
      used = 20L,
      failed = 0L
    ),
    level = 0.95,
    method = "profile",
    link_offset = log(tree_scale)
  )
  expect_equal(
    c(profile_ci$lower, profile_ci$upper),
    unname(raw_interval + log(tree_scale))
  )

  roundtrip_path <- tempfile(fileext = ".rds")
  saveRDS(fit, roundtrip_path)
  roundtrip_fit <- readRDS(roundtrip_path)
  unlink(roundtrip_path)
  expect_equal(
    coef(roundtrip_fit, "sd_phylo(species)"),
    expected_sd_coef
  )
  expect_equal(
    unname(predict(roundtrip_fit, dpar = "sd_phylo(species)")),
    expected
  )
  roundtrip_ci <- confint(roundtrip_fit, method = "wald")
  roundtrip_intercept <- roundtrip_ci$parm ==
    "fixef:sd_phylo:(Intercept)"
  expect_equal(
    c(roundtrip_ci$lower[roundtrip_intercept],
      roundtrip_ci$upper[roundtrip_intercept]),
    c(ci$lower[intercept_row], ci$upper[intercept_row])
  )

  no_intercept_form <- bf(
    y ~ x + phylo(1 | species, tree = tree),
    sd(species, level = "phylogenetic") ~ 0 + w
  )
  no_intercept_fit <- new_drmTMB_julia(
    result = list(
      coef_names = c("mu_(Intercept)", "mu_x", "sd_phylo_w"),
      coefficients = c(0, 0.2, raw_sd[["w"]]),
      vcov = diag(3L),
      loglik = -4,
      aic = 16,
      bic = 18,
      df = 3L,
      nobs = nrow(dat),
      fitted = rep(0.5, nrow(dat)),
      residuals = rep(0, nrow(dat)),
      sigma = numeric(),
      corpairs = list(),
      converged = TRUE,
      opt = list(convergence = 0L)
    ),
    call = quote(drmTMB(no_intercept_form, data = dat, engine = "julia")),
    formula = no_intercept_form,
    family = stats::binomial(),
    data = dat,
    family_type = "binomial",
    structured_sd_scales = c("phylo(1 | species)" = tree_scale)
  )
  expect_equal(
    unname(coef(no_intercept_fit, "sd_phylo(species)")),
    raw_sd[["w"]]
  )
  expect_equal(
    unname(predict(no_intercept_fit, dpar = "sd_phylo(species)")),
    exp(log(tree_scale) + raw_sd[["w"]] * c(-1, 1))
  )
  no_intercept_path <- tempfile(fileext = ".rds")
  saveRDS(no_intercept_fit, no_intercept_path)
  no_intercept_roundtrip <- readRDS(no_intercept_path)
  unlink(no_intercept_path)
  expect_equal(
    unname(coef(no_intercept_roundtrip, "sd_phylo(species)")),
    raw_sd[["w"]]
  )
  expect_equal(
    unname(predict(
      no_intercept_roundtrip, dpar = "sd_phylo(species)"
    )),
    exp(log(tree_scale) + raw_sd[["w"]] * c(-1, 1))
  )
})

test_that("the Julia bridge admits probit and cloglog phylogenetic SD regression", {
  tree <- structure(list(), class = "phylo")
  form <- bf(
    y ~ x + phylo(1 | species, tree = tree),
    sd(species, level = "phylogenetic") ~ z
  )

  for (link in c("probit", "cloglog")) {
    expect_true(
      drm_julia_binomial_sd_link_route_admitted(form, link = link),
      info = paste("The direct Julia", link,
                   "phylogenetic route must be reachable through the R bridge.")
    )
    expect_no_error(
      drm_julia_refuse_binomial_nonlogit_sd(
        form, stats::binomial(link = link)
      )
    )
  }
  expect_false(drm_julia_binomial_sd_link_route_admitted(form, link = "cauchit"))
  expect_error(
    drm_julia_bridge_family_type(stats::binomial(link = "cauchit")),
    "does not support binomial link"
  )

  ordinary_form <- bf(
    y ~ x + (1 | species),
    sd(species) ~ z
  )
  expect_no_error(
    drm_julia_refuse_binomial_nonlogit_sd(
      ordinary_form, stats::binomial(link = "cloglog")
    )
  )
})

test_that("the Julia bridge admits slope-only Binomial phylogenetic SD regression", {
  tree <- structure(
    list(
      edge = matrix(c(4, 1, 4, 5, 5, 2, 5, 3), ncol = 2L, byrow = TRUE),
      edge.length = c(2, 1, 1, 1),
      tip.label = c("a", "b", "c"),
      Nnode = 2L
    ),
    class = "phylo"
  )
  data <- data.frame(
    y = c(0L, 1L, 1L, 0L, 1L, 0L, 0L, 1L, 1L, 1L, 0L, 0L),
    x = rep(c(-1, 1, -1, 1), 3L),
    z = rep(c(-1, 0, 1), each = 4L),
    species = factor(rep(c("a", "b", "c"), each = 4L))
  )
  formula <- bf(
    y ~ x + phylo(0 + x | species, tree = tree),
    sd(species, level = "phylogenetic") ~ z
  )

  expect_true(
    drm_julia_binomial_sd_link_route_admitted(formula, data = data)
  )
  for (link in c("probit", "cloglog")) {
    expect_no_error(
      drm_julia_refuse_binomial_nonlogit_sd(
        formula, stats::binomial(link = link)
      )
    )
  }
  expect_no_error(
    drm_julia_refuse_marker_slope_unsupported(formula, "binomial")
  )

  payload <- drm_julia_phylo_payload(
    formula, "binomial", data, env = environment()
  )
  expect_identical(payload$locscale_mode, "phylo_slope")
  expect_identical(payload$group, "species")
  expect_named(payload$structured_sd_scales, "phylo(0 + x | species)")
  spec <- drm_julia_formula_spec(formula, phylo_payload = payload)
  expect_identical(spec$mu, "y ~ x + phylo(0 + x | species)")
  expect_identical(spec[["sd_phylo(species)"]], "sd_phylo(species) ~ z")

  intercept_plus_slope <- bf(
    y ~ x + phylo(1 + x | species, tree = tree),
    sd(species, level = "phylogenetic", coef = "(Intercept)") ~ z,
    sd(species, level = "phylogenetic", coef = "x") ~ z
  )
  expect_false(
    drm_julia_binomial_sd_link_route_admitted(
      intercept_plus_slope, data = data
    )
  )
})

test_that("live Julia phylogenetic Bernoulli SDs match TMB and the fitted design", {
  drm_skip_live_julia()
  skip_if_not_installed("ape")

  set.seed(20261019)
  n_tip <- 36L
  n_each <- 30L
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("species_", seq_len(n_tip))
  height <- max(ape::node.depth.edgelength(tree)[seq_len(n_tip)])
  tree$edge.length <- tree$edge.length / height * 2.5
  K <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_species <- as.numeric(scale(stats::rnorm(n_tip)))
  names(z_species) <- tree$tip.label
  alpha <- c(`(Intercept)` = log(0.35), z = 0.55)
  tau <- exp(alpha[[1L]] + alpha[[2L]] * z_species)
  unit_field <- as.vector(t(chol(K)) %*% stats::rnorm(n_tip))
  group <- rep(seq_len(n_tip), each = n_each)
  x <- stats::rnorm(length(group))
  eta <- 0.2 + 0.35 * x + tau[group] * unit_field[group]
  y <- stats::rbinom(length(group), size = 1L, prob = stats::plogis(eta))
  dat <- data.frame(
    y,
    x,
    species = factor(tree$tip.label[group], levels = tree$tip.label),
    z = z_species[group]
  )
  form <- bf(
    y ~ x + phylo(1 | species, tree = tree),
    sd(species, level = "phylogenetic") ~ z
  )

  fit_julia <- drmTMB(
    form, family = stats::binomial(), data = dat, engine = "julia"
  )
  fit_tmb <- drmTMB(
    form,
    family = stats::binomial(),
    data = dat,
    engine = "tmb",
    control = drm_control(se = FALSE)
  )
  coef_julia <- coef(fit_julia, "sd_phylo(species)")
  coef_tmb <- coef(fit_tmb, "sd_phylo(species)")
  tip_data <- data.frame(
    species = factor(tree$tip.label, levels = tree$tip.label),
    z = unname(z_species[tree$tip.label])
  )
  expected <- exp(as.vector(stats::model.matrix(~ z, tip_data) %*% coef_julia))
  predicted <- predict(
    fit_julia,
    newdata = tip_data,
    dpar = "sd_phylo(species)"
  )

  expect_true(is_converged(fit_julia))
  expect_true(is_converged(fit_tmb))
  expect_equal(coef_julia, coef_tmb, tolerance = 3e-4)
  expect_equal(
    unname(fit_julia$structured_sd_scales[["phylo(1 | species)"]]),
    sqrt(2.5),
    tolerance = 1e-8
  )
  expect_lt(abs(coef_julia[["z"]] - alpha[["z"]]), 0.5)
  expect_equal(
    as.numeric(logLik(fit_julia)),
    as.numeric(logLik(fit_tmb)),
    tolerance = 2e-5
  )
  expect_equal(unname(predicted), expected, tolerance = 1e-8)
  fitted_sd <- fit_julia$sdpars[["sd_phylo(species)"]]
  predicted_sd <- predict(fit_julia, dpar = "sd_phylo(species)")
  expect_setequal(
    names(fitted_sd),
    paste0("sd_phylo(species):", tree$tip.label)
  )
  expect_setequal(names(predicted_sd), tree$tip.label)
  expect_equal(unname(fitted_sd), unname(predicted_sd), tolerance = 1e-8)

  roundtrip_path <- tempfile(fileext = ".rds")
  on.exit(unlink(roundtrip_path), add = TRUE)
  saveRDS(fit_julia, roundtrip_path)
  fit_roundtrip <- readRDS(roundtrip_path)
  expect_equal(
    coef(fit_roundtrip, "sd_phylo(species)"),
    coef_julia,
    tolerance = 1e-12
  )
  expect_equal(
    predict(
      fit_roundtrip,
      newdata = tip_data,
      dpar = "sd_phylo(species)"
    ),
    predicted,
    tolerance = 1e-12
  )

  # Independent oracle: Brownian covariance on the native unit-height scale,
  # then group-specific marginal SD multipliers and Bernoulli responses.
  simulation_data <- fit_julia$data
  group_levels <- tree$tip.label
  tree_covariance <- ape::vcv.phylo(tree)
  tree_covariance <- tree_covariance[
    group_levels, group_levels, drop = FALSE
  ]
  unit_covariance <- tree_covariance / mean(diag(tree_covariance))
  simulation_seed <- 2026102301L
  set.seed(simulation_seed)
  latent_unit <- as.vector(
    t(chol(unit_covariance)) %*% stats::rnorm(length(group_levels))
  )
  group_index <- match(as.character(simulation_data$species), group_levels)
  fixed_eta <- predict(
    fit_julia,
    newdata = simulation_data,
    dpar = "mu",
    type = "link"
  )
  expected_simulation <- stats::rbinom(
    nrow(simulation_data),
    size = 1L,
    prob = stats::plogis(
      fixed_eta + predicted[group_index] * latent_unit[group_index]
    )
  )
  observed_simulation <- simulate(
    fit_julia,
    nsim = 1L,
    seed = simulation_seed
  )
  expect_equal(unname(observed_simulation$sim_1), expected_simulation)

  roundtrip_simulation <- simulate(
    fit_roundtrip,
    nsim = 1L,
    seed = simulation_seed
  )
  expect_equal(roundtrip_simulation, observed_simulation)
  expect_error(
    simulate(fit_julia, re.form = NULL),
    "Conditional simulation is unavailable"
  )
  missing_tree <- fit_julia
  missing_tree$bridge_payload$tree <- NULL
  expect_error(
    simulate(missing_tree),
    "does not retain the phylogenetic tree"
  )
})

test_that("live Julia probit phylogenetic Bernoulli SDs match TMB", {
  drm_skip_live_julia()
  skip_if_not_installed("ape")

  set.seed(202610251)
  n_tip <- 36L
  n_each <- 30L
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("probit_species_", seq_len(n_tip))
  height <- max(ape::node.depth.edgelength(tree)[seq_len(n_tip)])
  tree$edge.length <- tree$edge.length / height * 2.5
  covariance <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_species <- as.numeric(scale(stats::rnorm(n_tip)))
  names(z_species) <- tree$tip.label
  alpha <- c(`(Intercept)` = log(0.4), z = 0.5)
  tau <- exp(alpha[[1L]] + alpha[[2L]] * z_species)
  field <- as.vector(t(chol(covariance)) %*% stats::rnorm(n_tip))
  group <- rep(seq_len(n_tip), each = n_each)
  x <- stats::rnorm(length(group))
  eta <- 0.15 + 0.3 * x + tau[group] * field[group]
  y <- stats::rbinom(length(group), size = 1L, prob = stats::pnorm(eta))
  data <- data.frame(
    y,
    x,
    species = factor(tree$tip.label[group], levels = tree$tip.label),
    z = z_species[group]
  )
  form <- bf(
    y ~ x + phylo(1 | species, tree = tree),
    sd(species, level = "phylogenetic") ~ z
  )

  julia <- drmTMB(
    form, family = stats::binomial(link = "probit"),
    data = data, engine = "julia"
  )
  tmb <- drmTMB(
    form, family = stats::binomial(link = "probit"),
    data = data, engine = "tmb", control = drm_control(se = FALSE)
  )
  julia_sd <- coef(julia, "sd_phylo(species)")
  tmb_sd <- coef(tmb, "sd_phylo(species)")
  tip_data <- data.frame(
    species = factor(tree$tip.label, levels = tree$tip.label),
    z = unname(z_species[tree$tip.label])
  )

  expect_true(is_converged(julia))
  expect_true(is_converged(tmb))
  expect_equal(julia_sd, tmb_sd, tolerance = 5e-4)
  expect_gt(julia_sd[["z"]], 0)
  expect_lt(abs(julia_sd[["z"]] - alpha[["z"]]), 0.3)
  expect_equal(
    as.numeric(logLik(julia)), as.numeric(logLik(tmb)), tolerance = 5e-5
  )
  expect_equal(
    unname(predict(julia, newdata = tip_data, dpar = "sd_phylo(species)")),
    exp(as.vector(stats::model.matrix(~ z, tip_data) %*% julia_sd)),
    tolerance = 1e-8
  )
  reordered_tips <- tip_data[rev(seq_len(nrow(tip_data))), , drop = FALSE]
  expect_equal(
    unname(predict(
      julia, newdata = reordered_tips, dpar = "sd_phylo(species)"
    )),
    exp(as.vector(
      stats::model.matrix(~ z, reordered_tips) %*% julia_sd
    )),
    tolerance = 1e-8
  )

  slope_target <- "fixef:sd_phylo:z"
  expect_true(slope_target %in% profile_targets(julia)$parm)
  slope_profile <- confint(
    julia, parm = slope_target, method = "profile", level = 0.80
  )
  expect_equal(slope_profile$parm, slope_target)
  expect_equal(slope_profile$method, "profile")
  expect_true(is.finite(slope_profile$lower))
  expect_true(is.finite(slope_profile$upper))

  slope_bootstrap <- confint(
    julia,
    parm = slope_target,
    method = "bootstrap",
    R = 3L,
    seed = 20261026L,
    level = 0.80
  )
  expect_equal(slope_bootstrap$parm, slope_target)
  expect_equal(slope_bootstrap$method, "bootstrap")
  expect_equal(slope_bootstrap$conf.status, "bootstrap")
  expect_equal(
    slope_bootstrap$bootstrap.n + slope_bootstrap$bootstrap.failed,
    3L
  )
  expect_gte(slope_bootstrap$bootstrap.n, 1L)
  expect_true(is.finite(slope_bootstrap$lower))
  expect_true(is.finite(slope_bootstrap$upper))
})

test_that("live Julia cloglog phylogenetic Bernoulli SDs match TMB", {
  drm_skip_live_julia()
  skip_if_not_installed("ape")

  set.seed(202610261)
  n_tip <- 36L
  n_each <- 30L
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("cloglog_species_", seq_len(n_tip))
  height <- max(ape::node.depth.edgelength(tree)[seq_len(n_tip)])
  tree$edge.length <- tree$edge.length / height * 2.5
  covariance <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_species <- as.numeric(scale(stats::rnorm(n_tip)))
  names(z_species) <- tree$tip.label
  alpha <- c(`(Intercept)` = log(0.4), z = 0.5)
  tau <- exp(alpha[[1L]] + alpha[[2L]] * z_species)
  field <- as.vector(t(chol(covariance)) %*% stats::rnorm(n_tip))
  group <- rep(seq_len(n_tip), each = n_each)
  x <- stats::rnorm(length(group))
  eta <- 0.15 + 0.3 * x + tau[group] * field[group]
  y <- stats::rbinom(
    length(eta), size = 1L,
    prob = stats::binomial(link = "cloglog")$linkinv(eta)
  )
  data <- data.frame(
    y,
    x,
    species = factor(tree$tip.label[group], levels = tree$tip.label),
    z = z_species[group]
  )
  form <- bf(
    y ~ x + phylo(1 | species, tree = tree),
    sd(species, level = "phylogenetic") ~ z
  )

  julia <- drmTMB(
    form, family = stats::binomial(link = "cloglog"),
    data = data, engine = "julia"
  )
  tmb <- drmTMB(
    form, family = stats::binomial(link = "cloglog"),
    data = data, engine = "tmb", control = drm_control(se = FALSE)
  )
  julia_sd <- coef(julia, "sd_phylo(species)")
  tmb_sd <- coef(tmb, "sd_phylo(species)")
  tip_data <- data.frame(
    species = factor(tree$tip.label, levels = tree$tip.label),
    z = unname(z_species[tree$tip.label])
  )

  expect_true(is_converged(julia))
  expect_true(is_converged(tmb))
  expect_equal(julia_sd, tmb_sd, tolerance = 5e-4)
  expect_gt(julia_sd[["z"]], 0)
  expect_lt(abs(julia_sd[["z"]] - alpha[["z"]]), 0.3)
  expect_equal(
    as.numeric(logLik(julia)), as.numeric(logLik(tmb)), tolerance = 5e-5
  )
  expect_equal(
    unname(predict(julia, newdata = tip_data, dpar = "sd_phylo(species)")),
    exp(as.vector(stats::model.matrix(~ z, tip_data) %*% julia_sd)),
    tolerance = 1e-8
  )
})
