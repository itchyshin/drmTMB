# Julia minus R at the optimum, per route and seed (offline). Audit-fixed flag logic from the start.
# usage: SC_OUT=<out> Rscript compare.R        (run from the scripts directory; writes into SC_OUT/summary)
# Outputs: per_seed.csv, per_parameter.csv, summary_distribution.csv, nonconverged_seeds.csv, flagged_seeds.csv, layout_check.txt
source("routes.R")
O <- Sys.getenv("SC_OUT", "."); W <- file.path(O, "summary"); dir.create(W, showWarnings = FALSE)
NS <- c(gauss_q3 = 100, gauss_q4 = 100, gauss_ord = 300, nb2_relmat = 300, poisson_relmat = 100, nb2_animal = 100, nb2_phylo = 100, gauss_relmat = 100)
routes <- names(NS)
chol_rho <- function(th, q) { L <- diag(q); k <- 0; for (i in 1:q) for (j in seq_len(i - 1)) { k <- k + 1; L[i, j] <- th[k] }
  S <- L %*% t(L); d <- 1 / sqrt(diag(S)); (d * S * rep(d, each = q))[lower.tri(diag(q))] }
unhex <- function(h) rawToChar(as.raw(strtoi(substring(h, seq(1, nchar(h), 2), seq(2, nchar(h), 2)), 16L)))
expected_layout <- function(route) {   # per-index expected R names and Julia (block, k), plus the decoded-target check
  r <- ROUTES[[route]]; nc <- length(r$coefs)
  rn <- c(rep("beta_mu", r$nmu), if (r$sigma) "beta_sigma", rep("beta_sd_mu", 2 * nc))
  jb <- c(rep("mu", r$nmu), if (r$sigma) "sigma", rep(paste0("sdtarget#", seq_len(nc)), each = 2)); jk <- c(seq_len(r$nmu), if (r$sigma) 1L, rep(1:2, nc))
  np <- if (r$rho == "chol") r$q * (r$q - 1) / 2 else if (r$rho == "q2") 1 else 0
  if (np) { rn <- c(rn, if (r$rho == "chol") rep("theta_re_cov", np) else "eta_cor_mu"); jb <- c(jb, rep("recov", np)); jk <- c(jk, seq_len(np)) }
  list(rn = rn, jb = jb, jk = jk)
}
coefname <- function(c) if (c == "(Intercept)") "intercept" else c
check_layout <- function(route, j, r) {   # returns "" if the layout is as asserted, else a message
  e <- expected_layout(route); rt <- ROUTES[[route]]
  if (nrow(j) != length(e$rn) || nrow(r) != length(e$rn)) return(sprintf("length mismatch julia %d R %d expected %d", nrow(j), nrow(r), length(e$rn)))
  if (!identical(as.character(r$name), e$rn)) return("R parameter names differ from the asserted layout")
  if (!identical(as.integer(j$k), as.integer(e$jk))) return("Julia within-block index differs from the asserted layout")
  blk <- ifelse(grepl("^sdtarget_", j$block), NA, j$block); sdb <- unique(j$block[grepl("^sdtarget_", j$block)])
  if (length(sdb) != length(rt$coefs)) return("number of Julia SD blocks differs")
  ok <- vapply(seq_along(sdb), function(i) { f <- strsplit(unhex(sub("^sdtarget_", "", sdb[i])), "|", fixed = TRUE)[[1]]; n <- length(f)
    f[1] == rt$grp && f[n] == "none" && f[n - 1] == coefname(rt$coefs[i]) && f[n - 2] == "mu" && (rt$level == "" || f[2] == rt$level || (rt$level == "phylogenetic" && grepl("phylo", f[2]))) }, TRUE)
  if (!all(ok)) return("a Julia SD block decodes to a different group/level/coefficient than the asserted one")
  jb2 <- blk; for (i in seq_along(sdb)) jb2[j$block == sdb[i]] <- paste0("sdtarget#", i)
  if (!identical(as.character(jb2), e$jb)) return("Julia block order differs from the asserted layout")
  ""
}
layout_lines <- list()
rows <- list(); par_rows <- list()
for (route in routes) for (s in seq_len(NS[[route]])) {
  tag <- sprintf("%s_s%03d", route, s); rt <- ROUTES[[route]]
  rd <- function(p) tryCatch(read.csv(p, colClasses = c(ll = "character", msg = "character")), error = function(e) NULL)
  jl <- rd(file.path(O, "julia", paste0(tag, "_ll.csv"))); rl <- rd(file.path(O, "r", paste0(tag, "_ll.csv")))
  base <- data.frame(route = route, seed = s, julia_converged = NA, r_converged = NA, r_pdHess = NA, ll_julia = NA_real_, ll_R = NA_real_, ll_diff = NA_real_,
    max_abs_coef_diff = NA_real_, max_coef_diff_r_se = NA_real_, worst_param = NA_character_, max_sd_rel_diff = NA_real_, max_sd_abs_diff = NA_real_,
    rho_julia_maxabs = NA_real_, rho_R_maxabs = NA_real_, rho_diff = NA_real_, nonfinite_se_julia = NA_integer_, nonfinite_se_R = NA_integer_,
    boundary_R = NA, boundary_julia = NA, julia_sec = NA_real_, r_sec = NA_real_, note = "", stringsAsFactors = FALSE)
  if (is.null(jl) || is.null(rl)) { base$note <- "missing output"; rows[[tag]] <- base; next }
  base$julia_converged <- identical(jl$converged, "true"); base$r_converged <- rl$convergence == 0; base$r_pdHess <- rl$pdHess
  base$julia_sec <- suppressWarnings(as.numeric(jl$seconds)); base$r_sec <- suppressWarnings(as.numeric(rl$seconds))
  if (identical(jl$converged, "error") || identical(rl$convergence, "error")) {
    base$note <- paste0("fit error: julia ", jl$converged, " [", jl$msg, "]; R ", rl$convergence, " [", rl$msg, "]"); rows[[tag]] <- base; next }
  base$ll_julia <- as.numeric(jl$ll); base$ll_R <- as.numeric(rl$ll); base$ll_diff <- base$ll_julia - base$ll_R
  j <- read.csv(file.path(O, "julia", paste0(tag, ".csv"))); r <- read.csv(file.path(O, "r", paste0(tag, ".csv")))
  lc <- check_layout(route, j, r)
  if (nzchar(lc)) { base$note <- paste("LAYOUT:", lc); rows[[tag]] <- base; next }
  if (s == 1) layout_lines[[route]] <- data.frame(route = route, idx = seq_len(nrow(j)), julia_block = unname(vapply(j$block, function(b) if (grepl("^sdtarget_", b)) paste0("sdtarget[", unhex(sub("^sdtarget_", "", b)), "]") else b, "")),
                                                   julia_k = j$k, r_name = r$name, asserted_r_name = expected_layout(route)$rn, asserted_julia_block = expected_layout(route)$jb)
  isrho <- if (rt$rho == "none") rep(FALSE, nrow(j)) else if (rt$rho == "chol") j$block == "recov" else j$block == "recov"
  cmp <- if (rt$rho == "q2") !isrho else rep(TRUE, nrow(j))      # q2: rho parameterisations differ, compared on the rho scale only
  dif <- j$est - r$est; sc <- ifelse(is.finite(r$se) & r$se > 0, dif / r$se, NA_real_)
  base$max_abs_coef_diff <- max(abs(dif[cmp])); base$max_coef_diff_r_se <- if (all(is.na(sc[cmp]))) NA_real_ else max(abs(sc[cmp]), na.rm = TRUE)
  wi <- which.max(abs(ifelse(is.na(sc), 0, sc)) * cmp); base$worst_param <- paste0(r$name[wi], "#", wi)
  base$nonfinite_se_julia <- sum(!is.finite(j$se)); base$nonfinite_se_R <- sum(!is.finite(r$se))
  nm <- !isrho
  base$boundary_R <- any(r$est[nm] < -6) ; base$boundary_julia <- any(j$est[nm] < -6)
  par_rows[[tag]] <- data.frame(route = route, seed = s, idx = seq_along(dif), julia_block = j$block, r_name = r$name, julia_est = j$est, r_est = r$est,
    diff = dif, diff_r_se = sc, julia_se = j$se, r_se = r$se)
  # per-level SDs
  d <- read.csv(file.path(O, "data", paste0(tag, ".csv"))); o <- rt$nmu + as.integer(rt$sigma); sdr <- numeric(); sda <- numeric()
  for (f in seq_along(rt$coefs)) {
    u <- unique(d[, c(rt$grp, rt$sdz[f])]); zz <- u[[2]]; i <- o + 2 * (f - 1) + 1
    sj <- exp(j$est[i] + j$est[i + 1] * zz); sR <- exp(r$est[i] + r$est[i + 1] * zz)
    sdr <- c(sdr, abs(sj - sR) / sR); sda <- c(sda, abs(sj - sR)) }
  base$max_sd_rel_diff <- max(sdr); base$max_sd_abs_diff <- max(sda)
  if (rt$rho == "chol") { rj <- chol_rho(j$est[isrho], rt$q); rR <- chol_rho(r$est[isrho], rt$q) }
  if (rt$rho == "q2") { th <- j$est[isrho]; rj <- th / sqrt(1 + th^2); rR <- tanh(r$est[isrho]) }
  if (rt$rho != "none") { base$rho_julia_maxabs <- max(abs(rj)); base$rho_R_maxabs <- max(abs(rR)); base$rho_diff <- max(abs(rj - rR))
    base$boundary_R <- base$boundary_R || any(abs(rR) >= 0.99999); base$boundary_julia <- base$boundary_julia || any(abs(rj) >= 0.99999) }
  rows[[tag]] <- base
}
raw <- do.call(rbind, rows); rownames(raw) <- NULL
both <- raw$julia_converged %in% TRUE & raw$r_converged %in% TRUE
raw$both_converged <- both; raw$boundary <- raw$boundary_R %in% TRUE | raw$boundary_julia %in% TRUE
reason <- function(i) { x <- raw[i, ]; out <- character()
  if (!(x$julia_converged %in% TRUE)) out <- c(out, if (is.na(x$julia_converged)) "no-julia-output" else "julia-not-converged-or-error")
  if (!(x$r_converged %in% TRUE)) out <- c(out, "r-not-converged-or-error")
  if (!(x$r_pdHess %in% TRUE)) out <- c(out, "r-hessian-not-pd")
  if (nzchar(x$note)) out <- c(out, "note")
  if (is.finite(x$max_coef_diff_r_se) && x$max_coef_diff_r_se > 1e-3) out <- c(out, "coef-diff>1e-3-R-SE")
  if (is.finite(x$max_abs_coef_diff) && x$max_abs_coef_diff > 1e-3) out <- c(out, "abs-coef-diff>1e-3")
  if (is.finite(x$ll_diff) && abs(x$ll_diff) > 1e-6) out <- c(out, "ll-diff>1e-6")
  if (is.finite(x$max_sd_abs_diff) && x$max_sd_abs_diff > 1e-3) out <- c(out, "abs-SD-diff>1e-3")
  paste(out, collapse = ";") }
