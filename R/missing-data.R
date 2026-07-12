#' Configure missing-data handling
#'
#' `miss_control()` configures the first `drmTMB` missing-data slices. The
#' default keeps the existing complete-case behaviour. In the current fitted
#' slices, `response = "include"` is implemented for univariate Gaussian
#' response masks and bivariate Gaussian partial-response rows without dense
#' known covariance. `predictor = "model"` is implemented mainly for one `mi()`
#' missing predictor at a time in a univariate Gaussian location model:
#' numeric missing predictors can use Gaussian fixed-effect, grouped, or
#' structured predictor models. Binary,
#' ordered categorical, unordered categorical, strict beta/proportion,
#' zero-one beta boundary proportion, denominator-aware beta-binomial
#' success/trial proportion, Poisson, negative-binomial, or zero-truncated
#' negative-binomial count, positive continuous lognormal or Gamma, and
#' exact-zero semi-continuous Tweedie missing predictors can use fixed-effect
#' predictor models supplied by [impute_model()]. The non-Gaussian response
#' slices support `poisson()`, `binomial()`, `nbinom2()`, and `beta()` responses,
#' each with one fixed-effect Bernoulli/logit binary missing predictor.
#' EM/profile engines and simulation-based imputation
#' summaries are reserved for later slices.
#'
#' @param response Response missingness policy. `"drop"` keeps existing
#'   complete-case fitting; `"include"` keeps rows with supported missing
#'   Gaussian responses and masks or marginalizes their likelihood contribution.
#' @param predictor Predictor missingness policy. `"fail"` errors on missing
#'   predictors. `"model"` enables the current `mi()` predictor-model routes when
#'   paired with a matching `impute` formula or [impute_model()] in [drmTMB()].
#' @param engine Missing-data engine. Only `"laplace"` is implemented in this
#'   slice.
#'
#' @return A `drm_missing_control` object.
#' @export
#'
#' @examples
#' miss_control()
#' miss_control(response = "include")
#' miss_control(predictor = "model")
miss_control <- function(
  response = c("drop", "include"),
  predictor = c("fail", "model"),
  engine = c("laplace", "em", "profile")
) {
  response <- match.arg(response)
  predictor <- match.arg(predictor)
  engine <- match.arg(engine)

  if (!identical(engine, "laplace")) {
    cli::cli_abort(c(
      "{.arg engine = \"{engine}\"} is reserved, not implemented yet.",
      "i" = "Use {.code engine = \"laplace\"} for the first missing-data slice."
    ))
  }

  structure(
    list(
      response = response,
      predictor = predictor,
      engine = engine
    ),
    class = "drm_missing_control"
  )
}

#' Define a missing-predictor model
#'
#' `impute_model()` wraps the model for a predictor used inside [mi()]. A bare
#' formula in `impute`, such as `impute = list(x = x ~ z)`, is still treated as
#' a Gaussian model for a numeric missing predictor. Use `impute_model()` when
#' the missing predictor needs an explicit non-Gaussian predictor family. The
#' first non-Gaussian fitted routes are fixed-effect Bernoulli/logit models for
#' one binary predictor, fixed-effect cumulative-logit models for one ordered
#' categorical predictor, fixed-effect baseline-category softmax models for one
#' unordered categorical predictor, fixed-effect beta models for one strict
#' proportion predictor in `(0, 1)`, fixed-effect zero-one beta models for one
#' boundary proportion predictor in `[0, 1]`, fixed-effect beta-binomial
#' models for one denominator-aware success/trial proportion predictor,
#' fixed-effect Poisson, negative-binomial, or zero-truncated
#' negative-binomial models for one count predictor, fixed-effect lognormal or
#' Gamma models for one positive continuous predictor, and fixed-effect
#' Tweedie models for one non-negative semi-continuous predictor with exact
#' zeros. Most current non-Gaussian predictor families are fitted inside a
#' Gaussian response location model; Poisson, binomial, negative-binomial, and
#' beta responses are currently supported for one binary missing predictor.
#'
#' @param formula Two-sided predictor-model formula. For most families, the
#'   left-hand side must be the same variable used inside [mi()]. For
#'   `family = beta_binomial()`, the left-hand side is the success-count
#'   column, while the [mi()] variable is the success proportion used in the
#'   response model.
#' @param family Predictor-model family. `gaussian()` keeps the existing
#'   continuous predictor route. `binomial(link = "logit")` fits the binary
#'   missing-predictor route. [cumulative_logit()] fits the ordered categorical
#'   missing-predictor route. [categorical()] fits the unordered categorical
#'   missing-predictor route. [beta()] fits the strict beta/proportion
#'   missing-predictor route. [zero_one_beta()] fits the boundary-proportion
#'   missing-predictor route. [beta_binomial()] fits a denominator-aware
#'   success/trial proportion route and requires `trials`. `poisson(link =
#'   "log")`, [nbinom2()], and [truncated_nbinom2()] fit count
#'   missing-predictor routes. [lognormal()] and `Gamma(link = "log")` fit
#'   positive continuous missing-predictor routes. [tweedie()] fits a
#'   semi-continuous non-negative missing-predictor route with exact zeros.
#' @param trials Optional trial-count column for `family = beta_binomial()`.
#'   The formula left-hand side is the success count and `trials` is the known
#'   denominator for each row.
#'
#' @return A `drm_impute_model` object for the `impute` argument of [drmTMB()].
#' @export
#'
#' @examples
#' impute_model(x ~ z)
#' impute_model(treatment ~ z, family = binomial())
#' impute_model(score ~ z, family = cumulative_logit())
#' impute_model(habitat ~ z, family = categorical())
#' impute_model(cover ~ z, family = beta())
#' impute_model(cover ~ z, family = zero_one_beta())
#' impute_model(success ~ z, family = beta_binomial(), trials = trials)
#' impute_model(abundance ~ z, family = poisson())
#' impute_model(abundance ~ z, family = nbinom2())
#' impute_model(abundance ~ z, family = truncated_nbinom2())
#' impute_model(biomass ~ z, family = lognormal())
#' impute_model(biomass ~ z, family = Gamma(link = "log"))
#' impute_model(biomass ~ z, family = tweedie())
impute_model <- function(formula, family = stats::gaussian(), trials = NULL) {
  if (!inherits(formula, "formula") || length(formula) != 3L) {
    cli::cli_abort(
      "{.arg formula} must be a two-sided formula such as {.code x ~ z}."
    )
  }
  family_type <- drm_impute_family_type(family)
  trials_expr <- if (missing(trials)) {
    NULL
  } else {
    substitute(trials)
  }
  if (identical(trials_expr, quote(NULL))) {
    trials_expr <- NULL
  }
  if (!identical(family_type, "beta_binomial") && !is.null(trials_expr)) {
    cli::cli_abort(
      "{.arg trials} is only used for {.code family = beta_binomial()} missing-predictor models."
    )
  }
  if (identical(family_type, "beta_binomial") && is.null(trials_expr)) {
    cli::cli_abort(c(
      "{.fn beta_binomial} missing-predictor models require a {.arg trials} column.",
      "i" = "Use syntax such as {.code impute_model(success ~ z, family = beta_binomial(), trials = trials)}."
    ))
  }
  structure(
    list(
      formula = formula,
      family = family,
      family_type = family_type,
      trials = trials_expr
    ),
    class = "drm_impute_model"
  )
}

#' Unordered categorical missing-predictor family
#'
#' `categorical()` defines a baseline-category softmax model for one unordered
#' categorical predictor used inside [mi()]. It is currently a predictor-model
#' family for [impute_model()], not a response family for [drmTMB()].
#'
#' The first fitted route is fixed-effect and uses the first factor level as
#' the baseline category. Missing predictor values are integrated by exact
#' summation over the unordered levels.
#'
#' @return A `drm_impute_family` object.
#' @export
#'
#' @examples
#' categorical()
categorical <- function() {
  structure(
    list(
      name = "categorical",
      family = "categorical",
      link = "baseline_softmax"
    ),
    class = "drm_impute_family"
  )
}

drm_impute_family_type <- function(family) {
  if (inherits(family, "family") && identical(family$family, "gaussian")) {
    return("gaussian")
  }
  if (inherits(family, "family") && identical(family$family, "binomial")) {
    if (!identical(family$link, "logit")) {
      cli::cli_abort(c(
        "Binary missing-predictor models require {.code binomial(link = \"logit\")}.",
        "x" = "Received binomial link {.val {family$link}}."
      ))
    }
    return("bernoulli")
  }
  if (
    inherits(family, "drm_family") && identical(family$name, "cumulative_logit")
  ) {
    return("ordinal")
  }
  if (
    inherits(family, "drm_impute_family") &&
      identical(family$name, "categorical")
  ) {
    return("categorical")
  }
  if (inherits(family, "drm_family") && identical(family$name, "beta")) {
    return("beta")
  }
  if (
    inherits(family, "drm_family") && identical(family$name, "zero_one_beta")
  ) {
    return("zero_one_beta")
  }
  if (
    inherits(family, "drm_family") && identical(family$name, "beta_binomial")
  ) {
    return("beta_binomial")
  }
  if (inherits(family, "drm_family") && identical(family$name, "nbinom2")) {
    return("nbinom2")
  }
  if (
    inherits(family, "drm_family") &&
      identical(family$name, "truncated_nbinom2")
  ) {
    return("truncated_nbinom2")
  }
  if (inherits(family, "drm_family") && identical(family$name, "lognormal")) {
    return("lognormal")
  }
  if (inherits(family, "drm_family") && identical(family$name, "tweedie")) {
    return("tweedie")
  }
  if (inherits(family, "family") && identical(family$family, "Gamma")) {
    if (!identical(family$link, "log")) {
      cli::cli_abort(c(
        "Gamma missing-predictor models require {.code Gamma(link = \"log\")}.",
        "x" = "Received Gamma link {.val {family$link}}."
      ))
    }
    return("gamma")
  }
  if (inherits(family, "family") && identical(family$family, "poisson")) {
    if (!identical(family$link, "log")) {
      cli::cli_abort(c(
        "Poisson count missing-predictor models require {.code poisson(link = \"log\")}.",
        "x" = "Received poisson link {.val {family$link}}."
      ))
    }
    return("poisson")
  }
  label <- if (inherits(family, "family")) {
    family$family
  } else if (inherits(family, "drm_family")) {
    family$name
  } else if (inherits(family, "drm_impute_family")) {
    family$name
  } else {
    class(family)[[1L]]
  }
  cli::cli_abort(c(
    "Unsupported missing-predictor family {.val {label}}.",
    "i" = "The fitted predictor-model families are currently {.code gaussian()}, {.code binomial(link = \"logit\")}, {.fn cumulative_logit}, {.fn categorical}, {.fn beta}, {.fn zero_one_beta}, {.fn beta_binomial}, {.code poisson(link = \"log\")}, {.fn nbinom2}, {.fn truncated_nbinom2}, {.fn lognormal}, {.code Gamma(link = \"log\")}, and {.fn tweedie}."
  ))
}

drm_standardize_impute_model <- function(x) {
  if (inherits(x, "drm_impute_model")) {
    return(x)
  }
  if (inherits(x, "formula")) {
    return(impute_model(x, family = stats::gaussian()))
  }
  cli::cli_abort(
    "{.arg impute} entries must be formulas or objects created by {.fn impute_model}."
  )
}

drm_parse_missing_control <- function(missing) {
  if (inherits(missing, "drm_missing_control")) {
    return(missing)
  }
  if (is.list(missing)) {
    response <- missing$response
    predictor <- missing$predictor
    engine <- missing$engine
    if (is.null(response)) {
      response <- "drop"
    }
    if (is.null(predictor)) {
      predictor <- "fail"
    }
    if (is.null(engine)) {
      engine <- "laplace"
    }
    return(miss_control(
      response = response,
      predictor = predictor,
      engine = engine
    ))
  }
  cli::cli_abort(
    "{.arg missing} must be created with {.fn miss_control}."
  )
}

drm_missing_response_families <- function() {
  c(
    "gaussian", "biv_gaussian", "student", "skew_normal", "lognormal",
    "gamma", "binomial", "poisson", "nbinom2", "beta"
  )
}

drm_missing_predictor_families <- function() {
  c("gaussian", "poisson", "binomial", "nbinom2", "beta")
}

drm_missing_response_sentinel <- function() {
  sentinel <- getOption("drmTMB.missing_response_sentinel", 0)
  if (
    !is.numeric(sentinel) ||
      length(sentinel) != 1L ||
      !is.finite(sentinel)
  ) {
    cli::cli_abort(
      "Internal missing-response sentinel must be one finite numeric value."
    )
  }
  as.numeric(sentinel)
}

new_drm_missing_data <- function(
  control,
  original_row,
  model_row,
  observed_y,
  response_sentinel = NA_real_,
  predictors = list(),
  version = "MD1"
) {
  observed_y <- as.logical(observed_y)
  structure(
    list(
      version = version,
      response_policy = control$response,
      predictor_policy = control$predictor,
      engine = control$engine,
      original_row = as.integer(original_row),
      model_row = as.integer(model_row),
      observed_y = observed_y,
      counts = list(
        retained_rows = length(observed_y),
        observed_response = sum(observed_y),
        missing_response = sum(!observed_y),
        likelihood_rows = sum(observed_y)
      ),
      response_sentinel = response_sentinel,
      predictors = predictors
    ),
    class = "drm_missing_data"
  )
}

drm_default_missing_data <- function(control, keep) {
  original_row <- which(keep)
  new_drm_missing_data(
    control = control,
    original_row = original_row,
    model_row = seq_along(original_row),
    observed_y = rep(TRUE, length(original_row)),
    response_sentinel = NA_real_
  )
}

new_drm_biv_missing_data <- function(
  control,
  original_row,
  model_row,
  observed_y1,
  observed_y2,
  response_sentinel = NA_real_
) {
  observed_y1 <- as.logical(observed_y1)
  observed_y2 <- as.logical(observed_y2)
  if (length(observed_y1) != length(observed_y2)) {
    cli::cli_abort(
      "Internal bivariate missing-data error: response masks have different lengths."
    )
  }
  response_pattern <- ifelse(
    observed_y1 & observed_y2,
    "both_observed",
    ifelse(
      observed_y1,
      "y1_observed",
      ifelse(observed_y2, "y2_observed", "both_missing")
    )
  )
  structure(
    list(
      version = "MD2",
      response_policy = control$response,
      predictor_policy = control$predictor,
      engine = control$engine,
      original_row = as.integer(original_row),
      model_row = as.integer(model_row),
      observed_y = cbind(y1 = observed_y1, y2 = observed_y2),
      observed_y1 = observed_y1,
      observed_y2 = observed_y2,
      response_pattern = response_pattern,
      counts = list(
        retained_rows = length(observed_y1),
        observed_y1 = sum(observed_y1),
        observed_y2 = sum(observed_y2),
        complete_response = sum(observed_y1 & observed_y2),
        y1_only = sum(observed_y1 & !observed_y2),
        y2_only = sum(!observed_y1 & observed_y2),
        both_missing = sum(!observed_y1 & !observed_y2),
        likelihood_rows = sum(observed_y1 | observed_y2)
      ),
      response_sentinel = response_sentinel
    ),
    class = "drm_missing_data"
  )
}

drm_tmb_observed_y <- function(spec) {
  missing_data <- spec$missing_data
  if (
    is.list(missing_data) &&
      !is.null(missing_data$observed_y) &&
      length(missing_data$observed_y) > 0L
  ) {
    return(as.integer(missing_data$observed_y))
  }
  n <- if (identical(spec$model_type, "biv_gaussian")) {
    length(spec$y1)
  } else {
    length(spec$y)
  }
  rep(1L, n)
}

drm_tmb_observed_y1 <- function(spec) {
  missing_data <- spec$missing_data
  if (
    is.list(missing_data) &&
      !is.null(missing_data$observed_y1) &&
      length(missing_data$observed_y1) > 0L
  ) {
    return(as.integer(missing_data$observed_y1))
  }
  n <- if (identical(spec$model_type, "biv_gaussian")) {
    length(spec$y1)
  } else if (!is.null(spec$y)) {
    length(spec$y)
  } else {
    1L
  }
  rep(1L, n)
}

drm_tmb_observed_y2 <- function(spec) {
  missing_data <- spec$missing_data
  if (
    is.list(missing_data) &&
      !is.null(missing_data$observed_y2) &&
      length(missing_data$observed_y2) > 0L
  ) {
    return(as.integer(missing_data$observed_y2))
  }
  n <- if (identical(spec$model_type, "biv_gaussian")) {
    length(spec$y2)
  } else if (!is.null(spec$y)) {
    length(spec$y)
  } else {
    1L
  }
  rep(1L, n)
}

drm_mask_missing_response_values <- function(object, value) {
  missing_data <- object$missing_data
  if (
    !is.list(missing_data) ||
      !identical(missing_data$response_policy, "include") ||
      is.null(missing_data$observed_y)
  ) {
    return(value)
  }
  observed_y <- as.logical(missing_data$observed_y)
  if (length(value) != length(observed_y)) {
    cli::cli_abort(c(
      "Internal error: cannot mask missing responses because of a length mismatch.",
      "x" = "Received {length(value)} value{?s} but the response mask has {length(observed_y)} entr{?y/ies}.",
      "i" = "Masking is required so the internal missing-response sentinel is never reported as data."
    ))
  }
  value[!observed_y] <- NA_real_
  value
}

drm_mask_biv_missing_response_values <- function(object, value) {
  missing_data <- object$missing_data
  if (
    !is.list(missing_data) ||
      !identical(missing_data$response_policy, "include") ||
      is.null(missing_data$observed_y1) ||
      is.null(missing_data$observed_y2) ||
      !is.matrix(value) ||
      ncol(value) < 2L
  ) {
    return(value)
  }
  if (nrow(value) != length(missing_data$observed_y1)) {
    cli::cli_abort(c(
      "Internal error: cannot mask missing bivariate responses because of a row mismatch.",
      "x" = "Received {nrow(value)} row{?s} but the response mask has {length(missing_data$observed_y1)} entr{?y/ies}.",
      "i" = "Masking is required so the internal missing-response sentinel is never reported as data."
    ))
  }
  value[!as.logical(missing_data$observed_y1), 1L] <- NA_real_
  value[!as.logical(missing_data$observed_y2), 2L] <- NA_real_
  value
}

drm_warn_weak_biv_rho12_identifiability <- function(
  complete_pairs,
  rho12_parameter_count
) {
  minimum_pairs <- max(3L, rho12_parameter_count + 2L)
  if (complete_pairs >= minimum_pairs) {
    return(invisible(FALSE))
  }
  cli::cli_warn(c(
    "Residual {.code rho12} is weakly identified because few complete response pairs are available.",
    "x" = "Only {complete_pairs} complete response pair{?s} inform {.code rho12} directly; at least {minimum_pairs} {?is/are} recommended for this fitted {.code rho12} formula.",
    "i" = "Rows with one observed response still inform their marginal location and scale, but not the residual correlation directly."
  ))
  invisible(TRUE)
}

drm_find_mi_calls <- function(expr) {
  if (!is.call(expr)) {
    return(list())
  }
  head <- as.character(expr[[1L]])[[1L]]
  out <- if (identical(head, "mi")) list(expr) else list()
  children <- as.list(expr)[-1L]
  for (child in children) {
    out <- c(out, drm_find_mi_calls(child))
  }
  out
}

drm_prepare_gaussian_mi_setup <- function(mu_rhs, impute, missing) {
  mi_calls <- drm_find_mi_calls(mu_rhs)
  predictor_model <- identical(missing$predictor, "model")
  if (!predictor_model && length(mi_calls) > 0L) {
    cli::cli_abort(c(
      "{.fn mi} terms require {.code missing = miss_control(predictor = \"model\")}.",
      "i" = "Use ordinary predictor syntax for complete predictors, or supply a matching {.arg impute} formula for missing predictors."
    ))
  }
  if (!predictor_model && !is.null(impute)) {
    cli::cli_abort(
      "{.arg impute} is used only with {.code missing = miss_control(predictor = \"model\")}."
    )
  }
  if (!predictor_model) {
    return(empty_gaussian_mi_setup())
  }
  if (length(mi_calls) != 1L) {
    cli::cli_abort(c(
      "The current missing-predictor routes require exactly one {.fn mi} term in the response location formula.",
      "x" = "Found {length(mi_calls)} {.fn mi} term{?s}."
    ))
  }
  mi_call <- mi_calls[[1L]]
  if (length(mi_call) != 2L || !is.symbol(mi_call[[2L]])) {
    cli::cli_abort(c(
      "The current {.fn mi} routes support only a bare predictor, such as {.code mi(x)}.",
      "x" = "Transformations, interactions inside {.fn mi}, and multiple missing predictors are planned later."
    ))
  }
  variable <- as.character(mi_call[[2L]])
  mi_label <- paste0("mi(", variable, ")")
  term_labels <- attr(
    stats::terms(stats::as.formula(call("~", mu_rhs))),
    "term.labels"
  )
  mi_term_labels <- term_labels[
    vapply(term_labels, grepl, logical(1), pattern = mi_label, fixed = TRUE)
  ]
  if (!identical(mi_term_labels, mi_label)) {
    cli::cli_abort(c(
      "The first {.fn mi} slice supports {.fn mi} only as a simple additive location term.",
      "x" = "Use syntax like {.code y ~ z + mi(x)}, not interactions or transformed {.fn mi} terms."
    ))
  }
  impute_spec <- drm_validate_single_impute_formula(impute, variable)
  list(
    enabled = TRUE,
    variable = variable,
    label = mi_label,
    model_column = mi_label,
    formula = impute_spec$formula,
    raw_formula = impute_spec$raw_formula,
    family = impute_spec$family,
    trials = impute_spec$trials,
    trials_variable = impute_spec$trials_variable,
    response_variable = impute_spec$response_variable,
    random = impute_spec$random,
    structured = impute_spec$structured
  )
}

