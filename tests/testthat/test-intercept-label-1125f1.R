test_that("random_effect_label_is_intercept matches literal (Intercept) suffixes", {
  random_effect_label_is_intercept <- utils::getFromNamespace(
    "random_effect_label_is_intercept",
    "drmTMB"
  )

  expect_true(random_effect_label_is_intercept("(1 | g)"))
  expect_true(random_effect_label_is_intercept("(1 | p | g)"))
  expect_true(random_effect_label_is_intercept("(1 + x | g):(Intercept)"))
  expect_false(random_effect_label_is_intercept("(1 + x | g):x"))
  expect_false(random_effect_label_is_intercept("(0 + x | g):x"))
  expect_false(random_effect_label_is_intercept("grp:Intercept"))
})

test_that("check_drm() classifies correlated intercept terms before slope design notes", {
  set.seed(11251125)
  id <- factor(rep(letters[1:6], each = 5))
  x <- stats::rnorm(30)
  dat <- data.frame(
    y = 0.2 * x + stats::rnorm(30, sd = 0.3),
    x = x,
    id = id
  )
  fit <- drmTMB(
    bf(y ~ x + (1 + x | id), sigma ~ 1),
    family = gaussian(),
    data = dat
  )
  labels <- fit$model$random$mu$labels
  expect_true(any(grepl(":\\(Intercept\\)$", labels)))

  chk <- check_drm(fit)
  design <- chk[chk$check == "mu_random_effect_design", ]
  expect_equal(nrow(design), 1L)
  x_label <- labels[grepl(":x$", labels)]
  intercept_label <- labels[grepl(":\\(Intercept\\)$", labels)]
  expect_match(design$value, paste0(x_label, "="), fixed = TRUE)
  expect_no_match(design$value, paste0(intercept_label, "="), fixed = TRUE)
})