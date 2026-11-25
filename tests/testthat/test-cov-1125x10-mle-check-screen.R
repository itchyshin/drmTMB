# Coverage shard cursor-cloud-1125x10: check_mle_existence screen on tiny fits.

test_that("check_drm reports mle_existence ok on a simple Gaussian fit", {
  dat <- data.frame(y = rnorm(20), x = rnorm(20))
  fit <- drmTMB(
    bf(y ~ x),
    data = dat,
    family = gaussian(),
    control = drm_control(se = FALSE)
  )
  chk <- check_drm(fit)
  row <- chk[chk$check == "mle_existence", , drop = FALSE]
  expect_s3_class(chk, "data.frame")
  expect_equal(nrow(row), 1L)
  expect_identical(row$status, "ok")
  expect_match(row$message, "finite maximum-likelihood")
  expect_true(attr(chk, "ok"))
})

test_that("check_drm warns on quasi-complete separation", {
  dat <- data.frame(
    y = c(0, 0, 0, 1, 1, 1),
    x = c(-3, -2, -1, 1, 2, 3)
  )
  fit <- drmTMB(
    bf(y ~ x),
    data = dat,
    family = binomial(),
    control = drm_control(se = FALSE)
  )
  chk <- check_drm(fit)
  row <- chk[chk$check == "mle_existence", , drop = FALSE]
  expect_equal(row$status, "warning")
  expect_match(row$value, "binomial_separation")
  expect_match(row$message, "separation")
  expect_false(isTRUE(attr(chk, "ok")))
})

test_that("drm_glm_ray_screen returns a reason for separated binomial fits", {
  dat <- data.frame(
    y = c(0, 0, 0, 1, 1, 1),
    x = c(-3, -2, -1, 1, 2, 3)
  )
  fit <- drmTMB(
    bf(y ~ x),
    data = dat,
    family = binomial(),
    control = drm_control(se = FALSE)
  )
  hit <- drmTMB:::drm_glm_ray_screen(fit)
  expect_type(hit, "list")
  expect_identical(hit$reason, "binomial_separation")
  expect_true(length(hit$flagged) >= 1L)
  expect_true(hit$conclusive)
})

test_that("drm_mle_nonexistent surfaces separation on binomial fixed effects", {
  dat <- data.frame(
    y = c(0, 0, 0, 1, 1, 1),
    x = c(-3, -2, -1, 1, 2, 3)
  )
  fit <- drmTMB(
    bf(y ~ x),
    data = dat,
    family = binomial(),
    control = drm_control(se = FALSE)
  )
  hit <- drmTMB:::drm_mle_nonexistent(fit)
  expect_identical(hit$reason, "binomial_separation")
  expect_true(drmTMB:::drm_mle_nonexistent_is_true(fit))
})

test_that("drm_glm_ray_screen is NULL for mixed binomial outcomes", {
  dat <- data.frame(
    y = c(0, 1, 0, 1, 1, 0),
    x = rnorm(6)
  )
  fit <- drmTMB(
    bf(y ~ x),
    data = dat,
    family = binomial(),
    control = drm_control(se = FALSE)
  )
  expect_null(drmTMB:::drm_glm_ray_screen(fit))
  expect_false(drmTMB:::drm_mle_nonexistent_is_true(fit))
})