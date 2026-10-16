## F5-tiny-n-gaussian: engine-independent checks (base R + stats only).
## Model: y ~ N(b0 + b1 x, exp(g0 + g1 x)^2), n = 8 (cells gauss_n8 / n12 / n20 of sweep-oct16 t4).
## Run from this folder:  Rscript f5_reference.R > f5_reference.out 2>&1
##
## Method. For fixed scale parameters (g0, g1) the mean parameters enter as weighted least
## squares, so the log-likelihood profiles exactly onto (g0, g1):  P(g0, g1) = max_b ll.
## P is evaluated in a numerically exact form: the line is re-parametrised through the two
## highest-weight observations k, j (residuals delta_k, delta_j), and those residuals are
## carried in units of their own sigma, so a fitted sigma of 1e-18 costs no precision.
## Local maxima of P are in one-to-one correspondence with local maxima of ll (the inner
## problem is a strictly convex quadratic), so a 2-D grid scan plus local polish finds every
## local maximum, and the existence question becomes a question about P along a ray.
suppressWarnings(RNGkind("Mersenne-Twister", "Inversion", "Rejection"))
cat("R:", R.version.string, "\n")
ddir <- "../../data"
rd <- function(cell, r) read.csv(file.path(ddir, sprintf("%s_r%02d.csv", cell, r)))
LOG2PI <- log(2 * pi)

## ---- exact profile P(g0, g1) -------------------------------------------------------------
prof <- function(g, y, x, want_beta = FALSE) {
  n <- length(y); ls <- g[1] + g[2] * x
  if (any(!is.finite(ls))) return(if (want_beta) list(ll = -Inf) else -Inf)
  o <- order(ls); k <- o[1]; j <- o[2]                 # two highest-weight observations
  t <- (x - x[k]) / (x[j] - x[k])
  e <- y - (y[k] + t * (y[j] - y[k])); e[c(k, j)] <- 0  # residuals of the k-j line, exact 0 at k, j
  O <- setdiff(seq_len(n), c(k, j))
  ## r = e + (1 - t) delta_k + t delta_j ; v = (delta_k / sigma_k, delta_j / sigma_j)
  B <- cbind(exp(ls[k] - ls[O]) * (1 - t[O]), exp(ls[j] - ls[O]) * t[O])
  z <- exp(-ls[O]) * e[O]
  v <- -solve(diag(2) + crossprod(B), crossprod(B, z))
  rss <- sum(v^2) + sum((z + B %*% v)^2)
  ll <- -sum(ls) - 0.5 * rss - 0.5 * n * LOG2PI
  if (!want_beta) return(ll)
  dk <- v[1] * exp(ls[k]); dj <- v[2] * exp(ls[j])
  b1 <- ((y[j] - dj) - (y[k] - dk)) / (x[j] - x[k]); b0 <- (y[k] - dk) - b1 * x[k]
  list(ll = ll, beta = c(b0, b1), k = k, j = j, ls = ls)
}
## direct log-likelihood in the original parametrisation (for cross-checks at moderate scale)
ll_direct <- function(th, y, x) sum(dnorm(y, th[1] + th[2] * x, exp(th[3] + th[4] * x), log = TRUE))

## sanity: P equals the direct ll at the WLS optimum on well-scaled points
d <- rd("gauss_n20", 1); y <- d$y; x <- d$x
for (g in list(c(-0.3, 0.2), c(-2, 1.5), c(0.5, -1))) {
  w <- exp(-2 * (g[1] + g[2] * x)); b <- coef(lm(y ~ x, weights = w))
  cat(sprintf("check P vs direct WLS at g = (%g, %g): %.12f vs %.12f\n", g[1], g[2],
              prof(g, y, x), ll_direct(c(b, g), y, x)))
}

## ---- 1. analytic existence criterion, independent re-implementation ---------------------
## A spike needs sigma -> 0 at an observation the mean fits exactly. log sigma is linear in x,
## so the spike sits at an extreme x (index k); the line also passes through one more point j.
## Along log sigma_i = -c + s |x_i - x_k| with s = (c + K) / D (D = distance from x_k to the
## nearest point other than k, j), ll(c) = slope * c + O(1) with
##   slope = 1 + (1 - d_j / D) + sum_{i != k, j} (1 - d_i / D).
## The MLE fails to exist iff the best slope over k in {argmin x, argmax x} and j is > 0.
slope_of <- function(x) {
  n <- length(x); best <- c(slope = -Inf, k = NA, j = NA, D = NA)
  for (k in unique(c(which.min(x), which.max(x)))) {
    dk <- abs(x - x[k])
    for (j in setdiff(seq_len(n), k)) {
      oth <- setdiff(seq_len(n), c(k, j)); D <- min(dk[oth])
      s <- 1 + (1 - dk[j] / D) + sum(1 - dk[oth] / D)
      if (s > best["slope"]) best <- c(slope = s, k = k, j = j, D = D)
    }
  }
  best
}
cat("\n== 1. existence criterion over all 150 Gaussian datasets ==\n")
S <- do.call(rbind, lapply(c("gauss_n8", "gauss_n12", "gauss_n20"), function(cell)
  do.call(rbind, lapply(1:50, function(r) { s <- slope_of(rd(cell, r)$x)
    data.frame(cell = cell, rep = r, slope = s[["slope"]], k = s[["k"]], j = s[["j"]]) }))))
