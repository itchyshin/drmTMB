## F2 mechanism: why drmTMB's beta_family() fit reports nlminb "false convergence (8)" at phi ~ 1e4.
## Run from this directory:  Rscript f2_mechanism.R > f2_mechanism.out 2>&1
## Data: sweep-oct16/t4 cell beta_phi1e4, reps 1..50 (nominal seeds 20261017300..20261017349).
suppressPackageStartupMessages({ library(drmTMB); library(TMB); library(Rmpfr) })
cat("drmTMB", as.character(packageVersion("drmTMB")), "| TMB", as.character(packageVersion("TMB")), "\n")
rd <- function(r) read.csv(sprintf("../../data/beta_phi1e4_r%02d.csv", r))
fitb <- function(d, ...) suppressWarnings(drmTMB(bf(y ~ x, sigma ~ 1), family = beta_family(), data = d, ...))
nll_exact <- function(p, d, prec = 256) {       # 256-bit MPFR, drmTMB parameterisation incl. the 1e-12 mu nudge
  X <- cbind(1, d$x); eta <- mpfr(drop(X %*% p[1:2]), prec)
  mu <- mpfr(1e-12, prec) + (1 - 2 * mpfr(1e-12, prec)) / (1 + exp(-eta))
  phi <- exp(-2 * mpfr(p[3], prec)); a <- mu * phi; b <- (1 - mu) * phi; yy <- mpfr(d$y, prec)
  as.numeric(-sum(lgamma(a + b) - lgamma(a) - lgamma(b) + (a - 1) * log(yy) + (b - 1) * log(1 - yy)))
}
line_err <- function(fn, p0, d, j = 3, ts = seq(-1e-6, 1e-6, length.out = 41))
  sapply(ts, function(t) { p <- p0; p[j] <- p[j] + t; fn(p) - nll_exact(p, d) })

cat("\n== A. The preset ladder cannot help: all three presets retrace the same 7-iteration path (rep 15) ==\n")
f15 <- fitb(rd(15)); print(f15$optimizer_attempts[, c("attempt", "optimizer_preset", "convergence", "message", "objective")], digits = 12)
cat("nlminb iterations / evaluations of attempt 1:", f15$opt$iterations, "/", paste(f15$opt$evaluations, collapse = ","), "(default iter.max 150, eval.max 200)\n")

cat("\n== B. Newton polish trace from the raw nlminb stop (reps 15, 48, 50; polish logic of R/drmTMB.R drm_newton_polish) ==\n")
for (r in c(15, 48, 50)) {
  f <- fitb(rd(r), control = drm_control(newton_polish = FALSE)); obj <- f$obj
  par <- f$opt$par; grad <- as.numeric(obj$gr(par)); fo <- f$opt$objective
  cat(sprintf("rep %d raw: %s, max|grad| %.2e\n", r, f$opt$message, max(abs(grad))))
  for (i in 1:3) {
    he <- stats::optimHess(par, obj$fn, obj$gr); pn <- par - solve(he, grad)
    gn <- as.numeric(obj$gr(pn)); fn_new <- as.numeric(obj$fn(pn))
    cat(sprintf("  step %d: max|step| %.1e, TMB f_new - f_old = %+.2e, exact f_new - f_old = %+.2e, max|grad_new| %.1e -> %s\n",
        i, max(abs(pn - par)), fn_new - fo, nll_exact(pn, rd(r)) - nll_exact(par, rd(r)), max(abs(gn)),
        if (fn_new > fo + 1e-8) "REJECTED (f rose > 1e-8)" else "accepted"))
    if (fn_new > fo + 1e-8) break
    par <- pn; grad <- gn; fo <- fn_new; if (max(abs(grad)) <= 1e-8) break
  }
}

cat("\n== C. Objective noise, drmTMB obj$fn - exact, 41 points on |t| <= 1e-6 along beta_sigma (rep 15) ==\n")
for (opt in c(1, 0)) {
  invisible(TMB::config(optimize.instantly = opt, DLL = "drmTMB"))
  f <- fitb(rd(15)); e <- line_err(f$obj$fn, f$opt$par, rd(15))
  cat(sprintf("TMB optimize.instantly = %d : sd %.2e, max|err| %.2e\n", opt, sd(e), max(abs(e))))
}

cat("\n== D. Same 50 grid datasets with CppAD tape optimisation on (default) vs off ==\n")
for (opt in c(1, 0)) {
  invisible(TMB::config(optimize.instantly = opt, DLL = "drmTMB"))
  z <- t(sapply(1:50, function(r) { f <- fitb(rd(r)); c(raw = f$optimizer_attempts$convergence[1], final = f$opt$convergence) }))
  cat(sprintf("optimize.instantly = %d : raw nlminb code != 0 in reps {%s}; final code != 0 in reps {%s}\n",
      opt, paste(which(z[, "raw"] != 0), collapse = ","), paste(which(z[, "final"] != 0), collapse = ",")))
}
invisible(TMB::config(optimize.instantly = 1, DLL = "drmTMB"))

cat("\n== E. Minimal TMB model (textbook TMB dbeta(), no drmTMB code), rep 15, at drmTMB's optimum ==\n")
td <- tempfile("betamin"); dir.create(td); invisible(file.copy("betamin.cpp", td))
owd <- setwd(td); invisible(capture.output(TMB::compile("betamin.cpp"), type = "output")); dyn.load(dynlib("betamin")); setwd(owd)
d <- rd(15); p0 <- f15$opt$par
for (opt in c(1, 0)) {
  invisible(TMB::config(optimize.instantly = opt, DLL = "betamin"))
  o <- MakeADFun(list(y = d$y, X = cbind(1, d$x)), list(b = unname(p0[1:2]), ls = unname(p0[3])), DLL = "betamin", silent = TRUE)
  e <- line_err(o$fn, p0, d); er <- line_err(function(p) o$report(p)$nll, p0, d)
  cat(sprintf("optimize.instantly = %d : taped obj$fn err sd %.2e max %.2e | same template in plain double (REPORT) err sd %.2e max %.2e\n",
      opt, sd(e), max(abs(e)), sd(er), max(abs(er))))
}
cat("\nsessionInfo():\n"); print(sessionInfo())
