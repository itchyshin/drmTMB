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

#' Planned phylogenetic structured-effect marker
#'
#' `phylo()` reserves user-facing syntax for phylogenetic dependence. The
#' planned grammar is structured random-effect syntax such as
#' `phylo(1 | species, tree = tree)` and, later,
#' `phylo(1 + x | species, tree = tree)`. The public `phylo()` API should
#' require an ultrametric tree with branch lengths and use the Hadfield and
#' Nakagawa A-inverse sparse-precision path internally.
#'
#' @param term Planned structured random-effect term, such as `1 | species`.
#' @param tree Planned ultrametric phylogeny input with branch lengths.
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
#' bf(y ~ x + spatial(1 | site, coords = coords), sigma ~ z)
#' bf(y ~ x + spatial(1 | site, mesh = mesh), sigma ~ z)
spatial <- function(term, coords = NULL, mesh = NULL) {
  invisible(NULL)
}
