# G13 (Rose, on #1173): a guard against the exact drift A3's TSV backfill
# had to correct after the fact -- a family admitted on the fe (Workflow G)
# route in R/julia-family-registry.R silently missing a
# drm_julia_capability_comparison() row, or vice versa. No Julia required.
#
# The map below is a snapshot, maintained the SAME way
# tests/testthat/test-julia-family-registry.R's hand-maintained vectors are:
# each family leaf appends one entry. `NA` marks a KNOWN, NAMED gap -- a
# family admitted on the fe route with no comparison row yet -- so the gap is
# a verified, positive assertion (PATTERN WARNING, Rose) rather than a silent
# hole a passing test could hide. Remove a name from the gap the moment its
# row lands; do not leave it here past that PR.
drm_julia_fe_family_capability_map <- function() {
  c(
    gaussian = "base_gaussian_location_scale",
    biv_gaussian = "biv_gaussian_residual",
    student = "fe_student",
    lognormal = "fe_lognormal",
    poisson = "fe_poisson",
    nbinom2 = "fe_nbinom2",
    gamma = "fe_gamma",
    beta = "fe_beta",
    binomial = "plain_binomial_nonphylo",
    # A4-INTEGRATION follow-up (2026-09-05): each family's OWN leaf PR
    # (#1173, #1171, #1169) added the registry row; the missing
    # capability_comparison() rows this comment used to name as a gap are
    # now added (fe_truncated_nbinom2, fe_zero_one_beta, fe_tweedie).
    truncated_nbinom2 = "fe_truncated_nbinom2",
    zero_one_beta = "fe_zero_one_beta",
    tweedie = "fe_tweedie"
  )
}

test_that("G13: the fe-family-to-comparison-row map covers exactly the fe registry, nothing more or less", {
  fe <- drmTMB:::drm_julia_registry_families("fe")
  map <- drm_julia_fe_family_capability_map()
  expect_identical(sort(names(map)), sort(fe))
})

test_that("G13: every fe family with a mapped capability_id actually has that row", {
  map <- drm_julia_fe_family_capability_map()
  comparison <- drmTMB:::drm_julia_capability_comparison()
  mapped <- map[!is.na(map)]
  missing <- setdiff(mapped, comparison$capability_id)
  expect_identical(
    missing, character(0L),
    label = "capability_ids named in the map but absent from drm_julia_capability_comparison()"
  )
})

test_that("G13 vice-versa: every family named NA (a known gap) truly has no row yet", {
  map <- drm_julia_fe_family_capability_map()
  comparison <- drmTMB:::drm_julia_capability_comparison()
  gap_families <- names(map)[is.na(map)]
  for (family in gap_families) {
    pattern <- paste0("(^|_)", family, "($|_)")
    expect_false(
      any(grepl(pattern, comparison$capability_id)),
      info = paste0(
        family, " now has a capability_comparison row -- remove it from ",
        "drm_julia_fe_family_capability_map()'s gap list"
      )
    )
  }
})

test_that("RED CONTROL: a comparison row removed from the map's expectation is caught", {
  map <- drm_julia_fe_family_capability_map()
  comparison <- drmTMB:::drm_julia_capability_comparison()
  # Simulate the drift this guard exists to catch: drop fe_student's row
  # entirely, as if a future edit deleted it without updating the registry.
  comparison_without_student <- comparison[comparison$capability_id != "fe_student", ]
  mapped <- map[!is.na(map)]
  missing <- setdiff(mapped, comparison_without_student$capability_id)
  expect_identical(missing, "fe_student")
})
