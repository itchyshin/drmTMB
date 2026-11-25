# Censored responses are not supported (#1455). A reader arriving from survival
# or brms used to get three unrelated failures: an internal model-frame
# mismatch for `Surv()` on gaussian(), `Ops.Surv` for `Surv()` on lognormal(),
# and `could not find function "cens"` for a brms-style marker. One early,
# classed refusal replaces all three.

censored_fixture <- function(n = 24L) {
  data.frame(
    time = seq_len(n) + 0.5,
    event = rep(c(1L, 0L), length.out = n),
    age = seq(30, 60, length.out = n)
  )
}

expect_censoring_refusal <- function(expr) {
  err <- tryCatch(expr, error = function(e) e)
  expect_s3_class(err, "drmTMB_censoring_unsupported")
  msg <- conditionMessage(err)
  expect_match(msg, "Censored responses are not supported")
  expect_match(msg, "survreg", fixed = TRUE)
  expect_match(msg, "brms", fixed = TRUE)
  invisible(err)
}

test_that("a Surv() response is refused with a classed message on gaussian()", {
  d <- censored_fixture()
  expect_censoring_refusal(
    drmTMB(bf(Surv(time, event) ~ age), data = d, family = gaussian())
  )
})

test_that("a Surv() response is refused with a classed message on lognormal()", {
  d <- censored_fixture()
  expect_censoring_refusal(
    drmTMB(bf(Surv(time, event) ~ age), data = d, family = lognormal())
  )
})

test_that("a namespace-qualified survival::Surv() response is refused", {
  d <- censored_fixture()
  expect_censoring_refusal(
    drmTMB(
      bf(survival::Surv(time, event) ~ age),
      data = d,
      family = gaussian()
    )
  )
})

test_that("a brms-style cens() marker is refused, with or without sigma", {
  d <- censored_fixture()
  d$lt <- log(d$time)
  expect_censoring_refusal(
    drmTMB(bf(lt | cens(event == 0) ~ age), data = d, family = gaussian())
  )
  expect_censoring_refusal(
    drmTMB(
      bf(lt | cens(event == 0) ~ age, sigma ~ age),
      data = d,
      family = gaussian()
    )
  )
})

test_that("a cens() marker in a predictor formula is refused too", {
  d <- censored_fixture()
  d$lt <- log(d$time)
  expect_censoring_refusal(
    drmTMB(bf(lt ~ age + cens(event)), data = d, family = gaussian())
  )
})

test_that("an uncensored fit is unaffected", {
  d <- censored_fixture()
  d$lt <- log(d$time)
  fit <- drmTMB(bf(lt ~ age), data = d, family = gaussian())
  expect_s3_class(fit, "drmTMB")
})
