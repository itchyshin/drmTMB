#!/usr/bin/env Rscript

# Successor evidence runner. The stopped PR2 runner remains immutable and is
# sourced only to reuse its tested likelihood, manifest, shard, and stage code.
successor_script_path <- function() {
  script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  path <- if (length(script_arg)) {
    sub("^--file=", "", script_arg[[1L]])
  } else {
    getOption(
      "drmTMB.successor.runner_path",
      "tools/run-beta-phylo-q1-sd-interior-recovery.R"
    )
  }
  normalizePath(path, mustWork = TRUE)
}

successor_path <- successor_script_path()
stopped_runner_path <- file.path(
  dirname(successor_path),
  "run-beta-phylo-q1-sd-regression-recovery.R"
)
sys.source(stopped_runner_path, envir = environment())

stopped_pr2_seed_audit <- pr2_seed_audit
stopped_pr2_recovery_attempt <- pr2_recovery_attempt
stopped_pr2_recovery_gates <- pr2_recovery_gates
stopped_pr2_preflight <- pr2_preflight
stopped_authenticate_stage <- authenticate_pr2_stage_output

pr2_context <- function() {
  list(
    script_path = successor_script_path(),
    repo_root = normalizePath(
      file.path(dirname(successor_script_path()), ".."),
      mustWork = TRUE
    )
  )
}

pr2_seed_grid <- function(mode = c("certification", "smoke", "one_fit")) {
  mode <- match.arg(mode)
  reps <- if (mode == "certification") 400L else 1L
  cells <- pr2_cells()
  grid <- cells[rep(seq_len(nrow(cells)), each = reps), , drop = FALSE]
  grid$replicate <- rep(seq_len(reps), times = nrow(cells))
  base <- switch(
    mode,
    certification = 2080000000L,
    smoke = 2070000000L,
    one_fit = 2060000000L
  )
  grid$seed <- as.integer(base - 10000L * grid$cell_number - grid$replicate)
  if (mode == "one_fit") {
    grid <- grid[1L, , drop = FALSE]
  }
  rownames(grid) <- NULL
  grid
}

stopped_pr2_seed_grid <- function(
  mode = c("certification", "smoke", "one_fit")
) {
  mode <- match.arg(mode)
  reps <- if (mode == "certification") 400L else 1L
  cells <- pr2_cells()
  grid <- cells[rep(seq_len(nrow(cells)), each = reps), , drop = FALSE]
  grid$replicate <- rep(seq_len(reps), times = nrow(cells))
  base <- if (mode == "certification") 2100000000L else 2090000000L
  grid$seed <- as.integer(base - 10000L * grid$cell_number - grid$replicate)
  if (mode == "one_fit") {
    grid <- grid[1L, , drop = FALSE]
    grid$seed <- 2080000000L - 10000L * grid$cell_number - grid$replicate
  }
  rownames(grid) <- NULL
  grid
}

pr2_design_path <- function(repo_root) {
  file.path(
    repo_root,
    "docs/dev-log/simulation-designs",
    "2026-07-16-beta-phylo-q1-interior-dgp",
    "design.tsv"
  )
}

pr2_frozen_design_sha256 <- function() {
  "6d253e54c9f668b6009ab8e92e4af835e9d3b71b62557ef3e1ef75a45fc056a8"
}

# These are predecessor authentication records, not successor design files.
pr2_prior_manifest_path <- function(repo_root) {
  file.path(
    repo_root,
    "docs/dev-log/simulation-designs",
    "2026-07-16-beta-phylo-q1-pr2-sd-regression",
    "prior-design-manifest.tsv"
  )
}

pr2_seed_audit_path <- function(repo_root) {
  file.path(
    repo_root,
    "docs/dev-log/simulation-designs",
    "2026-07-16-beta-phylo-q1-pr2-sd-regression",
    "seed-audit.tsv"
  )
}

