# #1497: a fixed-effect predictor stored as character (read.csv with
# stringsAsFactors = FALSE, tibbles) must predict on any subset of its training
# values, exactly like the same column stored as a factor.

new_character_predictor_fit <- function(as_factor = FALSE) {
  set.seed(1)
  d <- data.frame(
    y = stats::rnorm(30) + rep(c(0, 0.5, 1), 10),
    chr = rep(c("u", "v", "w"), 10),
    stringsAsFactors = FALSE
  )
  if (as_factor) {
    d$chr <- factor(d$chr)
  }
  drmTMB(bf(y ~ chr, sigma ~ 1), data = d, family = gaussian())
}

test_that("predict(newdata) handles partial grids of a character predictor", {
  fit_chr <- new_character_predictor_fit()
  fit_fac <- new_character_predictor_fit(as_factor = TRUE)
  full <- predict(fit_chr, newdata = data.frame(chr = c("u", "v", "w")))
  expect_equal(
    full,
    predict(fit_fac, newdata = data.frame(chr = c("u", "v", "w"))),
    tolerance = 1e-6
  )

  partial <- predict(fit_chr, newdata = data.frame(chr = c("v", "w")))
  expect_equal(unname(partial), unname(full[2:3]), tolerance = 1e-8)

  for (k in 1:3) {
    one <- predict(fit_chr, newdata = data.frame(chr = c("u", "v", "w")[k]))
    expect_equal(unname(one), unname(full[k]), tolerance = 1e-8)
  }

  one_sigma <- predict(
    fit_chr,
    newdata = data.frame(chr = "w"),
    dpar = "sigma"
  )
  expect_length(one_sigma, 1L)
})

test_that("predict(newdata) names unseen character predictor values", {
  fit_chr <- new_character_predictor_fit()
  expect_error(
    predict(fit_chr, newdata = data.frame(chr = "z")),
    "unknown factor level"
  )
})

test_that("predict(newdata) handles a one-value grid of a logical predictor", {
  set.seed(2)
  d <- data.frame(y = stats::rnorm(30), flag = rep(c(TRUE, FALSE), 15))
  fit <- drmTMB(bf(y ~ flag, sigma ~ 1), data = d, family = gaussian())
  both <- predict(fit, newdata = data.frame(flag = c(FALSE, TRUE)))
  expect_equal(
    unname(predict(fit, newdata = data.frame(flag = TRUE))),
    unname(both[2]),
    tolerance = 1e-8
  )
})
