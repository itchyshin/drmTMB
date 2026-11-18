#' @title Simulate from a fitted model
#'
#' @description
#' Julia-engine Binomial fits with predictor-dependent SDs support marginal
#' simulation for independent ordinary random intercepts, coefficient-specific
#' SDs in one correlated ordinary block, and selected structured effects.
#' Gamma fits support complete-data animal intercept SDs
#' and an animal intercept-plus-numeric-slope model with separate
#' coefficient-specific SD formulas. Binomial animal intercept-plus-slope
#' blocks with separate coefficient-specific SD formulas use the fitted animal
#' covariance and coefficient correlation for marginal simulation. For both
#' Gamma routes, simulation uses
#' the supplied relationship matrix `A` at its raw scale, as the Julia fitter
#' and native TMB do, including when `A` has a non-unit diagonal. The
#' Julia Laplace route integrates these random effects and does not return
#' conditional modes, so `re.form = NULL` is refused.
#' Structured simulation uses the saved covariance and its fitted scale. A
#' fixed-coordinate Binomial spatial intercept or slope uses the same native
#' fixed-range covariance passed through the Julia related-matrix route.
#' Binomial animal intercept may be combined with one independent ordinary
#' random intercept when both have matching SD formulas; other combinations
#' of structured and ordinary effects are refused.
#' These routes require complete data and location-side SD targets.
#'
#' @rdname simulate.drmTMB
#' @export
simulate.drmTMB_julia <- function(
  object,
  nsim = 1,
  seed = NULL,
  re.form = NA,
  ...
) {
  if (!base::missing(re.form)) {
    drm_simulate_re_form_semantics_message()
  }
  marginal <- drm_simulate_re_form_marginal(re.form)
  if (!inherits(object, "drmTMB_julia")) {
    cli::cli_abort("{.arg object} must be a Julia-engine drmTMB fit.")
  }
  if (!identical(object$model$model_type, "binomial")) {
    if (drm_julia_simulation_has_random_terms(object$formula)) {
      if (identical(object$model$model_type, "gamma")) {
        gamma_spec <- drm_julia_gamma_animal_sd_simulation_spec(object)
        if (!is.null(gamma_spec)) {
          return(drm_julia_simulate_gamma_animal_sd(
            object = object,
            spec = gamma_spec,
            nsim = nsim,
            seed = seed,
            marginal = marginal
          ))
        }
      }
      if (identical(object$model$model_type, "nbinom2")) {
        nb2_spec <- drm_julia_nbinom2_animal_sd_slope_simulation_spec(object)
        if (!is.null(nb2_spec)) {
          return(drm_julia_simulate_nbinom2_animal_sd_slope(
            object = object,
            spec = nb2_spec,
            nsim = nsim,
            seed = seed,
            marginal = marginal
          ))
        }
      }
      cli::cli_abort(c(
        "Marginal simulation is not implemented for this Julia random-effect model.",
        "i" = "The current routes are the documented Binomial SD cases, complete-data Gamma animal intercept or intercept-plus-slope SD models, and the NB2 animal slope-only SD model."
      ))
    }
    if (base::missing(re.form)) {
      return(simulate.drmTMB(object, nsim = nsim, seed = seed, ...))
    }
    return(simulate.drmTMB(
      object, nsim = nsim, seed = seed, re.form = re.form, ...
    ))
  }
  spec <- drm_julia_binomial_sd_simulation_spec(object)
  if (is.null(spec$components)) {
    # Fixed-effect Julia fits use the established family simulator.
    if (base::missing(re.form)) {
      return(simulate.drmTMB(object, nsim = nsim, seed = seed, ...))
    }
    return(simulate.drmTMB(
      object, nsim = nsim, seed = seed, re.form = re.form, ...
    ))
  }
  if (!marginal) {
    cli::cli_abort(c(
      "Conditional simulation is unavailable for this Julia Binomial fit.",
      "x" = "DRM.jl's non-Gaussian Laplace route integrates random effects and does not retain conditional modes.",
      "i" = "Use the default marginal simulation, {.code re.form = NA}."
    ))
  }
  if (length(nsim) != 1L || is.na(nsim) || nsim < 1L ||
      nsim != as.integer(nsim)) {
    cli::cli_abort("{.arg nsim} must be one positive whole number.")
  }
  nsim <- as.integer(nsim)

  if (!is.null(seed)) {
    had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    old_seed <- if (had_seed) {
      get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    } else {
      NULL
    }
    on.exit(
      {
        if (had_seed) {
          assign(".Random.seed", old_seed, envir = .GlobalEnv)
        } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
          rm(".Random.seed", envir = .GlobalEnv)
        }
      },
      add = TRUE
    )
    set.seed(seed)
  }

  data <- object$data
  fixed_eta <- predict(
    object, newdata = data, dpar = "mu", type = "link"
  )
  trials <- object$model$trials
  if (length(fixed_eta) != nrow(data) || length(trials) != nrow(data)) {
    cli::cli_abort(
      "The Julia Binomial bridge did not retain row-aligned predictors and trial denominators for simulation."
    )
  }
  draws <- replicate(nsim, {
    eta <- as.numeric(fixed_eta)
    for (component in spec$components) {
      if (!is.null(component$members)) {
        group_value <- as.character(data[[component$group]])
        group_index <- match(group_value, component$groups)
        q <- length(component$members)
        group_sd <- do.call(rbind, lapply(component$members, function(member) {
          dpar <- as.character(drm_julia_sd_public_dpar(member$target))[[1L]]
          value <- predict(object, dpar = dpar)
          drm_julia_align_group_sd(
            value, component$groups, dpar, component$group
          )
        }))
        if (!is.null(component$group_covariance)) {
          random_effects <- drm_julia_draw_structured_correlated_effects(
            component$correlation, component$group_covariance, group_sd
          )
        } else {
          random_effects <- drm_julia_draw_correlated_random_effects(
            component$correlation, group_sd
          )
        }
        for (j in seq_len(q)) {
          member <- component$members[[j]]
          eta <- eta + member$loading * random_effects[j, group_index]
        }
        next
      }
      group_value <- as.character(data[[component$group]])
      groups <- unique(group_value)
      target_dpar <- as.character(
        drm_julia_sd_public_dpar(component$target)
      )[[1L]]
      sd_value <- predict(object, dpar = target_dpar)
      expected_names <- groups
      if (!identical(names(sd_value), expected_names)) {
        cli::cli_abort(
          "The Julia bridge SD predictions do not align with grouping levels for {.field {component$group}}."
        )
      }
      group_index <- match(group_value, groups)
      if (!is.null(component$covariance)) {
        latent <- as.vector(
          t(chol(component$covariance)) %*% stats::rnorm(length(groups))
        )
        latent <- as.numeric(sd_value) * latent
      } else {
        latent <- stats::rnorm(length(groups), sd = as.numeric(sd_value))
      }
      loading <- component$loading
      if (is.null(loading)) loading <- rep(1, nrow(data))
      eta <- eta + loading * latent[group_index]
    }
    probability <- drm_inverse_link(object, "mu", eta)
    stats::rbinom(nrow(data), size = trials, prob = probability)
  })
  draws <- as.data.frame(draws)
  names(draws) <- paste0("sim_", seq_len(nsim))
  draws[] <- lapply(draws, function(col) drm_mask_missing_response_values(object, col))
  draws
}

