nbinom2_animal_slope_sd_fixture <- function(
  seed = 20261021L,
  n_family = 16L,
  n_offspring = 3L,
  n_each = 20L
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
  id_levels <- offspring
  z_id <- stats::setNames(
    rep(c(-0.5, 0.5), length.out = length(id_levels)), id_levels
  )
  alpha <- c("(Intercept)" = log(0.35), z = 0.45)
  tau_id <- exp(alpha[[1L]] + alpha[[2L]] * z_id)
  A_obs <- A[id_levels, id_levels, drop = FALSE]
  slope_cov <- outer(tau_id, tau_id) * A_obs
  slope <- as.vector(t(chol(slope_cov + diag(1e-8, length(id_levels)))) %*%
    stats::rnorm(length(id_levels)))
  names(slope) <- id_levels
  id <- factor(rep(id_levels, each = n_each), levels = rev(id_levels))
  x <- rep(seq(-1, 1, length.out = n_each), length(id_levels))
  z <- unname(z_id[as.character(id)])
  eta <- 1.1 + 0.2 * x + slope[as.character(id)] * x
  mu <- exp(eta)
  dispersion <- 0.45
  data <- data.frame(
    y = stats::rnbinom(length(mu), mu = mu, size = 1 / dispersion^2),
    id = id,
    x = x,
    z = z
  )
  list(
    data = data,
    pedigree = pedigree,
    A = A,
    alpha = alpha,
    z_id = z_id,
    id_levels = id_levels,
    dispersion = dispersion
  )
}

test_that("NB2 animal slope SDs can depend on group-level predictors", {
  skip_on_cran()
  fx <- nbinom2_animal_slope_sd_fixture()
  pedigree <- fx$pedigree
  fit <- drmTMB(
    bf(
      y ~ x + animal(0 + x | id, pedigree = pedigree),
      sigma ~ 1,
      sd(id, level = "animal") ~ z
    ),
    family = nbinom2(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, "sd_animal(id)"), c("(Intercept)", "z"))
  expect_lt(abs(coef(fit, "sd_animal(id)")[["z"]] - fx$alpha[["z"]]), 0.25)
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
        y ~ x + animal(0 + x | id, pedigree = pedigree),
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
    bf(y ~ x + animal(0 + x | id, pedigree = pedigree), sigma ~ 1),
    family = nbinom2(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(
      y ~ x + animal(0 + x | id, pedigree = pedigree),
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
