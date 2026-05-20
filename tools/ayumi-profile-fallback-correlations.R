#!/usr/bin/env Rscript

load_drmtmb <- function() {
  if (
    requireNamespace("devtools", quietly = TRUE) && file.exists("DESCRIPTION")
  ) {
    devtools::load_all(".", quiet = TRUE)
    return(invisible(TRUE))
  }
  library(drmTMB)
  invisible(TRUE)
}

env_chr <- function(name, default) {
  value <- Sys.getenv(name, unset = default)
  if (!nzchar(value)) default else value
}

env_flag <- function(name, default = FALSE) {
  value <- Sys.getenv(name, unset = if (default) "true" else "false")
  tolower(value) %in% c("1", "true", "yes", "y")
}

env_num <- function(name, default = NA_real_) {
  value <- Sys.getenv(name, unset = as.character(default))
  out <- suppressWarnings(as.numeric(value))
  if (!is.finite(out) || is.na(out)) {
    default
  } else {
    out
  }
}

env_int <- function(name, default = NA_integer_) {
  value <- Sys.getenv(name, unset = as.character(default))
  out <- suppressWarnings(as.integer(value))
  if (!is.finite(out) || is.na(out)) {
    default
  } else {
    out
  }
}

capture_conditions <- function(expr) {
  warnings <- character()
  messages <- character()
  value <- withCallingHandlers(
    tryCatch(expr, error = function(e) e),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    },
    message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  list(value = value, warnings = warnings, messages = messages)
}

write_table <- function(dat, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(dat, path, row.names = FALSE, na = "")
}

bind_tables <- function(tables) {
  tables <- Filter(function(x) is.data.frame(x) && nrow(x) > 0L, tables)
  if (!length(tables)) {
    return(data.frame())
  }
  columns <- unique(unlist(lapply(tables, names), use.names = FALSE))
  tables <- lapply(tables, function(tab) {
    missing <- setdiff(columns, names(tab))
    for (col in missing) {
      tab[[col]] <- NA
    }
    tab[columns]
  })
  out <- do.call(rbind, tables)
  row.names(out) <- NULL
  out
}

condition_rows <- function(target, values, type) {
  if (!length(values)) {
    return(data.frame())
  }
  data.frame(
    target = target,
    type = type,
    message = as.character(values),
    stringsAsFactors = FALSE
  )
}

safe_table <- function(x) {
  if (is.null(x)) {
    return(data.frame())
  }
  out <- as.data.frame(x, stringsAsFactors = FALSE)
  row_names <- row.names(out)
  if (
    nrow(out) > 0L &&
      !is.null(row_names) &&
      !identical(row_names, as.character(seq_len(nrow(out))))
  ) {
    out <- cbind(term = row_names, out, stringsAsFactors = FALSE)
  }
  row.names(out) <- NULL
  out
}

load_fit <- function(path, model) {
  fits <- readRDS(path)
  if (inherits(fits, "drmTMB")) {
    return(fits)
  }
  if (is.list(fits) && model %in% names(fits)) {
    return(fits[[model]])
  }
  stop("Could not find model `", model, "` in ", path)
}

split_targets <- function(value) {
  trimws(strsplit(value, ",", fixed = TRUE)[[1L]])
}

select_targets <- function(targets, spec) {
  keys <- split_targets(spec)
  selected <- rep(FALSE, nrow(targets))
  for (key in keys) {
    selected <- selected |
      switch(
        key,
        all = targets$profile_ready,
        correlation = targets$profile_ready &
          targets$target_class %in%
            c("random-effect-correlation", "residual-correlation"),
        phylo = targets$profile_ready &
          grepl("cor:phylo:", targets$parm, fixed = TRUE),
        phylo_mean = targets$profile_ready &
          grepl("cor:phylo:cor(mu1:", targets$parm, fixed = TRUE),
        phylo_scale = targets$profile_ready &
          grepl("cor:phylo:cor(sigma1:", targets$parm, fixed = TRUE),
        rho12 = targets$profile_ready &
          targets$target_class == "residual-correlation",
        targets$parm == key
      )
  }
  out <- targets[selected, , drop = FALSE]
  row.names(out) <- NULL
  out
}

profile_one <- function(
  fit,
  target,
  level,
  trace,
  ystep,
  ytol,
  maxit,
  parm_range
) {
  args <- list(
    object = fit,
    parm = target$parm,
    level = level,
    method = "profile",
    trace = trace,
    ystep = ystep
  )
  if (is.finite(ytol)) {
    args$ytol <- ytol
  }
  if (is.finite(maxit)) {
    args$maxit <- maxit
  }
  if (length(parm_range) == 2L && all(is.finite(parm_range))) {
    args$parm.range <- parm_range
  }
  started <- Sys.time()
  captured <- capture_conditions(do.call(stats::confint, args))
  elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  if (inherits(captured$value, "error")) {
    summary <- data.frame(
      target = target$parm,
      status = "error",
      elapsed_sec = elapsed,
      level = level,
      lower = NA_real_,
      upper = NA_real_,
      scale = target$scale,
      transformation = target$transformation,
      estimate = target$estimate,
      profile.boundary = NA,
      profile.message = NA_character_,
      stringsAsFactors = FALSE
    )
    conditions <- bind_tables(list(
      condition_rows(target$parm, conditionMessage(captured$value), "error"),
      condition_rows(target$parm, captured$warnings, "warning"),
      condition_rows(target$parm, captured$messages, "message")
    ))
    return(list(summary = summary, conditions = conditions))
  }
  ci <- as.data.frame(captured$value, stringsAsFactors = FALSE)
  summary <- data.frame(
    target = target$parm,
    status = "profile",
    elapsed_sec = elapsed,
    level = ci$level,
    lower = ci$lower,
    upper = ci$upper,
    scale = ci$scale,
    transformation = ci$transformation,
    estimate = target$estimate,
    profile.boundary = ci$profile.boundary,
    profile.message = ci$profile.message,
    stringsAsFactors = FALSE
  )
  conditions <- bind_tables(list(
    condition_rows(target$parm, captured$warnings, "warning"),
    condition_rows(target$parm, captured$messages, "message")
  ))
  list(summary = summary, conditions = conditions)
}