raw$flag_reasons <- vapply(seq_len(nrow(raw)), reason, ""); raw$flag <- nzchar(raw$flag_reasons)
write.csv(raw, file.path(W, "per_seed.csv"), row.names = FALSE)
write.csv(do.call(rbind, par_rows), file.path(W, "per_parameter.csv"), row.names = FALSE)
q <- function(v) { v <- abs(v[is.finite(v)]); if (!length(v)) return(rep(NA_real_, 3)); c(median(v), unname(quantile(v, 0.99)), max(v)) }
summ <- do.call(rbind, lapply(routes, function(rt) {
  x <- raw[raw$route == rt, ]; y <- x[x$both_converged & !is.na(x$ll_diff), ]
  mk <- function(col) setNames(q(y[[col]]), paste0(col, c("_med", "_p99", "_max")))
  data.frame(route = rt, seeds = nrow(x), julia_converged = sum(x$julia_converged %in% TRUE), r_converged = sum(x$r_converged %in% TRUE), both_converged = sum(x$both_converged),
    r_pdHess = sum(x$r_pdHess %in% TRUE), compared = nrow(y), t(mk("max_coef_diff_r_se")), t(mk("max_abs_coef_diff")), t(mk("max_sd_rel_diff")), t(mk("max_sd_abs_diff")),
    t(mk("ll_diff")), t(mk("rho_diff")),
    seeds_nonfinite_se_julia = sum(y$nonfinite_se_julia > 0, na.rm = TRUE), seeds_nonfinite_se_R = sum(y$nonfinite_se_R > 0, na.rm = TRUE),
    seeds_boundary = sum(x$boundary), seeds_flagged = sum(x$flag), median_julia_sec = median(x$julia_sec, na.rm = TRUE), median_r_sec = median(x$r_sec, na.rm = TRUE))
}))
write.csv(summ, file.path(W, "summary_distribution.csv"), row.names = FALSE)
write.csv(raw[!raw$both_converged | nzchar(raw$note), c("route", "seed", "julia_converged", "r_converged", "r_pdHess", "note")], file.path(W, "nonconverged_seeds.csv"), row.names = FALSE)
write.csv(raw[raw$flag, ], file.path(W, "flagged_seeds.csv"), row.names = FALSE)
ll <- do.call(rbind, layout_lines); sink(file.path(W, "layout_check.txt"))
cat("Layout check (seed 1 of each route): Julia block names decoded (sdtarget_<hex> -> group|[kind|]dpar|coef|level) against R parameter names, per index.\n",
    "Every seed of every route was also asserted against the template (R names, Julia within-block index, decoded SD target group/level/coefficient, block order);\n",
    "a seed that failed would carry a 'LAYOUT:' note and be flagged. Seeds with a layout note: ", sum(grepl("^LAYOUT", raw$note)), " of ", nrow(raw), ".\n\n", sep = "")
options(width = 250); for (rt in routes) { cat("---", rt, "\n"); print(ll[ll$route == rt, -1], row.names = FALSE) }
sink()
options(width = 250); print(summ[, c("route", "seeds", "both_converged", "r_pdHess", "max_coef_diff_r_se_med", "max_coef_diff_r_se_p99", "max_coef_diff_r_se_max", "max_abs_coef_diff_max", "ll_diff_max", "seeds_boundary", "seeds_flagged")], digits = 3)
cat("\nFlagged:", sum(raw$flag), " not both converged:", sum(!raw$both_converged), "\n"); print(table(raw$route[raw$flag]))
