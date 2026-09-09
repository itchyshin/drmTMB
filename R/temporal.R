# Temporal structures deliberately have their own layout rather than using
# the sparse-precision provider interface.  The native likelihood needs the
# observed gaps, and an observation-to-state permutation lets it retain
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

temporal_structure_name <- function(term) {
  paste("Temporal", toupper(term$structure))
}

drm_formula_has_temporal <- function(formula) {
  any(vapply(
    formula$entries,
    function(entry) {
      any(vapply(
        entry$structured,
        function(term) identical(term$type, "temporal"),
        logical(1)
      ))
    },
    logical(1)
  ))
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
      "Only one temporal effect is implemented in {.code {dpar}}.",
      "x" = "Use one term such as {.code temporal(1 | id, time = occasion, structure = \"ar1\")} or {.code temporal(1 | id, time = elapsed, structure = \"ou\").}"
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
      "{temporal_structure_name(term)} inputs must be columns in {.arg data}.",
      "x" = "Missing temporal column{?s}: {.val {missing_columns}}."
    ))
  }
  id <- data[[term$group]]
  occasion <- data[[term$time]]
  if (anyNA(id) || anyNA(occasion)) {
    cli::cli_abort(c(
      "{temporal_structure_name(term)} identifiers and times must be complete before response omission.",
      "x" = "Column{?s} {.val {required}} contain missing value{?s}.",
      "i" = "Repair {.arg id} and {.arg time} metadata before fitting."
    ))
  }
  time_is_numeric <- is.numeric(occasion) &&
    !inherits(occasion, c("Date", "POSIXt", "difftime"))
  if (!time_is_numeric || any(!is.finite(occasion))) {
    cli::cli_abort(c(
      "Temporal inputs must be finite numeric values.",
      "x" = "{.arg {term$time}} cannot be a factor, date-time value, or non-finite value."
    ))
  }
  if (identical(term$structure, "ar1") && any(occasion != round(occasion))) {
    cli::cli_abort(c(
      "Temporal AR1 occasions must be finite integers.",
      "x" = "{.arg {term$time}} cannot be fractional for {.val ar1}.",
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
      "{temporal_structure_name(term)} series-time keys must be unique before response omission.",
      "x" = "{sum(duplicate_key)} duplicated {.code ({term$group}, {term$time})} key{?s} found.",
      "i" = "Use one response per series and occasion, or aggregate the data before fitting."
    ))
  }
  invisible(NULL)
}

# The first phylogenetic-temporal provider is additive: a stable phylogenetic
# intercept plus independent OU paths within each species.  It is intentionally
# distinct from the later separable phylogeny-by-OU field.
validate_phylo_temporal_ou_pair <- function(temporal_term, phylo_term, data, env) {
  if (is.null(temporal_term) || is.null(phylo_term)) {
    return(FALSE)
  }
  if (!identical(temporal_term$structure, "ou")) {
    cli::cli_abort(c(
      "The paired {.fn phylo} plus {.fn temporal} provider requires {.code structure = \"ou\"}.",
      "i" = "Use independent AR1 without {.fn phylo}, or use {.code phylo(1 | species, tree = tree) + temporal(1 | species, time = elapsed, structure = \"ou\")} for this first combined slice."
    ))
  }
  if (!identical(phylo_term$type, "phylo") ||
      !identical(phylo_term$coef_names, "(Intercept)") ||
      !is.null(phylo_term$covariance_label)) {
    cli::cli_abort(c(
      "The paired phylogenetic-temporal provider requires an unlabelled {.code phylo(1 | species, tree = tree)} intercept.",
      "i" = "Phylogenetic slopes and covariance-block labels are deferred for this combined slice."
    ))
  }
  if (!identical(temporal_term$group, phylo_term$group)) {
    cli::cli_abort(c(
      "Paired {.fn phylo} and {.fn temporal} terms must use the same grouping ID.",
      "x" = "The phylogenetic group is {.val {phylo_term$group}} but the temporal group is {.val {temporal_term$group}}.",
      "i" = "Use {.code phylo(1 | species, tree = tree) + temporal(1 | species, time = elapsed, structure = \"ou\")} with the same {.code species} column."
    ))
  }
  validate_temporal_raw_data(temporal_term, data)
  species <- as.character(data[[temporal_term$group]])
  if (length(unique(species)) < 3L) {
    cli::cli_abort(c(
      "The paired phylogenetic-temporal OU model requires at least three observed species.",
      "i" = "Supply repeated observations from at least three tree tips."
    ))
  }
  tree <- evaluate_phylo_tree(phylo_term$tree, env)
  tree_info <- validate_phylo_tree(tree, species = species)
  if (!setequal(tree_info$tip_label, unique(species)) ||
      length(tree_info$tip_label) != length(unique(species))) {
    cli::cli_abort(c(
      "The paired phylogenetic-temporal OU model requires tree tips to match the observed species.",
      "i" = "Prune the tree or supply data for the matching set of tips before fitting."
    ))
  }
  elapsed <- as.numeric(data[[temporal_term$time]])
  by_species <- split(elapsed, species)
  n_times <- vapply(by_species, function(x) length(unique(x)), integer(1))
  if (any(n_times < 2L)) {
    bad <- names(n_times)[n_times < 2L]
    cli::cli_abort(c(
      "Each species in the paired phylogenetic-temporal OU model needs at least two distinct times.",
      "x" = "Insufficient time variation for {.val {bad}}."
    ))
  }
  lags <- unlist(lapply(by_species, function(x) {
    x <- sort(unique(x))
    abs(outer(x, x, "-"))[upper.tri(outer(x, x, "-"), diag = FALSE)]
  }), use.names = FALSE)
  lags <- sort(unique(lags[lags > 0]))
  if (length(lags) < 3L) {
    cli::cli_abort(c(
      "The paired phylogenetic-temporal OU model requires at least three distinct positive lags.",
      "x" = "Found {.val {lags}}.",
      "i" = "Keep genuine elapsed-time gaps and collect more distinct within-species intervals."
    ))
  }
  TRUE
}

