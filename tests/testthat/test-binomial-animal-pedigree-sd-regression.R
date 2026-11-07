binomial_animal_pedigree_sd_fixture <- function(
  seed = 20261030L,
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
  alpha <- c(`(Intercept)` = log(0.4), z = 0.35)
  latent_matrix_order <- as.vector(t(chol(A)) %*% stats::rnorm(length(id_levels))) *
    exp(alpha[[1L]] + alpha[[2L]] * z_id[id_levels[matrix_order]])
  names(latent_matrix_order) <- id_levels[matrix_order]
  latent <- latent_matrix_order[id_levels]
  id_index <- rep(seq_along(id_levels), each = n_each)
  id <- factor(id_levels[id_index], levels = rev(id_levels))
  z <- unname(z_id[as.character(id)])
  x <- rep(seq(-1, 1, length.out = n_each), length(id_levels))
  eta <- -0.2 + 0.55 * x + latent[as.character(id)]
  data <- data.frame(
    y = stats::rbinom(length(eta), size = 1L, prob = stats::plogis(eta)),
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
    z_id = z_id
  )
}

test_that("Bernoulli animal intercepts support predictor-dependent SDs with pedigree", {
  skip_on_cran()
  fx <- binomial_animal_pedigree_sd_fixture()
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
      sd(id, level = "animal") ~ z
    ),
    family = stats::binomial(),
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
    bf(y ~ x + animal(1 | id, pedigree = pedigree)),
    family = stats::binomial(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(y ~ x + animal(1 | id, pedigree = pedigree), sd(id, level = "animal") ~ 1),
    family = stats::binomial(),
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
