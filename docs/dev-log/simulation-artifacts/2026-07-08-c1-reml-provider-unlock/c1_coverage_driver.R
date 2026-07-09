# C1 inference_ready coverage: REML profile-CI coverage of the scale-side
# intercept SD for spatial/animal/relmat, per provider x g. Truth = 0.50.
# Bypasses the provider gate (evidence generation). Parallel over seeds.
#   OPENBLAS_NUM_THREADS=1 N_SEEDS=150 NCORES=64 Rscript --no-init-file <this>
suppressMessages(devtools::load_all(".", quiet = TRUE))
suppressMessages(library(parallel))

N_SEEDS <- as.integer(Sys.getenv("N_SEEDS", "150"))
NCORES  <- as.integer(Sys.getenv("NCORES", "64"))
N_EACH  <- 20L
SD_INT  <- 0.50   # truth for sd_sigma_intercept (the certification target)
TRUTH <- list(mu_intercept = .40, mu_x = .25, log_sigma_intercept = -.90,
              sd_sigma_intercept = SD_INT, sd_sigma_x = .38)

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
build_form <- function(provider, sim) {
  switch(provider,
    spatial = { coords <- sim$coords; bf(y ~ x, sigma ~ spatial(1 + x | site, coords = coords)) },
    relmat  = { K <- sim$K;           bf(y ~ x, sigma ~ relmat(1 + x | id, K = K)) },
    animal  = { A <- sim$K;           bf(y ~ x, sigma ~ animal(1 + x | id, A = A)) })
}
int_parm <- function(provider) sprintf("sd:sigma:%s(1 | %s)",
  provider, if (provider == "spatial") "site" else "id")

cover_one <- function(provider, g, seed) {
  sim <- make_data(provider, g, seed)
  fit <- tryCatch(drmTMB(build_form(provider, sim), family = gaussian(), data = sim$data,
                         REML = TRUE, control = drm_control(optimizer = list(eval.max = 1400, iter.max = 1400))),
                  error = function(e) e)
  if (inherits(fit, "error")) return(c(conv = NA, cov = NA, lo = NA, hi = NA, wid = NA))
  parm <- int_parm(provider)
  ci <- tryCatch(withCallingHandlers(
    stats::confint(fit, parm = parm, method = "profile", level = 0.95,
                   profile_engine = "tmbprofile", trace = FALSE),
    warning = function(w) invokeRestart("muffleWarning")), error = function(e) e)
  if (inherits(ci, "error")) return(c(conv = fit$opt$convergence, cov = NA, lo = NA, hi = NA, wid = NA))
  lo <- suppressWarnings(as.numeric(ci$lower[[1]])); hi <- suppressWarnings(as.numeric(ci$upper[[1]]))
  fin <- is.finite(lo) && is.finite(hi)
  c(conv = fit$opt$convergence,
    cov = if (fin) as.numeric(SD_INT >= lo && SD_INT <= hi) else NA,
    lo = lo, hi = hi, wid = if (fin) hi - lo else NA)
}

orig_validate <- drmTMB:::drm_validate_reml_spec
assignInNamespace("drm_validate_reml_spec", function(spec) invisible(TRUE), ns = "drmTMB")

cells <- rbind(
  expand.grid(provider = "spatial", g = c(8L, 16L, 32L), stringsAsFactors = FALSE),
  expand.grid(provider = "relmat",  g = c(8L, 16L, 32L), stringsAsFactors = FALSE),
  expand.grid(provider = "animal",  g = 8L,              stringsAsFactors = FALSE)
)
cat(sprintf("C1 REML profile coverage  N_SEEDS=%d NCORES=%d  target=sd_sigma_intercept truth=%.2f\n",
            N_SEEDS, NCORES, SD_INT))
cat(sprintf("%-8s %-3s %8s %8s %8s %9s %8s\n","provider","g","coverage","n_fin","conv","MCSE","med_wid"))
cat(strrep("-", 62), "\n")
out <- list()
for (r in seq_len(nrow(cells))) {
  prov <- cells$provider[r]; g <- cells$g[r]
  M <- do.call(rbind, mclapply(seq_len(N_SEEDS), function(s)
    cover_one(prov, g, 930000L + 1000L * r + s), mc.cores = NCORES, mc.preschedule = FALSE))
  cov <- M[, "cov"]; nfin <- sum(!is.na(cov)); ch <- mean(cov, na.rm = TRUE)
  mcse <- sqrt(ch * (1 - ch) / max(nfin, 1))
  cat(sprintf("%-8s %-3d %8.3f %8d %8d %9.4f %8.3f\n", prov, g, ch, nfin,
              sum(M[,"conv"] == 0, na.rm = TRUE), mcse, median(M[,"wid"], na.rm = TRUE)))
  out[[r]] <- list(prov = prov, g = g, M = M)
}
assignInNamespace("drm_validate_reml_spec", orig_validate, ns = "drmTMB")
saveRDS(list(out = out, N_SEEDS = N_SEEDS, SD_INT = SD_INT), "scratchpad/c1_coverage.rds")
cat("\nwrote scratchpad/c1_coverage.rds\n")
