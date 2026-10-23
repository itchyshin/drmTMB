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

# Variance-component / covariance blocks the bridge names separately from any
# fixed-effect dpar formula -- random-effect SD ("resd_"), residual
# correlation ("recov_"), and phylogenetic among-axis covariance
# ("phylocov_") working parameters (SAME three prefixes `new_drmTMB_julia()`
# already uses to split `structured_coef` out of the fixed-effect coefficient
# table). These carry no `model.matrix()` column names and are excluded from
# the no-vacuity check below.
drm_julia_bridge_variance_component_prefixes <- function() {
  c("resd_", "recov_", "phylocov_")
}

# Fail-closed check, run UNCONDITIONALLY after the post-call label step
# resolves `coef_names` (whether from a validated `bridge_formula_labels_v1`
# map or, absent a map, the engine's raw names) -- design 258 S7.3. D-202:
# base-R spelling wins, so even a self-consistent, validator-accepted map
# cannot override drmTMB's own `model.matrix()` names; a validated map is
# necessary but not sufficient (Rose S9 attacks A3 permutation, A3c invented
# names).
#
# `bridge_payload` is the object returned by the payload builder, not just
# its `coef_labels` field, so this can tell "the main bridge computed zero
# labels" (an internal invariant failure -- report it) apart from "this
# route's payload builder does not populate `coef_labels` at all" (the
# structured/relmat/animal/spatial, bivariate-known-structured, and joint
# routes; design 258 S7.4 lists them; out of scope for this contract until
# their payload builders adopt it -- `drm_julia_predict_fixed_eta()` keeps the
# legacy predict-time rewrite for them meanwhile).
#
# When the field IS present, every FIXED-EFFECT dpar block the engine
# actually returned (identified via `drm_julia_split_coef_name()` on
# `coef_names`, excluding `drm_julia_bridge_variance_component_prefixes()`)
# must have a payload label, checked by exact string/order `identical()` --
# no punctuation is stripped or guessed anywhere in this codebase (S3). A
# fixed-effect dpar with NO payload label aborts (Rose S9 attack A5: this
# used to iterate only `names(coef_labels)`, so an unlabelled engine dpar
# passed by vacuity); a dpar whose labels do not match aborts naming DRM.jl.
drm_julia_bridge_check_coef_labels <- function(coef_names, bridge_payload) {
  has_field <- is.list(bridge_payload) && "coef_labels" %in% names(bridge_payload)
  if (!has_field) {
    return(invisible(NULL))
  }
  coef_labels <- bridge_payload$coef_labels
  if (length(coef_labels) == 0L) {
    cli::cli_abort(
      "No coefficient labels were built for this Julia-engine fit; report this (an internal invariant failure in the drmTMB Julia bridge, not a DRM.jl problem).",
      call. = FALSE
    )
  }
  split <- drm_julia_split_coef_name(coef_names)
  prefixes <- drm_julia_bridge_variance_component_prefixes()
  is_variance_component <- Reduce(
    `|`,
    lapply(prefixes, function(p) startsWith(coef_names, p)),
    rep(FALSE, length(coef_names))
  )
  engine_dpars <- unique(split$dpar[!is_variance_component])

  detail <- character()
  missing_dpars <- setdiff(engine_dpars, names(coef_labels))
  if (length(missing_dpars) > 0L) {
    detail <- c(detail, paste0(
      "no payload label was built for fixed-effect dpar(s): ",
      paste(missing_dpars, collapse = ", "), "."
    ))
  }
  for (dpar in intersect(engine_dpars, names(coef_labels))) {
    engine_terms <- split$term[split$dpar == dpar]
    expected <- as.character(coef_labels[[dpar]])
    if (!identical(engine_terms, expected)) {
      detail <- c(detail, paste0(
        dpar, ": drmTMB expects (", paste(expected, collapse = ", "),
        "); DRM.jl returned (", paste(engine_terms, collapse = ", "), ")."
      ))
    }
  }
  if (length(detail) == 0L) {
    return(invisible(NULL))
  }
  names(detail) <- rep_len("x", length(detail))
  cli::cli_abort(c(
    "DRM.jl returned coefficient names that do not match drmTMB's base-R {.fn model.matrix} spelling.",
    detail,
    i = "DRM.jl must supply {.code bridge_formula_labels_v1} (design 258 section 7) for this formula construct, or its raw names must equal drmTMB's own base-R spelling exactly."
  ), call. = FALSE)
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
