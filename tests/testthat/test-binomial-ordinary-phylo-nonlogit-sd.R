test_that("Binomial ordinary and phylogenetic SDs fit probit and cloglog", {
  skip_on_cran()
  skip_if_not_installed("ape")

  set.seed(20261069L)
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
  id_levels <- paste0("group_", seq_len(n_tip * n_id_per_tip))
  id <- factor(id_levels[id_index], levels = id_levels)
  w_group <- seq(-1, 1, length.out = length(id_levels))
  z_tip <- as.numeric(scale(stats::rnorm(n_tip)))
  ordinary_effect <- stats::rnorm(
    length(w_group), sd = exp(-1.0 + 0.3 * w_group)
  )
  phylo_effect <- as.vector(t(chol(K)) %*% stats::rnorm(n_tip)) *
    exp(-0.8 + 0.45 * z_tip)
  x <- stats::rnorm(length(species))
  eta <- 0.1 + 0.3 * x + ordinary_effect[id_index] + phylo_effect[species_index]
  base_data <- data.frame(
    x = x,
    id = id,
    species = species,
    w = w_group[id_index],
    z = z_tip[species_index]
  )

  set.seed(20261070L)
  for (link in c("probit", "cloglog")) {
    family <- stats::binomial(link = link)
    dat <- base_data
    dat$y <- stats::rbinom(nrow(dat), 1L, family$linkinv(eta))
    fit <- drmTMB(
      bf(
        y ~ x + (1 | id) + phylo(1 | species, tree = tree),
        sd(id) ~ w,
        sd(species, level = "phylogenetic") ~ z
      ),
      family = family,
      data = dat,
      control = drm_control(se = FALSE)
    )

    expect_identical(fit$opt$convergence, 0L, info = link)
    expect_named(coef(fit, "sd(id)"), c("(Intercept)", "w"), info = link)
    expect_named(
      coef(fit, "sd_phylo(species)"), c("(Intercept)", "z"), info = link
    )
    expect_true(coef(fit, "sd(id)")[["w"]] > 0, info = link)
    expect_true(abs(coef(fit, "sd(id)")[["w"]] - 0.3) < 0.25, info = link)
    expect_true(coef(fit, "sd_phylo(species)")[["z"]] > 0, info = link)
    expect_true(
      abs(coef(fit, "sd_phylo(species)")[["z"]] - 0.45) < 0.25,
      info = link
    )
    expect_length(predict(fit, dpar = "sd(id)"), length(id_levels))
    expect_length(predict(fit, dpar = "sd_phylo(species)"), n_tip)
    expect_setequal(structured_effects(fit)$marker, c("phylo"))
  }
})
