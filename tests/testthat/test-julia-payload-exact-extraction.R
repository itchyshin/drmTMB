# Raw DRM.jl payloads are read with `[[`, never `$`.
#
# WHY. `$` on an R list PARTIALLY MATCHES. If the exact name is absent and exactly one
# other name has it as a prefix, `$` silently returns THAT field:
#
#   l <- list(gradient_source = "none", coef_names = "a")
#   l$gradient                #> "none"
#   is.null(l[["gradient"]])  #> TRUE
#
# The payload is DRM.jl's shape, not ours, so a field added on the Julia side can turn an
# exact read into a partial one without a single line changing in R. Two such collisions
# exist among the names R/julia-bridge.R already reads, and both are UNIQUE prefixes, so
# partial matching fires rather than returning NULL on ambiguity:
#
#   gradient  is a prefix of gradient_names  -- reported from PR #1215
#   converged is a prefix of converged_inner -- found while auditing, and DRM.jl really
#             ships it: src/bridge.jl emits "converged_inner" => rr.converged
#
# The second is the worse of the two: `isTRUE(result$converged)` on a payload carrying
# converged_inner and no converged reports the INNER solver's flag as the fit's
# convergence. That is a wrong answer, not an abort.
#
# These tests pin the constructor's behaviour on such a payload. They need no engine.

drm_exact_payload <- function(...) {
  base <- list(
    coef_names = c("mu_(Intercept)", "mu_x", "sigma_(Intercept)"),
    coefficients = c(1.0, 0.5, -0.7),
    vcov = diag(3L),
    loglik = -100, aic = 206, bic = 210, df = 3L, nobs = 20L,
    converged = TRUE,
    fitted = list(mu = seq_len(20)),
    residuals = list(mu = rep(0, 20)),
    sigma = list(sigma = rep(0.5, 20))
  )
  utils::modifyList(base, list(...))
}

drm_exact_fit <- function(result) {
  dat <- data.frame(y = stats::rnorm(20), x = stats::rnorm(20))
  drmTMB:::new_drmTMB_julia(
    result = result,
    call = quote(drmTMB(bf(y ~ x), family = gaussian(), data = dat, engine = "julia")),
    formula = drmTMB::bf(y ~ x, sigma ~ 1),
    family = stats::gaussian(),
    data = dat,
    family_type = "gaussian"
  )
}

test_that("the partial-matching mechanism is real (the premise these tests rest on)", {
  l <- list(gradient_source = "none", coef_names = "a")
  expect_identical(l$gradient, "none")        # `$` partial-matches
  expect_null(l[["gradient"]])                # `[[` does not
  m <- list(converged_inner = FALSE)
  expect_false(l$gradient == "")              # keeps the first assertion honest
  expect_identical(m$converged, FALSE)        # the worse collision, same mechanism
  expect_null(m[["converged"]])
})

test_that("a payload with a gradient-PREFIXED field and no gradient yields NULL, not an abort", {
  set.seed(1)
  # `gradient_source` is what a future bridge reporting gradient provenance would send.
  # Under `$` this returned the STRING "finite", and the constructor then aborted on its
  # own gradient_names/coef_names comparison -- a fit failing for a reason unrelated to
  # the model.
  fit <- expect_no_error(
    drm_exact_fit(drm_exact_payload(gradient_source = "finite"))
  )
  expect_s3_class(fit, "drmTMB_julia")
  expect_null(fit$diagnostics$gradient)
  # and the provenance field must not have been mistaken for the gradient
  expect_false(identical(fit$diagnostics$gradient, "finite"))
})

test_that("a payload with gradient_names but no gradient still yields NULL", {
  set.seed(2)
  fit <- expect_no_error(
    drm_exact_fit(drm_exact_payload(
      gradient_names = c("mu_(Intercept)", "mu_x", "sigma_(Intercept)")
    ))
  )
  expect_null(fit$diagnostics$gradient)
})

test_that("converged is read exactly, so converged_inner cannot be mistaken for it", {
  set.seed(3)
  # DRM.jl emits converged_inner on its objective-at payload (src/bridge.jl). A payload
  # carrying it WITHOUT converged must not report the inner flag as the fit's convergence.
  p <- drm_exact_payload(converged_inner = FALSE)
  p[["converged"]] <- NULL
  fit <- expect_no_error(drm_exact_fit(p))
  # `$` would have returned FALSE here (partial match on converged_inner); `[[` gives NULL,
  # and isTRUE(NULL) is FALSE -- the same value, but reached honestly rather than by
  # borrowing a different field's meaning. What matters is that the INNER flag is not what
  # was consulted, which the next assertion pins.
  expect_false(isTRUE(fit$diagnostics$converged))
  q <- drm_exact_payload(converged_inner = FALSE, converged = TRUE)
  fit2 <- drm_exact_fit(q)
  expect_true(isTRUE(fit2$diagnostics$converged))  # the real field wins, not the prefix one
})

test_that("no raw-payload read in R/julia-bridge.R uses `$` (the guard against regression)", {
  root <- normalizePath(testthat::test_path("..", ".."), mustWork = FALSE)
  src <- file.path(root, "R", "julia-bridge.R")
  skip_if(!file.exists(src), "source tree unavailable (R/ is absent under R CMD check)")
  lines <- readLines(src, warn = FALSE)
  offenders <- grep("result\\$[A-Za-z_]", lines, value = TRUE)
  expect_gt(length(lines), 1000L)   # the corpus is real, not an empty read
  expect_identical(offenders, character(0))
})
