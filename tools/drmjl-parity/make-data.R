# Regenerate the shared input data for the drmTMB vs DRModels.jl parity
# fixtures (tests/testthat/test-drmjl-parity-fixtures.R).
#
# One CSV per family. Every CSV carries a grouping column `g` (20 groups of
# 10), so the fixed-effect case (`y ~ x`) and the random-intercept case
# (`y ~ x + (1 | g)`) read the same rows. The reference values are then
# produced from these exact files by tools/drmjl-parity/make-reference.jl.
#
# Run from the package root:
#   Rscript tools/drmjl-parity/make-data.R

out_dir <- file.path("tests", "testthat", "fixtures", "drmjl-parity")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

n_group <- 20L
per_group <- 10L
n <- n_group * per_group

make_base <- function(seed) {
  set.seed(seed)
  g <- rep(seq_len(n_group), each = per_group)
  x <- round(stats::rnorm(n), 6)
  b <- stats::rnorm(n_group, sd = 0.5)[g]
  list(g = g, x = x, b = b)
}

write_case <- function(df, family) {
  path <- file.path(out_dir, paste0("data-", family, ".csv"))
  utils::write.csv(df, path, row.names = FALSE)
  invisible(path)
}

# Gaussian: location-scale residual, mu random intercept.
d <- make_base(20261031)
write_case(data.frame(
  y = round(0.3 + 0.5 * d$x + d$b + stats::rnorm(n, sd = exp(-0.2 + 0.2 * d$x)), 8),
  x = d$x, g = d$g
), "gaussian")

d <- make_base(20261032)
write_case(data.frame(
  y = stats::rpois(n, exp(0.4 + 0.4 * d$x + d$b)),
  x = d$x, g = d$g
), "poisson")

d <- make_base(20261033)
write_case(data.frame(
  y = stats::rnbinom(n, size = 3, mu = exp(0.6 + 0.4 * d$x + d$b)),
  x = d$x, g = d$g
), "nbinom2")

# Beta with mean/precision phi = 15 (drmTMB beta_family() sigma is
# 1 / sqrt(1 + phi)); clamp away from the 0/1 boundary.
d <- make_base(20261034)
mu <- stats::plogis(-0.2 + 0.5 * d$x + d$b)
phi <- 15
write_case(data.frame(
  y = round(pmin(pmax(stats::rbeta(n, mu * phi, (1 - mu) * phi), 1e-4), 1 - 1e-4), 8),
  x = d$x, g = d$g
), "beta")

d <- make_base(20261035)
size <- 10L
successes <- stats::rbinom(n, size = size, prob = stats::plogis(-0.3 + 0.6 * d$x + d$b))
write_case(data.frame(
  successes = successes, failures = size - successes,
  x = d$x, g = d$g
), "binomial")

d <- make_base(20261036)
write_case(data.frame(
  y = round(0.2 + 0.4 * d$x + d$b + 0.7 * stats::rt(n, df = 5), 8),
  x = d$x, g = d$g
), "student")

# Gamma(link = "log"): shape 4, mean exp(eta).
d <- make_base(20261037)
mu <- exp(0.3 + 0.3 * d$x + d$b)
write_case(data.frame(
  y = round(stats::rgamma(n, shape = 4, rate = 4 / mu), 8),
  x = d$x, g = d$g
), "gamma")
