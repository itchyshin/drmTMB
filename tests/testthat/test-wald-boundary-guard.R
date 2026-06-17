# Wave 1 honesty guard 3: a Wald interval on a variance-component SD near zero or
# a correlation near +/-1 is unreliable (boundary / chi-square-mixture inference),
# yet it was returned as an ordinary symmetric interval with conf.status "wald".
# confint(method = "wald") now flags such rows as "wald_at_boundary" and warns,
# pointing to method = "profile". The interval is still returned -- a boundary is
# a warning, not an auto-discard. A residual/distributional scale near zero is
# regular and is NOT flagged.
#
# The classification logic is unit-tested deterministically; two real fits
# confirm the wiring (a collapsed random-effect SD, and a healthy fit).

target_row <- function(target_class, estimate) {
  data.frame(
    target_class = target_class,
    estimate = estimate,
    stringsAsFactors = FALSE
  )
}

test_that("wald_boundary_targets flags near-zero SDs and near-boundary correlations", {
  tg <- do.call(
    rbind,
    list(
      target_row("random-effect-sd", 5e-5), # SD ~ 0       -> TRUE
      target_row("random-effect-sd", 0.8), # healthy SD    -> FALSE
      target_row("random-effect-correlation", 0.99), # ~ +1 -> TRUE
      target_row("residual-correlation", -0.995), # ~ -1     -> TRUE
      target_row("residual-correlation", 0.3), # healthy     -> FALSE
      target_row("distributional-scale", 1e-6), # residual sigma small -> FALSE
      target_row("distributional-mean", 0) # fixed effect    -> FALSE
    )
  )
  expect_equal(
    wald_boundary_targets(tg),
    c(TRUE, FALSE, TRUE, TRUE, FALSE, FALSE, FALSE)
  )
})

test_that("wald_boundary_targets respects custom thresholds and finite estimates", {
  tg <- do.call(
    rbind,
    list(
      target_row("random-effect-sd", 0.005),
      target_row("residual-correlation", 0.9),
      target_row("random-effect-sd", NA_real_)
    )
  )
  expect_equal(wald_boundary_targets(tg), c(FALSE, FALSE, FALSE))
  expect_equal(
    wald_boundary_targets(tg, sd_boundary = 0.01, rho_boundary = 0.85),
    c(TRUE, TRUE, FALSE)
  )
})

healthy_re_fit <- function() {
  set.seed(11)
  n_id <- 40
  n <- n_id * 6
  u <- stats::rnorm(n_id, 0, 0.8)
  dat <- data.frame(
    id = factor(rep(seq_len(n_id), each = 6)),
    x = stats::rnorm(n)
  )
  dat$y <- 0.5 + 0.4 * dat$x + u[dat$id] + stats::rnorm(n, 0, 0.5)
  drmTMB(bf(y ~ x + (1 | id), sigma ~ 1), family = gaussian(), data = dat)
}

test_that("confint(method = 'wald') flags a boundary target and warns, keeping the interval", {
  fit <- healthy_re_fit()
  # The fitted RE SD is ~0.8; raising sd_boundary above it forces the boundary
  # branch deterministically (no reliance on a collapsed-SD draw).
  ci <- NULL
  expect_warning(
    ci <- stats::confint(fit, method = "wald", sd_boundary = 1.0),
    "boundary"
  )
  sd_row <- ci[ci$parm == "sd:mu:(1 | id)", ]
  expect_equal(sd_row$conf.status, "wald_at_boundary")
  # a boundary is a warning, not an auto-discard: the interval is still returned
  expect_true(is.finite(sd_row$lower) || is.finite(sd_row$upper))
})

test_that("confint(method = 'wald') does not flag a healthy fit at default thresholds", {
  fit <- healthy_re_fit()
  ci <- stats::confint(fit, method = "wald")
  expect_false(any(ci$conf.status == "wald_at_boundary"))
  expect_true("sd:mu:(1 | id)" %in% ci$parm)
})
