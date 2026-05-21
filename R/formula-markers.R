#' Known sampling covariance terms
#'
#' `meta_V()` and `meta_known_V()` mark known sampling variance or covariance
#' in a formula. They are designed for meta-analysis and other regression
#' problems where part of the observation covariance is known in advance.
#' `meta_V(V = V)` is the preferred spelling; `meta_known_V(V = V)` is retained
#' as a compatibility alias.
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
#' bf(yi ~ moderator + meta_known_V(V = vi), sigma ~ moderator)
meta_V <- function(V) {
  invisible(NULL)
}

#' @rdname meta_V
#' @export
meta_known_V <- function(V) {
  invisible(NULL)
}

#' Legacy reserved known-covariance group effect marker
#'
#' `gr()` is an older reserved marker for group-level effects with a
#' user-supplied covariance matrix. New user-facing documentation should prefer
#' the biological and matrix-specific structured-effect markers: [animal()] for
#' pedigree or additive-relatedness animal models, [phylo()] for phylogenetic
#' dependence, [spatial()] for spatial dependence, and [relmat()] for a
#' validated user-supplied relatedness or precision matrix. `gr()` remains
#' reserved while that clearer surface is completed.
#'
#' @param group Grouping factor.
#' @param cov Known covariance or precision structure.
#'
#' @return A formula marker; never evaluated by users.
#' @export
gr <- function(group, cov) {
  invisible(NULL)
}

#' Animal-model structured-effect marker
#'
#' `animal()` marks pedigree or additive-relatedness animal-model syntax. It is
#' the biological front door for questions such as whether among-individual
#' additive genetic variance appears in the location `mu`, residual scale
#' `sigma`, shape or skewness, inflation, or a bivariate covariance. The fitted
#' known-matrix routes are a univariate Gaussian `mu` random intercept with a
#' precomputed additive relationship matrix `A` or inverse relationship matrix
#' `Ainv`, for example `animal(1 | id, Ainv = Ainv)`, and the first bivariate
#' Gaussian q=2 location covariance from matching labelled terms in `mu1` and
#' `mu2`, for example `animal(1 | p | id, Ainv = Ainv)`. Direct
#' pedigree-to-Ainv construction, structured slopes, `sigma` animal models,
#' q=4 location-scale blocks, predictor-dependent `corpair()` regression, and
#' generic direct-SD grammar remain planned.
#'
#' @param term Structured random-effect term, such as `1 | id`.
#' @param pedigree Planned pedigree input from which an additive relationship
#'   matrix or sparse inverse will be built.
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
#' # Planned later: distributional animal model for residual predictability.
#' bf(activity ~ treatment + animal(1 | id, pedigree = pedigree),
#'   sigma ~ treatment
#' )
animal <- function(term, pedigree = NULL, A = NULL, Ainv = NULL) {
  invisible(NULL)
}

#' Phylogenetic structured-effect marker
#'
#' `phylo()` marks user-facing syntax for phylogenetic dependence. The current
#' fitted paths support intercept-only Gaussian location effects,
#' response-specific direct-SD formulas, and labelled bivariate Gaussian
#' location-scale blocks. Use `phylo(1 | species, tree = tree)` in univariate
#' `mu`, matching terms in bivariate `mu1` and `mu2`, or matching labelled
#' all-four terms across `mu1`, `mu2`, `sigma1`, and `sigma2`. A single shared
#' label estimates the full q4 block; a `mu1`/`mu2` label plus a separate
#' `sigma1`/`sigma2` label estimates the block-diagonal fallback. Standalone
#' univariate `sigma ~ phylo(...)` and structured phylogenetic slopes such as
#' `phylo(1 + x | species, tree = tree)` remain planned even though the
#' coordinate-spatial sibling already fits one numeric `mu` slope. The public
#' `phylo()` API requires an
#' ultrametric tree with branch lengths and uses the Hadfield and Nakagawa
#' A-inverse sparse-precision path internally.
#'
#' @param term Structured random-effect term, currently `1 | species`.
#' @param tree Ultrametric phylogeny input with branch lengths.
#'
#' @return A formula marker; never evaluated by users.
#' @export
#'
#' @examples
#' bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ z)
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
#' fields with separate SDs and no intercept-slope correlation. Mesh inputs,
#' scale formulas, multiple structured slopes, slope correlations, and bivariate
#' spatial blocks remain planned.
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
#' # Planned:
#' bf(y ~ x + spatial(1 | site, mesh = mesh), sigma ~ z)
spatial <- function(term, coords = NULL, mesh = NULL) {
  invisible(NULL)
}

#' User-supplied relatedness structured-effect marker
#'
#' `relmat()` marks syntax for a validated user-supplied relatedness matrix. It
#' is the lower-level route for dependence structures that are not best named as
#' `animal()`, `phylo()`, or `spatial()`: for example a genomic relationship
#' matrix, a laboratory relatedness kernel, or a precision matrix built outside
#' `drmTMB` and checked by the analyst.
#'
#' Use `K` for a covariance or relatedness matrix and `Q` for an inverse
#' covariance or precision matrix. The fitted known-matrix routes are a
#' univariate Gaussian `mu` random intercept, for example
#' `relmat(1 | line, Q = Q)`, and the first bivariate Gaussian q=2 location
#' covariance from matching labelled terms in `mu1` and `mu2`, for example
#' `relmat(1 | p | line, Q = Q)`. Structured slopes, `sigma` relatedness
#' models, q=4 location-scale blocks, predictor-dependent `corpair()`
#' regression, and generic direct-SD grammar remain planned. `relmat()` is
#' intentionally separate from [meta_V()], which adds known sampling covariance
#' among observations, and from residual `rho12`, which models
#' within-observation bivariate residual correlation.
#'
#' @param term Structured random-effect term, such as `1 | id`.
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
#' `corpair(id, level = "group", block = "p", from = "mu1", to = "mu2") ~ x`.
#' and
#' `corpair(species, level = "phylogenetic", block = "p", from = "mu1", to = "mu2") ~ ecology`.
#' Predictors must be constant within the grouping factor. Spatial,
#' location-scale, scale-scale, and q=4 `corpair()` regressions remain planned.
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
