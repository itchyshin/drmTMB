# Julia minus R at the optimum, per route and seed. Writes raw_per_seed.csv, raw_per_parameter.csv, summary.csv.
# usage: Rscript compare2.R   (run from this directory)
# Parameters are compared by position. check_layout (inside the seed loop) decodes each Julia block label and stops unless
# it matches R's parameter name at the same index (mu/sigma/recov, SD-target dpar) and the SD target's group matches spec.
# It cannot check which coefficient (intercept or slope) an SD pair belongs to: R's names carry no coefficient label.
# Spec per route: SD-coefficient blocks (first index, group column, predictor column) and the correlation type.
sdb <- function(...) list(...)
spec <- list(
  gauss_q3 = list(sd = list(c(5, "id", "w"), c(7, "id", "w"), c(9, "id", "w")), rho = "chol", q = 3, rj = 11:13),
  gauss_q4 = list(sd = list(c(5, "id", "w"), c(7, "id", "w"), c(9, "id", "w"), c(11, "id", "w")), rho = "chol", q = 4, rj = 13:18),
  gamma_same = list(sd = list(c(4, "g", "w1"), c(6, "g", "w2")), rho = "none"),
  nb2_same = list(sd = list(c(4, "g", "w1"), c(6, "g", "w2")), rho = "none"),
  nb2_corr = list(sd = list(c(4, "g", "w1"), c(6, "g", "w2")), rho = "atanh", rj = 8),
  gauss_phylo = list(sd = list(c(4, "id", "z0"), c(6, "id", "z1")), rho = "none"),
  gauss_spatial = list(sd = list(c(4, "id", "z0"), c(6, "id", "z1")), rho = "none"),
  gauss_lphylo = list(sd = list(c(4, "id", "z0"), c(6, "id", "z1")), rho = "atanh", rj = 8),
  gauss_lspatial = list(sd = list(c(4, "id", "z0"), c(6, "id", "z1")), rho = "atanh", rj = 8),
  gauss_joint = list(sd = list(c(4, "id", "w"), c(6, "id", "z")), rho = "none"),
  nb2_joint = list(sd = list(c(4, "id", "w"), c(6, "id", "z")), rho = "none"),
  nb2_jcross = list(sd = list(c(4, "id", "w"), c(6, "g", "z")), rho = "none"))
routes <- names(spec)
chol_rho <- function(th, q) { L <- diag(q); k <- 0; for (i in 1:q) for (j in seq_len(i - 1)) { k <- k + 1; L[i, j] <- th[k] }
  S <- L %*% t(L); d <- 1 / sqrt(diag(S)); (d * S * rep(d, each = q))[lower.tri(diag(q))] }