empty_gaussian_mi_setup <- function() {
  list(
    enabled = FALSE,
    variable = character(0),
    label = character(0),
    model_column = character(0),
    formula = NULL,
    raw_formula = NULL,
    family = "none",
    trials = NULL,
    trials_variable = character(0),
    response_variable = character(0),
    random = NULL,
    structured = NULL
  )
}

drm_validate_single_impute_formula <- function(impute, variable) {
  if (is.null(impute)) {
    cli::cli_abort(c(
      "{.code miss_control(predictor = \"model\")} requires an {.arg impute} formula.",
      "i" = "Use syntax such as {.code impute = list(x = x ~ z)} for a Gaussian predictor, or {.code impute = list(x = impute_model(x ~ z, family = binomial()))} for a finite-state predictor."
    ))
  }
  if (!is.list(impute) || length(impute) != 1L) {
    cli::cli_abort(
      "{.arg impute} must be a one-element named list for the current missing-predictor routes."
    )
  }
  name <- names(impute)
  if (
    !is.null(name) && nzchar(name[[1L]]) && !identical(name[[1L]], variable)
  ) {
    cli::cli_abort(c(
      "{.arg impute} name must match the {.fn mi} predictor.",
      "x" = "Found {.code impute = list({name[[1L]]} = ...)} for {.code mi({variable})}."
    ))
  }
  impute_model <- drm_standardize_impute_model(impute[[1L]])
  formula <- impute_model$formula
  family <- impute_model$family_type
  trials_expr <- impute_model$trials
  if (!inherits(formula, "formula") || length(formula) != 3L) {
    cli::cli_abort(
      "{.arg impute} must contain a two-sided formula such as {.code x ~ z}."
    )
  }
  if (identical(family, "beta_binomial")) {
    if (!is.symbol(formula[[2L]])) {
      cli::cli_abort(c(
        "{.fn beta_binomial} missing-predictor models require a success-count response on the left-hand side.",
        "x" = "Use syntax such as {.code impute_model(success ~ z, family = beta_binomial(), trials = trials)}."
      ))
    }
    trials_vars <- all.vars(trials_expr)
    if (length(trials_vars) != 1L || !is.symbol(trials_expr)) {
      cli::cli_abort(c(
        "{.arg trials} must be one trial-count column for {.fn beta_binomial} missing-predictor models.",
        "x" = "Use syntax such as {.code trials = trials}, not an expression."
      ))
    }
  } else {
    if (!is.null(trials_expr)) {
      cli::cli_abort(
        "{.arg trials} is only used for {.fn beta_binomial} missing-predictor models."
      )
    }
    if (
      !is.symbol(formula[[2L]]) ||
        !identical(as.character(formula[[2L]]), variable)
    ) {
      cli::cli_abort(c(
        "The left-hand side of the {.arg impute} formula must match the {.fn mi} predictor.",
        "x" = "Use {.code {variable} ~ ...} for {.code mi({variable})}."
      ))
    }
  }
  if (length(drm_find_mi_calls(formula[[3L]])) > 0L) {
    cli::cli_abort(
      "Nested {.fn mi} terms inside {.arg impute} formulas are not implemented."
    )
  }
  if ("." %in% all.names(formula[[3L]], functions = FALSE, unique = TRUE)) {
    cli::cli_abort(
      "The first {.arg impute} slice requires explicit predictor names; {.code .} is not supported."
    )
  }
  impute_structured <- drm_extract_impute_structured_intercept(formula)
  impute_random <- drm_extract_impute_random_intercept(
    impute_structured$fixed_formula
  )
  if (
    is.list(impute_structured$structured) &&
      isTRUE(impute_structured$structured$enabled) &&
      is.list(impute_random$random) &&
      isTRUE(impute_random$random$enabled)
  ) {
    cli::cli_abort(c(
      "The MD4 {.arg impute} route cannot combine grouped and structured covariate random effects.",
      "x" = "Use either {.code x ~ z + (1 | group)} or {.code x ~ z + relmat(1 | group, Q = Q)}, not both."
    ))
  }
  if (
    !identical(family, "gaussian") &&
      (isTRUE(impute_structured$structured$enabled) ||
        isTRUE(impute_random$random$enabled))
  ) {
    cli::cli_abort(c(
      "Non-Gaussian {.arg impute} models currently support fixed effects only.",
      "x" = "The first finite-state missing-predictor slices do not support grouped or structured covariate effects.",
      "i" = "Use syntax such as {.code impute = list(x = impute_model(x ~ z, family = binomial()))}, {.code impute_model(x ~ z, family = cumulative_logit())}, {.code impute_model(x ~ z, family = categorical())}, {.code impute_model(x ~ z, family = beta())}, {.code impute_model(x ~ z, family = zero_one_beta())}, {.code impute_model(success ~ z, family = beta_binomial(), trials = trials)}, {.code impute_model(x ~ z, family = poisson())}, {.code impute_model(x ~ z, family = nbinom2())}, {.code impute_model(x ~ z, family = truncated_nbinom2())}, {.code impute_model(x ~ z, family = lognormal())}, {.code impute_model(x ~ z, family = Gamma(link = \"log\"))}, or {.code impute_model(x ~ z, family = tweedie())}."
    ))
  }
  rhs_names <- all.names(
    impute_random$fixed_formula[[3L]],
    functions = TRUE,
    unique = TRUE
  )
  unsupported <- intersect(
    rhs_names,
    c("meta_V", "meta_known_V")
  )
  if (length(unsupported) > 0L) {
    cli::cli_abort(c(
      "The current {.arg impute} slices do not support known-covariance markers inside predictor models.",
      "x" = "Unsupported term marker{?s}: {.val {unsupported}}."
    ))
  }
  list(
    formula = impute_random$fixed_formula,
    raw_formula = formula,
    family = family,
    trials = trials_expr,
    trials_variable = if (identical(family, "beta_binomial")) {
      as.character(trials_expr)
    } else {
      character(0)
    },
    response_variable = if (identical(family, "beta_binomial")) {
      as.character(formula[[2L]])
    } else {
      variable
    },
    random = impute_random$random,
    structured = impute_structured$structured
  )
}

drm_extract_impute_structured_intercept <- function(formula) {
  entry <- parse_drm_formula_entry(formula, "", 1L)
  phylo_interaction <- extract_gaussian_mu_phylo_interaction_term(
    entry,
    dpar = "impute"
  )
  if (!is.null(phylo_interaction$term)) {
    cli::cli_abort(c(
      "The MD4 {.arg impute} route does not support {.fn phylo_interaction} covariate models.",
      "i" = "Use one of {.fn phylo}, {.fn spatial}, {.fn animal}, or {.fn relmat} for the first structured {.fn mi} slice."
    ))
  }
  entry$rhs <- phylo_interaction$rhs

  phylo <- extract_gaussian_mu_phylo_term(entry, dpar = "impute")
  entry$rhs <- phylo$rhs
  spatial <- extract_gaussian_mu_spatial_term(entry, dpar = "impute")
  entry$rhs <- spatial$rhs
  animal <- extract_gaussian_mu_known_term(entry, "animal", dpar = "impute")
  entry$rhs <- animal$rhs
  relmat <- extract_gaussian_mu_known_term(entry, "relmat", dpar = "impute")
  entry$rhs <- relmat$rhs

  terms <- list(
    phylo = phylo$term,
    spatial = spatial$term,
    animal = animal$term,
    relmat = relmat$term
  )
  active <- names(terms)[!vapply(terms, is.null, logical(1))]
  if (length(active) == 0L) {
    return(list(
      fixed_formula = formula,
      structured = NULL
    ))
  }
  if (length(active) > 1L) {
    cli::cli_abort(c(
      "The MD4 {.arg impute} route supports only one structured covariate model.",
      "x" = "Found structured marker{?s}: {.val {active}}."
    ))
  }
  term <- terms[[active]]
  if (!identical(term$coef_names, "(Intercept)")) {
    cli::cli_abort(c(
      "The MD4 {.arg impute} route supports only intercept-only structured covariate models.",
      "x" = "Requested structured coefficient{?s}: {.val {term$coef_names}}.",
      "i" = "Use syntax like {.code x ~ z + relmat(1 | line, Q = Q)}."
    ))
  }
  fixed_formula <- formula
  fixed_formula[[3L]] <- entry$rhs
  list(
    fixed_formula = fixed_formula,
    structured = list(
      enabled = TRUE,
      term = term
    )
  )
}

drm_extract_impute_random_intercept <- function(formula) {
  rhs_terms <- drm_split_additive_rhs(formula[[3L]])
  is_bar <- vapply(
    rhs_terms,
    function(term) {
      formula_contains_call(term, "|")
    },
    logical(1)
  )
  if (!any(is_bar)) {
    return(list(
      fixed_formula = formula,
      random = NULL
    ))
  }
  if (sum(is_bar) != 1L) {
    cli::cli_abort(
      "The MD3b {.arg impute} slice supports only one random-intercept term."
    )
  }
  random_term <- drm_unwrap_parentheses(rhs_terms[[which(is_bar)]])
  if (
    !is.call(random_term) || !identical(as.character(random_term[[1L]]), "|")
  ) {
    cli::cli_abort(c(
      "The MD3b {.arg impute} random-effect term must be additive and simple.",
      "i" = "Use syntax such as {.code x ~ z + (1 | group)}."
    ))
  }
  if (length(random_term) != 3L || !drm_is_one_expr(random_term[[2L]])) {
    cli::cli_abort(c(
      "The MD3b {.arg impute} route supports only random intercepts.",
      "x" = "Use {.code (1 | group)}, not random slopes or correlated covariate blocks."
    ))
  }
  group_expr <- random_term[[3L]]
  if (!is.symbol(group_expr)) {
    cli::cli_abort(c(
      "The MD3b {.arg impute} grouping variable must be a bare column name.",
      "x" = "Use syntax such as {.code (1 | group)}."
    ))
  }
  fixed_terms <- rhs_terms[!is_bar]
  fixed_rhs <- drm_rebuild_additive_rhs(fixed_terms)
  fixed_formula <- formula
  fixed_formula[[3L]] <- fixed_rhs
  list(
    fixed_formula = fixed_formula,
    random = list(
      enabled = TRUE,
      group = as.character(group_expr),
      term = random_term
    )
  )
}

drm_split_additive_rhs <- function(expr) {
  if (is.call(expr) && identical(as.character(expr[[1L]]), "+")) {
    return(c(
      drm_split_additive_rhs(expr[[2L]]),
      drm_split_additive_rhs(expr[[3L]])
    ))
  }
  list(expr)
}

drm_rebuild_additive_rhs <- function(terms) {
  if (length(terms) == 0L) {
    return(quote(1))
  }
  out <- terms[[1L]]
  if (length(terms) == 1L) {
    return(out)
  }
  for (i in seq.int(2L, length(terms))) {
    out <- call("+", out, terms[[i]])
  }
  out
}

drm_unwrap_parentheses <- function(expr) {
  while (is.call(expr) && identical(as.character(expr[[1L]]), "(")) {
    expr <- expr[[2L]]
  }
  expr
}

drm_is_one_expr <- function(expr) {
  is.numeric(expr) && length(expr) == 1L && identical(as.numeric(expr), 1)
}

drm_empty_missing_predictor_model <- function(n = 1L) {
  list(
    enabled = FALSE,
    variable = character(0),
    label = character(0),
    model_column = character(0),
    mu_col = 0L,
    family = "none",
    x = rep(0, n),
    observed = rep(TRUE, n),
    missing_index = integer(0),
    X = matrix(0, nrow = 1L, ncol = 1L),
    formula = NULL,
    raw_formula = NULL,
    theta_start = 0,
    coef_names = character(0),
    predictor_names = character(0),
    levels = character(0),
    n_state = 0L,
    X_mu_state = matrix(0, nrow = 1L, ncol = 1L),
    quad_nodes = 0,
    quad_weights = 1,
    response_value = NULL,
    summary = "none",
    random = list(
      enabled = FALSE,
      group = character(0),
      levels = character(0),
      n_group = 0L,
      group_index = integer(0)
    ),
    structured = list(
      enabled = FALSE,
      type = character(0),
      label = character(0),
      group = character(0),
      levels = character(0),
      n_re = 0L,
      index = integer(0),
      value = numeric(0),
      precision = NULL,
      log_det_precision = 0
    )
  )
}

drm_build_gaussian_missing_predictor_model <- function(
  setup,
  data_model,
  env = parent.frame()
) {
  if (!isTRUE(setup$enabled)) {
    return(drm_empty_missing_predictor_model(nrow(data_model)))
  }
  if (identical(setup$family, "bernoulli")) {
    return(drm_build_bernoulli_missing_predictor_model(
      setup,
      data_model,
      env = env
    ))
  }
  if (identical(setup$family, "ordinal")) {
    return(drm_build_ordinal_missing_predictor_model(
      setup,
      data_model,
      env = env
    ))
  }
  if (identical(setup$family, "categorical")) {
    return(drm_build_categorical_missing_predictor_model(
      setup,
      data_model,
      env = env
    ))
  }
  if (identical(setup$family, "beta")) {
    return(drm_build_beta_missing_predictor_model(
      setup,
      data_model,
      env = env
    ))
  }
  if (identical(setup$family, "zero_one_beta")) {
    return(drm_build_zero_one_beta_missing_predictor_model(
      setup,
      data_model,
      env = env
    ))
  }
  if (identical(setup$family, "beta_binomial")) {
    return(drm_build_beta_binomial_missing_predictor_model(
      setup,
      data_model,
      env = env
    ))
  }
  if (identical(setup$family, "poisson")) {
    return(drm_build_poisson_missing_predictor_model(
      setup,
      data_model,
      env = env
    ))
  }
  if (identical(setup$family, "nbinom2")) {
    return(drm_build_nbinom2_missing_predictor_model(
      setup,
      data_model,
      env = env
    ))
  }
  if (identical(setup$family, "truncated_nbinom2")) {
    return(drm_build_truncated_nbinom2_missing_predictor_model(
      setup,
      data_model,
      env = env
    ))
  }
  if (identical(setup$family, "lognormal")) {
    return(drm_build_lognormal_missing_predictor_model(
      setup,
      data_model,
      env = env
    ))
  }
  if (identical(setup$family, "gamma")) {
    return(drm_build_gamma_missing_predictor_model(
      setup,
      data_model,
      env = env
    ))
  }
  if (identical(setup$family, "tweedie")) {
    return(drm_build_tweedie_missing_predictor_model(
      setup,
      data_model,
      env = env
    ))
  }
  impute_formula <- setup$formula
  environment(impute_formula) <- env
  mf <- stats::model.frame(
    impute_formula,
    data = data_model,
    na.action = stats::na.pass
  )
  x_raw <- stats::model.response(mf)
  if (!is.numeric(x_raw) && !is.integer(x_raw)) {
    cli::cli_abort(c(
      "The first {.fn mi} slice supports numeric missing predictors only.",
      "x" = "Predictor {.val {setup$variable}} has class {.val {class(x_raw)}}."
    ))
  }
  x_raw <- as.numeric(x_raw)
  observed <- !is.na(x_raw)
  if (!any(!observed)) {
    cli::cli_abort(c(
      "{.code miss_control(predictor = \"model\")} requires at least one missing {.fn mi} predictor value.",
      "i" = "Use ordinary predictor syntax when {.code {setup$variable}} is complete."
    ))
  }
  if (!any(observed)) {
    cli::cli_abort(
      "At least one observed {.fn mi} predictor value is required for the predictor model."
    )
  }
  if (any(!is.finite(x_raw[observed]))) {
    cli::cli_abort(
      "Observed {.fn mi} predictor values must be finite."
    )
  }
  terms_x <- stats::delete.response(stats::terms(mf))
  rhs_vars <- all.vars(terms_x)
  if (length(rhs_vars) > 0L) {
    rhs_complete <- stats::complete.cases(mf[, rhs_vars, drop = FALSE])
    if (any(!rhs_complete)) {
      cli::cli_abort(c(
        "Missing predictors inside the {.arg impute} formula are not implemented.",
        "x" = "{sum(!rhs_complete)} retained row{?s} {?has/have} missing imputation-model predictor value{?s}."
      ))
    }
  }
  X <- stats::model.matrix(terms_x, mf)
  if (sum(observed) <= ncol(X)) {
    cli::cli_abort(c(
      "The Gaussian {.arg impute} model is weakly identified for the first {.fn mi} slice.",
      "x" = "It has {sum(observed)} observed {.code {setup$variable}} value{?s} and {ncol(X)} fixed-effect coefficient{?s}.",
      "i" = "Use a simpler predictor model or supply more observed predictor values."
    ))
  }
  fit <- stats::lm.fit(x = X[observed, , drop = FALSE], y = x_raw[observed])
  beta <- fit$coefficients
  beta[is.na(beta)] <- 0
  names(beta) <- colnames(X)
  eta <- as.vector(X %*% beta)
  resid <- x_raw[observed] - eta[observed]
  sigma <- stats::sd(resid)
  x_scale <- stats::sd(x_raw[observed])
  if (!is.finite(x_scale) || x_scale <= 0) {
    x_scale <- 1
  }
  random <- drm_build_gaussian_mi_random_intercept(setup, data_model)
  structured <- drm_build_gaussian_mi_structured_intercept(
    setup,
    data_model,
    env = env
  )
  sigma_floor <- max(1e-4, 0.05 * x_scale)
  if (!is.finite(sigma) || sigma <= 0) {
    sigma <- sigma_floor
  }
  sigma <- max(sigma, sigma_floor)
  x <- x_raw
  x[!observed] <- eta[!observed]
  log_sd_group_start <- if (isTRUE(random$enabled)) {
    log(max(1e-4, 0.25 * x_scale))
  } else {
    0
  }
  log_sd_structured_start <- if (isTRUE(structured$enabled)) {
    log(max(1e-4, 0.25 * x_scale))
  } else {
    0
  }
  list(
    enabled = TRUE,
    variable = setup$variable,
    label = setup$label,
    model_column = setup$model_column,
    mu_col = NA_integer_,
    family = "gaussian",
    x = x,
    observed = observed,
    missing_index = which(!observed),
    X = X,
    formula = impute_formula,
    raw_formula = setup$raw_formula,
    beta_start = beta,
    log_sigma_start = log(sigma),
    x_miss_start = x[!observed],
    theta_start = 0,
    coef_names = colnames(X),
    predictor_names = rhs_vars,
    levels = character(0),
    n_state = 0L,
    X_mu_state = matrix(0, nrow = 1L, ncol = 1L),
    response_value = NULL,
    summary = "conditional_mode",
    random = random,
    structured = structured,
    u_group_start = if (isTRUE(random$enabled)) {
      rep(0, random$n_group)
    } else {
      0
    },
    log_sd_group_start = log_sd_group_start,
    u_structured_start = if (isTRUE(structured$enabled)) {
      rep(0, structured$n_re)
    } else {
      0
    },
    log_sd_structured_start = log_sd_structured_start
  )
}

drm_build_bernoulli_missing_predictor_model <- function(
  setup,
  data_model,
  env = parent.frame()
) {
  impute_formula <- setup$formula
  environment(impute_formula) <- env
  mf <- stats::model.frame(
    impute_formula,
    data = data_model,
    na.action = stats::na.pass
  )
  x_binary <- drm_binary_missing_predictor_response(
    stats::model.response(mf),
    setup$variable
  )
  x_raw <- x_binary$value
  observed <- !is.na(x_raw)
  if (!any(!observed)) {
    cli::cli_abort(c(
      "{.code miss_control(predictor = \"model\")} requires at least one missing {.fn mi} predictor value.",
      "i" = "Use ordinary predictor syntax when {.code {setup$variable}} is complete."
    ))
  }
  if (!any(observed)) {
    cli::cli_abort(
      "At least one observed binary {.fn mi} predictor value is required for the predictor model."
    )
  }
  terms_x <- stats::delete.response(stats::terms(mf))
  rhs_vars <- all.vars(terms_x)
  if (length(rhs_vars) > 0L) {
    rhs_complete <- stats::complete.cases(mf[, rhs_vars, drop = FALSE])
    if (any(!rhs_complete)) {
      cli::cli_abort(c(
        "Missing predictors inside the {.arg impute} formula are not implemented.",
        "x" = "{sum(!rhs_complete)} retained row{?s} {?has/have} missing imputation-model predictor value{?s}."
      ))
    }
  }
  X <- stats::model.matrix(terms_x, mf)
  if (sum(observed) <= ncol(X)) {
    cli::cli_abort(c(
      "The binary {.arg impute} model is weakly identified for the first discrete {.fn mi} slice.",
      "x" = "It has {sum(observed)} observed {.code {setup$variable}} value{?s} and {ncol(X)} fixed-effect coefficient{?s}.",
      "i" = "Use a simpler predictor model or supply more observed binary predictor values."
    ))
  }
  fit <- stats::glm.fit(
    x = X[observed, , drop = FALSE],
    y = x_raw[observed],
    family = stats::binomial()
  )
  beta <- fit$coefficients
  beta[is.na(beta)] <- 0
  names(beta) <- colnames(X)
  probability <- stats::plogis(as.vector(X %*% beta))
  x <- x_raw
  x[!observed] <- probability[!observed]
  list(
    enabled = TRUE,
    variable = setup$variable,
    label = setup$label,
    model_column = setup$model_column,
    mu_col = NA_integer_,
    family = "bernoulli",
    x = x,
    observed = observed,
    missing_index = which(!observed),
    X = X,
    formula = impute_formula,
    raw_formula = setup$raw_formula,
    beta_start = beta,
    log_sigma_start = 0,
    x_miss_start = 0,
    theta_start = 0,
    coef_names = colnames(X),
    predictor_names = rhs_vars,
    levels = x_binary$levels,
    n_state = 2L,
    X_mu_state = matrix(0, nrow = 1L, ncol = 1L),
    response_value = NULL,
    summary = "conditional_probability",
    random = list(
      enabled = FALSE,
      group = character(0),
      levels = character(0),
      n_group = 0L,
      group_index = integer(0)
    ),
    structured = list(
      enabled = FALSE,
      type = character(0),
      label = character(0),
      group = character(0),
      levels = character(0),
      n_re = 0L,
      index = integer(0),
      value = numeric(0),
      precision = NULL,
      log_det_precision = 0
    ),
    u_group_start = 0,
    log_sd_group_start = 0,
    u_structured_start = 0,
    log_sd_structured_start = 0
  )
}

