# Julia minus R at the optimum, per route and seed (offline: reads the per-seed files written by
# julia_run.jl and r_run.R). Writes raw_per_seed.csv, raw_per_parameter.csv, summary_distribution.csv,
# coverage_informational.csv, flagged_seeds.csv.
# usage: SC_OUT=<out> Rscript compare.R [n_seeds]     (SC_OUT default ".")
args <- commandArgs(TRUE); nseed <- if (length(args)) as.integer(args[1]) else 300L
O <- Sys.getenv("SC_OUT", ".")
routes <- c("poisson_animal", "nb2_relmat", "gauss_ord", "gauss_animal", "poisson_phylo", "poisson_spatial",
            "poisson_labelled", "lord_poisson", "lord_nb2")
has_sigma <- c(nb2_relmat = TRUE, gauss_ord = TRUE, gauss_animal = TRUE, lord_nb2 = TRUE)
rho_in_coef <- c("poisson_labelled", "lord_poisson", "lord_nb2")   # rho on the same atanh scale in both
# True values on the estimation scale, in parameter order (informational coverage only).
truth <- list(
  poisson_animal = c(0.2, 0.3, -0.9, 0.35, -1.0, 0.45),
  nb2_relmat = c(0.2, 0.3, log(0.45), -0.9, 0.35, -1.0, 0.45),
  gauss_animal = c(0.3, 0.2, log(0.4), -0.7, 0.4, -0.9, 0.5),
  gauss_ord = c(0.2, 0.5, log(0.4), -0.5, 0.5, -0.8, -0.4),
  poisson_phylo = c(0.4, 0.3, log(0.4), 0.3, log(0.25), -0.3),
  poisson_spatial = c(0.4, 0.3, log(0.4), 0.3, log(0.25), -0.3),
  poisson_labelled = c(0.2, 0.3, -0.7, 0.35, -0.9, 0.45, atanh(0.5)),
  lord_poisson = c(0.3, 0.4, log(0.5), 0.3, log(0.3), -0.3, atanh(0.5)),
  lord_nb2 = c(0.3, 0.4, log(0.6), log(0.5), 0.3, log(0.3), -0.3, atanh(0.5)))
group_of <- function(route, i, n) {   # parameter group label for coverage tables
  ns <- as.integer(isTRUE(has_sigma[route])); rho <- route %in% c(rho_in_coef) && i == n
  if (rho) "rho" else if (i <= 2) "mu fixed" else if (i <= 2 + ns) "sigma" else "SD coefficients" }
