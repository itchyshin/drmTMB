skew_normal_slant_fit <- function(n = 400, seed = 20260610, nu = 0.0) {
  set.seed(seed)
  dat <- data.frame(x = stats::rnorm(n))
  mu <- 0.2 + 0.4 * dat$x
  sigma <- rep(1.0, n)
  native <- skew_normal_public_to_native(mu = mu, sigma = sigma, nu = nu)
  dat$y <- native$xi +
    native$omega *
      (native$delta *
        abs(stats::rnorm(n)) +
        sqrt(1 - native$delta^2) * stats::rnorm(n))
  drmTMB(
    bf(y ~ x, sigma ~ 1, nu ~ 1),
    family = skew_normal(),
    data = dat
  )
}

test_that("default Wald confint warns for the skew-normal slant nu", {
  fit <- skew_normal_slant_fit()

  expect_warning(
    confint(fit),
    "slant",
    ignore.case = TRUE
  )
  # The warning must point users to the better methods.
  expect_warning(
    confint(fit, parm = "fixef:nu:(Intercept)"),
    "profile.*bootstrap",
    ignore.case = TRUE
  )
})

test_that("recommended profile/bootstrap slant intervals do not warn", {
  fit <- skew_normal_slant_fit()

  expect_no_warning(
    confint(fit, parm = "fixef:nu:(Intercept)", method = "profile")
  )
})

test_that("other families' Wald confint is unaffected by the slant warning", {
  set.seed(20260610)
  n <- 400
  dat <- data.frame(x = stats::rnorm(n), z = stats::rnorm(n))
  mu <- 0.4 + 0.7 * dat$x
  sigma <- exp(-0.2 + 0.35 * dat$z)
  dat$y <- stats::rnorm(n, mean = mu, sd = sigma)

  gaussian_fit <- drmTMB(
    bf(y ~ x, sigma ~ z),
    family = gaussian(),
    data = dat
  )

  # A Gaussian fit has no slant; the skew-normal warning must not fire.
  # Scoped to the slant message so unrelated warnings (if any) do not mask it.
  ci <- withCallingHandlers(
    confint(gaussian_fit),
    warning = function(w) {
      if (grepl("slant", conditionMessage(w), ignore.case = TRUE)) {
        stop("skew-normal slant warning fired for a Gaussian fit")
      }
      invokeRestart("muffleWarning")
    }
  )
  expect_true("mu:x" %in% ci$parm || "fixef:mu:x" %in% ci$parm)
  # Direct check on the internal detector: no skew-normal slant targets.
  expect_length(
    drmTMB:::skew_normal_slant_targets(
      gaussian_fit,
      drmTMB:::drm_profile_targets(gaussian_fit)
    ),
    0L
  )
})
