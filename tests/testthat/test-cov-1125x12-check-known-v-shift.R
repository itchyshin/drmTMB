test_that("check_known_v passes for diagonal vector meta_V", {
  object <- list(
    model = list(
      has_known_v = TRUE,
      V_known_type = "vector",
      V_known = c(0.5, 1, 2)
    )
  )
  row <- drmTMB:::check_known_v(object)
  expect_equal(row$check, "known_sampling_covariance")
  expect_equal(row$status, "ok")
  expect_match(row$value, "type=vector")
  expect_match(row$message, "meta_V")

  bad <- modifyList(object, list(model = modifyList(
    object$model,
    list(V_known = c(1, -0.1))
  )))
  bad_row <- drmTMB:::check_known_v(bad)
  expect_equal(bad_row$status, "error")
})

test_that("check_known_v warns on singular dense meta_V matrices", {
  V <- matrix(c(1, 1, 1, 1), 2, 2)
  object <- list(
    model = list(
      has_known_v = TRUE,
      V_known_type = "matrix",
      V_known = V
    )
  )
  row <- drmTMB:::check_known_v(object)
  expect_equal(row$status, "warning")
  expect_match(row$message, "ill-conditioned")
  expect_match(row$value, "storage=dense")
})

test_that("check_known_v returns NULL when V is not recorded", {
  expect_null(drmTMB:::check_known_v(list(model = list(has_known_v = FALSE))))
})

test_that("phylo_shared_shift_statistic handles valid and invalid inputs", {
  Q <- Matrix::Matrix(c(2, -1, -1, 2), 2, 2, sparse = TRUE)
  stat <- drmTMB:::phylo_shared_shift_statistic(Q, c(1, -1))
  expect_type(stat$shift, "double")
  expect_type(stat$z, "double")
  q1 <- sum(Matrix::rowSums(Q))
  one_qu <- sum(Matrix::rowSums(Q) * c(1, -1))
  expect_equal(stat$prior_cost, one_qu^2 / (2 * q1))

  expect_null(drmTMB:::phylo_shared_shift_statistic(Q, c(1)))
  expect_null(drmTMB:::phylo_shared_shift_statistic(Q, c(NA, 1)))
  zero <- Matrix::Matrix(0, 2, 2, sparse = TRUE)
  expect_null(drmTMB:::phylo_shared_shift_statistic(zero, c(0, 0)))
})

test_that("check_fixed_effect_design_size notes wide dense designs", {
  X <- matrix(0, nrow = 4, ncol = 40)
  X[, c(1, 10, 20)] <- 1
  object <- list(model = list(X = list(mu = X)))
  row <- drmTMB:::check_fixed_effect_design_size(object)
  expect_equal(row$check, "fixed_effect_design_size")
  expect_match(row$value, "max_cols=40")
  expect_true(row$status %in% c("note", "ok"))
})

test_that("tiny Gaussian fit exposes dropped-row diagnostics", {
  set.seed(112512)
  dat <- data.frame(
    y = rnorm(12),
    g = factor(rep(c("keep", "drop"), each = 6))
  )
  dat <- dat[dat$g == "keep" | seq_len(nrow(dat)) <= 9, ]
  dat$g <- droplevels(dat$g)
  fit <- drmTMB(
    drm_formula(y ~ 1 + (1 | g)),
    data = dat,
    family = gaussian(),
    control = drm_control(optimizer = list(iter.max = 30, eval.max = 60))
  )
  chk <- check_drm(fit)
  expect_s3_class(chk, "data.frame")
  expect_true("dropped_rows" %in% chk$check)
  design <- chk[chk$check == "fixed_effect_design_size", ]
  if (nrow(design) > 0L) {
    expect_match(design$status, "ok|note")
  }
  expect_true(is.logical(attr(chk, "ok")))
})