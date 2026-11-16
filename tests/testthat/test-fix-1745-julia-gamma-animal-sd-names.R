# Issue #1745: predict() on a Julia Gamma animal SD fit must keep the
# `dpar:group` names that simulate() matches to the fitted animal groups.
# These objects are constructed in R. They do not call Julia.

gamma_animal_sd_name_object <- function(formula, coefficients, data, A) {
  object <- list(
    formula = formula,
    data = data,
    coefficients = coefficients,
    family = stats::Gamma(link = "log"),
    model = list(model_type = "gamma"),
    bridge_payload = list(kwarg = "A", matrix = A),
    sd_regression_offsets = numeric()
  )
  class(object) <- "drmTMB_julia"
  object
}

gamma_animal_sd_name_data <- function() {
  id_levels <- c("animal_01", "animal_02", "animal_03")
  id <- factor(rep(id_levels, each = 2L), levels = id_levels)
  data.frame(
    y = c(1.1, 0.9, 1.4, 1.2, 0.7, 0.8),
    x = c(-0.4, 0.2, 0.5, -0.1, 0.3, -0.6),
    id = id,
    z = rep(c(-1, 0, 1), each = 2L),
    z0 = rep(c(-1, 1, -1), each = 2L),
    z1 = rep(c(1, -1, 0), each = 2L)
  )
}

test_that("Julia Gamma animal intercept SD predictions keep dpar:group names", {
  dat <- gamma_animal_sd_name_data()
  groups <- unique(as.character(dat$id))
  A <- diag(3)
  A[1, 2] <- A[2, 1] <- 0.25
  dpar <- "sd_animal(id)"
  fit <- gamma_animal_sd_name_object(
    bf(
      y ~ x + animal(1 | id, A = A),
      sigma ~ 1,
      sd(id, level = "animal") ~ z
    ),
    list(
      mu = c(`(Intercept)` = 0.2, x = 0.15),
      sigma = c(`(Intercept)` = log(0.4)),
      sd = c(`(Intercept)` = log(0.42), z = 0.35)
    ),
    dat,
    A
  )

  predicted <- predict(fit, dpar = dpar)
  expect_named(predicted, paste0(dpar, ":", groups))
  expect_true(all(is.finite(predicted) & predicted > 0))

  spec <- drm_julia_gamma_animal_sd_simulation_spec(fit)
  expect_false(is.null(spec))
  expect_identical(names(predicted), paste0(dpar, ":", spec$groups))

  simulated <- simulate(fit, nsim = 1L, seed = 1745L)
  expect_s3_class(simulated, "data.frame")
  expect_named(simulated, "sim_1")
  expect_equal(nrow(simulated), nrow(dat))
  expect_true(all(is.finite(simulated$sim_1) & simulated$sim_1 > 0))
  expect_identical(simulate(fit, nsim = 1L, seed = 1745L), simulated)
})

test_that("Julia Gamma animal coefficient SD predictions keep dpar:group names", {
  dat <- gamma_animal_sd_name_data()
  groups <- unique(as.character(dat$id))
  A <- diag(3)
  key0 <- 'sd_animal(id, dpar = "mu", coef = "(Intercept)")'
  key1 <- 'sd_animal(id, dpar = "mu", coef = "x")'
  fit <- gamma_animal_sd_name_object(
    bf(
      y ~ x + animal(1 + x | id, A = A),
      sigma ~ 1,
      sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ 1,
      sd(id, level = "animal", dpar = "mu", coef = "x") ~ 1
    ),
    list(
      mu = c(`(Intercept)` = 0.1, x = 0.2),
      sigma = c(`(Intercept)` = log(0.35)),
      sd = c(`(Intercept)` = log(0.4))
    ),
    dat,
    A
  )

  expect_named(predict(fit, dpar = key0), paste0(key0, ":", groups))
  expect_named(predict(fit, dpar = key1), paste0(key1, ":", groups))
})

test_that("Julia Gamma SD alignment errors name the SD parameter when coef is omitted", {
  dat <- gamma_animal_sd_name_data()
  A <- diag(3)
  fit <- gamma_animal_sd_name_object(
    bf(
      y ~ x + animal(1 | id, A = A),
      sigma ~ 1,
      sd(id, level = "animal") ~ z
    ),
    list(
      mu = c(`(Intercept)` = 0.2, x = 0.15),
      sigma = c(`(Intercept)` = log(0.4)),
      sd = c(`(Intercept)` = log(0.42), z = 0.35)
    ),
    dat,
    A
  )
  spec <- drm_julia_gamma_animal_sd_simulation_spec(fit)
  expect_true(is.na(spec$components[[1L]]$target$target_coef))
  spec$groups <- paste0("missing_", spec$groups)

  err <- expect_error(
    drm_julia_simulate_gamma_animal_sd(
      object = fit, spec = spec, nsim = 1L, seed = 1L, marginal = TRUE
    ),
    "do not align with animal groups"
  )
  message <- conditionMessage(err)
  expect_match(message, "sd_animal(id)", fixed = TRUE)
  expect_false(grepl("for NA", message, fixed = TRUE))
})

test_that("ordinary Julia SD predictions stay named by group level", {
  dat <- gamma_animal_sd_name_data()
  groups <- unique(as.character(dat$id))
  fit <- gamma_animal_sd_name_object(
    bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ z),
    list(
      mu = c(`(Intercept)` = 0.2, x = 0.15),
      sigma = c(`(Intercept)` = log(0.4)),
      sd = c(`(Intercept)` = log(0.5), z = 0.2)
    ),
    dat,
    diag(3)
  )

  predicted <- predict(fit, dpar = "sd(id)")
  expect_named(predicted, groups)
  expect_false(any(startsWith(names(predicted), "sd(id):")))
})
