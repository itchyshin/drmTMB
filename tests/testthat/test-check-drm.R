check_drm_test_tree <- function() {
  structure(
    list(
      edge = matrix(
        c(
          5,
          6,
          5,
          7,
          6,
          1,
          6,
          2,
          7,
          3,
          7,
          4
        ),
        ncol = 2,
        byrow = TRUE
      ),
      edge.length = rep(1, 6),
      tip.label = paste0("sp_", 1:4),
      Nnode = 3L
    ),
    class = "phylo"
  )
}

check_drm_mu_sigma_cov_data <- function(
  n_id = 28,
  n_each = 6,
  sd_mu_id = 0.55,
  sd_sigma_id = 0.28,
  rho_mu_sigma = 0.4,
  seed = 2026051201
) {
  set.seed(seed)
  n <- n_id * n_each
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  u_mu <- stats::rnorm(n_id)
  u_sigma <- rho_mu_sigma * u_mu + sqrt(1 - rho_mu_sigma^2) * stats::rnorm(n_id)
  mu <- 0.2 + 0.45 * x + sd_mu_id * u_mu[id]
  sigma <- exp(log(0.55) + 0.18 * z + sd_sigma_id * u_sigma[id])

  data.frame(
    y = stats::rnorm(n, mean = mu, sd = sigma),
    x = x,
    z = z,
    id = id
  )
}

check_drm_two_mu_sigma_cov_data <- function(
  n_id = 14,
  n_site = 7,
  n_rep = 3,
  seed = 2026051207
) {
  set.seed(seed)
  dat <- expand.grid(
    id = factor(seq_len(n_id)),
    site = factor(seq_len(n_site)),
    rep = seq_len(n_rep)
  )
  n <- nrow(dat)
  dat$x <- stats::rnorm(n)
  dat$z <- stats::rnorm(n)
  id_mu <- stats::rnorm(n_id)
  id_sigma <- 0.45 * id_mu + sqrt(1 - 0.45^2) * stats::rnorm(n_id)
  site_mu <- stats::rnorm(n_site)
  site_sigma <- -0.35 * site_mu + sqrt(1 - 0.35^2) * stats::rnorm(n_site)
  id_index <- as.integer(dat$id)
  site_index <- as.integer(dat$site)
  mu <- 0.2 +
    0.45 * dat$x +
    0.50 * id_mu[id_index] +
    0.35 * site_mu[site_index]
  sigma <- exp(
    log(0.55) +
      0.18 * dat$z +
      0.30 * id_sigma[id_index] +
      0.24 * site_sigma[site_index]
  )
  dat$y <- stats::rnorm(n, mean = mu, sd = sigma)
  dat
}

check_drm_biv_phylo_data <- function(
  seed = 2026051305,
  n_each = 5L,
  rho_phylo = 0.25,
  rho12 = -0.10
) {
  set.seed(seed)
  tree <- check_drm_test_tree()
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  n_tip <- length(tree$tip.label)
  z1 <- stats::rnorm(n_tip)
  z2 <- rho_phylo * z1 + sqrt(1 - rho_phylo^2) * stats::rnorm(n_tip)
  phylo1 <- as.vector(t(chol(A)) %*% z1) * 0.45
  phylo2 <- as.vector(t(chol(A)) %*% z2) * 0.40
  names(phylo1) <- tree$tip.label
  names(phylo2) <- tree$tip.label

  species <- rep(tree$tip.label, each = n_each)
  x <- stats::rnorm(length(species))
  e1 <- stats::rnorm(length(species))
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(length(species))
  list(
    data = data.frame(
      y1 = 0.25 + 0.30 * x + phylo1[species] + 0.25 * e1,
      y2 = -0.15 - 0.25 * x + phylo2[species] + 0.30 * e2,
      x = x,
      species = species
    ),
    tree = tree
  )
}

check_drm_biv_sd_phylo_data <- function(seed = 2026051402, n_each = 5L) {
  set.seed(seed)
  tree <- check_drm_test_tree()
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  n_tip <- length(tree$tip.label)
  z_species <- stats::setNames(
    seq(-0.8, 0.8, length.out = n_tip),
    tree$tip.label
  )
  tau1 <- exp(-0.55 + 0.45 * z_species)
  tau2 <- exp(-0.65 - 0.35 * z_species)
  z1 <- stats::rnorm(n_tip)
  z2 <- 0.25 * z1 + sqrt(1 - 0.25^2) * stats::rnorm(n_tip)
  base1 <- as.vector(t(chol(A)) %*% z1)
  base2 <- as.vector(t(chol(A)) %*% z2)
  names(base1) <- tree$tip.label
  names(base2) <- tree$tip.label
  phylo1 <- tau1 * base1
  phylo2 <- tau2 * base2

  species <- rep(tree$tip.label, each = n_each)
  x <- stats::rnorm(length(species))
  e1 <- stats::rnorm(length(species))
  e2 <- 0.05 * e1 + sqrt(1 - 0.05^2) * stats::rnorm(length(species))
  list(
    data = data.frame(
      y1 = 0.25 + 0.30 * x + phylo1[species] + 0.22 * e1,
      y2 = -0.15 - 0.25 * x + phylo2[species] + 0.24 * e2,
      x = x,
      z_species = z_species[species],
      species = species
    ),
    tree = tree
  )
}

