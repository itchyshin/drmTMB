# #1758: Poisson with two or more ordinary sd() targets passes the #1551 fence
# and then died with a raw Julia `coef_labels ... unknown dpar
# "sdtarget_<hex>"` error after the fit. drmTMB now refuses it in R, before
# Julia starts. Static: no Julia is started, so these tests check the R
# admission gate only.

multi_sd_dat <- function() {
  set.seed(1)
  ng <- 30
  g <- factor(rep(seq_len(ng), each = 8))
  h <- factor(sample(1:10, 240, TRUE))
  x <- stats::rnorm(240)
  y <- stats::rpois(240, exp(0.3 + 0.5 * x))
  data.frame(y, x, g, h)
}

multi_sd_error <- function(formula, family = stats::poisson(), data = multi_sd_dat()) {
  withr::local_envvar(DRM_JL_PATH = NA, DRM_JL_PHYLO_PATH = NA, DRMODELS_JL_PATH = NA)
  withr::local_options(drmTMB.DRModels.jl.path = NULL, drmTMB.DRM.jl.path = NULL)
  tryCatch(
    drmTMB(formula, family = family, data = data, engine = "julia"),
    error = function(e) e
  )
}

refusal <- "does not yet fit \"poisson\" with more than one ordinary"

test_that("Poisson with two ordinary sd() targets is refused before Julia (#1758)", {
  slope <- multi_sd_error(bf(
    y ~ x + (1 | g) + (0 + x | g),
    sd(g, dpar = "mu", coef = "(Intercept)") ~ 1,
    sd(g, dpar = "mu", coef = "x") ~ 1
  ))
  expect_s3_class(slope, "error")
  expect_match(conditionMessage(slope), refusal, fixed = TRUE)
  expect_match(conditionMessage(slope), "engine = \"tmb\"", fixed = TRUE)

  crossed <- multi_sd_error(bf(y ~ x + (1 | g) + (1 | h), sd(g) ~ 1, sd(h) ~ 1))
  expect_s3_class(crossed, "error")
  expect_match(conditionMessage(crossed), refusal, fixed = TRUE)
})

test_that("one ordinary sd() target and other families are not refused by this fence", {
  one <- multi_sd_error(bf(y ~ x + (1 | g), sd(g) ~ 1))
  expect_s3_class(one, "error")
  expect_false(grepl(refusal, conditionMessage(one), fixed = TRUE))

  nb <- multi_sd_error(
    bf(y ~ x + (1 | g) + (1 | h), sigma ~ 1, sd(g) ~ 1, sd(h) ~ 1),
    family = nbinom2()
  )
  expect_s3_class(nb, "error")
  expect_false(grepl("more than one ordinary", conditionMessage(nb), fixed = TRUE))
})

test_that("the target helper counts ordinary mu sd() targets only", {
  helper <- drmTMB:::drm_julia_ordinary_sd_target_labels
  expect_length(helper(bf(y ~ x + (1 | g), sd(g) ~ 1)), 1L)
  expect_length(helper(bf(y ~ x + (1 | g) + (1 | h), sd(g) ~ 1, sd(h) ~ 1)), 2L)
  expect_length(helper(bf(y ~ x + (1 | g), sd(g, level = "animal") ~ 1)), 0L)
})
