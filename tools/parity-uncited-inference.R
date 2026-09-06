# The three inference capabilities of docs/design/parity-matrix.md, measured on
# both engines in one run: Wald SEs/CIs, profile-likelihood CIs, parametric
# bootstrap CIs -- plus the bivariate boundary that fences profile and bootstrap
# out of every bivariate Julia fit.
#
# This script MEASURES; it promotes nothing and writes no TSV. Its output is
# the receipt at
# docs/dev-log/evidence/julia-r-parity/p2-g3/uncited-inference-receipt.md.
#
# It is deliberately ONE route (base_gaussian_location_scale, on DRM.jl's
# committed gaussian-locscale fixture) and ONE target (fixef:mu:x), so it runs
# in a few minutes and its claim is exactly as wide as its evidence. It is NOT
# an interval-coverage study: coverage is fenced out of this programme by
# D-181 #2, and capability parity is a different question from calibration.
#
# Sections: G1 coef + logLik | G2 SE | G3 Wald CI | G4 profile CI |
# G5 bootstrap CI (R = 99) | G6 red control (the same profile deltas must FAIL
# a 1e-9 bar) | G7 the bivariate profile/bootstrap boundary, measured.
#
#   OPENBLAS_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true \
#     DRMTMB_WT=<drmTMB worktree> \
#     DRM_JL_PATH=<DRM.jl checkout> DRM_JL_PHYLO_PATH=<same> \
#     Rscript tools/parity-uncited-inference.R
#
# DRM.jl is read at its HEAD and that sha is printed first: an interval number
# without its commit is not evidence.

suppressMessages(pkgload::load_all(Sys.getenv("DRMTMB_WT"), quiet = TRUE))

drmjl <- Sys.getenv("DRM_JL_PATH")
sha <- system2("git", c("-C", shQuote(drmjl), "rev-parse", "HEAD"), stdout = TRUE)
cat("DRM.jl commit:", sha, "\n")
cat("drmTMB HEAD:", system2("git", c("-C", shQuote(Sys.getenv("DRMTMB_WT")), "rev-parse", "HEAD"), stdout = TRUE), "\n")

fx <- function(slug) read.csv(file.path(drmjl, "test", "parity", "fixtures", slug, "data.csv"))
fmt <- function(x) format(x, digits = 15)

dat <- fx("gaussian-locscale")
cat("fixture=gaussian-locscale n=", nrow(dat), "\n", sep = "")

ft <- drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = dat, engine = "tmb")
fj <- drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = dat, engine = "julia")

cat("\n## G1 coef + logLik, same target, name-matched\n")
ct <- unlist(coef(ft)); cj <- unlist(coef(fj))
nm <- intersect(names(ct), names(cj))
cat("matched coefficient names (", length(nm), "):", paste(nm, collapse = " "), "\n")
cat("only_tmb=", length(setdiff(names(ct), nm)), " only_julia=", length(setdiff(names(cj), nm)), "\n")
for (n in nm) cat(sprintf("  %-24s tmb=%s julia=%s |d|=%.6e\n", n, fmt(ct[[n]]), fmt(cj[[n]]), abs(ct[[n]] - cj[[n]])))
cat("coef max_abs_diff =", format(max(abs(ct[nm] - cj[nm])), digits = 6), "\n")
llt <- as.numeric(logLik(ft)); llj <- as.numeric(logLik(fj))
cat("logLik tmb=", fmt(llt), " julia=", fmt(llj), " |d|=", format(abs(llt - llj), digits = 6), "\n", sep = "")
cat("converged tmb=", isTRUE(is_converged(ft)), " julia=", isTRUE(is_converged(fj)), "\n", sep = "")

cat("\n## G2 SE parity (both engines report SEs)\n")
# vcov() is the common surface: summary()$coefficients has a different shape on
# the two engines (native returns estimate/std_error; the bridge returns
# dpar/term/estimate/std.error/statistic/p.value), so read the SEs off the
# covariance instead and normalise the bridge's "<dpar>_<term>" names.
norm_nm <- function(nm) sub("_", ":", nm, fixed = TRUE)
se_vec <- function(f) {
  v <- stats::vcov(f)
  out <- sqrt(diag(as.matrix(v)))
  names(out) <- norm_nm(colnames(as.matrix(v)))
  out
}
set <- se_vec(ft); sej <- se_vec(fj)
cat("  tmb SE names  :", paste(names(set), collapse = " | "), "\n")
cat("  julia SE names:", paste(names(sej), collapse = " | "), "\n")
snm <- intersect(names(set), names(sej))
for (n in snm) cat(sprintf("  %-24s tmb=%s julia=%s |d|=%.6e rel=%.6e\n", n, fmt(set[[n]]), fmt(sej[[n]]), abs(set[[n]] - sej[[n]]), abs(set[[n]] - sej[[n]]) / abs(set[[n]])))
cat("SE matched=", length(snm), " of tmb ", length(set), " / julia ", length(sej),
    "; max_abs_diff=", format(max(abs(set[snm] - sej[snm])), digits = 6),
    " max_rel_diff=", format(max(abs(set[snm] - sej[snm]) / abs(set[snm])), digits = 6), "\n", sep = "")

