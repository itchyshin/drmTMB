## Skeptic probes for F8a (independent re-check). Run from this directory:
##   Rscript skeptic_scope.R > skeptic_scope.out 2>&1
suppressPackageStartupMessages(library(drmTMB))
cat("drmTMB", format(packageVersion("drmTMB")), "\n"); print(sessionInfo())
cap <- function(expr) { w <- character(); v <- withCallingHandlers(expr, warning = function(c) { w <<- c(w, conditionMessage(c)); invokeRestart("muffleWarning") }); list(v = v, w = w) }
d3 <- read.csv(file.path("..", "..", "data", "pois_n8_lowmean_r03.csv"))

## (a) Rep 3 from a user start of (0, 0): WHY is it 'degenerate'? (pdHess vs NaN cov.fixed)
r <- cap(drmTMB(bf(y ~ x), family = poisson(), data = d3,
  control = drm_control(start = list("fixef:mu:(Intercept)" = 0, "fixef:mu:x" = 0))))
f <- r$v
cat("\n(a) rep 3 start (0,0): pdHess", f$sdr$pdHess, "| opt code", f$opt$convergence, f$opt$message,
    "| par", signif(f$opt$par, 6), "| status", convergence_status(f), "\n")
cat("    cov.fixed:\n"); print(f$sdr$cov.fixed)
chk <- check_drm(f); print(as.data.frame(chk)[chk$status != "ok", c("check", "status")], row.names = FALSE)
cat("    fit-time warnings:", paste(unique(substr(r$w, 1, 90)), collapse = " || "), "\n")

## (b) glm.fit warm start on all-zero y depends on n (22 iterations at n = 8; maxit = 25 reached for larger n)
for (n in c(8, 30, 80, 300)) {
  g <- cap(stats::glm.fit(cbind(1, seq_len(n) / n), rep(0, n), family = stats::poisson()))
  cat(sprintf("(b) glm.fit all-zero n=%3d: iter %d, b0 %.8f, warnings: %s\n", n, g$v$iter, g$v$coefficients[1],
      if (length(g$w)) paste(unique(g$w), collapse = " | ") else "none"))
}

one <- function(lab, d, f = bf(y ~ x)) {
  r <- cap(drmTMB(f, family = poisson(), data = d)); fit <- r$v
  se <- sqrt(diag(vcov(fit))); chk <- check_drm(fit)
  cat(sprintf("%-38s est (%s) SE (%s) status %s ok %s warnings %d | %s\n", lab,
    paste(signif(fit$opt$par, 4), collapse = ", "), paste(signif(se, 3), collapse = ", "),
    convergence_status(fit), isTRUE(attr(chk, "ok")), length(r$w),
    chk$value[chk$check == "standard_errors_inflated"]))
}
## (c) all-zero y at larger n: still silent?
cat("\n")
set.seed(1); for (n in c(30, 80, 300)) one(sprintf("(c) all-zero y, n = %d", n), data.frame(y = 0L, x = rnorm(n)))
## (d) PARTIAL nonexistence (one factor level with all-zero counts): is it caught?
set.seed(2); g <- factor(rep(c("a", "b", "c"), each = 20)); y <- rpois(60, c(a = 2, b = 3, c = 0)[as.character(g)])
cat("\n(d) level c all zero:", all(y[g == "c"] == 0), "\n")
one("(d) y ~ g (level c all zero)", data.frame(y = y, g = g), bf(y ~ g))
one("(d) y ~ 0 + g (level c all zero)", data.frame(y = y, g = g), bf(y ~ 0 + g))
