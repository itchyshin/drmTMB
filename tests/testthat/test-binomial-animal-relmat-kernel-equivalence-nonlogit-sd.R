test_that("Binomial animal and relmat kernels agree under probit and cloglog", {
  skip_on_cran()

  set.seed(20261077L)
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
  Ainv <- solve(A)

  n_population <- 36L
  population_levels <- paste0("population_", seq_len(n_population))
  population_order <- rev(seq_len(n_population))
  K <- outer(population_order, population_order, function(i, j) 0.50^abs(i - j))
  dimnames(K) <- list(
    population_levels[population_order], population_levels[population_order]
  )
  Q <- solve(K)

  z_animal <- setNames(
    sample(rep(c(-1, 1), length.out = length(animal_levels))), animal_levels
  )
  z_population <- setNames(
    sample(rep(c(-1, 1), length.out = n_population)), population_levels
  )
  alpha_animal <- c(`(Intercept)` = log(0.35), z = 0.45)
  alpha_population <- c(`(Intercept)` = log(0.30), z = 0.55)
  animal_sd <- exp(alpha_animal[[1L]] + alpha_animal[[2L]] * z_animal)
  population_sd <- exp(
    alpha_population[[1L]] + alpha_population[[2L]] * z_population
  )
  animal_field_order <- as.vector(
    t(chol(A)) %*% stats::rnorm(length(animal_levels))
  ) * animal_sd[animal_levels[animal_order]]
  population_field_order <- as.vector(
    t(chol(K)) %*% stats::rnorm(n_population)
  ) * population_sd[population_levels[population_order]]
  names(animal_field_order) <- animal_levels[animal_order]
  names(population_field_order) <- population_levels[population_order]
  animal_field <- animal_field_order[animal_levels]
  population_field <- population_field_order[population_levels]

  design <- expand.grid(
    replicate = seq_len(2L),
    population_index = seq_len(n_population),
    animal_index = seq_along(animal_levels)
  )
  x <- stats::rnorm(nrow(design))
  eta <- -0.1 + 0.25 * x +
    animal_field[animal_levels[design$animal_index]] +
    population_field[population_levels[design$population_index]]
  dat <- data.frame(
    x = x,
    animal_id = factor(animal_levels[design$animal_index], levels = rev(animal_levels)),
    population = factor(
      population_levels[design$population_index], levels = population_levels
    ),
    z_animal = unname(z_animal[animal_levels[design$animal_index]]),
    z_population = unname(z_population[population_levels[design$population_index]])
  )

  fit_model <- function(y, link, animal_input, relmat_input) {
    link_data <- dat
    link_data$y <- y
    formula <- switch(
      animal_input,
      A = switch(
        relmat_input,
        K = bf(
          y ~ x + animal(1 | animal_id, A = A) + relmat(1 | population, K = K),
          sd(animal_id, level = "animal") ~ z_animal,
          sd(population, level = "relmat") ~ z_population
        ),
        Q = bf(
          y ~ x + animal(1 | animal_id, A = A) + relmat(1 | population, Q = Q),
          sd(animal_id, level = "animal") ~ z_animal,
          sd(population, level = "relmat") ~ z_population
        )
      ),
      Ainv = switch(
        relmat_input,
        K = bf(
          y ~ x + animal(1 | animal_id, Ainv = Ainv) + relmat(1 | population, K = K),
          sd(animal_id, level = "animal") ~ z_animal,
          sd(population, level = "relmat") ~ z_population
        ),
        Q = bf(
          y ~ x + animal(1 | animal_id, Ainv = Ainv) + relmat(1 | population, Q = Q),
          sd(animal_id, level = "animal") ~ z_animal,
          sd(population, level = "relmat") ~ z_population
        )
      ),
      pedigree = switch(
        relmat_input,
        K = bf(
          y ~ x + animal(1 | animal_id, pedigree = pedigree) +
            relmat(1 | population, K = K),
          sd(animal_id, level = "animal") ~ z_animal,
          sd(population, level = "relmat") ~ z_population
        ),
        Q = bf(
          y ~ x + animal(1 | animal_id, pedigree = pedigree) +
            relmat(1 | population, Q = Q),
          sd(animal_id, level = "animal") ~ z_animal,
          sd(population, level = "relmat") ~ z_population
        )
      )
    )
    drmTMB(
      formula, family = stats::binomial(link = link), data = link_data,
      control = drm_control(se = FALSE)
    )
  }

  inverse_link <- list(
    probit = stats::pnorm,
    cloglog = function(eta) -expm1(-exp(eta))
  )
  inputs <- expand.grid(
    animal = c("A", "Ainv", "pedigree"),
    relmat = c("K", "Q"),
    stringsAsFactors = FALSE
  )
  for (link in names(inverse_link)) {
    set.seed(20261078L + match(link, names(inverse_link)))
    y <- stats::rbinom(nrow(dat), 1L, inverse_link[[link]](eta))
    fits <- lapply(seq_len(nrow(inputs)), function(i) {
      fit_model(y, link, inputs$animal[[i]], inputs$relmat[[i]])
    })
    names(fits) <- paste(inputs$animal, inputs$relmat, sep = "+")
    reference <- fits[["A+K"]]

    for (fit in fits) {
      expect_identical(fit$opt$convergence, 0L, info = link)
    }
    for (fit in fits[names(fits) != "A+K"]) {
      expect_equal(as.numeric(logLik(fit)), as.numeric(logLik(reference)), tolerance = 1e-5)
      expect_equal(
        coef(fit, "sd_animal(animal_id)"),
        coef(reference, "sd_animal(animal_id)"), tolerance = 2e-4
      )
      expect_equal(
        coef(fit, "sd_relmat(population)"),
        coef(reference, "sd_relmat(population)"), tolerance = 2e-4
      )
      expect_equal(
        unname(predict(fit, dpar = "sd_animal(animal_id)")[animal_levels]),
        unname(predict(reference, dpar = "sd_animal(animal_id)")[animal_levels]),
        tolerance = 2e-4
      )
      expect_equal(
        unname(predict(fit, dpar = "sd_relmat(population)")[population_levels]),
        unname(predict(reference, dpar = "sd_relmat(population)")[population_levels]),
        tolerance = 2e-4
      )
    }
  }
})