drm_binary_missing_predictor_response <- function(x, variable) {
  observed <- !is.na(x)
  if (!any(observed)) {
    return(list(value = rep(NA_real_, length(x)), levels = character(0)))
  }
  if (is.factor(x)) {
    levels <- levels(x)
    if (length(levels) != 2L) {
      cli::cli_abort(c(
        "The first binary {.fn mi} slice requires exactly two predictor levels.",
        "x" = "Predictor {.val {variable}} has {length(levels)} level{?s}: {.val {levels}}."
      ))
    }
    value <- as.integer(x) - 1L
    value[!observed] <- NA_integer_
    return(list(value = as.numeric(value), levels = levels))
  }
  if (is.logical(x)) {
    return(list(
      value = as.numeric(x),
      levels = c("FALSE", "TRUE")
    ))
  }
  if (is.character(x)) {
    levels <- sort(unique(x[observed]))
    if (length(levels) != 2L) {
      cli::cli_abort(c(
        "The first binary {.fn mi} slice requires exactly two predictor levels.",
        "x" = "Predictor {.val {variable}} has {length(levels)} observed level{?s}: {.val {levels}}."
      ))
    }
    value <- match(x, levels) - 1L
    value[!observed] <- NA_integer_
    return(list(value = as.numeric(value), levels = levels))
  }
  if (is.numeric(x) || is.integer(x)) {
    values <- sort(unique(x[observed]))
    if (
      length(values) != 2L ||
        any(!is.finite(values)) ||
        !identical(as.numeric(values), c(0, 1))
    ) {
      cli::cli_abort(c(
        "The first binary {.fn mi} slice requires a two-level or 0/1-like predictor.",
        "x" = "Predictor {.val {variable}} has observed values {.val {values}}."
      ))
    }
    value <- as.numeric(x)
    value[!observed] <- NA_integer_
    return(list(value = as.numeric(value), levels = as.character(values)))
  }
  cli::cli_abort(c(
    "The first binary {.fn mi} slice supports logical, two-level factor, character, or numeric binary predictors.",
    "x" = "Predictor {.val {variable}} has class {.val {class(x)}}."
  ))
}

drm_build_ordinal_missing_predictor_model <- function(
  setup,
  data_model,
  env = parent.frame()
) {
  impute_formula <- setup$formula
  environment(impute_formula) <- env
  mf <- stats::model.frame(
    impute_formula,
    data = data_model,
    na.action = stats::na.pass
  )
  x_ordinal <- drm_ordinal_missing_predictor_response(
    stats::model.response(mf),
    setup$variable
  )
  x_raw <- x_ordinal$value
  observed <- !is.na(x_raw)
  if (!any(!observed)) {
    cli::cli_abort(c(
      "{.code miss_control(predictor = \"model\")} requires at least one missing {.fn mi} predictor value.",
      "i" = "Use ordinary predictor syntax when {.code {setup$variable}} is complete."
    ))
  }
  if (!any(observed)) {
    cli::cli_abort(
      "At least one observed ordered {.fn mi} predictor value is required for the predictor model."
    )
  }
  terms_x <- stats::delete.response(stats::terms(mf))
  rhs_vars <- all.vars(terms_x)
  if (length(rhs_vars) > 0L) {
    rhs_complete <- stats::complete.cases(mf[, rhs_vars, drop = FALSE])
    if (any(!rhs_complete)) {
      cli::cli_abort(c(
        "Missing predictors inside the {.arg impute} formula are not implemented.",
        "x" = "{sum(!rhs_complete)} retained row{?s} {?has/have} missing imputation-model predictor value{?s}."
      ))
    }
  }
  X <- ordinal_mu_model_matrix(terms_x, mf)
  n_category <- length(x_ordinal$levels)
  n_parameter <- ncol(X) + n_category - 1L
  if (sum(observed) <= n_parameter) {
    cli::cli_abort(c(
      "The ordered {.arg impute} model is weakly identified for the first ordinal {.fn mi} slice.",
      "x" = "It has {sum(observed)} observed {.code {setup$variable}} value{?s} and {n_parameter} predictor-model parameter{?s}.",
      "i" = "Use a simpler predictor model, combine sparse categories, or supply more observed ordered predictor values."
    ))
  }
  beta <- rep(0, ncol(X))
  names(beta) <- colnames(X)
  cumulative <- cumsum(tabulate(x_raw[observed], nbins = n_category)) /
    sum(observed)
  cutpoints <- stats::qlogis(cumulative[-n_category])
  theta_start <- ordinal_raw_from_cutpoints(cutpoints)
  names(theta_start) <- ordinal_cutpoint_names(x_ordinal$levels)
  eta <- as.vector(X %*% beta)
  probability <- drm_ordinal_probability_matrix(eta, cutpoints)
  expected <- as.vector(probability %*% seq_len(n_category))
  x <- x_raw
  x[!observed] <- expected[!observed]
  response_value <- ordered(
    x_ordinal$levels[pmax(1L, as.integer(round(x)))],
    levels = x_ordinal$levels
  )
  list(
    enabled = TRUE,
    variable = setup$variable,
    label = setup$label,
    model_column = setup$model_column,
    mu_col = NA_integer_,
    family = "ordinal",
    x = x,
    observed = observed,
    missing_index = which(!observed),
    X = X,
    formula = impute_formula,
    raw_formula = setup$raw_formula,
    beta_start = beta,
    log_sigma_start = 0,
    x_miss_start = 0,
    theta_start = theta_start,
    coef_names = colnames(X),
    predictor_names = rhs_vars,
    levels = x_ordinal$levels,
    n_state = n_category,
    X_mu_state = matrix(0, nrow = 1L, ncol = 1L),
    response_value = response_value,
    summary = "conditional_expected_score",
    random = list(
      enabled = FALSE,
      group = character(0),
      levels = character(0),
      n_group = 0L,
      group_index = integer(0)
    ),
    structured = list(
      enabled = FALSE,
      type = character(0),
      label = character(0),
      group = character(0),
      levels = character(0),
      n_re = 0L,
      index = integer(0),
      value = numeric(0),
      precision = NULL,
      log_det_precision = 0
    ),
    u_group_start = 0,
    log_sd_group_start = 0,
    u_structured_start = 0,
    log_sd_structured_start = 0
  )
}

drm_ordinal_missing_predictor_response <- function(x, variable) {
  observed <- !is.na(x)
  if (!any(observed)) {
    return(list(value = rep(NA_real_, length(x)), levels = character(0)))
  }
  if (is.ordered(x)) {
    levels <- levels(x)
    value <- as.integer(x)
    value[!observed] <- NA_integer_
    return(drm_validate_ordinal_missing_predictor(
      value,
      levels = levels,
      variable = variable
    ))
  }
  if (is.factor(x)) {
    cli::cli_abort(c(
      "Ordered missing-predictor models require an ordered predictor.",
      "x" = "Predictor {.val {variable}} is an unordered factor.",
      "i" = "Use {.code ordered({variable})} for {.fn cumulative_logit} predictor models, or use {.fn categorical} for unordered predictor models."
    ))
  }
  if (!is.numeric(x) && !is.integer(x)) {
    cli::cli_abort(c(
      "Ordered missing-predictor models require an ordered factor or integer category scores.",
      "x" = "Predictor {.val {variable}} has class {.val {class(x)}}."
    ))
  }
  tolerance <- sqrt(.Machine$double.eps)
  if (
    any(!is.finite(x[observed])) ||
      any(x[observed] < 1) ||
      any(abs(x[observed] - round(x[observed])) > tolerance)
  ) {
    cli::cli_abort(c(
      "Numeric ordered missing predictors must be finite integer category scores starting at 1.",
      "x" = "Predictor {.val {variable}} contains non-integer, non-finite, or less-than-one observed values."
    ))
  }
  value <- as.integer(round(x))
  value[!observed] <- NA_integer_
  drm_validate_ordinal_missing_predictor(
    value,
    levels = as.character(seq_len(max(value[observed]))),
    variable = variable
  )
}

drm_validate_ordinal_missing_predictor <- function(value, levels, variable) {
  n_category <- length(levels)
  if (n_category < 3L) {
    cli::cli_abort(c(
      "{.fn cumulative_logit} missing-predictor models need at least three ordered categories.",
      "x" = "Predictor {.val {variable}} has {n_category} categor{?y/ies}."
    ))
  }
  observed <- !is.na(value)
  if (!all(value[observed] %in% seq_len(n_category))) {
    cli::cli_abort(
      "Internal ordered missing-predictor coding is outside 1, ..., K."
    )
  }
  counts <- tabulate(value[observed], nbins = n_category)
  if (any(counts == 0L)) {
    empty <- levels[counts == 0L]
    cli::cli_abort(c(
      "Every ordered predictor category must appear at least once among observed values.",
      "x" = "Predictor {.val {variable}} has empty observed categor{?y/ies}: {.val {empty}}.",
      "i" = "Drop unused ordered-factor levels or combine sparse categories before fitting the first ordinal {.fn mi} slice."
    ))
  }
  list(value = as.numeric(value), levels = levels)
}

drm_ordinal_probability_matrix <- function(eta, cutpoints) {
  n_category <- length(cutpoints) + 1L
  out <- matrix(NA_real_, nrow = length(eta), ncol = n_category)
  out[, 1L] <- stats::plogis(cutpoints[[1L]] - eta)
  if (n_category > 2L) {
    for (k in 2:(n_category - 1L)) {
      upper <- stats::plogis(cutpoints[[k]] - eta)
      lower <- stats::plogis(cutpoints[[k - 1L]] - eta)
      out[, k] <- upper - lower
    }
  }
  out[, n_category] <- stats::plogis(
    cutpoints[[n_category - 1L]] - eta,
    lower.tail = FALSE
  )
  pmax(out, .Machine$double.eps)
}

drm_build_categorical_missing_predictor_model <- function(
  setup,
  data_model,
  env = parent.frame()
) {
  impute_formula <- setup$formula
  environment(impute_formula) <- env
  mf <- stats::model.frame(
    impute_formula,
    data = data_model,
    na.action = stats::na.pass
  )
  x_categorical <- drm_categorical_missing_predictor_response(
    stats::model.response(mf),
    setup$variable
  )
  x_raw <- x_categorical$value
  observed <- !is.na(x_raw)
  if (!any(!observed)) {
    cli::cli_abort(c(
      "{.code miss_control(predictor = \"model\")} requires at least one missing {.fn mi} predictor value.",
      "i" = "Use ordinary predictor syntax when {.code {setup$variable}} is complete."
    ))
  }
  if (!any(observed)) {
    cli::cli_abort(
      "At least one observed unordered categorical {.fn mi} predictor value is required for the predictor model."
    )
  }
  terms_x <- stats::delete.response(stats::terms(mf))
  rhs_vars <- all.vars(terms_x)
  if (length(rhs_vars) > 0L) {
    rhs_complete <- stats::complete.cases(mf[, rhs_vars, drop = FALSE])
    if (any(!rhs_complete)) {
      cli::cli_abort(c(
        "Missing predictors inside the {.arg impute} formula are not implemented.",
        "x" = "{sum(!rhs_complete)} retained row{?s} {?has/have} missing imputation-model predictor value{?s}."
      ))
    }
  }
  X <- stats::model.matrix(terms_x, mf)
  n_category <- length(x_categorical$levels)
  n_parameter <- ncol(X) * (n_category - 1L)
  if (sum(observed) <= n_parameter) {
    cli::cli_abort(c(
      "The categorical {.arg impute} model is weakly identified for the first unordered {.fn mi} slice.",
      "x" = "It has {sum(observed)} observed {.code {setup$variable}} value{?s} and {n_parameter} predictor-model coefficient{?s}.",
      "i" = "Use a simpler predictor model, combine sparse categories, or supply more observed categorical predictor values."
    ))
  }
  beta_matrix <- matrix(
    0,
    nrow = ncol(X),
    ncol = n_category - 1L,
    dimnames = list(colnames(X), x_categorical$levels[-1L])
  )
  if ("(Intercept)" %in% rownames(beta_matrix)) {
    counts <- tabulate(x_raw[observed], nbins = n_category)
    probability <- counts / sum(counts)
    beta_matrix["(Intercept)", ] <- log(probability[-1L] / probability[[1L]])
  }
  beta <- as.numeric(beta_matrix)
  names(beta) <- drm_categorical_coef_names(
    colnames(X),
    x_categorical$levels
  )
  probability <- drm_categorical_probability_matrix(
    X,
    beta,
    n_state = n_category
  )
  modal_state <- max.col(probability, ties.method = "first")
  x <- x_raw
  x[!observed] <- modal_state[!observed]
  response_value <- factor(
    x_categorical$levels[pmax(1L, as.integer(round(x)))],
    levels = x_categorical$levels
  )
  list(
    enabled = TRUE,
    variable = setup$variable,
    label = setup$label,
    model_column = setup$model_column,
    mu_col = NA_integer_,
    family = "categorical",
    x = x,
    observed = observed,
    missing_index = which(!observed),
    X = X,
    formula = impute_formula,
    raw_formula = setup$raw_formula,
    beta_start = beta,
    log_sigma_start = 0,
    x_miss_start = 0,
    theta_start = 0,
    coef_names = names(beta),
    predictor_names = rhs_vars,
    levels = x_categorical$levels,
    n_state = n_category,
    X_mu_state = matrix(0, nrow = 1L, ncol = 1L),
    response_value = response_value,
    summary = "conditional_modal_category",
    random = list(
      enabled = FALSE,
      group = character(0),
      levels = character(0),
      n_group = 0L,
      group_index = integer(0)
    ),
    structured = list(
      enabled = FALSE,
      type = character(0),
      label = character(0),
      group = character(0),
      levels = character(0),
      n_re = 0L,
      index = integer(0),
      value = numeric(0),
      precision = NULL,
      log_det_precision = 0
    ),
    u_group_start = 0,
    log_sd_group_start = 0,
    u_structured_start = 0,
    log_sd_structured_start = 0
  )
}

drm_categorical_missing_predictor_response <- function(x, variable) {
  observed <- !is.na(x)
  if (!any(observed)) {
    return(list(value = rep(NA_real_, length(x)), levels = character(0)))
  }
  if (is.ordered(x)) {
    cli::cli_abort(c(
      "Unordered categorical missing-predictor models require an unordered predictor.",
      "x" = "Predictor {.val {variable}} is ordered.",
      "i" = "Use {.fn cumulative_logit} for ordered categorical predictor models."
    ))
  }
  if (is.factor(x)) {
    levels <- levels(x)
    value <- as.integer(x)
    value[!observed] <- NA_integer_
    return(drm_validate_categorical_missing_predictor(
      value,
      levels = levels,
      variable = variable
    ))
  }
  if (is.character(x)) {
    levels <- sort(unique(x[observed]))
    value <- match(x, levels)
    value[!observed] <- NA_integer_
    return(drm_validate_categorical_missing_predictor(
      value,
      levels = levels,
      variable = variable
    ))
  }
  if (is.numeric(x) || is.integer(x)) {
    observed_values <- x[observed]
    tolerance <- sqrt(.Machine$double.eps)
    if (
      any(!is.finite(observed_values)) ||
        any(observed_values < 1) ||
        any(abs(observed_values - round(observed_values)) > tolerance)
    ) {
      cli::cli_abort(c(
        "Numeric unordered categorical missing predictors must be finite integer category scores starting at 1.",
        "x" = "Predictor {.val {variable}} contains non-integer, non-finite, or less-than-one observed values."
      ))
    }
    value <- as.integer(round(x))
    value[!observed] <- NA_integer_
    return(drm_validate_categorical_missing_predictor(
      value,
      levels = as.character(seq_len(max(value[observed]))),
      variable = variable
    ))
  }
  cli::cli_abort(c(
    "Unordered categorical missing-predictor models require an unordered factor, character, or integer category predictor.",
    "x" = "Predictor {.val {variable}} has class {.val {class(x)}}."
  ))
}

drm_validate_categorical_missing_predictor <- function(
  value,
  levels,
  variable
) {
  n_category <- length(levels)
  if (n_category < 3L) {
    cli::cli_abort(c(
      "{.fn categorical} missing-predictor models need at least three unordered categories.",
      "x" = "Predictor {.val {variable}} has {n_category} categor{?y/ies}.",
      "i" = "Use {.code binomial(link = \"logit\")} for two-level missing predictors."
    ))
  }
  observed <- !is.na(value)
  if (!all(value[observed] %in% seq_len(n_category))) {
    cli::cli_abort(
      "Internal unordered categorical missing-predictor coding is outside 1, ..., K."
    )
  }
  counts <- tabulate(value[observed], nbins = n_category)
  if (any(counts == 0L)) {
    empty <- levels[counts == 0L]
    cli::cli_abort(c(
      "Every unordered predictor category must appear at least once among observed values.",
      "x" = "Predictor {.val {variable}} has empty observed categor{?y/ies}: {.val {empty}}.",
      "i" = "Drop unused factor levels or combine sparse categories before fitting the first categorical {.fn mi} slice."
    ))
  }
  list(value = as.numeric(value), levels = levels)
}

drm_categorical_coef_names <- function(coef_names, levels) {
  as.vector(outer(coef_names, levels[-1L], function(coef, level) {
    paste(level, coef, sep = ":")
  }))
}

drm_categorical_probability_matrix <- function(X, beta, n_state) {
  beta_matrix <- matrix(
    beta,
    nrow = ncol(X),
    ncol = n_state - 1L
  )
  eta <- cbind(0, X %*% beta_matrix)
  row_max <- apply(eta, 1L, max)
  probability <- exp(eta - row_max)
  probability / rowSums(probability)
}

drm_build_beta_missing_predictor_model <- function(
  setup,
  data_model,
  env = parent.frame()
) {
  impute_formula <- setup$formula
  environment(impute_formula) <- env
  mf <- stats::model.frame(
    impute_formula,
    data = data_model,
    na.action = stats::na.pass
  )
  x_raw <- drm_beta_missing_predictor_response(
    stats::model.response(mf),
    setup$variable
  )
  observed <- !is.na(x_raw)
  if (!any(!observed)) {
    cli::cli_abort(c(
      "{.code miss_control(predictor = \"model\")} requires at least one missing {.fn mi} predictor value.",
      "i" = "Use ordinary predictor syntax when {.code {setup$variable}} is complete."
    ))
  }
  if (!any(observed)) {
    cli::cli_abort(
      "At least one observed beta/proportion {.fn mi} predictor value is required for the predictor model."
    )
  }
  terms_x <- stats::delete.response(stats::terms(mf))
  rhs_vars <- all.vars(terms_x)
  if (length(rhs_vars) > 0L) {
    rhs_complete <- stats::complete.cases(mf[, rhs_vars, drop = FALSE])
    if (any(!rhs_complete)) {
      cli::cli_abort(c(
        "Missing predictors inside the {.arg impute} formula are not implemented.",
        "x" = "{sum(!rhs_complete)} retained row{?s} {?has/have} missing imputation-model predictor value{?s}."
      ))
    }
  }
  X <- stats::model.matrix(terms_x, mf)
  if (sum(observed) <= ncol(X) + 1L) {
    cli::cli_abort(c(
      "The beta {.arg impute} model is weakly identified for the first proportion {.fn mi} slice.",
      "x" = "It has {sum(observed)} observed {.code {setup$variable}} value{?s} and {ncol(X) + 1L} predictor-model coefficient/scale parameter{?s}.",
      "i" = "Use a simpler predictor model or supply more observed proportion predictor values."
    ))
  }
  X_sigma <- matrix(1, nrow = sum(observed), ncol = 1L)
  start <- beta_ls_start(
    y = x_raw[observed],
    X_mu = X[observed, , drop = FALSE],
    X_sigma = X_sigma
  )
  beta <- start$beta_mu
  beta[is.na(beta)] <- 0
  names(beta) <- colnames(X)
  log_sigma <- unname(start$beta_sigma[[1L]])
  if (!is.finite(log_sigma)) {
    log_sigma <- log(0.5)
  }
  eta <- as.vector(X %*% beta)
  mu <- drm_beta_missing_predictor_inverse_link(eta)
  x <- x_raw
  x[!observed] <- mu[!observed]
  quad <- drm_beta_mi_quadrature()
  list(
    enabled = TRUE,
    variable = setup$variable,
    label = setup$label,
    model_column = setup$model_column,
    mu_col = NA_integer_,
    family = "beta",
    x = x,
    observed = observed,
    missing_index = which(!observed),
    X = X,
    formula = impute_formula,
    raw_formula = setup$raw_formula,
    beta_start = beta,
    log_sigma_start = log_sigma,
    x_miss_start = 0,
    theta_start = 0,
    coef_names = colnames(X),
    predictor_names = rhs_vars,
    levels = character(0),
    n_state = 0L,
    X_mu_state = matrix(0, nrow = 1L, ncol = 1L),
    quad_nodes = quad$nodes,
    quad_weights = quad$weights,
    response_value = NULL,
    summary = "conditional_quadrature_mean",
    random = list(
      enabled = FALSE,
      group = character(0),
      levels = character(0),
      n_group = 0L,
      group_index = integer(0)
    ),
    structured = list(
      enabled = FALSE,
      type = character(0),
      label = character(0),
      group = character(0),
      levels = character(0),
      n_re = 0L,
      index = integer(0),
      value = numeric(0),
      precision = NULL,
      log_det_precision = 0
    ),
    u_group_start = 0,
    log_sd_group_start = 0,
    u_structured_start = 0,
    log_sd_structured_start = 0
  )
}

