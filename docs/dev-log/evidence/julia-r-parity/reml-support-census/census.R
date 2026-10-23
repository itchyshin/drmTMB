# REML support census for the DRM.jl bridge (arc f4, gate f4-G1).
# Measures which cells DRM.jl actually fits by restricted maximum likelihood,
# rather than trusting drm_julia_reml_supported()'s prior.
#
# Usage: Rscript census.R <batch>   where <batch> is 1, 2 or 3.

suppressMessages(devtools::load_all(".", quiet = TRUE))

args <- commandArgs(trailingOnly = TRUE)
batch <- if (length(args) >= 1L) as.integer(args[[1]]) else 1L
outdir <- Sys.getenv("CENSUS_OUT")

# ---------------------------------------------------------------------------
# Force the gate OPEN for the duration of the census. The point of the census
# is to measure the ENGINE, not our current belief about it: with the shipped
# gate in place the bridge would send method = "ML" for every cell it already
# disbelieves, and the census would only ever re-read its own prior back.
# ---------------------------------------------------------------------------
ns <- asNamespace("drmTMB")
unlockBinding("drm_julia_reml_supported", ns)
assign("drm_julia_reml_supported", function(formula, family_type) TRUE, envir = ns)

# ---------------------------------------------------------------------------
# THE ORACLE, behind a flag.
#
# oracle = "two-fit" (today): fit the cell twice, REML requested then ML, and
#   compare the two log-likelihoods. The two fits are INDEPENDENT optimiser
#   runs, so the comparison carries convergence noise of order 1e-5 (measured
#   in arc f3: nlminb moved 1.05e-5 under a tightened tolerance; the #1130
#   cross-engine gap was 1.086e-5). A genuine restriction is orders of
#   magnitude larger -- the DRM.jl lane's worked case is -172.747 against
#   -164.009, about 8.7 log-likelihood units. Hence tol = 1e-3, which sits
#   safely between noise and signal.
#
# oracle = "single-fit" (unavailable until DRM.jl #625): read `reml_loglik`
#   and `ml_loglik` from ONE fit object at ONE optimum, which removes the
#   optimiser-noise term entirely and makes the tolerance question moot. The
#   swap is deliberately confined to this one function.
# ---------------------------------------------------------------------------
census_classify <- function(reml_arm, ml_arm, oracle = "two-fit", tol = 1e-3) {
  if (!identical(oracle, "two-fit")) {
    stop("oracle '", oracle, "' requires DRM.jl #625 (estim_method, ml_loglik, ",
         "reml_loglik, infocrit_basis on a single fit object); not available ",
         "at the pinned ref.")
  }
  if (!isTRUE(reml_arm$ok)) {
    return(list(verdict = "REFUSED", detail = reml_arm$error))
  }
  if (!isTRUE(ml_arm$ok)) {
    return(list(verdict = "REFUSED", detail = paste("ML arm failed:", ml_arm$error)))
  }
  # A route that hard-codes `effective_REML = FALSE` never sends method = "REML"
  # to DRM.jl at all, so its two arms are the SAME fit by construction. Comparing
  # their log-likelihoods would measure nothing; the verdict is settled by the
  # route, not by the numbers, and no oracle is run.
  if (!isTRUE(reml_arm$effective_REML)) {
    return(list(
      verdict = "REFUSED",
      detail = "bridge route never sends method = REML (effective_REML is FALSE)"
    ))
  }
  d <- abs(reml_arm$loglik - ml_arm$loglik)
  if (!is.finite(d)) {
    return(list(verdict = "REFUSED", detail = "non-finite log-likelihood"))
  }
  if (d >= tol) {
    return(list(verdict = "RESTRICTED", detail = sprintf("abs diff %.10g", d)))
  }
  list(verdict = "UNDETERMINED", detail = sprintf("abs diff %.10g", d))
}

