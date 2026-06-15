#!/usr/bin/env Rscript

# Developer harness for Ayumi-style bivariate q4 phylogenetic
# location-scale fits.
#
# This is not a package test. It writes evidence tables that separate:
# - supported vs rejected cells;
# - point-estimate runtime from interval runtime;
# - ML from REML;
# - native TMB from the experimental Julia bridge.

env_chr <- function(name, default = "") {
  value <- Sys.getenv(name, unset = default)
  if (!nzchar(value)) default else value
}

env_flag <- function(name, default = FALSE) {
  value <- tolower(env_chr(name, if (default) "true" else "false"))
  value %in% c("1", "true", "t", "yes", "y")
}

env_num <- function(name, default = NA_real_) {
  value <- suppressWarnings(as.numeric(env_chr(name, as.character(default))))
  if (length(value) != 1L || is.na(value)) default else value
}

env_whole <- function(name, default = NA_integer_) {
  raw <- env_chr(name, "")
  if (!nzchar(raw)) {
    return(default)
  }
  value <- suppressWarnings(as.numeric(raw))
  if (
    length(value) != 1L ||
      is.na(value) ||
      !is.finite(value) ||
      value != as.integer(value)
  ) {
    stop("Invalid whole-number value in ", name, ": ", raw, call. = FALSE)
  }
  as.integer(value)
}

split_csv <- function(value) {
  out <- trimws(strsplit(value, ",", fixed = TRUE)[[1L]])
  out[nzchar(out)]
}

usage <- function() {
  cat(
    paste(
      "Ayumi q4 status harness",
      "",
      "Required:",
      "  DRMTMB_AYUMI_Q4_RDS=/path/to/birds_tarsus_beak_10440.rds",
      "",
      "Common controls:",
      "  DRMTMB_AYUMI_Q4_SIZES=250,500,1000,all",
      "  DRMTMB_AYUMI_Q4_ENGINES=tmb,julia",
      "  DRMTMB_AYUMI_Q4_REML=false,true",
      "  DRMTMB_AYUMI_Q4_PROFILE=none|first_sigma|all_sigma",
      "  DRMTMB_AYUMI_Q4_BOOTSTRAP=0",
      "  DRMTMB_AYUMI_Q4_BOOTSTRAP_TARGETS=none|first_sigma|all_sigma|all_q4",
      "  DRMTMB_AYUMI_Q4_BOOTSTRAP_SEED=",
      "  DRMTMB_AYUMI_Q4_TIME_LIMIT=0",
      "  DRMTMB_AYUMI_Q4_PROFILE_ENDPOINT_MAX_EVAL=",
      "  DRMTMB_AYUMI_Q4_OUT=docs/dev-log/ayumi-q4-status/<run>",
      "",
      "Column controls:",
      "  DRMTMB_AYUMI_Q4_Y1=Tarsus_Length_z",
      "  DRMTMB_AYUMI_Q4_Y2=Beak_Length_Culmen_z",
      "  DRMTMB_AYUMI_Q4_TEMP=mean_tavg_combined_z",
      "  DRMTMB_AYUMI_Q4_PREC=mean_prec_combined_z",
      "  DRMTMB_AYUMI_Q4_MASS=log_mass_z",
      "  DRMTMB_AYUMI_Q4_ID=phylo_id",
      "",
      "Example:",
      "  DRMTMB_AYUMI_Q4_RDS=for_author/birds_tarsus_beak_10440.rds \\",
      "  DRMTMB_AYUMI_Q4_SIZES=250 DRMTMB_AYUMI_Q4_ENGINES=tmb \\",
      "  DRMTMB_AYUMI_Q4_REML=false,true Rscript tools/ayumi-q4-status-harness.R",
      sep = "\n"
    )
  )
}

script_path <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  prefix <- "--file="
  hit <- args[startsWith(args, prefix)]
  if (length(hit) > 0L) {
    return(normalizePath(sub(prefix, "", hit[[1L]]), mustWork = TRUE))
  }
  normalizePath(
    file.path("tools", "ayumi-q4-status-harness.R"),
    mustWork = FALSE
  )
}

repo_root <- normalizePath(
  file.path(dirname(script_path()), ".."),
  mustWork = TRUE
)
setwd(repo_root)

require_package <- function(package, why) {
  if (!requireNamespace(package, quietly = TRUE)) {
    stop("Package `", package, "` is required to ", why, ".", call. = FALSE)
  }
}

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

