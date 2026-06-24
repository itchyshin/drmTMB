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

hessian_script <- file.path(
  repo_root,
  "tools",
  "run-structured-re-q4-slope-hessian-geometry.R"
)

load_hessian_helpers <- function(path) {
  exprs <- parse(path)
  stop_at <- which(vapply(
    exprs,
    function(expr) {
      is.call(expr) &&
        identical(as.character(expr[[1L]]), "<-") &&
        identical(as.character(expr[[2L]]), "rows")
    },
    logical(1L)
  ))[1L]
  if (is.na(stop_at)) {
    stop("Could not find Hessian helper boundary in ", path, call. = FALSE)
  }
  for (i in seq_len(stop_at - 1L)) {
    eval(exprs[[i]], envir = .GlobalEnv)
  }
}

load_hessian_helpers(hessian_script)

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
plan_path <- file.path(
  dashboard_dir,
  "structured-re-q4-location-slope-interval-diagnostic-plan.tsv"
)
artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  "2026-06-24-q4-location-slope-interval-smoke"
)
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

artifact_path <- file.path(
  artifact_dir,
  "structured-re-q4-location-slope-interval-smoke-results.tsv"
)
status_path <- file.path(
  dashboard_dir,
  "structured-re-q4-location-slope-interval-diagnostic-status.tsv"
)

fit_provider_location_axis <- function(provider, sim) {
  if (identical(provider, "phylo")) {
    tree <- sim$tree
    form <- bf(
      mu1 = y1 ~ x + phylo(1 + x | p | species, tree = tree),
      mu2 = y2 ~ x + phylo(1 + x | p | species, tree = tree),
      sigma1 = ~z,
      sigma2 = ~z,
      rho12 = ~1
    )
  } else if (identical(provider, "spatial")) {
    coords <- sim$coords
    form <- bf(
      mu1 = y1 ~ x + spatial(1 + x | p | site, coords = coords),
      mu2 = y2 ~ x + spatial(1 + x | p | site, coords = coords),
      sigma1 = ~z,
      sigma2 = ~z,
      rho12 = ~1
    )
  } else if (identical(provider, "animal")) {
    A <- sim$A
    form <- bf(
      mu1 = y1 ~ x + animal(1 + x | p | id, A = A),
      mu2 = y2 ~ x + animal(1 + x | p | id, A = A),
      sigma1 = ~z,
      sigma2 = ~z,
      rho12 = ~1
    )
  } else if (identical(provider, "relmat")) {
    K <- sim$K
    form <- bf(
      mu1 = y1 ~ x + relmat(1 + x | p | id, K = K),
      mu2 = y2 ~ x + relmat(1 + x | p | id, K = K),
      sigma1 = ~z,
      sigma2 = ~z,
      rho12 = ~1
    )
  } else {
    stop("Unknown provider: ", provider, call. = FALSE)
  }

  drmTMB(
    form,
    family = biv_gaussian(),
    data = sim$data,
    control = drm_control(
      fallback_optimizer = "BFGS",
      optimizer = list(eval.max = 1600, iter.max = 1600)
    )
  )
}

classify_interval_status <- function(rows) {
  finite_methods <- sort(rows$interval_method[rows$interval_finite])
  if (identical(finite_methods, c("bootstrap", "profile", "wald"))) {
    return("wald_profile_bootstrap_finite")
  }
  if (identical(finite_methods, c("bootstrap", "wald"))) {
    return("wald_bootstrap_finite_profile_failed")
  }
  if (identical(finite_methods, c("profile", "wald"))) {
    return("wald_profile_finite_bootstrap_failed")
  }
  if (identical(finite_methods, c("bootstrap", "profile"))) {
    return("profile_bootstrap_finite_wald_nonfinite")
  }
  if (identical(finite_methods, "wald")) {
    return("wald_only_finite")
  }
  if (identical(finite_methods, "profile")) {
    return("profile_only_finite")
  }
  if (identical(finite_methods, "bootstrap")) {
    return("bootstrap_only_finite_boundary")
  }
  if (length(finite_methods)) {
    return("partial_finite")
  }
  "no_finite_intervals"
}

