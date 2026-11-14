# Julia minus R at the optimum (run from this directory). Parameter order is identical:
# beta_mu, [beta_sigma], beta_sd_mu (intercept SD formula, slope SD formula), eta_cor_phylo.
rl <- read.csv("r_ll.csv", colClasses = c(ll = "character"))
jl <- read.csv("julia_ll.csv", colClasses = c(ll = "character"))
cases <- list()
for (i in seq_len(nrow(rl))) if (!is.na(rl$ll[i]))
  cases[[length(cases) + 1]] <- list(fn = rl$family[i], kind = rl$kind[i], const = FALSE, ll_r = as.numeric(rl$ll[i]),
    rconv = rl$convergence[i], rfile = sprintf("r_%s_%s.csv", rl$family[i], rl$kind[i]),
    jfile = sprintf("julia_%s_%s.csv", rl$family[i], rl$kind[i]))
cases[[length(cases) + 1]] <- list(fn = "poisson", kind = "phylo", const = TRUE,
  ll_r = as.numeric(readLines("r_poisson_phylo_const_ll.txt")), rconv = 0L,
  rfile = "r_poisson_phylo_const.csv", jfile = "julia_poisson_phylo_const.csv")
out <- NULL; allrows <- NULL
for (cs in cases) {
  r <- read.csv(cs$rfile); j <- read.csv(cs$jfile)
  stopifnot(nrow(r) == nrow(j))
  diff <- j$est - r$est
  allrows <- rbind(allrows, data.frame(family = cs$fn, kind = cs$kind, const_sd = cs$const, r_name = r$name,
    j_block = j$block, r_est = r$est, j_est = j$est, diff = diff, diff_in_r_se = diff / r$se,
    r_se = r$se, j_se = j$se, se_ratio = j$se / r$se))
  row <- jl[jl$family == cs$fn & jl$kind == cs$kind & tolower(jl$const_sd) == tolower(as.character(cs$const)), ]
  rho_r <- 0.999999 * tanh(tail(r$est, 1)); rho_j <- 0.999999 * tanh(tail(j$est, 1))
  out <- rbind(out, data.frame(family = cs$fn, kind = cs$kind, const_sd = cs$const, n_par = nrow(r),
    max_abs_diff = max(abs(diff)), max_diff_in_r_se = max(abs(diff / r$se)),
    rho_R = rho_r, rho_julia_minus_R = rho_j - rho_r,
    se_ratio_min = min(j$se / r$se), se_ratio_max = max(j$se / r$se),
    ll_R = cs$ll_r, ll_julia_minus_R = as.numeric(row$ll) - cs$ll_r,
    converged = paste0("R:", cs$rconv == 0, " J:", row$converged)))
}
print(out, digits = 4)
write.csv(allrows, "comparison_by_parameter.csv", row.names = FALSE)
write.csv(out, "comparison_summary.csv", row.names = FALSE)
