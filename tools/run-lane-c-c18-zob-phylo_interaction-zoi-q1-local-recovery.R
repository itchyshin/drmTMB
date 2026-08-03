#!/usr/bin/env Rscript
#
# C18 point recovery: structured `phylo_interaction` provider on the `zoi`
# atom of zero_one_beta(), q1 (one unlabelled intercept), cell mc-0607.
#
# DGP constants per docs/dev-log/implementation-recovery/
# 2026-08-02-c18-atom-dgp-feasibility/README.md: zoi = 0.50, n_each = 50,
# coi = 0.50, tau = 0.55, n_tip = 32 (single-tree phylo convention).
#
# DEVIATION NOTE (two-tree mapping). The feasibility campaign validated a
# 32-GROUP design. phylo_interaction's latent field is the Kronecker product
# of two tree precisions, so its group count is n1 * n2, not a single n_tip.
# We therefore use n1 = 8, n2 = 4 to hit exactly 32 interaction cells, so the
# group count, rows per group and total row count all match the validated
# cell. What the campaign did NOT validate is the Kronecker CORRELATION
# structure itself, which differs from a single tree; that is why this
# provider is sequenced last and why its result must be read on its own
# evidence rather than inheriting the phylo cell's.
#
# Structured routing for `zoi ~ phylo_interaction(...)` does not exist in
# the package yet (it is being implemented concurrently). This script is
# authored to PARSE and to fit the gate once that routing lands; it is not
# expected to run successfully today.

write_tsv <- function(x, path) utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE)

simulate_one <- function(seed, tau = .55) {
  set.seed(seed)
  n1 <- 8L; n2 <- 4L; n_each <- 50L
  t1 <- ape::stree(n1, type = "balanced"); t1$edge.length <- rep(1, nrow(t1$edge)); t1$tip.label <- paste0("plant", seq_len(n1))
  t2 <- ape::stree(n2, type = "balanced"); t2$edge.length <- rep(1, nrow(t2$edge)); t2$tip.label <- paste0("poll", seq_len(n2))
  V <- kronecker(drmTMB:::drm_phylo_tip_covariance(t2), drmTMB:::drm_phylo_tip_covariance(t1))
  g <- expand.grid(plant = t1$tip.label, pollinator = t2$tip.label)
  u <- as.numeric(t(chol(V)) %*% rnorm(n1 * n2, sd = tau))
  names(u) <- paste(g$plant, g$pollinator, sep = ":")

  d <- g[rep(seq_len(n1 * n2), each = n_each), ]
  d$x <- rnorm(nrow(d))
  d$x <- d$x - ave(d$x, interaction(d$plant, d$pollinator), FUN = mean)
  d$x <- d$x / sd(d$x)
  gid <- paste(d$plant, d$pollinator, sep = ":")
  group <- factor(gid, levels = names(u))

  mu <- plogis(-.15 + .35 * d$x)
  sigma <- exp(-1)
  zoi <- plogis(u[gid])       # qlogis(.5) == 0: structured term carries the whole zoi linear predictor
  coi <- .5                   # fixed, unstructured

  boundary <- rbinom(nrow(d), 1L, zoi)
  y <- rbeta(nrow(d), mu / sigma^2, (1 - mu) / sigma^2)
  y[boundary == 1L] <- rbinom(sum(boundary), 1L, coi)
  d$y <- y

  zero_ct <- tapply(y == 0, group, sum)
  one_ct <- tapply(y == 1, group, sum)
  list(
    data = d[, c("y", "x", "plant", "pollinator")], t1 = t1, t2 = t2, u = u,
    n_zero = sum(y == 0), n_one = sum(y == 1),
    min_group_zero = min(zero_ct), min_group_one = min(one_ct),
    min_group_interior = min(tapply(y > 0 & y < 1, group, sum)),
    n_separated_groups = sum(zero_ct == 0L | one_ct == 0L),
    min_boundary_per_group = min(zero_ct + one_ct)
  )
}

formula_str <- "y ~ x, sigma ~ 1, zoi ~ phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree), coi ~ 1"

