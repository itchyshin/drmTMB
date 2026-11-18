test_that("Binomial phylo and coordinate-spatial intercepts have separate SD regressions", {
  skip_on_cran()
  skip_if_not_installed("ape")

  set.seed(20261051L)
  n_tip <- 36L
  n_site <- 64L
  n_rep <- 4L
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("species_", seq_len(n_tip))
  species_levels <- tree$tip.label
  site_levels <- paste0("site_", seq_len(n_site))
  coords <- cbind(
    east = seq(0, 1, length.out = n_site),
    north = sin(seq(0, 2 * pi, length.out = n_site))
  )
  rownames(coords) <- site_levels

  phylo_cov <- drmTMB:::drm_phylo_tip_covariance(tree)
  spatial_precision <- drmTMB:::drm_spatial_coords_precision(
    coords, site = site_levels, group = "site"
  )
  spatial_cov <- solve(as.matrix(spatial_precision$precision))
  z_tree <- sample(rep(c(-1, 1), length.out = n_tip))
  z_site <- sample(rep(c(-1, 1), length.out = n_site))
  alpha_tree <- c(`(Intercept)` = log(0.35), z_tree = 0.45)
  alpha_site <- c(`(Intercept)` = log(0.30), z_site = 0.65)
  tau_tree <- exp(alpha_tree[[1L]] + alpha_tree[[2L]] * z_tree)
  tau_site <- exp(alpha_site[[1L]] + alpha_site[[2L]] * z_site)
  field_tree <- as.vector(
    t(chol(phylo_cov)) %*% stats::rnorm(n_tip)
  )
  field_site <- as.vector(
    t(chol(spatial_cov)) %*% stats::rnorm(n_site)
  )

  design <- expand.grid(
    replicate = seq_len(n_rep),
    site_index = seq_len(n_site),
    tip_index = seq_len(n_tip)
  )
  x <- stats::rnorm(nrow(design))
  eta <- -0.1 + 0.25 * x +
    tau_tree[design$tip_index] * field_tree[design$tip_index] +
    tau_site[design$site_index] * field_site[design$site_index]
  y <- stats::rbinom(nrow(design), 1L, stats::plogis(eta))
  dat <- data.frame(
    y = y,
    x = x,
    species = factor(species_levels[design$tip_index], levels = species_levels),
    site = factor(site_levels[design$site_index], levels = site_levels),
    z_tree = z_tree[design$tip_index],
    z_site = z_site[design$site_index]
  )

  fit <- drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree) +
        spatial(1 | site, coords = coords),
      sd(species, level = "phylogenetic") ~ z_tree,
      sd(site, level = "spatial") ~ z_site
    ),
    family = stats::binomial(link = "logit"),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_s3_class(fit, "drmTMB")
  expect_identical(fit$opt$convergence, 0L)
  tree_coef <- coef(fit, dpar = "sd_phylo(species)")
  site_coef <- coef(fit, dpar = "sd_spatial(site)")
  expect_equal(names(tree_coef), names(alpha_tree))
  expect_equal(names(site_coef), names(alpha_site))
  profile_rows <- profile_targets(fit)
  tree_profile <- profile_rows[grepl(
    "^fixef:sd_phylo\\(species\\):", profile_rows$parm
  ), , drop = FALSE]
  site_profile <- profile_rows[grepl(
    "^fixef:sd_spatial\\(site\\):", profile_rows$parm
  ), , drop = FALSE]
  expect_true(nrow(tree_profile) > 0L)
  expect_true(nrow(site_profile) > 0L)
  expect_true(all(tree_profile$tmb_parameter == "beta_sd_mu"))
  expect_true(all(site_profile$tmb_parameter == "beta_sd_mu"))
  expect_lt(max(tree_profile$index), min(site_profile$index))
  expect_lt(abs(unname(tree_coef[["z_tree"]]) - alpha_tree[["z_tree"]]), 0.45)
  expect_lt(abs(unname(site_coef[["z_site"]]) - alpha_site[["z_site"]]), 0.55)

  tree_rows <- dat[!duplicated(dat$species), , drop = FALSE]
  site_rows <- dat[!duplicated(dat$site), , drop = FALSE]
  expect_equal(
    unname(predict(fit, newdata = tree_rows, dpar = "sd_phylo(species)")),
    exp(as.vector(stats::model.matrix(~z_tree, tree_rows) %*% tree_coef)),
    tolerance = 1e-8
  )
  site_eta <- as.vector(stats::model.matrix(~z_site, site_rows) %*% site_coef)
  expected_site_sd <- drmTMB:::drm_exp_sd_logscale_guarded(
    drmTMB:::drm_softclamp_log_sd(site_eta, fit$model$tmb_data)
  )
  predicted_site_sd <- unname(predict(
    fit, newdata = site_rows, dpar = "sd_spatial(site)"
  ))
  expect_equal(predicted_site_sd, expected_site_sd, tolerance = 1e-8)
  expect_length(fit$sdpars[["sd_spatial(site)"]], n_site)
  expect_equal(
    unname(fit$sdpars[["sd_spatial(site)"]]),
    predicted_site_sd,
    tolerance = 1e-8
  )

  random_tree <- ranef(fit, "phylo_mu")$values
  random_site <- ranef(fit, "spatial_mu")$values
  expect_setequal(
    structured_effects(fit)$marker,
    c("phylo", "spatial")
  )
  eta_expected <- as.vector(stats::model.matrix(~x, dat) %*% coef(fit, "mu")) +
    unname(random_tree[match(as.character(dat$species), names(random_tree))]) +
    unname(random_site[match(as.character(dat$site), names(random_site))])
  expect_equal(
    unname(predict(fit, dpar = "mu", type = "link")),
    eta_expected,
    tolerance = 1e-8
  )

  simulated <- simulate(fit, nsim = 2L, seed = 20261052L)
  expect_true(all(unlist(simulated, use.names = FALSE) %in% 0:1))
  fresh <- drmTMB:::drm_structured_mu_random_effect_draws(fit)$mu
  primary_only <- drmTMB:::phylo_mu_primary_contribution(fit)
  expect_equal(length(fresh), nrow(dat))
  expect_false(isTRUE(all.equal(fresh, primary_only)))

  saved <- tempfile(fileext = ".rds")
  on.exit(unlink(saved), add = TRUE)
  saveRDS(fit, saved)
  reloaded <- readRDS(saved)
  expect_equal(
    coef(reloaded, dpar = "sd_spatial(site)"),
    site_coef
  )
  expect_equal(
    unname(predict(reloaded, newdata = site_rows, dpar = "sd_spatial(site)")),
    predicted_site_sd,
    tolerance = 1e-8
  )
})

