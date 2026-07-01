#!/usr/bin/env Rscript
#
# Replicated animal q4 all-four one-slope admission diagnostic.
#
# This runner measures fit/Hessian/direct-SD interval finiteness for the animal
# q4 all-four one-slope Q-Series row. It is admission evidence only: coverage,
# inference_ready, supported, q8, REML, AI-REML, and broad bridge support are out
# of scope.

`%||%` <- function(x, y) if (is.null(x)) y else x

args <- commandArgs(trailingOnly = TRUE)
if (any(args %in% c("--help", "-h"))) {
  cat(
    paste(
      "Usage: Rscript tools/run-structured-re-q4-animal-all-four-admission-probe.R [options]",
      "",
      "Options:",
      "  --n-rep=N                 Number of replicate seeds (default: 16).",
      "  --seed-start=N            First replicate index (default: 1).",
      "  --replicate-indexes=a,b   Exact replicate indexes; overrides --n-rep/--seed-start.",
      "  --seed-base=N             Seed base; seed = seed_base + replicate index + variant offset (default: 910000).",
      "  --variant=a,b             Variants to run: strong,more_levels,all (default: more_levels).",
      "  --qgt2-parameterization=P Hidden q>2 route: unstructured,partial_cholesky (default: unstructured).",
      "  --methods=a,b             Interval methods to attempt: wald,profile (default: wald,profile).",
      "  --profile-max-eval=N      Endpoint profile max evaluations (default: 60).",
      "  --output-dir=PATH         Artifact directory; --out-dir is accepted as an alias.",
      "  --attempt-temp-install     Install current source into a temp library if needed.",
      "  --no-load-all              Disable local devtools::load_all fallback.",
      "  --overwrite=true          Replace an existing artifact directory.",
      "  --write-dashboard=false   Do not overwrite the dashboard sidecar.",
      "",
      "This is diagnostic/admission evidence only. It does not promote q4/q8",
      "interval coverage, inference_ready, supported, REML, AI-REML, or bridge support.",
      sep = "\n"
    ),
    "\n"
  )
  quit(status = 0L)
}

arg_value <- function(name, default = NULL) {
  dashed <- paste0("--", name, "=")
  underscored <- gsub("-", "_", dashed, fixed = TRUE)
  hit <- c(
    grep(paste0("^", dashed), args, value = TRUE),
    grep(paste0("^", underscored), args, value = TRUE)
  )
  if (!length(hit)) {
    return(default)
  }
  sub("^[^=]+=", "", hit[[length(hit)]])
}

arg_flag <- function(name, default = FALSE) {
  value <- arg_value(name, NULL)
  if (any(args %in% paste0("--", name))) {
    return(TRUE)
  }
  if (is.null(value)) {
    return(default)
  }
  tolower(value) %in% c("1", "true", "yes", "y")
}

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

