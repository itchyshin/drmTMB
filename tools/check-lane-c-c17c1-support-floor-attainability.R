#!/usr/bin/env Rscript

# Exact attainability check for the frozen C17-C1 support-count warning.
zoi <- stats::plogis(-0.40)
group_pass_given_b <- function(b) {
  coi <- stats::plogis(0.10 + b)
  vapply(coi, function(p) {
    boundary_n <- 4:40
    sum(
      stats::dbinom(boundary_n, 50, zoi) *
        (stats::pbinom(boundary_n - 2, boundary_n, p) -
           stats::pbinom(1, boundary_n, p))
    )
  }, numeric(1))
}

p_group <- stats::integrate(
  function(b) group_pass_given_b(b) * stats::dnorm(b, 0, 0.45),
  -Inf, Inf, rel.tol = 1e-12, subdivisions = 1000
)$value
result <- c(
  per_group = p_group,
  all_64 = p_group^64,
  all_four_attempts = p_group^(64 * 4)
)
expected <- c(
  per_group = 0.9961244898,
  all_64 = 0.7799585313,
  all_four_attempts = 0.3700718500
)
stopifnot(isTRUE(all.equal(result, expected, tolerance = 1e-9)))
print(result, digits = 10)
