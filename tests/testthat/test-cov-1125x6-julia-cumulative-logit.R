# Ordinal Julia bridge prep in R/julia-family-cumulative_logit.R (native prep only).

ord_dat <- function() {
  data.frame(
    y = ordered(rep(c("lo", "mid", "hi"), each = 4), levels = c("lo", "mid", "hi")),
    x = rep(1:4, 3)
  )
}

test_that("drm_julia_cumulative_logit_response() reads the mu response name", {
  form <- bf(y ~ x)
  expect_equal(drmTMB:::drm_julia_cumulative_logit_response(form), "y")
  expect_error(
    drmTMB:::drm_julia_cumulative_logit_response(bf(sigma ~ 1)),
    "location formula"
  )
})

test_that("drm_julia_cumulative_logit_ordinal() validates ordered responses", {
  dat <- ord_dat()
  form <- bf(y ~ x)
  ord <- drmTMB:::drm_julia_cumulative_logit_ordinal(dat, form)
  expect_equal(ord$response, "y")
  expect_equal(length(ord$levels), 3L)
  expect_error(
    drmTMB:::drm_julia_cumulative_logit_ordinal(
      data.frame(y = ordered(c("a", "b"), levels = c("a", "b")), x = 1:2),
      bf(y ~ x)
    ),
    "three"
  )
})

test_that("drm_julia_cumulative_logit_bridge_data() integer-codes the response", {
  dat <- ord_dat()
  form <- bf(y ~ x)
  bridged <- drmTMB:::drm_julia_cumulative_logit_bridge_data(dat, form)
  expect_type(bridged$y, "integer")
  expect_equal(min(bridged$y), 1L)
  expect_equal(max(bridged$y), 3L)
})

test_that("drm_julia_cumulative_logit_coef_labels() drops the intercept and labels cuts", {
  dat <- ord_dat()
  form <- bf(y ~ x)
  labels <- list(mu = c("(Intercept)", "x"))
  out <- drmTMB:::drm_julia_cumulative_logit_coef_labels(labels, form, dat)
  expect_false("(Intercept)" %in% out$mu)
  expect_equal(length(out$cutpoints), 2L)
  expect_match(out$cutpoints[[1]], "\\|")
})