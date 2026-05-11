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

drm_profile_target_confint <- function(
  object,
  target,
  level,
  trace,
  ...
) {
  if (!identical(target$target_class, "fixed-effect")) {
    cli::cli_abort(c(
      "Only fixed-effect profile targets are implemented in this slice.",
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

  data.frame(
    parm = target$parm,
    level = level,
    lower = unname(ci[1L, "lower"]),
    upper = unname(ci[1L, "upper"]),
    scale = target$scale,
    transformation = target$transformation,
    tmb_parameter = target$tmb_parameter,
    index = target$index,
    method = "profile",
    stringsAsFactors = FALSE
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