drm_julia_draw_correlated_random_effects <- function(correlation, group_sd) {
  correlation <- as.matrix(correlation)
  group_sd <- as.matrix(group_sd)
  q <- nrow(correlation)
  if (q < 2L || ncol(correlation) != q || nrow(group_sd) != q ||
      ncol(group_sd) < 1L || any(!is.finite(group_sd)) ||
      any(group_sd <= 0) || any(!is.finite(correlation)) ||
      !isTRUE(all.equal(correlation, t(correlation))) ||
      any(abs(correlation) > 1) ||
      inherits(tryCatch(chol(correlation), error = function(error) error),
               "error")) {
    cli::cli_abort(
      "Correlated random-effect simulation requires a positive-definite correlation matrix and a positive finite SD for each coefficient and group."
    )
  }
  standard_normal <- matrix(stats::rnorm(q * ncol(group_sd)), nrow = q)
  t(chol(correlation)) %*% standard_normal * group_sd
}

drm_julia_draw_structured_correlated_effects <- function(
  correlation, group_covariance, group_sd
) {
  correlation <- as.matrix(correlation)
  group_covariance <- as.matrix(group_covariance)
  group_sd <- as.matrix(group_sd)
  q <- nrow(correlation)
  n_group <- nrow(group_covariance)
  invalid <- q < 2L || ncol(correlation) != q ||
    nrow(group_sd) != q || ncol(group_sd) != n_group ||
    ncol(group_covariance) != n_group || any(!is.finite(group_sd)) ||
    any(group_sd <= 0) || any(!is.finite(correlation)) ||
    any(!is.finite(group_covariance)) ||
    !isTRUE(all.equal(correlation, t(correlation))) ||
    !isTRUE(all.equal(group_covariance, t(group_covariance))) ||
    any(abs(correlation) > 1) || any(diag(group_covariance) <= 0) ||
    inherits(tryCatch(chol(correlation), error = function(error) error),
             "error") ||
    inherits(tryCatch(chol(group_covariance), error = function(error) error),
             "error")
  if (invalid) {
    cli::cli_abort(
      "Structured correlated random-effect simulation requires positive-definite coefficient and group covariance matrices and one positive finite SD per coefficient and group."
    )
  }
  standard_normal <- matrix(stats::rnorm(q * n_group), nrow = q)
  (t(chol(correlation)) %*% standard_normal %*% chol(group_covariance)) *
    group_sd
}

drm_julia_align_group_sd <- function(value, groups, dpar, group) {
  if (!is.numeric(value) || length(value) != length(groups) ||
      any(!is.finite(value)) || any(value <= 0)) {
    cli::cli_abort(
      "The Julia SD predictions for {.field {group}} must contain one positive finite value per group."
    )
  }
  value_names <- names(value)
  if (!is.null(value_names)) {
    if (setequal(value_names, groups)) {
      value <- value[groups]
    } else {
      prefix <- paste0(dpar, ":")
      group_names <- ifelse(startsWith(value_names, prefix),
                            substring(value_names, nchar(prefix) + 1L),
                            value_names)
      if (!setequal(group_names, groups)) {
        cli::cli_abort(
          "The Julia SD predictions for {.field {group}} do not match the fitted group labels."
        )
      }
      value <- value[match(paste0(prefix, groups), value_names)]
      if (anyNA(value)) {
        cli::cli_abort(
          "The Julia SD predictions for {.field {group}} could not be aligned to fitted groups."
        )
      }
    }
  }
  as.numeric(value)
}

