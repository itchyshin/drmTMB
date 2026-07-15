source_arc1b_s2r_recovery_runner <- function(env = parent.frame()) {
  runner <- testthat::test_path(
    "..", "..", "tools", "run-arc1b-s2r-relmat-q2-reml-recovery.R"
  )
  testthat::skip_if_not(
    file.exists(runner),
    "Arc 1b-S2R recovery runner requires a source checkout"
  )
  source(runner, local = env)
}

test_that("Arc 1b-S2R recovery runner retains every attempted fit", {
  skip_on_cran()
  source_arc1b_s2r_recovery_runner()
  out_dir <- withr::local_tempdir()
  result <- run_arc1b_s2r_recovery(list(
    n_rep = 1L,
    cores = 1L,
    master_seed = 2026071503L,
    out_dir = out_dir
  ))

  expect_equal(nrow(result$grid), 6L)
  expect_equal(nrow(result$raw), 6L)
  expect_equal(nrow(result$summary), 60L)
  expect_equal(nrow(result$rmse_difference), 3L)
  expect_true(all(result$rmse_difference$parameter %in% c("tau1", "tau2", "rho_K")))
  expect_true(any(result$gates$status == "HOLD"))
  expect_true(all(
    result$gates$status[result$gates$gate %in% c(
      "attempt_rows", "unique_attempt_keys"
    )] == "HOLD"
  ))
  expect_equal(sum(result$raw$fit_success), 6L)
  expect_true(all(result$raw$convergence == 0L))
  expect_true(all(nzchar(result$raw$K_digest)))
  expect_setequal(
    result$summary$parameter,
    c(
      "beta1_intercept", "beta1_x1", "beta2_intercept", "beta2_x2",
      "tau1", "tau2", "rho_K", "sigma1", "sigma2", "rho12"
    )
  )
  expect_true(all(result$summary$attempted == 1L))
  expect_true(all(file.exists(file.path(
    out_dir,
    c(
      "design.tsv", "raw-attempts.tsv", "summary.tsv",
      "rmse-difference.tsv", "gates.tsv", "failure-ledger.tsv",
      "matrix-digests.tsv", "session-info.txt"
    )
  ))))
})

test_that("Arc 1b-S2R promotion gates are fail closed", {
  source_arc1b_s2r_recovery_runner()
  raw <- do.call(rbind, lapply(seq_len(6L), function(cell_number) {
    g <- c(16L, 16L, 32L, 32L, 64L, 64L)[[cell_number]]
    m <- c(3L, 6L, 3L, 6L, 3L, 6L)[[cell_number]]
    data.frame(
      cell_id = sprintf("g%02d_m%02d", g, m),
      cell_number = cell_number,
      g = g,
      m = m,
      replicate = seq_len(400L),
      seed = 2026071503L + cell_number * 100000L + seq_len(400L),
      fit_success = TRUE,
      convergence = 0L,
      pdHess = TRUE,
      structured_boundary = FALSE,
      elapsed = 1,
      truth_tau1 = 0.80,
      truth_tau2 = 0.65,
      truth_rho_K = 0.35,
      estimate_tau1 = 0.80,
      estimate_tau2 = 0.65,
      estimate_rho_K = 0.35
    )
  }))
  summary <- do.call(rbind, lapply(unique(raw$cell_id), function(cell_id) {
    rows <- raw[raw$cell_id == cell_id, , drop = FALSE]
    do.call(rbind, lapply(c("tau1", "tau2", "rho_K"), function(parameter) {
      data.frame(
        cell_id = cell_id,
        g = rows$g[[1L]],
        m = rows$m[[1L]],
        parameter = parameter,
        attempted = 400L,
        usable = 400L,
        convergence_rate = 1,
        pdHess_rate = 1,
        bias = 0
      )
    }))
  }))
  difference <- data.frame(
    parameter = c("tau1", "tau2", "rho_K"),
    delta = 0,
    se_delta = 0.01,
    pass = TRUE
  )
  gates <- arc1b_s2r_gate_summary(raw, summary, difference)
  expect_true(all(gates$pass))
  raw$seed[[2400L]] <- raw$seed[[1L]]
  raw$cell_id[[2400L]] <- raw$cell_id[[1L]]
  raw$replicate[[2400L]] <- raw$replicate[[1L]]
  gates <- arc1b_s2r_gate_summary(raw, summary, difference)
  expect_false(gates$pass[gates$gate == "unique_attempt_keys"])
})

test_that("Arc 1b-S2R recovery CLI freezes seeds and worker cap", {
  source_arc1b_s2r_recovery_runner()
  expect_error(parse_arc1b_s2r_args("--cores=33"), "must be <= 32")
  expect_error(parse_arc1b_s2r_args("--unknown=yes"), "Unknown argument")
  grid <- arc1b_s2r_recovery_grid(2L, 2026071503L)
  expect_equal(grid$seed[[1L]], 2026171504L)
  expect_equal(grid$seed[[nrow(grid)]], 2026671505L)
  expect_equal(length(unique(grid$seed)), 12L)
})
