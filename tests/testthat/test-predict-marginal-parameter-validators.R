# Fit-free characterisation of the argument validators and plain-vector helpers
# in R/predict-parameters.R and R/marginal-parameters.R. No drmTMB fit is built:
# `predict_parameters_clamp_bent()` gets a minimal stand-in object.

test_that("predict/marginal newdata validators pass NULL and data frames", {
  df <- data.frame(x = 1:2)
  for (v in list(
    drmTMB:::validate_predict_parameters_newdata,
    drmTMB:::validate_marginal_parameters_newdata
  )) {
    expect_invisible(v(NULL))
    expect_null(v(NULL))
    expect_invisible(v(df))
    expect_identical(v(df), df)
    expect_error(v(list(x = 1)), "must be a data frame")
    expect_error(v(matrix(1:4, 2)), "must be a data frame")
    expect_error(v("newdata"), "must be a data frame")
  }
})

test_that("include_newdata and conf.int validators need a single TRUE/FALSE", {
  inc <- drmTMB:::validate_predict_parameters_include_newdata
  ci <- drmTMB:::validate_predict_parameters_conf_int
  for (flag in c(TRUE, FALSE)) {
    expect_invisible(inc(flag))
    expect_identical(inc(flag), flag)
    expect_invisible(ci(flag))
    expect_identical(ci(flag), flag)
  }
  bad <- list(NA, NULL, c(TRUE, FALSE), "TRUE", 1)
  for (b in bad) {
    expect_error(inc(b), "include_newdata.*single")
    expect_error(inc(b), "TRUE.*FALSE")
    expect_error(ci(b), "conf.int.*single")
    expect_error(ci(b), "TRUE.*FALSE")
  }
})

test_that("conf.level validator needs one number strictly between 0 and 1", {
  v <- drmTMB:::validate_predict_parameters_conf_level
  for (ok in c(0.95, 0.5)) {
    expect_invisible(v(ok))
    expect_identical(v(ok), ok)
  }
  bad <- list(0, 1, -0.1, 1.5, NA, Inf, c(0.9, 0.95), "a")
  for (b in bad) {
    expect_error(v(b), "conf.level.*between 0 and 1")
  }
})

test_that("marginal_parameters_by_columns() resolves input and output names", {
  f <- drmTMB:::marginal_parameters_by_columns
  nd <- data.frame(g = 1:2, h = 3:4, type = c("a", "b"), row = 1:2)

  expect_identical(
    f(NULL, NULL),
    list(input = character(), output = character())
  )
  expect_identical(
    f(nd, "g"),
    list(input = "g", output = "g")
  )
  expect_identical(
    f(nd, c("g", "h")),
    list(input = c("g", "h"), output = c("g", "h"))
  )
  # Reserved output column names are prefixed; others are kept.
  expect_identical(
    f(nd, c("type", "g", "row")),
    list(
      input = c("type", "g", "row"),
      output = c("newdata_type", "g", "newdata_row")
    )
  )
  for (r in c(
    "row", "row_label", "dpar", "component", "type", "estimate",
    "conf.status", "interval_source"
  )) {
    d <- stats::setNames(data.frame(1:2), r)
    expect_identical(f(d, r)$output, paste0("newdata_", r))
  }

  expect_error(f(nd, 1), "must be a character vector")
  expect_error(f(nd, character()), "must be a character vector")
  expect_error(f(nd, c("g", NA)), "must be a character vector")
  expect_error(f(NULL, "g"), "requires")
  expect_error(f(nd, c("g", "zzz")), "not present in")
  expect_error(f(nd, "zzz"), "Available columns")
})

test_that("marginal_parameter_group_mean() averages on the right scale", {
  f <- drmTMB:::marginal_parameter_group_mean
  v <- c(1, 2, 4)

  # Link scale: plain mean regardless of component.
  for (comp in c("distributional-scale", "residual-correlation", "location")) {
    expect_equal(f(v, comp, "link"), mean(v))
  }
  # Response scale: location and other components keep the arithmetic mean.
  expect_equal(f(v, "location", "response"), mean(v))
  expect_equal(f(v, "something-else", "response"), mean(v))
  # Dispersion components use the root mean square.
  for (comp in c("distributional-scale", "random-effect-sd-model")) {
    expect_equal(f(v, comp, "response"), sqrt(mean(v^2)))
  }
  # Correlations are averaged on the Fisher-z scale.
  r <- c(0.2, 0.5, 0.8)
  expect_equal(
    f(r, "residual-correlation", "response"),
    tanh(mean(atanh(r)))
  )
  # Values at +/-1 are clamped, so the result stays finite and inside [-1, 1].
  edge <- f(c(1, 1), "residual-correlation", "response")
  expect_true(is.finite(edge))
  expect_lte(edge, 1)
  expect_gt(edge, 0.999)
  expect_equal(
    f(c(-1, -1), "residual-correlation", "response"),
    -edge
  )
})

