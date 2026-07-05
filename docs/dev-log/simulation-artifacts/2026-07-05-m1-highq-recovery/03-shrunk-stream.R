# M1 recovery — SHRUNK, STREAMING runner (Shannon takeover, applying the
# 2026-07-05 lesson: stream+flush per fit, fast decisive fit first, heartbeat
# to a watchable .log, right-size to the question). Reuses Curie's DGP helpers.
#
# The question: does pdHess flip FALSE->TRUE and Sigma recover as n (groups)
# grows? Decisive contrast: q8 n_tip=16 (the failing case) vs n_tip=256.
#
# Run: R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 \
#   OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript --no-init-file \
#   docs/dev-log/simulation-artifacts/2026-07-05-m1-highq-recovery/03-shrunk-stream.R

suppressMessages(devtools::load_all("."))
art <- "docs/dev-log/simulation-artifacts/2026-07-05-m1-highq-recovery"
source(file.path(art, "00-helpers.R"))
tsv <- file.path(art, "03-shrunk-stream-results.tsv")
log <- file.path(art, "03-shrunk-stream.log")

hb <- function(...) { cat(sprintf(...), file = log, append = TRUE); cat(sprintf(...)) }
cols <- c("block","n_tip","n_each","n_obs","q","seed","conv","pdHess",
          "se_finite","max_abs_rho_hat","cap_saturated","rmse","max_abs_err",
          "frobenius","elapsed_s","error")
cat(paste(cols, collapse = "\t"), "\n", file = tsv)        # header once
cat(sprintf("start %s\n", format(Sys.time())), file = log)

fit_q4 <- function(dat, tree) suppressWarnings(drmTMB(bf(
  mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
  mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
  sigma1 = ~ z + phylo(1 | p | species, tree = tree),
  sigma2 = ~ z + phylo(1 | p | species, tree = tree),
  rho12 = ~1), family = biv_gaussian(), data = dat,
  control = list(eval.max = 2000, iter.max = 2000)))

fit_q8 <- function(dat, tree) suppressWarnings(drmTMB(bf(
  mu1 = y1 ~ x + phylo(1 + x | p | species, tree = tree),
  mu2 = y2 ~ x + phylo(1 + x | p | species, tree = tree),
  sigma1 = ~ z + phylo(1 + x | p | species, tree = tree),
  sigma2 = ~ z + phylo(1 + x | p | species, tree = tree),
  rho12 = ~1), family = biv_gaussian(), data = dat,
  control = list(eval.max = 2000, iter.max = 2000)))

do_one <- function(block, n_tip, n_each, seed) {
  q <- if (block == "q4") 4L else 8L
  sim <- if (block == "q4") simulate_q4_all_four(seed, n_tip, n_each)
         else simulate_q8_all_four_one_slope(seed, n_tip, n_each)
  t0 <- Sys.time()
  fit <- tryCatch(if (block == "q4") fit_q4(sim$data, sim$tree)
                  else fit_q8(sim$data, sim$tree), error = function(e) e)
  el <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  if (inherits(fit, "error")) {
    row <- c(block, n_tip, n_each, nrow(sim$data), q, seed, NA, NA, NA, NA, NA,
             NA, NA, NA, round(el,1), gsub("\t"," ",conditionMessage(fit)))
    hb("[%s] n_tip=%4d seed=%d ERROR: %s (%.1fs)\n", block, n_tip, seed,
       conditionMessage(fit), el)
  } else {
    rho_hat <- unname(fit$corpars$phylo)
    rho_true <- unname(upper_tri_vec(sim$truth$corr))
    m <- recovery_metrics(rho_hat, rho_true)
    fro <- frobenius_corr(corr_from_upper(rho_hat, q), sim$truth$corr)
    se <- suppressWarnings(sqrt(diag(fit$sdr$cov.fixed)))
    row <- c(block, n_tip, n_each, nrow(sim$data), q, seed,
             fit$opt$convergence, isTRUE(fit$sdr$pdHess), all(is.finite(se)),
             round(m$max_abs_rho_hat,4), m$cap_saturated, round(m$rmse,4),
             round(m$max_abs_err,4), round(fro,4), round(el,1), NA)
    hb("[%s] n_tip=%4d seed=%d conv=%s pdHess=%s max|rho|=%.3f rmse=%.3f frob=%.3f (%.1fs)\n",
       block, n_tip, seed, fit$opt$convergence, isTRUE(fit$sdr$pdHess),
       m$max_abs_rho_hat, m$rmse, fro, el)
  }
  cat(paste(row, collapse = "\t"), "\n", file = tsv, append = TRUE)  # STREAM+flush
  flush(stdout())
  invisible(NULL)
}

# Fast-first order: cheap decisive fits first, each streamed on completion.
do_one("q4", 64L,  8L, 20260801L)   # q4 anchor (6 corr / 64 groups): expect pdHess=TRUE
do_one("q8", 16L,  8L, 20260901L)   # q8 the FAILING case (28 corr / 16 groups): expect FALSE
do_one("q8", 64L,  8L, 20260901L)   # q8 transition
do_one("q8", 256L, 8L, 20260901L)   # q8 adequate n: expect pdHess=TRUE + recovery
do_one("q8", 16L,  8L, 20260902L)   # 2nd seed at the contrast endpoints
do_one("q8", 256L, 8L, 20260902L)
hb("done %s\n", format(Sys.time()))
