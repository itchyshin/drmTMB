test_that("location-only bridge payload TSV preserves the schema tuple", {
  required <- c(
    "target",
    "estimator",
    "requested_estimator",
    "effective_estimator",
    "r_bridge_status",
    "claim_status",
    "boundary_status_levels"
  )
  payload <- data.frame(
    target = "gaussian_loconly_phylo_reml",
    estimator = "supplied_variance_reml",
    requested_estimator = "REML",
    effective_estimator = "supplied_variance_reml",
    r_bridge_status = "planned",
    claim_status = "internal_diagnostic",
    boundary_status_levels = "interior;near_zero_variance;boundary",
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  missing_fields <- function(x) setdiff(required, names(x))
  path <- withr::local_tempfile(fileext = ".tsv")

  utils::write.table(
    payload,
    path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = ""
  )
  read_back <- utils::read.delim(
    path,
    sep = "\t",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  expect_named(read_back, required)
  expect_equal(read_back[required], payload[required], ignore_attr = TRUE)
  expect_equal(missing_fields(read_back), character())
  expect_equal(
    missing_fields(payload[setdiff(names(payload), "effective_estimator")]),
    "effective_estimator"
  )
})
