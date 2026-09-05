# #1144: the constrained ordinal-cutpoint endpoint solve stopped wherever
# nlminb alone stopped, while the free optimum is Newton-polished to ~1e-9.
# On the committed random-intercept cumulative_logit fixture
# (tests/testthat/test-arc2a-mu-random-intercept.R, seed 9) that left a
# gradient of 3.6e-4 to 1.9e-3 at the six endpoints (two above the 1e-3
# guard) against 8.5e-10 at the free optimum -- the same
# asymmetry that biased the main endpoint solve (#1130). Both endpoints are now
# polished the same way; PROFILE_ENDPOINT_GRADIENT_TOL (1e-3) is unchanged.

drm_ordinal_cutpoint_random_intercept_fit <- function() {
  set.seed(9)
  n_id <- 45L; n_each <- 18L
  id <- factor(rep(seq_len(n_id), each = n_each)); n <- length(id)
  dat <- data.frame(id = id, x = stats::rnorm(n))
  sd_id <- 0.7; u_id <- stats::rnorm(n_id, sd = sd_id); u_id <- u_id - mean(u_id)
  cut <- c(-1, 0, 1)
  lat <- 0.8 * dat$x + u_id[id] + stats::rlogis(n)
  dat$y <- ordered(findInterval(lat, cut) + 1L, levels = 1:4)
  drmTMB(bf(y ~ x + (1 | id)), family = cumulative_logit(), data = dat)
}

# Gradient of the constrained cutpoint objective with respect to the free
# parameters at a solved endpoint: the same chain rule the evaluator uses
# (theta_ord[1] is solved from the pinned cumulative cutpoint, so later log
# gaps carry a term from the first coordinate).
drm_cutpoint_endpoint_gradient <- function(fit, target, value) {
  drmTMB:::drm_pin_tmb_object_to_optimum(fit$obj, fit$opt, fit$tmb_state)
  control <- drmTMB:::profile_endpoint_inner_control(list())
  evaluator <- drmTMB:::ordinal_cutpoint_profile_evaluator(fit, target, control)
  solved <- evaluator$evaluate(value, evaluator$start_free)
  index <- as.integer(target$index[[1L]])
  theta_positions <- evaluator$theta_positions
  free_positions <- setdiff(seq_along(fit$opt$par), theta_positions[[1L]])
  full <- evaluator$compose(solved$par, value)
  gradient <- fit$obj$gr(full)
  out <- gradient[free_positions]
  if (index > 1L) {
    theta <- full[theta_positions]
    affected <- theta_positions[seq.int(2L, index)]
    affected_free <- match(affected, free_positions)
    out[affected_free] <- out[affected_free] -
      gradient[[theta_positions[[1L]]]] * exp(theta[seq.int(2L, index)])
  }
  list(max_abs_gradient = max(abs(out)), nll = solved$nll)
}

test_that("both cutpoint profile endpoints are polished to the free-fit gradient scale", {
  fit <- drm_ordinal_cutpoint_random_intercept_fit()
  expect_true(isTRUE(fit$control$newton_polish))
  free_gradient <- max(abs(fit$obj$gr(fit$opt$par)))
  expect_lt(free_gradient, 1e-8)

  targets <- profile_targets(fit)
  targets <- targets[targets$target_class == "ordinal-cutpoint", , drop = FALSE]
  expect_equal(
    targets$parm,
    c("ordinal:cutpoint:1|2", "ordinal:cutpoint:2|3", "ordinal:cutpoint:3|4")
  )

  ci <- stats::confint(
    fit, parm = targets$parm, level = 0.95, method = "profile", trace = FALSE
  )
  expect_equal(ci$conf.status, rep("profile", 3L))
  expect_true(all(is.finite(ci$lower)) && all(is.finite(ci$upper)))
  expect_true(all(ci$lower < targets$estimate))
  expect_true(all(ci$upper > targets$estimate))

  # Before the polish the same six endpoints stopped at 3.6e-4 to 1.9e-3;
  # after it each sits at the polished optimum (measured 4e-14 to 7e-9).
  # 1e-6 is more than two orders below the unpolished stops and two above
  # the polish target, so a reverted polish fails this and optimiser noise
  # does not.
  for (k in seq_len(nrow(targets))) {
    target <- targets[k, , drop = FALSE]
    for (side in c("lower", "upper")) {
      solved <- drm_cutpoint_endpoint_gradient(fit, target, ci[[side]][[k]])
      expect_lt(
        solved$max_abs_gradient, 1e-6,
        label = sprintf("%s %s endpoint max|gradient|", target$parm, side)
      )
      # A polished endpoint sits ON the likelihood-ratio cutoff, so the
      # constrained nll is the fitted nll plus the chi-square(1) cutoff.
      expect_equal(
        solved$nll - unname(fit$opt$objective),
        stats::qchisq(0.95, df = 1) / 2,
        tolerance = 1e-3,
        label = sprintf("%s %s endpoint nll gap", target$parm, side)
      )
    }
  }
})

test_that("cutpoint endpoint polish respects drm_control(newton_polish = FALSE)", {
  # Symmetric in the other direction too: switching the free-fit polish off
  # must not leave the constrained side polished on its own.
  fit <- drm_ordinal_cutpoint_random_intercept_fit()
  fit$control$newton_polish <- FALSE
  targets <- profile_targets(fit)
  target <- targets[targets$parm == "ordinal:cutpoint:1|2", , drop = FALSE]
  ci <- stats::confint(
    fit, parm = target$parm, level = 0.95, method = "profile", trace = FALSE
  )
  expect_equal(ci$conf.status, "profile")
  solved <- drm_cutpoint_endpoint_gradient(fit, target, ci$upper)
  # With no polish the solve stops where nlminb stops: above the polished
  # scale, below the PROFILE_ENDPOINT_GRADIENT_TOL guard that is unchanged.
  expect_gt(solved$max_abs_gradient, 1e-6)
  expect_lte(solved$max_abs_gradient, drmTMB:::PROFILE_ENDPOINT_GRADIENT_TOL * 3)
  expect_equal(drmTMB:::PROFILE_ENDPOINT_GRADIENT_TOL, 1e-3)
})

test_that("the committed fixed-effect ordinal fixture keeps its cutpoint intervals", {
  # The fixture from test-profile-targets.R: already near the polished
  # scale before #1144, so the interval must be unchanged to optimiser
  # precision and both endpoints now sit at the polished optimum.
  set.seed(20260812)
  dat <- data.frame(y = ordered(rep(1:3, each = 30L)), x = stats::rnorm(90L))
  fit <- drmTMB(bf(y ~ x), family = cumulative_logit(), data = dat)
  parm <- c("ordinal:cutpoint:1|2", "ordinal:cutpoint:2|3")
  ci <- stats::confint(fit, parm = parm, level = 0.80, method = "profile", trace = FALSE)
  expect_equal(ci$lower, c(-1.0613300302, 0.3535125449), tolerance = 1e-6)
  expect_equal(ci$upper, c(-0.4621264568, 0.9417268093), tolerance = 1e-6)
  targets <- profile_targets(fit)
  for (k in seq_along(parm)) {
    target <- targets[targets$parm == parm[[k]], , drop = FALSE]
    for (side in c("lower", "upper")) {
      solved <- drm_cutpoint_endpoint_gradient(fit, target, ci[[side]][[k]])
      expect_lt(solved$max_abs_gradient, 1e-6)
    }
  }
})
