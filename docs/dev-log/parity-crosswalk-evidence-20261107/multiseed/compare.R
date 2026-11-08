# Julia minus R at the optimum, per route and seed. Writes raw_per_seed.csv, summary.csv and a per-parameter file.
# usage: Rscript compare.R   (run from this directory)
routes <- c("poisson_animal", "nb2_relmat", "gauss_ord", "gauss_animal", "poisson_phylo", "poisson_spatial", "poisson_labelled")
has_sigma <- c(nb2_relmat = TRUE, gauss_ord = TRUE, gauss_animal = TRUE)
rows <- list(); par_rows <- list()
for (route in routes) for (s in 1:10) {
  tag <- sprintf("%s_s%02d", route, s)
  jl <- tryCatch(read.csv(file.path("julia", paste0(tag, "_ll.csv")), colClasses = c(ll = "character")), error = function(e) NULL)
  rl <- tryCatch(read.csv(file.path("r", paste0(tag, "_ll.csv")), colClasses = c(ll = "character")), error = function(e) NULL)
  base <- data.frame(route = route, seed = s, julia_converged = NA, r_converged = NA, r_pdHess = NA, ll_julia = NA_real_, ll_R = NA_real_,
                     ll_diff = NA_real_, max_abs_coef_diff = NA_real_, max_coef_diff_r_se = NA_real_, worst_param = NA_character_,
                     max_sd_rel_diff = NA_real_, rho_julia = NA_real_, rho_R = NA_real_, rho_diff = NA_real_, max_se_rel_diff = NA_real_,
                     julia_sec = NA_real_, r_sec = NA_real_, note = "", stringsAsFactors = FALSE)
  if (is.null(jl) || is.null(rl)) { base$note <- "missing output"; rows[[tag]] <- base; next }
  base$julia_converged <- identical(jl$converged, "true"); base$r_converged <- rl$convergence == 0
  base$r_pdHess <- rl$pdHess; base$julia_sec <- suppressWarnings(as.numeric(jl$seconds)); base$r_sec <- rl$seconds
  if (jl$converged == "error" || rl$convergence == "error") { base$note <- paste("fit error: julia", jl$converged, "R", rl$convergence, rl$msg); rows[[tag]] <- base; next }
  base$ll_julia <- as.numeric(jl$ll); base$ll_R <- as.numeric(rl$ll); base$ll_diff <- base$ll_julia - base$ll_R
  j <- read.csv(file.path("julia", paste0(tag, ".csv"))); r <- read.csv(file.path("r", paste0(tag, ".csv")))
  jrho <- j$block == "recov"; rrho <- grepl("^eta_cor", r$name)
  jc <- j[!jrho, ]; rc <- r[!rrho, ]
  stopifnot(nrow(jc) == nrow(rc))
  labelled <- route == "poisson_labelled"
  # coefficient comparison (labelled rho is on the same atanh scale in both, so it enters the coefficient diff)
  je <- c(jc$est, if (labelled) j$est[jrho]); re <- c(rc$est, if (labelled) r$est[rrho]); rse <- c(rc$se, if (labelled) r$se[rrho]); jse <- c(jc$se, if (labelled) j$se[jrho])
  nm <- c(rc$name, if (labelled) r$name[rrho])
  dif <- je - re
  base$max_abs_coef_diff <- max(abs(dif)); base$max_coef_diff_r_se <- max(abs(dif / rse)); base$worst_param <- paste0(nm[which.max(abs(dif / rse))], "#", which.max(abs(dif / rse)))
  base$max_se_rel_diff <- max(abs(jse / rse - 1))
  par_rows[[tag]] <- data.frame(route = route, seed = s, idx = seq_along(je), r_name = nm, julia_est = je, r_est = re, diff = dif, diff_r_se = dif / rse, julia_se = jse, r_se = rse)
  # per-level SD: sd = exp(b0 + b1 z) for each coefficient field, evaluated at the distinct groups' z values
  d <- read.csv(file.path("data", paste0(tag, ".csv"))); gz <- unique(d[, c("g", "z0", "z1")])
  o <- 2L + as.integer(isTRUE(has_sigma[route]))
  sdv <- function(b) cbind(exp(b[o + 1] + b[o + 2] * gz$z0), exp(b[o + 3] + b[o + 4] * gz$z1))
  sj <- sdv(jc$est); sr <- sdv(rc$est); base$max_sd_rel_diff <- max(abs(sj - sr) / sr)
  if (any(jrho) && any(rrho)) {
    th <- j$est[jrho]; eta <- r$est[rrho]
    if (route == "gauss_ord") { base$rho_julia <- th / sqrt(1 + th^2); base$rho_R <- tanh(eta) }
    else { base$rho_julia <- 0.999999 * tanh(th); base$rho_R <- 0.999999 * tanh(eta) }
    base$rho_diff <- base$rho_julia - base$rho_R
  }
  rows[[tag]] <- base
}
raw <- do.call(rbind, rows); rownames(raw) <- NULL
write.csv(raw, "raw_per_seed.csv", row.names = FALSE)
write.csv(do.call(rbind, par_rows), "raw_per_parameter.csv", row.names = FALSE)
summ <- do.call(rbind, lapply(split(raw, factor(raw$route, levels = routes)), function(x) {
  ok <- !is.na(x$ll_diff); w <- function(col) { v <- abs(x[[col]]); if (all(is.na(v))) return(c(NA, NA)); i <- which.max(v); c(v[i], x$seed[i]) }
  a <- w("max_coef_diff_r_se"); b <- w("max_abs_coef_diff"); c1 <- w("max_sd_rel_diff"); l <- w("ll_diff"); rr <- w("rho_diff"); sr <- w("max_se_rel_diff")
  data.frame(route = x$route[1], seeds = nrow(x), compared = sum(ok), both_converged = sum(x$julia_converged %in% TRUE & x$r_converged %in% TRUE),
    r_pdHess = sum(x$r_pdHess %in% TRUE),
    worst_coef_diff_r_se = a[1], at_seed = a[2], worst_abs_coef_diff = b[1], worst_sd_rel_diff = c1[1], worst_abs_ll_diff = l[1], ll_at_seed = l[2],
    worst_abs_rho_diff = rr[1], worst_se_rel_diff = sr[1], max_julia_sec = max(x$julia_sec, na.rm = TRUE), max_r_sec = max(x$r_sec, na.rm = TRUE))
}))
rownames(summ) <- NULL; write.csv(summ, "summary.csv", row.names = FALSE); print(summ, digits = 3)
# seeds flagged for inspection (flag thresholds are for triage only; nothing is tolerance-tested)
flag <- raw[!(raw$julia_converged %in% TRUE & raw$r_converged %in% TRUE) | is.na(raw$ll_diff) | abs(raw$max_coef_diff_r_se) > 1e-3 | abs(raw$ll_diff) > 1e-6 | raw$note != "", ]
cat("\nFlagged seeds (any non-convergence/error, coef diff > 1e-3 R-SE, or |ll diff| > 1e-6):", nrow(flag), "\n"); if (nrow(flag)) print(flag)
