# S5 probe: does native REML debias the ORDINARY sigma random-effect SD vs ML,
# and does it need replication? Model: y ~ x + (1|id), sigma ~ 1 + (1|id)
# (independent location + scale random intercepts -- the DHGLM repeatability case).
# Gate drm_validate_reml_spec (~:1973) bypassed to probe.
suppressPackageStartupMessages({devtools::load_all(".", quiet = TRUE); library(parallel)})
assignInNamespace("drm_validate_reml_spec", function(spec) invisible(TRUE), ns = "drmTMB")
Sys.setenv(OPENBLAS_NUM_THREADS = "1")
truth <- c(sd_mu = 0.6, sd_sigma = 0.4)

sim_fit <- function(n_id, n_each, seed) {
  set.seed(seed * 7919L + n_id * 13L + n_each)
  b_mu <- rnorm(n_id, 0, truth[["sd_mu"]]); b_sg <- rnorm(n_id, 0, truth[["sd_sigma"]])
  id <- rep(seq_len(n_id), each = n_each); n <- n_id * n_each; x <- rnorm(n)
  y <- 0.3 + 0.5 * x + b_mu[id] + rnorm(n, 0, exp(log(0.5) + b_sg[id]))
  d <- data.frame(y = y, x = x, id = factor(id))
  form <- bf(y ~ x + (1 | id), sigma ~ 1 + (1 | id))
  out <- list()
  for (est in c("ML", "REML")) {
    f <- tryCatch(suppressWarnings(drmTMB(form, gaussian(), d, REML = (est == "REML"),
             control = drm_control(optimizer_preset = "robust"))), error = function(e) e)
    if (inherits(f, "error")) return(NULL)
    pr <- tryCatch(summary(f)$parameters, error = function(e) NULL); if (is.null(pr)) return(NULL)
    g <- function(rx) unname(pr$estimate[grep(rx, pr$parm)][1])
    out[[est]] <- list(sd_mu = g("^sd:mu.*id"), sd_sigma = g("^sd:sigma.*id"),
                       pd = isTRUE(f$sdr$pdHess), conv = f$opt$convergence)
  }
  data.frame(n_id = n_id, n_each = n_each, seed = seed, param = names(truth), truth = truth,
             ml = c(out$ML$sd_mu, out$ML$sd_sigma), reml = c(out$REML$sd_mu, out$REML$sd_sigma),
             pd_ml = out$ML$pd, pd_reml = out$REML$pd, row.names = NULL)
}

grid <- expand.grid(seed = 1:8, n_each = c(3L, 8L), n_id = c(30L, 60L))
res <- mcmapply(sim_fit, grid$n_id, grid$n_each, grid$seed, SIMPLIFY = FALSE, mc.cores = 8)
res <- do.call(rbind, res[!vapply(res, is.null, logical(1))])
m <- function(z) mean(z, na.rm = TRUE)
cat("=== ordinary sigma-RE: bias(ML) vs bias(REML) by (n_id, n_each) [KEY: does REML debias sd_sigma?] ===\n")
agg <- aggregate(cbind(ml, reml) ~ n_id + n_each + param + truth, data = res, FUN = m)
agg$bias_ml <- agg$ml - agg$truth; agg$bias_reml <- agg$reml - agg$truth
agg <- agg[order(agg$param, agg$n_id, agg$n_each), ]
for (i in seq_len(nrow(agg))) cat(sprintf("%-9s n_id=%-3d n_each=%-2d : biasML %+.3f  biasREML %+.3f\n",
    agg$param[i], agg$n_id[i], agg$n_each[i], agg$bias_ml[i], agg$bias_reml[i]))
d1 <- res[res$param == "sd_sigma", ]
cat(sprintf("\npdHess: ML=%.2f REML=%.2f | P(REML PD | ML PD)=%.2f\n",
    m(as.logical(d1$pd_ml)), m(as.logical(d1$pd_reml)), m(as.logical(d1$pd_reml)[as.logical(d1$pd_ml)])))
cat("PROBE DONE\n")