write_tsv <- function(x, path) {
  character_cols <- vapply(x, is.character, logical(1L))
  x[character_cols] <- lapply(x[character_cols], clean_text)
  utils::write.table(
    x,
    file = path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA"
  )
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

n_rep <- as.integer(arg_value("n-rep", "16"))
if (!is.finite(n_rep) || n_rep < 1L) {
  stop("`--n-rep` must be a positive integer.", call. = FALSE)
}
seed_start <- as.integer(arg_value("seed-start", "1"))
if (!is.finite(seed_start) || seed_start < 1L) {
  stop("`--seed-start` must be a positive integer.", call. = FALSE)
}
replicate_indexes_arg <- arg_value("replicate-indexes", NULL)
if (is.null(replicate_indexes_arg)) {
  replicate_indexes <- seq.int(seed_start, length.out = n_rep)
} else {
  replicate_indexes <- as.integer(strsplit(
    replicate_indexes_arg,
    ",",
    fixed = TRUE
  )[[1L]])
  if (
    !length(replicate_indexes) ||
      any(!is.finite(replicate_indexes)) ||
      any(replicate_indexes < 1L)
  ) {
    stop(
      "`--replicate-indexes` must be a comma-separated list of positive integers.",
      call. = FALSE
    )
  }
  n_rep <- length(replicate_indexes)
}
seed_base <- as.integer(arg_value("seed-base", "910000"))
if (!is.finite(seed_base) || seed_base < 1L) {
  stop("`--seed-base` must be a positive integer.", call. = FALSE)
}
profile_max_eval <- as.integer(arg_value("profile-max-eval", "60"))
if (!is.finite(profile_max_eval) || profile_max_eval < 1L) {
  stop("`--profile-max-eval` must be a positive integer.", call. = FALSE)
}
overwrite <- arg_flag("overwrite", FALSE)
write_dashboard <- arg_flag("write-dashboard", TRUE)

variant_arg <- strsplit(
  arg_value("variant", "more_levels"),
  ",",
  fixed = TRUE
)[[1L]]
variant_arg <- trimws(variant_arg[nzchar(trimws(variant_arg))])
if (identical(variant_arg, "all")) {
  variant_arg <- c("strong", "more_levels")
}
method_arg <- strsplit(
  arg_value("methods", "wald,profile"),
  ",",
  fixed = TRUE
)[[1L]]
method_arg <- trimws(method_arg[nzchar(trimws(method_arg))])
if (!length(method_arg) || any(!method_arg %in% c("wald", "profile"))) {
  stop("`--methods` must contain only `wald` and/or `profile`.", call. = FALSE)
}
qgt2_parameterization <- arg_value("qgt2-parameterization", "unstructured")
if (!qgt2_parameterization %in% c("unstructured", "partial_cholesky")) {
  stop(
    "`--qgt2-parameterization` must be `unstructured` or `partial_cholesky`.",
    call. = FALSE
  )
}
if (
  identical(qgt2_parameterization, "partial_cholesky") &&
    isTRUE(write_dashboard)
) {
  stop(
    paste(
      "The hidden partial_cholesky route must be written as an artifact-only",
      "diagnostic. Re-run with --write-dashboard=false."
    ),
    call. = FALSE
  )
}
attempt_temp_install <- arg_flag("attempt-temp-install", FALSE)
allow_load_all <- !arg_flag("no-load-all", FALSE)

artifact_route <- if (identical(qgt2_parameterization, "partial_cholesky")) {
  "q4-animal-partial-correlation-admission-probe-local"
} else {
  "q4-animal-all-four-admission-probe-local"
}
default_artifact_dir <- file.path(
  repo_root,
  "docs",
  "dev-log",
  "simulation-artifacts",
  paste0("2026-06-29-", artifact_route)
)
artifact_dir_arg <- arg_value(
  "output-dir",
  arg_value("out-dir", default_artifact_dir)
)
artifact_dir <- normalizePath(artifact_dir_arg, mustWork = FALSE)
if (dir.exists(artifact_dir) && !overwrite) {
  stop(
    "`output-dir` already exists. Use --overwrite=true to replace it: ",
    artifact_dir,
    call. = FALSE
  )
}
if (dir.exists(artifact_dir) && overwrite) {
  unlink(artifact_dir, recursive = TRUE)
}
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)

dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
dashboard_path <- file.path(
  dashboard_dir,
  "structured-re-q4-animal-all-four-admission-probe.tsv"
)
replicate_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-all-four-admission-probe-replicates.tsv"
)
fit_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-all-four-admission-probe-fit-status.tsv"
)
target_summary_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-all-four-admission-probe-target-summary.tsv"
)
run_log_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-all-four-admission-probe-run-log.tsv"
)
seed_manifest_path <- file.path(
  artifact_dir,
  "structured-re-q4-animal-all-four-admission-probe-seed-manifest.tsv"
)
session_info_path <- file.path(artifact_dir, "sessionInfo.txt")
git_sha_path <- file.path(artifact_dir, "git-sha.txt")

source_q4_stability_prefix <- function() {
  runner <- file.path(
    repo_root,
    "tools",
    "run-structured-re-q4-slope-interval-stability-probe.R"
  )
  src <- readLines(runner, warn = FALSE)
  src <- src[!grepl("^devtools::load_all\\(", src)]
  main_line <- grep("^plan\\s*<-\\s*utils::read.delim", src)[1L]
  if (!is.finite(main_line)) {
    stop("Could not find q4 stability probe main entrypoint.", call. = FALSE)
  }
  tmp <- tempfile(fileext = ".R")
  writeLines(src[seq_len(main_line - 1L)], tmp)
  source(tmp, local = .GlobalEnv)
  invisible(TRUE)
}

