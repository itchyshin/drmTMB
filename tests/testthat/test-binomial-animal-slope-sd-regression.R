binomial_animal_slope_sd_fixture <- function(
  seed = 6211026L,
  n_id = 240L,
  n_each = 33L
) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(n_id))
  kernel_order <- rev(seq_len(n_id))
  A <- outer(kernel_order, kernel_order, function(i, j) 0.15^abs(i - j))
  dimnames(A) <- list(id_levels[kernel_order], id_levels[kernel_order])
  z_id <- rep(c(-1, 1), length.out = n_id)
  alpha <- c(`(Intercept)` = log(0.3), z = 0.65)
  latent_sd <- exp(alpha[[1L]] + alpha[[2L]] * z_id)
  slope_kernel <- as.vector(t(chol(A)) %*% stats::rnorm(n_id)) *
    latent_sd[kernel_order]
  names(slope_kernel) <- id_levels[kernel_order]
  slope <- slope_kernel[id_levels]
  id_index <- rep(seq_len(n_id), each = n_each)
  id <- factor(id_levels[id_index], levels = id_levels)
  x <- rep(seq(-1, 1, length.out = n_each), n_id)
  z <- z_id[id_index]
  eta <- -0.25 + 0.45 * x + slope[id] * x
  data <- data.frame(
    y = stats::rbinom(length(id), size = 1L, prob = stats::plogis(eta)),
    id = id,
    site = factor((id_index - 1L) %% 12L + 1L),
    x = x,
    z = z
  )
  list(
    data = data,
    A = A,
    alpha = alpha,
    latent_sd = stats::setNames(latent_sd, id_levels)
  )
}

binomial_animal_slope_pedigree_sd_fixture <- function(
  seed = 6211029L,
  n_family = 10L,
  n_offspring = 4L,
  n_each = 30L
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
  A <- A_base[matrix_order, matrix_order, drop = FALSE]
  z_id <- stats::setNames(rep(c(-1, 1), length.out = length(id_levels)), id_levels)
  alpha <- c(`(Intercept)` = log(0.35), z = 0.45)
  slope_ordered <- as.vector(
    t(chol(A)) %*% stats::rnorm(length(id_levels))
  ) * exp(alpha[["(Intercept)"]] + alpha[["z"]] * z_id[id_levels[matrix_order]])
  names(slope_ordered) <- id_levels[matrix_order]
  slope <- slope_ordered[id_levels]
  id_index <- rep(seq_along(id_levels), each = n_each)
  id <- factor(id_levels[id_index], levels = rev(id_levels))
  x <- rep(seq(-1, 1, length.out = n_each), length(id_levels))
  z <- unname(z_id[as.character(id)])
  eta <- -0.2 + 0.55 * x + slope[as.character(id)] * x
  data <- data.frame(
    y = stats::rbinom(length(eta), size = 1L, prob = stats::plogis(eta)),
    id = id,
    x = x,
    z = z
  )
  list(data = data, pedigree = pedigree, A = A_base, alpha = alpha)
}

