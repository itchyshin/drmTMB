# Pin test for make_tmb_data_core() (issue #1329, Dinnage audit Md-L).
#
# make_tmb_data_core() builds the data list handed to the TMB template. It was
# written as 17 hand-maintained copies of one 54-field literal, which is how
# #1048 shipped a silently wrong model. The snapshot in
# fixtures/tmb-data-core-pin.rds was captured from that hand-written
# implementation, before the copies were replaced by one shared defaults list.
# Every field of every case must stay identical (name, type, dimension, value).
#
# TMB resolves data by name, so field ORDER is not compared.
#
# To regenerate after an intentional change to the data contract, run
#   DRMTMB_REGEN_TMB_DATA_PIN=true Rscript -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-tmb-data-pin.R")'
# and review the fixture diff in the PR.

pin_fixture <- function() {
  testthat::test_path("fixtures", "tmb-data-core-pin.rds")
}

test_that("make_tmb_data_core() covers every model_type branch", {
  skip_if_not_installed("ape")
  spec <- tmb_data_pin_cases()
  covered <- unique(vapply(spec$cases, function(x) x$model_type, character(1)))
  expect_setequal(
    covered,
    c(
      "gaussian", "student", "skew_normal", "lognormal", "gamma", "tweedie",
      "beta", "zero_one_beta", "beta_binomial", "binomial",
      "cumulative_logit", "poisson", "zi_poisson", "nbinom2", "zi_nbinom2",
      "truncated_nbinom2", "hurdle_nbinom2", "biv_gaussian",
      "biv_lognormal", "biv_student"
    )
  )
})

test_that("make_tmb_data_core() list is unchanged field by field", {
  skip_if_not_installed("ape")
  spec <- tmb_data_pin_cases()
  current <- lapply(spec$cases, capture_tmb_data_core, data = spec$data)

  if (nzchar(Sys.getenv("DRMTMB_REGEN_TMB_DATA_PIN"))) {
    saveRDS(current, pin_fixture(), version = 2L)
    skip("Regenerated the make_tmb_data_core() pin fixture.")
  }

  pinned <- readRDS(pin_fixture())
  expect_setequal(names(current), names(pinned))
  for (case_name in names(pinned)) {
    got <- current[[case_name]]
    want <- pinned[[case_name]]
    expect_type(got, "list")
    expect_setequal(names(got), names(want))
    for (field in names(want)) {
      expect_identical(
        got[[field]],
        want[[field]],
        info = paste0(case_name, "$", field)
      )
    }
  }
})
