# Internal identity map for ordinary random-effect SD targets. This module does
# not admit a model or change the likelihood; callers retain their route gates.
drm_ordinary_sd_target_members <- function(terms, re, dpar) {
  if (length(terms) == 0L) {
    if (!identical(re$n_terms, 0L) || !identical(re$n_re, 0L) ||
        length(re$dpars) != 0L || length(re$groups) != 0L) {
      cli::cli_abort("Internal error: empty ordinary SD terms have misaligned random-effect metadata.")
    }
    return(list())
  }
  term_dpars <- if (length(dpar) == 1L) {
    rep(dpar, length(terms))
  } else {
    dpar
  }
  n_axis <- sum(vapply(terms, function(term) length(term$coef_names), integer(1L)))
  if (length(term_dpars) != length(terms) || anyNA(term_dpars) ||
      !identical(n_axis, re$n_terms) ||
      length(re$dpars) != n_axis || length(re$groups) != n_axis ||
      length(re$term_id0) != re$n_re ||
      length(re$re_pos0) != re$n_re ||
      length(re$re_cor_id0) != re$n_re ||
      length(re$re_pair_index0) != re$n_re ||
      ncol(re$index0) != n_axis || ncol(re$value) != n_axis) {
    cli::cli_abort("Internal error: ordinary SD target metadata is incomplete or misaligned.")
  }

  out <- vector("list", n_axis)
  axis <- 0L
  for (term_index in seq_along(terms)) {
    term <- terms[[term_index]]
    if (!is.list(term) || is.null(term$type) ||
        !term$type %in% c("intercept", "slope", "correlated_slope", "correlated_block") ||
        is.null(term$group) ||
        is.null(term$coef_names) || is.null(term$label)) {
      cli::cli_abort("Internal error: expected a parsed ordinary random-effect term.")
    }
    for (axis_pos in seq_along(term$coef_names)) {
      axis <- axis + 1L
      latent_pos0 <- which(re$term_id0 == axis - 1L) - 1L
      axis_positions <- unique(re$re_pos0[latent_pos0 + 1L])
      levels_axis <- re$groups[[axis]]
      obs_group_index0 <- match(re$index0[, axis], latent_pos0) - 1L
      pair_index0 <- re$re_pair_index0[latent_pos0 + 1L]
      has_pair <- pair_index0 >= 0L
      block <- if (is.null(term$covariance_label)) {
        NA_character_
      } else {
        term$covariance_label
      }
      if (length(latent_pos0) != length(levels_axis) ||
          length(axis_positions) != 1L ||
          anyNA(obs_group_index0) ||
          !identical(re$dpars[[axis]], term_dpars[[term_index]]) ||
          !identical(re$coef_names[[axis]], term$coef_names[[axis_pos]]) ||
          !identical(re$group_names[[axis]], term$group) ||
          !identical(re$covariance_labels[[axis]], block) ||
          any(pair_index0 < -1L) ||
          (any(has_pair) && !all(has_pair))) {
        cli::cli_abort("Internal error: ordinary SD target axes do not match the random-effect structure.")
      }
      if (all(has_pair)) {
        current_cor_id0 <- unique(re$re_cor_id0[latent_pos0 + 1L])
        if (any(pair_index0 >= latent_pos0) ||
            length(current_cor_id0) != 1L ||
            is.na(current_cor_id0) || current_cor_id0 < 0L ||
            current_cor_id0 >= re$n_cors) {
          cli::cli_abort("Internal error: ordinary SD correlation pair metadata is misaligned.")
        }
        paired_axis0 <- re$term_id0[pair_index0 + 1L]
        if (anyNA(paired_axis0) || length(unique(paired_axis0)) != 1L ||
            identical(paired_axis0[[1L]], axis - 1L)) {
          cli::cli_abort("Internal error: ordinary SD correlation pair metadata is misaligned.")
        }
        paired_pos0 <- which(re$term_id0 == paired_axis0[[1L]]) - 1L
        paired_axis <- paired_axis0[[1L]] + 1L
        paired_cor_id0 <- unique(re$re_cor_id0[paired_pos0 + 1L])
        if (!identical(as.integer(match(pair_index0, paired_pos0)),
                       seq_along(levels_axis)) ||
            !identical(re$groups[[paired_axis]], levels_axis) ||
            !identical(re$group_names[[paired_axis]], term$group) ||
            !identical(re$covariance_labels[[paired_axis]], block) ||
            length(paired_cor_id0) != 1L || is.na(paired_cor_id0) ||
            (paired_cor_id0 < 0L &&
               identical(re$dpars[[paired_axis]], term_dpars[[term_index]])) ||
            (paired_cor_id0 >= 0L && paired_cor_id0 != current_cor_id0)) {
          cli::cli_abort("Internal error: ordinary SD correlation pair metadata is misaligned.")
        }
      }
      out[[axis]] <- list(
        provider = "ordinary",
        level = "group",
        group = term$group,
        dpar = term_dpars[[term_index]],
        coef = term$coef_names[[axis_pos]],
        block = block,
        label = re$labels[[axis]],
        source_label = term$label,
        target_term = as.integer(term_index),
        target_coef = as.integer(axis),
        axis_pos0 = as.integer(axis_positions[[1L]]),
        source_coef_pos0 = as.integer(axis_pos - 1L),
        latent_pos0 = as.integer(latent_pos0),
        obs_group_index0 = as.integer(obs_group_index0),
        group_levels = levels_axis,
        design_value = as.numeric(re$value[, axis])
      )
    }
  }
  out
}

