test_that("prediction_grid() builds mean-reference grids for focal terms", {
  set.seed(20260522)
  dat <- data.frame(
    y = stats::rnorm(90),
    temperature = seq(-2, 2, length.out = 90),
    habitat = factor(rep(c("reef", "kelp", "sand"), length.out = 90)),
    season = rep(c("dry", "wet"), length.out = 90),
    tagged = rep(c(TRUE, FALSE), length.out = 90)
  )
  fit <- drmTMB(
    bf(y ~ temperature + habitat + season + tagged, sigma ~ temperature),
    family = gaussian(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  grid <- prediction_grid(
    fit,
    focal = c("temperature", "habitat"),
    at = list(temperature = c(-1, 0, 1)),
    condition = list(season = "wet")
  )

  expect_s3_class(grid, "drm_prediction_grid")
  expect_named(grid, c("temperature", "habitat", "season", "tagged"))
  expect_equal(nrow(grid), 9L)
  expect_equal(grid$temperature, rep(c(-1, 0, 1), 3))
  expect_equal(as.character(grid$habitat), rep(levels(dat$habitat), each = 3))
  expect_equal(as.character(grid$season), rep("wet", 9))
  expect_equal(levels(grid$habitat), levels(dat$habitat))
  expect_true(is.logical(grid$tagged))
  expect_equal(grid$tagged, rep(dat$tagged[[1L]], 9))

  info <- attr(grid, "prediction_grid")
  expect_equal(info$focal_terms, c("temperature", "habitat"))
  expect_equal(info$conditioned_terms, "season")
  expect_equal(info$margin, "mean_reference")
  expect_equal(info$weights, "equal")
  expect_equal(info$n_source_rows, nrow(dat))
  expect_equal(info$n_grid_rows, nrow(grid))

  pred <- predict_parameters(fit, newdata = grid, dpar = c("mu", "sigma"))
  expect_equal(nrow(pred), 18L)
  expect_equal(pred$estimate[pred$dpar == "mu"], predict(fit, newdata = grid))
})

test_that("prediction_grid() supports random-effect scale predictors", {
  sim <- new_gaussian_re_scale_data(n_id = 12, n_each = 4, seed = 20260569)
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ w),
    family = gaussian(),
    data = sim$data,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 120L, iter.max = 120L)
    )
  )

  grid <- prediction_grid(fit, focal = "w", at = list(w = c(-0.2, 0.4)))
  pred <- predict_parameters(fit, newdata = grid, dpar = "sd(id)")
  avg <- marginal_parameters(fit, newdata = grid, dpar = "sd(id)", by = "w")

  expect_s3_class(grid, "drm_prediction_grid")
  expect_equal(grid$w, c(-0.2, 0.4))
  expect_equal(attr(grid, "prediction_grid")$focal_terms, "w")
  expect_equal(unique(pred$component), "random-effect-sd-model")
  expect_equal(
    pred$estimate,
    unname(predict(fit, newdata = grid, dpar = "sd(id)"))
  )
  expect_equal(avg$w, grid$w)
  expect_equal(avg$estimate, pred$estimate)
  expect_equal(avg$n, c(1L, 1L))
})

test_that("prediction_grid() uses automatic focal values", {
  set.seed(20260523)
  dat <- data.frame(
    y = stats::rnorm(12),
    x = rep(c(0, 1, 2), each = 4),
    group = factor(rep(c("a", "b"), length.out = 12))
  )
  fit <- drmTMB(
    bf(y ~ x + group, sigma ~ 1),
    data = dat,
    control = drm_control(se = FALSE)
  )

  grid <- prediction_grid(fit, focal = c("x", "group"), n = 2)

  expect_equal(grid$x, rep(c(0, 2), 2))
  expect_equal(as.character(grid$group), rep(levels(dat$group), each = 2))
  expect_equal(attr(grid, "prediction_grid")$reference_terms, character())
})

test_that("prediction_grid() can cross focal values with empirical rows", {
  set.seed(20260524)
  dat <- data.frame(
    y = stats::rnorm(20),
    x = stats::rnorm(20),
    habitat = factor(rep(c("reef", "kelp"), length.out = 20)),
    site = factor(rep(letters[1:4], length.out = 20))
  )
  fit <- drmTMB(
    bf(y ~ x + habitat + site, sigma ~ x),
    family = gaussian(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  grid <- prediction_grid(
    fit,
    focal = "x",
    at = list(x = c(-0.5, 0.5)),
    condition = list(habitat = "reef"),
    margin = "empirical",
    weights = "proportional"
  )

  expect_equal(nrow(grid), 2L * nrow(dat))
  expect_equal(grid$x, rep(c(-0.5, 0.5), each = nrow(dat)))
  expect_equal(as.character(grid$habitat), rep("reef", nrow(grid)))
  expect_equal(as.character(grid$site), rep(as.character(dat$site), 2))
  expect_equal(attr(grid, "prediction_grid")$margin, "empirical")
  expect_equal(attr(grid, "prediction_grid")$weights, "proportional")

  out <- marginal_parameters(fit, newdata = grid, dpar = "mu", by = "x")
  expect_equal(out$n, rep(nrow(dat), 2))
  expect_equal(out$x, c(-0.5, 0.5))
})

test_that("prediction_grid() validates grid arguments", {
  dat <- data.frame(
    y = stats::rnorm(12),
    x = stats::rnorm(12),
    habitat = factor(rep(c("reef", "kelp"), 6))
  )
  fit <- drmTMB(
    bf(y ~ x + habitat, sigma ~ x),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_error(prediction_grid(fit, focal = "missing"), "unknown predictor")
  expect_error(
    prediction_grid(fit, focal = "x", at = list(habitat = "reef")),
    "can only name focal"
  )
  expect_error(
    prediction_grid(fit, focal = "x", condition = list(x = 0)),
    "both focal and conditioned"
  )
  expect_error(
    prediction_grid(fit, focal = "habitat", at = list(habitat = "forest")),
    "invalid level"
  )
  expect_error(prediction_grid(fit, focal = "x", n = 0), "positive whole")
  expect_error(
    prediction_grid(fit, focal = "x", condition = data.frame(x = 1)),
    "named list"
  )
  expect_error(
    prediction_grid(fit, focal = "x", condition = list(habitat = NA)),
    "cannot be missing"
  )
  expect_error(
    prediction_grid(
      drmTMB(
        bf(y ~ x + habitat, sigma ~ x),
        data = dat,
        control = drm_control(se = FALSE, keep_data = FALSE)
      ),
      focal = "x"
    ),
    "retain its fitted model data"
  )
})
