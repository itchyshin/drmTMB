test_that("Binomial animal pedigree plus relmat SDs match A covariance", {
  skip_on_cran()

  set.seed(20261072L)
  n_family <- 8L
  n_offspring <- 5L
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

  n_population <- 32L
  population_levels <- paste0("population_", seq_len(n_population))
  population_order <- rev(seq_len(n_population))
  K <- outer(population_order, population_order, function(i, j) 0.45^abs(i - j))
  dimnames(K) <- list(
    population_levels[population_order], population_levels[population_order]
  )
  z_animal <- setNames(
    sample(rep(c(-1, 1), length.out = length(animal_levels))), animal_levels
  )
  z_population <- setNames(
    sample(rep(c(-1, 1), length.out = n_population)), population_levels
  )
  alpha_animal <- c(`(Intercept)` = log(0.35), z_animal = 0.45)
  alpha_population <- c(`(Intercept)` = log(0.30), z_population = 0.55)
  animal_field_order <- as.vector(
    t(chol(A)) %*% stats::rnorm(length(animal_levels))
  ) * exp(
    alpha_animal[[1L]] +
      alpha_animal[[2L]] * z_animal[animal_levels[animal_order]]
  )
  population_field_order <- as.vector(
    t(chol(K)) %*% stats::rnorm(n_population)
  ) * exp(
    alpha_population[[1L]] +
      alpha_population[[2L]] * z_population[population_levels[population_order]]
  )
  names(animal_field_order) <- animal_levels[animal_order]
  names(population_field_order) <- population_levels[population_order]
  animal_field <- animal_field_order[animal_levels]
  population_field <- population_field_order[population_levels]

  design <- expand.grid(
    replicate = seq_len(4L),
    population_index = seq_len(n_population),
    animal_index = seq_along(animal_levels)
  )
  x <- stats::rnorm(nrow(design))
  eta <- -0.1 + 0.25 * x +
    animal_field[animal_levels[design$animal_index]] +
    population_field[population_levels[design$population_index]]
  dat <- data.frame(
    y = stats::rbinom(nrow(design), 1L, stats::plogis(eta)),
    x = x,
    animal_id = factor(animal_levels[design$animal_index], levels = rev(animal_levels)),
    population = factor(
      population_levels[design$population_index], levels = rev(population_levels)
    ),
    z_animal = unname(z_animal[animal_levels[design$animal_index]]),
    z_population = unname(z_population[population_levels[design$population_index]])
  )

  fit_a <- drmTMB(
    bf(
      y ~ x + animal(1 | animal_id, A = A) + relmat(1 | population, K = K),
      sd(animal_id, level = "animal") ~ z_animal,
      sd(population, level = "relmat") ~ z_population
    ),
    family = stats::binomial(), data = dat,
    control = drm_control(se = FALSE)
  )
  fit_pedigree <- drmTMB(
    bf(
      y ~ x + animal(1 | animal_id, pedigree = pedigree) +
        relmat(1 | population, K = K),
      sd(animal_id, level = "animal") ~ z_animal,
      sd(population, level = "relmat") ~ z_population
    ),
    family = stats::binomial(), data = dat,
    control = drm_control(se = FALSE)
  )

  expect_identical(fit_a$opt$convergence, 0L)
  expect_identical(fit_pedigree$opt$convergence, 0L)
  expect_equal(as.numeric(logLik(fit_pedigree)), as.numeric(logLik(fit_a)), tolerance = 1e-5)
  expect_equal(
    coef(fit_pedigree, "sd_animal(animal_id)"),
    coef(fit_a, "sd_animal(animal_id)"), tolerance = 1e-4
  )
  expect_equal(
    coef(fit_pedigree, "sd_relmat(population)"),
    coef(fit_a, "sd_relmat(population)"), tolerance = 1e-4
  )
  expect_equal(
    unname(predict(fit_pedigree, dpar = "sd_animal(animal_id)")[animal_levels]),
    unname(predict(fit_a, dpar = "sd_animal(animal_id)")[animal_levels]),
    tolerance = 1e-4
  )
  expect_equal(
    unname(predict(fit_pedigree, dpar = "sd_relmat(population)")[population_levels]),
    unname(predict(fit_a, dpar = "sd_relmat(population)")[population_levels]),
    tolerance = 1e-4
  )
})
