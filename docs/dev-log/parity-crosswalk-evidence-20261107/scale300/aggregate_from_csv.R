# Offline re-aggregation from the committed raw_per_seed.csv and raw_per_parameter.csv (no fits are run).
# Adds what compare.R did not report: (a) flags on the ABSOLUTE coefficient difference and on the absolute
# natural-scale SD difference, (b) counts of non-finite standard errors per side per route, (c) a table of
# seeds where the two sides do not both converge, (d) a classification column that uses only quantities in the
# CSVs and diagnosis.csv. compare.R's R-SE-unit flag is blind where R's SE is 5e3 to 5e4 (a boundary).
# usage: Rscript aggregate_from_csv.R [dir]      (dir default "."; reads <dir>/raw_per_*.csv, writes into <dir>)
# Limits: the datasets (so the observed z values) are not committed, so the natural-scale SD difference is
# taken at z = 0 (exp of the two SD-formula intercepts), not at every level. compare.R's max_sd_rel_diff
# (all observed levels) stays in raw_per_seed.csv.
# Definitions: julia_converged is the Julia converged flag; r_converged is R opt$convergence == 0; R pdHess is
# separate and is not part of "both converged". Thresholds: abs coef diff > 1e-3; abs SD diff at z = 0 > 1e-3;
# R rho or Julia rho >= 0.99999 (boundary); smallest SD at z = 0 in either fit < 1e-3 (boundary).
O <- if (length(commandArgs(TRUE))) commandArgs(TRUE)[1] else "."
raw <- read.csv(file.path(O, "raw_per_seed.csv")); pp <- read.csv(file.path(O, "raw_per_parameter.csv"))
has_sigma <- c("nb2_relmat", "gauss_ord", "gauss_animal", "lord_nb2")   # as in compare.R
per <- do.call(rbind, lapply(split(pp, list(pp$route, pp$seed), drop = TRUE), function(z) {
  z <- z[order(z$idx), ]; rt <- z$route[1]; o <- 2L + as.integer(rt %in% has_sigma); ix <- c(o + 1L, o + 3L)
  data.frame(route = rt, seed = z$seed[1], sd0_abs_diff = max(abs(exp(z$julia_est[ix]) - exp(z$r_est[ix]))),
             sd0_min = min(exp(z$julia_est[ix]), exp(z$r_est[ix])),
             n_julia_se_nonfinite = sum(!is.finite(z$julia_se)), n_r_se_nonfinite = sum(!is.finite(z$r_se)),
             r_se_max_finite = max(z$r_se[is.finite(z$r_se)]))
}))
m <- merge(raw, per, by = c("route", "seed"), all.x = TRUE)
m <- m[order(match(m$route, unique(raw$route)), m$seed), ]
both <- m$julia_converged %in% TRUE & m$r_converged %in% TRUE & !is.na(m$ll_diff)
m$rho_boundary <- pmax(abs(m$rho_R), abs(m$rho_julia)) >= 0.99999
m$sd_boundary <- m$sd0_min < 1e-3
diag <- read.csv(file.path(O, "diagnosis.csv")); diag$dl <- diag$ll_Robj_at_Julia_par - diag$ll_R_default
m <- merge(m, diag[, c("route", "seed", "dl")], by = c("route", "seed"), all.x = TRUE)
m <- m[order(match(m$route, unique(raw$route)), m$seed), ]
m$flag_r_se <- abs(m$max_coef_diff_r_se) > 1e-3
m$flag_ll <- abs(m$ll_diff) > 1e-6
m$flag_abs_coef <- m$max_abs_coef_diff > 1e-3
m$flag_abs_sd0 <- m$sd0_abs_diff > 1e-3
m$flag_nonconv <- !(m$julia_converged %in% TRUE & m$r_converged %in% TRUE) | m$note != ""
m$flag_nonfinite_se <- m$n_julia_se_nonfinite > 0 | m$n_r_se_nonfinite > 0
m$classification <- with(m, ifelse(grepl("^fit error", note), "Julia line-search error, no Julia result (fixed in wave 5)",
  ifelse(!is.na(dl) & dl > 1e-4, "R stopped at a lower maximum (diagnosed, diagnosis.csv)",
  ifelse(!is.na(dl) & dl < -1e-2, "Julia stopped at a lower maximum (diagnosed, diagnosis.csv)",
  ifelse(rho_boundary %in% TRUE, paste0("rho at the bound in both fits, |ll diff| ", signif(abs(ll_diff), 2), "; ", ifelse(is.na(dl), "not diagnosed", "diagnosed: R objective at Julia point equal")),
  ifelse(sd_boundary %in% TRUE, paste0("SD coefficient at its lower bound (smallest SD at z = 0 is ", signif(sd0_min, 2), "), |ll diff| ", signif(abs(ll_diff), 2), "; ", ifelse(is.na(dl), "not diagnosed", "diagnosed: R objective at Julia point equal")),
  "unclassified"))))))
