# G0 oracle: independent checks of the MSPL link-general kernels in R/mspl.R
# against base R glm() (IRLS working weights, expected/Fisher information) and
# brglm2 (Jeffreys-penalised / mean-bias-reducing binomial GLM fits).
#
# Slice S1 of the mspl-nonlogit-evidence campaign. Read-only w.r.t. R/mspl.R:
# this script sources it unmodified and only compares its outputs against
# independently built quantities.
#
# Run with: Rscript --no-init-file G0-oracle.R
# (from the repo root, or with working directory set to the repo root)

# Locate R/mspl.R relative to this script's known location in the worktree.
mspl_path <- "/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-drmTMB/e7414ec0-b299-4340-8cf1-7d90db6c2056/scratchpad/wt-omega/R/mspl.R"
stopifnot(file.exists(mspl_path))
source(mspl_path)

stopifnot(requireNamespace("brglm2", quietly = TRUE))

SEED <- 20260811L
set.seed(SEED)

links <- c("logit", "probit", "cloglog")

inv_link_base <- function(eta, link) {
  switch(
    link,
    logit = plogis(eta),
    probit = pnorm(eta),
    cloglog = -expm1(-exp(eta))
  )
}

# ---------------------------------------------------------------------------
# Design generator: continuous covariate (+ factor for p = 4 designs).
# Coefficients are kept moderate so mu stays away from {0,1} for the bulk of
# rows -> non-separated binomial data for every link.
# ---------------------------------------------------------------------------
make_design <- function(n, p, seed) {
  set.seed(seed)
  x <- rnorm(n, 0, 1)
  if (p == 2L) {
    X <- cbind(`(Intercept)` = 1, x = x)
    beta_true <- c(0.2, 0.6)
    df <- data.frame(x = x)
    formula_rhs <- "~ x"
  } else if (p == 4L) {
    f <- factor(sample(c("a", "b", "c"), n, replace = TRUE))
    X <- model.matrix(~ x + f)
    beta_true <- c(0.2, 0.6, 0.4, -0.3)
    df <- data.frame(x = x, f = f)
    formula_rhs <- "~ x + f"
  } else {
    stop("p must be 2 or 4")
  }
  trials <- sample(10:30, n, replace = TRUE)
  list(X = X, beta_true = beta_true, df = df, trials = trials, formula_rhs = formula_rhs)
}

designs <- list(
  D1 = make_design(n = 60, p = 2L, seed = SEED + 1L),
  D2 = make_design(n = 200L, p = 4L, seed = SEED + 2L),
  D3 = make_design(n = 1000L, p = 4L, seed = SEED + 3L)
)

simulate_response <- function(design, link, seed) {
  set.seed(seed)
  eta <- drop(design$X %*% design$beta_true)
  mu <- inv_link_base(eta, link)
  y <- rbinom(length(mu), design$trials, mu)
  list(y = y, eta_true = eta, mu_true = mu)
}

# ---------------------------------------------------------------------------
# (A) Weight parity: glm()'s IRLS working weights vs exp(mspl_log_weight())
#     evaluated at the SAME eta = glm_fit$linear.predictors.
#
# glm()'s returned $weights are the working weights from the LAST IRLS
# iteration, evaluated at the eta from that iteration; under default
# glm.control() (epsilon = 1e-8, on the deviance, not on eta) this eta is not
# bit-identical to the reported $linear.predictors and both differ from the
# true MLE by a small amount. We therefore report BOTH the default-tolerance
# fit ("loose") and a fit tightened to epsilon = 1e-15/maxit = 200 ("tight")
# to show the residual deviation shrinks toward machine precision as glm's
# own convergence tightens -- i.e. it is glm's tolerance, not a kernel defect.
# "tight" is the primary comparison.
# ---------------------------------------------------------------------------
check_A <- function(design, link, seed) {
  sim <- simulate_response(design, link, seed)
  df <- design$df
  df$y <- sim$y
  df$trials <- design$trials
  fml <- as.formula(paste0("cbind(y, trials - y) ", design$formula_rhs))
  fit_loose <- glm(fml, data = df, family = binomial(link = link))
  fit_tight <- glm(
    fml, data = df, family = binomial(link = link),
    control = glm.control(epsilon = 1e-15, maxit = 200)
  )

  eval_dev <- function(fit) {
    eta_hat <- fit$linear.predictors
    w_glm <- fit$weights
    w_mspl <- exp(mspl_log_weight(eta_hat, design$trials, link))
    abs_dev <- abs(w_glm - w_mspl)
    rel_dev <- abs_dev / pmax(abs(w_glm), 1e-300)
    list(max_abs_dev = max(abs_dev), max_rel_dev = max(rel_dev))
  }
  loose <- eval_dev(fit_loose)
  tight <- eval_dev(fit_tight)

  list(
    fit = fit_tight, eta_hat = fit_tight$linear.predictors,
    w_glm = fit_tight$weights,
    w_mspl = exp(mspl_log_weight(fit_tight$linear.predictors, design$trials, link)),
    y_succ = sim$y,
    max_abs_dev = tight$max_abs_dev, max_rel_dev = tight$max_rel_dev,
    loose_max_abs_dev = loose$max_abs_dev, loose_max_rel_dev = loose$max_rel_dev,
    converged = fit_tight$converged, n = nrow(df), p = ncol(design$X)
  )
}