drm_beta_missing_predictor_response <- function(x, variable) {
  if (!is.numeric(x) && !is.integer(x)) {
    cli::cli_abort(c(
      "Beta/proportion missing-predictor models require a numeric predictor.",
      "x" = "Predictor {.val {variable}} has class {.val {class(x)}}."
    ))
  }
  x <- as.numeric(x)
  observed <- !is.na(x)
  if (
    any(!is.finite(x[observed])) || any(x[observed] <= 0 | x[observed] >= 1)
  ) {
    cli::cli_abort(c(
      "Beta/proportion missing-predictor models require observed values strictly between 0 and 1.",
      "x" = "Predictor {.val {variable}} contains boundary, out-of-range, or non-finite observed values.",
      "i" = "Use {.code impute_model(x ~ z, family = zero_one_beta())} for proportions with exact 0 or 1 values."
    ))
  }
  x
}

drm_beta_missing_predictor_inverse_link <- function(eta) {
  eps <- 1e-12
  eps + (1 - 2 * eps) * stats::plogis(eta)
}

drm_beta_mi_quadrature <- function() {
  nodes <- c(
    -0.9879925180204854,
    -0.937273392400706,
    -0.8482065834104272,
    -0.72441773136017,
    -0.5709721726085388,
    -0.3941513470775634,
    -0.2011940939974345,
    0,
    0.2011940939974345,
    0.3941513470775634,
    0.5709721726085388,
    0.72441773136017,
    0.8482065834104272,
    0.937273392400706,
    0.9879925180204854
  )
  weights <- c(
    0.03075324199611727,
    0.07036604748810812,
    0.1071592204671719,
    0.1395706779261543,
    0.1662692058169939,
    0.1861610000155622,
    0.1984314853271116,
    0.2025782419255613,
    0.1984314853271116,
    0.1861610000155622,
    0.1662692058169939,
    0.1395706779261543,
    0.1071592204671719,
    0.07036604748810812,
    0.03075324199611727
  )
  list(nodes = (nodes + 1) / 2, weights = weights / 2)
}

drm_beta_missing_predictor_log_density <- function(x, mu, sigma) {
  phi <- 1 / sigma^2
  stats::dbeta(
    x,
    shape1 = pmax(mu * phi, 1e-8),
    shape2 = pmax((1 - mu) * phi, 1e-8),
    log = TRUE
  )
}

drm_build_zero_one_beta_missing_predictor_model <- function(
  setup,
  data_model,
  env = parent.frame()
) {
  impute_formula <- setup$formula
  environment(impute_formula) <- env
  mf <- stats::model.frame(
    impute_formula,
    data = data_model,
    na.action = stats::na.pass
  )
  x_raw <- drm_zero_one_beta_missing_predictor_response(
    stats::model.response(mf),
    setup$variable
  )
  observed <- !is.na(x_raw)
  if (!any(!observed)) {
    cli::cli_abort(c(
      "{.code miss_control(predictor = \"model\")} requires at least one missing {.fn mi} predictor value.",
      "i" = "Use ordinary predictor syntax when {.code {setup$variable}} is complete."
    ))
  }
  if (!any(observed)) {
    cli::cli_abort(
      "At least one observed zero-one beta/proportion {.fn mi} predictor value is required for the predictor model."
    )
  }
  if (!any(x_raw[observed] > 0 & x_raw[observed] < 1)) {
    cli::cli_abort(c(
      "Zero-one beta missing-predictor models require at least one observed interior value.",
      "x" = "Predictor {.val {setup$variable}} contains only exact boundary values among observed rows.",
      "i" = "Interior beta parameters need at least one observed value with {.code 0 < x < 1}."
    ))
  }
  terms_x <- stats::delete.response(stats::terms(mf))
  rhs_vars <- all.vars(terms_x)
  if (length(rhs_vars) > 0L) {
    rhs_complete <- stats::complete.cases(mf[, rhs_vars, drop = FALSE])
    if (any(!rhs_complete)) {
      cli::cli_abort(c(
        "Missing predictors inside the {.arg impute} formula are not implemented.",
        "x" = "{sum(!rhs_complete)} retained row{?s} {?has/have} missing imputation-model predictor value{?s}."
      ))
    }
  }
  X <- stats::model.matrix(terms_x, mf)
  n_parameter <- ncol(X) + 3L
  if (sum(observed) <= n_parameter) {
    cli::cli_abort(c(
      "The zero-one beta {.arg impute} model is weakly identified for the first boundary-proportion {.fn mi} slice.",
      "x" = "It has {sum(observed)} observed {.code {setup$variable}} value{?s} and {n_parameter} predictor-model parameter{?s}.",
      "i" = "Use a simpler predictor model or supply more observed boundary-proportion predictor values."
    ))
  }
  interior <- observed & x_raw > 0 & x_raw < 1
  if (sum(interior) > ncol(X) + 1L) {
    start <- beta_ls_start(
      y = x_raw[interior],
      X_mu = X[interior, , drop = FALSE],
      X_sigma = matrix(1, nrow = sum(interior), ncol = 1L)
    )
    beta <- start$beta_mu
    log_sigma <- unname(start$beta_sigma[[1L]])
  } else {
    beta <- rep(0, ncol(X))
    beta[[1L]] <- stats::qlogis(
      min(max(mean(x_raw[interior]), 1e-4), 1 - 1e-4)
    )
    log_sigma <- log(0.5)
  }
  beta[!is.finite(beta) | is.na(beta)] <- 0
  names(beta) <- colnames(X)
  if (!is.finite(log_sigma)) {
    log_sigma <- log(0.5)
  }
  boundary <- observed & (x_raw == 0 | x_raw == 1)
  zoi0 <- min(max(mean(boundary[observed]), 1e-3), 0.95)
  coi0 <- if (any(boundary)) {
    min(max(mean(x_raw[boundary] == 1), 1e-3), 1 - 1e-3)
  } else {
    0.5
  }
  zoi_start <- stats::qlogis(zoi0)
  coi_start <- stats::qlogis(coi0)
  eta <- as.vector(X %*% beta)
  mu <- drm_beta_missing_predictor_inverse_link(eta)
  x <- x_raw
  x[!observed] <- (1 - zoi0) * mu[!observed] + zoi0 * coi0
  quad <- drm_zero_one_beta_mi_quadrature()
  list(
    enabled = TRUE,
    variable = setup$variable,
    label = setup$label,
    model_column = setup$model_column,
    mu_col = NA_integer_,
    family = "zero_one_beta",
    x = x,
    observed = observed,
    missing_index = which(!observed),
    X = X,
    formula = impute_formula,
    raw_formula = setup$raw_formula,
    beta_start = beta,
    log_sigma_start = log_sigma,
    zoi_start = zoi_start,
    coi_start = coi_start,
    x_miss_start = 0,
    theta_start = 0,
    coef_names = colnames(X),
    predictor_names = rhs_vars,
    levels = c("0", "interior", "1"),
    n_state = 0L,
    X_mu_state = matrix(0, nrow = 1L, ncol = 1L),
    quad_nodes = quad$nodes,
    quad_weights = quad$weights,
    response_value = NULL,
    summary = "conditional_quadrature_mean",
    random = list(
      enabled = FALSE,
      group = character(0),
      levels = character(0),
      n_group = 0L,
      group_index = integer(0)
    ),
    structured = list(
      enabled = FALSE,
      type = character(0),
      label = character(0),
      group = character(0),
      levels = character(0),
      n_re = 0L,
      index = integer(0),
      value = numeric(0),
      precision = NULL,
      log_det_precision = 0
    ),
    u_group_start = 0,
    log_sd_group_start = 0,
    u_structured_start = 0,
    log_sd_structured_start = 0
  )
}

drm_zero_one_beta_missing_predictor_response <- function(x, variable) {
  if (!is.numeric(x) && !is.integer(x)) {
    cli::cli_abort(c(
      "Zero-one beta/proportion missing-predictor models require a numeric predictor.",
      "x" = "Predictor {.val {variable}} has class {.val {class(x)}}."
    ))
  }
  x <- as.numeric(x)
  observed <- !is.na(x)
  if (any(!is.finite(x[observed])) || any(x[observed] < 0 | x[observed] > 1)) {
    cli::cli_abort(c(
      "Zero-one beta/proportion missing-predictor models require observed values in [0, 1].",
      "x" = "Predictor {.val {variable}} contains out-of-range or non-finite observed values.",
      "i" = "Use {.fn beta} for strict proportions or another predictor family when the support is not bounded by 0 and 1."
    ))
  }
  x
}

drm_zero_one_beta_mi_quadrature <- function() {
  beta <- drm_beta_mi_quadrature()
  list(
    nodes = c(0, beta$nodes, 1),
    weights = c(1, beta$weights, 1)
  )
}

drm_zero_one_beta_missing_predictor_log_density <- function(
  x,
  mu,
  sigma,
  zoi,
  coi
) {
  phi <- 1 / sigma^2
  alpha <- pmax(mu * phi, 1e-8)
  beta_shape <- pmax((1 - mu) * phi, 1e-8)
  out <- numeric(length(x))
  is_zero <- x <= 0
  is_one <- x >= 1
  is_interior <- !is_zero & !is_one
  out[is_zero] <- log(zoi) + log1p(-coi)
  out[is_one] <- log(zoi) + log(coi)
  out[is_interior] <- log1p(-zoi) +
    stats::dbeta(
      x[is_interior],
      shape1 = alpha,
      shape2 = beta_shape,
      log = TRUE
    )
  out
}

drm_build_beta_binomial_missing_predictor_model <- function(
  setup,
  data_model,
  env = parent.frame()
) {
  impute_formula <- setup$formula
  environment(impute_formula) <- env
  mf <- stats::model.frame(
    impute_formula,
    data = data_model,
    na.action = stats::na.pass
  )
  success_raw <- stats::model.response(mf)
  trials_raw <- data_model[[setup$trials_variable]]
  value_raw <- data_model[[setup$variable]]
  response <- drm_beta_binomial_missing_predictor_response(
    success = success_raw,
    trials = trials_raw,
    value = value_raw,
    variable = setup$variable,
    success_variable = setup$response_variable,
    trials_variable = setup$trials_variable
  )
  success <- response$success
  trials <- response$trials
  observed <- response$observed
  if (!any(!observed)) {
    cli::cli_abort(c(
      "{.code miss_control(predictor = \"model\")} requires at least one missing {.fn mi} predictor value.",
      "i" = "Use ordinary predictor syntax when {.code {setup$variable}} is complete or can be fully derived from observed successes and trials."
    ))
  }
  if (!any(observed)) {
    cli::cli_abort(
      "At least one observed beta-binomial success count is required for the denominator-aware {.fn mi} predictor model."
    )
  }
  terms_x <- stats::delete.response(stats::terms(mf))
  rhs_vars <- all.vars(terms_x)
  if (length(rhs_vars) > 0L) {
    rhs_complete <- stats::complete.cases(mf[, rhs_vars, drop = FALSE])
    if (any(!rhs_complete)) {
      cli::cli_abort(c(
        "Missing predictors inside the {.arg impute} formula are not implemented.",
        "x" = "{sum(!rhs_complete)} retained row{?s} {?has/have} missing imputation-model predictor value{?s}."
      ))
    }
  }
  X <- stats::model.matrix(terms_x, mf)
  if (sum(observed) <= ncol(X) + 1L) {
    cli::cli_abort(c(
      "The beta-binomial {.arg impute} model is weakly identified for the first denominator-aware proportion {.fn mi} slice.",
      "x" = "It has {sum(observed)} observed success count{?s} and {ncol(X) + 1L} predictor-model coefficient/scale parameter{?s}.",
      "i" = "Use a simpler predictor model or supply more observed success/trial predictor values."
    ))
  }
  max_trials <- max(trials)
  if (max_trials > 2000L) {
    cli::cli_abort(c(
      "The first beta-binomial {.fn mi} slice would need a very wide success-count support.",
      "x" = "The largest trial count is {max_trials}.",
      "i" = "Use a coarser denominator-aware predictor, simplify the model, or wait for a count Laplace slice."
    ))
  }
  start <- beta_binomial_start(
    successes = success[observed],
    failures = trials[observed] - success[observed],
    X_mu = X[observed, , drop = FALSE],
    X_sigma = matrix(1, nrow = sum(observed), ncol = 1L)
  )
  beta <- start$beta_mu
  beta[!is.finite(beta) | is.na(beta)] <- 0
  names(beta) <- colnames(X)
  log_sigma <- unname(start$beta_sigma[[1L]])
  if (!is.finite(log_sigma)) {
    log_sigma <- log(0.35)
  }
  eta <- as.vector(X %*% beta)
  mu <- stats::plogis(eta)
  x <- success / trials
  x[!observed] <- mu[!observed]
  list(
    enabled = TRUE,
    variable = setup$variable,
    label = setup$label,
    model_column = setup$model_column,
    mu_col = NA_integer_,
    family = "beta_binomial",
    x = x,
    successes = success,
    trials = trials,
    success_variable = setup$response_variable,
    trials_variable = setup$trials_variable,
    observed = observed,
    missing_index = which(!observed),
    X = X,
    formula = impute_formula,
    raw_formula = setup$raw_formula,
    beta_start = beta,
    log_sigma_start = log_sigma,
    x_miss_start = 0,
    theta_start = 0,
    coef_names = colnames(X),
    predictor_names = c(rhs_vars, setup$trials_variable),
    levels = character(0),
    n_state = 0L,
    X_mu_state = matrix(0, nrow = 1L, ncol = 1L),
    quad_nodes = as.numeric(seq.int(0L, max_trials)),
    quad_weights = rep(1, max_trials + 1L),
    response_value = x,
    summary = "conditional_proportion_mean",
    random = list(
      enabled = FALSE,
      group = character(0),
      levels = character(0),
      n_group = 0L,
      group_index = integer(0)
    ),
    structured = list(
      enabled = FALSE,
      type = character(0),
      label = character(0),
      group = character(0),
      levels = character(0),
      n_re = 0L,
      index = integer(0),
      value = numeric(0),
      precision = NULL,
      log_det_precision = 0
    ),
    u_group_start = 0,
    log_sd_group_start = 0,
    u_structured_start = 0,
    log_sd_structured_start = 0
  )
}

drm_beta_binomial_missing_predictor_response <- function(
  success,
  trials,
  value,
  variable,
  success_variable,
  trials_variable
) {
  if (!is.numeric(success) && !is.integer(success)) {
    cli::cli_abort(c(
      "Beta-binomial missing-predictor models require a numeric or integer success count.",
      "x" = "Success column {.val {success_variable}} has class {.val {class(success)}}."
    ))
  }
  if (!is.numeric(trials) && !is.integer(trials)) {
    cli::cli_abort(c(
      "Beta-binomial missing-predictor models require a numeric or integer trial count.",
      "x" = "Trial column {.val {trials_variable}} has class {.val {class(trials)}}."
    ))
  }
  success <- as.numeric(success)
  trials <- as.numeric(trials)
  observed <- !is.na(success)
  tolerance <- sqrt(.Machine$double.eps)
  if (
    any(!is.finite(trials)) ||
      any(trials <= 0) ||
      any(abs(trials - round(trials)) > tolerance)
  ) {
    cli::cli_abort(c(
      "Beta-binomial missing-predictor models require complete positive integer trial counts.",
      "x" = "Trial column {.val {trials_variable}} contains missing, non-positive, non-integer, or non-finite values."
    ))
  }
  trials <- round(trials)
  if (
    any(!is.finite(success[observed])) ||
      any(success[observed] < 0) ||
      any(abs(success[observed] - round(success[observed])) > tolerance) ||
      any(success[observed] > trials[observed])
  ) {
    cli::cli_abort(c(
      "Beta-binomial missing-predictor models require observed success counts between 0 and the trial count.",
      "x" = "Success column {.val {success_variable}} contains invalid observed counts."
    ))
  }
  success[observed] <- round(success[observed])
  if (!is.numeric(value) && !is.integer(value) && !is.logical(value)) {
    cli::cli_abort(c(
      "The {.fn mi} variable for a beta-binomial missing predictor must be a numeric proportion or missing.",
      "x" = "Predictor {.val {variable}} has class {.val {class(value)}}."
    ))
  }
  value <- as.numeric(value)
  value_observed <- !is.na(value)
  if (
    any(!is.finite(value[value_observed])) ||
      any(value[value_observed] < 0 | value[value_observed] > 1)
  ) {
    cli::cli_abort(c(
      "The {.fn mi} variable for a beta-binomial missing predictor must be in [0, 1] when observed.",
      "x" = "Predictor {.val {variable}} contains out-of-range or non-finite observed values."
    ))
  }
  if (any(value_observed & !observed)) {
    cli::cli_abort(c(
      "Observed {.fn mi} proportions cannot be used without matching beta-binomial success counts.",
      "x" = "Predictor {.val {variable}} is observed in row{?s} where success column {.val {success_variable}} is missing.",
      "i" = "Use {.fn beta} or {.fn zero_one_beta} for proportion-only predictors, or provide success counts and trial counts."
    ))
  }
  if (any(value_observed & observed)) {
    expected <- success / trials
    mismatch <- value_observed &
      observed &
      abs(value - expected) > max(1e-8, tolerance)
    if (any(mismatch)) {
      cli::cli_abort(c(
        "Observed {.fn mi} proportions must match success divided by trials for beta-binomial missing predictors.",
        "x" = "Predictor {.val {variable}} does not match {.val {success_variable}} / {.val {trials_variable}} in {sum(mismatch)} row{?s}."
      ))
    }
  }
  list(success = success, trials = trials, observed = observed)
}

drm_beta_binomial_missing_predictor_log_density <- function(
  success,
  trials,
  mu,
  sigma
) {
  phi <- 1 / max(sigma, 1e-8)^2
  alpha <- pmax(mu * phi, 1e-8)
  beta_shape <- pmax((1 - mu) * phi, 1e-8)
  failure <- trials - success
  lgamma(trials + 1) -
    lgamma(success + 1) -
    lgamma(failure + 1) +
    lgamma(phi) -
    lgamma(trials + phi) +
    lgamma(success + alpha) -
    lgamma(alpha) +
    lgamma(failure + beta_shape) -
    lgamma(beta_shape)
}

drm_build_poisson_missing_predictor_model <- function(
  setup,
  data_model,
  env = parent.frame()
) {
  impute_formula <- setup$formula
  environment(impute_formula) <- env
  mf <- stats::model.frame(
    impute_formula,
    data = data_model,
    na.action = stats::na.pass
  )
  x_raw <- drm_poisson_missing_predictor_response(
    stats::model.response(mf),
    setup$variable
  )
  observed <- !is.na(x_raw)
  if (!any(!observed)) {
    cli::cli_abort(c(
      "{.code miss_control(predictor = \"model\")} requires at least one missing {.fn mi} predictor value.",
      "i" = "Use ordinary predictor syntax when {.code {setup$variable}} is complete."
    ))
  }
  if (!any(observed)) {
    cli::cli_abort(
      "At least one observed Poisson/count {.fn mi} predictor value is required for the predictor model."
    )
  }
  terms_x <- stats::delete.response(stats::terms(mf))
  rhs_vars <- all.vars(terms_x)
  if (length(rhs_vars) > 0L) {
    rhs_complete <- stats::complete.cases(mf[, rhs_vars, drop = FALSE])
    if (any(!rhs_complete)) {
      cli::cli_abort(c(
        "Missing predictors inside the {.arg impute} formula are not implemented.",
        "x" = "{sum(!rhs_complete)} retained row{?s} {?has/have} missing imputation-model predictor value{?s}."
      ))
    }
  }
  X <- stats::model.matrix(terms_x, mf)
  if (sum(observed) <= ncol(X)) {
    cli::cli_abort(c(
      "The Poisson {.arg impute} model is weakly identified for the first count {.fn mi} slice.",
      "x" = "It has {sum(observed)} observed {.code {setup$variable}} value{?s} and {ncol(X)} predictor-model coefficient{?s}.",
      "i" = "Use a simpler predictor model or supply more observed count predictor values."
    ))
  }
  fit <- tryCatch(
    stats::glm.fit(
      x = X[observed, , drop = FALSE],
      y = x_raw[observed],
      family = stats::poisson()
    ),
    error = function(e) NULL
  )
  beta <- if (is.null(fit)) {
    rep(0, ncol(X))
  } else {
    fit$coefficients
  }
  beta[!is.finite(beta) | is.na(beta)] <- 0
  names(beta) <- colnames(X)
  if ("(Intercept)" %in% names(beta) && all(beta == 0)) {
    beta[["(Intercept)"]] <- log(max(mean(x_raw[observed]), 1e-6))
  }
  eta <- as.vector(X %*% beta)
  lambda <- exp(pmin(eta, log(.Machine$double.xmax) / 4))
  x <- x_raw
  x[!observed] <- lambda[!observed]
  support <- drm_poisson_mi_support(lambda, x_raw[observed])
  list(
    enabled = TRUE,
    variable = setup$variable,
    label = setup$label,
    model_column = setup$model_column,
    mu_col = NA_integer_,
    family = "poisson",
    x = x,
    observed = observed,
    missing_index = which(!observed),
    X = X,
    formula = impute_formula,
    raw_formula = setup$raw_formula,
    beta_start = beta,
    log_sigma_start = 0,
    x_miss_start = 0,
    theta_start = 0,
    coef_names = colnames(X),
    predictor_names = rhs_vars,
    levels = character(0),
    n_state = 0L,
    X_mu_state = matrix(0, nrow = 1L, ncol = 1L),
    quad_nodes = support,
    quad_weights = rep(1, length(support)),
    response_value = NULL,
    summary = "conditional_expected_count",
    random = list(
      enabled = FALSE,
      group = character(0),
      levels = character(0),
      n_group = 0L,
      group_index = integer(0)
    ),
    structured = list(
      enabled = FALSE,
      type = character(0),
      label = character(0),
      group = character(0),
      levels = character(0),
      n_re = 0L,
      index = integer(0),
      value = numeric(0),
      precision = NULL,
      log_det_precision = 0
    ),
    u_group_start = 0,
    log_sd_group_start = 0,
    u_structured_start = 0,
    log_sd_structured_start = 0
  )
}

