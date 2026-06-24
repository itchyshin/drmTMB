#!/usr/bin/env Rscript

devtools::load_all(quiet = TRUE)

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

script_file <- sub(
  "^--file=",
  "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1L] %||% "tools"
)
repo_root <- normalizePath(file.path(dirname(script_file), ".."))
if (!file.exists(file.path(repo_root, "DESCRIPTION"))) {
  repo_root <- normalizePath(getwd())
}

artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-24-spatial-mu-profile-strategy"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

artifact_path <- file.path(
  artifact_dir,
  "structured-re-spatial-mu-profile-strategy-results.tsv"
)
status_path <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "dashboard",
  "structured-re-spatial-mu-profile-strategy.tsv"
)

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

correlated_effects <- function(K, sds) {
  z <- replicate(length(sds), as.vector(t(chol(K)) %*% stats::rnorm(nrow(K))))
  out <- sweep(z, 2L, sds, `*`)
  colnames(out) <- names(sds)
  out
}

make_spatial_data <- function(seed, n_each, sds) {
  set.seed(seed)
  n <- 8L
  labels <- paste0("site_", seq_len(n))
  theta <- seq(0, 1.5 * pi, length.out = n)
  coords <- data.frame(
    x = cos(theta) + seq_len(n) / (3 * n),
    y = sin(theta)
  )
  rownames(coords) <- labels
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords,
    site = labels,
    group = "site"
  )
  K <- solve(as.matrix(precision$precision))
  effects <- correlated_effects(K, sds)
  rownames(effects) <- labels

  site <- rep(labels, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), times = length(labels))
  eta_mu <- 0.35 +
    0.20 * x +
    effects[site, "mu_intercept"] +
    effects[site, "mu_x"] * x
  eta_sigma <- -1.05 +
    effects[site, "sigma_intercept"] +
    effects[site, "sigma_x"] * x
  data <- data.frame(
    y = eta_mu + exp(eta_sigma) * stats::rnorm(length(x)),
    x = x,
    site = site
  )

  list(
    data = data,
    coords = coords,
    realized_sds = apply(effects, 2L, stats::sd)
  )
}

fit_spatial <- function(sim) {
  coords <- sim$coords
  drmTMB(
    bf(
      y ~ x + spatial(1 + x | site, coords = coords),
      sigma ~ spatial(1 + x | site, coords = coords)
    ),
    family = gaussian(),
    data = sim$data,
    control = drm_control(optimizer = list(eval.max = 1200, iter.max = 1200))
  )
}

