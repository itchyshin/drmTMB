test_that("warn_sd_phylo_legacy_deprecated maps each legacy call", {
  expect_invisible(
    suppressWarnings(drmTMB:::warn_sd_phylo_legacy_deprecated("sd_phylo"))
  )
  expect_invisible(
    suppressWarnings(drmTMB:::warn_sd_phylo_legacy_deprecated("sd_phylo1"))
  )
  expect_invisible(
    suppressWarnings(drmTMB:::warn_sd_phylo_legacy_deprecated("sd_phylo2"))
  )
})

test_that("lifecycle warning is emitted for an unknown legacy name", {
  expect_warning(
    drmTMB:::warn_sd_phylo_legacy_deprecated("sd_phylo2"),
    "deprecated"
  )
})

test_that("print.drm_check reports row status counts", {
  ok <- drmTMB:::check_row("a", "ok", 1, "m1")
  warn <- drmTMB:::check_row("b", "warning", 2, "m2")
  x <- rbind(ok, warn)
  class(x) <- c("drm_check", "data.frame")
  expect_output(print(x), "warning")
  expect_output(print(x), "a")
})