## F7-twin-flag-semantics (drmTMB side): refit cells 1-14 of the t4 grid and record WHY
## is_converged() reads what it reads, using drmTMB's own internal predicates at the pin.
## Independent of the lane harness (t4_fit_drmTMB.R). Writes f7_census_drmTMB.csv.
##   cd sweep-oct16/t4/repro/F7-twin-flag-semantics && Rscript f7_census_drmTMB.R > f7_census_drmTMB.out 2>&1
suppressPackageStartupMessages(library(drmTMB))
ns <- asNamespace("drmTMB")
cat("drmTMB", format(packageVersion("drmTMB")), "built:", packageDescription("drmTMB")$Built, "\n")
## provenance: the installed predicates are byte-for-byte the pinned R/check.R ones
pin <- "ca3ddefa5ea11bbfd3b765615dfbb89305d2485a"
src <- tryCatch(system(paste("git -C ../../../.. show", paste0(pin, ":R/check.R")), intern = TRUE),
                error = function(e) NULL)
if (length(src)) {
  e <- new.env(); eval(parse(text = src), envir = e)
  for (f in c("is_converged.drmTMB", "convergence_status.drmTMB", "drm_inference_degenerate",
              "drm_fixed_effect_rank_deficient", "drm_standard_errors_pathological", "drm_inference_at_boundary"))
    cat(sprintf("  %-34s identical to %s:R/check.R: %s\n", f, substr(pin, 1, 8),
                identical(deparse(body(get(f, e))), deparse(body(get(f, ns))))))
}
DDIR <- "../../data"
cells <- c("gauss_n8", "gauss_n12", "gauss_n20", "pois_n8", "pois_n12", "pois_n20", "bin_complete",
           "bin_quasi", "nb2_poisdata", "beta_phi1e4", "student_gaussdata", "re_sd1e-4",
           "collin_sigma_exact", "collin_sigma_near")
src_gen <- "../../t4_gen_data.R"
get_data <- function(cell, r) {
  f <- file.path(DDIR, sprintf("%s_r%02d.csv", cell, r))
  if (file.exists(f)) return(read.csv(f))
  ## the uncommitted cells regenerate byte-identically from the lane DGP
  if (!exists("t4_gen")) source(src_gen)
  t4_gen(match(cell, t4_cells$cell), r)
}
fit_cell <- function(cell, d) {
  c0 <- sub("_n[0-9]+$", "", cell)
  switch(c0,
    gauss = drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = d),
    pois  = drmTMB(bf(y ~ x), family = poisson(), data = d),
    bin_complete = , bin_quasi = drmTMB(bf(y ~ x), family = binomial(), data = d),
    nb2_poisdata = drmTMB(bf(y ~ x, sigma ~ 1), family = nbinom2(), data = d),
    beta_phi1e4  = drmTMB(bf(y ~ x, sigma ~ 1), family = beta_family(), data = d),
    student_gaussdata = drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = student(), data = d),
    "re_sd1e-4" = { d$g <- factor(d$g); drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(), data = d) },
    collin_sigma_exact = , collin_sigma_near = drmTMB(bf(y ~ x, sigma ~ x + z), family = gaussian(), data = d))
}
rows <- list()
for (cell in cells) for (r in 1:50) {
  d <- get_data(cell, r)
  w <- character()
  fit <- withCallingHandlers(tryCatch(fit_cell(cell, d), error = function(e) e),
    warning = function(x) { w <<- c(w, conditionMessage(x)); invokeRestart("muffleWarning") },
    message = function(m) invokeRestart("muffleMessage"))
  if (inherits(fit, "error")) { rows[[length(rows) + 1]] <- data.frame(cell = cell, rep = r, error = conditionMessage(fit)); next }
  q <- function(f) isTRUE(get(f, ns)(fit))
  V <- tryCatch(vcov(fit), error = function(e) NULL)
  se <- if (is.null(V)) NA_real_ else suppressWarnings(sqrt(diag(V)))
  rows[[length(rows) + 1]] <- data.frame(
    cell = cell, rep = r, error = "",
    is_converged = is_converged(fit), status = convergence_status(fit),
    opt_code = as.integer(fit$opt$convergence), opt_message = fit$opt$message,
    optimizer_ok = q("drm_optimizer_converged"), pdHess = isTRUE(fit$sdr$pdHess),
    inference_degenerate = q("drm_inference_degenerate"), rank_deficient = q("drm_fixed_effect_rank_deficient"),
    se_pathological = q("drm_standard_errors_pathological"), at_boundary = q("drm_inference_at_boundary"),
    n_se_nonfinite = sum(!is.finite(se)), max_se = suppressWarnings(max(se[is.finite(se)])),
    logLik = as.numeric(logLik(fit)), fit_warning = length(w) > 0, warnings = paste(unique(w), collapse = " || "))
}
all_n <- unique(unlist(lapply(rows, names)))
res <- do.call(rbind, lapply(rows, function(x) { for (n in setdiff(all_n, names(x))) x[[n]] <- NA; x[all_n] }))
write.csv(res, "f7_census_drmTMB.csv", row.names = FALSE)
cat("\nfits:", nrow(res), " errors:", sum(nzchar(res$error)), "\n")
res$why <- with(res, ifelse(!optimizer_ok, "F:optimizer",
                     ifelse(inference_degenerate, "F:deg_hessian_or_SE",
                     ifelse(rank_deficient, "F:deg_rank",
                     ifelse(se_pathological, "F:deg_inflated_SE",
                     ifelse(at_boundary, "T:boundary", "T:converged"))))))
cat("\nis_converged() (T/F) and the first predicate that decides it, per cell\n(F:optimizer = code != 0 or non-finite objective; F:deg_hessian_or_SE = pdHess FALSE or a non-finite SE;\n F:deg_rank = design rank deficient; F:deg_inflated_SE = weakly identified, SE >= 50 and >= 1000 x median):\n")
print(as.data.frame.matrix(table(factor(res$cell, levels = cells), res$why)))
cat("\n"); print(sessionInfo())
