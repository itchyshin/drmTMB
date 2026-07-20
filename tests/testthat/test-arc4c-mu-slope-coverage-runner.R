contract_path <- testthat::test_path("..", "..", "tools", "arc4c-mu-slope-coverage-contract.R")
runner_path <- testthat::test_path("..", "..", "tools", "run-arc4c-mu-slope-coverage.R")

if (!all(file.exists(c(contract_path, runner_path)))) {
  test_that("Arc 4c coverage runner contract is available in a source checkout", {
    skip("Top-level tools are intentionally excluded from the source tarball")
  })
} else {
  source(contract_path)
  source(runner_path)

synthetic_arc4c_rows <- function() {
  task <- arc4c_task("mc-0464", 16L, 1L, "full")
  out <- do.call(rbind, lapply(seq_len(nrow(task)), function(i) arc4c_empty_row(task[i, , drop = FALSE])))
  out$fit_status <- c("eligible", "eligible", "fit_error", "pdHess_bad", "eligible", rep("eligible", 5L))
  out$pdHess <- c(TRUE, TRUE, NA, FALSE, TRUE, rep(TRUE, 5L))
  out$profile_lower <- c(0.2, 0.6, NA, NA, NA, rep(0.2, 5L))
  out$profile_upper <- c(0.8, 0.9, NA, NA, NA, rep(0.8, 5L))
  out$profile_conf_status <- c("profile", "profile", NA, NA, "failed", rep("profile", 5L))
  out <- do.call(rbind, lapply(seq_len(nrow(out)), function(i) arc4c_profile_flags(out[i, , drop = FALSE])))
  out
}

test_that("Arc 4c contract fixes cells, DGP constants, seed, and shard mapping", {
  expect_equal(arc4c_cells$n_each, c(12L, 12L, 15L))
  expect_equal(arc4c_dgp_spec$sigma_formula[[1L]], "sigma ~ z")
  expect_equal(arc4c_dgp_spec$phi[2:3], c(1.4, 6.25)); expect_equal(arc4c_dgp_spec$power[[2L]], 1.5)
  expect_equal(arc4c_dgp_spec$boundary_zero[[3L]], 0.075); expect_equal(arc4c_dgp_spec$boundary_one[[3L]], 0.075)
  expect_equal(arc4c_M, c(8L, 16L, 32L, 64L)); expect_equal(arc4c_true_sd, 0.5)
  expect_equal(arc4c_seed(1L), 202607191L); expect_equal(arc4c_shard_replicates(2L), 11:20)
  expect_equal(arc4c_task("mc-0539", 32L, 120L, "full")$replicate, 1191:1200)
  expect_equal(arc4c_task_from_range("mc-0539", "tweedie", 32L, 11L, 20L, "full")$shard, rep(2L, 10L))
  expect_error(arc4c_task_from_range("mc-0539", "skew_normal", 32L, 11L, 20L, "full"), "family")
  expect_error(arc4c_task("mc-0539", 20L, 1L, "full"), "M must")
})

test_that("frozen random-slope DGPs use the exact linear predictors and boundary balance", {
  skew <- arc4c_dgp("mc-0464", 8L, 1L)
  expect_equal(skew$eta, 0.2 + 0.6 * skew$x + skew$slope_re * skew$x)
  expect_equal(skew$sigma, exp(-0.3 + 0.15 * skew$z)); expect_true(all(skew$nu == 1.6))
  tw <- arc4c_dgp("mc-0539", 8L, 1L)
  expect_equal(tw$eta, 0.2 + 0.5 * tw$x + tw$slope_re * tw$x)
  expect_true(all(tw$phi == 1.4)); expect_true(all(tw$power == 1.5))
  zob <- arc4c_dgp("mc-0575", 8L, 1L)
  expect_equal(zob$eta, 0.3 + 0.7 * zob$x + zob$slope_re * zob$x)
  expect_equal(sum(zob$boundary == "zero"), 9L); expect_equal(sum(zob$boundary == "one"), 9L)
  expect_equal(sum(zob$boundary != "beta") / nrow(zob), 0.15); expect_true(all(zob$phi == 6.25))
})

test_that("all attempts define primary coverage while finite profiles define only a diagnostic", {
  raw <- synthetic_arc4c_rows(); s <- arc4c_summarize_cell(raw)
  expect_equal(s$n_attempted, 10L); expect_equal(s$n_profile_finite, 7L); expect_equal(s$n_hits, 6L)
  expect_equal(s$primary_coverage, 0.6); expect_equal(s$conditional_coverage, 6 / 7)
  expect_equal(s$n_profile_finite, s$n_hits + s$n_truth_below + s$n_truth_above)
  expect_equal(s$n_attempted, s$n_fit_error + s$n_nonconverged + s$n_pdHess_bad + s$n_eligible)
  raw$fit_status[[3L]] <- "simulation_error"; s <- arc4c_summarize_cell(raw)
  expect_equal(s$n_simulation_error, 1L)
  expect_equal(s$n_attempted, s$n_simulation_error + s$n_fit_error + s$n_nonconverged + s$n_pdHess_bad + s$n_eligible)
})

test_that("smoke selection and contiguous-suffix gates preserve the frozen policy", {
  raw <- synthetic_arc4c_rows(); smoke <- do.call(rbind, lapply(arc4c_M, function(M) { x <- raw[1, ]; x$M <- M; arc4c_summarize_cell(x) }))
  smoke$n_eligible[smoke$M == 8L] <- 0L
  selected <- arc4c_smoke_selection(smoke)
  expect_true(selected$run_full); expect_false(selected$include_M8)
  smoke$n_profile_in_range[smoke$M == 32L] <- 0L
  expect_false(arc4c_smoke_selection(smoke)$run_full)
  smoke$n_profile_in_range[smoke$M == 32L] <- 1L
  s <- do.call(rbind, lapply(c(16L, 32L, 64L), function(M) data.frame(cell_id="mc-0464", family="skew_normal", M=M, availability=1, primary_ci_low=.93, primary_ci_high=.97)))
  v <- arc4c_family_verdict(s); expect_true(v$promote); expect_equal(v$floor, 16L)
  expect_equal(arc4c_calibration(s[1, ]), "pass_firmly_nominal")
  s$primary_ci_high[s$M == 32L] <- .90
  s$primary_ci_high[s$M == 16L] <- .90
  expect_equal(arc4c_family_verdict(s)$floor, 64L)
  s$primary_ci_high[s$M == 16L] <- .97
  expect_false(arc4c_family_verdict(s)$promote)
  expect_equal(arc4c_family_verdict(s)$reason, "noncontiguous_hole")
})

test_that("fit factories preserve the exact ML formulas without running a fit", {
  factory_text <- vapply(arc4c_cells$cell_id, function(cell) {
    paste(deparse(body(arc4c_fit_factory(cell))), collapse = " ")
  }, character(1L))
  expect_match(factory_text[[1L]], "sigma ~ z")
  expect_match(factory_text[[1L]], "nu ~\\s+1")
  expect_match(factory_text[[2L]], "sigma ~ 1")
  expect_match(factory_text[[2L]], "nu ~\\s+1")
  expect_false(grepl("zoi ~", factory_text[[3L]], fixed = TRUE))
  expect_true(all(grepl("REML = FALSE", factory_text, fixed = TRUE)))
})

test_that("atomic shards resume only when schema, checksum, and task mapping are intact", {
  raw <- synthetic_arc4c_rows(); task <- arc4c_task("mc-0464", 16L, 1L, "full")
  path <- tempfile(fileext = ".tsv"); arc4c_atomic_write_tsv(raw, path)
  expect_silent(arc4c_validate_shard_file(path, task))
  writeLines("corrupt", paste0(path, ".md5")); expect_error(arc4c_validate_shard_file(path, task), "Checksum")
  arc4c_atomic_write_tsv(raw, path); raw$replicate[[1L]] <- 99L; arc4c_atomic_write_tsv(raw, path)
  expect_error(arc4c_validate_shard_file(path, task), "task mapping")
})

test_that("invalid checkpoints are quarantined before deterministic restart", {
  raw <- synthetic_arc4c_rows()
  task <- arc4c_task("mc-0464", 16L, 1L, "full")
  path <- tempfile(fileext = ".tsv")
  arc4c_atomic_write_tsv(raw, path)
  writeLines("bad-checksum", paste0(path, ".md5"))
  resumed <- suppressMessages(arc4c_resume_rows(path, task))
  expect_equal(nrow(resumed), 0L)
  expect_false(file.exists(path))
  expect_false(file.exists(paste0(path, ".md5")))
  quarantined <- Sys.glob(paste0(path, ".quarantine-*"))
  expect_length(quarantined[!endsWith(quarantined, ".md5")], 1L)
  expect_length(Sys.glob(paste0(path, ".quarantine-*.md5")), 1L)
})

test_that("runner CLI rejects seed overrides, duplicates, positionals, and empty outputs", {
  expect_error(arc4c_runner_main("--seed=1"), "Unknown or duplicate")
  expect_error(arc4c_runner_main(c("--mode=dry-run", "--mode=full")), "Unknown or duplicate")
  expect_error(arc4c_runner_main("positional"), "named --key=value")
  expect_error(arc4c_runner_main(c(
    "--mode=dry-run", "--cell-id=mc-0464", "--family=skew_normal",
    "--M=16", "--replicate-start=1", "--replicate-end=1", "--out-dir="
  )), "named --key=value")
  expect_output(arc4c_runner_main("--help"), "Usage:")
})

test_that("full aggregation refuses a partial cell even if its shard is internally valid", {
  raw <- synthetic_arc4c_rows()
  expect_error(arc4c_validate_complete_full_cells(raw), "replicates 1:1200 exactly")
  complete <- raw[rep(seq_len(nrow(raw)), length.out = 1200L), , drop = FALSE]
  complete$replicate <- seq_len(1200L)
  expect_silent(arc4c_validate_complete_full_cells(complete))
})

test_that("execution writes every attempted fit error atomically without loading drmTMB", {
  task <- arc4c_task("mc-0464", 16L, 1L, "full")
  path <- tempfile(fileext = ".tsv")
  fake_dgp <- function(...) data.frame(y = 1)
  fake_fit <- function(...) stop("synthetic fit failure")
  out <- arc4c_execute_task(task, path, fake_fit, dgp_fun = fake_dgp, heartbeat = function(...) NULL)
  expect_equal(nrow(out), 10L); expect_true(all(out$fit_status == "fit_error"))
  expect_true(file.exists(path)); expect_true(file.exists(paste0(path, ".md5")))
  expect_silent(arc4c_validate_shard_file(path, task))
})

summary.arc4c_mock_sdr <- function(object, ...) {
  matrix(rep(c(log(0.5), 0.1), 2L), nrow = 2L, byrow = TRUE,
    dimnames = list(c("log_sd_mu", "log_sd_mu"), c("Estimate", "Std. Error")))
}

test_that("eligible mocked fits use the unique fixed log_sd_mu parameter despite duplicate report rows", {
  assign("summary.arc4c_mock_sdr", summary.arc4c_mock_sdr, envir = .GlobalEnv)
  on.exit(rm("summary.arc4c_mock_sdr", envir = .GlobalEnv), add = TRUE)
  task <- arc4c_task("mc-0464", 16L, 1L, "full")[1, ]
  fake_dgp <- function(...) data.frame(y = 1, x = 0, z = 0, id = factor(1))
  fake_fit <- function(...) list(
    opt = list(convergence = 0L),
    sdr = structure(list(
      pdHess = TRUE,
      par.fixed = c(beta_mu = 0, log_sd_mu = log(0.5)),
      cov.fixed = diag(c(0.01, 0.01))
    ), class = "arc4c_mock_sdr")
  )
  fake_profile <- function(...) data.frame(lower = 0.25, upper = 0.75, conf.status = "profile")
  out <- arc4c_one_attempt(task, fake_fit, fake_profile, fake_dgp)
  expect_equal(out$sd_hat, 0.5); expect_true(out$wald_lower < 0.5); expect_true(out$wald_upper > 0.5)
  expect_true(out$wald_covered); expect_true(out$profile_finite)
})

test_that("raw schema reserves all frozen family diagnostics", {
  expect_true(all(c("nu_hat", "near_zero_slant", "zero_count", "all_zero_cluster_count",
    "interior_count", "one_count", "invalid_interior", "invalid_interior_count") %in% arc4c_raw_schema))
  zob <- arc4c_dgp("mc-0575", 8L, 1L)
  d <- arc4c_family_diagnostics(arc4c_task("mc-0575", 8L, 1L, "full")[1, ], zob)
  expect_equal(d$zero_count, 9L); expect_equal(d$one_count, 9L); expect_equal(d$interior_count, 102L)
  expect_false(d$invalid_interior)
})

test_that("the executable aggregator is manifest-authoritative", {
  dispatch <- new.env(parent = baseenv())
  sys.source(testthat::test_path("..", "..", "tools", "prepare-arc4c-drac-dispatch.R"), envir = dispatch)
  root <- tempfile("arc4c-aggregate-")
  input <- file.path(root, "shards")
  output <- file.path(root, "aggregate")
  dir.create(input, recursive = TRUE)
  manifest <- dispatch$arc4c_make_full_manifest(data.frame(cell_id = "mc-0464", M = c(16L, 32L, 64L)))
  manifest_path <- file.path(root, "manifest.tsv")
  utils::write.table(manifest, manifest_path, sep = "\t", quote = FALSE, row.names = FALSE)
  for (M in c(16L, 32L, 64L)) {
    for (shard in seq_len(120L)) {
      task <- arc4c_task("mc-0464", M, shard, "full")
      raw <- do.call(rbind, lapply(seq_len(nrow(task)), function(i) arc4c_empty_row(task[i, , drop = FALSE])))
      raw$fit_status <- "eligible"; raw$convergence <- 0L; raw$pdHess <- TRUE
      raw$sd_hat <- 0.5; raw$profile_lower <- 0.3; raw$profile_upper <- 0.7
      raw$profile_conf_status <- "profile"
      raw <- do.call(rbind, lapply(seq_len(nrow(raw)), function(i) arc4c_profile_flags(raw[i, , drop = FALSE])))
      path <- file.path(input, sprintf("arc4c-mc-0464-M%02d-shard%03d.tsv", M, shard))
      arc4c_atomic_write_tsv(raw, path)
    }
  }
  summarizer <- testthat::test_path("..", "..", "tools", "summarize-arc4c-mu-slope-coverage.R")
  run <- function(path = manifest_path) {
    system2(Sys.which("Rscript"), c(
      "--no-init-file", shQuote(summarizer), "--mode=full",
      paste0("--manifest=", shQuote(path)), paste0("--input-dir=", shQuote(input)),
      paste0("--output-dir=", shQuote(output))
    ), stdout = TRUE, stderr = TRUE)
  }
  result <- run()
  expect_null(attr(result, "status"))
  aggregated <- arc4c_read_tsv(file.path(output, "arc4c-raw.tsv"))
  expect_equal(nrow(aggregated), 3600L)
  expect_equal(arc4c_read_tsv(file.path(output, "arc4c-family-verdict.tsv"))$deployment_floor, 16L)

  bad_manifest <- manifest
  bad_manifest$logical_task_id[[1L]] <- 999L
  bad_path <- file.path(root, "bad-manifest.tsv")
  utils::write.table(bad_manifest, bad_path, sep = "\t", quote = FALSE, row.names = FALSE)
  bad <- suppressWarnings(run(bad_path))
  expect_gt(attr(bad, "status"), 0L)
  expect_true(any(grepl("logical_task_id mapping mismatch", bad, fixed = TRUE)))

  unlink(file.path(input, "arc4c-mc-0464-M64-shard120.tsv"))
  unlink(file.path(input, "arc4c-mc-0464-M64-shard120.tsv.md5"))
  missing <- suppressWarnings(run())
  expect_gt(attr(missing, "status"), 0L)
  expect_true(any(grepl("Unexpected or missing shard", missing, fixed = TRUE)))
})
}
