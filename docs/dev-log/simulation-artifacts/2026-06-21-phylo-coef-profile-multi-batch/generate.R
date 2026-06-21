# Bank the multi-coef profile-batch parity artifact (drmTMB#179 Stage A multi-coef).
# Runs the batched bridge profile call vs native per-coefficient tmbprofile across a
# seed x n_tip grid and writes the per-cell endpoints + deltas to parity.tsv.
pkg <- "/Users/z3437171/.codex/worktrees/540b/drmTMB"
jl <- "/Users/z3437171/.codex/worktrees/540b/DRM.jl-direct-main"
suppressMessages(pkgload::load_all(pkg, quiet = TRUE))
options(drmTMB.DRM.jl.path = jl)

n_tips <- c(40L, 80L)
seeds <- c(42L, 7L, 13L, 101L)
coefs <- c("mu:(Intercept)", "mu:x")
rows <- list()
for (n_tip in n_tips) for (seed in seeds) {
  set.seed(seed)
  tree <- ape::rcoal(n_tip)
  sp <- tree$tip.label
  x <- stats::rnorm(n_tip)
  bm <- ape::rTraitCont(tree, model = "BM", sigma = 0.6)
  y <- 0.5 + 0.4 * x + bm[sp] + stats::rnorm(n_tip, 0, 0.5)
  dat <- data.frame(species = sp, x = x, y = y, stringsAsFactors = FALSE)
  form <- drmTMB::bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)
  ft <- drmTMB::drmTMB(form, family = stats::gaussian(), data = dat)
  fj <- drmTMB::drmTMB(form, family = stats::gaussian(), data = dat, engine = "julia")
  ll_t <- tryCatch(as.numeric(stats::logLik(ft)), error = function(e) NA_real_)
  ll_j <- tryCatch(as.numeric(stats::logLik(fj)), error = function(e) NA_real_)
  fit_agree <- is.finite(ll_t) && is.finite(ll_j) && abs(ll_t - ll_j) < 1e-2
  jci <- tryCatch(
    suppressWarnings(stats::confint(fj, parm = coefs, method = "profile")),
    error = function(e) NULL
  )
  jn <- if (is.null(jci)) 0L else nrow(jci)
  for (p in coefs) {
    tci <- tryCatch(
      suppressWarnings(stats::confint(ft, parm = p, method = "profile")),
      error = function(e) NULL
    )
    jrow <- if (!is.null(jci)) {
      jci[as.character(jci$parm) == paste0("fixef:", p), , drop = FALSE]
    } else {
      NULL
    }
    hr <- !is.null(tci) && !is.null(jrow) && nrow(jrow) == 1L
    rows[[length(rows) + 1L]] <- data.frame(
      n_tip = n_tip, seed = seed, coef = p, good_fit = fit_agree && hr,
      ll_native = ll_t, ll_julia = ll_j, j_nrow = jn,
      t_lower = if (!is.null(tci)) tci$lower else NA_real_,
      t_upper = if (!is.null(tci)) tci$upper else NA_real_,
      j_lower = if (hr) jrow$lower else NA_real_,
      j_upper = if (hr) jrow$upper else NA_real_,
      stringsAsFactors = FALSE
    )
  }
}
res <- do.call(rbind, rows)
res$d_lower <- abs(res$t_lower - res$j_lower)
res$d_upper <- abs(res$t_upper - res$j_upper)
outdir <- file.path(
  pkg, "docs", "dev-log", "simulation-artifacts",
  "2026-06-21-phylo-coef-profile-multi-batch"
)
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
utils::write.table(
  res, file.path(outdir, "parity.tsv"),
  sep = "\t", quote = FALSE, row.names = FALSE, na = "NA"
)
good <- res[res$good_fit, ]
cat("cells total:", nrow(res), " good:", nrow(good), "\n")
cat(
  "max |dlower|,|dupper| on good cells:",
  formatC(max(c(good$d_lower, good$d_upper)), format = "e", digits = 3), "\n"
)
cat("all good j_nrow == 2:", all(good$j_nrow == 2L), "\n")
cat("ARTIFACT_DONE ->", file.path(outdir, "parity.tsv"), "\n")
