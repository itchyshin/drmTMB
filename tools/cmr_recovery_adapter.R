# Route adapter for fitting one generated data bundle under a frozen CMR cell.
# Data generation and campaign accounting stay outside this function so both
# native packages can consume the same literal history and predictor files.
# Recovery fits default to the bounded nlminb limits used by the preregistered
# pre-run. A fit is usable only when its individual-effect quadrature refined.

.cmr_recovery_formula <- function(x, name) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    stop("frozen cell `", name, "` must be one formula string.", call. = FALSE)
  }
  stats::as.formula(x, env = parent.frame())
}

cmr_recovery_bundle_from_files <- function(directory, cell, common_design) {
  required_files <- c("histories.csv", "phi_predictors.csv", "p_predictors.csv",
                      "truth.csv", "eligibility.csv")
  paths <- file.path(directory, required_files)
  missing <- !file.exists(paths)
  if (any(missing)) {
    stop("generated CMR bundle is missing: ", paste(required_files[missing], collapse = ", "),
         call. = FALSE)
  }
  read_table <- function(name, columns, classes, optional_append = character(),
                         optional_classes = character()) {
    path <- file.path(directory, name)
    header <- names(utils::read.csv(path, nrows = 0L, check.names = FALSE))
    valid_schemas <- if (length(optional_append)) {
      list(columns, c(columns, optional_append))
    } else {
      list(columns)
    }
    schema_index <- which(vapply(valid_schemas, identical, logical(1), y = header))
    if (length(schema_index) != 1L) {
      stop("generated CMR table schema mismatch in ", name, call. = FALSE)
    }
    if (length(optional_append) && schema_index == 2L) {
      classes <- c(classes, optional_classes)
    }
    table <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE,
                             na.strings = "", colClasses = classes)
    table
  }
  histories <- read_table("histories.csv",
    c("cell", "replicate", "id", "occasion", "capture", "observed", "first_capture", "admin_end", "units", "year"),
    c("character", "integer", "character", "integer", "numeric", "integer", "integer", "integer", "character", "character"))
  phi_predictors <- read_table("phi_predictors.csv",
    c("cell", "replicate", "id", "interval_start", "interval_end", "interval_length", "x_phi", "site", "year"),
    c("character", "integer", "character", "integer", "integer", "numeric", "numeric", "character", "character"))
  p_predictors <- read_table("p_predictors.csv",
    c("cell", "replicate", "id", "occasion", "z_p", "observed", "terminal_fixed", "site", "year"),
    c("character", "integer", "character", "integer", "numeric", "integer", "integer", "character", "character"))
  truth <- read_table("truth.csv", c("cell", "replicate", "id", "parameter", "value"),
    c("character", "integer", "character", "character", "character"))
  eligibility <- read_table("eligibility.csv",
    c("cell", "replicate", "id", "entry", "first_capture", "admin_end", "eligible", "retention_probability", "eligible_start_count"),
    c("character", "integer", "character", "integer", "integer", "integer", "integer", "numeric", "integer"),
    optional_append = c("profile_x", "profile_z", "profile_retained_count",
                        "profile_eligible_start_count", "profile_retention_probability"),
    optional_classes = c("character", "character", "integer", "integer", "numeric"))
  tables <- list(histories, phi_predictors, p_predictors, truth, eligibility)
  expected_cell <- as.character(cell$cell)
  expected_replicate <- unique(histories$replicate)
  if (length(expected_cell) != 1L || is.na(expected_cell) || !nzchar(expected_cell) ||
      length(expected_replicate) != 1L || is.na(expected_replicate) ||
      any(vapply(tables, function(x) nrow(x) > 0L &&
                   (any(x$cell != expected_cell) || any(x$replicate != expected_replicate)), logical(1)))) {
    stop("generated CMR tables do not match the requested cell and replicate.", call. = FALSE)
  }
  # JSON false is a non-NULL logical in ordinary cells; only the selection
  # metadata object denotes the conditional-selection route.
  selected <- is.list(cell$selection)
  selection <- NULL
  if (selected) {
    if (!nrow(eligibility) || anyDuplicated(eligibility$id) || !setequal(eligibility$id, histories$id)) {
      stop("selection eligibility CSV must contain one retained record per history id.", call. = FALSE)
    }
    selection <- data.frame(id = eligibility$id, eligibility = eligibility$entry,
                            assumption = "alive_available", stringsAsFactors = FALSE)
    target_first <- .cmr_recovery_numeric_vector(cell$selection$first_capture)
    target_eligibility <- .cmr_recovery_numeric_vector(cell$selection$eligibility)
    if (!is.null(target_first) &&
        (length(target_first) != 1L || any(eligibility$first_capture != target_first))) {
      stop("selection first_capture target does not match every retained history.", call. = FALSE)
    }
    if (!is.null(target_eligibility) &&
        (anyNA(target_eligibility) || any(!eligibility$entry %in% target_eligibility))) {
      stop("selection eligibility metadata does not include every retained entry occasion.",
           call. = FALSE)
    }
  }
  list(histories = histories, phi_predictors = phi_predictors,
       p_predictors = p_predictors, truth = truth, eligibility = eligibility,
       selection = selection,
       intervals = .cmr_recovery_default(cell$intervals, common_design$intervals_regular))
}

