# #1454: Julia-bridge NA handling. These tests call the pure-R helpers. They
# do not start Julia. Cross-family axes used to compare only lengths, so an
# NA in y1 on row 3 and an NA in y2 on row 7 kept 29 rows each and paired
# different observations. Structured response = "drop" did not drop. The q2
# bridge checked the control and not the data.

test_that("cross-family axes line up staggered NAs on one complete-case index (#1454)", {
  set.seed(1)
  d <- data.frame(x = stats::rnorm(30))
  d$y1 <- stats::rnorm(30)
  d$y2 <- stats::rpois(30, 3)
  d$y1[3] <- NA
  d$y2[7] <- NA
  # Pure R mapping. drm_julia_xfam_axes() does not start Julia.
  ax <- drmTMB:::drm_julia_xfam_axes(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x),
    d,
    environment(),
    c("gaussian", "poisson")
  )
  shared <- setdiff(seq_len(30), c(3L, 7L))
  expect_identical(ax$mu1$rows, shared)
  expect_identical(ax$mu2$rows, shared)
  expect_identical(ax$sigma1$rows, shared)
  expect_identical(ax$sigma2$rows, shared)
  expect_equal(ax$mu1$y, d$y1[shared])
  expect_equal(ax$mu2$y, d$y2[shared])
  expect_equal(unname(ax$mu1$X[, "x"]), d$x[shared])
  expect_equal(unname(ax$mu2$X[, "x"]), d$x[shared])
  # The old length check kept 29 rows and paired y1[4:7] with y2[3:6].
  # Positions 3:6 of the aligned vectors are original rows 4, 5, 6 and 8.
  lined <- c(4L, 5L, 6L, 8L)
  expect_equal(ax$mu1$y[3:6], d$y1[lined])
  expect_equal(ax$mu2$y[3:6], d$y2[lined])
  expect_false(isTRUE(all.equal(ax$mu1$y[3:6], d$y1[4:7])))
})

test_that("cross-family axes keep a shared complete-case index (#1454)", {
  set.seed(1)
  d <- data.frame(x = stats::rnorm(30))
  d$y1 <- stats::rnorm(30)
  d$y2 <- stats::rpois(30, 3)
  d$y1[c(3, 7)] <- NA
  d$y2[c(3, 7)] <- NA
  ax <- drmTMB:::drm_julia_xfam_axes(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x),
    d,
    environment(),
    c("gaussian", "poisson")
  )
  expect_identical(ax$mu1$rows, ax$mu2$rows)
  expect_length(ax$mu1$y, 28L)
  expect_equal(ax$mu1$y, d$y1[-c(3, 7)])
  expect_equal(ax$mu2$y, d$y2[-c(3, 7)])
  expect_equal(unname(ax$mu1$X[, "x"]), d$x[-c(3, 7)])
  expect_equal(unname(ax$mu2$X[, "x"]), unname(ax$mu1$X[, "x"]))
})

test_that("cross-family sigma missingness drops that row from every axis (#1454)", {
  set.seed(1)
  d <- data.frame(
    y1 = stats::rnorm(20),
    y2 = stats::rpois(20, 2),
    x = stats::rnorm(20),
    z = stats::rnorm(20)
  )
  d$z[4] <- NA
  ax <- drmTMB:::drm_julia_xfam_axes(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~z),
    d,
    environment(),
    c("gaussian", "poisson")
  )
  shared <- setdiff(seq_len(20), 4L)
  expect_identical(ax$mu1$rows, shared)
  expect_identical(ax$mu2$rows, shared)
  expect_identical(ax$sigma1$rows, shared)
  expect_equal(ax$mu1$y, d$y1[shared])
  expect_equal(ax$mu2$y, d$y2[shared])
  expect_equal(unname(ax$sigma1$X[, "z"]), d$z[shared])
})

test_that("structured response = 'drop' removes incomplete rows and keeps group levels (#1454)", {
  K <- diag(2)
  dat <- data.frame(
    id = c("a", "a", "b", "b"),
    x = c(1, 2, 3, 4),
    y = c(1, NA, 3, 4)
  )
  form <- bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1)
  dropped <- drmTMB:::drm_julia_drop_structured_missing(dat, form)
  expect_equal(nrow(dropped), 3L)
  expect_equal(attr(dropped, "drm_julia_n_dropped"), 1L)
  expect_setequal(unique(as.character(dropped$id)), c("a", "b"))

  dat$y[3:4] <- NA
  expect_error(
    drmTMB:::drm_julia_drop_structured_missing(dat, form),
    "grouping level"
  )
})

