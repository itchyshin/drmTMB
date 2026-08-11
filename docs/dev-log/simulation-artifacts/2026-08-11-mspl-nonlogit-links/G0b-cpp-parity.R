# G0b — does the COMPILED TMB MSPL penalty match the R kernels, per link?
#
# G0 verified R/mspl.R's kernels against glm()/brglm2. This checks the other
# implementation: the `use_mspl == 1` block in src/drmTMB.cpp. Until 2026-08-11
# that block hardcoded the logit working weight with no link_code branch, so a
# probit/cloglog fit would have been penalised as logit -- see
# BLOCKER-tmb-mspl-is-logit-only.md.
#
# Method: build one TMB object per link via the ordinary drmTMB path, then call
# obj$report(par) on a SWEEP of beta values that push eta deep into both tails,
# and compare TMB's reported mspl_jeffreys against mspl_jeffreys() in R at the
# same beta. Comparing at the optimum only would miss tail divergence, which is
# exactly where the penalty does its work.
#
# Usage: Rscript --no-init-file G0b-cpp-parity.R --src <pkg dir>

args <- commandArgs(trailingOnly = TRUE)
getarg <- function(k, d = NULL) { i <- match(k, args); if (is.na(i)) d else args[i + 1L] }
SRC <- getarg("--src", ".")

suppressMessages(pkgload::load_all(SRC, quiet = TRUE))
options(drmTMB.mspl_evidence_unsafe = TRUE)   # evidence-only bypass

stopifnot("estimator" %in% names(formals(drmTMB::drmTMB)))

set.seed(20260811)
G <- 12L; n_per <- 10L
block <- factor(rep(seq_len(G), each = n_per))
N <- length(block)
trt <- rep(c(0, 1), length.out = N)
u <- rnorm(G, sd = 0.7)

links <- c("logit", "probit", "cloglog")
# eta multipliers: 1 = ordinary, then progressively deeper separation rays.
# 40 and 200 drive the weight to underflow, which is the regime the log-scale
# code exists for.
scales <- c(0, 1, 2, 5, 10, 40, 200)

rows <- list()
for (lk in links) {
  d <- data.frame(
    y = rbinom(N, 1, binomial(link = lk)$linkinv(-0.5 + 1.0 * trt + u[block])),
    trt = trt, block = block
  )
  # Build the object WITHOUT optimising: fit with 0 iterations is not exposed,
  # so fit normally and reuse the returned TMB object for the sweep.
  fit <- try(drmTMB(bf(y ~ trt + (1 | block)), family = binomial(link = lk),
                    data = d, estimator = "mspl"), silent = TRUE)
  if (inherits(fit, "try-error")) {
    rows[[length(rows) + 1L]] <- data.frame(
      link = lk, scale = NA_real_, tmb = NA_real_, r = NA_real_,
      abs_diff = NA_real_, rel_diff = NA_real_,
      note = gsub("[[:space:]]+", " ", conditionMessage(attr(fit, "condition"))))
    next
  }
  obj <- fit$obj
  X   <- fit$spec_X_mu %||% NULL
  # Recover the design and offset the estimator itself used.
  sp  <- fit$mspl
  Xm  <- model.matrix(~ trt, data = d)
  par <- obj$env$last.par.best
  bi  <- which(names(par) == "beta_mu")
  stopifnot(length(bi) == ncol(Xm))
  b_hat <- par[bi]
  # Direction: push the slope, keep the intercept, so eta spreads in both tails.
  dir <- c(0, 1)
  for (s in scales) {
    p2 <- par
    p2[bi] <- b_hat + s * dir
    rep_tmb <- obj$report(p2)
    tmb_j <- as.numeric(rep_tmb$mspl_jeffreys)
    r_ref <- mspl_jeffreys(
      X = Xm, beta = as.numeric(p2[bi]), offset = rep(0, nrow(Xm)),
      trials = rep(1L, nrow(Xm)), frequency = rep(1L, nrow(Xm)), link = lk
    )
    r_j <- if (isTRUE(r_ref$ok)) as.numeric(r_ref$half_logdet) else NA_real_
    rows[[length(rows) + 1L]] <- data.frame(
      link = lk, scale = s, tmb = tmb_j, r = r_j,
      abs_diff = abs(tmb_j - r_j),
      rel_diff = abs(tmb_j - r_j) / pmax(abs(r_j), 1e-300),
      note = if (isTRUE(r_ref$ok)) "" else paste0("R:", r_ref$code))
  }
}

res <- do.call(rbind, rows)
print(res, digits = 10)

ok <- res[is.finite(res$rel_diff), ]
cat("\n--- SUMMARY ---\n")
for (lk in links) {
  s <- ok[ok$link == lk, ]
  if (!nrow(s)) { cat(sprintf("%-8s NO COMPARABLE ROWS\n", lk)); next }
  cat(sprintf("%-8s n=%d  max abs=%.3e  max rel=%.3e  %s\n", lk, nrow(s),
              max(s$abs_diff), max(s$rel_diff),
              if (max(s$rel_diff) < 1e-8) "PASS" else "**FAIL**"))
}
saveRDS(res, file.path(dirname(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]) %||% "."), "G0b-parity.rds"))