.cmr_recovery_numeric_vector <- function(x) {
  if (is.null(x) || !length(x) || !is.numeric(unlist(x, use.names = FALSE))) return(NULL)
  as.numeric(unlist(x, use.names = FALSE))
}

.cmr_recovery_history_data <- function(bundle, common_design) {
  history <- bundle$histories
  required <- c("id", "occasion", "capture", "observed", "admin_end")
  if (!is.data.frame(history) || !all(required %in% names(history))) {
    stop("CMR bundle histories require id, occasion, capture, observed, and admin_end columns.", call. = FALSE)
  }
  if (!nrow(history) || anyNA(history$id) || anyNA(history$occasion) || anyNA(history$observed)) {
    stop("CMR bundle histories must contain nonmissing ids, occasions, and survey masks.", call. = FALSE)
  }
  if (anyDuplicated(history[c("id", "occasion")])) {
    stop("duplicate id and occasion keys in CMR bundle histories.", call. = FALSE)
  }
  ids <- unique(history$id)
  intervals <- bundle$intervals
  if (is.null(intervals)) intervals <- common_design$intervals_regular
  intervals <- as.numeric(unlist(intervals, use.names = FALSE))
  if (!length(intervals) || any(!is.finite(intervals)) || any(intervals <= 0)) {
    stop("CMR bundle intervals must be positive finite durations.", call. = FALSE)
  }
  if (any(!is.finite(history$occasion)) || any(history$occasion < 1L) ||
      any(history$occasion != as.integer(history$occasion))) {
    stop("CMR bundle occasion keys must be positive whole-number indices.", call. = FALSE)
  }
  occasions <- seq_len(length(intervals) + 1L)
  if (max(history$occasion) > length(occasions)) {
    stop("CMR bundle occasion exceeds the interval schedule.", call. = FALSE)
  }
  ends_by_id <- lapply(ids, function(id) unique(history$admin_end[history$id == id]))
  if (any(lengths(ends_by_id) != 1L) ||
      any(vapply(ends_by_id, function(x) length(x) != 1L || is.na(x) ||
                   !is.finite(x) || x != as.integer(x) || x < 1L || x > length(occasions),
                 logical(1)))) {
    stop("each CMR history must have one valid administrative end.", call. = FALSE)
  }
  ends <- as.integer(vapply(ends_by_id, `[[`, history$admin_end[1], 1L))
  for (i in seq_along(ids)) {
    seen <- as.integer(history$occasion[history$id == ids[[i]]])
    if (!identical(sort(seen), seq_len(ends[[i]]))) {
      stop("each CMR history must include exactly one row from occasion 1 through its administrative end.",
           call. = FALSE)
    }
  }
  row_index <- match(history$id, ids)
  occasion_index <- as.integer(history$occasion)
  y <- matrix(NA_real_, nrow = length(ids), ncol = length(occasions),
              dimnames = list(as.character(ids), as.character(occasions)))
  observed <- matrix(FALSE, nrow = length(ids), ncol = length(occasions),
                     dimnames = dimnames(y))
  mask <- as.logical(history$observed)
  if (anyNA(mask)) stop("CMR survey mask must be logical or zero/one.", call. = FALSE)
  captures <- suppressWarnings(as.numeric(history$capture))
  if (any(mask & (!is.finite(captures) | !captures %in% c(0, 1)))) {
    stop("observed CMR capture values must be zero or one.", call. = FALSE)
  }
  observed[cbind(row_index, occasion_index)] <- mask
  y[cbind(row_index[mask], occasion_index[mask])] <- captures[mask]

  frequency <- NULL
  if ("frequency" %in% names(history)) {
    per_id_frequency <- lapply(ids, function(id) unique(history$frequency[history$id == id]))
    if (any(lengths(per_id_frequency) != 1L) || any(vapply(per_id_frequency, function(x) anyNA(x) || x[[1L]] < 1, logical(1)))) {
      stop("each CMR history must have one positive frequency.", call. = FALSE)
    }
    frequency <- as.integer(vapply(per_id_frequency, `[[`, history$frequency[1], 1L))
  }
  data_args <- list(histories = y, id = ids, observed = observed, occasions = occasions,
                    intervals = intervals, units = "years", end = ends)
  if (!is.null(frequency)) data_args$frequency <- frequency
  data <- do.call(cmr_data, data_args)
  if ("first_capture" %in% names(history)) {
    declared <- lapply(ids, function(id) unique(history$first_capture[history$id == id]))
    if (any(lengths(declared) != 1L) || any(vapply(declared, function(x) anyNA(x), logical(1)))) {
      stop("each CMR history must have one nonmissing first_capture value.", call. = FALSE)
    }
    declared <- as.integer(vapply(declared, `[[`, history$first_capture[1], 1L))
    if (!identical(declared, data$first)) {
      stop("declared first_capture values do not match the realized histories.", call. = FALSE)
    }
  }
  data
}

