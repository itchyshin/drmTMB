test_that("Bernoulli ordinary and phylogenetic SD targets fit together", {
  skip_on_cran()
  skip_if_not_installed("ape")

  set.seed(2026102021L)
  n_tip <- 48L
  n_id_per_tip <- 8L
  n_replicates <- 16L
  n_each <- n_id_per_tip * n_replicates
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("species_", seq_len(n_tip))
  K <- drmTMB:::drm_phylo_tip_covariance(tree)
  species_index <- rep(seq_len(n_tip), each = n_each)
  species <- factor(tree$tip.label[species_index], levels = tree$tip.label)
  id_index <- rep(seq_len(n_tip * n_id_per_tip), each = n_replicates)
  id <- factor(paste0("group_", id_index))
  w_group <- seq(-1, 1, length.out = n_tip * n_id_per_tip)
  z_tip <- as.numeric(scale(stats::rnorm(n_tip)))
  u <- stats::rnorm(length(w_group), sd = exp(-1.0 + 0.3 * w_group))
  v <- as.vector(t(chol(K)) %*% stats::rnorm(n_tip)) *
    exp(-0.8 + 0.45 * z_tip)
  x <- stats::rnorm(length(species))
  eta <- 0.1 + 0.3 * x + u[id_index] + v[species_index]
  dat <- data.frame(
    y = stats::rbinom(length(eta), 1L, stats::plogis(eta)),
    x, id, species, w = w_group[id_index], z = z_tip[species_index]
  )

  fit <- drmTMB(
    bf(
      y ~ x + (1 | id) + phylo(1 | species, tree = tree),
      sd(id) ~ w,
      sd(species, level = "phylogenetic") ~ z
    ),
    family = stats::binomial(), data = dat,
    control = drm_control(se = FALSE)
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, "sd(id)"), c("(Intercept)", "w"))
  expect_named(coef(fit, "sd_phylo(species)"), c("(Intercept)", "z"))
  expect_gt(coef(fit, "sd(id)")[["w"]], 0)
  expect_lt(abs(coef(fit, "sd(id)")[["w"]] - 0.3), 0.25)
  expect_gt(coef(fit, "sd_phylo(species)")[["z"]], 0)
  expect_lt(abs(coef(fit, "sd_phylo(species)")[["z"]] - 0.45), 0.25)
  expect_length(predict(fit, dpar = "sd(id)"), n_tip * n_id_per_tip)
  expect_length(predict(fit, dpar = "sd_phylo(species)"), n_tip)
  response_draws <- stats::simulate(fit, nsim = 2L, seed = 2026102022L)
  expect_equal(dim(response_draws), c(nrow(dat), 2L))
  expect_true(all(unlist(response_draws, use.names = FALSE) %in% c(0, 1)))

  path <- tempfile(fileext = ".rds")
  saveRDS(fit, path)
  stored <- readRDS(path)
  expect_equal(predict(stored, dpar = "sd(id)"),
               predict(fit, dpar = "sd(id)"))
  expect_equal(predict(stored, dpar = "sd_phylo(species)"),
               predict(fit, dpar = "sd_phylo(species)"))

  base_fit <- drmTMB(
    bf(y ~ x + (1 | id) + phylo(1 | species, tree = tree)),
    family = stats::binomial(), data = dat,
    control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(
      y ~ x + (1 | id) + phylo(1 | species, tree = tree),
      sd(id) ~ 1,
      sd(species, level = "phylogenetic") ~ 1
    ),
    family = stats::binomial(), data = dat,
    control = drm_control(se = FALSE)
  )
  expect_equal(base_fit$opt$convergence, 0L)
  expect_equal(constant_fit$opt$convergence, 0L)
  expect_equal(as.numeric(logLik(constant_fit)),
               as.numeric(logLik(base_fit)), tolerance = 2e-5)
  expect_equal(coef(constant_fit, "mu"), coef(base_fit, "mu"),
               tolerance = 1e-4)
})