target <- "fixef:mu:x"
cat("\n## G3 Wald CI, target", target, "\n")
wt <- confint(ft, parm = target, method = "wald")
wj <- confint(fj, parm = target, method = "wald")
cat("  tmb   [", fmt(wt$lower[[1]]), ",", fmt(wt$upper[[1]]), "]\n")
cat("  julia [", fmt(wj$lower[[1]]), ",", fmt(wj$upper[[1]]), "]\n")
d_w <- c(abs(wt$lower[[1]] - wj$lower[[1]]), abs(wt$upper[[1]] - wj$upper[[1]]))
cat("  delta =", format(d_w, digits = 6), "\n")

cat("\n## G4 profile-likelihood CI, target", target, "\n")
pt <- confint(ft, parm = target, method = "profile")
pj <- confint(fj, parm = target, method = "profile")
cat("  tmb   [", fmt(pt$lower[[1]]), ",", fmt(pt$upper[[1]]), "] status=", pt$conf.status[[1]], "\n")
cat("  julia [", fmt(pj$lower[[1]]), ",", fmt(pj$upper[[1]]), "] status=", pj$conf.status[[1]], "\n")
d_p <- c(abs(pt$lower[[1]] - pj$lower[[1]]), abs(pt$upper[[1]] - pj$upper[[1]]))
cat("  delta =", format(d_p, digits = 6), "\n")
cat("  PASS(tol=1e-4) =", all(d_p <= 1e-4) && all(is.finite(c(pt$lower[[1]], pt$upper[[1]], pj$lower[[1]], pj$upper[[1]]))), "\n")

cat("\n## G5 parametric bootstrap CI R=99 seed=20260905, target", target, "\n")
bt <- tryCatch(confint(ft, parm = target, method = "bootstrap", R = 99L, seed = 20260905L), error = function(e) e)
bj <- tryCatch(confint(fj, parm = target, method = "bootstrap", R = 99L, seed = 20260905L), error = function(e) e)
rep_ci <- function(b, lab) {
  if (inherits(b, "error")) { cat("  ", lab, " ERROR:", conditionMessage(b), "\n"); return(NULL) }
  cat(sprintf("  %-6s [%s, %s] used=%s failed=%s status=%s\n", lab, fmt(b$lower[[1]]), fmt(b$upper[[1]]),
              b$bootstrap.n[[1]], b$bootstrap.failed[[1]], b$conf.status[[1]]))
  b
}
bt <- rep_ci(bt, "tmb"); bj <- rep_ci(bj, "julia")
if (!is.null(bt) && !is.null(bj)) {
  ov <- max(bt$lower[[1]], bj$lower[[1]]) <= min(bt$upper[[1]], bj$upper[[1]])
  cat("  OVERLAP =", ov, "\n")
}

cat("\n## G6 RED CONTROL -- same profile deltas at a tightened 1e-9 bar\n")
cat("  d_profile =", format(d_p, digits = 6), "\n")
cat("  PASS(tol=1e-9) =", all(d_p <= 1e-9), " (expected FALSE: the check can fail)\n")
if (all(d_p <= 1e-9)) stop("RED CONTROL VACUOUS: profile deltas passed the 1e-9 bar")

cat("\n## G7 biv_gaussian_residual -- the structural profile boundary\n")
bdat <- fx("gaussian-bivariate-rho12")
fbj <- drmTMB(bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
              family = biv_gaussian(), data = bdat, engine = "julia")
tg <- profile_targets(fbj)
cat("  model_type =", fbj$model$model_type, "\n")
cat("  inventory rows =", nrow(tg), "; profile_ready TRUE count =", sum(tg$profile_ready), "\n")
print(tg[, c("parm", "profile_ready", "profile_note")], row.names = FALSE)
msg <- tryCatch({ confint(fbj, parm = "fixef:mu1:x", method = "profile"); NA_character_ },
                error = function(e) conditionMessage(e))
cat("  confint(method='profile') refusal verbatim:\n")
cat(paste0("    ", strsplit(msg, "\n")[[1]], collapse = "\n"), "\n")
bmsg <- tryCatch({ confint(fbj, parm = "fixef:mu1:x", method = "bootstrap", R = 5L, seed = 1L); NA_character_ },
                 error = function(e) conditionMessage(e))
cat("  confint(method='bootstrap') refusal verbatim:\n")
cat(paste0("    ", strsplit(bmsg, "\n")[[1]], collapse = "\n"), "\n")
cat("\nDONE\n")
