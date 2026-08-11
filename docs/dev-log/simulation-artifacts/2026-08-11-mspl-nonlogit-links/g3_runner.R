# G3 — MSPL standard-error calibration, all four link/orientation conditions.
#
# Grid, seeds, endpoints and bands frozen in PREREGISTRATION-G3-SE.md.
#
# Every replicate emits a row whatever happens. Retention is an ENDPOINT
# (prereg §2b): the scorer must be able to see a cell where MSPL reports
# convergence == 0 and carries no standard error, which is exactly the case the
# 2026-08-09 campaign filtered away and lost.
#
# Usage: Rscript g3_runner.R --lib <lib> --out <tsv> [--cell N] [--rfrom A] [--rto B]

args <- commandArgs(trailingOnly = TRUE)
getarg <- function(k, d = NULL) { i <- match(k, args); if (is.na(i)) d else args[i + 1L] }
SRC   <- getarg("--src", ".")
LIB   <- getarg("--lib", "")
OUT   <- getarg("--out", "g3_raw.tsv")
ONLY  <- getarg("--cell", NA)
RFROM <- as.integer(getarg("--rfrom", "1"))
RTO   <- as.integer(getarg("--rto", "1000"))

if (nzchar(LIB)) {
  .libPaths(c(LIB, .libPaths()))
  suppressMessages(library(drmTMB))
} else {
  suppressMessages(devtools::load_all(SRC, quiet = TRUE))
}
if (!"estimator" %in% names(formals(drmTMB::drmTMB))) {
  stop("STALE BUILD: drmTMB() has no `estimator` formal.")
}
options(drmTMB.mspl_evidence_unsafe = TRUE)
suppressMessages(library(glmmTMB))

ETA_D <- list(
  logit            = c(0, -2, -4, -6, -10),
  probit           = c(0, -1.2, -2.1, -3, -4.2),
  cloglog_standard = c(0, -2, -3.5, -5, -7),
  cloglog_mirrored = c(0, -2.4, -4.2, -6, -8.4)
)
CONDITIONS <- c("logit", "probit", "cloglog_standard", "cloglog_mirrored")
link_of  <- function(cond) if (cond %in% c("cloglog_standard","cloglog_mirrored")) "cloglog" else cond
mirrored <- function(cond) identical(cond, "cloglog_mirrored")

# prereg §4: q1 gets G in {12,30}; q2 gets G = 30 only.
grid <- do.call(rbind, lapply(CONDITIONS, function(cond)
  rbind(
    do.call(rbind, lapply(ETA_D[[cond]], function(e)
      data.frame(cond = cond, q = "q1", eta_d = e, G = c(12L, 30L), stringsAsFactors = FALSE))),
    do.call(rbind, lapply(ETA_D[[cond]], function(e)
      data.frame(cond = cond, q = "q2", eta_d = e, G = 30L, stringsAsFactors = FALSE))))))
grid$cell <- seq_len(nrow(grid))
stopifnot(nrow(grid) == 60L)
# Regime split is per-link (prereg §4): the two SHALLOWEST eta_d are identified.
grid$regime <- unlist(lapply(seq_len(nrow(grid)), function(i) {
  e <- sort(ETA_D[[grid$cond[i]]], decreasing = TRUE)
  if (grid$eta_d[i] %in% e[1:2]) "identified" else "separated"
}))
if (!is.na(ONLY)) grid <- grid[grid$cell == as.integer(ONLY), , drop = FALSE]

simulate_cell <- function(cond, q, eta_d, G, seed, n_per = 10L) {
  set.seed(seed)
  inv <- stats::binomial(link = link_of(cond))$linkinv
  block <- factor(rep(seq_len(G), each = n_per)); N <- length(block)
  if (q == "q1") {
    trt <- rep(c(0, 1), length.out = N); u <- rnorm(G, sd = 0.7)
    y <- rbinom(N, 1, inv(eta_d + 1.0 * trt + u[block]))
    if (mirrored(cond)) y <- 1L - y
    list(d = data.frame(y = y, trt = trt, block = block), target = "trt")
  } else {
    x <- rnorm(N); u0 <- rnorm(G, sd = 0.7); u1 <- rnorm(G, sd = 0.4)
    y <- rbinom(N, 1, inv(eta_d + 1.0 * x + u0[block] + u1[block] * x))
    if (mirrored(cond)) y <- 1L - y
    list(d = data.frame(y = y, x = x, block = block), target = "x")
  }
}