drm_julia_gamma_animal_sd_simulation_spec <- function(object) {
  formula <- object$formula
  slope_route <- drm_julia_gamma_animal_sd_slope_route_admitted(
    formula, "gamma"
  )
  intercept_route <- drm_julia_gamma_animal_sd_intercept_simulation_route_admitted(
    formula
  )
  if (!slope_route && !intercept_route) {
    return(NULL)
  }
  terms <- drm_julia_collect_structured_terms(formula)
  if (length(terms) != 1L) return(NULL)
  term <- terms[[1L]]
  data <- object$data
  group <- term$group
  if (!is.data.frame(data) || !group %in% names(data) || anyNA(data[[group]])) {
    cli::cli_abort(
      "Julia Gamma animal simulation requires complete stored grouping values."
    )
  }
  groups <- unique(as.character(data[[group]]))
  payload <- object$bridge_payload
  covariance <- payload$matrix
  if (!identical(payload$kwarg, "A") || is.null(covariance)) {
    cli::cli_abort(
      "The Julia Gamma animal fit does not retain the supplied relationship matrix needed for simulation."
    )
  }
  covariance <- as.matrix(covariance)
  # The bridge aligns labelled matrices to first-appearance group order before
  # sending them to Julia, then intentionally removes dimnames for the Julia
  # call. Recheck dimensions and covariance validity here; labels are no longer
  # present in the retained payload.
  if (!identical(dim(covariance), c(length(groups), length(groups))) ||
      any(!is.finite(covariance)) ||
      !isTRUE(all.equal(covariance, t(covariance))) ||
      any(diag(covariance) <= 0) ||
      inherits(tryCatch(chol(covariance), error = function(e) e), "error")) {
    cli::cli_abort(
      "The saved Julia Gamma animal relationship matrix is invalid or not aligned with the fitted group order."
    )
  }
  # Julia Gamma animal fits retain the supplied covariance scale, matching
  # native TMB. The fitted SD predictions multiply this covariance, so keep
  # the raw matrix for marginal simulation as well.

  sd_entries <- Filter(function(entry) {
    !is.null(entry$lhs) && is_random_scale_lhs(entry$lhs)
  }, formula$entries)
  expected_sd_entries <- if (slope_route) 2L else 1L
  if (length(sd_entries) != expected_sd_entries) return(NULL)
  targets <- lapply(sd_entries, function(entry) parse_sd_lhs(entry$lhs))
  components <- lapply(targets, function(target) {
    coef <- target$target_coef
    loading <- if (is.na(coef) || identical(coef, "(Intercept)")) {
      rep(1, nrow(data))
    } else {
      value <- data[[coef]]
      if (!is.numeric(value) || length(value) != nrow(data) ||
          any(!is.finite(value))) {
        cli::cli_abort(
          "Julia Gamma animal SD simulation requires finite numeric slope values for {.field {coef}}."
        )
      }
      as.numeric(value)
    }
    list(target = target, loading = loading)
  })
  list(
    group = group,
    groups = groups,
    group_index = match(as.character(data[[group]]), groups),
    covariance = covariance,
    components = components
  )
}

drm_julia_gamma_animal_sd_intercept_simulation_route_admitted <- function(
  formula
) {
  entries <- formula$entries
  dpars <- vapply(entries, `[[`, character(1L), "dpar")
  sd_idx <- which(vapply(entries, function(entry) {
    !is.null(entry$lhs) && is_random_scale_lhs(entry$lhs)
  }, logical(1L)))
  mu_idx <- which(dpars == "mu")
  sigma_idx <- which(dpars == "sigma")
  if (length(sd_idx) != 1L || length(mu_idx) != 1L ||
      length(sigma_idx) != 1L || length(entries) != 3L ||
      !identical(entries[[sigma_idx]]$rhs, 1)) {
    return(FALSE)
  }
  target <- tryCatch(parse_sd_lhs(entries[[sd_idx]]$lhs), error = function(e) NULL)
  if (is.null(target) || !identical(target$fun, "sd_animal") ||
      !identical(target$level, "animal") ||
      !(is.na(target$target_dpar) || identical(target$target_dpar, "mu")) ||
      !(is.na(target$target_coef) || identical(target$target_coef, "(Intercept)")) ||
      !is.na(target$target_block)) {
    return(FALSE)
  }
  terms <- drm_julia_collect_structured_terms(formula)
  length(terms) == 1L &&
    identical(terms[[1L]]$type, "animal") &&
    identical(terms[[1L]]$dpar, "mu") &&
    identical(terms[[1L]]$group, target$group) &&
    identical(terms[[1L]]$coef_names, "(Intercept)") &&
    length(entries[[mu_idx]]$structured) == 1L &&
    length(extract_random_mu_terms(entries[[mu_idx]]$rhs, "mu")$terms) == 0L
}

drm_julia_simulate_gamma_animal_sd <- function(
  object, spec, nsim, seed, marginal
) {
  if (!marginal) {
    cli::cli_abort(c(
      "Conditional simulation is unavailable for this Julia Gamma fit.",
      "x" = "The Laplace fit integrates random effects and does not retain conditional modes.",
      "i" = "Use the default marginal simulation or {.code re.form = NA}."
    ))
  }
  if (length(nsim) != 1L || is.na(nsim) || nsim < 1L ||
      nsim != as.integer(nsim)) {
    cli::cli_abort("{.arg nsim} must be one positive whole number.")
  }
  nsim <- as.integer(nsim)
  if (!is.null(seed)) {
    had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    old_seed <- if (had_seed) {
      get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    } else {
      NULL
    }
    on.exit({
      if (had_seed) {
        assign(".Random.seed", old_seed, envir = .GlobalEnv)
      } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
        rm(".Random.seed", envir = .GlobalEnv)
      }
    }, add = TRUE)
    set.seed(seed)
  }

  data <- object$data
  eta_fixed <- as.numeric(predict(
    object, newdata = data, dpar = "mu", type = "link"
  ))
  sigma <- as.numeric(predict(
    object, newdata = data, dpar = "sigma", type = "response"
  ))
  if (length(eta_fixed) != nrow(data) || length(sigma) != nrow(data)) {
    cli::cli_abort(
      "The Julia Gamma bridge did not retain row-aligned mean and scale predictors for simulation."
    )
  }
  chol_covariance <- t(chol(spec$covariance))
  draws <- replicate(nsim, {
    eta <- eta_fixed
    for (component in spec$components) {
      dpar <- as.character(drm_julia_sd_public_dpar(component$target))[[1L]]
      sd_value <- predict(object, dpar = dpar)
      expected_names <- paste0(dpar, ":", spec$groups)
      if (!identical(names(sd_value), expected_names)) {
        cli::cli_abort(
          "Julia Gamma SD predictions do not align with animal groups for {.field {component$target$target_coef}}."
        )
      }
      latent <- as.vector(
        chol_covariance %*% stats::rnorm(length(spec$groups))
      )
      group_sd <- as.numeric(sd_value)[spec$group_index]
      eta <- eta + component$loading * group_sd * latent[spec$group_index]
    }
    mu <- drm_inverse_link(object, "mu", eta)
    gamma_parameters <- drm_gamma_shape_scale(mu, sigma)
    stats::rgamma(
      nrow(data),
      shape = gamma_parameters$shape,
      scale = gamma_parameters$scale
    )
  })
  draws <- as.data.frame(draws)
  names(draws) <- paste0("sim_", seq_len(nsim))
  draws[] <- lapply(draws, function(col) drm_mask_missing_response_values(object, col))
  draws
}

