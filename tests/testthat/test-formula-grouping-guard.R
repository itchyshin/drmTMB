# Locks the simple-grouping rule. drmTMB does not implement nested (`g1/g2`) or
# interaction (`g1:g2`) grouping, and the value of rejecting them is that the
# message names the supported spellings instead of failing somewhere downstream.
#
# The guard is duplicated: `parse_random_sigma_term()` guards the sigma path and
# `parse_random_mu_term()` guards the mu path. Both are covered here, so removing
# either one fails this file.

grouping_guard_fixture <- function(seed = 2026072103L, n = 60L) {
  set.seed(seed)
  data.frame(
    y = stats::rnorm(n),
    x = stats::rnorm(n),
    g1 = factor(rep(letters[1:6], each = n / 6L)),
    g2 = factor(rep(c("a", "b"), length.out = n))
  )
}

test_that("nested grouping is rejected on the mu path", {
  data <- grouping_guard_fixture()
  expect_error(
    drmTMB(bf(y ~ x + (1 | g1 / g2)), data = data, family = gaussian()),
    "grouping terms must be simple variables"
  )
})

test_that("interaction grouping is rejected on the mu path", {
  data <- grouping_guard_fixture()
  expect_error(
    drmTMB(bf(y ~ x + (1 | g1:g2)), data = data, family = gaussian()),
    "grouping terms must be simple variables"
  )
})

test_that("nested grouping is rejected on the sigma path", {
  data <- grouping_guard_fixture()
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ x + (1 | g1 / g2)),
      data = data,
      family = gaussian()
    ),
    "grouping terms must be simple variables"
  )
})

test_that("interaction grouping is rejected on the sigma path", {
  data <- grouping_guard_fixture()
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ x + (1 | g1:g2)),
      data = data,
      family = gaussian()
    ),
    "grouping terms must be simple variables"
  )
})

test_that("the rejection names a supported spelling", {
  data <- grouping_guard_fixture()
  err <- tryCatch(
    drmTMB(bf(y ~ x + (1 | g1 / g2)), data = data, family = gaussian()),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "\\(1 \\| id\\)")
})

# `||` routes through the same rule before desugaring, so a compound group is
# caught there too rather than silently expanding into two bad terms.
test_that("a compound group under `||` is rejected", {
  data <- grouping_guard_fixture()
  expect_error(
    drmTMB(bf(y ~ x + (1 + x || g1 / g2)), data = data, family = gaussian()),
    "grouping terms must be simple variables"
  )
})

test_that("a simple grouping variable still fits", {
  skip_on_cran()
  data <- grouping_guard_fixture()
  expect_no_error(
    drmTMB(bf(y ~ x + (1 | g1)), data = data, family = gaussian())
  )
})