# Local stand-in for the constructor in test-julia-diagnostics.R. test_file
# does not load sibling test files, and check_drm() only needs this shape.
drm_alignment_julia_fit <- function() {
  coef_names <- c("mu_(Intercept)", "mu_x", "sigma_(Intercept)")
  result <- list(
    coef_names = coef_names,
    coefficients = c(0.5, 1.2, -0.3),
    vcov = diag(c(0.01, 0.02, 0.03)),
    loglik = -20,
    aic = 46,
    bic = 49,
    df = 3L,
    nobs = 50L,
    converged = TRUE,
    fitted = rep(1, 50),
    residuals = rep(0, 50),
    sigma = rep(0.8, 50),
    corpairs = list(),
    gradient = c(0.0002, -0.0005, 0.0001),
    gradient_names = coef_names
  )
  drmTMB:::new_drmTMB_julia(
    result = result,
    call = quote(drmTMB(bf(y ~ x, sigma ~ 1), data = dat, engine = "julia")),
    formula = bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = data.frame(y = rep(1, 50), x = rep(1, 50)),
    family_type = "gaussian"
  )
}

test_that("bivariate q2 structured payloads refuse incomplete rows (#1454)", {
  K <- diag(2)
  dat <- data.frame(
    id = c("a", "a", "b", "b"),
    x = c(1, 2, 3, 4),
    y1 = c(1, 2, NA, 4),
    y2 = c(1, 2, 3, 4)
  )
  form <- bf(
    mu1 = y1 ~ x + relmat(1 | p | id, K = K),
    mu2 = y2 ~ x + relmat(1 | p | id, K = K),
    sigma1 = ~1,
    sigma2 = ~1,
    rho12 = ~1
  )
  expect_error(
    drmTMB:::drm_julia_biv_known_structured_payload(
      form,
      "biv_gaussian",
      dat,
      environment()
    ),
    "complete responses"
  )
  # The payload helper is what the bridge calls. Calling it with complete
  # data still builds the matrix payload and does not need Julia.
  dat$y1[3] <- 3
  expect_silent(
    drmTMB:::drm_julia_require_complete_rows(
      dat,
      form,
      "bivariate q2 structured models"
    )
  )
  payload <- drmTMB:::drm_julia_biv_known_structured_payload(
    form,
    "biv_gaussian",
    dat,
    environment()
  )
  expect_equal(nrow(payload$data), 4L)
})

test_that("cross-family cbind() responses are refused with and without NA (#1454)", {
  d <- data.frame(
    s = c(2, 0, 1, 4),
    f = c(1, 3, 2, 1),
    y2 = c(1, 2, 0, 1),
    x = c(0.2, -0.4, 0.1, 0.3)
  )
  form <- bf(mu1 = cbind(s, f) ~ x, mu2 = y2 ~ x)
  # No missing values. The old length check aborted this fit because the
  # flattened response had length 2n. Subsetting that vector kept successes
  # only. The refusal has to fire before any shared-row index is built.
  expect_error(
    drmTMB:::drm_julia_xfam_axes(
      form, d, environment(), c("binomial", "poisson")
    ),
    "cbind"
  )
  d$s[2] <- NA
  d$y2[4] <- NA
  expect_error(
    drmTMB:::drm_julia_xfam_axes(
      form, d, environment(), c("binomial", "poisson")
    ),
    "cbind"
  )
  # A single 0/1 column is still a binomial response this route can marshal.
  d$y1 <- c(0, 1, 0, 1)
  ax <- drmTMB:::drm_julia_xfam_axes(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x),
    d,
    environment(),
    c("binomial", "poisson")
  )
  expect_equal(ax$mu1$y, c(0, 1, 0))
  expect_equal(ax$mu2$y, c(1, 2, 0))
})

test_that("cross-family formulas refuse offset() on location and sigma (#1454)", {
  d <- data.frame(
    y1 = stats::rnorm(8),
    y2 = stats::rpois(8, 2),
    x = stats::rnorm(8),
    z = stats::runif(8, 0.2, 2)
  )
  expect_error(
    drmTMB:::drm_julia_xfam_axes(
      bf(mu1 = y1 ~ x + offset(log(z)), mu2 = y2 ~ x),
      d,
      environment(),
      c("gaussian", "poisson")
    ),
    "offset"
  )
  expect_error(
    drmTMB:::drm_julia_xfam_axes(
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~offset(log(z))),
      d,
      environment(),
      c("gaussian", "poisson")
    ),
    "offset"
  )
})

