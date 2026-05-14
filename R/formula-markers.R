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

#' Planned known-covariance group effect marker
#'
#' `gr()` reserves syntax for group-level effects with a user-supplied
#' covariance matrix. It is the planned low-level foundation for phylogenetic
#' and other structured random effects.
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
#' bivariate `mu1` and `mu2`. Later phases will add structured slopes such as
#' `phylo(1 + x | species, tree = tree)`. The public `phylo()` API requires an
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

#' Planned spatial structured-effect marker
#'
#' `spatial()` reserves user-facing syntax for spatial dependence. The planned
#' grammar is structured random-effect syntax such as
#' `spatial(1 | site, coords = coords)` and, later,
#' `spatial(1 + depth | site, coords = coords)`. Future implementations will
#' use an SPDE/GMRF representation built from coordinates or a mesh.
#'
#' @param term Planned structured random-effect term, such as `1 | site`.
#' @param coords Planned coordinate object, such as a data frame or matrix of
#'   spatial coordinates.
#' @param mesh Planned precomputed mesh object.
#'
#' @return A formula marker; never evaluated by users.
#' @export
#'
#' @examples
#' # planned only; drmTMB() will currently reject spatial terms
#' bf(y ~ x + spatial(1 | site, coords = coords), sigma ~ z)
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
