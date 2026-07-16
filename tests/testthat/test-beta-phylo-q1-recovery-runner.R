runner_env <- new.env(parent = globalenv())
sys.source(
  testthat::test_path("..", "..", "tools", "run-beta-phylo-q1-recovery.R"),
  envir = runner_env
)

copy_prior_designs <- function(repo_root) {
  target <- tempfile("beta-phylo-repair-audit-")
  roots <- c(
    "2026-07-16-beta-phylo-q1-pr1-recovery-original-hold",
    "2026-07-16-beta-phylo-q1-pr1-recovery-addendum-hold"
  )
  for (root in roots) {
    dir.create(
      file.path(target, "docs/dev-log/simulation-artifacts", root),
      recursive = TRUE,
      showWarnings = FALSE
    )
    file.copy(
      file.path(
        repo_root,
        "docs/dev-log/simulation-artifacts",
        root,
        "design.tsv"
      ),
      file.path(
        target,
        "docs/dev-log/simulation-artifacts",
        root,
        "design.tsv"
      )
    )
  }
  target
}

test_that("beta phylo repair modes are frozen", {
  smoke <- runner_env$parse_args("--mode=repair_smoke")
  pilot <- runner_env$parse_args("--mode=repair_pilot")
  design <- runner_env$parse_args("--mode=repair_design")
  certification <- runner_env$parse_args("--mode=addendum_repair")

  expect_equal(c(smoke$reps, smoke$m, smoke$seed), c(1L, 4L, 2026071629L))
  expect_equal(c(pilot$reps, pilot$m, pilot$seed), c(10L, 4L, 2026071630L))
  expect_equal(c(design$reps, design$m, design$seed), c(400L, 4L, 2026071631L))
  expect_equal(
    c(certification$reps, certification$m, certification$seed),
    c(400L, 4L, 2026071631L)
  )
  expect_error(
    runner_env$parse_args(c("--mode=addendum_repair", "--seed=1")),
    "frozen"
  )
  expect_error(
    runner_env$parse_args(c("--mode=repair_pilot", "--reps=11")),
    "frozen"
  )
})

test_that("beta phylo repair seeds are deterministic and mutually disjoint", {
  modes <- runner_env$repair_mode_spec()$mode
  grids <- lapply(modes, runner_env$repair_seed_grid)
  names(grids) <- modes

  expect_equal(
    runner_env$repair_seed_grid("addendum_repair"),
    runner_env$repair_seed_grid("repair_design")
  )
  for (mode in modes) {
    expect_equal(length(unique(grids[[mode]]$seed)), nrow(grids[[mode]]))
  }
  pairs <- utils::combn(modes, 2L, simplify = FALSE)
  for (pair in pairs) {
    expect_length(
      intersect(grids[[pair[[1L]]]]$seed, grids[[pair[[2L]]]]$seed),
      0L
    )
  }
})

test_that("beta phylo repair seed generation freezes and restores RNG kind", {
  old_kind <- RNGkind()
  on.exit(do.call(RNGkind, as.list(old_kind)), add = TRUE)
  suppressWarnings(RNGkind(sample.kind = "Rounding"))
  caller_kind <- RNGkind()

  observed <- suppressWarnings(
    runner_env$repair_seed_grid("addendum_repair")
  )

  expect_equal(
    observed,
    suppressWarnings(runner_env$repair_seed_grid("addendum_repair"))
  )
  expect_equal(RNGkind(), caller_kind)
  expect_equal(
    runner_env$repair_rng_kind(),
    c(
      kind = "Mersenne-Twister",
      normal.kind = "Inversion",
      sample.kind = "Rejection"
    )
  )
})

test_that("beta phylo repair DGP freezes and restores RNG kind", {
  old_kind <- RNGkind()
  on.exit(do.call(RNGkind, as.list(old_kind)), add = TRUE)
  reference <- runner_env$with_repair_rng(
    runner_env$beta_phylo_dgp(g = 8L, m = 4L, seed = 2026071629L)
  )

  suppressWarnings(
    RNGkind(
      kind = "L'Ecuyer-CMRG",
      normal.kind = "Box-Muller",
      sample.kind = "Rounding"
    )
  )
  caller_kind <- RNGkind()
  observed <- suppressWarnings(
    runner_env$with_repair_rng(
      runner_env$beta_phylo_dgp(g = 8L, m = 4L, seed = 2026071629L)
    )
  )

  expect_equal(observed$tree$edge, reference$tree$edge)
  expect_equal(observed$tree$edge.length, reference$tree$edge.length)
  expect_equal(observed$data, reference$data)
  expect_equal(observed$truth, reference$truth)
  expect_equal(RNGkind(), caller_kind)
})

test_that("frozen repair design fails closed on absence, hash, or grid drift", {
  repo_root <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  path <- runner_env$frozen_repair_design_path(repo_root)
  grid <- runner_env$repair_seed_grid("addendum_repair")

  expect_invisible(runner_env$assert_frozen_repair_design(grid, path))
  expect_error(
    runner_env$assert_frozen_repair_design(grid, tempfile()),
    "missing"
  )

  altered_file <- tempfile(fileext = ".tsv")
  file.copy(path, altered_file)
  write("tamper", altered_file, append = TRUE)
  expect_error(
    runner_env$assert_frozen_repair_design(grid, altered_file),
    "SHA-256 mismatch"
  )

  altered_grid <- grid
  altered_grid$seed[[1L]] <- altered_grid$seed[[1L]] + 1L
  expect_error(
    runner_env$assert_frozen_repair_design(
      altered_grid,
      path
    ),
    "does not match"
  )
})

