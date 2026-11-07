# A single-seed numerical sensitivity pilot, not a calibration campaign.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L || dir.exists(args[[1L]])) stop("Supply a fresh output directory")
out <- args[[1L]]
lib <- Sys.getenv("DRMTMB_SD_TEST_LIBRARY")
if (!nzchar(lib)) stop("Set DRMTMB_SD_TEST_LIBRARY")
.libPaths(c(lib, .libPaths()))
library(drmTMB)
stopifnot(identical(normalizePath(find.package("drmTMB")),
                    normalizePath(file.path(lib, "drmTMB"))))
source("tools/general-sd-regression/scalar-binomial-reference.R")
source("tests/testthat/helper-binomial-sd-regression.R")
dir.create(out, recursive = TRUE)
writeLines(capture.output(sessionInfo()), file.path(out, "sessionInfo.txt"))
files <- c("tools/general-sd-regression/run-reference-pilot.R",
           "tools/general-sd-regression/scalar-binomial-reference.R",
           "tests/testthat/helper-binomial-sd-regression.R",
           getLoadedDLLs()[["drmTMB"]][["path"]],
           file.path(find.package("drmTMB"), "R", c("drmTMB.rdb", "drmTMB.rdx")))
write.csv(data.frame(file = files, sha256 = vapply(files, function(p) {
  digest::digest(file = p, algo = "sha256")
}, character(1))), file.path(out, "source-hashes.csv"), row.names = FALSE)
# This seed is predeclared in the original feasibility pilot, not selected by outcome.
dat <- binomial_sd_fixture(seed = 1120801948L)$data
fit <- drmTMB(bf(y ~ x + (1 | id), sd(id) ~ w), binomial(), dat)
start <- c(unname(coef(fit, "mu")), unname(coef(fit, "sd(id)")))
native <- -as.numeric(logLik(fit))
oracle <- binomial_sd_laplace_oracle(dat, start[1:2], start[3:4])
stopifnot(abs(native - oracle) < 1e-6)
saveRDS(list(par = start, nll = native, health = check_drm(fit)),
        file.path(out, "native-point.rds"))
rows <- split(seq_len(nrow(dat)), dat$id)
evaluations <- 0L
reference <- function(par, tol = 1e-8, reverse_sd = FALSE) {
  evaluations <<- evaluations + 1L
  if (evaluations %% 10L == 0L) writeLines(as.character(evaluations),
                                         file.path(out, "evaluations.txt"))
  sum(vapply(rows, function(i) {
    w <- dat$w[i[[1L]]]
    if (reverse_sd) w <- -w
    sd <- exp(par[[3L]] + par[[4L]]*w)
    -scalar_binomial_log_marginal(dat$y[i], rep(1, length(i)),
                                  par[[1L]] + par[[2L]]*dat$x[i], sd,
                                  rel.tol = tol)$log_marginal
  }, numeric(1L)))
}
clock <- proc.time()[["elapsed"]]
at_start <- reference(start)
tight <- reference(start, 1e-10)
stopifnot(abs(at_start - tight) < 1e-6)
wrong <- reference(start, reverse_sd = TRUE)
stopifnot(abs(wrong - at_start) > 0.01)
write.csv(data.frame(native_laplace_nll = native, independent_laplace_nll = oracle,
                     adaptive_nll_at_laplace_mle = at_start,
                     tighter_adaptive_nll = tight, wrong_group_index_nll = wrong),
           file.path(out, "point-comparison.csv"), row.names = FALSE)
lower <- c(-5, -5, -4, -2); upper <- c(5, 5, 2, 2)
quad <- optim(start, reference, method = "L-BFGS-B", lower = lower, upper = upper,
               control = list(maxit = 100, factr = 1e5, pgtol = 1e-6))
eps <- 1e-4
gradient <- vapply(seq_along(start), function(j) {
  a <- b <- quad$par; a[[j]] <- a[[j]] + eps; b[[j]] <- b[[j]] - eps
  (reference(a, 1e-10) - reference(b, 1e-10))/(2*eps)
}, numeric(1L))
boundary <- any(quad$par <= lower + 1e-5 | quad$par >= upper - 1e-5)
write.csv(data.frame(parameter = c("mu:(Intercept)", "mu:x", "sd(id):(Intercept)", "sd(id):w"),
                     laplace = start, adaptive = quad$par,
                     difference = quad$par - start, adaptive_gradient = gradient),
           file.path(out, "parameter-comparison.csv"), row.names = FALSE)
receipt <- list(seed = 1120801948L, groups = 160L, repeats = 16L,
                alpha = c(log(0.8), 0.5), evaluations = evaluations,
                convergence = quad$convergence, boundary = boundary,
                max_abs_gradient = max(abs(gradient)),
                adaptive_nll = quad$value, elapsed = proc.time()[["elapsed"]] - clock,
                numerical_bounds = list(lower = lower, upper = upper),
                calibration_claim = FALSE)
saveRDS(receipt, file.path(out, "receipt.rds"))
dput(receipt, file = file.path(out, "receipt.R"))
print(receipt)
if (quad$convergence != 0 || boundary || max(abs(gradient)) > 1e-3) {
  stop("Adaptive-reference optimizer did not pass its numerical checks")
}
cat("ADAPTIVE_REFERENCE_PILOT_PASS\n")
