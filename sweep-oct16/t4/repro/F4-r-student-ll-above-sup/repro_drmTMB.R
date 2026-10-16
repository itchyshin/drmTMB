## F4-r-student-ll-above-sup -- drmTMB student() logLik above the Gaussian-limit supremum
## sweep-oct16 / t4 (edge-case grid), cell 11 "student_gaussdata"
## drmTMB pin: ca3ddefa5ea11bbfd3b765615dfbb89305d2485a (checked below via fit$provenance)
## Run from this directory:  Rscript repro_drmTMB.R > repro_drmTMB.out 2>&1
##
## DGP (t4_gen_data.R, k = 11): x ~ N(0,1), y = 1 + 0.5 x + N(0,1), n = 100.
## Seed for rep r: nominal 20261016400 + 100*(11-1) + (r-1); R uses nominal %% 2^31.
## Data: ../../data/student_gaussdata_rNN.csv (write.csv of the generated data frame).
## Model: drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = student()), nu = 2 + exp(eta_nu).

suppressPackageStartupMessages(library(drmTMB))
options(width = 200, digits = 10)
ddir <- "../../data"
r_seed <- function(r) as.integer((20261016400 + 100 * 10 + (r - 1)) %% 2^31)
gen <- function(r) {                       # exact copy of the t4 DGP for this cell
  RNGkind("Mersenne-Twister", "Inversion", "Rejection"); set.seed(r_seed(r))
  x <- rnorm(100); data.frame(y = 1 + 0.5 * x + rnorm(100), x = x)
}

## Gaussian ML logLik of y ~ x (closed form). For data whose Student profile in nu is
## monotone (checked below), this is the supremum of the Student logLik over nu.
gauss_ml <- function(d) { r <- resid(lm(y ~ x, d)); n <- nrow(d); -n / 2 * (log(2 * pi * mean(r^2)) + 1) }
## exact Student logLik at given (b0, b1, log sigma, eta_nu), two independent ways:
##  (a) R's dt(), which uses bd0()/stirlerr() and is stable for large df;
##  (b) asymptotic lgamma difference + log1p, valid for nu > ~1e3:
##      lgamma((nu+1)/2) - lgamma(nu/2) - log(nu*pi)/2 = -log(2*pi)/2 - 1/(4 nu) + 1/(24 nu^3) + O(nu^-5)
ll_dt <- function(d, p) { nu <- 2 + exp(p[4]); z <- (d$y - p[1] - p[2] * d$x) / exp(p[3])
  sum(dt(z, nu, log = TRUE) - p[3]) }
ll_series <- function(d, p) { nu <- 2 + exp(p[4]); z <- (d$y - p[1] - p[2] * d$x) / exp(p[3])
  sum(-0.5 * log(2 * pi) - 1 / (4 * nu) + 1 / (24 * nu^3) - p[3] - (nu + 1) / 2 * log1p(z^2 / nu)) }
## the kernel formula of src/drm_response_kernels.h:17-21, evaluated in plain R double
ll_kernel_R <- function(d, p) { nu <- 2 + exp(p[4]); z <- (d$y - p[1] - p[2] * d$x) / exp(p[3])
  sum(lgamma(0.5 * (nu + 1)) - lgamma(0.5 * nu) - 0.5 * log(nu * pi) - p[3] - 0.5 * (nu + 1) * log(1 + z * z / nu)) }

fit_one <- function(d) {
  w <- character()
  f <- withCallingHandlers(
    drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = student(), data = d),
    warning = function(cond) { w <<- c(w, conditionMessage(cond)); invokeRestart("muffleWarning") })
  list(fit = f, warnings = w)
}

## ---------- provenance ----------
cat("drmTMB", as.character(packageVersion("drmTMB")), "\n")
pv <- fit_one(gen(1))$fit$provenance
cat("fit$provenance: git_sha =", pv$git_sha, "| git_dirty =", pv$git_dirty, "| build_time =", pv$build_time, "\n\n")

