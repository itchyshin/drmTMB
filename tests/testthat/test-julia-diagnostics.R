# #1108 / DRM.jl #569 (bridge #632): check_drm.drmTMB_julia() reads the
# route-aware gradient/route/convergence diagnostics new_drmTMB_julia()
# stores under object$diagnostics, through the SAME accessor -- check_drm()
# -- a native TMB fit already uses. Mocked-bridge tests below pin the exact
# field mapping without needing a live Julia install; the two live tests at
# the bottom (skipped without DRM_JL_PATH) each exercise a real DRM.jl fit
# end to end -- one on a route confirmed to omit the gradient, one on a
# route confirmed to carry it (see the R/julia-diagnostics.R header comment
# for how those routes were verified against DRM.jl 430ef64c).
#
# The engine_route / gradient-source / bridge-covariance rows below are the
# p-route-diagnostics leaf: check_drm() on a DRM.jl fit must say WHICH engine
# and route ran, WHICH producer made the gradient it prints (DRM.jl PR #656's
# grad_source vocabulary), and whether the covariance DRM.jl marshalled back is
# usable at all -- the last of which was previously never read, so a fit with
# no covariance passed check_drm() green.

drm_test_julia_diag_result <- function(
  with_gradient = TRUE,
  converged = TRUE,
  gradient = c(0.0002, -0.0005, 0.0001),
  vcov = diag(c(0.01, 0.02, 0.03))
) {
  coef_names <- c("mu_(Intercept)", "mu_x", "sigma_(Intercept)")
  result <- list(
    coef_names = coef_names,
    coefficients = c(0.5, 1.2, -0.3),
    vcov = vcov,
    loglik = -20,
    aic = 46,
    bic = 49,
    df = 3L,
    nobs = 50L,
    converged = converged,
    fitted = rep(1, 50),
    residuals = rep(0, 50),
    sigma = rep(0.8, 50),
    corpairs = list()
  )
  if (with_gradient) {
    result$gradient <- gradient
    result$gradient_names <- coef_names
  }
  result
}

drm_test_julia_diag_fit <- function(...) {
  result <- drm_test_julia_diag_result(...)
  drmTMB:::new_drmTMB_julia(
    result = result,
    call = quote(drmTMB(bf(y ~ x, sigma ~ 1), data = dat, engine = "julia")),
    formula = bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = data.frame(y = rep(1, 50), x = rep(1, 50)),
    family_type = "gaussian"
  )
}

# Builds the fit from a caller-supplied (possibly corrupted) `result` list,
# so a test can tamper with result$gradient_names / result$gradient AFTER
# drm_test_julia_diag_result() built them index-aligned, rather than through
# drm_test_julia_diag_fit()'s arguments, which have no way to desynchronize
# the two.
drm_test_julia_diag_fit_from_result <- function(result) {
  drmTMB:::new_drmTMB_julia(
    result = result,
    call = quote(drmTMB(bf(y ~ x, sigma ~ 1), data = dat, engine = "julia")),
    formula = bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = data.frame(y = rep(1, 50), x = rep(1, 50)),
    family_type = "gaussian"
  )
}

test_that("check_drm() dispatches on a Julia fit and reports max|gradient|, route, and convergence (G2)", {
  fit <- drm_test_julia_diag_fit()
  expect_s3_class(fit, "drmTMB_julia")

  dc <- check_drm(fit)
  expect_s3_class(dc, "drm_check")
  expect_true(attr(dc, "ok"))
  expect_setequal(
    dc$check,
    c(
      "engine_route",
      "optimizer_convergence",
      "fixed_gradient",
      "bridge_covariance",
      "bridge_standard_errors"
    )
  )

  grad_row <- dc[dc$check == "fixed_gradient", ]
  # The raw value this must match: max(abs(.)) of the EXACT vector the mocked
  # bridge result carried under "gradient" (drm_test_julia_diag_result()'s
  # default).
  raw_gradient <- c(0.0002, -0.0005, 0.0001)
  expect_equal(fit$diagnostics$gradient[["mu_x"]], -0.0005)
  expect_equal(max(abs(fit$diagnostics$gradient)), max(abs(raw_gradient)))
  expect_match(grad_row$value, "route=gaussian", fixed = TRUE)
  expect_match(
    grad_row$value,
    paste0("max=", drmTMB:::format_check_number(max(abs(raw_gradient)))),
    fixed = TRUE
  )
  expect_match(grad_row$value, "component=mu_x", fixed = TRUE)
  # The bridge's ONLY producer of a "gradient" key is `fit.nllgrad`
  # (DRM.jl 430ef64c src/bridge.jl:1497), which is DRM.jl's own `:stored`.
  expect_match(grad_row$value, "source=stored", fixed = TRUE)
  expect_identical(grad_row$status, "ok")

  conv_row <- dc[dc$check == "optimizer_convergence", ]
  expect_identical(conv_row$status, "ok")
})