test_that("an NA on y1 that empties a mu2 factor level rebuilds the design (#1454)", {
  d <- data.frame(
    y1 = c(1, 1, 1, 1, 1, 1),
    y2 = c(1, 2, 3, 4, 5, 6),
    g = factor(c("a", "a", "b", "b", "c", "c"), levels = c("a", "b", "c"))
  )
  d$y1[5:6] <- NA
  ax <- drmTMB:::drm_julia_xfam_axes(
    bf(mu1 = y1 ~ 1, mu2 = y2 ~ g),
    d,
    environment(),
    c("gaussian", "poisson")
  )
  shared <- 1:4
  expect_identical(ax$mu1$rows, shared)
  expect_identical(ax$mu2$rows, shared)
  rebuilt <- stats::model.matrix(~g, droplevels(d[shared, , drop = FALSE]))
  expect_identical(ax$mu2$coef_names, colnames(rebuilt))
  expect_equal(unname(ax$mu2$X), unname(rebuilt))
  expect_false(any(colSums(abs(ax$mu2$X)) == 0))
  expect_false("gc" %in% ax$mu2$coef_names)

  # One observed level left: the contrast cannot be built. Refuse rather than
  # send a rank-deficient design.
  d2 <- data.frame(
    y1 = c(1, 1, 1, 1),
    y2 = c(1, 2, 3, 4),
    g = factor(c("a", "a", "b", "b"), levels = c("a", "b"))
  )
  d2$y1[3:4] <- NA
  expect_error(
    drmTMB:::drm_julia_xfam_axes(
      bf(mu1 = y1 ~ 1, mu2 = y2 ~ g),
      d2,
      environment(),
      c("gaussian", "poisson")
    ),
    "factor level"
  )

  result <- list(
    rho_latent = 0.1,
    rho_ci_wald_lower = -0.2,
    rho_ci_wald_upper = 0.4,
    rho_ci_prof_lower = -0.1,
    rho_ci_prof_upper = 0.3,
    beta1 = 0.5,
    beta2 = c(0.2, -0.4),
    sigma_coef1 = -0.2,
    sigma_coef2 = numeric(),
    lambda1 = 0.3,
    lambda2 = 0.1,
    sigma1 = 0.8,
    sigma2 = NaN,
    loglik = -12,
    converged = TRUE
  )
  fit <- drmTMB:::new_drmTMB_julia_xfam(
    result = result,
    call = quote(drmTMB()),
    formula = bf(mu1 = y1 ~ 1, mu2 = y2 ~ g),
    family = c(gaussian(), poisson()),
    families = c("gaussian", "poisson"),
    axes = ax,
    data = d
  )
  expect_identical(fit$kept_rows, shared)
  expect_length(fitted(fit)$mu1, nrow(d))
  expect_length(residuals(fit)$mu2, nrow(d))
  expect_true(all(is.na(fitted(fit)$mu1[5:6])))
  expect_true(all(is.na(residuals(fit)$mu2[5:6])))
  expect_equal(fitted(fit)$mu1[shared], rep(0.5, 4))
  expect_equal(
    fitted(fit)$mu2[shared],
    as.numeric(exp(ax$mu2$X %*% c(0.2, -0.4)))
  )
  # y2 is observed on the dropped rows. residuals() is still NA there,
  # because those rows are not in the fit.
  expect_false(anyNA(d$y2[5:6]))
  expect_equal(
    residuals(fit)$mu2[shared],
    d$y2[shared] - fitted(fit)$mu2[shared]
  )
})

test_that("the main Julia drop records a complete-case count for check_drm() (#1454)", {
  f <- bf(y ~ x)
  dat <- data.frame(y = c(1, NA, 3), x = c(1, 2, 3))
  dropped <- drmTMB:::drm_julia_drop_missing_rows(dat, f)
  expect_equal(attr(dropped, "drm_julia_n_dropped"), 1L)
  expect_equal(attr(dropped, "drm_julia_n_input"), 3L)

  fit <- drm_alignment_julia_fit()
  fit$missing_rows <- drmTMB:::drm_julia_missing_rows_slot(dropped)
  fit$nobs <- 2L
  dc <- check_drm(fit)
  row <- dc[dc$check == "dropped_rows", ]
  expect_identical(row$status, "note")
  expect_match(row$value, "dropped=1", fixed = TRUE)
  expect_match(row$message, "complete-case", fixed = TRUE)
})
