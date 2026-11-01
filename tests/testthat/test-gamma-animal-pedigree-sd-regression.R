gamma_animal_pedigree_sd_fixture <- function(
  seed = 20261031L,
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
  A_base <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  id_levels <- rownames(A_base)
  matrix_order <- rev(seq_along(id_levels))
  A <- A_base[matrix_order, matrix_order]
  z_id <- setNames(rep(c(-0.5, 0.5), length.out = length(id_levels)), id_levels)
  alpha <- c(log(0.4), z = 0.35)
  latent_matrix_order <- as.vector(t(chol(A)) %*% stats::rnorm(length(id_levels))) *
    exp(alpha[[1L]] + alpha[[2L]] * z_id[id_levels[matrix_order]])
  names(latent_matrix_order) <- id_levels[matrix_order]
  latent <- latent_matrix_order[id_levels]
  id_index <- rep(seq_along(id_levels), each = n_each)
  id <- factor(id_levels[id_index], levels = rev(id_levels))
  z <- unname(z_id[as.character(id)])
  x <- rep(seq(-1, 1, length.out = n_each), length(id_levels))
  eta <- 0.3 + 0.25 * x + latent[as.character(id)]
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
    A = A_base,
    alpha = alpha,
    id_levels = id_levels,
    z_id = z_id,
    sigma = sigma
  )
}

