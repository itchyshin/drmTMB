# Compares out/r_<tag>.csv (native drmTMB 0.8.1) with out/julia_<tag>.csv row by row.
# Columns: conditional mu, sigma, PIT bounds lo = F(y-), hi = F(y), residual r.
# Count families: r is randomized, so the generators differ; the check is that Julia's Phi(r) lies inside the
# R PIT interval [lo, hi] (up to 1e-6) and that mu / sigma / lo / hi agree. Continuous families: r is deterministic
# and compared directly. Writes comparison.csv. No tolerance is applied here; the table is the evidence.
tags <- sub("\\.csv$", "", sub("^r_", "", grep("^r_[a-z]", list.files("out"), value = TRUE)))
tags <- setdiff(tags, "summary")
disc <- function(t) grepl("poisson|nb2", t)
rows <- lapply(tags, function(t) {
  R <- read.csv(sprintf("out/r_%s.csv", t)); J <- read.csv(sprintf("out/julia_%s.csv", t))
  stopifnot(nrow(R) == nrow(J), all(abs(R$y - J$y) <= 1e-8 * pmax(1, abs(R$y))))
  uJ <- pnorm(J$r)
  inside <- if (disc(t)) mean(uJ >= R$lo - 1e-6 & uJ <= R$hi + 1e-6) else NA
  data.frame(tag = t, n = nrow(R),
    max_rel_mu = max(abs(R$mu - J$mu) / abs(R$mu)),
    max_abs_sigma = if (all(is.na(R$sigma))) NA else max(abs(R$sigma - J$sigma)),
    max_abs_lo = max(abs(R$lo - J$lo)), max_abs_hi = max(abs(R$hi - J$hi)),
    frac_julia_u_in_R_interval = inside,
    max_abs_r = if (disc(t)) NA else max(abs(R$r - J$r)),
    sd_r_R = sd(R$r), sd_r_julia = sd(J$r))
})
out <- do.call(rbind, rows)
Rs <- read.csv("out/r_summary.csv"); Js <- read.csv("out/julia_summary.csv")
out$ll_R <- Rs$ll[match(out$tag, Rs$tag)]; out$ll_julia <- Js$ll[match(out$tag, Js$tag)]
out$abs_ll_diff <- abs(out$ll_R - out$ll_julia)
options(width = 200); print(out, digits = 4)
write.csv(out, "comparison.csv", row.names = FALSE)