.cmr_recovery_selection <- function(bundle, cell, ids) {
  # Manifest ordinary cells encode selection as JSON false, which R reads as
  # a non-NULL logical. Only the metadata object selects this route.
  if (!is.list(cell$selection)) return(NULL)
  selection <- bundle$selection
  required <- c("id", "eligibility", "assumption")
  if (!is.data.frame(selection) || !all(required %in% names(selection))) {
    stop("selection-route bundle requires id, eligibility, and assumption columns.", call. = FALSE)
  }
  if (anyDuplicated(selection$id) || !setequal(selection$id, ids)) {
    stop("selection eligibility must have exactly one row for each history id.", call. = FALSE)
  }
  selection <- selection[match(ids, selection$id), , drop = FALSE]
  if (anyNA(selection$eligibility) || any(selection$assumption != "alive_available")) {
    stop("selection bundle requires known eligibility and the alive_available assumption.", call. = FALSE)
  }
  target_first <- .cmr_recovery_numeric_vector(cell$selection$first_capture)
  if (!is.null(target_first) &&
      (length(target_first) != 1L || any(bundle$histories$first_capture != target_first))) {
    stop("selection first_capture target does not match every retained history.", call. = FALSE)
  }
  target_eligibility <- .cmr_recovery_numeric_vector(cell$selection$eligibility)
  if (!is.null(target_eligibility) &&
      (anyNA(target_eligibility) || any(!selection$eligibility %in% target_eligibility))) {
    stop("selection eligibility metadata does not include every retained entry occasion.",
         call. = FALSE)
  }
  list(eligibility = as.integer(selection$eligibility), assumption = "alive_available")
}

