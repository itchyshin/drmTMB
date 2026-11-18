test_that("Binomial phylo and animal SDs agree for A and pedigree inputs", {
  skip_on_cran()
  skip_if_not_installed("ape")

  set.seed(20261068L)
  n_family <- 10L
  n_offspring <- 4L
  sires <- paste0("sire_", seq_len(n_family))
  dams <- paste0("dam_", seq_len(n_family))
  offspring <- paste0("offspring_", seq_len(n_family * n_offspring))
  pedigree <- data.frame(
    id = c(sires, dams, offspring),
    dam = c(rep(NA_character_, 2L * n_family), rep(dams, each = n_offspring)),
    sire = c(rep(NA_character_, 2L * n_family), rep(sires, each = n_offspring)),
    stringsAsFactors = FALSE
  )
  A_base <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  animal_levels <- rownames(A_base)
  animal_order <- rev(seq_along(animal_levels))
  A <- A_base[animal_order, animal_order, drop = FALSE]
  tree <- ape::rcoal(20L)
  tree$tip.label <- paste0("species_", seq_len(20L))
  species_levels <- tree$tip.label
  phylo_cov <- drmTMB:::drm_phylo_tip_covariance(tree)

  z_animal <- setNames(
    sample(rep(c(-1, 1), length.out = length(animal_levels))), animal_levels
  )
  z_tree <- setNames(sample(rep(c(-1, 1), length.out = length(species_levels))), species_levels)
  alpha_animal <- c(`(Intercept)` = log(0.35), z_animal = 0.45)
  alpha_tree <- c(`(Intercept)` = log(0.30), z_tree = 0.55)
  animal_field_order <- as.vector(
    t(chol(A)) %*% stats::rnorm(length(animal_levels))
  ) * exp(
    alpha_animal[[1L]] +
      alpha_animal[[2L]] * z_animal[animal_levels[animal_order]]
  )
  names(animal_field_order) <- animal_levels[animal_order]
  animal_field <- animal_field_order[animal_levels]
  tree_field <- as.vector(t(chol(phylo_cov)) %*% stats::rnorm(length(species_levels))) *
    exp(alpha_tree[[1L]] + alpha_tree[[2L]] * z_tree)
  names(tree_field) <- species_levels

  design <- expand.grid(
    replicate = seq_len(4L),
    animal_index = seq_along(animal_levels),
    tip_index = seq_along(species_levels)
  )
  x <- stats::rnorm(nrow(design))
  eta <- -0.1 + 0.25 * x +
    animal_field[animal_levels[design$animal_index]] +
    tree_field[species_levels[design$tip_index]]
  dat <- data.frame(
    y = stats::rbinom(nrow(design), 1L, stats::plogis(eta)),
    x = x,
    animal_id = factor(animal_levels[design$animal_index], levels = rev(animal_levels)),
    species = factor(species_levels[design$tip_index], levels = species_levels),
    z_animal = unname(z_animal[animal_levels[design$animal_index]]),
    z_tree = unname(z_tree[species_levels[design$tip_index]])
  )

  formula_a <- bf(
    y ~ x + phylo(1 | species, tree = tree) + animal(1 | animal_id, A = A),
    sd(species, level = "phylogenetic") ~ z_tree,
    sd(animal_id, level = "animal") ~ z_animal
  )
  formula_pedigree <- bf(
    y ~ x + phylo(1 | species, tree = tree) +
      animal(1 | animal_id, pedigree = pedigree),
    sd(species, level = "phylogenetic") ~ z_tree,
    sd(animal_id, level = "animal") ~ z_animal
  )
  fit_a <- drmTMB(
    formula_a, family = stats::binomial(), data = dat,
    control = drm_control(se = FALSE)
  )
  fit_pedigree <- drmTMB(
    formula_pedigree, family = stats::binomial(), data = dat,
    control = drm_control(se = FALSE)
  )

  expect_identical(fit_a$opt$convergence, 0L)
  expect_identical(fit_pedigree$opt$convergence, 0L)
  expect_equal(
    as.numeric(logLik(fit_pedigree)), as.numeric(logLik(fit_a)), tolerance = 1e-5
  )
  expect_equal(
    coef(fit_pedigree, "sd_animal(animal_id)"),
    coef(fit_a, "sd_animal(animal_id)"), tolerance = 1e-4
  )
  expect_equal(
    coef(fit_pedigree, "sd_phylo(species)"),
    coef(fit_a, "sd_phylo(species)"), tolerance = 1e-4
  )
  expect_equal(
    unname(predict(fit_pedigree, dpar = "sd_animal(animal_id)")[animal_levels]),
    unname(predict(fit_a, dpar = "sd_animal(animal_id)")[animal_levels]),
    tolerance = 1e-4
  )
  expect_setequal(
    names(predict(fit_pedigree, dpar = "sd_phylo(species)")), species_levels
  )
})
