runner_path <- testthat::test_path(
  "..",
  "..",
  "tools",
  "run-beta-phylo-q1-sd-interior-recovery.R"
)

expect_true(file.exists(runner_path))
runner_env <- new.env(parent = globalenv())
old_runner_path <- getOption("drmTMB.successor.runner_path")
options(drmTMB.successor.runner_path = runner_path)
on.exit(options(drmTMB.successor.runner_path = old_runner_path), add = TRUE)
sys.source(runner_path, envir = runner_env)

make_successor_fixture <- function() {
  raw <- runner_env$pr2_seed_grid("certification")
  raw$convergence <- 0L
  raw$pdHess <- TRUE
  raw$fixed_hessian_condition <- 10
  raw$warning_count <- 0L
  raw$warnings <- ""
  raw$error <- NA_character_
  raw$initial_boundary_count <- 0L
  raw$total_redraws <- 0L
  raw$max_response_redraws <- 0L
  raw$cap_exhausted <- FALSE
  raw$all_final_responses_strict_interior <- TRUE
  truth <- c(
    beta_mu_intercept = 0,
    beta_mu_x = 0.35,
    beta_sigma_intercept = log(0.25),
    beta_sigma_x = 0.20,
    alpha_intercept = log(0.30),
    alpha_x = 0.25
  )
  for (parameter in names(truth)) {
    raw[[paste0("truth_", parameter)]] <- truth[[parameter]]
    raw[[paste0("estimate_", parameter)]] <- truth[[parameter]]
  }
  raw
}

test_that("successor seeds are disjoint from each other and the stopped lineage", {
  certification <- runner_env$pr2_seed_grid("certification")
  smoke <- runner_env$pr2_seed_grid("smoke")
  one_fit <- runner_env$pr2_seed_grid("one_fit")
  stopped <- runner_env$stopped_pr2_seed_grid("certification")

  expect_equal(nrow(certification), 4800L)
  expect_true(all(table(certification$cell_id) == 400L))
  expect_length(intersect(certification$seed, smoke$seed), 0L)
  expect_length(intersect(certification$seed, one_fit$seed), 0L)
  expect_length(intersect(certification$seed, stopped$seed), 0L)
  expect_equal(certification$seed[[1L]], 2079989999L)
  expect_equal(smoke$seed[[1L]], 2069989999L)
  expect_equal(one_fit$seed[[1L]], 2059989999L)
})

test_that("machine-strict conditional Beta redraws only failed response draws", {
  values <- c(0.2, 0, 0.4, 0.6)
  cursor <- 0L
  draw <- function(n, shape1, shape2) {
    cursor <<- cursor + 1L
    values[[cursor]]
  }
  result <- runner_env$draw_machine_interior_beta(
    mu = c(0.3, 0.4, 0.5),
    phi = c(10, 10, 10),
    draw_one = draw
  )

  expect_equal(result$y, c(0.2, 0.4, 0.6))
  expect_equal(result$initial_boundary_count, 1L)
  expect_equal(result$total_redraws, 1L)
  expect_equal(result$max_response_redraws, 1L)
  expect_false(result$cap_exhausted)
  expect_true(result$all_final_responses_strict_interior)
})

test_that("machine-strict conditional Beta redraws non-finite and upper endpoints", {
  values <- c(NaN, 0.25, 1, 0.75)
  cursor <- 0L
  draw <- function(n, shape1, shape2) {
    cursor <<- cursor + 1L
    values[[cursor]]
  }
  result <- runner_env$draw_machine_interior_beta(
    mu = c(0.3, 0.6),
    phi = c(10, 10),
    draw_one = draw
  )

  expect_equal(result$y, c(0.25, 0.75))
  expect_equal(result$initial_boundary_count, 2L)
  expect_equal(result$total_redraws, 2L)
  expect_true(result$all_final_responses_strict_interior)
})

test_that("cap exhaustion is retained and fails the successor recovery gate", {
  draw_zero <- function(n, shape1, shape2) 0
  result <- runner_env$draw_machine_interior_beta(
    mu = 0.4,
    phi = 10,
    max_redraws = 3L,
    draw_one = draw_zero
  )
  expect_true(result$cap_exhausted)
  expect_false(result$all_final_responses_strict_interior)
  expect_equal(result$total_redraws, 2L)
  expect_equal(result$max_response_redraws, 2L)
  expect_true(is.na(result$y))

  raw <- make_successor_fixture()
  target <- raw$predictor_design == "distinct" & raw$g == 1024L & raw$m == 4L
  raw$cap_exhausted[which(target)[[1L]]] <- TRUE
  raw$all_final_responses_strict_interior[which(target)[[1L]]] <- FALSE
  gates <- runner_env$pr2_recovery_gates(raw, 400L, TRUE)
  expect_equal(gates$decision$status, "HOLD_NO_SUCCESSOR_PROMOTION")
  expect_false(gates$decision$distinct_g1024_m4)
})

test_that("successor DGP is deterministic and carries strict-interior telemetry", {
  first <- runner_env$beta_phylo_sd_regression_dgp(8L, 2L, "shared", 123L)
  second <- runner_env$beta_phylo_sd_regression_dgp(8L, 2L, "shared", 123L)

  expect_equal(first$tree$edge, second$tree$edge)
  expect_equal(first$data, second$data)
  expect_equal(first$telemetry, second$telemetry)
  expect_true(first$telemetry$all_final_responses_strict_interior)
  expect_true(all(first$data$y > 0 & first$data$y < 1))
})

test_that("successor design is frozen at its pinned hash", {
  root <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  path <- runner_env$pr2_design_path(root)
  expect_identical(
    utils::read.delim(path, stringsAsFactors = FALSE),
    runner_env$pr2_seed_grid("certification")
  )
  expect_equal(
    runner_env$pr2_sha256(path),
    runner_env$pr2_frozen_design_sha256()
  )
})
