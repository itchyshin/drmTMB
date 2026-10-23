# Stored conditional prediction for the one admitted Julia-engine RE route.
# These are pure R payload tests: no JuliaCall session or engine fit is needed.

conditional_gaussian_ri_fixture <- function(payload = TRUE) {
  data <- data.frame(
    y = c(-1, 0, 1, 2),
    x = c(-2, -1, 1, 2),
    g = factor(c("b", "a", "b", "a"), levels = c("a", "b"))
  )
  out <- structure(
    list(
      formula = list(entries = list(
        list(dpar = "mu", rhs = quote(x + (1 | g)), structured = list()),
        list(dpar = "sigma", rhs = quote(1), structured = list())
      )),
      family = stats::gaussian(),
      model = list(model_type = "gaussian"),
      data = data,
      coefficients = list(
        mu = c("(Intercept)" = 0.5, x = 0.3),
        sigma = c("(Intercept)" = -0.2)
      ),
      engine = "julia"
    ),
    class = "drmTMB_julia"
  )
  if (isTRUE(payload)) {
    # Julia's `_group_index` order is first appearance: b then a, which is
    # deliberately different from this factor's declared a/b level order.
    out$conditional_re <- list(
      kind = "gaussian_mu_random_intercept_v1",
      group = "g",
      levels = c("b", "a"),
      gidx = c(1L, 2L, 1L, 2L),
      blup = c(0.6, -0.25)
    )
  }
  out
}

test_that("stored Gaussian ordinary random-intercept mu uses validated BLUPs", {
  fit <- conditional_gaussian_ri_fixture()
  fixed <- 0.5 + 0.3 * fit$data$x
  expected <- fixed + c(0.6, -0.25, 0.6, -0.25)

  expect_equal(predict(fit, dpar = "mu", type = "link"), expected)
  expect_equal(predict(fit, dpar = "mu", type = "response"), expected)
  expect_equal(
    predict(fit, dpar = "sigma", type = "response"),
    rep(exp(-0.2), nrow(fit$data))
  )
})

test_that("conditional Gaussian payload must match the training group map", {
  fit <- conditional_gaussian_ri_fixture()
  fit$conditional_re$gidx <- c(1L, 1L, 2L, 2L)

  expect_error(
    predict(fit, dpar = "mu", type = "link"),
    "conditional.*payload|group map"
  )

  fit <- conditional_gaussian_ri_fixture()
  fit$conditional_re$levels <- c("a", "b")
  fit$conditional_re$gidx <- c(2L, 1L, 2L, 1L)
  expect_error(
    predict(fit, dpar = "mu", type = "link"),
    "first-seen group levels"
  )

  fit <- conditional_gaussian_ri_fixture()
  fit$conditional_re$blup[[2L]] <- NA_real_
  expect_error(
    predict(fit, dpar = "mu", type = "link"),
    "invalid conditional random-effect BLUP"
  )

  fit <- conditional_gaussian_ri_fixture()
  fit$conditional_re$kind <- "unrecognized_payload"
  expect_error(
    predict(fit, dpar = "mu", type = "link"),
    "validated Gaussian random-intercept payload"
  )

  fit <- conditional_gaussian_ri_fixture(payload = FALSE)
  expect_error(
    predict(fit, dpar = "mu", type = "link"),
    "conditional.*payload"
  )
})

test_that("conditional payload does not change Gaussian random-effect newdata", {
  fit <- conditional_gaussian_ri_fixture()
  newdata <- data.frame(x = c(-1, 3), g = factor(c("a", "new")))

  expect_equal(
    predict(fit, newdata = newdata, dpar = "mu", type = "link"),
    c(0.2, 1.4)
  )
})

test_that("conditional adapter identifies only a single Gaussian mu intercept", {
  fit <- conditional_gaussian_ri_fixture()
  expect_equal(
    drm_julia_conditional_gaussian_ri_spec(fit$formula, "gaussian"),
    list(group = "g", dpar = "mu")
  )

  slope <- fit$formula
  slope$entries[[1L]]$rhs <- quote(x + (0 + x | g))
  expect_null(drm_julia_conditional_gaussian_ri_spec(slope, "gaussian"))

  scale_re <- fit$formula
  scale_re$entries[[2L]]$rhs <- quote(1 + (1 | g))
  expect_null(drm_julia_conditional_gaussian_ri_spec(scale_re, "gaussian"))

  lss <- fit$formula
  lss$entries[[3L]] <- list(dpar = "sd(g)", rhs = quote(1), structured = list())
  expect_null(drm_julia_conditional_gaussian_ri_spec(lss, "gaussian"))

  structured <- fit$formula
  structured$entries[[1L]]$structured <- list(list(type = "phylo"))
  expect_null(drm_julia_conditional_gaussian_ri_spec(structured, "gaussian"))

  offset <- fit$formula
  offset$entries[[1L]]$rhs <- quote(x + offset(x) + (1 | g))
  expect_null(drm_julia_conditional_gaussian_ri_spec(offset, "gaussian"))
})