validate_temporal_gaussian_terms <- function(
  term,
  mu_re,
  sigma_re,
  sigma_rhs,
  data,
  paired_phylo_stable = FALSE
) {
  if (is.null(term)) {
    return(invisible(NULL))
  }
  if (!is_intercept_one(sigma_rhs) || length(sigma_re$terms) > 0L) {
    cli::cli_abort(c(
      "{temporal_structure_name(term)} Gaussian models currently require {.code sigma ~ 1}.",
      "i" = "Use a constant residual SD while temporal effects are fitted."
    ))
  }
  if (isTRUE(paired_phylo_stable) && length(mu_re$terms) > 0L) {
    cli::cli_abort(c(
      "The paired phylogenetic-temporal OU model does not allow an ordinary random intercept.",
      "i" = "The stable between-species component is already {.code phylo(1 | species, tree = tree)}."
    ))
  }
  if (length(mu_re$terms) > 1L) {
    cli::cli_abort(c(
      "{temporal_structure_name(term)} models allow at most one ordinary random intercept.",
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
        "A {tolower(temporal_structure_name(term))} model with an ordinary random intercept requires multiple series.",
        "i" = "Fit the temporal process without an ordinary intercept for one series, or provide observations from at least two IDs."
      ))
    }
  }
  invisible(NULL)
}

