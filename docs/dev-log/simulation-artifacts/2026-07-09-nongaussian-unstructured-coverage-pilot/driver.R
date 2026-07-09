# Pilot coverage campaign: unstructured non-Gaussian fixed-effect (mean) intervals.
# n-ladder over binomial / poisson / beta / nbinom2. Wald channel (confint default).
# Measures finite-rate + coverage of the true mean coefficients (link scale).
.libPaths("~/Rlib")
suppressMessages({library(drmTMB); library(parallel)})

NSIM   <- as.integer(Sys.getenv("NSIM", "400"))
NCORES <- as.integer(Sys.getenv("NCORES", "90"))
NS     <- as.integer(strsplit(Sys.getenv("NS", "50,150,500"), ",")[[1]])

specs <- list(
  binomial = list(mu0 = 0.4, mu1 = 0.7, fam = quote(binomial()),
    sim = function(n, s){ set.seed(s); x <- rnorm(n)
      data.frame(y = rbinom(n, 1, plogis(0.4 + 0.7 * x)), x = x) }),
  poisson  = list(mu0 = 0.4, mu1 = 0.5, fam = quote(poisson()),
    sim = function(n, s){ set.seed(s); x <- rnorm(n)
      data.frame(y = rpois(n, exp(0.4 + 0.5 * x)), x = x) }),
  beta     = list(mu0 = 0.2, mu1 = 0.7, fam = quote(beta()),
    sim = function(n, s){ set.seed(s); x <- rnorm(n); m <- plogis(0.2 + 0.7 * x); phi <- 5
      data.frame(y = rbeta(n, m * phi, (1 - m) * phi), x = x) }),
  nbinom2  = list(mu0 = 0.6, mu1 = 0.4, fam = quote(nbinom2()),
    sim = function(n, s){ set.seed(s); x <- rnorm(n)
      data.frame(y = rnbinom(n, mu = exp(0.6 + 0.4 * x), size = 3), x = x) })
)

one <- function(sp, n, seed) {
  d <- sp$sim(n, seed)
  fit <- tryCatch(
    drmTMB(bf(y ~ x), family = eval(sp$fam), data = d, control = drm_control(se = TRUE)),
    error = function(e) NULL)
  truth <- c("fixef:mu:(Intercept)" = sp$mu0, "fixef:mu:x" = sp$mu1)
  res <- data.frame(parm = names(truth), covered = NA, finite = FALSE, width = NA_real_,
                    row.names = NULL, stringsAsFactors = FALSE)
  if (!is.null(fit)) {
    ci <- tryCatch(confint(fit), error = function(e) NULL)
    if (!is.null(ci) && "parm" %in% names(ci)) {
      for (i in seq_along(truth)) {
        row <- ci[ci$parm == names(truth)[i], , drop = FALSE]
        if (nrow(row) == 1) {
          lo <- row$lower; hi <- row$upper
          res$finite[i]  <- is.finite(lo) && is.finite(hi)
          res$covered[i] <- res$finite[i] && truth[i] >= lo && truth[i] <= hi
          res$width[i]   <- hi - lo
        }
      }
    }
  }
  res
}

grid <- expand.grid(fam = names(specs), n = NS, stringsAsFactors = FALSE)
out <- list()
for (gi in seq_len(nrow(grid))) {
  fam <- grid$fam[gi]; n <- grid$n[gi]; sp <- specs[[fam]]
  reps <- mclapply(seq_len(NSIM), function(s) one(sp, n, 100000L * gi + s), mc.cores = NCORES)
  for (p in c("fixef:mu:(Intercept)", "fixef:mu:x")) {
    cov <- vapply(reps, function(r) r$covered[r$parm == p], logical(1))
    fin <- vapply(reps, function(r) r$finite[r$parm == p], logical(1))
    wid <- vapply(reps, function(r) r$width[r$parm == p], numeric(1))
    finite_rate <- mean(fin)
    ok <- cov[fin & !is.na(cov)]
    coverage <- if (length(ok)) mean(ok) else NA_real_
    mcse <- if (length(ok)) sqrt(coverage * (1 - coverage) / length(ok)) else NA_real_
    out[[length(out) + 1]] <- data.frame(
      family = fam, n = n, param = p, nsim = NSIM,
      finite_rate = round(finite_rate, 3), coverage = round(coverage, 3),
      mcse = round(mcse, 4), mean_width = round(mean(wid[fin], na.rm = TRUE), 3))
  }
  cat(sprintf("done %s n=%d\n", fam, n))
}
res <- do.call(rbind, out)
res$clears_094 <- with(res, finite_rate >= 0.95 & (coverage + 2 * mcse) >= 0.94)
write.table(res, "~/drmTMB_work/pilot_coverage_results.tsv", sep = "\t", row.names = FALSE, quote = FALSE)
cat("\n===== PILOT COVERAGE RESULTS =====\n"); print(res, row.names = FALSE)