classify_failure <- function(rows) {
  if (any(rows$method_status == "fit_error")) {
    return("fit_error")
  }
  if (any(rows$method_status == "not_run_pdhess_false")) {
    return("fit_pdhess_false")
  }
  if (any(rows$method_status == "not_run_smoke_budget")) {
    return("bootstrap_not_run_smoke_budget")
  }
  failures <- character()
  wald <- rows[rows$interval_method == "wald", , drop = FALSE]
  profile <- rows[rows$interval_method == "profile", , drop = FALSE]
  bootstrap <- rows[rows$interval_method == "bootstrap", , drop = FALSE]
  if (!isTRUE(wald$interval_finite[[1L]])) {
    failures <- c(failures, "wald_boundary_or_nonfinite")
  }
  if (!isTRUE(profile$interval_finite[[1L]])) {
    failures <- c(failures, "profile_failed_or_nonfinite")
  }
  if (!isTRUE(bootstrap$interval_finite[[1L]])) {
    failures <- c(failures, "bootstrap_failed_or_nonfinite")
  }
  if (!length(failures)) {
    return("none")
  }
  paste(failures, collapse = ";")
}

endpoint_token <- function(endpoint_member) {
  out <- gsub(":", "_", endpoint_member, fixed = TRUE)
  out <- gsub("(", "", out, fixed = TRUE)
  out <- gsub(")", "", out, fixed = TRUE)
  out <- gsub("+", "_", out, fixed = TRUE)
  gsub("_Intercept", "_intercept", out, fixed = TRUE)
}

provider_claim_label <- function(provider) {
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
    spatial = "no range-estimating spatial support;",
    animal = "no pedigree/Ainv bridge marshalling;",
    relmat = "no Q precision marshalling;"
  )
}

claim_boundary <- function(provider, interval_status) {
  clean_text(paste(
    provider_claim_label(provider),
    "q4 location one-slope direct-SD interval smoke only;",
    "status =",
    interval_status,
    "with derived-correlation intervals still blocked;",
    provider_block_clause(provider),
    "no interval reliability, interval coverage, q4 REML, AI-REML, broad bridge support,",
    "public support, partial location-scale support, broader q8 support,",
    "or calibrated coverage wording promoted."
  ))
}

next_gate <- function(interval_status) {
  if (identical(interval_status, "wald_profile_bootstrap_finite")) {
    return(
      "Repeat with replicated deterministic fixtures and denominator accounting before calibrated coverage wording."
    )
  }
  if (identical(interval_status, "wald_profile_finite_bootstrap_failed")) {
    return(
      "Run bounded bootstrap denominator smoke before denominator accounting or coverage-grid design."
    )
  }
  if (identical(interval_status, "no_finite_intervals")) {
    return(
      "Diagnose fit, boundary, and profile failures before denominator accounting or coverage-grid design."
    )
  }
  "Diagnose nonfinite or failed interval methods before denominator accounting or coverage-grid design."
}

bootstrap_budget_row <- function() {
  data.frame(
    interval_method = "bootstrap",
    method_status = "not_run_smoke_budget",
    interval_finite = FALSE,
    lower = NA_real_,
    upper = NA_real_,
    conf_status = "not_run_smoke_budget",
    method_message = paste(
      "bootstrap omitted from this bounded local smoke;",
      "replicated denominator or coverage runners must revisit this target"
    ),
    method_warnings = "NA",
    stringsAsFactors = FALSE
  )
}

status_for_target <- function(plan_row, rows, fit, target_found) {
  provider <- plan_row$structured_type[[1L]]
  endpoint_member <- plan_row$endpoint_member[[1L]]
  interval_status <- classify_interval_status(rows)
  failure_class <- classify_failure(rows)
  fit_ok <- !inherits(fit, "error") && identical(fit$opt$convergence, 0L)
  pdhess <- !inherits(fit, "error") && isTRUE(fit$sdr$pdHess)
  data.frame(
    diagnostic_id = paste0(
      "q4_location_slope_interval_status_",
      provider,
      "_",
      endpoint_token(endpoint_member)
    ),
    cell_id = plan_row$cell_id[[1L]],
    formula_cell = plan_row$formula_cell[[1L]],
    structured_type = provider,
    target_kind = plan_row$target_kind[[1L]],
    endpoint_member = endpoint_member,
    estimand = plan_row$estimand[[1L]],
    profile_target = plan_row$profile_target[[1L]],
    source_artifact = file.path(
      "docs",
      "dev-log",
      "simulation-artifacts",
      "2026-06-24-q4-location-slope-interval-smoke",
      "structured-re-q4-location-slope-interval-smoke-results.tsv"
    ),
    observed_target_rows = as.integer(target_found),
    n_fit_ok = as.integer(fit_ok),
    n_converged = as.integer(fit_ok),
    n_pdhess = as.integer(pdhess),
    n_finite_intervals = sum(rows$interval_finite),
    wald_status = rows$method_status[rows$interval_method == "wald"],
    profile_status = rows$method_status[rows$interval_method == "profile"],
    bootstrap_status = rows$method_status[rows$interval_method == "bootstrap"],
    interval_status = interval_status,
    failure_class = failure_class,
    interval_claim_status = "diagnostic_only",
    status = "covered",
    evidence_url = "docs/dev-log/after-task/2026-06-24-q4-location-slope-interval-smoke-status.md",
    claim_boundary = claim_boundary(provider, interval_status),
    next_gate = next_gate(interval_status),
    stringsAsFactors = FALSE
  )
}