na1 <- function(x, f = NA_real_) if (is.null(x) || length(x) != 1L) f else x
flat <- function(s) if (is.null(s) || length(s) != 1L || is.na(s)) "" else
  gsub("[[:space:]]+", " ", trimws(substr(as.character(s), 1, 160)))

# bf() uses NSE, so the formula must appear literally (2026-08-09 harness bug 1).
fit_drm <- function(q, d, est, lk) {
  if (q == "q1")
    drmTMB(bf(y ~ trt + (1 | block)), family = binomial(link = lk), data = d, estimator = est)
  else
    drmTMB(bf(y ~ x + (1 + x | block)), family = binomial(link = lk), data = d, estimator = est)
}
fit_glmmtmb <- function(q, d, lk) {
  if (q == "q1")
    glmmTMB(y ~ trt + (1 | block), family = binomial(link = lk), data = d)
  else
    glmmTMB(y ~ x + (1 + x | block), family = binomial(link = lk), data = d)
}

one_drm <- function(sim, q, est, lk) {
  tryCatch({
    f <- fit_drm(q, sim$d, est, lk)
    v <- suppressWarnings(sqrt(diag(vcov(f))))
    nm <- paste0("mu:", sim$target)
    list(ok = TRUE,
         beta = na1(coef(f, "mu")[[sim$target]]),
         se   = if (nm %in% names(v)) v[[nm]] else NA_real_,
         conv = as.integer(na1(f$opt$convergence, NA_integer_)),
         err = NA_character_)
  }, error = function(e) list(ok = FALSE, beta = NA_real_, se = NA_real_,
                              conv = NA_integer_, err = conditionMessage(e)))
}
one_glmmtmb <- function(sim, q, lk) {
  tryCatch({
    f <- fit_glmmtmb(q, sim$d, lk)
    cf <- summary(f)$coefficients$cond
    list(ok = TRUE,
         beta = na1(unname(cf[sim$target, "Estimate"])),
         se   = na1(unname(cf[sim$target, "Std. Error"])),
         conv = as.integer(na1(f$fit$convergence, NA_integer_)),
         err = NA_character_)
  }, error = function(e) list(ok = FALSE, beta = NA_real_, se = NA_real_,
                              conv = NA_integer_, err = conditionMessage(e)))
}

rows <- list()
for (i in seq_len(nrow(grid))) {
  g  <- grid[i, ]
  lk <- link_of(g$cond)
  for (r in RFROM:RTO) {
    seed <- 20260813 + 100000 * g$cell + r          # prereg §4, frozen
    sim  <- simulate_cell(g$cond, g$q, g$eta_d, g$G, seed)
    ev   <- mean(sim$d$y)
    res <- list(mspl = one_drm(sim, g$q, "mspl", lk),
                ml   = one_drm(sim, g$q, "ml",   lk),
                glmmtmb = one_glmmtmb(sim, g$q, lk))
    for (en in names(res)) {
      f <- res[[en]]
      rows[[length(rows) + 1L]] <- data.frame(
        cell = g$cell, cond = g$cond, link = lk, mirrored = mirrored(g$cond),
        q = g$q, eta_d = g$eta_d, G = g$G, regime = g$regime, rep = r, seed = seed,
        engine = en, event_rate = ev,
        ok = f$ok, beta = f$beta, se = f$se, conv = f$conv,
        # Endpoint: reported success but no usable SE (prereg §3).
        se_missing = isTRUE(f$ok) && (is.na(f$se) || !is.finite(f$se)),
        err = flat(f$err), stringsAsFactors = FALSE)
    }
  }
}
out <- do.call(rbind, rows)
write.table(out, OUT, sep = "\t", row.names = FALSE, quote = FALSE)
cat("wrote", nrow(out), "rows to", OUT, "\n")
