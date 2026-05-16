#' Confidence intervals for fitted model parameters
#'
#' `confint()` returns confidence intervals for a fitted `drmTMB` model. Wald
#' intervals are fast and are returned for fixed-effect coefficients by default.
#' Profile-likelihood intervals are slower because nuisance parameters are
#' re-optimized; this first public profile path supports explicit fixed-effect,
#' constant distributional-scale, random-effect standard-deviation,
#' random-effect correlation, the first bivariate phylogenetic mean-mean
#' correlation, and constant residual-correlation targets.
#' For predictor-dependent scale, residual-correlation, or currently supported
#' `corpair()` formulae, supply `newdata` with `parm = "sigma"`,
#' `parm = "rho12"`, or the fitted `corpair(...)` dpar to profile the fitted
#' response-scale value for each supplied row.
#'
#' Target names follow the profile target namespace. For fixed effects, use
#' names such as `"fixef:mu:x"`, `"fixef:sigma:(Intercept)"`, or
#' `"fixef:rho12:w"`. Compact coefficient labels from `summary(fit)`, such as
#' `"mu:x"`, are also accepted. Random-effect SD intervals are reported on the
#' SD scale, and random-effect correlation intervals are reported on the
#' correlation scale. For bivariate Gaussian fits with constant residual
#' correlation, `parm = "rho12"` profiles the residual correlation and reports
#' the interval on the response correlation scale. For fits with constant
#' `sigma`, `sigma1`, or `sigma2`, `parm = "sigma"` and friends report
#' response-scale intervals.
#'
#' @param object A `drmTMB` fit.
#' @param parm Optional character or integer vector selecting interval targets.
#'   `NULL` selects all fixed effects for Wald intervals. Profile intervals
#'   require explicit target names.
#' @param level Confidence level.
#' @param method Interval method: `"wald"` or `"profile"`. If `newdata` is
#'   supplied and `method` is omitted, `method = "profile"` is used.
#' @param newdata Optional data frame for response-scale profile intervals for
#'   predictor-dependent `sigma`, `sigma1`, `sigma2`, `rho12`, or fitted
#'   `corpair()` values. Each row is profiled separately by profiling its
#'   fixed-effect linear predictor and then transforming the interval to the
#'   response scale.
#' @param trace Logical; passed to [TMB::tmbprofile()] for profile intervals.
#' @param ... Additional arguments passed to [TMB::tmbprofile()] when
#'   `method = "profile"`. `drmTMB` supplies the profiled `obj`, `name`,
#'   `lincomb`, and `trace` arguments internally; set the profile target with
#'   `parm`.
#'
#' @return A data frame with columns `parm`, `level`, `lower`, `upper`,
#'   `scale`, `transformation`, `tmb_parameter`, `index`, `method`, and
#'   `conf.status`, `profile.boundary`, and `profile.message`. Successful rows
#'   currently use `conf.status = "wald"` or `conf.status = "profile"`;
#'   profile rows mark intervals that land near a lower SD boundary or
#'   correlation boundary.
#'
#' @examples
#' dat <- data.frame(y = c(0.2, 0.5, 1.1, 1.4), x = c(-1, 0, 1, 2))
#' fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat)
#' confint(fit)
#' @export
confint.drmTMB <- function(
  object,
  parm = NULL,
  level = 0.95,
  method = c("wald", "profile"),
  newdata = NULL,
  trace = FALSE,
  ...
) {
  method_missing <- missing(method)
  method <- match.arg(method)
  if (!is.null(newdata) && method_missing) {
    method <- "profile"
  }
  validate_profile_level(level)

  if (identical(method, "wald")) {
    if (!is.null(newdata)) {
      cli::cli_abort(
        "{.arg newdata} is only used when {.code method = \"profile\"}."
      )
    }
    dots <- list(...)
    if (length(dots) > 0L) {
      cli::cli_abort(
        "Additional arguments in {.arg ...} are only used when {.code method = \"profile\"}."
      )
    }
    return(drm_wald_confint(object, parm = parm, level = level))
  }

  if (!is.null(newdata)) {
    return(drm_profile_response_newdata_confint(
      object,
      parm = parm,
      newdata = newdata,
      level = level,
      trace = trace,
      ...
    ))
  }

  if (is.null(parm)) {
    cli::cli_abort(c(
      "Profile confidence intervals currently require explicit target names.",
      i = "Use names such as {.val fixef:mu:x} or compact labels such as {.val mu:x}."
    ))
  }

  targets <- profile_match_confint_targets(
    drm_profile_targets(object),
    parm,
    fixed_only = FALSE
  )
  drm_profile_confint(
    object,
    parm = targets$parm,
    level = level,
    trace = trace,
    ...
  )
}

