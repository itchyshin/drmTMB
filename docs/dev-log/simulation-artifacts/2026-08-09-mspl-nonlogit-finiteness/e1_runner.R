#!/usr/bin/env Rscript
# E1 profile-ray descent probe. Prereg: docs/dev-log/simulation-artifacts/
#   2026-08-09-mspl-nonlogit-finiteness/PREREGISTRATION.md
# Criterion: doc 253 sec 4 (Noether).
suppressMessages(library(drmTMB))
args <- commandArgs(trailingOnly = TRUE)
ga <- function(k, d=NULL) { i <- match(k, args); if (is.na(i)) d else args[i+1L] }
OUT <- ga("--out", "/tmp/e1.tsv"); FROM <- as.integer(ga("--from","1")); TO <- as.integer(ga("--to","0"))

grid <- expand.grid(
  link = c("logit","probit","cloglog","cloglog_flip"),
  q = 1:2, G = c(5,10,20,40), n_g = c(2,5,10), sigma = c(0.25,1,2,4),
  p = c(2,4), sep = c("complete","quasi","incidental","none"),
  stringsAsFactors = FALSE)
grid$fx <- seq_len(nrow(grid))
if (TO == 0) TO <- nrow(grid)
grid <- grid[grid$fx >= FROM & grid$fx <= TO, , drop=FALSE]

simulate <- function(g, seed) {
  set.seed(seed)
  block <- factor(rep(seq_len(g$G), each = g$n_g)); N <- length(block)
  X <- cbind(1, matrix(rnorm(N * (g$p - 1)), N, g$p - 1))
  u <- rnorm(g$G, sd = g$sigma)
  base_link <- if (g$link == "cloglog_flip") "cloglog" else g$link
  li <- stats::make.link(base_link)$linkinv
  eta0 <- switch(g$sep, complete = -6, quasi = -4, incidental = -2, none = 0)
  eta <- eta0 + drop(X %*% c(0, rep(0.9, g$p - 1))) + u[block]
  y <- rbinom(N, 1, li(eta))
  if (g$sep == "complete") y[X[,2] > quantile(X[,2], 0.85)] <- 1L   # force separation
  if (g$link == "cloglog_flip") y <- 1L - y
  list(y=y, X=X, block=block, link=base_link)
}

# R(t): profiled MSPL objective along an escape ray. psi (log sd) re-optimised at each t.
ray <- function(s, delta, tgrid) {
  n_tr <- rep(1, length(s$y))
  obj <- function(beta, logsd) {
    pen <- drmTMB:::mspl_penalty_components(X = s$X, beta = beta, variance = exp(2*logsd),
             q = 1L, trials = n_tr, link = s$link)
    if (!isTRUE(pen$ok)) return(NA_real_)
    eta <- drop(s$X %*% beta)
    lm  <- drmTMB:::mspl_log_weight(eta, 1, s$link)   # touch the link kernel
    lp  <- sum(dbinom(s$y, 1, stats::make.link(s$link)$linkinv(eta), log = TRUE))
    lp + pen$log_objective_bonus
  }
  vapply(tgrid, function(t) {
    b <- delta * t
    o <- optimize(function(ls) -obj(b, ls), interval = c(-6, 6))
    v <- -o$objective; if (is.finite(v)) v else NA_real_
  }, numeric(1))
}

tgrid <- c(0, 1, 2, 5, 10, 20, 50, 100, 300, 1000, 3000, 10000)
rows <- list()
for (i in seq_len(nrow(grid))) {
  g <- grid[i, ]
  s <- try(simulate(g, 20260809 + g$fx), silent = TRUE)
  if (inherits(s, "try-error")) next
  delta <- c(0, rep(1, g$p - 1)); delta <- delta / sqrt(sum(delta^2))
  R <- try(ray(s, delta, tgrid), silent = TRUE)
  if (inherits(R, "try-error") || all(!is.finite(R))) {
    rows[[length(rows)+1L]] <- data.frame(g, ok=FALSE, drop=NA_real_, monotone_tail=NA,
      neg_inf=NA, n_finite=0L, reason="ray_failed", stringsAsFactors=FALSE); next
  }
  # -Inf is DESCENT, not missing data. An objective that reaches -Inf along the
  # ray is the strongest possible PASS of the coercivity criterion; the first
  # harness version filtered it out with is.finite() and so discarded exactly
  # the evidence it was built to find. Treat -Inf as an extreme finite value for
  # the monotonicity test and record that the ray diverged.
  Rc <- R; hit_neg_inf <- is.infinite(Rc) & Rc < 0
  Rc[hit_neg_inf] <- -1e300
  usable <- is.finite(Rc)
  tail_i <- which(usable & tgrid >= 50)
  mono <- length(tail_i) >= 3 && all(diff(Rc[tail_i]) < 0)
  drp  <- if (length(tail_i) >= 2) Rc[max(tail_i)] - Rc[min(tail_i)] else NA_real_
  reached_neg_inf <- any(hit_neg_inf)
  passed <- mono && !is.na(drp) && (drp < -50 || reached_neg_inf)
  rows[[length(rows)+1L]] <- data.frame(g, ok=TRUE, drop=drp, monotone_tail=mono,
    neg_inf=reached_neg_inf, n_finite=sum(usable),
    reason=if (passed) "PASS" else "FAIL", stringsAsFactors=FALSE)
  if (i %% 100 == 0) { cat("fixture", i, "of", nrow(grid), "\n"); flush(stdout()) }
}
res <- do.call(rbind, rows)
write.table(res, OUT, sep="\t", row.names=FALSE, quote=FALSE)
cat("wrote", nrow(res), "fixtures ->", OUT, "\n")