fit_one <- function(seed, sha, runner) {
  s <- simulate_one(seed)
  plant_tree <- s$t1; pollinator_tree <- s$t2
  f <- tryCatch(
    drmTMB::drmTMB(
      drmTMB::bf(
        y ~ x, sigma ~ 1,
        zoi ~ drmTMB::phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree),
        coi ~ 1
      ),
      family = drmTMB::zero_one_beta(), data = s$data,
      control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 2000L, iter.max = 2000L))
    ),
    error = identity
  )
  base <- data.frame(
    cell_id = "mc-0607", dpar = "zoi", seed, source_sha = sha, runner_sha = runner,
    formula = formula_str, tau_truth = .55,
    n_zero = s$n_zero, n_one = s$n_one,
    min_group_zero = s$min_group_zero, min_group_one = s$min_group_one,
    min_group_interior = s$min_group_interior,
    n_separated_groups = s$n_separated_groups,
    min_boundary_per_group = s$min_boundary_per_group
  )
  if (inherits(f, "error")) {
    return(cbind(base, status = "fit_error", error = conditionMessage(f)))
  }
  gr <- max(abs(f$obj$gr(f$opt$par)), na.rm = TRUE)
  tau_hat <- unname(f$sdpars$zoi[["phylo_interaction(1 | plant:pollinator)"]])
  mode <- ranef(f, "phylo_interaction_zoi")$terms[["phylo_interaction(1 | plant:pollinator)"]]
  cbind(
    base, status = "fit_ok",
    convergence = f$opt$convergence, pdHess = isTRUE(f$sdr$pdHess), max_gradient = gr,
    tau_hat = tau_hat,
    mode_correlation = suppressWarnings(cor(mode[names(s$u)], s$u)),
    boundary_hit = !is.finite(tau_hat) || tau_hat <= .05 || tau_hat >= 2.5,
    error = ""
  )
}

script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L])
root <- normalizePath(file.path(dirname(script), ".."))
setwd(root); pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
out <- Sys.getenv(
  "DRMTMB_RECOVERY_OUT",
  unset = file.path(root, "docs/dev-log/implementation-recovery/2026-08-02-lane-c-c18-zob-phylo_interaction-zoi-q1-local-run-1")
)
dir.create(out, recursive = TRUE, showWarnings = FALSE)
sha <- trimws(system2("git", c("rev-parse", "HEAD"), stdout = TRUE))
runner <- unname(tools::md5sum(script))

attempts <- do.call(rbind, lapply(2026080701:2026080704, fit_one, sha = sha, runner = runner))
write_tsv(attempts, file.path(out, "raw-attempts.tsv"))

# Guard: on the error path `run_one` returns only the base columns, so the
# fit-outcome columns below may be absent entirely. Without this guard the
# `with()` call aborts before summary.tsv is ever written -- which is exactly
# the state this script is in until structured atom routing lands.
gate_cols <- c(
  "status", "convergence", "pdHess", "max_gradient", "boundary_hit",
  "mode_correlation", "min_group_zero", "min_group_one", "min_group_interior",
  "n_separated_groups"
)
ok <- if (all(gate_cols %in% names(attempts))) {
  with(
    attempts,
    status == "fit_ok" & convergence == 0L & pdHess & max_gradient <= .01 & !boundary_hit &
      mode_correlation > .45 &
      min_group_zero > 0L & min_group_one > 0L & min_group_interior > 0L &
      n_separated_groups == 0L
  )
} else {
  rep(FALSE, nrow(attempts))
}
err <- if (any(ok)) mean(abs(attempts$tau_hat[ok] / .55 - 1)) else NA_real_
decision <- if (all(ok) && is.finite(err) && err <= .4) "PASS_POINT_RECOVERY_LOCAL" else "BLOCKED_LOCAL_FIXTURE"
write_tsv(
  data.frame(
    cell_id = "mc-0607", planned_attempts = 4L, attempted_attempts = nrow(attempts),
    passed_attempts = sum(ok), mean_tau_relative_error = err, decision = decision
  ),
  file.path(out, "summary.tsv")
)

# BOUNDARY_DIAGNOSTIC_ONLY: tau = 0, i.e. no group-level structure at all on
# zoi. Diagnostic fixture only; it is not part of the pass/fail gate above.
fixed <- simulate_one(2026080799L, tau = 0)
plant_tree <- fixed$t1; pollinator_tree <- fixed$t2
fixed_fit <- tryCatch(
  drmTMB::drmTMB(
    drmTMB::bf(
      y ~ x, sigma ~ 1,
      zoi ~ drmTMB::phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree),
      coi ~ 1
    ),
    family = drmTMB::zero_one_beta(), data = fixed$data,
    control = drmTMB::drm_control(se = TRUE, optimizer = list(eval.max = 2000L, iter.max = 2000L))
  ),
  error = identity
)
fixed_record <- if (inherits(fixed_fit, "error")) {
  data.frame(cell_id = "mc-0607", source_sha = sha, runner_sha = runner, status = "fit_error", decision = "BOUNDARY_DIAGNOSTIC_ONLY", error = conditionMessage(fixed_fit))
} else {
  data.frame(
    cell_id = "mc-0607", source_sha = sha, runner_sha = runner, status = "fit_ok",
    convergence = fixed_fit$opt$convergence, pdHess = isTRUE(fixed_fit$sdr$pdHess),
    tau_hat = unname(fixed_fit$sdpars$zoi[["phylo_interaction(1 | plant:pollinator)"]]),
    decision = "BOUNDARY_DIAGNOSTIC_ONLY", error = ""
  )
}
write_tsv(fixed_record, file.path(out, "fixed-zoi-phylo_interaction-boundary-diagnostic.tsv"))
