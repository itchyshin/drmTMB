# sweep-oct16 / t5 -- supplementary native probes of weights x missingness.
#   na_w_dropped : NA weight placed only on rows that NA-dropping removes
#                  (expect: identical to the fit with those weights set to 1)
#   na_w_kept    : one NA weight on a kept row (expect: named error)
#   zero_w       : weight 0 on 10 kept rows (expect: logLik/coef identical to
#                  dropping them; nobs counts them, per documented semantics)
#   double_w     : weights 2*w_pos vs w_pos on data stacked twice (expect identical)
# Usage: Rscript R/run_probe_wt.R <datadir> <outfile>
args <- commandArgs(trailingOnly = TRUE)
suppressMessages(library(drmTMB))
FO <- list(gaussian = gaussian(), poisson = poisson(link = "log"), gamma = Gamma(link = "log"))
FF <- function(f) if (f == "poisson") bf(y ~ x + (1 | g)) else bf(y ~ x + (1 | g), sigma ~ 1)
summ <- function(fit) { cf <- coef(fit); c(logLik = as.numeric(logLik(fit)), unlist(cf), sd = unname(fit$sdpars$mu[[1]]), nobs = nobs(fit)) }
out <- list()
for (fam in names(FO)) {
  d <- read.csv(file.path(args[[1]], sprintf("%s_y20_x20.csv", fam)))
  cc <- complete.cases(d[, c("y", "x", "g")])
  F <- FF(fam)
  base <- summ(drmTMB(F, family = FO[[fam]], data = d, weights = w_pos))
  # NA weights on dropped rows only
  d1 <- d; d1$w_pos[!cc] <- NA
  r1 <- tryCatch(summ(drmTMB(F, family = FO[[fam]], data = d1, weights = w_pos)), error = function(e) conditionMessage(e))
  # NA weight on a kept row
  d2 <- d; d2$w_pos[which(cc)[1]] <- NA
  r2 <- tryCatch(summ(drmTMB(F, family = FO[[fam]], data = d2, weights = w_pos)), error = function(e) gsub("[\r\n]+", " | ", conditionMessage(e)))
  # zero weights on 10 kept rows vs dropping them
  z <- which(cc)[seq(1, by = 7, length.out = 10)]
  d3 <- d; d3$w_pos[z] <- 0
  r3 <- summ(drmTMB(F, family = FO[[fam]], data = d3, weights = w_pos))
  r3d <- summ(drmTMB(F, family = FO[[fam]], data = d[-z, ], weights = w_pos))
  # 2 * w_pos vs data stacked twice with w_pos
  d4 <- d; d4$w2 <- 2 * d4$w_pos
  r4 <- summ(drmTMB(F, family = FO[[fam]], data = d4, weights = w2))
  r4d <- summ(drmTMB(F, family = FO[[fam]], data = rbind(d, d), weights = w_pos))
  k <- setdiff(names(base), "nobs")
  out[[fam]] <- data.frame(
    family = fam,
    na_w_dropped_maxdiff = if (is.character(r1)) NA else max(abs(r1[k] - base[k])),
    na_w_dropped_error = if (is.character(r1)) r1 else NA,
    na_w_kept_result = if (is.character(r2)) r2 else "FITTED (no error)",
    zero_w_vs_drop_maxdiff = max(abs(r3[k] - r3d[k])), zero_w_nobs = r3[["nobs"]], drop_nobs = r3d[["nobs"]],
    double_w_vs_stack_maxdiff = max(abs(r4[k] - r4d[k])), double_w_nobs = r4[["nobs"]], stack_nobs = r4d[["nobs"]])
}
res <- do.call(rbind, out)
write.csv(res, args[[2]], row.names = FALSE)
print(res, digits = 3)