drm_poisson_missing_predictor_response <- function(x, variable) {
  if (!is.numeric(x) && !is.integer(x)) {
    cli::cli_abort(c(
      "Poisson/count missing-predictor models require a numeric or integer predictor.",
      "x" = "Predictor {.val {variable}} has class {.val {class(x)}}."
    ))
  }
  x <- as.numeric(x)
  observed <- !is.na(x)
  tolerance <- sqrt(.Machine$double.eps)
  if (
    any(!is.finite(x[observed])) ||
      any(x[observed] < 0) ||
      any(abs(x[observed] - round(x[observed])) > tolerance)
  ) {
    cli::cli_abort(c(
      "Poisson/count missing-predictor models require observed non-negative integer counts.",
      "x" = "Predictor {.val {variable}} contains negative, non-integer, or non-finite observed values.",
      "i" = "Use {.code impute_model(x ~ z, family = lognormal())} for positive continuous abundance or biomass variables."
    ))
  }
  x[observed] <- round(x[observed])
  x
}

drm_poisson_mi_support <- function(lambda, observed_values, tail = 1e-10) {
  lambda <- lambda[is.finite(lambda) & lambda >= 0]
  lambda_max <- max(c(lambda, observed_values, 1), na.rm = TRUE)
  upper <- max(
    50L,
    as.integer(max(observed_values, na.rm = TRUE)) + 25L,
    as.integer(stats::qpois(1 - tail, lambda = lambda_max))
  )
  if (!is.finite(upper) || upper < 0L) {
    cli::cli_abort(
      "Internal Poisson {.fn mi} support calculation produced an invalid upper count."
    )
  }
  if (upper > 2000L) {
    cli::cli_abort(c(
      "The first Poisson/count {.fn mi} slice would need a very wide count support.",
      "x" = "The finite summation support would run from 0 to {upper}.",
      "i" = "Use a simpler count predictor model, rescale the predictor, try {.fn nbinom2} for overdispersed counts, or wait for a count Laplace slice."
    ))
  }
  as.numeric(seq.int(0L, upper))
}

drm_poisson_missing_predictor_log_density <- function(x, lambda) {
  stats::dpois(x, lambda = lambda, log = TRUE)
}

drm_build_nbinom2_missing_predictor_model <- function(
  setup,
  data_model,
  env = parent.frame()
) {
  impute_formula <- setup$formula
  environment(impute_formula) <- env
  mf <- stats::model.frame(
    impute_formula,
    data = data_model,
    na.action = stats::na.pass
  )
  x_raw <- drm_count_missing_predictor_response(
    stats::model.response(mf),
    setup$variable,
    label = "Negative-binomial/count"
  )
  observed <- !is.na(x_raw)
  if (!any(!observed)) {
    cli::cli_abort(c(
      "{.code miss_control(predictor = \"model\")} requires at least one missing {.fn mi} predictor value.",
      "i" = "Use ordinary predictor syntax when {.code {setup$variable}} is complete."
    ))
  }
  if (!any(observed)) {
    cli::cli_abort(
      "At least one observed negative-binomial/count {.fn mi} predictor value is required for the predictor model."
    )
  }
  terms_x <- stats::delete.response(stats::terms(mf))
  rhs_vars <- all.vars(terms_x)
  if (length(rhs_vars) > 0L) {
    rhs_complete <- stats::complete.cases(mf[, rhs_vars, drop = FALSE])
    if (any(!rhs_complete)) {
      cli::cli_abort(c(
        "Missing predictors inside the {.arg impute} formula are not implemented.",
        "x" = "{sum(!rhs_complete)} retained row{?s} {?has/have} missing imputation-model predictor value{?s}."
      ))
    }
  }
  X <- stats::model.matrix(terms_x, mf)
  if (sum(observed) <= ncol(X) + 1L) {
    cli::cli_abort(c(
      "The negative-binomial {.arg impute} model is weakly identified for the first count {.fn mi} slice.",
      "x" = "It has {sum(observed)} observed {.code {setup$variable}} value{?s} and {ncol(X) + 1L} predictor-model coefficient/scale parameter{?s}.",
      "i" = "Use a simpler predictor model or supply more observed count predictor values."
    ))
  }
  fit <- tryCatch(
    stats::glm.fit(
      x = X[observed, , drop = FALSE],
      y = x_raw[observed],
      family = stats::poisson()
    ),
    error = function(e) NULL
  )
  beta <- if (is.null(fit)) {
    rep(0, ncol(X))
  } else {
    fit$coefficients
  }
  beta[!is.finite(beta) | is.na(beta)] <- 0
  names(beta) <- colnames(X)
  if ("(Intercept)" %in% names(beta) && all(beta == 0)) {
    beta[["(Intercept)"]] <- log(max(mean(x_raw[observed]), 1e-6))
  }
  eta <- as.vector(X %*% beta)
  mu <- exp(pmin(eta, log(.Machine$double.xmax) / 4))
  mu_observed <- mu[observed]
  moment_sigma2 <- (stats::var(x_raw[observed]) - mean(mu_observed)) /
    mean(mu_observed^2)
  sigma <- if (is.finite(moment_sigma2) && moment_sigma2 > 0) {
    sqrt(moment_sigma2)
  } else {
    0.3
  }
  sigma <- min(max(sigma, 0.05), 3)
  x <- x_raw
  x[!observed] <- mu[!observed]
  support <- drm_nbinom2_mi_support(mu, sigma, x_raw[observed])
  list(
    enabled = TRUE,
    variable = setup$variable,
    label = setup$label,
    model_column = setup$model_column,
    mu_col = NA_integer_,
    family = "nbinom2",
    x = x,
    observed = observed,
    missing_index = which(!observed),
    X = X,
    formula = impute_formula,
    raw_formula = setup$raw_formula,
    beta_start = beta,
    log_sigma_start = log(sigma),
    x_miss_start = 0,
    theta_start = 0,
    coef_names = colnames(X),
    predictor_names = rhs_vars,
    levels = character(0),
    n_state = 0L,
    X_mu_state = matrix(0, nrow = 1L, ncol = 1L),
    quad_nodes = support,
    quad_weights = rep(1, length(support)),
    response_value = NULL,
    summary = "conditional_expected_count",
    random = list(
      enabled = FALSE,
      group = character(0),
      levels = character(0),
      n_group = 0L,
      group_index = integer(0)
    ),
    structured = list(
      enabled = FALSE,
      type = character(0),
      label = character(0),
      group = character(0),
      levels = character(0),
      n_re = 0L,
      index = integer(0),
      value = numeric(0),
      precision = NULL,
      log_det_precision = 0
    ),
    u_group_start = 0,
    log_sd_group_start = 0,
    u_structured_start = 0,
    log_sd_structured_start = 0
  )
}

drm_build_truncated_nbinom2_missing_predictor_model <- function(
  setup,
  data_model,
  env = parent.frame()
) {
  impute_formula <- setup$formula
  environment(impute_formula) <- env
  mf <- stats::model.frame(
    impute_formula,
    data = data_model,
    na.action = stats::na.pass
  )
  x_raw <- drm_positive_count_missing_predictor_response(
    stats::model.response(mf),
    setup$variable,
    label = "Zero-truncated negative-binomial/count"
  )
  observed <- !is.na(x_raw)
  if (!any(!observed)) {
    cli::cli_abort(c(
      "{.code miss_control(predictor = \"model\")} requires at least one missing {.fn mi} predictor value.",
      "i" = "Use ordinary predictor syntax when {.code {setup$variable}} is complete."
    ))
  }
  if (!any(observed)) {
    cli::cli_abort(
      "At least one observed zero-truncated negative-binomial/count {.fn mi} predictor value is required for the predictor model."
    )
  }
  terms_x <- stats::delete.response(stats::terms(mf))
  rhs_vars <- all.vars(terms_x)
  if (length(rhs_vars) > 0L) {
    rhs_complete <- stats::complete.cases(mf[, rhs_vars, drop = FALSE])
    if (any(!rhs_complete)) {
      cli::cli_abort(c(
        "Missing predictors inside the {.arg impute} formula are not implemented.",
        "x" = "{sum(!rhs_complete)} retained row{?s} {?has/have} missing imputation-model predictor value{?s}."
      ))
    }
  }
  X <- stats::model.matrix(terms_x, mf)
  if (sum(observed) <= ncol(X) + 1L) {
    cli::cli_abort(c(
      "The zero-truncated negative-binomial {.arg impute} model is weakly identified for the first positive-count {.fn mi} slice.",
      "x" = "It has {sum(observed)} observed {.code {setup$variable}} value{?s} and {ncol(X) + 1L} predictor-model coefficient/scale parameter{?s}.",
      "i" = "Use a simpler predictor model or supply more observed positive-count predictor values."
    ))
  }
  fit <- tryCatch(
    stats::glm.fit(
      x = X[observed, , drop = FALSE],
      y = x_raw[observed],
      family = stats::poisson()
    ),
    error = function(e) NULL
  )
  beta <- if (is.null(fit)) {
    rep(0, ncol(X))
  } else {
    fit$coefficients
  }
  beta[!is.finite(beta) | is.na(beta)] <- 0
  names(beta) <- colnames(X)
  if ("(Intercept)" %in% names(beta) && all(beta == 0)) {
    beta[["(Intercept)"]] <- log(max(mean(x_raw[observed]), 1e-6))
  }
  eta <- as.vector(X %*% beta)
  mu <- exp(pmin(eta, log(.Machine$double.xmax) / 4))
  mu_observed <- mu[observed]
  moment_sigma2 <- (stats::var(x_raw[observed]) - mean(mu_observed)) /
    mean(mu_observed^2)
  sigma <- if (is.finite(moment_sigma2) && moment_sigma2 > 0) {
    sqrt(moment_sigma2)
  } else {
    0.3
  }
  sigma <- min(max(sigma, 0.05), 3)
  trunc_prob <- 1 -
    stats::dnbinom(
      0,
      size = 1 / sigma^2,
      mu = pmax(mu, 1e-10)
    )
  x <- x_raw
  x[!observed] <- mu[!observed] / pmax(trunc_prob[!observed], 1e-10)
  support <- drm_truncated_nbinom2_mi_support(mu, sigma, x_raw[observed])
  list(
    enabled = TRUE,
    variable = setup$variable,
    label = setup$label,
    model_column = setup$model_column,
    mu_col = NA_integer_,
    family = "truncated_nbinom2",
    x = x,
    observed = observed,
    missing_index = which(!observed),
    X = X,
    formula = impute_formula,
    raw_formula = setup$raw_formula,
    beta_start = beta,
    log_sigma_start = log(sigma),
    x_miss_start = 0,
    theta_start = 0,
    coef_names = colnames(X),
    predictor_names = rhs_vars,
    levels = character(0),
    n_state = 0L,
    X_mu_state = matrix(0, nrow = 1L, ncol = 1L),
    quad_nodes = support,
    quad_weights = rep(1, length(support)),
    response_value = NULL,
    summary = "conditional_expected_count",
    random = list(
      enabled = FALSE,
      group = character(0),
      levels = character(0),
      n_group = 0L,
      group_index = integer(0)
    ),
    structured = list(
      enabled = FALSE,
      type = character(0),
      label = character(0),
      group = character(0),
      levels = character(0),
      n_re = 0L,
      index = integer(0),
      value = numeric(0),
      precision = NULL,
      log_det_precision = 0
    ),
    u_group_start = 0,
    log_sd_group_start = 0,
    u_structured_start = 0,
    log_sd_structured_start = 0
  )
}

drm_count_missing_predictor_response <- function(
  x,
  variable,
  label = "Count"
) {
  if (!is.numeric(x) && !is.integer(x)) {
    cli::cli_abort(c(
      "{label} missing-predictor models require a numeric or integer predictor.",
      "x" = "Predictor {.val {variable}} has class {.val {class(x)}}."
    ))
  }
  x <- as.numeric(x)
  observed <- !is.na(x)
  tolerance <- sqrt(.Machine$double.eps)
  if (
    any(!is.finite(x[observed])) ||
      any(x[observed] < 0) ||
      any(abs(x[observed] - round(x[observed])) > tolerance)
  ) {
    cli::cli_abort(c(
      "{label} missing-predictor models require observed non-negative integer counts.",
      "x" = "Predictor {.val {variable}} contains negative, non-integer, or non-finite observed values.",
      "i" = "Use {.code impute_model(x ~ z, family = lognormal())} for positive continuous abundance or biomass variables."
    ))
  }
  x[observed] <- round(x[observed])
  x
}

drm_positive_count_missing_predictor_response <- function(
  x,
  variable,
  label = "Positive count"
) {
  x <- drm_count_missing_predictor_response(
    x = x,
    variable = variable,
    label = label
  )
  observed <- !is.na(x)
  if (any(x[observed] <= 0)) {
    cli::cli_abort(c(
      "{label} missing-predictor models require observed positive integer counts.",
      "x" = "Predictor {.val {variable}} contains zero observed values.",
      "i" = "Use {.fn nbinom2} for non-negative counts that can include zeros, or {.fn tweedie} for semi-continuous predictors with exact zeros."
    ))
  }
  x
}

drm_nbinom2_mi_support <- function(mu, sigma, observed_values, tail = 1e-10) {
  mu <- mu[is.finite(mu) & mu >= 0]
  sigma <- max(as.numeric(sigma[[1L]]), 1e-8)
  size <- 1 / sigma^2
  q <- stats::qnbinom(1 - tail, size = size, mu = pmax(mu, 1e-10))
  upper <- max(
    50L,
    as.integer(max(observed_values, na.rm = TRUE)) + 25L,
    as.integer(max(q, na.rm = TRUE))
  )
  if (!is.finite(upper) || upper < 0L) {
    cli::cli_abort(
      "Internal negative-binomial {.fn mi} support calculation produced an invalid upper count."
    )
  }
  if (upper > 4000L) {
    cli::cli_abort(c(
      "The first negative-binomial/count {.fn mi} slice would need a very wide count support.",
      "x" = "The finite summation support would run from 0 to {upper}.",
      "i" = "Use a simpler count predictor model, rescale the predictor, or wait for a count Laplace slice."
    ))
  }
  as.numeric(seq.int(0L, upper))
}

drm_truncated_nbinom2_mi_support <- function(
  mu,
  sigma,
  observed_values,
  tail = 1e-10
) {
  support <- drm_nbinom2_mi_support(mu, sigma, observed_values, tail = tail)
  support[support > 0]
}

drm_nbinom2_missing_predictor_log_density <- function(x, mu, sigma) {
  stats::dnbinom(
    x,
    size = 1 / max(sigma, 1e-8)^2,
    mu = pmax(mu, 1e-10),
    log = TRUE
  )
}

drm_truncated_nbinom2_missing_predictor_log_density <- function(x, mu, sigma) {
  log_p0 <- stats::dnbinom(
    0,
    size = 1 / max(sigma, 1e-8)^2,
    mu = pmax(mu, 1e-10),
    log = TRUE
  )
  stats::dnbinom(
    x,
    size = 1 / max(sigma, 1e-8)^2,
    mu = pmax(mu, 1e-10),
    log = TRUE
  ) -
    log1p(-exp(log_p0))
}

drm_build_lognormal_missing_predictor_model <- function(
  setup,
  data_model,
  env = parent.frame()
) {
  impute_formula <- setup$formula
  environment(impute_formula) <- env
  mf <- stats::model.frame(
    impute_formula,
    data = data_model,
    na.action = stats::na.pass
  )
  x_raw <- drm_lognormal_missing_predictor_response(
    stats::model.response(mf),
    setup$variable
  )
  observed <- !is.na(x_raw)
  if (!any(!observed)) {
    cli::cli_abort(c(
      "{.code miss_control(predictor = \"model\")} requires at least one missing {.fn mi} predictor value.",
      "i" = "Use ordinary predictor syntax when {.code {setup$variable}} is complete."
    ))
  }
  if (!any(observed)) {
    cli::cli_abort(
      "At least one observed lognormal/positive {.fn mi} predictor value is required for the predictor model."
    )
  }
  terms_x <- stats::delete.response(stats::terms(mf))
  rhs_vars <- all.vars(terms_x)
  if (length(rhs_vars) > 0L) {
    rhs_complete <- stats::complete.cases(mf[, rhs_vars, drop = FALSE])
    if (any(!rhs_complete)) {
      cli::cli_abort(c(
        "Missing predictors inside the {.arg impute} formula are not implemented.",
        "x" = "{sum(!rhs_complete)} retained row{?s} {?has/have} missing imputation-model predictor value{?s}."
      ))
    }
  }
  X <- stats::model.matrix(terms_x, mf)
  if (sum(observed) <= ncol(X) + 1L) {
    cli::cli_abort(c(
      "The lognormal {.arg impute} model is weakly identified for the first positive continuous {.fn mi} slice.",
      "x" = "It has {sum(observed)} observed {.code {setup$variable}} value{?s} and {ncol(X) + 1L} predictor-model coefficient/scale parameter{?s}.",
      "i" = "Use a simpler predictor model or supply more observed positive predictor values."
    ))
  }
  log_x <- log(x_raw[observed])
  fit <- stats::lm.fit(x = X[observed, , drop = FALSE], y = log_x)
  beta <- fit$coefficients
  beta[!is.finite(beta) | is.na(beta)] <- 0
  names(beta) <- colnames(X)
  eta <- as.vector(X %*% beta)
  resid <- log_x - eta[observed]
  sigma <- stats::sd(resid)
  log_scale <- stats::sd(log_x)
  if (!is.finite(log_scale) || log_scale <= 0) {
    log_scale <- 1
  }
  sigma_floor <- max(1e-4, 0.05 * log_scale)
  if (!is.finite(sigma) || sigma <= 0) {
    sigma <- sigma_floor
  }
  sigma <- max(sigma, sigma_floor)
  x <- x_raw
  x[!observed] <- exp(eta[!observed] + 0.5 * sigma^2)
  quad <- drm_lognormal_mi_quadrature()
  list(
    enabled = TRUE,
    variable = setup$variable,
    label = setup$label,
    model_column = setup$model_column,
    mu_col = NA_integer_,
    family = "lognormal",
    x = x,
    observed = observed,
    missing_index = which(!observed),
    X = X,
    formula = impute_formula,
    raw_formula = setup$raw_formula,
    beta_start = beta,
    log_sigma_start = log(sigma),
    x_miss_start = 0,
    theta_start = 0,
    coef_names = colnames(X),
    predictor_names = rhs_vars,
    levels = character(0),
    n_state = 0L,
    X_mu_state = matrix(0, nrow = 1L, ncol = 1L),
    quad_nodes = quad$nodes,
    quad_weights = quad$weights,
    response_value = NULL,
    summary = "conditional_quadrature_mean",
    random = list(
      enabled = FALSE,
      group = character(0),
      levels = character(0),
      n_group = 0L,
      group_index = integer(0)
    ),
    structured = list(
      enabled = FALSE,
      type = character(0),
      label = character(0),
      group = character(0),
      levels = character(0),
      n_re = 0L,
      index = integer(0),
      value = numeric(0),
      precision = NULL,
      log_det_precision = 0
    ),
    u_group_start = 0,
    log_sd_group_start = 0,
    u_structured_start = 0,
    log_sd_structured_start = 0
  )
}

drm_lognormal_missing_predictor_response <- function(x, variable) {
  if (!is.numeric(x) && !is.integer(x)) {
    cli::cli_abort(c(
      "Lognormal missing-predictor models require a numeric positive predictor.",
      "x" = "Predictor {.val {variable}} has class {.val {class(x)}}."
    ))
  }
  x <- as.numeric(x)
  observed <- !is.na(x)
  if (any(!is.finite(x[observed])) || any(x[observed] <= 0)) {
    cli::cli_abort(c(
      "Lognormal missing-predictor models require observed values greater than 0.",
      "x" = "Predictor {.val {variable}} contains zero, negative, or non-finite observed values.",
      "i" = "Use {.code impute_model(x ~ z, family = tweedie())} for semi-continuous predictors with exact zeros."
    ))
  }
  x
}

drm_lognormal_mi_quadrature <- function(n = 15L) {
  i <- seq_len(n - 1L)
  off_diagonal <- sqrt(i / 2)
  jacobi <- matrix(0, nrow = n, ncol = n)
  jacobi[cbind(i, i + 1L)] <- off_diagonal
  jacobi[cbind(i + 1L, i)] <- off_diagonal
  eig <- eigen(jacobi, symmetric = TRUE)
  order <- order(eig$values)
  hermite_nodes <- eig$values[order]
  hermite_weights <- sqrt(pi) * eig$vectors[1L, order]^2
  list(
    nodes = sqrt(2) * hermite_nodes,
    weights = hermite_weights / sqrt(pi)
  )
}

drm_lognormal_missing_predictor_log_density <- function(x, eta, sigma) {
  stats::dnorm(log(x), mean = eta, sd = sigma, log = TRUE) - log(x)
}

