# Population-level newdata prediction for `engine = "julia"` fits.
#
# A Julia-engine fit stores everything a fixed-effect prediction needs on the R
# side: the parsed formula (`object$formula$entries`), the fixed-effect
# coefficient blocks (`object$coefficients[[dpar]]`, on the link scale), the
# original training `data`, and the `family` (its inverse link). So
# `predict(object, newdata = ...)` builds the mean-model design matrix from
# `newdata` -- reconstructing the model terms from the training data so factor
# contrasts and column ordering match -- and returns `X %*% beta` (`type =
# "link"`) or its inverse-link image (`type = "response"`). NO Julia is touched.
#
# Group-level random effects (phylo / spatial / study) are POPULATION-LEVEL
# (held at zero): the structured marker is stripped from the right-hand side
# before the design is built, so a `newdata` row need not belong to any fitted
# group. These tests construct the fit object by hand -- only the fields
# `predict()` reads -- so they run with no JuliaCall / DRM.jl engine present.

# Hand-build a minimal `drmTMB_julia` object carrying exactly the fields
# `predict.drmTMB_julia()` consumes for a univariate fit.
make_julia_fit <- function(formula, family, data, coef_blocks, fitted) {
  structure(
    list(
      formula = formula,
      family = family,
      data = data,
      coefficients = coef_blocks,
      fitted = fitted,
      engine = "julia"
    ),
    class = "drmTMB_julia"
  )
}

test_that("predict(newdata) on a Poisson phylo Julia fit is finite, right length", {
  set.seed(20260610L)
  n <- 24L
  train <- data.frame(
    y = stats::rpois(n, lambda = 3),
    x = stats::rnorm(n),
    species = paste0("sp", seq_len(n))
  )
  beta <- c("(Intercept)" = 0.8, x = 0.5)
  fit <- make_julia_fit(
    formula = drmTMB::bf(y ~ x + phylo(1 | species, tree = tree)),
    family = stats::poisson(),
    data = train,
    coef_blocks = list(mu = beta),
    fitted = exp(beta[["(Intercept)"]] + beta[["x"]] * train$x)
  )

  nd <- data.frame(
    x = c(-1.5, 0, 1.5),
    # NEW species labels: population-level prediction must not require them to
    # belong to any fitted phylogenetic group.
    species = c("spNEW1", "spNEW2", "spNEW3")
  )

  link <- predict(fit, newdata = nd, type = "link")
  resp <- predict(fit, newdata = nd, type = "response")

  expect_length(link, nrow(nd))
  expect_length(resp, nrow(nd))
  expect_true(all(is.finite(link)))
  expect_true(all(is.finite(resp)))

  # Population level: structured phylo term dropped, RE = 0, so the linear
  # predictor is exactly the fixed-effect design.
  expect_equal(link, unname(beta[["(Intercept)"]] + beta[["x"]] * nd$x))
  # Link and response are consistent through the log inverse link.
  expect_equal(resp, exp(link))
  expect_true(all(resp > 0))
})

test_that("predict(newdata) default dpar and type are mu + response", {
  train <- data.frame(y = stats::rpois(10L, 2), x = stats::rnorm(10L),
                      species = paste0("s", 1:10))
  beta <- c("(Intercept)" = 0.3, x = -0.4)
  fit <- make_julia_fit(
    formula = drmTMB::bf(y ~ x + phylo(1 | species, tree = tree)),
    family = stats::poisson(),
    data = train,
    coef_blocks = list(mu = beta),
    fitted = exp(beta[["(Intercept)"]] + beta[["x"]] * train$x)
  )
  nd <- data.frame(x = c(0, 1), species = c("a", "b"))

  default <- predict(fit, newdata = nd)
  explicit <- predict(fit, newdata = nd, dpar = "mu", type = "response")
  expect_equal(default, explicit)
})

test_that("predict(newdata) inverts the Gaussian identity link", {
  train <- data.frame(y = stats::rnorm(15L), x = stats::rnorm(15L))
  beta <- c("(Intercept)" = 1.2, x = 0.7)
  fit <- make_julia_fit(
    formula = drmTMB::bf(y ~ x, sigma ~ 1),
    family = stats::gaussian(),
    data = train,
    coef_blocks = list(mu = beta, sigma = c("(Intercept)" = -0.5)),
    fitted = beta[["(Intercept)"]] + beta[["x"]] * train$x
  )
  nd <- data.frame(x = c(-2, 0, 2))

  link <- predict(fit, newdata = nd, type = "link")
  resp <- predict(fit, newdata = nd, type = "response")
  # Identity link: response == link, both equal the fixed-effect predictor.
  expect_equal(link, resp)
  expect_equal(resp, unname(beta[["(Intercept)"]] + beta[["x"]] * nd$x))
})

test_that("predict(newdata) honours factor contrasts from the training data", {
  train <- data.frame(
    y = stats::rpois(12L, 2),
    g = factor(rep(c("a", "b", "c"), each = 4L)),
    species = paste0("sp", 1:12)
  )
  # Coefficients keyed exactly as model.matrix names the dummy columns.
  beta <- c("(Intercept)" = 0.5, gb = 0.3, gc = -0.2)
  fit <- make_julia_fit(
    formula = drmTMB::bf(y ~ g + phylo(1 | species, tree = tree)),
    family = stats::poisson(),
    data = train,
    coef_blocks = list(mu = beta),
    fitted = rep(NA_real_, 12L)
  )
  # newdata with only a subset of levels still maps to the trained contrasts.
  nd <- data.frame(g = factor(c("a", "c"), levels = c("a", "b", "c")),
                  species = c("z1", "z2"))

  link <- predict(fit, newdata = nd, type = "link")
  expect_length(link, 2L)
  # a -> intercept; c -> intercept + gc.
  expect_equal(link, unname(c(beta[["(Intercept)"]],
                              beta[["(Intercept)"]] + beta[["gc"]])))
})

test_that("predict(newdata) rejects non-location parameters", {
  train <- data.frame(y = stats::rnorm(8L), x = stats::rnorm(8L))
  fit <- make_julia_fit(
    formula = drmTMB::bf(y ~ x, sigma ~ x),
    family = stats::gaussian(),
    data = train,
    coef_blocks = list(mu = c("(Intercept)" = 0, x = 1),
                      sigma = c("(Intercept)" = 0, x = 0.1)),
    fitted = train$x
  )
  expect_error(
    predict(fit, newdata = data.frame(x = 0), dpar = "sigma"),
    "supports only the location parameter"
  )
})

test_that("predict(newdata) flags a design/coefficient mismatch", {
  train <- data.frame(y = stats::rpois(10L, 2), x = stats::rnorm(10L),
                      species = paste0("s", 1:10))
  fit <- make_julia_fit(
    formula = drmTMB::bf(y ~ x + phylo(1 | species, tree = tree)),
    family = stats::poisson(),
    data = train,
    coef_blocks = list(mu = c("(Intercept)" = 0.8, x = 0.5)),
    fitted = rep(NA_real_, 10L)
  )
  # newdata missing the `x` predictor cannot build the fitted design.
  expect_error(
    predict(fit, newdata = data.frame(z = c(1, 2))),
    "newdata|object 'x' not found",
    class = NULL
  )
})
