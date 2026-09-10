pkgload::load_all(".", compile = TRUE, quiet = TRUE)

homtoep_panel <- function(occasion = c(0L, 2L, 4L), ids = c("a", "b", "c")) {
  dat <- expand.grid(
    id = ids,
    occasion = occasion,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  dat$y <- seq_len(nrow(dat)) / 10
  dat[sample.int(nrow(dat)), , drop = FALSE]
}

test_that("homtoep parses only as its canonical temporal structure", {
  formula <- drmTMB::bf(
    y ~ temporal(1 | id, time = occasion, structure = "homtoep"),
    sigma ~ 1
  )
  term <- formula$entries[[1L]]$structured[[1L]]
  expect_identical(term$type, "temporal")
  expect_identical(term$structure, "homtoep")
  expect_identical(term$time, "occasion")

  expect_error(
    drmTMB::bf(y ~ temporal(1 | id, time = occasion, structure = "toep"), sigma ~ 1),
    "must be.*homtoep"
  )
})

test_that("homtoep layout stores a common equally spaced schedule and reconstructs row order", {
  dat <- homtoep_panel()
  term <- list(group = "id", time = "occasion", structure = "homtoep")
  layout <- drmTMB:::build_temporal_mu_structure(term, dat)

  expect_identical(layout$occasion_levels, c(0, 2, 4))
  expect_identical(layout$n_occasions, 3L)
  expect_identical(layout$occasion_index[order(layout$observation_node_index)], rep(1:3, 3L))
  expect_identical(layout$observation_node_index[order(layout$observation_node_index)], seq_len(nrow(dat)))
})

test_that("homtoep rejects irregular, incomplete, and oversized retained schedules", {
  term <- list(group = "id", time = "occasion", structure = "homtoep")

  irregular <- homtoep_panel(c(0L, 1L, 3L))
  expect_error(
    drmTMB:::build_temporal_mu_structure(term, irregular),
    "equally spaced.*OU"
  )

  incomplete <- homtoep_panel()
  incomplete <- incomplete[!(incomplete$id == "c" & incomplete$occasion == 4L), , drop = FALSE]
  expect_error(
    drmTMB:::build_temporal_mu_structure(term, incomplete),
    "complete retained schedule"
  )

  oversized <- homtoep_panel(0:12)
  expect_error(
    drmTMB:::build_temporal_mu_structure(term, oversized),
    "at most 12"
  )
})

test_that("homtoep validates raw keys before omission and cannot fall through to OU", {
  term <- list(group = "id", time = "occasion", structure = "homtoep")
  duplicate <- homtoep_panel()
  a_rows <- which(duplicate$id == "a")
  duplicate$occasion[a_rows[[2L]]] <- duplicate$occasion[a_rows[[1L]]]
  expect_error(
    drmTMB:::validate_temporal_raw_data(term, duplicate),
    "keys must be unique before response omission"
  )

  expect_error(
    drmTMB::drmTMB(
      drmTMB::bf(y ~ temporal(1 | id, time = occasion, structure = "homtoep"), sigma ~ 1),
      data = homtoep_panel(), family = gaussian(), REML = FALSE
    ),
    "native covariance provider is not yet enabled"
  )
})

test_that("homtoep gate runner fails closed for pending gates", {
  status <- system2(
    file.path(R.home("bin"), "Rscript"),
    c("--vanilla", "tools/temporal-homtoep-gates.R", "T3-7"),
    stdout = FALSE,
    stderr = FALSE
  )
  expect_false(identical(status, 0L))
})
