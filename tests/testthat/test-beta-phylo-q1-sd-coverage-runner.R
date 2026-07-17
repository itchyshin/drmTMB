runner_path <- testthat::test_path(
  "..",
  "..",
  "tools",
  "run-beta-phylo-q1-sd-coverage.R"
)

interior_runner_path <- testthat::test_path(
  "..",
  "..",
  "tools",
  "run-beta-phylo-q1-sd-interior-recovery.R"
)

testthat::skip_if_not(
  file.exists(runner_path) && file.exists(interior_runner_path),
  "requires the development-only coverage and interior-DGP runners"
)
runner_env <- new.env(parent = globalenv())
old_option <- getOption("drmTMB.coverage.runner_path")
old_interior_option <- getOption("drmTMB.successor.runner_path")
options(drmTMB.coverage.runner_path = runner_path)
options(drmTMB.successor.runner_path = interior_runner_path)
on.exit(
  {
    options(drmTMB.coverage.runner_path = old_option)
    options(drmTMB.successor.runner_path = old_interior_option)
  },
  add = TRUE
)
sys.source(runner_path, envir = runner_env)

# ---- Coverage-scoring helpers (no live fit) ----

test_that("pr2c_covered flags coverage and leaves non-finite intervals NA", {
  lower <- c(-2, 0.1, NA, -Inf)
  upper <- c(2, 0.2, 5, Inf)
  truth <- 0
  expect_equal(
    runner_env$pr2c_covered(lower, upper, truth),
    c(TRUE, FALSE, NA, NA)
  )
})

test_that("pr2c_miss_direction reports below/above/covered and NA for non-finite", {
  lower <- c(-2, 0.1, -0.3, NA)
  upper <- c(2, 0.3, -0.1, 5)
  truth <- 0
  expect_equal(
    runner_env$pr2c_miss_direction(lower, upper, truth),
    c("covered", "below", "above", NA_character_)
  )
})

test_that("pr2c_mcse matches the binomial-proportion formula and guards N = 0", {
  expect_equal(runner_env$pr2c_mcse(19, 20), sqrt(0.95 * 0.05 / 20))
  expect_true(is.na(runner_env$pr2c_mcse(0, 0)))
})

test_that("pr2c_exact_ci reproduces stats::binom.test Clopper-Pearson bounds", {
  reference <- stats::binom.test(38, 40, conf.level = 0.95)$conf.int
  observed <- runner_env$pr2c_exact_ci(38, 40)
  expect_equal(unname(observed[["lower"]]), reference[[1L]])
  expect_equal(unname(observed[["upper"]]), reference[[2L]])
  na_ci <- runner_env$pr2c_exact_ci(0, 0)
  expect_true(all(is.na(na_ci)))
})

# ---- Cells: promotion/context roles, exclusion, priority order ----

test_that("pr2c_cells excludes g=1024,m=2 and orders promotion arms first", {
  cells <- runner_env$pr2c_cells()
  expect_equal(nrow(cells), 10L)
  expect_false(any(cells$g == 1024L & cells$m == 2L))
  promotion <- cells[cells$role == "promotion", ]
  expect_equal(sort(promotion$cell_id), c("distinct_g1024_m04", "shared_g1024_m04"))
  expect_equal(nrow(promotion), 2L)
  expect_true(all(cells$role[cells$g %in% c(256L, 512L)] == "context"))
  # Priority order: both promotion rows precede every context row.
  expect_true(all(which(cells$role == "promotion") < min(which(cells$role == "context"))))
})

# ---- Seeds: frozen reuse below N=400, disjoint extension above it ----