# NB2 animal slope-only SD fits (DRM.jl 61a6dcdbd; raw A). Marginal simulation
# draws u = chol(A) z, scales it by the fitted group SD, and adds x * u to the
# fixed linear predictor, as the Gamma animal route does. A only; the bridge
# refuses Ainv for NB2, so no other matrix form is retained.
drm_julia_nbinom2_animal_sd_slope_simulation_spec <- function(object) {
  formula <- object$formula
  if (!drm_julia_nbinom2_animal_sd_slope_route_admitted(formula)) {
    return(NULL)
  }
  terms <- drm_julia_collect_structured_terms(formula)
  if (length(terms) != 1L) return(NULL)
  term <- terms[[1L]]
  data <- object$data
  group <- term$group
  slope <- term$coef_names[[1L]]
  if (!is.data.frame(data) || !group %in% names(data) || anyNA(data[[group]])) {
    cli::cli_abort(
      "Julia NB2 animal simulation requires complete stored grouping values."
    )
  }
  loading <- data[[slope]]
  if (!is.numeric(loading) || length(loading) != nrow(data) ||
      any(!is.finite(loading))) {
    cli::cli_abort(
      "Julia NB2 animal SD simulation requires finite numeric slope values for {.field {slope}}."
    )
  }
  groups <- unique(as.character(data[[group]]))
  payload <- object$bridge_payload
  covariance <- payload$matrix
  if (!identical(payload$kwarg, "A") || is.null(covariance)) {
    cli::cli_abort(
      "The Julia NB2 animal fit does not retain the supplied relationship matrix needed for simulation."
    )
  }
  covariance <- as.matrix(covariance)
  if (!identical(dim(covariance), c(length(groups), length(groups))) ||
      any(!is.finite(covariance)) ||
      !isTRUE(all.equal(covariance, t(covariance))) ||
      any(diag(covariance) <= 0) ||
      inherits(tryCatch(chol(covariance), error = function(e) e), "error")) {
    cli::cli_abort(
      "The saved Julia NB2 animal relationship matrix is invalid or not aligned with the fitted group order."
    )
  }
  sd_entry <- Filter(function(entry) {
    !is.null(entry$lhs) && is_random_scale_lhs(entry$lhs)
  }, formula$entries)
  list(
    group = group,
    groups = groups,
    group_index = match(as.character(data[[group]]), groups),
    covariance = covariance,
    loading = as.numeric(loading),
    target = parse_sd_lhs(sd_entry[[1L]]$lhs)
  )
}

drm_julia_simulate_nbinom2_animal_sd_slope <- function(
  object, spec, nsim, seed, marginal
) {
  if (!marginal) {
    cli::cli_abort(c(
      "Conditional simulation is unavailable for this Julia NB2 fit.",
      "x" = "The Laplace fit integrates random effects and does not retain conditional modes.",
      "i" = "Use the default marginal simulation or {.code re.form = NA}."
    ))
  }
  if (length(nsim) != 1L || is.na(nsim) || nsim < 1L ||
      nsim != as.integer(nsim)) {
    cli::cli_abort("{.arg nsim} must be one positive whole number.")
  }
  nsim <- as.integer(nsim)
  if (!is.null(seed)) {
    had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    old_seed <- if (had_seed) {
      get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    } else {
      NULL
    }
    on.exit({
      if (had_seed) {
        assign(".Random.seed", old_seed, envir = .GlobalEnv)
      } else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
        rm(".Random.seed", envir = .GlobalEnv)
      }
    }, add = TRUE)
    set.seed(seed)
  }

  data <- object$data
  eta_fixed <- as.numeric(predict(
    object, newdata = data, dpar = "mu", type = "link"
  ))
  sigma <- as.numeric(predict(
    object, newdata = data, dpar = "sigma", type = "response"
  ))
  if (length(eta_fixed) != nrow(data) || length(sigma) != nrow(data)) {
    cli::cli_abort(
      "The Julia NB2 bridge did not retain row-aligned mean and dispersion predictors for simulation."
    )
  }
  dpar <- as.character(drm_julia_sd_public_dpar(spec$target))[[1L]]
  sd_value <- predict(object, dpar = dpar)
  # The single-target NB2 route returns group-named SD predictions; accept the
  # `dpar:group` spelling the multi-target routes use as well.
  if (!identical(names(sd_value), spec$groups) &&
      !identical(names(sd_value), paste0(dpar, ":", spec$groups))) {
    cli::cli_abort(
      "Julia NB2 SD predictions do not align with animal groups."
    )
  }
  group_sd <- as.numeric(sd_value)[spec$group_index]
  chol_covariance <- t(chol(spec$covariance))
  draws <- replicate(nsim, {
    latent <- as.vector(chol_covariance %*% stats::rnorm(length(spec$groups)))
    eta <- eta_fixed + spec$loading * group_sd * latent[spec$group_index]
    mu <- drm_inverse_link(object, "mu", eta)
    stats::rnbinom(nrow(data), size = drm_nbinom2_size(sigma), mu = mu)
  })
  draws <- as.data.frame(draws)
  names(draws) <- paste0("sim_", seq_len(nsim))
  draws[] <- lapply(draws, function(col) drm_mask_missing_response_values(object, col))
  draws
}

