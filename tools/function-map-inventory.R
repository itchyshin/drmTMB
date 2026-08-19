# Reviewed task inventory for the public drmTMB function map.
#
# This is a navigation layer, not a capability ledger. Primary entries are
# current first-use routes; compatibility and specialist exports remain in the
# reference index without being promoted into the map.

function_map_inventory <- list(
  list(
    id = "specify", label = "1. Specify", colour = "#75A843", dark = "#476F1F",
    purpose = "State the response model, distributional parameters, and dependence structure.",
    functions = c("bf", "drm_formula", "meta_V", "miss_control", "phylo", "spatial", "relmat", "corpair"),
    route = "Use meta_V() for known sampling covariance; confirm the exact family and structure in the capability guide.",
    anchor = "#choose-a-route", link = "Choose a model route"
  ),
  list(
    id = "fit", label = "2. Fit", colour = "#4E86BF", dark = "#245C91",
    purpose = "Fit the specified model with the primary fitting function.",
    functions = c("drmTMB", "drm_control"),
    route = "Keep the formula, family, data, and control choices with the fitted object.",
    anchor = "#the-shortest-useful-workflow", link = "Fit a first model"
  ),
  list(
    id = "check", label = "3. Check fit health", colour = "#8464AD", dark = "#5B3C82",
    purpose = "Check convergence, gradients, uncertainty information, boundaries, and model-specific warnings.",
    functions = c("check_drm", "is_converged"),
    route = "Resolve a flagged fit before interpreting coefficients, predictions, or intervals.",
    anchor = "#choose-a-route", link = "Check and troubleshoot"
  ),
  list(
    id = "interpret", label = "Interpret", colour = "#DF8A45", dark = "#854314",
    purpose = "Extract fixed, random, scale, and correlation quantities on named scales.",
    functions = c("fixef", "ranef", "structured_effects", "rho12", "corpairs"),
    route = "Name the distributional parameter and scale; a successful extraction is not a universal inference claim.",
    anchor = "#the-shortest-useful-workflow", link = "Interpret parameters"
  ),
  list(
    id = "predict", label = "Predict and assess", colour = "#31A0A0", dark = "#126E70",
    purpose = "Build prediction grids, predict parameters, and inspect fitted distribution adequacy.",
    functions = c("prediction_grid", "predict_parameters", "fitted_distribution", "exceedance", "centile_chart", "qq_plot"),
    route = "Separate fitted response assessment from claims about random or structured components.",
    anchor = "#the-shortest-useful-workflow", link = "Predict on a grid"
  ),
  list(
    id = "uncertainty", label = "Uncertainty and simulation", colour = "#C56B8C", dark = "#81344F",
    purpose = "Discover available targets, request target specific intervals, or simulate from a fitted model.",
    functions = c("profile_targets"),
    methods = c("confint", "profile", "simulate"),
    route = "Inspect the returned method and status; interval availability and calibration are target-specific.",
    anchor = "#keep-the-boundaries-visible", link = "Check inference boundaries"
  )
)

function_map_primary_exports <- unique(unlist(lapply(
  function_map_inventory, `[[`, "functions"
)))

`%||%` <- function(x, y) if (is.null(x)) y else x

function_map_primary_methods <- unique(unlist(lapply(
  function_map_inventory, function(item) item$methods %||% character()
)))

function_map_compatibility <- c("gr", "meta_known_V")

function_map_classify_exports <- function(exports) {
  status <- rep("reference_only", length(exports))
  names(status) <- exports
  status[intersect(exports, function_map_primary_exports)] <- "featured"
  status[intersect(exports, function_map_compatibility)] <- "compatibility"
  status
}

function_map_escape_html <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}

function_map_function_label <- function(item) {
  exports <- paste0(item$functions, "()")
  method_names <- item$methods %||% character()
  methods <- if (length(method_names)) paste0(method_names, "()") else character()
  paste(c(exports, methods), collapse = ", ")
}

function_map_reference_topics <- c(bf = "drm_formula")

function_map_reference_path <- function(name, method = FALSE) {
  topic <- if (method) {
    paste0(name, ".drmTMB")
  } else if (name %in% names(function_map_reference_topics)) {
    unname(function_map_reference_topics[[name]])
  } else {
    name
  }
  paste0("../reference/", topic, ".html")
}

function_map_function_links <- function(item) {
  export_links <- vapply(item$functions, function(name) {
    sprintf(
      '<a class="drmtmb-map__function" href="%s"><code>%s()</code></a>',
      function_map_reference_path(name), function_map_escape_html(name)
    )
  }, character(1))
  method_names <- item$methods %||% character()
  method_links <- vapply(method_names, function(name) {
    sprintf(
      '<a class="drmtmb-map__function" href="%s"><code>%s()</code></a>',
      function_map_reference_path(name, method = TRUE),
      function_map_escape_html(name)
    )
  }, character(1))
  paste(c(export_links, method_links), collapse = ", ")
}

function_map_html <- function() {
  card_class <- c(
    specify = "map-specify", fit = "map-fit", check = "map-check",
    interpret = "map-interpret", predict = "map-predict",
    uncertainty = "map-uncertainty"
  )
  cards <- vapply(function_map_inventory, function(item) {
    sprintf(
      paste0(
        '<section class="drmtmb-map__card %s">',
        '<h3>%s</h3><p>%s</p><p class="drmtmb-map__functions">%s</p>',
        '<a href="%s">%s</a><small>%s</small></section>'
      ),
      card_class[[item$id]],
      function_map_escape_html(item$label),
      function_map_escape_html(item$purpose),
      function_map_function_links(item),
      item$anchor,
      function_map_escape_html(item$link),
      function_map_escape_html(item$route)
    )
  }, character(1))
  paste(cards, collapse = "\n")
}
