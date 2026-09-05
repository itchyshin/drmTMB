## Bridge (engine="julia") REML probe for the A9f route table.
## ONE warm Julia session covers every NEW cell below (D-139: estimate ~3-5 min
## total: ~20-30s boot + ~10 cells at a few seconds each).
suppressMessages(devtools::load_all("/Users/z3437171/local-scratch/parity-joint/wt-a9f-reml-table", quiet = TRUE))
suppressMessages(library(ape))
`%||%` <- function(a, b) if (is.null(a) || (length(a) == 1 && is.na(a))) b else a

probe <- function(label, expr) {
  t0 <- Sys.time()
  # The fit call itself is the only thing allowed to turn into a REFUSES row
  # (drmTMB's own gate declining the request). Reading the oracle fields off a
  # SUCCESSFUL fit is deliberately kept OUTSIDE this tryCatch: a NULL there
  # means a field was renamed, and that must halt the script, not silently
  # relabel a FITS cell as if the model had refused.
  fit_result <- tryCatch(
    list(ok = TRUE, fit = force(expr)),
    error = function(e) list(ok = FALSE, message = conditionMessage(e))
  )
  secs <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  if (fit_result$ok) {
    fit <- fit_result$fit
    # THE ORACLE (DRM.jl #625): `fit$bridge` is the raw list DRM.jl itself
    # returned, and `estim_method` is the engine's own unconditional report of
    # which estimator actually ran -- not drmTMB's belief about it. The
    # R-side belief is `fit$estimator` / `fit$effective_REML` (see
    # R/julia-bridge.R's "THE ENGINE IS THE AUTHORITY" comment). A drmTMB
    # Julia fit object has no top-level `fit$estim_method` field; reading
    # that (as this probe used to) silently returns NULL every time.
    engine_estim_method <- fit$bridge$estim_method
    if (is.null(engine_estim_method)) {
      stop(sprintf(
        "probe '%s': fit$bridge$estim_method is NULL -- the DRM.jl estim_method oracle field (DRM.jl #625) is missing or has been renamed on this fit object.",
        label
      ))
    }
    r_estimator <- fit$estimator
    if (is.null(r_estimator)) {
      stop(sprintf(
        "probe '%s': fit$estimator is NULL -- the R-side estimator-belief field has been renamed on this fit object.",
        label
      ))
    }
    r_effective_REML <- fit$effective_REML
    if (is.null(r_effective_REML)) {
      stop(sprintf(
        "probe '%s': fit$effective_REML is NULL -- the R-side effective_REML-belief field has been renamed on this fit object.",
        label
      ))
    }
    res <- list(label = label, outcome = "FITS",
                estim_method = as.character(engine_estim_method)[1L],
                estimator = as.character(r_estimator)[1L],
                effective_REML = isTRUE(r_effective_REML),
                message = NA_character_)
  } else {
    res <- list(label = label, outcome = "REFUSES",
                estim_method = NA_character_, estimator = NA_character_,
                effective_REML = NA, message = fit_result$message)
  }
  cat(sprintf("== %s (%.1fs) ==\n outcome=%s estim_method=%s estimator=%s effective_REML=%s\n message=%s\n\n",
              label, secs, res$outcome, res$estim_method, res$estimator, res$effective_REML,
              gsub("\n", " | ", res$message %||% "")))
  res
}

set.seed(1)
n <- 60
x <- rnorm(n)
y <- 0.5 + 0.8 * x + rnorm(n, sd = 0.6)
g <- factor(rep(1:12, length.out = n))
d_base <- data.frame(y = y, x = x, g = g)

t_start <- Sys.time()

## 1. base_gaussian_location_scale (fixed-effect Gaussian) -- expect FITS.
probe("base_gaussian_location_scale, REML=TRUE (bridge)",
  drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = d_base, REML = TRUE, engine = "julia")
)

## 2. biv_gaussian_residual (fixed-effect bivariate, no phylo/structure) -- expect REFUSES.
y1 <- 0.4 + 0.6 * x + rnorm(n, sd = 0.5)
y2 <- -0.2 + 0.3 * x + 0.4 * y1 + rnorm(n, sd = 0.5)
d_biv <- data.frame(y1 = y1, y2 = y2, x = x)
probe("biv_gaussian_residual, REML=TRUE (bridge)",
  drmTMB(bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
         family = biv_gaussian(), data = d_biv, REML = TRUE, engine = "julia")
)

