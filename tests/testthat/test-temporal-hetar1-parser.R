pkgload::load_all(".", compile = FALSE, quiet = TRUE)

test_that("temporal() accepts the canonical heterogeneous AR1 declaration", {
  form <- drm_formula(
    y ~ treatment + temporal(1 | id, time = occasion, structure = "hetar1")
  )
  term <- form$entries[[1L]]$structured[[1L]]
  expect_equal(term$structure, "hetar1")
  expect_equal(term$group, "id")
  expect_equal(term$time, "occasion")
})

test_that("hetar1 layout requires a common complete equally spaced integer schedule", {
  dat <- expand.grid(
    id = c("a", "b", "c"), occasion = c(0L, 1L, 2L),
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  term <- drm_formula(
    y ~ temporal(1 | id, time = occasion, structure = "hetar1")
  )$entries[[1L]]$structured[[1L]]
  layout <- build_temporal_mu_structure(term, dat)
  expect_identical(layout$structure, "hetar1")
  expect_identical(layout$occasion_levels, c(0, 1, 2))
  expect_identical(layout$occasion_index, as.integer(match(dat$occasion, c(0L, 1L, 2L))))
  expect_identical(layout$gap[layout$gap > 0], rep(1L, 6L))
  expect_identical(
    temporal_mu_tmb_data(list(structured = list(temporal_mu = layout)))$temporal_mu_level_index,
    as.integer(layout$occasion_index - 1L)
  )

  incomplete <- dat[-1L, , drop = FALSE]
  expect_error(build_temporal_mu_structure(term, incomplete), "complete retained schedule")
  duplicate <- rbind(dat, dat[1L, , drop = FALSE])
  expect_error(build_temporal_mu_structure(term, duplicate), "keys must be unique")
  even_gap <- dat
  even_gap$occasion <- 2L * even_gap$occasion
  expect_error(build_temporal_mu_structure(term, even_gap), "lag variation")
  fractional <- dat
  fractional$occasion[[1L]] <- 0.5
  expect_error(build_temporal_mu_structure(term, fractional), "finite integers")

  too_many <- expand.grid(
    id = c("a", "b"), occasion = 0:12,
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  expect_error(build_temporal_mu_structure(term, too_many), "at most 12")
})

test_that("hetar1 keeps original integer gaps and rejects aliases", {
  expect_error(
    drm_formula(y ~ temporal(1 | id, time = occasion, structure = "het_ar1")),
    "hetar1"
  )
})
