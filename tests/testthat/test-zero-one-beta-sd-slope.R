test_that("zero-one beta location SD regression targets an independent slope", {
  groups <- 12L
  repeats <- 4L
  id <- factor(rep(seq_len(groups), each = repeats))
  dat <- data.frame(
    prop = rep(c(0, 1, 0.25, 0.75), groups),
    w = rep(seq(-1, 1, length.out = groups), each = repeats),
    x = rep(c(-1, 0, 1, 0.5), groups),
    id = id
  )

  spec <- drm_build_zero_one_beta_spec(
    bf(
      prop ~ 0 + x + (0 + x | id),
      sd(id, coef = "x") ~ w
    ),
    dat
  )

  target <- spec$random_scale$mu$target_identity[["sd(id, coef = \"x\")"]]
  expect_identical(target$dpar, "mu")
  expect_identical(target$group, "id")
  expect_identical(target$coef, "x")
  expect_identical(spec$tmb_data$has_sd_mu_model, 1L)
  expect_true(all(spec$random_scale$mu$re_sd_row0 >= 0L))
  expect_equal(
    unname(spec$random_scale$mu$X_list[["sd(id, coef = \"x\")"]][, "w"]),
    seq(-1, 1, length.out = 12L)
  )
})

zero_one_beta_slope_sd_data <- function(
  groups = 80L,
  repeats = 16L,
  beta_sd = c("(Intercept)" = log(0.30), w = 0.45),
  seed = 20261021L
) {
  set.seed(seed)
  id <- factor(rep(seq_len(groups), each = repeats))
  w_group <- seq(-1.2, 1.2, length.out = groups)
  w <- w_group[as.integer(id)]
  x <- rep(seq(-1, 1, length.out = repeats), groups)
  tau <- exp(beta_sd[["(Intercept)"]] + beta_sd[["w"]] * w_group)
  slope <- stats::rnorm(groups, sd = tau)
  mu <- stats::plogis(-0.25 + 0.7 * x + slope[as.integer(id)] * x)
  sigma <- 0.42
  phi <- 1 / sigma^2
  prop <- stats::rbeta(length(x), mu * phi, (1 - mu) * phi)
  boundary <- stats::rbinom(length(x), size = 1L, prob = 0.16) == 1L
  prop[boundary] <- stats::rbinom(sum(boundary), size = 1L, prob = 0.58)
  data.frame(prop, x, w, id)
}

test_that("zero-one beta slope SD regression recovers and predicts group SDs", {
  dat <- zero_one_beta_slope_sd_data()
  fit <- drmTMB(
    bf(
      prop ~ x + (0 + x | id),
      sigma ~ 1,
      zoi ~ 1,
      coi ~ 1,
      sd(id, coef = "x") ~ w
    ),
    family = zero_one_beta(),
    data = dat,
    control = drm_control(se = TRUE)
  )

  expect_true(is_converged(fit))
  target <- 'sd(id, coef = "x")'
  estimate <- stats::coef(fit, dpar = target)
  expect_named(estimate, c("(Intercept)", "w"))
  expect_lt(abs(estimate[["w"]] - 0.45), 0.30)
  predicted <- stats::predict(fit, dpar = target)
  expect_true(all(diff(as.numeric(predicted)) > 0))
  expect_true(all(is.finite(stats::vcov(fit, dpar = target))))

  simulated <- stats::simulate(fit, nsim = 1L, seed = 20261022L)
  expect_equal(nrow(simulated), nrow(dat))
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(fit, path)
  restored <- readRDS(path)
  expect_identical(
    restored$model$random_scale$mu$target_identity,
    fit$model$random_scale$mu$target_identity
  )
  expect_equal(
    stats::predict(restored, dpar = target),
    predicted
  )
})

test_that("constant zero-one beta slope SD matches the existing slope fit", {
  dat <- zero_one_beta_slope_sd_data(groups = 32L, repeats = 12L)
  control <- drm_control(se = FALSE)
  baseline <- drmTMB(
    bf(prop ~ x + (0 + x | id), sigma ~ 1, zoi ~ 1, coi ~ 1),
    family = zero_one_beta(),
    data = dat,
    control = control
  )
  constant <- drmTMB(
    bf(
      prop ~ x + (0 + x | id),
      sigma ~ 1,
      zoi ~ 1,
      coi ~ 1,
      sd(id, coef = "x") ~ 1
    ),
    family = zero_one_beta(),
    data = dat,
    control = control
  )

  expect_true(is_converged(baseline))
  expect_true(is_converged(constant))
  expect_equal(
    as.numeric(stats::logLik(constant)),
    as.numeric(stats::logLik(baseline)),
    tolerance = 1e-5
  )
})