pr2_seed_audit <- function(grid, repo_root, mode) {
  audit <- stopped_pr2_seed_audit(grid, repo_root, mode)
  stopped <- lapply(
    c("certification", "smoke", "one_fit"),
    stopped_pr2_seed_grid
  )
  stopped_audit <- do.call(
    rbind,
    lapply(names(stopped), function(label) {
      data.frame(
        check = paste0("overlap_stopped_pr2_", label),
        observed = length(intersect(grid$seed, stopped[[label]]$seed)),
        expected = 0L,
        stringsAsFactors = FALSE
      )
    })
  )
  stopped_audit$pass <- stopped_audit$observed == stopped_audit$expected
  audit <- rbind(audit, stopped_audit)
  if (!all(audit$pass)) {
    stop(
      "Successor seed audit failed: ",
      paste(audit$check[!audit$pass], collapse = ", "),
      call. = FALSE
    )
  }
  audit
}

draw_machine_interior_beta <- function(
  mu,
  phi,
  max_redraws = 1000L,
  draw_one = stats::rbeta
) {
  if (
    length(mu) != length(phi) || any(!is.finite(mu)) || any(!is.finite(phi))
  ) {
    stop(
      "`mu` and `phi` must be finite vectors of equal length.",
      call. = FALSE
    )
  }
  if (length(max_redraws) != 1L || is.na(max_redraws) || max_redraws < 1L) {
    stop("`max_redraws` must be a positive integer.", call. = FALSE)
  }
  y <- rep(NA_real_, length(mu))
  initial_boundary_count <- 0L
  total_redraws <- 0L
  row_redraws <- integer(length(mu))
  cap_exhausted <- FALSE
  for (i in seq_along(mu)) {
    for (draw in seq_len(as.integer(max_redraws))) {
      value <- draw_one(1L, mu[[i]] * phi[[i]], (1 - mu[[i]]) * phi[[i]])
      strict <- length(value) == 1L &&
        is.finite(value) &&
        value > 0 &&
        value < 1
      if (draw == 1L && !strict) {
        initial_boundary_count <- initial_boundary_count + 1L
      }
      if (strict) {
        y[[i]] <- value
        row_redraws[[i]] <- draw - 1L
        total_redraws <- total_redraws + draw - 1L
        break
      }
      if (draw == max_redraws) {
        row_redraws[[i]] <- draw - 1L
        total_redraws <- total_redraws + draw - 1L
        cap_exhausted <- TRUE
      }
    }
  }
  list(
    y = y,
    initial_boundary_count = initial_boundary_count,
    total_redraws = total_redraws,
    max_response_redraws = max(row_redraws),
    cap_exhausted = cap_exhausted,
    all_final_responses_strict_interior = all(is.finite(y) & y > 0 & y < 1)
  )
}

