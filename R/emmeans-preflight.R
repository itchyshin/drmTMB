drm_emmeans_mu_basis <- function(
  object,
  newdata,
  dpar = "mu",
  type = c("link", "response")
) {
  type <- match.arg(type)
  drm_validate_emmeans_mu_target(object, dpar)
  basis <- drm_fixed_effect_basis(
    object = object,
    newdata = newdata,
    dpar = dpar,
    covariance = TRUE
  )
  list(
    dpar = dpar,
    type = type,
    basis = basis
  )
}

recover_data.drmTMB <- function(object, dpar = "mu", data = NULL, ...) {
  recovered <- tryCatch(
    drm_emmeans_recover_data(object, dpar = dpar),
    error = function(e) conditionMessage(e)
  )
  if (is.character(recovered)) {
    return(recovered)
  }
  data <- if (is.null(data)) recovered$model_frame else data
  emmeans::recover_data(
    object$call,
    recovered$terms,
    na.action = NULL,
    data = data,
    frame = data,
    ...
  )
}

emm_basis.drmTMB <- function(object, trms, xlev, grid, dpar = "mu", ...) {
  target <- drm_emmeans_mu_basis(
    object,
    newdata = grid,
    dpar = dpar
  )
  basis <- target$basis
  bhat <- as.numeric(basis$bhat)
  names(bhat) <- names(basis$bhat)
  misc <- drm_emmeans_misc(basis$link, dpar = dpar)
  list(
    X = as.matrix(basis$X),
    bhat = bhat,
    nbasis = matrix(NA_real_, nrow = 1L, ncol = 1L),
    V = basis$V,
    dffun = function(k, dfargs) dfargs$df,
    dfargs = list(df = Inf),
    misc = misc
  )
}

drm_emmeans_misc <- function(link, dpar) {
  misc <- list(dpar = dpar)
  if (identical(link, "identity")) {
    return(misc)
  }
  misc$tran <- link
  misc$inv.lbl <- "response"
  misc$sigma <- NA_real_
  misc
}

drm_emmeans_recover_data <- function(object, dpar = "mu") {
  drm_validate_emmeans_mu_target(object, dpar)
  model_frame <- drm_emmeans_model_frame(object, dpar)
  terms <- object$model$terms[[dpar]]
  if (is.null(terms)) {
    cli::cli_abort(
      "This {.cls drmTMB} fit does not retain terms for {.code dpar = \"{dpar}\"}."
    )
  }
  model_frame <- drm_emmeans_complete_model_frame(object, model_frame, terms)
  list(
    dpar = dpar,
    model_frame = model_frame,
    terms = terms,
    predictors = all.vars(stats::delete.response(terms)),
    response = response_name_from_model_frame(
      object,
      dpar,
      fallback = NA_character_
    ),
    xlevels = stats::.getXlevels(terms, model_frame),
    row_names = row.names(model_frame)
  )
}

drm_emmeans_model_frame <- function(object, dpar) {
  model_frames <- object$model$model_frame
  if (!is.list(model_frames)) {
    cli::cli_abort(c(
      "The first {.pkg emmeans} recover-data preflight requires retained model frames.",
      i = "Refit with {.code control = drm_control(keep_model_frame = TRUE)}."
    ))
  }
  model_frame <- model_frames[[dpar]]
  if (!is.data.frame(model_frame)) {
    cli::cli_abort(c(
      "The first {.pkg emmeans} recover-data preflight requires a retained model frame for {.code dpar = \"{dpar}\"}.",
      i = "Refit with {.code control = drm_control(keep_model_frame = TRUE)}."
    ))
  }
  model_frame
}

drm_emmeans_complete_model_frame <- function(object, model_frame, terms) {
  needed <- all.vars(terms)
  missing <- setdiff(needed, names(model_frame))
  if (length(missing) == 0L) {
    return(model_frame)
  }

  source <- object$data
  if (!is.data.frame(source) || !all(missing %in% names(source))) {
    cli::cli_abort(c(
      "The first {.pkg emmeans} recover-data preflight could not recover all model variables.",
      i = "Missing variable{?s}: {.val {missing}}.",
      i = "Refit with stored data so offset and transformed predictor variables can be reconstructed."
    ))
  }

  row_index <- match(row.names(model_frame), row.names(source))
  if (anyNA(row_index) && nrow(source) == nrow(model_frame)) {
    row_index <- seq_len(nrow(model_frame))
  }
  if (anyNA(row_index)) {
    cli::cli_abort(c(
      "The first {.pkg emmeans} recover-data preflight could not align retained model rows with stored data.",
      i = "Refit with retained model frames and stored data."
    ))
  }

  for (name in missing) {
    model_frame[[name]] <- source[[name]][row_index]
  }
  model_frame
}

