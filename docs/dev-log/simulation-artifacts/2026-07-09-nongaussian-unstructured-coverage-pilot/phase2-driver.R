# Phase-2 coverage: scale (sigma) coefficients for beta/nbinom2 using the model's
# own parameterization, plus rare-event binomial / low-count Poisson mean stress.
# Wald channel (confint default), link scale. Run on Totoro.
if (dir.exists(path.expand("~/Rlib"))) .libPaths("~/Rlib")
suppressMessages({library(drmTMB); library(parallel)})

NSIM   <- as.integer(Sys.getenv("NSIM", "400"))
NCORES <- as.integer(Sys.getenv("NCORES", "90"))
NS     <- as.integer(strsplit(Sys.getenv("NS", "150,400,800"), ",")[[1]])

specs <- list(
  # beta location-scale: phi = exp(-2 * log_sigma)  (src/drmTMB.cpp model_type 10)
  # beta location-scale: phi = exp(-2 * log_sigma)  (empirically confirmed)
  beta_ls = list(
    form = quote(bf(y ~ x, sigma ~ x)),
    fam  = quote(beta()),
    truth = c("fixef:mu:(Intercept)" = 0.2, "fixef:mu:x" = 0.7,
              "fixef:sigma:(Intercept)" = -0.7, "fixef:sigma:x" = 0.2),
    sim = function(n, s) { set.seed(s); x <- rnorm(n)
      mu <- plogis(0.2 + 0.7 * x); phi <- exp(-2 * (-0.7 + 0.2 * x))
      data.frame(y = rbeta(n, mu * phi, (1 - mu) * phi), x = x) }),
  # nbinom2 location-scale: size = exp(-2 * log_sigma)  (empirically confirmed)
  nbinom2_ls = list(
    form = quote(bf(y ~ x, sigma ~ x)),
    fam  = quote(nbinom2()),
    truth = c("fixef:mu:(Intercept)" = 0.6, "fixef:mu:x" = 0.4,
              "fixef:sigma:(Intercept)" = -0.5, "fixef:sigma:x" = 0.2),
    sim = function(n, s) { set.seed(s); x <- rnorm(n)
      mu <- exp(0.6 + 0.4 * x); size <- exp(-2 * (-0.5 + 0.2 * x))
      data.frame(y = rnbinom(n, mu = mu, size = size), x = x) }),
  # stress: rare-event binomial (~8% base rate)
  binomial_rare = list(
    form = quote(bf(y ~ x)), fam = quote(binomial()),
    truth = c("fixef:mu:(Intercept)" = -2.5, "fixef:mu:x" = 0.7),
    sim = function(n, s) { set.seed(s); x <- rnorm(n)
      data.frame(y = rbinom(n, 1, plogis(-2.5 + 0.7 * x)), x = x) }),
  # stress: low-count Poisson (base mean 1)
  poisson_low = list(
    form = quote(bf(y ~ x)), fam = quote(poisson()),
    truth = c("fixef:mu:(Intercept)" = 0.0, "fixef:mu:x" = 0.4),
    sim = function(n, s) { set.seed(s); x <- rnorm(n)
      data.frame(y = rpois(n, exp(0.0 + 0.4 * x)), x = x) })
)

one <- function(sp, n, seed) {
  d <- sp$sim(n, seed)
  fit <- tryCatch(
    drmTMB(eval(sp$form), family = eval(sp$fam), data = d, control = drm_control(se = TRUE)),
    error = function(e) NULL)
  truth <- sp$truth
  res <- data.frame(parm = names(truth), covered = NA, finite = FALSE, width = NA_real_,
                    stringsAsFactors = FALSE)
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

grid <- expand.grid(spec = names(specs), n = NS, stringsAsFactors = FALSE)
out <- list()
for (gi in seq_len(nrow(grid))) {
  nm <- grid$spec[gi]; n <- grid$n[gi]; sp <- specs[[nm]]
  reps <- mclapply(seq_len(NSIM), function(s) one(sp, n, 200000L * gi + s), mc.cores = NCORES)
  for (p in names(sp$truth)) {
    cov <- vapply(reps, function(r) { v <- r$covered[r$parm == p]; if (length(v)) v else NA }, logical(1))
    fin <- vapply(reps, function(r) { v <- r$finite[r$parm == p]; if (length(v)) v else FALSE }, logical(1))
    wid <- vapply(reps, function(r) { v <- r$width[r$parm == p]; if (length(v)) v else NA_real_ }, numeric(1))
    finite_rate <- mean(fin)
    ok <- cov[fin & !is.na(cov)]
    coverage <- if (length(ok)) mean(ok) else NA_real_
    mcse <- if (length(ok)) sqrt(coverage * (1 - coverage) / length(ok)) else NA_real_
    out[[length(out) + 1]] <- data.frame(
      spec = nm, n = n, param = p, nsim = NSIM,
      finite_rate = round(finite_rate, 3), coverage = round(coverage, 3),
      mcse = round(mcse, 4), mean_width = round(mean(wid[fin], na.rm = TRUE), 3))
  }
  cat(sprintf("done %s n=%d\n", nm, n))
}
res <- do.call(rbind, out)
res$clears_094 <- with(res, finite_rate >= 0.95 & (coverage + 2 * mcse) >= 0.94)
write.table(res, Sys.getenv("OUTFILE", "~/drmTMB_work/phase2_coverage_results.tsv"), sep = "\t", row.names = FALSE, quote = FALSE)
cat("\n===== PHASE-2 COVERAGE RESULTS =====\n"); print(res, row.names = FALSE)
