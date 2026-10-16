#!/usr/bin/env Rscript
# Compare drmTMB vs DRModels.jl vs reference against the t8 pass bar.
# Usage: Rscript compare_case.R <case_id>
# Writes fits/<id>/compare.json and appends a row to results.csv

suppressPackageStartupMessages(library(jsonlite))

args <- commandArgs(trailingOnly = TRUE)
if (!length(args)) stop("need case id")
id <- args[[1]]
root <- Sys.getenv("T8_ROOT", unset = "/workspace/sweep-oct16/t8")
bar_ll <- 1e-4
bar_coef <- 1e-4
bar_se <- 1e-3
`%||%` <- function(a, b) {
  if (is.null(a)) return(b)
  if (length(a) == 1 && is.na(a)) return(b)
  a
}

read_opt <- function(path) {
  if (!file.exists(path)) return(NULL)
  fromJSON(path, simplifyVector = FALSE)
}

norm_name <- function(s) {
  s <- tolower(s)
  s <- gsub("\\(intercept\\)", "intercept", s)
  s <- gsub("[^a-z0-9]+", "", s)
  s
}

as_num_list <- function(x) {
  if (is.null(x) || (is.list(x) && length(x) == 0)) return(setNames(numeric(), character()))
  nms <- names(x)
  vals <- vapply(x, function(v) {
    if (is.null(v) || (is.list(v) && length(v) == 0)) return(NA_real_)
    if (is.list(v)) return(NA_real_)
    as.numeric(v)
  }, numeric(1))
  names(vals) <- nms
  vals[!is.na(vals) & names(vals) != ".error"]
}

pair_by_norm <- function(a, b) {
  if (!length(a) || !length(b)) {
    return(data.frame(name_a = character(), name_b = character(),
                      a = numeric(), b = numeric(), stringsAsFactors = FALSE))
  }
  na <- vapply(names(a), norm_name, character(1))
  nb <- vapply(names(b), norm_name, character(1))
  rows <- list()
  used_b <- logical(length(b))
  for (i in seq_along(a)) {
    hits <- which(nb == na[[i]] & !used_b)
    if (!length(hits)) next
    j <- hits[[1]]
    used_b[[j]] <- TRUE
    rows[[length(rows) + 1]] <- data.frame(
      name_a = names(a)[[i]], name_b = names(b)[[j]],
      a = unname(a[[i]]), b = unname(b[[j]]),
      stringsAsFactors = FALSE
    )
  }
  if (!length(rows)) {
    return(data.frame(name_a = character(), name_b = character(),
                      a = numeric(), b = numeric(), stringsAsFactors = FALSE))
  }
  do.call(rbind, rows)
}

rel_diff <- function(a, b) {
  abs(a - b) / pmax(pmax(abs(a), abs(b)), 1e-8)
}

r <- read_opt(file.path(root, "fits", id, "r.json"))
j <- read_opt(file.path(root, "fits", id, "jl.json"))
ref <- read_opt(file.path(root, "fits", id, "ref.json"))
spec <- read_opt(file.path(root, "fits", id, "spec.json"))

r_ok <- isTRUE(r$ok)
j_ok <- isTRUE(j$ok)
ref_ok <- isTRUE(ref$ok)

ll_r <- if (r_ok) as.numeric(r$logLik) else NA_real_
ll_j <- if (j_ok) as.numeric(j$logLik) else NA_real_
ll_ref <- if (ref_ok) as.numeric(ref$logLik) else NA_real_

d_rj <- if (is.finite(ll_r) && is.finite(ll_j)) abs(ll_r - ll_j) else NA_real_
d_rref <- if (is.finite(ll_r) && is.finite(ll_ref)) abs(ll_r - ll_ref) else NA_real_
d_jref <- if (is.finite(ll_j) && is.finite(ll_ref)) abs(ll_j - ll_ref) else NA_real_

