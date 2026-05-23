#!/usr/bin/env Rscript

# Development benchmark for endpoint-only scalar profile intervals. Run from
# the package root, for example:
# Rscript bench/profile-scalar-endpoint.R --rows 10000 --species 1000

load_large_phylo_helpers <- function() {
  path <- file.path("bench", "large-phylo-location.R")
  if (!file.exists(path)) {
    stop(
      "Run this script from the package root so bench/large-phylo-location.R is visible.",
      call. = FALSE
    )
  }
  env <- new.env(parent = globalenv())
  sys.source(path, envir = env)
  env
}

parse_args <- function(args = commandArgs(trailingOnly = TRUE)) {
  defaults <- list(
    rows = 10000L,
    species = 1000L,
    seed = 20260523L,
    tree = "balanced",
    targets = "sd:mu:phylo(1 | species)",
    level = 0.95,
    eval_max = 300L,
    iter_max = 300L,
    endpoint_workers = 1L,
    output = "docs/dev-log/benchmarks/profile-scalar-endpoint.csv"
  )
  if (any(args %in% c("-h", "--help"))) {
    print_usage()
    quit(save = "no", status = 0)
  }
  i <- 1L
  while (i <= length(args)) {
    key <- args[[i]]
    value <- NULL
    if (grepl("^--[^=]+=", key)) {
      parts <- strsplit(sub("^--", "", key), "=", fixed = TRUE)[[1L]]
      key <- parts[[1L]]
      value <- parts[[2L]]
    } else {
      key <- sub("^--", "", key)
      i <- i + 1L
      if (i > length(args)) {
        stop("Missing value for --", key, call. = FALSE)
      }
      value <- args[[i]]
    }
    key <- gsub("-", "_", key, fixed = TRUE)
    if (identical(key, "target")) {
      key <- "targets"
    }
    if (!key %in% names(defaults)) {
      stop("Unknown argument --", key, call. = FALSE)
    }
    defaults[[key]] <- cast_arg(value, defaults[[key]], key)
    i <- i + 1L
  }
  defaults
}

cast_arg <- function(value, template, key) {
  if (is.integer(template)) {
    out <- suppressWarnings(as.integer(value))
    if (is.na(out) || out <= 0L) {
      stop("--", key, " must be a positive integer.", call. = FALSE)
    }
    return(out)
  }
  if (is.numeric(template)) {
    out <- suppressWarnings(as.numeric(value))
    if (is.na(out) || !is.finite(out) || out <= 0 || out >= 1) {
      stop(
        "--",
        key,
        " must be a finite number between 0 and 1.",
        call. = FALSE
      )
    }
    return(out)
  }
  value
}

print_usage <- function() {
  cat(
    "Usage: Rscript bench/profile-scalar-endpoint.R [options]\n\n",
    "Options:\n",
    "  --rows N        Number of observation rows; default 10000\n",
    "  --species N     Number of species; default 1000\n",
    "  --seed N        Random seed; default 20260523\n",
    "  --tree balanced|star  Synthetic ultrametric tree shape; default balanced\n",
    "  --targets CSV   Profile targets; default sd:mu:phylo(1 | species)\n",
    "                  Use all for sd:mu:phylo(1 | species),sigma\n",
    "  --level P       Confidence level; default 0.95\n",
    "  --eval-max N    Fit and endpoint nlminb eval.max; default 300\n",
    "  --iter-max N    Fit and endpoint nlminb iter.max; default 300\n",
    "  --endpoint-workers N  Add endpoint-multicore rows with N workers; default 1\n",
    "  --output PATH   CSV output path\n",
    sep = ""
  )
}

benchmark_targets <- function(targets) {
  if (identical(tolower(targets), "all")) {
    return(c("sd:mu:phylo(1 | species)", "sigma"))
  }
  out <- trimws(strsplit(targets, ",", fixed = TRUE)[[1L]])
  out[nzchar(out)]
}

benchmark_engines <- function(args) {
  engines <- c("tmbprofile", "endpoint")
  if (args$endpoint_workers > 1L) {
    engines <- c(engines, "endpoint-multicore")
  }
  engines
}

profile_engine_arg <- function(engine) {
  if (identical(engine, "endpoint-multicore")) {
    return("endpoint")
  }
  engine
}

