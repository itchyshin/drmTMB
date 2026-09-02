# Slice A5 -- the #575 cross-engine objective diagnosis, re-runnable from R.
#
# Reproduces the by-hand manoeuvre from
# docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-01-matched-q4/
# warmstart_575.jl / 575-mechanism.md as a committed, pinned script: evaluate
# EACH engine's REML objective at BOTH engines' fitted points on the
# committed `biv-q4-phylo-reml` fixture, so #575's "is the Julia optimum
# worse, or is it a different objective?" question is answered by a receipt
# instead of a scratchpad.
#
# This is a DIAGNOSIS primitive -- it measures which engine's objective is
# better/worse at which point -- NOT a fix of #575, and it promotes nothing
# (no r_bridge_status change, no capability-ledger row change).
#
# --stable-only: fits the fixture with engine = "tmb" only (no Julia at all)
#   and checks the TMB REML logLik against expected.toml. Use this to verify
#   the native half of the receipt without a Julia install.
#
# (default) full mode: also fits engine = "julia" against the PINNED DRM.jl
#   clone (main @ e4647333, DRM.jl#589/#590 -- the exact-gradient #575 fix plus
#   the supported drm_bridge_objective_at entry point) and computes the 2x2
#   cross-engine
#   objective table. Requires DRM_JL_PATH (or options(drmTMB.DRM.jl.path=))
#   pointed at that exact pinned clone, and DRMTMB_JULIA_TESTS=true.
#
# `objective_at()` (R/objective-at.R, A3) evaluates the native TMB objective
# on the public start-label vocabulary ("fixef:<dpar>:<col>", "sd:<dpar>:
# <term>", "cor:<dpar>:<term>"). That vocabulary does not yet reach
# biv_gaussian's `rho12` fixed effect (its TMB start component carries no
# names) or the q4 phylo covariance block (`log_sd_phylo`/`theta_phylo`,
# which live outside `spec$random` entirely) -- confirmed empirically while
# building this receipt: both `objective_at(fit_tmb, at = list("fixef:rho12:
# (Intercept)" = ...))` and a `sd:mu:mu1:phylo(...)` label abort with "Unknown
# public start label" on this exact fixture. This is a real, separate gap in
# the A2/A3 public-start-label surface, not something this slice's OWNS
# (R/julia-bridge.R + this receipt) may silently patch. "TMB objective at
# TMB's own fitted point" therefore uses `-logLik(fit_tmb)` directly (which
# is definitionally what `objective_at()` would return at a fit's own
# optimum, and is verified as an exact anchor below); "TMB objective at
# Julia's point" reuses `objective_at()`'s OWN internal evaluation mechanism
# (`drm_pin_tmb_object_to_optimum()` + `obj$fn()`, re-pinned afterwards) with
# the internal TMB parameter names (`log_sd_phylo`, `theta_phylo`,
# `beta_rho12`) substituted directly, since the label translator cannot reach
# them yet for this model. See the after-task note for the request to the
# A2/A3 lane.

args <- commandArgs(trailingOnly = TRUE)
stable_only <- "--stable-only" %in% args

worktree <- "/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-drmTMB/7db7461b-e1ee-4ad0-a526-010c1c2e26a6/scratchpad/wt-a4"
suppressPackageStartupMessages({
  library(devtools)
  library(ape)
})
load_all(worktree, quiet = TRUE)

fixture <- "/Users/z3437171/Dropbox/Github Local/DRM.jl/test/parity/q4-reml/biv-q4-phylo-reml"
dat <- read.csv(file.path(fixture, "data.csv"), stringsAsFactors = FALSE)
tree <- read.tree(file.path(fixture, "tree.newick"))
dat$species <- factor(dat$species, levels = tree$tip.label)

form <- bf(
  mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
  mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
  sigma1 = ~ 1 + phylo(1 | p | species, tree = tree),
  sigma2 = ~ 1 + phylo(1 | p | species, tree = tree),
  rho12 = ~1
)

EXPECTED_TMB_LOGLIK <- -2.196139863046289e+02

fit_tmb <- drmTMB(
  form,
  family = biv_gaussian(),
  data = dat,
  engine = "tmb",
  REML = TRUE,
  control = drm_control(optimizer_preset = "robust", keep_tmb_object = TRUE)
)
tmb_loglik <- as.numeric(logLik(fit_tmb))
if (abs(tmb_loglik - EXPECTED_TMB_LOGLIK) >= 1e-6) {
  stop(sprintf(
    "A5 stable half FAILED: TMB REML logLik %.10f does not match expected.toml %.10f (|diff| = %g >= 1e-6).",
    tmb_loglik, EXPECTED_TMB_LOGLIK, abs(tmb_loglik - EXPECTED_TMB_LOGLIK)
  ))
}
cat(sprintf("TMB REML logLik = %.10f (matches expected.toml within 1e-6)\n", tmb_loglik))
cat("STABLE_HALF_OK\n")

