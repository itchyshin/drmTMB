# G1b — grading against PREREGISTRATION-G1b.md §3. Frozen before any replicate.
# Usage: Rscript --no-init-file analyse_g1b.R [--raw data/g1b_raw.tsv.gz]

args <- commandArgs(trailingOnly = TRUE)
getarg <- function(k, d = NULL) { i <- match(k, args); if (is.na(i)) d else args[i + 1L] }
RAW <- getarg("--raw", "data/g1b_raw.tsv.gz")

d <- read.delim(gzfile(RAW), stringsAsFactors = FALSE)
stopifnot(nrow(d) == 88000L, length(unique(d$cell)) == 88L)

mspl <- d[d$estimator == "mspl", ]
ml   <- d[d$estimator == "ml", ]

# Endpoint C, and endpoint F (evaluated on the completed subset only).
mspl$C <- mspl$completed %in% TRUE
mspl$F <- mspl$C &
  (!is.na(mspl$fi_finite_pos) & mspl$fi_finite_pos) &
  (!is.na(mspl$logdet_fi) & is.finite(mspl$logdet_fi)) &
  (!is.na(mspl$beta) & is.finite(mspl$beta))

cp_lower <- function(k, n) if (n == 0 || k == 0) 0 else stats::qbeta(0.025, k, n - k + 1)

cells <- unique(d[, c("cell", "cond", "q", "eta_d", "G", "corner")])
cells <- cells[order(cells$cell), ]
res <- do.call(rbind, lapply(seq_len(nrow(cells)), function(i) {
  cc <- cells[i, ]
  s <- mspl[mspl$cell == cc$cell, ]
  m <- ml[ml$cell == cc$cell, ]
  n_tot <- nrow(s); n_comp <- sum(s$C); k_fin <- sum(s$F)
  completion <- n_comp / n_tot
  fin_prop <- if (n_comp > 0) k_fin / n_comp else NA_real_
  cp <- if (n_comp > 0) cp_lower(k_fin, n_comp) else NA_real_
  evaluable <- completion >= 0.90            # the guard, prereg §3
  data.frame(cc, n = n_tot, n_completed = n_comp, completion = completion,
             k_finite = k_fin, fin_prop = fin_prop, cp_lo = cp,
             evaluable = evaluable,
             finiteness_ok = if (!evaluable) NA else (fin_prop >= 0.99 && cp >= 0.97),
             ml_div = mean(is.na(m$se) | !is.finite(m$se) | abs(m$se) > 1e3 |
                             (!is.na(m$err) & nzchar(m$err))),
             stringsAsFactors = FALSE)
}))

cat("=== ENDPOINT F — finiteness GIVEN completion (prereg §3) ===\n")
cat("cells:", nrow(res),
    " evaluable:", sum(res$evaluable),
    " INSUFFICIENT-COMPLETION:", sum(!res$evaluable), "\n")
cat("finiteness holds in:", sum(res$finiteness_ok %in% TRUE), "of", sum(res$evaluable), "evaluable cells\n\n")

cat("=== BY CONDITION ===\n")
by_cond <- do.call(rbind, lapply(unique(res$cond), function(cn) {
  r <- res[res$cond == cn, ]
  s <- mspl[mspl$cond == cn, ]
  verdict <- if (any(r$finiteness_ok %in% FALSE)) "FAIL"
             else if (any(!r$evaluable)) "COMPLETION-LIMITED"
             else "PASS"
  data.frame(cond = cn, cells = nrow(r),
             completion = sum(s$C) / nrow(s),
             min_cell_completion = min(r$completion),
             fits_completed = sum(s$C), fits_finite = sum(s$F),
             finite_given_completed = sum(s$F) / max(sum(s$C), 1),
             non_finite_completed = sum(s$C) - sum(s$F),
             verdict = verdict, stringsAsFactors = FALSE)
}))
print(by_cond, row.names = FALSE, digits = 6)

cat("\n=== THE DECISIVE COUNT: completed fits that were NOT finite ===\n")
cat("(this is the only quantity that is evidence AGAINST MSPL finiteness)\n")
nf <- mspl[mspl$C & !mspl$F, ]
cat("total across all conditions:", nrow(nf), "of", sum(mspl$C), "completed fits\n")
if (nrow(nf)) print(table(nf$cond)) else cat("none\n")

cat("\n=== cells failing finiteness where evaluable ===\n")
bad <- res[res$finiteness_ok %in% FALSE, ]
if (nrow(bad)) print(bad[, c("cell","cond","q","eta_d","G","n_completed","k_finite","fin_prop","cp_lo")],
                     row.names = FALSE, digits = 5) else cat("none\n")

cat("\n=== cells below the 0.90 completion guard ===\n")
ins <- res[!res$evaluable, ]
if (nrow(ins)) print(ins[, c("cell","cond","q","eta_d","G","completion","n_completed","k_finite","ml_div")],
                     row.names = FALSE, digits = 5) else cat("none\n")

cat("\n=== logit control ===\n")
lg <- res[res$cond == "logit", ]
cat("all evaluable:", all(lg$evaluable), " all finiteness_ok:", all(lg$finiteness_ok %in% TRUE),
    " min completion:", min(lg$completion), "\n")

write.csv(res, "G1b-cell-results.csv", row.names = FALSE)
cat("\nwrote G1b-cell-results.csv\n")