# Resolve identity only. A caller must still validate whether the selected
# family, endpoint, coefficient shape, and engine admit an SD formula.
drm_resolve_sd_target <- function(target, members) {
  if (!is.list(target) || is.null(target$group) ||
      length(target$group) != 1L || is.na(target$group)) {
    cli::cli_abort("Internal error: expected a parsed SD target.")
  }
  fun <- target$fun
  level <- target$level
  if (is.null(level)) level <- NA_character_
  if (!is.null(fun) && !fun %in% c("sd", "sd1", "sd2") ||
      !is.na(level) && !identical(level, "group")) {
    cli::cli_abort("Structured random-effect SD targets require their own resolver.")
  }
  members <- Filter(function(member) identical(member$provider, "ordinary"), members)
  format_member <- function(member) {
    paste0(
      "group=", member$group,
      ", provider=", member$provider,
      ", dpar=", member$dpar,
      ", coef=", member$coef,
      ", block=", if (is.na(member$block)) "<unlabelled>" else member$block
    )
  }
  available <- if (length(members) == 0L) {
    "none"
  } else {
    paste(vapply(members, format_member, character(1L)), collapse = "; ")
  }
  selected <- Filter(function(member) identical(member$group, target$group), members)

  selector <- function(value) {
    !is.null(value) && length(value) == 1L && !is.na(value)
  }
  requested_dpar <- target$target_dpar
  alias_dpar <- switch(fun, sd1 = "mu1", sd2 = "mu2", NULL)
  if (!is.null(alias_dpar)) {
    if (selector(requested_dpar) && !identical(requested_dpar, alias_dpar)) {
      cli::cli_abort("Conflicting SD target distributional parameter and alias.")
    }
    requested_dpar <- alias_dpar
  }
  if (selector(requested_dpar)) {
    selected <- Filter(function(member) identical(member$dpar, requested_dpar), selected)
  }
  if (selector(target$target_coef)) {
    selected <- Filter(function(member) identical(member$coef, target$target_coef), selected)
  }
  if (selector(target$target_block)) {
    selected <- Filter(function(member) identical(member$block, target$target_block), selected)
  }

  if (length(selected) == 1L) return(selected[[1L]])
  if (length(selected) == 0L) {
    cli::cli_abort(c(
      "No ordinary random-effect SD target matches group {.field {target$group}} and its selectors.",
      "i" = "Available targets: {available}. Check {.arg dpar}, {.arg coef}, and {.arg block}."
    ))
  }
  candidates <- paste(vapply(selected, format_member, character(1L)), collapse = "; ")
  cli::cli_abort(c(
    "Ambiguous ordinary random-effect SD target for group {.field {target$group}}.",
    "x" = "Matching targets: {candidates}.",
    "i" = "Supply {.arg dpar}, {.arg coef}, or {.arg block} to select one; add unique block labels for otherwise indistinguishable terms."
  ))
}
