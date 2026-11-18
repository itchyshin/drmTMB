beta_binomial_sd_slope_data <- function(
  groups = 72L,
  repeats = 18L,
  seed = 202610207L
) {
  set.seed(seed)
  group <- factor(rep(seq_len(groups), each = repeats))
  w_group <- seq(-1, 1, length.out = groups)
  w <- rep(w_group, each = repeats)
  x <- stats::rnorm(length(group))
  slope_sd <- exp(log(0.35) + 0.4 * w_group)
  slope <- stats::rnorm(groups, sd = slope_sd)
  mu <- stats::plogis(-0.1 + 0.55 * x + slope[as.integer(group)] * x)
  trials <- rep(12L, length(group))
  sigma <- 0.22
  precision <- 1 / sigma^2
  probability <- stats::rbeta(
    length(group),
    shape1 = mu * precision,
    shape2 = (1 - mu) * precision
  )
  success <- stats::rbinom(length(group), size = trials, prob = probability)
  data.frame(success, failure = trials - success, x, w, group)
}

test_that("beta-binomial SD regression resolves an independent slope target", {
  dat <- beta_binomial_sd_slope_data(groups = 12L, repeats = 8L)
  spec <- drm_build_beta_binomial_spec(
    bf(
      cbind(success, failure) ~ 1 + x + (0 + x | group),
      sigma ~ 1,
      sd(group, coef = "x") ~ w
    ),
    dat
  )

  expect_identical(spec$model_type, "beta_binomial")
  expect_identical(spec$random_scale$mu$dpars, "sd(group, coef = \"x\")")
  expect_identical(spec$random_scale$mu$target_identity[["sd(group, coef = \"x\")"]]$coef, "x")
  expect_identical(spec$random$mu$coef_names, "x")
  expect_identical(spec$tmb_data$has_sd_mu_model, 1L)
  expect_true(all(spec$tmb_data$mu_re_sd_row >= 0L))
  expect_length(spec$start$beta_sd_mu, 2L)
})

test_that("beta-binomial predictor-dependent slope SD recovers and predicts", {
  dat <- beta_binomial_sd_slope_data()
  fit <- drmTMB(
    bf(
      cbind(success, failure) ~ 1 + x + (0 + x | group),
      sigma ~ 1,
      sd(group, coef = "x") ~ w
    ),
    family = beta_binomial(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_true(is_converged(fit))
  estimate <- stats::coef(fit, dpar = "sd(group, coef = \"x\")")
  expect_lt(abs(estimate[["w"]] - 0.4), 0.5)
  predicted_sd <- stats::predict(
    fit,
    newdata = data.frame(
      group = factor(levels(dat$group)[1L], levels = levels(dat$group)),
      w = c(-1, 0, 1)
    ),
    dpar = "sd(group, coef = \"x\")"
  )
  expect_true(all(diff(as.numeric(predicted_sd)) > 0))
  simulated <- stats::simulate(fit, nsim = 1L, seed = 202610208L)
  expect_equal(nrow(simulated), nrow(dat))

  save_path <- tempfile(fileext = ".rds")
  saveRDS(fit, save_path)
  restored <- readRDS(save_path)
  expect_equal(
    stats::predict(
      restored,
      newdata = data.frame(
        group = factor(levels(dat$group)[1L], levels = levels(dat$group)),
        w = c(-1, 0, 1)
      ),
      dpar = "sd(group, coef = \"x\")"
    ),
    predicted_sd
  )
})