check_drm_sd_phylo_data <- function(seed = 2026051401, n_each = 4L) {
  set.seed(seed)
  tree <- check_drm_test_tree()
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  species_z <- stats::setNames(
    seq(-0.9, 0.9, length.out = length(tree$tip.label)),
    tree$tip.label
  )
  tau <- exp(-0.55 + 0.55 * species_z)
  base_effect <- as.vector(t(chol(A)) %*% stats::rnorm(length(tree$tip.label)))
  names(base_effect) <- tree$tip.label
  phylo_effect <- tau * base_effect
  species <- factor(
    rep(tree$tip.label, each = n_each),
    levels = tree$tip.label
  )
  x <- stats::rnorm(length(species))
  data <- data.frame(
    y = 0.25 +
      0.35 * x +
      phylo_effect[as.character(species)] +
      stats::rnorm(length(species), sd = 0.20),
    x = x,
    z_species = species_z[as.character(species)],
    species = species
  )

  list(data = data, tree = tree)
}

check_drm_spatial_data <- function(
  seed = 2026051436,
  n_site = 7L,
  n_each = 4L
) {
  set.seed(seed)
  site_levels <- paste0("site_", seq_len(n_site))
  theta <- seq(0, 1.5 * pi, length.out = n_site)
  coords <- data.frame(
    x = cos(theta) + seq_len(n_site) / (4 * n_site),
    y = sin(theta)
  )
  rownames(coords) <- site_levels

  precision <- drmTMB:::drm_spatial_coords_precision(
    coords,
    site = site_levels,
    group = "site"
  )
  covariance <- solve(as.matrix(precision$precision))
  spatial_effect <- as.vector(
    t(chol(covariance)) %*% stats::rnorm(n_site, sd = 0.35)
  )
  names(spatial_effect) <- site_levels

  site <- rep(site_levels, each = n_each)
  x <- stats::rnorm(length(site))
  data <- data.frame(
    y = 0.45 -
      0.2 * x +
      spatial_effect[site] +
      stats::rnorm(length(site), sd = 0.12),
    x = x,
    site = site
  )
  list(data = data, coords = coords)
}

check_drm_biv_q4_data <- function(
  n_id = 36L,
  n_each = 6L,
  seed = 2026051307
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  beta_mu1 <- c(0.10, 0.30)
  beta_mu2 <- c(-0.15, -0.25)
  log_sigma1 <- log(0.42)
  log_sigma2 <- log(0.50)
  rho12 <- 0.08
  sd <- c(0.48, 0.52, 0.26, 0.30)
  corr <- matrix(
    c(
      1.00,
      0.22,
      0.10,
      -0.06,
      0.22,
      1.00,
      0.08,
      0.14,
      0.10,
      0.08,
      1.00,
      0.18,
      -0.06,
      0.14,
      0.18,
      1.00
    ),
    nrow = 4L,
    byrow = TRUE
  )
  z <- matrix(stats::rnorm(n_id * 4L), n_id, 4L)
  b <- sweep(z %*% chol(corr), 2L, sd, `*`)
  e1 <- stats::rnorm(n)
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)

  dat <- data.frame(id = id, x = x)
  dat$y1 <- beta_mu1[[1L]] +
    beta_mu1[[2L]] * x +
    b[id, 1L] +
    exp(log_sigma1 + b[id, 3L]) * e1
  dat$y2 <- beta_mu2[[1L]] +
    beta_mu2[[2L]] * x +
    b[id, 2L] +
    exp(log_sigma2 + b[id, 4L]) * e2
  dat
}

check_drm_registry_singleton <- function(fit, dpar) {
  member_row <- which(
    fit$model$random$covariance_blocks$members$dpar == dpar
  )[[1L]]
  index <- fit$model$random$covariance_blocks$members$latent_index0[[
    member_row
  ]]
  first_group <- min(index[index >= 0L])
  singleton_rows <- which(index == first_group)[-1L]
  index[singleton_rows] <- first_group + 1L
  fit$model$random$covariance_blocks$members$latent_index0[[
    member_row
  ]] <- index
  fit
}

test_that("check_drm() reports core diagnostics for Gaussian fits", {
  set.seed(20260508)
  dat <- data.frame(
    y = stats::rnorm(80),
    x = stats::rnorm(80)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ x),
    family = gaussian(),
    data = dat
  )

  chk <- check_drm(fit)

  expect_s3_class(chk, "drm_check")
  expect_named(chk, c("check", "status", "value", "message"))
  expect_true(attr(chk, "ok"))
  expect_true(all(chk$status == "ok"))
  expect_true(all(
    c(
      "optimizer_convergence",
      "optimizer_budget",
      "finite_objective",
      "fixed_gradient",
      "hessian_positive_definite",
      "standard_errors_finite",
      "dropped_rows",
      "positive_scale"
    ) %in%
      chk$check
  ))
  printed <- NULL
  messages <- capture.output(
    printed <- capture.output(print(chk)),
    type = "message"
  )
  expect_match(paste(c(messages, printed), collapse = "\n"), "<drm_check")
})