beta_phylo_sd_regression_dgp <- function(g, m, predictor_design, seed) {
  with_pr2_rng(seed, {
    truth <- c(
      beta_mu_intercept = 0,
      beta_mu_x = 0.35,
      beta_sigma_intercept = log(0.25),
      beta_sigma_x = 0.20,
      alpha_intercept = log(0.30),
      alpha_x = 0.25
    )
    tree <- ape::rcoal(g)
    if (identical(predictor_design, "distinct")) {
      x_mu_species <- pr2_standardize(stats::rnorm(g))
      x_sigma_species <- pr2_standardize(stats::rnorm(g))
      x_tau_species <- pr2_standardize(stats::rnorm(g))
    } else if (identical(predictor_design, "shared")) {
      shared <- pr2_standardize(stats::rnorm(g))
      x_mu_species <- x_sigma_species <- x_tau_species <- shared
    } else {
      stop("Unknown predictor design: ", predictor_design, call. = FALSE)
    }
    A <- drmTMB:::drm_phylo_tip_covariance(tree)
    unit_tip <- as.vector(t(chol(A)) %*% stats::rnorm(g))
    tau <- exp(truth[["alpha_intercept"]] + truth[["alpha_x"]] * x_tau_species)
    location_effect <- tau * unit_tip
    names(location_effect) <- tree$tip.label
    spp_id <- factor(rep(tree$tip.label, each = m), levels = tree$tip.label)
    species_index <- rep(seq_len(g), each = m)
    x_mu <- x_mu_species[species_index]
    x_sigma <- x_sigma_species[species_index]
    x_tau <- x_tau_species[species_index]
    eta_mu <- truth[["beta_mu_intercept"]] +
      truth[["beta_mu_x"]] * x_mu +
      location_effect[as.character(spp_id)]
    log_sigma <- truth[["beta_sigma_intercept"]] +
      truth[["beta_sigma_x"]] * x_sigma
    mu <- stats::plogis(eta_mu)
    phi <- exp(-2 * log_sigma)
    response <- draw_machine_interior_beta(mu, phi)
    list(
      data = data.frame(y = response$y, x_mu, x_sigma, x_tau, spp_id),
      tree = tree,
      truth = truth,
      telemetry = response[names(response) != "y"]
    )
  })
}

pr2_recovery_attempt <- function(row, identity = NULL) {
  generated <- beta_phylo_sd_regression_dgp(
    row$g,
    row$m,
    row$predictor_design,
    row$seed
  )
  out <- stopped_pr2_recovery_attempt(row, identity)
  telemetry <- as.data.frame(generated$telemetry, stringsAsFactors = FALSE)
  cbind(
    out[, seq_len(match("error", names(out))), drop = FALSE],
    telemetry,
    out[, (match("error", names(out)) + 1L):ncol(out), drop = FALSE]
  )
}

pr2_attempt_columns <- function() {
  before <- c(
    "cell_id",
    "cell_number",
    "predictor_design",
    "g",
    "m",
    "replicate",
    "seed",
    "elapsed",
    "fit_success",
    "convergence",
    "pdHess",
    "max_gradient",
    "fixed_hessian_condition",
    "min_tau",
    "max_tau",
    "warning_count",
    "warnings",
    "error"
  )
  c(
    before,
    "initial_boundary_count",
    "total_redraws",
    "max_response_redraws",
    "cap_exhausted",
    "all_final_responses_strict_interior",
    paste0("truth_", pr2_parameters()),
    paste0("estimate_", pr2_parameters()),
    pr2_identity_columns()
  )
}

pr2_attempt_col_classes <- function() {
  columns <- pr2_attempt_columns()
  classes <- stats::setNames(rep("numeric", length(columns)), columns)
  classes[c(
    "cell_id",
    "predictor_design",
    "warnings",
    "error",
    pr2_identity_columns()
  )] <- "character"
  classes[c(
    "cell_number",
    "g",
    "m",
    "replicate",
    "seed",
    "convergence",
    "warning_count",
    "initial_boundary_count",
    "total_redraws",
    "max_response_redraws"
  )] <- "integer"
  classes[c(
    "fit_success",
    "pdHess",
    "cap_exhausted",
    "all_final_responses_strict_interior"
  )] <- "logical"
  unname(classes)
}

