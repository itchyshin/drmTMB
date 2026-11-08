# Compare R and Julia estimates, SEs and log-likelihoods for each case.
O <- "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/w2ps"
rows <- list()
for (case in c("gphy","pphy","nphy","gsp","psp","nsp")) {
  r <- read.csv(file.path(O, paste0("r_", case, ".csv"))); j <- read.csv(file.path(O, paste0("j_", case, ".csv")))
  stopifnot(nrow(r) == nrow(j))
  d <- j$est - r$estimate
  out <- data.frame(case = case, term = r$X, r_est = r$estimate, j_est = j$est, diff = d,
                    diff_in_r_se = d / r$std_error, r_se = r$std_error, j_se = j$se,
                    se_rel = j$se / r$std_error - 1)
  write.csv(out, file.path(O, paste0("cmp_", case, ".csv")), row.names = FALSE)
  llr <- as.numeric(readLines(file.path(O, paste0("r_", case, "_ll.txt"))))
  llj <- as.numeric(readLines(file.path(O, paste0("j_", case, "_ll.txt"))))
  rows[[case]] <- data.frame(case = case, n_par = nrow(r), max_abs_diff = max(abs(d)),
    max_diff_r_se = max(abs(out$diff_in_r_se)), max_se_rel = max(abs(out$se_rel)),
    ll_r = llr, ll_j = llj, ll_diff_j_minus_r = llj - llr)
}
s <- do.call(rbind, rows); print(s, digits = 4, row.names = FALSE)
write.csv(s, file.path(O, "summary.csv"), row.names = FALSE)
