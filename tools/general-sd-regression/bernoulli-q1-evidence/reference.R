# Independent one-dimensional references for the frozen Bernoulli SD case.
# This file is sourced *inside* the existing paired test expression after its
# public-method checks, so `sim`, `native_fit`, and `fit` are the original objects.

q1_gh_rule <- function(k) {
  stopifnot(k >= 1L)
  if (k == 1L) return(list(z = 0, w = sqrt(pi)))
  jacobi <- matrix(0, k, k)
  off <- sqrt(seq_len(k - 1L) / 2)
  for (j in seq_len(k - 1L)) {
    jacobi[j, j + 1L] <- off[j]
    jacobi[j + 1L, j] <- off[j]
  }
  eig <- eigen(jacobi, symmetric = TRUE)
  order <- order(eig$values)
  list(z = eig$values[order],
       w = sqrt(pi) * eig$vectors[1L, order]^2)
}

q1_logsumexp <- function(x) {
  m <- max(x)
  m + log(sum(exp(x - m)))
}

q1_aghq_nll <- function(data, beta, alpha, k) {
  rule <- q1_gh_rule(k)
  rows_by_group <- split(seq_len(nrow(data)), data$id)
  sum(vapply(rows_by_group, function(rows) {
    stopifnot(length(unique(data$w[rows])) == 1L)
    stopifnot(all(data$y[rows] + data$failure[rows] == 1L))
    eta0 <- as.vector(cbind(1, data$x[rows]) %*% beta)
    tau <- exp(alpha[[1L]] + alpha[[2L]] * data$w[rows[[1L]]])
    f <- function(b) {
      sum(stats::dbinom(data$y[rows], size = 1L,
                        prob = stats::plogis(eta0 + b), log = TRUE)) +
        stats::dnorm(b, 0, tau, log = TRUE)
    }
    bound <- max(15 * tau, 20)
    mode <- stats::optimize(function(b) -f(b), c(-bound, bound),
                            tol = 1e-10)$minimum
    p <- stats::plogis(eta0 + mode)
    h <- 1 / tau^2 + sum(p * (1 - p))
    stopifnot(is.finite(h), h > 0)
    cscale <- sqrt(2 / h)
    -(log(cscale) + q1_logsumexp(log(rule$w) +
      vapply(mode + cscale * rule$z, f, numeric(1L)) + rule$z^2))
  }, numeric(1L)))
}

# Two exact controls independent of either fitting engine.
gh5 <- q1_gh_rule(5L)
testthat::expect_equal(sum(gh5$w), sqrt(pi), tolerance = 1e-14)
testthat::expect_equal(sum(gh5$w * gh5$z^2), sqrt(pi) / 2,
                       tolerance = 1e-14)
testthat::expect_equal(sum(gh5$w * gh5$z^4), 3 * sqrt(pi) / 4,
                       tolerance = 1e-14)
testthat::expect_equal(sum(gh5$w * gh5$z^6), 15 * sqrt(pi) / 8,
                       tolerance = 1e-14)
testthat::expect_equal(sum(gh5$w * gh5$z^8), 105 * sqrt(pi) / 16,
                       tolerance = 1e-13)
for (tau_control in c(0.35, 0.8, 2.0)) {
  density_at_nodes <- stats::dnorm(sqrt(2) * tau_control * gh5$z,
                                   sd = tau_control, log = TRUE)
  gaussian_logint <- log(sqrt(2) * tau_control) +
    q1_logsumexp(log(gh5$w) + density_at_nodes + gh5$z^2)
  testthat::expect_equal(gaussian_logint, 0, tolerance = 1e-13)
}

data <- sim$data
stopifnot(nrow(data) == 3600L, nlevels(data$id) == 300L)
stopifnot(all(data$y + data$failure == 1L))
fixture_path <- file.path(Sys.getenv("Q1_EVIDENCE", tempdir()), "fixture.rds")
saveRDS(sim, fixture_path, version = 3L)
fixture_sha <- suppressWarnings(system2("shasum",
  c("-a", "256", shQuote(fixture_path)), stdout = TRUE))
