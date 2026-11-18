# Batch 31 (group nb) companion: native Binomial single-field structured SD
# regression, animal intercept (A, Ainv), animal numeric slope (A, Ainv) and
# relmat intercept (K), across logit / probit / cloglog.
# Each fit is compared with a base-R dense Laplace marginal at the fitted
# parameters (1e-4 on logLik) using a Henderson tabular A from an inbred
# pedigree (diag(A) up to 1.67) or a hand relmat kernel with a non-constant
# diagonal. Emulated bugs (reversed per-level SD, K read by position, K x 2,
# cov2cor(K), dropped slope design) must each move the oracle by more than 0.1.
# Scope: likelihood assembly and alignment at one seed per route; no
# calibration, coverage or parity claim.

test_that("Binomial animal intercept (A, Ainv): dense Laplace oracle and sensitivity", {
  skip_on_cran()
  for (link in b31nb_links) {
    fx <- b31nb_single_fixture("animal", "intercept", link, 31100L + match(link, b31nb_links))
    refs <- vapply(c("A", "Ainv"), function(p) {
      b31nb_check_single(fx, p, paste("animal intercept", link, p))$ref
    }, numeric(1L))
    expect_lt(abs(diff(refs)), 1e-6)
  }
})

test_that("Binomial animal numeric slope (A, Ainv): dense Laplace oracle and sensitivity", {
  skip_on_cran()
  for (link in b31nb_links) {
    fx <- b31nb_single_fixture("animal", "slope", link, 31250L + match(link, b31nb_links))
    refs <- vapply(c("A", "Ainv"), function(p) {
      b31nb_check_single(fx, p, paste("animal slope", link, p))$ref
    }, numeric(1L))
    expect_lt(abs(diff(refs)), 1e-6)
  }
})

test_that("Binomial relmat intercept (K): dense Laplace oracle and sensitivity", {
  skip_on_cran()
  for (link in b31nb_links) {
    fx <- b31nb_single_fixture("relmat", "intercept", link, 31300L + match(link, b31nb_links))
    b31nb_check_single(fx, "K", paste("relmat intercept", link, "K"))
  }
})