run_parallel <- function(tasks, worker, backend, cores) {
  if (identical(backend, "none") || cores <= 1L || length(tasks) <= 1L) {
    return(lapply(tasks, worker))
  }
  if (identical(backend, "multicore")) {
    if (.Platform$OS.type == "windows") {
      stop("The multicore backend is unavailable on Windows; use backend=none.")
    }
    return(parallel::mclapply(tasks, worker, mc.cores = cores))
  }
  stop("Unknown backend: ", backend)
}

main <- function() {
  load_drmtmb()
  fit_rds <- env_chr(
    "DRMTMB_PROFILE_FIT_RDS",
    "docs/dev-log/ayumi-convergence/slices-403-412/mass-beak-pv2-block-fallback/fits.rds"
  )
  model <- env_chr("DRMTMB_PROFILE_MODEL", "PV2_phylo_fallback")
  out <- env_chr(
    "DRMTMB_PROFILE_OUT",
    "docs/dev-log/ayumi-convergence/slices-413-422/mass-beak-pv2-block-fallback-profile"
  )
  target_spec <- env_chr("DRMTMB_PROFILE_TARGETS", "phylo_mean")
  level <- env_num("DRMTMB_PROFILE_LEVEL", 0.95)
  ystep <- env_num("DRMTMB_PROFILE_YSTEP", 0.5)
  ytol <- env_num("DRMTMB_PROFILE_YTOL", NA_real_)
  maxit <- env_int("DRMTMB_PROFILE_MAXIT", NA_integer_)
  trace <- env_flag("DRMTMB_PROFILE_TRACE", FALSE)
  lower <- env_num("DRMTMB_PROFILE_RANGE_LOWER", NA_real_)
  upper <- env_num("DRMTMB_PROFILE_RANGE_UPPER", NA_real_)
  parm_range <- c(lower, upper)

  fit <- load_fit(fit_rds, model)
  targets <- profile_targets(fit)
  selected <- select_targets(targets, target_spec)
  if (!nrow(selected)) {
    stop("No profile-ready targets matched `", target_spec, "`.")
  }
  requested_cores <- max(
    1L,
    env_int("DRMTMB_PROFILE_CORES", min(4L, nrow(selected)))
  )
  cores <- min(10L, requested_cores, nrow(selected))
  backend <- env_chr(
    "DRMTMB_PROFILE_BACKEND",
    if (cores > 1L) "multicore" else "none"
  )
  if (!backend %in% c("none", "multicore")) {
    stop("DRMTMB_PROFILE_BACKEND must be one of none or multicore.")
  }
  if (identical(backend, "none")) {
    cores <- 1L
  }

  preflight <- data.frame(
    item = c(
      "fit_rds",
      "model",
      "target_spec",
      "level",
      "ystep",
      "ytol",
      "maxit",
      "trace",
      "parm_range_lower",
      "parm_range_upper",
      "backend",
      "requested_cores",
      "cores",
      "fit_convergence",
      "fit_pdHess"
    ),
    value = c(
      fit_rds,
      model,
      target_spec,
      level,
      ystep,
      if (is.finite(ytol)) ytol else NA,
      if (is.finite(maxit)) maxit else NA,
      trace,
      if (is.finite(lower)) lower else NA,
      if (is.finite(upper)) upper else NA,
      backend,
      requested_cores,
      cores,
      fit$opt$convergence,
      if (is.null(fit$sdr)) NA else isTRUE(fit$sdr$pdHess)
    ),
    stringsAsFactors = FALSE
  )

  write_table(preflight, file.path(out, "preflight.csv"))
  write_table(targets, file.path(out, "profile-targets-all.csv"))
  write_table(selected, file.path(out, "profile-targets-selected.csv"))
  write_table(safe_table(corpairs(fit)), file.path(out, "corpairs.csv"))
  write_table(safe_table(check_drm(fit)), file.path(out, "check-rows.csv"))

  cat(
    "Profiling ",
    nrow(selected),
    " target(s) with backend=",
    backend,
    " and cores=",
    cores,
    "...\n",
    sep = ""
  )
  worker <- function(i) {
    profile_one(
      fit = fit,
      target = selected[i, , drop = FALSE],
      level = level,
      trace = trace,
      ystep = ystep,
      ytol = ytol,
      maxit = maxit,
      parm_range = parm_range
    )
  }
  results <- run_parallel(
    seq_len(nrow(selected)),
    worker,
    backend = backend,
    cores = cores
  )
  for (result in results) {
    print(result$summary)
  }

  write_table(
    bind_tables(lapply(results, `[[`, "summary")),
    file.path(out, "profile-summary.csv")
  )
  write_table(
    bind_tables(lapply(results, `[[`, "conditions")),
    file.path(out, "profile-conditions.csv")
  )
  cat("Wrote profile artifacts to ", out, "\n", sep = "")
}

main()