drm_julia_simulation_has_random_terms <- function(formula) {
  entries <- formula$entries
  if (!is.list(entries)) {
    return(FALSE)
  }
  any(vapply(entries, function(entry) {
    length(entry$structured) > 0L || any(vapply(
      flatten_plus_terms(entry$rhs), is_random_bar_call, logical(1L)
    ))
  }, logical(1L)))
}

drm_julia_binomial_sd_simulation_spec <- function(object) {
  entries <- object$formula$entries
  mu_entries <- Filter(function(entry) identical(entry$dpar, "mu"), entries)
  if (length(mu_entries) != 1L) {
    cli::cli_abort(
      "Julia Binomial SD simulation requires one location formula."
    )
  }
  terms <- flatten_plus_terms(mu_entries[[1L]]$rhs)
  bars <- Filter(is_random_bar_call, terms)
  structured_terms <- mu_entries[[1L]]$structured
  if (length(structured_terms) == 1L &&
      identical(structured_terms[[1L]]$type, "animal") &&
      drm_julia_binomial_animal_q2_sd_route_admitted(object$formula)) {
    return(list(components = list(
      drm_julia_binomial_animal_q2_sd_component(object, structured_terms[[1L]])
    )))
  }
  animal_iid_route <- length(structured_terms) == 1L &&
    identical(structured_terms[[1L]]$type, "animal") &&
    drm_julia_binomial_animal_iid_sd_route_admitted(object$formula)
  relmat_iid_route <- length(structured_terms) == 1L &&
    identical(structured_terms[[1L]]$type, "relmat") &&
    drm_julia_binomial_relmat_iid_sd_route_admitted(object$formula)
  phylo_iid_route <- length(structured_terms) == 1L &&
    identical(structured_terms[[1L]]$type, "phylo") &&
    drm_julia_binomial_phylo_ordinary_sd_route_admitted(object$formula)
  other_structured <- unlist(lapply(entries, function(entry) {
    if (identical(entry$dpar, "mu")) list() else entry$structured
  }), recursive = FALSE)
  if (length(structured_terms) > 0L || length(other_structured) > 0L) {
    if (length(structured_terms) != 1L || length(other_structured) > 0L ||
        (length(bars) > 0L && !animal_iid_route && !relmat_iid_route &&
          !phylo_iid_route)) {
      cli::cli_abort(c(
        "Julia Binomial SD simulation supports one structured random effect at a time.",
        "i" = "Other structured or ordinary random-effect combinations need a separately validated covariance draw."
      ))
    }
    term <- structured_terms[[1L]]
    provider <- term$type
    is_phylo <- identical(provider, "phylo")
    is_phylo_slope <- is_phylo &&
      drm_julia_binomial_phylo_sd_slope_route_admitted(
        object$formula, data = object$data
      )
    is_phylo_interaction <- identical(provider, "phylo_interaction")
    is_relmat <- identical(provider, "relmat")
    is_spatial <- identical(provider, "spatial")
    is_animal_intercept <- identical(provider, "animal") &&
      drm_julia_binomial_animal_sd_intercept_route_admitted(object$formula)
    is_animal_slope <- identical(provider, "animal") &&
      drm_julia_binomial_animal_sd_slope_route_admitted(object$formula)
    is_spatial_slope <- is_spatial &&
      drm_julia_binomial_spatial_sd_route_admitted(object$formula) &&
      !identical(term$coef_names, "(Intercept)")
    is_phylo_interaction_slope <- is_phylo_interaction &&
      length(term$coef_names) == 1L &&
      !identical(term$coef_names, "(Intercept)")
    is_animal_iid <- identical(provider, "animal") && animal_iid_route
    is_relmat_iid <- identical(provider, "relmat") && relmat_iid_route
    is_phylo_iid <- is_phylo && phylo_iid_route
    if (!identical(term$dpar, "mu") ||
        !(is_phylo || is_phylo_interaction || (is_relmat &&
          drm_julia_binomial_relmat_sd_route_admitted(object$formula)) ||
          (is_spatial &&
            drm_julia_binomial_spatial_sd_route_admitted(object$formula)) ||
          is_animal_intercept || is_animal_slope || is_animal_iid ||
          is_phylo_iid || is_relmat_iid) ||
        (is_phylo && !identical(term$coef_names, "(Intercept)") &&
          !is_phylo_slope) ||
        (is_phylo_interaction &&
          !identical(term$coef_names, "(Intercept)") &&
          !is_phylo_interaction_slope)) {
      cli::cli_abort(c(
        "Julia Binomial SD simulation supports a phylogenetic intercept or slope-only term, phylogenetic-interaction intercept or slope-only term, relmat intercept, fixed-coordinate spatial intercept or slope-only terms, animal intercept or slope terms, and animal-plus-IID routes.",
        "i" = "Use a matching {.code sd(group, level = ...)} target for the selected structured effect."
      ))
    }
    sd_entries <- Filter(function(entry) {
      !is.null(entry$lhs) && is_random_scale_lhs(entry$lhs)
    }, entries)
    targets <- lapply(sd_entries, function(entry) parse_sd_lhs(entry$lhs))
    expected_target_count <- if (is_animal_iid || is_relmat_iid ||
                                  is_phylo_iid) 2L else 1L
    if (length(targets) != expected_target_count) {
      cli::cli_abort(
        "Julia Binomial phylogenetic simulation requires one matching SD target."
      )
    }
    target <- targets[[1L]]
    target_level <- switch(provider,
      phylo = "phylogenetic",
      phylo_interaction = "phylogenetic_interaction",
      relmat = "relmat",
      spatial = "spatial",
      animal = "animal"
    )
    target_funs <- switch(provider,
      phylo = c("sd", "sd_phylo"),
      phylo_interaction = "sd_phylo",
      relmat = "sd_relmat",
      spatial = "sd_spatial",
      animal = "sd_animal"
    )
    structured_target <- function(candidate) {
      candidate$fun %in% target_funs &&
        identical(candidate$level, target_level) &&
        if (is_phylo_interaction) {
          is.data.frame(object$data) && candidate$group %in% names(object$data)
        } else {
          identical(candidate$group, term$group)
        }
    }
    structured_target_idx <- which(vapply(
      targets, structured_target, logical(1L)
    ))
    if (length(structured_target_idx) != 1L) {
      cli::cli_abort(
        "Julia Binomial structured simulation needs one matching SD target for the fitted group."
      )
    }
    target <- targets[[structured_target_idx]]
    target_coef_matches <- if (is_phylo_interaction_slope || is_phylo_slope) {
      is.na(target$target_coef) ||
        identical(target$target_coef, term$coef_names[[1L]])
    } else {
      is.na(target$target_coef)
    }
    if (!target$fun %in% target_funs ||
        !identical(target$level, target_level) ||
        (!is_phylo_interaction && !identical(target$group, term$group)) ||
        !is.na(target$target_dpar) || !target_coef_matches ||
        !is.na(target$target_block)) {
      cli::cli_abort(
        "Julia Binomial structured simulation needs one matching SD target for the fitted group."
      )
    }
    group <- target$group
    if (!is.data.frame(object$data) || !group %in% names(object$data) ||
        anyNA(object$data[[group]])) {
      cli::cli_abort(
        "Julia Binomial structured simulation requires complete stored grouping values."
      )
    }
    groups <- unique(as.character(object$data[[group]]))
    if (is_phylo) {
      if (!requireNamespace("ape", quietly = TRUE)) {
        cli::cli_abort(
          "Julia Binomial phylogenetic simulation requires the {.pkg ape} package used to fit the tree model."
        )
      }
      tree_text <- object$bridge_payload$tree
      if (!is.character(tree_text) || length(tree_text) != 1L ||
          is.na(tree_text) || !nzchar(tree_text)) {
        cli::cli_abort(
          "The Julia fit does not retain the phylogenetic tree needed for marginal simulation."
        )
      }
      tree <- tryCatch(
        ape::read.tree(text = tree_text),
        error = function(error) NULL
      )
      if (is.null(tree) || is.null(tree$tip.label) ||
          anyDuplicated(tree$tip.label)) {
        cli::cli_abort(
          "The stored Julia phylogenetic tree cannot be reconstructed with unique tip labels."
        )
      }
      if (!all(groups %in% tree$tip.label)) {
        cli::cli_abort(
          "The stored Julia data contain phylogenetic groups absent from the saved tree."
        )
      }
      covariance <- ape::vcv.phylo(tree)
      covariance <- covariance[groups, groups, drop = FALSE]
      scale <- drm_julia_structured_sd_scale(object, term$label)
      if (length(scale) != 1L || !is.finite(scale) || scale <= 0) {
        cli::cli_abort(
          "The Julia fit does not retain a valid scale for its phylogenetic covariance."
        )
      }
      covariance <- covariance / scale^2
    } else {
      payload <- object$bridge_payload
      valid_kwarg <- if (is_relmat || is_spatial || is_phylo_interaction) {
        isTRUE(identical(payload$kwarg, "K"))
      } else {
        isTRUE(payload$kwarg %in% c("A", "Ainv"))
      }
      covariance <- payload$matrix
      if (!valid_kwarg || is.null(covariance)) {
        cli::cli_abort(
          "The Julia fit does not retain the relatedness matrix needed for structured Binomial simulation."
        )
      }
      covariance <- as.matrix(covariance)
      if (identical(provider, "animal") &&
          identical(payload$kwarg, "Ainv")) {
        covariance <- tryCatch(
          solve(covariance),
          error = function(error) NULL
        )
        if (is.null(covariance)) {
          cli::cli_abort(
            "The saved Julia animal precision matrix cannot be inverted for simulation."
          )
        }
      }
    }
    covariance_names <- dimnames(covariance)
    if (is.null(covariance_names) ||
        is.null(covariance_names[[1L]]) ||
        is.null(covariance_names[[2L]])) {
      # Julia bridge payloads may drop R dimnames after serialization, but the
      # bridge has already aligned the matrix to first-seen fitted group order.
      dimnames(covariance) <- list(groups, groups)
    } else {
      if (!all(groups %in% covariance_names[[1L]]) ||
          !all(groups %in% covariance_names[[2L]])) {
        cli::cli_abort(
          "The saved Julia structured covariance labels do not match its fitted grouping values."
        )
      }
      covariance <- covariance[groups, groups, drop = FALSE]
    }
    if (any(!is.finite(covariance)) ||
        !isTRUE(all.equal(covariance, t(covariance))) ||
        any(diag(covariance) <= 0) ||
        !identical(dim(covariance), c(length(groups), length(groups))) ||
        inherits(tryCatch(chol(covariance), error = function(error) error), "error")) {
      cli::cli_abort(
        "The saved Julia structured covariance is invalid for simulation."
      )
    }
    loading <- NULL
    if (is_animal_slope || is_spatial_slope || is_phylo_slope ||
        is_phylo_interaction_slope) {
      slope <- term$coef_names[[1L]]
      if (!slope %in% names(object$data)) {
        cli::cli_abort(
          "The saved Julia data do not contain random-slope predictor {.field {slope}}."
        )
      }
      loading <- object$data[[slope]]
      if (!is.numeric(loading) || length(loading) != nrow(object$data) ||
          any(!is.finite(loading))) {
        cli::cli_abort(
          "The saved Julia random-slope predictor must be finite numeric values, one per response row."
        )
      }
      loading <- as.numeric(loading)
    }
    components <- list(list(
      group = group,
      target = target,
      structured = TRUE,
      phylogenetic = is_phylo,
      covariance = covariance,
      loading = loading
    ))
    if (is_animal_iid || is_relmat_iid || is_phylo_iid) {
      iid_target_idx <- setdiff(seq_along(targets), structured_target_idx)
      iid_target <- targets[[iid_target_idx]]
      bar <- strip_parens(bars[[1L]])
      lhs <- strip_parens(bar[[2L]])
      iid_group <- as.character(strip_parens(bar[[3L]]))
      if (length(bars) != 1L || !is.numeric(lhs) ||
          length(lhs) != 1L || lhs != 1 ||
          !identical(iid_target$fun, "sd") ||
          !is.na(iid_target$level) ||
          !is.na(iid_target$target_dpar) ||
          !is.na(iid_target$target_coef) ||
          !is.na(iid_target$target_block) ||
          !identical(iid_target$group, iid_group) ||
          !is.data.frame(object$data) || !iid_group %in% names(object$data) ||
          anyNA(object$data[[iid_group]])) {
        cli::cli_abort(
          "Julia Binomial structured-plus-IID simulation requires one complete ordinary intercept with its matching unselected SD target."
        )
      }
      components[[2L]] <- list(
        group = iid_group,
        target = iid_target,
        structured = FALSE,
        phylogenetic = FALSE,
        covariance = NULL,
        loading = NULL
      )
    }
    return(list(components = components))
  }
  if (length(bars) == 0L) {
    return(list(components = NULL))
  }
  groups <- character(length(bars))
  sd_entries <- Filter(function(entry) {
    !is.null(entry$lhs) && is_random_scale_lhs(entry$lhs)
  }, entries)
  targets <- lapply(sd_entries, function(entry) parse_sd_lhs(entry$lhs))
  correlated_component <- drm_julia_binomial_correlated_sd_component(
    object, bars, targets
  )
  if (!is.null(correlated_component)) {
    return(list(components = list(correlated_component)))
  }
  for (i in seq_along(bars)) {
    bar <- strip_parens(bars[[i]])
    lhs <- strip_parens(bar[[2L]])
    group <- strip_parens(bar[[3L]])
    if (!is.numeric(lhs) || length(lhs) != 1L || lhs != 1 || !is.name(group)) {
      cli::cli_abort(c(
        "Julia Binomial SD simulation currently supports independent random intercepts only.",
        "i" = "Slope and correlated-block simulation require conditional or covariance-aware backend draws."
      ))
    }
    groups[[i]] <- as.character(group)
  }
  if (anyDuplicated(groups)) {
    cli::cli_abort(
      "Julia Binomial SD simulation currently requires distinct grouping factors for independent intercepts."
    )
  }
  if (length(targets) != length(groups) || any(vapply(targets, function(target) {
    !identical(target$fun, "sd") || !is.na(target$level) ||
      !is.na(target$target_dpar) || !is.na(target$target_coef) ||
      !is.na(target$target_block)
  }, logical(1L)))) {
    cli::cli_abort(c(
      "Julia Binomial SD simulation requires one unselected ordinary SD target per random intercept.",
      "i" = "Use one {.code sd(group) ~ predictors} formula for each distinct {.code (1 | group)} term."
    ))
  }
  target_groups <- vapply(targets, `[[`, character(1L), "group")
  if (!setequal(target_groups, groups)) {
    cli::cli_abort(
      "Julia Binomial SD simulation requires each ordinary intercept to have a matching {.code sd(group)} formula."
    )
  }
  if (!is.data.frame(object$data) || any(vapply(groups, function(group) {
    !group %in% names(object$data) || anyNA(object$data[[group]])
  }, logical(1L)))) {
    cli::cli_abort(
      "Julia Binomial SD simulation requires complete stored grouping columns."
    )
  }
  components <- lapply(groups, function(group) {
    target <- targets[[match(group, target_groups)]]
    list(group = group, target = target)
  })
  list(components = components)
}

