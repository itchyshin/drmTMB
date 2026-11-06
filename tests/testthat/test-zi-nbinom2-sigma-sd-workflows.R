zi_nbinom2_sigma_sd_workflow_data <- function(
  groups = 96L,
  repeats = 30L,
  seed = 2026102511L
) {
  set.seed(seed)
  group <- rep(seq_len(groups), each = repeats)
  group_w <- seq(-1, 1, length.out = groups)
  alpha <- c(`(Intercept)` = log(0.28), w = 0.38)
  tau <- exp(alpha[[1L]] + alpha[[2L]] * group_w)
  u <- stats::rnorm(groups, sd = tau)
  sigma <- exp(-0.55 + u[group])
  mu <- exp(0.45)
  zi <- 0.16
  y <- stats::rnbinom(length(group), size = 1 / sigma^2, mu = mu)
  y[stats::rbinom(length(group), 1L, zi) == 1L] <- 0L
  list(
    data = data.frame(y, id = factor(group), w = group_w[group]),
    alpha = alpha
  )
}

test_that("ZI-NB2 sigma SD slope is profile-ready and bootstrap retains its target", {
  sim <- zi_nbinom2_sigma_sd_workflow_data()
  formula <- drmTMB::bf(
    y ~ 1,
    sigma ~ 1 + (1 | id),
    zi ~ 1,
    sd(id, dpar = "sigma") ~ w
  )
  fit <- drmTMB::drmTMB(
    formula,
    family = nbinom2(),
    data = sim$data,
    control = list(eval.max = 600, iter.max = 600)
  )
  expect_equal(fit$opt$convergence, 0L)
  expect_true(isTRUE(fit$sdr$pdHess))

  targets <- profile_targets(fit)
  parm <- targets$parm[
    targets$dpar == 'sd(id, dpar = "sigma")' & targets$term == "w"
  ]
  expect_length(parm, 1L)
  target_row <- match(parm, targets$parm)
  expect_true(targets$profile_ready[[target_row]])

  bootstrap_ci <- suppressMessages(confint(
    fit,
    parm = parm,
    method = "bootstrap",
    R = 2L,
    seed = 2026102514L,
    parallel = "none",
    refit_control = drm_control(se = FALSE)
  ))
  diagnostics <- attr(bootstrap_ci, "bootstrap.diagnostics", exact = TRUE)
  expect_identical(bootstrap_ci$parm, parm)
  expect_identical(bootstrap_ci$method, "bootstrap")
  expect_equal(bootstrap_ci$bootstrap.n + bootstrap_ci$bootstrap.failed, 2L)
  expect_s3_class(diagnostics, "data.frame")
  expect_equal(nrow(diagnostics), 2L)
  expect_identical(diagnostics$parm, rep(parm, 2L))
  expect_true(all(diagnostics$target_available))
  expect_true(all(diagnostics$draw_used))
})
