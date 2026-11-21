E <- Sys.getenv("E"); ps <- read.csv(file.path(E, "per_seed.csv")); ps <- ps[ps$route == "nb2_phylo", c("seed","ll_julia","ll_R")]
m <- rbind(read.csv("ms_1_50.csv"), read.csv("ms_51_100.csv")); m$f <- as.numeric(m$f)
w <- reshape(m[, c("seed","start","f")], idvar = "seed", timevar = "start", direction = "wide"); w <- merge(w, ps, by = "seed")
w$nllJ <- -w$ll_julia; w$nllR <- -w$ll_R
cat("n seeds", nrow(w), "\n")
cat("campaign Julia above R by >1e-6:", paste(w$seed[w$nllJ - w$nllR > 1e-6], collapse=","), "\n")
for (k in 1:4) { cat("start", k, ": better than campaign Julia by >1e-6 in seeds", paste(w$seed[w$nllJ - w[[paste0("f.",k)]] > 1e-6], collapse=","), "; worse by >1e-6 in", paste(w$seed[w[[paste0("f.",k)]] - w$nllJ > 1e-6], collapse=","), "\n") }
w$best3 <- pmin(w$nllJ, w$f.2, w$f.3, w$f.4)
cat("best of {campaign, starts 2,3,4} vs R:\n"); print(w[abs(w$best3 - w$nllR) > 1e-6, c("seed","nllJ","f.2","f.3","f.4","nllR")])
m2 <- m[m$start==1,]; cat("minsd of harness-default fits < 0.05:", sum(as.numeric(m2$minsd) < 0.05), " <0.01:", sum(as.numeric(m2$minsd) < 0.01), "\n")