build_temporal_mu_structure <- function(term, data, has_ordinary_intercept = FALSE, paired_phylo_stable = FALSE) {
  if (is.null(term)) {
    return(empty_temporal_mu_structure())
  }
  validate_temporal_raw_data(term, data)
  id <- as.character(data[[term$group]])
  occasion <- as.numeric(data[[term$time]])
  series_levels <- unique(id)
  series_index <- match(id, series_levels)
  original_row <- seq_along(id)
  ordering <- order(series_index, occasion, original_row, method = "radix")
  ordered_series <- series_index[ordering]
  ordered_time <- occasion[ordering]
  starts <- c(which(!duplicated(ordered_series)), length(ordering) + 1L)
  n_series <- length(series_levels)
  gap <- if (identical(term$structure, "ar1")) integer(length(ordering)) else numeric(length(ordering))
  pairwise_lags <- numeric()
  for (series in seq_len(n_series)) {
    from <- starts[[series]]
    to <- starts[[series + 1L]] - 1L
    time_series <- ordered_time[from:to]
    if (length(time_series) > 1L) {
      gap[(from + 1L):to] <- diff(time_series)
      pairwise_lags <- c(
        pairwise_lags,
        abs(outer(time_series, time_series, "-"))[upper.tri(
          outer(time_series, time_series, "-"), diag = FALSE
        )]
      )
    }
  }
  if (identical(term$structure, "ar1")) {
    gap <- as.integer(gap)
  }
  distinct_lags <- sort(unique(pairwise_lags[pairwise_lags > 0]))
  required_lags <- if (isTRUE(paired_phylo_stable)) 3L else if (has_ordinary_intercept) 3L else 2L
  has_required_lags <- length(distinct_lags) >= required_lags && (
    identical(term$structure, "ou") || any(distinct_lags %% 2L == 1L)
  )
  if (!has_required_lags) {
    cli::cli_abort(c(
      paste0("Temporal ", toupper(term$structure), " occasions do not provide the required lag variation."),
      "x" = "Found distinct positive lags {.val {distinct_lags}}; this model needs at least {required_lags}.",
      "i" = "Keep genuine sampling gaps and collect more distinct within-series occasions."
    ))
  }
  if (isTRUE(paired_phylo_stable) && n_series < 3L) {
    cli::cli_abort("The paired phylogenetic-temporal OU model requires at least three retained species after response omission.")
  }
  if (isTRUE(paired_phylo_stable)) {
    series_size <- tabulate(ordered_series, nbins = n_series)
    if (any(series_size < 2L)) {
      cli::cli_abort("Each species in the paired phylogenetic-temporal OU model needs at least two retained observations after response omission.")
    }
  }
  if (has_ordinary_intercept && n_series < 2L) {
    cli::cli_abort(c(
      "A {tolower(temporal_structure_name(term))} model with an ordinary random intercept requires multiple series.",
      "i" = "Fit the temporal process without an ordinary intercept for one series, or provide observations from at least two IDs."
    ))
  }
  observation_node_index <- integer(nrow(data))
  observation_node_index[ordering] <- seq_along(ordering)
  list(
    has = TRUE,
    type = "temporal",
    label = paste0("temporal(1 | ", term$group, ", time = ", term$time, ", structure = \"", term$structure, "\")"),
    group = term$group,
    time = term$time,
    structure = term$structure,
    paired_phylo_stable = isTRUE(paired_phylo_stable),
    minimum_distinct_lags = as.integer(required_lags),
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
      temporal_mu_gap = 0L,
      temporal_mu_elapsed_gap = 0,
      temporal_mu_structure = 0L
    ))
  }
  list(
    has_temporal_mu = 1L,
    temporal_mu_node_index = temporal$observation_node_index0,
    temporal_mu_series_start = temporal$series_start0,
    temporal_mu_gap = as.integer(round(temporal$gap)),
    temporal_mu_elapsed_gap = as.numeric(temporal$gap),
    temporal_mu_structure = if (identical(temporal$structure, "ar1")) 1L else 2L
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
  temporal <- object$model$structured$temporal_mu
  if (identical(temporal$structure, "ou")) {
    cli::cli_abort(c(
      "OU mean-coefficient Wald intervals are not yet qualified.",
      "i" = "The inherited AR1 calibration prerequisite remains unresolved; OU Wald intervals are deferred."
    ))
  }
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

validate_temporal_profile_parm <- function(object, parm) {
  targets <- drm_profile_targets(object)
  allowed <- drm_temporal_mean_target_parm(object)
  selected <- if (is.null(parm)) {
    targets[match(allowed, targets$parm), , drop = FALSE]
  } else {
    profile_match_confint_targets(targets, parm, fixed_only = FALSE)
  }
  bad <- selected$parm[!selected$parm %in% allowed]
  if (length(bad) > 0L) {
    temporal_structure <- toupper(object$model$structured$temporal_mu$structure)
    cli::cli_abort(c(
      "Temporal {temporal_structure} profile intervals currently support mean regression coefficients only.",
      "x" = "Unsupported temporal profile target{?s}: {.val {bad}}.",
      "i" = "Use {.val {allowed}} or compact coefficient labels such as {.val mu:x} with {.code method = \"profile\"}.",
      "i" = "Variance components and persistence or decay intervals remain deferred."
    ))
  }
  selected$parm
}

temporal_mu_contribution <- function(object) {
  temporal <- object$model$structured$temporal_mu
  values <- object$random_effects$temporal$values
  unname(values[temporal$observation_node_index])
}

drm_fresh_temporal_mu_values <- function(object) {
  temporal <- object$model$structured$temporal_mu
  sd <- unname(object$sdpars$mu[[temporal_mu_sd_label(temporal)]])
  temporal_parameter <- if (identical(temporal$structure, "ar1")) {
    unname(object$corpars$temporal[[temporal$label]])
  } else {
    unname(object$decaypars$temporal[[temporal$label]])
  }
  latent <- numeric(temporal$n_re)
  starts <- temporal$series_start0 + 1L
  for (series in seq_len(temporal$n_series)) {
    first <- starts[[series]]
    last <- starts[[series + 1L]] - 1L
    latent[[first]] <- stats::rnorm(1L)
    if (last > first) {
      for (node in (first + 1L):last) {
        transition <- if (identical(temporal$structure, "ar1")) {
          temporal_parameter^temporal$gap[[node]]
        } else {
          exp(-temporal_parameter * temporal$gap[[node]])
        }
        latent[[node]] <- transition * latent[[node - 1L]] +
          sqrt(if (identical(temporal$structure, "ou")) {
            -expm1(-2 * temporal_parameter * temporal$gap[[node]])
          } else {
            1 - transition^2
          }) * stats::rnorm(1L)
      }
    }
  }
  values <- sd * latent
  unname(values[temporal$observation_node_index])
}
