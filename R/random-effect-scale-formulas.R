#' Random-effect scale formula syntax
#'
#' `sd(group) ~ predictors` and its siblings are formula-only syntax for
#' modelling random-effect standard deviations. They are captured by
#' [drm_formula()] or [bf()] and are not evaluated as ordinary R calls. In
#' particular, `sd(group) ~ predictors` does not replace `stats::sd()`.
#'
#' The currently documented syntax is:
#'
#' * `sd(group) ~ predictors` for univariate Gaussian location random-effect
#'   scale models;
#' * `sd1(group) ~ predictors` and `sd2(group) ~ predictors` for bivariate
#'   Gaussian location random-effect scale models targeting `mu1` and `mu2`;
#' * `sd(group, level = "phylogenetic") ~ predictors` for univariate Gaussian
#'   phylogenetic location random-effect scale models;
#' * `sd1(group, level = "phylogenetic") ~ predictors` and
#'   `sd2(group, level = "phylogenetic") ~ predictors` for bivariate Gaussian
#'   phylogenetic location random-effect scale models targeting `mu1` and
#'   `mu2`.
#'
#' `sd(group, level = "phylogenetic")` and its bivariate siblings are the
#' generic spelling for these targets. The historical spellings
#' `sd_phylo(species) ~ predictors`, `sd_phylo1(species) ~ predictors`, and
#' `sd_phylo2(species) ~ predictors` are **deprecated (soft)**: they still
#' parse and fit identically, but emit a one-time deprecation warning per
#' session and should not be used in new formulas. Future spatial,
#' animal-model, and user-supplied relatedness direct-SD routes are planned
#' to use the same `level = ` grammar, such as `sd(group, level = "spatial")`
#' or `sd1(group, level = "animal")`, rather than adding parallel
#' `sd_spatial*()`, `sd_animal*()`, and `sd_relmat*()` families.
#'
#' These formulas model the standard deviation of a latent random-effect block.
#' They are distinct from residual scale formulas such as `sigma ~ predictors`
#' and from latent correlation formulas such as [corpair()]. Non-Gaussian
#' random-effect scale formulas, spatial/animal/relmat direct-SD formulas, and
#' explicit coefficient-specific targets such as
#' `sd(group, dpar = "mu", coef = "slope") ~ predictors` remain planned.
#'
#' @return A formula-syntax reference page; no object is returned.
#'
#' @examples
#' bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ habitat)
#'
#' bf(
#'   mu1 = y1 ~ x + (1 | p | id),
#'   mu2 = y2 ~ x + (1 | p | id),
#'   sd1(id) ~ habitat,
#'   sd2(id) ~ habitat,
#'   rho12 = ~ x
#' )
#'
#' bf(
#'   y ~ x + phylo(1 | species, tree = tree),
#'   sd(species, level = "phylogenetic") ~ ecology
#' )
#'
#' @name random_effect_scale_formulas
#' @aliases sd sd1 sd2 sd_phylo sd_phylo1 sd_phylo2
NULL

# `sd_phylo()`, `sd_phylo1()`, and `sd_phylo2()` are deprecated (soft) as of
# `drmTMB 0.3.0` in favour of `sd(group, level = "phylogenetic")`,
# `sd1(group, level = "phylogenetic")`, and
# `sd2(group, level = "phylogenetic")`. This fires the one-time-per-session
# lifecycle warning; parsing and fitting are unchanged.
warn_sd_phylo_legacy_deprecated <- function(fun) {
  replacement <- switch(
    fun,
    sd_phylo = 'sd(level = "phylogenetic")',
    sd_phylo1 = 'sd1(level = "phylogenetic")',
    sd_phylo2 = 'sd2(level = "phylogenetic")'
  )
  lifecycle::deprecate_warn(
    "0.3.0",
    paste0(fun, "()"),
    replacement
  )
  invisible(NULL)
}
