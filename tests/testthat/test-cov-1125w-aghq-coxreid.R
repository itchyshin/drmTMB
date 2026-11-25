# Coverage for R/aghq-coxreid.R pack/unpack helpers (complement test-aghq-coxreid.R).

test_that("drm_o3_npar() counts fixed parameters per family", {
  f <- drmTMB:::drm_o3_npar
  expect_identical(f("binomial", p = 3L, K = 4L), 3L)
  expect_identical(f("cumulative_logit", p = 2L, K = 4L), 5L)
})

test_that("drm_o3_split() unpacks beta and cutpoints", {
  split <- drmTMB:::drm_o3_split
  expect_identical(
    split(c(1, 2, 3), "binomial", p = 3L),
    list(beta = c(1, 2, 3), theta = NULL)
  )
  out <- split(c(0.1, 0.2, 0.3, 0.4), "cumulative_logit", p = 2L)
  expect_identical(out$beta, c(0.1, 0.2))
  expect_identical(out$theta, c(0.3, 0.4))
})