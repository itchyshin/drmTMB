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
  if ((!is.null(fun) && !fun %in% c("sd", "sd1", "sd2")) ||
      length(level) != 1L || (!is.na(level) && !is.character(level))) {
    cli::cli_abort("Internal error: expected a scalar SD target level and function.")
  }
  valid_member_string <- function(value) {
    is.character(value) && length(value) == 1L && !is.na(value) && nzchar(value)
  }
  valid_member_block <- function(value) {
    is.character(value) && length(value) == 1L &&
      (is.na(value) || nzchar(value))
  }
  malformed_identity <- Filter(function(member) {
    if (!is.list(member)) return(TRUE)
    !valid_member_string(member[["provider"]]) ||
      !valid_member_string(member[["group"]]) ||
      !valid_member_string(member[["dpar"]]) ||
      !valid_member_string(member[["coef"]]) ||
      !valid_member_block(member[["block"]])
  }, members)
  if (length(malformed_identity) > 0L) {
    cli::cli_abort(c(
      "Random-effect SD members require complete identity metadata.",
      "x" = "Each member needs scalar {.arg provider}, {.arg group}, {.arg dpar}, and {.arg coef} strings, plus a {.arg block} string or {.code NA_character_}."
    ))
  }
  malformed_levels <- Filter(function(member) {
    if (identical(member$provider, "ordinary")) return(FALSE)
    member_level <- member$level
    is.null(member_level) || !is.character(member_level) ||
      length(member_level) != 1L || is.na(member_level) ||
      !nzchar(member_level) || identical(member_level, "group")
  }, members)
  if (length(malformed_levels) > 0L) {
    cli::cli_abort(c(
      "Structured random-effect SD members require explicit level metadata.",
      "x" = "At least one structured target has a missing or invalid {.arg level}.",
      "i" = "Set each structured member's level to its provider level, such as {.val phylogenetic} or {.val spatial}."
    ))
  }
  member_level <- function(member) {
    if (!is.null(member$level)) return(member$level)
    if (identical(member$provider, "ordinary")) return("group")
    NA_character_
  }
  members <- Filter(function(member) {
    current_level <- member_level(member)
    if (identical(member$provider, "ordinary")) {
      identical(current_level, "group")
    } else {
      is.character(current_level) && length(current_level) == 1L &&
        !is.na(current_level) && !identical(current_level, "group")
    }
  }, members)
  format_member <- function(member) {
    paste0(
      "group=", member$group,
      ", provider=", member$provider,
      ", level=", member_level(member),
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
  if (!is.na(level)) {
    selected <- Filter(function(member) identical(member_level(member), level), selected)
  }
  scope <- if (all(vapply(members, function(member) {
    identical(member$provider, "ordinary")
  }, logical(1L)))) {
    "ordinary random-effect SD target"
  } else {
    "random-effect SD target"
  }

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
    if (!is.na(level) && !identical(level, "group") &&
        all(vapply(members, function(member) {
          identical(member$provider, "ordinary")
        }, logical(1L)))) {
      cli::cli_abort("Structured random-effect SD targets require matching structured target metadata.")
    }
    cli::cli_abort(c(
      "No {scope} matches group {.field {target$group}} and its selectors.",
      "i" = "Available targets: {available}. Check {.arg dpar}, {.arg coef}, and {.arg block}."
    ))
  }
  candidates <- paste(vapply(selected, format_member, character(1L)), collapse = "; ")
  cli::cli_abort(c(
    "Ambiguous {scope} for group {.field {target$group}}.",
    "x" = "Matching targets: {candidates}.",
    "i" = "Supply {.arg dpar}, {.arg coef}, or {.arg block} to select one; add unique block labels for otherwise indistinguishable terms."
  ))
}

# Native binomial admission for scalar mu targets and members of one ordinary
# correlated block. Keep identity resolution separate from the family-specific
# shape fence.
drm_binomial_sd_mu_targets <- function(entries, terms, re) {
  drm_scalar_sd_mu_targets(
    entries, terms, re,
    family_label = "Binomial",
    allow_slopes = TRUE,
    allow_independent_same_group = TRUE,
    allow_correlated_q2 = TRUE,
    allow_correlated_blocks = TRUE
  )
}

