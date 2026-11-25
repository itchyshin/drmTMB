# Coverage for R/binomial-q2-sd.R (native labelled q2 admission).

labelled_q2_term <- function(provider = "animal", structure = "A", link = "logit") {
  list(
    type = provider,
    structure = structure,
    covariance_label = "species",
    coef_names = c("(Intercept)", "x"),
    variables = "x",
    group = "id",
    link = link
  )
}

test_that("drm_binomial_labelled_q2_ok() rejects incomplete inputs", {
  ok <- drmTMB:::drm_binomial_labelled_q2_ok
  term <- labelled_q2_term()
  expect_false(ok(NULL, list(1, 2), "logit"))
  term2 <- labelled_q2_term()
  term2$covariance_label <- NULL
  expect_false(ok(term2, list(1, 2), "logit"))
  expect_false(ok(term, list(1), "logit"))
  expect_false(ok(term, list(1, 2, 3), "logit"))
})

test_that("drm_binomial_labelled_q2_ok() accepts animal and logit-phylo labelled q2", {
  ok <- drmTMB:::drm_binomial_labelled_q2_ok
  animal <- labelled_q2_term("animal", "A")
  expect_true(ok(animal, list(1, 2), "logit"))
  expect_true(ok(labelled_q2_term("animal", "Ainv"), list(1, 2), "probit"))
  expect_true(ok(labelled_q2_term("animal", "pedigree"), list(1, 2), "cloglog"))
  phylo <- labelled_q2_term("phylo", link = "logit")
  expect_true(ok(phylo, list(1, 2), "logit"))
})

test_that("drm_binomial_labelled_q2_ok() rejects wrong provider, link, or shape", {
  ok <- drmTMB:::drm_binomial_labelled_q2_ok
  term <- labelled_q2_term("spatial")
  expect_false(ok(term, list(1, 2), "logit"))
  phylo_probit <- labelled_q2_term("phylo", link = "probit")
  expect_false(ok(phylo_probit, list(1, 2), "probit"))
  slope_only <- labelled_q2_term()
  slope_only$coef_names <- "x"
  slope_only$variables <- "x"
  expect_false(ok(slope_only, list(1, 2), "logit"))
  three_coef <- labelled_q2_term()
  three_coef$coef_names <- c("(Intercept)", "x", "z")
  three_coef$variables <- c("x", "z")
  expect_false(ok(three_coef, list(1, 2), "logit"))
})

test_that("drm_binomial_labelled_q2_ok() stays FALSE without labelled intercept slope", {
  ok <- drmTMB:::drm_binomial_labelled_q2_ok
  unlabelled <- labelled_q2_term()
  unlabelled$covariance_label <- NULL
  expect_false(ok(unlabelled, list(1, 2), "logit"))
})