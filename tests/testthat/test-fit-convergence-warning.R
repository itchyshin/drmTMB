# Wave 1 honesty guard 1: a fit the optimizer reports as non-converged must not
# look fine. A pure label interprets the nlminb code; the fit path warns when it
# is non-zero; print() and summary() surface the interpreted code and the
# optimizer message (#1545: summary() used to print only the bare code). The
# warning path is tested with a synthetic `opt` list (deterministic) rather than
# a forced bad fit, whose convergence code is optimizer/BLAS-path dependent.

test_that("drm_convergence_label returns NULL for a converged code", {
  expect_null(drm_convergence_label(0L, "relative convergence (4)"))
  expect_null(drm_convergence_label(0L, NULL))
})

test_that("drm_convergence_label interprets a non-zero code with its message", {
  lab <- drm_convergence_label(1L, "false convergence (8)")
  expect_type(lab, "character")
  expect_match(lab, "non-convergence")
  expect_match(lab, "false convergence (8)", fixed = TRUE)
})

test_that("drm_convergence_label is robust to a missing message and NA/empty code", {
  expect_match(drm_convergence_label(1L, NULL), "non-convergence")
  expect_match(drm_convergence_label(1L, ""), "non-convergence")
  expect_null(drm_convergence_label(NA_integer_, "x"))
  expect_null(drm_convergence_label(integer(0), "x"))
})

test_that("drm_warn_if_not_converged is silent on a converged fit and warns otherwise", {
  expect_no_warning(
    drm_warn_if_not_converged(list(
      convergence = 0L,
      message = "relative convergence (4)"
    ))
  )
  expect_warning(
    drm_warn_if_not_converged(list(
      convergence = 1L,
      message = "false convergence (8)"
    )),
    "non-convergence"
  )
})

test_that("a clean Gaussian fit converges and emits no convergence warning", {
  set.seed(1)
  n <- 60
  x <- stats::rnorm(n)
  dat <- data.frame(y = 1 + 0.5 * x + stats::rnorm(n, 0, 0.5), x = x)
  fit <- expect_no_warning(
    drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  )
  expect_equal(fit$opt$convergence, 0L)
})

test_that("drm_warn_if_nonfinite_objective is silent on a finite objective and warns otherwise", {
  expect_no_warning(drm_warn_if_nonfinite_objective(list(objective = -123.4)))
  expect_warning(
    drm_warn_if_nonfinite_objective(list(objective = NaN)),
    "not finite"
  )
  expect_warning(
    drm_warn_if_nonfinite_objective(list(objective = Inf)),
    "not finite"
  )
})

# --- #1545: summary() must flag a non-converged fit as clearly as print() ----
# Everything cli prints goes to the message stream; tables go to stdout. cli
# wraps a long message at the console width, so whitespace is squashed before
# matching.
convergence_printed <- function(x) {
  out <- utils::capture.output(
    msgs <- utils::capture.output(print(x), type = "message")
  )
  gsub("\\s+", " ", paste(c(msgs, out), collapse = "\n"))
}

convergence_fixture_fit <- function() {
  set.seed(1545)
  n <- 40
  x <- stats::rnorm(n)
  dat <- data.frame(y = 1 + 0.5 * x + stats::rnorm(n, 0, 0.5), x = x)
  drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
}

test_that("summary() of a non-converged fit says so and prints the optimizer message (#1545)", {
  fit <- convergence_fixture_fit()
  # The false-convergence state the Student t fits on #1504 ended in. Setting
  # it on a fitted object keeps the test deterministic across BLAS paths.
  fit$opt$convergence <- 1L
  fit$opt$message <- "false convergence (8)"

  smry <- summary(fit)
  expect_identical(smry$convergence_message, "false convergence (8)")
  printed <- convergence_printed(smry)
  expect_match(printed, "convergence: 1 (not converged; see `check_drm()`)", fixed = TRUE)
  expect_match(printed, "convergence message: false convergence (8)", fixed = TRUE)

  # print() and summary() share one display rule, message line included.
  printed_fit <- convergence_printed(fit)
  expect_match(printed_fit, "convergence: 1 (not converged; see `check_drm()`)", fixed = TRUE)
  expect_match(printed_fit, "convergence message: false convergence (8)", fixed = TRUE)
})

test_that("a converged fit's print() and summary() keep the bare code and no message line", {
  fit <- convergence_fixture_fit()
  expect_identical(as.integer(fit$opt$convergence), 0L)
  for (printed in list(convergence_printed(summary(fit)), convergence_printed(fit))) {
    expect_match(printed, "convergence: 0", fixed = TRUE)
    expect_no_match(printed, "not converged", fixed = TRUE)
    expect_no_match(printed, "convergence message:", fixed = TRUE)
  }
})