## 3. gaussian_phylo_mean (mean-only phylo, sigma~1) -- expect REFUSES.
tree <- ape::rcoal(20); tree$tip.label <- paste0("sp_", seq_len(20))
Aphy <- ape::vcv(tree, corr = TRUE)
sp <- factor(tree$tip.label, levels = tree$tip.label)
u <- as.vector(t(chol(Aphy)) %*% rnorm(20)) * 0.5
xp <- rnorm(20)
yp <- 0.3 + 0.5 * xp + u + rnorm(20, sd = 0.4)
d_phylo <- data.frame(y = yp, x = xp, species = sp)
probe("gaussian_phylo_mean (mean-only phylo, sigma~1), REML=TRUE (bridge)",
  drmTMB(bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
         family = gaussian(), data = d_phylo, REML = TRUE, engine = "julia")
)

## 3b. gaussian_response_mask: same cell, response="include" with one NA response row.
d_phylo_mask <- d_phylo
d_phylo_mask$y[3] <- NA
probe("gaussian_response_mask (phylo mean, response='include'), REML=TRUE (bridge)",
  drmTMB(bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
         family = gaussian(), data = d_phylo_mask, REML = TRUE, engine = "julia",
         missing = miss_control(response = "include"))
)

## 4. phylo_count_large_p: poisson + phylo(1|species) mean intercept -- re-verify at
## OUR pin (430ef64cc); earlier citation (R/julia-bridge.R comment) is at pin e0a65f96b.
yc <- rpois(20, exp(0.3 + 0.2 * xp))
d_phylo_c <- data.frame(y = yc, x = xp, species = sp)
probe("phylo_count_large_p: poisson + phylo(1|species), REML=TRUE (bridge, re-verify at 430ef64cc)",
  drmTMB(bf(y ~ x + phylo(1 | species, tree = tree)),
         family = poisson(), data = d_phylo_c, REML = TRUE, engine = "julia")
)

## 5. fe_poisson: fixed-effect ONLY Poisson, zero random effects -- NOVEL edge case:
## the R-side poisson_reml gate does not check for random-effect presence at all.
ypo <- rpois(n, exp(0.2 + 0.1 * x))
d_pois <- data.frame(y = ypo, x = x)
probe("fe_poisson (fixed-effect only, zero RE), REML=TRUE (bridge)",
  drmTMB(bf(y ~ x), family = poisson(), data = d_pois, REML = TRUE, engine = "julia")
)
probe("fe_poisson (fixed-effect only, zero RE), REML=FALSE (bridge, for ml_loglik reference)",
  drmTMB(bf(y ~ x), family = poisson(), data = d_pois, REML = FALSE, engine = "julia")
)

## 6. zi_poisson: fixed-effect only + zi ~ x, zero mu RE -- same edge case with a zi component.
zi_p <- plogis(-0.5 + 0.2 * x)
y_zip <- ifelse(runif(n) < zi_p, 0L, rpois(n, exp(0.3 + 0.1 * x)))
d_zip <- data.frame(y = y_zip, x = x)
probe("zi_poisson (fixed-effect only, zero RE), REML=TRUE (bridge)",
  drmTMB(bf(y ~ x, zi ~ x), family = poisson(), data = d_zip, REML = TRUE, engine = "julia")
)

## 7. general_covariance_structured: Gaussian relmat(1|g,K=K), sigma~1 -- expect REFUSES.
K <- diag(12) * 0.7 + 0.3
rownames(K) <- colnames(K) <- levels(g)
probe("general_covariance_structured Gaussian relmat(1|g,K=K), REML=TRUE (bridge)",
  drmTMB(bf(y ~ x + relmat(1 | g, K = K), sigma ~ 1),
         family = gaussian(), data = d_base, REML = TRUE, engine = "julia")
)

## 8. plain_binomial_nonphylo: fixed-effect only, cbind trials, no RE -- expect REFUSES.
succ <- rbinom(n, 10, plogis(0.2 + 0.3 * x)); fail <- 10 - succ
d_bin <- data.frame(succ = succ, fail = fail, x = x)
probe("plain_binomial_nonphylo (fixed-effect only cbind trials), REML=TRUE (bridge)",
  drmTMB(bf(cbind(succ, fail) ~ x), family = stats::binomial(), data = d_bin, REML = TRUE, engine = "julia")
)

## 9. cross_family_latent: c(gaussian(), poisson()) -- expect REFUSES ("cross-family").
d_xfam <- data.frame(y1g = y1, y2c = rpois(n, exp(0.2 + 0.1 * x)), x = x)
probe("cross_family_latent c(gaussian(),poisson()), REML=TRUE (bridge)",
  drmTMB(bf(mu1 = y1g ~ x, mu2 = y2c ~ x), family = c(gaussian(), poisson()),
         data = d_xfam, REML = TRUE, engine = "julia")
)

cat(sprintf("TOTAL WALL TIME: %.1fs\n", as.numeric(difftime(Sys.time(), t_start, units = "secs"))))
cat("ALL BRIDGE PROBES DONE\n")
