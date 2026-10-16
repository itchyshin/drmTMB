# t6 verifier scan (not an issue repro): every exported consumer of fitted_distribution() on the 14 (1 | g) cells.
# drmTMB ca3ddefa5ea11bbfd3b765615dfbb89305d2485a; data sweep-oct16/t6/data/<family>_ri.csv (seeds in cells.csv).
# For each cell: is the fitted-row (newdata = NULL) output equal to the same computation at the population-level
# parameters (fitted_distribution(fit, newdata = d)) or at the conditional fitted-row parameters (fitted_distribution(fit))?
suppressPackageStartupMessages(library(drmTMB))
source("/home/user/drmTMB/sweep-oct16/t6/R/lib_t6.R")
cells <- read.csv(file.path(T6_DATA, "cells.csv"), stringsAsFactors = FALSE)
cells <- cells[cells$re == "ri", ]
probs <- c(0.025, 0.5, 0.975)
mx <- function(a, b) { a <- as.matrix(a); b <- as.matrix(b); ok <- is.finite(a) & is.finite(b); if (!any(ok)) NA_real_ else max(abs(a[ok] - b[ok])) }
rows <- list()
for (k in seq_len(nrow(cells))) {
  fam <- cells$family[k]
  d <- t6_read_cell(cells$file[k], fam)
  spec <- t6_formula(fam, "ri")
  fit <- tryCatch(suppressWarnings(drmTMB(spec$bf, family = t6_family_object(fam), data = d)), error = function(e) e)
  if (inherits(fit, "error")) { rows[[fam]] <- data.frame(family = fam, note = conditionMessage(fit)); next }
  fd_c <- fitted_distribution(fit)                  # what the fitted-row consumers use
  fd_p <- fitted_distribution(fit, newdata = d)     # documented population-level parameters, same rows
  dpars <- setdiff(names(fd_c$params), "V_known")
  par_gap <- max(vapply(dpars, function(p) mx(fd_c$params[[p]], fd_p$params[[p]]), 0))
  n <- nrow(d)
  Q <- predict(fit, type = "quantile", prob = probs)
  Qc <- sapply(probs, function(p) fd_c$q(rep(p, n))); Qp <- sapply(probs, function(p) fd_p$q(rep(p, n)))
  y <- drmTMB:::drm_quantile_residual_response_y(fit, NULL)
  thr <- if (fam == "cumulative_logit") 2 else stats::median(as.numeric(y))
  E <- exceedance(fit, threshold = thr)
  Ec <- 1 - fd_c$p(rep(thr, n)); Ep <- 1 - fd_p$p(rep(thr, n))
  R <- residuals(fit, type = "quantile", seed = 7)
  Rc <- qnorm(drmTMB:::drm_quantile_residual_u(fd_c, y, seed = 7))
  Rp <- qnorm(drmTMB:::drm_quantile_residual_u(fd_p, y, seed = 7))
  qq <- if (requireNamespace("ggplot2", quietly = TRUE)) {
    g <- qq_plot(fit, seed = 7); mx(sort(g$data$sample), sort(Rc[is.finite(Rc)]))
  } else NA_real_
  rows[[fam]] <- data.frame(family = fam, max_abs_bhat = max(abs(fit$random_effects$mu$values)),
    param_cond_vs_pop = par_gap,
    q_vs_cond = mx(Q, Qc), q_vs_pop = mx(Q, Qp),
    exc_vs_cond = mx(E, Ec), exc_vs_pop = mx(E, Ep),
    qres_vs_cond = mx(R, Rc), qres_vs_pop = mx(R, Rp), qqplot_vs_cond = qq, note = "")
}
out <- do.call(rbind, lapply(rows, function(r) { for (nm in c("max_abs_bhat","param_cond_vs_pop","q_vs_cond","q_vs_pop","exc_vs_cond","exc_vs_pop","qres_vs_cond","qres_vs_pop","qqplot_vs_cond","note")) if (is.null(r[[nm]])) r[[nm]] <- NA; r }))
rownames(out) <- NULL
print(format(out, digits = 3), right = FALSE)
cat("tweedie package:", as.character(packageVersion("tweedie")), "; drmTMB", as.character(packageVersion("drmTMB")), "\n")
