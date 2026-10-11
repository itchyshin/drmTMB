# Independent high-precision reference for one-dimensional mi() marginals
# (#1476, #1477). `log_integrand(x)` is log p(x) + log f(y | x) for one row on
# the support (lower, upper). The mode is located by a dense scan (linear on a
# bounded support, log-spaced on a half-line) refined by optimize(), because
# optimize() alone can lock onto the wrong part of a wide interval when the
# posterior is narrow. integrate() then runs on segments around the mode with
# stop.on.error = TRUE, so a failed segment errors instead of silently
# returning a partial value. Used to check the TMB quadrature, never by it.
mi_reference_log_marginal <- function(log_integrand, lower, upper) {
  n_scan <- 40001L
  scan <- if (is.finite(upper)) {
    seq(lower, upper, length.out = n_scan + 2L)[-c(1L, n_scan + 2L)]
  } else {
    lower + 10^seq(-10, 7, length.out = n_scan)
  }
  v <- log_integrand(scan)
  v[!is.finite(v)] <- -Inf
  j <- which.max(v)
  bracket <- c(scan[[max(j - 1L, 1L)]], scan[[min(j + 1L, n_scan)]])
  opt <- stats::optimize(log_integrand, bracket, maximum = TRUE, tol = 1e-14)
  mode <- if (opt$objective >= v[[j]]) opt$maximum else scan[[j]]
  shift <- max(opt$objective, v[[j]])
  step <- max(1e-5 * abs(mode), 1e-9)
  curv <- -(log_integrand(mode + step) - 2 * log_integrand(mode) +
    log_integrand(mode - step)) / step^2
  span <- if (is.finite(upper)) upper - lower else max(10 * mode, 1)
  width <- if (is.finite(curv) && curv > 0) 1 / sqrt(curv) else span / 50
  width <- min(width, span / 4)
  pts <- mode + width * c(-60, -30, -15, -8, -4, -2, -1, 0, 1, 2, 4, 8, 15, 30, 60)
  pts <- pts[pts > lower & pts < upper]
  pts <- sort(unique(c(lower, pts, upper)))
  f <- function(x) {
    out <- exp(log_integrand(x) - shift)
    out[!is.finite(out)] <- 0
    out
  }
  total <- 0
  for (i in seq_len(length(pts) - 1L)) {
    total <- total + stats::integrate(
      f,
      pts[[i]],
      pts[[i + 1L]],
      rel.tol = 1e-11,
      abs.tol = 0,
      subdivisions = 5000L
    )$value
  }
  shift + log(total)
}
