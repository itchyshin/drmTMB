# G1 — TMB-Laplace finiteness for MSPL, probit and cloglog. Runner.
#
# Grid, seeds and endpoints are frozen in PREREGISTRATION.md; the eta_d values
# for the three non-logit conditions are frozen in S3-CALIBRATION.md. Do not
# edit either after the first replicate.
#
# Extends f1_runner.R (2026-08-10) by link and response orientation. Everything
# f1_runner.R got right is kept verbatim, including the two load paths, the
# STALE BUILD assertion, the NSE branch in fit_drm(), and flat().
#
# Usage:
#   Rscript g1_runner.R --src <pkg dir> --out <tsv> [--cell N] [--rfrom A] [--rto B]
#   Rscript g1_runner.R --lib <lib dir> --out <tsv> ...

args <- commandArgs(trailingOnly = TRUE)
getarg <- function(k, d = NULL) { i <- match(k, args); if (is.na(i)) d else args[i + 1L] }
SRC   <- getarg("--src", ".")
LIB   <- getarg("--lib", "")
OUT   <- getarg("--out", "g1_raw.tsv")
ONLY  <- getarg("--cell", NA)
RFROM <- as.integer(getarg("--rfrom", "1"))
RTO   <- as.integer(getarg("--rto", "500"))

# Two load paths, deliberately -- see f1_runner.R for why. --lib is the Totoro
# path (compile once, 100 workers attach); --src is devtools::load_all() locally.
if (nzchar(LIB)) {
  .libPaths(c(LIB, .libPaths()))
  suppressMessages(library(drmTMB))
} else {
  suppressMessages(devtools::load_all(SRC, quiet = TRUE))
}
if (!"estimator" %in% names(formals(drmTMB::drmTMB))) {
  stop("STALE BUILD: drmTMB() has no `estimator` formal. Rebuild from the campaign SHA.")
}
# G1-specific staleness check: a build predating the link-dispatch fix would
# compute a LOGIT penalty for probit/cloglog and return plausible wrong numbers
# (BLOCKER-tmb-mspl-is-logit-only.md). The evidence bypass is the marker for it.
options(drmTMB.mspl_evidence_unsafe = TRUE)
local({
  d <- data.frame(y = c(0, 1, 0, 1, 1, 0), trt = c(0, 0, 1, 1, 0, 1),
                  block = factor(c(1, 1, 2, 2, 3, 3)))
  ok <- tryCatch({
    drmTMB(bf(y ~ trt + (1 | block)), family = binomial(link = "probit"),
           data = d, estimator = "mspl"); TRUE
  }, error = function(e) conditionMessage(e))
  if (!isTRUE(ok)) {
    stop("STALE BUILD: probit MSPL is still rejected -- this build predates the ",
         "link-dispatch fix. Rebuild from the campaign SHA. Message: ", ok)
  }
})

# ---- the frozen grid -------------------------------------------------------
# eta_d: logit from F1 (prereg 5.2, reused verbatim); the other three from
# S3-CALIBRATION.md, which is frozen.
ETA_D <- list(
  logit            = c(0, -2, -4, -6, -10),
  probit           = c(0, -1.2, -2.1, -3, -4.2),
  cloglog_standard = c(0, -2, -3.5, -5, -7),
  cloglog_mirrored = c(0, -2.4, -4.2, -6, -8.4)
)
CONDITIONS <- c("logit", "probit", "cloglog_standard", "cloglog_mirrored")
link_of  <- function(cond) if (cond %in% c("cloglog_standard", "cloglog_mirrored")) "cloglog" else cond
mirrored <- function(cond) identical(cond, "cloglog_mirrored")

# Main grid: cond x q x eta_d x G, ordered so cells 1-80 match prereg 5.4's
# "link x q x eta_d x G order".
main <- do.call(rbind, lapply(CONDITIONS, function(cond)
  do.call(rbind, lapply(c("q1", "q2"), function(q)
    do.call(rbind, lapply(ETA_D[[cond]], function(e)
      data.frame(cond = cond, q = q, eta_d = e, G = c(12L, 30L),
                 n_per = 10L, corner = FALSE, stringsAsFactors = FALSE)))))))
# Adversarial corner: the TWO DEEPEST eta_d of each condition, q1, G = 400.
corner <- do.call(rbind, lapply(CONDITIONS, function(cond) {
  deep <- sort(ETA_D[[cond]])[1:2]          # two most negative
  data.frame(cond = cond, q = "q1", eta_d = deep, G = 400L,
             n_per = 10L, corner = TRUE, stringsAsFactors = FALSE)
}))
grid <- rbind(main, corner)
grid$cell <- seq_len(nrow(grid))
stopifnot(nrow(grid) == 88L)
if (!is.na(ONLY)) grid <- grid[grid$cell == as.integer(ONLY), , drop = FALSE]