cat("Q1 fixture RDS:", fixture_path, "\n")
cat("Q1 fixture SHA256:", strsplit(fixture_sha, " +")[[1L]][[1L]], "\n")
native_beta <- stats::coef(native_fit, dpar = "mu")
native_alpha <- stats::coef(native_fit, dpar = "sd(id)")
julia_beta <- stats::coef(fit, dpar = "mu")
julia_alpha <- stats::coef(fit, dpar = "sd(id)")
stopifnot(identical(names(native_beta), c("(Intercept)", "x")))
stopifnot(identical(names(julia_beta), names(native_beta)))
stopifnot(identical(names(native_alpha), c("(Intercept)", "w")))
stopifnot(identical(names(julia_alpha), names(native_alpha)))
native_eta_sd <- native_alpha[[1L]] + native_alpha[[2L]] *
  unique(data$w[!duplicated(data$id)])
julia_eta_sd <- julia_alpha[[1L]] + julia_alpha[[2L]] *
  unique(data$w[!duplicated(data$id)])
# Both engines use a smooth clamp that is exactly identity within [-9, 9].
# The simple exp(alpha0 + alpha1*w) reference is valid only in this interior.
testthat::expect_lt(max(abs(native_eta_sd)), 9)
testthat::expect_lt(max(abs(julia_eta_sd)), 9)
testthat::expect_true(all(is.finite(c(ci_sd_slope$lower,
                                      ci_sd_slope$upper))))
testthat::expect_lt(ci_sd_slope$lower, ci_sd_slope$upper)
testthat::expect_true(all(is.finite(c(ci_sd_slope_boot$lower,
                                      ci_sd_slope_boot$upper))))
testthat::expect_lt(ci_sd_slope_boot$lower, ci_sd_slope_boot$upper)

native_ref <- binomial_sd_laplace_oracle(data, native_beta, native_alpha)
native_nll <- -as.numeric(stats::logLik(native_fit))
julia_ref <- q1_aghq_nll(data, julia_beta, julia_alpha, 5L)
julia_nll <- -as.numeric(stats::logLik(fit))
one_node <- q1_aghq_nll(data, native_beta, native_alpha, 1L)
testthat::expect_equal(one_node, native_ref, tolerance = 1e-6)
testthat::expect_lte(abs(native_nll - native_ref), 1e-6)
testthat::expect_lte(abs(julia_nll - julia_ref), 1e-5)

cat(sprintf("Q1 fixture rows=%d groups=%d trials=%s\n",
            nrow(data), nlevels(data$id),
            paste(unique(data$y + data$failure), collapse = ",")))
cat(sprintf("Q1 native NLL=%.12f Laplace reference=%.12f abs_error=%.9g\n",
            native_nll, native_ref, abs(native_nll - native_ref)))
cat(sprintf("Q1 Julia NLL=%.12f AGHQ5 reference=%.12f abs_error=%.9g\n",
            julia_nll, julia_ref, abs(julia_nll - julia_ref)))
cat(sprintf("Q1 AGHQ1 versus Laplace abs_error=%.9g\n",
            abs(one_node - native_ref)))
cat(sprintf("Q1 native/JULIA NLL gap (distinct approximations)=%.9g\n",
            abs(native_nll - julia_nll)))
cat(sprintf("Q1 SD predictor abs maxima native=%.6g Julia=%.6g interior_bound=9\n",
            max(abs(native_eta_sd)), max(abs(julia_eta_sd))))
cat(sprintf("Q1 profile interval lower=%.9g upper=%.9g; bootstrap3 lower=%.9g upper=%.9g\n",
            ci_sd_slope$lower, ci_sd_slope$upper,
            ci_sd_slope_boot$lower, ci_sd_slope_boot$upper))
cat(sprintf("Q1 native pdHess=%s Julia converged=%s\n",
            native_fit$sdr$pdHess, fit$bridge$converged))