test_that("check_drm() reports a warning gradient row when max|gradient| exceeds the tolerance", {
  fit <- drm_test_julia_diag_fit(gradient = c(0.01, 0.5, -0.02))
  dc <- check_drm(fit, gradient_tolerance = 1e-3)
  grad_row <- dc[dc$check == "fixed_gradient", ]
  expect_identical(grad_row$status, "warning")
  expect_match(grad_row$value, "component=mu_x", fixed = TRUE)
  expect_false(attr(dc, "ok"))
})

test_that("new_drmTMB_julia() refuses to mislabel a gradient when gradient_names is permuted relative to coef_names", {
  # drm_test_julia_diag_result() sets result$gradient_names <- coef_names,
  # so mislabel this deliberately: same set, different order.
  result <- drm_test_julia_diag_result()
  result$gradient_names <- rev(result$coef_names)
  expect_error(
    drm_test_julia_diag_fit_from_result(result),
    "gradient_names.*do not match.*coef_names|refusing to mislabel gradient entries"
  )
})

test_that("new_drmTMB_julia() refuses to mislabel a gradient when the gradient vector is shorter than coef_names", {
  result <- drm_test_julia_diag_result()
  result$gradient <- result$gradient[-1]
  expect_error(
    drm_test_julia_diag_fit_from_result(result),
    "refusing to mislabel gradient entries"
  )
})

test_that("check_drm() reports NOT converged as a warning on the convergence row", {
  fit <- drm_test_julia_diag_fit(converged = FALSE)
  dc <- check_drm(fit)
  conv_row <- dc[dc$check == "optimizer_convergence", ]
  expect_identical(conv_row$status, "warning")
  expect_match(conv_row$message, "NOT converged")
  expect_false(attr(dc, "ok"))
})

test_that("check_drm() is route-aware: a fit whose route carries no gradient gets a NOTE naming the route, never a fabricated number", {
  fit <- drm_test_julia_diag_fit(with_gradient = FALSE)
  expect_null(fit$diagnostics$gradient)
  dc <- check_drm(fit)
  grad_row <- dc[dc$check == "fixed_gradient", ]
  expect_identical(grad_row$status, "note")
  expect_match(grad_row$value, "route=gaussian", fixed = TRUE)
  expect_false(grepl("max=", grad_row$value, fixed = TRUE))
  # "unknown" is deliberately NOT one of DRM.jl's six grad_source values: the
  # bridge sends no source field, so R must not name one of the five it cannot
  # distinguish.
  expect_match(grad_row$value, "source=unknown", fixed = TRUE)
  expect_false(any(grepl(
    paste0("source=", drmTMB:::drm_julia_grad_source_vocabulary(), collapse = "|"),
    grad_row$value
  )))
  expect_match(grad_row$message, "did not attach a gradient")
  # A note does not flip the overall "ok" attribute (matches TMB's own
  # keep_tmb_object = FALSE note in check_fixed_gradient()).
  expect_true(attr(dc, "ok"))
})

test_that("check_drm() on a Julia fit prints the same drm_check summary-line shape as a TMB fit", {
  fit <- drm_test_julia_diag_fit()
  printed <- NULL
  messages <- capture.output(
    printed <- capture.output(print(check_drm(fit))),
    type = "message"
  )
  combined <- paste(c(messages, printed), collapse = "\n")
  expect_match(combined, "<drm_check: 5 checks>", fixed = TRUE)
  expect_match(combined, "ok: 4; notes: 1; warnings: 0; errors: 0", fixed = TRUE)
})

