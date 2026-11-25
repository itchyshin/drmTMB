factor_y_data <- function(ordered = FALSE) {
  set.seed(1)
  n <- 40
  d <- data.frame(x = stats::rnorm(n))
  labels <- sample(c("3", "7", "12"), n, TRUE)
  d$y <- if (ordered) ordered(labels) else factor(labels)
  d
}

biv_factor_y_data <- function(ordered = FALSE) {
  set.seed(1)
  n <- 40
  d <- data.frame(x = stats::rnorm(n))
  labels <- sample(c("3", "7", "12"), n, TRUE)
  d$y1 <- if (ordered) ordered(labels) else factor(labels)
  d$y2 <- stats::rnorm(n)
  d
}

test_that("location-scale builders #1481: reject factor response", {
  d <- factor_y_data()
  for (fam in list(
    list(call = quote(lognormal()), re = "Lognormal", sigma = TRUE),
    list(call = quote(Gamma(link = "log")), re = "Gamma", sigma = TRUE),
    list(call = quote(tweedie()), re = "Tweedie", sigma = TRUE, nu = TRUE),
    list(call = quote(beta_family()), re = "Beta", sigma = TRUE),
    list(call = quote(poisson()), re = "Poisson", sigma = FALSE),
    list(call = quote(nbinom2()), re = "NB2", sigma = TRUE)
  )) {
    form <- if (isTRUE(fam$sigma)) {
      bf(y ~ x, sigma ~ 1)
    } else {
      bf(y ~ x)
    }
    if (isTRUE(fam$nu)) {
      form <- bf(y ~ x, sigma ~ 1, nu ~ 1)
    }
    err <- expect_error(
      drmTMB(form, family = eval(fam$call), data = d),
      "not a factor",
      class = "rlang_error"
    )
    expect_match(conditionMessage(err), fam$re, fixed = TRUE)
    expect_match(conditionMessage(err), "y", fixed = TRUE)
  }
})

test_that("bivariate builders #1481: reject factor response on y1", {
  d <- biv_factor_y_data()
  for (fam in list(
    list(call = quote(biv_gaussian()), re = "bivariate Gaussian"),
    list(call = quote(biv_student()), re = "bivariate Student-t")
  )) {
    err <- expect_error(
      drmTMB(
        bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
        family = eval(fam$call),
        data = d
      ),
      "not a factor",
      class = "rlang_error"
    )
    expect_match(conditionMessage(err), fam$re, fixed = TRUE)
    expect_match(conditionMessage(err), "y1", fixed = TRUE)
  }
})

test_that("more builders #1481: ordered factor is rejected the same way", {
  d <- factor_y_data(ordered = TRUE)
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = lognormal(), data = d),
    "not a factor",
    class = "rlang_error"
  )
})