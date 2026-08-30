# Preparation contract for the first R -> DRM.jl joint missing-predictor route.
#
# This adapter deliberately stops before MakeADFun() or any Julia call.  It
# delegates formula parsing, complete-case policy, factor coding, and the
# missing-predictor design to the native Gaussian preparer, then exposes only
# atomic vectors and numeric matrices to the Julia primitive bridge.

drm_julia_joint_default_control <- function(control) {
  if (inherits(control, "drm_control")) {
    return(identical(control, drm_control()))
  }
  is.null(control) || (is.list(control) && length(control) == 0L)
}

drm_julia_joint_formula_entries <- function(formula) {
  if (!inherits(formula, "drm_formula")) {
    cli::cli_abort(
      "The Julia joint missing-predictor adapter requires a formula created by bf() or drm_formula()."
    )
  }
  formula$entries
}

drm_julia_joint_reject_formula_markers <- function(entries) {
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  unsupported_dpars <- setdiff(dpars, c("mu", "sigma"))
  if (length(unsupported_dpars) > 0L) {
    cli::cli_abort(c(
      "The Julia joint missing-predictor adapter supports only mu and sigma formulas.",
      "x" = "Unsupported parameter formula{?s}: {.val {unsupported_dpars}}."
    ))
  }

  forbidden <- c(
    "|", "||", "phylo", "phylo_interaction", "spatial", "animal", "relmat",
    "meta_V", "meta_known_V", "offset", "corpair"
  )
  for (entry in entries) {
    hits <- forbidden[vapply(
      forbidden,
      function(marker) formula_contains_call(entry$rhs, marker),
      logical(1)
    )]
    if (length(hits) > 0L) {
      kind <- if (any(hits %in% c("|", "||"))) "random" else "structured"
      cli::cli_abort(c(
        "The Julia joint missing-predictor adapter supports fixed effects only.",
        "x" = "The {.code {entry$dpar}} formula contains unsupported {kind}-effect or offset syntax: {.val {hits}}."
      ))
    }
  }
  invisible(TRUE)
}

drm_julia_joint_mi_setup <- function(entries) {
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  mu_entries <- entries[dpars == "mu"]
  if (length(mu_entries) != 1L || is.na(mu_entries[[1L]]$response)) {
    cli::cli_abort(
      "The Julia joint missing-predictor adapter requires exactly one mu response formula."
    )
  }
  other_mi <- vapply(
    entries[dpars != "mu"],
    function(entry) length(drm_find_mi_calls(entry$rhs)) > 0L,
    logical(1)
  )
  if (any(other_mi)) {
    cli::cli_abort(
      "The Julia joint missing-predictor adapter permits mi() only in the mu location formula."
    )
  }
  mi_calls <- drm_find_mi_calls(mu_entries[[1L]]$rhs)
  if (length(mi_calls) != 1L) {
    cli::cli_abort(c(
      "The Julia joint missing-predictor adapter requires exactly one mi() term in mu.",
      "x" = "Found {length(mi_calls)} mi() term{?s}."
    ))
  }
  variable <- drm_validate_bare_mi_call(mi_calls[[1L]], mu_entries[[1L]]$rhs)
  response <- as.character(mu_entries[[1L]]$response)
  if (identical(variable, response)) {
    cli::cli_abort(
      "The Julia joint missing-predictor adapter cannot use the response itself as mi()."
    )
  }
  list(variable = variable, response = response)
}

drm_julia_joint_impute_formula <- function(impute, variable) {
  impute_spec <- drm_validate_named_impute_entry(
    impute,
    variable,
    n_expected = 1L
  )
  rhs <- impute_spec$raw_formula[[3L]]
  forbidden <- c(
    "|", "||", "phylo", "phylo_interaction", "spatial", "animal", "relmat",
    "meta_V", "meta_known_V", "offset", "corpair"
  )
  hits <- forbidden[vapply(
    forbidden,
    function(marker) formula_contains_call(rhs, marker),
    logical(1)
  )]
  if (length(hits) > 0L) {
    cli::cli_abort(c(
      "The Julia joint missing-predictor adapter supports fixed-effect impute formulas only.",
      "x" = "The impute formula contains unsupported random, structured, or offset syntax: {.val {hits}}."
    ))
  }
  impute_spec
}