test_that("check_drm.drmTMB_julia validates gradient_tolerance and rejects extra dots, like check_drm.drmTMB", {
  fit <- drm_test_julia_diag_fit()
  expect_error(check_drm(fit, gradient_tolerance = -1), "finite numeric scalar")
  expect_error(check_drm(fit, nonsense = TRUE), "reserved for future")
})

test_that("live: a real engine = \"julia\" fit on a route WITHOUT a stored gradient reports the route-aware NOTE, not a fabricated number (G3)", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  jl_path <- Sys.getenv("DRM_JL_PATH", "")
  skip_if_not(nzchar(jl_path) && dir.exists(jl_path), "DRM_JL_PATH not available")

  # Verified 2026-09-05 against DRM.jl 430ef64c (`grep nllgrad src/*.jl`):
  # the base univariate Gaussian/GLMM fitter (src/gaussian_core.jl) never
  # assigns `fit.nllgrad`, so this ordinary sigma-random-effect route omits
  # "gradient" from the bridge payload entirely.
  set.seed(1)
  n <- 120
  g <- factor(rep(1:12, each = 10))
  x <- rnorm(n)
  y <- 1 + 0.5 * x + rnorm(12, sd = 0.7)[g] + rnorm(n, sd = exp(0.2 * rnorm(12)[g]))
  dat <- data.frame(y = y, x = x, g = g)

  form <- bf(y ~ x, sigma ~ (1 | g))
  fj <- drmTMB(form, data = dat, engine = "julia")

  expect_identical(fj$diagnostics$route, "gaussian")
  expect_null(fj$bridge$gradient)
  expect_null(fj$diagnostics$gradient)

  dc <- check_drm(fj)
  expect_s3_class(dc, "drm_check")
  expect_setequal(
    dc$check,
    c(
      "engine_route",
      "optimizer_convergence",
      "fixed_gradient",
      "bridge_covariance",
      "bridge_standard_errors"
    )
  )
  grad_row <- dc[dc$check == "fixed_gradient", ]
  expect_identical(grad_row$status, "note")
  expect_match(grad_row$value, "route=gaussian", fixed = TRUE)
  expect_false(grepl("max=", grad_row$value, fixed = TRUE))
  expect_match(grad_row$value, "source=unknown", fixed = TRUE)

  route_row <- dc[dc$check == "engine_route", ]
  expect_identical(route_row$status, "note")
  expect_identical(
    route_row$value,
    "engine=julia; route=gaussian; estimator=ML"
  )
})