drm_julia_binomial_animal_q2_sd_component <- function(object, term) {
  group <- term$group
  groups <- unique(as.character(object$data[[group]]))
  coefficients <- term$coef_names
  sd_entries <- Filter(function(entry) {
    !is.null(entry$lhs) && is_random_scale_lhs(entry$lhs)
  }, object$formula$entries)
  targets <- lapply(sd_entries, function(entry) parse_sd_lhs(entry$lhs))
  target_coef <- vapply(targets, function(target) {
    if (identical(target$target_coef, "intercept")) {
      "(Intercept)"
    } else {
      target$target_coef
    }
  }, character(1L))
  if (length(targets) != length(coefficients) ||
      anyDuplicated(target_coef) || !setequal(target_coef, coefficients) ||
      any(vapply(targets, function(target) {
        !identical(target$fun, "sd_animal") ||
          !identical(target$level, "animal") ||
          !identical(target$group, group) ||
          !identical(target$target_dpar, "mu") ||
          !is.na(target$target_block)
      }, logical(1L)))) {
    cli::cli_abort(
      "Julia Binomial animal q2 simulation requires one matching animal SD target per random-effect coefficient."
    )
  }
  members <- lapply(coefficients, function(coef_name) {
    target <- targets[[match(coef_name, target_coef)]]
    loading <- if (identical(coef_name, "(Intercept)")) {
      rep(1, nrow(object$data))
    } else {
      value <- object$data[[coef_name]]
      if (!is.numeric(value) || length(value) != nrow(object$data) ||
          any(!is.finite(value))) {
        cli::cli_abort(
          "Julia Binomial animal q2 simulation requires a finite numeric {.field {coef_name}} predictor."
        )
      }
      as.numeric(value)
    }
    list(target = target, loading = loading)
  })
  names(members) <- coefficients

  correlations <- object$corpars$mu
  correlation_name <- paste0(
    "cor((Intercept),", term$variables[[1L]], " | ", group, ")"
  )
  if (!is.numeric(correlations) || is.null(names(correlations)) ||
      !correlation_name %in% names(correlations)) {
    cli::cli_abort(
      "The Julia Binomial animal q2 fit does not expose its coefficient correlation for marginal simulation."
    )
  }
  rho <- unname(correlations[[correlation_name]])
  correlation <- matrix(c(1, rho, rho, 1), nrow = 2L,
                        dimnames = list(coefficients, coefficients))
  payload <- object$bridge_payload
  if (!isTRUE(payload$kwarg %in% c("A", "Ainv")) ||
      is.null(payload$matrix)) {
    cli::cli_abort(
      "The Julia Binomial animal q2 fit does not retain its relationship matrix for marginal simulation."
    )
  }
  group_covariance <- as.matrix(payload$matrix)
  if (identical(payload$kwarg, "Ainv")) {
    group_covariance <- tryCatch(
      solve(group_covariance),
      error = function(error) NULL
    )
    if (is.null(group_covariance)) {
      cli::cli_abort(
        "The saved Julia animal precision matrix cannot be inverted for marginal simulation."
      )
    }
  }
  matrix_names <- dimnames(group_covariance)
  if (is.null(matrix_names) || any(vapply(matrix_names, is.null, logical(1L)))) {
    dimnames(group_covariance) <- list(groups, groups)
  } else {
    if (!all(groups %in% matrix_names[[1L]]) ||
        !all(groups %in% matrix_names[[2L]])) {
      cli::cli_abort(
        "The saved Julia animal covariance labels do not match its fitted grouping values."
      )
    }
    group_covariance <- group_covariance[groups, groups, drop = FALSE]
  }
  list(
    group = group,
    groups = groups,
    members = members,
    correlation = correlation,
    group_covariance = group_covariance
  )
}

