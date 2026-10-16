# sweep-oct16 / t5 -- cross-leg comparison and pass-bar evaluation.
# Reads results/{native,native_fixedp,bridge,julia_direct}.csv and writes
# results/summary.md plus results/cells.csv (one row per dataset).
# Usage: Rscript R/compare.R <resultsdir>
args <- commandArgs(trailingOnly = TRUE)
rd <- if (length(args)) args[[1]] else "results"
nat <- read.csv(file.path(rd, "native.csv"), stringsAsFactors = FALSE)
fxp <- read.csv(file.path(rd, "native_fixedp.csv"), stringsAsFactors = FALSE)
brg <- read.csv(file.path(rd, "bridge.csv"), stringsAsFactors = FALSE)
jd  <- read.csv(file.path(rd, "julia_direct.csv"), stringsAsFactors = FALSE)
TOL <- 1e-8

pick <- function(df, key, val, ids) { x <- df[df[[key]] == val, ]; x[match(ids, x$id), ] }
ids <- unique(nat$id)
fam <- nat$family[match(ids, nat$id)]
coefd <- function(a, b, logsd_a = log(a$sd_g), logsd_b = log(b$sd_g)) {
  pmax(abs(a$b_mu0 - b$b_mu0), abs(a$b_mu1 - b$b_mu1),
       ifelse(is.na(a$b_sigma0) & is.na(b$b_sigma0), 0, abs(a$b_sigma0 - b$b_sigma0)),
       abs(logsd_a - logsd_b))
}
N <- function(v) pick(nat, "fit", v, ids)
B <- function(v) pick(brg, "fit", v, ids)
J <- function(v) { x <- jd[jd$cell == v, ]; x[match(ids, x$id), ] }

n0 <- N("N0_omitted"); n1 <- N("N1_null"); n2 <- N("N2_ones"); n3 <- N("N3_int")
d3 <- N("D3_dup"); n4 <- N("N4_pos"); n5 <- N("N5_pos_cc"); n6 <- N("N6_misscontrol")
fx <- fxp[match(ids, fxp$id), ]
b0 <- B("J0_omitted"); b6 <- B("J6_misscontrol"); b7 <- B("J7_dup")
jcc <- J("JD_cc"); jlap <- J("JD_cc_lap"); jdup <- J("JD_dup"); jlw <- J("JD_listwise"); jraw <- J("JD_raw")
num <- function(v) suppressWarnings(as.numeric(v))

cells <- data.frame(
  id = ids, family = fam, na_y = n0$na_y, na_x = n0$na_x, n_complete = n0$n_complete_harness,
  # Bar 1: integer weights == row duplication (native)
  int_dup_dLL = n3$logLik - d3$logLik, int_dup_dcoef = coefd(n3, d3),
  int_dup_fixedp_fn = fx$fn_int_minus_dup,
  # Weight semantics: NULL / ones / omitted, alignment, oracle
  null_vs_omit_dLL = n1$logLik - n0$logLik, ones_vs_omit_dLL = n2$logLik - n0$logLik,
  pos_vs_poscc_dLL = n4$logLik - n5$logLik,
  oracle_max = pmax(abs(n0$logLik - n0$oracle_ll), abs(n3$logLik - n3$oracle_ll),
                    abs(d3$logLik - d3$oracle_ll), abs(n4$logLik - n4$oracle_ll)),
  # Bar 2: nobs equal across engines
  nobs_native = n0$nobs, nobs_bridge = ifelse(b0$status == "ok", b0$nobs, NA),
  nobs_jl_listwise = num(jlw$nobs), nobs_jl_cc = num(jcc$nobs),
  nobs_jl_raw = ifelse(jraw$status == "ok", num(jraw$nobs), NA),
  jl_raw_status = ifelse(jraw$status == "ok", "ok", jraw$errtype),
  # Bar 3: engine = "julia" vs native (weights omitted)
  bridge_status = ifelse(b0$status == "ok", "ok",
                          ifelse(grepl("resd", b0$error, fixed = TRUE), "error: resd label (#1551)",
                          ifelse(grepl("does not support `weights`", b0$error, fixed = TRUE), "error: weights fenced (#1450)",
                          ifelse(grepl("status 139|SIGSEGV|setup.jl|install_dependency", b0$error),
                                 "error: JuliaCall setup/segfault (exit 139)",
                                 b0$error)))),
  bridge_dLL = ifelse(b0$status == "ok", b0$logLik - n0$logLik, NA),
  bridge_dcoef = ifelse(b0$status == "ok", coefd(b0, n0), NA),
  bridge_dup_vs_native_int_dLL = ifelse(b7$status == "ok", b7$logLik - n3$logLik, NA),
  # Direct DRModels.jl vs native on complete cases
  jl_cc_dLL = num(jcc$loglik) - n0$logLik,
  jl_cc_dcoef = coefd(data.frame(b_mu0 = num(jcc$b_mu0), b_mu1 = num(jcc$b_mu1), b_sigma0 = num(jcc$b_sigma0)),
                      n0, logsd_a = num(jcc$log_sd_g)),
  jl_cc_marginal = jcc$marginal,
  jl_lap_dLL = ifelse(fam == "gaussian", NA, num(jlap$loglik) - n0$logLik),
  jl_lap_dcoef = ifelse(fam == "gaussian", NA,
                        coefd(data.frame(b_mu0 = num(jlap$b_mu0), b_mu1 = num(jlap$b_mu1), b_sigma0 = num(jlap$b_sigma0)),
                              n0, logsd_a = num(jlap$log_sd_g))),
  jl_dup_vs_native_int_dLL = num(jdup$loglik) - n3$logLik,
  jl_dup_vs_native_int_dcoef = coefd(data.frame(b_mu0 = num(jdup$b_mu0), b_mu1 = num(jdup$b_mu1), b_sigma0 = num(jdup$b_sigma0)),
                                     n3, logsd_a = num(jdup$log_sd_g)),
  # Explicit miss_control() asymmetry
  misscontrol_native = n6$status, misscontrol_bridge = ifelse(b6$status == "ok", "ok",
                                                              ifelse(grepl("resd", b6$error), "error: resd (#1551)", "error")),
  stringsAsFactors = FALSE)
