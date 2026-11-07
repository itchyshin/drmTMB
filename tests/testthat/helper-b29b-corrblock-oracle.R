# Batch 29 (lane b) shared correlated-block Binomial oracle (see
# test-binomial-correlated-q3-sd-oracle-b29b.R for scope).

b29b_corr_block_fixture <- function(q, link, seed, groups, repeats) {
  set.seed(seed)
  id <- factor(rep(seq_len(groups), each = repeats))
  n <- length(id)
  xs <- c("x", "z", "t")[seq_len(q - 1L)]
  X <- vapply(xs, function(v) stats::rnorm(n), numeric(n))
  sel_names <- c("w", "h", "j", "k")[seq_len(q)]
  sel <- lapply(sel_names, function(v) as.numeric(scale(stats::rnorm(groups))))
  names(sel) <- sel_names
  a <- list(c(log(0.9), 0.7), c(log(0.8), -0.7), c(log(0.8), 0.6),
            c(log(0.7), -0.6))[seq_len(q)]
  tau <- vapply(seq_len(q), function(k) exp(a[[k]][[1L]] + a[[k]][[2L]] * sel[[k]]),
                numeric(groups))
  # Modified-Cholesky partial correlations (always a valid R).
  partial <- c(0.5, -0.4, 0.35, 0.3, -0.35, 0.25)[seq_len(q * (q - 1L) / 2L)]
  Lc <- matrix(0, q, q)
  pos <- 0L
  for (i in seq_len(q)) {
    prod_ <- 1
    for (j in seq_len(i - 1L)) {
      pos <- pos + 1L
      Lc[i, j] <- prod_ * partial[[pos]]
      prod_ <- prod_ * sqrt(1 - partial[[pos]]^2)
    }
    Lc[i, i] <- prod_
  }
  u <- vapply(seq_len(groups), function(g) {
    drop(diag(tau[g, ]) %*% Lc %*% stats::rnorm(q))
  }, numeric(q))
  gi <- as.integer(id)
  eta <- -0.1 + 0.2 * X[, 1L] - 0.15 * X[, 2L] + u[1L, gi] +
    u[2L, gi] * X[, 1L] + u[3L, gi] * X[, 2L] +
    if (q == 4L) 0.12 * X[, 3L] + u[4L, gi] * X[, 3L] else 0
  p <- if (identical(link, "probit")) stats::pnorm(eta) else -expm1(-exp(eta))
  dat <- data.frame(y = stats::rbinom(n, 1L, p), X, id)
  for (k in seq_len(q)) dat[[sel_names[[k]]]] <- rep(sel[[k]], each = repeats)
  list(data = dat, sel = unname(sel), xs = xs, sel_names = sel_names)
}

b29b_corr_block_check <- function(q, link, seed, groups, repeats) {
  fx <- b29b_corr_block_fixture(q, link, seed, groups, repeats)
  dat <- fx$data
  coefs <- c("(Intercept)", fx$xs)
  keys <- paste0('sd(id, dpar = "mu", coef = "', coefs, '")')
  main <- stats::as.formula(paste0(
    "y ~ ", paste(fx$xs[seq_len(q - 1L)], collapse = " + "),
    " + (1 + ", paste(fx$xs, collapse = " + "), " | id)"
  ))
  sds <- lapply(seq_len(q), function(k) {
    stats::as.formula(paste0(keys[[k]], " ~ ", fx$sel_names[[k]]), env = globalenv())
  })
  # The mean fixed part is x + z (+ t): all block covariates are also fixed.
  main <- stats::as.formula(paste0(
    "y ~ ", paste(fx$xs, collapse = " + "),
    " + (1 + ", paste(fx$xs, collapse = " + "), " | id)"
  ))
  fit <- drmTMB(do.call(bf, c(list(main), sds)),
                family = stats::binomial(link = link), data = dat,
                control = drm_control(se = FALSE))
  expect_identical(fit$opt$convergence, 0L, info = paste(q, link))
  co <- lapply(keys, function(k) coef(fit, k))
  for (k in seq_len(q)) {
    expect_identical(names(co[[k]]), c("(Intercept)", fx$sel_names[[k]]))
  }
  curve <- function(cf, w) unname(exp(cf[[1L]] + cf[[2L]] * w))
  S0 <- vapply(seq_len(q), function(k) curve(co[[k]], fx$sel[[k]]),
               numeric(groups <- length(fx$sel[[1L]])))
  cors <- fit$corpars$mu
  expect_length(cors, q * (q - 1L) / 2L)
  R <- diag(q)
  for (nm in names(cors)) {
    inner <- sub("^cor\\((.*) \\| id\\)$", "\\1", nm)
    p <- trimws(strsplit(inner, ",", fixed = TRUE)[[1L]])
    i <- match(p[[1L]], coefs)
    j <- match(p[[2L]], coefs)
    expect_false(anyNA(c(i, j)), info = nm)
    R[i, j] <- R[j, i] <- unname(cors[[nm]])
  }
  mu <- unname(coef(fit, "mu"))
  Xf <- cbind(1, as.matrix(dat[, fx$xs, drop = FALSE]))
  eta_fixed <- drop(Xf %*% mu)
  oracle <- function(S = S0, Rm = R) {
    sum(vapply(seq_len(groups), function(g) {
      rows <- which(as.integer(dat$id) == g)
      sb26_laplace(sb26_deriv_binary(dat$y[rows], link), eta_fixed[rows],
                   Xf[rows, , drop = FALSE],
                   diag(S[g, ], q) %*% Rm %*% diag(S[g, ], q))
    }, numeric(1L)))
  }
  ref <- oracle()
  ll <- as.numeric(logLik(fit))
  expect_lt(abs(ll - ref), 1e-4, label = paste(q, link))
  for (k in seq_len(q)) expect_gt(stats::sd(log(S0[, k])), 0.05)
  flipR <- R
  flipR[1L, 2L] <- flipR[2L, 1L] <- -R[1L, 2L]
  rev_col <- function(k) {
    S <- S0
    S[, k] <- rev(S[, k])
    S
  }
  bugs <- c(
    rotated_coef_sets = oracle(S = vapply(seq_len(q), function(k) {
      curve(co[[k %% q + 1L]], fx$sel[[k]])
    }, numeric(groups))),
    stats::setNames(lapply(seq_len(q), function(k) oracle(S = rev_col(k))),
                    paste0("reversed_sd_", coefs)),
    flipped_cor_first = oracle(Rm = flipR),
    R_identity = oracle(Rm = diag(q))
  )
  bugs <- unlist(bugs)
  for (nm in names(bugs)) {
    expect_gt(abs(bugs[[nm]] - ref), 0.1, label = paste(q, link, nm))
  }
  if (nzchar(Sys.getenv("B29B_SHOW_GAPS"))) {
    cat(sprintf("GAP q%d %s | ll-ref %.2e | min gap %.3f (%s)\n", q, link, ll - ref,
                min(abs(bugs - ref)), names(bugs)[[which.min(abs(bugs - ref))]]))
  }
}