fit_arm <- function(f, fam, dat, reml) {
  t0 <- Sys.time()
  out <- tryCatch(
    {
      fit <- suppressWarnings(drmTMB(
        f, family = fam, data = dat, engine = "julia", REML = reml
      ))
      list(
        ok = TRUE,
        loglik = as.numeric(stats::logLik(fit)),
        effective_REML = isTRUE(fit$effective_REML),
        error = NA_character_
      )
    },
    error = function(e) list(
      ok = FALSE, loglik = NA_real_, effective_REML = NA,
      error = gsub("[\r\n]+", " ", conditionMessage(e))
    )
  )
  out$secs <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  out
}

run_cell <- function(cell) {
  cat("[cell]", cell$name, "... ")
  utils::flush.console()
  if (isTRUE(cell$skip)) {
    cat("SKIPPED (", cell$note, ")\n", sep = "")
    return(data.frame(
      cell = cell$name, verdict = cell$skip_verdict, ll_reml = NA_real_,
      ll_ml = NA_real_, detail = cell$note, stringsAsFactors = FALSE
    ))
  }
  a <- fit_arm(cell$formula, cell$family, cell$data, TRUE)
  b <- fit_arm(cell$formula, cell$family, cell$data, FALSE)
  cls <- census_classify(a, b)
  verdict <- cls$verdict
  if (!is.null(cell$affected_620) && isTRUE(cell$affected_620)) {
    verdict <- paste0("#620-AFFECTED (raw ", verdict, ")")
  }
  cat(verdict, "\n")
  data.frame(
    cell = cell$name, verdict = verdict,
    ll_reml = a$loglik, ll_ml = b$loglik,
    detail = cls$detail, stringsAsFactors = FALSE
  )
}

# ---------------------------------------------------------------------------
# Data
# ---------------------------------------------------------------------------
set.seed(20260903)
n <- 150
plain <- data.frame(x = rnorm(n), z = rnorm(n))
plain$g <- factor(rep(seq_len(15), each = 10))
plain$g2 <- factor(rep(seq_len(10), times = 15))
plain$y <- 1 + 0.5 * plain$x + rnorm(15, sd = 0.6)[plain$g] +
  rnorm(n, sd = exp(0.2 + 0.3 * plain$x))
plain$ycount <- rpois(n, exp(0.8 + 0.3 * plain$x + rnorm(15, sd = 0.4)[plain$g]))
plain$ypos <- rgamma(n, shape = 3, rate = 3 / exp(0.5 + 0.2 * plain$x))

set.seed(20260904)
tree <- ape::rcoal(30)
sp <- tree$tip.label
phy <- data.frame(
  species = rep(sp, each = 3),
  x = rnorm(90), z = rnorm(90), stringsAsFactors = FALSE
)
sp_eff <- setNames(rnorm(30, sd = 0.7), sp)
phy$y <- 1 + 0.5 * phy$x + sp_eff[phy$species] + rnorm(90, sd = 0.5)
phy$y1 <- phy$y
phy$y2 <- 0.5 + 0.4 * phy$x + 0.6 * sp_eff[phy$species] + rnorm(90, sd = 0.5)
phy$ycount <- rpois(90, exp(0.6 + 0.3 * phy$x + sp_eff[phy$species]))
phy$ypos <- rgamma(90, shape = 3, rate = 3 / exp(0.4 + 0.2 * phy$x))

relmat_dat <- plain
relmat_dat$id <- factor(seq_len(n))
K <- diag(n)
dimnames(K) <- list(levels(relmat_dat$id), levels(relmat_dat$id))

meta_dat <- data.frame(x = rnorm(60))
meta_dat$y <- 1 + 0.5 * meta_dat$x + rnorm(60, sd = 0.5)
Vknown <- runif(60, 0.05, 0.2)

