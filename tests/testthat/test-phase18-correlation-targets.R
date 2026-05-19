source_phase18_correlation_targets <- function(env = parent.frame()) {
  source(
    system.file(
      "sim/R/sim_correlation_targets.R",
      package = "drmTMB",
      mustWork = TRUE
    ),
    local = env
  )
}

new_phase18_biv_rho_data <- function(n = 110L, modelled = FALSE) {
  set.seed(20260624)
  x <- stats::rnorm(n)
  w <- stats::rnorm(n)
  mu1 <- 0.20 + 0.45 * x
  mu2 <- -0.10 - 0.30 * x
  rho <- if (modelled) {
    0.99999999 * tanh(0.10 + 0.35 * w)
  } else {
    rep(0.25, n)
  }
  e1 <- stats::rnorm(n)
  e2 <- rho * e1 + sqrt(1 - rho^2) * stats::rnorm(n)
  data.frame(
    y1 = mu1 + 0.55 * e1,
    y2 = mu2 + 0.65 * e2,
    x = x,
    w = w
  )
}

new_phase18_group_cor_data <- function(n_id = 16L, n_each = 5L) {
  set.seed(20260625)
  ID <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(ID)
  x <- stats::rnorm(n)
  z0 <- stats::rnorm(n_id)
  z1 <- stats::rnorm(n_id)
  rho <- 0.40
  u0 <- 0.45 * z0
  u1 <- 0.30 * (rho * z0 + sqrt(1 - rho^2) * z1)
  data.frame(
    y = 0.15 + 0.55 * x + u0[ID] + u1[ID] * x + stats::rnorm(n, sd = 0.35),
    x = x,
    ID = ID
  )
}

test_that("Phase 18 correlation inventory records constant residual rho12 route", {
  source_phase18_correlation_targets()
  dat <- new_phase18_biv_rho_data(modelled = FALSE)
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~1),
    family = biv_gaussian(),
    data = dat
  )

  inventory <- phase18_correlation_target_inventory(fit)

  expect_equal(nrow(inventory), 1L)
  expect_equal(inventory$artifact_grain, "inventory")
  expect_equal(inventory$level, "residual")
  expect_equal(inventory$parameter, "rho12")
  expect_false(inventory$modelled)
  expect_equal(inventory$profile_target, "rho12")
  expect_true(inventory$profile_ready)
  expect_equal(inventory$interval_route, "direct_profile")
  expect_equal(inventory$interval_status, "profile_ready")
})

test_that("Phase 18 correlation inventory keeps modelled rho12 as newdata work", {
  source_phase18_correlation_targets()
  dat <- new_phase18_biv_rho_data(modelled = TRUE)
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~w),
    family = biv_gaussian(),
    data = dat
  )

  inventory <- phase18_correlation_target_inventory(fit)

  expect_equal(nrow(inventory), 1L)
  expect_equal(inventory$level, "residual")
  expect_true(inventory$modelled)
  expect_true(is.na(inventory$profile_target))
  expect_false(inventory$profile_ready)
  expect_equal(inventory$interval_route, "response_scale_profile_newdata")
  expect_equal(inventory$interval_status, "newdata_required")
})

test_that("Phase 18 correlation inventory maps ordinary group correlations", {
  source_phase18_correlation_targets()
  dat <- new_phase18_group_cor_data()
  fit <- drmTMB(
    bf(y ~ x + (1 + x | p | ID)),
    family = gaussian(),
    data = dat
  )

  inventory <- phase18_correlation_target_inventory(fit)

  expect_equal(nrow(inventory), 1L)
  expect_equal(inventory$level, "group")
  expect_equal(inventory$group, "ID")
  expect_equal(inventory$block, "p")
  expect_equal(inventory$class, "mean-slope")
  expect_true(startsWith(inventory$profile_target, "cor:mu:"))
  expect_true(inventory$profile_ready)
  expect_equal(inventory$interval_route, "direct_profile")
  expect_equal(inventory$interval_status, "profile_ready")
})

test_that("Phase 18 correlation inventory returns a typed empty table", {
  source_phase18_correlation_targets()
  dat <- data.frame(y = c(0.1, 0.4, 0.7, 1.0), x = c(-1, 0, 1, 2))
  fit <- drmTMB(bf(y ~ x), family = gaussian(), data = dat)

  inventory <- phase18_correlation_target_inventory(fit)

  expect_equal(nrow(inventory), 0L)
  expect_named(
    inventory,
    c(
      "artifact_grain",
      "level",
      "group",
      "block",
      "from_dpar",
      "to_dpar",
      "class",
      "parameter",
      "estimate",
      "min",
      "max",
      "n_values",
      "modelled",
      "profile_target",
      "target_type",
      "profile_ready",
      "profile_note",
      "interval_route",
      "interval_status"
    )
  )
})
