#' Transform longitude and latitude to planar spatial coordinates
#'
#' Converts WGS84 longitude/latitude columns to an explicitly selected projected
#' coordinate reference system. Spatial mesh models use metric planar distances;
#' this helper deliberately does not infer a UTM zone or treat decimal degrees as
#' planar coordinates.
#'
#' @param data A non-empty data frame containing the longitude and latitude
#'   columns.
#' @param longitude,latitude Unquoted or quoted names of the longitude and
#'   latitude columns, respectively.
#' @param crs_out A projected output CRS understood by [sf::st_crs()], for
#'   example `32610` or `"EPSG:32610"`.
#'
#' @return A two-column numeric matrix with class `drmTMB_coords`. Its `crs`
#'   attribute records the projected CRS and it can be supplied to [make_mesh()].
#' @export
#'
#' @examples
#' if (requireNamespace("sf", quietly = TRUE)) {
#'   locations <- data.frame(lon = c(-123.2, -123.1), lat = c(49.2, 49.3))
#'   spatial_coords(locations, lon, lat, crs_out = 32610)
#' }
spatial_coords <- function(data, longitude, latitude, crs_out) {
  .drm_require_mesh_package("sf", "transform geographic coordinates")
  if (!is.data.frame(data) || !nrow(data)) {
    cli::cli_abort("{.arg data} must be a non-empty data frame.")
  }
  longitude <- .drm_coordinate_name(data, substitute(longitude), "longitude")
  latitude <- .drm_coordinate_name(data, substitute(latitude), "latitude")

  lon <- data[[longitude]]
  lat <- data[[latitude]]
  if (!is.numeric(lon) || !is.numeric(lat) ||
    any(!is.finite(lon)) || any(!is.finite(lat))) {
    cli::cli_abort("Longitude and latitude columns must be finite numeric values.")
  }
  if (any(lon < -180 | lon > 180) || any(lat < -90 | lat > 90)) {
    cli::cli_abort("Longitude must lie in [-180, 180] and latitude in [-90, 90].")
  }

  crs <- tryCatch(sf::st_crs(crs_out), error = function(e) NULL)
  if (is.null(crs) || is.na(crs)) {
    cli::cli_abort("{.arg crs_out} must identify a valid projected coordinate reference system.")
  }
  if (isTRUE(sf::st_is_longlat(crs))) {
    cli::cli_abort("{.arg crs_out} must be projected; longitude/latitude are not metric mesh coordinates.")
  }

  points <- sf::st_as_sf(
    data.frame(longitude = lon, latitude = lat),
    coords = c("longitude", "latitude"), crs = 4326, remove = FALSE
  )
  xy <- sf::st_coordinates(sf::st_transform(points, crs))
  storage.mode(xy) <- "double"
  if (any(!is.finite(xy))) {
    cli::cli_abort("The requested CRS transformation did not produce finite planar coordinates.")
  }
  colnames(xy) <- c("x", "y")
  rownames(xy) <- rownames(data)
  structure(xy, crs = crs, xy_cols = c("x", "y"),
    class = c("drmTMB_coords", class(xy)))
}

