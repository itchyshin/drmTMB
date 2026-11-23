# Parse prior rows before resolving selectors against a model.
drm_parse_prior_table <- function(x) {
  if (!is.data.frame(x) || anyDuplicated(names(x))) {
    cli::cli_abort("prior table must have unique columns")
  }
  required <- c("prior", "class", "coef")
  optional <- c("dpar", "group", "scale", "from_coef", "to_coef")
  if (!all(required %in% names(x)) || any(!names(x) %in% c(required, optional))) {
    cli::cli_abort("invalid prior table columns")
  }
  if (!nrow(x) || any(!vapply(x, is.character, logical(1))) || anyNA(x)) {
    cli::cli_abort("prior table requires nonmissing character rows")
  }

  number <- "[+-]?(?:(?:[0-9]+(?:\\.[0-9]*)?)|(?:\\.[0-9]+))(?:[eE][+-]?[0-9]+)?"
  ws <- "[ \\t\\r\\n\\f\\v]*"
  pat <- paste0(
    "^", ws, "(normal|student_t|ridge|gamma|lkj)", ws, "\\(", ws,
    "(", number, ")", ws, "(?:,", ws, "(", number, ")", ws,
    ")?(?:,", ws, "(", number, ")", ws, ")?\\)", ws, "$"
  )
  lapply(seq_len(nrow(x)), function(i) {
    cls <- x$class[[i]]
    coef <- x$coef[[i]]
    dpar <- if ("dpar" %in% names(x)) x$dpar[[i]] else ""
    group <- if ("group" %in% names(x)) x$group[[i]] else ""
    scale <- if ("scale" %in% names(x)) x$scale[[i]] else ""
    from_coef <- if ("from_coef" %in% names(x)) x$from_coef[[i]] else ""
    to_coef <- if ("to_coef" %in% names(x)) x$to_coef[[i]] else ""
    if (!nzchar(dpar)) dpar <- "mu"
    if (!cls %in% c("fixef", "ranef_sd", "residual_sd", "correlation")) {
      cli::cli_abort("unsupported prior class")
    }
    match <- regmatches(x$prior[[i]], regexec(pat, x$prior[[i]], perl = TRUE))[[1L]]
    if (!length(match)) cli::cli_abort("invalid prior syntax")
    kind <- match[[2L]]
    args <- match[3:5]
    args <- args[nzchar(args)]
    arity <- switch(kind, normal = 2L, student_t = 3L, ridge = 1L,
      gamma = 2L, lkj = 1L)
    if (length(args) != arity) cli::cli_abort("wrong prior arity")
    values <- suppressWarnings(as.numeric(args))
    nonzero_literal <- grepl("[1-9]", sub("[eE].*$", "", args))
    if (any(!is.finite(values)) || any(values == 0 & nonzero_literal)) {
      cli::cli_abort("unrepresentable prior parameter")
    }

    if (kind == "normal") {
      precision <- 1 / values[[2L]]^2
      if (cls != "fixef" || values[[2L]] <= 0 ||
          !is.finite(precision) || precision <= 0) {
        cli::cli_abort("invalid normal prior")
      }
    } else if (kind == "student_t") {
      precision <- 1 / values[[2L]]^2
      if (cls != "fixef" || values[[2L]] <= 0 || values[[3L]] <= 0 ||
          !is.finite(precision) || precision <= 0) {
        cli::cli_abort("invalid Student-t prior: location, scale, and df must be finite; scale and df must be positive")
      }
    } else if (kind == "ridge") {
      if (cls != "fixef" || values[[1L]] < 0) cli::cli_abort("invalid ridge prior")
    } else if (kind == "gamma") {
      rate <- values[[2L]] / values[[1L]]
      if (!cls %in% c("ranef_sd", "residual_sd") || values[[1L]] <= 0 ||
          values[[2L]] <= 1 || !is.finite(rate) || rate <= 0) {
        cli::cli_abort("invalid Gamma prior: mean must be positive and shape > 1")
      }
    } else if (kind == "lkj") {
      if (cls != "correlation" || values[[1L]] <= 1) {
        cli::cli_abort("LKJ prior requires class correlation and eta > 1")
      }
    }

    if (!nzchar(scale) && cls %in% c("residual_sd", "correlation")) {
      cli::cli_abort("{.val {cls}} prior rows must explicitly specify their target scale.")
    }
    if (!nzchar(scale)) {
      scale <- switch(cls, fixef = "link", ranef_sd = "natural_sd",
        residual_sd = "natural_sd", correlation = "natural_correlation")
    }
    if (cls == "fixef") {
      if (nzchar(group) || coef == "all" || nzchar(from_coef) || nzchar(to_coef)) {
        cli::cli_abort("invalid fixed selector")
      }
      if (scale != "link") cli::cli_abort("fixed-effect priors require scale=link")
    } else if (cls == "ranef_sd") {
      if (dpar != "mu" || nzchar(from_coef) || nzchar(to_coef) ||
          scale != "natural_sd") {
        cli::cli_abort("random-effect SD priors require dpar=mu and scale=natural_sd")
      }
    } else if (cls == "residual_sd") {
      if (kind != "gamma" || dpar != "sigma" || coef != "(Intercept)" ||
          nzchar(group) || nzchar(from_coef) || nzchar(to_coef) ||
          scale != "natural_sd") {
        cli::cli_abort("residual_sd Gamma priors require dpar=sigma, coef=(Intercept), scale=natural_sd, and no group or pair selectors")
      }
    } else {
      if (kind != "lkj" || scale != "natural_correlation") {
        cli::cli_abort("correlation priors require lkj(eta) and scale=natural_correlation")
      }
      if (dpar == "rho12") {
        if (coef != "(Intercept)" || nzchar(group) ||
            nzchar(from_coef) || nzchar(to_coef)) {
          cli::cli_abort("rho12 correlation priors require coef=(Intercept) and no group or pair selectors")
        }
      } else if (dpar == "mu") {
        if (nzchar(coef) || !nzchar(group) || !nzchar(from_coef) ||
            !nzchar(to_coef) || from_coef == to_coef ||
            !("(Intercept)" %in% c(from_coef, to_coef))) {
          cli::cli_abort("random-slope correlation priors require dpar=mu, group, and distinct (Intercept)/slope from_coef/to_coef selectors")
        }
        if (from_coef != "(Intercept)") {
          swap <- from_coef
          from_coef <- to_coef
          to_coef <- swap
        }
      } else {
        cli::cli_abort("correlation dpar must be rho12 or mu")
      }
    }
    list(
      kind = kind, class = cls, coef = coef, dpar = dpar, group = group,
      from_coef = from_coef, to_coef = to_coef, scale = scale, args = values
    )
  })
}