test_that("Binomial animal slopes support predictor-dependent SDs", {
  skip_on_cran()
  fx <- binomial_animal_slope_sd_fixture()
  A <- fx$A
  fit <- drmTMB(
    bf(
      y ~ x + animal(0 + x | id, A = A),
      sd(id, level = "animal") ~ z
    ),
    family = stats::binomial(),
    data = fx$data
  )

  expect_gt(sum(fx$data$x == 0), 0L)
  expect_equal(fit$opt$convergence, 0)
  expect_named(fit$coefficients[["sd_animal(id)"]], c("(Intercept)", "z"))
  expect_lt(
    abs(fit$coefficients[["sd_animal(id)"]][["z"]] - fx$alpha[["z"]]),
    0.25
  )
  sd_prediction <- predict(fit, dpar = "sd_animal(id)")
  expect_equal(
    unname(sd_prediction),
    unname(fit$sdpars[["sd_animal(id)"]]),
    tolerance = 1e-10
  )
  fixed_eta <- predict(fit, newdata = fx$data, type = "link")
  conditional_eta <- predict(fit, type = "link")
  fitted_contribution <- conditional_eta - fixed_eta
  expect_equal(
    unname(fitted_contribution[fx$data$x == 0]),
    rep(0, sum(fx$data$x == 0)),
    tolerance = 1e-10
  )
  fitted_contribution_per_x <- fitted_contribution[fx$data$x != 0] /
    fx$data$x[fx$data$x != 0]
  fitted_group_per_x <- split(
    fitted_contribution_per_x,
    fx$data$id[fx$data$x != 0]
  )
  expect_true(all(vapply(fitted_group_per_x, function(value) {
    diff(range(value)) < 1e-8
  }, logical(1L))))
  set.seed(6211028L)
  fresh_contribution <- drm_structured_mu_random_effect_draws(fit)[["mu"]]
  expect_equal(
    unname(fresh_contribution[fx$data$x == 0]),
    rep(0, sum(fx$data$x == 0)),
    tolerance = 1e-12
  )
  contribution_per_x <- fresh_contribution[fx$data$x != 0] /
    fx$data$x[fx$data$x != 0]
  group_per_x <- split(contribution_per_x, fx$data$id[fx$data$x != 0])
  expect_true(all(vapply(group_per_x, function(value) {
    diff(range(value)) < 1e-10
  }, logical(1L))))
  expect_setequal(names(sd_prediction), rownames(A))
  group_z <- stats::setNames(
    fx$data$z[match(rownames(A), as.character(fx$data$id))], rownames(A)
  )
  expect_equal(
    unname(sd_prediction),
    unname(exp(
      coef(fit, "sd_animal(id)")[["(Intercept)"]] +
        coef(fit, "sd_animal(id)")[["z"]] * group_z[names(sd_prediction)]
    )),
    tolerance = 1e-10
  )
  expect_true("fixef:sd_animal(id):z" %in% profile_targets(fit)$parm)
  simulated <- simulate(fit, nsim = 1L, seed = 6211027L)
  expect_length(simulated[[1L]], nrow(fx$data))
  save_file <- tempfile(fileext = ".rds")
  on.exit(unlink(save_file), add = TRUE)
  saveRDS(fit, save_file)
  reloaded <- readRDS(save_file)
  expect_equal(coef(reloaded, "sd_animal(id)"), coef(fit, "sd_animal(id)"))
  expect_equal(predict(reloaded, dpar = "sd_animal(id)"), sd_prediction)

  base_fit <- drmTMB(
    bf(y ~ x + animal(0 + x | id, A = A)),
    family = stats::binomial(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(
      y ~ x + animal(0 + x | id, A = A),
      sd(id, level = "animal") ~ 1
    ),
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

  inconsistent <- fx$data
  inconsistent$z[[1L]] <- inconsistent$z[[1L]] + 1
  expect_error(
    drmTMB(
      bf(
        y ~ x + animal(0 + x | id, A = A),
        sd(id, level = "animal") ~ z
      ),
      family = stats::binomial(),
      data = inconsistent
    ),
    "constant within"
  )

  expect_error(
    drmTMB(
      bf(y ~ x + animal(1 + x | id, A = A)),
      family = stats::binomial(),
      data = fx$data
    ),
    "intercept-only q1"
  )
  expect_error(
    drmTMB(
      bf(
        y ~ x + (1 | site) + animal(0 + x | id, A = A),
        sd(id, level = "animal") ~ z
      ),
      family = stats::binomial(),
      data = fx$data
    ),
    "must be fitted without ordinary random effects"
  )
})

test_that("Binomial animal slope SDs agree for A, Ainv, and pedigree inputs", {
  skip_on_cran()
  fx <- binomial_animal_slope_pedigree_sd_fixture()
  pedigree <- fx$pedigree
  group_levels <- levels(fx$data$id)
  A <- fx$A[group_levels, group_levels, drop = FALSE]
  matrix_order <- rev(seq_along(group_levels))
  Ainv <- solve(A[matrix_order, matrix_order, drop = FALSE])
  dimnames(Ainv) <- list(group_levels[matrix_order], group_levels[matrix_order])
  expect_false(identical(group_levels, rownames(Ainv)))

  fit_pedigree <- drmTMB(
    bf(
      y ~ x + animal(0 + x | id, pedigree = pedigree),
      sd(id, level = "animal") ~ z
    ),
    family = stats::binomial(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  fit_A <- drmTMB(
    bf(
      y ~ x + animal(0 + x | id, A = A),
      sd(id, level = "animal") ~ z
    ),
    family = stats::binomial(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  fit_Ainv <- drmTMB(
    bf(
      y ~ x + animal(0 + x | id, Ainv = Ainv),
      sd(id, level = "animal") ~ z
    ),
    family = stats::binomial(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )

  expect_true(all(vapply(list(fit_pedigree, fit_A, fit_Ainv), function(fit) {
    identical(fit$opt$convergence, 0L)
  }, logical(1L))))
  expect_equal(as.numeric(logLik(fit_A)), as.numeric(logLik(fit_pedigree)), tolerance = 2e-5)
  expect_equal(as.numeric(logLik(fit_Ainv)), as.numeric(logLik(fit_pedigree)), tolerance = 2e-5)
  expect_equal(coef(fit_A, "sd_animal(id)"), coef(fit_pedigree, "sd_animal(id)"), tolerance = 2e-4)
  expect_equal(coef(fit_Ainv, "sd_animal(id)"), coef(fit_pedigree, "sd_animal(id)"), tolerance = 2e-4)
  expect_gt(coef(fit_pedigree, "sd_animal(id)")[["z"]], 0)
  sd_pedigree <- predict(fit_pedigree, dpar = "sd_animal(id)")
  sd_A <- predict(fit_A, dpar = "sd_animal(id)")
  sd_Ainv <- predict(fit_Ainv, dpar = "sd_animal(id)")
  expect_setequal(names(sd_A), names(sd_pedigree))
  expect_setequal(names(sd_Ainv), names(sd_pedigree))
  expect_equal(unname(sd_A[names(sd_pedigree)]), unname(sd_pedigree), tolerance = 2e-4)
  expect_equal(unname(sd_Ainv[names(sd_pedigree)]), unname(sd_pedigree), tolerance = 2e-4)
})
