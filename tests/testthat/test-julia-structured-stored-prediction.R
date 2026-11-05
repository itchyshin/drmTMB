# Public stored-row prediction must use the already-exported structured mode.
# These payload tests use hand-built link-scale contributions and no fit.
structured_stored_fixture <- function(model_type = "gaussian", link = "logit") {
  data <- data.frame(y = c(0, 1, 2, 3), x = c(-2, -1, 1, 2),
                     g = factor(c("b", "a", "b", "a")), z = c(1, -1, 1, -1))
  K <- matrix(c(2, 0.3, 0.3, 1.5), 2, dimnames = list(c("b", "a"), c("b", "a")))
  family <- switch(model_type, gaussian = stats::gaussian(),
    poisson = stats::poisson(), nbinom2 = nbinom2(),
    gamma = stats::Gamma(link = "log"), binomial = stats::binomial(link = link))
  if (model_type == "binomial") data$y <- c(0, 1, 0, 1)
  if (model_type == "gamma") data$y <- c(0.5, 1, 2, 3)
  eta <- 0.5 + 0.3 * data$x
  inverse <- switch(model_type, gaussian = identity,
    poisson = exp, nbinom2 = exp, gamma = exp, binomial = family$linkinv)
  population <- inverse(eta)
  structure(list(formula = bf(y ~ x + relmat(1 | g, K = K), sigma ~ 1,
                             sd(g, level = "relmat") ~ z),
    family = family, model = list(model_type = model_type), data = data,
    coefficients = list(mu = c("(Intercept)" = 0.5, x = 0.3),
                        sigma = c("(Intercept)" = -0.2)),
    fitted = population, residuals = data$y - population,
    conditional_structured = list(kind = "structured_eta_re_v1",
      eta_re = c(0.7, -0.4, 0.7, -0.4), modes = list(c(0.7, -0.4))),
    engine = "julia"), class = "drmTMB_julia")
}

structured_stored_cases <- list(c("gaussian", "identity"), c("poisson", "log"),
  c("nbinom2", "log"), c("gamma", "log"), c("binomial", "logit"),
  c("binomial", "probit"), c("binomial", "cloglog"))

for (case in structured_stored_cases) {
  local({
    model_type <- case[[1L]]; link <- case[[2L]]
    test_that(paste(model_type, link, "stored prediction conditions on the structured mode"), {
      fit <- structured_stored_fixture(model_type, link)
      eta <- 0.5 + 0.3 * fit$data$x + c(0.7, -0.4, 0.7, -0.4)
      expect_equal(predict(fit, dpar = "mu", type = "link"), eta, tolerance = 1e-12)
      expect_equal(predict(fit, dpar = "mu"), fitted(fit), tolerance = 1e-12)
      expect_false(isTRUE(all.equal(fitted(fit), fit$fitted)))
      expect_equal(predict(fit, newdata = fit$data, dpar = "mu"),
                   fit$fitted, tolerance = 1e-12)
      restored <- unserialize(serialize(fit, NULL))
      expect_equal(predict(restored, dpar = "mu"), fitted(fit), tolerance = 1e-12)
    })
  })
}

test_that("explicit newdata keeps the established fixed-effect contract", {
  fit <- structured_stored_fixture("poisson")
  expect_equal(predict(fit, newdata = fit$data, dpar = "mu", type = "link"),
               0.5 + 0.3 * fit$data$x, tolerance = 1e-12)
  expect_equal(predict(fit, newdata = fit$data, dpar = "mu"), fit$fitted,
               tolerance = 1e-12)
})

test_that("a malformed or missing structured mode cannot look conditional", {
  fit <- structured_stored_fixture("poisson")
  fit$conditional_structured$eta_re <- c(0.1, 0.2)
  expect_error(predict(fit, dpar = "mu"), "structured.*payload|conditional")
  fit$conditional_structured$eta_re <- c(0.1, NA, 0.3, 0.4)
  expect_error(predict(fit, dpar = "mu"), "structured.*payload|conditional")
  fit$conditional_structured <- NULL
  expect_error(predict(fit, dpar = "mu"), "conditional|payload")
})


