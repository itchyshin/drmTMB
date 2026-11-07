test_that("Binomial phylo and animal SDs agree for A and A-inverse inputs", {
  skip_on_cran()
  skip_if_not_installed("ape")

  set.seed(20261067L)
  n_tip <- 30L
  n_animal <- 48L
  n_replicates <- 6L
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("species_", seq_len(n_tip))
  species_levels <- tree$tip.label
  animal_levels <- paste0("animal_", seq_len(n_animal))
  animal_order <- rev(seq_len(n_animal))
  A <- outer(animal_order, animal_order, function(i, j) 0.30^abs(i - j))
  dimnames(A) <- list(animal_levels[animal_order], animal_levels[animal_order])
  Ainv <- solve(A)

  phylo_cov <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_tree <- setNames(sample(rep(c(-1, 1), length.out = n_tip)), species_levels)
  z_animal <- setNames(sample(rep(c(-1, 1), length.out = n_animal)), animal_levels)
  alpha_tree <- c(`(Intercept)` = log(0.35), z_tree = 0.45)
  alpha_animal <- c(`(Intercept)` = log(0.30), z_animal = 0.55)
  tree_field <- as.vector(t(chol(phylo_cov)) %*% stats::rnorm(n_tip)) *
    exp(alpha_tree[[1L]] + alpha_tree[[2L]] * z_tree)
  names(tree_field) <- species_levels
  animal_field_order <- as.vector(t(chol(A)) %*% stats::rnorm(n_animal)) *
    exp(alpha_animal[[1L]] +
      alpha_animal[[2L]] * z_animal[animal_levels[animal_order]])
  names(animal_field_order) <- animal_levels[animal_order]
  animal_field <- animal_field_order[animal_levels]

  design <- expand.grid(
    replicate = seq_len(n_replicates),
    animal_index = seq_len(n_animal),
    tip_index = seq_len(n_tip)
  )
  x <- stats::rnorm(nrow(design))
  eta <- -0.1 + 0.25 * x +
    tree_field[species_levels[design$tip_index]] +
    animal_field[animal_levels[design$animal_index]]
  dat <- data.frame(
    y = stats::rbinom(nrow(design), 1L, stats::plogis(eta)),
    x = x,
    species = factor(species_levels[design$tip_index], levels = species_levels),
    animal_id = factor(animal_levels[design$animal_index], levels = rev(animal_levels)),
    z_tree = unname(z_tree[species_levels[design$tip_index]]),
    z_animal = unname(z_animal[animal_levels[design$animal_index]])
  )

  formula_a <- bf(
    y ~ x + phylo(1 | species, tree = tree) + animal(1 | animal_id, A = A),
    sd(species, level = "phylogenetic") ~ z_tree,
    sd(animal_id, level = "animal") ~ z_animal
  )
  formula_ainv <- bf(
    y ~ x + phylo(1 | species, tree = tree) + animal(1 | animal_id, Ainv = Ainv),
    sd(species, level = "phylogenetic") ~ z_tree,
    sd(animal_id, level = "animal") ~ z_animal
  )
  fit_a <- drmTMB(
    formula_a, family = stats::binomial(), data = dat,
    control = drm_control(se = FALSE)
  )
  fit_ainv <- drmTMB(
    formula_ainv, family = stats::binomial(), data = dat,
    control = drm_control(se = FALSE)
  )

  expect_identical(fit_a$opt$convergence, 0L)
  expect_identical(fit_ainv$opt$convergence, 0L)
  expect_equal(as.numeric(logLik(fit_ainv)), as.numeric(logLik(fit_a)), tolerance = 1e-6)
  expect_equal(
    coef(fit_ainv, "sd_phylo(species)"),
    coef(fit_a, "sd_phylo(species)"), tolerance = 1e-5
  )
  expect_equal(
    coef(fit_ainv, "sd_animal(animal_id)"),
    coef(fit_a, "sd_animal(animal_id)"), tolerance = 1e-5
  )
  expect_equal(
    unname(predict(fit_ainv, dpar = "sd_animal(animal_id)")[animal_levels]),
    unname(predict(fit_a, dpar = "sd_animal(animal_id)")[animal_levels]),
    tolerance = 1e-5
  )
  expect_setequal(
    names(predict(fit_ainv, dpar = "sd_phylo(species)")), species_levels
  )
})
