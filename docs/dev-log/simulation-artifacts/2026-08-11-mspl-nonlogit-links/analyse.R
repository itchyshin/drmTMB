# G1 — grading against PREREGISTRATION.md §6 and §7. Nothing here is negotiable
# after the fact; the rule was frozen before the first replicate (§8.6).
#
# Usage: Rscript --no-init-file analyse.R [--raw data/g1_raw.tsv.gz]

args <- commandArgs(trailingOnly = TRUE)
getarg <- function(k, d = NULL) { i <- match(k, args); if (is.na(i)) d else args[i + 1L] }
RAW <- getarg("--raw", "data/g1_raw.tsv.gz")

d <- read.delim(gzfile(RAW), stringsAsFactors = FALSE)
stopifnot(nrow(d) == 88000L, length(unique(d$cell)) == 88L)

mspl <- d[d$estimator == "mspl", ]
ml   <- d[d$estimator == "ml", ]

# ---- primary endpoint (prereg §6) -----------------------------------------
# E1 & E2 & E3. NA counts as FAILURE, never a dropped row -- E1's first scorer
# filtered with is.finite() and removed exactly the values that were evidence.
prim <- function(r) {
  e1 <- !is.na(r$fi_finite_pos) & r$fi_finite_pos
  e2 <- !is.na(r$logdet_fi) & is.finite(r$logdet_fi)
  e3 <- !is.na(r$beta) & is.finite(r$beta)
  e1 & e2 & e3
}
mspl$pass <- prim(mspl)

cp_lower <- function(k, n, conf = 0.95) {
  if (k == 0) return(0)
  stats::qbeta((1 - conf) / 2, k, n - k + 1)
}

cells <- unique(d[, c("cell", "cond", "q", "eta_d", "G", "corner")])
cells <- cells[order(cells$cell), ]
res <- do.call(rbind, lapply(seq_len(nrow(cells)), function(i) {
  cc <- cells[i, ]
  s <- mspl[mspl$cell == cc$cell, ]
  m <- ml[ml$cell == cc$cell, ]
  k <- sum(s$pass); n <- nrow(s)
  # Control (prereg §7): ML |SE| > 1e3, failed fit, or non-finite/absent SE.
  ml_div <- mean(is.na(m$se) | !is.finite(m$se) | abs(m$se) > 1e3 |
                   (!is.na(m$err) & nzchar(m$err)))
  data.frame(cc,
             n = n, k = k, prop = k / n, cp_lo = cp_lower(k, n),
             cell_pass = (k / n >= 0.99) && (cp_lower(k, n) >= 0.97),
             ml_div = ml_div,
             median_logdet = suppressWarnings(median(s$logdet_fi, na.rm = TRUE)),
             median_event = median(s$event_rate, na.rm = TRUE),
             hess_pd = mean(s$hess_pd %in% TRUE),
             conv0 = mean(s$conv %in% 0L),
             stringsAsFactors = FALSE)
}))

cat("=== PRIMARY ENDPOINT, per cell (prereg §6) ===\n")
cat("cells:", nrow(res), " PASS:", sum(res$cell_pass), " FAIL:", sum(!res$cell_pass), "\n\n")

cat("=== BY CONDITION (graded separately -- never pooled, prereg §6) ===\n")
by_cond <- do.call(rbind, lapply(unique(res$cond), function(cn) {
  r <- res[res$cond == cn, ]
  s <- mspl[mspl$cond == cn, ]
  data.frame(cond = cn, cells = nrow(r), cells_pass = sum(r$cell_pass),
             fits = nrow(s), fits_pass = sum(s$pass),
             prop = sum(s$pass) / nrow(s),
             min_cell_prop = min(r$prop),
             verdict = if (all(r$cell_pass)) "PASS" else "FAIL",
             stringsAsFactors = FALSE)
}))
print(by_cond, row.names = FALSE, digits = 6)

cat("\n=== FAILING CELLS (if any) ===\n")
bad <- res[!res$cell_pass, ]
if (nrow(bad)) print(bad[, c("cell","cond","q","eta_d","G","corner","k","n","prop","cp_lo","ml_div")],
                     row.names = FALSE, digits = 5) else cat("none\n")

cat("\n=== CONTROL (prereg §7): ML divergence in the two deepest cells per condition ===\n")
ctrl <- do.call(rbind, lapply(unique(res$cond), function(cn) {
  r <- res[res$cond == cn & !res$corner, ]
  deep <- sort(unique(r$eta_d))[1:2]
  rr <- r[r$eta_d %in% deep, ]
  data.frame(cond = cn, deepest_eta_d = paste(deep, collapse = ", "),
             ml_div_min = min(rr$ml_div), ml_div_mean = mean(rr$ml_div),
             control_ok = min(rr$ml_div) >= 0.50,
             median_event_deepest = median(rr$median_event),
             stringsAsFactors = FALSE)
}))
print(ctrl, row.names = FALSE, digits = 4)

cat("\n=== LOGIT CONTROL vs F1 (prereg §3a: must reproduce, or the harness is wrong) ===\n")
lg <- res[res$cond == "logit" & !res$corner, ]
cat("logit main cells:", nrow(lg), " all PASS:", all(lg$cell_pass),
    " min prop:", min(lg$prop), "\n")

cat("\n=== SECONDARY (reported, not gating): median logdet monotone in eta_d ===\n")
for (cn in unique(res$cond)) {
  r <- res[res$cond == cn & !res$corner, ]
  ok <- all(sapply(split(r, list(r$q, r$G), drop = TRUE), function(s) {
    s <- s[order(-s$eta_d), ]
    all(diff(s$median_logdet) <= 1e-8)
  }))
  cat(sprintf("%-18s monotone declining with depth: %s\n", cn, ok))
}

cat("\n=== ADVERSARIAL CORNER (prereg §5.3) ===\n")
co <- res[res$corner, ]
print(co[, c("cell","cond","eta_d","k","n","prop","cp_lo","cell_pass","ml_div")],
      row.names = FALSE, digits = 5)
cat("corner c_n:", unique(round(mspl$c_n[mspl$cell %in% co$cell], 5)), "\n")

cat("\n=== LINK INTEGRITY (no silent logit fallback) ===\n")
chk <- table(mspl$cond, mspl$rep_link, useNA = "ifany")
print(chk)

write.csv(res, "G1-cell-results.csv", row.names = FALSE)
cat("\nwrote G1-cell-results.csv\n")
