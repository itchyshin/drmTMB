## sweep-oct16 / t4: engine-independent reference likelihoods (base R + stats only).
## For each dataset: the best log-likelihood found by multi-start optim on the
## exact likelihood written here, plus boundary / existence diagnostics.
## Output: results/reference.csv
suppressWarnings(RNGkind("Mersenne-Twister", "Inversion", "Rejection"))
args <- commandArgs(trailingOnly = TRUE)
ddir <- if (length(args) >= 1) args[1] else "sweep-oct16/t4/data"
out  <- if (length(args) >= 2) args[2] else "sweep-oct16/t4/results/reference.csv"
idx <- read.csv(file.path(ddir, "index.csv"), stringsAsFactors = FALSE)

## multi-start optimiser: BFGS from each start, then Nelder-Mead + BFGS polish of the best
ms_opt <- function(nll, gr, starts) {
  best <- NULL; vals <- numeric(0)
  for (s in starts) {
    o <- try(optim(s, nll, gr, method = "BFGS",
                   control = list(maxit = 5000, reltol = 1e-15)), silent = TRUE)
    if (inherits(o, "try-error") || !is.finite(o$value)) next
    vals <- c(vals, o$value)
    if (is.null(best) || o$value < best$value) best <- o
  }
  if (is.null(best)) return(list(value = NA_real_, par = NA, nloc = NA, spread = NA))
  for (i in 1:3) {
    o2 <- try(optim(best$par, nll, method = "Nelder-Mead",
                    control = list(maxit = 20000, reltol = 1e-15)), silent = TRUE)
    if (!inherits(o2, "try-error") && is.finite(o2$value) && o2$value < best$value) best <- o2
    o3 <- try(optim(best$par, nll, gr, method = "BFGS",
                    control = list(maxit = 5000, reltol = 1e-15)), silent = TRUE)
    if (!inherits(o3, "try-error") && is.finite(o3$value) && o3$value < best$value) best <- o3
  }
  ## distinct local optima: values more than 1e-3 above the best
  loc <- sort(unique(round(vals - best$value, 3)))
  list(value = best$value, par = best$par, nloc = sum(loc > 1e-3) + 1,
       second_gap = if (any(loc > 1e-3)) min(loc[loc > 1e-3]) else NA_real_)
}
numgr <- function(f) function(p) {
  h <- 1e-6 * pmax(1, abs(p)); g <- numeric(length(p))
  for (j in seq_along(p)) { e <- replace(numeric(length(p)), j, h[j]); g[j] <- (f(p + e) - f(p - e)) / (2 * h[j]) }
  g
}
rstarts <- function(base, n, sd = 1, seed = 1) {
  set.seed(seed); c(list(base), lapply(seq_len(n), function(i) base + rnorm(length(base), 0, sd)))
}

gls_ref <- function(y, Xm, Xs, seed) {
  p <- ncol(Xm); q <- ncol(Xs)
  nll <- function(th) {
    mu <- Xm %*% th[1:p]; ls <- Xs %*% th[p + 1:q]
    if (any(!is.finite(ls)) || any(ls < -700)) return(Inf)
    -sum(dnorm(y, mu, exp(ls), log = TRUE))
  }
  gr <- function(th) {
    mu <- drop(Xm %*% th[1:p]); ls <- drop(Xs %*% th[p + 1:q]); s2 <- exp(2 * ls); r <- y - mu
    c(-crossprod(Xm, r / s2), -crossprod(Xs, r^2 / s2 - 1))
  }
  b <- qr.coef(qr(Xm), y); b[is.na(b)] <- 0
  base <- c(b, log(sd(y)), rep(0, q - 1))
  ms_opt(nll, gr, rstarts(base, 40, 1, seed))
}