drm_build_gamma_missing_predictor_model <- function(
  setup,
  data_model,
  env = parent.frame()
) {
  impute_formula <- setup$formula
  environment(impute_formula) <- env
  mf <- stats::model.frame(
    impute_formula,
    data = data_model,
    na.action = stats::na.pass
  )
  x_raw <- drm_gamma_missing_predictor_response(
    stats::model.response(mf),
    setup$variable
  )
  observed <- !is.na(x_raw)
  if (!any(!observed)) {
    cli::cli_abort(c(
      "{.code miss_control(predictor = \"model\")} requires at least one missing {.fn mi} predictor value.",
      "i" = "Use ordinary predictor syntax when {.code {setup$variable}} is complete."
    ))
  }
  if (!any(observed)) {
    cli::cli_abort(
      "At least one observed Gamma/positive {.fn mi} predictor value is required for the predictor model."
    )
  }
  terms_x <- stats::delete.response(stats::terms(mf))
  rhs_vars <- all.vars(terms_x)
  if (length(rhs_vars) > 0L) {
    rhs_complete <- stats::complete.cases(mf[, rhs_vars, drop = FALSE])
    if (any(!rhs_complete)) {
      cli::cli_abort(c(
        "Missing predictors inside the {.arg impute} formula are not implemented.",
        "x" = "{sum(!rhs_complete)} retained row{?s} {?has/have} missing imputation-model predictor value{?s}."
      ))
    }
  }
  X <- stats::model.matrix(terms_x, mf)
  if (sum(observed) <= ncol(X) + 1L) {
    cli::cli_abort(c(
      "The Gamma {.arg impute} model is weakly identified for the first positive continuous {.fn mi} slice.",
      "x" = "It has {sum(observed)} observed {.code {setup$variable}} value{?s} and {ncol(X) + 1L} predictor-model coefficient/scale parameter{?s}.",
      "i" = "Use a simpler predictor model or supply more observed positive predictor values."
    ))
  }
  fit <- tryCatch(
    stats::glm.fit(
      x = X[observed, , drop = FALSE],
      y = x_raw[observed],
      family = stats::Gamma(link = "log")
    ),
    error = function(e) NULL
  )
  beta <- if (is.null(fit)) {
    stats::lm.fit(
      x = X[observed, , drop = FALSE],
      y = log(x_raw[observed])
    )$coefficients
  } else {
    fit$coefficients
  }
  beta[!is.finite(beta) | is.na(beta)] <- 0
  names(beta) <- colnames(X)
  eta <- as.vector(X %*% beta)
  mu <- exp(pmin(eta, log(.Machine$double.xmax) / 4))
  cv <- sqrt(mean(((x_raw[observed] - mu[observed]) / mu[observed])^2))
  if (!is.finite(cv) || cv <= 0) {
    cv <- 0.5
  }
  cv <- max(cv, 1e-4)
  x <- x_raw
  x[!observed] <- mu[!observed]
  quad <- drm_gamma_mi_quadrature()
  list(
    enabled = TRUE,
    variable = setup$variable,
    label = setup$label,
    model_column = setup$model_column,
    mu_col = NA_integer_,
    family = "gamma",
    x = x,
    observed = observed,
    missing_index = which(!observed),
    X = X,
    formula = impute_formula,
    raw_formula = setup$raw_formula,
    beta_start = beta,
    log_sigma_start = log(cv),
    x_miss_start = 0,
    theta_start = 0,
    coef_names = colnames(X),
    predictor_names = rhs_vars,
    levels = character(0),
    n_state = 0L,
    X_mu_state = matrix(0, nrow = 1L, ncol = 1L),
    quad_nodes = quad$nodes,
    quad_weights = quad$weights,
    response_value = NULL,
    summary = "conditional_quadrature_mean",
    random = list(
      enabled = FALSE,
      group = character(0),
      levels = character(0),
      n_group = 0L,
      group_index = integer(0)
    ),
    structured = list(
      enabled = FALSE,
      type = character(0),
      label = character(0),
      group = character(0),
      levels = character(0),
      n_re = 0L,
      index = integer(0),
      value = numeric(0),
      precision = NULL,
      log_det_precision = 0
    ),
    u_group_start = 0,
    log_sd_group_start = 0,
    u_structured_start = 0,
    log_sd_structured_start = 0
  )
}

drm_gamma_missing_predictor_response <- function(x, variable) {
  if (!is.numeric(x) && !is.integer(x)) {
    cli::cli_abort(c(
      "Gamma missing-predictor models require a numeric positive predictor.",
      "x" = "Predictor {.val {variable}} has class {.val {class(x)}}."
    ))
  }
  x <- as.numeric(x)
  observed <- !is.na(x)
  if (any(!is.finite(x[observed])) || any(x[observed] <= 0)) {
    cli::cli_abort(c(
      "Gamma missing-predictor models require observed values greater than 0.",
      "x" = "Predictor {.val {variable}} contains zero, negative, or non-finite observed values.",
      "i" = "Use {.code impute_model(x ~ z, family = tweedie())} for semi-continuous predictors with exact zeros."
    ))
  }
  x
}

drm_gamma_mi_quadrature <- function(n = 20L) {
  i <- seq_len(n)
  jacobi <- matrix(0, nrow = n, ncol = n)
  diag(jacobi) <- 2 * i - 1
  if (n > 1L) {
    off <- seq_len(n - 1L)
    jacobi[cbind(off, off + 1L)] <- off
    jacobi[cbind(off + 1L, off)] <- off
  }
  eig <- eigen(jacobi, symmetric = TRUE)
  order <- order(eig$values)
  list(
    nodes = eig$values[order],
    weights = eig$vectors[1L, order]^2
  )
}

drm_gamma_missing_predictor_log_density <- function(x, mu, sigma) {
  stats::dgamma(
    x,
    shape = 1 / sigma^2,
    scale = mu * sigma^2,
    log = TRUE
  )
}

drm_build_tweedie_missing_predictor_model <- function(
  setup,
  data_model,
  env = parent.frame()
) {
  impute_formula <- setup$formula
  environment(impute_formula) <- env
  mf <- stats::model.frame(
    impute_formula,
    data = data_model,
    na.action = stats::na.pass
  )
  x_raw <- drm_tweedie_missing_predictor_response(
    stats::model.response(mf),
    setup$variable
  )
  observed <- !is.na(x_raw)
  if (!any(!observed)) {
    cli::cli_abort(c(
      "{.code miss_control(predictor = \"model\")} requires at least one missing {.fn mi} predictor value.",
      "i" = "Use ordinary predictor syntax when {.code {setup$variable}} is complete."
    ))
  }
  if (!any(observed)) {
    cli::cli_abort(
      "At least one observed Tweedie/semi-continuous {.fn mi} predictor value is required for the predictor model."
    )
  }
  if (!any(x_raw[observed] > 0)) {
    cli::cli_abort(c(
      "Tweedie/semi-continuous missing-predictor models require at least one observed positive value.",
      "i" = "Exact zeros are allowed, but the positive component cannot be identified from all-zero observed predictor values."
    ))
  }
  terms_x <- stats::delete.response(stats::terms(mf))
  rhs_vars <- all.vars(terms_x)
  if (length(rhs_vars) > 0L) {
    rhs_complete <- stats::complete.cases(mf[, rhs_vars, drop = FALSE])
    if (any(!rhs_complete)) {
      cli::cli_abort(c(
        "Missing predictors inside the {.arg impute} formula are not implemented.",
        "x" = "{sum(!rhs_complete)} retained row{?s} {?has/have} missing imputation-model predictor value{?s}."
      ))
    }
  }
  X <- stats::model.matrix(terms_x, mf)
  if (sum(observed) <= ncol(X) + 1L) {
    cli::cli_abort(c(
      "The Tweedie {.arg impute} model is weakly identified for the first semi-continuous {.fn mi} slice.",
      "x" = "It has {sum(observed)} observed {.code {setup$variable}} value{?s} and {ncol(X) + 1L} predictor-model coefficient/scale parameter{?s}.",
      "i" = "Use a simpler predictor model or supply more observed semi-continuous predictor values."
    ))
  }

  positive_x <- x_raw[observed & x_raw > 0]
  zero_floor <- max(min(positive_x) * 0.5, .Machine$double.eps)
  log_x <- log(pmax(x_raw[observed], zero_floor))
  fit <- tryCatch(
    stats::lm.fit(x = X[observed, , drop = FALSE], y = log_x),
    error = function(e) NULL
  )
  beta <- if (is.null(fit)) {
    rep(0, ncol(X))
  } else {
    fit$coefficients
  }
  beta[!is.finite(beta) | is.na(beta)] <- 0
  names(beta) <- colnames(X)
  eta <- as.vector(X %*% beta)
  mu <- exp(pmin(eta, log(.Machine$double.xmax) / 4))
  power <- 1.5
  phi <- stats::var(x_raw[observed]) /
    mean(pmax(mu[observed], .Machine$double.eps)^power)
  if (!is.finite(phi) || phi <= 0) {
    phi <- 0.5
  }
  sigma <- sqrt(min(max(phi, 1e-4), 9))
  x <- x_raw
  x[!observed] <- mu[!observed]
  quad <- drm_tweedie_mi_quadrature(
    mu = mu,
    sigma = sigma,
    observed = x_raw[observed],
    power = power
  )
  list(
    enabled = TRUE,
    variable = setup$variable,
    label = setup$label,
    model_column = setup$model_column,
    mu_col = NA_integer_,
    family = "tweedie",
    x = x,
    observed = observed,
    missing_index = which(!observed),
    X = X,
    formula = impute_formula,
    raw_formula = setup$raw_formula,
    beta_start = beta,
    log_sigma_start = log(sigma),
    x_miss_start = 0,
    theta_start = 0,
    coef_names = colnames(X),
    predictor_names = rhs_vars,
    levels = character(0),
    n_state = 0L,
    X_mu_state = matrix(0, nrow = 1L, ncol = 1L),
    quad_nodes = quad$nodes,
    quad_weights = quad$weights,
    power = power,
    response_value = NULL,
    summary = "conditional_quadrature_mean",
    random = list(
      enabled = FALSE,
      group = character(0),
      levels = character(0),
      n_group = 0L,
      group_index = integer(0)
    ),
    structured = list(
      enabled = FALSE,
      type = character(0),
      label = character(0),
      group = character(0),
      levels = character(0),
      n_re = 0L,
      index = integer(0),
      value = numeric(0),
      precision = NULL,
      log_det_precision = 0
    ),
    u_group_start = 0,
    log_sd_group_start = 0,
    u_structured_start = 0,
    log_sd_structured_start = 0
  )
}

drm_tweedie_missing_predictor_response <- function(x, variable) {
  if (!is.numeric(x) && !is.integer(x)) {
    cli::cli_abort(c(
      "Tweedie missing-predictor models require a numeric non-negative predictor.",
      "x" = "Predictor {.val {variable}} has class {.val {class(x)}}."
    ))
  }
  x <- as.numeric(x)
  observed <- !is.na(x)
  if (any(!is.finite(x[observed])) || any(x[observed] < 0)) {
    cli::cli_abort(c(
      "Tweedie missing-predictor models require observed values greater than or equal to 0.",
      "x" = "Predictor {.val {variable}} contains negative or non-finite observed values.",
      "i" = "Use {.fn lognormal} or {.code Gamma(link = \"log\")} for strictly positive continuous predictors."
    ))
  }
  x
}

drm_tweedie_mi_quadrature <- function(
  mu,
  sigma,
  observed,
  power = 1.5,
  n = 35L
) {
  unit <- drm_legendre_unit_quadrature(n)
  variance <- sigma^2 * pmax(mu, .Machine$double.eps)^power
  upper <- max(
    observed,
    mu + 8 * sqrt(pmax(variance, .Machine$double.eps)),
    1,
    na.rm = TRUE
  )
  if (!is.finite(upper) || upper <= 0) {
    cli::cli_abort(
      "Internal Tweedie {.fn mi} quadrature calculation produced an invalid support."
    )
  }
  if (upper > 1e6) {
    cli::cli_abort(c(
      "The first Tweedie/semi-continuous {.fn mi} slice would need a very wide positive support.",
      "x" = "The deterministic quadrature upper limit would be {signif(upper, 4)}.",
      "i" = "Rescale the predictor, simplify the predictor model, or wait for an adaptive semi-continuous integration slice."
    ))
  }
  positive_nodes <- upper * unit$nodes
  positive_weights <- upper * unit$weights
  list(
    nodes = c(0, positive_nodes),
    weights = c(1, positive_weights)
  )
}

drm_legendre_unit_quadrature <- function(n) {
  n <- as.integer(n[[1L]])
  if (!is.finite(n) || n < 2L) {
    cli::cli_abort("Internal quadrature order must be at least 2.")
  }
  i <- seq_len(n - 1L)
  off <- i / sqrt(4 * i^2 - 1)
  jacobi <- matrix(0, nrow = n, ncol = n)
  jacobi[cbind(i, i + 1L)] <- off
  jacobi[cbind(i + 1L, i)] <- off
  eig <- eigen(jacobi, symmetric = TRUE)
  order <- order(eig$values)
  nodes <- eig$values[order]
  weights <- 2 * eig$vectors[1L, order]^2
  list(nodes = (nodes + 1) / 2, weights = weights / 2)
}

drm_tweedie_missing_predictor_log_density <- function(
  x,
  mu,
  sigma,
  power = 1.5,
  max_terms = 2000L
) {
  phi <- sigma^2
  mu <- rep_len(mu, length(x))
  vapply(
    seq_along(x),
    function(i) {
      drm_tweedie_missing_predictor_log_density_one(
        x = x[[i]],
        mu = mu[[i]],
        phi = phi,
        power = power,
        max_terms = max_terms
      )
    },
    numeric(1)
  )
}

drm_tweedie_missing_predictor_log_density_one <- function(
  x,
  mu,
  phi,
  power,
  max_terms
) {
  if (!is.finite(x) || x < 0 || !is.finite(mu) || mu <= 0) {
    return(-Inf)
  }
  lambda <- mu^(2 - power) / (phi * (2 - power))
  if (x == 0) {
    return(-lambda)
  }
  gamma_shape <- (2 - power) / (power - 1)
  gamma_scale <- phi * (power - 1) * mu^(power - 1)
  j <- seq_len(max_terms)
  log_terms <- stats::dpois(j, lambda = lambda, log = TRUE) +
    stats::dgamma(
      x,
      shape = j * gamma_shape,
      scale = gamma_scale,
      log = TRUE
    )
  max_log <- max(log_terms)
  max_log + log(sum(exp(log_terms - max_log)))
}

drm_missing_predictor_state_design <- function(model, mf_mu, terms_mu, X_mu) {
  if (!model$family %in% c("ordinal", "categorical")) {
    return(model)
  }
  if (!model$model_column %in% names(mf_mu)) {
    cli::cli_abort(
      "Internal finite-state {.fn mi} state-design error: model column was not found."
    )
  }
  n <- nrow(mf_mu)
  n_state <- length(model$levels)
  out <- matrix(
    NA_real_,
    nrow = n * n_state,
    ncol = ncol(X_mu),
    dimnames = list(NULL, colnames(X_mu))
  )
  for (state in seq_len(n_state)) {
    mf_state <- mf_mu
    mf_state[[model$model_column]] <- if (identical(model$family, "ordinal")) {
      ordered(
        rep(model$levels[[state]], n),
        levels = model$levels
      )
    } else {
      factor(
        rep(model$levels[[state]], n),
        levels = model$levels
      )
    }
    X_state <- stats::model.matrix(terms_mu, mf_state)
    if (!identical(colnames(X_state), colnames(X_mu))) {
      cli::cli_abort(
        "Internal finite-state {.fn mi} state-design error: state model matrix columns changed."
      )
    }
    out[seq.int(state, by = n_state, length.out = n), ] <- X_state
  }
  model$X_mu_state <- out
  model
}

drm_build_gaussian_mi_random_intercept <- function(setup, data_model) {
  random <- setup$random
  if (!is.list(random) || !isTRUE(random$enabled)) {
    return(list(
      enabled = FALSE,
      group = character(0),
      levels = character(0),
      n_group = 0L,
      group_index = integer(0)
    ))
  }
  group <- random$group
  if (!group %in% names(data_model)) {
    cli::cli_abort(
      "The MD3b {.arg impute} grouping variable {.val {group}} was not found in {.arg data}."
    )
  }
  values <- data_model[[group]]
  if (anyNA(values)) {
    cli::cli_abort(
      "The MD3b {.arg impute} grouping variable {.val {group}} must be complete."
    )
  }
  group_factor <- factor(values)
  if (nlevels(group_factor) < 2L) {
    cli::cli_abort(
      "The MD3b {.arg impute} random-intercept model needs at least two group levels."
    )
  }
  list(
    enabled = TRUE,
    group = group,
    levels = levels(group_factor),
    n_group = nlevels(group_factor),
    group_index = as.integer(group_factor)
  )
}

drm_build_gaussian_mi_structured_intercept <- function(
  setup,
  data_model,
  env = parent.frame()
) {
  structured <- setup$structured
  if (!is.list(structured) || !isTRUE(structured$enabled)) {
    return(list(
      enabled = FALSE,
      type = character(0),
      label = character(0),
      group = character(0),
      levels = character(0),
      n_re = 0L,
      index = integer(0),
      value = numeric(0),
      precision = NULL,
      log_det_precision = 0
    ))
  }
  field <- build_structured_mu_structure(structured$term, data_model, env)
  if (!isTRUE(field$has) || field$q != 1L) {
    cli::cli_abort(c(
      "The MD4 {.arg impute} route supports one scalar structured covariate field.",
      "x" = "Requested structured model {.code {structured$term$label}} has q = {field$q}."
    ))
  }
  if (!identical(field$coef_names, "(Intercept)")) {
    cli::cli_abort(c(
      "The MD4 {.arg impute} route supports only intercept-only structured covariate models.",
      "x" = "Requested structured coefficient{?s}: {.val {field$coef_names}}."
    ))
  }
  list(
    enabled = TRUE,
    type = field$type,
    label = field$label,
    group = field$group,
    levels = field$group_levels,
    n_re = field$n_re,
    index = as.integer(field$observation_node_index),
    index0 = as.integer(field$observation_node_index0),
    value = as.numeric(field$value[, 1L]),
    precision = field$precision$precision,
    log_det_precision = field$precision$log_det_precision
  )
}

drm_missing_predictor_metadata <- function(model, original_row) {
  if (!isTRUE(model$enabled)) {
    return(list())
  }
  out <- list(
    variable = model$variable,
    family = model$family,
    formula = paste(deparse(model$raw_formula), collapse = " "),
    model_row = as.integer(model$missing_index),
    original_row = as.integer(original_row[model$missing_index]),
    observed = as.logical(model$observed),
    counts = list(
      observed = sum(model$observed),
      missing = sum(!model$observed)
    ),
    coef_names = model$coef_names,
    predictor_names = model$predictor_names,
    levels = model$levels,
    n_state = model$n_state,
    summary = model$summary,
    success_variable = if (!is.null(model$success_variable)) {
      model$success_variable
    } else {
      character(0)
    },
    trials_variable = if (!is.null(model$trials_variable)) {
      model$trials_variable
    } else {
      character(0)
    },
    trials = if (!is.null(model$trials)) {
      model$trials
    } else {
      numeric(0)
    },
    power = if (!is.null(model$power)) {
      model$power
    } else {
      NA_real_
    },
    random = list(
      enabled = isTRUE(model$random$enabled),
      group = model$random$group,
      levels = model$random$levels,
      n_group = model$random$n_group
    ),
    structured = list(
      enabled = isTRUE(model$structured$enabled),
      type = model$structured$type,
      label = model$structured$label,
      group = model$structured$group,
      levels = model$structured$levels,
      n_re = model$structured$n_re
    )
  )
  stats::setNames(list(out), model$variable)
}

