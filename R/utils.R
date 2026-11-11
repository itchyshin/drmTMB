# Null-default operator. Base R only exports `%||%` from 4.4.0, but the
# package declares R >= 4.1.0, so keep an internal copy with the same
# definition. Only NULL is replaced; empty vectors and NA are kept.
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

drm_suggest_closest_name <- function(x, choices) {
  if (
    !is.character(x) ||
      length(x) != 1L ||
      is.na(x) ||
      !nzchar(x) ||
      length(choices) == 0L
  ) {
    return(NULL)
  }
  i <- which.min(utils::adist(x, choices))
  choices[[i]]
}

drm_abort_unknown_fitted_dpar <- function(dpar, choices, arg = "dpar") {
  suggestion <- drm_suggest_closest_name(dpar, choices)
  bullets <- c(
    "{.arg {arg}} must exactly match one fitted parameter name.",
    "i" = "Available names: {.val {choices}}."
  )
  if (!is.null(suggestion)) {
    bullets <- c(bullets, "i" = "Did you mean {.val {suggestion}}?")
  }
  cli::cli_abort(bullets)
}

drm_resolve_fitted_dpar_name <- function(dpar, choices, arg = "dpar") {
  if (
    is.character(dpar) &&
      length(dpar) == 1L &&
      !is.na(dpar) &&
      dpar %in% choices
  ) {
    return(dpar)
  }
  drm_abort_unknown_fitted_dpar(dpar, choices, arg = arg)
}
