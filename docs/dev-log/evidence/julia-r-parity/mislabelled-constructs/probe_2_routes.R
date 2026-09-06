# Probe 2: does the refusal that closes the two MISLABELLED_SILENT shapes on
# the Gaussian location-scale route HOLD on other families and routes?
# DRM.jl's `_bridge_check_coef_labels_fidelity` skips any block it cannot
# render itself (`rendered === nothing && continue`, `vouched || continue`),
# so a route where rendering bails would still report DRM.jl's coefficients
# under R's names.
suppressMessages(devtools::load_all(Sys.getenv("WT"), quiet = TRUE))
options(warn = 1)

mk <- function(n = 200L, seed = 20260905L) {
  set.seed(seed)
  x <- stats::rnorm(n); z <- stats::rnorm(n)
  g_chr <- sample(c("low", "mid", "high"), n, TRUE)
  eff <- c(low = 0, mid = 0.6, high = -0.9)
  d <- data.frame(x = x, z = z, g_chr = g_chr,
                  g_fac = factor(g_chr, levels = c("low", "mid", "high")),
                  stringsAsFactors = FALSE)
  d$m_chr  <- sample(c("Beta", "alpha", "gamma"), n, TRUE)
  meff     <- c(Beta = 0.5, alpha = -0.4, gamma = 0.2)
  d$g_empty <- factor(g_chr, levels = c("low", "mid", "high", "zz"))
  d$grp    <- factor(sample(paste0("s", 1:8), n, TRUE))
  lin      <- 0.3 + 0.5 * x + meff[d$m_chr]
  d$y      <- lin + stats::rnorm(n, 0, 0.5)                # gaussian
  d$cnt    <- stats::rpois(n, exp(0.4 + 0.3 * x + 0.5 * meff[d$m_chr]))
  d$nb     <- stats::rnbinom(n, mu = exp(0.4 + 0.3 * x + 0.5 * meff[d$m_chr]), size = 3)
  d$bin    <- stats::rbinom(n, 1, stats::plogis(0.2 + 0.5 * x + meff[d$m_chr]))
  d$succ   <- stats::rbinom(n, 10, stats::plogis(0.2 + 0.5 * x + meff[d$m_chr]))
  d$fail   <- 10L - d$succ
  d$prop   <- pmin(pmax(stats::plogis(lin + stats::rnorm(n, 0, 0.3)), 1e-3), 1 - 1e-3)
  d$pos    <- exp(lin + stats::rnorm(n, 0, 0.3))
  d$ord    <- factor(cut(lin + stats::rnorm(n, 0, 0.5), 3, labels = c("a", "b", "c")),
                     ordered = TRUE)
  d
}
d <- mk()
cat("R levels of m_chr:", paste(levels(factor(d$m_chr)), collapse = ", "),
    "| codepoint:", paste(sort(unique(d$m_chr), method = "radix"), collapse = ", "), "\n\n")

classify <- function(tag, form, fam, data) {
  ft <- try(drmTMB(form, family = fam, data = data, engine = "tmb"), silent = TRUE)
  tmb_ok <- !inherits(ft, "try-error")
  fj <- try(drmTMB(form, family = fam, data = data, engine = "julia"), silent = TRUE)
  if (inherits(fj, "try-error")) {
    msg <- gsub("\\s+", " ", conditionMessage(attr(fj, "condition")))
    kind <- if (grepl("does not match the design DRM.jl built", msg, fixed = TRUE)) {
      "REFUSED_fidelity"
    } else if (grepl("cannot reproduce R's design", msg, fixed = TRUE)) {
      "REFUSED_drmTMB"
    } else "REFUSED_other"
    cat(sprintf("%-34s %-17s %s\n", tag, kind, substr(msg, 1, 150)))
    return(invisible(NULL))
  }
  if (!tmb_ok) {
    cat(sprintf("%-34s JULIA_ONLY_FIT    jl names: %s\n", tag,
                paste(names(unlist(fixef(fj))), collapse = " ")))
    return(invisible(NULL))
  }
  ct <- unlist(fixef(ft)); cj <- unlist(fixef(fj))
  if (!identical(names(ct), names(cj))) {
    cat(sprintf("%-34s NAME_DIFF         tmb=%s | jl=%s\n", tag,
                paste(names(ct), collapse = ","), paste(names(cj), collapse = ",")))
    return(invisible(NULL))
  }
  dd <- max(abs(ct - cj))
  cat(sprintf("%-34s %-17s max|coef diff| = %.6g   names: %s\n", tag,
              if (dd <= 1e-4) "FAITHFUL" else "MISLABELLED_SILENT", dd,
              paste(names(ct), collapse = " ")))
  invisible(NULL)
}

cat("---- shape 2 (character column, locale order != codepoint order) ----\n")
classify("F2 poisson  mu",        bf(cnt ~ x + m_chr), poisson(), d)
classify("F3 nbinom2  mu+sigma",  bf(nb ~ x + m_chr, sigma ~ 1), nbinom2(), d)
classify("F4 binomial mu",        bf(bin ~ x + m_chr), binomial(), d)
classify("F5 gamma    mu+sigma",  bf(pos ~ x + m_chr, sigma ~ 1), Gamma(link = "log"), d)
classify("F6 beta     mu+sigma",  bf(prop ~ x + m_chr, sigma ~ 1), beta_family(), d)
classify("F7 cumul_logit mu",     bf(ord ~ x + m_chr), cumulative_logit(), d)
classify("F8 gaussian SIGMA side",bf(y ~ x, sigma ~ m_chr), gaussian(), d)
classify("F9 nbinom2  SIGMA side",bf(nb ~ x, sigma ~ m_chr), nbinom2(), d)
classify("F10 poisson RE (1|grp)",bf(cnt ~ x + m_chr + (1 | grp)), poisson(), d)
classify("F11 gauss   RE (1|grp)",bf(y ~ x + m_chr + (1 | grp), sigma ~ 1), gaussian(), d)

cat("\n---- shape 1 (a declared factor level no row uses) ----\n")
classify("F2 poisson  mu",        bf(cnt ~ x + g_empty), poisson(), d)
classify("F3 nbinom2  mu+sigma",  bf(nb ~ x + g_empty, sigma ~ 1), nbinom2(), d)
classify("F7 cumul_logit mu",     bf(ord ~ x + g_empty), cumulative_logit(), d)
classify("F8 gaussian SIGMA side",bf(y ~ x, sigma ~ g_empty), gaussian(), d)
classify("F11 gauss   RE (1|grp)",bf(y ~ x + g_empty + (1 | grp), sigma ~ 1), gaussian(), d)

cat("\n---- controls: a properly declared factor must stay FAITHFUL ----\n")
classify("C poisson  factor",     bf(cnt ~ x + g_fac), poisson(), d)
classify("C nbinom2  factor",     bf(nb ~ x + g_fac, sigma ~ 1), nbinom2(), d)
classify("C cumul_logit factor",  bf(ord ~ x + g_fac), cumulative_logit(), d)
classify("C gauss RE factor",     bf(y ~ x + g_fac + (1 | grp), sigma ~ 1), gaussian(), d)
cat("\nDRM_JL_PATH =", Sys.getenv("DRM_JL_PATH"), "\n")
