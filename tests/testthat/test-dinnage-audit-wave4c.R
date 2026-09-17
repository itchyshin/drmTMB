test_that("Mi-1: unqualified beta() is base::beta after drmTMB attach", {
  # devtools::test attaches unexported namespace objects via pkgload; the release
  # contract is `library(drmTMB)` on the installed package (test_check() path).
  if (exists("beta", envir = asNamespace("drmTMB"), inherits = FALSE) &&
      identical(
        get("beta", envir = environment()),
        get("beta", envir = asNamespace("drmTMB"), inherits = FALSE)
      )) {
    skip("pkgload dev attach binds unexported beta(); install attach is covered by test_check()")
  }
  withr::local_options(lifecycle_verbosity = "quiet")
  expect_equal(beta(2, 3), base::beta(2, 3))
  expect_equal(beta(0.5, 0.5), base::beta(0.5, 0.5))
})

test_that("Mi-1: beta_family() is the exported proportion family constructor", {
  fam <- drmTMB::beta_family()
  expect_s3_class(fam, "drm_family")
  expect_equal(fam$family, "beta")
})

test_that("Mi-1: unexported drmTMB:::beta() aliases beta_family()", {
  withr::local_options(lifecycle_verbosity = "warning")
  expect_false("beta" %in% getNamespaceExports("drmTMB"))
  expect_warning(
    fam <- drmTMB:::beta(),
    "deprecated",
    fixed = FALSE
  )
  expect_equal(fam, drmTMB::beta_family())
})

test_that("Mi-2: exported fixef and ranef work with drmTMB-only attach", {
  withr::local_seed(20260917)
  dat <- data.frame(
    y = rnorm(20),
    x = rnorm(20),
    id = factor(rep(1:5, each = 4))
  )
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
  expect_identical(get("ranef", envir = asNamespace("drmTMB")), get("ranef", envir = asNamespace("nlme")))
  expect_identical(get("fixef", envir = asNamespace("drmTMB")), get("fixef", envir = asNamespace("nlme")))
  expect_no_error(ranef(gfit))
  expect_no_error(ranef(lfit))
  expect_no_error(fixef(gfit))
  expect_no_error(fixef(lfit))
})