# ---- DGP (prereg 5.1) ------------------------------------------------------
simulate_cell <- function(cond, q, eta_d, G, n_per, seed) {
  set.seed(seed)
  lk <- link_of(cond)
  inv <- stats::binomial(link = lk)$linkinv
  block <- factor(rep(seq_len(G), each = n_per))
  N <- length(block)
  if (q == "q1") {
    trt <- rep(c(0, 1), length.out = N)
    u   <- rnorm(G, sd = 0.7)
    y   <- rbinom(N, 1, inv(eta_d + 1.0 * trt + u[block]))
    if (mirrored(cond)) y <- 1L - y           # y* = m - y, same link
    list(d = data.frame(y = y, trt = trt, block = block), target = "trt")
  } else {
    x  <- rnorm(N)
    u0 <- rnorm(G, sd = 0.7); u1 <- rnorm(G, sd = 0.4)
    y  <- rbinom(N, 1, inv(eta_d + 1.0 * x + u0[block] + u1[block] * x))
    if (mirrored(cond)) y <- 1L - y
    list(d = data.frame(y = y, x = x, block = block), target = "x")
  }
}

# bf() uses NSE: a formula VARIABLE fails, so branch rather than pass an object.
fit_drm <- function(q, d, est, lk) {
  if (q == "q1") {
    drmTMB(bf(y ~ trt + (1 | block)), family = binomial(link = lk),
           data = d, estimator = est)
  } else {
    drmTMB(bf(y ~ x + (1 + x | block)), family = binomial(link = lk),
           data = d, estimator = est)
  }
}

na1 <- function(x, f = NA_real_) if (is.null(x) || length(x) != 1L) f else x

# drmTMB uses multi-line cli messages; written raw into a TSV with quote = FALSE
# they SHATTER the table (F1's first run: 25,887 lines for 20,000 fits). Flatten.
flat <- function(s) {
  if (is.null(s) || length(s) != 1L || is.na(s)) return("")
  gsub("[[:space:]]+", " ", trimws(substr(as.character(s), 1, 200)))
}

fit_one <- function(sim, q, est, lk) {
  tryCatch({
    f  <- fit_drm(q, sim$d, est, lk)
    v  <- suppressWarnings(sqrt(diag(vcov(f))))
    nm <- paste0("mu:", sim$target)
    m  <- f$mspl
    list(
      beta = na1(coef(f, "mu")[[sim$target]]),
      se   = if (nm %in% names(v)) v[[nm]] else NA_real_,
      conv = as.integer(na1(f$opt$convergence, NA_integer_)),
      # Absent => NA => scored as FAILURE, never dropped (prereg 6): E1's first
      # scorer filtered with is.finite() and removed exactly the evidence.
      fi_finite_pos = if (is.null(m)) NA else isTRUE(m$fixed_information_finite_positive),
      logdet_fi     = if (is.null(m)) NA_real_ else na1(m$final_logdet_fixed_information),
      hess_pd       = if (is.null(m)) NA else isTRUE(m$numerical$hessian_positive_definite),
      pen_obj       = if (is.null(m)) NA_real_ else na1(m$penalized_objective),
      ident_err     = if (is.null(m)) NA_real_ else na1(m$objective_identity_error),
      c_n           = if (is.null(m)) NA_real_ else na1(m$c_n),
      n_eff         = if (is.null(m)) NA_real_ else na1(m$n_eff),
      # Guard against a silently logit-penalised run: fit$mspl$link must equal
      # the link we asked for.
      rep_link      = if (is.null(m)) NA_character_ else na1(m$link, NA_character_),
      err = NA_character_)
  }, error = function(e) list(
      beta = NA_real_, se = NA_real_, conv = NA_integer_, fi_finite_pos = NA,
      logdet_fi = NA_real_, hess_pd = NA, pen_obj = NA_real_, ident_err = NA_real_,
      c_n = NA_real_, n_eff = NA_real_, rep_link = NA_character_,
      err = conditionMessage(e)))
}

rows <- list()
for (i in seq_len(nrow(grid))) {
  g  <- grid[i, ]
  lk <- link_of(g$cond)
  for (r in RFROM:RTO) {
    seed <- 20260811 + 100000 * g$cell + r          # prereg 5.4, frozen
    sim  <- simulate_cell(g$cond, g$q, g$eta_d, g$G, g$n_per, seed)
    ev   <- mean(sim$d$y)
    for (est in c("mspl", "ml")) {
      f <- fit_one(sim, g$q, est, lk)
      rows[[length(rows) + 1L]] <- data.frame(
        cell = g$cell, cond = g$cond, link = lk, mirrored = mirrored(g$cond),
        q = g$q, eta_d = g$eta_d, G = g$G, corner = g$corner, rep = r,
        seed = seed, estimator = est, event_rate = ev,
        beta = f$beta, se = f$se, conv = f$conv,
        fi_finite_pos = f$fi_finite_pos, logdet_fi = f$logdet_fi,
        hess_pd = f$hess_pd, pen_obj = f$pen_obj, ident_err = f$ident_err,
        c_n = f$c_n, n_eff = f$n_eff, rep_link = f$rep_link,
        err = flat(f$err), stringsAsFactors = FALSE)
    }
  }
}
out <- do.call(rbind, rows)
write.table(out, OUT, sep = "\t", row.names = FALSE, quote = FALSE)
cat("wrote", nrow(out), "rows to", OUT, "\n")