test_that("check_drm() records dropped rows as notes", {
  dat <- data.frame(
    y = c(0.1, 0.3, NA, 0.5, 0.7, 0.9),
    x = c(-1, -0.5, 0, 0.5, NA, 1)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat
  )

  chk <- check_drm(fit)
  dropped <- chk[chk$check == "dropped_rows", ]

  expect_true(attr(chk, "ok"))
  expect_equal(dropped$status, "note")
  expect_match(dropped$value, "dropped=2")
})

test_that("check_drm() warns when residual rho12 is near a requested boundary", {
  set.seed(20260509)
  n <- 220
  dat <- data.frame(
    x = stats::rnorm(n),
    y1 = stats::rnorm(n)
  )
  dat$y2 <- 0.7 * dat$y1 + sqrt(1 - 0.7^2) * stats::rnorm(n)

  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~1),
    family = c(gaussian(), gaussian()),
    data = dat
  )
  chk <- check_drm(fit, rho_boundary = 0.2)
  rho_row <- chk[chk$check == "rho12_boundary", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(rho_row$status, "warning")
  expect_false(attr(chk, "ok"))
})

test_that("check_drm() reports Student-t nu diagnostics", {
  n <- 160
  x <- seq(-1, 1, length.out = n)
  z <- rep(c(-0.5, 0.5), length.out = n)
  nu_true <- 8
  dat <- data.frame(x = x, z = z)
  dat$y <- 0.2 +
    0.5 * x +
    exp(-0.4 + 0.2 * z) * stats::qt((seq_len(n) - 0.5) / n, df = nu_true)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ z, nu ~ 1),
    family = student(),
    data = dat
  )
  stable <- fit
  stable$coefficients$nu[[1L]] <- log(6)

  chk <- check_drm(stable)
  nu <- chk[chk$check == "student_nu", ]

  expect_equal(nu$status, "ok")
  expect_match(nu$value, "range=")
  expect_true(attr(chk, "ok"))

  near_boundary <- fit
  near_boundary$coefficients$nu[[1L]] <- log(0.01)
  chk_boundary <- check_drm(near_boundary)
  nu_boundary <- chk_boundary[chk_boundary$check == "student_nu", ]
  expect_equal(nu_boundary$status, "warning")
  expect_match(nu_boundary$message, "finite-variance boundary")
  expect_false(attr(chk_boundary, "ok"))

  nearly_gaussian <- fit
  nearly_gaussian$coefficients$nu[[1L]] <- log(200)
  chk_gaussian <- check_drm(nearly_gaussian)
  nu_gaussian <- chk_gaussian[chk_gaussian$check == "student_nu", ]
  expect_equal(nu_gaussian$status, "note")
  expect_match(nu_gaussian$message, "Gaussian")
  expect_true(attr(chk_gaussian, "ok"))

  invalid <- fit
  invalid$coefficients$nu[[1L]] <- Inf
  chk_invalid <- check_drm(invalid)
  nu_invalid <- chk_invalid[chk_invalid$check == "student_nu", ]
  expect_equal(nu_invalid$status, "error")
  expect_match(nu_invalid$message, "non-finite")
  expect_false(attr(chk_invalid, "ok"))
})

test_that("check_drm() reports predictor-varying Student-t nu ranges", {
  n <- 180
  x <- seq(-1, 1, length.out = n)
  dat <- data.frame(x = x)
  dat$y <- 0.3 + 0.4 * x + stats::qt((seq_len(n) - 0.5) / n, df = 10)
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, nu ~ x),
    family = student(),
    data = dat
  )
  fit$coefficients$nu[] <- c(log(6), 0.5)

  chk <- check_drm(fit)
  nu <- chk[chk$check == "student_nu", ]

  expect_equal(nu$status, "ok")
  expect_match(nu$value, "range=\\[[0-9.]+,[0-9.]+\\]")
  expect_true(attr(chk, "ok"))
})

test_that("check_drm() reports random-effect replication notes", {
  set.seed(20260510)
  dat <- data.frame(
    id = factor(c("a", "a", "b", "b", "c", "d", "d", "e", "e", "e")),
    x = stats::rnorm(10)
  )
  dat$y <- 0.2 +
    0.4 * dat$x +
    c(a = -0.2, b = 0.1, c = 0.3, d = -0.1, e = 0.2)[dat$id] +
    stats::rnorm(10, sd = 0.15)

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1),
    family = gaussian(),
    data = dat
  )
  chk <- check_drm(fit)
  replication <- chk[chk$check == "mu_random_effect_replication", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(replication$status, "note")
  expect_match(replication$message, "one fitted observation")

  near_boundary <- fit
  near_boundary$sdpars$mu[] <- 1e-8
  chk_boundary <- check_drm(near_boundary)
  sd_boundary <- chk_boundary[
    chk_boundary$check == "random_effect_sd_boundary",
  ]
  expect_equal(sd_boundary$status, "warning")
  expect_match(sd_boundary$value, "boundary=")
  expect_match(sd_boundary$message, "lower boundary")
  expect_false(attr(chk_boundary, "ok"))

  bad_sd <- fit
  bad_sd$sdpars$mu[] <- 0
  chk_bad_sd <- check_drm(bad_sd)
  bad_sd_boundary <- chk_bad_sd[
    chk_bad_sd$check == "random_effect_sd_boundary",
  ]
  expect_equal(bad_sd_boundary$status, "error")
  expect_match(bad_sd_boundary$message, "non-positive")
  expect_false(attr(chk_bad_sd, "ok"))
})