test_that("Binomial phylo and coordinate-spatial SD regressions support probit and cloglog", {
  skip_on_cran()
  skip_if_not_installed("ape")

  for (link in c("probit", "cloglog")) {
    set.seed(if (link == "probit") 20261053L else 20261054L)
    n_tip <- 36L
    n_site <- 64L
    n_rep <- 4L
    tree <- ape::rcoal(n_tip)
    tree$tip.label <- paste0("species_", seq_len(n_tip))
    species_levels <- tree$tip.label
    site_levels <- paste0("site_", seq_len(n_site))
    coords <- cbind(
      east = seq(0, 1, length.out = n_site),
      north = sin(seq(0, 2 * pi, length.out = n_site))
    )
    rownames(coords) <- site_levels

    phylo_cov <- drmTMB:::drm_phylo_tip_covariance(tree)
    spatial_precision <- drmTMB:::drm_spatial_coords_precision(
      coords, site = site_levels, group = "site"
    )
    spatial_cov <- solve(as.matrix(spatial_precision$precision))
    z_tree <- sample(rep(c(-1, 1), length.out = n_tip))
    z_site <- sample(rep(c(-1, 1), length.out = n_site))
    alpha_tree <- c(`(Intercept)` = log(0.35), z_tree = 0.45)
    alpha_site <- c(`(Intercept)` = log(0.30), z_site = 0.65)
    tau_tree <- exp(alpha_tree[[1L]] + alpha_tree[[2L]] * z_tree)
    tau_site <- exp(alpha_site[[1L]] + alpha_site[[2L]] * z_site)
    field_tree <- as.vector(t(chol(phylo_cov)) %*% stats::rnorm(n_tip))
    field_site <- as.vector(t(chol(spatial_cov)) %*% stats::rnorm(n_site))

    design <- expand.grid(
      replicate = seq_len(n_rep),
      site_index = seq_len(n_site),
      tip_index = seq_len(n_tip)
    )
    x <- stats::rnorm(nrow(design))
    eta <- -0.1 + 0.25 * x +
      tau_tree[design$tip_index] * field_tree[design$tip_index] +
      tau_site[design$site_index] * field_site[design$site_index]
    probability <- if (link == "probit") {
      stats::pnorm(eta)
    } else {
      -expm1(-exp(eta))
    }
    y <- stats::rbinom(nrow(design), 1L, probability)
    dat <- data.frame(
      y = y,
      x = x,
      species = factor(species_levels[design$tip_index], levels = species_levels),
      site = factor(site_levels[design$site_index], levels = site_levels),
      z_tree = z_tree[design$tip_index],
      z_site = z_site[design$site_index]
    )

    fit <- drmTMB(
      bf(
        y ~ x + phylo(1 | species, tree = tree) +
          spatial(1 | site, coords = coords),
        sd(species, level = "phylogenetic") ~ z_tree,
        sd(site, level = "spatial") ~ z_site
      ),
      family = stats::binomial(link = link),
      data = dat,
      control = drm_control(se = FALSE)
    )

    expect_identical(fit$opt$convergence, 0L)
    expect_true(
      abs(unname(coef(fit, dpar = "sd_phylo(species)")["z_tree"]) - 0.45) <
        0.55,
      info = link
    )
    expect_true(
      abs(unname(coef(fit, dpar = "sd_spatial(site)")["z_site"]) - 0.65) <
        0.65,
      info = link
    )
    expect_length(fit$sdpars[["sd_phylo(species)"]], n_tip)
    expect_length(fit$sdpars[["sd_spatial(site)"]], n_site)
  }
})

