# `||` desugaring (#776). Before this slice, R parsed `(1 + x || g)` as a `||`
# call that `is_random_bar_call()` never matched, so the term reached the
# fixed-effect design matrix and aborted with
# `'length = N' in coercion to 'logical(1)'`.

double_bar_fixture <- function(seed = 2026072101L, g = 20L, m = 10L) {
  set.seed(seed)
  level <- sprintf("g%02d", seq_len(g))
  group <- factor(rep(level, each = m), levels = level)
  n <- length(group)
  x <- stats::rnorm(n)
  x2 <- stats::rnorm(n)
  u0 <- stats::rnorm(g, sd = 0.8)
  u1 <- stats::rnorm(g, sd = 0.4)
  data.frame(
    y = 1 + 0.5 * x +
      u0[as.integer(group)] +
      x * u1[as.integer(group)] +
      stats::rnorm(n, sd = 0.5),
    x = x,
    x2 = x2,
    g = group,
    fslope = factor(rep(c("lo", "hi"), length.out = n))
  )
}

double_bar_rhs <- function(expr, data) {
  desugar_double_bars_in_rhs(expr, data)
}

test_that("`||` desugars to the explicit uncorrelated terms", {
  data <- double_bar_fixture()
  expect_equal(
    double_bar_rhs(quote(x + (1 + x || g)), data),
    quote(x + (1 | g) + (0 + x | g))
  )
})

test_that("`||` keeps the implicit intercept", {
  data <- double_bar_fixture()
  expect_equal(
    double_bar_rhs(quote(x + (x || g)), data),
    quote(x + (1 | g) + (0 + x | g))
  )
})

test_that("`||` without an intercept expands to slope-only terms", {
  data <- double_bar_fixture()
  expect_equal(
    double_bar_rhs(quote(x + (0 + x || g)), data),
    quote(x + (0 + x | g))
  )
})

test_that("`||` expands every numeric slope", {
  data <- double_bar_fixture()
  expect_equal(
    double_bar_rhs(quote(x + (1 + x + x2 || g)), data),
    quote(x + (1 | g) + (0 + x | g) + (0 + x2 | g))
  )
})

test_that("a single-bar formula is left untouched", {
  data <- double_bar_fixture()
  rhs <- quote(x + (1 + x | g))
  expect_identical(double_bar_rhs(rhs, data), rhs)
})

test_that("`||` on a factor slope aborts instead of copying lme4's wart", {
  data <- double_bar_fixture()
  expect_error(
    double_bar_rhs(quote(fslope + (1 + fslope || g)), data),
    "does not uncorrelate categorical random slopes"
  )
})

test_that("`||` rejects a non-symbol slope", {
  data <- double_bar_fixture()
  expect_error(
    double_bar_rhs(quote(x + (1 + log(x) || g)), data),
    "only simple numeric slopes"
  )
})

# This is the behavioural claim: the two spellings are the SAME model, not merely
# both fittable. If desugaring ever drifts, the likelihoods separate.
test_that("`(1 + x || g)` fits identically to `(1 | g) + (0 + x | g)`", {
  skip_on_cran()
  data <- double_bar_fixture()
  explicit <- drmTMB(
    bf(y ~ x + (1 | g) + (0 + x | g)),
    data = data,
    family = gaussian()
  )
  bars <- drmTMB(
    bf(y ~ x + (1 + x || g)),
    data = data,
    family = gaussian()
  )
  expect_equal(
    as.numeric(logLik(bars)),
    as.numeric(logLik(explicit)),
    tolerance = 1e-6
  )
  expect_equal(
    unlist(fixef(bars)),
    unlist(fixef(explicit)),
    tolerance = 1e-6
  )
})

test_that("`||` stays distinct from the correlated block", {
  skip_on_cran()
  data <- double_bar_fixture()
  bars <- drmTMB(
    bf(y ~ x + (1 + x || g)),
    data = data,
    family = gaussian()
  )
  correlated <- drmTMB(
    bf(y ~ x + (1 + x | g)),
    data = data,
    family = gaussian()
  )
  expect_false(
    isTRUE(all.equal(
      as.numeric(logLik(bars)),
      as.numeric(logLik(correlated)),
      tolerance = 1e-8
    ))
  )
})