#' List confidence-interval targets for a fitted model
#'
#' `profile_targets()` shows the names that can be supplied to
#' [confint.drmTMB()]. The table also records whether each row is currently
#' ready for direct profile-likelihood intervals. This helps users inspect the
#' fitted object before starting an expensive profile.
#'
#' @param object A `drmTMB` fit.
#' @param ready_only Logical; if `TRUE`, return only targets whose
#'   `profile_ready` column is `TRUE`.
#'
#' @return A data frame with columns `parm`, `target_class`, `dpar`, `term`,
#'   `tmb_parameter`, `index`, `estimate`, `link_estimate`, `scale`,
#'   `transformation`, `target_type`, `profile_ready`, and `profile_note`.
#'   `target_type` is either `"direct"` for a target that maps to a single
#'   fitted TMB parameter or `"derived"` for a target that is reported from a
#'   transformed or multi-parameter quantity. `profile_ready = TRUE` means the
#'   target is direct and the fitted object retained the TMB object needed for
#'   [confint.drmTMB()] with `method = "profile"`. Common `profile_note`
#'   values are `"ready"`, `"tmb_object_required"`, `"missing_tmb_parameter"`,
#'   `"derived_target"`, and `"derived_unstructured_correlation"`.
#'   Derived variance-ratio summaries such as repeatability and phylogenetic
#'   signal are listed as point-estimate targets with
#'   `profile_ready = FALSE`.
#'
#' @examples
#' dat <- data.frame(y = c(0.2, 0.5, 1.1, 1.4), x = c(-1, 0, 1, 2))
#' fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat)
#' profile_targets(fit)
#' @export
profile_targets <- function(object, ready_only = FALSE) {
  if (!inherits(object, "drmTMB")) {
    cli::cli_abort("{.arg object} must be a {.cls drmTMB} fit.")
  }
  if (
    !is.logical(ready_only) ||
      length(ready_only) != 1L ||
      is.na(ready_only)
  ) {
    cli::cli_abort(
      "{.arg ready_only} must be a single {.code TRUE} or {.code FALSE}."
    )
  }

  targets <- drm_profile_targets(object)
  if (ready_only) {
    targets <- targets[targets$profile_ready, , drop = FALSE]
  }
  row.names(targets) <- NULL
  targets
}

