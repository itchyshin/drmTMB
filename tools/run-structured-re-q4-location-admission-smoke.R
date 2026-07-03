#!/usr/bin/env Rscript

`%||%` <- function(x, y) if (is.null(x)) y else x

print_help <- function() {
  cat(
    paste(
      "Usage: Rscript tools/run-structured-re-q4-location-admission-smoke.R [options]",
      "",
      "Runs the Tranche 4 q4 location retained-denominator admission smoke.",
      "This is not a coverage grid and does not promote any q4 row.",
      "",
      "Options:",
      "  --mode=dry-run|execute       Default: dry-run.",
      "  --provider=all|phylo|spatial|animal|relmat",
      "                               Default: all.",
      "  --n_rep=N                    Retained smoke replicates per provider; default: 5.",
      "  --seed_start=N               Provider seed base; default: 960000.",
      "  --n_each=N                   Observations per group; default: 20.",
      "  --host_label=LABEL           Provenance label; default: local.",
      "  --out_dir=PATH               Artifact directory; default is the Tranche 4 artifact dir.",
      "  --summary_path=PATH|NA        Dashboard summary path; default is the Tranche 4 sidecar.",
      "  --load_source=false          Use installed/temp-installed drmTMB instead of load_all().",
      "  --attempt-temp-install       If not using load_all(), allow temp install fallback.",
      "  --help, -h                   Print this help.",
      "",
      "Boundary: retains fit errors, nonconvergence, pdHess FALSE, gradient/profile",
      "warnings, boundary estimates, finite direct-SD Wald/profile intervals,",
      "derived-correlation unavailable status, and every attempted replicate.",
      sep = "\n"
    ),
    "\n"
  )
}

