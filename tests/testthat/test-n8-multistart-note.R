# #1469: at n = 8 with a 4-parameter location-scale model the likelihood can
# have two maxima; the default fit stops on one of them with status
# "converged" and nothing points the user at multi_start. The small-sample
# note in check_drm() now names multi_start when it was not used.

n8_gen <- function(r) {
  RNGkind("Mersenne-Twister", "Inversion", "Rejection")
  set.seed(933663568L + r - 1L)
  x <- rnorm(8)
  data.frame(y = 1 + 0.5 * x + exp(-0.4 + 0.3 * x) * rnorm(8), x = x)
}

n8_row <- function(fit) {
  chk <- check_drm(fit)
  chk[chk$check == "observations_per_parameter", ]
}

test_that("low n per parameter note recommends multi_start when unused (#1469)", {
  fit <- drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = n8_gen(5))
  expect_true(is_converged(fit))
  row <- n8_row(fit)
  expect_equal(row$status, "note")
  expect_match(row$message, "multi_start", fixed = TRUE)
  expect_match(row$message, "multimodal", fixed = TRUE)
})

test_that("the multi_start advice is dropped once multi_start was used (#1469)", {
  fit <- drmTMB(
    bf(y ~ x, sigma ~ x), family = gaussian(), data = n8_gen(5),
    control = drm_control(multi_start = 4)
  )
  row <- n8_row(fit)
  expect_equal(row$status, "note")
  expect_no_match(row$message, "multi_start", fixed = TRUE)
})

test_that("ok rows are unchanged at adequate n (#1469)", {
  set.seed(1)
  d <- data.frame(y = rnorm(120), x = rnorm(120))
  fit <- drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = d)
  row <- n8_row(fit)
  expect_equal(row$status, "ok")
  expect_no_match(row$message, "multi_start", fixed = TRUE)
})