# Family adapters opt into independently checked coefficient shapes. Identity
# resolution does not itself admit a correlated or mixed block.
drm_scalar_sd_mu_targets <- function(entries, terms, re, family_label,
                                     allow_slopes = FALSE,
                                     allow_independent_same_group = FALSE,
                                     allow_correlated_q2 = FALSE,
                                     allow_correlated_blocks = FALSE,
                                     target_dpar = "mu") {
  if (length(entries) == 0L) return(list())
  members <- drm_ordinary_sd_target_members(terms, re, target_dpar)
  if (length(members) == 0L) {
    cli::cli_abort(c(
      "No random-effect term matches the {family_label} {.code sd()} formula for {.code {target_dpar}}.",
      "i" = "Add an ordinary {.code (1 | group)} term to {.code {target_dpar}} or remove the SD formula."
    ))
  }
  targets <- lapply(entries, function(entry) {
    parsed <- parse_sd_lhs(entry$lhs)
    member <- drm_resolve_sd_target(parsed, members)
    term <- terms[[member$target_term]]
    allowed <- if (isTRUE(allow_slopes)) c("intercept", "slope") else "intercept"
    correlated_q2_target <-
      isTRUE(allow_correlated_q2) &&
      identical(term$type, "correlated_slope") &&
      length(term$coef_names) == 2L &&
      identical(term$coef_names[[1L]], "(Intercept)") &&
      !identical(term$coef_names[[2L]], "(Intercept)") &&
      is.null(term$covariance_label) &&
      member$coef %in% term$coef_names
    correlated_block_target <-
      isTRUE(allow_correlated_blocks) &&
      identical(term$type, "correlated_block") &&
      length(term$coef_names) >= 3L &&
      identical(term$coef_names[[1L]], "(Intercept)") &&
      all(term$coef_names[-1L] != "(Intercept)") &&
      is.null(term$covariance_label) &&
      member$coef %in% term$coef_names
    scalar_target <- term$type %in% allowed &&
      length(term$coef_names) == 1L &&
      !(identical(term$type, "intercept") &&
          !identical(member$coef, "(Intercept)")) &&
      !(identical(term$type, "slope") &&
          identical(member$coef, "(Intercept)"))
    if (!scalar_target && !correlated_q2_target && !correlated_block_target) {
      cli::cli_abort(c(
        "{family_label} random-effect SD regression does not support the selected random-effect shape.",
        "x" = "Selected {.code {entry$dpar}} targets coefficient {.val {member$coef}}.",
        "i" = if (isTRUE(allow_slopes)) {
          "Use a scalar intercept or independent slope, or an unlabelled correlated block where the family admits one."
        } else {
          "Random-slope and correlated-block SD regression require separate likelihood checks."
        }
      ))
    }
    same_group <- Filter(function(x) identical(x$group, member$group), members)
    if (length(same_group) > 1L) {
      same_group_terms <- vapply(
        same_group, function(x) x$target_term, integer(1L)
      )
      independent_same_group <-
        isTRUE(allow_independent_same_group) &&
        !anyDuplicated(same_group_terms) &&
        all(vapply(same_group, function(x) {
          terms[[x$target_term]]$type %in% c("intercept", "slope") &&
            length(terms[[x$target_term]]$coef_names) == 1L
        }, logical(1L)))
      correlated_q2_same_group <-
        isTRUE(allow_correlated_q2) &&
        length(same_group) == 2L &&
        length(unique(same_group_terms)) == 1L &&
        identical(term$type, "correlated_slope") &&
        length(term$coef_names) == 2L &&
        identical(term$coef_names[[1L]], "(Intercept)") &&
        !identical(term$coef_names[[2L]], "(Intercept)") &&
        is.null(term$covariance_label) &&
        all(vapply(same_group, function(x) {
          identical(x$target_term, member$target_term) &&
            x$coef %in% term$coef_names
        }, logical(1L)))
      correlated_block_same_group <-
        isTRUE(allow_correlated_blocks) &&
        length(same_group) == length(term$coef_names) &&
        length(unique(same_group_terms)) == 1L &&
        identical(term$type, "correlated_block") &&
        length(term$coef_names) >= 3L &&
        identical(term$coef_names[[1L]], "(Intercept)") &&
        all(term$coef_names[-1L] != "(Intercept)") &&
        is.null(term$covariance_label) &&
        all(vapply(same_group, function(x) {
          identical(x$target_term, member$target_term) &&
            x$coef %in% term$coef_names
        }, logical(1L)))
      if (!independent_same_group && !correlated_q2_same_group &&
          !correlated_block_same_group) {
        cli::cli_abort(c(
          "{family_label} scalar SD regression cannot yet combine another random-effect coefficient on the same group.",
          "x" = "Selected {.code {entry$dpar}} but group {.field {member$group}} has more than one coefficient.",
          "i" = "Fit one q1 coefficient for this group until mixed or correlated SD targets have been checked."
        ))
      }
    }
    list(
      dpar = entry$dpar,
      group = member$group,
      target_term = member$target_term,
      target_coef = member$target_coef,
      label = member$label,
      identity = member
    )
  })
  dpars <- vapply(targets, `[[`, character(1L), "dpar")
  if (anyDuplicated(dpars)) {
    cli::cli_abort("Duplicate random-effect scale formula {.code {dpars[duplicated(dpars)][[1L]]}}.")
  }
  coefficients <- vapply(targets, `[[`, integer(1L), "target_coef")
  if (anyDuplicated(coefficients)) {
    duplicate <- dpars[duplicated(coefficients)][[1L]]
    cli::cli_abort("Duplicate random-effect scale target {.code {duplicate}}: each latent coefficient can have only one SD formula.")
  }
  targets
}