drm_profile_targets <- function(object) {
  rows <- list()
  counters <- new.env(parent = emptyenv())

  add_rows <- function(new_rows) {
    if (!length(new_rows)) {
      return(invisible(NULL))
    }
    rows <<- c(rows, new_rows)
    invisible(NULL)
  }

  next_indices <- function(internal, n) {
    if (is.na(internal) || n == 0L) {
      return(rep(NA_integer_, n))
    }
    current <- if (exists(internal, envir = counters, inherits = FALSE)) {
      get(internal, envir = counters, inherits = FALSE)
    } else {
      0L
    }
    out <- current + seq_len(n)
    assign(internal, current + n, envir = counters)
    out
  }

  for (dpar in names(object$coefficients)) {
    beta <- object$coefficients[[dpar]]
    internal <- profile_fixef_internal(dpar)
    indices <- next_indices(internal, length(beta))
    add_rows(lapply(seq_along(beta), function(i) {
      status <- profile_direct_target_status(
        object,
        internal,
        indices[[i]]
      )
      new_profile_target_row(
        parm = paste0("fixef:", dpar, ":", names(beta)[[i]]),
        target_class = "fixed-effect",
        dpar = dpar,
        term = names(beta)[[i]],
        tmb_parameter = internal,
        index = indices[[i]],
        estimate = unname(beta[[i]]),
        link_estimate = unname(beta[[i]]),
        scale = "link",
        transformation = "linear_predictor",
        target_type = "direct",
        profile_ready = status$profile_ready,
        profile_note = status$profile_note
      )
    }))
  }

  scale_dpars <- intersect(
    names(object$coefficients),
    c("sigma", "sigma1", "sigma2")
  )
  for (dpar in scale_dpars) {
    beta <- object$coefficients[[dpar]]
    if (
      length(beta) == 1L &&
        identical(names(beta), "(Intercept)") &&
        identical(drm_dpar_link(object, dpar), "log")
    ) {
      internal <- profile_fixef_internal(dpar)
      status <- profile_direct_target_status(object, internal, 1L)
      add_rows(list(new_profile_target_row(
        parm = dpar,
        target_class = "distributional-scale",
        dpar = dpar,
        term = "(constant)",
        tmb_parameter = internal,
        index = 1L,
        estimate = exp(unname(beta[[1L]])),
        link_estimate = unname(beta[[1L]]),
        scale = "response",
        transformation = "exp",
        target_type = "direct",
        profile_ready = status$profile_ready,
        profile_note = status$profile_note
      )))
    }
  }

  if ("rho12" %in% names(object$coefficients)) {
    beta <- object$coefficients$rho12
    if (length(beta) == 1L && identical(names(beta), "(Intercept)")) {
      status <- profile_direct_target_status(object, "beta_rho12", 1L)
      add_rows(list(new_profile_target_row(
        parm = "rho12",
        target_class = "residual-correlation",
        dpar = "rho12",
        term = "(constant)",
        tmb_parameter = "beta_rho12",
        index = 1L,
        estimate = rho_response(unname(beta[[1L]])),
        link_estimate = unname(beta[[1L]]),
        scale = "response",
        transformation = "rho12_tanh",
        target_type = "direct",
        profile_ready = status$profile_ready,
        profile_note = status$profile_note
      )))
    }
  }

  for (dpar in names(object$sdpars)) {
    values <- object$sdpars[[dpar]]
    for (i in seq_along(values)) {
      term <- names(values)[[i]]
      internal <- profile_sd_internal(dpar, term)
      is_direct <- !is.na(internal)
      index <- if (is_direct) {
        next_indices(internal, 1L)
      } else {
        NA_integer_
      }
      status <- if (is_direct) {
        profile_direct_target_status(object, internal, index)
      } else {
        list(profile_ready = FALSE, profile_note = "derived_target")
      }
      add_rows(list(new_profile_target_row(
        parm = paste0("sd:", dpar, ":", term),
        target_class = "random-effect-sd",
        dpar = dpar,
        term = term,
        tmb_parameter = internal,
        index = index,
        estimate = unname(values[[i]]),
        link_estimate = log(unname(values[[i]])),
        scale = "response",
        transformation = if (is_direct) "exp" else "derived_group_scale",
        target_type = if (is_direct) "direct" else "derived",
        profile_ready = status$profile_ready,
        profile_note = status$profile_note
      )))
    }
  }

  registry_cor_rows <- profile_registry_cor_targets(object)
  add_rows(registry_cor_rows)
  add_rows(profile_derived_summary_targets(object))
  registry_cor_keys <- covariance_block_corpars_keys(
    object$model$random$covariance_blocks
  )
  for (dpar in names(object$corpars)) {
    values <- object$corpars[[dpar]]
    internal <- profile_cor_internal(dpar)
    is_phylo_unstructured <- identical(dpar, "phylo") &&
      isTRUE(object$model$structured$phylo_mu$has) &&
      isTRUE(object$model$structured$phylo_mu$q > 2L)
    for (i in seq_along(values)) {
      if (paste(dpar, i, sep = ":") %in% registry_cor_keys) {
        next
      }
      if (random_effect_correlation_is_modelled(object, dpar, i)) {
        next
      }
      index <- i
      if (is_phylo_unstructured) {
        internal <- "theta_phylo"
        status <- list(
          profile_ready = FALSE,
          profile_note = "derived_unstructured_correlation"
        )
      } else {
        status <- profile_direct_target_status(
          object,
          internal,
          index
        )
      }
      add_rows(list(new_profile_target_row(
        parm = paste0("cor:", dpar, ":", names(values)[[i]]),
        target_class = "random-effect-correlation",
        dpar = dpar,
        term = names(values)[[i]],
        tmb_parameter = internal,
        index = index,
        estimate = unname(values[[i]]),
        link_estimate = if (is_phylo_unstructured) {
          NA_real_
        } else {
          guarded_correlation_link(
            unname(values[[i]]),
            guard = 0.999999
          )
        },
        scale = "response",
        transformation = if (is_phylo_unstructured) {
          "unstructured_corr"
        } else {
          "tanh"
        },
        target_type = if (is_phylo_unstructured) "derived" else "direct",
        profile_ready = status$profile_ready,
        profile_note = status$profile_note
      )))
    }
  }

  if (!is.null(object$ordinal)) {
    theta <- object$ordinal$theta_raw
    internal <- "theta_ord"
    indices <- next_indices(internal, length(theta))
    add_rows(lapply(seq_along(theta), function(i) {
      status <- profile_direct_target_status(
        object,
        internal,
        indices[[i]]
      )
      new_profile_target_row(
        parm = paste0("ordinal:theta_ord:", names(theta)[[i]]),
        target_class = "ordinal-cutpoint-internal",
        dpar = "ordinal",
        term = names(theta)[[i]],
        tmb_parameter = internal,
        index = indices[[i]],
        estimate = unname(theta[[i]]),
        link_estimate = unname(theta[[i]]),
        scale = "internal",
        transformation = "ordered_cutpoint",
        target_type = "direct",
        profile_ready = status$profile_ready,
        profile_note = status$profile_note
      )
    }))
  }

  out <- if (length(rows)) {
    do.call(rbind, rows)
  } else {
    empty_profile_targets()
  }
  row.names(out) <- NULL
  validate_profile_targets(out)
}

