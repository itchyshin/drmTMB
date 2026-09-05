# Shared data-generating draw for the ordinary-RE census and its parity rows
# (one seed per shape; the parity rows must be about the SAME fits census.R
# classified). Sourced by census.R and parity_ordinary_re.R.

make_data <- function(shape) {
  set.seed(20260904L)
  n_g <- 15L; per <- 10L; n <- n_g * per
  g <- factor(rep(seq_len(n_g), each = per))
  x <- rnorm(n)
  u0 <- rnorm(n_g, sd = 0.6)
  if (identical(shape, "gaussian_random_intercept")) {
    y <- 1 + 0.5 * x + u0[g] + rnorm(n, sd = 0.7)
  } else if (identical(shape, "gaussian_random_slope")) {
    u1 <- 0.3 * u0 + rnorm(n_g, sd = 0.4)
    y <- 1 + 0.5 * x + u0[g] + u1[g] * x + rnorm(n, sd = 0.7)
  } else if (identical(shape, "gaussian_sigma_random_intercept")) {
    v0 <- rnorm(n_g, sd = 0.4)
    y <- 1 + 0.5 * x + rnorm(n, sd = exp(-0.2 + v0[g]))
  } else {
    stop("unknown shape")
  }
  data.frame(y = y, x = x, g = g)
}