cmr_recovery_fit_adapter <- function(bundle, cell, common_design, fit_fun = NULL,
                                     control = list(iter.max = 120L, eval.max = 180L)) {
  if (!is.list(bundle) || !is.list(cell) || !is.list(common_design)) {
    stop("bundle, frozen cell, and common design must be lists.", call. = FALSE)
  }
  if (is.null(fit_fun)) fit_fun <- drm_cjs
  if (!is.function(fit_fun)) stop("fit_fun must be a function.", call. = FALSE)
  if (!is.list(control)) stop("control must be a list of `nlminb()` controls.", call. = FALSE)
  control <- utils::modifyList(list(iter.max = 120L, eval.max = 180L), control)
  data <- .cmr_recovery_history_data(bundle, common_design)
  if (!all(c("phi_predictors", "p_predictors") %in% names(bundle)) ||
      !is.data.frame(bundle$phi_predictors) || !is.data.frame(bundle$p_predictors)) {
    stop("CMR bundle requires keyed phi_predictors and p_predictors data frames.", call. = FALSE)
  }
  selection <- .cmr_recovery_selection(bundle, cell, data$id)
  fit_args <- list(
    data = data,
    phi = .cmr_recovery_formula(cell$phi, "phi"),
    p = .cmr_recovery_formula(cell$p, "p"),
    phi_data = bundle$phi_predictors,
    p_data = bundle$p_predictors,
    selection = selection,
    terminal_constraint = common_design$terminal_constraint,
    control = control
  )
  if (!is.null(cell$sd_phi)) fit_args$sd_phi <- .cmr_recovery_formula(cell$sd_phi, "sd_phi")
  if (!is.null(cell$sd_p)) fit_args$sd_p <- .cmr_recovery_formula(cell$sd_p, "sd_p")

  started <- Sys.time()
  elapsed_start <- proc.time()[["elapsed"]]
  fit_error <- NULL
  fit <- tryCatch(do.call(fit_fun, fit_args), error = function(e) {
    fit_error <<- conditionMessage(e)
    NULL
  })
  elapsed <- proc.time()[["elapsed"]] - elapsed_start
  converged <- !is.null(fit) && identical(as.integer(fit$convergence), 0L)
  gradient_norm <- if (is.null(fit)) NA_real_ else as.numeric(fit$gradient_norm)
  refinement_status <- if (is.null(fit)) "not_run" else {
    value <- fit$random_effects$integration$status
    if (is.null(value) || !length(value) || is.na(value[[1L]])) "missing" else as.character(value[[1L]])
  }
  individual_route <- startsWith(as.character(cell$route), "individual_")
  integration_refined <- !individual_route || identical(refinement_status, "refined")
  usable <- converged && length(gradient_norm) == 1L && is.finite(gradient_norm) && gradient_norm <= 1e-4 &&
    length(fit$logLik) == 1L && is.finite(fit$logLik) && integration_refined
  sd <- if (is.null(fit)) NULL else fit$random_effects$sd
  sd_value <- function(key) {
    if (is.null(sd)) return(NA_real_)
    value <- if (is.list(sd)) sd[[key]] else sd[[key]]
    if (length(value) > 1L && all(is.finite(value)) && all(value == value[[1L]])) {
      return(unname(value[[1L]]))
    }
    unname(value)
  }
  extra_estimates <- list()
  if (!is.null(fit)) for (process in c("phi", "p")) {
    if (!is.null(cell[[paste0("sd_", process)]])) {
      if (!exists("cmr_sd_recovery_coefficients", mode = "function", inherits = TRUE))
        stop("SD recovery needs tools/cmr_sd_recovery_extract.R loaded before the route adapter.", call. = FALSE)
      gamma <- cmr_sd_recovery_coefficients(fit, process)
      expected <- paste0("gamma", 0:1, "_", process)
      if (identical(as.character(cell$route), "individual_pair_sd") &&
          !identical(names(gamma), expected))
        stop("SD recovery lacks the verified intercept-plus-predictor coefficient map for ", process, ".", call. = FALSE)
      extra_estimates[[paste0("log_sd_coefficients_", process)]] <- gamma
      for (name in intersect(names(gamma), expected)) extra_estimates[[name]] <- unname(gamma[[name]])
    }
  }
  list(
    cell = as.character(cell$cell),
    route = as.character(cell$route),
    status = if (usable) "usable" else if (is.null(fit)) "error" else "unusable",
    converged = converged,
    gradient_norm = gradient_norm,
    logLik = if (is.null(fit)) NA_real_ else as.numeric(fit$logLik),
    elapsed_seconds = elapsed,
    started_utc = format(started, tz = "UTC", usetz = TRUE),
    estimates = if (is.null(fit)) NULL else c(list(
      beta_phi = fit$coefficients$phi,
      beta_p = fit$coefficients$p,
      sd_phi = sd_value("phi"),
      sd_p = sd_value("p")
    ), extra_estimates),
    inner_mode_status = if (is.null(fit)) "not_run" else fit$random_effects$laplace_status,
    hessian_status = if (is.null(fit)) "not_run" else fit$random_effects$inner_diagnostics_status,
    quadrature_order = if (is.null(fit)) NA_integer_ else fit$random_effects$integration$selected_order,
    refinement_status = refinement_status,
    boundary_status = if (is.null(fit)) "not_run" else if (any(c(sd_value("phi"), sd_value("p")) == 0, na.rm = TRUE)) "at_zero" else "interior_or_not_applicable",
    interval_status = "unavailable",
    failure_stage = if (is.null(fit)) "fit" else if (usable) "none" else "fit_diagnostics",
    failure_code = if (is.null(fit)) "fit_error" else if (usable) "none" else "unusable_fit",
    failure_message = if (is.null(fit)) fit_error else if (usable) "" else if (!integration_refined) {
      paste0("quadrature refinement was not established (status: ", refinement_status, ")")
    } else as.character(if (is.null(fit$message)) "fit failed declared usability checks" else fit$message),
    fit = fit,
    fit_arguments = fit_args
  )
}

