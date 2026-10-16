## F3-r-complete-separation: minimal repro (drmTMB, default ML path).
## Complete separation in a fixed-effect logistic fit is reported as
## converged = TRUE, status "converged", no warning, check_drm() ok = TRUE.
## Run from this directory:  Rscript repro_drmTMB.R > repro_drmTMB.out 2>&1
suppressPackageStartupMessages(library(drmTMB))
cat("drmTMB", as.character(packageVersion("drmTMB")), "\n")
cat("R", R.version.string, "\n\n")

## Data: lane t4 cell bin_complete (k = 7), rep 1.
## Nominal seed 20261016400 + 100 * (7 - 1) + (1 - 1) = 20261017000; R uses seed %% 2^31.
seed <- as.integer(20261017000 %% 2^31)
RNGkind("Mersenne-Twister", "Inversion", "Rejection")
set.seed(seed)
x <- rnorm(50)
d <- data.frame(y = as.integer(x > 0), x = x)   # complete separation at x = 0
csv <- read.csv("../../data/bin_complete_r01.csv")
cat("R seed:", seed, "; regenerated data equal to CSV:",
    isTRUE(all.equal(d, csv, tolerance = 1e-12)), "\n")
cat("n =", nrow(d), "; successes =", sum(d$y), "; max x among failures =",
    format(max(d$x[d$y == 0])), "; min x among successes =", format(min(d$x[d$y == 1])), "\n\n")

warns <- character()
fit <- withCallingHandlers(
  drmTMB(bf(y ~ x), family = binomial(), data = d),
  warning = function(w) { warns <<- c(warns, conditionMessage(w)); invokeRestart("muffleWarning") }
)
cat("fit-time warnings:", length(warns), "\n")
cat("coef(mu):\n"); print(fixef(fit)$mu)
se <- sqrt(diag(vcov(fit)))
cat("SE:\n"); print(se)
cat("logLik:", format(as.numeric(logLik(fit)), digits = 6), "(supremum is 0; MLE does not exist)\n")
cat("opt$convergence:", fit$opt$convergence, "; opt$message:", fit$opt$message, "\n")
cat("sdr$pdHess:", fit$sdr$pdHess, "\n")
cat("is_converged():", is_converged(fit), "\n")
cat("is_converged(include_hessian = TRUE):", is_converged(fit, include_hessian = TRUE), "\n")
cat("convergence_status():", convergence_status(fit), "\n\n")
chk <- check_drm(fit)
cat("check_drm() ok attr:", attr(chk, "ok"), "\n")
cat("check_drm() rows not 'ok':", sum(chk$status != "ok"), "\n")
print(as.data.frame(chk)[chk$check %in% c("standard_errors_inflated", "hessian_conditioning",
  "standard_errors_finite", "convergence_status"), c("check", "status", "value")], right = FALSE)

cat("\n-- why the SE-inflation guard stays silent (R/check.R:1340-1350) --\n")
cat("all finite SEs >= floor 50, so the reference falls back to min(SE) =", format(min(se)),
    "; flag needs SE >= 1000 * min(SE) =", format(1000 * min(se)),
    "; max(SE)/min(SE) =", format(max(se) / min(se)), "\n")

cat("\n-- base R glm() on the same data, for contrast --\n")
g <- withCallingHandlers(glm(y ~ x, family = binomial(), data = d),
  warning = function(w) { cat("glm WARNING:", conditionMessage(w), "\n"); invokeRestart("muffleWarning") })
print(coef(summary(g)))

cat("\n-- contrast: quasi-complete cell bin_quasi (k = 8), rep 1 --\n")
set.seed(as.integer(20261017100 %% 2^31))
xq <- rnorm(50); yq <- as.integer(xq > 0); xq[1:10] <- 0; yq[1:10] <- c(0L, 1L, rbinom(8, 1, 0.5))
dq <- data.frame(y = yq, x = xq)
cat("regenerated equal to CSV:", isTRUE(all.equal(dq, read.csv("../../data/bin_quasi_r01.csv"), tolerance = 1e-12)), "\n")
fq <- suppressWarnings(drmTMB(bf(y ~ x), family = binomial(), data = dq))
print(sqrt(diag(vcov(fq))))
cat("is_converged():", is_converged(fq), "; convergence_status():", convergence_status(fq), "\n")
cq <- check_drm(fq)
print(as.data.frame(cq)[cq$status != "ok", c("check", "status", "value")], right = FALSE)
cat("(caught only because the intercept SE < 50 gives a small reference scale)\n\n")
sessionInfo()
