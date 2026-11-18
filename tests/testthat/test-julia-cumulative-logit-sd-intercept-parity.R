cumulative_logit_sd_intercept_bridge_data <- function(groups = 256L,
                                                       repeats = 30L,
                                                       seed = 202610206L) {
  set.seed(seed)
  id <- factor(rep(seq_len(groups), each = repeats))
  w_group <- seq(-1, 1, length.out = groups)
  w <- w_group[as.integer(id)]
  x <- stats::rnorm(length(id))
  intercept_sd <- exp(-1 + 0.5 * w_group)
  random_intercept <- stats::rnorm(groups, sd = intercept_sd)
  latent <- 0.45 * x + random_intercept[as.integer(id)] +
    stats::rlogis(length(id))
  category <- cut(
    latent,
    breaks = c(-Inf, -0.75, 0.75, Inf),
    labels = c("low", "middle", "high"),
    ordered_result = TRUE
  )
  data.frame(score = ordered(category, levels = c("low", "middle", "high")),
             x = x, w = w, id = id)
}

test_that("cumulative-logit bridge admits a matched random-intercept SD", {
  dat <- cumulative_logit_sd_intercept_bridge_data(groups = 30L, repeats = 30L)
  form <- bf(score ~ x + (1 | id), sd(id) ~ w)

  expect_true(drmTMB:::drm_julia_cumulative_logit_intercept_sd_route_admitted(
    form
  ))
  expect_invisible(drmTMB:::drm_julia_refuse_fe_only_random_effects(
    form, "cumulative_logit", data = dat
  ))

  mismatched_target <- bf(score ~ x + (1 | id), sd(other) ~ w)
  expect_false(drmTMB:::drm_julia_cumulative_logit_intercept_sd_route_admitted(
    mismatched_target
  ))
  expect_error(
    drmTMB:::drm_julia_refuse_fe_only_random_effects(
      mismatched_target, "cumulative_logit", data = dat
    ),
    "Found a random-effect bar term"
  )
})

test_that("cumulative-logit random-intercept SD has same-data Julia bridge parity", {
  skip_if_not(identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true"),
              "Julia bridge tests are opt-in")

  dat <- cumulative_logit_sd_intercept_bridge_data()
  form <- bf(score ~ x + (1 | id), sd(id) ~ w)
  target <- "sd(id)"
  control <- drm_control(se = FALSE)

  fit_tmb <- drmTMB(form, family = cumulative_logit(), data = dat,
                    engine = "tmb", control = control)
  fit_julia <- drmTMB(form, family = cumulative_logit(), data = dat,
                      engine = "julia")

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  expect_true(is.finite(as.numeric(logLik(fit_tmb))))
  expect_true(is.finite(as.numeric(logLik(fit_julia))))

  beta_tmb <- coef(fit_tmb, dpar = target)
  beta_julia <- coef(fit_julia, dpar = target)
  expect_named(beta_tmb, c("(Intercept)", "w"))
  expect_named(beta_julia, names(beta_tmb))
  expect_gt(unname(beta_tmb[["w"]]), 0)
  expect_gt(unname(beta_julia[["w"]]), 0)
  expect_lt(abs(unname(beta_tmb[["w"]]) - 0.5), 0.2)
  expect_lt(abs(unname(beta_julia[["w"]]) - 0.5), 0.2)
  expect_lt(abs(unname(beta_julia[["w"]] - beta_tmb[["w"]])), 0.3)

  prediction_data <- data.frame(
    id = factor(levels(dat$id)[1:3], levels = levels(dat$id)),
    w = c(-1, 0, 1)
  )
  pred_tmb <- predict(fit_tmb, newdata = prediction_data, dpar = target)
  pred_julia <- predict(fit_julia, newdata = prediction_data, dpar = target)
  expect_length(pred_tmb, 3L)
  expect_length(pred_julia, 3L)
  expect_true(all(diff(as.numeric(pred_tmb)) > 0))
  expect_true(all(diff(as.numeric(pred_julia)) > 0))
  expect_equal(as.numeric(pred_julia), as.numeric(pred_tmb), tolerance = 0.35)
})
