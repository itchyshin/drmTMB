# R-vs-Julia comparison at the ML optimum. Flags are fixed BEFORE reading results:
#   ll_flag       |ll_J - ll_R| > 1e-3
#   coef_abs_flag max |coef_J - coef_R| > 0.01 (absolute, any of the 6 coefficients)
#   coef_se_flag  max |coef_J - coef_R| / SE_R > 0.01
#   se_flag       max |SE_J / SE_R - 1| > 0.10
#   nonfinite_flag  any non-finite SE in either engine
#   conv_flag     R convergence code != 0 or Julia converged == false
#   boundary_flag min fitted group SD < 0.01 in either engine (SD coefficient run to -Inf)
# (R group SD recomputed from its coefficients and the z design: z0 in {-1,1}, z1 per tip.)
here <- dirname(sub("--file=", "", grep("--file=", commandArgs(FALSE), value = TRUE)))
seeds <- c(20261108, 1:10); rows <- list(); det <- list()
for (kind in c("phylo", "spatial")) for (seed in seeds) {
  tag <- sprintf("%s_%d", kind, seed)
  r <- read.csv(file.path(here, "out", paste0("r_", tag, ".csv"))); j <- read.csv(file.path(here, "out", paste0("j_", tag, ".csv")))
  stopifnot(identical(r$term, j$term))
  llr <- scan(file.path(here, "out", paste0("r_", tag, "_ll.txt")), what = "", quiet = TRUE)
  llj <- scan(file.path(here, "out", paste0("j_", tag, "_ll.txt")), what = "", quiet = TRUE)
  d <- j$est - r$est
  dat <- read.csv(file.path(here, "data", paste0(tag, ".csv"))); z1 <- unique(dat[, c("id", "z1")])$z1
  sd_r <- min(exp(r$est[3] + r$est[4] * c(-1, 1)), exp(r$est[5] + r$est[6] * z1))
  sd_j <- as.numeric(llj[4])
  det[[tag]] <- data.frame(kind = kind, seed = seed, term = r$term, r_est = r$est, j_est = j$est, diff = d,
                           diff_in_r_se = d / r$se, r_se = r$se, j_se = j$se, se_rel = j$se / r$se - 1)
  rows[[tag]] <- data.frame(kind = kind, seed = seed,
    ll_r = as.numeric(llr[1]), ll_j = as.numeric(llj[1]), ll_diff_j_minus_r = as.numeric(llj[1]) - as.numeric(llr[1]),
    max_abs_coef_diff = max(abs(d)), max_abs_diff_in_r_se = max(abs(d / r$se)), max_abs_se_rel = max(abs(j$se / r$se - 1)),
    max_abs_sd_coef_diff = max(abs(d[3:6])),
    nonfinite_se_r = sum(!is.finite(r$se)), nonfinite_se_j = sum(!is.finite(j$se)),
    r_conv_code = llr[2], j_converged = llj[2], r_min_group_sd = sd_r, j_min_group_sd = sd_j)
}
s <- do.call(rbind, rows); det <- do.call(rbind, det)
s$ll_flag <- abs(s$ll_diff_j_minus_r) > 1e-3
s$coef_abs_flag <- s$max_abs_coef_diff > 0.01
s$coef_se_flag <- s$max_abs_diff_in_r_se > 0.01
s$se_flag <- s$max_abs_se_rel > 0.10
s$nonfinite_flag <- s$nonfinite_se_r > 0 | s$nonfinite_se_j > 0
s$conv_flag <- s$r_conv_code != "0" | s$j_converged != "true"
s$boundary_flag <- s$r_min_group_sd < 0.01 | s$j_min_group_sd < 0.01
write.csv(s, file.path(here, "summary.csv"), row.names = FALSE); write.csv(det, file.path(here, "detail.csv"), row.names = FALSE)
options(width = 250); print(s[, c("kind", "seed", "ll_diff_j_minus_r", "max_abs_coef_diff", "max_abs_diff_in_r_se", "max_abs_se_rel", "nonfinite_se_r", "nonfinite_se_j", "r_min_group_sd", "j_min_group_sd")], digits = 3, row.names = FALSE)
cat("\nflag counts (of", nrow(s), "):\n"); print(colSums(s[, grep("_flag$", names(s))]))
agg <- aggregate(cbind(abs(ll_diff_j_minus_r), max_abs_coef_diff, max_abs_diff_in_r_se, max_abs_se_rel) ~ kind, data = s, FUN = max)
names(agg)[-1] <- c("max_abs_ll_diff", "max_abs_coef_diff", "max_abs_diff_in_r_se", "max_abs_se_rel"); print(agg, digits = 3)
