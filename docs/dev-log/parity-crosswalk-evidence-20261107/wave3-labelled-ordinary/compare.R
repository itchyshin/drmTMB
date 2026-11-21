# Julia minus R at the optimum (run from this directory). Parameter order is identical:
# beta_mu, [beta_sigma], beta_sd_mu (intercept SD formula, slope SD formula), eta_cor.
rl <- read.csv("r_ll.csv", colClasses = c(seed = "character", ll = "character"))
jl <- read.csv("julia_ll.csv", colClasses = c(seed = "character", ll = "character"))
out <- NULL; allrows <- NULL
for (i in seq_len(nrow(rl))) {
  if (is.na(rl$ll[i])) next
  s <- rl$seed[i]; fn <- rl$family[i]
  r <- read.csv(sprintf("r_%s_%s.csv", fn, s)); j <- read.csv(sprintf("julia_%s_%s.csv", fn, s))
  stopifnot(nrow(r) == nrow(j))
  diff <- j$est - r$est
  allrows <- rbind(allrows, data.frame(seed = s, family = fn, r_name = r$name, j_block = j$block,
    r_est = r$est, j_est = j$est, diff = diff, diff_in_r_se = diff / r$se,
    r_se = r$se, j_se = j$se, se_ratio = j$se / r$se))
  row <- jl[jl$seed == s & jl$family == fn, ]
  rho_r <- 0.999999 * tanh(tail(r$est, 1)); rho_j <- 0.999999 * tanh(tail(j$est, 1))
  out <- rbind(out, data.frame(seed = s, family = fn, n_par = nrow(r),
    max_abs_diff = max(abs(diff)), max_diff_in_r_se = max(abs(diff / r$se)),
    rho_R = rho_r, rho_julia_minus_R = rho_j - rho_r,
    se_ratio_min = min(j$se / r$se), se_ratio_max = max(j$se / r$se),
    ll_R = as.numeric(rl$ll[i]), ll_julia_minus_R = as.numeric(row$ll) - as.numeric(rl$ll[i]),
    converged = paste0("R:", rl$convergence[i] == 0, " J:", row$converged)))
}
print(out, digits = 4)
write.csv(allrows, "comparison_by_parameter.csv", row.names = FALSE)
write.csv(out, "comparison_summary.csv", row.names = FALSE)
