nbinom2_animal_sd_fixture <- function(
  seed = 20261032L,
  n_family = 12L,
  n_offspring = 3L,
  n_each = 12L
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
  alpha <- c(log(0.45), z = 0.3)
  latent <- as.vector(t(chol(A)) %*% stats::rnorm(length(id_levels))) *
    exp(alpha[[1L]] + alpha[[2L]] * z_id[id_levels])
  names(latent) <- id_levels
  id_index <- rep(seq_along(id_levels), each = n_each)
  id <- factor(id_levels[id_index], levels = rev(id_levels))
  z <- unname(z_id[as.character(id)])
  x <- rep(seq(-1, 1, length.out = n_each), length(id_levels))
  eta <- 1.1 + 0.2 * x + latent[as.character(id)]
  mu <- exp(eta)
  dispersion <- 0.55
  data <- data.frame(
    y = stats::rnbinom(length(mu), mu = mu, size = 1 / dispersion^2),
    id,
    x,
    z
  )
  list(data = data, pedigree = pedigree, A = A, alpha = alpha, id_levels = id_levels,
       z_id = z_id, dispersion = dispersion)
}

test_that("NB2 animal intercepts support predictor-dependent SDs with pedigree", {
  skip_on_cran()
  fx <- nbinom2_animal_sd_fixture()
  pedigree <- fx$pedigree
  fit <- drmTMB(
    bf(
      y ~ x + animal(1 | id, pedigree = pedigree),
      sigma ~ 1,
      sd(id, level = "animal") ~ z
    ),
    family = nbinom2(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, "sd_animal(id)"), c("(Intercept)", "z"))
  expect_lt(abs(coef(fit, "sd_animal(id)")[["z"]] - fx$alpha[["z"]]), 0.35)
  sd_prediction <- predict(fit, dpar = "sd_animal(id)")
  expect_setequal(names(sd_prediction), fx$id_levels)
  expected_sd <- exp(
    coef(fit, "sd_animal(id)")[["(Intercept)"]] +
      coef(fit, "sd_animal(id)")[["z"]] * fx$z_id[names(sd_prediction)]
  )
  expect_equal(unname(sd_prediction), unname(expected_sd), tolerance = 1e-10)

  inconsistent <- fx$data
  inconsistent$z[1L] <- inconsistent$z[1L] + 1
  expect_error(
    drmTMB(
      bf(
        y ~ x + animal(1 | id, pedigree = pedigree),
        sigma ~ 1,
        sd(id, level = "animal") ~ z
      ),
      family = nbinom2(),
      data = inconsistent,
      control = drm_control(se = FALSE)
    ),
    "constant within"
  )

  base_fit <- drmTMB(
    bf(y ~ x + animal(1 | id, pedigree = pedigree), sigma ~ 1),
    family = nbinom2(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(
      y ~ x + animal(1 | id, pedigree = pedigree),
      sigma ~ 1,
      sd(id, level = "animal") ~ 1
    ),
    family = nbinom2(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(base_fit$opt$convergence, 0L)
  expect_equal(constant_fit$opt$convergence, 0L)
  expect_equal(as.numeric(logLik(constant_fit)), as.numeric(logLik(base_fit)),
               tolerance = 2e-5)
})

test_that("NB2 animal intercept SDs preserve labels for supplied A covariance", {
  skip_on_cran()
  fx <- nbinom2_animal_sd_fixture()
  A <- fx$A
  pedigree <- fx$pedigree

  fit_A <- drmTMB(
    bf(
      y ~ x + animal(1 | id, A = A),
      sigma ~ 1,
      sd(id, level = "animal") ~ z
    ),
    family = nbinom2(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  fit_pedigree <- drmTMB(
    bf(
      y ~ x + animal(1 | id, pedigree = pedigree),
      sigma ~ 1,
      sd(id, level = "animal") ~ z
    ),
    family = nbinom2(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit_A$opt$convergence, 0L)
  expect_equal(fit_pedigree$opt$convergence, 0L)
  expect_named(coef(fit_A, "sd_animal(id)"), c("(Intercept)", "z"))
  expect_equal(
    unname(coef(fit_A, "sd_animal(id)")),
    unname(coef(fit_pedigree, "sd_animal(id)")),
    tolerance = 1e-7
  )
  expect_equal(
    as.numeric(logLik(fit_A)),
    as.numeric(logLik(fit_pedigree)),
    tolerance = 1e-7
  )
  sd_A <- predict(fit_A, dpar = "sd_animal(id)")
  sd_pedigree <- predict(fit_pedigree, dpar = "sd_animal(id)")
  expect_setequal(names(sd_A), fx$id_levels)
  expect_equal(
    unname(sd_A[fx$id_levels]),
    unname(sd_pedigree[fx$id_levels]),
    tolerance = 1e-7
  )
})