test_that("pr2c_seed_grid reuses the frozen certification seeds for N <= 400", {
  cells <- runner_env$pr2c_cells()
  n_by_cell <- stats::setNames(rep(3L, nrow(cells)), cells$cell_id)
  grid <- runner_env$pr2c_seed_grid(cells, n_by_cell)
  expect_equal(nrow(grid), 30L)
  expect_true(all(grid$seed_source == "frozen_certification"))

  frozen <- runner_env$pr2_seed_grid("certification")
  matched <- merge(
    grid[c("cell_id", "replicate", "seed")],
    frozen[c("cell_id", "replicate", "seed")],
    by = c("cell_id", "replicate"),
    suffixes = c("", "_expected")
  )
  expect_equal(nrow(matched), nrow(grid))
  expect_true(all(matched$seed == matched$seed_expected))

  audit <- runner_env$pr2c_seed_audit(grid)
  expect_true(audit$pass)
  expect_true(audit$frozen_matches_certification)
  expect_true(audit$extra_disjoint_from_known)
  expect_true(audit$seeds_unique)
})

test_that("pr2c_seed_grid extends disjointly beyond N = 400", {
  cells <- runner_env$pr2c_cells()
  n_by_cell <- stats::setNames(rep(3L, nrow(cells)), cells$cell_id)
  n_by_cell[[cells$cell_id[[1L]]]] <- 402L
  grid <- runner_env$pr2c_seed_grid(cells, n_by_cell)

  extra <- grid[grid$seed_source == "extra_coverage", , drop = FALSE]
  expect_equal(nrow(extra), 2L)
  expect_equal(sort(extra$replicate), c(401L, 402L))

  known <- c(
    runner_env$pr2_seed_grid("certification")$seed,
    runner_env$pr2_seed_grid("smoke")$seed,
    runner_env$pr2_seed_grid("one_fit")$seed,
    runner_env$stopped_pr2_seed_grid("certification")$seed,
    runner_env$stopped_pr2_seed_grid("smoke")$seed,
    runner_env$stopped_pr2_seed_grid("one_fit")$seed
  )
  expect_length(intersect(extra$seed, known), 0L)

  audit <- runner_env$pr2c_seed_audit(grid)
  expect_true(audit$pass)
})

test_that("pr2c_seed_audit fails on a corrupted frozen seed or a duplicate", {
  cells <- runner_env$pr2c_cells()
  n_by_cell <- stats::setNames(rep(3L, nrow(cells)), cells$cell_id)
  grid <- runner_env$pr2c_seed_grid(cells, n_by_cell)

  corrupted <- grid
  corrupted$seed[[1L]] <- corrupted$seed[[1L]] + 1L
  audit_corrupted <- runner_env$pr2c_seed_audit(corrupted)
  expect_false(audit_corrupted$pass)
  expect_false(audit_corrupted$frozen_matches_certification)

  duplicated <- grid
  duplicated$seed[[2L]] <- duplicated$seed[[1L]]
  audit_duplicated <- runner_env$pr2c_seed_audit(duplicated)
  expect_false(audit_duplicated$pass)
  expect_false(audit_duplicated$seeds_unique)
})

# ---- Widening a confint() result into the wide per-replicate schema ----

test_that("pr2c_widen_confint carries values through with the documented naming", {
  table <- data.frame(
    coefficient = c("alpha_intercept", "alpha_x"),
    lower = c(-1.5, 0.05),
    upper = c(-0.9, 0.45),
    width = c(0.6, 0.4),
    scale = c("link", "link"),
    conf_status = c("wald", "wald"),
    profile_engine = c(NA_character_, NA_character_),
    covered = c(TRUE, TRUE),
    miss_direction = c("covered", "covered"),
    stringsAsFactors = FALSE
  )
  widened <- runner_env$pr2c_widen_confint("wald", list(table = table, error = NA_character_))
  expect_equal(widened[["wald_alpha_intercept_lower"]], -1.5)
  expect_equal(widened[["wald_alpha_intercept_upper"]], -0.9)
  expect_equal(widened[["wald_alpha_x_covered"]], TRUE)
  expect_true(is.na(widened[["wald_error"]]))
})

