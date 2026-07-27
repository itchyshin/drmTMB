runner_path <- testthat::test_path("..", "..", "tools", "run-arc6-bernoulli-nbinom2-f4-private.R")
source(runner_path, local = TRUE)

f4_test_sha <- paste(rep("a", 40L), collapse = "")

test_that("F4 freezes the full 24-cell and 24,000-attempt seed schedule", {
  grid <- f4_grid(); manifest <- f4_seed_manifest(grid)
  expect_equal(nrow(grid), 24L); expect_equal(nrow(manifest), 24000L)
  expect_identical(manifest$seed[[1L]], 2026172001L)
  expect_identical(manifest$seed[[1001L]], 2026272001L)
  expect_silent(f4_validate_seed_manifest(manifest))
  tampered <- manifest; tampered$seed[[1L]] <- tampered$seed[[1L]] + 1L
  expect_error(f4_validate_seed_manifest(tampered), "frozen 24,000-attempt")
})

test_that("F4 accepts only preparation and never exposes an execution CLI", {
  opts <- f4_parse_args(c("--mode=prepare", paste0("--expected-sha=", f4_test_sha), "--out-dir=f4-prep"))
  expect_identical(opts$expected_sha, f4_test_sha)
  expect_error(f4_parse_args(c("--mode=execute", paste0("--expected-sha=", f4_test_sha), "--out-dir=x")), "Usage")
})

test_that("F4 preflight rejects source and blob mismatches before preparation", {
  root <- tempfile("f4-root-"); dir.create(root); dir.create(file.path(root, "R")); file.create(file.path(root, "DESCRIPTION"))
  fake_git <- function(command, args, stdout, stderr) {
    if (identical(args, c("status", "--porcelain"))) return(character())
    if (identical(args, c("rev-parse", "HEAD"))) return(f4_test_sha)
    if (startsWith(args[[2L]], "HEAD:")) return("bad-blob")
    stop("unexpected fake Git call")
  }
  expect_error(f4_preflight(f4_test_sha, root, fake_git), "blob mismatch")
  wrong_head <- function(command, args, stdout, stderr) if (identical(args, c("status", "--porcelain"))) character() else paste(rep("b", 40L), collapse = "")
  expect_error(f4_preflight(f4_test_sha, root, wrong_head), "does not equal")
})

test_that("F4 terminal status uses the preregistered earliest-stage precedence", {
  row <- f4_status_template(f4_seed_manifest()[1L, ], f4_test_sha)
  row$bernoulli_margin_status <- "bernoulli_margin_failure"
  row$sandwich_status <- "bread_solve_failure"
  final <- f4_terminalize(row)
  expect_identical(final$terminal_stage, "bernoulli_margin")
  expect_identical(final$terminal_status, "bernoulli_margin_failure")
  row$protocol_status <- "quarantined"
  final <- f4_terminalize(row)
  expect_identical(final$terminal_stage, "dgp_harness")
  expect_identical(final$terminal_status, "protocol_quarantine")
})

test_that("F4 retains unavailable and boundary attempts without an alpha point", {
  row <- f4_status_template(f4_seed_manifest()[1L, ], f4_test_sha)
  row$bernoulli_margin_status <- "ok"; row$nb2_mean_status <- "ok"
  row$nb2_dispersion_status <- "ok"
  association <- list(status = "near_boundary", rectangle_ok = TRUE, alpha = 7.9)
  sandwich <- list(status = "ok", alpha_covariance = matrix(0.04, 1L, 1L), alpha_se = 0.2, eta_se = 0.01)
  result <- f4_apply_alpha_extract(row, association, sandwich)
  expect_equal(nrow(result), 1L); expect_false(result$point_available)
  expect_false(result$interval_available); expect_identical(result$terminal_stage, "association")
  expect_identical(result$terminal_status, "near_boundary")
})

test_that("F4 restores the fixed outer seed stream", {
  set.seed(19); old_kind <- RNGkind(); old_seed <- .Random.seed
  first <- f4_with_rng(runif(3), seed = 2026172001L)
  second <- f4_with_rng(runif(3), seed = 2026172001L)
  expect_identical(first, second)
  expect_identical(RNGkind(), old_kind); expect_identical(.Random.seed, old_seed)
})

test_that("F4 assigns a private eta-delta failure to the delta stage", {
  row <- f4_status_template(f4_seed_manifest()[1L, ], f4_test_sha)
  row$bernoulli_margin_status <- "ok"; row$nb2_mean_status <- "ok"
  row$nb2_dispersion_status <- "ok"
  association <- list(status = "interior", rectangle_ok = TRUE, alpha = 0.22)
  sandwich <- list(status = "unavailable", reason = "eta_delta_unstable")
  result <- f4_apply_alpha_extract(row, association, sandwich)
  expect_true(result$point_available)
  expect_identical(result$terminal_stage, "delta")
  expect_identical(result$terminal_status, "eta_delta_unstable")
})

test_that("F4 uses private alpha Godambe uncertainty, never conditional curvature", {
  association <- list(status = "interior", rectangle_ok = TRUE, alpha = 0.22,
    opt = list(hessian = matrix(400, 1L, 1L)), eta = 0.999999 * tanh(0.22))
  sandwich <- list(status = "ok", alpha_covariance = matrix(0.09, 1L, 1L), alpha_se = c("association:(Intercept)" = 0.3), eta_se = 0.21)
  result <- f4_alpha_extract(association, sandwich)
  expect_true(result$point_available); expect_true(result$alpha_godambe_available)
  expect_identical(result$alpha_godambe_se, 0.3)
  expect_false(isTRUE(all.equal(result$alpha_godambe_se, sqrt(1 / association$opt$hessian[[1L]]))))
  expect_true(result$interval_available); expect_true(result$eta_delta_available)
})