pr2_recovery_gates <- function(raw, expected_reps, certification = FALSE) {
  required <- c(
    "initial_boundary_count",
    "total_redraws",
    "max_response_redraws",
    "cap_exhausted",
    "all_final_responses_strict_interior"
  )
  if (!all(required %in% names(raw))) {
    stop("Successor telemetry columns are missing.", call. = FALSE)
  }
  gates <- stopped_pr2_recovery_gates(raw, expected_reps, certification)
  telemetry <- do.call(
    rbind,
    lapply(seq_len(nrow(gates$quality)), function(i) {
      id <- gates$quality$cell_id[[i]]
      rows <- raw[raw$cell_id == id, , drop = FALSE]
      data.frame(
        cell_id = id,
        initial_boundary_count = sum(rows$initial_boundary_count),
        total_redraws = sum(rows$total_redraws),
        max_response_redraws = max(rows$max_response_redraws),
        cap_exhaustions = sum(rows$cap_exhausted %in% TRUE),
        all_final_responses_strict_interior = all(
          rows$all_final_responses_strict_interior %in% TRUE
        ),
        stringsAsFactors = FALSE
      )
    })
  )
  gates$quality <- merge(gates$quality, telemetry, by = "cell_id", sort = FALSE)
  gates$quality$quality_pass <- gates$quality$quality_pass &
    gates$quality$cap_exhaustions == 0L &
    gates$quality$all_final_responses_strict_interior
  promotion <- gates$quality$g == 1024L & gates$quality$m == 4L
  gates$promotion_cells$pass <- vapply(
    gates$promotion_cells$cell_id,
    function(id) {
      quality_pass <- gates$quality$quality_pass[gates$quality$cell_id == id]
      parameter_pass <- gates$summary$parameter_pass[
        gates$summary$cell_id == id
      ]
      isTRUE(quality_pass) && all(parameter_pass)
    },
    logical(1L)
  )
  gates$decision$distinct_g1024_m4 <- isTRUE(gates$promotion_cells$pass[
    gates$promotion_cells$predictor_design == "distinct"
  ])
  gates$decision$shared_g1024_m4 <- isTRUE(gates$promotion_cells$pass[
    gates$promotion_cells$predictor_design == "shared"
  ])
  gates$decision$status <- if (!certification) {
    "SMOKE_ONLY_NO_PROMOTION"
  } else if (
    gates$decision$distinct_g1024_m4 && gates$decision$shared_g1024_m4
  ) {
    "PASS_EXACT_TWO_G1024_M4"
  } else {
    "HOLD_NO_SUCCESSOR_PROMOTION"
  }
  gates
}

pr2_preflight <- function(repo_root, design_path, require_compute_host = TRUE) {
  result <- stopped_pr2_preflight(repo_root, design_path, require_compute_host)
  protected <- c(
    "tools/run-beta-phylo-q1-sd-interior-recovery.R",
    "docs/dev-log/simulation-designs/2026-07-16-beta-phylo-q1-interior-dgp/design.tsv"
  )
  status <- system2(
    Sys.which("git"),
    c(
      "-C",
      repo_root,
      "status",
      "--porcelain",
      "--untracked-files=all",
      "--",
      protected
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  extra <- data.frame(
    check = "successor_paths_clean",
    observed = as.character(length(status)),
    expected = "0",
    pass = length(status) == 0L,
    stringsAsFactors = FALSE
  )
  result <- rbind(result, extra)
  if (!all(result$pass)) {
    stop("Successor preflight failed.", call. = FALSE)
  }
  result
}

pr2_default_output <- function(repo_root, mode) {
  file.path(
    repo_root,
    "docs/dev-log/simulation-artifacts",
    paste0("2026-07-16-beta-phylo-q1-interior-dgp-", mode)
  )
}

authenticate_pr2_stage_output <- function(
  out_dir,
  expected_mode,
  expected_attempts
) {
  provenance <- stopped_authenticate_stage(
    out_dir,
    expected_mode,
    expected_attempts
  )
  raw <- utils::read.delim(
    file.path(out_dir, "raw-attempts.tsv"),
    stringsAsFactors = FALSE
  )
  required <- c("cap_exhausted", "all_final_responses_strict_interior")
  if (
    !all(required %in% names(raw)) ||
      any(raw$cap_exhausted %in% TRUE) ||
      !all(raw$all_final_responses_strict_interior %in% TRUE)
  ) {
    stop(
      "Authenticated stage failed successor interior-response gate.",
      call. = FALSE
    )
  }
  provenance
}

if (sys.nframe() == 0L) {
  run_pr2_recovery()
}
