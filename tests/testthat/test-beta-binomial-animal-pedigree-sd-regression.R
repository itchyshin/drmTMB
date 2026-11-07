beta_binomial_animal_pedigree_sd_fixture <- function(
  seed = 20261020L,
  n_family = 20L,
  n_offspring = 6L,
  n_each = 10L,
  trials = 16L
) {
  set.seed(seed)
  sires <- sprintf("sire%02d", seq_len(n_family))
  dams <- sprintf("dam%02d", seq_len(n_family))
  offspring <- sprintf("offspring%03d", seq_len(n_family * n_offspring))
  pedigree <- data.frame(
    id = c(sires, dams, offspring),
    dam = c(rep(NA_character_, 2L * n_family), rep(dams, each = n_offspring)),
    sire = c(rep(NA_character_, 2L * n_family), rep(sires, each = n_offspring)),
    stringsAsFactors = FALSE
  )
  A <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  animal_levels <- rownames(A)
  z_animal <- setNames(
    rep(c(-0.5, 0.5), length.out = length(animal_levels)),
    animal_levels
  )
  alpha_sd <- c("(Intercept)" = log(0.3), z = 0.4)
  latent_unit <- drop(t(chol(A)) %*% stats::rnorm(length(animal_levels)))
  latent <- setNames(
    latent_unit * exp(alpha_sd[[1L]] + alpha_sd[[2L]] * z_animal),
    animal_levels
  )
  id_values <- rep(offspring, each = n_each)
  id <- factor(id_values, levels = rev(animal_levels))
  x <- rep(seq(-1, 1, length.out = n_each), length(offspring))
  z <- unname(z_animal[as.character(id)])
  eta <- -0.35 + 0.4 * x + latent[as.character(id)]
  probability <- stats::plogis(eta)
  successes <- stats::rbinom(length(id), size = trials, prob = probability)
  data <- data.frame(
    successes = successes,
    failures = trials - successes,
    x = x,
    id = id,
    z = z
  )
  list(
    data = data,
    pedigree = pedigree,
    A = A,
    alpha_sd = alpha_sd,
    z_animal = z_animal,
    observed_ids = offspring
  )
}

test_that("Beta-binomial animal intercepts support predictor-dependent SDs", {
  fx <- beta_binomial_animal_pedigree_sd_fixture()
  pedigree <- fx$pedigree
  fit <- drmTMB(
    bf(
      cbind(successes, failures) ~ x + animal(1 | id, pedigree = pedigree),
      sigma ~ 1,
      sd(id, level = "animal") ~ z
    ),
    family = beta_binomial(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, "sd_animal(id)"), c("(Intercept)", "z"))
  expect_lt(abs(coef(fit, "sd_animal(id)")[["z"]] - fx$alpha_sd[["z"]]), 0.3)
  sd_prediction <- predict(fit, dpar = "sd_animal(id)")
  expect_setequal(names(sd_prediction), fx$observed_ids)
  expected_sd <- exp(
    coef(fit, "sd_animal(id)")[["(Intercept)"]] +
      coef(fit, "sd_animal(id)")[["z"]] * fx$z_animal[names(sd_prediction)]
  )
  expect_equal(unname(sd_prediction), unname(expected_sd), tolerance = 1e-10)
  expect_true(any(fit$model$random_scale$phylo$node_sd_row0 < 0L))
  marginal_draws <- simulate(fit, nsim = 2L, seed = 20261021L)
  expect_equal(dim(marginal_draws), c(nrow(fx$data), 2L))
  expect_true(all(marginal_draws >= 0L))
  expect_true(all(marginal_draws <= 16L))

  base_fit <- drmTMB(
    bf(
      cbind(successes, failures) ~ x + animal(1 | id, pedigree = pedigree),
      sigma ~ 1
    ),
    family = beta_binomial(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(
      cbind(successes, failures) ~ x + animal(1 | id, pedigree = pedigree),
      sigma ~ 1,
      sd(id, level = "animal") ~ 1
    ),
    family = beta_binomial(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(constant_fit$logLik, base_fit$logLik, tolerance = 1e-6)
})

test_that("Beta-binomial animal SD predictors must be constant within animal", {
  fx <- beta_binomial_animal_pedigree_sd_fixture()
  pedigree <- fx$pedigree
  bad_data <- fx$data
  bad_data$z[[1L]] <- bad_data$z[[1L]] + 1

  expect_error(
    drmTMB(
      bf(
        cbind(successes, failures) ~ x +
          animal(1 | id, pedigree = pedigree),
        sigma ~ 1,
        sd(id, level = "animal") ~ z
      ),
      family = beta_binomial(),
      data = bad_data,
      control = drm_control(se = FALSE)
    ),
    "varies within"
  )
})

test_that("Beta-binomial animal SDs accept covariance and precision inputs", {
  fx <- beta_binomial_animal_pedigree_sd_fixture()
  pedigree <- fx$pedigree
  A_order <- rev(seq_len(nrow(fx$A)))
  A_provider <- fx$A[A_order, A_order, drop = FALSE]
  Ainv_provider <- solve(A_provider)

  fit_pedigree <- drmTMB(
    bf(
      cbind(successes, failures) ~ x +
        animal(1 | id, pedigree = pedigree),
      sigma ~ 1,
      sd(id, level = "animal") ~ z
    ),
    family = beta_binomial(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  fit_A <- drmTMB(
    bf(
      cbind(successes, failures) ~ x + animal(1 | id, A = A_provider),
      sigma ~ 1,
      sd(id, level = "animal") ~ z
    ),
    family = beta_binomial(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  fit_Ainv <- drmTMB(
    bf(
      cbind(successes, failures) ~ x + animal(1 | id, Ainv = Ainv_provider),
      sigma ~ 1,
      sd(id, level = "animal") ~ z
    ),
    family = beta_binomial(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )

  for (provider_fit in list(fit_A, fit_Ainv)) {
    expect_equal(provider_fit$opt$convergence, 0L)
    expect_equal(
      as.numeric(logLik(provider_fit)),
      as.numeric(logLik(fit_pedigree)),
      tolerance = 2e-5
    )
    expect_lt(
      abs(coef(provider_fit, "sd_animal(id)")[["z"]] - fx$alpha_sd[["z"]]),
      0.3
    )
    provider_sd <- predict(provider_fit, dpar = "sd_animal(id)")
    expect_setequal(names(provider_sd), fx$observed_ids)
    provider_expected_sd <- exp(
      coef(provider_fit, "sd_animal(id)")[["(Intercept)"]] +
        coef(provider_fit, "sd_animal(id)")[["z"]] *
          fx$z_animal[names(provider_sd)]
    )
    expect_equal(unname(provider_sd), unname(provider_expected_sd), tolerance = 1e-10)
  }
})