load_drmTMB_for_admission <- function(attempt_temp_install, allow_load_all) {
  if (isTRUE(allow_load_all) && requireNamespace("devtools", quietly = TRUE)) {
    loaded_source <- tryCatch(
      {
        suppressPackageStartupMessages(devtools::load_all(
          repo_root,
          quiet = TRUE
        ))
        list(
          ok = TRUE,
          status = "devtools_load_all",
          detail = "loaded current source with devtools::load_all"
        )
      },
      error = function(e) {
        list(
          ok = FALSE,
          status = "devtools_load_all_failed",
          detail = clean_text(conditionMessage(e))
        )
      }
    )
    if (isTRUE(loaded_source$ok)) {
      return(loaded_source)
    }
  }

  if (requireNamespace("drmTMB", quietly = TRUE)) {
    suppressPackageStartupMessages(library(drmTMB))
    return(list(
      ok = TRUE,
      status = "installed_namespace_loaded",
      detail = "loaded drmTMB from .libPaths()"
    ))
  }

  if (!attempt_temp_install) {
    return(list(
      ok = FALSE,
      status = "package_not_installed",
      detail = paste(
        "drmTMB not loadable and --attempt-temp-install not requested"
      )
    ))
  }

  temp_lib <- tempfile("drmTMB-q4-animal-lib-")
  dir.create(temp_lib, recursive = TRUE, showWarnings = FALSE)
  output <- tryCatch(
    system2(
      file.path(R.home("bin"), "R"),
      c(
        "CMD",
        "INSTALL",
        "--no-init-file",
        "--preclean",
        shQuote(paste0("--library=", temp_lib)),
        shQuote(repo_root)
      ),
      stdout = TRUE,
      stderr = TRUE
    ),
    error = function(e) conditionMessage(e)
  )
  if (!requireNamespace("drmTMB", lib.loc = temp_lib, quietly = TRUE)) {
    return(list(
      ok = FALSE,
      status = "temp_install_failed",
      detail = clean_text(paste(tail(output, 12L), collapse = " "))
    ))
  }
  .libPaths(c(temp_lib, .libPaths()))
  suppressPackageStartupMessages(library(drmTMB))
  list(
    ok = TRUE,
    status = "temp_install_loaded",
    detail = "temporary_library_current_source"
  )
}

load_result <- load_drmTMB_for_admission(attempt_temp_install, allow_load_all)
message("[q4-animal-admission] load_status=", load_result$status)
if (!isTRUE(load_result$ok)) {
  stop(load_result$detail, call. = FALSE)
}
old_qgt2_parameterization <- options(
  drmTMB.internal.qgt2_corr_parameterization = qgt2_parameterization
)
on.exit(options(old_qgt2_parameterization), add = TRUE)
message(
  "[q4-animal-admission] qgt2_parameterization=",
  qgt2_parameterization
)
source_q4_stability_prefix()
artifact_dir <- normalizePath(artifact_dir_arg, mustWork = FALSE)

q4_variants <- list(
  strong = list(
    seed_offset = 0L,
    n = 8L,
    n_each = 24L,
    sds = c(
      mu1_intercept = 0.70,
      mu1_x = 0.48,
      mu2_intercept = 0.62,
      mu2_x = 0.44,
      sigma1_intercept = 0.50,
      sigma1_x = 0.34,
      sigma2_intercept = 0.46,
      sigma2_x = 0.30
    )
  ),
  more_levels = list(
    seed_offset = 100000L,
    n = 16L,
    n_each = 12L,
    sds = c(
      mu1_intercept = 0.62,
      mu1_x = 0.42,
      mu2_intercept = 0.56,
      mu2_x = 0.38,
      sigma1_intercept = 0.42,
      sigma1_x = 0.28,
      sigma2_intercept = 0.40,
      sigma2_x = 0.26
    )
  )
)
if (any(!variant_arg %in% names(q4_variants))) {
  stop(
    "`--variant` must be one or more of: ",
    paste(names(q4_variants), collapse = ", "),
    call. = FALSE
  )
}