test_that("Gamma animal intercepts support predictor-dependent SDs with pedigree", {
  skip_on_cran()
  fx <- gamma_animal_pedigree_sd_fixture()
  pedigree <- fx$pedigree
  expect_false(identical(levels(fx$data$id), fx$id_levels))
  sparse_precision <- drmTMB:::drm_pedigree_sparse_precision(pedigree)
  expected_precision <- solve(fx$A)
  expect_equal(
    as.matrix(sparse_precision)[rownames(expected_precision), rownames(expected_precision)],
    expected_precision,
    tolerance = 1e-10
  )

  fit <- drmTMB(
    bf(
      y ~ x + animal(1 | id, pedigree = pedigree),
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

  base_fit <- drmTMB(
    bf(y ~ x + animal(1 | id, pedigree = pedigree), sigma ~ 1),
    family = stats::Gamma(link = "log"),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(
      y ~ x + animal(1 | id, pedigree = pedigree),
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

  A_gamma <- fx$A
  A_fit <- drmTMB(
    bf(
      y ~ x + animal(1 | id, A = A_gamma),
      sigma ~ 1,
      sd(id, level = "animal") ~ z
    ),
    family = stats::Gamma(link = "log"),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  Q <- solve(fx$A)
  Ainv_fit <- drmTMB(
    bf(
      y ~ x + animal(1 | id, Ainv = Q),
      sigma ~ 1,
      sd(id, level = "animal") ~ z
    ),
    family = stats::Gamma(link = "log"),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(A_fit$opt$convergence, 0L)
  expect_equal(Ainv_fit$opt$convergence, 0L)
  expect_equal(as.numeric(logLik(A_fit)), as.numeric(logLik(fit)), tolerance = 2e-5)
  expect_equal(as.numeric(logLik(Ainv_fit)), as.numeric(logLik(fit)), tolerance = 2e-5)
})

gamma_animal_intercept_slope_sd_fixture <- function(
  seed = 20261024L,
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
  ids <- rownames(A)
  z0_id <- stats::setNames(rep(c(-0.5, 0.5), length.out = length(ids)), ids)
  z1_id <- stats::setNames(rep(c(0.5, -0.5), length.out = length(ids)), ids)
  alpha0 <- c(log(0.35), z0 = 0.45)
  alpha1 <- c(log(0.3), z1 = -0.4)
  chol_A <- t(chol(A))
  u0 <- as.vector(chol_A %*% stats::rnorm(length(ids)))
  u1 <- as.vector(chol_A %*% stats::rnorm(length(ids)))
  names(u0) <- names(u1) <- ids
  b0 <- exp(alpha0[[1L]] + alpha0[[2L]] * z0_id) * u0
  b1 <- exp(alpha1[[1L]] + alpha1[[2L]] * z1_id) * u1
  idx <- rep(seq_along(ids), each = n_each)
  id <- factor(ids[idx], levels = rev(ids))
  x <- rep(seq(-1, 1, length.out = n_each), times = length(ids))
  id_chr <- as.character(id)
  z0 <- unname(z0_id[id_chr])
  z1 <- unname(z1_id[id_chr])
  eta <- 0.25 + 0.2 * x + b0[id_chr] + x * b1[id_chr]
  mu <- exp(eta)
  sigma <- 0.45
  data <- data.frame(
    y = stats::rgamma(length(mu), shape = 1 / sigma^2, scale = mu * sigma^2),
    id = id,
    x = x,
    z0 = z0,
    z1 = z1
  )
  list(
    data = data,
    pedigree = pedigree,
    A = A,
    ids = ids,
    z0_id = z0_id,
    z1_id = z1_id,
    alpha0 = alpha0,
    alpha1 = alpha1,
    sigma = sigma
  )
}

test_that("Gamma animal intercept and independent slope have separate SD regressions", {
  skip_on_cran()
  fx <- gamma_animal_intercept_slope_sd_fixture()
  pedigree <- fx$pedigree
  expect_false(identical(levels(fx$data$id), fx$ids))
  key0 <- 'sd_animal(id, dpar = "mu", coef = "(Intercept)")'
  key1 <- 'sd_animal(id, dpar = "mu", coef = "x")'

  fit <- drmTMB(
    bf(
      y ~ x + animal(1 + x | id, pedigree = pedigree),
      sigma ~ 1,
      sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ z0,
      sd(id, level = "animal", dpar = "mu", coef = "x") ~ z1
    ),
    family = stats::Gamma(link = "log"),
    data = fx$data,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, key0), c("(Intercept)", "z0"))
  expect_named(coef(fit, key1), c("(Intercept)", "z1"))
  expect_lt(abs(coef(fit, key0)[["z0"]] - fx$alpha0[["z0"]]), 0.3)
  expect_lt(abs(coef(fit, key1)[["z1"]] - fx$alpha1[["z1"]]), 0.3)

  sd0 <- predict(fit, dpar = key0)
  sd1 <- predict(fit, dpar = key1)
  expect_setequal(names(sd0), fx$ids)
  expect_setequal(names(sd1), fx$ids)
  expect_equal(
    unname(sd0),
    unname(exp(coef(fit, key0)[["(Intercept)"]] +
      coef(fit, key0)[["z0"]] * fx$z0_id[names(sd0)])),
    tolerance = 1e-10
  )
  expect_equal(
    unname(sd1),
    unname(exp(coef(fit, key1)[["(Intercept)"]] +
      coef(fit, key1)[["z1"]] * fx$z1_id[names(sd1)])),
    tolerance = 1e-10
  )

  simulated <- simulate(fit, nsim = 1L, seed = 20261025L, re.form = NULL)
  expect_equal(nrow(simulated), nrow(fx$data))
  expect_true(all(is.finite(simulated$sim_1)))
  saved <- tempfile(fileext = ".rds")
  on.exit(unlink(saved), add = TRUE)
  saveRDS(fit, saved)
  reloaded <- readRDS(saved)
  expect_equal(coef(reloaded, key0), coef(fit, key0))
  expect_equal(coef(reloaded, key1), coef(fit, key1))
  expect_equal(predict(reloaded, dpar = key0), sd0)
  expect_equal(predict(reloaded, dpar = key1), sd1)

  base_fit <- drmTMB(
    bf(y ~ x + animal(1 + x | id, pedigree = pedigree), sigma ~ 1),
    family = stats::Gamma(link = "log"), data = fx$data,
    control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(
      y ~ x + animal(1 + x | id, pedigree = pedigree), sigma ~ 1,
      sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ 1,
      sd(id, level = "animal", dpar = "mu", coef = "x") ~ 1
    ),
    family = stats::Gamma(link = "log"), data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(base_fit$opt$convergence, 0L)
  expect_equal(constant_fit$opt$convergence, 0L)
  expect_equal(
    as.numeric(logLik(constant_fit)), as.numeric(logLik(base_fit)),
    tolerance = 2e-5
  )
})

test_that("animal coefficient selectors are unique and ambiguity is explicit", {
  fx <- gamma_animal_intercept_slope_sd_fixture(n_family = 3L, n_offspring = 2L, n_each = 3L)
  pedigree <- fx$pedigree
  expect_error(
    drmTMB(
      bf(
        y ~ x + animal(1 + x | id, pedigree = pedigree), sigma ~ 1,
        sd(id, level = "animal") ~ z0
      ),
      family = stats::Gamma(link = "log"), data = fx$data,
      control = drm_control(se = FALSE)
    ),
    "must select a coefficient when the term has multiple fields"
  )
  expect_error(
    drmTMB(
      bf(
        y ~ x + animal(1 + x | id, pedigree = pedigree), sigma ~ 1,
        sd(id, level = "animal", coef = "x") ~ z0,
        sd(id, level = "animal", coef = "x") ~ z1
      ),
      family = stats::Gamma(link = "log"), data = fx$data,
      control = drm_control(se = FALSE)
    ),
    "requires one SD formula for each coefficient"
  )
})

test_that("Gamma animal q2 SD regression rejects unidentified slope scales", {
  fx <- gamma_animal_intercept_slope_sd_fixture(
    n_family = 3L, n_offspring = 2L, n_each = 3L
  )
  pedigree <- fx$pedigree

  zero_loading <- fx$data
  zero_loading$x[] <- 0
  expect_error(
    drmTMB(
      bf(
        y ~ 1 + animal(1 + x | id, pedigree = pedigree),
        sigma ~ 1,
        sd(id, level = "animal", coef = "(Intercept)") ~ z0,
        sd(id, level = "animal", coef = "x") ~ z1
      ),
      family = stats::Gamma(link = "log"), data = zero_loading,
      control = drm_control(se = FALSE)
    ),
    "slope loading is identically zero"
  )

  constant_loading <- fx$data
  constant_loading$x[] <- 1
  expect_error(
    drmTMB(
      bf(
        y ~ 1 + animal(1 + x | id, pedigree = pedigree),
        sigma ~ 1,
        sd(id, level = "animal", coef = "(Intercept)") ~ 1,
        sd(id, level = "animal", coef = "x") ~ 1
      ),
      family = stats::Gamma(link = "log"), data = constant_loading,
      control = drm_control(se = FALSE)
    ),
    "only the combined variance is identified"
  )
})
