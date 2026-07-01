#!/usr/bin/env Rscript
# Post-hoc t-interval recompute on banked g-sweep coverage replicates.
#
# drmTMB builds the Wald SD interval exactly symmetric on the log scale
# (profile.R:1612-1626): [exp(m - z*s), exp(m + z*s)] with z = qnorm(.975).
# So from the banked response-scale endpoints we recover, exactly:
#     m  = (log L + log U) / 2        (log-scale point)
#     s  = (log U - log L) / (2 z)    (log-scale SE)
# and rebuild a t-interval on the SAME log scale:
#     [exp(m - t*s), exp(m + t*s)],  t = qt(.975, df).
# This isolates effect (a) df-narrowness (z -> t widening) on the IDENTICAL
# fits, so the wald-vs-t coverage delta is a clean paired comparison.
# It does NOT touch effect (b) ML shrinkage bias (the log-scale centre m is
# unchanged) -- that is REML's job, not the quantile's.
#
# df candidates: g-1 (Satterthwaite-style between-group df, the doctrine
# headline) and g-2 (sensitivity). animal = fixed-8 pedigree -> g=8 always.
# cor_ targets are excluded (correlation is not log-linked; recovery invalid).

ROOT <- "/Users/z3437171/Dropbox/Github Local/drmTMB"
ART  <- file.path(ROOT, "docs/dev-log/simulation-artifacts")
z <- stats::qnorm(0.975)

lanes <- list(
  list(kind="sigma", g=8L,  dir=file.path(ART, "2026-06-27-sigma-slope-coverage-grid-local")),
  list(kind="sigma", g=16L, dir=file.path(ART, "2026-06-27-slope-coverage-gsweep-local/gsweep-sigma-g16")),
  list(kind="sigma", g=32L, dir=file.path(ART, "2026-06-27-slope-coverage-gsweep-local/gsweep-sigma-g32")),
  list(kind="q2",    g=8L,  dir=file.path(ART, "2026-06-27-q2-slope-coverage-grid-local")),
  list(kind="q2",    g=16L, dir=file.path(ART, "2026-06-27-slope-coverage-gsweep-local/gsweep-q2-g16")),
  list(kind="q2",    g=32L, dir=file.path(ART, "2026-06-27-slope-coverage-gsweep-local/gsweep-q2-g32"))
)

parse_meta <- function(fn) {
  # e.g. 02-phylo-sigma_x-replicates.tsv  -> provider=phylo target=sigma_x
  base <- sub("-replicates\\.tsv$", "", basename(fn))
  parts <- strsplit(base, "-", fixed=TRUE)[[1]]
  provider <- parts[2]
  target   <- paste(parts[-c(1,2)], collapse="-")
  list(provider=provider, target=target)
}

