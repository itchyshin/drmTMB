# Issue #1717: a stats family object named nbinom2() must not be told that
# nbinom2() is a supported imputation family.

foreign_stats_family <- function(name) {
  structure(
    list(
      family = name,
      link = "log",
      linkfun = function(mu) log(mu),
      linkinv = function(eta) exp(eta),
      variance = function(mu) mu + mu^2,
      dev.resids = function(y, mu, wt) numeric(length(y)),
      aic = function(...) NA_real_,
      mu.eta = function(eta) exp(eta),
      initialize = expression({}),
      validmu = function(mu) TRUE,
      valideta = function(eta) TRUE
    ),
    class = "family"
  )
}

test_that("drmTMB nbinom2() remains a supported imputation family", {
  expect_identical(
    drmTMB:::drm_impute_family_type(nbinom2()),
    "nbinom2"
  )
  model <- impute_model(abundance ~ z, family = nbinom2())
  expect_s3_class(model, "drm_impute_model")
})

test_that("a foreign stats nbinom2 family names drmTMB::nbinom2()", {
  foreign <- foreign_stats_family("nbinom2")
  expect_error(
    impute_model(abundance ~ z, family = foreign),
    regexp = "not a drmTMB family",
    class = "drmTMB_foreign_impute_family"
  )
  expect_error(
    drmTMB:::drm_impute_family_type(foreign),
    regexp = "drmTMB::nbinom2\\(\\)",
    class = "drmTMB_foreign_impute_family"
  )
})

test_that("a foreign stats beta family names beta_family()", {
  expect_error(
    drmTMB:::drm_impute_family_type(foreign_stats_family("beta")),
    regexp = "drmTMB::beta_family\\(\\)",
    class = "drmTMB_foreign_impute_family"
  )
})
