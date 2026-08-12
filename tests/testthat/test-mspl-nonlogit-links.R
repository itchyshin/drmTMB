# MSPL admits probit and cloglog (2026-08-12).
#
# The evidence basis is
# `docs/dev-log/simulation-artifacts/2026-08-11-mspl-nonlogit-links/`:
# finiteness (0 non-finite in 43,972 completed fits), calibrated standard errors
# in the identified regime, and a softness constant whose logit calibration
# costs ~1% of one standard error for the other two links.
#
# These tests pin the ADMISSION and its boundary. They deliberately do not
# re-measure the campaign -- that lives in the artifacts, and a unit test cannot
# resolve a 1% effect anyway.

mspl_binary_data <- function(seed = 1, G = 8L, n_per = 8L) {
  set.seed(seed)
  block <- factor(rep(seq_len(G), each = n_per))
  n <- length(block)
  trt <- rep(c(0, 1), length.out = n)
  u <- rnorm(G, sd = 0.5)
  data.frame(
    y = rbinom(n, 1, stats::plogis(-0.4 + 0.8 * trt + u[block])),
    trt = trt, block = block
  )
}

test_that("MSPL fits under probit and cloglog, not only logit", {
  d <- mspl_binary_data()
  for (lk in c("logit", "probit", "cloglog")) {
    fit <- drmTMB(
      bf(y ~ trt + (1 | block)),
      family = binomial(link = lk), data = d, estimator = "mspl"
    )
    expect_s3_class(fit, "drmTMB")
    expect_true(is.finite(coef(fit, "mu")[["trt"]]))
    # The fit must report the link it was actually given -- a fit silently
    # penalised as logit while labelled probit is the defect PR #1012 fixed.
    expect_identical(fit$mspl$link, lk)
    expect_true(is.finite(fit$mspl$final_logdet_fixed_information))
  }
})

test_that("the penalty actually differs by link on the same data", {
  # The load-bearing assertion. A test that only checked "probit runs" would
  # pass against a build that penalises every link as logit.
  d <- mspl_binary_data(seed = 4)
  jeffreys <- vapply(c("logit", "probit", "cloglog"), function(lk) {
    fit <- drmTMB(
      bf(y ~ trt + (1 | block)),
      family = binomial(link = lk), data = d, estimator = "mspl"
    )
    fit$mspl$fixed_penalty
  }, numeric(1))
  expect_equal(length(unique(round(jeffreys, 8))), 3L)
})

test_that("a link drmTMB does not implement is still rejected", {
  # Note where this is caught: `cauchit` never reaches the MSPL guard, because
  # drmTMB's binomial family implements exactly logit/probit/cloglog and rejects
  # anything else upstream. So after this change the MSPL link list and the
  # binomial family's link list coincide -- which is why the MSPL guard's own
  # message is currently unreachable for a link reason, and why it still earns
  # its place for the non-binomial and malformed-family cases (next test).
  #
  # Kosmidis & Firth (2021) Table 1 also lists log-log and cauchit as links
  # satisfying the finiteness condition. Neither is admitted here: drmTMB has no
  # `link_code` for them, and no evidence was gathered.
  d <- mspl_binary_data()
  expect_error(
    drmTMB(
      bf(y ~ trt + (1 | block)),
      family = binomial(link = "cauchit"), data = d, estimator = "mspl"
    ),
    "cauchit"
  )
})

test_that("opening the link fence did not open any other fence", {
  d <- mspl_binary_data()
  # REML
  expect_error(
    drmTMB(
      bf(y ~ trt + (1 | block)),
      family = binomial(link = "probit"), data = d, estimator = "mspl", REML = TRUE
    ),
    "REML"
  )
  # non-binomial family
  dg <- d
  dg$y <- rnorm(nrow(dg), 5, 1)
  expect_error(
    drmTMB(
      bf(y ~ trt + (1 | block)),
      family = gaussian(), data = dg, estimator = "mspl"
    ),
    "binomial"
  )
})

test_that("the MSPL intercept starts inside the data's own scale", {
  # Regression for the start-value fix shipped with this admission. At beta = 0
  # cloglog implies an event rate of 1 - exp(-1) = 0.632, so a rare-event design
  # used to begin several log units from its own intercept. The start is now the
  # link of the observed rate; the fitted intercept should land near the value
  # implied by the data rather than near zero.
  set.seed(11)
  G <- 10L; n_per <- 12L
  block <- factor(rep(seq_len(G), each = n_per))
  n <- length(block)
  trt <- rep(c(0, 1), length.out = n)
  y <- rbinom(n, 1, 0.05)                      # rare, but not separated
  d <- data.frame(y = y, trt = trt, block = block)
  fit <- drmTMB(
    bf(y ~ trt + (1 | block)),
    family = binomial(link = "cloglog"), data = d, estimator = "mspl"
  )
  icept <- coef(fit, "mu")[["(Intercept)"]]
  expect_true(is.finite(icept))
  # cloglog link of a ~5% rate is about -3; assert we are in that neighbourhood
  # rather than near the old beta = 0 origin.
  expect_lt(icept, -1)
})

test_that("a clamped start stays finite for an all-zero response", {
  # The half-observation clamp exists for exactly this case: linkfun(0) is
  # -Inf for every link, which would make the start unusable.
  set.seed(12)
  G <- 6L; n_per <- 10L
  block <- factor(rep(seq_len(G), each = n_per))
  n <- length(block)
  d <- data.frame(y = rep(0L, n), trt = rep(c(0, 1), length.out = n), block = block)
  for (lk in c("logit", "probit", "cloglog")) {
    fit <- try(
      drmTMB(
        bf(y ~ trt + (1 | block)),
        family = binomial(link = lk), data = d, estimator = "mspl"
      ),
      silent = TRUE
    )
    # The fit may legitimately fail to converge on a constant response; what it
    # must NOT do is fail because the start was non-finite.
    if (!inherits(fit, "try-error")) {
      expect_true(is.finite(coef(fit, "mu")[["(Intercept)"]]))
    } else {
      expect_false(grepl("non-finite|NA/NaN|infinite", conditionMessage(attr(fit, "condition"))))
    }
  }
})
