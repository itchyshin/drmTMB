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
  "2026-06-24-spatial-mu-boundary-diagnostic"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

artifact_path <- file.path(
  artifact_dir,
  "structured-re-spatial-mu-boundary-diagnostic-results.tsv"
)
status_path <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "dashboard",
  "structured-re-spatial-mu-boundary-diagnostic.tsv"
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
    effects = effects,
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

endpoint_profile_target <- function(endpoint_member) {
  coefficient <- if (grepl("Intercept", endpoint_member, fixed = TRUE)) {
    "1"
  } else {
    "0 + x"
  }
  paste0("sd:mu:mu:spatial(", coefficient, " | site)")
}

direct_sd_target <- function(endpoint_member) {
  switch(
    endpoint_member,
    "mu:(Intercept)" = "sd_mu_intercept",
    "mu:x" = "sd_mu_x"
  )
}

endpoint_token <- function(endpoint_member) {
  out <- gsub(":", "_", endpoint_member, fixed = TRUE)
  out <- gsub("(", "", out, fixed = TRUE)
  out <- gsub(")", "", out, fixed = TRUE)
  gsub("_Intercept", "_intercept", out, fixed = TRUE)
}

run_interval <- function(fit, parm, method) {
  warnings <- character()
  result <- withCallingHandlers(
    tryCatch(
      {
        args <- list(object = fit, parm = parm, method = method, level = 0.70)
        if (identical(method, "profile")) {
          args <- c(
            args,
            list(
              profile_engine = "endpoint",
              trace = FALSE,
              profile_endpoint_max_eval = 80L
            )
          )
        }
        do.call(stats::confint, args)
      },
      error = function(e) e
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  if (inherits(result, "error")) {
    return(data.frame(
      interval_method = method,
      method_status = "error",
      interval_finite = FALSE,
      lower = NA_real_,
      upper = NA_real_,
      conf_status = "error",
      method_message = clean_text(conditionMessage(result)),
      method_warnings = clean_text(paste(warnings, collapse = " | ")),
      stringsAsFactors = FALSE
    ))
  }

  interval_finite <- is.finite(result$lower[[1L]]) &&
    is.finite(result$upper[[1L]])
  data.frame(
    interval_method = method,
    method_status = if (interval_finite) "finite" else "nonfinite",
    interval_finite = interval_finite,
    lower = result$lower[[1L]],
    upper = result$upper[[1L]],
    conf_status = if ("conf.status" %in% names(result)) {
      result$conf.status[[1L]]
    } else {
      NA_character_
    },
    method_message = clean_text(
      if ("profile.message" %in% names(result)) {
        as.character(result$profile.message[[1L]])
      } else {
        NA_character_
      }
    ),
    method_warnings = clean_text(paste(warnings, collapse = " | ")),
    stringsAsFactors = FALSE
  )
}

classify_status <- function(rows) {
  if (all(rows$interval_finite)) {
    return("wald_profile_finite")
  }
  if (any(rows$interval_finite)) {
    return("wald_finite_profile_nonfinite")
  }
  "wald_profile_nonfinite_boundary"
}

classify_failure <- function(rows) {
  failures <- character()
  wald <- rows[rows$interval_method == "wald", , drop = FALSE]
  profile <- rows[rows$interval_method == "profile", , drop = FALSE]
  if (!isTRUE(wald$interval_finite[[1L]])) {
    failures <- c(failures, "wald_boundary_or_nonfinite")
  }
  if (!isTRUE(profile$interval_finite[[1L]])) {
    failures <- c(failures, "profile_failed_or_nonfinite")
  }
  if (!length(failures)) {
    return("none")
  }
  paste(failures, collapse = ";")
}

claim_boundary <- function(diagnostic_status) {
  clean_text(paste(
    "Fixed-covariance spatial mu+sigma one-slope spatial-mu boundary",
    "diagnostic only; status =",
    diagnostic_status,
    "with no range-estimating spatial support, no interval reliability,",
    "interval coverage, REML, AI-REML, broad bridge support, or public",
    "support promoted."
  ))
}

next_gate <- function(diagnostic_status) {
  if (identical(diagnostic_status, "wald_profile_finite")) {
    return(
      "Use only as seed-sensitivity evidence; require replicated denominators before coverage wording."
    )
  }
  if (identical(diagnostic_status, "wald_finite_profile_nonfinite")) {
    return(
      "Diagnose endpoint-profile failure before any spatial mu coverage-grid design."
    )
  }
  "Avoid this design as a coverage denominator until boundary geometry is diagnosed."
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
  strong_seed102 = list(
    seed = 102L,
    n_each = 20L,
    sds = c(
      mu_intercept = 0.60,
      mu_x = 0.45,
      sigma_intercept = 0.55,
      sigma_x = 0.40
    )
  ),
  strong_seed302 = list(
    seed = 302L,
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

endpoint_members <- c("mu:(Intercept)", "mu:x")
methods <- c("wald", "profile")
method_rows <- list()
status_rows <- list()

for (design_id in names(designs)) {
  design <- designs[[design_id]]
  sim <- make_spatial_data(
    seed = design$seed,
    n_each = design$n_each,
    sds = design$sds
  )
  fit <- fit_spatial(sim)
  targets <- profile_targets(fit)

  for (endpoint_member in endpoint_members) {
    parm <- endpoint_profile_target(endpoint_member)
    target <- targets[match(parm, targets$parm), , drop = FALSE]
    target_found <- nrow(target) == 1L && identical(target$parm[[1L]], parm)
    rows <- do.call(
      rbind,
      lapply(methods, function(method) {
        run_interval(fit, parm, method)
      })
    )
    rows$design_id <- design_id
    rows$seed <- design$seed
    rows$n_each <- design$n_each
    rows$endpoint_member <- endpoint_member
    rows$direct_sd_target <- direct_sd_target(endpoint_member)
    rows$profile_target <- parm
    rows$intended_sd_mu_intercept <- design$sds[["mu_intercept"]]
    rows$intended_sd_mu_x <- design$sds[["mu_x"]]
    rows$intended_sd_sigma_intercept <- design$sds[["sigma_intercept"]]
    rows$intended_sd_sigma_x <- design$sds[["sigma_x"]]
    rows$realized_sd_mu_intercept <- sim$realized_sds[["mu_intercept"]]
    rows$realized_sd_mu_x <- sim$realized_sds[["mu_x"]]
    rows$realized_sd_sigma_intercept <- sim$realized_sds[["sigma_intercept"]]
    rows$realized_sd_sigma_x <- sim$realized_sds[["sigma_x"]]
    rows$estimate <- if (target_found) target$estimate[[1L]] else NA_real_
    rows$profile_ready <- if (target_found) {
      target$profile_ready[[1L]]
    } else {
      FALSE
    }
    rows$profile_note <- if (target_found) {
      target$profile_note[[1L]]
    } else {
      NA_character_
    }
    rows$convergence <- fit$opt$convergence
    rows$pdHess <- isTRUE(fit$sdr$pdHess)
    rows$logLik <- as.numeric(stats::logLik(fit))
    method_rows[[length(method_rows) + 1L]] <- rows

    diagnostic_status <- classify_status(rows)
    diagnostic_id <- paste0(
      "spatial_mu_boundary_",
      design_id,
      "_",
      endpoint_token(endpoint_member)
    )
    status_rows[[length(status_rows) + 1L]] <- data.frame(
      diagnostic_id = diagnostic_id,
      cell_id = "qseries_spatial_q1_mu_sigma_one_slope",
      design_id = design_id,
      seed = design$seed,
      n_each = design$n_each,
      formula_cell = "spatial(1 + x | site, coords = coords) in mu and sigma",
      structured_type = "spatial",
      target_kind = "direct_sd",
      endpoint_member = endpoint_member,
      direct_sd_target = direct_sd_target(endpoint_member),
      profile_target = parm,
      source_artifact = file.path(
        "docs",
        "dev-log",
        "simulation-artifacts",
        "2026-06-24-spatial-mu-boundary-diagnostic",
        "structured-re-spatial-mu-boundary-diagnostic-results.tsv"
      ),
      intended_sd_mu_intercept = design$sds[["mu_intercept"]],
      intended_sd_mu_x = design$sds[["mu_x"]],
      intended_sd_sigma_intercept = design$sds[["sigma_intercept"]],
      intended_sd_sigma_x = design$sds[["sigma_x"]],
      realized_sd_mu_intercept = sim$realized_sds[["mu_intercept"]],
      realized_sd_mu_x = sim$realized_sds[["mu_x"]],
      realized_sd_sigma_intercept = sim$realized_sds[["sigma_intercept"]],
      realized_sd_sigma_x = sim$realized_sds[["sigma_x"]],
      observed_target_rows = as.integer(target_found),
      n_fit_ok = as.integer(fit$opt$convergence == 0L),
      n_pdhess = as.integer(isTRUE(fit$sdr$pdHess)),
      estimate = if (target_found) target$estimate[[1L]] else NA_real_,
      wald_status = rows$method_status[rows$interval_method == "wald"],
      profile_status = rows$method_status[rows$interval_method == "profile"],
      diagnostic_status = diagnostic_status,
      failure_class = classify_failure(rows),
      interval_claim_status = "diagnostic_only",
      status = "covered",
      evidence_url = "docs/dev-log/after-task/2026-06-24-spatial-mu-boundary-diagnostic.md",
      claim_boundary = claim_boundary(diagnostic_status),
      next_gate = next_gate(diagnostic_status),
      stringsAsFactors = FALSE
    )
  }
}

method_out <- do.call(rbind, method_rows)
method_out <- method_out[
  c(
    "design_id",
    "seed",
    "n_each",
    "endpoint_member",
    "direct_sd_target",
    "profile_target",
    "interval_method",
    "method_status",
    "interval_finite",
    "lower",
    "upper",
    "conf_status",
    "method_message",
    "method_warnings",
    "intended_sd_mu_intercept",
    "intended_sd_mu_x",
    "intended_sd_sigma_intercept",
    "intended_sd_sigma_x",
    "realized_sd_mu_intercept",
    "realized_sd_mu_x",
    "realized_sd_sigma_intercept",
    "realized_sd_sigma_x",
    "estimate",
    "profile_ready",
    "profile_note",
    "convergence",
    "pdHess",
    "logLik"
  )
]
character_method_cols <- vapply(method_out, is.character, logical(1L))
method_out[character_method_cols] <- lapply(
  method_out[character_method_cols],
  clean_text
)

status_out <- do.call(rbind, status_rows)
character_status_cols <- vapply(status_out, is.character, logical(1L))
status_out[character_status_cols] <- lapply(
  status_out[character_status_cols],
  clean_text
)

utils::write.table(
  method_out,
  file = artifact_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)
utils::write.table(
  status_out,
  file = status_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)

message("Wrote ", normalizePath(artifact_path, winslash = "/"))
message("Wrote ", normalizePath(status_path, winslash = "/"))