.cmr_recovery_json_numbers <- function(x) {
  if (is.null(x)) return(NULL)
  if (is.numeric(x)) {
    if (length(x) == 1L) return(if (is.finite(x)) unname(as.numeric(x)) else NULL)
    out <- lapply(as.list(x), .cmr_recovery_json_numbers)
    names(out) <- names(x)
    return(out)
  }
  if (is.list(x)) return(lapply(x, .cmr_recovery_json_numbers))
  if (is.logical(x) && length(x) == 1L) return(unname(x))
  if (is.character(x) && length(x) == 1L) return(unname(x))
  NULL
}

.cmr_recovery_default <- function(x, fallback) {
  if (is.null(x) || !length(x)) fallback else x
}

cmr_recovery_route_fitters <- function(common_design, fit_fun = NULL,
                                       control = list(iter.max = 120L, eval.max = 180L)) {
  routes <- c("fixed", "shared_site_phi", "shared_site_p", "shared_site_pair",
              "shared_year_pair", "individual_phi", "individual_p", "individual_pair",
              "individual_pair_sd", "individual_pair_selection")
  callbacks <- lapply(routes, function(route) {
    force(route)
    function(bundle, cell, seed, stage, replicate) {
      if (!identical(as.character(cell$route), route)) {
        stop(sprintf("CMR route callback %s received cell route %s.", route,
                     paste(cell$route, collapse = ",")), call. = FALSE)
      }
      result <- cmr_recovery_fit_adapter(bundle, cell, common_design,
                                         fit_fun = fit_fun, control = control)
      list(
        converged = isTRUE(result$converged),
        gradient_norm = .cmr_recovery_json_numbers(result$gradient_norm),
        inner_mode_status = as.character(.cmr_recovery_default(result$inner_mode_status, "not_run")),
        hessian_status = as.character(.cmr_recovery_default(result$hessian_status, "not_run")),
        quadrature_order = .cmr_recovery_json_numbers(result$quadrature_order),
        refinement_status = as.character(.cmr_recovery_default(result$refinement_status, "not_run")),
        boundary_status = as.character(.cmr_recovery_default(result$boundary_status, "unknown")),
        interval_status = as.character(.cmr_recovery_default(result$interval_status, "unavailable")),
        loglik = .cmr_recovery_json_numbers(result$logLik),
        estimates = .cmr_recovery_default(.cmr_recovery_json_numbers(result$estimates), list()),
        failure_stage = as.character(.cmr_recovery_default(result$failure_stage, "unknown")),
        failure_code = as.character(.cmr_recovery_default(result$failure_code, "unknown")),
        failure_message = as.character(.cmr_recovery_default(result$failure_message, "")),
        usable = identical(result$status, "usable"),
        fit_attempted = TRUE,
        elapsed_seconds = .cmr_recovery_json_numbers(result$elapsed_seconds),
        started_utc = as.character(.cmr_recovery_default(result$started_utc, ""))
      )
    }
  })
  names(callbacks) <- routes
  callbacks
}

