# R-vs-Julia comparison at the optimum for the wave4-reml cells. Parameters are matched by POSITION. The Julia csv files carry no
# parameter names, so names are not checked; the only structural check is that both sides have the same number of parameters
# (nrow), plus the check that R's own names have the layout expected for the case (below). A transposition of two Julia coordinates
# would show as a large difference, not as an error.
cases <- c("animal","relmat","phylo","spatial","phylo_lab","phylo_sx"); rows <- list(); prm <- list()
for (s in 1:5) for (cn in cases) for (est in c("REML","ML")) {
  tag <- sprintf("%s_s%02d", cn, s)
  fr <- sprintf("r/%s_%s.csv", tag, est); fj <- sprintf("julia/%s_%s.csv", tag, est)
  if (!file.exists(fr) || !file.exists(fj)) next
  r <- read.csv(fr); j <- read.csv(fj); stopifnot(nrow(r) == nrow(j))
  stopifnot(grepl("^mu:", r$name[1]), grepl("^sigma:", r$name[3]), sum(grepl("^sd_", r$name)) == 4L)   # R-side layout only
  llr <- read.csv(sprintf("r/%s_%s_ll.csv", tag, est)); llj <- read.csv(sprintf("julia/%s_%s_ll.csv", tag, est))
  d <- j$est - r$est
  # derived natural-scale targets: the two SD intercept coefficients (SD at z = 0) and rho
  sdi <- grep("\\(Intercept\\)\\):\\(Intercept\\)|coef = \"x\"\\):\\(Intercept\\)", r$name)
  rho_r <- if (any(r$name == "eta_cor_phylo")) 0.999999 * tanh(r$est[r$name == "eta_cor_phylo"]) else NA
  rho_j <- if (any(r$name == "eta_cor_phylo")) 0.999999 * tanh(j$est[r$name == "eta_cor_phylo"]) else NA
  rows[[length(rows) + 1]] <- data.frame(case = cn, seed = s, estimator = est, n_par = nrow(r),
    max_abs_coef_diff = max(abs(d)), max_abs_sd_diff = max(abs(exp(j$est[sdi]) - exp(r$est[sdi]))),
    abs_rho_diff = abs(rho_j - rho_r),
    max_se_rel_diff = max(abs(j$se / r$se - 1)), max_se_rel_diff_mean_block = max(abs((j$se / r$se - 1)[grepl("^mu:", r$name)])),
    ll_r = as.numeric(llr$ll), ll_julia = llj$ll, ll_diff = llj$ll - as.numeric(llr$ll), r_conv = llr$convergence, r_pdHess = llr$pdHess, julia_converged = llj$converged)
  prm[[length(prm) + 1]] <- data.frame(case = cn, seed = s, estimator = est, name = r$name, r_est = r$est, julia_est = j$est, diff = d, r_se = r$se, julia_se = j$se)
}
tab <- do.call(rbind, rows); write.csv(tab, "summary.csv", row.names = FALSE)
write.csv(do.call(rbind, prm), "parameters.csv", row.names = FALSE)
op <- options(width = 220, digits = 4); print(tab[tab$estimator == "REML", c(1:2, 4:9, 12:15)], row.names = FALSE)   # includes ll_diff, r_conv, r_pdHess, julia_converged
cat("\nML (reference, not the goal):\n"); print(tab[tab$estimator == "ML", c(1:2, 4:9, 12:15)], row.names = FALSE)
