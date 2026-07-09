# Parallel recovery ladder: scale-side REML for spatial/animal/relmat providers.
# Overnight certification-precision run (C1). Parallelizes the seed loop; keeps the
# gate bypass (assignInNamespace) so the fit is admitted for evidence generation.
#
#   OPENBLAS_NUM_THREADS=1 N_SEEDS=400 NCORES=64 Rscript --no-init-file <this>
#
# Signals (see serial script header for the full caveat on signal 2):
#   (1) bias -> 0 with g for BOTH estimators   -> estimator is sound, just needs data
#   (3) paired REML>ML near N/N for the intercept SD (the admission target)
# At N_SEEDS=400 the bias MCSE is ~0.008 (vs ~0.02 at 40), sharpening the bias columns.
suppressMessages(devtools::load_all(".", quiet = TRUE))
suppressMessages(library(parallel))

N_SEEDS <- as.integer(Sys.getenv("N_SEEDS", "400"))
NCORES  <- as.integer(Sys.getenv("NCORES", "64"))
N_EACH  <- 20L
TRUTH <- list(mu_intercept = .40, mu_x = .25, log_sigma_intercept = -.90,
              sd_sigma_intercept = .50, sd_sigma_x = .38)

spatial_K <- function(n) {
  labels <- paste0("site_", seq_len(n)); theta <- seq(0, 1.5 * pi, length.out = n)
  coords <- data.frame(x = cos(theta) + seq_len(n) / (3 * n), y = sin(theta))
  rownames(coords) <- labels
  p <- drmTMB:::drm_spatial_coords_precision(coords, site = labels, group = "site")
  list(labels = labels, coords = coords, K = solve(as.matrix(p$precision)))
}
relmat_K <- function(n) {
  labels <- paste0("id", seq_len(n))
  K <- outer(seq_len(n), seq_len(n), function(i, j) .35^abs(i - j))
  diag(K) <- diag(K) + .15; dimnames(K) <- list(labels, labels)
  list(labels = labels, K = K)
}
animal_K <- function() {
  ped <- data.frame(id = paste0("id", 1:8),
                    dam = c(NA, NA, NA, NA, "id1", "id3", "id5", "id1"),
                    sire = c(NA, NA, NA, NA, "id2", "id4", "id6", "id3"),
                    stringsAsFactors = FALSE)
  K <- drmTMB:::drm_pedigree_additive_relationship(ped)
  list(labels = rownames(K), K = K)
}
scaled_effects <- function(K, sds) {
  z <- replicate(length(sds), as.vector(t(chol(K)) %*% stats::rnorm(nrow(K))))
  out <- sweep(z, 2L, sds, `*`); colnames(out) <- names(sds); out
}
make_data <- function(provider, g, seed) {
  set.seed(seed)
  o <- switch(provider, spatial = spatial_K(g), relmat = relmat_K(g), animal = animal_K())
  grp <- if (provider == "spatial") "site" else "id"
  eff <- scaled_effects(o$K, c(i = TRUTH$sd_sigma_intercept, s = TRUTH$sd_sigma_x))
  rownames(eff) <- o$labels
  ep <- rep(o$labels, each = N_EACH)
  x <- rep(seq(-1.2, 1.2, length.out = N_EACH), times = length(o$labels))
  eta <- TRUTH$log_sigma_intercept + eff[ep, "i"] + eff[ep, "s"] * x
  y <- TRUTH$mu_intercept + TRUTH$mu_x * x + exp(eta) * stats::rnorm(length(x))
  d <- data.frame(y = y, x = x, stringsAsFactors = FALSE); d[[grp]] <- ep
  list(data = d, coords = o$coords, K = o$K)
}
fit_one <- function(provider, sim, reml) {
  form <- switch(provider,
    spatial = { coords <- sim$coords; bf(y ~ x, sigma ~ spatial(1 + x | site, coords = coords)) },
    relmat  = { K <- sim$K;           bf(y ~ x, sigma ~ relmat(1 + x | id, K = K)) },
    animal  = { A <- sim$K;           bf(y ~ x, sigma ~ animal(1 + x | id, A = A)) })
  tryCatch(drmTMB(form, family = gaussian(), data = sim$data, REML = reml,
                  control = drm_control(optimizer = list(eval.max = 1400, iter.max = 1400))),
           error = function(e) e)
}
grab <- function(f) {
  if (inherits(f, "error")) return(c(int = NA, slp = NA, conv = NA, pdh = NA))
  p <- tryCatch({ s <- summary(f)$parameters; stats::setNames(s$estimate, s$parm) },
                error = function(e) NULL)
  if (is.null(p)) return(c(int = NA, slp = NA, conv = NA, pdh = NA))
  ii <- grep("^sd:sigma:.*\\(1 \\|", names(p)); ss <- grep("^sd:sigma:.*\\(0 \\+ x \\|", names(p))
  c(int = if (length(ii)) p[[ii[1]]] else NA,
    slp = if (length(ss)) p[[ss[1]]] else NA,
    conv = f$opt$convergence, pdh = isTRUE(f$sdr$pdHess))
}