# Read one literal bundle and dispatch it through the registered route callback.
# This is deliberately a single-attempt seam: stage accounting and campaign
# authorization belong to the caller, while this function never generates data
# or starts a fit outside the selected mockable callback.
cmr_recovery_attempt_from_files <- function(directory, cell, common_design,
                                            fitters = cmr_recovery_route_fitters(common_design),
                                            seed, stage, replicate) {
  if (!is.list(cell) || length(cell$route) != 1L || is.na(cell$route) ||
      !nzchar(as.character(cell$route))) {
    stop("frozen CMR cell must declare one route.", call. = FALSE)
  }
  route <- as.character(cell$route)
  if (!is.list(fitters) || is.null(fitters[[route]]) || !is.function(fitters[[route]])) {
    stop(sprintf("no registered CMR fitter for route `%s`.", route), call. = FALSE)
  }
  if (length(seed) != 1L || is.na(seed) || !is.finite(seed) || seed != as.integer(seed) ||
      length(replicate) != 1L || is.na(replicate) || !is.finite(replicate) ||
      replicate < 1 || replicate != as.integer(replicate) ||
      length(stage) != 1L || is.na(stage) || !nzchar(stage)) {
    stop("CMR attempt requires a finite integer seed, positive integer replicate, and nonempty stage.",
         call. = FALSE)
  }
  bundle <- cmr_recovery_bundle_from_files(directory, cell, common_design)
  fitters[[route]](bundle, cell, seed = as.integer(seed), stage = as.character(stage),
                   replicate = as.integer(replicate))
}

.cmr_recovery_cli_scalar <- function(line, key) {
  pattern <- if (key %in% c("cell", "stage")) {
    paste0('"', key, '"\\s*:\\s*"([^"]*)"')
  } else {
    paste0('"', key, '"\\s*:\\s*([0-9]+)')
  }
  match <- regexec(pattern, line, perl = TRUE)
  value <- regmatches(line, match)[[1L]]
  if (length(value) != 2L) stop("generator output is missing metadata field `", key, "`.", call. = FALSE)
  value[[2L]]
}

.cmr_recovery_file_sha256 <- function(path) {
  command <- if (nzchar(Sys.which("sha256sum"))) {
    "sha256sum"
  } else if (nzchar(Sys.which("shasum"))) {
    "shasum"
  } else {
    stop("SHA-256 verification requires sha256sum or shasum.", call. = FALSE)
  }
  args <- if (identical(command, "shasum")) c("-a", "256", shQuote(path)) else shQuote(path)
  output <- suppressWarnings(system2(command, args = args, stdout = TRUE, stderr = TRUE))
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) {
    stop("could not compute SHA-256 for generated file ", basename(path), ".", call. = FALSE)
  }
  hash <- strsplit(trimws(output[[1L]]), "[[:space:]]+")[[1L]][[1L]]
  if (!grepl("^[[:xdigit:]]{64}$", hash)) {
    stop("SHA-256 command returned malformed output for ", basename(path), ".", call. = FALSE)
  }
  tolower(hash)
}