drm_julia_joint_reject_modelled_exogenous <- function(
  entries,
  mi_setup,
  impute_spec
) {
  protected <- c(mi_setup$response, mi_setup$variable)
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  mu_rhs <- entries[[which(dpars == "mu")]]$rhs
  # terms() resolves addition/subtraction and no-intercept syntax. Skipping
  # an entire AST node containing mi() would also skip its other covariates.
  labels <- attr(stats::terms(stats::as.formula(call("~", mu_rhs))), "term.labels")
  mu_terms <- lapply(labels, str2lang)
  mi_term <- labels == paste0("mi(", mi_setup$variable, ")")
  for (term in mu_terms[!mi_term]) {
    bad <- intersect(all.vars(term), protected)
    if (length(bad) > 0L) {
      cli::cli_abort(c(
        "The Julia joint missing-predictor adapter does not permit modelled variables as ordinary fixed effects.",
        "x" = "The mu fixed-effect term {.code {deparse1(term)}} reuses {.val {bad}} outside mi({mi_setup$variable})."
      ))
    }
  }
  for (entry in entries[dpars == "sigma"]) {
    bad <- intersect(all.vars(entry$rhs), protected)
    if (length(bad) > 0L) {
      cli::cli_abort(c(
        "The Julia joint missing-predictor adapter does not permit modelled variables in sigma fixed effects.",
        "x" = "The sigma formula reuses {.val {bad}}."
      ))
    }
  }
  bad <- intersect(all.vars(impute_spec$raw_formula[[3L]]), protected)
  if (length(bad) > 0L) {
    cli::cli_abort(c(
      "The Julia joint missing-predictor adapter does not permit modelled variables in impute fixed effects.",
      "x" = "The impute formula reuses {.val {bad}}."
    ))
  }
  invisible(TRUE)
}

drm_julia_joint_numeric_matrix <- function(x, label) {
  x <- as.matrix(x)
  storage.mode(x) <- "double"
  if (!is.numeric(x) || any(!is.finite(x))) {
    cli::cli_abort(
      "The Julia joint missing-predictor adapter requires a finite numeric {label} matrix."
    )
  }
  unname(x)
}

drm_julia_joint_response_drop <- function(data, response, missing) {
  original_row <- seq_len(nrow(data))
  if (!identical(missing$response, "drop")) {
    return(list(data = data, original_row = original_row))
  }
  if (!response %in% names(data)) {
    cli::cli_abort(
      "The Julia joint missing-predictor adapter requires the mu response to be a data column."
    )
  }
  keep <- !is.na(data[[response]])
  list(
    data = data[keep, , drop = FALSE],
    original_row = original_row[keep]
  )
}