test_that("live: a real engine = \"julia\" fit on a route WITH a stored gradient reaches max|gradient| through check_drm(), matching the raw bridge gradient exactly (G2/G3)", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("ape")
  jl_path <- Sys.getenv("DRM_JL_PATH", "")
  skip_if_not(nzchar(jl_path) && dir.exists(jl_path), "DRM_JL_PATH not available")

  # Verified 2026-09-05 against DRM.jl 430ef64c: the bivariate structured q4
  # route (src/gaussian_bivariate.jl) DOES assign `fit.nllgrad` regardless of
  # ML/REML, so this fixture is a real "gradient present" round trip -- not
  # just the mocked-bridge branch above. Reuses the exact committed fixture
  # and call shape test-julia-phylo-q4-corpairs.R already exercises live, so
  # this is a known-working shape, not a guess at one.
  fixture <- file.path(jl_path, "test/parity/q4-reml/biv-q4-phylo-reml")
  skip_if_not(dir.exists(fixture), "q4 phylo REML fixture not available")
  dat <- utils::read.csv(file.path(fixture, "data.csv"), stringsAsFactors = FALSE)
  tree <- ape::read.tree(file.path(fixture, "tree.newick"))
  dat$species <- factor(dat$species, levels = tree$tip.label)

  form <- bf(
    mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
    mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
    sigma1 = ~ 1 + phylo(1 | p | species, tree = tree),
    sigma2 = ~ 1 + phylo(1 | p | species, tree = tree),
    rho12 = ~1
  )
  fj <- drmTMB(
    form,
    family = biv_gaussian(),
    data = dat,
    engine = "julia",
    REML = TRUE
  )

  expect_identical(fj$diagnostics$route, "biv_gaussian")
  raw_gradient <- fj$bridge$gradient
  expect_true(is.numeric(raw_gradient) && length(raw_gradient) > 0L)
  expect_true(all(is.finite(raw_gradient)))
  # Same vector, reachable through the SAME accessor a TMB fit uses.
  expect_equal(unname(fj$diagnostics$gradient), unname(raw_gradient))

  dc <- check_drm(fj)
  expect_s3_class(dc, "drm_check")
  expect_setequal(
    dc$check,
    c(
      "engine_route",
      "optimizer_convergence",
      "fixed_gradient",
      "bridge_covariance",
      "bridge_standard_errors"
    )
  )
  route_row <- dc[dc$check == "engine_route", ]
  expect_identical(
    route_row$value,
    "engine=julia; route=biv_gaussian; estimator=REML"
  )
  grad_row <- dc[dc$check == "fixed_gradient", ]
  # Real fit, real gradient -- this must NOT be the route-aware "note" branch.
  expect_true(grad_row$status %in% c("ok", "warning"))
  expect_match(grad_row$value, "route=biv_gaussian", fixed = TRUE)
  expect_match(grad_row$value, "source=stored", fixed = TRUE)
  expect_match(
    grad_row$value,
    paste0("max=", drmTMB:::format_check_number(max(abs(raw_gradient)))),
    fixed = TRUE
  )
})

# ---------------------------------------------------------------------------
# p-route-diagnostics: the fit must not present as a TMB fit
# ---------------------------------------------------------------------------

test_that("check_drm() names the engine, route and estimator before any other row", {
  fit <- drm_test_julia_diag_fit()
  dc <- check_drm(fit)
  expect_identical(dc$check[[1L]], "engine_route")
  route_row <- dc[dc$check == "engine_route", ]
  expect_identical(route_row$status, "note")
  expect_identical(
    route_row$value,
    "engine=julia; route=gaussian; estimator=ML"
  )
  expect_match(route_row$message, "DRM.jl", fixed = TRUE)
  expect_match(route_row$message, "not by TMB", fixed = TRUE)
  # It must name the native checks that did NOT run, or a clean bridge table
  # reads like a clean native one.
  expect_match(route_row$message, "sdreport status", fixed = TRUE)
  expect_match(route_row$message, "narrower claim", fixed = TRUE)
  # A note never flips the overall verdict.
  expect_true(attr(dc, "ok"))
})

test_that("the engine_route row reports REML when the fit is REML", {
  result <- drm_test_julia_diag_result()
  result$estim_method <- "REML"
  fit <- drm_test_julia_diag_fit_from_result(result)
  dc <- check_drm(fit)
  expect_identical(
    dc[dc$check == "engine_route", ]$value,
    "engine=julia; route=gaussian; estimator=REML"
  )
})

test_that("the gradient source vocabulary is exactly DRM.jl PR #656's six symbols", {
  expect_identical(
    drmTMB:::drm_julia_grad_source_vocabulary(),
    c("locscale", "stored", "forward", "finite", "none", "unavailable")
  )
})

test_that("a gradient that crossed the bridge is reported as DRM.jl's :stored", {
  fit <- drm_test_julia_diag_fit()
  expect_identical(drmTMB:::drm_julia_gradient_source(fit), "stored")
})

test_that("an absent gradient is reported as \"unknown\", never as one of DRM.jl's five undistinguishable sources", {
  fit <- drm_test_julia_diag_fit(with_gradient = FALSE)
  expect_identical(drmTMB:::drm_julia_gradient_source(fit), "unknown")
  expect_false("unknown" %in% drmTMB:::drm_julia_grad_source_vocabulary())
})