write.csv(cells, file.path(rd, "cells.csv"), row.names = FALSE)

mx <- function(x) max(abs(x), na.rm = TRUE)
f <- function(x) {
  m <- suppressWarnings(mx(x))
  if (!is.finite(m)) "NA" else formatC(m, format = "e", digits = 1)
}
pf <- function(ok) if (isTRUE(ok)) "**PASS**" else "**FAIL**"
gauss <- fam == "gaussian"
lines <- c(
  "## Pass bars (computed by R/compare.R)", "",
  "| Bar | Scope | Metric | Value | Verdict |", "|---|---|---|---|---|",
  sprintf("| Integer weights = row duplication (logLik) | native, 27 cells | max \\|ΔlogLik\\| | %s | %s |",
          f(mx(cells$int_dup_dLL)), pf(mx(cells$int_dup_dLL) <= TOL)),
  sprintf("| Integer weights = row duplication (coefficients) | native, 27 cells | max \\|Δ\\| over β_μ, β_σ, log SD(g) | %s | %s |",
          f(mx(cells$int_dup_dcoef)), pf(mx(cells$int_dup_dcoef) <= TOL)),
  sprintf("| Same, objective at fixed θ | native, 27 cells | max \\|Δ nll(θ̂)\\| | %s | %s |",
          f(mx(cells$int_dup_fixedp_fn)), pf(mx(cells$int_dup_fixedp_fn) <= TOL)),
  sprintf("| `weights = NULL` and all-ones = omitted | native, 27 cells | max \\|ΔlogLik\\| | %s | %s |",
          f(max(mx(cells$null_vs_omit_dLL), mx(cells$ones_vs_omit_dLL))),
          pf(max(mx(cells$null_vs_omit_dLL), mx(cells$ones_vs_omit_dLL)) == 0)),
  sprintf("| Random positive weights: NA-row drop keeps weights aligned | native, 27 cells | max \\|ΔlogLik\\| raw vs pre-dropped | %s | %s |",
          f(mx(cells$pos_vs_poscc_dLL)), pf(mx(cells$pos_vs_poscc_dLL) == 0)),
  sprintf("| Weighted logLik = independent Laplace oracle | native, 27 cells × 4 weightings | max \\|Δ\\| | %s | %s |",
          f(mx(cells$oracle_max)), pf(mx(cells$oracle_max) <= TOL)),
  sprintf("| nobs: native = harness complete cases | 27 cells | mismatches | %d | %s |",
          sum(cells$nobs_native != cells$n_complete), pf(all(cells$nobs_native == cells$n_complete))),
  sprintf("| nobs: bridge = native | Gaussian, 9 cells | mismatches | %d | %s |",
          sum(is.na(cells$nobs_bridge[gauss]) | cells$nobs_bridge[gauss] != cells$nobs_native[gauss]),
          if (all(is.na(cells$nobs_bridge[gauss])))
            paste0("**FAIL** (", unique(cells$bridge_status[gauss])[1], ")")
          else
            pf(all(cells$nobs_bridge[gauss] == cells$nobs_native[gauss]))),
  sprintf("| nobs: bridge = native | Poisson/Gamma, 18 cells | fits returned | %d / 18 | %s |",
          sum(!is.na(cells$nobs_bridge[!gauss])),
          if (all(is.na(cells$nobs_bridge[!gauss])))
            paste0("**FAIL** (", unique(cells$bridge_status[!gauss])[1], ")")
          else "**FAIL** (#1551)"),
  sprintf("| nobs: DRModels `drm_listwise` = native | 27 cells | mismatches | %d | %s |",
          sum(cells$nobs_jl_listwise != cells$nobs_native), pf(all(cells$nobs_jl_listwise == cells$nobs_native))),
  sprintf("| nobs: DRModels raw data with `missing` = native | 27 cells | fits returned / matching | %d / %d | %s |",
          sum(!is.na(cells$nobs_jl_raw)), sum(cells$nobs_jl_raw == cells$nobs_native, na.rm = TRUE),
          "**FAIL** (#1089: KeyError on missing x; Gaussian (1\\|g) refuses missing y)"),
  sprintf("| `engine = \"julia\"` = native | Gaussian, 9 cells | max \\|ΔlogLik\\| / max \\|Δcoef\\| | %s / %s | %s |",
          f(mx(cells$bridge_dLL[gauss])), f(mx(cells$bridge_dcoef[gauss])),
          if (all(is.na(cells$bridge_dLL[gauss])))
            paste0("**FAIL** (", unique(cells$bridge_status[gauss])[1], ")")
          else
            pf(mx(cells$bridge_dLL[gauss]) <= TOL && mx(cells$bridge_dcoef[gauss]) <= TOL)),
  sprintf("| `engine = \"julia\"` = native | Poisson/Gamma, 18 cells | fits returned | %d / 18 | %s |",
          sum(!is.na(cells$bridge_dLL[!gauss])),
          if (all(is.na(cells$bridge_dLL[!gauss])))
            paste0("**FAIL** (", unique(cells$bridge_status[!gauss])[1], ")")
          else "**FAIL** (#1551)"),
  "| `engine = \"julia\"` with any `weights` (incl. `NULL`) | 27 cells × 4 | fits returned | 0 / 108 | fenced (#1450; #1502 draft) |",
  sprintf("| Julia on duplicated rows = native integer weights | bridge, Gaussian, 9 cells | max \\|ΔlogLik\\| | %s | %s |",
          f(mx(cells$bridge_dup_vs_native_int_dLL[gauss])),
          if (all(is.na(cells$bridge_dup_vs_native_int_dLL[gauss])))
            paste0("**FAIL** (", unique(cells$bridge_status[gauss])[1], ")")
          else
            pf(mx(cells$bridge_dup_vs_native_int_dLL[gauss]) <= TOL)),
  sprintf("| DRModels direct, complete cases = native | Gaussian, 9 cells | max \\|ΔlogLik\\| / max \\|Δcoef\\| | %s / %s | %s |",
          f(mx(cells$jl_cc_dLL[gauss])), f(mx(cells$jl_cc_dcoef[gauss])),
          pf(mx(cells$jl_cc_dLL[gauss]) <= TOL && mx(cells$jl_cc_dcoef[gauss]) <= TOL)),
  sprintf("| DRModels direct, `marginal = :Laplace` = native | Poisson/Gamma, 18 cells | max \\|ΔlogLik\\| / max \\|Δcoef\\| | %s / %s | %s |",
          f(mx(cells$jl_lap_dLL[!gauss])), f(mx(cells$jl_lap_dcoef[!gauss])),
          pf(mx(cells$jl_lap_dLL[!gauss]) <= TOL && mx(cells$jl_lap_dcoef[!gauss]) <= TOL)),
  sprintf("| DRModels direct, default `:LA` (AGHQ-5) vs native Laplace | Poisson/Gamma, 18 cells | max \\|ΔlogLik\\| / max \\|Δcoef\\| | %s / %s | different integrator (informative) |",
          f(mx(cells$jl_cc_dLL[!gauss])), f(mx(cells$jl_cc_dcoef[!gauss]))),
  sprintf("| DRModels direct on duplicated rows = native integer weights | 27 cells (Laplace for Poisson/Gamma) | max \\|ΔlogLik\\| / max \\|Δcoef\\| | %s / %s | %s |",
          f(mx(cells$jl_dup_vs_native_int_dLL)), f(mx(cells$jl_dup_vs_native_int_dcoef)),
          pf(mx(cells$jl_dup_vs_native_int_dLL) <= TOL && mx(cells$jl_dup_vs_native_int_dcoef) <= TOL)),
  "| DRModels `drm(...; weights = w)` | 27 cells | fits returned | 0 / 27 (`MethodError`) | not implemented (#931, #691; #1061 draft) |",
  sprintf("| Explicit `miss_control()` with NA in x: Julia fails like native | Gaussian, 6 cells | Julia fits instead of failing | %d / 6 | %s |",
          sum(cells$misscontrol_bridge[gauss & cells$na_x > 0] == "ok"),
          if (any(cells$misscontrol_bridge[gauss & cells$na_x > 0] == "ok")) "**FAIL** (#1454 comment)"
          else if (all(is.na(cells$nobs_bridge[gauss]))) "**UNTESTED** (bridge never started)"
          else "**PASS**"),
  "")
writeLines(lines, file.path(rd, "summary.md"))
cat(lines, sep = "\n")