drm_profile_confint <- function(
  object,
  parm,
  level = 0.95,
  trace = FALSE,
  ...
) {
  validate_profile_level(level)
  profile_check_tmbprofile_dots(...)
  if (is.null(object$obj)) {
    cli::cli_abort(c(
      "Profile confidence intervals require the TMB object retained in {.code fit$obj}.",
      i = "Refit with {.code drm_control(keep_tmb_object = TRUE)} before using {.code method = \"profile\"}."
    ))
  }
  targets <- profile_match_targets(drm_profile_targets(object), parm)

  rows <- lapply(seq_len(nrow(targets)), function(i) {
    drm_profile_target_confint(
      object = object,
      target = targets[i, , drop = FALSE],
      level = level,
      trace = trace,
      ...
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

profile_derived_summary_targets <- function(object) {
  rows <- drm_derived_summary_rows(object)
  if (nrow(rows) == 0L) {
    return(list())
  }
  lapply(seq_len(nrow(rows)), function(i) {
    row <- rows[i, , drop = FALSE]
    new_profile_target_row(
      parm = row$parm[[1L]],
      target_class = "derived-summary",
      dpar = row$dpar[[1L]],
      term = row$term[[1L]],
      tmb_parameter = NA_character_,
      index = NA_integer_,
      estimate = row$estimate[[1L]],
      link_estimate = NA_real_,
      scale = "response",
      transformation = "variance_ratio",
      target_type = "derived",
      profile_ready = FALSE,
      profile_note = "derived_target"
    )
  })
}

drm_profile_response_newdata_confint <- function(
  object,
  parm,
  newdata,
  level = 0.95,
  trace = FALSE,
  ...
) {
  validate_profile_level(level)
  profile_check_tmbprofile_dots(...)
  if (is.null(object$obj)) {
    cli::cli_abort(c(
      "Profile confidence intervals require the TMB object retained in {.code fit$obj}.",
      i = "Refit with {.code drm_control(keep_tmb_object = TRUE)} before using {.code method = \"profile\"}."
    ))
  }
  dpar <- profile_newdata_dpar(object, parm)
  if (!is.data.frame(newdata)) {
    cli::cli_abort("{.arg newdata} must be a data frame.")
  }
  if (nrow(newdata) < 1L) {
    cli::cli_abort("{.arg newdata} must contain at least one row.")
  }

  X <- drm_prediction_matrix(object, newdata, dpar)
  beta <- object$coefficients[[dpar]]
  if (!identical(colnames(X), names(beta))) {
    cli::cli_abort(c(
      "Could not align {.arg newdata} with the fitted {.val {dpar}} formula.",
      i = "Check that factor levels and predictor columns match the fitted model."
    ))
  }
  offset <- drm_prediction_offset(object, newdata, dpar)
  if (length(offset) != nrow(X)) {
    cli::cli_abort(
      "Internal error: response-scale profile offsets do not match {.arg newdata} rows."
    )
  }

  internal <- profile_fixef_internal(dpar)
  par_names <- names(object$opt$par)
  positions <- which(par_names == internal)
  if (length(positions) < ncol(X)) {
    cli::cli_abort(c(
      "Profile target {.val {dpar}} cannot be mapped to optimized parameters.",
      i = "Expected {ncol(X)} coefficient{?s} in TMB parameter {.val {internal}}."
    ))
  }

  labels <- profile_newdata_parm_labels(dpar, newdata)
  rows <- lapply(seq_len(nrow(X)), function(i) {
    lincomb <- rep(0, length(object$opt$par))
    lincomb[positions[seq_len(ncol(X))]] <- as.numeric(X[i, ])
    prof <- drm_tmbprofile(
      object = object,
      target_name = labels[[i]],
      lincomb = lincomb,
      trace = trace,
      ...
    )
    ci <- drm_tmbprofile_confint(prof, target_name = labels[[i]], level = level)
    interval <- profile_transform_newdata_interval(
      c(unname(ci[1L, "lower"]), unname(ci[1L, "upper"])),
      object = object,
      dpar = dpar,
      offset = offset[[i]]
    )

    diagnostics <- profile_interval_diagnostics(
      interval,
      transformation = profile_newdata_transformation(object, dpar)
    )

    data.frame(
      parm = labels[[i]],
      level = level,
      lower = interval[[1L]],
      upper = interval[[2L]],
      scale = "response",
      transformation = profile_newdata_transformation(object, dpar),
      tmb_parameter = internal,
      index = NA_integer_,
      method = "profile",
      conf.status = "profile",
      profile.boundary = diagnostics$boundary,
      profile.message = diagnostics$message,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

drm_wald_confint <- function(object, parm, level) {
  targets <- drm_profile_targets(object)
  targets <- targets[targets$target_class == "fixed-effect", , drop = FALSE]
  targets <- profile_match_confint_targets(
    targets,
    parm,
    fixed_only = TRUE
  )

  estimates <- unlist(object$coefficients, use.names = FALSE)
  se <- sqrt(diag(stats::vcov(object)))
  labels <- coefficient_labels(object)
  z <- stats::qnorm((1 + level) / 2)
  rows <- profile_target_positions(targets, labels)

  out <- data.frame(
    parm = targets$parm,
    level = level,
    lower = estimates[rows] - z * se[rows],
    upper = estimates[rows] + z * se[rows],
    scale = targets$scale,
    transformation = targets$transformation,
    tmb_parameter = targets$tmb_parameter,
    index = targets$index,
    method = "wald",
    conf.status = "wald",
    profile.boundary = NA,
    profile.message = NA_character_,
    stringsAsFactors = FALSE
  )
  row.names(out) <- NULL
  out
}

drm_profile_target_confint <- function(
  object,
  target,
  level,
  trace,
  ...
) {
  implemented_classes <- c(
    "fixed-effect",
    "distributional-scale",
    "random-effect-sd",
    "random-effect-correlation",
    "residual-correlation"
  )
  if (!isTRUE(target$profile_ready)) {
    cli::cli_abort(c(
      "Profile target {.val {target$parm}} is not ready for direct profiling.",
      i = "Inventory note: {.val {target$profile_note}}."
    ))
  }
  if (!target$target_class %in% implemented_classes) {
    cli::cli_abort(c(
      "Profile intervals are implemented for direct fixed-effect, constant distributional-scale, random-effect SD, random-effect correlation, and constant residual-correlation targets.",
      i = "Requested {.val {target$parm}} has target class {.val {target$target_class}}."
    ))
  }

  lincomb <- profile_lincomb(object, target)
  prof <- drm_tmbprofile(
    object = object,
    target_name = target$parm,
    lincomb = lincomb,
    trace = trace,
    ...
  )
  ci <- drm_tmbprofile_confint(prof, target_name = target$parm, level = level)
  interval <- profile_transform_interval(
    c(unname(ci[1L, "lower"]), unname(ci[1L, "upper"])),
    target
  )
  diagnostics <- profile_interval_diagnostics(
    interval,
    transformation = target$transformation
  )

  data.frame(
    parm = target$parm,
    level = level,
    lower = interval[[1L]],
    upper = interval[[2L]],
    scale = target$scale,
    transformation = target$transformation,
    tmb_parameter = target$tmb_parameter,
    index = target$index,
    method = "profile",
    conf.status = "profile",
    profile.boundary = diagnostics$boundary,
    profile.message = diagnostics$message,
    stringsAsFactors = FALSE
  )
}

profile_check_tmbprofile_dots <- function(...) {
  dots <- list(...)
  if (!length(dots)) {
    return(invisible(NULL))
  }
  dot_names <- names(dots)
  if (is.null(dot_names)) {
    return(invisible(NULL))
  }
  controlled <- intersect(
    dot_names[nzchar(dot_names)],
    c("obj", "name", "lincomb", "trace")
  )
  if (length(controlled)) {
    cli::cli_abort(c(
      "Profile target selection is controlled by {.arg parm}.",
      x = "Do not pass {.arg {controlled}} through {.arg ...}.",
      i = "{.pkg drmTMB} profiles one target at a time by supplying {.arg obj}, {.arg name}, {.arg lincomb}, and {.arg trace} to {.fun TMB::tmbprofile} internally."
    ))
  }
  invisible(NULL)
}

drm_tmbprofile <- function(object, target_name, lincomb, trace, ...) {
  drm_pin_tmb_object_to_optimum(object$obj, object$opt, object$tmb_state)
  tryCatch(
    TMB::tmbprofile(
      obj = object$obj,
      name = target_name,
      lincomb = lincomb,
      trace = trace,
      ...
    ),
    error = function(err) {
      cli::cli_abort(
        c(
          "Profile likelihood failed while profiling target {.val {target_name}}.",
          i = "Check {.code profile_targets(fit)} to confirm the target is profile-ready.",
          i = "Try changing profile controls such as {.arg ystep}, {.arg ytol}, or {.arg parm.range}; then inspect {.code check_drm(fit)} if the profile still fails.",
          i = "This can indicate a boundary, one-sided, non-monotone, or failed-inner-optimization profile.",
          x = "Original error: {conditionMessage(err)}"
        ),
        parent = err
      )
    }
  )
}

drm_tmbprofile_confint <- function(profile, target_name, level) {
  tryCatch(
    stats::confint(profile, level = level),
    error = function(err) {
      cli::cli_abort(
        c(
          "Could not extract a profile confidence interval for target {.val {target_name}}.",
          i = "The profile may not cross the likelihood-ratio threshold on both sides.",
          i = "Try a wider {.arg parm.range}, a smaller {.arg ystep}, or inspect the profile object interactively.",
          i = "This can indicate a boundary, one-sided, non-monotone, or failed-inner-optimization profile.",
          x = "Original error: {conditionMessage(err)}"
        ),
        parent = err
      )
    }
  )
}

profile_interval_diagnostics <- function(
  interval,
  transformation,
  sd_boundary = sqrt(.Machine$double.eps),
  correlation_boundary = 0.98
) {
  interval <- as.numeric(interval)
  if (length(interval) != 2L || any(!is.finite(interval))) {
    return(list(boundary = TRUE, message = "nonfinite_interval"))
  }
  if (
    transformation %in%
      c("exp", "derived_group_scale") &&
      min(interval) <= sd_boundary
  ) {
    return(list(boundary = TRUE, message = "near_sd_boundary"))
  }
  if (
    transformation %in%
      c("tanh", "rho12_tanh", "unstructured_corr") &&
      max(abs(interval)) >= correlation_boundary
  ) {
    return(list(boundary = TRUE, message = "near_correlation_boundary"))
  }
  list(boundary = FALSE, message = "ok")
}

profile_transform_interval <- function(interval, target) {
  switch(
    target$transformation,
    linear_predictor = interval,
    exp = exp(interval),
    tanh = 0.999999 * tanh(interval),
    rho12_tanh = rho_response(interval),
    interval
  )
}

profile_transform_newdata_interval <- function(interval, object, dpar, offset) {
  eta_interval <- interval + offset
  switch(
    drm_dpar_link(object, dpar),
    log = exp(eta_interval),
    atanh_guarded = rho_response(eta_interval),
    atanh_re_guarded = rho_response(eta_interval, guard = 0.999999),
    cli::cli_abort(
      "Internal error: no response-scale profile transformation for {.val {dpar}}."
    )
  )
}

profile_newdata_transformation <- function(object, dpar) {
  switch(
    drm_dpar_link(object, dpar),
    log = "exp",
    atanh_guarded = "rho12_tanh",
    atanh_re_guarded = "random_effect_correlation_tanh",
    "unknown"
  )
}

profile_registry_cor_targets <- function(object) {
  registry <- object$model$random$covariance_blocks
  if (
    !is.list(registry) ||
      is.null(registry$pairs) ||
      nrow(registry$pairs) == 0L
  ) {
    return(list())
  }

  pairs <- registry$pairs
  pair_is_fitted <- !is.na(pairs$tmb_parameter) & !is.na(pairs$tmb_index)
  pairs <- pairs[pair_is_fitted, , drop = FALSE]
  if (nrow(pairs) == 0L) {
    return(list())
  }

  out <- lapply(seq_len(nrow(pairs)), function(i) {
    pair <- pairs[i, , drop = FALSE]
    dpar <- covariance_block_corpars_key(pair$tmb_parameter[[1L]])
    values <- object$corpars[[dpar]]
    index <- pair$tmb_index[[1L]]
    if (random_effect_correlation_is_modelled(object, dpar, index)) {
      return(NULL)
    }
    if (is.null(values) || index < 1L || index > length(values)) {
      cli::cli_abort(
        "Internal error: covariance-block registry pair has no profile target correlation."
      )
    }
    estimate <- unname(values[[index]])
    is_unstructured_corr <- identical(pair$tmb_parameter[[1L]], "theta_re_cov")
    status <- if (is_unstructured_corr) {
      list(
        profile_ready = FALSE,
        profile_note = "derived_unstructured_correlation"
      )
    } else {
      profile_direct_target_status(
        object,
        pair$tmb_parameter[[1L]],
        index
      )
    }
    new_profile_target_row(
      parm = paste0("cor:", dpar, ":", pair$parameter[[1L]]),
      target_class = "random-effect-correlation",
      dpar = dpar,
      term = pair$parameter[[1L]],
      tmb_parameter = pair$tmb_parameter[[1L]],
      index = index,
      estimate = estimate,
      link_estimate = if (is_unstructured_corr) {
        NA_real_
      } else {
        guarded_correlation_link(estimate, guard = 0.999999)
      },
      scale = "response",
      transformation = if (is_unstructured_corr) {
        "unstructured_corr"
      } else {
        "tanh"
      },
      target_type = if (is_unstructured_corr) "derived" else "direct",
      profile_ready = status$profile_ready,
      profile_note = status$profile_note
    )
  })
  out[!vapply(out, is.null, logical(1L))]
}

new_profile_target_row <- function(
  parm,
  target_class,
  dpar,
  term,
  tmb_parameter,
  index,
  estimate,
  link_estimate,
  scale,
  transformation,
  target_type,
  profile_ready,
  profile_note
) {
  data.frame(
    parm = parm,
    target_class = target_class,
    dpar = dpar,
    term = term,
    tmb_parameter = tmb_parameter,
    index = as.integer(index),
    estimate = as.numeric(estimate),
    link_estimate = as.numeric(link_estimate),
    scale = scale,
    transformation = transformation,
    target_type = target_type,
    profile_ready = as.logical(profile_ready),
    profile_note = profile_note,
    stringsAsFactors = FALSE
  )
}

empty_profile_targets <- function() {
  data.frame(
    parm = character(),
    target_class = character(),
    dpar = character(),
    term = character(),
    tmb_parameter = character(),
    index = integer(),
    estimate = numeric(),
    link_estimate = numeric(),
    scale = character(),
    transformation = character(),
    target_type = character(),
    profile_ready = logical(),
    profile_note = character(),
    stringsAsFactors = FALSE
  )
}

validate_profile_targets <- function(targets) {
  expected <- names(empty_profile_targets())
  if (!identical(names(targets), expected)) {
    cli::cli_abort("Internal error: profile target columns are inconsistent.")
  }
  if (nrow(targets) == 0L) {
    return(targets)
  }
  allowed_types <- c("direct", "derived")
  bad_type <- !targets$target_type %in% allowed_types
  if (any(bad_type)) {
    cli::cli_abort(
      "Internal error: profile target type {.val {targets$target_type[bad_type][[1L]]}} is not supported."
    )
  }
  allowed_notes <- c(
    "ready",
    "tmb_object_required",
    "missing_tmb_parameter",
    "derived_target",
    "derived_unstructured_correlation"
  )
  bad_note <- !targets$profile_note %in% allowed_notes
  if (any(bad_note)) {
    cli::cli_abort(
      "Internal error: profile target note {.val {targets$profile_note[bad_note][[1L]]}} is not supported."
    )
  }
  allowed_transformations <- c(
    "linear_predictor",
    "exp",
    "rho12_tanh",
    "tanh",
    "variance_ratio",
    "derived_group_scale",
    "unstructured_corr",
    "ordered_cutpoint"
  )
  bad_transformation <- !targets$transformation %in% allowed_transformations
  if (any(bad_transformation)) {
    cli::cli_abort(
      "Internal error: profile target transformation {.val {targets$transformation[bad_transformation][[1L]]}} is not supported."
    )
  }
  if (any(targets$profile_ready & targets$target_type != "direct")) {
    cli::cli_abort("Internal error: derived profile targets cannot be ready.")
  }
  duplicate <- duplicated(targets$parm)
  if (any(duplicate)) {
    cli::cli_abort(
      "Internal error: duplicate profile target name {.val {targets$parm[duplicate][[1L]]}}."
    )
  }
  targets
}

profile_fixef_internal <- function(dpar) {
  if (
    any(startsWith(
      dpar,
      c("sd(", "sd1(", "sd2(", "sd_phylo(", "sd_phylo1(", "sd_phylo2(")
    ))
  ) {
    return("beta_sd_mu")
  }
  if (identical(dpar, "hu")) {
    return("beta_zi")
  }
  if (startsWith(dpar, "corpair(")) {
    return("beta_cor_mu")
  }
  paste0("beta_", dpar)
}

profile_sd_internal <- function(dpar, term) {
  if (identical(dpar, "mu") && grepl("phylo\\(|spatial\\(", term)) {
    return("log_sd_phylo")
  }
  if (dpar %in% c("mu", "sigma")) {
    return(paste0("log_sd_", dpar))
  }
  NA_character_
}

profile_cor_internal <- function(dpar) {
  if (identical(dpar, "mu")) {
    return("eta_cor_mu")
  }
  paste0("eta_cor_", dpar)
}

profile_internal_is_active <- function(object, internal, index) {
  if (is.na(internal) || is.na(index)) {
    return(FALSE)
  }
  if (is.null(object$obj)) {
    return(FALSE)
  }
  sum(names(object$opt$par) == internal) >= index
}

profile_direct_target_status <- function(object, internal, index) {
  ready <- profile_internal_is_active(object, internal, index)
  list(
    profile_ready = ready,
    profile_note = profile_ready_note(
      ready,
      object = object,
      internal = internal,
      index = index
    )
  )
}

profile_ready_note <- function(
  profile_ready,
  object = NULL,
  internal = NA,
  index = NA
) {
  if (isTRUE(profile_ready)) {
    return("ready")
  }
  if (!is.null(object) && is.null(object$obj)) {
    return("tmb_object_required")
  }
  "missing_tmb_parameter"
}

profile_match_targets <- function(targets, parm) {
  if (missing(parm) || is.null(parm)) {
    cli::cli_abort(c(
      "Profile targets must be supplied explicitly.",
      i = "Use {.code drmTMB:::drm_profile_targets(fit)$parm} to inspect available targets."
    ))
  }
  if (!is.character(parm)) {
    cli::cli_abort(
      "{.arg parm} must be a character vector of profile target names."
    )
  }
  index <- match(parm, targets$parm)
  missing_index <- is.na(index)
  if (any(missing_index)) {
    available <- paste(utils::head(targets$parm, 10L), collapse = ", ")
    cli::cli_abort(c(
      "Unknown profile target{?s}: {.val {parm[missing_index]}}.",
      i = "First available targets: {available}."
    ))
  }
  targets[index, , drop = FALSE]
}

profile_match_confint_targets <- function(targets, parm, fixed_only) {
  if (is.null(parm)) {
    return(targets)
  }
  if (is.numeric(parm)) {
    if (
      any(!is.finite(parm)) ||
        any(parm != as.integer(parm)) ||
        any(parm < 1L | parm > nrow(targets))
    ) {
      cli::cli_abort(
        "{.arg parm} numeric values must select rows from the available confidence-interval targets."
      )
    }
    return(targets[as.integer(parm), , drop = FALSE])
  }
  if (!is.character(parm)) {
    cli::cli_abort(
      "{.arg parm} must be a character or integer vector of confidence-interval targets."
    )
  }

  aliases <- paste0(targets$dpar, ":", targets$term)
  index <- match(parm, targets$parm)
  missing_index <- is.na(index)
  if (any(missing_index)) {
    index[missing_index] <- match(parm[missing_index], aliases)
  }
  missing_index <- is.na(index)
  if (any(missing_index)) {
    available <- paste(utils::head(targets$parm, 10L), collapse = ", ")
    detail <- if (fixed_only) {
      "Use coefficient labels from summary(fit) or full names such as {.val fixef:mu:x}."
    } else {
      "Use full profile target names such as {.val fixef:mu:x}."
    }
    cli::cli_abort(c(
      "Unknown confidence-interval target{?s}: {.val {parm[missing_index]}}.",
      i = detail,
      i = "First available targets: {available}."
    ))
  }
  targets[index, , drop = FALSE]
}

profile_newdata_dpar <- function(object, parm) {
  if (is.null(parm)) {
    cli::cli_abort(c(
      "{.arg parm} must name one distributional parameter when {.arg newdata} is supplied.",
      i = "Use {.val sigma}, {.val sigma1}, {.val sigma2}, {.val rho12}, or a fitted {.fn corpair} dpar."
    ))
  }
  if (!is.character(parm) || length(parm) != 1L || is.na(parm)) {
    cli::cli_abort(
      "{.arg parm} must be one distributional-parameter name when {.arg newdata} is supplied."
    )
  }

  scale_or_residual <- intersect(
    c("sigma", "sigma1", "sigma2", "rho12"),
    names(object$coefficients)
  )
  scale_or_residual <- scale_or_residual[vapply(
    scale_or_residual,
    function(dpar) drm_dpar_link(object, dpar) %in% c("log", "atanh_guarded"),
    logical(1)
  )]
  corpair <- names(object$coefficients)[
    startsWith(names(object$coefficients), "corpair(")
  ]
  corpair <- corpair[vapply(
    corpair,
    function(dpar) identical(drm_dpar_link(object, dpar), "atanh_re_guarded"),
    logical(1)
  )]
  supported <- c(scale_or_residual, corpair)
  if (!parm %in% supported) {
    available <- if (length(supported)) {
      paste(supported, collapse = ", ")
    } else {
      "none for this fitted model"
    }
    cli::cli_abort(c(
      "Response-scale profile intervals with {.arg newdata} are implemented for fitted scale, residual-correlation, and q2 ordinary or phylogenetic {.fn corpair} parameters.",
      i = "Requested {.val {parm}}; available for this fit: {available}."
    ))
  }
  parm
}

profile_newdata_parm_labels <- function(dpar, newdata) {
  labels <- row.names(newdata)
  default_labels <- as.character(seq_len(nrow(newdata)))
  if (
    is.null(labels) ||
      anyNA(labels) ||
      any(!nzchar(labels)) ||
      identical(labels, default_labels)
  ) {
    labels <- default_labels
  }
  paste0(dpar, "[", labels, "]")
}

profile_target_positions <- function(targets, labels) {
  aliases <- paste0(targets$dpar, ":", targets$term)
  positions <- match(aliases, labels)
  if (anyNA(positions)) {
    cli::cli_abort(
      "Internal error: confidence-interval targets do not match fitted coefficient labels."
    )
  }
  positions
}

profile_lincomb <- function(object, target) {
  par_names <- names(object$opt$par)
  positions <- which(par_names == target$tmb_parameter)
  if (length(positions) < target$index) {
    cli::cli_abort(c(
      "Profile target {.val {target$parm}} cannot be mapped to optimized parameters.",
      i = "Expected index {target$index} in TMB parameter {.val {target$tmb_parameter}}."
    ))
  }
  out <- rep(0, length(object$opt$par))
  out[positions[[target$index]]] <- 1
  out
}

validate_profile_level <- function(level) {
  if (
    !is.numeric(level) ||
      length(level) != 1L ||
      !is.finite(level) ||
      level <= 0 ||
      level >= 1
  ) {
    cli::cli_abort("{.arg level} must be one number between 0 and 1.")
  }
}