run_profile <- function(fit, parm, engine) {
  warnings <- character()
  result <- withCallingHandlers(
    tryCatch(
      stats::confint(
        fit,
        parm = parm,
        method = "profile",
        profile_engine = engine,
        trace = FALSE,
        level = 0.70
      ),
      error = function(e) e
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  if (inherits(result, "error")) {
    return(data.frame(
      requested_engine = engine,
      method_status = "error",
      interval_finite = FALSE,
      lower = NA_real_,
      upper = NA_real_,
      conf_status = "error",
      effective_engine = engine,
      method_message = clean_text(conditionMessage(result)),
      method_warnings = clean_text(paste(warnings, collapse = " | ")),
      stringsAsFactors = FALSE
    ))
  }

  interval_finite <- is.finite(result$lower[[1L]]) &&
    is.finite(result$upper[[1L]])
  data.frame(
    requested_engine = engine,
    method_status = if (interval_finite) "finite" else "nonfinite",
    interval_finite = interval_finite,
    lower = result$lower[[1L]],
    upper = result$upper[[1L]],
    conf_status = result$conf.status[[1L]],
    effective_engine = result$profile.engine[[1L]],
    method_message = clean_text(result$profile.message[[1L]]),
    method_warnings = clean_text(paste(warnings, collapse = " | ")),
    stringsAsFactors = FALSE
  )
}

strategy_status <- function(design_id, method_status) {
  if (identical(method_status, "finite")) {
    return("finite_control")
  }
  if (design_id == "strong_seed202") {
    return("boundary_not_rescued")
  }
  "lower_side_not_rescued"
}

claim_boundary <- function(status) {
  clean_text(paste(
    "Fixed-covariance spatial mu:x profile-strategy diagnostic only;",
    "status =",
    status,
    "with no range-estimating spatial support, no interval reliability,",
    "interval coverage, REML, AI-REML, broad bridge support, public support,",
    "or coverage denominator admission promoted."
  ))
}

next_gate <- function(status) {
  if (identical(status, "finite_control")) {
    return(
      "Use as finite control only; require replicated denominators before coverage wording."
    )
  }
  "Keep this design out of coverage denominators until a safer lower-side strategy exists."
}

designs <- list(
  smoke_seed102 = list(
    seed = 102L,
    n_each = 10L,
    sds = c(
      mu_intercept = 0.40,
      mu_x = 0.24,
      sigma_intercept = 0.22,
      sigma_x = 0.14
    )
  ),
  strong_seed202 = list(
    seed = 202L,
    n_each = 20L,
    sds = c(
      mu_intercept = 0.60,
      mu_x = 0.45,
      sigma_intercept = 0.55,
      sigma_x = 0.40
    )
  ),
  strong_n50_seed202 = list(
    seed = 202L,
    n_each = 50L,
    sds = c(
      mu_intercept = 0.60,
      mu_x = 0.45,
      sigma_intercept = 0.55,
      sigma_x = 0.40
    )
  ),
  mu_dominant_seed202 = list(
    seed = 202L,
    n_each = 20L,
    sds = c(
      mu_intercept = 0.80,
      mu_x = 0.60,
      sigma_intercept = 0.12,
      sigma_x = 0.08
    )
  )
)
engines <- c("endpoint", "auto", "tmbprofile")
parm <- "sd:mu:mu:spatial(0 + x | site)"
rows <- list()

for (design_id in names(designs)) {
  design <- designs[[design_id]]
  sim <- make_spatial_data(
    seed = design$seed,
    n_each = design$n_each,
    sds = design$sds
  )
  fit <- fit_spatial(sim)
  target <- profile_targets(fit)
  target <- target[target$parm == parm, , drop = FALSE]

  for (engine in engines) {
    profile_row <- run_profile(fit, parm = parm, engine = engine)
    status <- strategy_status(design_id, profile_row$method_status[[1L]])
    strategy_id <- paste0(
      "spatial_mu_x_profile_strategy_",
      design_id,
      "_",
      engine
    )
    rows[[length(rows) + 1L]] <- data.frame(
      strategy_id = strategy_id,
      cell_id = "qseries_spatial_q1_mu_sigma_one_slope",
      design_id = design_id,
      requested_engine = engine,
      effective_engine = profile_row$effective_engine,
      seed = design$seed,
      n_each = design$n_each,
      formula_cell = "spatial(1 + x | site, coords = coords) in mu and sigma",
      structured_type = "spatial",
      target_kind = "direct_sd",
      endpoint_member = "mu:x",
      direct_sd_target = "sd_mu_x",
      profile_target = parm,
      source_artifact = file.path(
        "docs",
        "dev-log",
        "simulation-artifacts",
        "2026-06-24-spatial-mu-profile-strategy",
        "structured-re-spatial-mu-profile-strategy-results.tsv"
      ),
      source_geometry = "docs/dev-log/dashboard/structured-re-spatial-mu-profile-geometry.tsv",
      intended_sd_mu_intercept = design$sds[["mu_intercept"]],
      intended_sd_mu_x = design$sds[["mu_x"]],
      intended_sd_sigma_intercept = design$sds[["sigma_intercept"]],
      intended_sd_sigma_x = design$sds[["sigma_x"]],
      realized_sd_mu_intercept = sim$realized_sds[["mu_intercept"]],
      realized_sd_mu_x = sim$realized_sds[["mu_x"]],
      realized_sd_sigma_intercept = sim$realized_sds[["sigma_intercept"]],
      realized_sd_sigma_x = sim$realized_sds[["sigma_x"]],
      estimate = target$estimate[[1L]],
      profile_ready = target$profile_ready[[1L]],
      method_status = profile_row$method_status,
      interval_finite = profile_row$interval_finite,
      lower = profile_row$lower,
      upper = profile_row$upper,
      conf_status = profile_row$conf_status,
      method_message = profile_row$method_message,
      method_warnings = profile_row$method_warnings,
      strategy_status = status,
      interval_claim_status = "diagnostic_only",
      denominator_admission = "not_admitted",
      status = "covered",
      evidence_url = "docs/dev-log/after-task/2026-06-24-spatial-mu-profile-strategy.md",
      claim_boundary = claim_boundary(status),
      next_gate = next_gate(status),
      stringsAsFactors = FALSE
    )
  }
}

out <- do.call(rbind, rows)
character_cols <- vapply(out, is.character, logical(1L))
out[character_cols] <- lapply(out[character_cols], clean_text)

utils::write.table(
  out,
  file = artifact_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)
utils::write.table(
  out,
  file = status_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)

message("Wrote ", normalizePath(artifact_path, winslash = "/"))
message("Wrote ", normalizePath(status_path, winslash = "/"))
