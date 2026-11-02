# A Poisson SD-regression fit with an offset is not admitted through
# engine = "julia": the DRM.jl bridge translator refuses `offset(...)` on every
# route (it needs a fixed, non-estimated coefficient). An earlier version of
# this file asserted native-vs-Julia parity for this route; it could not pass,
# because the Julia side always refused. The refusal now happens in R, before
# Julia starts, with the classed condition used for every other offset.

test_that("Poisson SD regression with an offset is refused in R before Julia starts", {
  set.seed(20261023L)
  groups <- 32L
  repeats <- 20L
  id_index <- rep(seq_len(groups), each = repeats)
  z_group <- rep(c(-1, 1), each = groups / 2L)
  z <- z_group[id_index]
  id <- factor(id_index)
  x <- stats::rnorm(length(id_index))
  exposure <- stats::runif(length(id_index), min = 0.4, max = 2.2)
  alpha <- c(`(Intercept)` = -0.4, z = 0.45)
  b <- exp(alpha[[1L]] + alpha[[2L]] * z_group) * stats::rnorm(groups)
  y <- stats::rpois(
    length(id_index),
    exposure * exp(0.3 + 0.25 * x + b[id_index])
  )
  dat <- data.frame(y, x, z, exposure, id)
  formula <- bf(
    y ~ x + offset(log(exposure)) + (1 | id),
    sd(id, coef = "(Intercept)") ~ z
  )

  expect_error(
    drmTMB(formula, family = poisson(), data = dat, engine = "julia"),
    class = "drmTMB_julia_offset_unsupported"
  )
  # The refusal points to the native engine, which does fit this model.
  expect_error(
    drmTMB(formula, family = poisson(), data = dat, engine = "julia"),
    "engine = \"tmb\""
  )
  fit_tmb <- drmTMB(formula, family = poisson(), data = dat)
  expect_true(is_converged(fit_tmb))
})