#' Prepare the first joint missing-predictor Julia payload
#'
#' Internal bridge preparation. It admits one additive `mi()` predictor in a
#' Gaussian identity-link response model with either a Gaussian or Bernoulli
#' fixed-effect imputation model. No fitting happens here.
#'
#' @keywords internal
drm_julia_joint_prepare <- function(
  formula,
  family,
  data,
  env = parent.frame(),
  weights_missing = TRUE,
  control = drm_control(),
  impute = NULL,
  missing = miss_control(),
  REML = FALSE
) {
  if (!is.data.frame(data)) {
    cli::cli_abort("The Julia joint missing-predictor adapter requires data to be a data frame.")
  }
  if (!inherits(family, "family") ||
      !identical(family$family, "gaussian") ||
      !identical(family$link, "identity")) {
    cli::cli_abort(
      "The Julia joint missing-predictor adapter currently supports gaussian(link = \"identity\") responses only."
    )
  }
  if (!isTRUE(weights_missing)) {
    cli::cli_abort(
      "The Julia joint missing-predictor adapter does not support likelihood weights."
    )
  }
  if (!isFALSE(REML)) {
    cli::cli_abort(
      "The Julia joint missing-predictor adapter supports ML only; REML = TRUE is not implemented."
    )
  }
  if (!drm_julia_joint_default_control(control)) {
    cli::cli_abort(
      "The Julia joint missing-predictor adapter requires the default drm_control()."
    )
  }
  control <- if (inherits(control, "drm_control")) control else drm_control()
  missing <- drm_parse_missing_control(missing)
  fields <- c("response", "predictor", "engine")
  if (!identical(sort(names(missing)), sort(fields))) {
    cli::cli_abort("The Julia joint missing control requires response, predictor and engine fields only.")
  }
  for (field in fields) {
    value <- missing[[field]]
    if (!is.character(value) || length(value) != 1L || is.na(value)) {
      cli::cli_abort("Missing-control {.val {field}} must be a single character string.")
    }
  }
  # Classed controls are mutable lists; rerun the constructor validation.
  missing <- miss_control(missing$response, missing$predictor, missing$engine)
  if (!identical(missing$predictor, "model")) {
    cli::cli_abort(
      "The Julia joint missing-predictor adapter requires missing = miss_control(predictor = \"model\")."
    )
  }
  if (!missing$response %in% c("drop", "include")) {
    cli::cli_abort("The Julia joint missing-predictor adapter supports response = \"drop\" or \"include\" only.")
  }

  entries <- drm_julia_joint_formula_entries(formula)
  drm_julia_joint_reject_formula_markers(entries)
  mi_setup <- drm_julia_joint_mi_setup(entries)
  impute_spec <- drm_julia_joint_impute_formula(impute, mi_setup$variable)
  drm_julia_joint_reject_modelled_exogenous(entries, mi_setup, impute_spec)
  response_drop <- drm_julia_joint_response_drop(data, mi_setup$response, missing)

  spec <- drm_build_gaussian_ls_spec(
    formula = formula,
    data = response_drop$data,
    env = env,
    weights = NULL,
    control = control,
    impute = impute,
    missing = missing
  )
  model <- spec$missing_predictor
  if (!isTRUE(model$enabled) || isTRUE(spec$missing_predictor2$enabled)) {
    cli::cli_abort(
      "The Julia joint missing-predictor adapter requires exactly one missing predictor model."
    )
  }
  if (!model$family %in% c("gaussian", "bernoulli")) {
    cli::cli_abort(c(
      "The Julia joint missing-predictor adapter supports Gaussian or Bernoulli predictor models only.",
      "x" = "Received predictor family {.val {model$family}}."
    ))
  }
  if (isTRUE(model$random$enabled) || isTRUE(model$structured$enabled)) {
    cli::cli_abort(
      "The Julia joint missing-predictor adapter supports fixed-effect impute formulas only."
    )
  }
  if (!identical(model$variable, mi_setup$variable) ||
      !identical(model$variable, as.character(model$variable))) {
    cli::cli_abort("Internal Julia joint missing-predictor variable mismatch.")
  }

  X_mu <- drm_julia_joint_numeric_matrix(spec$X$mu, "mu design")
  X_sigma <- drm_julia_joint_numeric_matrix(spec$X$sigma, "sigma design")
  X_predictor <- drm_julia_joint_numeric_matrix(model$X, "predictor design")
  mu_names <- colnames(spec$X$mu)
  sigma_names <- colnames(spec$X$sigma)
  predictor_names <- colnames(model$X)
  mu_col <- as.integer(model$mu_col)
  if (length(mu_col) != 1L || is.na(mu_col) || mu_col < 1L ||
      mu_col > ncol(X_mu) || !identical(mu_names[[mu_col]], model$model_column)) {
    cli::cli_abort("Internal Julia joint missing-predictor mu design-column mismatch.")
  }
  observed_y <- as.logical(spec$missing_data$observed_y)
  observed_x <- as.logical(model$observed)
  original_row <- as.integer(
    response_drop$original_row[spec$missing_data$original_row]
  )
  spec$missing_data$original_row <- original_row
  if (length(spec$missing_data$predictors) > 0L) {
    for (name in names(spec$missing_data$predictors)) {
      predictor <- spec$missing_data$predictors[[name]]
      predictor$original_row <- as.integer(
        response_drop$original_row[predictor$original_row]
      )
      spec$missing_data$predictors[[name]] <- predictor
    }
  }
  y <- as.numeric(spec$y)
  x <- as.numeric(model$x)
  n <- length(original_row)
  if (length(y) != n || length(x) != n || length(observed_y) != n ||
      length(observed_x) != n || nrow(X_mu) != n || nrow(X_sigma) != n ||
      nrow(X_predictor) != n) {
    cli::cli_abort("Internal Julia joint missing-predictor payload row mismatch.")
  }
  if (!all(is.finite(y[observed_y])) || !all(is.finite(x[observed_x]))) {
    cli::cli_abort("Observed response and predictor values must be finite before Julia preparation.")
  }
  if (!any(!observed_x)) {
    cli::cli_abort("The Julia joint missing-predictor adapter requires at least one missing mi() predictor value.")
  }

  payload <- list(
    schema = "joint_missing_v1",
    predictor = model$family,
    variable = model$variable,
    y = y,
    x = x,
    observed_y = observed_y,
    observed_x = observed_x,
    X_mu = X_mu,
    X_sigma = X_sigma,
    X_predictor = X_predictor,
    mu_col = mu_col,
    mu_names = unname(as.character(mu_names)),
    sigma_names = unname(as.character(sigma_names)),
    predictor_names = unname(as.character(predictor_names)),
    original_row = original_row,
    options = list(g_tol = 1e-8)
  )
  list(payload = payload, spec = spec)
}
