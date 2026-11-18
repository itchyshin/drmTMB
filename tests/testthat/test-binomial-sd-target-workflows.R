test_that("selected SD identities survive storage, profiles and bootstrap refits", {
  dat <- binomial_sd_fixture(groups = 120L, repeats = 12L)$data
  key <- 'sd(id, dpar = "mu", coef = "(Intercept)", block = "p")'
  fit <- drmTMB(bf(
    y ~ x + (1 | p | id),
    sd(id, dpar = "mu", coef = "(Intercept)", block = "p") ~ w
  ), binomial(), dat)
  path <- tempfile(fileext = ".rds")
  saveRDS(fit, path)
  stored <- readRDS(path)
  expect_equal(coef(stored, key), coef(fit, key))
  expect_equal(predict(stored, dpar = key), predict(fit, dpar = key))
  expect_identical(stored$model$random_scale$mu$target_identity[[key]],
                   fit$model$random_scale$mu$target_identity[[key]])
  target <- paste0("fixef:", key, ":w")
  targets <- profile_targets(stored)
  selected <- targets[targets$parm == target, , drop = FALSE]
  expect_equal(nrow(selected), 1L)
  expect_equal(selected$tmb_parameter, "beta_sd_mu")
  expect_equal(selected$index, 2L)
  ci <- confint(stored, parm = target, method = "profile", level = 0.8)
  expect_equal(ci$parm, target)
  expect_true(all(is.finite(c(ci$lower, ci$upper))))
  expect_lt(ci$lower, unname(coef(fit, key)[["w"]]))
  expect_gt(ci$upper, unname(coef(fit, key)[["w"]]))
  boot <- suppressMessages(confint(stored, parm = paste0(key, ":w"),
                                    method = "bootstrap", R = 2L,
                                    seed = 2026101718L))
  diagnostics <- attr(boot, "bootstrap.diagnostics", exact = TRUE)
  expect_equal(nrow(diagnostics), 2L)
  expect_true(any(diagnostics$refit_status == "ok"))
})
