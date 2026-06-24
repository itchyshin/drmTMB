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

location_smoke_script <- file.path(
  repo_root,
  "tools",
  "run-structured-re-q4-location-slope-interval-smoke.R"
)

load_location_smoke_helpers <- function(path) {
  exprs <- parse(path)
  stop_at <- which(vapply(
    exprs,
    function(expr) {
      is.call(expr) &&
        identical(as.character(expr[[1L]]), "<-") &&
        identical(as.character(expr[[2L]]), "plan")
    },
    logical(1L)
  ))[1L]
  if (is.na(stop_at)) {
    stop(
      "Could not find location-smoke helper boundary in ",
      path,
      call. = FALSE
    )
  }
  for (i in seq_len(stop_at - 1L)) {
    eval(exprs[[i]], envir = .GlobalEnv)
  }
}

load_location_smoke_helpers(location_smoke_script)

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
status_path <- file.path(
  dashboard_dir,
  "structured-re-q4-location-slope-interval-diagnostic-status.tsv"
)
artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-24-q4-location-slope-bootstrap-budget-probe"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

artifact_path <- file.path(
  artifact_dir,
  "structured-re-q4-location-slope-bootstrap-budget-probe-results.tsv"
)
probe_path <- file.path(
  dashboard_dir,
  "structured-re-q4-location-slope-bootstrap-budget-probe.tsv"
)

status <- utils::read.delim(
  status_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)

providers <- c("phylo", "spatial", "animal", "relmat")
providers_to_run <- "phylo"
target_member <- "mu1:(Intercept)"
variant <- "strong"
spec <- variants[[variant]]

provider_label <- function(provider) {
  switch(
    provider,
    phylo = "Phylo",
    spatial = "Fixed-covariance spatial",
    animal = "Animal A-matrix",
    relmat = "Relmat K-matrix"
  )
}

provider_block_clause <- function(provider) {
  switch(
    provider,
    phylo = "",
    spatial = " no range-estimating spatial support,",
    animal = " no pedigree/Ainv bridge marshalling,",
    relmat = " no Q precision marshalling,"
  )
}

probe_claim_boundary <- function(provider, probe_status) {
  clean_text(paste(
    provider_label(provider),
    "q4 location one-slope bootstrap budget probe only;",
    "target =",
    target_member,
    "status =",
    probe_status,
    "with",
    provider_block_clause(provider),
    "no all-target bootstrap denominator, no derived-correlation intervals,",
    "no interval reliability, interval coverage, q4 REML, AI-REML,",
    "broad bridge support, public support, partial location-scale support,",
    "broader q8 support, or calibrated coverage wording promoted."
  ))
}

probe_next_gate <- function(probe_status) {
  if (identical(probe_status, "bootstrap_budget_probe_finite")) {
    return(
      paste(
        "Use Totoro or a reviewed DRAC/totoro dispatch plan for any all-16",
        "direct-SD bootstrap denominator runner; retain every target outcome",
        "before coverage-grid design."
      )
    )
  }
  paste(
    "Run provider-rotating bootstrap probes on Totoro or a reviewed",
    "DRAC/totoro dispatch plan before any all-target denominator or",
    "coverage-grid design."
  )
}

short_text <- function(x, max_chars = 500L) {
  x <- clean_text(x)
  long <- nchar(x) > max_chars
  x[long] <- paste0(substr(x[long], 1L, max_chars), "...[truncated]")
  x
}

probe_status_from_row <- function(row) {
  if (
    identical(row$method_status[[1L]], "finite") &&
      isTRUE(row$interval_finite[[1L]])
  ) {
    return("bootstrap_budget_probe_finite")
  }
  if (identical(row$method_status[[1L]], "error")) {
    return("bootstrap_budget_probe_error")
  }
  if (grepl("not_run", row$method_status[[1L]], fixed = TRUE)) {
    return("bootstrap_budget_probe_not_run_budget")
  }
  "bootstrap_budget_probe_nonfinite"
}

