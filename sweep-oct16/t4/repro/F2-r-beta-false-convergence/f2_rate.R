## F2: how often does drmTMB's beta_family() fit report nlminb false convergence at large phi?
## Usage (from this directory):
##   Rscript f2_rate.R main   > f2_rate_main.out   2>&1   # installed drmTMB (pin ca3ddefa)
##   Rscript f2_rate.R <lib> pr1547 > f2_rate_pr1547.out 2>&1   # a library holding the PR #1547 build (head 569bd918)
## DGP = t4 cell beta_phi1e4 (t4_gen_data.R): x ~ N(0,1), mu = plogis(0.5 x), y ~ Beta(mu phi, (1-mu) phi), n = 100.
## Seeds (R seed = nominal %% 2^31, Mersenne-Twister/Inversion/Rejection):
##   phi = 1e4: the 50 grid CSVs (nominal 20261017300..20261017349), then nominal 20261017350..20261017399
##              (unused tail of cell k = 10's block) and 20261090000..20261090399  -> 500 datasets
##   phi = 1e3: nominal 20261091000..20261091199 ; phi = 1e5: nominal 20261092000..20261092199
## Generated data are round-tripped through write.csv/read.csv so they match the grid's CSV precision.
args <- commandArgs(trailingOnly = TRUE)
lib <- if (length(args) && args[1] != "main") args[1] else NULL
suppressPackageStartupMessages(library(drmTMB, lib.loc = lib))
cat("drmTMB", as.character(packageVersion("drmTMB", lib.loc = lib)), "from", find.package("drmTMB"),
    "| TMB", as.character(packageVersion("TMB")), "\n")
gen <- function(nominal, phi) {
  RNGkind("Mersenne-Twister", "Inversion", "Rejection"); set.seed(as.integer(nominal %% 2^31))
  x <- rnorm(100); mu <- plogis(0.5 * x)
  d <- data.frame(y = rbeta(100, mu * phi, (1 - mu) * phi), x = x)
  read.csv(text = paste(capture.output(write.csv(d, row.names = FALSE)), collapse = "\n"))
}
## sanity: the generator reproduces the grid CSV for rep 1
stopifnot(isTRUE(all.equal(gen(20261017300, 1e4), read.csv("../../data/beta_phi1e4_r01.csv"), tolerance = 0)))
ref_ll <- function(d, start) {          # engine-independent optimum: base-R dbeta, same parameterisation + nudge
  X <- cbind(1, d$x)
  nll <- function(p) { mu <- 1e-12 + (1 - 2e-12) * plogis(drop(X %*% p[1:2])); phi <- exp(-2 * p[3])
    v <- -sum(dbeta(d$y, mu * phi, (1 - mu) * phi, log = TRUE)); if (is.finite(v)) v else Inf }
  o <- nlminb(start, nll)
  for (i in 1:2) o <- { b <- optim(o$par, nll, method = "BFGS", control = list(reltol = 1e-15, maxit = 2000)); list(par = b$par, objective = b$value) }
  -o$objective
}
one <- function(d) {
  w <- character()
  fit <- withCallingHandlers(drmTMB(bf(y ~ x, sigma ~ 1), family = beta_family(), data = d),
    warning = function(x) { w <<- c(w, conditionMessage(x)); invokeRestart("muffleWarning") })
  ll <- as.numeric(logLik(fit))
  data.frame(raw_code = fit$optimizer_attempts$convergence[1], n_attempts = nrow(fit$optimizer_attempts),
             final_code = as.integer(fit$opt$convergence), converged = is_converged(fit),
             status = convergence_status(fit), warned = length(w) > 0, logLik = ll,
             ll_minus_ref = ll - ref_ll(d, fit$opt$par), max_grad = max(abs(fit$gradient)))
}
plan <- rbind(
  data.frame(phi = 1e4, nominal = 20261017300 + 0:49, src = "grid_csv"),
  data.frame(phi = 1e4, nominal = c(20261017350 + 0:49, 20261090000 + 0:399), src = "extra"),
  data.frame(phi = 1e3, nominal = 20261091000 + 0:199, src = "extra"),
  data.frame(phi = 1e5, nominal = 20261092000 + 0:199, src = "extra"))
res <- do.call(rbind, lapply(seq_len(nrow(plan)), function(i) {
  d <- if (plan$src[i] == "grid_csv") read.csv(sprintf("../../data/beta_phi1e4_r%02d.csv", i)) else gen(plan$nominal[i], plan$phi[i])
  cbind(plan[i, ], one(d))
}))
lab <- if (length(args) >= 2) args[2] else if (is.null(lib)) "main" else "altlib"
write.csv(res, sprintf("f2_rate_%s.csv", lab), row.names = FALSE)
for (ph in c(1e3, 1e4, 1e5)) {
  r <- res[res$phi == ph, ]
  cat(sprintf("\nphi = %g (n datasets = %d)\n", ph, nrow(r)))
  cat(sprintf("  nlminb raw false convergence (default preset): %d  -> after ladder + Newton polish, opt code != 0: %d (%.1f%%)\n",
      sum(r$raw_code != 0), sum(r$final_code != 0), 100 * mean(r$final_code != 0)))
  cat(sprintf("  is_converged FALSE: %d ; fit-time warning: %d ; status table: %s\n", sum(!r$converged), sum(r$warned),
      paste(names(table(r$status)), table(r$status), sep = "=", collapse = " ")))
  bad <- r[r$final_code != 0, ]
  if (nrow(bad)) cat(sprintf("  flagged fits: max |logLik - dbeta optimum| = %.2e ; max |grad| range [%.1e, %.1e]\n",
      max(abs(bad$ll_minus_ref)), min(bad$max_grad), max(bad$max_grad)))
  cat(sprintf("  all fits: max |logLik - dbeta optimum| = %.2e\n", max(abs(r$ll_minus_ref))))
}
g <- res[res$src == "grid_csv", ]
cat("\ngrid reps (1..50) with opt code != 0:", which(g$final_code != 0), "\n")
cat("\nsessionInfo():\n"); print(sessionInfo())
