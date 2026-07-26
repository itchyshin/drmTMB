contract_path <- testthat::test_path("..", "..", "tools", "b1-breadth-contract.R")

if (!file.exists(contract_path)) {
  test_that("B1 contract is available in a source checkout", {
    skip("Top-level tools are intentionally excluded from the source tarball")
  })
} else {
  source(contract_path)

  test_that("B1 freezes a sixteen-cell breadth panel and its adapter boundary", {
    expect_silent(b1_validate_cells())
    expect_equal(nrow(b1_cells), 16L)
    expect_false("mc-0017" %in% b1_cells$cell_id)
    expect_true(all(c("direct", "fixture_lift", "adapter_build") %in% b1_cells$adapter_status))
    expect_true(all(nzchar(b1_cells$target)))
  })

  test_that("B1 smoke and full manifests are deterministic and seed-disjoint", {
    smoke <- b1_make_smoke_manifest()
    expect_equal(nrow(smoke), 16L)
    expect_true(all(smoke$information_rung == "smoke"))
    full <- b1_make_full_manifest(10L)
    expect_equal(nrow(full), 16L * 3L * 20L)
    expect_equal(b1_full_attempt_count(), 9600L)
    expect_silent(b1_validate_task_manifest(full, 10L))
    expect_equal(full$seed_start[[1L]], b1_seed_base + 1L)
    expect_equal(full$seed_end[[1L]], b1_seed_base + 10L)
    expect_error(b1_make_full_manifest(7L), "must divide")
  })

  test_that("B1 validator rejects duplicate seeds and noncanonical shard widths", {
    full <- b1_make_full_manifest(10L)
    broken <- full
    broken$seed_start[[2L]] <- broken$seed_start[[1L]]
    broken$seed_end[[2L]] <- broken$seed_end[[1L]]
    expect_error(b1_validate_task_manifest(broken, 10L), "non-unique seeds")
    broken <- full
    broken$replicate_end[[1L]] <- broken$replicate_end[[1L]] - 1L
    expect_error(b1_validate_task_manifest(broken, 10L), "canonical shard")
  })
}