with_elapsed_limit <- function(expr, seconds) {
  if (!is.finite(seconds) || seconds <= 0) {
    return(force(expr))
  }
  old <- setTimeLimit(elapsed = seconds, transient = TRUE)
  on.exit({
    setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE)
    invisible(old)
  })
  force(expr)
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

write_table <- function(dat, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(dat, path, row.names = FALSE, na = "")
}

append_table <- function(dat, path) {
  if (!is.data.frame(dat) || nrow(dat) == 0L) {
    return(invisible(FALSE))
  }
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.table(
    dat,
    path,
    sep = ",",
    row.names = FALSE,
    col.names = !file.exists(path),
    append = file.exists(path),
    na = "",
    qmethod = "double"
  )
  invisible(TRUE)
}

condition_rows <- function(cell, values, type, phase) {
  if (!length(values)) {
    return(data.frame())
  }
  data.frame(
    cell = cell,
    phase = phase,
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
  row.names(out) <- NULL
  out
}

git_output <- function(args) {
  out <- tryCatch(
    system2("git", args, stdout = TRUE, stderr = TRUE),
    error = function(e) character()
  )
  paste(out, collapse = "\n")
}

package_version_or_na <- function(package) {
  if (!requireNamespace(package, quietly = TRUE)) {
    return(NA_character_)
  }
  as.character(utils::packageVersion(package))
}

find_component <- function(x, names, label) {
  for (name in names) {
    if (is.list(x) && !is.null(x[[name]])) {
      return(x[[name]])
    }
  }
  stop(
    "Could not find `",
    label,
    "` in the RDS list. Tried: ",
    paste(names, collapse = ", "),
    call. = FALSE
  )
}

clean_model_data <- function(dat, columns) {
  missing <- setdiff(unlist(columns, use.names = FALSE), names(dat))
  if (length(missing) > 0L) {
    stop(
      "Missing data columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  out <- data.frame(
    y1_ayumi = dat[[columns$y1]],
    y2_ayumi = dat[[columns$y2]],
    temp_ayumi = dat[[columns$temp]],
    prec_ayumi = dat[[columns$prec]],
    log_mass_ayumi = dat[[columns$mass]],
    species = as.character(dat[[columns$id]]),
    stringsAsFactors = FALSE
  )
  keep <- stats::complete.cases(out[, c(
    "temp_ayumi",
    "prec_ayumi",
    "log_mass_ayumi",
    "species"
  )])
  out[keep, , drop = FALSE]
}

parse_sizes <- function(value) {
  raw <- tolower(split_csv(value))
  if (!length(raw)) {
    return(list(250L))
  }
  lapply(raw, function(x) {
    if (identical(x, "all")) {
      return(NA_integer_)
    }
    size <- suppressWarnings(as.integer(x))
    if (length(size) != 1L || is.na(size) || size <= 0L) {
      stop("Invalid size in DRMTMB_AYUMI_Q4_SIZES: ", x, call. = FALSE)
    }
    size
  })
}

parse_reml <- function(value) {
  raw <- tolower(split_csv(value))
  if (!length(raw)) {
    raw <- "false"
  }
  vapply(
    raw,
    function(x) {
      if (x %in% c("1", "true", "t", "yes", "y")) {
        return(TRUE)
      }
      if (x %in% c("0", "false", "f", "no", "n")) {
        return(FALSE)
      }
      stop("Invalid REML flag: ", x, call. = FALSE)
    },
    logical(1L)
  )
}

subset_by_tree <- function(dat, tree, size) {
  available <- tree$tip.label[tree$tip.label %in% dat$species]
  if (!length(available)) {
    stop("No overlap between data species and tree tips.", call. = FALSE)
  }
  if (is.na(size)) {
    keep_species <- available
    size_label <- "all"
  } else {
    keep_species <- utils::head(available, min(size, length(available)))
    size_label <- as.character(length(keep_species))
  }
  out_dat <- dat[dat$species %in% keep_species, , drop = FALSE]
  out_dat <- out_dat[match(keep_species, out_dat$species), , drop = FALSE]
  out_tree <- ape::keep.tip(tree, keep_species)
  list(data = out_dat, tree = out_tree, size_label = size_label)
}

make_ayumi_q4_formula <- function(tree) {
  bf(
    mu1 = y1_ayumi ~ 1 +
      temp_ayumi +
      prec_ayumi +
      temp_ayumi:prec_ayumi +
      log_mass_ayumi +
      phylo(1 | p | species, tree = tree),
    mu2 = y2_ayumi ~ 1 +
      temp_ayumi +
      prec_ayumi +
      temp_ayumi:prec_ayumi +
      log_mass_ayumi +
      phylo(1 | p | species, tree = tree),
    sigma1 = ~ 1 +
      temp_ayumi +
      prec_ayumi +
      temp_ayumi:prec_ayumi +
      log_mass_ayumi +
      phylo(1 | p | species, tree = tree),
    sigma2 = ~ 1 +
      temp_ayumi +
      prec_ayumi +
      temp_ayumi:prec_ayumi +
      log_mass_ayumi +
      phylo(1 | p | species, tree = tree),
    rho12 = ~1
  )
}

fit_summary <- function(fit) {
  scalar <- function(expr, default) {
    out <- tryCatch(expr, error = function(e) default)
    if (is.null(out) || length(out) == 0L) {
      return(default)
    }
    out[[1L]]
  }
  convergence <- scalar(fit$opt$convergence, NA_integer_)
  pd_hess <- scalar(fit$sdr$pdHess, NA)
  log_lik <- tryCatch(as.numeric(stats::logLik(fit)), error = function(e) {
    NA_real_
  })
  data.frame(
    convergence = convergence,
    convergence_message = scalar(fit$opt$message, NA_character_),
    pdHess = pd_hess,
    fit_diagnostic_status = fit_diagnostic_status(convergence, pd_hess),
    logLik = log_lik,
    AIC = scalar(stats::AIC(fit), NA_real_),
    nobs = scalar(stats::nobs(fit), NA_integer_),
    df = scalar(attr(stats::logLik(fit), "df"), NA_integer_),
    stringsAsFactors = FALSE
  )
}

fit_diagnostic_status <- function(convergence, pd_hess) {
  convergence_ok <- !is.na(convergence) &&
    identical(as.integer(convergence), 0L)
  pd_hess_ok <- !is.na(pd_hess) && isTRUE(pd_hess)
  if (convergence_ok && pd_hess_ok) {
    return("fit_returned_converged_pdhess_true")
  }
  if (convergence_ok) {
    return("fit_returned_converged_pdhess_false")
  }
  if (pd_hess_ok) {
    return("fit_returned_nonconverged_pdhess_true")
  }
  "fit_returned_nonconverged_pdhess_false"
}

select_interval_targets <- function(targets, mode) {
  if (!nrow(targets) || identical(mode, "none")) {
    return(targets[0L, , drop = FALSE])
  }
  is_phylo_sd <- grepl("^sd:", targets$parm) &
    grepl("phylo", targets$parm, fixed = TRUE)
  selected <- targets[is_phylo_sd, , drop = FALSE]
  if (identical(mode, "all_q4")) {
    return(selected)
  }
  is_sigma_phylo <- grepl("sigma[12]", selected$parm)
  selected <- selected[is_sigma_phylo, , drop = FALSE]
  if (identical(mode, "first_sigma") && nrow(selected) > 1L) {
    selected <- selected[1L, , drop = FALSE]
  }
  selected
}

run_profile <- function(
  fit,
  targets,
  cell,
  time_limit,
  profile_endpoint_max_eval,
  paths
) {
  if (!nrow(targets)) {
    return(invisible(NULL))
  }
  started <- Sys.time()
  captured <- capture_conditions(with_elapsed_limit(
    stats::confint(
      fit,
      parm = targets$parm,
      method = "profile",
      profile_endpoint_max_eval = profile_endpoint_max_eval
    ),
    time_limit
  ))
  elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  if (inherits(captured$value, "error")) {
    append_table(
      data.frame(
        cell = cell,
        phase = "profile",
        status = "error",
        elapsed_sec = elapsed,
        parm = paste(targets$parm, collapse = ";"),
        lower = NA_real_,
        upper = NA_real_,
        conf.status = NA_character_,
        profile.boundary = NA,
        profile.message = conditionMessage(captured$value),
        stringsAsFactors = FALSE
      ),
      paths$intervals
    )
  } else {
    ci <- safe_table(captured$value)
    ci <- cbind(
      cell = cell,
      phase = "profile",
      status = "ok",
      elapsed_sec = elapsed,
      ci,
      stringsAsFactors = FALSE
    )
    append_table(ci, paths$intervals)
  }
  append_table(
    bind_tables(list(
      condition_rows(cell, captured$warnings, "warning", "profile"),
      condition_rows(cell, captured$messages, "message", "profile")
    )),
    paths$conditions
  )
}

run_bootstrap <- function(
  fit,
  targets,
  cell,
  time_limit,
  bootstrap_replicates,
  bootstrap_seed,
  paths
) {
  if (!nrow(targets) || bootstrap_replicates < 1L) {
    return(invisible(NULL))
  }
  args <- list(
    object = fit,
    parm = targets$parm,
    method = "bootstrap",
    R = bootstrap_replicates
  )
  if (!is.null(bootstrap_seed)) {
    args$seed <- bootstrap_seed
  }
  started <- Sys.time()
  captured <- capture_conditions(with_elapsed_limit(
    do.call(stats::confint, args),
    time_limit
  ))
  elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  if (inherits(captured$value, "error")) {
    append_table(
      data.frame(
        cell = cell,
        phase = "bootstrap",
        status = "error",
        elapsed_sec = elapsed,
        parm = paste(targets$parm, collapse = ";"),
        lower = NA_real_,
        upper = NA_real_,
        conf.status = NA_character_,
        profile.boundary = NA,
        profile.message = conditionMessage(captured$value),
        bootstrap.n = bootstrap_replicates,
        bootstrap.failed = NA_integer_,
        stringsAsFactors = FALSE
      ),
      paths$intervals
    )
  } else {
    ci <- safe_table(captured$value)
    ci <- cbind(
      cell = cell,
      phase = "bootstrap",
      status = "ok",
      elapsed_sec = elapsed,
      ci,
      stringsAsFactors = FALSE
    )
    append_table(ci, paths$intervals)
  }
  append_table(
    bind_tables(list(
      condition_rows(cell, captured$warnings, "warning", "bootstrap"),
      condition_rows(cell, captured$messages, "message", "bootstrap")
    )),
    paths$conditions
  )
}

run_fit_cell <- function(dat, tree, size_label, engine, reml, config, paths) {
  cell <- paste(size_label, engine, paste0("REML_", reml), sep = "|")
  formula <- make_ayumi_q4_formula(tree)
  args <- list(
    formula = formula,
    family = biv_gaussian(),
    data = dat,
    engine = engine,
    REML = reml
  )
  if (isTRUE(config$missing_include)) {
    args$missing <- miss_control(response = "include")
  }
  started <- Sys.time()
  captured <- capture_conditions(with_elapsed_limit(
    do.call(drmTMB, args),
    config$time_limit
  ))
  elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
  base <- data.frame(
    cell = cell,
    size = size_label,
    n = nrow(dat),
    tips = length(tree$tip.label),
    engine = engine,
    REML = reml,
    missing_response = if (config$missing_include) "include" else "default",
    phase = "fit",
    elapsed_sec = elapsed,
    stringsAsFactors = FALSE
  )
  if (inherits(captured$value, "error")) {
    append_table(
      cbind(
        base,
        status = "error",
        fit_summary(data.frame()),
        error = conditionMessage(captured$value),
        stringsAsFactors = FALSE
      ),
      paths$fits
    )
    append_table(
      bind_tables(list(
        condition_rows(cell, conditionMessage(captured$value), "error", "fit"),
        condition_rows(cell, captured$warnings, "warning", "fit"),
        condition_rows(cell, captured$messages, "message", "fit")
      )),
      paths$conditions
    )
    return(invisible(NULL))
  }
  fit <- captured$value
  append_table(
    cbind(
      base,
      status = "ok",
      fit_summary(fit),
      error = NA_character_,
      stringsAsFactors = FALSE
    ),
    paths$fits
  )
  append_table(
    bind_tables(list(
      condition_rows(cell, captured$warnings, "warning", "fit"),
      condition_rows(cell, captured$messages, "message", "fit")
    )),
    paths$conditions
  )

  targets <- tryCatch(profile_targets(fit), error = function(e) e)
  if (inherits(targets, "error")) {
    append_table(
      condition_rows(cell, conditionMessage(targets), "error", "targets"),
      paths$conditions
    )
    return(invisible(fit))
  }
  targets <- cbind(
    cell = cell,
    size = size_label,
    engine = engine,
    REML = reml,
    safe_table(targets),
    stringsAsFactors = FALSE
  )
  append_table(targets, paths$targets)
  selected <- select_interval_targets(targets, config$profile)
  run_profile(
    fit,
    selected,
    cell,
    config$time_limit,
    config$profile_endpoint_max_eval,
    paths
  )
  bootstrap_targets <- select_interval_targets(
    targets,
    config$bootstrap_targets
  )
  run_bootstrap(
    fit,
    bootstrap_targets,
    cell,
    config$time_limit,
    config$bootstrap_replicates,
    config$bootstrap_seed,
    paths
  )
  invisible(fit)
}

write_metadata <- function(paths, config, input_path) {
  dir.create(dirname(paths$metadata), recursive = TRUE, showWarnings = FALSE)
  info <- Sys.info()
  lines <- c(
    "# Ayumi q4 Status Harness Metadata",
    "",
    paste0("- run_start: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
    paste0("- input: ", normalizePath(input_path, mustWork = FALSE)),
    paste0("- repo: ", repo_root),
    paste0("- git_head: ", git_output(c("rev-parse", "HEAD"))),
    paste0("- git_dirty: ", nzchar(git_output(c("status", "--porcelain")))),
    paste0("- R.version: ", R.version.string),
    paste0("- drmTMB: ", package_version_or_na("drmTMB")),
    paste0("- TMB: ", package_version_or_na("TMB")),
    paste0("- ape: ", package_version_or_na("ape")),
    paste0("- JuliaCall: ", package_version_or_na("JuliaCall")),
    paste0(
      "- system: ",
      paste(info[c("sysname", "release", "machine")], collapse = " ")
    ),
    paste0(
      "- sizes: ",
      paste(
        vapply(
          config$sizes,
          function(x) if (is.na(x)) "all" else as.character(x),
          character(1L)
        ),
        collapse = ","
      )
    ),
    paste0("- engines: ", paste(config$engines, collapse = ",")),
    paste0("- REML: ", paste(config$reml, collapse = ",")),
    paste0("- profile: ", config$profile),
    paste0("- bootstrap_replicates: ", config$bootstrap_replicates),
    paste0("- bootstrap_targets: ", config$bootstrap_targets),
    paste0(
      "- bootstrap_seed: ",
      if (is.null(config$bootstrap_seed)) {
        "NULL"
      } else {
        config$bootstrap_seed
      }
    ),
    paste0(
      "- profile_endpoint_max_eval: ",
      if (is.null(config$profile_endpoint_max_eval)) {
        "NULL"
      } else {
        config$profile_endpoint_max_eval
      }
    ),
    paste0(
      "- missing_response: ",
      if (config$missing_include) "include" else "default"
    ),
    paste0("- time_limit_sec: ", config$time_limit),
    paste0("- OMP_NUM_THREADS: ", Sys.getenv("OMP_NUM_THREADS")),
    paste0("- OPENBLAS_NUM_THREADS: ", Sys.getenv("OPENBLAS_NUM_THREADS")),
    paste0("- MKL_NUM_THREADS: ", Sys.getenv("MKL_NUM_THREADS")),
    paste0("- VECLIB_MAXIMUM_THREADS: ", Sys.getenv("VECLIB_MAXIMUM_THREADS")),
    paste0("- JULIA_HOME: ", Sys.getenv("JULIA_HOME")),
    ""
  )
  writeLines(lines, paths$metadata)
}

if (
  env_flag("DRMTMB_AYUMI_Q4_HELP", FALSE) ||
    "--help" %in% commandArgs(trailingOnly = TRUE)
) {
  usage()
  quit(status = 0L)
}

input_path <- env_chr("DRMTMB_AYUMI_Q4_RDS", "")
if (!nzchar(input_path)) {
  usage()
  stop("Set DRMTMB_AYUMI_Q4_RDS before running.", call. = FALSE)
}

require_package("ape", "prune the phylogenetic tree")
load_drmtmb()

pin_threads <- env_flag("DRMTMB_AYUMI_Q4_PIN_THREADS", TRUE)
if (pin_threads) {
  Sys.setenv(
    OMP_NUM_THREADS = env_chr("OMP_NUM_THREADS", "1"),
    OPENBLAS_NUM_THREADS = env_chr("OPENBLAS_NUM_THREADS", "1"),
    MKL_NUM_THREADS = env_chr("MKL_NUM_THREADS", "1"),
    VECLIB_MAXIMUM_THREADS = env_chr("VECLIB_MAXIMUM_THREADS", "1")
  )
  if (requireNamespace("TMB", quietly = TRUE)) {
    invisible(capture.output(try(TMB::openmp(1L), silent = TRUE)))
  }
}

out_dir <- env_chr(
  "DRMTMB_AYUMI_Q4_OUT",
  file.path(
    "docs",
    "dev-log",
    "ayumi-q4-status",
    format(Sys.time(), "%Y%m%d-%H%M%S")
  )
)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
paths <- list(
  fits = file.path(out_dir, "fits.csv"),
  targets = file.path(out_dir, "profile-targets.csv"),
  intervals = file.path(out_dir, "intervals.csv"),
  conditions = file.path(out_dir, "conditions.csv"),
  metadata = file.path(out_dir, "metadata.md")
)
config <- list(
  sizes = parse_sizes(env_chr("DRMTMB_AYUMI_Q4_SIZES", "250,500,1000")),
  engines = split_csv(tolower(env_chr("DRMTMB_AYUMI_Q4_ENGINES", "tmb"))),
  reml = parse_reml(env_chr("DRMTMB_AYUMI_Q4_REML", "false,true")),
  profile = match.arg(
    env_chr("DRMTMB_AYUMI_Q4_PROFILE", "none"),
    c("none", "first_sigma", "all_sigma")
  ),
  time_limit = env_num("DRMTMB_AYUMI_Q4_TIME_LIMIT", 0),
  profile_endpoint_max_eval = env_whole(
    "DRMTMB_AYUMI_Q4_PROFILE_ENDPOINT_MAX_EVAL",
    NULL
  ),
  bootstrap_replicates = env_whole("DRMTMB_AYUMI_Q4_BOOTSTRAP", 0L),
  bootstrap_targets = match.arg(
    env_chr(
      "DRMTMB_AYUMI_Q4_BOOTSTRAP_TARGETS",
      if (env_whole("DRMTMB_AYUMI_Q4_BOOTSTRAP", 0L) > 0L) {
        "all_q4"
      } else {
        "none"
      }
    ),
    c("none", "first_sigma", "all_sigma", "all_q4")
  ),
  bootstrap_seed = env_whole("DRMTMB_AYUMI_Q4_BOOTSTRAP_SEED", NULL),
  missing_include = env_flag("DRMTMB_AYUMI_Q4_MISSING_INCLUDE", TRUE)
)
if (config$bootstrap_replicates < 0L) {
  stop("DRMTMB_AYUMI_Q4_BOOTSTRAP must be non-negative.", call. = FALSE)
}

columns <- list(
  y1 = env_chr("DRMTMB_AYUMI_Q4_Y1", "Tarsus_Length_z"),
  y2 = env_chr("DRMTMB_AYUMI_Q4_Y2", "Beak_Length_Culmen_z"),
  temp = env_chr("DRMTMB_AYUMI_Q4_TEMP", "mean_tavg_combined_z"),
  prec = env_chr("DRMTMB_AYUMI_Q4_PREC", "mean_prec_combined_z"),
  mass = env_chr("DRMTMB_AYUMI_Q4_MASS", "log_mass_z"),
  id = env_chr("DRMTMB_AYUMI_Q4_ID", "phylo_id")
)

write_metadata(paths, config, input_path)

payload <- readRDS(input_path)
dat <- clean_model_data(
  find_component(payload, c("data", "dat", "df"), "data"),
  columns
)
tree <- find_component(payload, c("tree", "phylo", "pruned_tree"), "tree")
if (!inherits(tree, "phylo")) {
  stop("The tree component is not an `ape::phylo` object.", call. = FALSE)
}

for (size in config$sizes) {
  subset <- subset_by_tree(dat, tree, size)
  for (engine in config$engines) {
    for (reml in config$reml) {
      message(
        "Running size=",
        subset$size_label,
        " engine=",
        engine,
        " REML=",
        reml
      )
      run_fit_cell(
        dat = subset$data,
        tree = subset$tree,
        size_label = subset$size_label,
        engine = engine,
        reml = reml,
        config = config,
        paths = paths
      )
    }
  }
}

message("Wrote Ayumi q4 status harness outputs to ", out_dir)
