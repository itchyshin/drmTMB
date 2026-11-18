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
#'   scale models and ordinary Bernoulli/binomial intercepts or independent
#'   numeric slopes in the native R/TMB development branch; a Julia candidate
#'   has been tested only with a matching local DRM.jl source checkout. That
#'   route is not in the current shared or released DRM.jl companion. Predictors
#'   must be constant within each retained group;
#' * `sd(group, dpar = "sigma") ~ predictors` for a native Gaussian model with
#'   one ordinary random intercept on the `sigma` predictor, or
#'   `sd(group, dpar = "sigma", coef = "x") ~ predictors` for one independent
#'   numeric random slope. Both development routes require a fixed-effects-only
#'   `mu` formula, complete unaggregated data, and a predictor that is constant
#'   within each group. Julia parity and other `sigma` random-effect structures
#'   remain under development;
#' * native complete-data LogNormal models also support one independent
#'   numeric random slope on the `sigma` predictor with
#'   `sd(group, dpar = "sigma", coef = "x") ~ predictors`. The `mu` formula
#'   must be fixed-effect-only, and the SD predictor must be constant within
#'   each group. Other LogNormal `sigma` random-effect structures and Julia
#'   parity remain under development;
#' * native complete-data, non-inflated NB2 also supports one independent
#'   random slope on the `sigma` predictor with
#'   `sd(group, dpar = "sigma", coef = "x") ~ predictors`. The `mu` formula
#'   must be fixed-effect-only, and the SD predictor must be constant within
#'   each group. Zero-inflated NB2 and other `sigma` random-effect structures
#'   remain under development;
#' * `sd(group, dpar = "mu", coef = "x") ~ predictors` selects an ordinary
#'   coefficient-specific target in Bernoulli/binomial models, including the
#'   intercept and slope members of one unlabelled correlated block; omit
#'   selectors when the target is unique. The native engine also supports a
#'   matching `block` selector for labelled scalar intercepts;
#' * native Bernoulli/binomial models also support a single relatedness-matrix
#'   intercept with `sd(group, level = "relmat") ~ predictors`;
#' * native Bernoulli/binomial models support supplied animal-model q1
#'   intercepts and one unlabelled intercept-plus-slope block with separate
#'   coefficient-specific SD formulas. The q2 SD route currently supports
#'   complete, unweighted 0/1 responses under logit, probit, or cloglog links,
#'   with `A`, `Ainv`, or pedigree inputs, and no other random effects;
#'   predictors must be constant within each animal ID. Julia parity and
#'   interval coverage for this q2 route have not been established;
#' * native Bernoulli/binomial models also support one fixed-kappa mesh
#'   spatial location intercept, written
#'   `spatial(1 | site, mesh = mesh)` with
#'   `sd(site, level = "spatial") ~ predictors`. This initial route requires
#'   complete responses, one location SD formula, and no other random effects;
#'   it is ML-only. The SD formula is a multiplier on the supplied mesh field,
#'   so the marginal SD after mesh projection also depends on the mesh
#'   covariance. R-to-Julia bridge parity and interval calibration are not
#'   established;
#' * native non-inflated Poisson models support one complete-data,
#'   supplied-`A` animal-model intercept or slope-only coefficient with this
#'   `level = "animal"` syntax; intercept-plus-slope animal blocks are not part
#'   of this direct-SD route;
#' * native complete-data NB2 models support one animal location intercept or
#'   one slope-only coefficient with a predictor-dependent SD when `sigma ~ 1`;
#'   the animal model cannot be combined with other random or structured terms;
#' * native complete-data Gamma models support one animal location intercept
#'   or one slope-only coefficient with a group-level SD predictor and fixed
#'   `sigma`; multi-coefficient animal blocks remain unsupported;
#' * native Poisson supports ordinary intercept SD regression, with `dpar`
#'   and `coef` selectors for an unlabelled intercept;
#' * `sd1(group) ~ predictors` and `sd2(group) ~ predictors` for bivariate
#'   Gaussian location random-effect scale models targeting `mu1` and `mu2`;
#' * `sd(group, level = "phylogenetic") ~ predictors` for univariate Gaussian
#'   phylogenetic location random-effect scale models;
#' * `sd(pair_id, level = "phylogenetic_interaction") ~ predictors` for a
#'   native Binomial location SD regression on an existing q1
#'   `phylo_interaction()` field. The pair identifier must map one-to-one to
#'   observed partner pairs, and each SD predictor must be constant within a
#'   pair. Julia direct fitting and the R-to-Julia bridge remain unsupported;
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
#' session and should not be used in new formulas. Other spatial direct-SD
#' routes should use the same `level = ` grammar, such as
#' `sd(group, level = "spatial")`
#' or `sd1(group, level = "animal")`, rather than adding parallel
#' `sd_spatial*()`, `sd_animal*()`, and `sd_relmat*()` families.
#'
#' These formulas model the standard deviation of a latent random-effect block.
#' They are distinct from residual scale formulas such as `sigma ~ predictors`
#' and from latent correlation formulas such as [corpair()]. Bernoulli/binomial
#' and Poisson SDs are on the response-link scale; they do not add a free
#' residual `sigma`. Synthetic Bernoulli/binomial point-recovery, public-output,
#' simulation, and profile/bootstrap-refit checks cover native R/TMB and the
#' Julia candidate with a matching local DRM.jl checkout. These tests do not
#' establish cross-engine parity or interval calibration. The Julia q2
#' correlated-block smoke tests include a near-singular Hessian warning, so
#' they do not establish reliable Wald intervals. A separate narrow beta
#' phylogenetic direct-SD route
#' also exists. Other family/effect combinations and spatial direct-SD
#' structures beyond the initial Binomial mesh intercept,
#' animal-model SDs outside the native Bernoulli/binomial and Poisson
#' intercept and slope-only slices,
#' relatedness-matrix SDs outside the native Bernoulli/binomial
#' intercept slice, and interval calibration remain under development.
#'
#' @return A formula-syntax reference page; no object is returned.
#'
#' @examples
#' bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ habitat)
#'
#' # A labelled scalar target for a native binomial() model
#' bf(y ~ x + (1 | p | id),
#'    sd(id, dpar = "mu", coef = "(Intercept)", block = "p") ~ habitat)
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
#'   y ~ x + animal(1 | id, A = A),
#'   sd(id, level = "animal") ~ habitat
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