drm_validate_emmeans_mu_target <- function(object, dpar) {
  if (!is.character(dpar) || length(dpar) != 1L || is.na(dpar)) {
    cli::cli_abort(
      "{.arg dpar} must be one distributional-parameter name."
    )
  }
  if (!identical(dpar, "mu")) {
    cli::cli_abort(c(
      "The first {.pkg emmeans} basis preflight is limited to {.code dpar = \"mu\"}.",
      i = "Use {.fn prediction_grid} and {.fn predict_parameters} for other distributional parameters."
    ))
  }
  supported_model_types <- c(
    "gaussian",
    "student",
    "lognormal",
    "gamma",
    "beta",
    "beta_binomial",
    "poisson",
    "nbinom2",
    "truncated_nbinom2"
  )
  if (!object$model$model_type %in% supported_model_types) {
    cli::cli_abort(c(
      "The first {.pkg emmeans} basis preflight is not implemented for {.val {object$model$model_type}} fits.",
      i = "Supported model types: {.val {supported_model_types}}.",
      i = "Use {.fn prediction_grid} and {.fn predict_parameters} for explicit prediction tables."
    ))
  }

  if (drm_emmeans_has_transformed_response(object, dpar)) {
    response <- object$model$response_names[[dpar]]
    cli::cli_abort(c(
      "The first {.pkg emmeans} basis preflight does not support transformed responses.",
      i = "Unsupported response: {.code {response}}.",
      i = "Fit an untransformed response, or use {.fn prediction_grid} and {.fn predict_parameters} for explicit transformed-scale predictions."
    ))
  }

  if (!dpar %in% names(object$coefficients)) {
    cli::cli_abort(
      "This {.cls drmTMB} fit does not contain a fitted {.code mu} parameter."
    )
  }

  blocked <- drm_emmeans_blocked_features(object)
  if (length(blocked) > 0L) {
    cli::cli_abort(c(
      "The first {.pkg emmeans} basis preflight is limited to fixed-effect models.",
      i = "Unsupported feature{?s}: {.val {blocked}}.",
      i = "Use {.fn prediction_grid} and {.fn predict_parameters} until this path has explicit tests."
    ))
  }
  invisible(TRUE)
}

drm_emmeans_has_transformed_response <- function(object, dpar) {
  response <- object$model$response_names[[dpar]]
  if (!is.character(response) || length(response) != 1L || is.na(response)) {
    return(FALSE)
  }
  expr <- tryCatch(
    parse(text = response, keep.source = FALSE)[[1L]],
    error = function(e) NULL
  )
  if (is.null(expr) || is.symbol(expr)) {
    return(FALSE)
  }
  if (is.call(expr) && identical(as.character(expr[[1L]]), "cbind")) {
    return(FALSE)
  }
  TRUE
}

drm_emmeans_blocked_features <- function(object) {
  blocked <- character()
  if (has_ordinary_mu_random_effects(object)) {
    blocked <- c(blocked, "mu random effects")
  }
  if (has_sigma_random_effects(object)) {
    blocked <- c(blocked, "sigma random effects")
  }
  if (has_structured_mu_effect(object)) {
    blocked <- c(blocked, "structured mu effects")
  }
  if (has_covariance_block_random_effects(object)) {
    blocked <- c(blocked, "covariance-block random effects")
  }
  if (drm_has_random_scale_models(object)) {
    blocked <- c(blocked, "random-effect scale models")
  }
  unique(blocked)
}

drm_has_random_scale_models <- function(object) {
  mu_models <- is.list(object$model$random_scale$mu) &&
    object$model$random_scale$mu$n_models > 0L
  phylo_models <- is.list(object$model$random_scale$phylo) &&
    object$model$random_scale$phylo$n_models > 0L
  isTRUE(mu_models) || isTRUE(phylo_models)
}