test_that("a summary object without a stored message still says not converged", {
  # summary.drmTMB objects saved before #1545 carry no convergence_message.
  fit <- convergence_fixture_fit()
  fit$opt$convergence <- 1L
  smry <- summary(fit)
  smry$convergence_message <- NULL
  printed <- convergence_printed(smry)
  expect_match(printed, "convergence: 1 (not converged; see `check_drm()`)", fixed = TRUE)
  expect_no_match(printed, "convergence message:", fixed = TRUE)
})

test_that("check_drm()'s convergence_status row does not call a failed optimizer a success (#1545)", {
  fit <- convergence_fixture_fit()
  fit$opt$convergence <- 1L
  fit$opt$message <- "false convergence (8)"
  chk <- check_drm(fit)
  row <- chk[chk$check == "convergence_status", ]
  # Value and status are unchanged; only the explanation was wrong.
  expect_identical(row$value, "degenerate")
  expect_identical(row$status, "note")
  expect_no_match(row$message, "reported success", fixed = TRUE)
  expect_match(row$message, "did not reach a converged, finite optimum", fixed = TRUE)
  optimizer_row <- chk[chk$check == "optimizer_convergence", ]
  expect_identical(optimizer_row$status, "warning")
  expect_match(optimizer_row$message, "false convergence (8)", fixed = TRUE)
})

test_that("an optimizer-starved Student t fit is flagged by summary(), not only at fit time", {
  set.seed(1545)
  n <- 80
  x <- stats::rnorm(n)
  dat <- data.frame(y = 1 + 0.5 * x + stats::rt(n, df = 6), x = x)
  # Explicit optimizer controls switch off the preset escalation ladder and
  # newton_polish = FALSE keeps the Newton step from rescuing the fit, so this
  # is a genuinely non-converged nlminb result, not a synthetic one.
  expect_warning(
    fit <- drmTMB(
      bf(y ~ x, sigma ~ 1, nu ~ 1),
      family = student(),
      data = dat,
      control = drm_control(
        newton_polish = FALSE,
        optimizer = list(iter.max = 1, eval.max = 2)
      )
    ),
    class = "drmTMB_convergence_warning"
  )
  expect_false(identical(as.integer(fit$opt$convergence), 0L))
  expect_no_warning(smry <- summary(fit))
  printed <- convergence_printed(smry)
  expect_match(printed, "(not converged; see `check_drm()`)", fixed = TRUE)
  expect_match(printed, paste("convergence message:", fit$opt$message), fixed = TRUE)
})

test_that("Julia-engine print() and summary() flag a non-converged fit with its message (#1545)", {
  opt <- drm_julia_opt_slot(list(converged = FALSE, iterations = 37L))
  fit <- structure(
    list(nobs = 12L, logLik = -20.5, opt = opt),
    class = "drmTMB_julia"
  )
  printed_fit <- convergence_printed(fit)
  expect_match(printed_fit, "convergence: 1 (not converged; see `check_drm()`)", fixed = TRUE)
  expect_match(printed_fit, paste("convergence message:", opt$message), fixed = TRUE)

  smry <- summary(fit)
  expect_false(smry$converged)
  expect_identical(smry$convergence_message, opt$message)
  printed <- convergence_printed(smry)
  expect_match(printed, "convergence: not converged (see `check_drm()`)", fixed = TRUE)
  expect_match(printed, "Optimiser iterations: 37.", fixed = TRUE)

  # A converged Julia fit keeps its one-word status and no message line.
  fit$opt <- drm_julia_opt_slot(list(converged = TRUE, iterations = 12L))
  printed <- convergence_printed(summary(fit))
  expect_match(printed, "convergence: converged", fixed = TRUE)
  expect_no_match(printed, "convergence message:", fixed = TRUE)
  expect_no_match(convergence_printed(fit), "not converged", fixed = TRUE)
})

test_that("cross-family Julia print() and summary() carry the convergence message (#1545)", {
  opt <- drm_julia_opt_slot(list(converged = FALSE, iterations = -1L))
  xfam <- structure(
    list(
      nobs = 12L, logLik = -20.5, opt = opt,
      families = c("gaussian", "poisson"), rho_latent = 0.3,
      coef_vector = c("mu1_(Intercept)" = 0.1, "mu2_(Intercept)" = 0.2)
    ),
    class = c("drmTMB_julia_xfam", "drmTMB_julia")
  )
  expect_match(
    convergence_printed(xfam),
    "convergence: 1 (not converged; see `check_drm()`)",
    fixed = TRUE
  )
  smry <- summary(xfam)
  expect_identical(smry$convergence_message, opt$message)
  printed <- convergence_printed(smry)
  expect_match(printed, "convergence: not converged (see `check_drm()`)", fixed = TRUE)
  expect_match(printed, "were not recorded by this route", fixed = TRUE)
})