#' Construct a fixed-kappa SPDE mesh
#'
#' Builds a two-dimensional `fmesher` triangulation, its finite-element matrices,
#' and the observation-to-vertex projection matrix used by the fixed-kappa mesh
#' spatial field. This helper only creates the geometry and fixed SPDE inputs; it
#' neither estimates kappa nor defines a spatial likelihood.
#'
#' @param coords A finite two-column matrix or data frame of metric planar
#'   coordinates, normally returned by [spatial_coords()]. Supply `crs` when the
#'   coordinate object does not already carry it.
#' @param kappa One finite strictly positive fixed SPDE kappa value, expressed in
#'   inverse units of `coords`.
#' @param mesh Optional pre-built `fmesher` two-dimensional mesh. When supplied,
#'   it is reprojected onto `coords` and validated rather than rebuilt.
#' @param crs A projected CRS for plain planar coordinate inputs. Geographic CRS
#'   values are rejected.
#' @param ... Additional arguments passed to [fmesher::fm_mesh_2d_inla()] when a
#'   mesh is built.
#'
#' @return A `drmTMBmesh` object containing `loc_xy`, `xy_cols`, `mesh`, `spde`,
#'   `loc_centers`, `A_st`, alignment identifiers, the projected CRS, and the
#'   fixed `kappa` configuration.
#' @export
#'
#' @examples
#' if (requireNamespace("sf", quietly = TRUE) && requireNamespace("fmesher", quietly = TRUE)) {
#'   locations <- data.frame(lon = c(-123.2, -123.1, -123.15),
#'                           lat = c(49.2, 49.3, 49.25))
#'   xy <- spatial_coords(locations, lon, lat, crs_out = 32610)
#'   make_mesh(xy, kappa = 1 / 10000)
#' }
make_mesh <- function(coords, kappa, mesh = NULL, crs = attr(coords, "crs"), ...) {
  .drm_require_mesh_package("fmesher", "construct an SPDE mesh")
  .drm_require_mesh_package("sf", "validate projected mesh coordinates")
  loc_xy <- .drm_mesh_coordinates(coords)
  crs <- .drm_validate_projected_crs(crs)
  kappa <- .drm_validate_positive_scalar(kappa, "kappa")

  if (is.null(mesh)) {
    mesh <- tryCatch(
      fmesher::fm_mesh_2d_inla(loc = loc_xy, ...),
      error = function(e) {
        cli::cli_abort(c(
          "Could not construct a valid two-dimensional mesh.",
          "i" = conditionMessage(e)
        ))
      }
    )
  }
  if (!inherits(mesh, "fm_mesh_2d")) {
    cli::cli_abort("{.arg mesh} must inherit from {.cls fm_mesh_2d}.")
  }

  fem <- tryCatch(fmesher::fm_fem(mesh, order = 2), error = function(e) NULL)
  projection <- tryCatch(fmesher::fm_basis(mesh, loc = loc_xy), error = function(e) NULL)
  .drm_validate_mesh_components(fem, projection, nrow(loc_xy))

  result <- structure(
    list(
      loc_xy = loc_xy,
      xy_cols = colnames(loc_xy),
      mesh = mesh,
      spde = fem[c("c0", "g1", "g2")],
      loc_centers = mesh$loc,
      A_st = projection,
      alignment_ids = .drm_mesh_alignment_ids(loc_xy),
      source_rows = seq_len(nrow(loc_xy)),
      crs = crs,
      kappa = kappa
    ),
    class = "drmTMBmesh"
  )
  .drm_validate_mesh(result)
  result
}

.drm_require_mesh_package <- function(package, action) {
  if (!requireNamespace(package, quietly = TRUE)) {
    cli::cli_abort("Install the suggested package {.pkg {package}} to {action}.")
  }
  invisible(NULL)
}

.drm_coordinate_name <- function(data, expression, argument) {
  value <- if (is.character(expression)) expression else {
    if (is.symbol(expression)) as.character(expression) else NULL
  }
  if (is.null(value) || length(value) != 1L || !value %in% names(data)) {
    cli::cli_abort("{.arg {argument}} must name one column in {.arg data}.")
  }
  value
}

.drm_mesh_coordinates <- function(coords) {
  if (!(is.matrix(coords) || is.data.frame(coords)) || nrow(coords) < 3L || ncol(coords) != 2L) {
    cli::cli_abort("{.arg coords} must be a finite two-column object with at least three rows.")
  }
  loc_xy <- as.matrix(coords)
  if (!is.numeric(loc_xy) || any(!is.finite(loc_xy))) {
    cli::cli_abort("{.arg coords} must contain finite numeric planar coordinates.")
  }
  if (qr(sweep(loc_xy, 2L, colMeans(loc_xy), FUN = "-"))$rank < 2L) {
    cli::cli_abort("{.arg coords} must span two dimensions; collinear locations cannot form a mesh.")
  }
  storage.mode(loc_xy) <- "double"
  if (is.null(colnames(loc_xy))) colnames(loc_xy) <- c("x", "y")
  loc_xy
}

