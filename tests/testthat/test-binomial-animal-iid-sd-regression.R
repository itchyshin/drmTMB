binomial_animal_iid_sd_fixture <- function(
  seed = 20261024L,
  n_id = 24L,
  n_site = 8L,
  n_each = 12L,
  animal_slope = FALSE
) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(n_id))
  site_levels <- paste0("site", seq_len(n_site))
  # Keep site membership balanced while making it independent of the animal
  # ordering used by the relationship matrix.
  site_by_id <- sample(rep(site_levels, each = n_id / n_site))
  z_animal <- stats::setNames(seq(-1, 1, length.out = n_id), id_levels)
  z_iid <- stats::setNames(seq(-0.8, 0.8, length.out = n_site), site_levels)

  kernel_order <- rev(seq_len(n_id))
  A <- outer(kernel_order, kernel_order, function(i, j) 0.2^abs(i - j))
  dimnames(A) <- list(id_levels[kernel_order], id_levels[kernel_order])

  animal_sd <- exp(-0.7 + 0.45 * z_animal)
  animal_draw <- as.vector(t(chol(A)) %*% stats::rnorm(n_id))
  names(animal_draw) <- rownames(A)
  animal_draw <- animal_draw * animal_sd[names(animal_draw)]
  animal_draw <- animal_draw[id_levels]

  iid_sd <- exp(-0.8 + 0.45 * z_iid)
  iid_draw <- stats::setNames(stats::rnorm(n_site, sd = iid_sd), site_levels)

  id_index <- rep(seq_len(n_id), each = n_each)
  site_index <- match(site_by_id[id_index], site_levels)
  id <- factor(id_levels[id_index], levels = id_levels)
  site <- factor(site_levels[site_index], levels = site_levels)
  x <- stats::rnorm(length(id))
  animal_effect <- animal_draw[as.character(id)]
  if (isTRUE(animal_slope)) {
    animal_effect <- x * animal_effect
  }
  iid_effect <- iid_draw[as.character(site)]
  y <- stats::rbinom(
    length(id), size = 1L,
    prob = stats::plogis(-0.2 + 0.3 * x + animal_effect + iid_effect)
  )
  data <- data.frame(
    y = y,
    x = x,
    id = id,
    site = site,
    z_animal = unname(z_animal[as.character(id)]),
    z_iid = unname(z_iid[as.character(site)])
  )
  list(data = data, A = A, z_animal = z_animal, z_iid = z_iid)
}

test_that("Binomial animal and IID intercepts retain separate SD designs", {
  fx <- binomial_animal_iid_sd_fixture()
  A <- fx$A
  spec <- drm_build_binomial_spec(bf(
    y ~ x + animal(1 | id, A = A) + (1 | site),
    sd(id, level = "animal") ~ z_animal,
    sd(site) ~ z_iid
  ), fx$data)
  dat <- make_tmb_data(spec)

  expect_equal(dat$model_type, 18L)
  expect_equal(dat$n_mu_re_terms, 1L)
  expect_equal(dat$has_phylo_mu, 1L)
  expect_equal(dat$has_sd_mu_model, 1L)
  expect_equal(dat$has_sd_phylo_model, 1L)
  expect_equal(nrow(dat$X_sd_mu), length(fx$z_iid))
  expect_equal(nrow(dat$X_sd_phylo), length(fx$z_animal))
  expect_identical(
    colnames(dat$X_sd_mu), c("sd(site):(Intercept)", "sd(site):z_iid")
  )
  expect_identical(colnames(dat$X_sd_phylo), c("(Intercept)", "z_animal"))
  expect_equal(
    unname(dat$X_sd_mu[, "sd(site):z_iid"]),
    unname(fx$z_iid[levels(fx$data$site)])
  )
  expect_equal(
    unname(dat$X_sd_phylo[, "z_animal"]),
    unname(fx$z_animal[rownames(fx$A)])
  )
  expect_equal(dim(dat$Q_phylo), dim(fx$A))
  expect_length(dat$phylo_mu_node_index, nrow(fx$data))
  expect_length(dat$mu_re_index, nrow(fx$data))
  expect_identical(
    as.integer(dat$mu_re_index[, 1L]),
    match(as.character(fx$data$site), levels(fx$data$site)) - 1L
  )
  expect_identical(
    as.integer(dat$phylo_mu_node_index),
    match(as.character(fx$data$id), rownames(fx$A)) - 1L
  )
  expect_identical(
    as.integer(dat$phylo_mu_sd_row),
    as.integer(dat$phylo_mu_node_index)
  )
})

