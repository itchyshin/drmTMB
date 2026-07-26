# Analysis of the A1 marginal-bootstrap coverage campaign.
#
# Judged against the PRE-REGISTERED prediction in a1_coverage.R's header,
# written before launch:
#   1. marginal (new default) attains ~0.95 on the RE SD sd:mu:(1 | g)
#   2. conditional (old behaviour) UNDER-covers the RE SD, worsening as
#      n_groups shrinks
#   3. the fixed effect mu:x is the CONTROL -- much smaller gap there
# If (1) fails, or (2) is absent, or (3) shows an equal gap, the mechanism
# claimed in PR #843 is wrong and that is the finding.
#
# FULL DENOMINATOR. Every attempt is retained. Coverage is computed over all
# attempted replicates, not over successful ones -- a converged-only filter is
# how a coverage study lies. Attrition is reported separately and explicitly.

f <- list.files("~/drm_work/results", pattern = "\\.csv$", full.names = TRUE)
d <- do.call(rbind, lapply(f, read.csv, stringsAsFactors = FALSE))
cat("shards:", length(f), " rows:", nrow(d), "\n\n")

cat("=== ATTRITION (full denominator) ===\n")
print(table(d$status, useNA = "ifany"))
cat("\nrows with a non-finite interval:",
    sum(!is.finite(d$lo) | !is.finite(d$hi)), "/", nrow(d), "\n")
if ("boot_failed" %in% names(d)) {
  cat("bootstrap refit failures: total", sum(d$boot_failed, na.rm = TRUE),
      "| replicates with any failure:", sum(d$boot_failed > 0, na.rm = TRUE), "\n")
}

# Exact binomial CI on a coverage proportion, so we do not over-read noise.
cover_ci <- function(k, n) {
  if (n == 0) return(c(NA, NA))
  bt <- binom.test(k, n)$conf.int
  c(bt[1], bt[2])
}

agg <- function(sub) {
  n <- nrow(sub)                       # FULL denominator
  k <- sum(sub$covered %in% TRUE)      # NA counts as not-covered
  ci <- cover_ci(k, n)
  data.frame(n = n, covered = k, coverage = if (n) k / n else NA_real_,
             lo95 = ci[1], hi95 = ci[2],
             med_width = median(sub$width, na.rm = TRUE))
}

for (target in c("sd:mu:(1 | g)", "sigma", "fixef:mu:x")) {
  sub <- d[d$parm == target, ]
  if (!nrow(sub)) next
  cat("\n\n================ ", target, " ================\n")
  cat("--- overall, by re_form ---\n")
  for (rf in c("marginal", "conditional")) {
    a <- agg(sub[sub$re_form == rf, ])
    cat(sprintf("  %-12s n=%5d  coverage=%.4f  [%.4f, %.4f]  med width=%.4f\n",
                rf, a$n, a$coverage, a$lo95, a$hi95, a$med_width))
  }
  cat("--- by n_groups (the predicted gradient) ---\n")
  for (ng in sort(unique(sub$n_groups))) {
    line <- sprintf("  n_groups=%-3d", ng)
    for (rf in c("marginal", "conditional")) {
      a <- agg(sub[sub$re_form == rf & sub$n_groups == ng, ])
      line <- paste0(line, sprintf("  %s=%.4f (n=%d)", substr(rf, 1, 4), a$coverage, a$n))
    }
    cat(line, "\n")
  }
}

cat("\n\n=== VERDICT AGAINST THE PRE-REGISTERED PREDICTION ===\n")
re <- d[d$parm == "sd:mu:(1 | g)", ]
fe <- d[d$parm == "fixef:mu:x", ]
m_re <- agg(re[re$re_form == "marginal", ]);    c_re <- agg(re[re$re_form == "conditional", ])
m_fe <- agg(fe[fe$re_form == "marginal", ]);    c_fe <- agg(fe[fe$re_form == "conditional", ])
cat(sprintf("RE SD      marginal %.4f [%.4f,%.4f] vs conditional %.4f [%.4f,%.4f]  gap=%+.4f\n",
            m_re$coverage, m_re$lo95, m_re$hi95, c_re$coverage, c_re$lo95, c_re$hi95,
            m_re$coverage - c_re$coverage))
cat(sprintf("fixef mu:x marginal %.4f [%.4f,%.4f] vs conditional %.4f [%.4f,%.4f]  gap=%+.4f\n",
            m_fe$coverage, m_fe$lo95, m_fe$hi95, c_fe$coverage, c_fe$lo95, c_fe$hi95,
            m_fe$coverage - c_fe$coverage))
cat("\n(1) marginal RE SD attains ~0.95 : ",
    if (!is.na(m_re$lo95) && m_re$hi95 >= 0.93 && m_re$lo95 <= 0.97) "SUPPORTED" else "NOT SUPPORTED", "\n")
cat("(2) conditional UNDER-covers RE SD: ",
    if (!is.na(c_re$hi95) && c_re$hi95 < m_re$lo95) "SUPPORTED" else "NOT SUPPORTED", "\n")
cat("(3) fixed effect is a CONTROL      : ",
    if (abs(m_fe$coverage - c_fe$coverage) < abs(m_re$coverage - c_re$coverage))
      "SUPPORTED (smaller gap)" else "NOT SUPPORTED (gap as large or larger)", "\n")
cat("\nIf (2) is NOT SUPPORTED, or (3) is NOT SUPPORTED, the mechanism claimed in\n",
    "PR #843 is wrong and must be reported as such.\n")
