# Pure stored-prediction checks for the versioned ordinary Gaussian component
# payload. These tests never start Julia or fit a model.

conditional_component_fit <- function(rhs, data, mu, payload) {
  structure(
    list(
      formula = list(entries = list(
        list(dpar = "mu", rhs = rhs, structured = list()),
        list(dpar = "sigma", rhs = quote(1), structured = list())
      )),
      family = stats::gaussian(),
      model = list(model_type = "gaussian"),
      data = data,
      coefficients = list(
        mu = mu,
        sigma = c("(Intercept)" = -0.2)
      ),
      conditional_re = payload,
      engine = "julia"
    ),
    class = "drmTMB_julia"
  )
}

conditional_component_payload <- function(components, clamp = FALSE) {
  list(
    kind = "gaussian_mu_ordinary_components_v2",
    components = components,
    sigma_clamp_active = clamp
  )
}

test_that("stored scalar intercept and slope components add their validated modes", {
  data_i <- data.frame(y = 1:4, q = c(-2, -1, 1, 2), g = c("b", "a", "b", "a"))
  intercept <- conditional_component_fit(
    quote(q + (1 | g)),
    data_i,
    c("(Intercept)" = 0.5, q = 0.2),
    conditional_component_payload(list(list(
      kind = "scalar", group = "g", loading_source = "(Intercept)",
      levels = c("b", "a"), gidx = c(1L, 2L, 1L, 2L),
      loading = rep(1, 4), modes = c(0.6, -0.25)
    )))
  )
  expect_equal(
    predict(intercept, dpar = "mu", type = "link"),
    0.5 + 0.2 * data_i$q + c(0.6, -0.25, 0.6, -0.25)
  )

  data_s <- data.frame(y = 1:4, q = c(-1, 0, 1, 2), x = c(2, -1, 3, -2), g = c(2, 1, 2, 1))
  slope <- conditional_component_fit(
    quote(q + (0 + x | g)),
    data_s,
    c("(Intercept)" = 0.3, q = -0.1),
    conditional_component_payload(list(list(
      kind = "scalar", group = "g", loading_source = "x",
      levels = c(2, 1), gidx = c(1L, 2L, 1L, 2L),
      loading = data_s$x, modes = c(0.4, -0.5)
    )))
  )
  expect_equal(
    predict(slope, dpar = "mu", type = "link"),
    0.3 - 0.1 * data_s$q + data_s$x * c(0.4, -0.5, 0.4, -0.5)
  )
})

test_that("stored correlated intercept-slope modes use their declared column order", {
  data <- data.frame(y = 1:4, q = c(-2, -1, 1, 2), x = c(-1, 2, 0.5, -2), g = c("z", "y", "z", "y"))
  fit <- conditional_component_fit(
    quote(q + (1 + x | g)),
    data,
    c("(Intercept)" = 0.1, q = 0.3),
    conditional_component_payload(list(list(
      kind = "correlated", group = "g", loading_source = "x",
      levels = c("z", "y"), gidx = c(1L, 2L, 1L, 2L),
      loading = data$x,
      modes = rbind(c(0.5, -0.2), c(-0.3, 0.4))
    )))
  )
  random <- c(0.5 - 0.2 * data$x[[1L]], -0.3 + 0.4 * data$x[[2L]],
              0.5 - 0.2 * data$x[[3L]], -0.3 + 0.4 * data$x[[4L]])
  expect_equal(
    predict(fit, dpar = "mu", type = "link"),
    0.1 + 0.3 * data$q + random
  )
})