test_that("Binomial animal-slope plus IID-intercept SD design is assembled", {
  fx <- binomial_animal_iid_sd_fixture()
  A <- fx$A

  slope_spec <- drm_build_binomial_spec(bf(
    y ~ x + animal(0 + x | id, A = A) + (1 | site),
    sd(id, level = "animal") ~ z_animal,
    sd(site) ~ z_iid
  ), fx$data)
  slope_data <- make_tmb_data(slope_spec)
  expect_equal(slope_data$model_type, 18L)
  expect_equal(slope_data$has_phylo_mu, 1L)
  expect_equal(slope_data$has_sd_phylo_model, 1L)
  expect_equal(slope_data$has_sd_mu_model, 1L)
  structured_data <- structured_mu_tmb_data(slope_spec)
  expect_equal(ncol(structured_data$phylo_mu_value), 1L)
  expect_equal(
    unname(structured_data$phylo_mu_value[, 1L]),
    unname(fx$data$x),
    tolerance = 0
  )
  expect_equal(
    as.integer(slope_data$phylo_mu_sd_row),
    as.integer(slope_data$phylo_mu_node_index)
  )

  expect_error(drm_build_binomial_spec(bf(
    y ~ x + animal(1 | id, A = A) + (1 | site),
    sd(id, level = "animal") ~ z_animal,
    sd(site) ~ z_iid
  ), fx$data, missing = miss_control(response = "include")),
  "without ordinary random effects")
})

