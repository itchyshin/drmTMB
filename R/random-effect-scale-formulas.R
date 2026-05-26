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
#' * `sd(species, level = "phylogenetic") ~ predictors` for univariate
#'   Gaussian phylogenetic location random-effect scale models;
#' * `sd1(species, level = "phylogenetic") ~ predictors` and
#'   `sd2(species, level = "phylogenetic") ~ predictors` for bivariate
#'   Gaussian phylogenetic location random-effect scale models targeting `mu1`
#'   and `mu2`.
#'
#' The older `sd_phylo()`, `sd_phylo1()`, and `sd_phylo2()` spellings are
#' deprecated compatibility aliases. New code should use the generic `sd*()`
#' spelling with an explicit `level = "phylogenetic"` selector. Future spatial,
#' animal-model, and user-supplied relatedness direct-SD routes should use the
#' same level-based pattern, rather than adding parallel `sd_spatial*()`,
#' `sd_animal*()`, and `sd_relmat*()` families.
#'
#' These formulas model the standard deviation of a latent random-effect block.
#' They are distinct from residual scale formulas such as `sigma ~ predictors`
#' and from latent correlation formulas such as [corpair()]. Non-Gaussian
#' random-effect scale formulas, `level = "spatial"`, `level = "animal"`,
#' `level = "relmat"` direct-SD formulas, and explicit coefficient-specific
#' targets such as
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
#' bf(
#'   mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
#'   mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
#'   sd1(species, level = "phylogenetic") ~ ecology,
#'   sd2(species, level = "phylogenetic") ~ ecology
#' )
#'
#' @name random_effect_scale_formulas
#' @aliases sd sd1 sd2 sd_phylo sd_phylo1 sd_phylo2
NULL
