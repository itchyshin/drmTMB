#' Confidence intervals for fitted model parameters
#'
#' `confint()` returns confidence intervals for a fitted `drmTMB` model. Wald
#' intervals are fast and are returned for fixed-effect coefficients by default.
#' Profile-likelihood intervals are slower because nuisance parameters are
#' re-optimized; this first public profile path supports explicit fixed-effect,
#' random-effect standard-deviation, random-effect correlation, and constant
#' residual-correlation targets.
#'
#' Target names follow the profile target namespace. For fixed effects, use
#' names such as `"fixef:mu:x"`, `"fixef:sigma:(Intercept)"`, or
#' `"fixef:rho12:w"`. Compact coefficient labels from `summary(fit)`, such as
#' `"mu:x"`, are also accepted. Random-effect SD intervals are reported on the
#' SD scale, and random-effect correlation intervals are reported on the
#' correlation scale. For bivariate Gaussian fits with constant residual
#' correlation, `parm = "rho12"` profiles the residual correlation and reports
#' the interval on the response correlation scale.
#'
#' @param object A `drmTMB` fit.
#' @param parm Optional character or integer vector selecting interval targets.
#'   `NULL` selects all fixed effects for Wald intervals. Profile intervals
#'   require explicit target names.
#' @param level Confidence level.
#' @param method Interval method: `"wald"` or `"profile"`.
#' @param trace Logical; passed to [TMB::tmbprofile()] for profile intervals.
#' @param ... Additional arguments passed to [TMB::tmbprofile()] when
#'   `method = "profile"`.
#'
#' @return A data frame with columns `parm`, `level`, `lower`, `upper`,
#'   `scale`, `transformation`, `tmb_parameter`, `index`, and `method`.
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
  trace = FALSE,
  ...
) {
  method <- match.arg(method)
  validate_profile_level(level)

  if (identical(method, "wald")) {
    dots <- list(...)
    if (length(dots) > 0L) {
      cli::cli_abort(
        "Additional arguments in {.arg ...} are only used when {.code method = \"profile\"}."
      )
    }
    return(drm_wald_confint(object, parm = parm, level = level))
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
      profile_ready <- profile_internal_is_active(
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
        profile_ready = profile_ready,
        profile_note = profile_ready_note(profile_ready)
      )
    }))
  }

  if ("rho12" %in% names(object$coefficients)) {
    beta <- object$coefficients$rho12
    if (length(beta) == 1L && identical(names(beta), "(Intercept)")) {
      profile_ready <- profile_internal_is_active(object, "beta_rho12", 1L)
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
        profile_ready = profile_ready,
        profile_note = profile_ready_note(profile_ready)
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
      profile_ready <- is_direct &&
        profile_internal_is_active(object, internal, index)
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
        profile_ready = profile_ready,
        profile_note = if (is_direct) {
          profile_ready_note(profile_ready)
        } else {
          "derived_target"
        }
      )))
    }
  }

  for (dpar in names(object$corpars)) {
    values <- object$corpars[[dpar]]
    internal <- profile_cor_internal(dpar)
    indices <- next_indices(internal, length(values))
    add_rows(lapply(seq_along(values), function(i) {
      profile_ready <- profile_internal_is_active(
        object,
        internal,
        indices[[i]]
      )
      new_profile_target_row(
        parm = paste0("cor:", dpar, ":", names(values)[[i]]),
        target_class = "random-effect-correlation",
        dpar = dpar,
        term = names(values)[[i]],
        tmb_parameter = internal,
        index = indices[[i]],
        estimate = unname(values[[i]]),
        link_estimate = guarded_correlation_link(
          unname(values[[i]]),
          guard = 0.999999
        ),
        scale = "response",
        transformation = "tanh",
        target_type = "direct",
        profile_ready = profile_ready,
        profile_note = profile_ready_note(profile_ready)
      )
    }))
  }

  if (!is.null(object$ordinal)) {
    theta <- object$ordinal$theta_raw
    internal <- "theta_ord"
    indices <- next_indices(internal, length(theta))
    add_rows(lapply(seq_along(theta), function(i) {
      profile_ready <- profile_internal_is_active(
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
        profile_ready = profile_ready,
        profile_note = profile_ready_note(profile_ready)
      )
    }))
  }

  out <- if (length(rows)) {
    do.call(rbind, rows)
  } else {
    empty_profile_targets()
  }
  row.names(out) <- NULL
  out
}

drm_profile_confint <- function(
  object,
  parm,
  level = 0.95,
  trace = FALSE,
  ...
) {
  validate_profile_level(level)
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
    "random-effect-sd",
    "random-effect-correlation",
    "residual-correlation"
  )
  if (!target$target_class %in% implemented_classes) {
    cli::cli_abort(c(
      "Profile intervals are implemented for direct fixed-effect, random-effect SD, random-effect correlation, and constant residual-correlation targets.",
      i = "Requested {.val {target$parm}} has target class {.val {target$target_class}}."
    ))
  }
  if (!isTRUE(target$profile_ready)) {
    cli::cli_abort(c(
      "Profile target {.val {target$parm}} is not ready for direct profiling.",
      i = "Inventory note: {.val {target$profile_note}}."
    ))
  }

  lincomb <- profile_lincomb(object, target)
  prof <- TMB::tmbprofile(
    obj = object$obj,
    name = target$parm,
    lincomb = lincomb,
    trace = trace,
    ...
  )
  ci <- stats::confint(prof, level = level)
  interval <- profile_transform_interval(
    c(unname(ci[1L, "lower"]), unname(ci[1L, "upper"])),
    target
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
    stringsAsFactors = FALSE
  )
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

profile_fixef_internal <- function(dpar) {
  if (startsWith(dpar, "sd(")) {
    return("beta_sd_mu")
  }
  if (identical(dpar, "hu")) {
    return("beta_zi")
  }
  paste0("beta_", dpar)
}

profile_sd_internal <- function(dpar, term) {
  if (identical(dpar, "mu") && startsWith(term, "phylo(")) {
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
  sum(names(object$opt$par) == internal) >= index
}

profile_ready_note <- function(profile_ready) {
  if (isTRUE(profile_ready)) {
    return("ready")
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