.cmr_recovery_verify_generator_output <- function(line, directory, expected) {
  scalar <- list(cell = .cmr_recovery_cli_scalar(line, "cell"),
                 stage = .cmr_recovery_cli_scalar(line, "stage"),
                 replicate = as.integer(.cmr_recovery_cli_scalar(line, "replicate")),
                 seed = as.integer(.cmr_recovery_cli_scalar(line, "seed")))
  scalar_expected <- expected[intersect(names(expected), names(scalar))]
  if (!identical(scalar, scalar_expected)) {
    stop("shared CMR generator metadata does not match requested cell, stage, replicate, and seed.",
         call. = FALSE)
  }
  manifest_match <- regmatches(line, regexec('"manifest_sha256"\\s*:\\s*"([[:xdigit:]]{64})"',
                                             line, perl = TRUE))[[1L]]
  if (length(manifest_match) != 2L ||
      ("manifest_sha256" %in% names(expected) &&
       !identical(tolower(manifest_match[[2L]]), tolower(expected$manifest_sha256)))) {
    stop("shared CMR generator manifest hash is missing or differs from the frozen manifest.",
         call. = FALSE)
  }
  tables <- c("histories", "phi_predictors", "p_predictors", "truth", "eligibility")
  files <- paste0(tables, ".csv")
  hashes <- stats::setNames(vector("character", length(files)), files)
  rows <- stats::setNames(integer(length(tables)), tables)
  for (i in seq_along(files)) {
    hash_pattern <- paste0('"', files[[i]], '"\\s*:\\s*"([[:xdigit:]]{64})"')
    hash_match <- regmatches(line, regexec(hash_pattern, line, perl = TRUE))[[1L]]
    row_pattern <- paste0('"', tables[[i]], '"\\s*:\\s*([0-9]+)')
    row_match <- regmatches(line, regexec(row_pattern, line, perl = TRUE))[[1L]]
    if (length(hash_match) != 2L || length(row_match) != 2L) {
      stop("shared CMR generator metadata is missing SHA-256 or row count for ", files[[i]], ".",
           call. = FALSE)
    }
    path <- file.path(directory, files[[i]])
    if (!file.exists(path)) stop("shared CMR generator omitted ", files[[i]], ".", call. = FALSE)
    expected_hash <- tolower(hash_match[[2L]])
    actual_hash <- .cmr_recovery_file_sha256(path)
    if (!identical(actual_hash, expected_hash)) {
      stop("shared CMR generator SHA-256 mismatch for ", files[[i]], ".", call. = FALSE)
    }
    expected_rows <- as.integer(row_match[[2L]])
    actual_rows <- nrow(utils::read.csv(path, stringsAsFactors = FALSE,
                                       check.names = FALSE, na.strings = ""))
    if (!identical(actual_rows, expected_rows)) {
      stop("shared CMR generator row-count mismatch for ", files[[i]], ".", call. = FALSE)
    }
    hashes[[i]] <- actual_hash
    rows[[i]] <- actual_rows
  }
  list(cell = scalar$cell, stage = scalar$stage, replicate = scalar$replicate,
       seed = scalar$seed, rows = rows, sha256 = hashes)
}