drm_tmb_missing_predictor_data <- function(spec) {
  model <- if (is.list(spec$missing_predictor)) {
    spec$missing_predictor
  } else {
    drm_empty_missing_predictor_model()
  }
  dummy_sparse <- Matrix::sparseMatrix(
    i = integer(0),
    j = integer(0),
    x = numeric(0),
    dims = c(1L, 1L)
  )
  if (isTRUE(model$enabled)) {
    return(list(
      has_mi = 1L,
      mi_family = switch(
        model$family,
        gaussian = 0L,
        bernoulli = 1L,
        ordinal = 2L,
        categorical = 3L,
        beta = 4L,
        poisson = 5L,
        lognormal = 6L,
        gamma = 7L,
        nbinom2 = 8L,
        tweedie = 9L,
        zero_one_beta = 10L,
        truncated_nbinom2 = 11L,
        beta_binomial = 12L,
        0L
      ),
      # mu_col is NA_integer_ for missing-response fits (no predictor column to
      # impute). TMB's DATA_INTEGER(mi_col) converts the value via
      # CppAD::Integer(), which is undefined behaviour on NaN (clang-UBSAN:
      # "nan is outside the range of representable values of type 'int'"). Pass a
      # finite sentinel: mi_col is only read inside the predictor-imputation
      # branches, which a response-masking fit never enters, so 0L is inert.
      mi_col = as.integer(
        if (length(model$mu_col) == 1L && !is.na(model$mu_col)) {
          model$mu_col - 1L
        } else {
          0L
        }
      ),
      mi_x = as.numeric(model$x),
      mi_successes = if (!is.null(model$successes)) {
        as.numeric(model$successes)
      } else {
        rep(0, length(model$x))
      },
      mi_trials = if (!is.null(model$trials)) {
        as.numeric(model$trials)
      } else {
        rep(1, length(model$x))
      },
      mi_observed = as.integer(model$observed),
      mi_missing_index = as.integer(model$missing_index - 1L),
      has_mi_group = as.integer(isTRUE(model$random$enabled)),
      mi_group_index = if (isTRUE(model$random$enabled)) {
        as.integer(model$random$group_index - 1L)
      } else {
        0L
      },
      has_mi_struct = as.integer(isTRUE(model$structured$enabled)),
      mi_struct_index = if (isTRUE(model$structured$enabled)) {
        as.integer(model$structured$index0)
      } else {
        0L
      },
      mi_struct_value = if (isTRUE(model$structured$enabled)) {
        as.numeric(model$structured$value)
      } else {
        0
      },
      Q_mi_struct = if (isTRUE(model$structured$enabled)) {
        model$structured$precision
      } else {
        dummy_sparse
      },
      log_det_Q_mi_struct = if (isTRUE(model$structured$enabled)) {
        model$structured$log_det_precision
      } else {
        0
      },
      X_mi = model$X,
      mi_n_state = as.integer(model$n_state),
      X_mi_state_mu = model$X_mu_state,
      mi_quad_nodes = if (!is.null(model$quad_nodes)) {
        as.numeric(model$quad_nodes)
      } else {
        0
      },
      mi_quad_weights = if (!is.null(model$quad_weights)) {
        as.numeric(model$quad_weights)
      } else {
        1
      }
    ))
  }
  n <- if (!is.null(spec$y)) {
    length(spec$y)
  } else if (!is.null(spec$y1)) {
    length(spec$y1)
  } else {
    1L
  }
  list(
    has_mi = 0L,
    mi_family = 0L,
    mi_col = 0L,
    mi_x = rep(0, max(1L, n)),
    mi_successes = rep(0, max(1L, n)),
    mi_trials = rep(1, max(1L, n)),
    mi_observed = rep(1L, max(1L, n)),
    mi_missing_index = 0L,
    has_mi_group = 0L,
    mi_group_index = 0L,
    has_mi_struct = 0L,
    mi_struct_index = 0L,
    mi_struct_value = 0,
    Q_mi_struct = dummy_sparse,
    log_det_Q_mi_struct = 0,
    X_mi = matrix(0, nrow = 1L, ncol = 1L),
    mi_n_state = 0L,
    X_mi_state_mu = matrix(0, nrow = 1L, ncol = 1L),
    mi_quad_nodes = 0,
    mi_quad_weights = 1
  )
}

drm_finalize_missing_data <- function(missing_data, par_list, spec) {
  if (
    !is.list(missing_data) ||
      !is.list(spec$missing_predictor) ||
      !isTRUE(spec$missing_predictor$enabled)
  ) {
    return(missing_data)
  }
  model <- spec$missing_predictor
  variable <- model$variable
  if (
    !is.list(missing_data$predictors) ||
      !variable %in% names(missing_data$predictors)
  ) {
    return(missing_data)
  }
  value <- as.numeric(model$x)
  if (identical(model$family, "bernoulli")) {
    eta <- as.vector(model$X %*% as.numeric(par_list$beta_mi))
    probability <- stats::plogis(eta)
    missing_index <- model$missing_index
    if (length(missing_index) > 0L) {
      beta_mu <- as.numeric(par_list$beta_mu)
      beta_x <- beta_mu[[model$mu_col]]
      x_base <- spec$X$mu[, model$mu_col]
      log_p1 <- stats::plogis(eta, log.p = TRUE)
      log_p0 <- stats::plogis(eta, lower.tail = FALSE, log.p = TRUE)
      observed_y <- as.logical(missing_data$observed_y)
      rows_y <- missing_index[observed_y[missing_index]]
      if (length(rows_y) > 0L) {
        if (identical(spec$model_type, "poisson")) {
          offset_mu <- if (!is.null(spec$offset$mu)) {
            spec$offset$mu
          } else {
            rep(0, length(spec$y))
          }
          eta_base <- as.vector(offset_mu + spec$X$mu %*% beta_mu)
          eta1 <- eta_base + beta_x * (1 - x_base)
          eta0 <- eta_base + beta_x * (0 - x_base)
          log_p1[rows_y] <- log_p1[rows_y] +
            spec$weights[rows_y] *
              stats::dpois(
                spec$y[rows_y],
                lambda = exp(eta1[rows_y]),
                log = TRUE
              )
          log_p0[rows_y] <- log_p0[rows_y] +
            spec$weights[rows_y] *
              stats::dpois(
                spec$y[rows_y],
                lambda = exp(eta0[rows_y]),
                log = TRUE
              )
        } else if (identical(spec$model_type, "binomial")) {
          offset_mu <- if (!is.null(spec$offset$mu)) {
            spec$offset$mu
          } else {
            rep(0, length(spec$y))
          }
          eta_base <- as.vector(offset_mu + spec$X$mu %*% beta_mu)
          eta1 <- eta_base + beta_x * (1 - x_base)
          eta0 <- eta_base + beta_x * (0 - x_base)
          log_p1[rows_y] <- log_p1[rows_y] +
            spec$weights[rows_y] *
              stats::dbinom(
                spec$y[rows_y],
                size = spec$trials[rows_y],
                prob = stats::plogis(eta1[rows_y]),
                log = TRUE
              )
          log_p0[rows_y] <- log_p0[rows_y] +
            spec$weights[rows_y] *
              stats::dbinom(
                spec$y[rows_y],
                size = spec$trials[rows_y],
                prob = stats::plogis(eta0[rows_y]),
                log = TRUE
              )
        } else if (identical(spec$model_type, "nbinom2")) {
          beta_sigma <- as.numeric(par_list$beta_sigma)
          offset_mu <- if (!is.null(spec$offset$mu)) {
            spec$offset$mu
          } else {
            rep(0, length(spec$y))
          }
          eta_base <- as.vector(offset_mu + spec$X$mu %*% beta_mu)
          log_sigma <- as.vector(spec$X$sigma %*% beta_sigma)
          size <- exp(-2 * log_sigma)
          eta1 <- eta_base + beta_x * (1 - x_base)
          eta0 <- eta_base + beta_x * (0 - x_base)
          log_p1[rows_y] <- log_p1[rows_y] +
            spec$weights[rows_y] *
              stats::dnbinom(
                spec$y[rows_y],
                size = size[rows_y],
                mu = exp(eta1[rows_y]),
                log = TRUE
              )
          log_p0[rows_y] <- log_p0[rows_y] +
            spec$weights[rows_y] *
              stats::dnbinom(
                spec$y[rows_y],
                size = size[rows_y],
                mu = exp(eta0[rows_y]),
                log = TRUE
              )
        } else if (identical(spec$model_type, "beta")) {
          beta_sigma <- as.numeric(par_list$beta_sigma)
          eta_base <- as.vector(spec$X$mu %*% beta_mu)
          log_sigma <- as.vector(spec$X$sigma %*% beta_sigma)
          phi <- exp(-2 * log_sigma)
          beta_mu_eps <- 1e-12
          beta_shape_floor <- 1e-8
          eta1 <- eta_base + beta_x * (1 - x_base)
          eta0 <- eta_base + beta_x * (0 - x_base)
          mu1 <- beta_mu_eps + (1 - 2 * beta_mu_eps) * stats::plogis(eta1)
          mu0 <- beta_mu_eps + (1 - 2 * beta_mu_eps) * stats::plogis(eta0)
          alpha1 <- pmax(mu1 * phi, beta_shape_floor)
          beta_shape1 <- pmax((1 - mu1) * phi, beta_shape_floor)
          alpha0 <- pmax(mu0 * phi, beta_shape_floor)
          beta_shape0 <- pmax((1 - mu0) * phi, beta_shape_floor)
          log_p1[rows_y] <- log_p1[rows_y] +
            spec$weights[rows_y] *
              stats::dbeta(
                spec$y[rows_y],
                shape1 = alpha1[rows_y],
                shape2 = beta_shape1[rows_y],
                log = TRUE
              )
          log_p0[rows_y] <- log_p0[rows_y] +
            spec$weights[rows_y] *
              stats::dbeta(
                spec$y[rows_y],
                shape1 = alpha0[rows_y],
                shape2 = beta_shape0[rows_y],
                log = TRUE
              )
        } else {
          beta_sigma <- as.numeric(par_list$beta_sigma)
          mu_base <- as.vector(spec$X$mu %*% beta_mu)
          log_sigma <- as.vector(spec$X$sigma %*% beta_sigma)
          sigma <- sqrt(spec$V_known_diag + exp(2 * log_sigma))
          mu1 <- mu_base + beta_x * (1 - x_base)
          mu0 <- mu_base + beta_x * (0 - x_base)
          log_p1[rows_y] <- log_p1[rows_y] +
            spec$weights[rows_y] *
              stats::dnorm(
                spec$y[rows_y],
                mean = mu1[rows_y],
                sd = sigma[rows_y],
                log = TRUE
              )
          log_p0[rows_y] <- log_p0[rows_y] +
            spec$weights[rows_y] *
              stats::dnorm(
                spec$y[rows_y],
                mean = mu0[rows_y],
                sd = sigma[rows_y],
                log = TRUE
              )
        }
      }
      max_log <- pmax(log_p1[missing_index], log_p0[missing_index])
      denom <- max_log +
        log(
          exp(log_p1[missing_index] - max_log) +
            exp(log_p0[missing_index] - max_log)
        )
      probability[missing_index] <- exp(log_p1[missing_index] - denom)
    }
    value[model$missing_index] <- probability[model$missing_index]
    missing_data$predictors[[variable]]$value <- value
    missing_data$predictors[[variable]]$conditional_probability <-
      probability[model$missing_index]
    missing_data$predictors[[variable]]$summary <- "conditional_probability"
    return(missing_data)
  }
  if (identical(model$family, "ordinal")) {
    eta <- as.vector(model$X %*% as.numeric(par_list$beta_mi))
    cutpoints <- ordinal_cutpoints_from_raw(as.numeric(par_list$theta_ord))
    probability <- drm_ordinal_probability_matrix(eta, cutpoints)
    missing_index <- model$missing_index
    if (length(missing_index) > 0L) {
      beta_mu <- as.numeric(par_list$beta_mu)
      beta_sigma <- as.numeric(par_list$beta_sigma)
      log_sigma <- as.vector(spec$X$sigma %*% beta_sigma)
      sigma <- sqrt(spec$V_known_diag + exp(2 * log_sigma))
      n_state <- length(model$levels)
      state_mu <- matrix(
        as.vector(model$X_mu_state %*% beta_mu),
        nrow = length(model$x),
        ncol = n_state,
        byrow = TRUE
      )
      log_prob <- log(probability)
      observed_y <- as.logical(missing_data$observed_y)
      rows_y <- missing_index[observed_y[missing_index]]
      if (length(rows_y) > 0L) {
        for (state in seq_len(n_state)) {
          log_prob[rows_y, state] <- log_prob[rows_y, state] +
            spec$weights[rows_y] *
              stats::dnorm(
                spec$y[rows_y],
                mean = state_mu[rows_y, state],
                sd = sigma[rows_y],
                log = TRUE
              )
        }
      }
      row_max <- apply(log_prob[missing_index, , drop = FALSE], 1L, max)
      normalized <- exp(log_prob[missing_index, , drop = FALSE] - row_max)
      normalized <- normalized / rowSums(normalized)
      probability[missing_index, ] <- normalized
    }
    score <- as.vector(probability %*% seq_along(model$levels))
    value[model$missing_index] <- score[model$missing_index]
    missing_data$predictors[[variable]]$value <- value
    missing_data$predictors[[variable]]$cutpoints <- cutpoints
    missing_data$predictors[[variable]]$conditional_probabilities <-
      probability[model$missing_index, , drop = FALSE]
    colnames(missing_data$predictors[[variable]]$conditional_probabilities) <-
      model$levels
    missing_data$predictors[[variable]]$conditional_expected_score <-
      score[model$missing_index]
    missing_data$predictors[[variable]]$summary <-
      "conditional_expected_score"
    return(missing_data)
  }
  if (identical(model$family, "categorical")) {
    probability <- drm_categorical_probability_matrix(
      model$X,
      as.numeric(par_list$beta_mi),
      n_state = length(model$levels)
    )
    missing_index <- model$missing_index
    if (length(missing_index) > 0L) {
      beta_mu <- as.numeric(par_list$beta_mu)
      beta_sigma <- as.numeric(par_list$beta_sigma)
      log_sigma <- as.vector(spec$X$sigma %*% beta_sigma)
      sigma <- sqrt(spec$V_known_diag + exp(2 * log_sigma))
      n_state <- length(model$levels)
      state_mu <- matrix(
        as.vector(model$X_mu_state %*% beta_mu),
        nrow = length(model$x),
        ncol = n_state,
        byrow = TRUE
      )
      log_prob <- log(probability)
      observed_y <- as.logical(missing_data$observed_y)
      rows_y <- missing_index[observed_y[missing_index]]
      if (length(rows_y) > 0L) {
        for (state in seq_len(n_state)) {
          log_prob[rows_y, state] <- log_prob[rows_y, state] +
            spec$weights[rows_y] *
              stats::dnorm(
                spec$y[rows_y],
                mean = state_mu[rows_y, state],
                sd = sigma[rows_y],
                log = TRUE
              )
        }
      }
      row_max <- apply(log_prob[missing_index, , drop = FALSE], 1L, max)
      normalized <- exp(log_prob[missing_index, , drop = FALSE] - row_max)
      normalized <- normalized / rowSums(normalized)
      probability[missing_index, ] <- normalized
    }
    modal_state <- max.col(probability, ties.method = "first")
    value[model$missing_index] <- modal_state[model$missing_index]
    missing_data$predictors[[variable]]$value <- value
    missing_data$predictors[[variable]]$conditional_probabilities <-
      probability[model$missing_index, , drop = FALSE]
    colnames(missing_data$predictors[[variable]]$conditional_probabilities) <-
      model$levels
    missing_data$predictors[[variable]]$conditional_modal_category <-
      model$levels[modal_state[model$missing_index]]
    missing_data$predictors[[variable]]$summary <-
      "conditional_modal_category"
    return(missing_data)
  }
  if (identical(model$family, "beta")) {
    eta <- as.vector(model$X %*% as.numeric(par_list$beta_mi))
    mu_x <- drm_beta_missing_predictor_inverse_link(eta)
    sigma_x <- exp(as.numeric(par_list$log_sigma_mi[[1L]]))
    nodes <- as.numeric(model$quad_nodes)
    weights <- as.numeric(model$quad_weights)
    missing_index <- model$missing_index
    if (length(missing_index) > 0L) {
      beta_mu <- as.numeric(par_list$beta_mu)
      beta_sigma <- as.numeric(par_list$beta_sigma)
      mu_base <- as.vector(spec$X$mu %*% beta_mu)
      log_sigma <- as.vector(spec$X$sigma %*% beta_sigma)
      sigma <- sqrt(spec$V_known_diag + exp(2 * log_sigma))
      beta_x <- beta_mu[[model$mu_col]]
      x_base <- spec$X$mu[, model$mu_col]
      probability <- matrix(
        NA_real_,
        nrow = length(missing_index),
        ncol = length(nodes),
        dimnames = list(NULL, format(nodes, digits = 4))
      )
      conditional_mean <- numeric(length(missing_index))
      observed_y <- as.logical(missing_data$observed_y)
      for (row_i in seq_along(missing_index)) {
        row <- missing_index[[row_i]]
        log_terms <- log(weights) +
          drm_beta_missing_predictor_log_density(
            nodes,
            mu = mu_x[[row]],
            sigma = sigma_x
          )
        if (observed_y[[row]]) {
          mu_node <- mu_base[[row]] + beta_x * (nodes - x_base[[row]])
          log_terms <- log_terms +
            spec$weights[[row]] *
              stats::dnorm(
                spec$y[[row]],
                mean = mu_node,
                sd = sigma[[row]],
                log = TRUE
              )
        }
        max_log <- max(log_terms)
        normalized <- exp(log_terms - max_log)
        normalized <- normalized / sum(normalized)
        probability[row_i, ] <- normalized
        conditional_mean[[row_i]] <- sum(nodes * normalized)
      }
      value[missing_index] <- conditional_mean
      missing_data$predictors[[variable]]$conditional_mean <-
        conditional_mean
      missing_data$predictors[[variable]]$quadrature_probabilities <-
        probability
    }
    missing_data$predictors[[variable]]$value <- value
    missing_data$predictors[[variable]]$summary <-
      "conditional_quadrature_mean"
    return(missing_data)
  }
  if (identical(model$family, "zero_one_beta")) {
    eta <- as.vector(model$X %*% as.numeric(par_list$beta_mi))
    mu_x <- drm_beta_missing_predictor_inverse_link(eta)
    sigma_x <- exp(as.numeric(par_list$log_sigma_mi[[1L]]))
    zoi_x <- stats::plogis(as.numeric(par_list$beta_zoi[[1L]]))
    coi_x <- stats::plogis(as.numeric(par_list$beta_coi[[1L]]))
    nodes <- as.numeric(model$quad_nodes)
    weights <- as.numeric(model$quad_weights)
    missing_index <- model$missing_index
    if (length(missing_index) > 0L) {
      beta_mu <- as.numeric(par_list$beta_mu)
      beta_sigma <- as.numeric(par_list$beta_sigma)
      mu_base <- as.vector(spec$X$mu %*% beta_mu)
      log_sigma <- as.vector(spec$X$sigma %*% beta_sigma)
      sigma <- sqrt(spec$V_known_diag + exp(2 * log_sigma))
      beta_x <- beta_mu[[model$mu_col]]
      x_base <- spec$X$mu[, model$mu_col]
      probability <- matrix(
        NA_real_,
        nrow = length(missing_index),
        ncol = length(nodes),
        dimnames = list(NULL, format(nodes, digits = 4))
      )
      conditional_mean <- numeric(length(missing_index))
      observed_y <- as.logical(missing_data$observed_y)
      for (row_i in seq_along(missing_index)) {
        row <- missing_index[[row_i]]
        log_terms <- log(weights) +
          drm_zero_one_beta_missing_predictor_log_density(
            nodes,
            mu = mu_x[[row]],
            sigma = sigma_x,
            zoi = zoi_x,
            coi = coi_x
          )
        if (observed_y[[row]]) {
          mu_node <- mu_base[[row]] + beta_x * (nodes - x_base[[row]])
          log_terms <- log_terms +
            spec$weights[[row]] *
              stats::dnorm(
                spec$y[[row]],
                mean = mu_node,
                sd = sigma[[row]],
                log = TRUE
              )
        }
        max_log <- max(log_terms)
        normalized <- exp(log_terms - max_log)
        normalized <- normalized / sum(normalized)
        probability[row_i, ] <- normalized
        conditional_mean[[row_i]] <- sum(nodes * normalized)
      }
      value[missing_index] <- conditional_mean
      missing_data$predictors[[variable]]$conditional_mean <-
        conditional_mean
      missing_data$predictors[[variable]]$quadrature_values <-
        matrix(
          rep(nodes, each = length(missing_index)),
          nrow = length(missing_index),
          ncol = length(nodes),
          dimnames = list(NULL, format(nodes, digits = 4))
        )
      missing_data$predictors[[variable]]$quadrature_probabilities <-
        probability
      missing_data$predictors[[variable]]$zoi <- zoi_x
      missing_data$predictors[[variable]]$coi <- coi_x
    }
    missing_data$predictors[[variable]]$value <- value
    missing_data$predictors[[variable]]$summary <-
      "conditional_quadrature_mean"
    return(missing_data)
  }
  if (identical(model$family, "beta_binomial")) {
    eta <- as.vector(model$X %*% as.numeric(par_list$beta_mi))
    mu_x <- stats::plogis(eta)
    sigma_x <- exp(as.numeric(par_list$log_sigma_mi[[1L]]))
    missing_index <- model$missing_index
    if (length(missing_index) > 0L) {
      beta_mu <- as.numeric(par_list$beta_mu)
      beta_sigma <- as.numeric(par_list$beta_sigma)
      mu_base <- as.vector(spec$X$mu %*% beta_mu)
      log_sigma <- as.vector(spec$X$sigma %*% beta_sigma)
      sigma <- sqrt(spec$V_known_diag + exp(2 * log_sigma))
      beta_x <- beta_mu[[model$mu_col]]
      x_base <- spec$X$mu[, model$mu_col]
      max_trials <- max(model$trials[missing_index])
      support_names <- as.character(seq.int(0L, max_trials))
      probability <- matrix(
        NA_real_,
        nrow = length(missing_index),
        ncol = max_trials + 1L,
        dimnames = list(NULL, support_names)
      )
      support <- matrix(
        NA_real_,
        nrow = length(missing_index),
        ncol = max_trials + 1L,
        dimnames = list(NULL, support_names)
      )
      conditional_mean <- numeric(length(missing_index))
      observed_y <- as.logical(missing_data$observed_y)
      for (row_i in seq_along(missing_index)) {
        row <- missing_index[[row_i]]
        row_support <- seq.int(0L, model$trials[[row]])
        row_values <- row_support / model$trials[[row]]
        log_terms <- drm_beta_binomial_missing_predictor_log_density(
          success = row_support,
          trials = model$trials[[row]],
          mu = mu_x[[row]],
          sigma = sigma_x
        )
        if (observed_y[[row]]) {
          mu_node <- mu_base[[row]] + beta_x * (row_values - x_base[[row]])
          log_terms <- log_terms +
            spec$weights[[row]] *
              stats::dnorm(
                spec$y[[row]],
                mean = mu_node,
                sd = sigma[[row]],
                log = TRUE
              )
        }
        max_log <- max(log_terms)
        normalized <- exp(log_terms - max_log)
        normalized <- normalized / sum(normalized)
        cols <- seq_along(row_support)
        probability[row_i, cols] <- normalized
        support[row_i, cols] <- row_support
        conditional_mean[[row_i]] <- sum(row_values * normalized)
      }
      value[missing_index] <- conditional_mean
      missing_data$predictors[[variable]]$conditional_mean <-
        conditional_mean
      missing_data$predictors[[variable]]$success_support <- support
      missing_data$predictors[[variable]]$conditional_probabilities <-
        probability
    }
    missing_data$predictors[[variable]]$value <- value
    missing_data$predictors[[variable]]$summary <-
      "conditional_proportion_mean"
    return(missing_data)
  }
  if (identical(model$family, "poisson")) {
    eta <- as.vector(model$X %*% as.numeric(par_list$beta_mi))
    lambda <- exp(eta)
    nodes <- as.numeric(model$quad_nodes)
    missing_index <- model$missing_index
    if (length(missing_index) > 0L) {
      beta_mu <- as.numeric(par_list$beta_mu)
      beta_sigma <- as.numeric(par_list$beta_sigma)
      mu_base <- as.vector(spec$X$mu %*% beta_mu)
      log_sigma <- as.vector(spec$X$sigma %*% beta_sigma)
      sigma <- sqrt(spec$V_known_diag + exp(2 * log_sigma))
      beta_x <- beta_mu[[model$mu_col]]
      x_base <- spec$X$mu[, model$mu_col]
      probability <- matrix(
        NA_real_,
        nrow = length(missing_index),
        ncol = length(nodes),
        dimnames = list(NULL, as.character(nodes))
      )
      conditional_mean <- numeric(length(missing_index))
      observed_y <- as.logical(missing_data$observed_y)
      for (row_i in seq_along(missing_index)) {
        row <- missing_index[[row_i]]
        log_terms <- drm_poisson_missing_predictor_log_density(
          nodes,
          lambda = lambda[[row]]
        )
        if (observed_y[[row]]) {
          mu_node <- mu_base[[row]] + beta_x * (nodes - x_base[[row]])
          log_terms <- log_terms +
            spec$weights[[row]] *
              stats::dnorm(
                spec$y[[row]],
                mean = mu_node,
                sd = sigma[[row]],
                log = TRUE
              )
        }
        max_log <- max(log_terms)
        normalized <- exp(log_terms - max_log)
        normalized <- normalized / sum(normalized)
        probability[row_i, ] <- normalized
        conditional_mean[[row_i]] <- sum(nodes * normalized)
      }
      value[missing_index] <- conditional_mean
      missing_data$predictors[[variable]]$conditional_mean <-
        conditional_mean
      missing_data$predictors[[variable]]$count_support <- nodes
      missing_data$predictors[[variable]]$conditional_probabilities <-
        probability
    }
    missing_data$predictors[[variable]]$value <- value
    missing_data$predictors[[variable]]$summary <-
      "conditional_expected_count"
    return(missing_data)
  }
  if (identical(model$family, "nbinom2")) {
    eta <- as.vector(model$X %*% as.numeric(par_list$beta_mi))
    mu_x <- exp(eta)
    sigma_x <- exp(as.numeric(par_list$log_sigma_mi[[1L]]))
    nodes <- as.numeric(model$quad_nodes)
    missing_index <- model$missing_index
    if (length(missing_index) > 0L) {
      beta_mu <- as.numeric(par_list$beta_mu)
      beta_sigma <- as.numeric(par_list$beta_sigma)
      mu_base <- as.vector(spec$X$mu %*% beta_mu)
      log_sigma <- as.vector(spec$X$sigma %*% beta_sigma)
      sigma <- sqrt(spec$V_known_diag + exp(2 * log_sigma))
      beta_x <- beta_mu[[model$mu_col]]
      x_base <- spec$X$mu[, model$mu_col]
      probability <- matrix(
        NA_real_,
        nrow = length(missing_index),
        ncol = length(nodes),
        dimnames = list(NULL, as.character(nodes))
      )
      conditional_mean <- numeric(length(missing_index))
      observed_y <- as.logical(missing_data$observed_y)
      for (row_i in seq_along(missing_index)) {
        row <- missing_index[[row_i]]
        log_terms <- drm_nbinom2_missing_predictor_log_density(
          nodes,
          mu = mu_x[[row]],
          sigma = sigma_x
        )
        if (observed_y[[row]]) {
          mu_node <- mu_base[[row]] + beta_x * (nodes - x_base[[row]])
          log_terms <- log_terms +
            spec$weights[[row]] *
              stats::dnorm(
                spec$y[[row]],
                mean = mu_node,
                sd = sigma[[row]],
                log = TRUE
              )
        }
        max_log <- max(log_terms)
        normalized <- exp(log_terms - max_log)
        normalized <- normalized / sum(normalized)
        probability[row_i, ] <- normalized
        conditional_mean[[row_i]] <- sum(nodes * normalized)
      }
      value[missing_index] <- conditional_mean
      missing_data$predictors[[variable]]$conditional_mean <-
        conditional_mean
      missing_data$predictors[[variable]]$count_support <- nodes
      missing_data$predictors[[variable]]$conditional_probabilities <-
        probability
    }
    missing_data$predictors[[variable]]$value <- value
    missing_data$predictors[[variable]]$summary <-
      "conditional_expected_count"
    return(missing_data)
  }
  if (identical(model$family, "truncated_nbinom2")) {
    eta <- as.vector(model$X %*% as.numeric(par_list$beta_mi))
    mu_x <- exp(eta)
    sigma_x <- exp(as.numeric(par_list$log_sigma_mi[[1L]]))
    nodes <- as.numeric(model$quad_nodes)
    missing_index <- model$missing_index
    if (length(missing_index) > 0L) {
      beta_mu <- as.numeric(par_list$beta_mu)
      beta_sigma <- as.numeric(par_list$beta_sigma)
      mu_base <- as.vector(spec$X$mu %*% beta_mu)
      log_sigma <- as.vector(spec$X$sigma %*% beta_sigma)
      sigma <- sqrt(spec$V_known_diag + exp(2 * log_sigma))
      beta_x <- beta_mu[[model$mu_col]]
      x_base <- spec$X$mu[, model$mu_col]
      probability <- matrix(
        NA_real_,
        nrow = length(missing_index),
        ncol = length(nodes),
        dimnames = list(NULL, as.character(nodes))
      )
      conditional_mean <- numeric(length(missing_index))
      observed_y <- as.logical(missing_data$observed_y)
      for (row_i in seq_along(missing_index)) {
        row <- missing_index[[row_i]]
        log_terms <- drm_truncated_nbinom2_missing_predictor_log_density(
          nodes,
          mu = mu_x[[row]],
          sigma = sigma_x
        )
        if (observed_y[[row]]) {
          mu_node <- mu_base[[row]] + beta_x * (nodes - x_base[[row]])
          log_terms <- log_terms +
            spec$weights[[row]] *
              stats::dnorm(
                spec$y[[row]],
                mean = mu_node,
                sd = sigma[[row]],
                log = TRUE
              )
        }
        max_log <- max(log_terms)
        normalized <- exp(log_terms - max_log)
        normalized <- normalized / sum(normalized)
        probability[row_i, ] <- normalized
        conditional_mean[[row_i]] <- sum(nodes * normalized)
      }
      value[missing_index] <- conditional_mean
      missing_data$predictors[[variable]]$conditional_mean <-
        conditional_mean
      missing_data$predictors[[variable]]$count_support <- nodes
      missing_data$predictors[[variable]]$conditional_probabilities <-
        probability
    }
    missing_data$predictors[[variable]]$value <- value
    missing_data$predictors[[variable]]$summary <-
      "conditional_expected_count"
    return(missing_data)
  }
  if (identical(model$family, "lognormal")) {
    eta <- as.vector(model$X %*% as.numeric(par_list$beta_mi))
    sigma_x <- exp(as.numeric(par_list$log_sigma_mi[[1L]]))
    nodes <- as.numeric(model$quad_nodes)
    weights <- as.numeric(model$quad_weights)
    missing_index <- model$missing_index
    if (length(missing_index) > 0L) {
      beta_mu <- as.numeric(par_list$beta_mu)
      beta_sigma <- as.numeric(par_list$beta_sigma)
      mu_base <- as.vector(spec$X$mu %*% beta_mu)
      log_sigma <- as.vector(spec$X$sigma %*% beta_sigma)
      sigma <- sqrt(spec$V_known_diag + exp(2 * log_sigma))
      beta_x <- beta_mu[[model$mu_col]]
      x_base <- spec$X$mu[, model$mu_col]
      probability <- matrix(
        NA_real_,
        nrow = length(missing_index),
        ncol = length(nodes),
        dimnames = list(NULL, format(nodes, digits = 4))
      )
      quadrature_values <- matrix(
        NA_real_,
        nrow = length(missing_index),
        ncol = length(nodes),
        dimnames = list(NULL, format(nodes, digits = 4))
      )
      conditional_mean <- numeric(length(missing_index))
      observed_y <- as.logical(missing_data$observed_y)
      for (row_i in seq_along(missing_index)) {
        row <- missing_index[[row_i]]
        x_nodes <- exp(eta[[row]] + sigma_x * nodes)
        log_terms <- log(weights)
        if (observed_y[[row]]) {
          mu_node <- mu_base[[row]] + beta_x * (x_nodes - x_base[[row]])
          log_terms <- log_terms +
            spec$weights[[row]] *
              stats::dnorm(
                spec$y[[row]],
                mean = mu_node,
                sd = sigma[[row]],
                log = TRUE
              )
        }
        max_log <- max(log_terms)
        normalized <- exp(log_terms - max_log)
        normalized <- normalized / sum(normalized)
        probability[row_i, ] <- normalized
        quadrature_values[row_i, ] <- x_nodes
        conditional_mean[[row_i]] <- sum(x_nodes * normalized)
      }
      value[missing_index] <- conditional_mean
      missing_data$predictors[[variable]]$conditional_mean <-
        conditional_mean
      missing_data$predictors[[variable]]$quadrature_values <-
        quadrature_values
      missing_data$predictors[[variable]]$quadrature_probabilities <-
        probability
    }
    missing_data$predictors[[variable]]$value <- value
    missing_data$predictors[[variable]]$summary <-
      "conditional_quadrature_mean"
    return(missing_data)
  }
  if (identical(model$family, "gamma")) {
    eta <- as.vector(model$X %*% as.numeric(par_list$beta_mi))
    mu_x <- exp(eta)
    sigma_x <- exp(as.numeric(par_list$log_sigma_mi[[1L]]))
    shape_x <- 1 / sigma_x^2
    nodes <- as.numeric(model$quad_nodes)
    weights <- as.numeric(model$quad_weights)
    missing_index <- model$missing_index
    if (length(missing_index) > 0L) {
      beta_mu <- as.numeric(par_list$beta_mu)
      beta_sigma <- as.numeric(par_list$beta_sigma)
      mu_base <- as.vector(spec$X$mu %*% beta_mu)
      log_sigma <- as.vector(spec$X$sigma %*% beta_sigma)
      sigma <- sqrt(spec$V_known_diag + exp(2 * log_sigma))
      beta_x <- beta_mu[[model$mu_col]]
      x_base <- spec$X$mu[, model$mu_col]
      probability <- matrix(
        NA_real_,
        nrow = length(missing_index),
        ncol = length(nodes),
        dimnames = list(NULL, format(nodes, digits = 4))
      )
      quadrature_values <- matrix(
        NA_real_,
        nrow = length(missing_index),
        ncol = length(nodes),
        dimnames = list(NULL, format(nodes, digits = 4))
      )
      conditional_mean <- numeric(length(missing_index))
      observed_y <- as.logical(missing_data$observed_y)
      for (row_i in seq_along(missing_index)) {
        row <- missing_index[[row_i]]
        scale <- mu_x[[row]] * sigma_x^2
        x_nodes <- scale * nodes
        log_terms <- log(weights) + (shape_x - 1) * log(nodes) - lgamma(shape_x)
        if (observed_y[[row]]) {
          mu_node <- mu_base[[row]] + beta_x * (x_nodes - x_base[[row]])
          log_terms <- log_terms +
            spec$weights[[row]] *
              stats::dnorm(
                spec$y[[row]],
                mean = mu_node,
                sd = sigma[[row]],
                log = TRUE
              )
        }
        max_log <- max(log_terms)
        normalized <- exp(log_terms - max_log)
        normalized <- normalized / sum(normalized)
        probability[row_i, ] <- normalized
        quadrature_values[row_i, ] <- x_nodes
        conditional_mean[[row_i]] <- sum(x_nodes * normalized)
      }
      value[missing_index] <- conditional_mean
      missing_data$predictors[[variable]]$conditional_mean <-
        conditional_mean
      missing_data$predictors[[variable]]$quadrature_values <-
        quadrature_values
      missing_data$predictors[[variable]]$quadrature_probabilities <-
        probability
    }
    missing_data$predictors[[variable]]$value <- value
    missing_data$predictors[[variable]]$summary <-
      "conditional_quadrature_mean"
    return(missing_data)
  }
  if (identical(model$family, "tweedie")) {
    eta <- as.vector(model$X %*% as.numeric(par_list$beta_mi))
    mu_x <- exp(eta)
    sigma_x <- exp(as.numeric(par_list$log_sigma_mi[[1L]]))
    power_x <- model$power
    nodes <- as.numeric(model$quad_nodes)
    weights <- as.numeric(model$quad_weights)
    missing_index <- model$missing_index
    if (length(missing_index) > 0L) {
      beta_mu <- as.numeric(par_list$beta_mu)
      beta_sigma <- as.numeric(par_list$beta_sigma)
      mu_base <- as.vector(spec$X$mu %*% beta_mu)
      log_sigma <- as.vector(spec$X$sigma %*% beta_sigma)
      sigma <- sqrt(spec$V_known_diag + exp(2 * log_sigma))
      beta_x <- beta_mu[[model$mu_col]]
      x_base <- spec$X$mu[, model$mu_col]
      probability <- matrix(
        NA_real_,
        nrow = length(missing_index),
        ncol = length(nodes),
        dimnames = list(NULL, format(nodes, digits = 4))
      )
      quadrature_values <- matrix(
        rep(nodes, each = length(missing_index)),
        nrow = length(missing_index),
        ncol = length(nodes),
        dimnames = list(NULL, format(nodes, digits = 4))
      )
      conditional_mean <- numeric(length(missing_index))
      observed_y <- as.logical(missing_data$observed_y)
      for (row_i in seq_along(missing_index)) {
        row <- missing_index[[row_i]]
        log_terms <- log(weights) +
          drm_tweedie_missing_predictor_log_density(
            nodes,
            mu = mu_x[[row]],
            sigma = sigma_x,
            power = power_x
          )
        if (observed_y[[row]]) {
          mu_node <- mu_base[[row]] + beta_x * (nodes - x_base[[row]])
          log_terms <- log_terms +
            spec$weights[[row]] *
              stats::dnorm(
                spec$y[[row]],
                mean = mu_node,
                sd = sigma[[row]],
                log = TRUE
              )
        }
        max_log <- max(log_terms)
        normalized <- exp(log_terms - max_log)
        normalized <- normalized / sum(normalized)
        probability[row_i, ] <- normalized
        conditional_mean[[row_i]] <- sum(nodes * normalized)
      }
      value[missing_index] <- conditional_mean
      missing_data$predictors[[variable]]$conditional_mean <-
        conditional_mean
      missing_data$predictors[[variable]]$quadrature_values <-
        quadrature_values
      missing_data$predictors[[variable]]$quadrature_probabilities <-
        probability
    }
    missing_data$predictors[[variable]]$value <- value
    missing_data$predictors[[variable]]$summary <-
      "conditional_quadrature_mean"
    return(missing_data)
  }
  x_miss <- as.numeric(par_list$x_miss)
  if (length(x_miss) != length(model$missing_index)) {
    return(missing_data)
  }
  value[model$missing_index] <- x_miss
  missing_data$predictors[[variable]]$value <- value
  missing_data$predictors[[variable]]$conditional_mode <- x_miss
  missing_data$predictors[[variable]]$summary <- "conditional_mode"
  missing_data
}

