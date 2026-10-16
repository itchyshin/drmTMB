## F5-tiny-n-gaussian: minimal self-contained repro for drmTMB (data regenerated from seeds).
## sweep-oct16 t4 cell gauss_n8, rep r: R seed 933663568 + r - 1 (= nominal 20261016400 + r - 1, mod 2^31).
## Run:  Rscript f5_min_drmTMB.R > f5_min_drmTMB.out 2>&1
suppressPackageStartupMessages(library(drmTMB))
cat(R.version.string, "| drmTMB", as.character(packageVersion("drmTMB")), "| TMB", as.character(packageVersion("TMB")), "\n")
gen <- function(r) {
  RNGkind("Mersenne-Twister", "Inversion", "Rejection"); set.seed(933663568L + r - 1L)
  x <- rnorm(8); data.frame(y = 1 + 0.5 * x + exp(-0.4 + 0.3 * x) * rnorm(8), x = x)
}
ll <- function(th, d) sum(dnorm(d$y, th[1] + th[2] * d$x, exp(th[3] + th[4] * d$x), log = TRUE))
fit <- function(d, ...) suppressWarnings(drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = d,
                                                control = drm_control(...)))
## (a) two local maxima; default start ends on the lower one
glob <- list(`5`  = c(0.62897981, 1.85913573, -1.4548979, -3.0420365),
             `9`  = c(0.57975945, 0.01155896, -1.3209085,  2.0000361),
             `28` = c(1.55547165, 0.42682448, -3.0166713, -2.7533529))
for (r in c(5, 9, 28)) {
  d <- gen(r); f <- fit(d); m <- fit(d, multi_start = 10)
  cat(sprintf("r%02d default logLik %.5f, is_converged %s, status %s, max|grad| %.1e | multi_start=10 %.5f (%s) | exact ll at the other maximum %.5f\n",
              r, logLik(f), is_converged(f), convergence_status(f), max(abs(f$gradient)),
              logLik(m), convergence_status(m), ll(glob[[as.character(r)]], d)))
}
## (b) finite maximum below the default log-sigma clamp band
for (r in c(4, 31)) {
  d <- gen(r); f <- fit(d); u <- fit(d, logsigma_clamp = NULL)
  th <- unlist(fixef(f)); thu <- unlist(fixef(u))
  cat(sprintf("r%02d default logLik %.5f (is_converged %s, status %s; min raw log sigma %.2f) | clamp = NULL: logLik %.5f, is_converged %s, min log sigma %.2f\n",
              r, logLik(f), is_converged(f), convergence_status(f), min(th[3] + th[4] * d$x),
              logLik(u), is_converged(u), min(thu[3] + thu[4] * d$x)))
  chk <- check_drm(f); cat("    default check_drm rows not ok:", paste0(chk$check, "=", chk$status)[chk$status != "ok"], "\n")
}
## (c) unbounded likelihood (no MLE): default fit reports converged
for (r in c(6, 19)) {
  d <- gen(r); f <- fit(d)
  cat(sprintf("r%02d default logLik %.5f, is_converged %s, status %s\n", r, logLik(f), is_converged(f), convergence_status(f)))
}
