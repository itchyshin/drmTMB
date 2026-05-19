phase18_count_mu_re_plot_data <- function(pilot) {
  phase18_assert_count_mu_re_pilot(pilot)
  aggregate <- phase18_count_mu_re_add_plot_columns(pilot$aggregate)
  replicates <- phase18_count_mu_re_replicate_plot_data(pilot)
  wald_coverage <- phase18_count_mu_re_add_coverage_columns(
    pilot$wald_coverage,
    interval_method = "wald"
  )
  profile_coverage <- phase18_count_mu_re_add_coverage_columns(
    pilot$profile_coverage,
    interval_method = "profile"
  )
  coverage <- phase18_bind_count_mu_re_plot_tables(
    wald_coverage,
    profile_coverage
  )

  list(
    aggregate = aggregate,
    replicates = replicates,
    coverage = coverage,
    manifest = pilot$manifest,
    failures = pilot$failures
  )
}

phase18_count_mu_re_add_plot_columns <- function(x) {
  phase18_assert_plot_data_frame(
    x,
    c("surface", "cell_id", "parameter", "bias", "rmse"),
    "aggregate"
  )
  out <- x
  out$family <- phase18_count_mu_re_family_label(out$surface)
  out$parameter_class <- phase18_count_mu_re_parameter_class(out$parameter)
  out$dpar <- phase18_count_mu_re_dpar(out$parameter)
  out$term <- phase18_count_mu_re_term(out$parameter)
  out$abs_bias <- abs(out$bias)
  if (!"artifact_grain" %in% names(out)) {
    out$artifact_grain <- "aggregate"
  }
  out
}

phase18_count_mu_re_replicate_plot_data <- function(pilot) {
  if (
    !"replicates" %in% names(pilot) ||
      !is.data.frame(pilot$replicates) ||
      nrow(pilot$replicates) == 0L
  ) {
    return(phase18_count_mu_re_empty_replicates())
  }
  phase18_count_mu_re_add_replicate_columns(pilot$replicates)
}

phase18_count_mu_re_add_replicate_columns <- function(x) {
  phase18_assert_plot_data_frame(
    x,
    c(
      "surface",
      "cell_id",
      "replicate",
      "parameter",
      "truth",
      "estimate",
      "error"
    ),
    "replicates"
  )
  out <- x
  out$family <- phase18_count_mu_re_family_label(out$surface)
  out$parameter_class <- phase18_count_mu_re_parameter_class(out$parameter)
  out$dpar <- phase18_count_mu_re_dpar(out$parameter)
  out$term <- phase18_count_mu_re_term(out$parameter)
  out$abs_error <- abs(out$error)
  if (!"artifact_grain" %in% names(out)) {
    out$artifact_grain <- "replicate"
  }
  out
}

phase18_count_mu_re_empty_replicates <- function() {
  data.frame(
    surface = character(),
    cell_id = character(),
    replicate = integer(),
    parameter = character(),
    truth = numeric(),
    estimate = numeric(),
    error = numeric(),
    family = character(),
    parameter_class = character(),
    dpar = character(),
    term = character(),
    abs_error = numeric(),
    artifact_grain = character(),
    stringsAsFactors = FALSE
  )
}

phase18_count_mu_re_add_coverage_columns <- function(
  x,
  interval_method
) {
  phase18_assert_plot_data_frame(
    x,
    c("surface", "cell_id", "parameter", "coverage", "n_interval"),
    "coverage"
  )
  out <- x
  out$family <- phase18_count_mu_re_family_label(out$surface)
  out$parameter_class <- phase18_count_mu_re_parameter_class(out$parameter)
  out$dpar <- phase18_count_mu_re_dpar(out$parameter)
  out$term <- phase18_count_mu_re_term(out$parameter)
  out$interval_method <- rep(interval_method, nrow(out))
  out
}

phase18_count_mu_re_family_label <- function(surface) {
  ifelse(
    identical(surface, "poisson_mu_random_effect") |
      surface == "poisson_mu_random_effect",
    "Poisson",
    ifelse(surface == "nbinom2_mu_random_effect", "NB2", surface)
  )
}

phase18_count_mu_re_parameter_class <- function(parameter) {
  ifelse(
    grepl("^sd:", parameter),
    "random_sd",
    "fixed_effect"
  )
}

phase18_count_mu_re_dpar <- function(parameter) {
  ifelse(
    grepl("^sd:", parameter),
    sub("^sd:([^:]+):.*$", "\\1", parameter),
    sub("^([^:]+):.*$", "\\1", parameter)
  )
}

phase18_count_mu_re_term <- function(parameter) {
  ifelse(
    grepl("^sd:", parameter),
    sub("^sd:[^:]+:", "", parameter),
    sub("^[^:]+:", "", parameter)
  )
}

phase18_assert_count_mu_re_pilot <- function(pilot) {
  if (!is.list(pilot)) {
    stop("`pilot` must be a count mu random-effect pilot list.", call. = FALSE)
  }
  required <- c(
    "aggregate",
    "wald_coverage",
    "profile_coverage",
    "manifest",
    "failures"
  )
  missing <- setdiff(required, names(pilot))
  if (length(missing) > 0L) {
    stop(
      "`pilot` must contain ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  invisible(pilot)
}

phase18_assert_plot_data_frame <- function(x, required, name) {
  if (!is.data.frame(x)) {
    stop("`", name, "` must be a data frame.", call. = FALSE)
  }
  missing <- setdiff(required, names(x))
  if (length(missing) > 0L) {
    stop(
      "`",
      name,
      "` must contain ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  invisible(x)
}

phase18_bind_count_mu_re_plot_tables <- function(...) {
  pieces <- list(...)
  pieces <- Filter(function(x) is.data.frame(x) && nrow(x) > 0L, pieces)
  if (length(pieces) == 0L) {
    return(data.frame())
  }
  out <- do.call(rbind, pieces)
  row.names(out) <- NULL
  out
}