profile_parallel_arg <- function(engine) {
  if (identical(engine, "endpoint-multicore")) {
    return("multicore")
  }
  "none"
}

profile_workers_arg <- function(args, engine) {
  if (identical(engine, "endpoint-multicore")) {
    return(args$endpoint_workers)
  }
  1L
}

fit_args <- function(args) {
  list(
    rows = args$rows,
    species = args$species,
    seed = args$seed,
    structured = "phylo",
    tree = args$tree,
    factor_heavy = FALSE,
    sigma_x = FALSE,
    sparse_fixed = FALSE,
    aggregate_gaussian = FALSE,
    aggregation_cells = 80L,
    cell_random_effect = FALSE,
    cell_random_effect_cells = 80L,
    memory_light = FALSE,
    eval_max = args$eval_max,
    iter_max = args$iter_max,
    output = ""
  )
}

package_version_or_na <- function(package) {
  if (!requireNamespace(package, quietly = TRUE)) {
    return(NA_character_)
  }
  as.character(utils::packageVersion(package))
}

git_value <- function(args) {
  out <- tryCatch(
    system2("git", args, stdout = TRUE, stderr = FALSE),
    warning = function(w) character(),
    error = function(e) character()
  )
  if (length(out) == 0L || !nzchar(out[[1L]])) {
    return(NA_character_)
  }
  out[[1L]]
}

git_dirty <- function() {
  out <- tryCatch(
    system2("git", c("status", "--porcelain"), stdout = TRUE, stderr = FALSE),
    warning = function(w) NA_character_,
    error = function(e) NA_character_
  )
  if (length(out) == 1L && is.na(out[[1L]])) {
    return(NA)
  }
  length(out) > 0L
}

environment_row <- function() {
  sys <- Sys.info()
  value <- function(name) {
    out <- unname(sys[[name]])
    if (is.null(out) || is.na(out) || !nzchar(out)) {
      return(NA_character_)
    }
    out
  }
  list(
    run_started_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    git_sha = git_value(c("rev-parse", "--short", "HEAD")),
    git_dirty = git_dirty(),
    r_version = paste(R.version$major, R.version$minor, sep = "."),
    platform = R.version$platform,
    os = paste(na.omit(c(value("sysname"), value("release"))), collapse = " "),
    machine = value("machine"),
    drmTMB_version = if (file.exists("DESCRIPTION")) {
      read.dcf("DESCRIPTION", fields = "Version")[[1L]]
    } else {
      package_version_or_na("drmTMB")
    },
    TMB_version = package_version_or_na("TMB")
  )
}

fit_profile_model <- function(args, helper_env) {
  helper_env$load_drmTMB()
  bench_args <- fit_args(args)
  gc()
  data_time <- system.time(
    sim <- helper_env$simulate_benchmark_data(bench_args)
  )
  control <- drm_control(
    optimizer = list(eval.max = args$eval_max, iter.max = args$iter_max),
    keep_data = FALSE,
    keep_model_frame = FALSE,
    keep_tmb_object = TRUE
  )
  fit_time <- system.time({
    tree <- sim$tree
    fit <- drmTMB(
      helper_env$fit_formula(bench_args),
      family = gaussian(),
      data = sim$data,
      control = control
    )
  })
  list(
    fit = fit,
    data_build_sec = unname(data_time[["elapsed"]]),
    fit_sec = unname(fit_time[["elapsed"]])
  )
}

link_interval_from_response <- function(interval, target) {
  switch(
    target$transformation[[1L]],
    linear_predictor = interval,
    exp = log(interval),
    tanh = atanh(interval / 0.999999),
    rho12_tanh = atanh(interval / 0.99999999),
    c(NA_real_, NA_real_)
  )
}