rows <- list(); par_rows <- list()
for (route in routes) for (s in 1:10) {
  tag <- sprintf("%s_s%02d", route, s); sp <- spec[[route]]
  rd <- function(p, ...) tryCatch(read.csv(p, ...), error = function(e) NULL)
  jl <- rd(file.path("julia", paste0(tag, "_ll.csv")), colClasses = c(ll = "character"))
  rl <- rd(file.path("r", paste0(tag, "_ll.csv")), colClasses = c(ll = "character"))
  base <- data.frame(route = route, seed = s, julia_converged = NA, r_converged = NA, r_pdHess = NA, ll_julia = NA_real_, ll_R = NA_real_,
                     ll_diff = NA_real_, max_abs_coef_diff = NA_real_, max_coef_diff_r_se = NA_real_, worst_param = NA_character_,
                     max_sd_rel_diff = NA_real_, max_rho_diff = NA_real_, max_se_rel_diff = NA_real_,
                     julia_sec = NA_real_, r_sec = NA_real_, note = "", stringsAsFactors = FALSE)
  if (is.null(jl) || is.null(rl)) { base$note <- "missing output"; rows[[tag]] <- base; next }
  base$julia_converged <- identical(jl$converged, "true"); base$r_converged <- rl$convergence == 0
  base$r_pdHess <- rl$pdHess; base$julia_sec <- suppressWarnings(as.numeric(jl$seconds)); base$r_sec <- rl$seconds
  if (identical(jl$converged, "error") || identical(rl$convergence, "error")) {
    base$note <- paste0("fit error: julia ", jl$converged, if (!is.null(jl$msg)) paste0(" [", jl$msg, "]"), "; R ", rl$convergence, " [", rl$msg, "]")
    rows[[tag]] <- base; next }
  base$ll_julia <- as.numeric(jl$ll); base$ll_R <- as.numeric(rl$ll); base$ll_diff <- base$ll_julia - base$ll_R
  j <- read.csv(file.path("julia", paste0(tag, ".csv"))); r <- read.csv(file.path("r", paste0(tag, ".csv")))
  stopifnot(nrow(j) == nrow(r))
  hexdec <- function(h) rawToChar(as.raw(strtoi(substring(h, seq(1, nchar(h), 2), seq(2, nchar(h), 2)), 16L)))
  check_layout <- vapply(seq_len(nrow(j)), function(i) { bl <- j$block[i]
    if (bl == "mu") r$name[i] == "beta_mu" else if (bl == "sigma") r$name[i] == "beta_sigma"
    else if (bl == "recov") grepl("^(theta_re_cov|eta_cor)", r$name[i])
    else { f <- strsplit(hexdec(sub("^sdtarget_", "", bl)), "|", fixed = TRUE)[[1]]
      k <- Filter(function(z) as.integer(z[1]) == i || as.integer(z[1]) + 1L == i, sp$sd)
      r$name[i] == paste0("beta_sd_", f[3]) && length(k) == 1 && f[1] == k[[1]][2] } }, TRUE)
  if (!all(check_layout)) stop("layout mismatch in ", tag, " at index ", paste(which(!check_layout), collapse = ","))
  dif <- j$est - r$est
  base$max_abs_coef_diff <- max(abs(dif)); base$max_coef_diff_r_se <- max(abs(dif / r$se))
  w <- which.max(abs(dif / r$se)); base$worst_param <- paste0(r$name[w], "#", w)
  base$max_se_rel_diff <- max(abs(j$se / r$se - 1))
  par_rows[[tag]] <- data.frame(route = route, seed = s, idx = seq_along(dif), julia_block = j$block, r_name = r$name, julia_est = j$est,
                                r_est = r$est, diff = dif, diff_r_se = dif / r$se, julia_se = j$se, r_se = r$se)
  d <- read.csv(file.path("data", paste0(tag, ".csv")))
  sdrel <- sapply(sp$sd, function(b) { i <- as.integer(b[1]); u <- unique(d[, c(b[2], b[3])]); zz <- u[[2]]
    sj <- exp(j$est[i] + j$est[i + 1] * zz); sr <- exp(r$est[i] + r$est[i + 1] * zz); max(abs(sj - sr) / sr) })
  base$max_sd_rel_diff <- max(sdrel)
  if (sp$rho == "chol") base$max_rho_diff <- max(abs(chol_rho(j$est[sp$rj], sp$q) - chol_rho(r$est[sp$rj], sp$q)))
  if (sp$rho == "atanh") base$max_rho_diff <- max(abs(0.999999 * tanh(j$est[sp$rj]) - 0.999999 * tanh(r$est[sp$rj])))
  rows[[tag]] <- base
}
raw <- do.call(rbind, rows); rownames(raw) <- NULL
write.csv(raw, "raw_per_seed.csv", row.names = FALSE)
write.csv(do.call(rbind, par_rows), "raw_per_parameter.csv", row.names = FALSE)
summ <- do.call(rbind, lapply(split(raw, factor(raw$route, levels = routes)), function(x) {
  ok <- !is.na(x$ll_diff); w <- function(col) { v <- abs(x[[col]]); if (all(is.na(v))) return(c(NA, NA)); i <- which.max(v); c(v[i], x$seed[i]) }
  a <- w("max_coef_diff_r_se"); b <- w("max_abs_coef_diff"); c1 <- w("max_sd_rel_diff"); l <- w("ll_diff"); rr <- w("max_rho_diff"); sr <- w("max_se_rel_diff")
  data.frame(route = x$route[1], seeds = nrow(x), compared = sum(ok), both_converged = sum(x$julia_converged %in% TRUE & x$r_converged %in% TRUE),
    r_pdHess = sum(x$r_pdHess %in% TRUE), worst_coef_diff_r_se = a[1], at_seed = a[2], worst_abs_coef_diff = b[1], worst_sd_rel_diff = c1[1], sd_at_seed = c1[2],
    worst_abs_ll_diff = l[1], ll_at_seed = l[2], worst_abs_rho_diff = rr[1], worst_se_rel_diff = sr[1], se_at_seed = sr[2],
    max_julia_sec = suppressWarnings(max(x$julia_sec, na.rm = TRUE)), max_r_sec = suppressWarnings(max(x$r_sec, na.rm = TRUE)))
}))
rownames(summ) <- NULL; write.csv(summ, "summary.csv", row.names = FALSE); print(summ, digits = 3)
# seeds flagged for inspection (triage thresholds only; nothing is tolerance-tested)
flag <- raw[!(raw$julia_converged %in% TRUE & raw$r_converged %in% TRUE) | is.na(raw$ll_diff) | abs(raw$max_coef_diff_r_se) > 1e-3 |
            abs(raw$max_abs_coef_diff) > 1e-3 | abs(raw$max_sd_rel_diff) > 1e-3 | abs(raw$ll_diff) > 1e-6 | raw$note != "" | !(raw$r_pdHess %in% TRUE), ]
cat("\nFlagged seeds (non-convergence/error/non-PD Hessian, coef diff > 1e-3 R-SE or abs, SD rel diff > 1e-3, |ll diff| > 1e-6):", nrow(flag), "\n")
if (nrow(flag)) print(flag[, c("route", "seed", "julia_converged", "r_converged", "r_pdHess", "ll_diff", "max_abs_coef_diff", "max_coef_diff_r_se", "max_sd_rel_diff", "note")])
