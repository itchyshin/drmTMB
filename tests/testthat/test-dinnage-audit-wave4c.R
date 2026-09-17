test_that("Mi-1: unqualified beta() is base::beta after drmTMB attach", {
  skip_if_not_installed("pkgload")
  withr::local_options(lifecycle_verbosity = "quiet")
  pkgload::load_all(test_path(".."), export_all = FALSE, helpers = FALSE, attach = TRUE)
  expect_equal(beta(2, 3), base::beta(2, 3))
  expect_equal(beta(0.5, 0.5), base::beta(0.5, 0.5))
})

test_that("Mi-1: beta_family() is the exported proportion family constructor", {
  skip_if_not_installed("pkgload")
  pkgload::load_all(test_path(".."), export_all = TRUE, helpers = FALSE, attach = FALSE)
  fam <- drmTMB::beta_family()
  expect_s3_class(fam, "drm_family")
  expect_equal(fam$family, "beta")
})

test_that("Mi-2: exported fixef and ranef work with drmTMB-only attach", {
  skip_if_not_installed("pkgload")
  withr::local_seed(20260917)
  dat <- data.frame(
    y = rnorm(20),
    x = rnorm(20),
    id = factor(rep(1:5, each = 4))
  )
  pkgload::load_all(test_path(".."), export_all = FALSE, helpers = FALSE, attach = TRUE)
  expect_true("fixef" %in% getNamespaceExports("drmTMB"))
  expect_true("ranef" %in% getNamespaceExports("drmTMB"))
  expect_identical(get("fixef", envir = asNamespace("drmTMB")), get("fixef", envir = asNamespace("nlme")))
  expect_identical(get("ranef", envir = asNamespace("drmTMB")), get("ranef", envir = asNamespace("nlme")))
  dfit <- drmTMB(bf(y ~ x + (1 | id), sigma ~ 1), data = dat)
  expect_type(fixef(dfit, "mu"), "double")
  expect_named(ranef(dfit), "mu")
})

test_that("Mi-2: foreign glmmTMB and lmerMod extractors work after drmTMB attach", {
  skip_if_not_installed("glmmTMB")
  skip_if_not_installed("lme4")
  skip_if_not_installed("pkgload")
  withr::local_seed(20260917)
  id <- factor(rep(letters[1:4], each = 5))
  dat <- data.frame(
    y = rnorm(20),
    x = rnorm(20),
    id = id
  )
  library(glmmTMB)
  library(lme4)
  gfit <- glmmTMB::glmmTMB(y ~ x + (1 | id), data = dat)
  lfit <- lme4::lmer(y ~ x + (1 | id), data = dat)
  pkgload::load_all(test_path(".."), export_all = FALSE, helpers = FALSE, attach = TRUE)
  expect_identical(get("ranef", envir = asNamespace("drmTMB")), get("ranef", envir = asNamespace("nlme")))
  expect_identical(get("fixef", envir = asNamespace("drmTMB")), get("fixef", envir = asNamespace("nlme")))
  expect_no_error(ranef(gfit))
  expect_no_error(ranef(lfit))
  expect_no_error(fixef(gfit))
  expect_no_error(fixef(lfit))
})
