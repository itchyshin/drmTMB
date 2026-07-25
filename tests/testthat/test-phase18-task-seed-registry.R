# The retired Actions matrix pinned each campaign cell as task + seed +
# include_in_all, and those bindings were checked executably. Commit e159959b
# removed the matrix under D-50, after which the seeds survived only as prose in
# docs/dev-log/. inst/sim/registry/phase18_actions_task_seeds.csv restores them
# as data, recovered verbatim from
# `git show e159959b^:.github/workflows/phase18-simulation-grid.yaml`.
#
# SCOPE, stated so this file is not mistaken for more than it is: this records
# what the seeds WERE and keeps them in step with the runner's task list. It does
# NOT make any campaign USE them -- sim_run_actions_cell.R still takes
# --master-seed from its caller. Closing that second gap means having the runner
# read this registry, which is a behaviour change and is deliberately not made
# here.

phase18_seed_registry <- function() {
  path <- testthat::test_path(
    "..",
    "..",
    "inst",
    "sim",
    "registry",
    "phase18_actions_task_seeds.csv"
  )
  testthat::skip_if_not(file.exists(path))
  utils::read.csv(path, stringsAsFactors = FALSE)
}

phase18_runner_tasks <- function() {
  script <- testthat::test_path(
    "..",
    "..",
    "inst",
    "sim",
    "run",
    "sim_run_actions_cell.R"
  )
  testthat::skip_if_not(file.exists(script))
  env <- new.env(parent = globalenv())
  source(script, local = env)
  env$phase18_actions_task_choices()
}

test_that("the seed registry covers exactly the runner's task list", {
  reg <- phase18_seed_registry()
  tasks <- phase18_runner_tasks()

  # Both directions. A task added to the runner without a seed is as much a
  # reproducibility hole as a registry row for a task that no longer exists.
  expect_setequal(reg$task, tasks)
  expect_equal(anyDuplicated(reg$task), 0L)
})

test_that("registry seeds are well formed", {
  reg <- phase18_seed_registry()

  expect_true(all(grepl("^2026[0-9]{4}$", as.character(reg$seed))))
  expect_true(all(reg$include_in_all %in% c("true", "false")))
  expect_true(all(nzchar(reg$provenance)))
})

# Two seeds were shared by two cells each in the original matrix. That is
# recorded rather than silently repaired: whether it was intentional pairing or
# an oversight is a maintainer question, and quietly renumbering a seed would
# destroy the historical binding this registry exists to preserve. Pinning the
# KNOWN collisions means any NEW collision fails this test.
test_that("no seed collision beyond the two inherited from the matrix", {
  reg <- phase18_seed_registry()

  collisions <- lapply(
    split(reg$task, reg$seed)[table(reg$seed) > 1L],
    sort
  )
  expect_equal(
    collisions,
    list(
      `20260629` = c(
        "biv_gaussian_mu_sigma_slope",
        "biv_gaussian_q4_location_recovery"
      ),
      `20260630` = c(
        "biv_gaussian_mu_sigma_slope_recovery",
        "biv_gaussian_q6_location_recovery"
      )
    )
  )
})

test_that("the two aggregate tasks are the only include_in_all rows", {
  reg <- phase18_seed_registry()

  expect_setequal(
    reg$task[reg$include_in_all == "true"],
    c("first_wave_summary", "interval_heavy_summary")
  )
})
