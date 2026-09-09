# Temporal AR1 structures deliberately have their own layout rather than using
# the sparse-precision provider interface.  The native likelihood needs the
# observed integer gaps, and an observation-to-state permutation lets it retain
# the user's original row order for fitted values and residuals.

empty_temporal_mu_structure <- function() {
  list(
    has = FALSE,
    type = "temporal",
    label = character(),
    group = NA_character_,
    time = NA_character_,
    structure = NA_character_,
    n_series = 0L,
    n_re = 0L,
    series_levels = character(),
    node_labels = character(),
    observation_node_index = integer(),
    observation_node_index0 = 0L,
    series_start0 = 0L,
    gap = 0L
  )
}

extract_gaussian_mu_temporal_term <- function(entry, dpar = entry$dpar) {
  terms <- flatten_plus_terms(entry$rhs)
  is_temporal <- vapply(
    terms,
    is_structured_marker_call,
    logical(1),
    name = "temporal"
  )
  if (!any(is_temporal)) {
    return(list(rhs = entry$rhs, term = NULL))
  }
  if (sum(is_temporal) > 1L) {
    cli::cli_abort(c(
      "Only one temporal AR1 effect is implemented in {.code {dpar}}.",
      "x" = "Use one term such as {.code temporal(1 | id, time = occasion, structure = \"ar1\").}"
    ))
  }
  temporal_terms <- Filter(
    function(x) identical(x$type, "temporal"),
    entry$structured
  )
  if (length(temporal_terms) != 1L) {
    cli::cli_abort("Internal formula parser error while extracting {.fn temporal}.")
  }
  list(rhs = rebuild_plus_terms(terms[!is_temporal]), term = temporal_terms[[1L]])
}

validate_temporal_raw_data <- function(term, data) {
  if (is.null(term)) {
    return(invisible(NULL))
  }
  required <- c(term$group, term$time)
  missing_columns <- setdiff(required, names(data))
  if (length(missing_columns) > 0L) {
    cli::cli_abort(c(
      "Temporal AR1 inputs must be columns in {.arg data}.",
      "x" = "Missing temporal column{?s}: {.val {missing_columns}}."
    ))
  }
  id <- data[[term$group]]
  occasion <- data[[term$time]]
  if (anyNA(id) || anyNA(occasion)) {
    cli::cli_abort(c(
      "Temporal AR1 identifiers and occasions must be complete before response omission.",
      "x" = "Column{?s} {.val {required}} contain missing value{?s}.",
      "i" = "Repair {.arg id} and {.arg time} metadata before fitting."
    ))
  }
  time_is_numeric <- is.numeric(occasion) &&
    !inherits(occasion, c("Date", "POSIXt", "difftime"))
  if (!time_is_numeric || any(!is.finite(occasion)) || any(occasion != round(occasion))) {
    cli::cli_abort(c(
      "Temporal AR1 occasions must be finite integers.",
      "x" = "{.arg {term$time}} cannot be a factor, date-time value, fractional value, or non-finite value.",
      "i" = "Use the original integer sampling occasion; its gaps are part of the AR1 model."
    ))
  }
  duplicate_key <- duplicated(data.frame(
    temporal_id = as.character(id),
    temporal_time = as.numeric(occasion),
    stringsAsFactors = FALSE
  ))
  if (any(duplicate_key)) {
    cli::cli_abort(c(
      "Temporal AR1 series-occasion keys must be unique before response omission.",
      "x" = "{sum(duplicate_key)} duplicated {.code ({term$group}, {term$time})} key{?s} found.",
      "i" = "Use one response per series and occasion, or aggregate the data before fitting."
    ))
  }
  invisible(NULL)
}

validate_temporal_gaussian_terms <- function(
  term,
  mu_re,
  sigma_re,
  sigma_rhs,
  data
) {
  if (is.null(term)) {
    return(invisible(NULL))
  }
  if (!is_intercept_one(sigma_rhs) || length(sigma_re$terms) > 0L) {
    cli::cli_abort(c(
      "Temporal AR1 Gaussian models currently require {.code sigma ~ 1}.",
      "i" = "Use a constant residual SD while temporal AR1 effects are fitted."
    ))
  }
  if (length(mu_re$terms) > 1L) {
    cli::cli_abort(c(
      "Temporal AR1 models allow at most one ordinary random intercept.",
      "x" = "Additional ordinary random effects are not implemented with {.fn temporal}."
    ))
  }
  if (length(mu_re$terms) == 1L) {
    ordinary <- mu_re$terms[[1L]]
    if (
      !identical(ordinary$type, "intercept") ||
        !is.null(ordinary$covariance_label) ||
        !identical(ordinary$group, term$group)
    ) {
      cli::cli_abort(c(
        "The ordinary random effect paired with {.fn temporal} must be {.code (1 | id)} using the same ID.",
        "x" = "Temporal group is {.val {term$group}}; requested ordinary term is {.code {ordinary$label}}.",
        "i" = "Use either no ordinary random effect or {.code (1 | {term$group})}."
      ))
    }
    if (length(unique(as.character(data[[term$group]]))) < 2L) {
      cli::cli_abort(c(
        "A temporal AR1 model with an ordinary random intercept requires multiple series.",
        "i" = "Fit AR1-only for one series, or provide observations from at least two IDs."
      ))
    }
  }
  invisible(NULL)
}