.drm_mesh_alignment_ids <- function(coords) {
  ids <- rownames(coords)
  if (is.null(ids)) ids <- as.character(seq_len(nrow(coords)))
  if (anyNA(ids) || any(!nzchar(ids)) || anyDuplicated(ids)) {
    cli::cli_abort("Mesh coordinate row names must be unique, non-missing alignment identifiers.")
  }
  as.character(ids)
}

.drm_validate_projected_crs <- function(crs) {
  if (is.null(crs)) {
    cli::cli_abort("{.arg coords} must carry a projected {.field crs} attribute, or supply {.arg crs} explicitly.")
  }
  crs <- tryCatch(sf::st_crs(crs), error = function(e) NULL)
  if (is.null(crs) || is.na(crs) || isTRUE(sf::st_is_longlat(crs))) {
    cli::cli_abort("Mesh coordinates require a valid projected CRS; geographic degrees are not supported.")
  }
  crs
}

.drm_validate_positive_scalar <- function(x, argument) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x <= 0) {
    cli::cli_abort("{.arg {argument}} must be one finite number greater than zero and remains fixed.")
  }
  as.numeric(x)
}

.drm_validate_mesh_components <- function(fem, projection, n_obs) {
  matrices <- if (is.null(fem)) list() else fem[c("c0", "g1", "g2")]
  matrix_ok <- length(matrices) == 3L && all(vapply(matrices, function(x) {
    inherits(x, "sparseMatrix") && nrow(x) == ncol(x) && all(is.finite(x@x))
  }, logical(1)))
  projection_ok <- inherits(projection, "sparseMatrix") &&
    nrow(projection) == n_obs && ncol(projection) > 0L &&
    all(is.finite(projection@x)) &&
    all(abs(Matrix::rowSums(projection) - 1) < 1e-8)
  if (!matrix_ok || !projection_ok) {
    cli::cli_abort(paste(
      "Mesh construction failed: FEM c0/g1/g2 and A_st must be finite sparse",
      "matrices, with one unit-summing projection row per observation."
    ))
  }
  dimensions <- vapply(matrices, nrow, integer(1))
  if (length(unique(dimensions)) != 1L || ncol(projection) != dimensions[[1L]]) {
    cli::cli_abort("Mesh FEM matrices and the projection matrix are not conformable.")
  }
  invisible(NULL)
}

.drm_validate_mesh <- function(mesh) {
  required <- c("loc_xy", "xy_cols", "mesh", "spde", "loc_centers", "A_st",
                "alignment_ids", "source_rows", "crs", "kappa")
  missing <- setdiff(required, names(mesh))
  if (!inherits(mesh, "drmTMBmesh") || length(missing)) {
    cli::cli_abort("{.arg mesh} must be a complete {.cls drmTMBmesh} from {.fn make_mesh}.")
  }
  .drm_mesh_coordinates(mesh$loc_xy)
  .drm_validate_projected_crs(mesh$crs)
  .drm_validate_positive_scalar(mesh$kappa, "mesh$kappa")
  .drm_validate_mesh_components(mesh$spde, mesh$A_st, nrow(mesh$loc_xy))
  alignment_ids <- as.character(mesh$alignment_ids)
  if (length(alignment_ids) != nrow(mesh$loc_xy) || anyNA(alignment_ids) ||
      any(!nzchar(alignment_ids)) || anyDuplicated(alignment_ids) ||
      !identical(alignment_ids, .drm_mesh_alignment_ids(mesh$loc_xy)) ||
      !identical(mesh$source_rows, seq_len(nrow(mesh$loc_xy)))) {
    cli::cli_abort("Mesh alignment identifiers must be unique and match the coordinate rows.")
  }
  invisible(mesh)
}