empty_profile_row <- function(args, env, target, engine, fit_meta, message) {
  data.frame(
    rows = args$rows,
    species = args$species,
    target = target,
    engine = engine,
    elapsed_sec = NA_real_,
    lower = NA_real_,
    upper = NA_real_,
    speedup_vs_tmbprofile = NA_real_,
    convergence = "failure",
    failure_message = message,
    profile_engine = NA_character_,
    profile_parallel = profile_parallel_arg(engine),
    profile_workers = profile_workers_arg(args, engine),
    lower_internal = NA_real_,
    upper_internal = NA_real_,
    lower_root_error = NA_real_,
    upper_root_error = NA_real_,
    lower_n_eval = NA_integer_,
    upper_n_eval = NA_integer_,
    endpoint_n_eval = NA_integer_,
    endpoint_curvature_se = NA_real_,
    lower_initial_step = NA_real_,
    upper_initial_step = NA_real_,
    lower_bracket_step = NA_real_,
    upper_bracket_step = NA_real_,
    lower_step_source = NA_character_,
    upper_step_source = NA_character_,
    endpoint_parallel = NA_character_,
    endpoint_workers = NA_integer_,
    endpoint_vs_tmbprofile_lower_diff = NA_real_,
    endpoint_vs_tmbprofile_upper_diff = NA_real_,
    data_build_sec = fit_meta$data_build_sec,
    fit_sec = fit_meta$fit_sec,
    fit_convergence = fit_meta$fit_convergence,
    fit_message = fit_meta$fit_message,
    run_started_utc = env$run_started_utc,
    git_sha = env$git_sha,
    git_dirty = env$git_dirty,
    r_version = env$r_version,
    platform = env$platform,
    os = env$os,
    machine = env$machine,
    drmTMB_version = env$drmTMB_version,
    TMB_version = env$TMB_version,
    stringsAsFactors = FALSE
  )
}

profile_one <- function(args, env, fit, fit_meta, target_name, engine) {
  targets <- profile_targets(fit)
  target <- targets[targets$parm == target_name, , drop = FALSE]
  if (nrow(target) != 1L) {
    return(empty_profile_row(
      args,
      env,
      target_name,
      engine,
      fit_meta,
      "target not found in profile_targets(fit)"
    ))
  }

  elapsed <- system.time({
    ci <- tryCatch(
      stats::confint(
        fit,
        parm = target_name,
        level = args$level,
        method = "profile",
        profile_engine = profile_engine_arg(engine),
        parallel = profile_parallel_arg(engine),
        workers = profile_workers_arg(args, engine)
      ),
      error = function(e) e
    )
  })
  elapsed_sec <- unname(elapsed[["elapsed"]])
  if (inherits(ci, "error")) {
    out <- empty_profile_row(
      args,
      env,
      target_name,
      engine,
      fit_meta,
      conditionMessage(ci)
    )
    out$elapsed_sec <- elapsed_sec
    return(out)
  }

  internal <- link_interval_from_response(
    c(ci$lower[[1L]], ci$upper[[1L]]),
    target
  )
  endpoint_result <- NULL
  endpoint_error <- NULL
  if (engine %in% c("endpoint", "endpoint-multicore")) {
    endpoint_plan <- drmTMB:::profile_endpoint_parallel_plan(
      targets = target,
      parallel = profile_parallel_arg(engine),
      workers = profile_workers_arg(args, engine),
      profile_engine = "endpoint"
    )
    endpoint_result <- tryCatch(
      drmTMB:::drm_profile_endpoint_result(
        object = fit,
        target = target,
        level = args$level,
        endpoint_plan = endpoint_plan
      ),
      error = function(e) e
    )
    if (inherits(endpoint_result, "error")) {
      endpoint_error <- conditionMessage(endpoint_result)
      endpoint_result <- NULL
    }
  }

  row <- empty_profile_row(args, env, target_name, engine, fit_meta, "")
  row$elapsed_sec <- elapsed_sec
  row$lower <- ci$lower[[1L]]
  row$upper <- ci$upper[[1L]]
  row$convergence <- "ok"
  row$profile_engine <- ci$profile.engine[[1L]]
  row$lower_internal <- internal[[1L]]
  row$upper_internal <- internal[[2L]]
  if (!is.null(endpoint_result)) {
    row$lower_root_error <- endpoint_result$lower_root_error
    row$upper_root_error <- endpoint_result$upper_root_error
    row$lower_n_eval <- endpoint_result$lower_n_eval
    row$upper_n_eval <- endpoint_result$upper_n_eval
    row$endpoint_n_eval <- endpoint_result$n_eval
    row$endpoint_curvature_se <- endpoint_result$curvature_se
    row$lower_initial_step <- endpoint_result$lower_initial_step
    row$upper_initial_step <- endpoint_result$upper_initial_step
    row$lower_bracket_step <- endpoint_result$lower_bracket_step
    row$upper_bracket_step <- endpoint_result$upper_bracket_step
    row$lower_step_source <- endpoint_result$lower_step_source
    row$upper_step_source <- endpoint_result$upper_step_source
    row$endpoint_parallel <- endpoint_result$endpoint_parallel
    row$endpoint_workers <- endpoint_result$endpoint_workers
  }
  if (!is.null(endpoint_error)) {
    row$failure_message <- paste("endpoint root check failed:", endpoint_error)
  }
  row
}