# Bypass the provider gate in the parent; mclapply forks inherit it.
orig_validate <- drmTMB:::drm_validate_reml_spec
assignInNamespace("drm_validate_reml_spec", function(spec) invisible(TRUE), ns = "drmTMB")

cells <- rbind(
  expand.grid(provider = "spatial", g = c(8L, 16L, 32L), stringsAsFactors = FALSE),
  expand.grid(provider = "relmat",  g = c(8L, 16L, 32L), stringsAsFactors = FALSE),
  expand.grid(provider = "animal",  g = 8L,              stringsAsFactors = FALSE)
)

cat(sprintf("N_SEEDS=%d NCORES=%d  (bias MCSE ~ %.3f)\n", N_SEEDS, NCORES, 0.5 / sqrt(N_SEEDS)))
cat(sprintf("%-8s %-3s %-5s %8s %8s %8s %8s %9s %7s %7s\n",
            "provider","g","targ","ML_bias","REML_bias","ML_sd","REML_sd","REML>ML","MLconv","RMconv"))
cat(strrep("-", 92), "\n")
out <- list()
for (r in seq_len(nrow(cells))) {
  prov <- cells$provider[r]; g <- cells$g[r]
  res <- mclapply(seq_len(N_SEEDS), function(s) {
    sim <- make_data(prov, g, 920000L + 1000L * r + s)
    list(M = grab(fit_one(prov, sim, FALSE)), R = grab(fit_one(prov, sim, TRUE)))
  }, mc.cores = NCORES, mc.preschedule = FALSE)
  M <- do.call(rbind, lapply(res, `[[`, "M"))
  R <- do.call(rbind, lapply(res, `[[`, "R"))
  for (tg in c("int","slp")) {
    tr <- if (tg == "int") TRUTH$sd_sigma_intercept else TRUTH$sd_sigma_x
    mb <- mean(M[, tg], na.rm = TRUE) - tr; rb <- mean(R[, tg], na.rm = TRUE) - tr
    d <- R[, tg] - M[, tg]
    cat(sprintf("%-8s %-3d %-5s %+8.4f %+8.4f %8.4f %8.4f %5d/%-3d %7d %7d\n",
      prov, g, tg, mb, rb, mean(M[,tg],na.rm=TRUE), mean(R[,tg],na.rm=TRUE),
      sum(d > 0, na.rm = TRUE), sum(!is.na(d)),
      sum(M[,"conv"] == 0, na.rm=TRUE), sum(R[,"conv"] == 0, na.rm=TRUE)))
  }
  out[[r]] <- list(prov = prov, g = g, M = M, R = R)
}
assignInNamespace("drm_validate_reml_spec", orig_validate, ns = "drmTMB")
saveRDS(list(out = out, N_SEEDS = N_SEEDS, TRUTH = TRUTH), "scratchpad/reml_provider_ladder_parallel.rds")
cat("\nwrote scratchpad/reml_provider_ladder_parallel.rds\n")
