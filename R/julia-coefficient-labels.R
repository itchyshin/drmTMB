# Versioned formula-label metadata from DRM.jl. No term spelling is inferred
# from synthetic ordinals or punctuation: the engine supplies an exact map.
drm_julia_bridge_coef_labels <- function(result) {
  keys <- c("coef_label_contract", "raw_coef_names", "coef_name_map")
  if (!any(keys %in% names(result))) return(NULL)
  fail <- function(what) stop(paste0("Invalid Julia coefficient label metadata: ", what), call. = FALSE)
  if (!identical(result$coef_label_contract, "bridge_formula_labels_v1")) fail("unknown contract")
  strings <- function(x) is.character(x) && length(x) > 0L && !anyNA(x) && all(nzchar(x)) && !anyDuplicated(x)
  public <- result$coef_names
  raw <- result$raw_coef_names
  if (!strings(public) || !strings(raw) || length(public) != length(raw)) fail("missing or duplicate labels")
  n <- length(public)
  map <- result$coef_name_map
  if (!(is.list(map) || is.character(map)) || is.null(names(map)) ||
      !strings(names(map)) || !setequal(names(map), public) || length(map) != n) fail("incomplete label map")
  if (is.list(map)) {
    if (!all(vapply(map, function(x) is.character(x) && length(x) == 1L && !is.na(x), TRUE))) fail("invalid map values")
    map <- vapply(map, identity, "")
  }
  if (!identical(unname(map[public]), unname(raw))) fail("map order or coefficient identity mismatch")
  if (!identical(drm_julia_split_coef_name(public)$dpar, drm_julia_split_coef_name(raw)$dpar)) fail("coefficient block mismatch")
  if (!identical(result$vcov_names, public)) fail("covariance label order mismatch")
  values <- unlist(result$coefficients, use.names = FALSE)
  if (!is.numeric(values) || length(values) != n) fail("coefficient coverage mismatch")
  V <- result$vcov
  if (is.matrix(V)) {
    if (!is.numeric(V) || !identical(dim(V), c(n,n))) fail("covariance dimensions mismatch")
    axes <- dimnames(V)
    if (!is.null(axes) && !all(vapply(axes, function(x) identical(x,public), TRUE))) fail("covariance axes mismatch")
  } else if (is.list(V)) {
    if (length(V) != n || !all(lengths(V) == n) ||
        !all(vapply(V, is.numeric, TRUE))) fail("covariance dimensions mismatch")
  } else if (!is.numeric(V) || length(V) != n*n) fail("covariance dimensions mismatch")
  list(contract = result$coef_label_contract, public = public, raw = raw, map = map[public])
}

# Legacy fits deliberately keep their old selector spelling. A versioned fit
# must never silently fall back after a missing or corrupted map entry.
drm_julia_public_inference_term <- function(object, dpar, term) {
  labels <- object$bridge_public_coef_labels
  if (is.null(labels)) return(term)
  if (!identical(labels$contract,"bridge_formula_labels_v1"))
    stop("Invalid Julia coefficient label contract", call. = FALSE)
  key <- paste0(dpar,"_",term)
  pos <- match(key, labels$public)
  if (length(pos) != 1L || is.na(pos) || is.null(labels$map) ||
      anyDuplicated(names(labels$map)) || !identical(unname(labels$map[labels$public]),unname(labels$raw)))
    stop("Invalid or unknown Julia coefficient label", call. = FALSE)
  raw <- unname(labels$map[[key]])
  prefix <- paste0(dpar,"_")
  if (!is.character(raw) || length(raw)!=1L || is.na(raw) || !startsWith(raw,prefix))
    stop("Invalid Julia coefficient label block", call. = FALSE)
  substring(raw,nchar(prefix)+1L)
}
