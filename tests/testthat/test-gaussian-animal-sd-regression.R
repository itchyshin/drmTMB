gaussian_animal_sd_fixture <- function(seed = 20261021L, n_id = 128L, n_each = 10L) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(n_id))
  kernel_order <- c(seq.int(1L, n_id, by = 2L), seq.int(2L, n_id, by = 2L))
  A_base <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.35^abs(i - j))
  A <- A_base[kernel_order, kernel_order]
  dimnames(A) <- list(id_levels[kernel_order], id_levels[kernel_order])
  z_id <- rep(c(-0.5, 0.5), length.out = n_id)
  alpha <- c(`(Intercept)` = log(0.55), z = 0.35)
  latent_kernel <- as.vector(t(chol(A)) %*% stats::rnorm(n_id)) *
    exp(alpha[[1L]] + alpha[[2L]] * z_id[kernel_order])
  names(latent_kernel) <- id_levels[kernel_order]
  latent <- latent_kernel[id_levels]
  id_index <- rep(seq_len(n_id), each = n_each)
  id <- factor(id_levels[id_index], levels = id_levels)
  z <- z_id[id_index]
  x <- stats::rnorm(length(id))
  y <- 0.2 + 0.5 * x + latent[id] + stats::rnorm(length(id), sd = 0.35)
  data <- data.frame(y, id, x, z)
  list(data = data, A = A, alpha = alpha)
}