ll_pass_rj <- is.finite(d_rj) && d_rj <= bar_ll
ll_pass_rref <- is.finite(d_rref) && d_rref <= bar_ll
ll_pass_jref <- is.finite(d_jref) && d_jref <= bar_ll

# coefficient / SE match drmTMB vs Julia on shared normalised names
coef_r <- as_num_list(r$coef)
coef_j <- as_num_list(j$coef)
se_r <- as_num_list(r$se)
se_j <- as_num_list(j$se)

pc <- pair_by_norm(coef_r, coef_j)
ps <- pair_by_norm(se_r, se_j)

if (nrow(pc)) {
  pc$rel <- rel_diff(pc$a, pc$b)
  pc$abs <- abs(pc$a - pc$b)
  pc$pass <- pc$rel <= bar_coef
} else {
  pc$rel <- numeric(); pc$abs <- numeric(); pc$pass <- logical()
}
if (nrow(ps)) {
  ps$abs <- abs(ps$a - ps$b)
  ps$rel <- rel_diff(ps$a, ps$b)
  ps$pass <- ps$abs <= bar_se
} else {
  ps$abs <- numeric(); ps$rel <- numeric(); ps$pass <- logical()
}

n_coef <- nrow(pc)
n_coef_pass <- if (n_coef) sum(pc$pass) else 0L
n_se <- nrow(ps)
n_se_pass <- if (n_se) sum(ps$pass) else 0L
max_coef_rel <- if (n_coef) max(pc$rel) else NA_real_
max_se_abs <- if (n_se) max(ps$abs) else NA_real_

coef_pass <- n_coef > 0 && n_coef_pass == n_coef
se_pass <- n_se > 0 && n_se_pass == n_se

engines_ok <- r_ok && j_ok
overall <- engines_ok && isTRUE(r$converged) && isTRUE(j$converged) &&
  ll_pass_rj && coef_pass && se_pass

verdict <- if (!r_ok && !j_ok) {
  "BOTH_FAIL"
} else if (!r_ok) {
  "R_FAIL"
} else if (!j_ok) {
  "JL_FAIL"
} else if (overall) {
  "PASS"
} else {
  "FAIL_BAR"
}

fail_reasons <- character()
if (!r_ok) fail_reasons <- c(fail_reasons, paste("drmTMB error:", r$error %||% "?"))
if (!j_ok) fail_reasons <- c(fail_reasons, paste("DRModels.jl error:", j$error %||% "?"))
if (r_ok && !isTRUE(r$converged)) fail_reasons <- c(fail_reasons, "drmTMB not converged")
if (j_ok && !isTRUE(j$converged)) fail_reasons <- c(fail_reasons, "DRModels.jl not converged")
if (r_ok && j_ok && !ll_pass_rj) {
  fail_reasons <- c(fail_reasons, sprintf("logLik |R-J|=%.6g > 1e-4", d_rj))
}
if (r_ok && j_ok && !coef_pass) {
  fail_reasons <- c(fail_reasons, sprintf("coef relative: %d/%d matched names pass 1e-4 (max rel=%.6g)",
                                          n_coef_pass, n_coef, max_coef_rel))
}
if (r_ok && j_ok && !se_pass) {
  fail_reasons <- c(fail_reasons, sprintf("SE abs: %d/%d matched names pass 1e-3 (max abs=%.6g)",
                                          n_se_pass, n_se, max_se_abs))
}

