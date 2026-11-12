# Null-default operator. Base R only exports `%||%` from 4.4.0, but the
# package declares R >= 4.1.0, so keep an internal copy with the same
# definition. Only NULL is replaced; empty vectors and NA are kept.
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

# Unknown-name suggestions: every case-sensitive prefix of `x` in `choices`,
# or if none, every case-insensitive `adist` tie within `cutoff`. Return NULL
# when nothing is close so the caller omits a "Did you mean" line.
drm_suggest_closest_name <- function(x, choices, cutoff = 2L) {
  if (
    !is.character(x) ||
      length(x) != 1L ||
      is.na(x) ||
      !nzchar(x) ||
      length(choices) == 0L
  ) {
    return(NULL)
  }
  prefix <- choices[startsWith(choices, x)]
  if (length(prefix) > 0L) {
    return(prefix)
  }
  distances <- as.integer(utils::adist(x, choices, ignore.case = TRUE))
  min_dist <- min(distances)
  if (!is.finite(min_dist) || min_dist > cutoff) {
    return(NULL)
  }
  choices[distances == min_dist]
}

# Documented `stats::nlminb()` control element names (stable across R versions).
# Keep in sync with `names(stats:::port_cpos)`; `maxiter` is an alias for `iter.max`.
drm_nlminb_control_names <- function() {
  c(
    "eval.max", "iter.max", "trace", "maxiter", "abs.tol", "rel.tol", "x.tol",
    "xf.tol", "step.min", "step.max", "sing.tol", "scale.init", "diff.g"
  )
}