test_that("failed fields and incompatible models never grant conditional prediction", {
  fit <- structured_stored_fixture("poisson")
  fit$conditional_structured$kind <- "structured_eta_re_v1_failed"
  expect_error(predict(fit, dpar = "mu"), "conditional|payload")
  fit <- structured_stored_fixture("poisson")
  fit$conditional_structured$eta_re[1] <- Inf
  expect_error(predict(fit, dpar = "mu"), "structured.*payload|conditional")
  fit <- structured_stored_fixture("poisson")
  fit$data <- fit$data[-1, ]
  expect_error(predict(fit, dpar = "mu"), "stored prediction rows")
  fit <- structured_stored_fixture("poisson")
  fit$model$model_type <- "beta"
  expect_error(predict(fit, dpar = "mu"), "structured.*payload|conditional")
})

test_that("conditional fitted values survive rounded or overflowing population means", {
  for (case in list(c("binomial", "logit", "40"),
                    c("binomial", "probit", "40"),
                    c("binomial", "cloglog", "5"),
                    c("poisson", "log", "800"),
                    c("gamma", "log", "800"))) {
    fit <- structured_stored_fixture(case[1], case[2])
    eta0 <- as.numeric(case[3])
    fit$coefficients$mu <- c("(Intercept)" = eta0, x = 0)
    inverse <- if (case[1] == "binomial") fit$family$linkinv else exp
    fit$fitted <- rep(inverse(eta0), nrow(fit$data))
    fit$conditional_structured$eta_re <- rep(-eta0, nrow(fit$data))
    expected <- rep(inverse(0), nrow(fit$data))
    expect_equal(predict(fit, dpar = "mu"), expected, tolerance = 1e-12)
    expect_equal(fitted(fit), expected, tolerance = 1e-12)
  }
})

test_that("structured response residuals retain y through population cancellation", {
  cases <- list(c("binomial", "logit", "40"),
                c("binomial", "probit", "40"),
                c("binomial", "cloglog", "5"),
                c("poisson", "log", "40"), c("poisson", "log", "800"),
                c("gamma", "log", "40"), c("gamma", "log", "800"),
                c("nbinom2", "log", "40"), c("nbinom2", "log", "800"))
  for (case in cases) {
    fit <- structured_stored_fixture(case[1], case[2])
    fit$data$y <- if (case[1] == "binomial") c(0, 1, 0, 1) else c(1, 2, 4, 8)
    eta0 <- as.numeric(case[3])
    inverse <- if (case[1] == "binomial") fit$family$linkinv else exp
    fit$coefficients$mu <- c("(Intercept)" = eta0, x = 0)
    fit$fitted <- rep(inverse(eta0), nrow(fit$data))
    fit$residuals <- fit$data$y - fit$fitted
    names(fit$residuals) <- paste0("row", seq_len(nrow(fit$data)))
    fit$conditional_structured$eta_re <- rep(-eta0, nrow(fit$data))
    expected <- fit$data$y - inverse(0)
    names(expected) <- names(fit$residuals)
    expect_equal(residuals(fit), expected, tolerance = 1e-12,
                 info = paste(case, collapse = " "))
  }
})

test_that("structured Binomial count residuals use observed success proportions", {
  fit <- structured_stored_fixture("binomial", "logit")
  K <- matrix(c(2, 0.3, 0.3, 1.5), 2,
              dimnames = list(c("b", "a"), c("b", "a")))
  fit$formula <- bf(cbind(successes, failures) ~ x + relmat(1 | g, K = K),
                    sd(g, level = "relmat") ~ z)
  fit$data$successes <- c(0, 1, 2, 4)
  fit$data$failures <- c(1, 2, 2, 1)
  observed <- fit$data$successes / (fit$data$successes + fit$data$failures)
  fit$coefficients$mu <- c("(Intercept)" = 40, x = 0)
  fit$fitted <- rep(1, nrow(fit$data))
  fit$residuals <- observed - fit$fitted
  fit$conditional_structured$eta_re <- rep(-40, nrow(fit$data))
  expect_equal(residuals(fit), observed - 0.5, tolerance = 1e-12)
})


test_that("older structured objects without a retained response keep residual fallback", {
  fit <- structured_stored_fixture("poisson")
  expected <- fit$residuals + fit$fitted - fitted(fit)
  fit$data$y <- NULL
  expect_equal(residuals(fit), expected, tolerance = 1e-12)
  fit$data <- NULL
  expect_equal(residuals(fit), expected, tolerance = 1e-12)
})