not_run_budget_row <- function() {
  data.frame(
    interval_method = "bootstrap",
    method_status = "not_run_after_phylo_budget_probe",
    interval_finite = FALSE,
    lower = NA_real_,
    upper = NA_real_,
    conf_status = "not_run_after_phylo_budget_probe",
    method_message = paste(
      "bootstrap omitted from this provider after the phylo probe exposed",
      "multi-minute runtime and a spatial precursor attempt exceeded the local",
      "turn budget"
    ),
    method_warnings = "NA",
    stringsAsFactors = FALSE
  )
}

method_rows <- list()
probe_rows <- list()

for (provider in providers) {
  message(
    "Fitting ",
    provider,
    " q4 location one-slope bootstrap probe model (variant=",
    variant,
    ")"
  )
  status_row <- status[
    status$structured_type == provider &
      status$endpoint_member == target_member,
    ,
    drop = FALSE
  ]
  if (nrow(status_row) != 1L) {
    stop(
      "Expected one status row for ",
      provider,
      " ",
      target_member,
      call. = FALSE
    )
  }
  if (!(provider %in% providers_to_run)) {
    message(
      "Skipping bootstrap for ",
      provider,
      " after the representative phylo budget probe"
    )
    rows <- not_run_budget_row()
    targets <- data.frame()
    target <- data.frame()
    target_found <- FALSE
    fit <- NULL
    fit_ok <- FALSE
    pdhess <- FALSE
  } else {
    sim <- make_provider_data(
      provider,
      seed = seeds[[provider]] + spec$seed_offset,
      n = spec$n,
      n_each = spec$n_each,
      sds = spec$sds
    )
    fit <- tryCatch(
      fit_provider_location_axis(provider, sim),
      error = function(e) e
    )
    if (inherits(fit, "error")) {
      message(
        "Fit failed for ",
        provider,
        ": ",
        clean_text(conditionMessage(fit))
      )
      rows <- fit_error_rows("bootstrap", conditionMessage(fit))
      targets <- data.frame()
    } else {
      message(
        "Fit done for ",
        provider,
        ": convergence=",
        fit$opt$convergence,
        ", pdHess=",
        isTRUE(fit$sdr$pdHess)
      )
      targets <- profile_targets(fit)
      if (!isTRUE(fit$sdr$pdHess)) {
        rows <- pdhess_blocked_rows("bootstrap")
      } else {
        message("  bootstrap ", provider, " ", target_member)
        rows <- run_interval(
          fit,
          status_row$profile_target[[1L]],
          method = "bootstrap"
        )
        message(
          "  bootstrap ",
          provider,
          " ",
          target_member,
          " -> ",
          rows$method_status[[1L]]
        )
      }
    }

    target <- if (inherits(fit, "error")) {
      data.frame()
    } else {
      targets[
        match(status_row$profile_target[[1L]], targets$parm),
        ,
        drop = FALSE
      ]
    }
    target_found <- nrow(target) == 1L &&
      identical(target$parm[[1L]], status_row$profile_target[[1L]])
    fit_ok <- !inherits(fit, "error") && identical(fit$opt$convergence, 0L)
    pdhess <- !inherits(fit, "error") && isTRUE(fit$sdr$pdHess)
  }

  probe_status <- probe_status_from_row(rows)

  rows$provider <- provider
  rows$variant <- variant
  rows$method_message <- short_text(rows$method_message)
  rows$method_warnings <- short_text(rows$method_warnings)
  rows$n_levels <- spec$n
  rows$n_each <- spec$n_each
  rows$endpoint_member <- status_row$endpoint_member[[1L]]
  rows$target_kind <- status_row$target_kind[[1L]]
  rows$estimand <- status_row$estimand[[1L]]
  rows$profile_target <- status_row$profile_target[[1L]]
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
  rows$convergence <- if (inherits(fit, "error")) {
    NA_integer_
  } else if (is.null(fit)) {
    NA_integer_
  } else {
    fit$opt$convergence
  }
  rows$pdHess <- pdhess
  rows$logLik <- if (inherits(fit, "error") || is.null(fit)) {
    NA_real_
  } else {
    as.numeric(stats::logLik(fit))
  }
  method_rows[[length(method_rows) + 1L]] <- rows

  probe_rows[[length(probe_rows) + 1L]] <- data.frame(
    probe_id = paste0(
      "q4_location_slope_bootstrap_budget_",
      provider,
      "_mu1_intercept"
    ),
    cell_id = status_row$cell_id[[1L]],
    formula_cell = status_row$formula_cell[[1L]],
    structured_type = provider,
    target_kind = status_row$target_kind[[1L]],
    endpoint_member = status_row$endpoint_member[[1L]],
    estimand = status_row$estimand[[1L]],
    profile_target = status_row$profile_target[[1L]],
    source_interval_status = "docs/dev-log/dashboard/structured-re-q4-location-slope-interval-diagnostic-status.tsv",
    source_interval_artifact = status_row$source_artifact[[1L]],
    source_bootstrap_artifact = file.path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q4-location-slope-bootstrap-budget-probe",
      "structured-re-q4-location-slope-bootstrap-budget-probe-results.tsv"
    ),
    bootstrap_replicates = 2L,
    bootstrap_seed = 41L,
    observed_target_rows = as.integer(target_found),
    n_fit_ok = as.integer(fit_ok),
    n_converged = as.integer(fit_ok),
    n_pdhess = as.integer(pdhess),
    bootstrap_status = rows$method_status[[1L]],
    bootstrap_finite = isTRUE(rows$interval_finite[[1L]]),
    bootstrap_lower = rows$lower[[1L]],
    bootstrap_upper = rows$upper[[1L]],
    conf_status = rows$conf_status[[1L]],
    method_message = rows$method_message[[1L]],
    method_warnings = rows$method_warnings[[1L]],
    estimate = if (target_found) target$estimate[[1L]] else NA_real_,
    profile_ready = if (target_found) target$profile_ready[[1L]] else FALSE,
    profile_note = if (target_found) {
      target$profile_note[[1L]]
    } else {
      NA_character_
    },
    probe_status = probe_status,
    denominator_status = "representative_bootstrap_probe_only",
    coverage_status = "not_evaluated",
    interval_claim_status = "diagnostic_only",
    status = "covered",
    evidence_url = "docs/dev-log/after-task/2026-06-24-q4-location-slope-bootstrap-budget-probe.md",
    claim_boundary = probe_claim_boundary(provider, probe_status),
    next_gate = probe_next_gate(probe_status),
    stringsAsFactors = FALSE
  )
}

method_out <- do.call(rbind, method_rows)
method_out <- method_out[
  c(
    "provider",
    "variant",
    "n_levels",
    "n_each",
    "endpoint_member",
    "target_kind",
    "estimand",
    "profile_target",
    "interval_method",
    "method_status",
    "interval_finite",
    "lower",
    "upper",
    "conf_status",
    "method_message",
    "method_warnings",
    "estimate",
    "profile_ready",
    "profile_note",
    "convergence",
    "pdHess",
    "logLik"
  )
]
probe_out <- do.call(rbind, probe_rows)

character_method_cols <- vapply(method_out, is.character, logical(1L))
method_out[character_method_cols] <- lapply(
  method_out[character_method_cols],
  clean_text
)
character_probe_cols <- vapply(probe_out, is.character, logical(1L))
probe_out[character_probe_cols] <- lapply(
  probe_out[character_probe_cols],
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
  probe_out,
  file = probe_path,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)

message("Wrote ", normalizePath(artifact_path, winslash = "/"))
message("Wrote ", normalizePath(probe_path, winslash = "/"))