drm_prior_table_groups <- function(formula) {
  mu <- Filter(function(entry) identical(entry$dpar, "mu"), formula$entries)
  if (length(mu) != 1L) return(character())
  terms <- extract_random_mu_terms(mu[[1L]]$rhs, "mu")$terms
  vapply(terms, `[[`, character(1), "group")
}

# Expand broad random-SD selectors only after the formula has been parsed.
drm_expand_prior_table <- function(rows, groups) {
  if (anyDuplicated(groups)) cli::cli_abort("ambiguous random-effect groups")
  out <- list()
  seen <- character()
  for (row in rows) {
    if (row$class != "ranef_sd") {
      out[[length(out) + 1L]] <- row
      next
    }
    if (row$dpar != "mu") cli::cli_abort("SD priors require dpar=mu")
    selected <- if (nzchar(row$group)) {
      if (!row$coef %in% c("", "(Intercept)", row$group)) {
        cli::cli_abort("conflicting group and coefficient selectors")
      }
      row$group
    } else if (!nzchar(row$coef)) {
      groups
    } else if (row$coef == "(Intercept)") {
      cli::cli_abort("use group for the random-intercept grouping variable")
    } else {
      row$coef
    }
    if (!length(selected)) cli::cli_abort("SD prior matched no random effect")
    for (group in selected) {
      if (!group %in% groups) cli::cli_abort("unknown random-effect group")
      if (group %in% seen) cli::cli_abort("overlapping SD prior target")
      seen <- c(seen, group)
      expanded <- row
      expanded$group <- group
      expanded$coef <- "(Intercept)"
      out[[length(out) + 1L]] <- expanded
    }
  }
  out
}