print(table(cell = S$cell, unbounded = S$slope > 0))
cat("datasets with slope > -0.05 (unbounded, or bounded with a near-flat ridge):\n")
print(S[S$slope > -0.05, ], row.names = FALSE, digits = 6)

## ---- 2. profile with log sigma at the spike observation held fixed ----------------------
## P_c = max over the remaining scale parameter of P, with log sigma(x_k) = -c fixed.
## Rising P_c without bound => no MLE. Uses the exact P above (no residual precision loss).
pc <- function(y, x, k, cval) {
  xo <- x[which.max(abs(x - x[k]))]                    # the other extreme
  ## L = log sigma at the other extreme; log sigma is the line through (x_k, -c) and (xo, L)
  f <- function(L) { g1 <- (L + cval) / (xo - x[k]); prof(c(-cval - g1 * x[k], g1), y, x) }
  ## search a wide bracket around the asymptotic choice s = (c + K) / D
  D <- sort(abs(x - x[k]))[3]; L0 <- -cval + (cval + 5) / D * abs(xo - x[k])
  o <- optimize(f, c(-cval, L0 + 50 + 2 * abs(L0)), maximum = TRUE, tol = 1e-10)
  c(ll = o$objective, L = o$maximum)
}
cat("\n== 2. profile with log sigma at the spike observation fixed at -c ==\n")
cvals <- c(5, 10, 20, 40, 80, 160, 320, 1e3, 1e4, 1e5)
for (r in c(6, 19, 49, 30, 4, 31, 29)) {
  d <- rd("gauss_n8", r); s <- slope_of(d$x)
  pp <- t(sapply(cvals, function(cv) pc(d$y, d$x, s[["k"]], cv)))
  inc <- diff(pp[, "ll"]) / diff(cvals)
  cat(sprintf("\nr%02d  analytic slope %.6g (k = %d, j = %d)\n", r, s[["slope"]], s[["k"]], s[["j"]]))
  print(data.frame(c = cvals, P_c = pp[, "ll"], dP_dc = c(NA, inc)), row.names = FALSE, digits = 8)
}

## ---- 3. every local maximum: dense 2-D grid scan of P + local polish ---------------------
## Grid on (L1, L2) = (log sigma at min x, log sigma at max x) in [-60, 40]^2, step 0.5.
## Grid cells that beat all 8 neighbours are polished with Nelder-Mead + BFGS on P;
## polished points within 1e-6 in P and 1e-3 in parameters are merged. A maximum on the
## grid boundary is reported as "edge" (P still rising: unbounded direction or out of box).
gpar <- function(L, x) { g1 <- (L[2] - L[1]) / (max(x) - min(x)); c(L[1] - g1 * min(x), g1) }
scan_maxima <- function(y, x, lim = c(-60, 40), h = 0.5) {
  grid <- seq(lim[1], lim[2], by = h); m <- length(grid)
  Z <- matrix(NA_real_, m, m)
  for (a in seq_len(m)) for (b in seq_len(m)) Z[a, b] <- prof(gpar(c(grid[a], grid[b]), x), y, x)
  loc <- list()
  for (a in seq_len(m)) for (b in seq_len(m)) {
    nb <- Z[max(1, a - 1):min(m, a + 1), max(1, b - 1):min(m, b + 1)]
    if (Z[a, b] >= max(nb)) loc[[length(loc) + 1]] <- c(a, b)
  }
  out <- list()
  for (ab in loc) {
    a <- ab[1]; b <- ab[2]; edge <- a %in% c(1, m) || b %in% c(1, m)
    g0 <- gpar(c(grid[a], grid[b]), x)
    f <- function(g) -prof(g, y, x)
    o <- optim(g0, f, method = "Nelder-Mead", control = list(maxit = 5000, reltol = 1e-14))
    o <- optim(o$par, f, method = "BFGS", control = list(maxit = 2000, reltol = 1e-15))
    out[[length(out) + 1]] <- c(ll = -o$value, g0 = o$par[1], g1 = o$par[2], grid_edge = edge)
  }
  res <- as.data.frame(do.call(rbind, out))
  res <- res[order(-res$ll), ]
  keep <- rep(TRUE, nrow(res))
  for (i in seq_len(nrow(res))) if (keep[i]) for (j in seq_len(nrow(res))) if (j > i && keep[j] &&
      abs(res$ll[i] - res$ll[j]) < 1e-6 && max(abs(res[i, 2:3] - res[j, 2:3])) < 1e-3) keep[j] <- FALSE
  res[keep, ]
}
## curvature and gradient of P at a point (central differences on the exact P)
pdiag <- function(g, y, x, h = 1e-4) {
  f <- function(p) prof(p, y, x)
  gr <- sapply(1:2, function(i) { e <- replace(c(0, 0), i, h); (f(g + e) - f(g - e)) / (2 * h) })
  H <- matrix(0, 2, 2)
  for (i in 1:2) for (j in 1:2) { ei <- replace(c(0, 0), i, h); ej <- replace(c(0, 0), j, h)
    H[i, j] <- (f(g + ei + ej) - f(g + ei - ej) - f(g - ei + ej) + f(g - ei - ej)) / (4 * h^2) }
  c(max_abs_grad = max(abs(gr)), max_eig = max(eigen(H, symmetric = TRUE)$values))
}
cat("\n== 3. all local maxima of the exact likelihood (gauss_n8; grid scan + polish) ==\n")
cat("columns: ll, g0, g1 = the polished maximum; grid_edge = 1 if the scan max sat on the box edge;\n",
    "max_abs_grad / max_eig = gradient and largest Hessian eigenvalue of P there (local max: ~0 and < 0);\n",
    "min_ls / max_ls = fitted log sigma range; b0, b1 = the mean line at that maximum.\n")
