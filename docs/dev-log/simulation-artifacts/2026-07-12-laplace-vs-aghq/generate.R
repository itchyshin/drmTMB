# Laplace vs AGHQ, and RE-SD bias vs sample size.
# Model: binomial random intercept y ~ x + (1 | id), Bernoulli (trials=1) -- the
# hardest, most integral-biased case. drmTMB fits by Laplace; lme4::glmer gives an
# external reference: nAGQ=1 is Laplace (cross-check), nAGQ=25 is adaptive
# Gauss-Hermite quadrature (AGHQ). Two panels:
#   A. df/finite-cluster bias: vary M (clusters), fixed per-group n. AGHQ CANNOT fix
#      this (it is the REML/ML gap); expect it to shrink as M grows -> "sample size".
#   B. integral/Laplace bias: fixed M, vary per-group n. AGHQ (nAGQ=25) removes the
#      per-cluster Laplace error; expect glmer-AGHQ closer to truth than either
#      Laplace fit, gap largest at small n.
suppressWarnings(suppressMessages(devtools::load_all(".", quiet = TRUE)))
suppressWarnings(suppressMessages(library(lme4)))
Sys.setenv(OPENBLAS_NUM_THREADS = "1")
options(warn = -1)

SD_TRUE <- 0.8
B0 <- -0.2; B1 <- 0.7

sim_one <- function(seed, M, n_each) {
  set.seed(seed)
  id <- factor(rep(seq_len(M), each = n_each)); n <- length(id)
  x <- stats::rnorm(n)
  u <- stats::rnorm(M, sd = SD_TRUE); u <- u - mean(u)
  p <- stats::plogis(B0 + B1 * x + u[id])
  y <- stats::rbinom(n, 1, p)
  d <- data.frame(y = y, succ = y, fail = 1 - y, x = x, id = id)
  out <- c(drm = NA, gL = NA, gA = NA)
  fit <- tryCatch(drmTMB(bf(cbind(succ, fail) ~ x + (1 | id)), family = binomial(), data = d),
                  error = function(e) NULL)
  if (!is.null(fit) && isTRUE(fit$opt$convergence == 0) && isTRUE(fit$sdr$pdHess))
    out["drm"] <- unname(fit$sdpars$mu[["(1 | id)"]])
  gL <- tryCatch(glmer(y ~ x + (1 | id), family = binomial, data = d, nAGQ = 1),
                 error = function(e) NULL)
  if (!is.null(gL)) out["gL"] <- as.data.frame(VarCorr(gL))$sdcor[1]
  gA <- tryCatch(glmer(y ~ x + (1 | id), family = binomial, data = d, nAGQ = 25),
                 error = function(e) NULL)
  if (!is.null(gA)) out["gA"] <- as.data.frame(VarCorr(gA))$sdcor[1]
  out
}

run_cell <- function(M, n_each, seeds) {
  res <- do.call(rbind, parallel::mclapply(seeds, sim_one, M = M, n_each = n_each,
                                            mc.cores = 6))
  colMeans_na <- function(v) mean(v, na.rm = TRUE)
  data.frame(
    M = M, n_each = n_each, n_seeds = length(seeds),
    drm_sd   = round(colMeans_na(res[, "drm"]), 4),
    glmerL_sd = round(colMeans_na(res[, "gL"]), 4),
    glmerA_sd = round(colMeans_na(res[, "gA"]), 4),
    drm_relbias   = round((colMeans_na(res[, "drm"]) - SD_TRUE) / SD_TRUE, 4),
    glmerL_relbias = round((colMeans_na(res[, "gL"]) - SD_TRUE) / SD_TRUE, 4),
    glmerA_relbias = round((colMeans_na(res[, "gA"]) - SD_TRUE) / SD_TRUE, 4)
  )
}

SEEDS <- 20260800L + seq_len(80L)

cat("== Panel A: df/finite-cluster bias -- vary M, n_each=8 fixed ==\n")
A <- do.call(rbind, lapply(c(8L, 16L, 32L, 64L, 128L), run_cell, n_each = 8L, seeds = SEEDS))
print(A[, c("M","drm_sd","glmerL_sd","glmerA_sd","drm_relbias","glmerA_relbias")], row.names = FALSE)

cat("\n== Panel B: integral/Laplace bias -- M=40 fixed, vary n_each ==\n")
B <- do.call(rbind, lapply(c(2L, 4L, 8L, 20L), run_cell, M = 40L, seeds = SEEDS))
print(B[, c("n_each","drm_sd","glmerL_sd","glmerA_sd","drm_relbias","glmerL_relbias","glmerA_relbias")], row.names = FALSE)

outdir <- "docs/dev-log/simulation-artifacts/2026-07-12-laplace-vs-aghq"
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
write.table(rbind(A, B), file.path(outdir, "laplace-vs-aghq.tsv"),
            sep = "\t", row.names = FALSE, quote = FALSE)
cat("\nWROTE", file.path(outdir, "laplace-vs-aghq.tsv"), "\nDONE\n")
