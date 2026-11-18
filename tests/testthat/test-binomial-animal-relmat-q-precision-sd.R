test_that("Binomial animal plus relatedness SDs agree for K and Q inputs", {
  skip_on_cran()

  set.seed(20261064L)
  n_animal <- 32L
  n_population <- 36L
  n_replicates <- 6L
  animal_levels <- paste0("animal_", seq_len(n_animal))
  population_levels <- paste0("population_", seq_len(n_population))
  animal_order <- rev(seq_len(n_animal))
  population_order <- rev(seq_len(n_population))
  A <- outer(animal_order, animal_order, function(i, j) 0.35^abs(i - j))
  K <- outer(population_order, population_order, function(i, j) 0.50^abs(i - j))
  dimnames(A) <- list(animal_levels[animal_order], animal_levels[animal_order])
  dimnames(K) <- list(population_levels[population_order], population_levels[population_order])
  Q <- solve(K)

  z_animal <- setNames(sample(rep(c(-1, 1), length.out = n_animal)), animal_levels)
  z_population <- setNames(
    sample(rep(c(-1, 1), length.out = n_population)), population_levels
  )
  alpha_animal <- c(`(Intercept)` = log(0.35), z_animal = 0.45)
  alpha_population <- c(`(Intercept)` = log(0.30), z_population = 0.55)
  animal_field_order <- as.vector(t(chol(A)) %*% stats::rnorm(n_animal)) *
    exp(alpha_animal[[1L]] + alpha_animal[[2L]] * z_animal[animal_levels[animal_order]])
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
    replicate = seq_len(n_replicates),
    population_index = seq_len(n_population),
    animal_index = seq_len(n_animal)
  )
  x <- stats::rnorm(nrow(design))
  eta <- -0.1 + 0.25 * x +
    animal_field[animal_levels[design$animal_index]] +
    population_field[population_levels[design$population_index]]
  dat <- data.frame(
    y = stats::rbinom(nrow(design), 1L, stats::plogis(eta)),
    x = x,
    animal_id = factor(animal_levels[design$animal_index], levels = animal_levels),
    population = factor(
      population_levels[design$population_index], levels = population_levels
    ),
    z_animal = unname(z_animal[animal_levels[design$animal_index]]),
    z_population = unname(z_population[population_levels[design$population_index]])
  )

  formula_k <- bf(
    y ~ x + animal(1 | animal_id, A = A) + relmat(1 | population, K = K),
    sd(animal_id, level = "animal") ~ z_animal,
    sd(population, level = "relmat") ~ z_population
  )
  formula_q <- bf(
    y ~ x + animal(1 | animal_id, A = A) + relmat(1 | population, Q = Q),
    sd(animal_id, level = "animal") ~ z_animal,
    sd(population, level = "relmat") ~ z_population
  )
  fit_k <- drmTMB(
    formula_k,
    family = stats::binomial(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  fit_q <- drmTMB(
    formula_q,
    family = stats::binomial(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_identical(fit_k$opt$convergence, 0L)
  expect_identical(fit_q$opt$convergence, 0L)
  expect_equal(as.numeric(logLik(fit_q)), as.numeric(logLik(fit_k)), tolerance = 1e-6)
  expect_equal(
    coef(fit_q, "sd_animal(animal_id)"),
    coef(fit_k, "sd_animal(animal_id)"), tolerance = 1e-5
  )
  expect_equal(
    coef(fit_q, "sd_relmat(population)"),
    coef(fit_k, "sd_relmat(population)"), tolerance = 1e-5
  )
  expect_equal(
    unname(predict(fit_q, dpar = "sd_animal(animal_id)")[animal_levels]),
    unname(predict(fit_k, dpar = "sd_animal(animal_id)")[animal_levels]),
    tolerance = 1e-5
  )
  expect_equal(
    unname(predict(fit_q, dpar = "sd_relmat(population)")[population_levels]),
    unname(predict(fit_k, dpar = "sd_relmat(population)")[population_levels]),
    tolerance = 1e-5
  )
  expect_setequal(
    names(predict(fit_q, dpar = "sd_relmat(population)")), population_levels
  )
})
