files <- list.files("out", pattern="\\.tsv$", full.names=TRUE)
d <- do.call(rbind, lapply(files, function(f) read.delim(f, stringsAsFactors=FALSE)))
cat("rows:", nrow(d), " cells:", length(unique(d$cell)), " engines:", paste(unique(d$engine), collapse=","), "\n")
cat("expected rows: 15 cells x 1000 reps x 4 engines =", 15*1000*4, "\n\n")

# retention (prereg sec 6 item 3)
ret <- aggregate(cbind(ok=as.integer(ok=="TRUE"|ok==TRUE)) ~ engine, d, function(v) mean(v))
cat("=== retention by engine ===\n"); print(ret)

d$ok <- d$ok=="TRUE" | d$ok==TRUE
u <- d[d$ok & is.finite(d$est) & is.finite(d$se), ]

R <- do.call(rbind, lapply(split(u, list(u$cell, u$engine), drop=TRUE), function(g) {
  n <- nrow(g); if (n < 50) return(NULL)
  sd_b  <- sd(g$est); mad_b <- mad(g$est) # mad() already *1.4826
  data.frame(cell=g$cell[1], q=g$q[1], eta_d=g$eta_d[1], G=g$G[1], engine=g$engine[1],
    n=n, mean_se=mean(g$se), sd_beta=sd_b, mad_beta=mad_b,
    R_sd = mean(g$se)/sd_b, R_mad = mean(g$se)/mad_b,
    mcse = (mean(g$se)/sd_b)/sqrt(2*(n-1)),   # approx MCSE of a ratio via sd
    conv0 = mean(g$conv==0, na.rm=TRUE), evt = mean(g$event_rate))
}))
R <- R[order(R$cell, R$engine), ]

band <- function(eta, r) {
  if (eta >= -2) { if (r>=0.95 && r<=1.05) "PASS" else if (r>=0.90 && r<=1.10) "BORDERLINE" else "FAIL" }
  else           { if (r>=0.90 && r<=1.15) "PASS" else if (r>=0.80 && r<=1.25) "BORDERLINE" else "FAIL" }
}
R$verdict <- mapply(band, R$eta_d, R$R_sd)
R$anticons <- R$verdict=="FAIL" & R$R_sd < 1
write.table(R, "R_summary.tsv", sep="\t", row.names=FALSE, quote=FALSE)

cat("\n=== R_j = mean(SE)/sd(beta-hat)   [sd GATES; mad shown alongside] ===\n")
for (e in c("mspl","ml","glmer","glmmTMB")) {
  s <- R[R$engine==e, ]
  cat(sprintf("\n--- %s ---\n", toupper(e)))
  cat(sprintf("%-4s %-3s %6s %3s %5s %8s %8s %8s %-11s\n","cell","q","eta_d","G","n","R(sd)","R(mad)","conv0","verdict"))
  for (i in seq_len(nrow(s))) with(s[i,], cat(sprintf("%-4d %-3s %6.0f %3d %5d %8.4f %8.4f %8.3f %-11s\n",
     cell,q,eta_d,G,n,R_sd,R_mad,conv0,verdict)))
}
cat("\n=== CAMPAIGN VERDICT (prereg sec 5) ===\n")
m <- R[R$engine=="mspl", ]
cat("MSPL cells:", nrow(m), " PASS:", sum(m$verdict=="PASS"),
    " BORDERLINE:", sum(m$verdict=="BORDERLINE"), " FAIL:", sum(m$verdict=="FAIL"), "\n")
cat("ANTI-CONSERVATIVE FAILS (R<1 and outside band):", sum(m$anticons), "\n")
cat(if (sum(m$anticons)>0) ">>> CAMPAIGN FAILS (one anti-conservative FAIL fails it)\n" else ">>> no anti-conservative FAIL\n")
