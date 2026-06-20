# Coevolutionary phylo_interaction SD recovery (native R/TMB). Fits
# y ~ x + phylo_interaction(1 | host:parasite, tree1 = host_tree,
# tree2 = parasite_tree), sigma ~ 1 with fixed known trees per cell and recovers
# the fixed effects, the COEVOLUTIONARY SD (the Hadfield et al. 2014 headline
# A^(p) (x) A^(h) Kronecker term), and residual sigma.
#
# Design 178 Stage 0: validate that the single coevolutionary term recovers on
# its own -- the honest baseline under any future additive multi-component fit
# (Stage 1, engine-gated). Boundary: native R/TMB, Gaussian, ONE structured
# phylo_interaction block, known balanced trees, several obs per host:parasite
# pair, complete data; POINT recovery + fixed-effect Wald coverage only (coev-SD
# interval calibration NOT claimed). A species ladder shows estimator CONSISTENCY:
# the phylogenetic variance component is downward-biased at few species and the
# bias shrinks as species counts grow (cf. the single-tree phylo-SD diagnostic).
#
# Usage: Rscript --vanilla run.R [n_rep]
suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
n_rep <- if (length(args) >= 1L) as.integer(args[[1L]]) else 50L
out_dir <- "docs/dev-log/simulation-artifacts/2026-06-20-coevolution-phylo-interaction-recovery"
dir.create(file.path(out_dir, "tables"), recursive = TRUE, showWarnings = FALSE)

b0 <- 0.3; b1 <- 0.5; sigma <- 0.4; sd_co <- 0.7
n_each <- 4L                                   # obs per host:parasite pair
master_seed <- 20260620L
n_sps <- c(6L, 10L, 14L)                       # n_host = n_parasite per cell
truth <- c("fixef:mu:(Intercept)" = b0, "fixef:mu:x" = b1,
           "sd_coev" = sd_co, "sigma" = sigma)

rows <- list()
add <- function(...) rows[[length(rows) + 1L]] <<- data.frame(..., stringsAsFactors = FALSE)
t0 <- Sys.time(); ci <- 0L
for (n_sp in n_sps) {
  ci <- ci + 1L
  set.seed(20000L + n_sp)                       # fixed known trees per cell
  host_tree <- ape::rcoal(n_sp); host_tree$tip.label <- paste0("h", seq_len(n_sp))
  parasite_tree <- ape::rcoal(n_sp); parasite_tree$tip.label <- paste0("p", seq_len(n_sp))
  Ah <- stats::cov2cor(ape::vcv(host_tree))     # unit-diagonal phylo correlation
  Ap <- stats::cov2cor(ape::vcv(parasite_tree))
  pair_cov <- kronecker(Ap, Ah)                 # A^(p) (x) A^(h); host varies fastest
  Lpair <- t(chol(pair_cov))
  grid <- expand.grid(host = host_tree$tip.label, parasite = parasite_tree$tip.label,
                      KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  pair_name <- paste0(grid$host, ":", grid$parasite)
  n_pair <- nrow(grid)
  for (r in seq_len(n_rep)) {
    set.seed(master_seed + ci * 100000L + r)
    u <- sd_co * as.vector(Lpair %*% stats::rnorm(n_pair)); names(u) <- pair_name
    row_id <- rep(seq_len(n_pair), each = n_each)
    dat <- grid[row_id, , drop = FALSE]
    x <- stats::rnorm(nrow(dat))
    key <- paste0(dat$host, ":", dat$parasite)
    y <- b0 + b1 * x + u[key] + stats::rnorm(nrow(dat), 0, sigma)
    dat$x <- x; dat$y <- y
    fit <- tryCatch(
      drmTMB(bf(y ~ x + phylo_interaction(1 | host:parasite,
                                          tree1 = host_tree, tree2 = parasite_tree),
                sigma ~ 1),
             family = gaussian(), data = dat),
      error = function(e) e)
    if (inherits(fit, "error")) {
      add(n_sp = n_sp, rep = r, target = "NA", est = NA_real_, covered = NA,
          pdhess = NA, status = "fit_error"); next
    }
    pdh <- isTRUE(fit$sdr$pdHess)
    co <- tryCatch(coef(fit, "mu"), error = function(e) NULL)
    sdp <- fit$sdpars$mu
    sig <- tryCatch(as.numeric(sigma(fit))[1L], error = function(e) NA_real_)
    cw <- tryCatch(suppressWarnings(confint(fit, parm = c("mu:(Intercept)", "mu:x"))),
                   error = function(e) NULL)
    sd_coev <- {
      v <- sdp[grepl("phylo_interaction", names(sdp))]
      if (length(v) >= 1L) as.numeric(v[[1L]]) else NA_real_
    }
    est <- c(
      "fixef:mu:(Intercept)" = if (!is.null(co) && "(Intercept)" %in% names(co)) as.numeric(co[["(Intercept)"]]) else NA_real_,
      "fixef:mu:x" = if (!is.null(co) && "x" %in% names(co)) as.numeric(co[["x"]]) else NA_real_,
      "sd_coev" = sd_coev,
      "sigma" = sig
    )
    cov_lookup <- function(tg) {
      if (is.null(cw)) return(NA)
      row <- cw[cw$parm == tg, , drop = FALSE]
      if (nrow(row) == 0L) return(NA)
      tv <- truth[[tg]]
      pdh && is.finite(row$lower[1L]) && is.finite(row$upper[1L]) &&
        tv >= row$lower[1L] && tv <= row$upper[1L]
    }
    for (tg in names(est)) {
      add(n_sp = n_sp, rep = r, target = tg, est = est[[tg]],
          covered = if (tg %in% c("fixef:mu:(Intercept)", "fixef:mu:x")) cov_lookup(tg) else NA,
          pdhess = pdh, status = "ok")
    }
  }
}
elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
fits <- do.call(rbind, rows)
write.csv(fits, file.path(out_dir, "tables", "coevolution-recovery-fits.csv"), row.names = FALSE)

ok <- fits[!is.na(fits$est) & fits$target != "NA", , drop = FALSE]
key <- paste(ok$n_sp, ok$target, sep = "|")
agg <- do.call(rbind, lapply(split(ok, key), function(d) {
  tv <- truth[[d$target[[1L]]]]
  cov_rows <- d$covered[!is.na(d$covered)]
  pr <- if (length(cov_rows)) mean(cov_rows) else NA_real_
  m <- length(cov_rows)
  data.frame(n_sp = d$n_sp[[1L]], target = d$target[[1L]], truth = tv,
             mean_est = round(mean(d$est), 4), bias = round(mean(d$est) - tv, 4),
             rel_bias = round((mean(d$est) - tv) / tv, 3),
             rmse = round(sqrt(mean((d$est - tv)^2)), 4),
             wald_coverage = if (is.na(pr)) NA_real_ else round(pr, 4),
             cov_mcse = if (is.na(pr)) NA_real_ else round(sqrt(pr * (1 - pr) / max(m, 1)), 4),
             pdhess_rate = round(mean(d$pdhess), 4), n_used = nrow(d),
             stringsAsFactors = FALSE)
}))
write.csv(agg, file.path(out_dir, "tables", "coevolution-recovery-summary.csv"), row.names = FALSE)
cat("=== Gaussian coevolutionary phylo_interaction SD recovery (n_rep=", n_rep, ") ===\n", sep = "")
print(agg, row.names = FALSE)
cat("fit errors:", sum(fits$target == "NA"), "| elapsed:", round(elapsed, 1), "s\n")
writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
cat("DONE\n")