add_speedup_and_differences <- function(rows) {
  for (target in unique(rows$target)) {
    idx <- rows$target == target
    tmb <- rows[idx & rows$engine == "tmbprofile" & rows$convergence == "ok", ]
    if (nrow(tmb) == 1L) {
      rows$speedup_vs_tmbprofile[idx & rows$convergence == "ok"] <-
        tmb$elapsed_sec[[1L]] / rows$elapsed_sec[idx & rows$convergence == "ok"]
    }
    if (nrow(tmb) == 1L) {
      endpoint_idx <- which(
        idx &
          rows$engine %in% c("endpoint", "endpoint-multicore") &
          rows$convergence == "ok"
      )
      rows$endpoint_vs_tmbprofile_lower_diff[endpoint_idx] <-
        rows$lower[endpoint_idx] - tmb$lower[[1L]]
      rows$endpoint_vs_tmbprofile_upper_diff[endpoint_idx] <-
        rows$upper[endpoint_idx] - tmb$upper[[1L]]
    }
  }
  rows
}

run_benchmark <- function(args) {
  helper_env <- load_large_phylo_helpers()
  env <- environment_row()
  targets <- benchmark_targets(args$targets)
  fit_result <- tryCatch(
    fit_profile_model(args, helper_env),
    error = function(e) e
  )
  if (inherits(fit_result, "error")) {
    fit_meta <- list(
      data_build_sec = NA_real_,
      fit_sec = NA_real_,
      fit_convergence = NA_integer_,
      fit_message = conditionMessage(fit_result)
    )
    rows <- do.call(
      rbind,
      lapply(targets, function(target) {
        do.call(
          rbind,
          lapply(benchmark_engines(args), function(engine) {
            empty_profile_row(
              args,
              env,
              target,
              engine,
              fit_meta,
              conditionMessage(fit_result)
            )
          })
        )
      })
    )
    return(rows)
  }

  fit <- fit_result$fit
  fit_message <- fit$opt$message
  if (is.null(fit_message) || length(fit_message) == 0L) {
    fit_message <- NA_character_
  }
  fit_meta <- list(
    data_build_sec = fit_result$data_build_sec,
    fit_sec = fit_result$fit_sec,
    fit_convergence = fit$opt$convergence,
    fit_message = fit_message[[1L]]
  )
  rows <- do.call(
    rbind,
    lapply(targets, function(target) {
      do.call(
        rbind,
        lapply(benchmark_engines(args), function(engine) {
          profile_one(
            args = args,
            env = env,
            fit = fit,
            fit_meta = fit_meta,
            target_name = target,
            engine = engine
          )
        })
      )
    })
  )
  add_speedup_and_differences(rows)
}

write_result <- function(result, output) {
  if (!nzchar(output)) {
    print(result, row.names = FALSE)
    return(invisible(result))
  }
  dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
  append <- file.exists(output) && file.info(output)$size > 0
  if (append) {
    header <- names(utils::read.csv(output, nrows = 0L, check.names = FALSE))
    if (!identical(header, names(result))) {
      stop(
        "Existing benchmark CSV has a different schema. ",
        "Choose a new --output path or remove the old benchmark CSV.",
        call. = FALSE
      )
    }
  }
  utils::write.table(
    result,
    file = output,
    sep = ",",
    row.names = FALSE,
    col.names = !append,
    append = append
  )
  message("Wrote benchmark result to ", output)
  invisible(result)
}

main <- function() {
  args <- parse_args()
  result <- run_benchmark(args)
  write_result(result, args$output)
}

if (identical(environment(), globalenv())) {
  main()
}
