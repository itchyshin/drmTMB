test_that("Phase 18 seed tables are reproducible and shaped by cell", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  seeds <- phase18_seed_table(n_cells = 3, n_rep = 4, master_seed = 101)
  seeds_again <- phase18_seed_table(n_cells = 3, n_rep = 4, master_seed = 101)

  expect_equal(seeds, seeds_again)
  expect_equal(nrow(seeds), 12L)
  expect_equal(seeds$cell_index, rep(1:3, each = 4))
  expect_equal(seeds$replicate, rep(1:4, times = 3))
  expect_equal(length(unique(seeds$seed)), 12L)
})

test_that("Phase 18 cell registry joins conditions to replicate seeds", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  conditions <- data.frame(
    n_group = c(12L, 24L),
    sd_group = c(0.2, 0.5)
  )
  registry <- phase18_cell_registry(
    surface = "gaussian_ls",
    conditions = conditions,
    n_rep = 3,
    master_seed = 2026
  )

  expect_equal(registry$cells$cell_id, c("gaussian_ls_001", "gaussian_ls_002"))
  expect_equal(registry$cells$n_group, conditions$n_group)
  expect_equal(nrow(registry$seeds), 6L)
  expect_equal(
    registry$seeds$cell_id,
    rep(registry$cells$cell_id, each = 3)
  )
  expect_equal(registry$n_rep, 3)
  expect_equal(registry$master_seed, 2026)
})

test_that("Phase 18 registry validates malformed inputs", {
  source(
    system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE),
    local = TRUE
  )

  expect_error(phase18_seed_table(0, 2), "positive whole number")
  expect_error(phase18_seed_table(2, 0), "positive whole number")
  expect_error(
    phase18_cell_registry("", data.frame(x = 1), n_rep = 1),
    "surface"
  )
  expect_error(
    phase18_cell_registry("x", data.frame(), n_rep = 1),
    "conditions"
  )
})