test_that("check_drm() reports weak random-slope design notes", {
  set.seed(20260511)
  id <- factor(rep(letters[1:8], each = 3))
  x <- rep(seq(-1, 1, length.out = 8), each = 3)
  dat <- data.frame(id = id, x = x)
  dat$y <- 0.3 +
    0.5 * dat$x +
    rep(stats::rnorm(8, sd = 0.2), each = 3) +
    stats::rnorm(nrow(dat), sd = 0.2)

  fit <- drmTMB(
    bf(y ~ x + (1 + x | id), sigma ~ 1),
    family = gaussian(),
    data = dat
  )
  chk <- check_drm(fit)
  design <- chk[chk$check == "mu_random_effect_design", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(design$status, "note")
  expect_match(design$message, "weak within-group design variation")
  expect_true(attr(chk, "ok"))
})

test_that("check_drm() records known sampling covariance summaries", {
  set.seed(20260512)
  n <- 24
  dat <- data.frame(x = stats::rnorm(n))
  V <- 0.015 * outer(seq_len(n), seq_len(n), function(i, j) 0.35^abs(i - j))
  dat$yi <- stats::rnorm(n)

  fit <- drmTMB(
    bf(yi ~ x + meta_V(V = V)),
    family = gaussian(),
    data = dat
  )
  chk <- check_drm(fit)
  known_v <- chk[chk$check == "known_sampling_covariance", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(known_v$status, "note")
  expect_match(known_v$value, "type=matrix")
  expect_match(known_v$value, "storage=dense")
  expect_match(known_v$value, "density=")
  expect_match(known_v$value, "size_mb=")
  expect_match(known_v$value, "rank=24")
  expect_match(known_v$message, "small-to-moderate")
  expect_match(known_v$message, "sparse or block-sparse")
  expect_true(attr(chk, "ok"))
})

test_that("check_drm() notes wide dense fixed-effect designs", {
  set.seed(20260510)
  n <- 90
  dat <- data.frame(
    y = stats::rnorm(n),
    habitat = factor(rep(paste0("hab_", seq_len(45)), each = 2))
  )

  fit <- drmTMB(
    bf(y ~ habitat, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 120, iter.max = 120)
  )
  chk <- check_drm(fit)
  design <- chk[chk$check == "fixed_effect_design_size", ]

  expect_equal(design$status, "note")
  expect_match(design$value, "max_cols=45")
  expect_match(design$value, "largest_density=")
  expect_match(design$message, "mostly zero")
  expect_match(design$message, "sparse fixed-effect matrices")
  expect_true(attr(chk, "ok"))
})

test_that("check_drm() records phylogenetic replication notes", {
  set.seed(20260513)
  tree <- check_drm_test_tree()
  dat <- data.frame(
    species = factor(c("sp_1", "sp_2", "sp_2", "sp_3", "sp_3", "sp_4", "sp_4")),
    x = c(-1, -0.5, 0.5, -0.2, 0.3, -0.1, 0.7)
  )
  dat$y <- 0.2 +
    0.4 * dat$x +
    c(sp_1 = -0.1, sp_2 = 0.2, sp_3 = 0.05, sp_4 = -0.2)[dat$species] +
    stats::rnorm(nrow(dat), sd = 0.15)

  fit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
    family = gaussian(),
    data = dat
  )
  chk <- check_drm(fit)
  phylo <- chk[chk$check == "phylo_mu_replication", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(phylo$status, "note")
  expect_match(phylo$value, "min_species_n=1")
  expect_true(attr(chk, "ok"))
})

test_that("check_drm() records spatial mu diagnostics separately from phylo", {
  sim <- check_drm_spatial_data()
  coords <- sim$coords

  fit <- drmTMB(
    bf(y ~ x + spatial(1 | site, coords = coords), sigma ~ 1),
    family = gaussian(),
    data = sim$data,
    control = list(eval.max = 500, iter.max = 500)
  )
  stable <- fit
  stable$sdpars$mu[["spatial(1 | site)"]] <- 0.35
  stable$coefficients$sigma[] <- log(0.12)
  chk <- check_drm(stable)
  spatial <- chk[chk$check == "spatial_mu_diagnostics", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(nrow(spatial), 1L)
  expect_equal(spatial$status, "ok")
  expect_match(spatial$value, "group=site")
  expect_match(spatial$value, "n_sites=7")
  expect_match(spatial$value, "min_site_n=4")
  expect_match(spatial$value, "coord_range=")
  expect_match(spatial$value, "spatial_sd=")
  expect_match(spatial$value, "sd_ratio=")
  expect_match(spatial$message, "coordinate spatial random intercept")
  expect_equal(nrow(chk[chk$check == "phylo_mu_replication", ]), 0L)
  expect_identical(attr(chk, "ok"), TRUE)

  singleton <- stable
  index <- singleton$model$structured$phylo_mu$observation_node_index
  first_index <- index[[1L]]
  first_rows <- which(index == first_index)
  recipient <- index[which(index != first_index)[[1L]]]
  singleton$model$structured$phylo_mu$observation_node_index[
    first_rows[-1L]
  ] <- recipient
  singleton_chk <- check_drm(singleton)
  singleton_spatial <- singleton_chk[
    singleton_chk$check == "spatial_mu_diagnostics",
  ]

  expect_equal(singleton_spatial$status, "note")
  expect_match(singleton_spatial$value, "min_site_n=1")
  expect_match(singleton_spatial$message, "fewer than two fitted observations")
  expect_identical(attr(singleton_chk, "ok"), TRUE)

  weak <- stable
  weak$sdpars$mu[["spatial(1 | site)"]] <- 1e-5
  weak_chk <- check_drm(weak)
  weak_spatial <- weak_chk[weak_chk$check == "spatial_mu_diagnostics", ]

  expect_equal(weak_spatial$status, "note")
  expect_match(weak_spatial$message, "tiny relative to the residual scale")

  bad <- stable
  bad$sdpars$mu[["spatial(1 | site)"]] <- NA_real_
  bad_chk <- check_drm(bad)
  bad_spatial <- bad_chk[bad_chk$check == "spatial_mu_diagnostics", ]

  expect_equal(bad_spatial$status, "error")
  expect_match(bad_spatial$message, "non-positive or non-finite")
  expect_identical(attr(bad_chk, "ok"), FALSE)
})

test_that("check_drm() records sd_phylo direct-SD diagnostics", {
  sim <- check_drm_sd_phylo_data()
  tree <- sim$tree
  fit <- drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree),
      sigma ~ 1,
      sd_phylo(species) ~ z_species
    ),
    family = gaussian(),
    data = sim$data,
    control = list(eval.max = 500, iter.max = 500)
  )
  chk <- check_drm(fit)
  direct_sd <- chk[chk$check == "phylo_direct_sd_model", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(nrow(direct_sd), 1L)
  expect_equal(direct_sd$status, "ok")
  expect_match(direct_sd$value, "dpar=sd_phylo\\(species\\)")
  expect_match(direct_sd$value, "group=species")
  expect_match(direct_sd$value, "min_species_n=4")
  expect_match(direct_sd$value, "sd_range=\\[")
  expect_match(direct_sd$value, "max_sd_ratio=")
  expect_match(direct_sd$message, "finite positive")

  singleton <- fit
  singleton$model$random_scale$phylo$observation_sd_row0 <- c(
    0L,
    rep.int(1L, 4L),
    rep.int(2L, 4L),
    rep.int(3L, length(sim$data$species) - 9L)
  )
  singleton$model$random_scale$phylo$observation_sd_row0_list[
    "sd_phylo(species)"
  ] <- list(singleton$model$random_scale$phylo$observation_sd_row0)
  singleton_chk <- check_drm(singleton)
  singleton_sd <- singleton_chk[
    singleton_chk$check == "phylo_direct_sd_model",
  ]

  expect_equal(singleton_sd$status, "note")
  expect_match(singleton_sd$value, "min_species_n=1")
  expect_match(singleton_sd$message, "recovery can be weak")

  bad_sd <- fit
  bad_sd$sdpars[["sd_phylo(species)"]][[1L]] <- NA_real_
  bad_chk <- check_drm(bad_sd)
  bad_direct_sd <- bad_chk[bad_chk$check == "phylo_direct_sd_model", ]

  expect_equal(bad_direct_sd$status, "error")
  expect_match(bad_direct_sd$message, "non-finite")
  expect_false(attr(bad_chk, "ok"))
})

test_that("check_drm() records bivariate sd_phylo direct-SD diagnostics", {
  sim <- check_drm_biv_sd_phylo_data()
  dat <- sim$data
  tree <- sim$tree
  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + phylo(1 | species, tree = tree),
      mu2 = y2 ~ x + phylo(1 | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1,
      sd_phylo1(species) ~ z_species,
      sd_phylo2(species) ~ z_species
    ),
    family = biv_gaussian(),
    data = dat,
    control = list(eval.max = 600, iter.max = 600)
  )
  chk <- check_drm(fit)
  direct_sd <- chk[chk$check == "phylo_direct_sd_model", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(nrow(direct_sd), 2L)
  expect_equal(direct_sd$status, c("ok", "ok"))
  expect_match(direct_sd$value[[1L]], "dpar=sd_phylo1\\(species\\)")
  expect_match(direct_sd$value[[1L]], "target=mu1")
  expect_match(direct_sd$value[[2L]], "dpar=sd_phylo2\\(species\\)")
  expect_match(direct_sd$value[[2L]], "target=mu2")
  expect_true(all(grepl("min_species_n=5", direct_sd$value, fixed = TRUE)))
  expect_true(all(grepl("sd_range=[", direct_sd$value, fixed = TRUE)))
  expect_true(all(grepl("max_sd_ratio=", direct_sd$value, fixed = TRUE)))
  expect_true(all(grepl("finite positive", direct_sd$message, fixed = TRUE)))
  expect_false(any(direct_sd$status %in% c("warning", "error")))

  one_sided <- drmTMB(
    bf(
      mu1 = y1 ~ x + phylo(1 | species, tree = tree),
      mu2 = y2 ~ x + phylo(1 | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1,
      sd_phylo1(species) ~ z_species
    ),
    family = biv_gaussian(),
    data = dat,
    control = list(eval.max = 600, iter.max = 600)
  )
  one_sided_sd <- check_drm(one_sided)
  one_sided_direct <- one_sided_sd[
    one_sided_sd$check == "phylo_direct_sd_model",
  ]

  expect_equal(one_sided$opt$convergence, 0)
  expect_equal(nrow(one_sided_direct), 1L)
  expect_match(one_sided_direct$value, "dpar=sd_phylo1\\(species\\)")
  expect_match(one_sided_direct$value, "target=mu1")
})

test_that("check_drm() reports bivariate phylogenetic covariance diagnostics", {
  sim <- check_drm_biv_phylo_data()
  dat <- sim$data
  tree <- sim$tree
  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + phylo(1 | species, tree = tree),
      mu2 = y2 ~ x + phylo(1 | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = list(eval.max = 300, iter.max = 300)
  )

  stable <- fit
  phylo_names <- paste0(c("mu1:", "mu2:"), fit$model$structured$phylo_mu$label)
  stable$sdpars$mu[phylo_names] <- c(0.45, 0.40)
  stable$corpars$phylo[] <- 0.25
  chk <- check_drm(stable)
  phylo <- chk[chk$check == "biv_phylo_mu_covariance", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(nrow(phylo), 1L)
  expect_equal(phylo$status, "ok")
  expect_match(phylo$value, "group=species")
  expect_match(phylo$value, "rho_abs=0.2500")
  expect_match(phylo$value, "n_species=4")
  expect_match(phylo$value, "min_species_n=5")
  expect_match(phylo$value, "min_sd_ratio=")
  expect_match(phylo$message, "non-negligible")

  near_boundary <- stable
  near_boundary$corpars$phylo[] <- 0.995
  near_boundary_chk <- check_drm(near_boundary, rho_boundary = 0.98)
  near_boundary_phylo <- near_boundary_chk[
    near_boundary_chk$check == "biv_phylo_mu_covariance",
  ]

  expect_equal(near_boundary_phylo$status, "warning")
  expect_match(near_boundary_phylo$value, "boundary=0.9800")
  expect_match(near_boundary_phylo$message, "close to \\+/-1")
  expect_false(attr(near_boundary_chk, "ok"))

  weak_sd <- stable
  weak_sd$sdpars$mu[phylo_names[[1L]]] <- 0.005
  weak_sd_chk <- check_drm(weak_sd)
  weak_sd_phylo <- weak_sd_chk[
    weak_sd_chk$check == "biv_phylo_mu_covariance",
  ]

  expect_equal(weak_sd_phylo$status, "note")
  expect_match(weak_sd_phylo$message, "tiny relative")
})

test_that("check_drm() notes ordinary species covariance beside phylogenetic covariance", {
  sim <- check_drm_biv_phylo_data(seed = 2026051306, n_each = 6L)
  dat <- sim$data
  tree <- sim$tree
  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x +
        (1 | species_residual | species) +
        phylo(1 | species, tree = tree),
      mu2 = y2 ~ x +
        (1 | species_residual | species) +
        phylo(1 | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 400, iter.max = 400)
    )
  )

  stable <- fit
  phylo_names <- paste0(c("mu1:", "mu2:"), fit$model$structured$phylo_mu$label)
  stable$sdpars$mu[phylo_names] <- c(0.45, 0.40)
  stable$corpars$phylo[] <- 0.25
  chk <- check_drm(stable)
  phylo <- chk[chk$check == "biv_phylo_mu_covariance", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(nrow(phylo), 1L)
  expect_equal(phylo$status, "note")
  expect_match(phylo$value, "same_group_covariance=true")
  expect_match(phylo$message, "ordinary group-level covariance")
  expect_match(phylo$message, "non-phylogenetic species correlations")
})

test_that("check_drm() reports univariate mu/sigma covariance diagnostics", {
  dat <- check_drm_mu_sigma_cov_data()
  fit <- drmTMB(
    bf(y ~ x + (1 | p | id), sigma ~ z + (1 | p | id)),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 250, iter.max = 250)
  )
  chk <- check_drm(fit)
  group_cov <- chk[chk$check == "mu_sigma_random_effect_covariance", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(group_cov$status, "ok")
  expect_match(group_cov$value, "term=\\(1 \\| p \\| id\\)")
  expect_match(group_cov$value, "n_groups=28")
  expect_match(group_cov$value, "min_group_n=6")
  expect_match(group_cov$message, "non-negligible")

  singleton <- check_drm_registry_singleton(fit, "sigma")
  singleton_chk <- check_drm(singleton)
  singleton_cov <- singleton_chk[
    singleton_chk$check == "mu_sigma_random_effect_covariance",
  ]

  expect_equal(singleton_cov$status, "note")
  expect_match(singleton_cov$value, "singleton_groups=1")
  expect_match(singleton_cov$message, "fewer than two")
  expect_true(attr(singleton_chk, "ok"))

  weak_sd <- fit
  weak_sd$sdpars$sigma[[1L]] <- 0.001
  weak_chk <- check_drm(weak_sd)
  weak_cov <- weak_chk[weak_chk$check == "mu_sigma_random_effect_covariance", ]

  expect_equal(weak_cov$status, "note")
  expect_match(weak_cov$message, "tiny")
  expect_true(attr(weak_chk, "ok"))
})

test_that("check_drm() reports each univariate mu/sigma covariance block", {
  dat <- check_drm_two_mu_sigma_cov_data()
  fit <- drmTMB(
    bf(
      y ~ x + (1 | p | id) + (1 | q | site),
      sigma ~ z + (1 | p | id) + (1 | q | site)
    ),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 500, iter.max = 500)
  )
  chk <- check_drm(fit)
  group_cov <- chk[chk$check == "mu_sigma_random_effect_covariance", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(nrow(group_cov), 2L)
  expect_match(group_cov$value[[1L]], "term=\\(1 \\| p \\| id\\)")
  expect_match(group_cov$value[[1L]], "n_groups=14")
  expect_match(group_cov$value[[2L]], "term=\\(1 \\| q \\| site\\)")
  expect_match(group_cov$value[[2L]], "n_groups=7")
  expect_false(any(grepl("complex", group_cov$message, fixed = TRUE)))
})

test_that("check_drm() reports bivariate mu random-effect covariance diagnostics", {
  set.seed(2026051102)
  n_id <- 20
  n_each <- 5
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  sigma1 <- 0.25
  sigma2 <- 0.3
  sd_mu1 <- 0.7
  sd_mu2 <- 0.8
  rho_group <- 0.35
  rho12 <- 0.15

  u1 <- stats::rnorm(n_id)
  u2 <- rho_group * u1 + sqrt(1 - rho_group^2) * stats::rnorm(n_id)
  e1 <- stats::rnorm(n)
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)
  dat <- data.frame(id = id, x = x)
  dat$y1 <- 0.2 + 0.45 * x + sd_mu1 * u1[id] + sigma1 * e1
  dat$y2 <- -0.1 - 0.3 * x + sd_mu2 * u2[id] + sigma2 * e2

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + (1 | p | id),
      mu2 = y2 ~ x + (1 | p | id),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = list(eval.max = 250, iter.max = 250)
  )
  chk <- check_drm(fit)
  group_cov <- chk[chk$check == "biv_mu_random_effect_covariance", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(group_cov$status, "ok")
  expect_match(group_cov$value, "n_groups=20")
  expect_match(group_cov$value, "min_group_n=5")
  expect_match(group_cov$message, "non-negligible")

  singleton <- check_drm_registry_singleton(fit, "mu1")
  singleton_chk <- check_drm(singleton)
  singleton_cov <- singleton_chk[
    singleton_chk$check == "biv_mu_random_effect_covariance",
  ]

  expect_equal(singleton_cov$status, "note")
  expect_match(singleton_cov$value, "singleton_groups=1")
  expect_match(singleton_cov$message, "fewer than two")
  expect_true(attr(singleton_chk, "ok"))

  weak_sd <- fit
  weak_sd$sdpars$mu[[1L]] <- mean(stats::sigma(fit)$sigma1) * 0.001
  weak_chk <- check_drm(weak_sd)
  weak_cov <- weak_chk[weak_chk$check == "biv_mu_random_effect_covariance", ]

  expect_equal(weak_cov$status, "note")
  expect_match(weak_cov$message, "tiny relative")
  expect_true(attr(weak_chk, "ok"))
})

test_that("check_drm() reports ordinary q4 bivariate covariance diagnostics", {
  dat <- check_drm_biv_q4_data()
  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + (1 | p | id),
      mu2 = y2 ~ x + (1 | p | id),
      sigma1 = ~ 1 + (1 | p | id),
      sigma2 = ~ 1 + (1 | p | id),
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = list(eval.max = 500, iter.max = 500)
  )
  chk <- check_drm(fit)
  q4 <- chk[chk$check == "biv_q4_random_effect_covariance", ]

  expect_equal(fit$opt$convergence, 0)
  expect_equal(nrow(q4), 1L)
  expect_match(q4$value, "n_blocks=1")
  expect_match(q4$value, "min_group_n=6")
  expect_match(q4$value, "max_abs_cor=")
  expect_match(q4$message, "Ordinary q4 location-scale covariance")

  near_boundary <- fit
  near_boundary$corpars$re_cov[] <- 0.995
  near_boundary_chk <- check_drm(near_boundary, rho_boundary = 0.98)
  near_boundary_q4 <- near_boundary_chk[
    near_boundary_chk$check == "biv_q4_random_effect_covariance",
  ]

  expect_equal(near_boundary_q4$status, "warning")
  expect_match(near_boundary_q4$value, "boundary=0.9800")
  expect_match(near_boundary_q4$message, "close to \\+/-1")
  expect_false(attr(near_boundary_chk, "ok"))

  weak_scale <- fit
  weak_scale$corpars$re_cov[] <- 0
  weak_scale$sdpars$sigma[] <- 0.01
  weak_scale_chk <- check_drm(weak_scale)
  weak_scale_q4 <- weak_scale_chk[
    weak_scale_chk$check == "biv_q4_random_effect_covariance",
  ]

  expect_equal(weak_scale_q4$status, "note")
  expect_match(weak_scale_q4$message, "log-sigma random-effect SD is tiny")
})