res <- vector("list", nrow(idx))
for (i in seq_len(nrow(idx))) {
  row <- idx[i, ]; d <- read.csv(file.path(ddir, row$file)); y <- d$y; n <- nrow(d)
  cell <- row$cell; seed <- row$r_seed
  info <- list(ref_ll = NA_real_, ref_par = "", ref_nloc = NA, ref_second_gap = NA,
               mle_exists = TRUE, boundary = FALSE, note = "")
  X1 <- cbind(1, d$x)
  if (startsWith(cell, "gauss_")) {
    o <- gls_ref(y, X1, X1, seed)
    info$ref_ll <- -o$value; info$ref_par <- paste(signif(o$par, 8), collapse = ";")
    info$ref_nloc <- o$nloc; info$ref_second_gap <- o$second_gap
  } else if (startsWith(cell, "pois_")) {
    pos <- y > 0
    if (!any(pos)) { info$mle_exists <- FALSE; info$ref_ll <- 0; info$note <- "all y = 0: sup logLik = 0, intercept -> -Inf" }
    else if (length(unique(d$x[pos])) == 1 && (all(d$x[pos] == max(d$x)) || all(d$x[pos] == min(d$x)))) {
      info$mle_exists <- FALSE; kp <- which(pos)
      info$ref_ll <- sum(dpois(y[kp], y[kp], log = TRUE))
      info$note <- "positive counts only at an extreme x: slope -> +-Inf; sup logLik = that point's saturated term"
    }
    g <- suppressWarnings(glm(y ~ x, family = poisson(), data = d, control = glm.control(epsilon = 1e-14, maxit = 200)))
    if (info$mle_exists) { info$ref_ll <- as.numeric(logLik(g)); info$ref_par <- paste(signif(coef(g), 8), collapse = ";") }
  } else if (startsWith(cell, "bin_")) {
    info$mle_exists <- FALSE; info$ref_ll <- 0
    info$note <- if (cell == "bin_complete") "complete separation: sup logLik = 0, slope -> +Inf"
                 else {
                   y0 <- y[d$x == 0]; p0 <- mean(y0); m0 <- length(y0)
                   info$ref_ll <- sum(dbinom(y0, 1, p0, log = TRUE))
                   sprintf("quasi-complete separation: sup logLik = %.6f (ties at x=0, p=%.2f), slope -> +Inf", info$ref_ll, p0)
                 }
  } else if (cell == "nb2_poisdata") {
    ## NB2 with Var = mu + sigma^2 mu^2  (size = 1/sigma^2); theta = (b0, b1, log sigma)
    ## stable log-density (R's dnbinom loses ~1e-5 per dataset at size ~ 1e10):
    ## log p = sum_{j<y} log1p((j - mu)/(size + mu)) + y log mu - lgamma(y + 1) - size log1p(mu/size)
    yj <- lapply(y, function(yy) if (yy > 0) 0:(yy - 1) else numeric(0))
    nb2_ld <- function(mu, size) vapply(seq_along(y), function(i)
      sum(log1p((yj[[i]] - mu[i]) / (size + mu[i]))) + y[i] * log(mu[i]) - lgamma(y[i] + 1) -
        size * log1p(mu[i] / size), 0)
    nll <- function(th) { mu <- exp(drop(X1 %*% th[1:2])); s <- exp(th[3]); size <- 1 / s^2
      v <- -sum(nb2_ld(mu, size)); if (is.finite(v)) v else Inf }
    g <- glm(y ~ x, family = poisson(), data = d, control = glm.control(epsilon = 1e-14))
    pll <- as.numeric(logLik(g))
    starts <- lapply(c(-12, -8, -6, -4, -3, -2, -1, 0), function(ls) c(coef(g), ls))
    o <- ms_opt(nll, numgr(nll), starts)
    nbll <- -o$value
    info$ref_ll <- max(nbll, pll); info$ref_par <- paste(signif(o$par, 8), collapse = ";")
    info$boundary <- (nbll - pll) < 1e-6 || o$par[3] < -6
    ## score of log(1/size) at the Poisson limit: sign tells whether overdispersion is supported
    info$note <- sprintf("poisson_ll=%.8f nb2_ll=%.8f nb2_logsigma=%.4f lrt=%.4g", pll, nbll, o$par[3], 2 * (nbll - pll))
  } else if (cell == "beta_phi1e4") {
    ## Beta(mu phi, (1-mu) phi), logit mu, theta = (b0, b1, log phi)
    nll <- function(th) { mu <- plogis(drop(X1 %*% th[1:2])); phi <- exp(th[3])
      v <- -sum(dbeta(y, mu * phi, (1 - mu) * phi, log = TRUE)); if (is.finite(v)) v else Inf }
    lm0 <- lm(qlogis(y) ~ d$x)
    starts <- c(lapply(c(4, 7, 9.2, 11), function(lp) c(coef(lm0), lp)), list(c(0, 0.5, 9.21)))
    o <- ms_opt(nll, numgr(nll), starts)
    info$ref_ll <- -o$value; info$ref_par <- paste(signif(o$par, 10), collapse = ";")
    info$ref_nloc <- o$nloc
  } else if (cell == "student_gaussdata") {
    ## t_nu location-scale; theta = (b0, b1, log sigma, log nu)
    nll <- function(th) { mu <- drop(X1 %*% th[1:2]); s <- exp(th[3]); nu <- exp(th[4])
      v <- -sum(dt((y - mu) / s, df = nu, log = TRUE) - log(s)); if (is.finite(v)) v else Inf }
    l <- lm(y ~ x, data = d); s_ml <- sqrt(mean(resid(l)^2))
    gll <- sum(dnorm(y, fitted(l), s_ml, log = TRUE))
    starts <- lapply(c(0, 1, 2, 3, 5, 8, 12), function(ln) c(coef(l), log(s_ml), ln))
    o <- ms_opt(nll, numgr(nll), starts)
    tll <- -o$value
    info$ref_ll <- max(tll, gll); info$ref_par <- paste(signif(o$par, 8), collapse = ";")
    info$boundary <- (tll - gll) < 1e-6 || o$par[4] > 10
    info$note <- sprintf("gauss_ll=%.8f t_ll=%.8f t_lognu=%.3f excess_kurt=%.3f", gll, tll, o$par[4],
                         mean(resid(l)^4) / mean(resid(l)^2)^2 - 3)
  } else if (cell == "re_sd1e-4") {
    ## exact Gaussian random-intercept marginal; theta = (b0, b1, log s, log tau)
    gidx <- split(seq_len(n), d$g)
    nll <- function(th) { r <- y - drop(X1 %*% th[1:2]); s2 <- exp(2 * th[3]); t2 <- exp(2 * th[4]); tot <- 0
      for (ii in gidx) { m <- length(ii); rr <- r[ii]; a <- s2 + m * t2
        tot <- tot + 0.5 * (m * log(2 * pi) + (m - 1) * log(s2) + log(a) + (sum(rr^2) - t2 / a * sum(rr)^2) / s2) }
      if (is.finite(tot)) tot else Inf }
    l <- lm(y ~ x, data = d); s_ml <- sqrt(mean(resid(l)^2))
    lmll <- as.numeric(logLik(l))  # ML (lm logLik is ML)
    starts <- lapply(c(-12, -6, -3, -1.5, -0.5), function(lt) c(coef(l), log(s_ml), lt))
    o <- ms_opt(nll, numgr(nll), starts)
    info$ref_ll <- max(-o$value, lmll); info$ref_par <- paste(signif(o$par, 8), collapse = ";")
    info$boundary <- (-o$value - lmll) < 1e-6 || o$par[4] < -6
    info$note <- sprintf("lm_ll=%.8f re_ll=%.8f log_tau=%.3f", lmll, -o$value, o$par[4])
  } else if (cell == "collin_sigma_exact") {
    o <- gls_ref(y, X1, X1, seed)  # z = 2x + 1 lies in span(1, x): reduced model is the full model
    info$ref_ll <- -o$value; info$ref_par <- paste(signif(o$par, 8), collapse = ";")
    info$note <- "rank-deficient sigma design (z = 2x + 1): MLE of (g0, g1, g2) not unique; logLik = sigma ~ x fit"
  } else if (cell == "collin_sigma_near") {
    ## z = x + 1e-6 e, so span(1, x, z) = span(1, x, e) with e = (z - x) / 1e-6:
    ## fit the well-conditioned equivalent and map back
    e <- (d$z - d$x) / 1e-6
    o <- gls_ref(y, X1, cbind(1, d$x, e), seed)
    ## g0 + g1 x + g2 z = g0 + (g1 + g2) x + g2 * 1e-6 e  =>  g2 = c_e / 1e-6, g1 = c_x - g2
    g2 <- o$par[5] / 1e-6; g1 <- o$par[4] - g2
    o_red <- gls_ref(y, X1, X1, seed)
    info$ref_ll <- -o$value
    info$ref_par <- paste(signif(c(o$par[1:3], g1, g2), 8), collapse = ";")
    info$note <- sprintf("full-model MLE in original coords: g1=%.4g g2=%.4g; reduced (sigma~x) ll=%.8f; gain=%.4g",
                         g1, g2, -o_red$value, -o$value + o_red$value)
  }
  res[[i]] <- data.frame(row[, c("k", "cell", "rep", "nominal_seed", "r_seed", "file", "n")],
                         ref_ll = info$ref_ll, ref_par = info$ref_par, ref_nloc = info$ref_nloc,
                         ref_second_gap = info$ref_second_gap, mle_exists = info$mle_exists,
                         boundary = info$boundary, note = info$note, stringsAsFactors = FALSE)
  if (i %% 50 == 0) cat(i, "of", nrow(idx), "\n")
}
res <- do.call(rbind, res)
dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)
write.csv(res, out, row.names = FALSE)
cat("wrote", out, "\n")
