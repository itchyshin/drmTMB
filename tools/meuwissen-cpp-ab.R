# Same-build A/B: C++ Meuwissen-Luo F vs the private R walk.
# Arms share one load_all() DLL. Construction times
# drm_pedigree_sparse_precision() with C F (default) vs R F
# (temporary namespace swap of drm_pedigree_inbreeding_meuwissen_luo).
#
# Usage:
#   R_PROFILE_USER=/dev/null Rscript --no-init-file \
#     tools/meuwissen-cpp-ab.R
# Optional: DRM_CPP_NS="1500,3000,6000"  DRM_CPP_OUT=path.csv

suppressMessages({
  pkgload::load_all(quiet = TRUE)
})

ns <- asNamespace("drmTMB")
ML_C <- get("drm_pedigree_inbreeding_meuwissen_luo", envir = ns)
ML_R <- get("drm_pedigree_inbreeding_meuwissen_luo_r", envir = ns)

set_f_arm <- function(arm) {
  utils::assignInNamespace(
    "drm_pedigree_inbreeding_meuwissen_luo",
    if (arm == "R") ML_R else ML_C,
    ns = "drmTMB"
  )
}

make_pedigree <- function(n, n_founder, seed) {
  set.seed(seed)
  ids <- sprintf("i%06d", seq_len(n))
  dam <- rep(NA_character_, n)
  sire <- rep(NA_character_, n)
  for (i in (n_founder + 1L):n) {
    lo <- max(1L, i - 400L)
    parents <- sample(seq.int(lo, i - 1L), 2L)
    dam[[i]] <- ids[[parents[[1L]]]]
    sire[[i]] <- ids[[parents[[2L]]]]
  }
  data.frame(id = ids, dam = dam, sire = sire, stringsAsFactors = FALSE)
}

sizes_raw <- Sys.getenv("DRM_CPP_NS", "1500,3000,6000")
sizes <- as.integer(strsplit(sizes_raw, ",", fixed = TRUE)[[1]])
out_path <- Sys.getenv(
  "DRM_CPP_OUT",
  file.path("docs", "dev-log", "2026-09-26-meuwissen-cpp-ab.csv")
)

rows <- list()
on.exit(set_f_arm("C"), add = TRUE)

for (n in sizes) {
  n_founder <- max(20L, as.integer(round(n * 0.05)))
  ped <- make_pedigree(n, n_founder, seed = 20260926L + n)
  ped <- ped[drmTMB:::drm_pedigree_topological_order(ped), , drop = FALSE]

  set_f_arm("C")
  t_f_c <- system.time(F_c <- drmTMB:::drm_pedigree_inbreeding_meuwissen_luo(ped))
  t_cons_c <- system.time(
    Ainv_c <- drmTMB:::drm_pedigree_sparse_precision(ped)
  )

  set_f_arm("R")
  t_f_r <- system.time(F_r <- drmTMB:::drm_pedigree_inbreeding_meuwissen_luo(ped))
  t_cons_r <- system.time(
    Ainv_r <- drmTMB:::drm_pedigree_sparse_precision(ped)
  )
  set_f_arm("C")

  max_dF <- max(abs(unname(F_c) - unname(F_r)))
  max_dA <- max(abs(Ainv_c - Ainv_r))

  rows[[length(rows) + 1L]] <- data.frame(
    n = n,
    f_c_s = unname(t_f_c[["elapsed"]]),
    f_r_s = unname(t_f_r[["elapsed"]]),
    construct_c_s = unname(t_cons_c[["elapsed"]]),
    construct_r_s = unname(t_cons_r[["elapsed"]]),
    max_abs_dF = max_dF,
    max_abs_dAinv = max_dA,
    stringsAsFactors = FALSE
  )
  message(sprintf(
    "n=%d  F C=%.3fs R=%.3fs  construct C=%.3fs R=%.3fs  max|dF|=%.3e",
    n,
    t_f_c[["elapsed"]],
    t_f_r[["elapsed"]],
    t_cons_c[["elapsed"]],
    t_cons_r[["elapsed"]],
    max_dF
  ))
}

out <- do.call(rbind, rows)
dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
utils::write.csv(out, out_path, row.names = FALSE)
message("wrote ", normalizePath(out_path))
print(out)