test_that("stored distinct-group scalar components add in formula order", {
  data <- data.frame(
    y = 1:4, q = c(-1, 0, 1, 2), x = c(2, -1, 3, -2),
    g = c("b", "a", "b", "a"), h = c(TRUE, FALSE, TRUE, FALSE)
  )
  fit <- conditional_component_fit(
    quote(q + (1 | g) + (0 + x | h)),
    data,
    c("(Intercept)" = 0.4, q = 0.1),
    conditional_component_payload(list(
      list(
        kind = "scalar", group = "g", loading_source = "(Intercept)",
        levels = c("b", "a"), gidx = c(1L, 2L, 1L, 2L),
        loading = rep(1, 4), modes = c(0.5, -0.2)
      ),
      list(
        kind = "scalar", group = "h", loading_source = "x",
        levels = c(TRUE, FALSE), gidx = c(1L, 2L, 1L, 2L),
        loading = data$x, modes = c(-0.3, 0.25)
      )
    ))
  )
  expected <- 0.4 + 0.1 * data$q + c(0.5, -0.2, 0.5, -0.2) +
    data$x * c(-0.3, 0.25, -0.3, 0.25)
  expect_equal(predict(fit, dpar = "mu", type = "response"), expected)
  expect_equal(
    predict(fit, newdata = data.frame(q = c(0, 1), x = c(3, -2), g = "new", h = TRUE), dpar = "mu", type = "link"),
    c(0.4, 0.5)
  )
})

test_that("component admission refuses unrecoverable ordinary shapes", {
  data <- data.frame(y = 1:4, x = 1:4, z = 4:1, g = c("a", "b", "a", "b"), h = c("u", "v", "u", "v"))
  base <- list(entries = list(
    list(dpar = "mu", rhs = quote(x + (1 | g)), structured = list()),
    list(dpar = "sigma", rhs = quote(1), structured = list())
  ))
  expect_equal(
    drm_julia_conditional_gaussian_components_spec(base, "gaussian"),
    list(dpar = "mu", components = list(list(kind = "scalar", group = "g", loading_source = "(Intercept)")))
  )

  repeated <- base
  repeated$entries[[1L]]$rhs <- quote(x + (1 | g) + (0 + x | g))
  expect_null(drm_julia_conditional_gaussian_components_spec(repeated, "gaussian"))

  multicorr <- base
  multicorr$entries[[1L]]$rhs <- quote(x + (1 + x | g) + (1 + z | h))
  expect_null(drm_julia_conditional_gaussian_components_spec(multicorr, "gaussian"))

  wider <- base
  wider$entries[[1L]]$rhs <- quote(x + (1 + x + z | g))
  expect_null(drm_julia_conditional_gaussian_components_spec(wider, "gaussian"))
})

test_that("component admission validates slope payload columns before Julia setup", {
  spec <- list(dpar = "mu", components = list(
    list(kind = "scalar", group = "g", loading_source = "x")
  ))
  expect_error(
    drm_julia_validate_conditional_gaussian_components_data(
      spec, data.frame(g = c("a", "b"), x = factor(c("low", "high")))
    ),
    "finite numeric random-slope"
  )
  expect_error(
    drm_julia_validate_conditional_gaussian_components_data(
      spec, data.frame(g = c("a", NA_character_), x = c(1, 2))
    ),
    "non-missing grouping"
  )
  expect_invisible(
    drm_julia_validate_conditional_gaussian_components_data(
      spec, data.frame(g = c("a", "b"), x = c(1, 2))
    )
  )
})

