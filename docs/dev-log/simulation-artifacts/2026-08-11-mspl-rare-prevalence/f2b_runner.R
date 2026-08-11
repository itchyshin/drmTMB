# F2b — clean cells at the target prevalence, gated on EXPECTED EVENT COUNT.
# Runner. Derived from f2_runner.R; only the grid and the seed base differ.
# Derived from f1_runner.R. Differences: q1 only, n_per varies, eta_d in {-6,-8},
# G in {30,100}. Everything else -- endpoints, NA handling, the stale-build
# assertion, the whitespace flattening -- is F1's, unchanged and for the same reasons.
# Grid, seeds and endpoints are frozen in PREREGISTRATION.md. Do not edit either
# after the first replicate.
#
# Usage:
#   Rscript f1_runner.R --src <pkg dir> --out <tsv> [--cell N] [--rfrom A] [--rto B]

args <- commandArgs(trailingOnly = TRUE)
getarg <- function(k, d = NULL) { i <- match(k, args); if (is.na(i)) d else args[i + 1L] }
SRC   <- getarg("--src", ".")
LIB   <- getarg("--lib", "")
OUT   <- getarg("--out", "f1_raw.tsv")
ONLY  <- getarg("--cell", NA)
RFROM <- as.integer(getarg("--rfrom", "1"))
RTO   <- as.integer(getarg("--rto", "500"))

# Two load paths, deliberately.
#
# --lib: a library holding drmTMB INSTALLED FROM THE CAMPAIGN SHA. This is the
#   Totoro path. 100 workers each calling load_all() would race on the same
#   src/*.o and *.so, so the package is compiled ONCE and workers only attach it.
#   Safe here because this runner touches nothing internal -- drmTMB(), bf(),
#   coef(), vcov() are exported and fit$mspl is a plain field.
#
# --src: devtools::load_all(). The local path.
#
# Either way the version is asserted below. A STALE build is the failure mode
# that cost the 2026-08-09 E1 probe a run and this campaign's own pre-run test:
# it presents as "`drmTMB()` does not use arguments in `...` yet", because
# `estimator=` falls through to `...` in a build predating the MSPL merge.
if (nzchar(LIB)) {
  .libPaths(c(LIB, .libPaths()))
  suppressMessages(library(drmTMB))
} else {
  suppressMessages(devtools::load_all(SRC, quiet = TRUE))
}
if (!"estimator" %in% names(formals(drmTMB::drmTMB))) {
  stop("STALE BUILD: drmTMB() has no `estimator` formal. Rebuild from the campaign SHA.")
}

# prereg sec 3. eta_d <= -10 is EXCLUDED: the calibration probe found 57-100% of
# those replicates have zero events, i.e. total separation, where the slope is not
# identified by any estimator and a finite estimate measures the penalty alone.
# Addendum F2b. eta_d held at -8 (pins prevalence ~8e-4 independent of design);
# N varied to sweep expected events 1.58 -> 2.40 -> 3.34 at 21.3% -> 9.3% -> 3.0%
# zero-event. Gating on event count is F2's own finding applied to F2's own flaw.
grid <- expand.grid(eta_d = -8, G = 100L, n_per = c(20L, 30L, 40L),
                    stringsAsFactors = FALSE)
grid$q <- "q1"
grid <- grid[order(grid$n_per), ]
grid$cell <- seq_len(nrow(grid))
if (!is.na(ONLY)) grid <- grid[grid$cell == as.integer(ONLY), , drop = FALSE]

simulate_cell <- function(q, eta_d, G, seed, n_per = 10L) {
  set.seed(seed)
  block <- factor(rep(seq_len(G), each = n_per))
  N <- length(block)
  if (q == "q1") {
    trt <- rep(c(0, 1), length.out = N)
    u   <- rnorm(G, sd = 0.7)
    d <- data.frame(y = rbinom(N, 1, plogis(eta_d + 1.0 * trt + u[block])),
                    trt = trt, block = block)
    list(d = d, target = "trt")
  } else {
    x  <- rnorm(N)
    u0 <- rnorm(G, sd = 0.7); u1 <- rnorm(G, sd = 0.4)
    d <- data.frame(y = rbinom(N, 1, plogis(eta_d + 1.0 * x + u0[block] + u1[block] * x)),
                    x = x, block = block)
    list(d = d, target = "x")
  }
}

