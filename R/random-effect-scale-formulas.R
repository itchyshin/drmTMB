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
#' * `sd_phylo(species) ~ predictors` for univariate Gaussian phylogenetic
#'   location random-effect scale models;
#' * `sd_phylo1(species) ~ predictors` and
#'   `sd_phylo2(species) ~ predictors` for bivariate Gaussian phylogenetic
#'   location random-effect scale models targeting `mu1` and `mu2`.
#'
#' The `sd_phylo*()` spellings are the current implemented phylogenetic
#' direct-SD interface, but they should not be treated as a pattern to clone for
#' every structured-effect family. Future spatial, animal-model, and
#' user-supplied relatedness direct-SD routes should prefer a generic spelling
#' such as `sd(group, level = "spatial")`, `sd1(group, level = "animal")`, or a
#' closely reviewed equivalent, rather than adding parallel `sd_spatial*()`,
#' `sd_animal*()`, and `sd_relmat*()` families.
#'
#' These formulas model the standard deviation of a latent random-effect block.
#' They are distinct from residual scale formulas such as `sigma ~ predictors`
#' and from latent correlation formulas such as [corpair()]. Non-Gaussian
#' random-effect scale formulas, spatial direct-SD formulas, and explicit
#' coefficient-specific targets such as
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
#'   sd_phylo(species) ~ ecology
#' )
#'
#' @name random_effect_scale_formulas
#' @aliases sd sd1 sd2 sd_phylo sd_phylo1 sd_phylo2
NULL