drm_julia_binomial_correlated_sd_component <- function(
  object, bars, targets
) {
  if (length(bars) != 1L ||
      !drm_julia_binomial_sd_link_route_admitted(
        object$formula, data = object$data
      )) {
    return(NULL)
  }
  bar <- strip_parens(bars[[1L]])
  if (length(bar) != 3L || !is.symbol(bar[[3L]])) return(NULL)
  group <- as.character(bar[[3L]])
  random <- tryCatch(
    parse_random_mu_lhs(bar[[2L]], "mu", group),
    error = function(error) NULL
  )
  if (is.null(random) ||
      !random$type %in% c("correlated_slope", "correlated_block")) {
    return(NULL)
  }
  coefficients <- random$coef_names
  if (length(targets) != length(coefficients) ||
      any(vapply(targets, function(target) {
        !identical(target$fun, "sd") || !is.na(target$level) ||
          !identical(target$target_dpar, "mu") ||
          is.na(target$target_coef) || !is.na(target$target_block) ||
          !identical(target$group, group)
      }, logical(1L)))) {
    return(NULL)
  }
  member_labels <- vapply(targets, `[[`, character(1L), "target_coef")
  member_labels[member_labels == "intercept"] <- "(Intercept)"
  if (anyDuplicated(member_labels) || !setequal(member_labels, coefficients)) {
    return(NULL)
  }
  if (!is.data.frame(object$data) || !group %in% names(object$data) ||
      anyNA(object$data[[group]])) {
    cli::cli_abort(
      "Julia Binomial correlated-block simulation requires complete stored grouping values."
    )
  }
  groups <- unique(as.character(object$data[[group]]))
  members <- lapply(coefficients, function(coef_name) {
    target <- targets[[match(coef_name, member_labels)]]
    loading <- if (identical(coef_name, "(Intercept)")) {
      rep(1, nrow(object$data))
    } else {
      value <- object$data[[coef_name]]
      if (!is.numeric(value) || length(value) != nrow(object$data) ||
          any(!is.finite(value))) {
        cli::cli_abort(
          "Julia Binomial correlated-block simulation requires a finite numeric {.field {coef_name}} predictor."
        )
      }
      as.numeric(value)
    }
    list(target = target, loading = loading)
  })
  names(members) <- coefficients

  correlations <- object$corpars$mu
  if (!is.numeric(correlations) || is.null(names(correlations))) {
    cli::cli_abort(
      "The Julia Binomial fit does not expose named correlations for its correlated SD block."
    )
  }
  correlation <- diag(length(coefficients))
  dimnames(correlation) <- list(coefficients, coefficients)
  for (i in seq_len(length(coefficients) - 1L)) {
    for (j in seq.int(i + 1L, length(coefficients))) {
      key <- paste0("cor(", coefficients[[i]], ",", coefficients[[j]],
                    " | ", group, ")")
      rho <- correlations[[key]]
      if (is.null(rho) || length(rho) != 1L || !is.finite(rho) ||
          abs(rho) >= 1) {
        cli::cli_abort(
          "The Julia Binomial fit is missing a valid correlation for {.val {coefficients[[i]]}} and {.val {coefficients[[j]]}}."
        )
      }
      correlation[i, j] <- rho
      correlation[j, i] <- rho
    }
  }
  if (inherits(tryCatch(chol(correlation), error = function(error) error),
               "error")) {
    cli::cli_abort(
      "The fitted Julia Binomial correlated-block matrix is not positive definite for marginal simulation."
    )
  }
  list(
    group = group,
    groups = groups,
    members = members,
    correlation = correlation
  )
}