# bf() uses NSE: passing a formula VARIABLE fails with "`drm_formula()` inputs
# must be formulas". The literal must appear, so branch rather than pass an object.
fit_drm <- function(q, d, est) {
  if (q == "q1") {
    drmTMB(bf(y ~ trt + (1 | block)), family = binomial(link = "logit"),
           data = d, estimator = est)
  } else {
    drmTMB(bf(y ~ x + (1 + x | block)), family = binomial(link = "logit"),
           data = d, estimator = est)
  }
}

na1 <- function(x, f = NA_real_) if (is.null(x) || length(x) != 1L) f else x

# Error/message text carries embedded newlines and tabs (drmTMB uses multi-line
# cli messages, e.g. the "Refit with drm_control(se = TRUE)" hint). Written raw
# into a tab-separated file with quote = FALSE, those SHATTER the table: the
# first run produced 25,887 lines for 20,000 fits and R message text appeared in
# the `estimator` column. Flatten before writing.
flat <- function(s) {
  if (is.null(s) || length(s) != 1L || is.na(s)) return("")
  gsub("[[:space:]]+", " ", trimws(substr(as.character(s), 1, 200)))
}

fit_one <- function(sim, q, est) {
  tryCatch({
    f  <- fit_drm(q, sim$d, est)
    v  <- suppressWarnings(sqrt(diag(vcov(f))))
    nm <- paste0("mu:", sim$target)
    m  <- f$mspl
    list(
      beta = na1(coef(f, "mu")[[sim$target]]),
      se   = if (nm %in% names(v)) v[[nm]] else NA_real_,
      conv = as.integer(na1(f$opt$convergence, NA_integer_)),
      # Primary endpoints (prereg sec 5). Absent => NA => scored as FAILURE,
      # never dropped: E1's first scorer filtered with is.finite() and removed
      # exactly the values that were the evidence.
      fi_finite_pos = if (is.null(m)) NA else isTRUE(m$fixed_information_finite_positive),
      logdet_fi     = if (is.null(m)) NA_real_ else na1(m$final_logdet_fixed_information),
      hess_pd       = if (is.null(m)) NA else isTRUE(m$numerical$hessian_positive_definite),
      hess_mineig   = if (is.null(m)) NA_real_ else na1(m$numerical$hessian_min_eigenvalue),
      pen_obj       = if (is.null(m)) NA_real_ else na1(m$penalized_objective),
      unpen_obj     = if (is.null(m)) NA_real_ else na1(m$unpenalized_laplace_objective),
      ident_err     = if (is.null(m)) NA_real_ else na1(m$objective_identity_error),
      c_n           = if (is.null(m)) NA_real_ else na1(m$c_n),
      n_eff         = if (is.null(m)) NA_real_ else na1(m$n_eff),
      err = NA_character_)
  }, error = function(e) list(
      beta = NA_real_, se = NA_real_, conv = NA_integer_, fi_finite_pos = NA,
      logdet_fi = NA_real_, hess_pd = NA, hess_mineig = NA_real_, pen_obj = NA_real_,
      unpen_obj = NA_real_, ident_err = NA_real_, c_n = NA_real_, n_eff = NA_real_,
      err = conditionMessage(e)))
}

rows <- list()
for (i in seq_len(nrow(grid))) {
  g <- grid[i, ]
  for (r in RFROM:RTO) {
    seed <- 20260812 + 100000 * g$cell + r          # addendum F2b, frozen
    sim  <- simulate_cell(g$q, g$eta_d, g$G, seed, g$n_per)
    for (est in c("mspl", "ml")) {
      f <- fit_one(sim, g$q, est)
      rows[[length(rows) + 1L]] <- data.frame(
        cell = g$cell, q = g$q, eta_d = g$eta_d, G = g$G, n_per = g$n_per,
        rep = r, seed = seed,
        estimator = est, event_rate = mean(sim$d$y),
        beta = f$beta, se = f$se, conv = f$conv,
        fi_finite_pos = f$fi_finite_pos, logdet_fi = f$logdet_fi,
        hess_pd = f$hess_pd, hess_mineig = f$hess_mineig,
        pen_obj = f$pen_obj, unpen_obj = f$unpen_obj, ident_err = f$ident_err,
        c_n = f$c_n, n_eff = f$n_eff,
        err = flat(f$err), stringsAsFactors = FALSE)
    }
  }
  cat(sprintf("cell %d (eta_d=%g G=%d n_per=%d) done\n", g$cell, g$eta_d, g$G, g$n_per))
  flush(stdout())
}
res <- do.call(rbind, rows)
write.table(res, OUT, sep = "\t", row.names = FALSE, quote = FALSE)
cat("\nwrote", nrow(res), "rows ->", OUT, "\n")