test_that("beta phylo repair seed audit rejects any prior overlap", {
  repo_root <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  grid <- runner_env$repair_seed_grid("addendum_repair")
  audit <- runner_env$repair_seed_audit(grid, repo_root, "addendum_repair")

  expect_true(all(audit$pass))
  expect_equal(audit$observed[audit$check == "unique_current_seeds"], 1200L)
  expect_equal(audit$observed[grepl("^overlap_", audit$check)], rep(0L, 4L))

  original <- utils::read.delim(
    file.path(
      repo_root,
      "docs/dev-log/simulation-artifacts",
      "2026-07-16-beta-phylo-q1-pr1-recovery-original-hold",
      "design.tsv"
    )
  )
  bad <- grid
  bad$seed[[1L]] <- original$seed[[1L]]
  expect_error(
    runner_env$repair_seed_audit(bad, repo_root, "addendum_repair"),
    "overlap_original_m2"
  )

  duplicate <- grid
  duplicate$seed[[2L]] <- duplicate$seed[[1L]]
  expect_error(
    runner_env$repair_seed_audit(duplicate, repo_root, "addendum_repair"),
    "unique_current_seeds"
  )

  invalid_m4 <- utils::read.delim(
    file.path(
      repo_root,
      "docs/dev-log/simulation-artifacts",
      "2026-07-16-beta-phylo-q1-pr1-recovery-addendum-hold",
      "design.tsv"
    )
  )
  bad$seed[[1L]] <- invalid_m4$seed[[1L]]
  expect_error(
    runner_env$repair_seed_audit(bad, repo_root, "addendum_repair"),
    "overlap_invalid_m4"
  )

  for (sibling in c("repair_smoke", "repair_pilot")) {
    bad <- grid
    bad$seed[[1L]] <- runner_env$repair_seed_grid(sibling)$seed[[1L]]
    expect_error(
      runner_env$repair_seed_audit(bad, repo_root, "addendum_repair"),
      paste0("overlap_", sibling)
    )
  }
})

test_that("beta phylo repair seed audit rejects missing and malformed priors", {
  repo_root <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  grid <- runner_env$repair_seed_grid("addendum_repair")
  temp_root <- copy_prior_designs(repo_root)
  on.exit(unlink(temp_root, recursive = TRUE), add = TRUE)
  original_path <- file.path(
    temp_root,
    "docs/dev-log/simulation-artifacts",
    "2026-07-16-beta-phylo-q1-pr1-recovery-original-hold",
    "design.tsv"
  )

  file.remove(original_path)
  expect_error(
    runner_env$repair_seed_audit(grid, temp_root, "addendum_repair"),
    "requires both prior design files"
  )
  unlink(temp_root, recursive = TRUE)

  temp_root <- copy_prior_designs(repo_root)
  on.exit(unlink(temp_root, recursive = TRUE), add = TRUE)
  original_path <- file.path(
    temp_root,
    "docs/dev-log/simulation-artifacts",
    "2026-07-16-beta-phylo-q1-pr1-recovery-original-hold",
    "design.tsv"
  )
  malformed <- utils::read.delim(original_path, stringsAsFactors = FALSE)
  malformed$seed[[1L]] <- "not-an-integer"
  utils::write.table(
    malformed,
    original_path,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE
  )
  expect_error(
    runner_env$repair_seed_audit(grid, temp_root, "addendum_repair"),
    "Invalid prior seed design"
  )
})

test_that("repair provenance and output guards fail closed", {
  good <- data.frame(
    check = "source_tree",
    observed = "expected",
    expected = "expected",
    pass = TRUE
  )
  expect_invisible(runner_env$assert_repair_provenance(good))

  bad <- good
  bad$observed <- "drifted"
  bad$pass <- FALSE
  expect_error(
    runner_env$assert_repair_provenance(bad),
    "source_tree"
  )
  expect_error(
    runner_env$assert_repair_provenance(data.frame(nope = TRUE)),
    "malformed_provenance_audit"
  )

  repo_root <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  prior <- file.path(
    repo_root,
    "docs/dev-log/simulation-artifacts",
    "2026-07-16-beta-phylo-q1-pr1-recovery-addendum-hold",
    "gates.tsv"
  )
  tampered <- tempfile(fileext = ".tsv")
  file.copy(prior, tampered)
  write("tamper", tampered, append = TRUE)
  hash_audit <- data.frame(
    check = "sha256_invalid_gates",
    observed = runner_env$sha256_file(tampered),
    expected = runner_env$sha256_file(prior),
    pass = FALSE
  )
  expect_error(
    runner_env$assert_repair_provenance(hash_audit),
    "sha256_invalid_gates"
  )

  out <- tempfile("nonempty-repair-output-")
  dir.create(out)
  writeLines("occupied", file.path(out, "existing.txt"))
  on.exit(unlink(out, recursive = TRUE), add = TRUE)
  expect_error(runner_env$assert_empty_output_dir(out), "Refusing to overwrite")
})

test_that("repair promotion requires repair and pooled m4 gates", {
  gates <- function(pass) data.frame(pass = pass)

  hold <- runner_env$repair_promotion_decision(gates(FALSE), gates(TRUE))
  conflict <- runner_env$repair_promotion_decision(gates(TRUE), gates(FALSE))
  pass <- runner_env$repair_promotion_decision(gates(TRUE), gates(TRUE))

  expect_equal(hold$status, "HOLD")
  expect_false(hold$promotion_authorized)
  expect_equal(conflict$status, "INCONCLUSIVE")
  expect_false(conflict$promotion_authorized)
  expect_equal(pass$status, "PASS")
  expect_true(pass$promotion_authorized)
})