test_that("component payload validation refuses altered maps, loadings, and mode shapes", {
  data <- data.frame(y = 1:4, q = 1:4, x = c(2, -1, 3, -2), g = c("b", "a", "b", "a"))
  payload <- conditional_component_payload(list(list(
    kind = "correlated", group = "g", loading_source = "x",
    levels = c("b", "a"), gidx = c(1L, 2L, 1L, 2L), loading = data$x,
    modes = rbind(c(0.1, 0.2), c(-0.1, -0.2))
  )))
  fit <- conditional_component_fit(quote(q + (1 + x | g)), data, c("(Intercept)" = 0, q = 0), payload)

  fit$conditional_re$components[[1L]]$loading[[1L]] <- 99
  expect_error(predict(fit, dpar = "mu", type = "link"), "loading|payload")

  fit <- conditional_component_fit(quote(q + (1 + x | g)), data, c("(Intercept)" = 0, q = 0), payload)
  fit$conditional_re$components[[1L]]$modes <- c(0.1, -0.1)
  expect_error(predict(fit, dpar = "mu", type = "link"), "mode|payload")

  fit <- conditional_component_fit(quote(q + (1 + x | g)), data, c("(Intercept)" = 0, q = 0), payload)
  fit$conditional_re$components[[1L]]$levels <- c("a", "b")
  expect_error(predict(fit, dpar = "mu", type = "link"), "first-seen group levels")

  fit <- conditional_component_fit(quote(q + (1 + x | g)), data, c("(Intercept)" = 0, q = 0), payload)
  fit$conditional_re$components[[1L]]$gidx <- c(1L, 1L, 2L, 2L)
  expect_error(predict(fit, dpar = "mu", type = "link"), "group map")

  fit <- conditional_component_fit(quote(q + (1 + x | g)), data, c("(Intercept)" = 0, q = 0), payload)
  fit$conditional_re$components[[1L]]$modes[1L, 1L] <- NA_real_
  expect_error(predict(fit, dpar = "mu", type = "link"), "mode")

  fit <- conditional_component_fit(quote(q + (1 + x | g)), data, c("(Intercept)" = 0, q = 0), payload)
  fit$conditional_re$kind <- "unrecognized_payload"
  expect_error(predict(fit, dpar = "mu", type = "link"), "ordinary Gaussian component payload")

  fit <- conditional_component_fit(quote(q + (0 + x | g)), data, c("(Intercept)" = 0, q = 0), payload)
  fit$conditional_re <- list(kind = "gaussian_mu_random_intercept_v1", group = "g", levels = c("b", "a"), gidx = c(1L, 2L, 1L, 2L), blup = c(0.1, -0.1))
  expect_error(predict(fit, dpar = "mu", type = "link"), "v1 payload.*cannot validate")
})

test_that("stored multi-component sigma follows the DRM clamp after payload validation", {
  data <- data.frame(y = 1:4, q = c(-1, 0, 1, 2), x = c(2, -1, 3, -2), g = c("b", "a", "b", "a"), h = c("u", "v", "u", "v"))
  payload <- conditional_component_payload(list(
    list(kind = "scalar", group = "g", loading_source = "(Intercept)", levels = c("b", "a"), gidx = c(1L, 2L, 1L, 2L), loading = rep(1, 4), modes = c(0.1, -0.1)),
    list(kind = "scalar", group = "h", loading_source = "x", levels = c("u", "v"), gidx = c(1L, 2L, 1L, 2L), loading = data$x, modes = c(0.2, -0.2))
  ), clamp = TRUE)
  fit <- conditional_component_fit(quote(q + (1 | g) + (0 + x | h)), data, c("(Intercept)" = 0, q = 0), payload)
  fit$coefficients$sigma <- c("(Intercept)" = 31)
  expect_equal(predict(fit, dpar = "sigma", type = "link"), rep(30, nrow(data)))
  expect_equal(predict(fit, dpar = "sigma", type = "response"), rep(exp(30), nrow(data)))
  expect_equal(
    predict(fit, newdata = data, dpar = "sigma", type = "response"),
    rep(exp(31), nrow(data))
  )

  fit$coefficients$sigma <- c("(Intercept)" = -31)
  expect_equal(predict(fit, dpar = "sigma", type = "link"), rep(-30, nrow(data)))
  expect_equal(predict(fit, dpar = "sigma", type = "response"), rep(exp(-30), nrow(data)))

  fit$coefficients$sigma <- c("(Intercept)" = -0.2)
  fit$conditional_re$sigma_clamp_active <- FALSE
  expect_equal(predict(fit, dpar = "sigma", type = "link"), rep(-0.2, nrow(data)))
  expect_equal(predict(fit, dpar = "sigma", type = "response"), rep(exp(-0.2), nrow(data)))

  default_sigma <- fit
  default_sigma$formula$entries <- default_sigma$formula$entries[1L]
  expect_equal(predict(default_sigma, dpar = "sigma", type = "link"), rep(-0.2, nrow(data)))
})
