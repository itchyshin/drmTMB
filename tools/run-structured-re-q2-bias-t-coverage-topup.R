#!/usr/bin/env Rscript
#
# q2 spatial/animal bias+t coverage top-up runner.
#
# This runner measures the deployment-default location-axis small-sample
# interval channel for the blocked spatial/animal q2 mu-slope SD endpoints.
# It is intentionally endpoint-only: q2 correlation targets, support labels,
# REML, AI-REML, q4/q8, and public-support wording are out of scope.

`%||%` <- function(x, y) if (is.null(x)) y else x

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

write_tsv <- function(x, path) {
  utils::write.table(
    x,
    path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA"
  )
}

append_tsv <- function(x, path) {
  file_existed <- file.exists(path)
  utils::write.table(
    x,
    path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA",
    append = file_existed,
    col.names = !file_existed
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

usage <- function() {
  cat(
    paste(
      "Usage: Rscript tools/run-structured-re-q2-bias-t-coverage-topup.R [options]",
      "",
      "Options:",
      "  --shard=N                  Shard 1..4 (required).",
      "  --n_rep=N                  Number of top-up replicate seeds (default: 525).",
      "  --seed_start=N             First top-up seed (default: 730476).",
      "  --n_each=N                 Observations per group (default: 20).",
      "  --out_dir=PATH             Output directory.",
      "  --attempt-temp-install     Install current source into a temp library if needed.",
      "  --no-load-all              Disable local devtools::load_all fallback.",
      "  -h, --help                 Show this help.",
      "",
      "Shard map:",
      "  1 spatial mu1:x",
      "  2 spatial mu2:x",
      "  3 animal  mu1:x",
      "  4 animal  mu2:x",
      sep = "\n"
    )
  )
}

parse_args <- function(args) {
  out <- list(
    shard = NA_integer_,
    n_rep = 525L,
    seed_start = 730476L,
    n_each = 20L,
    out_dir = NA_character_,
    attempt_temp_install = FALSE,
    allow_load_all = TRUE
  )
  for (arg in args) {
    if (arg %in% c("-h", "--help")) {
      usage()
      quit(status = 0L)
    } else if (startsWith(arg, "--shard=")) {
      out$shard <- as.integer(sub("^--shard=", "", arg))
    } else if (startsWith(arg, "--n_rep=")) {
      out$n_rep <- as.integer(sub("^--n_rep=", "", arg))
    } else if (startsWith(arg, "--seed_start=")) {
      out$seed_start <- as.integer(sub("^--seed_start=", "", arg))
    } else if (startsWith(arg, "--n_each=")) {
      out$n_each <- as.integer(sub("^--n_each=", "", arg))
    } else if (startsWith(arg, "--out_dir=")) {
      out$out_dir <- sub("^--out_dir=", "", arg)
    } else if (identical(arg, "--attempt-temp-install")) {
      out$attempt_temp_install <- TRUE
    } else if (identical(arg, "--no-load-all")) {
      out$allow_load_all <- FALSE
    } else {
      stop("Unknown argument: ", arg, call. = FALSE)
    }
  }
  if (!is.finite(out$shard) || out$shard < 1L || out$shard > 4L) {
    stop("`--shard` must be an integer from 1 to 4.", call. = FALSE)
  }
  if (!is.finite(out$n_rep) || out$n_rep < 1L) {
    stop("`--n_rep` must be a positive integer.", call. = FALSE)
  }
  if (!is.finite(out$seed_start) || out$seed_start < 1L) {
    stop("`--seed_start` must be a positive integer.", call. = FALSE)
  }
  if (!is.finite(out$n_each) || out$n_each < 1L) {
    stop("`--n_each` must be a positive integer.", call. = FALSE)
  }
  out
}

source_q2_runner_prefix <- function() {
  runner <- file.path(
    repo_root,
    "tools",
    "run-structured-re-q2-slope-coverage-grid.R"
  )
  src <- readLines(runner, warn = FALSE)
  main_line <- grep("^args\\s*<-\\s*parse_args", src)[1L]
  if (!is.finite(main_line)) {
    stop("Could not find q2 coverage runner main entrypoint.", call. = FALSE)
  }
  tmp <- tempfile(fileext = ".R")
  writeLines(src[seq_len(main_line - 1L)], tmp)
  source(tmp, local = .GlobalEnv)
  invisible(TRUE)
}

load_drmTMB_for_topup <- function(attempt_temp_install, allow_load_all) {
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
  loaded <- try_load_drmTMB(attempt_temp_install)
  if (isTRUE(loaded$ok)) {
    return(loaded)
  }
  loaded
}

TOPUP_MAP <- data.frame(
  shard = 1:4,
  provider = c("spatial", "spatial", "animal", "animal"),
  target = c("mu1:x", "mu2:x", "mu1:x", "mu2:x"),
  linked_cell_id = c(
    "qseries_spatial_q2_mu1_mu2_one_slope",
    "qseries_spatial_q2_mu1_mu2_one_slope",
    "qseries_animal_q2_mu1_mu2_one_slope",
    "qseries_animal_q2_mu1_mu2_one_slope"
  ),
  stringsAsFactors = FALSE
)

target_token <- function(target) {
  gsub("[^A-Za-z0-9]+", "_", target)
}

contains_truth <- function(truth, lower, upper) {
  if (is.finite(lower) && is.finite(upper)) {
    truth >= lower & truth <= upper
  } else {
    NA
  }
}

run_interval <- function(fit, parm, bias_t = FALSE) {
  warnings_cap <- character()
  result <- withCallingHandlers(
    tryCatch(
      {
        if (isTRUE(bias_t)) {
          stats::confint(
            fit,
            parm = parm,
            method = "wald",
            small_sample_df = "group",
            bias_correct = "group"
          )
        } else {
          stats::confint(fit, parm = parm, method = "wald")
        }
      },
      error = function(e) e
    ),
    warning = function(w) {
      warnings_cap <<- c(warnings_cap, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  if (inherits(result, "error")) {
    return(list(
      lower = NA_real_,
      upper = NA_real_,
      status = "error",
      message = clean_text(conditionMessage(result)),
      warnings = clean_text(paste(warnings_cap, collapse = "; "))
    ))
  }
  lower <- result$lower[[1L]]
  upper <- result$upper[[1L]]
  list(
    lower = lower,
    upper = upper,
    status = if (is.finite(lower) && is.finite(upper)) {
      "finite"
    } else {
      "nonfinite"
    },
    message = NA_character_,
    warnings = clean_text(paste(warnings_cap, collapse = "; "))
  )
}

topup_empty_row <- function(
  seed,
  rep_id,
  provider,
  target,
  linked_cell_id,
  status,
  msg
) {
  parm <- parm_name_for(provider, target)
  truth <- truth_for(target)
  data.frame(
    replicate_id = rep_id,
    seed = seed,
    linked_cell_id = linked_cell_id,
    provider = provider,
    target = target,
    target_parm = parm,
    truth_value = truth,
    attempt_status = status,
    message = clean_text(msg),
    convergence = NA_integer_,
    pdHess = NA,
    estimate = NA_real_,
    wald_lower = NA_real_,
    wald_upper = NA_real_,
    wald_status = NA_character_,
    wald_message = NA_character_,
    wald_warnings = NA_character_,
    wald_contains = NA,
    bias_t_lower = NA_real_,
    bias_t_upper = NA_real_,
    bias_t_status = NA_character_,
    bias_t_message = NA_character_,
    bias_t_warnings = NA_character_,
    bias_t_contains = NA,
    elapsed_sec = NA_real_,
    stringsAsFactors = FALSE
  )
}

run_one_topup_rep <- function(
  seed,
  rep_id,
  provider,
  target,
  linked_cell_id,
  n_each
) {
  parm <- parm_name_for(provider, target)
  truth <- truth_for(target)
  sim <- tryCatch(
    make_q2_slope_data(provider, seed, n_each),
    error = function(e) e
  )
  if (inherits(sim, "error")) {
    return(topup_empty_row(
      seed,
      rep_id,
      provider,
      target,
      linked_cell_id,
      "sim_error",
      conditionMessage(sim)
    ))
  }

  fit_warnings <- character()
  elapsed <- system.time({
    fit <- withCallingHandlers(
      tryCatch(fit_q2_slope(provider, sim), error = function(e) e),
      warning = function(w) {
        fit_warnings <<- c(fit_warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
  })
  if (inherits(fit, "error")) {
    return(topup_empty_row(
      seed,
      rep_id,
      provider,
      target,
      linked_cell_id,
      "fit_error",
      conditionMessage(fit)
    ))
  }

  est <- extract_estimate(fit, provider, target)
  raw <- run_interval(fit, parm, bias_t = FALSE)
  bc <- run_interval(fit, parm, bias_t = TRUE)

  data.frame(
    replicate_id = rep_id,
    seed = seed,
    linked_cell_id = linked_cell_id,
    provider = provider,
    target = target,
    target_parm = parm,
    truth_value = truth,
    attempt_status = "fit_ok",
    message = clean_text(paste(fit_warnings, collapse = "; ")),
    convergence = fit$opt$convergence,
    pdHess = isTRUE(fit$sdr$pdHess),
    estimate = if (is.null(est) || length(est) == 0L) NA_real_ else est,
    wald_lower = raw$lower,
    wald_upper = raw$upper,
    wald_status = raw$status,
    wald_message = raw$message,
    wald_warnings = raw$warnings,
    wald_contains = contains_truth(truth, raw$lower, raw$upper),
    bias_t_lower = bc$lower,
    bias_t_upper = bc$upper,
    bias_t_status = bc$status,
    bias_t_message = bc$message,
    bias_t_warnings = bc$warnings,
    bias_t_contains = contains_truth(truth, bc$lower, bc$upper),
    elapsed_sec = unname(elapsed[["elapsed"]]),
    stringsAsFactors = FALSE
  )
}

mcse <- function(p, n) {
  if (!is.finite(p) || n <= 0L) NA_real_ else sqrt(p * (1 - p) / n)
}

make_topup_summary <- function(
  rows,
  shard,
  provider,
  target,
  linked_cell_id,
  planned_reps
) {
  fit_rows <- rows[rows$attempt_status == "fit_ok", , drop = FALSE]
  finite_bc <- fit_rows[
    is.finite(fit_rows$bias_t_lower) & is.finite(fit_rows$bias_t_upper),
    ,
    drop = FALSE
  ]
  finite_wald <- fit_rows[
    is.finite(fit_rows$wald_lower) & is.finite(fit_rows$wald_upper),
    ,
    drop = FALSE
  ]
  n_bc <- nrow(finite_bc)
  n_wald <- nrow(finite_wald)
  bc_coverage <- if (n_bc > 0L) {
    mean(finite_bc$bias_t_contains, na.rm = TRUE)
  } else {
    NA_real_
  }
  wald_coverage <- if (n_wald > 0L) {
    mean(finite_wald$wald_contains, na.rm = TRUE)
  } else {
    NA_real_
  }
  lower_miss_bc <- sum(
    finite_bc$truth_value < finite_bc$bias_t_lower,
    na.rm = TRUE
  )
  upper_miss_bc <- sum(
    finite_bc$truth_value > finite_bc$bias_t_upper,
    na.rm = TRUE
  )
  data.frame(
    shard = shard,
    linked_cell_id = linked_cell_id,
    provider = provider,
    target = target,
    target_parm = parm_name_for(provider, target),
    truth_value = truth_for(target),
    planned_reps = planned_reps,
    n_fit_ok = nrow(fit_rows),
    n_fit_error = sum(rows$attempt_status == "fit_error"),
    n_sim_error = sum(rows$attempt_status == "sim_error"),
    n_converged = sum(fit_rows$convergence == 0L, na.rm = TRUE),
    n_pdhess = sum(fit_rows$pdHess, na.rm = TRUE),
    n_bias_t_finite = n_bc,
    bias_t_finite_rate = round(
      if (nrow(fit_rows) > 0L) n_bc / nrow(fit_rows) else NA_real_,
      4L
    ),
    n_bias_t_covered = sum(finite_bc$bias_t_contains, na.rm = TRUE),
    bias_t_coverage = round(bc_coverage, 4L),
    bias_t_mcse = round(mcse(bc_coverage, n_bc), 6L),
    bias_t_lower_miss = lower_miss_bc,
    bias_t_upper_miss = upper_miss_bc,
    n_wald_finite = n_wald,
    n_wald_covered = sum(finite_wald$wald_contains, na.rm = TRUE),
    wald_coverage = round(wald_coverage, 4L),
    wald_mcse = round(mcse(wald_coverage, n_wald), 6L),
    mean_estimate = round(mean(fit_rows$estimate, na.rm = TRUE), 6L),
    bias_mean_estimate = round(
      mean(fit_rows$estimate, na.rm = TRUE) - truth_for(target),
      6L
    ),
    summary_status = "topup_endpoint_only_no_promotion",
    claim_boundary = paste(
      "q2 bias+t top-up endpoint-only runner output for",
      provider,
      target,
      "does not promote interval_status, coverage_status, inference_ready,",
      "supported, correlation targets, q4/q8, REML, AI-REML, bridge support,",
      "or public support."
    ),
    stringsAsFactors = FALSE
  )
}

args <- parse_args(commandArgs(TRUE))
source_q2_runner_prefix()
load_result <- load_drmTMB_for_topup(
  args$attempt_temp_install,
  args$allow_load_all
)

shard_row <- TOPUP_MAP[TOPUP_MAP$shard == args$shard, , drop = FALSE]
provider <- shard_row$provider
target <- shard_row$target
linked_cell_id <- shard_row$linked_cell_id
tok <- target_token(target)

out_dir <- if (!is.na(args$out_dir)) {
  args$out_dir
} else {
  file.path(
    repo_root,
    "docs",
    "dev-log",
    "simulation-artifacts",
    sprintf("q2-bias-t-topup-shard%02d", args$shard)
  )
}
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

rep_file_stem <- sprintf("%02d-%s-%s", args$shard, provider, tok)
rep_path <- file.path(out_dir, paste0(rep_file_stem, "-replicates.tsv"))
sum_path <- file.path(out_dir, paste0(rep_file_stem, "-summary.tsv"))
run_log_path <- file.path(out_dir, paste0(rep_file_stem, "-run-log.tsv"))

message(sprintf(
  "[q2-bias-t] shard=%d provider=%s target=%s n_rep=%d seed_start=%d",
  args$shard,
  provider,
  target,
  args$n_rep,
  args$seed_start
))
message("[q2-bias-t] load_status=", load_result$status)

done_seeds <- integer(0L)
if (file.exists(rep_path)) {
  previous <- tryCatch(
    utils::read.delim(
      rep_path,
      sep = "\t",
      check.names = FALSE,
      stringsAsFactors = FALSE
    ),
    error = function(e) NULL
  )
  if (!is.null(previous) && "seed" %in% names(previous)) {
    done_seeds <- unique(as.integer(previous$seed[!is.na(previous$seed)]))
  }
}

all_seeds <- seq.int(args$seed_start, length.out = args$n_rep)
todo_seeds <- setdiff(all_seeds, done_seeds)
todo_rep_ids <- match(todo_seeds, all_seeds)
message(sprintf(
  "[q2-bias-t] seeds_to_run=%d of %d",
  length(todo_seeds),
  args$n_rep
))

if (!load_result$ok) {
  rows <- do.call(
    rbind,
    Map(
      function(seed, rep_id) {
        topup_empty_row(
          seed,
          rep_id,
          provider,
          target,
          linked_cell_id,
          "not_attempted",
          load_result$detail
        )
      },
      todo_seeds,
      todo_rep_ids
    )
  )
  if (nrow(rows) > 0L) {
    append_tsv(rows, rep_path)
  }
} else if (length(todo_seeds) > 0L) {
  for (i in seq_along(todo_seeds)) {
    row <- run_one_topup_rep(
      todo_seeds[[i]],
      todo_rep_ids[[i]],
      provider,
      target,
      linked_cell_id,
      args$n_each
    )
    append_tsv(row, rep_path)
    if (i %% 25L == 0L || i == length(todo_seeds)) {
      message(sprintf(
        "[q2-bias-t] completed %d/%d new seeds",
        i,
        length(todo_seeds)
      ))
    }
  }
}

rows_all <- utils::read.delim(
  rep_path,
  sep = "\t",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
summary_out <- make_topup_summary(
  rows_all,
  args$shard,
  provider,
  target,
  linked_cell_id,
  args$n_rep
)
write_tsv(summary_out, sum_path)

run_log <- data.frame(
  timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
  shard = args$shard,
  provider = provider,
  target = target,
  linked_cell_id = linked_cell_id,
  n_rep = args$n_rep,
  seed_start = args$seed_start,
  n_each = args$n_each,
  load_status = load_result$status,
  load_detail = clean_text(load_result$detail),
  rep_path = rep_path,
  summary_path = sum_path,
  stringsAsFactors = FALSE
)
write_tsv(run_log, run_log_path)

writeLines(capture.output(sessionInfo()), file.path(out_dir, "sessionInfo.txt"))
git_sha <- tryCatch(
  system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE),
  error = function(e) conditionMessage(e)
)
writeLines(git_sha, file.path(out_dir, "git-sha.txt"))

message("[q2-bias-t] summary_path=", sum_path)

if (!isTRUE(load_result$ok)) {
  message(
    "[q2-bias-t] failing because drmTMB did not load: ",
    load_result$status
  )
  quit(status = 2L)
}