test_that("Binomial animal-slope plus IID-intercept SDs recover both targets", {
  skip_on_cran()
  fx <- binomial_animal_iid_sd_fixture(
    n_id = 192L,
    n_site = 48L,
    n_each = 24L,
    animal_slope = TRUE
  )
  A <- fx$A
  fit <- drmTMB(
    bf(
      y ~ x + animal(0 + x | id, A = A) + (1 | site),
      sd(id, level = "animal") ~ z_animal,
      sd(site) ~ z_iid
    ),
    family = stats::binomial(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_true(is.finite(as.numeric(logLik(fit))))
  expect_setequal(names(coef(fit)), c("mu", "sd_animal(id)", "sd(site)"))
  animal_coef <- coef(fit, "sd_animal(id)")
  iid_coef <- coef(fit, "sd(site)")
  expect_identical(names(animal_coef), c("(Intercept)", "z_animal"))
  expect_identical(names(iid_coef), c("(Intercept)", "z_iid"))
  expect_lt(abs(animal_coef[["z_animal"]] - 0.45), 0.35)
  expect_lt(abs(iid_coef[["z_iid"]] - 0.45), 0.35)
  expect_length(predict(fit, dpar = "sd_animal(id)"), 192L)
  expect_length(predict(fit, dpar = "sd(site)"), 48L)

  save_file <- tempfile(fileext = ".rds")
  on.exit(unlink(save_file), add = TRUE)
  saveRDS(fit, save_file)
  reloaded <- readRDS(save_file)
  expect_equal(coef(reloaded, "sd_animal(id)"), animal_coef)
  expect_equal(coef(reloaded, "sd(site)"), iid_coef)
})

test_that("Binomial animal plus IID intercepts allow each SD target independently", {
  fx <- binomial_animal_iid_sd_fixture()
  A <- fx$A

  ordinary_only <- drm_build_binomial_spec(bf(
    y ~ x + animal(1 | id, A = A) + (1 | site),
    sd(site) ~ z_iid
  ), fx$data)
  ordinary_data <- make_tmb_data(ordinary_only)
  expect_equal(ordinary_data$has_phylo_mu, 1L)
  expect_equal(ordinary_data$n_mu_re_terms, 1L)
  expect_equal(ordinary_data$has_sd_mu_model, 1L)
  expect_equal(ordinary_data$has_sd_phylo_model, 0L)

  animal_only <- drm_build_binomial_spec(bf(
    y ~ x + animal(1 | id, A = A) + (1 | site),
    sd(id, level = "animal") ~ z_animal
  ), fx$data)
  animal_data <- make_tmb_data(animal_only)
  expect_equal(animal_data$has_phylo_mu, 1L)
  expect_equal(animal_data$n_mu_re_terms, 1L)
  expect_equal(animal_data$has_sd_mu_model, 0L)
  expect_equal(animal_data$has_sd_phylo_model, 1L)

  constant <- drm_build_binomial_spec(bf(
    y ~ x + animal(1 | id, A = A) + (1 | site)
  ), fx$data)
  constant_data <- make_tmb_data(constant)
  expect_equal(constant_data$has_phylo_mu, 1L)
  expect_equal(constant_data$n_mu_re_terms, 1L)
  expect_equal(constant_data$has_sd_mu_model, 0L)
  expect_equal(constant_data$has_sd_phylo_model, 0L)
})

test_that("Binomial animal plus IID SD regressions fit and recover both targets", {
  skip_on_cran()
  fx <- binomial_animal_iid_sd_fixture(
    n_id = 192L,
    n_site = 48L,
    n_each = 24L
  )
  A <- fx$A
  fit <- drmTMB(
    bf(
      y ~ x + animal(1 | id, A = A) + (1 | site),
      sd(id, level = "animal") ~ z_animal,
      sd(site) ~ z_iid
    ),
    family = stats::binomial(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_true(is.finite(as.numeric(logLik(fit))))
  expect_setequal(names(coef(fit)), c("mu", "sd_animal(id)", "sd(site)"))
  animal_coef <- coef(fit, "sd_animal(id)")
  iid_coef <- coef(fit, "sd(site)")
  expect_identical(names(animal_coef), c("(Intercept)", "z_animal"))
  expect_identical(names(iid_coef), c("(Intercept)", "z_iid"))
  expect_lt(abs(animal_coef[["z_animal"]] - 0.45), 0.35)
  expect_lt(abs(iid_coef[["z_iid"]] - 0.45), 0.35)

  animal_prediction <- predict(fit, dpar = "sd_animal(id)")
  iid_prediction <- predict(fit, dpar = "sd(site)")
  expect_length(animal_prediction, 192L)
  expect_length(iid_prediction, 48L)
  expect_true(all(animal_prediction > 0))
  expect_true(all(iid_prediction > 0))
  expect_equal(
    unname(animal_prediction),
    unname(fit$sdpars[["sd_animal(id)"]]),
    tolerance = 1e-10
  )
  expect_equal(
    unname(iid_prediction),
    unname(fit$sdpars[["sd(site)"]]),
    tolerance = 1e-10
  )

  save_file <- tempfile(fileext = ".rds")
  on.exit(unlink(save_file), add = TRUE)
  saveRDS(fit, save_file)
  reloaded <- readRDS(save_file)
  expect_equal(coef(reloaded, "sd_animal(id)"), animal_coef)
  expect_equal(coef(reloaded, "sd(site)"), iid_coef)
  expect_equal(predict(reloaded, dpar = "sd_animal(id)"), animal_prediction)
  expect_equal(predict(reloaded, dpar = "sd(site)"), iid_prediction)
})
