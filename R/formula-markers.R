#' Known sampling covariance marker
#'
#' `meta_V()` marks known sampling variance or covariance in a formula. It is
#' designed for meta-analysis and other regression problems where part of the
#' observation covariance is known in advance.
#'
#' @param V A column name, vector, diagonal matrix, block-diagonal matrix, or
#'   full covariance matrix. Diagonal/vector `V` represents independent known
#'   sampling variances. A matrix represents the known covariance among rows.
#'
#' @return A formula marker; never evaluated by users.
#' @export
#'
#' @examples
#' bf(yi ~ moderator + meta_V(V = vi), sigma ~ moderator)
meta_V <- function(V) {
  invisible(NULL)
}

#' Deprecated known sampling covariance marker
#'
#' `meta_known_V()` is deprecated as a formula marker in `drmTMB 0.1.3.9000`.
#' Use [meta_V()] for known sampling variance or covariance. The deprecated
#' marker still routes to the same additive known-`V` likelihood path for
#' compatibility.
#'
#' @inheritParams meta_V
#'
#' @return A formula marker; never evaluated by users.
#' @keywords internal
#' @export
meta_known_V <- function(V) {
  warn_meta_known_v_deprecated()
  invisible(NULL)
}

warn_meta_known_v_deprecated <- function() {
  .Deprecated(
    old = "meta_known_V()",
    new = "meta_V()",
    msg = paste(
      "`meta_known_V()` is deprecated as a drmTMB formula marker.",
      "Use `meta_V(V = V)` for known sampling variance or covariance."
    )
  )
  invisible(NULL)
}

#' Deprecated legacy known-covariance group effect marker
#'
#' `gr()` is deprecated as a public formula marker in `drmTMB 0.1.3.9000`.
#' Use [relmat()] for a validated lower-level user-supplied relatedness or
#' precision matrix, [animal()] for pedigree or additive-relatedness animal
#' models, [phylo()] for phylogenetic dependence, or [spatial()] for spatial
#' dependence. The exported `gr()` placeholder remains only for compatibility
#' with older design notes and should not be used in new model formulas.
#'
#' @param group Grouping factor.
#' @param cov Known covariance or precision structure.
#'
#' @return A formula marker; never evaluated by users.
#' @keywords internal
#' @export
gr <- function(group, cov) {
  .Deprecated(
    msg = paste(
      "`gr()` is deprecated as a public drmTMB formula marker.",
      "Use `relmat()` for lower-level known relatedness matrices,",
      "or `animal()`, `phylo()`, or `spatial()` for biological structured effects."
    )
  )
  invisible(NULL)
}

#' Animal-model structured-effect marker
#'
#' `animal()` marks pedigree or additive-relatedness animal-model syntax. It is
#' the biological front door for questions such as whether among-individual
#' additive genetic variance appears in the location `mu`, residual scale
#' `sigma`, shape or skewness, inflation, or a bivariate covariance. The fitted
#' routes are univariate Gaussian `mu` and `sigma` random intercepts from a
#' small pedigree data frame, precomputed additive relationship matrix `A`, or
#' inverse relationship matrix `Ainv`, for example
#' `animal(1 | id, pedigree = pedigree)` or
#' `animal(1 | id, Ainv = Ainv)`. Matching univariate `mu` and `sigma`
#' intercept terms estimate one animal-model mean-scale correlation. The first
#' bivariate Gaussian q=2 location covariance comes from matching labelled
#' terms in `mu1` and `mu2`, and the constant all-four q=4 location-scale block
#' comes from matching labelled terms in `mu1`,
#' `mu2`, `sigma1`, and `sigma2`, for example
#' `animal(1 | p | id, pedigree = pedigree)`. The pedigree route builds a dense
#' additive relationship matrix from `id`, `dam`, and `sire` columns. The
#' univariate Gaussian `mu` path also supports one numeric slope, for example
#' `animal(1 + x | id, pedigree = pedigree)`, as independent intercept and
#' slope fields with separate SDs and no intercept-slope correlation.
#' Large-pedigree sparse precision construction, multiple structured slopes,
#' slope correlations, predictor-dependent `corpair()` regression,
#' residual-scale structured slopes, and animal-model `sd*()` direct-SD grammar
#' remain planned.
#'
#' @param term Structured random-effect term, such as `1 | id` or
#'   `1 + x | id`.
#' @param pedigree Pedigree data frame with columns `id`, `dam`, and `sire`.
#'   Unknown parents can be `NA`, `""`, or `"0"`. The first fitted route builds
#'   a dense additive relationship matrix for Gaussian `mu` animal effects.
#' @param A Additive relatedness or covariance matrix for the first fitted
#'   univariate Gaussian `mu` path.
#' @param Ainv Sparse or dense inverse additive relatedness matrix for the first
#'   fitted univariate Gaussian `mu` path.
#'
#' @return A formula marker; never evaluated by users.
#' @export
#'
#' @examples
#' # Fitted: additive genetic variance in body size from a precomputed Ainv.
#' bf(body_size ~ age + sex + animal(1 | id, Ainv = Ainv),
#'   sigma ~ habitat
#' )
#'
#' # Fitted: the same route can build a small additive matrix from a pedigree.
#' bf(activity ~ treatment + animal(1 | id, pedigree = pedigree),
#'   sigma ~ treatment
#' )
animal <- function(term, pedigree = NULL, A = NULL, Ainv = NULL) {
  invisible(NULL)
}

