## F6-julia-re-boundary-flag: drmTMB twin on the 50 re_sd1e-4 datasets of sweep-oct16 t4 (cell k = 12).
## Run from this folder:  Rscript f6_drmTMB.R > f6_drmTMB.out 2>&1
## Data: ../../data/re_sd1e-4_rNN.csv (R seed = (20261017500 + rep - 1) %% 2^31; ../../t4_gen_data.R)
suppressPackageStartupMessages(library(drmTMB))
print(sessionInfo())
cat("drmTMB", format(packageVersion("drmTMB")), " RemoteSha:",
    tryCatch(utils::packageDescription("drmTMB")$RemoteSha, error = function(e) NA), "\n")
cat("drmTMB checkout HEAD:", tryCatch(system("git -C /home/user/drmTMB rev-parse HEAD", intern = TRUE),
                                     error = function(e) NA), "\n")
cat("pin ca3ddefa5ea11bbfd3b765615dfbb89305d2485a; files changed in R/ src/ DESCRIPTION since the pin:",
    length(system("git -C /home/user/drmTMB diff --name-only ca3ddefa5ea11bbfd3b765615dfbb89305d2485a HEAD -- R src DESCRIPTION",
                  intern = TRUE)), "\n\n")

rows <- list()
for (r in 1:50) {
  d <- read.csv(file.path("..", "..", "data", sprintf("re_sd1e-4_r%02d.csv", r)))
  d$g <- factor(d$g)
  lmll <- as.numeric(logLik(lm(y ~ x, data = d)))
  fit <- suppressWarnings(drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(), data = d))
  chk <- suppressWarnings(check_drm(fit))
  w <- chk[chk$status %in% c("warning", "error"), , drop = FALSE]
  rows[[r]] <- data.frame(rep = r, boundary = as.numeric(logLik(fit)) - lmll < 1e-6,
                          ll_minus_lm = as.numeric(logLik(fit)) - lmll,
                          is_converged = is_converged(fit), status = convergence_status(fit),
                          max_grad = max(abs(fit$gradient)),
                          check_warn = paste0(w$check, "=", w$status, collapse = "; "))
}
res <- do.call(rbind, rows)
print(res, digits = 4)
cat("\nboundary datasets:", sum(res$boundary), "; is_converged TRUE among them:",
    sum(res$is_converged[res$boundary]), "; status table:\n")
print(table(boundary = res$boundary, status = res$status))

cat("\n== rep 1 in full ==\n")
d <- read.csv(file.path("..", "..", "data", "re_sd1e-4_r01.csv")); d$g <- factor(d$g)
fit <- drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(), data = d)
cat("logLik", format(as.numeric(logLik(fit)), digits = 12), "  lm logLik",
    format(as.numeric(logLik(lm(y ~ x, data = d))), digits = 12), "\n")
cat("is_converged", is_converged(fit), "  convergence_status", convergence_status(fit), "\n")
print(fixef(fit))
print(check_drm(fit))
