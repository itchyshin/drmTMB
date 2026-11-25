# Print, summary, and predict methods for a frozen-margin association.
# The object is constructed directly so the tests do not fit either margin.

pair_association <- function(
  status = "interior",
  coefficients = c("(Intercept)" = 0.5),
  pair_class = "gaussian_bernoulli"
) {
  design <- matrix(1, nrow = 2L, ncol = length(coefficients))
  colnames(design) <- names(coefficients)
  structure(
    list(
      kernel = list(name = "latent_normal"),
      status = status,
      eta = 0.2,
      eta_internal = c(0.2, 0.2),
      association_coefficients = coefficients,
      association_design = list(matrix = design),
      alpha_inference = list(status = "unavailable"),
      diagnostics = list(near_boundary = FALSE),
      components = list(pair_class = pair_class),
      provenance = list(stage = "test")
    ),
    class = "drm_pair_association"
  )
}

test_that("print and summary describe a constant and a multi-coefficient association", {
  constant <- pair_association()
  constant_text <- paste(
    capture.output(print(constant), type = "message"),
    collapse = "\n"
  )
  expect_match(constant_text, "latent_normal", fixed = TRUE)
  expect_match(constant_text, "eta:", fixed = TRUE)
  expect_match(constant_text, "alpha uncertainty: unavailable", fixed = TRUE)

  varying <- pair_association(coefficients = c("(Intercept)" = 0.2, x = -0.1))
  varying_text <- paste(
    capture.output(print(varying), type = "message"),
    collapse = "\n"
  )
  expect_match(varying_text, "association coefficients: 2", fixed = TRUE)

  available <- constant
  available$alpha_inference$status <- "available"
  available_text <- paste(
    capture.output(print(available), type = "message"),
    collapse = "\n"
  )
  expect_match(available_text, "uncertainty: alpha via vcov()", fixed = TRUE)

  unresolved <- pair_association(status = "boundary_unresolved")
  unresolved_text <- paste(
    capture.output(print(unresolved), type = "message"),
    collapse = "\n"
  )
  expect_false(grepl("eta:", unresolved_text, fixed = TRUE))

  expect_error(
    association(unresolved),
    "boundary-unresolved"
  )
  summary_text <- paste(
    capture.output(print(summary(unresolved)), type = "message"),
    collapse = "\n"
  )
  expect_match(summary_text, "boundary-unresolved", fixed = TRUE)

  coefficient_summary <- summary(varying)
  expect_s3_class(coefficient_summary, "summary.drm_pair_association")
  summary_rows <- paste(
    capture.output(print(coefficient_summary), type = "message"),
    collapse = "\n"
  )
  expect_match(summary_rows, "association coefficients: 2", fixed = TRUE)
})

test_that("association prediction uses the documented eta transform and rejects bad requests", {
  object <- pair_association()
  link <- rep(0.5, 2)
  expect_equal(as.numeric(predict(object, type = "link")), link)
  expect_equal(
    as.numeric(predict(object, type = "eta")),
    0.999999 * tanh(link)
  )

  expect_error(
    predict(object, type = "link", extra = 1),
    "Unused prediction argument"
  )
  expect_error(
    predict(object, type = "link", se.fit = NA),
    "se.fit"
  )
  expect_error(
    predict(object, type = "link", level = 2),
    "level"
  )
  expect_error(
    predict(object, se.fit = TRUE),
    "Choose an association scale"
  )
  expect_error(
    predict(pair_association(status = "boundary_unresolved"), type = "eta"),
    "boundary-unresolved"
  )
  expect_error(
    predict(object, newdata = data.frame(x = 1), type = "eta"),
    "frozen analysis rows"
  )
  mismatched <- pair_association()
  mismatched$association_coefficients <- c(a = 0.1, b = 0.2)
  expect_error(
    predict(mismatched, type = "link"),
    "does not match the fitted coefficients"
  )
})

test_that("simulate refuses an unresolved association and a non-integer nsim", {
  expect_error(
    simulate(pair_association(status = "boundary_unresolved")),
    "boundary-unresolved"
  )
  expect_error(
    simulate(pair_association(), nsim = 0),
    "positive integer"
  )
})