parse_admission_args <- function(args) {
  out <- list(
    mode = "dry-run",
    provider = "all",
    n_rep = 5L,
    seed_start = 960000L,
    n_each = 20L,
    host_label = "local",
    out_dir = NA_character_,
    summary_path = NA_character_,
    load_source = TRUE,
    attempt_temp_install = FALSE
  )
  for (arg in args) {
    if (startsWith(arg, "--mode=")) {
      out$mode <- sub("^--mode=", "", arg)
    } else if (startsWith(arg, "--provider=")) {
      out$provider <- sub("^--provider=", "", arg)
    } else if (startsWith(arg, "--n_rep=")) {
      out$n_rep <- as.integer(sub("^--n_rep=", "", arg))
    } else if (startsWith(arg, "--seed_start=")) {
      out$seed_start <- as.integer(sub("^--seed_start=", "", arg))
    } else if (startsWith(arg, "--n_each=")) {
      out$n_each <- as.integer(sub("^--n_each=", "", arg))
    } else if (startsWith(arg, "--host_label=")) {
      out$host_label <- sub("^--host_label=", "", arg)
    } else if (startsWith(arg, "--out_dir=")) {
      out$out_dir <- sub("^--out_dir=", "", arg)
    } else if (startsWith(arg, "--summary_path=")) {
      out$summary_path <- sub("^--summary_path=", "", arg)
    } else if (startsWith(arg, "--load_source=")) {
      value <- tolower(sub("^--load_source=", "", arg))
      out$load_source <- value %in% c("true", "1", "yes")
    } else if (identical(arg, "--attempt-temp-install")) {
      out$attempt_temp_install <- TRUE
    }
  }
  out
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

clean_ascii <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "NA"
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub("[^ -~]", "", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

git_scalar <- function(args, default = "unknown") {
  out <- tryCatch(
    system2(
      "git",
      c("-C", shQuote(repo_root), args),
      stdout = TRUE,
      stderr = FALSE
    ),
    error = function(e) character()
  )
  out <- out[nzchar(out)]
  if (!length(out)) {
    return(default)
  }
  clean_ascii(out[[1L]])
}

git_dirty_status <- function() {
  out <- tryCatch(
    system2(
      "git",
      c("-C", shQuote(repo_root), "status", "--porcelain"),
      stdout = TRUE,
      stderr = FALSE
    ),
    error = function(e) character()
  )
  if (length(out) > 0L) "dirty" else "clean"
}

env_or_default <- function(name, default_fun) {
  value <- Sys.getenv(name, unset = "")
  if (nzchar(value)) {
    return(clean_ascii(value))
  }
  default_fun()
}

read_tsv <- function(path) {
  utils::read.delim(
    path,
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

write_tsv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  char_cols <- vapply(x, is.character, logical(1L))
  x[char_cols] <- lapply(x[char_cols], clean_ascii)
  utils::write.table(
    x,
    path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA"
  )
}

format_rate <- function(num, den) {
  if (is.na(den) || den == 0L) {
    return(NA_real_)
  }
  round(num / den, 4L)
}

source_coverage_helpers <- function(path) {
  exprs <- parse(path)
  stop_at <- which(vapply(
    exprs,
    function(expr) {
      is.call(expr) &&
        identical(as.character(expr[[1L]]), "<-") &&
        identical(as.character(expr[[2L]]), "raw_args")
    },
    logical(1L)
  ))[1L]
  if (is.na(stop_at)) {
    stop("Could not find q4 coverage helper boundary in ", path, call. = FALSE)
  }
  env <- new.env(parent = globalenv())
  for (i in seq_len(stop_at - 1L)) {
    eval(exprs[[i]], envir = env)
  }
  env
}

load_drmTMB_for_smoke <- function(helpers, load_source, attempt_temp_install) {
  if (isTRUE(load_source)) {
    result <- tryCatch(
      {
        devtools::load_all(repo_root, quiet = TRUE)
        list(
          ok = TRUE,
          status = "devtools_load_all_current_source",
          detail = "loaded current checkout"
        )
      },
      error = function(e) {
        list(
          ok = FALSE,
          status = "devtools_load_all_failed",
          detail = conditionMessage(e)
        )
      }
    )
    if (isTRUE(result$ok)) {
      return(result)
    }
    message("[admission] load_all failed: ", clean_ascii(result$detail))
  }
  helpers$try_load_drmTMB(attempt_temp_install)
}

target_token <- function(endpoint_member) {
  gsub(
    "_$",
    "",
    gsub("[^A-Za-z0-9]+", "_", tolower(endpoint_member))
  )
}

provider_seed <- function(seed_start, provider, rep_id) {
  provider_offset <- match(provider, c("phylo", "spatial", "animal", "relmat"))
  seed_start + provider_offset * 1000L + rep_id
}

max_abs_gradient <- function(fit) {
  gradient <- fit$sdr$gradient.fixed %||%
    tryCatch(fit$obj$gr(fit$opt$par), error = function(e) numeric())
  if (!length(gradient) || !any(is.finite(gradient))) {
    return(NA_real_)
  }
  max(abs(gradient), na.rm = TRUE)
}

empty_target_row <- function(
  run_id,
  replicate_id,
  seed,
  host_label,
  design_row,
  status,
  message,
  elapsed_sec = NA_real_
) {
  data.frame(
    run_id = run_id,
    replicate_id = replicate_id,
    seed = seed,
    host_label = host_label,
    provider = design_row$structured_type,
    endpoint_member = design_row$endpoint_member,
    cell_id = design_row$cell_id,
    design_id = design_row$design_id,
    source_target_map_id = design_row$source_target_map_id,
    profile_target = design_row$profile_target,
    attempt_status = status,
    fit_message = clean_ascii(message),
    convergence = NA_integer_,
    pdHess = NA,
    max_abs_gradient = NA_real_,
    boundary_estimate = NA,
    estimate_sd = NA_real_,
    target_found = NA,
    wald_lower = NA_real_,
    wald_upper = NA_real_,
    wald_status = NA_character_,
    wald_warnings = NA_character_,
    wald_finite = FALSE,
    profile_lower = NA_real_,
    profile_upper = NA_real_,
    profile_status = NA_character_,
    profile_conf_status = NA_character_,
    profile_message = NA_character_,
    profile_warnings = NA_character_,
    profile_finite = FALSE,
    derived_correlation_interval_status = "derived_correlation_unavailable",
    coverage_decision = "coverage_not_authorized",
    promotion_decision = "do_not_promote",
    elapsed_sec = elapsed_sec,
    stringsAsFactors = FALSE
  )
}

target_row_from_fit <- function(
  helpers,
  run_id,
  replicate_id,
  seed,
  host_label,
  design_row,
  fit,
  fit_message,
  elapsed_sec
) {
  provider <- design_row$structured_type
  endpoint_member <- design_row$endpoint_member
  parm_name <- helpers$mu_parm_name(provider, endpoint_member)
  sd_label <- helpers$sd_label_in_sdpars(provider, endpoint_member)
  sdpars_mu <- tryCatch(fit$sdpars$mu, error = function(e) NULL)
  estimate_sd <- if (is.null(sdpars_mu)) {
    NA_real_
  } else {
    tryCatch(unname(sdpars_mu[[sd_label]]), error = function(e) NA_real_)
  }
  targets <- tryCatch(profile_targets(fit), error = function(e) {
    data.frame(parm = character())
  })
  target_found <- parm_name %in% targets$parm
  wald <- helpers$run_wald(fit, parm_name)
  profile <- helpers$run_profile(fit, parm_name)
  conv <- tryCatch(fit$opt$convergence, error = function(e) NA_integer_)
  if (is.null(conv) || !length(conv)) {
    conv <- NA_integer_
  }
  pd_hess <- tryCatch(isTRUE(fit$sdr$pdHess), error = function(e) FALSE)
  grad <- max_abs_gradient(fit)
  boundary <- is.finite(estimate_sd) && estimate_sd <= 0.0500001
  data.frame(
    run_id = run_id,
    replicate_id = replicate_id,
    seed = seed,
    host_label = host_label,
    provider = provider,
    endpoint_member = endpoint_member,
    cell_id = design_row$cell_id,
    design_id = design_row$design_id,
    source_target_map_id = design_row$source_target_map_id,
    profile_target = design_row$profile_target,
    attempt_status = "fit_ok",
    fit_message = clean_ascii(fit_message),
    convergence = conv,
    pdHess = pd_hess,
    max_abs_gradient = grad,
    boundary_estimate = boundary,
    estimate_sd = if (is.null(estimate_sd)) NA_real_ else estimate_sd,
    target_found = target_found,
    wald_lower = wald$lower,
    wald_upper = wald$upper,
    wald_status = wald$status,
    wald_warnings = wald$warnings,
    wald_finite = is.finite(wald$lower) && is.finite(wald$upper),
    profile_lower = profile$lower,
    profile_upper = profile$upper,
    profile_status = profile$status,
    profile_conf_status = profile$conf_status %||% NA_character_,
    profile_message = profile$message,
    profile_warnings = profile$warnings,
    profile_finite = is.finite(profile$lower) && is.finite(profile$upper),
    derived_correlation_interval_status = "derived_correlation_unavailable",
    coverage_decision = "coverage_not_authorized",
    promotion_decision = "do_not_promote",
    elapsed_sec = elapsed_sec,
    stringsAsFactors = FALSE
  )
}

claim_boundary_for_result <- function() {
  paste(
    "Tranche 4 q4 location admission smoke only; retained denominator recorded;",
    "no coverage grid; no interval reliability; no inference_ready; no supported;",
    "no q4 REML; no REML; no AI-REML; no q8 inference;",
    "no derived-correlation interval claim; no broad bridge support;",
    "no public support."
  )
}

admission_decision_for <- function(
  pdhess_rate,
  wald_rate,
  profile_rate,
  n_attempted
) {
  if (
    is.finite(pdhess_rate) &&
      is.finite(wald_rate) &&
      is.finite(profile_rate) &&
      n_attempted >= 5L &&
      pdhess_rate >= 0.95 &&
      wald_rate >= 0.95 &&
      profile_rate >= 0.95
  ) {
    return("local_smoke_gate_passed_review_required_no_admission")
  }
  "not_admitted_local_smoke_gate_failed"
}

summarise_results <- function(rows, design, artifact_relpath, raw_relpath) {
  out <- lapply(seq_len(nrow(design)), function(i) {
    design_row <- design[i, , drop = FALSE]
    subset <- rows[
      rows$design_id == design_row$design_id &
        rows$provider == design_row$structured_type &
        rows$endpoint_member == design_row$endpoint_member,
      ,
      drop = FALSE
    ]
    n_attempted <- nrow(subset)
    n_fit_error <- sum(subset$attempt_status %in% c("fit_error", "sim_error"))
    n_converged <- sum(
      subset$attempt_status == "fit_ok" &
        !is.na(subset$convergence) &
        subset$convergence == 0L
    )
    n_pdhess <- sum(subset$pdHess %in% TRUE, na.rm = TRUE)
    n_wald_finite <- sum(subset$wald_finite %in% TRUE, na.rm = TRUE)
    n_profile_finite <- sum(subset$profile_finite %in% TRUE, na.rm = TRUE)
    n_gradient_warning <- sum(
      is.finite(subset$max_abs_gradient) &
        subset$max_abs_gradient > 1e-3,
      na.rm = TRUE
    )
    n_profile_warning <- sum(
      nzchar(subset$profile_warnings) |
        nzchar(subset$profile_message),
      na.rm = TRUE
    )
    n_boundary <- sum(subset$boundary_estimate %in% TRUE, na.rm = TRUE)
    pdhess_rate <- format_rate(n_pdhess, n_attempted)
    wald_rate <- format_rate(n_wald_finite, n_attempted)
    profile_rate <- format_rate(n_profile_finite, n_attempted)
    data.frame(
      result_id = paste0(
        "q4_location_admission_smoke_",
        design_row$structured_type,
        "_",
        target_token(design_row$endpoint_member)
      ),
      design_id = design_row$design_id,
      cell_id = design_row$cell_id,
      structured_type = design_row$structured_type,
      endpoint_member = design_row$endpoint_member,
      profile_target = design_row$profile_target,
      source_target_map_id = design_row$source_target_map_id,
      n_rep_planned = design_row$n_rep_planned,
      n_attempted = n_attempted,
      host_label = paste(sort(unique(subset$host_label)), collapse = ";"),
      n_fit_error = n_fit_error,
      n_converged = n_converged,
      n_pdhess = n_pdhess,
      pdhess_rate = pdhess_rate,
      n_wald_finite = n_wald_finite,
      wald_finite_rate = wald_rate,
      n_profile_finite = n_profile_finite,
      profile_finite_rate = profile_rate,
      n_gradient_warning = n_gradient_warning,
      n_profile_warning = n_profile_warning,
      n_boundary_estimate = n_boundary,
      derived_correlation_interval_status = "derived_correlation_unavailable",
      admission_decision = admission_decision_for(
        pdhess_rate,
        wald_rate,
        profile_rate,
        n_attempted
      ),
      coverage_decision = "coverage_not_authorized",
      promotion_decision = "do_not_promote",
      rose_audit = "rose_no_status_claim_retained_denominator_recorded",
      fisher_review = "fisher_no_coverage_before_admission_review",
      gauss_review = "gauss_fit_hessian_warning_denominator_retained",
      noether_review = "noether_exact_profile_target_preserved",
      evidence_url = artifact_relpath,
      raw_artifact_url = raw_relpath,
      claim_boundary = claim_boundary_for_result(),
      next_gate = paste(
        "Review retained-denominator q4 location admission smoke n=5 for",
        design_row$structured_type,
        design_row$endpoint_member,
        "using profile_targets()",
        design_row$profile_target,
        "with host provenance before any coverage design."
      ),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, out)
}

run_provider_replicate <- function(
  helpers,
  run_id,
  provider,
  replicate_id,
  seed,
  host_label,
  n_each,
  design_rows
) {
  sim <- tryCatch(
    helpers$make_q4_location_data(provider, seed, n_each = n_each),
    error = function(e) e
  )
  if (inherits(sim, "error")) {
    return(do.call(
      rbind,
      lapply(seq_len(nrow(design_rows)), function(i) {
        empty_target_row(
          run_id,
          replicate_id,
          seed,
          host_label,
          design_rows[i, , drop = FALSE],
          "sim_error",
          conditionMessage(sim)
        )
      })
    ))
  }

  fit_warnings <- character()
  elapsed <- system.time({
    fit <- withCallingHandlers(
      tryCatch(helpers$fit_q4_location(provider, sim), error = function(e) e),
      warning = function(w) {
        fit_warnings <<- c(fit_warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
  })[["elapsed"]]

  if (inherits(fit, "error")) {
    return(do.call(
      rbind,
      lapply(seq_len(nrow(design_rows)), function(i) {
        empty_target_row(
          run_id,
          replicate_id,
          seed,
          host_label,
          design_rows[i, , drop = FALSE],
          "fit_error",
          conditionMessage(fit),
          elapsed
        )
      })
    ))
  }

  do.call(
    rbind,
    lapply(seq_len(nrow(design_rows)), function(i) {
      target_row_from_fit(
        helpers,
        run_id,
        replicate_id,
        seed,
        host_label,
        design_rows[i, , drop = FALSE],
        fit,
        paste(fit_warnings, collapse = "; "),
        elapsed
      )
    })
  )
}

raw_args <- commandArgs(TRUE)
if (any(raw_args %in% c("--help", "-h"))) {
  print_help()
  quit(status = 0L)
}

args <- parse_admission_args(raw_args)
if (!args$mode %in% c("dry-run", "execute")) {
  stop("--mode must be dry-run or execute", call. = FALSE)
}
if (!args$provider %in% c("all", "phylo", "spatial", "animal", "relmat")) {
  stop(
    "--provider must be all, phylo, spatial, animal, or relmat",
    call. = FALSE
  )
}
if (is.na(args$n_rep) || args$n_rep < 1L) {
  stop("--n_rep must be a positive integer", call. = FALSE)
}

helper_path <- file.path(
  repo_root,
  "tools",
  "run-structured-re-q4-location-coverage-grid.R"
)
helpers <- source_coverage_helpers(helper_path)
dashboard_dir <- file.path(repo_root, "docs", "dev-log", "dashboard")
design_path <- file.path(
  dashboard_dir,
  "structured-re-q4-location-admission-runner-design.tsv"
)
design <- read_tsv(design_path)
providers <- if (identical(args$provider, "all")) {
  c("phylo", "spatial", "animal", "relmat")
} else {
  args$provider
}
design <- design[design$structured_type %in% providers, , drop = FALSE]
design <- design[
  order(match(
    design$structured_type,
    c("phylo", "spatial", "animal", "relmat")
  )),
]

artifact_dir <- if (!is.na(args$out_dir)) {
  args$out_dir
} else {
  file.path(
    repo_root,
    "docs",
    "dev-log",
    "simulation-artifacts",
    "2026-07-01-q4-location-admission-smoke"
  )
}
raw_path <- file.path(
  artifact_dir,
  "structured-re-q4-location-admission-smoke-results.tsv"
)
run_log_path <- file.path(
  artifact_dir,
  "structured-re-q4-location-admission-smoke-run-log.tsv"
)
summary_path <- if (is.na(args$summary_path)) {
  file.path(dashboard_dir, "structured-re-q4-location-admission-smoke.tsv")
} else if (identical(args$summary_path, "NA")) {
  NA_character_
} else {
  args$summary_path
}
summary_relpath <- if (is.na(summary_path)) {
  "NA"
} else {
  substring(
    normalizePath(summary_path, winslash = "/", mustWork = FALSE),
    nchar(repo_root) + 2L
  )
}
raw_relpath <- substring(
  normalizePath(raw_path, winslash = "/", mustWork = FALSE),
  nchar(repo_root) + 2L
)
source_sha <- env_or_default(
  "DRMTMB_SOURCE_SHA",
  function() git_scalar(c("rev-parse", "--short", "HEAD"))
)
source_dirty <- env_or_default("DRMTMB_SOURCE_DIRTY", git_dirty_status)
output_path <- normalizePath(artifact_dir, winslash = "/", mustWork = FALSE)
raw_output_path <- normalizePath(raw_path, winslash = "/", mustWork = FALSE)
run_log_output_path <- normalizePath(
  run_log_path,
  winslash = "/",
  mustWork = FALSE
)
summary_output_path <- if (is.na(summary_path)) {
  "NA"
} else {
  normalizePath(summary_path, winslash = "/", mustWork = FALSE)
}
run_id <- paste0(
  "q4_location_admission_smoke_",
  args$host_label,
  "_n",
  args$n_rep
)

message("[admission] mode=", args$mode)
message("[admission] providers=", paste(providers, collapse = ","))
message("[admission] target rows=", nrow(design))
message("[admission] n_rep=", args$n_rep)
message("[admission] host_label=", args$host_label)
message("[admission] raw_path=", raw_path)
message("[admission] summary_path=", summary_path)

if (identical(args$mode, "dry-run")) {
  print(data.frame(
    provider = design$structured_type,
    endpoint_member = design$endpoint_member,
    profile_target = design$profile_target,
    n_rep = args$n_rep,
    host_label = args$host_label,
    stringsAsFactors = FALSE
  ))
  quit(status = 0L)
}

load_result <- load_drmTMB_for_smoke(
  helpers,
  args$load_source,
  args$attempt_temp_install
)
run_log <- data.frame(
  run_id = run_id,
  mode = args$mode,
  host_label = args$host_label,
  provider = args$provider,
  n_rep = args$n_rep,
  seed_start = args$seed_start,
  n_each = args$n_each,
  source_sha = source_sha,
  source_dirty = source_dirty,
  output_path = output_path,
  raw_output_path = raw_output_path,
  run_log_output_path = run_log_output_path,
  summary_output_path = summary_output_path,
  load_status = load_result$status,
  load_detail = clean_ascii(load_result$detail),
  raw_artifact_url = raw_relpath,
  summary_url = summary_relpath,
  coverage_decision = "coverage_not_authorized",
  promotion_decision = "do_not_promote",
  claim_boundary = claim_boundary_for_result(),
  stringsAsFactors = FALSE
)
write_tsv(run_log, run_log_path)

if (!isTRUE(load_result$ok)) {
  rows <- do.call(
    rbind,
    lapply(seq_len(nrow(design)), function(i) {
      design_row <- design[i, , drop = FALSE]
      do.call(
        rbind,
        lapply(seq_len(args$n_rep), function(rep_id) {
          empty_target_row(
            run_id,
            rep_id,
            provider_seed(args$seed_start, design_row$structured_type, rep_id),
            args$host_label,
            design_row,
            "not_attempted",
            load_result$detail
          )
        })
      )
    })
  )
  write_tsv(rows, raw_path)
  summary <- summarise_results(rows, design, summary_relpath, raw_relpath)
  if (!is.na(summary_path)) {
    write_tsv(summary, summary_path)
  }
  stop(
    "drmTMB could not be loaded; wrote retained not_attempted rows",
    call. = FALSE
  )
}

message("[admission] drmTMB loaded: ", load_result$status)
provider_rows <- lapply(providers, function(provider) {
  design_rows <- design[design$structured_type == provider, , drop = FALSE]
  do.call(
    rbind,
    lapply(seq_len(args$n_rep), function(rep_id) {
      seed <- provider_seed(args$seed_start, provider, rep_id)
      message(sprintf(
        "[admission] provider=%s rep=%d/%d seed=%d",
        provider,
        rep_id,
        args$n_rep,
        seed
      ))
      run_provider_replicate(
        helpers,
        run_id,
        provider,
        rep_id,
        seed,
        args$host_label,
        args$n_each,
        design_rows
      )
    })
  )
})
rows <- do.call(rbind, provider_rows)
write_tsv(rows, raw_path)
summary <- summarise_results(rows, design, summary_relpath, raw_relpath)
if (!is.na(summary_path)) {
  write_tsv(summary, summary_path)
}

message("[admission] wrote ", raw_path)
message("[admission] wrote ", run_log_path)
if (!is.na(summary_path)) {
  message("[admission] wrote ", summary_path)
}
message("[admission] coverage_decision=coverage_not_authorized")
message("[admission] promotion_decision=do_not_promote")