if (stable_only) {
  quit(save = "no", status = 0)
}

# --- Full mode: DRM.jl pin check --------------------------------------------

drmjl_path <- Sys.getenv("DRM_JL_PATH", getOption("drmTMB.DRM.jl.path", ""))
if (!nzchar(drmjl_path)) {
  message("A5 REFUSED: DRM_JL_PATH is not set; point it at the pinned e4647333 clone.")
  quit(save = "no", status = 1)
}
DRMJL_PIN <- "e4647333"
drmjl_head <- tryCatch(
  system2("git", c("-C", drmjl_path, "rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE),
  error = function(e) NA_character_
)
if (length(drmjl_head) != 1L || !startsWith(drmjl_head, DRMJL_PIN)) {
  message(sprintf(
    "A5 REFUSED: DRM_JL_PATH (%s) is at %s, not the pinned %s. This receipt only runs against the pinned clone.",
    drmjl_path, paste(drmjl_head, collapse = " "), DRMJL_PIN
  ))
  quit(save = "no", status = 1)
}
drmtmb_ref <- tryCatch(
  system2("git", c("-C", worktree, "rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE),
  error = function(e) NA_character_
)

Sys.setenv(DRMTMB_JULIA_TESTS = "true")

fit_julia <- drmTMB(
  form,
  family = biv_gaussian(),
  data = dat,
  engine = "julia",
  REML = TRUE
)
julia_loglik <- as.numeric(logLik(fit_julia))

# --- Raw TMB-parameter-name objective evaluator (mirrors objective_at.drmTMB's
# own mechanism at R/objective-at.R -- pin to optimum, substitute, `obj$fn()`,
# re-pin -- addressed by internal TMB component name since the public
# fixef:/sd:/cor: label translator does not yet reach biv_gaussian's `rho12`
# or the q4 phylo covariance block for this model; see header note above).
tmb_objective_at_raw <- function(fit, log_sd_phylo, theta_phylo, beta_rho12) {
  full <- fit$opt$par
  par_names <- names(full)
  full[par_names == "log_sd_phylo"] <- log_sd_phylo
  full[par_names == "theta_phylo"] <- theta_phylo
  full[par_names == "beta_rho12"] <- beta_rho12
  drmTMB:::drm_pin_tmb_object_to_optimum(fit$obj, fit$opt, fit$tmb_state)
  raw <- unname(as.numeric(fit$obj$fn(full)))
  penalty_report <- fit$obj$report()$phylo_penalty
  penalty <- if (is.null(penalty_report)) 0 else as.numeric(penalty_report)
  value <- raw - penalty
  drmTMB:::drm_pin_tmb_object_to_optimum(fit$obj, fit$opt, fit$tmb_state)
  value
}

Lambda_tmb <- fit_tmb$obj$report()$phylo_q4_covariance
Lambda_julia <- drmTMB:::drm_julia_phylocov_matrix(fit_julia)

# TMB's own (log_sd_phylo, theta_phylo) at its own optimum, for the
# self-consistency anchor below.
log_sd_tmb_hat <- unname(fit_tmb$opt$par[names(fit_tmb$opt$par) == "log_sd_phylo"])
theta_tmb_hat <- unname(fit_tmb$opt$par[names(fit_tmb$opt$par) == "theta_phylo"])
rho12_tmb <- as.numeric(coef(fit_tmb)$rho12[["(Intercept)"]])

# Julia's Lambda -> TMB's (log_sd_phylo, theta_phylo) internal parameterisation
# (D. Lambda = D Corr D; theta_phylo is TMB's UNSTRUCTURED_CORR_t Cholesky
# parameterisation of Corr -- `correlation_matrix_to_tmb_unstructured_theta()`
# is its exact algebraic inverse, R/drmTMB.R).
sd_julia <- sqrt(diag(Lambda_julia))
corr_julia <- diag(1 / sd_julia) %*% Lambda_julia %*% diag(1 / sd_julia)
log_sd_julia <- log(sd_julia)
theta_julia <- drmTMB:::correlation_matrix_to_tmb_unstructured_theta(corr_julia)
rho12_julia <- as.numeric(fit_julia$coef_vector[["rho12_(Intercept)"]])

# --- (1) TMB objective at TMB's own point -----------------------------------
tmb_at_tmb <- -tmb_loglik

# --- (2) TMB objective at Julia's point -------------------------------------
tmb_at_julia <- tmb_objective_at_raw(
  fit_tmb,
  log_sd_phylo = log_sd_julia,
  theta_phylo = theta_julia,
  beta_rho12 = rho12_julia
)

# --- (3) Julia objective at Julia's own point (wrapper) ---------------------
beta_julia <- list(
  beta_mu1 = unname(fit_julia$coefficients$mu1),
  beta_mu2 = unname(fit_julia$coefficients$mu2),
  beta_sigma1 = unname(fit_julia$coefficients$sigma1),
  beta_sigma2 = unname(fit_julia$coefficients$sigma2)
)
julia_at_julia <- drmTMB:::drm_julia_reml_objective_at(
  fit_julia,
  beta = beta_julia,
  Lambda = Lambda_julia,
  rho12 = rho12_julia
)

# --- (4) Julia objective at TMB's point (wrapper) ---------------------------
beta_tmb <- list(
  beta_mu1 = unname(coef(fit_tmb)$mu1),
  beta_mu2 = unname(coef(fit_tmb)$mu2),
  beta_sigma1 = unname(coef(fit_tmb)$sigma1),
  beta_sigma2 = unname(coef(fit_tmb)$sigma2)
)
julia_at_tmb <- drmTMB:::drm_julia_reml_objective_at(
  fit_julia,
  beta = beta_tmb,
  Lambda = Lambda_tmb,
  rho12 = rho12_tmb
)

# --- Anchors and cross-term finiteness --------------------------------------

ANCHOR_TOL <- 2e-4
anchor_tmb_diff <- abs(tmb_at_tmb - (-tmb_loglik))
anchor_julia_diff <- abs(julia_at_julia$reml_loglik - julia_loglik)

stopifnot(
  "TMB self-consistency anchor failed" = anchor_tmb_diff < ANCHOR_TOL,
  "Julia self-consistency anchor failed" = anchor_julia_diff < ANCHOR_TOL,
  "TMB-at-Julia is not finite" = is.finite(tmb_at_julia),
  "Julia-at-TMB is not finite" = is.finite(julia_at_tmb$reml_loglik)
)

tab <- data.frame(
  evaluated_at = c("TMB's point", "Julia's point"),
  tmb_objective = c(-tmb_at_tmb, -tmb_at_julia),
  julia_reml_loglik = c(julia_at_tmb$reml_loglik, julia_at_julia$reml_loglik)
)
cat("\n2x2 cross-engine objective table (all on the -logLik/reml_loglik reporting convention; the two TMB columns are -objective so bigger = better fit, matching reml_loglik's sign):\n")
print(tab)
cat(sprintf(
  "\nTMB anchor  |TMB@TMB - (-logLik(TMB))|  = %.3e (< %.0e)\n",
  anchor_tmb_diff, ANCHOR_TOL
))
cat(sprintf(
  "Julia anchor |Julia@Julia - own reml_loglik| = %.3e (< %.0e)\n",
  anchor_julia_diff, ANCHOR_TOL
))
cat(sprintf(
  "\nTMB objective at TMB's point (== -logLik(fit_tmb))      : %.6f\n", -tmb_at_tmb
))
cat(sprintf(
  "TMB objective at Julia's point                          : %.6f\n", -tmb_at_julia
))
cat(sprintf(
  "Julia reml_loglik at Julia's own point (wrapper)         : %.6f\n", julia_at_julia$reml_loglik
))
cat(sprintf(
  "Julia reml_loglik at TMB's point (wrapper)                : %.6f\n", julia_at_tmb$reml_loglik
))

drmjl_ref_full <- paste(drmjl_head, collapse = "")
receipt_meta <- list(
  drmjl_ref = drmjl_ref_full,
  drmtmb_ref = paste(drmtmb_ref, collapse = ""),
  table = tab,
  anchor_tmb_diff = anchor_tmb_diff,
  anchor_julia_diff = anchor_julia_diff
)
saveRDS(
  receipt_meta,
  file.path(dirname(worktree), "a5-cross-engine-receipt-out.rds")
)
cat(sprintf("\ndrmjl_ref: %s\n", drmjl_ref_full))
cat(sprintf("drmtmb_ref: %s\n", receipt_meta$drmtmb_ref))

cat("\n575 CROSS-ENGINE OK\n")
