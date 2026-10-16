# t6: build the receipt's results matrix from the harness result files.
# Run from the repository root: Rscript sweep-oct16/t6/R/90_receipt_matrix.R
# Writes sweep-oct16/t6/results/matrix_t6.md. Base R only.

res_dir <- file.path("sweep-oct16", "t6", "results")
cells <- read.csv(file.path("sweep-oct16", "t6", "data", "cells.csv"), stringsAsFactors = FALSE)
cells$cell <- paste(cells$family, cells$re, sep = "_")

r <- read.csv(file.path(res_dir, "r_summary.csv"), stringsAsFactors = FALSE)
jl <- read.csv(file.path(res_dir, "jl_summary.csv"), stringsAsFactors = FALSE)
par <- read.csv(file.path(res_dir, "parity_p9_p10.csv"), stringsAsFactors = FALSE)
br <- read.csv(file.path(res_dir, "bridge_summary.csv"), stringsAsFactors = FALSE)

fmt <- function(x, d = 1) {
  if (length(x) == 0L || is.na(x)) return("NA")
  formatC(x, format = "e", digits = d)
}
z <- function(x) if (length(x) == 0L || is.na(x)) "NA" else sprintf("%.1f", x)
abbrev <- function(s) {
  s <- s[!is.na(s) & nzchar(s)]
  if (length(s) == 0L) return("-")
  s <- unique(s)
  if (all(s == "PASS")) return("P")
  if (any(s == "ERROR")) return("E")
  if (any(s == "FAIL")) return("F")
  if (all(s == "NA")) return("-")
  paste(s, collapse = "/")
}

rows <- lapply(cells$cell, function(cl) {
  rr <- r[r$cell == cl, ]
  rs <- function(t) abbrev(rr$status[rr$test == t])
  rz <- function(t) z(rr$value[rr$test == t])
  r_tests <- paste(vapply(paste0("P", 1:7), rs, ""), collapse = "")
  r_p8 <- paste0(rz("P8mean_default_reNA"), "/", rz("P8var_default_reNA"))
  if (any(rr$test == "P8mean_reNULL_conditional")) {
    r_p8 <- paste0(r_p8, "; re.form=NULL ", rz("P8mean_reNULL_conditional"), "/",
                   rz("P8var_reNULL_conditional"))
  }
  jj <- jl[jl$cell == cl, ]
  if (nrow(jj) == 0L || !isTRUE(as.logical(jj$fit_ok))) {
    j_tests <- "refused"
    j_p8 <- "NA"
  } else {
    j_tests <- paste(vapply(paste0("P", 1:7), function(t) abbrev(jj[[t]]), ""), collapse = "")
    j_p8 <- paste0(z(jj$P8_zmean_b0), "/", z(jj$P8_zvar_b0))
    if (!is.na(jj$P8_zvar_marg)) j_p8 <- paste0(j_p8, " (vs marginal var z ", z(jj$P8_zvar_marg), ")")
  }
  pp <- par[par$cell == cl, ]
  p9_link <- suppressWarnings(max(pp$value[pp$test == "P9" & pp$type == "link" &
                                             pp$metric == "maxabs_value"], na.rm = TRUE))
  p9_stat <- abbrev(pp$pass[pp$test == "P9" & pp$type == "summary"])
  p10_link <- suppressWarnings(max(pp$value[pp$test == "P10" & pp$type == "link" &
                                              pp$metric == "maxabs_value"], na.rm = TRUE))
  p10_stat <- abbrev(pp$pass[pp$test == "P10" & pp$type == "summary"])
  bb <- br[br$cell == cl, ]
  b_txt <- if (nrow(bb) == 0L || !isTRUE(bb$admitted)) "refused" else
    if (identical(bb$P11, "NA") || is.na(bb$P11)) "admitted; P11 NA (native predict errors)" else
    paste0(bb$P11, " (", fmt(bb$P11_link_maxabs), ")")
  data.frame(
    cell = cl, seed = cells$seed[cells$cell == cl],
    r = r_tests, r_p8 = r_p8, jl = j_tests, jl_p8 = j_p8,
    p9 = if (is.finite(p9_link)) paste0(p9_stat, " (link ", fmt(p9_link), ")") else p9_stat,
    p10 = if (is.finite(p10_link)) paste0(p10_stat, " (link ", fmt(p10_link), ")") else p10_stat,
    p11 = b_txt, stringsAsFactors = FALSE
  )
})
m <- do.call(rbind, rows)

hdr <- c(
  "| cell | seed | R P1-P7 | R P8 z mean/var | Julia P1-P7 | Julia P8 z mean/var (b = 0) | P9 shared-theta | P10 own fits | P11 bridge |",
  "|---|---|---|---|---|---|---|---|---|"
)
body <- apply(m, 1, function(x) paste0("| ", paste(x, collapse = " | "), " |"))
legend <- c(
  "",
  "P = pass, F = fail, E = error, - = not applicable or not run. The seven letters are P1..P7 in order.",
  "P8 cells give z for the global mean and the batch-means variance (pass |z| < 3).",
  "P9/P10 give the overall status and the largest link-scale max |diff| over dpars on nd_main.",
  "A P9 F with link ~1e-15 is a response-scale (inverse-link) failure.",
  "Julia P6 is NA everywhere: there is no quantile API. R P6 for Tweedie: see the verifier note in the receipt."
)
writeLines(c(hdr, body, legend), file.path(res_dir, "matrix_t6.md"))
cat("wrote", file.path(res_dir, "matrix_t6.md"), "\n")