# ---------------------------------------------------------------------------
# (B) Jeffreys parity: drmTMB half_logdet vs (1/2) log det(X' diag(w_glm) X)
#     built from glm()'s own converged weights, at the glm-fitted beta.
# ---------------------------------------------------------------------------
check_B <- function(design, link, seed, glm_result) {
  X <- design$X
  w_glm <- glm_result$w_glm
  info_glm <- crossprod(X, X * w_glm)
  logdet_glm <- determinant(info_glm, logarithm = TRUE)
  stopifnot(logdet_glm$sign > 0)
  half_logdet_glm <- as.numeric(logdet_glm$modulus) / 2

  beta_hat <- coef(glm_result$fit)
  jeff <- mspl_jeffreys(
    X = X, beta = beta_hat, offset = 0,
    trials = design$trials, frequency = 1L, link = link
  )
  stopifnot(isTRUE(jeff$ok))
  abs_dev <- abs(jeff$half_logdet - half_logdet_glm)
  rel_dev <- abs_dev / max(abs(half_logdet_glm), 1e-300)

  # Optional: brglm2 mean-bias-reducing (Jeffreys / AS_mean) fit, finite check.
  y_succ <- glm_result$y_succ
  y_fail <- design$trials - y_succ
  brglm_fit <- tryCatch(
    brglm2::brglm_fit(
      x = X, y = cbind(y_succ, y_fail),
      family = binomial(link = link), control = brglm2::brglmControl(type = "AS_mean")
    ),
    error = function(e) NULL
  )
  brglm_finite <- if (is.null(brglm_fit)) NA else all(is.finite(coef(brglm_fit)))

  list(
    half_logdet_mspl = jeff$half_logdet, half_logdet_glm = half_logdet_glm,
    abs_dev = abs_dev, rel_dev = rel_dev, brglm_finite = brglm_finite
  )
}

# ---------------------------------------------------------------------------
# (C) Defect regression: mspl_penalty_components() must actually CHANGE with
#     link on the SAME inputs.
# ---------------------------------------------------------------------------
check_C <- function(design, seed) {
  set.seed(seed)
  # Use a fixed, link-neutral beta (not link-specific fitted values) so the
  # comparison isolates the link argument's effect on the SAME X, beta.
  beta_fixed <- design$beta_true
  out <- lapply(links, function(L) {
    mspl_penalty_components(
      X = design$X, beta = beta_fixed, variance = 0, q = 1L,
      offset = 0, trials = design$trials, frequency = 1L, link = L
    )
  })
  names(out) <- links
  stopifnot(all(vapply(out, function(o) isTRUE(o$ok), logical(1))))
  jeffreys_bonus <- vapply(out, function(o) o$jeffreys_bonus, numeric(1))
  log_objective_bonus <- vapply(out, function(o) o$log_objective_bonus, numeric(1))
  list(jeffreys_bonus = jeffreys_bonus, log_objective_bonus = log_objective_bonus)
}

# ---------------------------------------------------------------------------
# Run everything, collect results.
# ---------------------------------------------------------------------------
results_A <- list()
results_B <- list()
seed_ctr <- SEED + 100L

for (dname in names(designs)) {
  design <- designs[[dname]]
  for (link in links) {
    seed_ctr <- seed_ctr + 1L
    key <- paste(dname, link, sep = "_")
    a <- check_A(design, link, seed_ctr)
    results_A[[key]] <- a
    b <- check_B(design, link, seed_ctr, a)
    results_B[[key]] <- b
  }
}

results_C <- lapply(names(designs), function(dname) check_C(designs[[dname]], SEED + 500L))
names(results_C) <- names(designs)

# ---------------------------------------------------------------------------
# Print a summary to stdout (captured into the report by hand).
# ---------------------------------------------------------------------------
cat("=== (A) WEIGHT PARITY: glm() IRLS weights vs exp(mspl_log_weight()) ===\n")
cat("(tight = glm.control(epsilon=1e-15, maxit=200); loose = glm() defaults)\n")
for (key in names(results_A)) {
  a <- results_A[[key]]
  cat(sprintf(
    "%-16s n=%4d p=%d converged=%s  tight[abs=%.3e rel=%.3e]  loose[abs=%.3e rel=%.3e]\n",
    key, a$n, a$p, a$converged, a$max_abs_dev, a$max_rel_dev,
    a$loose_max_abs_dev, a$loose_max_rel_dev
  ))
}

cat("\n=== (B) JEFFREYS PARITY: mspl half_logdet vs 0.5*logdet(X'diag(w_glm)X) ===\n")
for (key in names(results_B)) {
  b <- results_B[[key]]
  cat(sprintf(
    "%-16s half_logdet_mspl=%.6f  half_logdet_glm=%.6f  abs_dev=%.3e  rel_dev=%.3e  brglm_finite=%s\n",
    key, b$half_logdet_mspl, b$half_logdet_glm, b$abs_dev, b$rel_dev, b$brglm_finite
  ))
}

cat("\n=== (C) DEFECT REGRESSION: mspl_penalty_components() jeffreys_bonus by link ===\n")
for (dname in names(results_C)) {
  c_res <- results_C[[dname]]
  cat(sprintf("%s: %s\n", dname, paste(sprintf("%s=%.6f", names(c_res$jeffreys_bonus), c_res$jeffreys_bonus), collapse = "  ")))
}

cat("\nSEED =", SEED, "\n")

# Save the raw results for the report author.
saveRDS(
  list(results_A = results_A, results_B = results_B, results_C = results_C, seed = SEED),
  file = "/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-drmTMB/e7414ec0-b299-4340-8cf1-7d90db6c2056/scratchpad/wt-omega/docs/dev-log/simulation-artifacts/2026-08-11-mspl-nonlogit-links/G0-oracle-results.rds"
)
