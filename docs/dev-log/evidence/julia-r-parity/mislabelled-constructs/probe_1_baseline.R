# Probe 1: do the two MISLABELLED_SILENT shapes named by PR #1227 still
# mislabel on drmTMB origin/main (NO guard) against DRM.jl aee371cc9?
# Classification per case: FAITHFUL / REFUSED / MISLABELLED_SILENT.
suppressMessages(devtools::load_all(Sys.getenv("WT"), quiet = TRUE))
options(warn = 1)

mk <- function(n = 150L, seed = 20260905L) {
  set.seed(seed)
  x <- stats::rnorm(n); z <- stats::rnorm(n)
  g_chr <- sample(c("low", "mid", "high"), n, TRUE)
  eff <- c(low = 0, mid = 0.6, high = -0.9)
  d <- data.frame(x = x, z = z, g_chr = g_chr,
                  g_fac = factor(g_chr, levels = c("low", "mid", "high")),
                  stringsAsFactors = FALSE)
  # shape 2: character column whose R (locale) sort order is NOT codepoint order
  d$m_chr <- sample(c("Beta", "alpha", "gamma"), n, TRUE)
  # shape 1: a declared factor level that no row uses
  d$g_empty <- factor(g_chr, levels = c("low", "mid", "high", "zz"))
  d$y <- 0.3 + 0.8 * x + 0.4 * x^2 + eff[g_chr] + stats::rnorm(n, 0, 0.5)
  d$flag <- d$x > 0
  d
}
d <- mk()
cat("R levels of m_chr:", paste(levels(factor(d$m_chr)), collapse = ", "), "\n")
cat("codepoint order   :", paste(sort(unique(d$m_chr), method = "radix"), collapse = ", "), "\n")

classify <- function(tag, form, fam, data) {
  ft <- try(drmTMB(form, family = fam, data = data, engine = "tmb"), silent = TRUE)
  if (inherits(ft, "try-error")) {
    cat(sprintf("%-28s TMB_FAILED  %s\n", tag, gsub("\n", " ", conditionMessage(attr(ft, "condition")))))
    return(invisible(NULL))
  }
  fj <- try(drmTMB(form, family = fam, data = data, engine = "julia"), silent = TRUE)
  if (inherits(fj, "try-error")) {
    msg <- gsub("\\s+", " ", conditionMessage(attr(fj, "condition")))
    cat(sprintf("%-28s REFUSED     %s\n", tag, substr(msg, 1, 220)))
    return(invisible(NULL))
  }
  ct <- unlist(fixef(ft)); cj <- unlist(fixef(fj))
  if (!identical(names(ct), names(cj))) {
    cat(sprintf("%-28s NAME_DIFF   tmb=%s | jl=%s\n", tag,
                paste(names(ct), collapse = ","), paste(names(cj), collapse = ",")))
    return(invisible(NULL))
  }
  dd <- max(abs(ct - cj))
  verdict <- if (dd <= 1e-4) "FAITHFUL" else "MISLABELLED_SILENT"
  cat(sprintf("%-28s %-11s max|coef diff| = %.6g  (names identical: %s) logLik tmb=%.6f jl=%.6f\n",
              tag, verdict, dd, paste(names(ct), collapse = " "),
              as.numeric(logLik(ft)), as.numeric(logLik(fj))))
  invisible(NULL)
}

cat("\n================ FIXTURE F1: gaussian location-scale ================\n")
classify("chr_collation",      bf(y ~ x + m_chr, sigma ~ 1), gaussian(), d)
classify("factor_chr_collation", bf(y ~ x + factor(m_chr), sigma ~ 1), gaussian(), d)
classify("unused_level",       bf(y ~ x + g_empty, sigma ~ 1), gaussian(), d)
classify("CONTROL_factor",     bf(y ~ x + g_fac, sigma ~ 1), gaussian(), d)
classify("CONTROL_poly2",      bf(y ~ poly(x, 2), sigma ~ 1), gaussian(), d)
cat("\nDRM_JL_PATH =", Sys.getenv("DRM_JL_PATH"), "\n")