#' Extract fitted missing-predictor summaries
#'
#' `imputed()` reports the fitted values used for explicitly modelled missing
#' predictors. Gaussian missing predictor values are reported as conditional
#' modes from the fitted TMB likelihood. When [TMB::sdreport()] is available,
#' `std_error` contains the corresponding likelihood-based conditional standard
#' error for Gaussian missing predictor values. Binary missing predictor values
#' are reported as fitted conditional probabilities from the Bernoulli/logit
#' predictor model and the Gaussian response likelihood. Ordered categorical
#' missing predictor values are reported as fitted conditional expected scores
#' from the cumulative-logit predictor model and the Gaussian response
#' likelihood. Unordered categorical missing predictor values are reported as
#' fitted conditional modal category scores from the baseline-category softmax
#' predictor model and the Gaussian response likelihood. Beta/proportion,
#' zero-one beta boundary-proportion, and denominator-aware beta-binomial
#' missing predictor values are reported as fitted conditional means from the
#' fitted predictor model and the Gaussian response likelihood. Count missing
#' predictor values are reported as
#' fitted conditional expected counts from Poisson, negative-binomial, or
#' zero-truncated negative-binomial predictor models and Gaussian response
#' likelihood. Lognormal, Gamma, and Tweedie missing predictor values are
#' reported as fitted conditional quadrature means from the positive or
#' semi-continuous predictor model and Gaussian response likelihood. The first
#' finite-state, beta/proportion, boundary-proportion, beta-binomial, count,
#' lognormal, Gamma, and Tweedie routes report `NA` standard errors.
#'
#' This is not multiple imputation: the output does not contain posterior
#' means, posterior intervals, credible intervals, or pooled-imputation
#' summaries.
#'
#' @param object A `drmTMB` fit.
#' @param variable Optional missing-predictor name. The default uses the only
#'   modelled missing predictor in the fit.
#' @param rows Which rows to return. `"missing"` returns only fitted missing
#'   predictor values. `"all"` returns retained model rows, with observed
#'   predictor values labelled as observed.
#' @param se Logical; include conditional standard errors when the fit contains
#'   a successful [TMB::sdreport()] result.
#' @param ... Reserved for future extractor options.
#'
#' @return A data frame with `variable`, `original_row`, `model_row`,
#'   `observed`, `estimate`, `std_error`, `source`, and `uncertainty_status`.
#' @export
imputed <- function(object, ...) {
  UseMethod("imputed")
}

#' @rdname imputed
#' @export
imputed.drmTMB <- function(
  object,
  variable = NULL,
  rows = c("missing", "all"),
  se = TRUE,
  ...
) {
  rows <- match.arg(rows)
  se <- isTRUE(se)
  predictors <- object$missing_data$predictors
  if (!is.list(predictors) || length(predictors) == 0L) {
    cli::cli_abort(c(
      "This fit has no modelled missing predictors to summarize.",
      "i" = "{.fn imputed} currently supports fitted {.fn mi} predictors, not response masks."
    ))
  }
  predictor_names <- names(predictors)
  if (is.null(variable)) {
    if (length(predictor_names) != 1L) {
      cli::cli_abort(
        "{.arg variable} is required when a fit contains more than one modelled missing predictor."
      )
    }
    variable <- predictor_names[[1L]]
  }
  if (
    !is.character(variable) ||
      length(variable) != 1L ||
      is.na(variable) ||
      !nzchar(variable)
  ) {
    cli::cli_abort("{.arg variable} must be one missing-predictor name.")
  }
  if (!variable %in% predictor_names) {
    cli::cli_abort(c(
      "Unknown modelled missing predictor {.val {variable}}.",
      "i" = "Available modelled missing predictor{?s}: {.val {predictor_names}}."
    ))
  }

  predictor <- predictors[[variable]]
  if (
    is.null(predictor$value) ||
      length(predictor$value) != length(predictor$observed)
  ) {
    cli::cli_abort(c(
      "Fitted missing-predictor values are unavailable for {.val {variable}}.",
      "i" = "Refit with the current {.pkg drmTMB} missing-predictor implementation."
    ))
  }
  observed <- as.logical(predictor$observed)
  row_index <- if (identical(rows, "missing")) {
    which(!observed)
  } else {
    seq_along(observed)
  }
  missing_rows <- which(!observed)
  se_missing <- drm_imputed_missing_predictor_se(
    object,
    length(missing_rows),
    se
  )
  se_full <- rep(NA_real_, length(observed))
  se_full[missing_rows] <- se_missing

  missing_source <- if (!is.null(predictor$summary)) {
    predictor$summary
  } else {
    "conditional_mode"
  }
  source <- ifelse(observed[row_index], "observed", missing_source)
  out <- data.frame(
    variable = rep(variable, length(row_index)),
    original_row = as.integer(object$missing_data$original_row[row_index]),
    model_row = as.integer(row_index),
    observed = observed[row_index],
    estimate = as.numeric(predictor$value[row_index]),
    std_error = as.numeric(se_full[row_index]),
    source = source,
    uncertainty_status = rep(
      drm_standard_error_status(object),
      length(row_index)
    ),
    stringsAsFactors = FALSE
  )
  row.names(out) <- NULL
  out
}

drm_imputed_missing_predictor_se <- function(object, n_missing, se) {
  if (n_missing == 0L) {
    return(numeric(0))
  }
  if (
    !isTRUE(se) || is.null(object$sdr) || is.null(object$sdr$diag.cov.random)
  ) {
    return(rep(NA_real_, n_missing))
  }
  random_names <- names(object$sdr$par.random)
  positions <- which(random_names == "x_miss")
  if (length(positions) != n_missing) {
    # Summed (finite-state) mi families legitimately have zero x_miss random
    # parameters; fall back to NA in that case rather than mismatching.
    return(rep(NA_real_, n_missing))
  }
  variance <- as.numeric(object$sdr$diag.cov.random[positions])
  sqrt(pmax(variance, 0))
}
