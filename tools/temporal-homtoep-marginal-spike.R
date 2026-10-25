# Independent base-R marginal Toeplitz identifiability spike: V_i = s^2 R.
reflection_rho <- function(theta) {
  K <- length(theta) + 1L; rho <- numeric(K); rho[1] <- 1
  ar <- numeric(K - 1L); innovation <- 1
  for (m in seq_len(K - 1L)) {
    kappa <- tanh(theta[m])
    prediction <- if (m == 1L) 0 else sum(ar[seq_len(m - 1L)] * rho[m:2L])
    rho[m + 1L] <- prediction + kappa * innovation
    new_ar <- numeric(K - 1L); new_ar[m] <- kappa
    if (m > 1L) for (j in seq_len(m - 1L)) new_ar[j] <- ar[j] - kappa * ar[m - j]
    ar <- new_ar; innovation <- innovation * (1 - kappa^2)
  }
  rho
}
set.seed(202609101L)
n_id <- 80L; K <- 6L
id <- rep(seq_len(n_id), each = K)
between <- rep(rep(c(-0.5, 0.5), length.out = n_id), each = K)
within <- unlist(lapply(seq_len(n_id), function(i) sample(rep(c(-0.5, 0.5), length.out = K))), use.names = FALSE)
X <- cbind(1, between, within)
beta_truth <- c(0, 0.5, 0.5); sd_truth <- 0.8; rho_truth <- c(1, 0.55^(1:5))
root <- chol(toeplitz(rho_truth))
y <- as.vector(X %*% beta_truth) + unlist(lapply(seq_len(n_id), function(i) as.vector(t(root) %*% rnorm(K, sd = sd_truth))), use.names = FALSE)
nll <- function(par) {
  beta <- par[1:3]; sd <- exp(par[4]); R <- toeplitz(reflection_rho(par[5:9]))
  ch <- tryCatch(chol(sd^2 * R), error = function(e) NULL)
  if (is.null(ch)) return(.Machine$double.xmax / 100)
  total <- 0
  for (i in seq_len(n_id)) {
    rows <- which(id == i); z <- forwardsolve(t(ch), y[rows] - X[rows, , drop = FALSE] %*% beta)
    total <- total + sum(log(diag(ch))) + sum(z^2) / 2
  }
  n_id * K * log(2 * pi) / 2 + total
}
fit <- optim(c(0, 0, 0, log(0.7), rep(atanh(0.3), K - 1L)), nll, method = "BFGS", control = list(reltol = 1e-11, maxit = 2000))
H <- optimHess(fit$par, nll)
eig <- eigen((H + t(H)) / 2, symmetric = TRUE, only.values = TRUE)$values
stopifnot(fit$convergence == 0L, all(is.finite(eig)), min(eig) > 1e-4)
cat(sprintf('MARGINAL_HOMTOEP_SPIKE_PASS objective=%.6f min_hessian_eigen=%.6f\n', fit$value, min(eig)))