build_temporal_mu_structure <- function(term, data, has_ordinary_intercept = FALSE) {
  if (is.null(term)) {
    return(empty_temporal_mu_structure())
  }
  validate_temporal_raw_data(term, data)
  id <- as.character(data[[term$group]])
  occasion <- as.integer(data[[term$time]])
  series_levels <- unique(id)
  series_index <- match(id, series_levels)
  original_row <- seq_along(id)
  ordering <- order(series_index, occasion, original_row, method = "radix")
  ordered_series <- series_index[ordering]
  ordered_time <- occasion[ordering]
  starts <- c(which(!duplicated(ordered_series)), length(ordering) + 1L)
  n_series <- length(series_levels)
  gap <- integer(length(ordering))
  pairwise_lags <- integer()
  for (series in seq_len(n_series)) {
    from <- starts[[series]]
    to <- starts[[series + 1L]] - 1L
    time_series <- ordered_time[from:to]
    if (length(time_series) > 1L) {
      gap[(from + 1L):to] <- diff(time_series)
      pairwise_lags <- c(
        pairwise_lags,
        as.integer(abs(outer(time_series, time_series, "-"))[upper.tri(
          outer(time_series, time_series, "-"), diag = FALSE
        )])
      )
    }
  }
  distinct_lags <- sort(unique(pairwise_lags[pairwise_lags > 0L]))
  required_lags <- if (has_ordinary_intercept) 3L else 2L
  if (length(distinct_lags) < required_lags || !any(distinct_lags %% 2L == 1L)) {
    cli::cli_abort(c(
      "Temporal AR1 occasions do not provide the required lag variation.",
      "x" = "Found distinct positive lags {.val {distinct_lags}}; this model needs at least {required_lags}, including an odd lag.",
      "i" = "Keep genuine integer gaps and collect more distinct within-series occasions."
    ))
  }
  if (has_ordinary_intercept && n_series < 2L) {
    cli::cli_abort(c(
      "A temporal AR1 model with an ordinary random intercept requires multiple series.",
      "i" = "Fit AR1-only for one series, or provide observations from at least two IDs."
    ))
  }
  observation_node_index <- integer(nrow(data))
  observation_node_index[ordering] <- seq_along(ordering)
  list(
    has = TRUE,
    type = "temporal",
    label = paste0("temporal(1 | ", term$group, ", time = ", term$time, ", structure = \"ar1\")"),
    group = term$group,
    time = term$time,
    structure = term$structure,
    n_series = as.integer(n_series),
    n_re = as.integer(nrow(data)),
    series_levels = series_levels,
    node_labels = paste(id[ordering], occasion[ordering], sep = ":"),
    observation_node_index = observation_node_index,
    observation_node_index0 = observation_node_index - 1L,
    series_start0 = as.integer(starts - 1L),
    gap = gap
  )
}

temporal_mu_tmb_data <- function(spec) {
  temporal <- if (is.list(spec$structured)) spec$structured$temporal_mu else NULL
  if (!is.list(temporal) || !isTRUE(temporal$has)) {
    return(list(
      has_temporal_mu = 0L,
      temporal_mu_node_index = 0L,
      temporal_mu_series_start = 0L,
      temporal_mu_gap = 0L
    ))
  }
  list(
    has_temporal_mu = 1L,
    temporal_mu_node_index = temporal$observation_node_index0,
    temporal_mu_series_start = temporal$series_start0,
    temporal_mu_gap = temporal$gap
  )
}

drm_has_temporal_mu <- function(object) {
  is.list(object$model) &&
    is.list(object$model$structured) &&
    is.list(object$model$structured$temporal_mu) &&
    isTRUE(object$model$structured$temporal_mu$has)
}

temporal_mu_sd_label <- function(temporal) {
  paste0("temporal_sd: ", temporal$label)
}

drm_temporal_mean_target_parm <- function(object) {
  targets <- drm_profile_targets(object)
  targets$parm[
    targets$target_class == "fixed-effect" & targets$dpar == "mu"
  ]
}

validate_temporal_wald_parm <- function(object, parm) {
  allowed <- drm_temporal_mean_target_parm(object)
  requested <- if (is.null(parm)) allowed else as.character(parm)
  bad <- setdiff(requested, allowed)
  if (length(bad) > 0L) {
    cli::cli_abort(c(
      "Temporal AR1 confidence intervals are currently available only for mean regression coefficients.",
      "x" = "Unsupported temporal interval target{?s}: {.val {bad}}.",
      "i" = "Use {.val {allowed}} with {.code method = \"wald\"}."
    ))
  }
  requested
}

temporal_mu_contribution <- function(object) {
  temporal <- object$model$structured$temporal_mu
  values <- object$random_effects$temporal$values
  unname(values[temporal$observation_node_index])
}

drm_fresh_temporal_mu_values <- function(object) {
  temporal <- object$model$structured$temporal_mu
  sd <- unname(object$sdpars$mu[[temporal_mu_sd_label(temporal)]])
  phi <- unname(object$corpars$temporal[[temporal$label]])
  latent <- numeric(temporal$n_re)
  starts <- temporal$series_start0 + 1L
  for (series in seq_len(temporal$n_series)) {
    first <- starts[[series]]
    last <- starts[[series + 1L]] - 1L
    latent[[first]] <- stats::rnorm(1L)
    if (last > first) {
      for (node in (first + 1L):last) {
        transition <- phi^temporal$gap[[node]]
        latent[[node]] <- transition * latent[[node - 1L]] +
          sqrt(1 - transition^2) * stats::rnorm(1L)
      }
    }
  }
  values <- sd * latent
  unname(values[temporal$observation_node_index])
}