# ---------------------------------------------------------------------------
# Cells
# ---------------------------------------------------------------------------
cells <- list(
  # --- batch 1: the Gaussian core the current gate already claims ---
  list(batch = 1, name = "gaussian_fixed_locscale",
       formula = bf(y ~ x, sigma ~ x), family = gaussian(), data = plain),
  list(batch = 1, name = "gaussian_random_intercept",
       formula = bf(y ~ x + (1 | g)), family = gaussian(), data = plain),
  list(batch = 1, name = "gaussian_mean_only_phylo_no_sd",
       formula = bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
       family = gaussian(), data = phy),
  list(batch = 1, name = "gaussian_sigma_phylo_locscale",
       formula = bf(y ~ x + phylo(1 | species, tree = tree),
                    sigma ~ phylo(1 | species, tree = tree)),
       family = gaussian(), data = phy),

  # --- batch 2: location-scale-scale routes ---
  list(batch = 2, name = "lss_sd_group_dense",
       formula = bf(y ~ x + (1 | g), sigma ~ x, sd(g) ~ z),
       family = gaussian(), data = plain),
  list(batch = 2, name = "lss_sd_phylo_dense",
       formula = bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ x,
                    sd(species, level = "phylogenetic") ~ z),
       family = gaussian(), data = phy),
  list(batch = 2, name = "lss_multi_component_dense",
       formula = bf(y ~ x + (1 | g) + (1 | g2), sigma ~ x,
                    sd(g) ~ z, sd(g2) ~ z),
       family = gaussian(), data = plain),
  list(batch = 2, name = "lss_multi_component_SPARSE",
       skip = TRUE, skip_verdict = "EXPECTED-ABSENT",
       note = paste("sparse multi-component location-scale-scale route",
                    "(DRM.jl lane census row 9) landed AFTER our pin 77513aa0",
                    "and cannot exist here; not a disagreement")),

  # --- batch 3: bivariate, counts, expected refusals, #620 ---
  list(batch = 3, name = "biv_q2_structured_phylo",
       formula = bf(mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
                    mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
                    sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
       family = biv_gaussian(), data = phy),
  list(batch = 3, name = "biv_q4_phylo",
       formula = bf(mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
                    mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
                    sigma1 = ~ 1 + phylo(1 | p | species, tree = tree),
                    sigma2 = ~ 1 + phylo(1 | p | species, tree = tree),
                    rho12 = ~1),
       family = biv_gaussian(), data = phy),
  list(batch = 3, name = "poisson_random_intercept",
       formula = bf(ycount ~ x + (1 | g)), family = poisson(), data = plain),
  list(batch = 3, name = "poisson_phylo_intercept",
       formula = bf(ycount ~ x + phylo(1 | species, tree = tree)),
       family = poisson(), data = phy),
  list(batch = 3, name = "gaussian_random_slopes",
       formula = bf(y ~ x + (1 + x | g)), family = gaussian(), data = plain),
  list(batch = 3, name = "gaussian_meta_V",
       formula = bf(y ~ x + meta_V(V = Vknown)), family = gaussian(),
       data = meta_dat),
  list(batch = 3, name = "biv_residual_only",
       formula = bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~x, sigma2 = ~x,
                    rho12 = ~1),
       family = biv_gaussian(), data = phy),
  list(batch = 3, name = "gamma_fixed_no_ranef",
       formula = bf(ypos ~ x, sigma ~ 1), family = Gamma(link = "log"),
       data = plain),
  # #620-affected: a structured marker with a NON-INTERCEPT left side silently
  # fits the INTERCEPT-ONLY model at our pin instead of throwing.
  list(batch = 3, name = "relmat_slope_620",
       formula = bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1),
       family = gaussian(), data = relmat_dat, affected_620 = TRUE),
  list(batch = 3, name = "gamma_phylo_slope_620",
       formula = bf(ypos ~ x + phylo(1 + x | species, tree = tree)),
       family = Gamma(link = "log"), data = phy, affected_620 = TRUE)
)

sel <- Filter(function(cc) isTRUE(as.integer(cc$batch) == batch), cells)
res <- do.call(rbind, lapply(sel, run_cell))
stopifnot(nzchar(outdir))
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)
utils::write.csv(res, file.path(outdir, sprintf("batch%d.csv", batch)), row.names = FALSE)
print(res)