# Generate one CLI-authorized dataset, verify the generator receipt, then pass
# its literal CSVs to the same mockable route callback used by file dispatch.
cmr_recovery_attempt_from_generator <- function(generator, directory, cell,
                                                common_design,
                                                fitters = cmr_recovery_route_fitters(common_design),
                                                seed, stage, replicate,
                                                python = Sys.which("python3"), manifest = NULL) {
  if (!is.character(generator) || length(generator) != 1L || is.na(generator) ||
      !file.exists(generator)) stop("generator must name an existing generate.py file.", call. = FALSE)
  if (!is.character(python) || length(python) != 1L || is.na(python) || !nzchar(python)) {
    stop("python must name an available Python executable.", call. = FALSE)
  }
  if (!is.character(directory) || length(directory) != 1L || is.na(directory) || !nzchar(directory)) {
    stop("directory must name a nonempty output path.", call. = FALSE)
  }
  if (is.null(manifest)) {
    package_root <- normalizePath(file.path(dirname(generator), "..", ".."))
    manifest <- file.path(package_root, "docs", "dev-log", "cmr", "fixtures", "recovery-manifest-v5.json")
  }
  if (!is.character(manifest) || length(manifest) != 1L || is.na(manifest) || !file.exists(manifest)) {
    stop("manifest must name an existing frozen CMR manifest.", call. = FALSE)
  }
  manifest <- normalizePath(manifest)
  manifest_sha256 <- .cmr_recovery_file_sha256(manifest)
  if (!is.list(cell) || length(cell$cell) != 1L || is.na(cell$cell) ||
      !nzchar(as.character(cell$cell)) || length(cell$route) != 1L || is.na(cell$route)) {
    stop("frozen CMR cell must declare one cell name and one route.", call. = FALSE)
  }
  route <- as.character(cell$route)
  if (!is.list(fitters) || is.null(fitters[[route]]) || !is.function(fitters[[route]])) {
    stop(sprintf("no registered CMR fitter for route `%s`.", route), call. = FALSE)
  }
  if (length(seed) != 1L || is.na(seed) || !is.finite(seed) || seed != as.integer(seed) ||
      length(replicate) != 1L || is.na(replicate) || !is.finite(replicate) ||
      replicate < 1 || replicate != as.integer(replicate) ||
      length(stage) != 1L || is.na(stage) || !nzchar(stage)) {
    stop("CMR attempt requires a finite integer seed, positive integer replicate, and nonempty stage.",
         call. = FALSE)
  }
  if (dir.exists(directory) && length(list.files(directory, all.files = TRUE,
                                                 no.. = TRUE)) > 0L) {
    stop("generator output directory must be empty; refusing to reuse or overwrite prior data.",
         call. = FALSE)
  }
  if (!dir.exists(directory) && !dir.create(directory, recursive = TRUE)) {
    stop("could not create generator output directory.", call. = FALSE)
  }
  output <- suppressWarnings(system2(python,
    args = c(shQuote(normalizePath(generator)), "--cell", shQuote(as.character(cell$cell)),
             "--replicate", as.character(as.integer(replicate)), "--stage",
             shQuote(as.character(stage)), "--out", shQuote(normalizePath(directory)),
             "--manifest", shQuote(manifest)),
    stdout = TRUE, stderr = TRUE))
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L
  if (status != 0L) {
    stop("shared CMR generator failed (exit ", status, "): ", paste(output, collapse = "\n"),
         call. = FALSE)
  }
  json_lines <- trimws(output[startsWith(trimws(output), "{")])
  if (length(json_lines) != 1L) {
    stop("shared CMR generator did not emit exactly one metadata JSON line.", call. = FALSE)
  }
  expected <- list(cell = as.character(cell$cell), stage = as.character(stage),
                   replicate = as.integer(replicate), seed = as.integer(seed),
                   manifest_sha256 = manifest_sha256)
  metadata <- .cmr_recovery_verify_generator_output(json_lines[[1L]], directory, expected)
  attempt <- cmr_recovery_attempt_from_files(directory, cell, common_design,
    fitters = fitters, seed = seed, stage = stage, replicate = replicate)
  attempt$generator_metadata <- metadata
  attempt$generator_output <- json_lines[[1L]]
  attempt
}
