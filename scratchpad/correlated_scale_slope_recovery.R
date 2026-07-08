# (1) q12 engine piece: CORRELATED residual-scale intercept+slope block
#     `sigma ~ x + (1 + x | id)`  (new C++ same-dpar conditioning, model_type == 1).
# CORRECTNESS GATE: recover a KNOWN (sd_int, sd_slope, rho) on the sigma side.
# A silent mis-specification (wrong conditioning order / wrong pair index) would show
# up as a biased or sign-flipped correlation, or a collapsed slope SD.
suppressPackageStartupMessages({devtools::load_all(".", quiet = TRUE); library(parallel)})
Sys.setenv(OPENBLAS_NUM_THREADS = "1")

truth <- c(sd_sig_int = 0.50, sd_sig_slope = 0.30, cor_sig = 0.50)
S <- chol(matrix(c(.5^2, .5 * .5 * .3, .5 * .5 * .3, .3^2), 2, 2))

sim <- function(n_id, n_each, seed) {
  set.seed(seed * 3181L + n_id * 7L + n_each)
  b <- matrix(rnorm(n_id * 2), n_id, 2) %*% S   # (b_int, b_slope) per id, cor 0.5
  u_mu <- rnorm(n_id, 0, 0.4)
  id <- rep(seq_len(n_id), each = n_each); n <- n_id * n_each; x <- rnorm(n)
  log_sig <- log(0.5) + 0.2 * x + b[id, 1] + b[id, 2] * x
  y <- 0.3 + 0.5 * x + u_mu[id] + rnorm(n, 0, exp(log_sig))
  d <- data.frame(y = y, x = x, id = factor(id))
  f <- tryCatch(suppressWarnings(drmTMB(bf(y ~ x + (1 | id), sigma ~ x + (1 + x | id)),
         gaussian(), d, control = drm_control(optimizer_preset = "robust"))),
       error = function(e) NULL)
  if (is.null(f)) return(NULL)
  pr <- summary(f)$parameters
  sig_sds <- pr$estimate[grepl("^sd:sigma", pr$parm)]
  cor_rows <- pr$estimate[grepl("^cor", pr$parm) & grepl("sigma", pr$parm)]
  if (length(sig_sds) < 2L || length(cor_rows) < 1L) return(NULL)
  data.frame(n_id = n_id, n_each = n_each, seed = seed,
    par = names(truth), truth = truth,
    est = c(sig_sds[1], sig_sds[2], cor_rows[1]),
    pd = isTRUE(f$sdr$pdHess), conv = f$opt$convergence, row.names = NULL)
}

g <- expand.grid(seed = 1:12, n_each = c(10L, 20L), n_id = c(80L, 150L))
res <- do.call(rbind, mcmapply(sim, g$n_id, g$n_each, g$seed, SIMPLIFY = FALSE, mc.cores = 8))
if (is.null(res)) stop("all fits failed")
m <- function(z) mean(z, na.rm = TRUE)
cat("=== correlated sigma intercept+slope RECOVERY (truth sd_int=.50 sd_slope=.30 rho=+.50) ===\n")
for (ni in c(80L, 150L)) for (ne in c(10L, 20L)) {
  s <- res[res$n_id == ni & res$n_each == ne, ]
  if (!nrow(s)) next
  cat(sprintf("n_id=%-4d n_each=%-3d  pdHess %.2f conv0 %.2f | ", ni, ne,
      m(s$pd[s$par == "cor_sig"]), m(s$conv[s$par == "cor_sig"] == 0)))
  for (p in names(truth)) {
    ss <- s[s$par == p, ]
    cat(sprintf("%s %+.3f (bias %+.3f)  ", p, m(ss$est), m(ss$est) - truth[[p]]))
  }
  cat("\n")
}
cat("\nVERDICT: all three should track truth with bias -> 0 as n grows.\n")
cat("CORRELATED SCALE SLOPE RECOVERY DONE\n")