plan <- utils::read.delim(
  plan_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
direct_plan <- plan[
  plan$structured_type == "animal" & plan$target_kind == "direct_sd",
  ,
  drop = FALSE
]
direct_plan <- direct_plan[order(direct_plan$diagnostic_id), , drop = FALSE]
if (nrow(direct_plan) != 8L) {
  stop("Expected exactly eight animal q4 direct-SD targets.", call. = FALSE)
}

run_interval_admission <- function(fit, parm, method) {
  warnings <- character()
  result <- withCallingHandlers(
    tryCatch(
      {
        conf_args <- list(
          object = fit,
          parm = parm,
          method = method,
          level = 0.70
        )
        if (identical(method, "profile")) {
          conf_args <- c(
            conf_args,
            list(
              profile_engine = "endpoint",
              trace = FALSE,
              profile_endpoint_max_eval = profile_max_eval
            )
          )
        }
        do.call(stats::confint, conf_args)
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

safe_loglik <- function(fit) {
  tryCatch(as.numeric(stats::logLik(fit)), error = function(e) NA_real_)
}

safe_profile_targets <- function(fit) {
  tryCatch(profile_targets(fit), error = function(e) {
    data.frame(profile_target_error = clean_text(conditionMessage(e)))
  })
}

endpoint_token <- function(endpoint_member) {
  out <- gsub(":", "_", endpoint_member, fixed = TRUE)
  out <- gsub("(", "", out, fixed = TRUE)
  out <- gsub(")", "", out, fixed = TRUE)
  gsub("_Intercept", "_intercept", out, fixed = TRUE)
}

format_rate <- function(num, den) {
  if (!is.finite(den) || den <= 0) {
    return("NA")
  }
  sprintf("%.3f", num / den)
}

diagnostic_verdict <- function(
  n_rep,
  n_fit_ok,
  n_pdhess,
  n_profile_finite,
  n_target_rep_rows
) {
  if (n_fit_ok < n_rep) {
    return("fit_failures_retained")
  }
  if (n_pdhess / n_rep < 0.95) {
    return("pdhess_admission_blocked")
  }
  if (n_rep < 16L) {
    return("smoke_only_insufficient_denominator")
  }
  if (n_profile_finite / n_target_rep_rows < 0.95) {
    return("profile_finite_admission_blocked")
  }
  "admission_diagnostic_passed_not_inference"
}

claim_boundary_text <- paste(
  "Animal q4 all-four one-slope admission probe only:",
  "direct-SD fit, pdHess, and interval-finiteness diagnostics;",
  paste0("q>2 route is ", qgt2_parameterization, ";"),
  "no coverage evidence, no inference_ready, no supported, no q8 inference,",
  "no q4 REML, no REML, no AI-REML, no broad q4 bridge support,",
  "and derived-correlation intervals remain blocked."
)

next_gate_text <- function(verdict) {
  if (identical(verdict, "smoke_only_insufficient_denominator")) {
    return(
      paste(
        "If smoke remains deterministic, run Totoro first or Nibi/Rorqual only",
        "for a 16-32 replicate admission tranche; keep coverage not_evaluable",
        "until pdHess and finite direct-SD interval rates pass."
      )
    )
  }
  if (identical(verdict, "admission_diagnostic_passed_not_inference")) {
    return(
      paste(
        "Ask Fisher/Rose to review denominator retention, then design an",
        "MCSE-calibrated q4 coverage grid; do not use this probe as coverage",
        "or support evidence."
      )
    )
  }
  paste(
    "Diagnose retained fit, pdHess, or profile-finiteness blockers before",
    "any q4 coverage-grid design; do not use DRAC for larger grids until",
    "local or Totoro evidence is insufficient."
  )
}

fit_rows <- list()
method_rows <- list()
seed_rows <- list()
summary_prefix <- if (identical(qgt2_parameterization, "partial_cholesky")) {
  "q4_animal_partial_cholesky_admission"
} else {
  "q4_animal_all_four_admission"
}

for (variant in variant_arg) {
  spec <- q4_variants[[variant]]
  for (replicate_index in replicate_indexes) {
    seed <- seed_base + replicate_index + spec$seed_offset
    seed_rows[[length(seed_rows) + 1L]] <- data.frame(
      variant = variant,
      qgt2_parameterization = qgt2_parameterization,
      replicate_index = replicate_index,
      seed = seed,
      n_levels = spec$n,
      n_each = spec$n_each,
      stringsAsFactors = FALSE
    )
    message(
      "Fitting animal q4 all-four admission replicate ",
      replicate_index,
      " (",
      variant,
      ", seed ",
      seed,
      ")"
    )
    sim <- make_provider_data(
      "animal",
      seed = seed,
      n = spec$n,
      n_each = spec$n_each,
      sds = spec$sds
    )
    fit <- tryCatch(fit_provider("animal", sim), error = function(e) e)
    fit_error <- inherits(fit, "error")
    convergence <- if (fit_error) NA_integer_ else fit$opt$convergence
    fit_ok <- !fit_error && identical(convergence, 0L)
    pdhess <- !fit_error && isTRUE(fit$sdr$pdHess)
    loglik <- if (fit_error) NA_real_ else safe_loglik(fit)
    fit_message <- if (fit_error) {
      clean_text(conditionMessage(fit))
    } else {
      "ok"
    }
    fit_rows[[length(fit_rows) + 1L]] <- data.frame(
      variant = variant,
      qgt2_parameterization = qgt2_parameterization,
      replicate_index = replicate_index,
      seed = seed,
      n_levels = spec$n,
      n_each = spec$n_each,
      fit_error = fit_error,
      fit_ok = fit_ok,
      convergence = convergence,
      pdHess = pdhess,
      logLik = loglik,
      fit_message = fit_message,
      stringsAsFactors = FALSE
    )

    targets <- if (fit_error) data.frame() else safe_profile_targets(fit)
    if (!fit_error && !("parm" %in% names(targets))) {
      fit_message <- paste(
        "profile_targets failed:",
        paste(names(targets), collapse = ",")
      )
    }

    for (i in seq_len(nrow(direct_plan))) {
      plan_row <- direct_plan[i, , drop = FALSE]
      parm <- plan_row$profile_target[[1L]]
      target <- if ("parm" %in% names(targets)) {
        targets[match(parm, targets$parm), , drop = FALSE]
      } else {
        data.frame()
      }
      target_found <- nrow(target) == 1L && identical(target$parm[[1L]], parm)
      interval_rows <- if (fit_error) {
        fit_error_rows(method_arg, fit_message)
      } else if (!pdhess) {
        pdhess_blocked_rows(method_arg)
      } else {
        do.call(
          rbind,
          lapply(method_arg, function(method) {
            message(
              "  interval animal ",
              plan_row$endpoint_member[[1L]],
              " ",
              method
            )
            run_interval_admission(fit, parm, method)
          })
        )
      }
      interval_rows$variant <- variant
      interval_rows$qgt2_parameterization <- qgt2_parameterization
      interval_rows$replicate_index <- replicate_index
      interval_rows$seed <- seed
      interval_rows$cell_id <- plan_row$cell_id[[1L]]
      interval_rows$formula_cell <- plan_row$formula_cell[[1L]]
      interval_rows$structured_type <- "animal"
      interval_rows$target_kind <- plan_row$target_kind[[1L]]
      interval_rows$endpoint_member <- plan_row$endpoint_member[[1L]]
      interval_rows$estimand <- plan_row$estimand[[1L]]
      interval_rows$profile_target <- parm
      interval_rows$target_found <- target_found
      interval_rows$estimate <- if (target_found) {
        target$estimate[[1L]]
      } else {
        NA_real_
      }
      interval_rows$profile_ready <- if (target_found) {
        target$profile_ready[[1L]]
      } else {
        FALSE
      }
      interval_rows$profile_note <- if (target_found) {
        target$profile_note[[1L]]
      } else {
        NA_character_
      }
      interval_rows$n_levels <- spec$n
      interval_rows$n_each <- spec$n_each
      interval_rows$intended_sd_mu1_intercept <- spec$sds[["mu1_intercept"]]
      interval_rows$intended_sd_mu1_x <- spec$sds[["mu1_x"]]
      interval_rows$intended_sd_mu2_intercept <- spec$sds[["mu2_intercept"]]
      interval_rows$intended_sd_mu2_x <- spec$sds[["mu2_x"]]
      interval_rows$intended_sd_sigma1_intercept <- spec$sds[[
        "sigma1_intercept"
      ]]
      interval_rows$intended_sd_sigma1_x <- spec$sds[["sigma1_x"]]
      interval_rows$intended_sd_sigma2_intercept <- spec$sds[[
        "sigma2_intercept"
      ]]
      interval_rows$intended_sd_sigma2_x <- spec$sds[["sigma2_x"]]
      interval_rows$fit_ok <- fit_ok
      interval_rows$convergence <- convergence
      interval_rows$pdHess <- pdhess
      interval_rows$logLik <- loglik
      method_rows[[length(method_rows) + 1L]] <- interval_rows
    }
  }
}

fit_out <- do.call(rbind, fit_rows)
method_out <- do.call(rbind, method_rows)
seed_out <- do.call(rbind, seed_rows)

method_out <- method_out[
  c(
    "variant",
    "qgt2_parameterization",
    "replicate_index",
    "seed",
    "cell_id",
    "formula_cell",
    "structured_type",
    "target_kind",
    "endpoint_member",
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
    "target_found",
    "estimate",
    "profile_ready",
    "profile_note",
    "fit_ok",
    "convergence",
    "pdHess",
    "logLik",
    "n_levels",
    "n_each",
    "intended_sd_mu1_intercept",
    "intended_sd_mu1_x",
    "intended_sd_mu2_intercept",
    "intended_sd_mu2_x",
    "intended_sd_sigma1_intercept",
    "intended_sd_sigma1_x",
    "intended_sd_sigma2_intercept",
    "intended_sd_sigma2_x"
  )
]

summary_rows <- list()
dashboard_rows <- list()
for (variant in variant_arg) {
  variant_methods <- method_out[method_out$variant == variant, , drop = FALSE]
  variant_fits <- fit_out[fit_out$variant == variant, , drop = FALSE]
  n_fit_ok <- sum(variant_fits$fit_ok)
  n_pdhess <- sum(variant_fits$pdHess)
  for (endpoint_member in unique(variant_methods$endpoint_member)) {
    target_rows <- variant_methods[
      variant_methods$endpoint_member == endpoint_member,
      ,
      drop = FALSE
    ]
    wald <- target_rows[target_rows$interval_method == "wald", , drop = FALSE]
    profile <- target_rows[
      target_rows$interval_method == "profile",
      ,
      drop = FALSE
    ]
    n_target_rep <- length(unique(target_rows$replicate_index))
    n_profile_finite <- sum(profile$interval_finite %in% TRUE)
    verdict <- diagnostic_verdict(
      n_target_rep,
      n_fit_ok,
      n_pdhess,
      n_profile_finite,
      n_target_rep
    )
    summary_rows[[length(summary_rows) + 1L]] <- data.frame(
      summary_id = paste0(
        summary_prefix,
        "_",
        variant,
        "_",
        endpoint_token(endpoint_member)
      ),
      cell_id = target_rows$cell_id[[1L]],
      variant = variant,
      qgt2_parameterization = qgt2_parameterization,
      structured_type = "animal",
      endpoint_member = endpoint_member,
      estimand = target_rows$estimand[[1L]],
      profile_target = target_rows$profile_target[[1L]],
      n_rep = n_target_rep,
      n_fit_ok = n_fit_ok,
      n_pdhess = n_pdhess,
      pdhess_rate = format_rate(n_pdhess, n_target_rep),
      n_target_found = sum(
        target_rows$target_found[
          target_rows$interval_method == method_arg[[1L]]
        ] %in%
          TRUE
      ),
      n_wald_finite = sum(wald$interval_finite %in% TRUE),
      wald_finite_rate = format_rate(
        sum(wald$interval_finite %in% TRUE),
        n_target_rep
      ),
      n_profile_attempted = nrow(profile),
      n_profile_finite = n_profile_finite,
      profile_finite_rate = format_rate(n_profile_finite, n_target_rep),
      n_profile_nonfinite = sum(
        profile$method_status %in% c("nonfinite", "error")
      ),
      admission_status = verdict,
      interval_claim_status = "diagnostic_only",
      coverage_status = "not_evaluable",
      claim_boundary = claim_boundary_text,
      next_gate = next_gate_text(verdict),
      stringsAsFactors = FALSE
    )
  }

  n_target_rep_rows <- length(unique(variant_methods$replicate_index)) *
    length(unique(variant_methods$endpoint_member))
  n_profile_finite_all <- sum(
    variant_methods$interval_method == "profile" &
      variant_methods$interval_finite %in% TRUE
  )
  verdict <- diagnostic_verdict(
    n_rep,
    n_fit_ok,
    n_pdhess,
    n_profile_finite_all,
    n_target_rep_rows
  )
  dashboard_rows[[length(dashboard_rows) + 1L]] <- data.frame(
    probe_id = paste0("q4_animal_all_four_admission_", variant),
    cell_id = "qseries_animal_q4_all_four_one_slope_planned",
    widget_state = "high_q_diagnostic",
    variant = variant,
    structured_type = "animal",
    dimension_pattern = "q4",
    target_scope = "all_four_direct_sd",
    n_rep = n_rep,
    n_direct_targets = length(unique(variant_methods$endpoint_member)),
    n_target_rep_rows = n_target_rep_rows,
    n_fit_ok = n_fit_ok,
    n_pdhess = n_pdhess,
    pdhess_rate = format_rate(n_pdhess, n_rep),
    n_wald_finite = sum(
      variant_methods$interval_method == "wald" &
        variant_methods$interval_finite %in% TRUE
    ),
    wald_finite_rate = format_rate(
      sum(
        variant_methods$interval_method == "wald" &
          variant_methods$interval_finite %in% TRUE
      ),
      n_target_rep_rows
    ),
    n_profile_attempted = sum(variant_methods$interval_method == "profile"),
    n_profile_finite = n_profile_finite_all,
    profile_finite_rate = format_rate(n_profile_finite_all, n_target_rep_rows),
    n_profile_nonfinite = sum(
      variant_methods$interval_method == "profile" &
        variant_methods$method_status %in% c("nonfinite", "error")
    ),
    admission_status = verdict,
    interval_claim_status = "diagnostic_only",
    coverage_status = "not_evaluable",
    status = "covered",
    source_artifact = paste(
      "docs/dev-log/simulation-artifacts",
      basename(artifact_dir),
      "structured-re-q4-animal-all-four-admission-probe-replicates.tsv",
      sep = "/"
    ),
    evidence_url = "docs/dev-log/after-task/2026-06-29-q-series-q4-animal-all-four-admission-probe.md",
    claim_boundary = claim_boundary_text,
    next_gate = next_gate_text(verdict),
    stringsAsFactors = FALSE
  )
}

summary_out <- do.call(rbind, summary_rows)
dashboard_out <- do.call(rbind, dashboard_rows)
run_log <- data.frame(
  log_id = "q4_animal_all_four_admission_probe",
  timestamp_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  n_rep = n_rep,
  seed_start = if (is.null(replicate_indexes_arg)) seed_start else NA_integer_,
  replicate_indexes = paste(replicate_indexes, collapse = ","),
  seed_base = seed_base,
  variants = paste(variant_arg, collapse = ","),
  qgt2_parameterization = qgt2_parameterization,
  methods = paste(method_arg, collapse = ","),
  profile_max_eval = profile_max_eval,
  load_status = load_result$status,
  load_detail = load_result$detail,
  output_dir = artifact_dir,
  dashboard_output = if (write_dashboard) dashboard_path else "not_written",
  claim_boundary = claim_boundary_text,
  next_gate = paste(unique(dashboard_out$next_gate), collapse = " | "),
  stringsAsFactors = FALSE
)

write_tsv(seed_out, seed_manifest_path)
write_tsv(fit_out, fit_path)
write_tsv(method_out, replicate_path)
write_tsv(summary_out, target_summary_path)
write_tsv(run_log, run_log_path)
if (write_dashboard) {
  write_tsv(dashboard_out, dashboard_path)
}

git_sha <- tryCatch(
  {
    old_wd <- setwd(repo_root)
    on.exit(setwd(old_wd), add = TRUE)
    out <- system2(
      "git",
      c("rev-parse", "HEAD"),
      stdout = TRUE,
      stderr = FALSE
    )
    if (!length(out)) "unknown" else out[[1L]]
  },
  error = function(e) "unknown"
)
writeLines(git_sha, git_sha_path)
writeLines(capture.output(sessionInfo()), session_info_path)

message("Wrote replicate artifact: ", replicate_path)
message("Wrote target summary: ", target_summary_path)
if (write_dashboard) {
  message("Wrote dashboard sidecar: ", dashboard_path)
}
