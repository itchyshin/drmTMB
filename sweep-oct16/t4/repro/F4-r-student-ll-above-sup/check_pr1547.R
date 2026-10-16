## F4-r-student-ll-above-sup -- OFF-PIN check: same 50 CSVs on the open fix PR head
## drmTMB PR #1547 head 569bd9182e364d3c8890bc75d8150f77b3f9db14 (stacked on #1504 af2ee2501),
## installed into a scratch library (NOT the pinned build). Usage, from this directory:
##   Rscript check_pr1547.R <scratch_lib> > check_pr1547.out 2>&1
lib <- commandArgs(trailingOnly = TRUE)[1]
suppressPackageStartupMessages(library(drmTMB, lib.loc = lib))
options(width = 200, digits = 10)
ddir <- "../../data"
gauss_ml <- function(d) { r <- resid(lm(y ~ x, d)); n <- nrow(d); -n / 2 * (log(2 * pi * mean(r^2)) + 1) }
ll_dt <- function(d, p) { nu <- 2 + exp(p[4]); z <- (d$y - p[1] - p[2] * d$x) / exp(p[3]); sum(dt(z, nu, log = TRUE) - p[3]) }
cat("drmTMB", as.character(packageVersion("drmTMB", lib.loc = lib)), "from", find.package("drmTMB"), "\n")
## boundary datasets from repro_drmTMB.out (dt() profile below the Gaussian ML for nu in 2.5..1e7)
interior <- c(1, 2, 8, 9, 13, 16, 28, 29, 31, 34, 37, 41, 42, 49)
rows <- list()
for (r in 1:50) {
  d <- read.csv(file.path(ddir, sprintf("student_gaussdata_r%02d.csv", r)))
  w <- character()
  f <- withCallingHandlers(drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = student(), data = d),
         warning = function(cond) { w <<- c(w, conditionMessage(cond)); invokeRestart("muffleWarning") })
  if (r == 1) cat("fit$provenance$git_sha:", f$provenance$git_sha, "| dirty:", f$provenance$git_dirty, "\n\n")
  p <- unname(f$opt$par)
  rows[[r]] <- data.frame(rep = r, boundary = !(r %in% interior), eta_nu = p[4], opt_code = f$opt$convergence,
    is_conv = is_converged(f), status = convergence_status(f), pdHess = isTRUE(f$sdr$pdHess),
    excess_vs_gauss = as.numeric(logLik(f)) - gauss_ml(d), reported_minus_exact = as.numeric(logLik(f)) - ll_dt(d, p),
    warn = paste(unique(substr(w, 1, 50)), collapse = " | "))
}
tab <- do.call(rbind, rows); print(tab, digits = 6, row.names = FALSE)
B <- tab$boundary
cat("\nboundary datasets:", sum(B), "\n")
cat("  reported logLik > Gaussian ML + 1e-8:", sum(B & tab$excess_vs_gauss > 1e-8), "| > 1e-6:", sum(B & tab$excess_vs_gauss > 1e-6), "\n")
cat("  max excess over Gaussian ML:", format(max(tab$excess_vs_gauss[B]), digits = 3), "\n")
cat("  max |reported - exact dt() at own estimates|:", format(max(abs(tab$reported_minus_exact[B])), digits = 3), "\n")
cat("  is_converged TRUE:", sum(B & tab$is_conv), "| status table:\n"); print(table(tab$status[B]))
cat("  eta_nu range:", format(range(tab$eta_nu[B]), digits = 4), "\n")
cat("interior datasets: max |reported - exact| =", format(max(abs(tab$reported_minus_exact[!B])), digits = 3), "\n\n")
print(sessionInfo())