allmax <- list()
t0 <- proc.time()[["elapsed"]]
for (r in 1:50) {
  d <- rd("gauss_n8", r); y <- d$y; x <- d$x
  M <- scan_maxima(y, x)
  for (i in seq_len(nrow(M))) {
    g <- c(M$g0[i], M$g1[i]); pb <- prof(g, y, x, want_beta = TRUE); dg <- pdiag(g, y, x)
    allmax[[length(allmax) + 1]] <- data.frame(rep = r, rank = i, ll = M$ll[i], g0 = g[1], g1 = g[2],
      grid_edge = M$grid_edge[i], max_abs_grad = dg[["max_abs_grad"]], max_eig = dg[["max_eig"]],
      min_ls = min(pb$ls), max_ls = max(pb$ls), b0 = pb$beta[1], b1 = pb$beta[2])
  }
}
A <- do.call(rbind, allmax)
cat(sprintf("scan time %.0f s\n", proc.time()[["elapsed"]] - t0))
nmax <- tapply(A$rep, A$rep, length)
cat("number of distinct maxima found per dataset (interior + edge):\n"); print(table(nmax))
cat("\ndatasets with more than one maximum or an edge maximum:\n")
sel <- A$rep %in% as.integer(names(nmax)[nmax > 1]) | A$rep %in% A$rep[A$grid_edge == 1]
print(A[sel, ], row.names = FALSE, digits = 7)
write.csv(A, "f5_reference_maxima.csv", row.names = FALSE)

## ---- 4. the run-1 numbers of both engines evaluated on the exact likelihood -------------
run1 <- "/tmp/claude-0/-home-user/ed2098f2-a8dc-5fee-9d90-16689cc12c90/scratchpad/run1/results"
if (dir.exists(run1)) {
  cat("\n== 4. engine estimates (sweep run 1) on the exact likelihood, and nearest reference maximum ==\n")
  R <- read.csv(file.path(run1, "fits_drmTMB.csv"), stringsAsFactors = FALSE)
  J <- read.csv(file.path(run1, "fits_DRModels.csv"), stringsAsFactors = FALSE)
  pc_ <- function(s) as.numeric(sub(".*=", "", strsplit(s, ";")[[1]]))
  for (r in c(4, 5, 6, 9, 19, 28, 29, 30, 31, 49)) {
    f <- sprintf("gauss_n8_r%02d.csv", r); d <- rd("gauss_n8", r)
    for (eng in c("drmTMB", "DRModels.jl")) {
      row <- if (eng == "drmTMB") R[R$file == f, ] else J[J$file == f, ]
      th <- pc_(row$coef)
      cat(sprintf("r%02d %-11s converged=%-5s reported ll %.7f | exact ll at its estimate %.7f | log sigma range [%.2f, %.2f] | best max %.7f\n",
                  r, eng, row$converged, row$logLik, ll_direct(th, d$y, d$x),
                  min(th[3] + th[4] * d$x), max(th[3] + th[4] * d$x), max(A$ll[A$rep == r])))
    }
  }
}