test_that("Binomial animal and relatedness intercepts have separate SD regressions", {
  skip_on_cran()

  set.seed(20261055L)
  n_animal <- 32L
  n_pop <- 36L
  n_rep <- 6L
  animal_levels <- paste0("animal_", seq_len(n_animal))
  pop_levels <- paste0("population_", seq_len(n_pop))
  animal_order <- rev(seq_len(n_animal))
  pop_order <- rev(seq_len(n_pop))
  A <- outer(animal_order, animal_order, function(i, j) 0.35^abs(i - j))
  K <- outer(pop_order, pop_order, function(i, j) 0.50^abs(i - j))
  dimnames(A) <- list(animal_levels[animal_order], animal_levels[animal_order])
  dimnames(K) <- list(pop_levels[pop_order], pop_levels[pop_order])
  z_animal <- sample(rep(c(-1, 1), length.out = n_animal))
  z_pop <- sample(rep(c(-1, 1), length.out = n_pop))
  alpha_animal <- c(`(Intercept)` = log(0.35), z_animal = 0.45)
  alpha_relmat <- c(`(Intercept)` = log(0.30), z_pop = 0.55)
  sd_animal <- exp(alpha_animal[[1L]] + alpha_animal[[2L]] * z_animal)
  sd_pop <- exp(alpha_relmat[[1L]] + alpha_relmat[[2L]] * z_pop)
  effect_animal_order <- as.vector(t(chol(A)) %*% stats::rnorm(n_animal)) *
    sd_animal[animal_order]
  effect_pop_order <- as.vector(t(chol(K)) %*% stats::rnorm(n_pop)) *
    sd_pop[pop_order]
  names(effect_animal_order) <- animal_levels[animal_order]
  names(effect_pop_order) <- pop_levels[pop_order]
  effect_animal <- effect_animal_order[animal_levels]
  effect_pop <- effect_pop_order[pop_levels]

  design <- expand.grid(
    replicate = seq_len(n_rep),
    animal_index = seq_len(n_animal),
    pop_index = seq_len(n_pop)
  )
  x <- stats::rnorm(nrow(design))
  eta <- -0.1 + 0.25 * x +
    effect_animal[animal_levels[design$animal_index]] +
    effect_pop[pop_levels[design$pop_index]]
  dat <- data.frame(
    y = stats::rbinom(nrow(design), 1L, stats::plogis(eta)),
    x = x,
    animal_id = factor(animal_levels[design$animal_index], levels = animal_levels),
    population = factor(pop_levels[design$pop_index], levels = pop_levels),
    z_animal = z_animal[design$animal_index],
    z_pop = z_pop[design$pop_index]
  )

  fit <- drmTMB(
    bf(
      y ~ x + animal(1 | animal_id, A = A) + relmat(1 | population, K = K),
      sd(animal_id, level = "animal") ~ z_animal,
      sd(population, level = "relmat") ~ z_pop
    ),
    family = stats::binomial(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_identical(fit$opt$convergence, 0L)
  expect_lt(
    abs(unname(coef(fit, dpar = "sd_animal(animal_id)")["z_animal"]) - 0.45),
    0.55
  )
  expect_lt(
    abs(unname(coef(fit, dpar = "sd_relmat(population)")["z_pop"]) - 0.55),
    0.60
  )
  expect_length(fit$sdpars[["sd_animal(animal_id)"]], n_animal)
  expect_length(fit$sdpars[["sd_relmat(population)"]], n_pop)
  expect_named(
    coef(fit, dpar = "sd_animal(animal_id)"),
    c("(Intercept)", "z_animal")
  )
  expect_named(
    coef(fit, dpar = "sd_relmat(population)"),
    c("(Intercept)", "z_pop")
  )
  profile_rows <- profile_targets(fit)
  animal_profile <- profile_rows[grepl(
    "^fixef:sd_animal\\(animal_id\\):", profile_rows$parm
  ), , drop = FALSE]
  relmat_profile <- profile_rows[grepl(
    "^fixef:sd_relmat\\(population\\):", profile_rows$parm
  ), , drop = FALSE]
  expect_equal(nrow(animal_profile), 2L)
  expect_equal(nrow(relmat_profile), 2L)
  expect_true(all(animal_profile$tmb_parameter == "beta_sd_mu"))
  expect_true(all(relmat_profile$tmb_parameter == "beta_sd_mu"))
  expect_lt(max(animal_profile$index), min(relmat_profile$index))
  expect_setequal(
    names(predict(fit, dpar = "sd_animal(animal_id)")),
    levels(dat$animal_id)
  )
  expect_setequal(
    names(predict(fit, dpar = "sd_relmat(population)")),
    levels(dat$population)
  )
})

test_that("Binomial animal and coordinate-spatial intercepts have separate SD regressions", {
  skip_on_cran()

  set.seed(20261056L)
  n_animal <- 32L
  n_site <- 72L
  n_rep <- 6L
  animal_levels <- paste0("animal_", seq_len(n_animal))
  site_levels <- paste0("site_", seq_len(n_site))
  animal_order <- rev(seq_len(n_animal))
  A <- outer(animal_order, animal_order, function(i, j) 0.35^abs(i - j))
  dimnames(A) <- list(animal_levels[animal_order], animal_levels[animal_order])
  coords <- cbind(
    east = seq(0, 1, length.out = n_site),
    north = cos(seq(0, 2 * pi, length.out = n_site))
  )
  rownames(coords) <- site_levels
  spatial_precision <- drmTMB:::drm_spatial_coords_precision(
    coords, site = site_levels, group = "site"
  )
  spatial_cov <- solve(as.matrix(spatial_precision$precision))
  z_animal <- sample(rep(c(-1, 1), length.out = n_animal))
  z_site <- sample(rep(c(-1, 1), length.out = n_site))
  alpha_animal <- c(`(Intercept)` = log(0.35), z_animal = 0.45)
  alpha_spatial <- c(`(Intercept)` = log(0.30), z_site = 0.55)
  sd_animal <- exp(alpha_animal[[1L]] + alpha_animal[[2L]] * z_animal)
  sd_site <- exp(alpha_spatial[[1L]] + alpha_spatial[[2L]] * z_site)
  effect_animal_order <- as.vector(t(chol(A)) %*% stats::rnorm(n_animal)) *
    sd_animal[animal_order]
  effect_site <- as.vector(t(chol(spatial_cov)) %*% stats::rnorm(n_site)) *
    sd_site
  names(effect_animal_order) <- animal_levels[animal_order]
  names(effect_site) <- site_levels
  effect_animal <- effect_animal_order[animal_levels]

  design <- expand.grid(
    replicate = seq_len(n_rep),
    animal_index = seq_len(n_animal),
    site_index = seq_len(n_site)
  )
  x <- stats::rnorm(nrow(design))
  eta <- -0.1 + 0.25 * x +
    effect_animal[animal_levels[design$animal_index]] +
    effect_site[site_levels[design$site_index]]
  dat <- data.frame(
    y = stats::rbinom(nrow(design), 1L, stats::plogis(eta)),
    x = x,
    animal_id = factor(animal_levels[design$animal_index], levels = animal_levels),
    site = factor(site_levels[design$site_index], levels = site_levels),
    z_animal = z_animal[design$animal_index],
    z_site = z_site[design$site_index]
  )

  fit <- drmTMB(
    bf(
      y ~ x + animal(1 | animal_id, A = A) + spatial(1 | site, coords = coords),
      sd(animal_id, level = "animal") ~ z_animal,
      sd(site, level = "spatial") ~ z_site
    ),
    family = stats::binomial(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_identical(fit$opt$convergence, 0L)
  expect_true(
    abs(unname(coef(fit, dpar = "sd_animal(animal_id)")["z_animal"]) - 0.45) <
      0.55
  )
  expect_lt(
    abs(unname(coef(fit, dpar = "sd_spatial(site)")["z_site"]) - 0.55),
    0.60
  )
  expect_setequal(
    names(predict(fit, dpar = "sd_animal(animal_id)")),
    levels(dat$animal_id)
  )
  expect_setequal(
    names(predict(fit, dpar = "sd_spatial(site)")),
    levels(dat$site)
  )

  Ainv <- solve(A)
  fit_precision <- drmTMB(
    bf(
      y ~ x + animal(1 | animal_id, Ainv = Ainv) +
        spatial(1 | site, coords = coords),
      sd(animal_id, level = "animal") ~ z_animal,
      sd(site, level = "spatial") ~ z_site
    ),
    family = stats::binomial(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  expect_identical(fit_precision$opt$convergence, 0L)
  expect_equal(as.numeric(logLik(fit_precision)), as.numeric(logLik(fit)), tolerance = 1e-6)
  expect_equal(
    coef(fit_precision, dpar = "sd_animal(animal_id)"),
    coef(fit, dpar = "sd_animal(animal_id)"),
    tolerance = 1e-5
  )
  expect_equal(
    unname(predict(fit_precision, dpar = "sd_animal(animal_id)")),
    unname(predict(fit, dpar = "sd_animal(animal_id)")),
    tolerance = 1e-5
  )
})

test_that("Binomial pedigree and coordinate-spatial intercepts have separate SD regressions", {
  skip_on_cran()

  set.seed(20261057L)
  n_family <- 16L
  n_offspring <- 2L
  sires <- paste0("sire_", seq_len(n_family))
  dams <- paste0("dam_", seq_len(n_family))
  offspring <- paste0("offspring_", seq_len(n_family * n_offspring))
  pedigree <- data.frame(
    id = c(sires, dams, offspring),
    dam = c(rep(NA_character_, 2L * n_family),
      rep(dams, each = n_offspring)),
    sire = c(rep(NA_character_, 2L * n_family),
      rep(sires, each = n_offspring)),
    stringsAsFactors = FALSE
  )
  A <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  animal_levels <- rownames(A)
  animal_order <- rev(seq_along(animal_levels))
  animal_cov <- A[animal_order, animal_order, drop = FALSE]

  n_site <- 72L
  n_rep <- 4L
  site_levels <- paste0("site_", seq_len(n_site))
  coords <- cbind(
    east = seq(0, 1, length.out = n_site),
    north = cos(seq(0, 2 * pi, length.out = n_site))
  )
  rownames(coords) <- site_levels
  spatial_precision <- drmTMB:::drm_spatial_coords_precision(
    coords, site = site_levels, group = "site"
  )
  spatial_cov <- solve(as.matrix(spatial_precision$precision))

  z_animal <- setNames(sample(rep(c(-1, 1), length.out = length(animal_levels))),
    animal_levels)
  z_site <- setNames(sample(rep(c(-1, 1), length.out = n_site)), site_levels)
  alpha_animal <- c(`(Intercept)` = log(0.35), z_animal = 0.45)
  alpha_spatial <- c(`(Intercept)` = log(0.30), z_site = 0.55)
  animal_field_order <- as.vector(
    t(chol(animal_cov)) %*% stats::rnorm(length(animal_levels))
  ) * exp(alpha_animal[[1L]] + alpha_animal[[2L]] * z_animal[animal_levels[animal_order]])
  names(animal_field_order) <- animal_levels[animal_order]
  animal_field <- animal_field_order[animal_levels]
  spatial_field <- as.vector(
    t(chol(spatial_cov)) %*% stats::rnorm(n_site)
  ) * exp(alpha_spatial[[1L]] + alpha_spatial[[2L]] * z_site)
  names(spatial_field) <- site_levels

  design <- expand.grid(
    replicate = seq_len(n_rep),
    animal_index = seq_along(animal_levels),
    site_index = seq_len(n_site)
  )
  x <- stats::rnorm(nrow(design))
  eta <- -0.1 + 0.25 * x +
    animal_field[animal_levels[design$animal_index]] +
    spatial_field[site_levels[design$site_index]]
  dat <- data.frame(
    y = stats::rbinom(nrow(design), 1L, stats::plogis(eta)),
    x = x,
    animal_id = factor(animal_levels[design$animal_index], levels = rev(animal_levels)),
    site = factor(site_levels[design$site_index], levels = site_levels),
    z_animal = unname(z_animal[animal_levels[design$animal_index]]),
    z_site = unname(z_site[site_levels[design$site_index]])
  )

  fit <- drmTMB(
    bf(
      y ~ x + animal(1 | animal_id, pedigree = pedigree) +
        spatial(1 | site, coords = coords),
      sd(animal_id, level = "animal") ~ z_animal,
      sd(site, level = "spatial") ~ z_site
    ),
    family = stats::binomial(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_identical(fit$opt$convergence, 0L)
  expect_true(abs(coef(fit, "sd_animal(animal_id)")[["z_animal"]] - 0.45) < 0.55)
  expect_true(abs(coef(fit, "sd_spatial(site)")[["z_site"]] - 0.55) < 0.60)
  expect_setequal(names(predict(fit, dpar = "sd_animal(animal_id)")), animal_levels)
  expect_setequal(names(predict(fit, dpar = "sd_spatial(site)")), site_levels)
})
