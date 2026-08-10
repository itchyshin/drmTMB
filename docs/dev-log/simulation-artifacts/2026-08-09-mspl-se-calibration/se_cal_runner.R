#!/usr/bin/env Rscript
# MSPL SE-calibration campaign runner.
# Pre-registration: docs/dev-log/simulation-artifacts/2026-08-09-mspl-se-calibration/
suppressMessages({library(drmTMB); library(lme4); library(glmmTMB)})

args <- commandArgs(trailingOnly = TRUE)
getarg <- function(k, d = NULL) { i <- match(k, args); if (is.na(i)) d else args[i + 1L] }
MODE   <- getarg("--mode", "smoke")
NREP   <- as.integer(getarg("--nrep", "5"))
OUT    <- getarg("--out", "/tmp/se_cal_out.tsv")
ONLY   <- getarg("--cell", NA)
RFROM  <- as.integer(getarg("--repfrom", "1"))
RTO    <- as.integer(getarg("--repto", as.character(NREP)))

# ---- the frozen grid (prereg sec 4) -------------------------------------
grid <- rbind(
  expand.grid(q = "q1", eta_d = c(0, -2, -4, -6, -10), G = c(12, 30),
              stringsAsFactors = FALSE),
  expand.grid(q = "q2", eta_d = c(0, -2, -4, -6, -10), G = 30,
              stringsAsFactors = FALSE)
)
grid$cell <- seq_len(nrow(grid))
if (!is.na(ONLY)) grid <- grid[grid$cell == as.integer(ONLY), , drop = FALSE]

simulate_cell <- function(q, eta_d, G, seed) {
  set.seed(seed)
  n_per <- 10L
  block <- factor(rep(seq_len(G), each = n_per))
  N <- length(block)
  if (q == "q1") {
    trt <- rep(c(0, 1), length.out = N)
    u   <- rnorm(G, sd = 0.7)
    eta <- eta_d + 1.0 * trt + u[block]
    d   <- data.frame(y = rbinom(N, 1, plogis(eta)), trt = trt, block = block)
    list(d = d, fml = y ~ trt + (1 | block), target = "trt")
  } else {
    x  <- rnorm(N)
    u0 <- rnorm(G, sd = 0.7); u1 <- rnorm(G, sd = 0.4)
    eta <- eta_d + 1.0 * x + u0[block] + u1[block] * x
    d   <- data.frame(y = rbinom(N, 1, plogis(eta)), x = x, block = block)
    list(d = d, fml = y ~ x + (1 + x | block), target = "x")
  }
}

# NOTE: bf() uses NSE. `bf(fml)` where `fml` is a formula VARIABLE fails with
# "`drm_formula()` inputs must be formulas". The formula must appear LITERALLY,
# so the two cell shapes are branched here rather than passed as an object.
# (Verified on Totoro: the variable form errors, the literal form fits.)
fit_drm <- function(q, d, est) {
  if (q == "q1") {
    drmTMB(bf(y ~ trt + (1 | block)), family = binomial(link = "logit"),
           data = d, estimator = est)
  } else {
    drmTMB(bf(y ~ x + (1 + x | block)), family = binomial(link = "logit"),
           data = d, estimator = est)
  }
}

fit_one <- function(sim, q, engine) {
  tryCatch({
    if (engine == "glmmTMB") {
      f <- glmmTMB(sim$fml, family = binomial(), data = sim$d)
      list(est = fixef(f)$cond[[sim$target]],
           se  = sqrt(diag(vcov(f)$cond))[[sim$target]],
           conv = as.integer(f$fit$convergence), ok = TRUE)
    } else if (engine == "glmer") {
      f  <- glmer(sim$fml, family = binomial(), data = sim$d, nAGQ = 1)
      list(est = fixef(f)[[sim$target]],
           se  = sqrt(diag(as.matrix(vcov(f))))[[sim$target]],
           conv = 0L, ok = TRUE)
    } else {
      f  <- fit_drm(q, sim$d, if (engine == "mspl") "mspl" else "ml")
      v  <- sqrt(diag(vcov(f)))
      nm <- paste0("mu:", sim$target)
      list(est  = coef(f, "mu")[[sim$target]],
           se   = if (nm %in% names(v)) v[[nm]] else NA_real_,
           conv = as.integer(f$opt$convergence), ok = TRUE)
    }
  }, error = function(e) list(est = NA_real_, se = NA_real_, conv = NA_integer_,
                              ok = FALSE, msg = conditionMessage(e)))
}

rows <- list()
for (i in seq_len(nrow(grid))) {
  g <- grid[i, ]
  for (r in RFROM:RTO) {
    seed <- 20260809 + 100000 * g$cell + r          # prereg sec 4, frozen
    sim  <- simulate_cell(g$q, g$eta_d, g$G, seed)
    for (eng in c("mspl", "ml", "glmer", "glmmTMB")) {
      f <- fit_one(sim, g$q, eng)
      rows[[length(rows) + 1L]] <- data.frame(
        cell = g$cell, q = g$q, eta_d = g$eta_d, G = g$G, rep = r, seed = seed,
        engine = eng, est = f$est, se = f$se, conv = f$conv, ok = f$ok,
        event_rate = mean(sim$d$y), stringsAsFactors = FALSE)
    }
  }
  cat(sprintf("cell %d/%d (%s eta_d=%g G=%d) done\n", i, nrow(grid), g$q, g$eta_d, g$G))
  flush(stdout())
}
res <- do.call(rbind, rows)
write.table(res, OUT, sep = "\t", row.names = FALSE, quote = FALSE)
cat("\nwrote", nrow(res), "rows ->", OUT, "\n")
