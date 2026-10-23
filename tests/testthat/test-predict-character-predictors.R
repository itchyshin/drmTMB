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

# #1508 review: only columns used as bare terms are re-levelled; a variable
# that also enters a transform must reach that transform with its raw values.
manual_eta <- function(fit, formula_rhs, newdata) {
  X <- stats::model.matrix(formula_rhs, newdata)
  beta <- fit$coefficients$mu
  as.vector(X[, names(beta), drop = FALSE] %*% beta)
}

test_that("transformed uses of a logical predictor keep their raw values", {
  set.seed(4)
  d <- data.frame(
    y = stats::rnorm(40),
    flag = rep(c(TRUE, FALSE), 20),
    x = stats::rnorm(40)
  )
  fit <- drmTMB(bf(y ~ flag + x:as.numeric(flag), sigma ~ 1), data = d)
  nd <- data.frame(flag = TRUE, x = 2)
  full <- rbind(nd, data.frame(flag = FALSE, x = 2))
  expect_equal(
    unname(predict(fit, newdata = nd)),
    manual_eta(fit, ~ flag + x:as.numeric(flag), full)[1],
    tolerance = 1e-8
  )
})

test_that("a character predictor used bare and inside a transform still predicts", {
  set.seed(5)
  d <- data.frame(
    y = stats::rnorm(30),
    chr = rep(c("a", "bb", "ccc"), 10),
    stringsAsFactors = FALSE
  )
  fit <- drmTMB(bf(y ~ chr + nchar(chr), sigma ~ 1), data = d)
  nd <- data.frame(chr = c("a", "bb", "ccc"), stringsAsFactors = FALSE)
  expect_length(predict(fit, newdata = nd), 3L)
})

test_that("keep_model_frame = FALSE keeps transformed-only columns raw", {
  set.seed(6)
  d <- data.frame(
    y = stats::rnorm(40),
    x = stats::rnorm(40),
    flag = rep(c(TRUE, FALSE), 20)
  )
  fit <- drmTMB(
    bf(y ~ x + as.numeric(flag), sigma ~ 1),
    data = d,
    control = drm_control(keep_model_frame = FALSE)
  )
  nd <- data.frame(x = 0, flag = c(FALSE, TRUE))
  expect_equal(
    unname(predict(fit, newdata = nd)),
    manual_eta(fit, ~ x + as.numeric(flag), nd),
    tolerance = 1e-8
  )
})

test_that("a character or logical binary mi() predictor survives a data-only template", {
  # Mirrors test-missing-predictor-prediction.R's mi_prediction_object():
  # keep_model_frame = FALSE leaves fit$data as the template, where the raw
  # binary predictor is character or logical rather than a factor.
  base <- list(
    model = list(
      model_type = "gaussian",
      terms = list(mu = stats::terms(~ z + mi(x)))
    ),
    missing_data = list(
      original_row = 11:14,
      model_row = 1:4,
      predictors = list(x = list(
        variable = "x",
        family = "bernoulli",
        levels = c("no", "yes"),
        observed = c(TRUE, FALSE, TRUE, FALSE),
        value = c(0.1, 0.8, 0.3, 0.6),
        model_row = c(2L, 4L),
        original_row = c(12L, 14L),
        summary = "conditional_probability"
      ))
    )
  )
  for (raw in list(c("no", NA, "yes", NA), c(FALSE, NA, TRUE, NA))) {
    object <- base
    object$data <- data.frame(x = raw, z = c(-.5, 0, .5, 1))
    if (is.logical(raw)) {
      object$missing_data$predictors$x$levels <- c("FALSE", "TRUE")
    }
    newdata <- data.frame(x = as.character(raw[c(3, 1)]), z = c(-.25, .75))
    out <- drmTMB:::drm_prepare_prediction_newdata(object, newdata, "mu")
    expect_equal(out$x, c(1, 0))
  }
})