test_that("Gaussian animal intercepts support predictor-dependent SDs", {
  skip_on_cran()
  fx <- gaussian_animal_sd_fixture()
  A <- fx$A
  fit <- drmTMB(
    bf(
      y ~ x + animal(1 | id, A = A),
      sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ z
    ),
    family = stats::gaussian(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, "sd_animal(id)"), c("(Intercept)", "z"))
  expect_lt(abs(coef(fit, "sd_animal(id)")[["z"]] - fx$alpha[["z"]]), 0.2)
  sd_prediction <- predict(fit, dpar = "sd_animal(id)")
  expect_setequal(names(sd_prediction), levels(fx$data$id))
  expect_equal(length(sd_prediction), nlevels(fx$data$id))
  expect_equal(
    unname(sd_prediction[levels(fx$data$id)]),
    unname(exp(coef(fit, "sd_animal(id)")[["(Intercept)"]] +
      coef(fit, "sd_animal(id)")[["z"]] *
        fx$data$z[match(levels(fx$data$id), fx$data$id)])),
    tolerance = 1e-10
  )
  expect_length(simulate(fit, nsim = 1L, seed = 20261022L)[[1L]], nrow(fx$data))
  saved_fit <- tempfile(fileext = ".rds")
  on.exit(unlink(saved_fit), add = TRUE)
  saveRDS(fit, saved_fit)
  reloaded_fit <- readRDS(saved_fit)
  expect_equal(
    predict(reloaded_fit, dpar = "sd_animal(id)"),
    sd_prediction,
    tolerance = 1e-12
  )

  base_fit <- drmTMB(
    bf(y ~ x + animal(1 | id, A = A)),
    family = stats::gaussian(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(y ~ x + animal(1 | id, A = A), sd(id, level = "animal") ~ 1),
    family = stats::gaussian(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(
    as.numeric(logLik(constant_fit)),
    as.numeric(logLik(base_fit)),
    tolerance = 2e-5
  )
})

test_that("Gaussian animal SD predictors must be constant within animal", {
  fx <- gaussian_animal_sd_fixture(n_id = 12L, n_each = 3L)
  A <- fx$A
  inconsistent <- fx$data
  inconsistent$z[[1L]] <- inconsistent$z[[1L]] + 1
  expect_error(
    drmTMB(
      bf(
        y ~ x + animal(1 | id, A = A),
        sd(id, level = "animal") ~ z
      ),
      family = stats::gaussian(),
      data = inconsistent
    ),
    "constant within"
  )
})

test_that("Gaussian animal SD regression agrees for equivalent A and Ainv inputs", {
  skip_on_cran()
  fx <- gaussian_animal_sd_fixture()
  A <- fx$A
  Ainv <- solve(A)
  covariance_fit <- drmTMB(
    bf(
      y ~ x + animal(1 | id, A = A),
      sd(id, level = "animal") ~ z
    ),
    family = stats::gaussian(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  precision_fit <- drmTMB(
    bf(
      y ~ x + animal(1 | id, Ainv = Ainv),
      sd(id, level = "animal") ~ z
    ),
    family = stats::gaussian(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )

  expect_equal(covariance_fit$opt$convergence, 0L)
  expect_equal(precision_fit$opt$convergence, 0L)
  expect_equal(
    as.numeric(logLik(precision_fit)),
    as.numeric(logLik(covariance_fit)),
    tolerance = 2e-5
  )
  expect_equal(
    unname(coef(precision_fit, "sd_animal(id)")),
    unname(coef(covariance_fit, "sd_animal(id)")),
    tolerance = 1e-5
  )
  precision_sd <- predict(precision_fit, dpar = "sd_animal(id)")
  covariance_sd <- predict(covariance_fit, dpar = "sd_animal(id)")
  expect_setequal(names(precision_sd), levels(fx$data$id))
  expect_equal(
    unname(precision_sd[levels(fx$data$id)]),
    unname(covariance_sd[levels(fx$data$id)]),
    tolerance = 1e-8
  )
})

gaussian_animal_pedigree_sd_fixture <- function(
  seed = 20261023L,
  n_family = 10L,
  n_offspring = 4L,
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
  ids <- rownames(A)
  z_id <- setNames(rep(c(-0.5, 0.5), length.out = length(ids)), ids)
  alpha <- c("(Intercept)" = log(0.45), z = 0.3)
  latent <- setNames(
    as.vector(t(chol(A)) %*% stats::rnorm(length(ids))) *
      exp(alpha[[1L]] + alpha[[2L]] * z_id[ids]),
    ids
  )
  id <- factor(rep(offspring, each = n_each), levels = rev(ids))
  z <- unname(z_id[as.character(id)])
  x <- rep(seq(-1, 1, length.out = n_each), length(offspring))
  y <- 0.2 + 0.4 * x + latent[as.character(id)] +
    stats::rnorm(length(id), sd = 0.3)
  list(
    data = data.frame(y, id, x, z),
    pedigree = pedigree,
    A = A,
    alpha = alpha,
    z_id = z_id,
    observed_ids = offspring
  )
}

test_that("Gaussian animal SD regression supports pedigree with unobserved founders", {
  skip_on_cran()
  fx <- gaussian_animal_pedigree_sd_fixture()
  pedigree <- fx$pedigree
  expect_true(all(fx$observed_ids %in% levels(fx$data$id)))
  expect_false(any(c(grep("^(sire|dam)", rownames(fx$A), value = TRUE)) %in%
    as.character(fx$data$id)))

  fit <- drmTMB(
    bf(
      y ~ x + animal(1 | id, pedigree = pedigree),
      sd(id, level = "animal") ~ z
    ),
    family = stats::gaussian(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, "sd_animal(id)"), c("(Intercept)", "z"))
  expect_lt(abs(coef(fit, "sd_animal(id)")[["z"]] - fx$alpha[["z"]]), 0.25)
  sd_prediction <- predict(fit, dpar = "sd_animal(id)")
  expect_setequal(names(sd_prediction), fx$observed_ids)
  expected_sd <- exp(
    coef(fit, "sd_animal(id)")[["(Intercept)"]] +
      coef(fit, "sd_animal(id)")[["z"]] * fx$z_id[names(sd_prediction)]
  )
  expect_equal(unname(sd_prediction), unname(expected_sd), tolerance = 1e-10)
  expect_length(simulate(fit, nsim = 1L, seed = 20261024L)[[1L]], nrow(fx$data))

  base_fit <- drmTMB(
    bf(y ~ x + animal(1 | id, pedigree = pedigree)),
    family = stats::gaussian(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(
      y ~ x + animal(1 | id, pedigree = pedigree),
      sd(id, level = "animal") ~ 1
    ),
    family = stats::gaussian(),
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
})