test_that("pr2c_widen_confint returns all-NA fields when the table is NULL", {
  widened <- runner_env$pr2c_widen_confint(
    "profile",
    list(table = NULL, error = "tmbprofile did not converge")
  )
  expect_true(is.na(widened[["profile_alpha_intercept_lower"]]))
  expect_true(is.na(widened[["profile_alpha_x_covered"]]))
  expect_equal(widened[["profile_error"]], "tmbprofile did not converge")
})

test_that("pr2c_confint_method short-circuits cleanly for a NULL (failed) fit", {
  result <- runner_env$pr2c_confint_method(NULL, "wald")
  expect_null(result$table)
  expect_true(is.na(result$error))
})

test_that("pr2c_attempt_columns has the documented per-method/coefficient fields, no duplicates", {
  columns <- runner_env$pr2c_attempt_columns()
  expect_false(anyDuplicated(columns) > 0L)
  expect_true("wald_alpha_intercept_lower" %in% columns)
  expect_true("wald_alpha_intercept_covered" %in% columns)
  expect_true("profile_alpha_x_conf_status" %in% columns)
  expect_true("profile_alpha_x_profile_engine" %in% columns)
  expect_true("wald_error" %in% columns)
  expect_true("profile_error" %in% columns)
})

# ---- Per-cell aggregation (coverage + tree-structure summaries) ----

synthetic_raw <- function() {
  data.frame(
    cell_id = rep("distinct_g0256_m02", 4L),
    cell_number = rep(1L, 4L),
    role = rep("context", 4L),
    predictor_design = rep("distinct", 4L),
    g = rep(256L, 4L),
    m = rep(2L, 4L),
    wald_alpha_intercept_lower = c(-1.5, -1.4, -1.6, NA),
    wald_alpha_intercept_upper = c(-0.9, -1.0, -0.5, NA),
    wald_alpha_intercept_width = c(0.6, 0.4, 1.1, NA),
    wald_alpha_intercept_covered = c(TRUE, FALSE, TRUE, NA),
    wald_alpha_intercept_miss_direction = c("covered", "above", "covered", NA),
    wald_alpha_x_lower = c(0.05, 0.10, 0.02, 0.15),
    wald_alpha_x_upper = c(0.45, 0.40, 0.60, 0.55),
    wald_alpha_x_width = c(0.40, 0.30, 0.58, 0.40),
    wald_alpha_x_covered = c(TRUE, TRUE, TRUE, TRUE),
    wald_alpha_x_miss_direction = c("covered", "covered", "covered", "covered"),
    profile_alpha_intercept_lower = rep(NA_real_, 4L),
    profile_alpha_intercept_upper = rep(NA_real_, 4L),
    profile_alpha_intercept_width = rep(NA_real_, 4L),
    profile_alpha_intercept_covered = rep(NA, 4L),
    profile_alpha_intercept_miss_direction = rep(NA_character_, 4L),
    profile_alpha_x_lower = rep(NA_real_, 4L),
    profile_alpha_x_upper = rep(NA_real_, 4L),
    profile_alpha_x_width = rep(NA_real_, 4L),
    profile_alpha_x_covered = rep(NA, 4L),
    profile_alpha_x_miss_direction = rep(NA_character_, 4L),
    tree_depth = c(2.1, 2.3, 1.9, 2.0),
    mean_pairwise_distance = c(1.1, 1.3, 0.9, 1.0),
    mean_offdiag_correlation = c(0.2, 0.25, 0.15, 0.18),
    effective_n_proxy = c(150, 140, 160, 155),
    stringsAsFactors = FALSE
  )
}