#' Phylogenetic structured-effect marker
#'
#' `phylo()` marks user-facing syntax for phylogenetic dependence. The current
#' fitted paths support Gaussian location and residual-scale effects,
#' response-specific direct-SD formulas for location effects, labelled
#' bivariate Gaussian location-scale blocks, and the first ordinary Poisson q=1
#' and NB2 q=1 location effects. Use `phylo(1 | species, tree = tree)` in
#' univariate Gaussian `mu`, univariate Gaussian `sigma`, ordinary Poisson `mu`,
#' or ordinary NB2 `mu`, one numeric univariate Gaussian `mu` slope with
#' independent intercept/slope SDs, matching univariate Gaussian `mu` and
#' `sigma` intercept terms for a mean-scale phylogenetic correlation, matching
#' terms in bivariate Gaussian `mu1` and `mu2`, or matching labelled all-four
#' terms across Gaussian `mu1`, `mu2`, `sigma1`, and `sigma2`. A single shared
#' label estimates the full q4 block; a `mu1`/`mu2` label plus a separate
#' `sigma1`/`sigma2` label estimates the block-diagonal fallback. Poisson and
#' NB2 phylogenetic slopes, zero-inflated phylogenetic effects, multiple
#' phylogenetic slopes, residual-scale structured slopes, and phylogenetic slope
#' correlations remain planned. The public `phylo()` API
#' requires an
#' ultrametric tree with branch lengths and uses the Hadfield and Nakagawa
#' A-inverse sparse-precision path internally.
#'
#' @param term Structured random-effect term, currently `1 | species` or
#'   `1 + x | species`.
#' @param tree Ultrametric phylogeny input with branch lengths.
#'
#' @return A formula marker; never evaluated by users.
#' @export
#'
#' @examples
#' bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ z)
#' bf(count ~ x + phylo(1 | species, tree = tree))
phylo <- function(term, tree) {
  invisible(NULL)
}

#' Spatial structured-effect marker
#'
#' `spatial()` marks structured spatial dependence. The first fitted path is
#' the univariate Gaussian location random intercept
#' `spatial(1 | site, coords = coords)`, where `coords` is a matrix or data
#' frame with one row per site or one row per observation. The univariate
#' Gaussian location path also supports one numeric slope,
#' `spatial(1 + x | site, coords = coords)`, as independent intercept and slope
#' fields with separate SDs and no intercept-slope correlation. Matching
#' labelled bivariate Gaussian `mu1`/`mu2` terms fit the first q=2
#' coordinate-spatial location covariance, matching univariate Gaussian `mu` and
#' `sigma` intercept terms fit one spatial mean-scale correlation, and matching
#' labelled all-four `mu1`/`mu2`/`sigma1`/`sigma2` terms fit the first constant
#' q=4 location-scale block. Mesh inputs, multiple structured slopes,
#' residual-scale structured slopes, slope correlations, predictor-dependent
#' spatial `corpair()` regression, and non-Gaussian spatial effects remain
#' planned.
#'
#' @param term Structured random-effect term, such as `1 | site`.
#' @param coords Coordinate object, such as a data frame or matrix of spatial
#'   coordinates.
#' @param mesh Planned precomputed mesh object.
#'
#' @return A formula marker; never evaluated by users.
#' @export
#'
#' @examples
#' # Fitted for univariate Gaussian mu with coords:
#' bf(y ~ x + spatial(1 | site, coords = coords), sigma ~ z)
#' # Fitted first q=2 bivariate spatial location block:
#' bf(
#'   mu1 = y1 ~ x + spatial(1 | p | site, coords = coords),
#'   mu2 = y2 ~ x + spatial(1 | p | site, coords = coords),
#'   sigma1 = ~ 1,
#'   sigma2 = ~ 1,
#'   rho12 = ~ 1
#' )
#' # Planned:
#' bf(y ~ x + spatial(1 | site, mesh = mesh), sigma ~ z)
spatial <- function(term, coords = NULL, mesh = NULL) {
  invisible(NULL)
}

