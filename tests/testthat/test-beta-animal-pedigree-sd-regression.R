beta_animal_pedigree_sd_fixture <- function(
  seed = 20261020L,
  n_family = 20L,
  n_offspring = 6L,
  n_each = 16L
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
  id_levels <- rownames(A)
  z_id <- setNames(rep(c(-0.5, 0.5), length.out = length(id_levels)), id_levels)
  alpha_sd <- c("(Intercept)" = log(0.35), z = 0.35)
  latent_unit <- as.vector(t(chol(A)) %*% stats::rnorm(length(id_levels)))
  latent <- setNames(
    latent_unit * exp(alpha_sd[[1L]] + alpha_sd[[2L]] * z_id[id_levels]),
    id_levels
  )
  data_id <- offspring
  id <- factor(rep(data_id, each = n_each), levels = rev(id_levels))
  z <- unname(z_id[as.character(id)])
  x <- rep(seq(-1, 1, length.out = n_each), length(data_id))
  eta <- -0.25 + 0.3 * x + latent[as.character(id)]
  mu <- stats::plogis(eta)
  sigma <- 0.25
  phi <- 1 / sigma^2
  data <- data.frame(
    y = stats::rbeta(length(mu), mu * phi, (1 - mu) * phi),
    id,
    x,
    z
  )
  list(
    data = data, pedigree = pedigree, A = A, alpha_sd = alpha_sd,
    z_id = z_id, observed_ids = offspring
  )
}

test_that("Beta animal intercepts support predictor-dependent SDs with pedigree", {
  fx <- beta_animal_pedigree_sd_fixture()
  pedigree <- fx$pedigree
  fit <- drmTMB(
    bf(
      y ~ x + animal(1 | id, pedigree = pedigree),
      sigma ~ 1,
      sd(id, level = "animal") ~ z
    ),
    family = beta_family(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, "sd_animal(id)"), c("(Intercept)", "z"))
  expect_lt(abs(coef(fit, "sd_animal(id)")[["z"]] - fx$alpha_sd[["z"]]), 0.3)
  sd_prediction <- predict(fit, dpar = "sd_animal(id)")
  expect_setequal(names(sd_prediction), fx$observed_ids)
  expect_true(any(fit$model$random_scale$phylo$node_sd_row0 < 0L))
  expected_sd <- exp(
    coef(fit, "sd_animal(id)")[["(Intercept)"]] +
      coef(fit, "sd_animal(id)")[["z"]] * fx$z_id[names(sd_prediction)]
  )
  expect_equal(unname(sd_prediction), unname(expected_sd), tolerance = 1e-10)

  A_order <- rev(seq_len(nrow(fx$A)))
  A_provider <- fx$A[A_order, A_order, drop = FALSE]
  Ainv_provider <- solve(A_provider)
  fit_A <- drmTMB(
    bf(
      y ~ x + animal(1 | id, A = A_provider),
      sigma ~ 1,
      sd(id, level = "animal") ~ z
    ),
    family = beta_family(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  fit_Ainv <- drmTMB(
    bf(
      y ~ x + animal(1 | id, Ainv = Ainv_provider),
      sigma ~ 1,
      sd(id, level = "animal") ~ z
    ),
    family = beta_family(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )

  for (provider_fit in list(fit_A, fit_Ainv)) {
    expect_equal(provider_fit$opt$convergence, 0L)
    expect_lt(
      abs(coef(provider_fit, "sd_animal(id)")[["z"]] - fx$alpha_sd[["z"]]),
      0.3
    )
    provider_sd <- predict(provider_fit, dpar = "sd_animal(id)")
    expect_setequal(names(provider_sd), fx$observed_ids)
    provider_expected_sd <- exp(
      coef(provider_fit, "sd_animal(id)")[["(Intercept)"]] +
        coef(provider_fit, "sd_animal(id)")[["z"]] *
          fx$z_id[names(provider_sd)]
    )
    expect_equal(
      unname(provider_sd), unname(provider_expected_sd), tolerance = 1e-10
    )
    expect_equal(
      as.numeric(logLik(provider_fit)), as.numeric(logLik(fit)),
      tolerance = 2e-5
    )
  }

  base_fit <- drmTMB(
    bf(y ~ x + animal(1 | id, pedigree = pedigree), sigma ~ 1),
    family = beta_family(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(
      y ~ x + animal(1 | id, pedigree = pedigree),
      sigma ~ 1,
      sd(id, level = "animal") ~ 1
    ),
    family = beta_family(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(constant_fit$logLik, base_fit$logLik, tolerance = 1e-6)

  constant_A <- drmTMB(
    bf(
      y ~ x + animal(1 | id, A = A_provider),
      sigma ~ 1,
      sd(id, level = "animal") ~ 1
    ),
    family = beta_family(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  constant_Ainv <- drmTMB(
    bf(
      y ~ x + animal(1 | id, Ainv = Ainv_provider),
      sigma ~ 1,
      sd(id, level = "animal") ~ 1
    ),
    family = beta_family(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(constant_A$logLik, base_fit$logLik, tolerance = 1e-6)
  expect_equal(constant_Ainv$logLik, base_fit$logLik, tolerance = 1e-6)
})
