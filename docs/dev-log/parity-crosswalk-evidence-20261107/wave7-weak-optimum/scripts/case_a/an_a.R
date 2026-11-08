E <- Sys.getenv("E"); ps <- read.csv(file.path(E, "per_seed.csv")); ps <- ps[ps$route == "nb2_phylo", c("seed","ll_julia","ll_R","julia_converged")]
m <- rbind(read.csv("ms_1_50.csv"), read.csv("ms_51_100.csv")); m$f <- as.numeric(m$f)
w <- reshape(m[, c("seed","start","f")], idvar = "seed", timevar = "start", direction = "wide")
w <- merge(w, ps, by = "seed"); w$best <- apply(w[, paste0("f.", 1:4)], 1, min, na.rm = TRUE)
w$d_default <- -w$f.1 - w$ll_julia   # new harness vs campaign Julia ll
cat("harness default vs campaign Julia: max abs diff", max(abs(w$d_default), na.rm=TRUE), "\n")
w$gap_default_to_best <- w$f.1 - w$best
w$gapR <- -w$ll_R - w$best  # R nll minus best nll: positive = R worse than best-of-4
cat("seeds with default start >1e-6 above best of 4 starts:", sum(w$gap_default_to_best > 1e-6, na.rm=TRUE), "\n"); print(w[w$gap_default_to_best > 1e-6, c("seed","f.1","f.2","f.3","f.4","ll_R")])
for (k in 2:4) cat("start", k, "alone: seeds where it beats default by >1e-6:", sum(w$f.1 - w[[paste0("f.",k)]] > 1e-6, na.rm=TRUE), "; where default beats it by >1e-6:", sum(w[[paste0("f.",k)]] - w$f.1 > 1e-6, na.rm=TRUE), "\n")
cat("R nll worse than best-of-4 by >1e-6:", sum(w$gapR > 1e-6), "; best-of-4 worse than R by >1e-6:", sum(-w$ll_R - w$best < -1e-6), "\n")
print(w[abs(w$gapR) > 1e-6, c("seed","best","ll_R","gapR")])