#' User-supplied relatedness structured-effect marker
#'
#' `relmat()` marks syntax for a validated user-supplied relatedness matrix. It
#' is the lower-level route for latent group-level dependence structures that
#' are not best named as `animal()`, `phylo()`, or `spatial()`: for example a
#' genomic relationship matrix, a laboratory relatedness kernel, or a graph,
#' river-network, areal, or Gaussian Markov random-field precision matrix built
#' outside `drmTMB` and checked by the analyst. If the matrix is known sampling
#' covariance among observed estimates, use [meta_V()] instead.
#'
#' Use `K` for a covariance or relatedness matrix and `Q` for an inverse
#' covariance or precision matrix. A correlation matrix with diagonal 1 is a
#' natural `K` input because the fitted relatedness SD supplies the latent
#' variance scale. The fitted known-matrix routes are a univariate Gaussian
#' `mu` random intercept, for example
#' `relmat(1 | line, Q = Q)`, the first bivariate Gaussian q=2 location
#' covariance from matching labelled terms in `mu1` and `mu2`, matching
#' univariate Gaussian `mu` and `sigma` intercept terms estimate one
#' relatedness mean-scale correlation, and the constant all-four q=4
#' location-scale block comes from matching labelled terms in `mu1`, `mu2`,
#' `sigma1`, and `sigma2`, for example `relmat(1 | p | line, Q = Q)`. The
#' univariate Gaussian `mu` path also
#' supports one numeric slope, for example `relmat(1 + x | line, Q = Q)`, as
#' independent intercept and slope fields with separate SDs and no
#' intercept-slope correlation. Multiple structured slopes, slope correlations,
#' residual-scale structured slopes, predictor-dependent `corpair()`
#' regression, and relatedness `sd*()` direct-SD grammar remain planned.
#' `relmat()` is
#' intentionally separate from [meta_V()], which adds known sampling covariance
#' among observations, and from residual `rho12`, which models
#' within-observation bivariate residual correlation.
#'
#' @param term Structured random-effect term, such as `1 | id` or
#'   `1 + x | id`.
#' @param K Known relatedness or covariance matrix for the first fitted
#'   univariate Gaussian `mu` path.
#' @param Q Known precision or inverse covariance matrix for the first fitted
#'   univariate Gaussian `mu` path.
#'
#' @return A formula marker; never evaluated by users.
#' @export
#'
#' @examples
#' # Fitted: a genomic relatedness matrix for among-line genetic variance.
#' bf(seed_mass ~ temperature + relmat(1 | line, K = G),
#'   sigma ~ temperature
#' )
#'
#' # Fitted: a user-built sparse precision for another dependence structure.
#' bf(growth ~ treatment + relmat(1 | plot, Q = Q_plot),
#'   sigma ~ treatment
#' )
relmat <- function(term, K = NULL, Q = NULL) {
  invisible(NULL)
}

#' Latent random-effect correlation formula marker
#'
#' `corpair()` marks predictor-dependent latent random-effect correlations. It
#' is distinct from residual `rho12` and from the [corpairs()] extractor. The
#' first fitted paths are q=2 location-location cases for matching labelled
#' `mu1`/`mu2` random intercepts:
#' `corpair(id, level = "group", block = "p", from = "mu1", to = "mu2") ~ x`
#' and
#' `corpair(species, level = "phylogenetic", block = "p", from = "mu1", to = "mu2") ~ ecology`.
#' Predictors must be constant within the grouping factor. Spatial
#' `corpair()` regressions, location-scale `corpair()` regressions,
#' scale-scale `corpair()` regressions, and q=4 `corpair()` regressions remain
#' planned.
#' The phylogenetic q=2 route uses a positive-definite two-field loading
#' contract for the whole tree-coupled species block.
#'
#' @param group Grouping factor for the latent covariance block.
#' @param level Optional latent correlation level, such as `"group"`,
#'   `"phylogenetic"`, or `"spatial"`.
#' @param block Optional covariance-block label, such as `"p"`.
#' @param class Optional latent correlation class: `"location-location"`,
#'   `"location-scale"`, or `"scale-scale"`. This is an extraction-oriented
#'   shorthand and is not the first fitted q=4 correlation-regression target.
#' @param from,to Optional endpoint-specific distributional parameters, such as
#'   `"mu1"` and `"mu2"` for the first fitted q=2 targets, or
#'   `"mu1"` and `"sigma2"` for later location-scale targets.
#'
#' @return A formula marker; never evaluated by users.
#' @export
#'
#' @examples
#' bf(corpair(id, level = "group", block = "p",
#'   from = "mu1", to = "mu2") ~ ecology)
#'
#' # fitted q=2 phylogenetic sibling
#' bf(corpair(species, level = "phylogenetic", block = "p",
#'   from = "mu1", to = "mu2") ~ ecology)
corpair <- function(
  group,
  level = NULL,
  block = NULL,
  class = NULL,
  from = NULL,
  to = NULL
) {
  invisible(NULL)
}
