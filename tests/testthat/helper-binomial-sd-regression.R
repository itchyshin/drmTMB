# The generator is independent of drmTMB's simulation and fitting kernels.
binomial_sd_fixture <- function(groups = 160L, repeats = 16L,
                                seed = 2026101701L, trials = 1L,
                                link = "logit") {
  set.seed(seed)
  group <- rep(seq_len(groups), each = repeats)
  w <- rep(seq(-1, 1, length.out = groups), each = repeats)
  x <- stats::rnorm(length(group))
  alpha <- c("(Intercept)" = log(0.8), w = 0.5)
  tau <- exp(alpha[[1L]] + alpha[[2L]] * w)
  b <- stats::rnorm(groups)
  inverse <- stats::binomial(link = link)$linkinv
  probability <- inverse(-0.3 + 0.6 * x + tau * b[group])
  success <- stats::rbinom(length(group), size = trials, prob = probability)
  list(
    data = data.frame(y = success, failure = trials - success, x = x,
                      w = w, id = factor(group)),
    alpha = alpha
  )
}

# An independent scalar-cluster Laplace calculation. This does not call TMB,
# drmTMB's likelihood, or its simulation machinery.
binomial_sd_laplace_oracle <- function(data, beta, alpha) {
  group_rows <- split(seq_len(nrow(data)), data$id)
  sum(vapply(group_rows, function(rows) {
    eta <- as.vector(cbind(1, data$x[rows]) %*% beta)
    tau <- exp(alpha[[1L]] + alpha[[2L]] * data$w[rows[[1L]]])
    trials <- data$y[rows] + data$failure[rows]
    joint_nll <- function(b) {
      -sum(stats::dbinom(data$y[rows], size = trials,
                         prob = stats::plogis(eta + b), log = TRUE)) -
        stats::dnorm(b, sd = tau, log = TRUE)
    }
    mode <- stats::optimize(joint_nll, c(-15 * tau, 15 * tau),
                            tol = 1e-10)$minimum
    p <- stats::plogis(eta + mode)
    hessian <- 1 / tau^2 + sum(trials * p * (1 - p))
    joint_nll(mode) + 0.5 * log(hessian) - 0.5 * log(2 * pi)
  }, numeric(1L)))
}