rows <- list()
for (lane in lanes) {
  files <- list.files(lane$dir, pattern="-replicates\\.tsv$", full.names=TRUE)
  for (f in files) {
    meta <- parse_meta(f)
    if (grepl("cor", meta$target)) next            # correlation: not log-linked
    g <- if (meta$provider == "animal") 8L else lane$g
    df1 <- g - 1L; df2 <- max(g - 2L, 1L)
    t1 <- stats::qt(0.975, df1); t2 <- stats::qt(0.975, df2)
    d <- tryCatch(read.delim(f, stringsAsFactors=FALSE), error=function(e) NULL)
    if (is.null(d) || !nrow(d)) next
    truth <- if ("truth_sd" %in% names(d)) d$truth_sd else d$truth_value
    L <- suppressWarnings(as.numeric(d$wald_lower))
    U <- suppressWarnings(as.numeric(d$wald_upper))
    fin <- is.finite(L) & is.finite(U) & L > 0 & U > 0 & is.finite(truth)
    if (!any(fin)) next
    L <- L[fin]; U <- U[fin]; tr <- truth[fin]
    m <- (log(L) + log(U)) / 2
    s <- (log(U) - log(L)) / (2 * z)
    wz_lo <- L; wz_hi <- U
    wt1_lo <- exp(m - t1*s); wt1_hi <- exp(m + t1*s)
    wt2_lo <- exp(m - t2*s); wt2_hi <- exp(m + t2*s)
    cov_z  <- mean(tr >= wz_lo  & tr <= wz_hi)
    cov_t1 <- mean(tr >= wt1_lo & tr <= wt1_hi)
    cov_t2 <- mean(tr >= wt2_lo & tr <= wt2_hi)
    # profile coverage on its own (smaller, censored) denominator
    if ("profile_contains" %in% names(d)) {
      pc <- d$profile_contains[fin]
      pc <- suppressWarnings(as.logical(pc))
      n_prof <- sum(!is.na(pc)); cov_p <- if (n_prof>0) mean(pc, na.rm=TRUE) else NA_real_
    } else { n_prof <- 0L; cov_p <- NA_real_ }
    width_ratio_t1 <- mean((wt1_hi - wt1_lo) / (wz_hi - wz_lo))
    rows[[length(rows)+1]] <- data.frame(
      kind=lane$kind, g=g, provider=meta$provider, target=meta$target,
      n_fin=length(tr), df1=df1,
      cov_waldz=cov_z, cov_waldt_gm1=cov_t1, cov_waldt_gm2=cov_t2,
      cov_profile=cov_p, n_prof=n_prof,
      width_ratio_t1=width_ratio_t1, stringsAsFactors=FALSE)
  }
}
res <- do.call(rbind, rows)

fmt <- function(x) formatC(x, format="f", digits=3, width=6)
cat("\n=== PER-TARGET (log-scale SD targets only; paired z-vs-t on identical fits) ===\n")
res <- res[order(res$kind, res$g, res$provider, res$target), ]
print(within(res, {
  cov_waldz<-fmt(cov_waldz); cov_waldt_gm1<-fmt(cov_waldt_gm1)
  cov_waldt_gm2<-fmt(cov_waldt_gm2); cov_profile<-fmt(cov_profile)
  width_ratio_t1<-fmt(width_ratio_t1)
}), row.names=FALSE)

cat("\n=== POOLED BY LANE x g (clean-g providers: phylo/spatial/relmat; animal shown separately) ===\n")
res$cleang <- res$provider != "animal"
agg <- function(sub) {
  # rep-weighted pooled coverage
  w <- sub$n_fin
  data.frame(
    n_targets=nrow(sub), n_fin=sum(w),
    cov_waldz=sum(sub$cov_waldz*w)/sum(w),
    cov_waldt_gm1=sum(sub$cov_waldt_gm1*w)/sum(w),
    cov_waldt_gm2=sum(sub$cov_waldt_gm2*w)/sum(w),
    width_ratio_t1=sum(sub$width_ratio_t1*w)/sum(w))
}
for (k in c("sigma","q2")) for (gg in c(8,16,32)) {
  sub <- res[res$kind==k & res$g==gg & res$cleang, ]
  if (!nrow(sub)) next
  a <- agg(sub)
  cat(sprintf("%-6s g=%-2d  n_tgt=%d n=%5d   waldz=%s  waldt(g-1)=%s  waldt(g-2)=%s  width x%s\n",
      k, gg, a$n_targets, a$n_fin, fmt(a$cov_waldz), fmt(a$cov_waldt_gm1),
      fmt(a$cov_waldt_gm2), fmt(a$width_ratio_t1)))
}
cat("\n(animal, fixed g=8:)\n")
for (k in c("sigma","q2")) {
  sub <- res[res$kind==k & res$provider=="animal", ]
  if (!nrow(sub)) next
  a <- agg(sub)
  cat(sprintf("%-6s animal   n_tgt=%d n=%5d   waldz=%s  waldt(g-1=7)=%s  width x%s\n",
      k, a$n_targets, a$n_fin, fmt(a$cov_waldz), fmt(a$cov_waldt_gm1), fmt(a$width_ratio_t1)))
}

out <- "/tmp/t_recompute_results.tsv"
write.table(res, out, sep="\t", row.names=FALSE, quote=FALSE)
cat(sprintf("\nwrote %s\n", out))
