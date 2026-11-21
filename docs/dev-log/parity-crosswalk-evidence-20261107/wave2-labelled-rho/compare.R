# Julia minus R at the optimum, per route. Parameter order is identical:
# beta_mu, [beta_sigma], beta_sd_mu (intercept SD formula, slope SD formula), eta_cor_phylo.
O <- "."  # run from this directory
rl <- read.csv(file.path(O, "r_ll.csv"), colClasses = c(ll = "character"))
jl <- read.csv(file.path(O, "julia_ll.csv"), colClasses = c(ll = "character"))
out <- NULL; allrows <- NULL
for (i in seq_len(nrow(rl))) {
  fn <- rl$family[i]; kind <- rl$kind[i]
  r <- read.csv(file.path(O, sprintf("r_%s_%s.csv", fn, kind)))
  j <- read.csv(file.path(O, sprintf("julia_%s_%s.csv", fn, kind)))
  stopifnot(nrow(r) == nrow(j))
  diff <- j$est - r$est
  rows <- data.frame(family = fn, kind = kind, r_name = r$name, j_block = j$block, r_est = r$est, j_est = j$est,
                     diff = diff, diff_in_r_se = diff / r$se, se_ratio = j$se / r$se)
  allrows <- rbind(allrows, rows)
  llj <- as.numeric(jl$ll[jl$family == fn & jl$kind == kind]); llr <- as.numeric(rl$ll[i])
  rho_r <- 0.999999 * tanh(tail(r$est, 1)); rho_j <- 0.999999 * tanh(tail(j$est, 1))
  out <- rbind(out, data.frame(family = fn, kind = kind, n_par = nrow(r),
    max_abs_diff = max(abs(diff)), max_abs_diff_se = max(abs(diff / r$se)),
    rho_R = rho_r, rho_julia_minus_R = rho_j - rho_r,
    se_ratio_min = min(j$se / r$se), se_ratio_max = max(j$se / r$se),
    ll_R = llr, ll_julia_minus_R = llj - llr,
    converged = paste0("R:", rl$convergence[i] == 0, " J:", jl$converged[jl$family == fn & jl$kind == kind])))
}
print(out, digits = 4)
write.csv(allrows, file.path(O, "comparison_by_parameter.csv"), row.names = FALSE)
write.csv(out, file.path(O, "comparison_summary.csv"), row.names = FALSE)