## ---------- 1. whole cell (50 reps): frequency at this pin ----------
rows <- list()
for (r in 1:50) {
  d <- read.csv(file.path(ddir, sprintf("student_gaussdata_r%02d.csv", r)))
  stopifnot(max(abs(as.matrix(d) - as.matrix(gen(r)))) < 1e-13)   # CSV == DGP output
  res <- fit_one(d); f <- res$fit; p <- unname(f$opt$par)
  rk <- resid(lm(y ~ x, d)); xk <- mean(rk^4) / mean(rk^2)^2 - 3
  chk <- check_drm(f); snu <- chk$status[chk$check == "student_nu"]
  rows[[r]] <- data.frame(rep = r, r_seed = r_seed(r), xkurt = xk, eta_nu = p[4],
    opt_code = f$opt$convergence, is_conv = is_converged(f), status = convergence_status(f),
    pdHess = isTRUE(f$sdr$pdHess), check_ok = isTRUE(attr(chk, "ok")), student_nu = snu,
    gauss_ml = gauss_ml(d), reported = as.numeric(logLik(f)), obj_at_par = -f$obj$fn(f$opt$par),
    exact_dt = ll_dt(d, p), exact_series = ll_series(d, p), kernel_R = ll_kernel_R(d, p),
    warn = paste(unique(substr(res$warnings, 1, 60)), collapse = " | "))
}
tab <- do.call(rbind, rows)

## boundary datasets: the dt() profile logLik (max over b0, b1, log sigma at fixed nu) stays below
## the Gaussian ML on a nu grid from 2.5 to 1e7, i.e. sup over nu = Gaussian ML (nu -> Inf limit).
prof <- function(d, nu) { o <- optim(c(coef(lm(y ~ x, d)), log(sd(resid(lm(y ~ x, d))))),
  function(q) -sum(dt((d$y - q[1] - q[2] * d$x) / exp(q[3]), nu, log = TRUE) - q[3]),
  method = "BFGS", control = list(reltol = 1e-15, maxit = 5000)); -o$value }
nus <- c(2.5, 3, 5, 10, 30, 1e2, 1e3, 1e4, 1e5, 1e6, 1e7)
profs <- t(sapply(1:50, function(r) { d <- read.csv(file.path(ddir, sprintf("student_gaussdata_r%02d.csv", r)))
  sapply(nus, prof, d = d) - gauss_ml(d) }))
tab$prof_max_minus_gauss <- apply(profs, 1, max)
tab$boundary <- tab$prof_max_minus_gauss < 0
tab$excess_vs_gauss <- tab$reported - tab$gauss_ml
tab$reported_minus_exact <- tab$reported - tab$exact_dt
cat("== 1. all 50 reps ==\n")
print(tab[, c("rep", "xkurt", "boundary", "eta_nu", "opt_code", "is_conv", "status", "pdHess", "check_ok", "student_nu",
              "gauss_ml", "reported", "excess_vs_gauss", "exact_dt", "reported_minus_exact")], digits = 8, row.names = FALSE)
B <- tab$boundary; above <- B & tab$excess_vs_gauss > 1e-6
cat("\nreported logLik == -obj$fn(opt$par) for all reps:", isTRUE(all.equal(tab$reported, tab$obj_at_par, tolerance = 0)), "\n")
cat("max |exact_dt - exact_series| over reps with eta_nu > 7:",
    format(max(abs((tab$exact_dt - tab$exact_series)[tab$eta_nu > 7])), digits = 3), "\n")
cat("boundary datasets (sup = Gaussian ML):", sum(B), "of 50; interior-nu datasets:", sum(!B), "\n")
cat("  boundary: exact Student logLik at drmTMB's own estimates <= Gaussian ML in", sum(B & tab$exact_dt <= tab$gauss_ml), "of", sum(B), "\n")
cat("  boundary: reported logLik > Gaussian ML + 1e-6:", sum(above), "of", sum(B), "\n")
cat("    of these: is_converged TRUE", sum(above & tab$is_conv), "| status 'converged'", sum(above & tab$status == "converged"),
    "| check_drm ok", sum(above & tab$check_ok), "| fit-time warning", sum(above & nzchar(tab$warn)), "\n")