rd <- function(f) tryCatch(read.csv(f, colClasses = c(ll = "character")), error = function(e) NULL)
rows <- list(); par_rows <- list()
for (route in routes) for (s in seq_len(nseed)) {
  tag <- sprintf("%s_s%03d", route, s)
  jl <- rd(file.path(O, "julia", paste0(tag, "_ll.csv"))); rl <- rd(file.path(O, "r", paste0(tag, "_ll.csv")))
  base <- data.frame(route = route, seed = s, julia_converged = NA, r_converged = NA, r_pdHess = NA, ll_julia = NA_real_, ll_R = NA_real_,
                     ll_diff = NA_real_, max_abs_coef_diff = NA_real_, max_coef_diff_r_se = NA_real_, worst_param = NA_character_,
                     max_sd_rel_diff = NA_real_, rho_julia = NA_real_, rho_R = NA_real_, rho_diff = NA_real_, max_se_rel_diff = NA_real_,
                     julia_sec = NA_real_, r_sec = NA_real_, note = "", stringsAsFactors = FALSE)
  if (is.null(jl) || is.null(rl)) { base$note <- "missing output"; rows[[tag]] <- base; next }
  base$julia_converged <- identical(jl$converged, "true"); base$r_converged <- rl$convergence == 0
  base$r_pdHess <- rl$pdHess; base$julia_sec <- suppressWarnings(as.numeric(jl$seconds)); base$r_sec <- rl$seconds
  if (jl$converged == "error" || rl$convergence == "error") { base$note <- paste("fit error: julia", jl$converged, "R", rl$convergence, rl$msg); rows[[tag]] <- base; next }
  base$ll_julia <- as.numeric(jl$ll); base$ll_R <- as.numeric(rl$ll); base$ll_diff <- base$ll_julia - base$ll_R
  j <- read.csv(file.path(O, "julia", paste0(tag, ".csv"))); r <- read.csv(file.path(O, "r", paste0(tag, ".csv")))
  rrho <- grepl("^eta_cor", r$name)
  jrho <- if (route %in% rho_in_coef) seq_len(nrow(j)) == nrow(j) else j$block == "recov"   # rho is the last Julia row
  jc <- j[!jrho, ]; rc <- r[!rrho, ]
  stopifnot(nrow(jc) == nrow(rc))
  inc <- route %in% rho_in_coef
  je <- c(jc$est, if (inc) j$est[jrho]); re <- c(rc$est, if (inc) r$est[rrho]); rse <- c(rc$se, if (inc) r$se[rrho]); jse <- c(jc$se, if (inc) j$se[jrho])
  nm <- c(rc$name, if (inc) r$name[rrho])
  dif <- je - re; sc <- dif / rse
  wi <- which.max(abs(sc)); if (length(wi) == 0 || all(is.na(sc))) wi <- which.max(abs(dif))
  base$max_abs_coef_diff <- max(abs(dif)); base$max_coef_diff_r_se <- max(abs(sc), na.rm = TRUE)
  base$worst_param <- paste0(nm[wi], "#", wi); base$max_se_rel_diff <- max(abs(jse / rse - 1))
  tv <- truth[[route]]; stopifnot(length(tv) == length(je))
  cov <- function(e, se) ifelse(is.finite(se) & se > 0 & se < 1e3, as.integer(abs(e - tv) <= qnorm(0.975) * se), NA_integer_)
  par_rows[[tag]] <- data.frame(route = route, seed = s, idx = seq_along(je), r_name = nm,
     pgroup = vapply(seq_along(je), function(i) group_of(route, i, length(je)), ""),
     julia_est = je, r_est = re, diff = dif, diff_r_se = sc, julia_se = jse, r_se = rse, truth = tv,
     julia_covers = cov(je, jse), r_covers = cov(re, rse))
  d <- read.csv(file.path(O, "data", paste0(tag, ".csv"))); gz <- unique(d[, c("g", "z0", "z1")])
  o <- 2L + as.integer(isTRUE(has_sigma[route]))
  sdv <- function(b) cbind(exp(b[o + 1] + b[o + 2] * gz$z0), exp(b[o + 3] + b[o + 4] * gz$z1))
  base$max_sd_rel_diff <- max(abs(sdv(jc$est) - sdv(rc$est)) / sdv(rc$est))
  if (any(jrho) && any(rrho)) {
    th <- j$est[jrho]; eta <- r$est[rrho]
    if (route == "gauss_ord") { base$rho_julia <- th / sqrt(1 + th^2); base$rho_R <- tanh(eta) }
    else { base$rho_julia <- 0.999999 * tanh(th); base$rho_R <- 0.999999 * tanh(eta) }
    base$rho_diff <- base$rho_julia - base$rho_R
  }
  rows[[tag]] <- base
}
raw <- do.call(rbind, rows); rownames(raw) <- NULL
write.csv(raw, file.path(O, "raw_per_seed.csv"), row.names = FALSE)
pp <- do.call(rbind, par_rows); write.csv(pp, file.path(O, "raw_per_parameter.csv"), row.names = FALSE)
q <- function(v) { v <- abs(v[is.finite(v)]); if (!length(v)) return(rep(NA_real_, 3)); c(median(v), unname(quantile(v, 0.99)), max(v)) }
summ <- do.call(rbind, lapply(routes, function(rt) {
  x <- raw[raw$route == rt, ]; both <- x$julia_converged %in% TRUE & x$r_converged %in% TRUE
  y <- x[both & !is.na(x$ll_diff), ]
  mk <- function(col) setNames(q(y[[col]]), paste0(col, c("_med", "_p99", "_max")))
  data.frame(route = rt, seeds = nrow(x), both_converged = sum(both), r_pdHess = sum(x$r_pdHess %in% TRUE), compared = nrow(y),
    t(mk("max_coef_diff_r_se")), t(mk("max_abs_coef_diff")), t(mk("max_sd_rel_diff")), t(mk("ll_diff")), t(mk("rho_diff")), t(mk("max_se_rel_diff")),
    n_beyond_1e3_rse = sum(abs(y$max_coef_diff_r_se) > 1e-3, na.rm = TRUE), n_ll_beyond_1e6 = sum(abs(y$ll_diff) > 1e-6, na.rm = TRUE),
    median_julia_sec = median(x$julia_sec, na.rm = TRUE), median_r_sec = median(x$r_sec, na.rm = TRUE))
}))
write.csv(summ, file.path(O, "summary_distribution.csv"), row.names = FALSE)
# Informational Wald-CI coverage of the true values (NOT the claim of this study).
cvr <- do.call(rbind, lapply(split(pp, list(pp$route, pp$pgroup), drop = TRUE), function(z) data.frame(route = z$route[1], pgroup = z$pgroup[1],
   n_julia = sum(!is.na(z$julia_covers)), julia_coverage = mean(z$julia_covers, na.rm = TRUE),
   n_R = sum(!is.na(z$r_covers)), R_coverage = mean(z$r_covers, na.rm = TRUE))))
write.csv(cvr, file.path(O, "coverage_informational.csv"), row.names = FALSE)
# Triage flags only; no tolerance is applied to any verdict.
flag <- raw[!(raw$julia_converged %in% TRUE & raw$r_converged %in% TRUE) | is.na(raw$ll_diff) | abs(raw$max_coef_diff_r_se) > 1e-3 | abs(raw$ll_diff) > 1e-6 | raw$note != "", ]
write.csv(flag, file.path(O, "flagged_seeds.csv"), row.names = FALSE)
options(width = 200); print(summ[, c("route", "seeds", "both_converged", "r_pdHess", "compared", "max_coef_diff_r_se_med", "max_coef_diff_r_se_p99", "max_coef_diff_r_se_max", "n_beyond_1e3_rse", "n_ll_beyond_1e6")], digits = 3)
cat("\nFlagged seeds:", nrow(flag), "\n"); print(table(flag$route))
