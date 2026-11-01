# FX3b: shared three-valued convergence_status; is_converged := status ==
# "converged". Red-proof: on the pin / FX3 head, a boundary RE-SD fit still
# returned is_converged() TRUE. After this change it is FALSE, while
# convergence_status() is "boundary". Print, summary, and check_drm show the
# status.

test_that("is_converged is TRUE only when status is converged (FX3b red-proof)", {
  set.seed(20261016)
  dat <- data.frame(y = rnorm(40, sd = 0.5), x = rnorm(40))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat)
  expect_identical(convergence_status(fit), "converged")
  expect_true(is_converged(fit))
  expect_true(converged(fit))

  printed <- paste(utils::capture.output(print(fit), type = "message"), collapse = "\n")
  expect_match(printed, "convergence_status: converged", fixed = TRUE)

  sm <- summary(fit)
  expect_identical(sm$convergence_status, "converged")
  sm_printed <- paste(utils::capture.output(print(sm), type = "message"), collapse = "\n")
  expect_match(sm_printed, "convergence_status: converged", fixed = TRUE)

  chk <- check_drm(fit)
  expect_identical(chk$value[chk$check == "convergence_status"], "converged")
  expect_identical(chk$status[chk$check == "convergence_status"], "ok")

  # On FX3 / the pin, a boundary RE-SD still returned is_converged() TRUE.
  # Mutate a clearly interior random intercept rather than relying on n=40
  # with tiny groups, which can already sit below 1e-4.
  set.seed(20261016)
  g <- factor(rep(seq_len(8), each = 25))
  u <- rnorm(nlevels(g), sd = 0.8)
  re_dat <- data.frame(
    y = rnorm(length(g), sd = 0.4) + u[g],
    x = rnorm(length(g)),
    g = g
  )
  re_fit <- drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), data = re_dat)
  expect_identical(convergence_status(re_fit), "converged")
  expect_true(is_converged(re_fit))
  boundary <- re_fit
  stopifnot(length(boundary$sdpars$mu) >= 1L)
  boundary$sdpars$mu[[1L]] <- 1e-8
  expect_identical(convergence_status(boundary), "boundary")
  expect_false(is_converged(boundary))
  expect_false(converged(boundary))
  chk_b <- check_drm(boundary)
  expect_identical(chk_b$value[chk_b$check == "convergence_status"], "boundary")
  expect_identical(chk_b$status[chk_b$check == "convergence_status"], "note")
})

test_that("twin inflated-SE and rank predicates match the documented constants", {
  expect_identical(drmTMB:::drm_twin_rank_tol, 1e-8)
  expect_identical(drmTMB:::drm_twin_inflated_se_floor, 50)
  expect_identical(drmTMB:::drm_twin_inflated_se_ratio, 1000)
  expect_identical(drmTMB:::drm_twin_re_sd_boundary, 1e-4)
  expect_identical(drmTMB:::drm_twin_rho12_boundary, 0.98)
  expect_identical(drmTMB:::drm_twin_sentinel_loglik, -1e15)

  expect_false(drmTMB:::drm_twin_inflated_se_is_true(c(0.1, 0.2, 0.15)))
  # SE >= 50 and >= 1000 x median of the sub-50 reference.
  expect_true(drmTMB:::drm_twin_inflated_se_is_true(c(0.1, 0.2, 500)))
  # min-SE fallback when every SE is >= 50: ratio against min(SE).
  expect_false(drmTMB:::drm_twin_inflated_se_is_true(c(80, 90, 100)))
  expect_true(drmTMB:::drm_twin_inflated_se_is_true(c(80, 90, 8e5)))
})

test_that("optimizer failure and skipped SEs keep the documented status", {
  dat <- data.frame(y = c(-0.2, 0.1, 0.4, 0.7, 1.0, 1.2), x = c(-1, -0.5, 0, 0.5, 1, 1.5))
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(optimizer = list(eval.max = 100, iter.max = 100))
  )
  failed <- fit
  failed$opt$convergence <- 1L
  expect_identical(convergence_status(failed), "degenerate")
  expect_false(is_converged(failed))
  chk <- check_drm(failed)
  expect_identical(chk$value[chk$check == "convergence_status"], "degenerate")
  expect_identical(chk$status[chk$check == "convergence_status"], "warning")

  se_skipped <- fit
  se_skipped$sdr <- NULL
  se_skipped$uncertainty <- list(
    status = "skipped",
    message = "TMB::sdreport() was skipped."
  )
  expect_identical(convergence_status(se_skipped), "converged")
  expect_true(is_converged(se_skipped))
  expect_false(is_converged(se_skipped, include_hessian = TRUE))
})