test_that("a gradient_source sent by a future bridge is honoured, colon-prefixed or not", {
  for (src in drmTMB:::drm_julia_grad_source_vocabulary()) {
    result <- drm_test_julia_diag_result()
    result$gradient_source <- src
    fit <- drm_test_julia_diag_fit_from_result(result)
    expect_identical(drmTMB:::drm_julia_gradient_source(fit), src)
    dc <- check_drm(fit)
    expect_match(
      dc[dc$check == "fixed_gradient", ]$value,
      paste0("source=", src),
      fixed = TRUE
    )
  }
  # Julia spells these as symbols; tolerate the ":stored" rendering.
  result <- drm_test_julia_diag_result()
  result$gradient_source <- ":finite"
  fit <- drm_test_julia_diag_fit_from_result(result)
  expect_identical(drmTMB:::drm_julia_gradient_source(fit), "finite")
  expect_match(
    check_drm(fit)[check_drm(fit)$check == "fixed_gradient", ]$message,
    "FINITE DIFFERENCE",
    fixed = TRUE
  )
})

test_that("an out-of-vocabulary gradient source aborts instead of being echoed into a diagnostic", {
  result <- drm_test_julia_diag_result()
  result$gradient_source <- "vibes"
  fit <- drm_test_julia_diag_fit_from_result(result)
  expect_error(
    check_drm(fit),
    "unrecognised gradient source"
  )
})

test_that("check_drm() flags a Julia fit whose bridge covariance came back wholly non-finite (it used to pass green)", {
  fit <- drm_test_julia_diag_fit(vcov = matrix(NaN, 3L, 3L))
  # The state the bridge constructor itself builds for this case.
  expect_identical(fit$uncertainty$status, "unavailable")

  dc <- check_drm(fit)
  cov_row <- dc[dc$check == "bridge_covariance", ]
  expect_identical(cov_row$status, "warning")
  expect_identical(cov_row$value, "status=unavailable")
  expect_match(cov_row$message, "did not return finite fixed-effect covariance")
  expect_match(cov_row$message, "TMB::sdreport() was not run", fixed = TRUE)

  se_row <- dc[dc$check == "bridge_standard_errors", ]
  expect_identical(se_row$status, "warning")
  expect_identical(se_row$value, "n=3; nonfinite=3")

  # The point of the row: the overall verdict is no longer silently TRUE.
  expect_false(attr(dc, "ok"))
})

test_that("a complete covariance with a negative variance is caught by the standard-error row, which the completeness status cannot see", {
  fit <- drm_test_julia_diag_fit(vcov = diag(c(0.01, -0.02, 0.03)))
  # Every entry is finite, so the constructor's own completeness check is "ok".
  expect_identical(fit$uncertainty$status, "ok")
  dc <- check_drm(fit)
  expect_identical(dc[dc$check == "bridge_covariance", ]$status, "ok")

  se_row <- dc[dc$check == "bridge_standard_errors", ]
  expect_identical(se_row$status, "warning")
  expect_match(se_row$value, "nonfinite=1", fixed = TRUE)
  expect_match(se_row$message, "mu_x", fixed = TRUE)
  expect_false(attr(dc, "ok"))
})

test_that("a healthy covariance reports an ok bridge_covariance row and the range of the implied standard errors", {
  fit <- drm_test_julia_diag_fit()
  dc <- check_drm(fit)
  expect_identical(dc[dc$check == "bridge_covariance", ]$status, "ok")
  se_row <- dc[dc$check == "bridge_standard_errors", ]
  expect_identical(se_row$status, "ok")
  # Raw values: sqrt(c(0.01, 0.02, 0.03)) -> 0.1, 0.1414214, 0.1732051.
  expect_identical(
    se_row$value,
    paste0(
      "n=3; nonfinite=0; range=[",
      drmTMB:::format_check_number(sqrt(0.01)), ",",
      drmTMB:::format_check_number(sqrt(0.03)), "]"
    )
  )
})

test_that("the stable drm_check reader schema still holds for a Julia fit", {
  dc <- check_drm(drm_test_julia_diag_fit())
  expect_identical(names(dc), c("check", "status", "value", "message"))
  expect_true(all(vapply(dc, is.character, logical(1L))))
  expect_true(all(dc$status %in% c("ok", "note", "warning", "error")))
  expect_identical(
    attr(dc, "ok"),
    !any(dc$status %in% c("warning", "error"))
  )
})
