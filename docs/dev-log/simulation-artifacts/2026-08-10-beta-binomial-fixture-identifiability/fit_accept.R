# Acceptance table for the hardened beta-binomial mi() fixture, measured on the
# actual fit at test-missing-predictor-beta-binomial.R:138.
# Criteria per Fisher's Phase-2 review (gradient + max-eigenvalue + se(log_sigma_mi),
# NOT min-eigenvalue / cor / exact-0-1, which measure the wrong things).
suppressMessages(pkgload::load_all(".", quiet = TRUE))
src <- readLines("tests/testthat/test-missing-predictor-beta-binomial.R")
first <- grep("^test_that", src)[1]
eval(parse(text = paste(src[seq_len(first - 1)], collapse = "\n")), envir = globalenv())

dat <- missing_predictor_beta_binomial_data()
missing_x <- is.na(dat$success)

warns <- character(0)
fit <- withCallingHandlers(
  drmTMB(
    bf(y ~ z + mi(cover), sigma ~ 1), data = dat,
    impute = list(cover = impute_model(success ~ z, family = beta_binomial(), trials = trials)),
    missing = miss_control(predictor = "model")),
  warning = function(w) { warns <<- c(warns, conditionMessage(w)); invokeRestart("muffleWarning") })

imp <- imputed(fit)
ev <- eigen(fit$sdr$cov.fixed, only.values = TRUE)$values
gr <- tryCatch(max(abs(fit$obj$gr(fit$fit$par))), error = function(e) NA_real_)
sdsum <- summary(fit$sdr, "fixed")
smi <- grep("sigma_mi|log_sigma_mi", rownames(sdsum), value = TRUE)
se_smi <- if (length(smi)) max(sdsum[smi, "Std. Error"], na.rm = TRUE) else NA_real_

conv_warn <- any(grepl("convergence", warns, ignore.case = TRUE))
pass <- function(x) if (isTRUE(x)) "PASS" else "FAIL"

cat("\n================ ACCEPTANCE TABLE ================\n")
cat(sprintf("  max|gradient|          : %.3e   [< 1e-06]   %s\n", gr, pass(gr < 1e-6)))
cat(sprintf("  convergence warning    : %-11s [none]      %s\n",
            if (conv_warn) "PRESENT" else "none", pass(!conv_warn)))
cat(sprintf("  sdr$pdHess             : %-11s [TRUE]      %s\n",
            isTRUE(fit$sdr$pdHess), pass(isTRUE(fit$sdr$pdHess))))
cat(sprintf("  max eigen(cov.fixed)   : %.4g       [< 100]     %s\n", max(ev), pass(max(ev) < 100)))
cat(sprintf("  condition number       : %.4g\n", max(abs(ev)) / min(abs(ev))))
cat(sprintf("  se(log_sigma_mi)       : %.4g       [< 1]       %s\n", se_smi, pass(se_smi < 1)))
cat("  ---- the three literal assertions that are RED on main ----\n")
a1 <- all(is.finite(imp$std_error)); a2 <- all(imp$std_error > 0)
a3 <- identical(imp$uncertainty_status, rep("ok", sum(missing_x)))
cat(sprintf("  L152 all finite(std_error) : %-5s  %s\n", a1, pass(a1)))
cat(sprintf("  L153 all std_error > 0     : %-5s  %s\n", a2, pass(a2)))
cat(sprintf("  L154 uncertainty_status ok : %-5s  %s  (%s)\n", a3, pass(a3),
            paste(unique(imp$uncertainty_status), collapse = ",")))
cat(sprintf("\n  recovered sigma_mi_cover : %.4f  (truth 0.35)\n",
            unname(coef(fit, "sigma_mi_cover"))))
cat("==================================================\n")
if (length(warns)) cat("warnings seen:\n", paste("  -", warns, collapse = "\n"), "\n")