cmp <- list(
  id = id,
  source = spec$source,
  family = spec$family_r,
  n = spec$n,
  verdict = verdict,
  overall_pass = overall,
  fail_reasons = fail_reasons,
  drmTMB = list(ok = r_ok, logLik = ll_r, converged = r$converged,
                elapsed_s = r$elapsed_s, error = r$error, n_coef = length(coef_r)),
  DRModels = list(ok = j_ok, logLik = ll_j, converged = j$converged,
                  elapsed_s = j$elapsed_s, error = j$error, n_coef = length(coef_j)),
  ref = list(engine = spec$ref, ok = ref_ok, logLik = ll_ref,
             converged = ref$converged, elapsed_s = ref$elapsed_s, error = ref$error),
  logLik = list(
    abs_R_minus_J = d_rj, pass_RJ = ll_pass_rj,
    abs_R_minus_ref = d_rref, pass_Rref = ll_pass_rref,
    abs_J_minus_ref = d_jref, pass_Jref = ll_pass_jref
  ),
  coef = list(n_matched = n_coef, n_pass = n_coef_pass, max_rel = max_coef_rel, pass = coef_pass,
              pairs = if (n_coef) pc else list()),
  se = list(n_matched = n_se, n_pass = n_se_pass, max_abs = max_se_abs, pass = se_pass,
            pairs = if (n_se) ps else list())
)

write_json(cmp, file.path(root, "fits", id, "compare.json"), auto_unbox = TRUE, pretty = TRUE, na = "null", digits = 16)

scalar <- function(x, default = NA) {
  if (is.null(x) || length(x) == 0) return(default)
  x1 <- x[[1]]
  if (is.null(x1) || (length(x1) == 1 && is.na(x1))) return(default)
  x1
}
err_txt <- function(e) {
  if (is.null(e) || length(e) == 0) return("")
  paste(as.character(unlist(e)), collapse = " ")
}
row <- data.frame(
  id = id,
  source = scalar(spec$source, NA_character_),
  family = scalar(spec$family_r, NA_character_),
  n = as.integer(scalar(spec$n, NA_integer_)),
  verdict = verdict,
  ll_R = as.numeric(scalar(ll_r)), ll_J = as.numeric(scalar(ll_j)),
  ll_ref = as.numeric(scalar(ll_ref)),
  dLL_RJ = as.numeric(scalar(d_rj)), dLL_Rref = as.numeric(scalar(d_rref)),
  dLL_Jref = as.numeric(scalar(d_jref)),
  ll_pass_RJ = isTRUE(ll_pass_rj), ll_pass_Rref = isTRUE(ll_pass_rref),
  n_coef_matched = as.integer(n_coef), n_coef_pass = as.integer(n_coef_pass),
  max_coef_rel = as.numeric(scalar(max_coef_rel)),
  n_se_matched = as.integer(n_se), n_se_pass = as.integer(n_se_pass),
  max_se_abs = as.numeric(scalar(max_se_abs)),
  conv_R = isTRUE(r$converged), conv_J = isTRUE(j$converged),
  err_R = err_txt(r$error), err_J = err_txt(j$error), err_ref = err_txt(ref$error),
  elapsed_R = as.numeric(scalar(r$elapsed_s)), elapsed_J = as.numeric(scalar(j$elapsed_s)),
  fail_reasons = paste(fail_reasons, collapse = " | "),
  stringsAsFactors = FALSE
)

csv_path <- file.path(root, "results.csv")
if (file.exists(csv_path)) {
  old <- utils::read.csv(csv_path, stringsAsFactors = FALSE)
  old <- old[old$id != id, , drop = FALSE]
  utils::write.csv(rbind(old, row), csv_path, row.names = FALSE)
} else {
  utils::write.csv(row, csv_path, row.names = FALSE)
}

cat(sprintf("[%s] verdict=%s dLL(R-J)=%s coef %d/%d se %d/%d\n",
            id, verdict, format(d_rj, digits = 8),
            n_coef_pass, n_coef, n_se_pass, n_se))
if (length(fail_reasons)) cat("  ", paste(fail_reasons, collapse = "\n  "), "\n", sep = "")
if (n_coef && n_coef_pass < n_coef) {
  bad <- pc[!pc$pass, , drop = FALSE]
  cat("  failing coefs:\n")
  print(bad)
}
if (n_se && n_se_pass < n_se) {
  bad <- ps[!ps$pass, , drop = FALSE]
  cat("  failing SEs:\n")
  print(bad)
}