test_that("predict_parameters_clamp_bent() flags rows outside the clamp band", {
  f <- drmTMB:::predict_parameters_clamp_bent
  fake <- function(model_type = "gaussian", use = 1L, band = c(-2, 2)) {
    list(model = list(
      model_type = model_type,
      tmb_data = list(use_logsigma_clamp = use, logsigma_clamp = band)
    ))
  }
  eta <- c(-3, -2, 0, 2, 3, NA, Inf, -Inf)
  expected <- c(TRUE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE)

  for (dp in c("sigma", "sigma1", "sigma2")) {
    expect_identical(f(fake(), dp, eta), expected)
  }
  # Not a scale parameter: never bent.
  expect_identical(f(fake(), "mu", eta), rep(FALSE, length(eta)))
  # Family outside the clamped set: never bent.
  expect_identical(
    f(fake(model_type = "not_a_family"), "sigma", eta),
    rep(FALSE, length(eta))
  )
  expect_identical(f(list(model = list()), "sigma", eta), rep(FALSE, length(eta)))
  # Clamp disabled or malformed.
  expect_identical(f(fake(use = 0L), "sigma", eta), rep(FALSE, length(eta)))
  expect_identical(f(fake(use = c(1L, 1L)), "sigma", eta), rep(FALSE, length(eta)))
  expect_identical(f(fake(band = 1), "sigma", eta), rep(FALSE, length(eta)))
  expect_identical(f(fake(band = c(NA, 2)), "sigma", eta), rep(FALSE, length(eta)))
  # Zero-length input.
  expect_identical(f(fake(), "sigma", numeric()), logical())
})

test_that("predict_parameters_link_se() takes row-wise sqrt of diag(X V X')", {
  f <- drmTMB:::predict_parameters_link_se
  X <- cbind(1, c(0, 1, 2))
  V <- matrix(c(0.04, 0.01, 0.01, 0.09), 2)
  expected <- sqrt(rowSums((X %*% V) * X))
  expect_equal(f(list(X = X, V = V), 3L), expected)
  expect_null(dim(f(list(X = X, V = V), 3L)))

  # Row-count mismatch gives all NA of length n.
  expect_identical(f(list(X = X, V = V), 2L), rep(NA_real_, 2L))

  # Tiny negative variance (rounding) is floored at 0; a clearly negative or
  # non-finite variance gives NA.
  X1 <- matrix(1, 1, 1)
  expect_identical(f(list(X = X1, V = matrix(-1e-12)), 1L), 0)
  expect_identical(f(list(X = X1, V = matrix(-1)), 1L), NA_real_)
  expect_identical(f(list(X = X1, V = matrix(NA_real_)), 1L), NA_real_)
  expect_identical(f(list(X = X1, V = matrix(Inf)), 1L), NA_real_)

  # Mixed rows are handled independently.
  X2 <- matrix(c(1, 0, 0, 1), 2)
  V2 <- diag(c(4, -1))
  expect_identical(f(list(X = X2, V = V2), 2L), c(2, NA_real_))

  # Data frames and vectors are coerced with as.matrix().
  expect_equal(
    f(list(X = as.data.frame(X), V = as.data.frame(V)), 3L),
    expected
  )
})

test_that("predict_parameters_interval_unavailable() returns an all-NA block", {
  f <- drmTMB:::predict_parameters_interval_unavailable
  out <- f(3L, "no_vcov")
  expect_identical(
    names(out),
    c(
      "std.error", "conf.low", "conf.high", "conf.level", "conf.status",
      "interval_source"
    )
  )
  expect_identical(out$std.error, rep(NA_real_, 3L))
  expect_identical(out$conf.low, rep(NA_real_, 3L))
  expect_identical(out$conf.high, rep(NA_real_, 3L))
  expect_identical(out$conf.level, rep(NA_real_, 3L))
  expect_identical(out$conf.status, rep("no_vcov", 3L))
  expect_identical(out$interval_source, rep("not_available", 3L))

  out2 <- f(2L, "off", conf.level = 0.9)
  expect_identical(out2$conf.level, c(0.9, 0.9))
  expect_identical(out2$conf.status, c("off", "off"))

  zero <- f(0L, "x")
  expect_true(all(lengths(zero) == 0L))
})