plan <- utils::read.delim(
  plan_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
direct_plan <- plan[plan$target_kind == "direct_sd", , drop = FALSE]
providers <- c("phylo", "spatial", "animal", "relmat")
direct_plan$provider_order <- match(direct_plan$structured_type, providers)
direct_plan <- direct_plan[
  order(direct_plan$provider_order, direct_plan$diagnostic_id),
]
direct_plan$provider_order <- NULL

variant <- "strong"
spec <- variants[[variant]]
methods <- c("wald", "profile", "bootstrap")
smoke_methods <- c("wald", "profile")

method_rows <- list()
status_rows <- list()

for (provider in providers) {
  message(
    "Fitting ",
    provider,
    " q4 location one-slope smoke model (variant=",
    variant,
    ")"
  )
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
  } else {
    message(
      "Fit done for ",
      provider,
      ": convergence=",
      fit$opt$convergence,
      ", pdHess=",
      isTRUE(fit$sdr$pdHess)
    )
  }

  targets <- if (inherits(fit, "error")) {
    data.frame()
  } else {
    profile_targets(fit)
  }
  provider_plan <- direct_plan[
    direct_plan$structured_type == provider,
    ,
    drop = FALSE
  ]

  for (i in seq_len(nrow(provider_plan))) {
    plan_row <- provider_plan[i, , drop = FALSE]
    parm <- plan_row$profile_target[[1L]]
    target <- targets[match(parm, targets$parm), , drop = FALSE]
    target_found <- nrow(target) == 1L && identical(target$parm[[1L]], parm)

    rows <- if (inherits(fit, "error")) {
      fit_error_rows(methods, conditionMessage(fit))
    } else if (!isTRUE(fit$sdr$pdHess)) {
      message(
        "  interval ",
        provider,
        " ",
        plan_row$endpoint_member[[1L]],
        " blocked: pdHess=FALSE"
      )
      pdhess_blocked_rows(methods)
    } else {
      rbind(
        do.call(
          rbind,
          lapply(smoke_methods, function(method) {
            message(
              "  interval ",
              provider,
              " ",
              plan_row$endpoint_member[[1L]],
              " ",
              method
            )
            out <- run_interval(fit, parm, method)
            message(
              "  interval ",
              provider,
              " ",
              plan_row$endpoint_member[[1L]],
              " ",
              method,
              " -> ",
              out$method_status[[1L]]
            )
            out
          })
        ),
        bootstrap_budget_row()
      )
    }
    if (!inherits(fit, "error") && isTRUE(fit$sdr$pdHess)) {
      message(
        "  interval ",
        provider,
        " ",
        plan_row$endpoint_member[[1L]],
        " bootstrap -> not_run_smoke_budget"
      )
    }

    rows$provider <- provider
    rows$variant <- variant
    rows$n_levels <- spec$n
    rows$n_each <- spec$n_each
    rows$endpoint_member <- plan_row$endpoint_member[[1L]]
    rows$target_kind <- plan_row$target_kind[[1L]]
    rows$estimand <- plan_row$estimand[[1L]]
    rows$profile_target <- parm
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
    } else {
      fit$opt$convergence
    }
    rows$pdHess <- if (inherits(fit, "error")) {
      FALSE
    } else {
      isTRUE(fit$sdr$pdHess)
    }
    rows$logLik <- if (inherits(fit, "error")) {
      NA_real_
    } else {
      as.numeric(stats::logLik(fit))
    }
    method_rows[[length(method_rows) + 1L]] <- rows
    status_rows[[length(status_rows) + 1L]] <- status_for_target(
      plan_row,
      rows,
      fit,
      target_found
    )
  }
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
