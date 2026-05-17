#' Known sampling covariance term
#'
#' `meta_known_V()` marks known sampling variance or covariance in a formula.
#' It is designed for meta-analysis and other regression problems where part of
#' the observation covariance is known in advance.
#'
#' @param V A column name, vector, diagonal matrix, block-diagonal matrix, or
#'   full covariance matrix. Diagonal/vector `V` represents independent known
#'   sampling variances. A matrix represents the known covariance among rows.
#'
#' @return A formula marker; never evaluated by users.
#' @export
#'
#' @examples
#' bf(yi ~ moderator + meta_known_V(V = vi), sigma ~ moderator)
meta_known_V <- function(V) {
  invisible(NULL)
}

#' Reserved known-covariance group effect marker
#'
#' `gr()` is an older reserved marker for group-level effects with a
#' user-supplied covariance matrix. The current design direction is to use a
#' clearer lower-level name such as `relmat()` if a public user-supplied
#' relatedness route is exposed, while keeping `phylo()`, `spatial()`, and
#' future `animal()` as named high-level structured-effect front doors.
#'
#' @param group Grouping factor.
#' @param cov Known covariance or precision structure.
#'
#' @return A formula marker; never evaluated by users.
#' @export
gr <- function(group, cov) {
  invisible(NULL)
}

#' Phylogenetic structured-effect marker
#'
#' `phylo()` marks user-facing syntax for phylogenetic dependence. The current
#' fitted paths support intercept-only Gaussian location effects:
#' `phylo(1 | species, tree = tree)` in univariate `mu`, or matching terms in
#' bivariate `mu1` and `mu2`. Structured phylogenetic slopes such as
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