test_that("pr2c_aggregate_coverage computes hits/N, MCSE, exact CI, and directional misses by hand", {
  raw <- synthetic_raw()
  summary <- runner_env$pr2c_aggregate_coverage(raw)

  wald_intercept <- summary[
    summary$method == "wald" & summary$coefficient == "alpha_intercept",
  ]
  # Row 4 has a non-finite interval (excluded from N). Of the remaining 3
  # (rows 1-3), the fixture's `covered`/`miss_direction` columns say rows 1
  # and 3 cover and row 2 misses above; the aggregator trusts those
  # already-scored columns rather than recomputing coverage from the bounds.
  expect_equal(wald_intercept$attempted, 4L)
  expect_equal(wald_intercept$interval_finite_n, 3L)
  expect_equal(wald_intercept$interval_finite_rate, 0.75)
  expect_equal(wald_intercept$hits, 2L)
  expect_equal(wald_intercept$rate, 2 / 3)
  expect_equal(wald_intercept$mcse, runner_env$pr2c_mcse(2L, 3L))
  reference_ci <- stats::binom.test(2L, 3L)$conf.int
  expect_equal(wald_intercept$exact_ci_lower, reference_ci[[1L]])
  expect_equal(wald_intercept$exact_ci_upper, reference_ci[[2L]])
  expect_equal(wald_intercept$miss_below_n, 0L)
  expect_equal(wald_intercept$miss_above_n, 1L)
  expect_equal(wald_intercept$mean_width, mean(c(0.6, 0.4, 1.1)))

  wald_x <- summary[summary$method == "wald" & summary$coefficient == "alpha_x", ]
  expect_equal(wald_x$attempted, 4L)
  expect_equal(wald_x$interval_finite_n, 4L)
  expect_equal(wald_x$hits, 4L)
  expect_equal(wald_x$rate, 1)

  profile_intercept <- summary[
    summary$method == "profile" & summary$coefficient == "alpha_intercept",
  ]
  expect_equal(profile_intercept$attempted, 4L)
  expect_equal(profile_intercept$interval_finite_n, 0L)
  expect_equal(profile_intercept$interval_finite_rate, 0)
  expect_true(is.na(profile_intercept$rate))
  expect_true(all(is.na(runner_env$pr2c_exact_ci(0L, 0L))))
})

test_that("pr2c_aggregate_tree summarizes the phylogenetic structure columns per cell", {
  raw <- synthetic_raw()
  tree_summary <- runner_env$pr2c_aggregate_tree(raw)
  expect_equal(nrow(tree_summary), 1L)
  expect_equal(tree_summary$n_trees, 4L)
  expect_equal(tree_summary$mean_tree_depth, mean(c(2.1, 2.3, 1.9, 2.0)))
  expect_equal(
    tree_summary$mean_pairwise_distance,
    mean(c(1.1, 1.3, 0.9, 1.0))
  )
  expect_equal(
    tree_summary$mean_effective_n_proxy,
    mean(c(150, 140, 160, 155))
  )
})

# ---- Crash-safe incremental writer and resume-key lookup ----

test_that("pr2c_append_row writes a header once and then appends, and pr2c_done_keys reads it back", {
  path <- tempfile(fileext = ".tsv")
  on.exit(unlink(path), add = TRUE)

  row1 <- data.frame(cell_id = "distinct_g0256_m02", replicate = 1L, seed = 111L, x = 1.5)
  row2 <- data.frame(cell_id = "distinct_g0256_m02", replicate = 2L, seed = 112L, x = NA_real_)
  runner_env$pr2c_append_row(row1, path)
  runner_env$pr2c_append_row(row2, path)

  lines <- readLines(path)
  expect_equal(length(lines), 3L)
  expect_equal(lines[[1L]], "cell_id\treplicate\tseed\tx")
  expect_true(grepl("\tNA$", lines[[3L]]))

  keys <- runner_env$pr2c_done_keys(path)
  expect_equal(keys, c("distinct_g0256_m02 1 111", "distinct_g0256_m02 2 112"))
  expect_false(paste("distinct_g0256_m02", 3L, 999L) %in% keys)
})