drm_prior_table_specs <- function(rows, groups) {
  expanded <- drm_expand_prior_table(rows, groups)
  entries <- lapply(expanded, function(row) {
    if (row$class == "ranef_sd") {
      return(drm_prior_sd_gamma(
        dpar = row$dpar, group = row$group,
        shape = row$args[[2L]], rate = row$args[[2L]] / row$args[[1L]]
      ))
    }
    if (row$class == "residual_sd") {
      return(drm_residual_sd_prior_gamma(
        shape = row$args[[2L]], rate = row$args[[2L]] / row$args[[1L]]
      ))
    }
    if (row$class == "correlation") {
      return(drm_correlation_prior_lkj(
        dpar = row$dpar, group = if (nzchar(row$group)) row$group else NULL,
        from_coef = if (nzchar(row$from_coef)) row$from_coef else NULL,
        to_coef = if (nzchar(row$to_coef)) row$to_coef else NULL,
        eta = row$args[[1L]]
      ))
    }
    coefficient <- if (nzchar(row$coef)) row$coef else "all"
    intercept <- if (nzchar(row$coef)) NULL else "exclude"
    if (row$kind == "normal") {
      return(drm_prior_normal(
        dpar = row$dpar, coef = coefficient, mean = row$args[[1L]],
        sd = row$args[[2L]], intercept = intercept
      ))
    }
    if (row$kind == "student_t") {
      return(drm_prior_student_t(
        dpar = row$dpar, coef = coefficient, mean = row$args[[1L]],
        scale = row$args[[2L]], df = row$args[[3L]], intercept = intercept
      ))
    }
    drm_prior_ridge(dpar = row$dpar, coef = coefficient,
      lambda = row$args[[1L]], intercept = intercept)
  })
  do.call(drm_priors, entries)
}

drm_normalize_prior_table <- function(table, formula, family, data, ...) {
  rows <- drm_parse_prior_table(table)
  specs <- drm_prior_table_specs(rows, drm_prior_table_groups(formula))
  drm_validate_fixed_prior_request(specs, formula, family, data, ...)
  attr(specs, "input_table") <- table
  specs
}

# Freeze model-matrix identities for update; retain the submitted table as metadata.
drm_freeze_table_prior_specs <- function(priors, resolved) {
  fixed <- if ("class" %in% names(resolved)) {
    resolved[resolved$class == "fixed", , drop = FALSE]
  } else {
    resolved
  }
  if (nrow(fixed) && any(fixed$coefficient == "all")) {
    cli::cli_abort("A coefficient literally named all cannot be selected by a prior table")
  }
  entries <- list()
  for (prior in priors) {
    if (!inherits(prior, "drm_fixed_prior")) {
      entries[[length(entries) + 1L]] <- prior
      next
    }
    selected <- fixed$dpar == prior$dpar & if (prior$coef == "all") {
      fixed$reason == paste0("all; intercept ", prior$intercept)
    } else {
      fixed$coefficient == prior$coef
    }
    targets <- fixed$coefficient[selected]
    if (!length(targets)) cli::cli_abort("Prior replay target was not resolved.")
    for (target in targets) {
      entries[[length(entries) + 1L]] <- switch(
        prior$kind,
        normal = drm_prior_normal(prior$dpar, target, mean = prior$mean, sd = prior$sd),
        student_t = drm_prior_student_t(prior$dpar, target, mean = prior$mean,
          scale = prior$sd, df = prior$df),
        ridge = drm_prior_ridge(prior$dpar, target, lambda = prior$precision)
      )
    }
  }
  out <- do.call(drm_priors, entries)
  attr(out, "input_table") <- attr(priors, "input_table")
  out
}

# Public table previews use the same target vocabulary as the submitted table.
# Keep the native resolved rows unchanged for fits and bridge serialization.
drm_prior_table_preview <- function(rows) {
  if (!is.data.frame(rows) || !nrow(rows)) return(rows)
  if ("class" %in% names(rows)) {
    rows$class[rows$class == "sd_gamma"] <- "ranef_sd"
  }
  if ("scale" %in% names(rows) && "class" %in% names(rows)) {
    rows$scale[rows$class == "ranef_sd" & rows$scale == "SD"] <- "natural_sd"
  }
  if (all(c("class", "dpar", "block") %in% names(rows))) {
    q2 <- rows$class == "correlation" & rows$dpar == "mu"
    rows$block[q2] <- "gaussian_q2"
  }
  rows
}