test_that("check_drm() reports mutated diagnostic failure branches", {
  dat <- data.frame(y = stats::rnorm(24), x = stats::rnorm(24))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  nonconverged <- fit
  nonconverged$opt$convergence <- 1L
  nonconverged$opt$message <- "test convergence failure"
  nonconverged$opt$iterations <- 10L
  nonconverged$opt$evaluations["function"] <- 10L
  nonconverged$control$optimizer <- list(iter.max = 10, eval.max = 10)
  convergence <- check_drm(nonconverged)
  convergence <- convergence[convergence$check == "optimizer_convergence", ]
  expect_equal(convergence$status, "warning")
  expect_match(convergence$message, "test convergence failure")

  budget <- check_drm(nonconverged)
  budget <- budget[budget$check == "optimizer_budget", ]
  expect_equal(budget$status, "warning")
  expect_match(budget$value, "iterations=10; function=10")
  expect_match(budget$message, "evaluation or iteration limit")

  converged_budget <- nonconverged
  converged_budget$opt$convergence <- 0L
  budget_note <- check_drm(converged_budget)
  budget_note <- budget_note[budget_note$check == "optimizer_budget", ]
  expect_equal(budget_note$status, "note")

  nonfinite <- fit
  nonfinite$opt$objective <- Inf
  objective <- check_drm(nonfinite)
  objective <- objective[objective$check == "finite_objective", ]
  expect_equal(objective$status, "error")

  large_gradient <- fit
  large_gradient$obj$gr <- function(par) {
    c(0, 0.02, 0)
  }
  gradient <- check_drm(large_gradient)
  gradient <- gradient[gradient$check == "fixed_gradient", ]
  expect_equal(gradient$status, "warning")
  expect_match(gradient$value, "max=")
  expect_match(gradient$value, "component=beta_mu\\[2\\]")
  expect_match(gradient$message, "largest component is beta_mu\\[2\\]")

  gradient_error <- fit
  gradient_error$obj$gr <- function(par) {
    stop("test gradient failure")
  }
  gradient <- check_drm(gradient_error)
  gradient <- gradient[gradient$check == "fixed_gradient", ]
  expect_equal(gradient$status, "warning")
  expect_match(gradient$message, "test gradient failure")

  bad_gradient <- fit
  bad_gradient$obj$gr <- function(par) {
    c(NA_real_, 0)
  }
  gradient <- check_drm(bad_gradient)
  gradient <- gradient[gradient$check == "fixed_gradient", ]
  expect_equal(gradient$status, "error")

  bad_hessian <- fit
  bad_hessian$sdr$pdHess <- FALSE
  hessian <- check_drm(bad_hessian)
  hessian <- hessian[hessian$check == "hessian_positive_definite", ]
  expect_equal(hessian$status, "warning")

  bad_se <- fit
  bad_se$sdr$cov.fixed[1, 1] <- Inf
  standard_errors <- check_drm(bad_se)
  standard_errors <- standard_errors[
    standard_errors$check == "standard_errors_finite",
  ]
  expect_equal(standard_errors$status, "warning")
  expect_match(standard_errors$message, "non-finite")

  bad_scale <- fit
  bad_scale$model$model_type <- "broken"
  scale <- check_drm(bad_scale)
  scale <- scale[scale$check == "positive_scale", ]
  expect_equal(scale$status, "warning")
})

test_that("check_drm() validates scalar diagnostic thresholds", {
  dat <- data.frame(y = stats::rnorm(20))
  fit <- drmTMB(bf(y ~ 1), family = gaussian(), data = dat)

  expect_error(check_drm(fit, gradient_tolerance = 0), "gradient_tolerance")
  expect_error(check_drm(fit, rho_boundary = 1), "rho_boundary")
  expect_error(check_drm(fit, sd_boundary = 0), "sd_boundary")
  expect_error(check_drm(fit, unknown_option = TRUE), "reserved")
})