m$classification[!(m$flag_r_se | m$flag_ll | m$flag_abs_coef | m$flag_abs_sd0 | m$flag_nonconv)] <- ""
flag <- m[m$flag_r_se | m$flag_ll | m$flag_abs_coef | m$flag_abs_sd0 | m$flag_nonconv, ]
write.csv(flag[, c("route", "seed", "julia_converged", "r_converged", "r_pdHess", "ll_diff", "max_abs_coef_diff", "max_coef_diff_r_se",
  "sd0_abs_diff", "max_sd_rel_diff", "r_se_max_finite", "n_julia_se_nonfinite", "n_r_se_nonfinite", "rho_boundary", "sd_boundary",
  "flag_r_se", "flag_ll", "flag_abs_coef", "flag_abs_sd0", "flag_nonconv", "classification")], file.path(O, "flagged_seeds.csv"), row.names = FALSE)
nc <- m[m$flag_nonconv | m$r_pdHess %in% FALSE, ]
nc$reason <- with(nc, ifelse(grepl("^fit error", note), "Julia error, no result", ifelse(!(julia_converged %in% TRUE), "Julia converged = FALSE (result returned)",
                      ifelse(!(r_converged %in% TRUE), "R convergence != 0", "R pdHess FALSE (both converged)"))))
write.csv(nc[, c("route", "seed", "reason", "julia_converged", "r_converged", "r_pdHess", "ll_diff", "max_abs_coef_diff", "max_coef_diff_r_se")],
          file.path(O, "nonconverged_seeds.csv"), row.names = FALSE)
q3 <- function(v) { v <- abs(v[is.finite(v)]); if (!length(v)) rep(NA_real_, 3) else c(median(v), unname(quantile(v, 0.99)), max(v)) }
routes <- unique(raw$route)
s <- do.call(rbind, lapply(routes, function(rt) {
  x <- m[m$route == rt, ]; b <- both[m$route == rt]; y <- x[b, ]
  a <- q3(y$max_abs_coef_diff); d <- q3(y$sd0_abs_diff)
  data.frame(route = rt, seeds = nrow(x), julia_converged = sum(x$julia_converged %in% TRUE), r_convergence0 = sum(x$r_converged %in% TRUE),
    both_converged_compared = sum(b), r_pdHess = sum(x$r_pdHess %in% TRUE),
    abs_coef_med = a[1], abs_coef_p99 = a[2], abs_coef_max = a[3], n_abs_coef_gt_1e3 = sum(y$flag_abs_coef),
    sd0_abs_med = d[1], sd0_abs_p99 = d[2], sd0_abs_max = d[3], n_sd0_abs_gt_1e3 = sum(y$flag_abs_sd0),
    n_rho_boundary_R = sum(abs(x$rho_R) >= 0.99999, na.rm = TRUE), n_sd_boundary = sum(y$sd_boundary),
    julia_se_nonfinite = sum(x$n_julia_se_nonfinite, na.rm = TRUE), seeds_with_julia_se_nonfinite = sum(x$n_julia_se_nonfinite > 0, na.rm = TRUE),
    r_se_nonfinite = sum(x$n_r_se_nonfinite, na.rm = TRUE), seeds_with_r_se_nonfinite = sum(x$n_r_se_nonfinite > 0, na.rm = TRUE),
    n_flag_union = sum(m$route == rt & (m$flag_r_se | m$flag_ll | m$flag_abs_coef | m$flag_abs_sd0 | m$flag_nonconv)))
}))
write.csv(s, file.path(O, "summary_abs_and_nonfinite.csv"), row.names = FALSE)
options(width = 220); print(s, digits = 3)
cat("\nFlagged seeds (union of all flags):", nrow(flag), "\n"); print(table(flag$route))
cat("Seeds flagged ONLY by the new absolute flags (not by R-SE units, log-lik, or non-convergence):", sum(!(flag$flag_r_se | flag$flag_ll | flag$flag_nonconv)), "\n")