cat("    excess quantiles (min / median / max):", format(quantile(tab$excess_vs_gauss[above], c(0, .5, 1)), digits = 3), "\n")
cat("  boundary: reported - exact (objective error at own estimates), median:", format(median(tab$reported_minus_exact[B]), digits = 3),
    " max:", format(max(tab$reported_minus_exact[B]), digits = 3), "\n")
cat("  interior-nu datasets: max |reported - exact| =", format(max(abs(tab$reported_minus_exact[!B])), digits = 3),
    " (eta_nu range", paste(format(range(tab$eta_nu[!B]), digits = 3), collapse = " to "), ")\n\n")

## ---------- 2. the silent cases + the worst case ----------
sil <- tab[above & tab$is_conv, ]
cat("== 2. boundary datasets with converged = TRUE and logLik > Gaussian ML + 1e-6 ==\n")
print(sil[, c("rep", "r_seed", "eta_nu", "opt_code", "status", "pdHess", "check_ok", "student_nu", "gauss_ml",
              "reported", "excess_vs_gauss", "exact_dt", "reported_minus_exact", "warn")], digits = 12, row.names = FALSE)
w <- tab[which.max(tab$excess_vs_gauss), ]
cat("\nworst rep", w$rep, ": eta_nu =", w$eta_nu, " nu =", format(2 + exp(w$eta_nu), digits = 4),
    " opt_code =", w$opt_code, " is_converged =", w$is_conv, " status =", w$status,
    "\n   reported logLik =", format(w$reported, digits = 6), " Gaussian ML =", w$gauss_ml,
    " exact at same estimates =", w$exact_dt, "\n   warnings:", w$warn, "\n\n")

## ---------- 3. profile for the silent reps: the Gaussian ML is the sup ----------
cat("== 3. silent reps: dt() profile logLik minus Gaussian ML, by nu ==\n")
for (i in which(above & tab$is_conv))
  cat(sprintf("rep %2d:", tab$rep[i]), sprintf("nu=%g: %+.3e", nus, profs[i, ]), "\n")

## ---------- 4. mechanism: drmTMB objective vs exact, eta_nu scan at fixed mu, sigma (rep 4) ----------
cat("\n== 4. rep 4: -obj$fn with only eta_nu changed (mu, sigma at drmTMB's estimates) ==\n")
d <- read.csv(file.path(ddir, "student_gaussdata_r04.csv")); f <- fit_one(d)$fit; p0 <- f$opt$par
cat("Gaussian ML logLik:", format(gauss_ml(d), digits = 12), "\n")
etas <- c(5, 10, 12, 14, 15, unname(p0[4]), 16, 18, 20, 25, 30, 40, 60, 80, 100, 120)
scan <- t(sapply(etas, function(e) { p <- p0; p[4] <- e; pp <- unname(p)
  c(eta_nu = e, nu = 2 + exp(e), tmb = -f$obj$fn(p), exact_dt = ll_dt(d, pp), exact_series = ll_series(d, pp),
    kernel_in_R = ll_kernel_R(d, pp)) }))
scan <- as.data.frame(scan)
scan$tmb_minus_exact <- scan$tmb - scan$exact_dt
scan$kernelR_minus_exact <- scan$kernel_in_R - scan$exact_dt
scan$tmb_minus_gauss <- scan$tmb - gauss_ml(d)
print(scan, digits = 10, row.names = FALSE)

## ---------- 5. sensitivity: same reps fitted on the full-precision DGP output (not the CSV) ----------
cat("\n== 5. silent reps refitted on gen(r) (full double precision instead of 15-digit CSV) ==\n")
for (r in sil$rep) { d <- gen(r); f <- fit_one(d)$fit
  cat(sprintf("rep %2d: eta_nu=%.4f is_converged=%s status=%s logLik-GaussML=%+.3e\n", r, f$opt$par[4],
              is_converged(f), convergence_status(f), as.numeric(logLik(f)) - gauss_ml(d))) }

cat("\n"); print(sessionInfo())
