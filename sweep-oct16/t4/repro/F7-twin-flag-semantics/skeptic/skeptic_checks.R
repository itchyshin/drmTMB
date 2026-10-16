## F7 skeptic checks (run from this directory): (1) installed drmTMB predicates == ca3ddefa source,
## (2) per-cell disagreement recount from the census CSVs, (3) Student disagreeing-fit breakdown.
##   Rscript skeptic_checks.R > skeptic_checks.out 2>&1
pin <- tempfile(fileext = ".R")
system2("git", c("-C", "../../../../..", "show", "ca3ddefa5ea11bbfd3b765615dfbb89305d2485a:R/check.R"), stdout = pin)
e <- new.env(); sys.source(pin, envir = e, keep.source = FALSE)
fns <- c("is_converged.drmTMB", "convergence_status.drmTMB", "drm_optimizer_converged", "drm_inference_degenerate",
         "drm_standard_errors_pathological", "drm_fixed_effect_rank_deficient", "drm_inference_at_boundary",
         "check_standard_errors_inflated")
for (f in fns) cat(sprintf("%-34s installed == pin: %s\n", f, identical(deparse(get(f, e)), deparse(get(f, asNamespace("drmTMB"))))))
cat("convergence_status.drmTMB_julia exists:", exists("convergence_status.drmTMB_julia", asNamespace("drmTMB")), "\n")
cat("is_converged.drmTMB_julia:", paste(deparse(drmTMB:::is_converged.drmTMB_julia), collapse = " "), "\n\n")
r <- read.csv("../f7_census_drmTMB.csv"); j <- read.csv("../f7_census_DRModels.csv")
m <- merge(r, j, by = c("cell", "rep"), suffixes = c(".R", ".J"))
m$J <- m$is_converged.J %in% c("true", TRUE); m$dis <- m$is_converged.R != m$J
a <- aggregate(cbind(n = 1, R_T = is_converged.R, J_T = J, disagree = dis) ~ cell, data = m, FUN = sum)
print(a, row.names = FALSE); cat("total disagree:", sum(m$dis), "of", nrow(m), "\n\n")
s <- m[m$cell == "student_gaussdata" & m$dis, ]
s$dLL <- s$logLik - s$loglik
print(s[order(s$opt_code, s$rep), c("rep", "opt_code", "status", "pdHess", "se_pathological", "logLik", "loglik", "dLL")], row.names = FALSE)
cat("\n"); print(sessionInfo())
