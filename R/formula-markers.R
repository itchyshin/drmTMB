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

#' Known-covariance group effect
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

#' Phylogenetic group effect
#'
#' `phylo()` reserves user-facing syntax for phylogenetic dependence. Future
#' implementations will use a sparse A-inverse path when a tree is supplied.
#'
#' @param species Species or taxon factor.
#'
#' @return A formula marker; never evaluated by users.
#' @export
phylo <- function(species) {
  invisible(NULL)
}

#' Spatial effect
#'
#' `spatial()` reserves user-facing syntax for spatial dependence. Future
#' implementations will use an SPDE/GMRF representation.
#'
#' @param ... Coordinate columns or a spatial term specification.
#'
#' @return A formula marker; never evaluated by users.
#' @export
spatial <- function(...) {
  invisible(NULL)
}
