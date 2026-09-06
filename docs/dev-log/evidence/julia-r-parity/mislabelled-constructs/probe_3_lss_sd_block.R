suppressMessages(devtools::load_all(Sys.getenv("WT"), quiet = TRUE))
set.seed(2026090501)
n_study <- 14L; n_each <- 8L; n <- n_study * n_each
study <- factor(rep(seq_len(n_study), each = n_each))
lab_pool <- c("Beta", "alpha", "gamma")
study_lab <- lab_pool[rep_len(c(1L, 2L, 3L), n_study)]
dat <- data.frame(x = rnorm(n), z = rnorm(n), study = study,
                  s_chr = rep(study_lab, each = n_each), stringsAsFactors = FALSE)
dat$s_fac <- factor(dat$s_chr)
study_sd <- exp(-1.0 + c(Beta = 0.5, alpha = -0.3, gamma = 0.1)[study_lab])
study_effect <- study_sd * rnorm(n_study)
dat$y <- 0.10 + 0.40 * dat$x + study_effect[study] + rnorm(n, 0, exp(-1.0 + 0.15 * dat$z))

blk <- function(form) {
  ft <- drmTMB(form, gaussian(), dat, engine = "tmb")
  fj <- drmTMB(form, gaussian(), dat, engine = "julia")
  list(t = fixef(ft), j = fixef(fj),
       llt = as.numeric(logLik(ft)), llj = as.numeric(logLik(fj)))
}
cmp <- function(tag, form) {
  r <- tryCatch(blk(form), error = function(e) e)
  if (inherits(r, "error")) { cat(sprintf("%-22s REFUSED %s\n", tag,
      substr(gsub("\\s+"," ",conditionMessage(r)),1,180))); return(invisible()) }
  cat("\n##", tag, "  logLik tmb =", sprintf("%.6f", r$llt),
      " jl =", sprintf("%.6f", r$llj), " diff =", sprintf("%.3g", abs(r$llt-r$llj)), "\n")
  # map tmb dpar "sd(study)" onto julia dpar "sd"
  key <- function(k) sub("^sd\\(.*\\)$", "sd", k)
  tn <- setNames(r$t, key(names(r$t))); jn <- setNames(r$j, key(names(r$j)))
  worst <- 0
  for (k in intersect(names(tn), names(jn))) {
    a <- tn[[k]]; b <- jn[[k]]
    if (!identical(names(a), names(b))) {
      cat(sprintf("  %-8s NAME_DIFF tmb=%s jl=%s\n", k,
          paste(names(a),collapse=","), paste(names(b),collapse=","))); next
    }
    d <- max(abs(a - b)); worst <- max(worst, d)
    cat(sprintf("  %-8s max|diff|=%.6g  %s\n", k, d,
        paste(sprintf("%s: tmb %.6f jl %.6f", names(a), a, b), collapse=" | ")))
  }
  cat("  VERDICT:", if (worst <= 1e-4) "FAITHFUL" else "MISLABELLED_SILENT",
      sprintf("(worst %.6g)\n", worst))
}
cmp("sd(study) ~ s_chr", bf(y ~ x + (1 | study), sigma ~ z, sd(study) ~ s_chr))
cmp("sd(study) ~ s_fac", bf(y ~ x + (1 | study), sigma ~ z, sd(study) ~ s_fac))
cmp("sd(study) ~ 1",     bf(y ~ x + (1 | study), sigma ~ z, sd(study) ~ 1))
