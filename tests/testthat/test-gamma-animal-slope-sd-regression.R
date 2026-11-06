gamma_animal_slope_sd_fixture <- function(
  seed = 20261022L,
  n_family = 16L,
  n_offspring = 6L,
  n_each = 24L
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
  z_id <- stats::setNames(rep(c(-0.5, 0.5), length.out = length(id_levels)), id_levels)
  alpha <- c(log(0.4), z = 0.35)
  animal_slope <- as.vector(t(chol(A)) %*% stats::rnorm(length(id_levels))) *
    exp(alpha[[1L]] + alpha[[2L]] * z_id[id_levels])
  names(animal_slope) <- id_levels

  id_index <- rep(seq_along(id_levels), each = n_each)
  id <- factor(id_levels[id_index], levels = rev(id_levels))
  x <- rep(seq(-1, 1, length.out = n_each), times = length(id_levels))
  z <- unname(z_id[as.character(id)])
  eta <- 0.3 + 0.25 * x + animal_slope[as.character(id)] * x
  mu <- exp(eta)
  sigma <- 0.5
  data <- data.frame(
    y = stats::rgamma(length(mu), shape = 1 / sigma^2, scale = mu * sigma^2),
    id,
    x,
    z
  )
  list(
    data = data,
    pedigree = pedigree,
    A = A,
    alpha = alpha,
    id_levels = id_levels,
    z_id = z_id,
    sigma = sigma
  )
}

test_that("Gamma animal slope SDs can depend on group-level predictors", {
  skip_on_cran()
  fx <- gamma_animal_slope_sd_fixture()
  pedigree <- fx$pedigree
  fit <- drmTMB(
    bf(
      y ~ x + animal(0 + x | id, pedigree = pedigree),
      sigma ~ 1,
      sd(id, level = "animal") ~ z
    ),
    family = stats::Gamma(link = "log"),
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

  simulated <- simulate(fit, nsim = 1L, seed = 20261023L, re.form = NULL)
  expect_equal(nrow(simulated), nrow(fx$data))
  expect_named(simulated, "sim_1")
  expect_true(all(is.finite(simulated$sim_1)))

  saved_fit <- tempfile(fileext = ".rds")
  on.exit(unlink(saved_fit), add = TRUE)
  saveRDS(fit, saved_fit)
  reloaded_fit <- readRDS(saved_fit)
  expect_equal(
    coef(reloaded_fit, "sd_animal(id)"),
    coef(fit, "sd_animal(id)")
  )
  expect_equal(
    predict(reloaded_fit, dpar = "sd_animal(id)"),
    sd_prediction
  )

  base_fit <- drmTMB(
    bf(y ~ x + animal(0 + x | id, pedigree = pedigree), sigma ~ 1),
    family = stats::Gamma(link = "log"),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(
      y ~ x + animal(0 + x | id, pedigree = pedigree),
      sigma ~ 1,
      sd(id, level = "animal") ~ 1
    ),
    family = stats::Gamma(link = "log"),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(base_fit$opt$convergence, 0L)
  expect_equal(constant_fit$opt$convergence, 0L)
  expect_equal(
    as.numeric(logLik(constant_fit)),
    as.numeric(logLik(base_fit)),
    tolerance = 2e-5
  )

  inconsistent <- fx$data
  inconsistent$z[1L] <- inconsistent$z[1L] + 1
  expect_error(
    drmTMB(
      bf(
        y ~ x + animal(0 + x | id, pedigree = pedigree),
        sigma ~ 1,
        sd(id, level = "animal") ~ z
      ),
      family = stats::Gamma(link = "log"),
      data = inconsistent,
      control = drm_control(se = FALSE)
    ),
    "varies within id level"
  )

  expect_error(
    drmTMB(
      bf(
        y ~ x + animal(1 + x | id, pedigree = pedigree),
        sigma ~ 1,
        sd(id, level = "animal") ~ z
      ),
      family = stats::Gamma(link = "log"),
      data = fx$data,
      control = drm_control(se = FALSE)
    ),
    "must select a coefficient"
  )
})
