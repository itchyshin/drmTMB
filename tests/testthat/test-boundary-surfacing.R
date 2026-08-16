# Boundary surfacing: the bootstrap route must not be the one silent way to
# obtain an unflagged interval at a variance boundary, and check_drm() must not
# imply it assessed interval reliability when it did not.

boundary_fit <- function(seed = 11, n_group = 10, per = 4) {
  set.seed(seed)
  n <- n_group * per
  d <- data.frame(
    y = stats::rnorm(n),            # no true group effect: SD collapses
    x = stats::rnorm(n),
    g = factor(rep(seq_len(n_group), each = per))
  )
  drmTMB(bf(mu = y ~ x + (1 | g), sigma = ~1), data = d, family = gaussian())
}

identified_fit <- function(seed = 9, n_group = 30, per = 12, sd_u = 0.9) {
  set.seed(seed)
  n <- n_group * per
  g <- factor(rep(seq_len(n_group), each = per))
  u <- stats::rnorm(n_group, 0, sd_u)
  d <- data.frame(
    y = stats::rnorm(n, 1 + u[g], 0.5),
    x = stats::rnorm(n),
    g = g
  )
  drmTMB(bf(mu = y ~ x + (1 | g), sigma = ~1), data = d, family = gaussian())
}

sd_target <- function(fit) {
  tg <- profile_targets(fit)
  tg$parm[grepl("^sd", tg$parm)][[1L]]
}

test_that("the bootstrap route warns at a variance boundary, as profile does", {
  skip_on_cran()
  fit <- boundary_fit()
  parm <- sd_target(fit)

  # The profile route already warns here; before this guard the bootstrap route
  # returned a clean-looking interval on the SAME fit and target and said
  # nothing, which made it the unguarded way to report a boundary interval.
  expect_warning(
    stats::confint(fit, parm = parm, method = "profile"),
    class = "drmTMB_profile_boundary_warning"
  )
  expect_warning(
    ci <- stats::confint(fit, parm = parm, method = "bootstrap", R = 40),
    class = "drmTMB_bootstrap_boundary_warning"
  )
  expect_identical(ci$conf.status, "bootstrap_at_boundary")
})

test_that("a well-identified random effect is not flagged", {
  skip_on_cran()
  fit <- identified_fit()
  parm <- sd_target(fit)
  expect_no_warning(
    ci <- stats::confint(fit, parm = parm, method = "bootstrap", R = 40),
    class = "drmTMB_bootstrap_boundary_warning"
  )
  expect_identical(ci$conf.status, "bootstrap")
  # The interval is clear of the bound, which is what "not flagged" must mean.
  expect_gt(ci$lower, 0.1)
})

test_that("too few retained draws cannot trip the boundary flag", {
  skip_on_cran()
  # A share is not a statistic at R = 2: one boundary draw would read as 50%.
  # Plumbing tests deliberately run that small, so the flag must stay silent
  # rather than fire on noise.
  fit <- boundary_fit()
  parm <- sd_target(fit)
  expect_no_warning(
    ci <- stats::confint(
      fit,
      parm = parm,
      method = "bootstrap",
      R = 2,
      refit_control = drm_control(se = FALSE)
    ),
    class = "drmTMB_bootstrap_boundary_warning"
  )
  expect_false(identical(ci$conf.status, "bootstrap_at_boundary"))
})

test_that("the boundary share is measured on the natural scale", {
  skip_on_cran()
  # Regression: the first implementation tested `bootstrap_percentile_draws()`,
  # which returns LINK-scale values whenever the percentile is taken there. On
  # the log scale every SD below 1 is negative and therefore "below 1e-4", so a
  # well-identified SD of 0.9 was flagged. The test must be on the natural
  # scale, matching wald_boundary_targets().
  draws <- c(0.6, 0.7, 0.8, 0.9, 1.0)
  target <- data.frame(
    target_class = "ordinary-re-sd",
    stringsAsFactors = FALSE
  )
  expect_equal(
    bootstrap_boundary_share_at(rep(draws, 8L), target),
    0
  )
  at_bound <- c(rep(0, 10L), rep(0.5, 30L))
  expect_equal(
    bootstrap_boundary_share_at(at_bound, target),
    0.25
  )
})

test_that("check_drm() states that it does not assess interval reliability", {
  skip_on_cran()
  fit <- boundary_fit()
  res <- check_drm(fit)
  row <- res[res$check == "interval_reliability_scope", , drop = FALSE]

  expect_equal(nrow(row), 1L)
  expect_identical(row$status, "note")
  expect_match(row$value, "assessed_here=0")
  expect_match(row$message, "conf\\.status")

  # The point of the row: every fit-level check can pass while confint() still
  # warns about the same target. That is the state this fit is in.
  sd_row <- res[res$check == "random_effect_sd_boundary", , drop = FALSE]
  expect_identical(sd_row$status, "ok")
})

test_that("a fit with no random-effect SD target gets no scope note", {
  skip_on_cran()
  set.seed(3)
  d <- data.frame(y = stats::rnorm(60), x = stats::rnorm(60))
  fit <- drmTMB(bf(mu = y ~ x, sigma = ~1), data = d, family = gaussian())
  res <- check_drm(fit)
  expect_false(any(res$check == "interval_reliability_scope"))
})
