# S4 ladder — drmTMB #1424: construction-inside-fit after Meuwissen-Luo F.
#
# Arms share one load_all() build. The only swap is how F is obtained:
#   DENSE_F = post-#1422: dense A, F = diag(A) - 1, then Quaas
#   ML      = this slice: Meuwissen-Luo F, then the same Quaas assembly
# Data generation does not form A (that would reintroduce the O(n^2) cost
# this ladder is measuring). Identity is same-data, two constructors.
#
# Usage:
#   R_PROFILE_USER=/dev/null Rscript --no-init-file \
#     tools/meuwissen-luo-s4-ladder.R
# Optional env: DRM_S4_NS="1500,3000,6000,10000"  DRM_S4_OUT=path.csv

suppressMessages({
  pkgload::load_all(quiet = TRUE)
})

ns <- asNamespace("drmTMB")
ML_FUN <- get("drm_pedigree_relatedness_precision", envir = ns)

DENSE_F_FUN <- function(
  pedigree,
  group,
  object = "pedigree",
  group_name = "id"
) {
  Ainv <- drmTMB:::drm_pedigree_sparse_precision_dense_F(
    pedigree,
    object = object
  )
  drmTMB:::drm_known_relatedness_precision(
    Ainv,
    group = group,
    matrix_type = "precision",
    marker = "animal",
    object = object,
    group_name = group_name,
    reported_matrix_type = "covariance"
  )
}

set_arm <- function(arm) {
  utils::assignInNamespace(
    "drm_pedigree_relatedness_precision",
    if (arm == "dense_F") DENSE_F_FUN else ML_FUN,
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

make_data <- function(ped, seed) {
  set.seed(seed + 1L)
  n <- nrow(ped)
  x <- stats::rnorm(n)
  y <- 1 + 0.5 * x + stats::rnorm(n, sd = 0.7)
  data.frame(id = ped$id, x = x, y = y, stringsAsFactors = FALSE)
}

fit_animal <- function(dat, ped) {
  drmTMB::drmTMB(
    drmTMB::bf(y ~ x + animal(1 | id, pedigree = ped), sigma ~ 1),
    data = dat,
    family = stats::gaussian()
  )
}

sizes_raw <- Sys.getenv("DRM_S4_NS", "1500,3000,6000,10000")
sizes <- as.integer(strsplit(sizes_raw, ",", fixed = TRUE)[[1]])
out_csv <- Sys.getenv(
  "DRM_S4_OUT",
  file.path(
    Sys.getenv("HOME"),
    "local-scratch/lanes/drmTMB-meuwissen-luo-1424-20260924/.unlazy/meuwissen-luo-1424/s4-ladder.csv"
  )
)
dir.create(dirname(out_csv), recursive = TRUE, showWarnings = FALSE)

# Tiny warmup so the first timed drmTMB() is not the ADFun compile.
invisible(fit_animal(
  data.frame(id = c("a", "b", "c"), x = 0:2, y = rnorm(3)),
  data.frame(
    id = c("a", "b", "c"),
    dam = c(NA, NA, "b"),
    sire = c(NA, NA, "a"),
    stringsAsFactors = FALSE
  )
))

rows <- list()
for (n in sizes) {
  n_founder <- max(20L, as.integer(round(0.1 * n)))
  ped <- make_pedigree(n, n_founder, seed = 1424L + n)
  dat <- make_data(ped, seed = 1424L + n)

  t_dense <- system.time({
    Ainv_dense <- drmTMB:::drm_pedigree_sparse_precision_dense_F(ped)
  })[["elapsed"]]
  t_ml <- system.time({
    Ainv_ml <- drmTMB:::drm_pedigree_sparse_precision(ped)
  })[["elapsed"]]
  delta_x <- (Ainv_ml - Ainv_dense)@x
  max_ainv <- if (length(delta_x) == 0L) 0 else max(abs(delta_x))
  nnz <- as.integer(Matrix::nnzero(Ainv_ml))

  set_arm("dense_F")
  t_dense_fit <- system.time({
    fit_dense <- fit_animal(dat, ped)
  })[["elapsed"]]
  set_arm("ml")
  t_ml_fit <- system.time({
    fit_ml <- fit_animal(dat, ped)
  })[["elapsed"]]

  mu_dense <- as.numeric(coef(fit_dense, "mu"))
  mu_ml <- as.numeric(coef(fit_ml, "mu"))
  if (length(mu_dense) != length(mu_ml) || length(mu_dense) == 0L) {
    stop("coef(fit, 'mu') length mismatch: dense=", length(mu_dense), " ml=", length(mu_ml))
  }
  max_coef <- max(abs(mu_ml - mu_dense))
  d_ll <- abs(
    as.numeric(stats::logLik(fit_ml)) - as.numeric(stats::logLik(fit_dense))
  )
  conv_dense <- as.integer(fit_dense$opt$convergence)[[1L]]
  conv_ml <- as.integer(fit_ml$opt$convergence)[[1L]]

  row <- data.frame(
    n = n,
    n_founder = n_founder,
    construct_dense_F_s = unname(t_dense),
    construct_ml_s = unname(t_ml),
    fit_dense_F_s = unname(t_dense_fit),
    fit_ml_s = unname(t_ml_fit),
    construct_inside_fit_ml_s = unname(t_ml),
    max_abs_ainv = max_ainv,
    max_abs_coef = max_coef,
    abs_d_logLik = d_ll,
    nnz = nnz,
    conv_dense = conv_dense,
    conv_ml = conv_ml,
    stringsAsFactors = FALSE
  )
  rows[[as.character(n)]] <- row
  utils::write.csv(do.call(rbind, rows), out_csv, row.names = FALSE)
  message(sprintf(
    "n=%d construct dense=%.3fs ml=%.3fs | fit dense=%.3fs ml=%.3fs | |dAinv|=%.3e |dcoef|=%.3e |dll|=%.3e nnz=%d",
    n,
    t_dense,
    t_ml,
    t_dense_fit,
    t_ml_fit,
    max_ainv,
    max_coef,
    d_ll,
    nnz
  ))
}

set_arm("ml")
message("wrote ", out_csv)
