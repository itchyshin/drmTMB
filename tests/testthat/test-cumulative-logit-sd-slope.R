cumulative_logit_sd_slope_data <- function(groups = 256L, repeats = 30L,
                                           seed = 202610205L) {
  set.seed(seed)
  id <- factor(rep(seq_len(groups), each = repeats))
  w_group <- seq(-1, 1, length.out = groups)
  w <- w_group[as.integer(id)]
  x <- stats::rnorm(length(id))
  slope_sd <- exp(-1 + 0.5 * w_group)
  random_slope <- stats::rnorm(groups, sd = slope_sd)
  latent <- 0.45 * x + random_slope[as.integer(id)] * x +
    stats::rlogis(length(id))
  category <- cut(
    latent,
    breaks = c(-Inf, -0.75, 0.75, Inf),
    labels = c("low", "middle", "high"),
    ordered_result = TRUE
  )
  data.frame(
    score = ordered(category, levels = c("low", "middle", "high")),
    x = x,
    w = w,
    id = id
  )
}

test_that("cumulative-logit SD regression assembles an independent slope target", {
  dat <- cumulative_logit_sd_slope_data(groups = 12L, repeats = 5L)
  spec <- drm_build_cumulative_logit_spec(
    bf(score ~ x + (0 + x | id), sd(id, coef = "x") ~ w),
    dat
  )

  expect_identical(spec$model_type, "cumulative_logit")
  target <- spec$random_scale$mu$target_identity[["sd(id, coef = \"x\")"]]
  expect_identical(target$dpar,
                   "mu")
  expect_identical(target$coef, "x")
  expect_identical(spec$random$mu$coef_names, "x")
  expect_identical(spec$tmb_data$has_sd_mu_model, 1L)
  expect_true(all(spec$tmb_data$mu_re_sd_row >= 0L))
  expect_length(spec$start$beta_sd_mu, 2L)
})

test_that("cumulative-logit predictor-dependent slope SD recovers and predicts", {
  dat <- cumulative_logit_sd_slope_data()
  fit <- drmTMB(
    bf(score ~ x + (0 + x | id), sd(id, coef = "x") ~ w),
    family = cumulative_logit(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_true(is_converged(fit))
  estimate <- stats::coef(fit, dpar = "sd(id, coef = \"x\")")
  expect_lt(abs(estimate[["w"]] - 0.5), 0.2)
  predicted_sd <- stats::predict(
    fit,
    newdata = data.frame(
      id = factor(levels(dat$id)[1L], levels = levels(dat$id)),
      w = c(-1, 0, 1)
    ),
    dpar = "sd(id, coef = \"x\")"
  )
  expect_true(all(diff(as.numeric(predicted_sd)) > 0))
})
