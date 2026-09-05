# predict() for `cumulative_logit()` fits through engine = "julia" (parity
# leaf `leaf-cumlogit-predict`, 2026-09-05). The family admission (#1174) left
# a documented gap: `drm_julia_predict_design()` rebuilds `mu`'s design with
# `stats::model.matrix()`, which always restores "(Intercept)" -- but the
# fitted `mu` coefficient block never carries it (the cutpoints absorb the
# location intercept; design 258 section 8.9), so `predict()` aborted
# ("could not align the design with the fitted mu coefficients"). The fix
# drops "(Intercept)" from the reconstructed design, scoped to
# model_type == "cumulative_logit" && dpar == "mu", mirroring the native
# engine's own `ordinal_mu_model_matrix()` (R/drmTMB.R).
#
# `mu`'s link is identity (R/methods.R `cumulative_logit = c(mu = "identity")`),
# so engine = "tmb"'s own predict() returns the SAME values for type =
# "response" and type = "link" -- a plain eta vector, no per-category
# probabilities and no cutpoints. That is the whole same-target contract for
# this leaf: predict.drmTMB_julia() never reads cutpoints either.

# ---- offline (no Julia): exercise the intercept-dropping design logic ------

make_cumlogit_julia_fit <- function(data, beta_x) {
  structure(
    list(
      formula = drmTMB::bf(score ~ x),
      family = drmTMB::cumulative_logit(),
      model = list(model_type = "cumulative_logit"),
      data = data,
      coefficients = list(mu = c(x = beta_x)),
      fitted = NULL,
      engine = "julia"
    ),
    class = "drmTMB_julia"
  )
}

test_that("predict() on a hand-built cumulative_logit Julia stub does not abort on the intercept mismatch", {
  set.seed(20260905L)
  n <- 30L
  train <- data.frame(x = stats::rnorm(n))
  beta_x <- 0.6
  fit <- make_cumlogit_julia_fit(train, beta_x)

  # Stored-data prediction: intercept dropped from the reconstructed design,
  # so eta is exactly beta_x * x (the fitted block has no intercept term).
  link <- predict(fit, type = "link")
  resp <- predict(fit, type = "response")
  expect_length(link, n)
  expect_equal(link, unname(beta_x * train$x))
  # identity link: response == link for this family's mu
  expect_equal(resp, link)

  # Default dpar/type are mu + response, matching the generic bridge contract.
  expect_equal(predict(fit), resp)
})

test_that("predict(newdata) on a hand-built cumulative_logit Julia stub matches the population eta", {
  train <- data.frame(x = stats::rnorm(20L))
  beta_x <- -0.9
  fit <- make_cumlogit_julia_fit(train, beta_x)

  nd <- data.frame(x = c(-2, -0.5, 0, 0.5, 2))
  link <- predict(fit, newdata = nd, type = "link")
  resp <- predict(fit, newdata = nd, type = "response")

  expect_equal(link, unname(beta_x * nd$x))
  expect_equal(resp, link)
})

test_that("RED CONTROL: an un-dropped intercept aborts predict() again", {
  train <- data.frame(x = stats::rnorm(15L))
  fit <- make_cumlogit_julia_fit(train, beta_x = 0.4)
  # Simulate the pre-fix behaviour directly: build the design the OLD way
  # (intercept kept) and confirm the alignment check this leaf relies on
  # actually fires for a mismatched column count.
  local_mocked_bindings(
    drm_julia_predict_design = function(object, entry, newdata) {
      stats::model.matrix(~x, data = newdata)
    },
    .package = "drmTMB"
  )
  expect_error(
    predict(fit),
    "could not align the .stored. design with the fitted .mu. coefficients"
  )
})

# ---- live round trip (opt-in; skips only when the engine is absent) --------

drm_cumlogit_predict_fixture <- function(n = 900L, seed = 20260509) {
  set.seed(seed)
  dat <- data.frame(x = stats::rnorm(n))
  cutpoints <- c(-0.90, 0.75)
  eta <- 0.85 * dat$x
  p_low <- stats::plogis(cutpoints[[1L]] - eta)
  p_medium <- stats::plogis(cutpoints[[2L]] - eta) - p_low
  prob <- cbind(p_low, p_medium, 1 - stats::plogis(cutpoints[[2L]] - eta))
  draw <- vapply(
    seq_len(n),
    function(i) sample.int(3L, size = 1L, prob = prob[i, ]),
    integer(1)
  )
  dat$score <- ordered(
    c("low", "medium", "high")[draw],
    levels = c("low", "medium", "high")
  )
  dat
}

drm_cumlogit_predict_formula <- function() drmTMB::bf(score ~ x)

drm_cumlogit_predict_roundtrip <- function() {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_test_drmjl_path()
  callr::r(
    function(pkg, jl_path, build, formula_fn) {
      julia_home <- Sys.getenv("DRM_JL_JULIA_HOME", Sys.getenv("JULIA_HOME", ""))
      if (nzchar(julia_home)) Sys.setenv(JULIA_HOME = julia_home)
      options(drmTMB.DRM.jl.path = jl_path)
      Sys.setenv(DRM_JL_PATH = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))
      dat <- build()
      form <- formula_fn()
      ft <- drmTMB::drmTMB(form, family = drmTMB::cumulative_logit(), data = dat, engine = "tmb")
      fj <- drmTMB::drmTMB(form, family = drmTMB::cumulative_logit(), data = dat, engine = "julia")
      newdat <- data.frame(x = c(-2, -0.5, 0, 0.5, 2))
      list(
        converged = drmTMB::is_converged(fj),
        nobs = stats::nobs(fj),
        # stored data, both types
        stored_resp_tmb = as.numeric(predict(ft)),
        stored_resp_julia = as.numeric(predict(fj)),
        stored_link_tmb = as.numeric(predict(ft, type = "link")),
        stored_link_julia = as.numeric(predict(fj, type = "link")),
        # newdata, both types
        newdata_resp_tmb = as.numeric(predict(ft, newdata = newdat)),
        newdata_resp_julia = as.numeric(predict(fj, newdata = newdat)),
        newdata_link_tmb = as.numeric(predict(ft, newdata = newdat, type = "link")),
        newdata_link_julia = as.numeric(predict(fj, newdata = newdat, type = "link"))
      )
    },
    args = list(
      pkg = pkg, jl_path = jl_path,
      build = drm_cumlogit_predict_fixture,
      formula_fn = drm_cumlogit_predict_formula
    ),
    error = "stack"
  )
}

test_that("predict() on a live engine = 'julia' cumulative_logit fit matches engine = 'tmb'", {
  drm_skip_live_julia()
  testthat::skip_if_not_installed("JuliaCall")
  testthat::skip_if_not_installed("callr")
  testthat::skip_if_not_installed("pkgload")

  out <- drm_cumlogit_predict_roundtrip()

  expect_true(isTRUE(out$converged))
  expect_identical(out$nobs, 900L)

  # cumulative_logit's mu link is identity: response and link are identical
  # on BOTH engines.
  expect_equal(out$stored_resp_tmb, out$stored_link_tmb)
  expect_equal(out$stored_resp_julia, out$stored_link_julia)

  expect_lt(max(abs(out$stored_resp_julia - out$stored_resp_tmb)), 1e-6)
  expect_lt(max(abs(out$stored_link_julia - out$stored_link_tmb)), 1e-6)
  expect_lt(max(abs(out$newdata_resp_julia - out$newdata_resp_tmb)), 1e-6)
  expect_lt(max(abs(out$newdata_link_julia - out$newdata_link_tmb)), 1e-6)
})
