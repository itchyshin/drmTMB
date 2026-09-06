# Name-normalised coefficient and SE readers for the REML bridge receipts.
#
# engine = "tmb" spells a coefficient `mu.(Intercept)` in coef() and
# `mu:(Intercept)` in summary()/vcov(); the bridge uses the same separators.
# Comparing without normalising both silently yields an EMPTY intersection,
# which reads exactly like "the engines share no parameters" -- a false
# negative this leaf hit before catching it.
drm_reml_normalise_names <- function(x) gsub("[.:]", "_", x)

drm_reml_named_coef <- function(fit) {
  cf <- stats::coef(fit)
  if (is.list(cf)) cf <- unlist(cf)
  stats::setNames(as.numeric(cf), drm_reml_normalise_names(names(cf)))
}

# summary()$coefficients FIRST, vcov() as the fallback -- and the fallback is
# load-bearing, not defensive padding: on an `engine = "julia"` REML fit
# summary()$coefficients carries no `std_error` column at all (measured
# 2026-09-05 on the cell-2 fixture), while vcov() returns a usable matrix. A
# reader who only tries summary() concludes the bridge reports no SEs, which is
# wrong.
drm_reml_named_se <- function(fit) {
  s <- try(summary(fit)$coefficients, silent = TRUE)
  if (!inherits(s, "try-error") && !is.null(s) && "std_error" %in% colnames(s)) {
    return(stats::setNames(
      as.numeric(s[, "std_error"]), drm_reml_normalise_names(rownames(s))
    ))
  }
  v <- as.matrix(stats::vcov(fit))
  stats::setNames(sqrt(diag(v)), drm_reml_normalise_names(rownames(v)))
}
