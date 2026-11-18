# Native Binomial labelled intercept-plus-slope structured q2 SD blocks (b32).
#
# `animal(1 + x | p | id, A = A)` (any Binomial link) and
# `phylo(1 + x | p | id, tree = tree)` (logit) with one coefficient-specific SD
# formula per coefficient use the same correlated unit-scale prior as the NB2
# and Gamma routes: the fields are N(0, R (x) K) with
# rho = 0.999999 * tanh(eta_cor_phylo), and the coefficient SDs scale the
# fields multiplicatively. Unlabelled terms keep the independent-field prior.
drm_binomial_labelled_q2_ok <- function(term, sd_entries, link) {
  if (is.null(term) || is.null(term$covariance_label)) {
    return(FALSE)
  }
  marker <- structured_mu_type(term)
  provider_ok <- (identical(marker, "animal") &&
    term$structure %in% c("A", "Ainv", "pedigree")) ||
    (identical(marker, "phylo") && identical(link, "logit"))
  provider_ok &&
    structured_term_is_intercept_one_slope(term) &&
    length(sd_entries) == 2L
}