test_that("bridge constructor retains the fit-time conditional payload", {
  fixture <- conditional_gaussian_ri_fixture()
  result <- list(
    coef_names = c("mu_(Intercept)", "mu_x", "sigma_(Intercept)", "resd_g"),
    coefficients = c(0.5, 0.3, -0.2, -0.7),
    vcov = diag(4L),
    loglik = -4,
    aic = 16,
    bic = 18,
    df = 4L,
    nobs = nrow(fixture$data),
    converged = TRUE,
    fitted = list(mu = 0.5 + 0.3 * fixture$data$x),
    dpars = list(mu = 0.5 + 0.3 * fixture$data$x,
                 sigma = rep(exp(-0.2), nrow(fixture$data))),
    residuals = list(mu = rep(0, nrow(fixture$data))),
    sigma = rep(exp(-0.2), nrow(fixture$data)),
    corpairs = list(),
    conditional_re = fixture$conditional_re
  )
  fit <- new_drmTMB_julia(
    result = result,
    call = quote(drmTMB()),
    formula = fixture$formula,
    family = stats::gaussian(),
    data = fixture$data,
    family_type = "gaussian"
  )

  expect_equal(fit$conditional_re$levels, c("b", "a"))
  expect_equal(
    predict(fit, dpar = "mu", type = "link"),
    c(0.5 + 0.3 * -2 + 0.6, 0.5 + 0.3 * -1 - 0.25,
      0.5 + 0.3 * 1 + 0.6, 0.5 + 0.3 * 2 - 0.25)
  )
})

test_that("numeric first-seen groups retain their Julia types through the wrapper", {
  data <- data.frame(y = c(-1, 0, 1, 2), g = c(2, 1, 2, 1))
  formula <- list(entries = list(
    list(dpar = "mu", rhs = quote(g + (1 | g)), structured = list()),
    list(dpar = "sigma", rhs = quote(1), structured = list())
  ))
  fit <- structure(
    list(
      formula = formula,
      family = stats::gaussian(),
      model = list(model_type = "gaussian"),
      data = data,
      coefficients = list(
        mu = c("(Intercept)" = 0.5, g = 0.3),
        sigma = c("(Intercept)" = -0.2)
      ),
      conditional_re = list(
        kind = "gaussian_mu_random_intercept_v1",
        group = "g",
        levels = c(2, 1),
        gidx = c(1L, 2L, 1L, 2L),
        blup = c(0.6, -0.25)
      ),
      engine = "julia"
    ),
    class = "drmTMB_julia"
  )
  expect_equal(
    predict(fit, dpar = "mu", type = "link"),
    c(0.5 + 0.3 * 2 + 0.6, 0.5 + 0.3 * 1 - 0.25,
      0.5 + 0.3 * 2 + 0.6, 0.5 + 0.3 * 1 - 0.25)
  )

})

test_that("logical first-seen groups use the same typed transport contract", {
  data <- data.frame(y = c(-1, 0, 1, 2), g = c(TRUE, FALSE, TRUE, FALSE))
  formula <- list(entries = list(
    list(dpar = "mu", rhs = quote(g + (1 | g)), structured = list()),
    list(dpar = "sigma", rhs = quote(1), structured = list())
  ))
  fit <- structure(
    list(
      formula = formula,
      family = stats::gaussian(),
      model = list(model_type = "gaussian"),
      data = data,
      coefficients = list(
        mu = c("(Intercept)" = 0.5, gTRUE = 0.3),
        sigma = c("(Intercept)" = -0.2)
      ),
      conditional_re = list(
        kind = "gaussian_mu_random_intercept_v1",
        group = "g",
        levels = c(TRUE, FALSE),
        gidx = c(1L, 2L, 1L, 2L),
        blup = c(0.6, -0.25)
      ),
      engine = "julia"
    ),
    class = "drmTMB_julia"
  )

  expect_equal(
    predict(fit, dpar = "mu", type = "link"),
    c(0.5 + 0.3 + 0.6, 0.5 - 0.25, 0.5 + 0.3 + 0.6, 0.5 - 0.25)
  )
  decoded <- drm_julia_conditional_re_plain(fit$conditional_re)
  expect_equal(decoded$levels, c("TRUE", "FALSE"))
})
