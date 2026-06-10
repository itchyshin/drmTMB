julia_bridge_supported_dpars <- function() {
  c(
    "mu",
    "sigma",
    "nu",
    "zi",
    "hu",
    "zoi",
    "coi",
    "mu1",
    "mu2",
    "sigma1",
    "sigma2",
    "rho12"
  )
}

drm_julia_setup_state <- new.env(parent = emptyenv())
drm_julia_phylo_payload_cache <- new.env(parent = emptyenv())

drmTMB_julia_bridge <- function(
  formula,
  family,
  data,
  env,
  weights_missing,
  control,
  impute,
  missing,
  call
) {
  if (!isTRUE(weights_missing)) {
    cli::cli_abort(
      "{.code engine = \"julia\"} does not support {.arg weights} yet."
    )
  }
  if (!is.null(impute)) {
    cli::cli_abort(
      "{.code engine = \"julia\"} does not support {.arg impute} yet."
    )
  }
  missing_control <- drm_parse_missing_control(missing)
  if (
    !identical(missing_control$response, "drop") ||
      !identical(missing_control$predictor, "fail")
  ) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} does not support {.arg missing} routes yet.",
      i = "Use the native {.code engine = \"tmb\"} path for missing-data models."
    ))
  }
  if (!drm_julia_default_control(control)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} currently accepts only default {.arg control}.",
      i = "Use the native {.code engine = \"tmb\"} path for TMB optimizer, storage, sparse, or aggregation controls."
    ))
  }

  family_type <- drm_family_type(family)
  family_tag <- drm_julia_family_tag(family_type)
  bridge_payload <- drm_julia_bridge_payload(
    formula = formula,
    family_type = family_type,
    data = data,
    env = env
  )

  result <- drm_julia_call_bridge(
    formula = bridge_payload$formula,
    family = family_tag,
    data = bridge_payload$data,
    tree = bridge_payload$tree,
    options = bridge_payload$options
  )
  result <- drm_julia_restore_row_order(result, bridge_payload$row_order)
  new_drmTMB_julia(
    result = result,
    call = call,
    formula = formula,
    family = family,
    data = data,
    family_type = family_type,
    structured_sd_scales = bridge_payload$structured_sd_scales,
    bridge_payload = bridge_payload
  )
}

drm_julia_default_control <- function(control) {
  if (inherits(control, "drm_control")) {
    default <- drm_control()
    return(identical(control, default))
  }
  is.null(control) || (is.list(control) && length(control) == 0L)
}

drm_julia_family_tag <- function(family_type) {
  if (!family_type %in% c("gaussian", "biv_gaussian")) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} currently supports only Gaussian one-response and two-response models.",
      i = "Use {.code engine = \"tmb\"} for non-Gaussian drmTMB fits until the R bridge has coefficient-scale parity tests."
    ))
  }
  family_type
}

drm_julia_bridge_payload <- function(formula, family_type, data, env) {
  formula_spec <- drm_julia_formula_spec(formula)
  phylo_payload <- drm_julia_phylo_payload(
    formula = formula,
    family_type = family_type,
    data = data,
    env = env
  )
  data_out <- drm_julia_bridge_data(
    data = data,
    formula = formula,
    phylo_payload = phylo_payload
  )
  if (!is.null(phylo_payload)) {
    data_out <- data_out[phylo_payload$row_order, , drop = FALSE]
    data_out[[phylo_payload$group]] <- as.character(
      data_out[[phylo_payload$group]]
    )
  }
  list(
    formula = formula_spec,
    data = data_out,
    tree = if (is.null(phylo_payload)) NULL else phylo_payload$newick,
    options = drm_julia_bridge_options(phylo_payload),
    row_order = if (is.null(phylo_payload)) NULL else phylo_payload$row_order,
    structured_sd_scales = if (is.null(phylo_payload)) {
      NULL
    } else {
      phylo_payload$structured_sd_scales
    }
  )
}

drm_julia_bridge_data <- function(data, formula, phylo_payload = NULL) {
  needed <- unique(unlist(
    lapply(formula$entries, function(entry) {
      c(
        if (!is.na(entry$response)) entry$response,
        all.vars(
          drm_julia_collapse_phylo_block(drm_julia_strip_phylo_tree(entry$rhs))
        )
      )
    }),
    use.names = FALSE
  ))
  if (!is.null(phylo_payload)) {
    needed <- unique(c(needed, phylo_payload$group))
  }
  missing <- setdiff(needed, names(data))
  if (length(missing) > 0L) {
    cli::cli_abort(
      "{.code engine = \"julia\"} could not find model variable{?s} {.val {missing}} in {.arg data}."
    )
  }
  data[, needed, drop = FALSE]
}

drm_julia_bridge_options <- function(phylo_payload) {
  if (is.null(phylo_payload)) {
    return(list())
  }
  if (isTRUE(phylo_payload$bivariate)) {
    # The q=4 PLSM route uses DRM.jl's own defaults (no g_tol override): the
    # direct-fit parity check matched the bridge to 0 with defaults.
    return(list())
  }

  # The sparse all-node Gaussian phylo route is L-BFGS-based in DRM.jl's
  # current default. The direct AVONET/Hackett benchmark shows the exact-gradient
  # sparse route is insensitive to this tolerance over the bridge-smoke range,
  # while keeping the R payload explicit and reproducible.
  list(g_tol = 1e-4)
}

drm_julia_formula_spec <- function(formula) {
  dpars <- vapply(formula$entries, `[[`, character(1L), "dpar")
  bad <- setdiff(dpars, julia_bridge_supported_dpars())
  if (length(bad) > 0L) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} cannot marshal formula parameter{?s}: {.val {bad}}.",
      i = "Use the native {.code engine = \"tmb\"} path for random-effect scale formulas, corpair formulas, or unsupported syntax."
    ))
  }

  out <- stats::setNames(
    vector("list", length(formula$entries)),
    dpars
  )
  for (i in seq_along(formula$entries)) {
    entry <- formula$entries[[i]]
    out[[i]] <- drm_julia_formula_entry(entry)
  }
  out
}

drm_julia_formula_entry <- function(entry) {
  rhs <- deparse1(
    drm_julia_collapse_phylo_block(drm_julia_strip_phylo_tree(entry$rhs))
  )
  if (!is.na(entry$response)) {
    return(paste(entry$response, "~", rhs))
  }
  paste(entry$dpar, "~", rhs)
}

drm_julia_call_bridge <- function(
  formula,
  family,
  data,
  tree = NULL,
  options = list()
) {
  if (!requireNamespace("JuliaCall", quietly = TRUE)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} requires the {.pkg JuliaCall} package.",
      i = "Install it with {.code install.packages(\"JuliaCall\")}, then retry."
    ))
  }

  drm_julia_setup()
  JuliaCall::julia_call(
    "drmTMB_drm_bridge",
    formula,
    family,
    as.list(data),
    tree,
    if (length(options) == 0L) NULL else options
  )
}

drm_julia_call_inference <- function(
  object,
  method,
  level,
  R,
  seed,
  threads
) {
  if (!requireNamespace("JuliaCall", quietly = TRUE)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} inference requires the {.pkg JuliaCall} package.",
      i = "Install it with {.code install.packages(\"JuliaCall\")}, then retry."
    ))
  }
  payload <- object$bridge_payload
  if (is.null(payload) || is.null(payload$tree)) {
    cli::cli_abort(c(
      "Julia-engine profile and bootstrap intervals require a stored bridge payload.",
      i = "Refit the Gaussian phylogenetic model with {.code engine = \"julia\"} before calling {.fn confint}."
    ))
  }

  drm_julia_setup()
  JuliaCall::julia_call(
    "drmTMB_drm_bridge_inference",
    payload$formula,
    object$model$model_type,
    as.list(payload$data),
    payload$tree,
    if (length(payload$options) == 0L) NULL else payload$options,
    method,
    level,
    as.integer(R),
    seed,
    threads
  )
}

drm_julia_phylo_payload <- function(formula, family_type, data, env) {
  phylo_terms <- unlist(
    lapply(formula$entries, function(entry) {
      Filter(
        function(term) identical(term$type, "phylo"),
        entry$structured
      )
    }),
    recursive = FALSE
  )
  if (length(phylo_terms) == 0L) {
    return(NULL)
  }
  # Univariate Gaussian keeps the original single mu-intercept slice (sigma ~ 1).
  # Bivariate Gaussian (q=4 PLSM) admits intercept phylo on mu1/mu2/sigma1/sigma2
  # sharing ONE tree + grouping factor (rho12 may not carry phylo). Both routes
  # preserve the phylo() marker in the formula string (only `tree =` is stripped);
  # DRM.jl reconstructs the structured term and the tree is marshalled as Newick.
  if (identical(family_type, "gaussian")) {
    if (length(phylo_terms) != 1L) {
      cli::cli_abort(c(
        "{.code engine = \"julia\"} currently supports one {.fn phylo} term for univariate Gaussian fits.",
        i = "Use native {.code engine = \"tmb\"} for multiple phylogenetic terms."
      ))
    }
    term <- phylo_terms[[1L]]
    if (
      !identical(term$dpar, "mu") ||
        !identical(term$coef_names, "(Intercept)")
    ) {
      cli::cli_abort(c(
        "{.code engine = \"julia\"} currently supports only {.code phylo(1 | group, tree = tree)} in the Gaussian {.code mu} formula.",
        i = "Use native {.code engine = \"tmb\"} for phylogenetic slopes, residual-scale phylogenetic effects, or direct-SD formulas."
      ))
    }
    sigma_entries <- Filter(
      function(entry) identical(entry$dpar, "sigma"),
      formula$entries
    )
    if (
      length(sigma_entries) > 0L &&
        !all(vapply(
          sigma_entries,
          function(entry) drm_julia_is_intercept_rhs(entry$rhs),
          logical(1L)
        ))
    ) {
      cli::cli_abort(c(
        "{.code engine = \"julia\"} uses DRM.jl's sparse all-node route for univariate phylogenetic bridge fits, which currently requires {.code sigma ~ 1}.",
        i = "Use native {.code engine = \"tmb\"} for phylogenetic models with predictor-dependent residual scale until the sparse Julia route has parity tests."
      ))
    }
    rep_term <- term
    labels <- term$label
    bivariate <- FALSE
  } else if (identical(family_type, "biv_gaussian")) {
    allowed <- c("mu1", "mu2", "sigma1", "sigma2")
    dpars <- vapply(phylo_terms, `[[`, character(1L), "dpar")
    if (!all(dpars %in% allowed)) {
      cli::cli_abort(c(
        "{.code engine = \"julia\"} routes bivariate {.fn phylo} only on {.val {allowed}}.",
        x = "Unsupported phylogenetic axis: {.val {setdiff(dpars, allowed)}}.",
        i = "Use native {.code engine = \"tmb\"} for phylogenetic {.code rho12} or other axes."
      ))
    }
    if (!all(allowed %in% dpars)) {
      cli::cli_abort(c(
        "{.code engine = \"julia\"} routes the bivariate q=4 PLSM only when {.fn phylo} is on all four axes {.val {allowed}}.",
        x = "Missing phylogenetic axis: {.val {setdiff(allowed, dpars)}}.",
        i = "Use native {.code engine = \"tmb\"} for partial bivariate phylogenetic structure."
      ))
    }
    if (!all(vapply(phylo_terms, function(t) identical(t$coef_names, "(Intercept)"), logical(1L)))) {
      cli::cli_abort(c(
        "{.code engine = \"julia\"} currently supports only intercept {.code phylo(1 | group, tree = tree)} terms in the bivariate q=4 route.",
        i = "Use native {.code engine = \"tmb\"} for phylogenetic slopes in the location-scale model."
      ))
    }
    groups <- vapply(phylo_terms, `[[`, character(1L), "group")
    trees <- vapply(phylo_terms, `[[`, character(1L), "tree")
    if (length(unique(groups)) != 1L || length(unique(trees)) != 1L) {
      cli::cli_abort(c(
        "{.code engine = \"julia\"} requires all bivariate {.fn phylo} terms to share one tree and grouping factor.",
        i = "Use native {.code engine = \"tmb\"} for heterogeneous phylogenetic structure across axes."
      ))
    }
    rep_term <- phylo_terms[[1L]]
    labels <- vapply(phylo_terms, `[[`, character(1L), "label")
    bivariate <- TRUE
  } else {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} can marshal {.fn phylo} only for Gaussian one- or two-response fits.",
      i = "Use native {.code engine = \"tmb\"} for non-Gaussian phylogenetic fits until the bridge has parity tests."
    ))
  }

  if (!rep_term$group %in% names(data)) {
    cli::cli_abort(
      "Phylogenetic grouping variable {.field {rep_term$group}} was not found in {.arg data}."
    )
  }

  tree <- get(rep_term$tree, envir = env, inherits = TRUE)
  species <- as.character(data[[rep_term$group]])
  cache <- drm_julia_phylo_payload_cache
  if (
    !is.null(cache$full_tree) &&
      identical(cache$full_tree, tree) &&
      identical(cache$full_group, rep_term$group) &&
      identical(cache$full_label, labels) &&
      identical(cache$full_species, species)
  ) {
    return(cache$full_payload)
  }

  info <- validate_phylo_tree(tree, species = species)
  tree_payload <- drm_julia_phylo_tree_payload(tree, info = info)
  row_order <- order(
    match(species, tree_payload$tip_order),
    seq_len(nrow(data))
  )

  payload <- list(
    newick = tree_payload$newick,
    group = rep_term$group,
    row_order = row_order,
    bivariate = bivariate,
    structured_sd_scales = stats::setNames(
      rep(tree_payload$sd_scale, length(labels)),
      labels
    )
  )
  cache$full_tree <- tree
  cache$full_group <- rep_term$group
  cache$full_label <- labels
  cache$full_species <- species
  cache$full_payload <- payload
  payload
}

drm_julia_phylo_tree_payload <- function(tree, info = NULL) {
  cache <- drm_julia_phylo_payload_cache
  if (!is.null(cache$tree) && identical(cache$tree, tree)) {
    return(cache$payload)
  }
  if (is.null(info)) {
    info <- validate_phylo_tree(tree)
  }
  payload <- drm_julia_phylo_newick(tree, info = info)
  payload$sd_scale <- drm_julia_phylo_sd_scale(tree, info = info)
  cache$tree <- tree
  cache$payload <- payload
  payload
}

drm_julia_phylo_sd_scale <- function(tree, info = NULL) {
  if (is.null(info)) {
    info <- validate_phylo_tree(tree)
  }
  edge <- matrix(as.integer(tree$edge), ncol = 2L)
  edge_length <- as.numeric(tree$edge.length)
  children <- split(seq_len(nrow(edge)), edge[, 1L])
  depths <- rep(NA_real_, max(edge))
  depths[[info$root]] <- 0

  walk <- function(node) {
    child_edges <- children[[as.character(node)]]
    if (is.null(child_edges)) {
      return(invisible(NULL))
    }
    for (edge_index in child_edges) {
      child <- edge[[edge_index, 2L]]
      depths[[child]] <<- depths[[node]] + edge_length[[edge_index]]
      walk(child)
    }
    invisible(NULL)
  }

  walk(info$root)
  depths <- depths[seq_len(info$n_tip)]
  sqrt(mean(depths))
}

drm_julia_is_intercept_rhs <- function(rhs) {
  identical(rhs, 1) || identical(rhs, quote(1))
}

drm_julia_strip_phylo_tree <- function(expr) {
  if (!is.call(expr)) {
    return(expr)
  }
  call <- as.list(expr)
  if (identical(call[[1L]], as.name("phylo"))) {
    names_call <- names(call)
    keep <- is.na(names_call) | !identical(names_call, "tree")
    if (is.null(names_call)) {
      keep <- rep(TRUE, length(call))
    } else {
      keep <- names_call != "tree"
      keep[is.na(keep)] <- TRUE
    }
    call <- call[keep]
  } else {
    call[-1L] <- lapply(call[-1L], drm_julia_strip_phylo_tree)
  }
  as.call(call)
}

# Collapse drmTMB's labelled covariance-block grammar `re | label | group` to
# DRM.jl's `re | group` inside phylo() calls. DRM.jl implies the q=4 4x4 Sigma_a
# from the four location/scale axes sharing one tree + grouping factor, so the
# block label is dropped on the way across the bridge. No-op for the plain
# `re | group` form (univariate route and unlabelled bivariate terms).
drm_julia_collapse_phylo_block <- function(expr) {
  if (!is.call(expr)) {
    return(expr)
  }
  parts <- as.list(expr)
  if (identical(parts[[1L]], as.name("phylo"))) {
    nm <- names(parts)
    for (i in seq_along(parts)) {
      if (i == 1L) {
        next
      }
      if (!is.null(nm) && !is.na(nm[[i]]) && nzchar(nm[[i]])) {
        next
      }
      bar <- parts[[i]]
      if (
        is.call(bar) && identical(bar[[1L]], as.name("|")) && length(bar) == 3L &&
          is.call(bar[[2L]]) && identical(bar[[2L]][[1L]], as.name("|")) &&
          length(bar[[2L]]) == 3L
      ) {
        parts[[i]] <- call("|", bar[[2L]][[2L]], bar[[3L]])
      }
      break
    }
    return(as.call(parts))
  }
  parts[-1L] <- lapply(parts[-1L], drm_julia_collapse_phylo_block)
  as.call(parts)
}

drm_julia_phylo_newick <- function(tree, info = NULL) {
  if (is.null(info)) {
    info <- validate_phylo_tree(tree)
  }
  if (any(tree$edge.length <= 0)) {
    cli::cli_abort(
      "{.code engine = \"julia\"} requires positive phylogenetic branch lengths."
    )
  }
  bad_label <- grep("^[A-Za-z0-9_.-]+$", tree$tip.label, invert = TRUE)
  if (length(bad_label) > 0L) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} can serialize only simple phylogenetic tip labels in this slice.",
      x = "Unsupported tip label: {.val {tree$tip.label[[bad_label[[1L]]]]}}."
    ))
  }

  edge <- matrix(as.integer(tree$edge), ncol = 2L)
  children <- split(seq_len(nrow(edge)), edge[, 1L])
  child_counts <- lengths(children)
  if (any(child_counts != 2L)) {
    cli::cli_abort(
      "{.code engine = \"julia\"} currently serializes binary phylogenies only."
    )
  }
  edge_length_by_child <- stats::setNames(
    tree$edge.length,
    as.character(edge[, 2L])
  )
  tip_order <- character()
  node_newick <- function(node) {
    if (node <= info$n_tip) {
      label <- tree$tip.label[[node]]
      tip_order <<- c(tip_order, label)
    } else {
      child_edges <- children[[as.character(node)]]
      child_nodes <- edge[child_edges, 2L]
      label <- paste0(
        "(",
        paste(vapply(child_nodes, node_newick, character(1L)), collapse = ","),
        ")"
      )
    }
    if (identical(node, info$root)) {
      return(label)
    }
    paste0(
      label,
      ":",
      format(
        edge_length_by_child[[as.character(node)]],
        scientific = FALSE,
        digits = 17L,
        trim = TRUE
      )
    )
  }

  newick <- paste0(node_newick(info$root), ";")
  list(newick = newick, tip_order = tip_order)
}

drm_julia_restore_row_order <- function(result, row_order) {
  if (is.null(row_order)) {
    return(result)
  }
  result <- as.list(result)
  restore <- order(row_order)
  for (field in c("fitted", "residuals", "sigma")) {
    result[[field]] <- drm_julia_restore_value_order(result[[field]], restore)
  }
  result
}

drm_julia_restore_value_order <- function(x, restore) {
  if (is.null(x)) {
    return(NULL)
  }
  if (is.matrix(x) && nrow(x) == length(restore)) {
    return(x[restore, , drop = FALSE])
  }
  if (is.atomic(x) && length(x) == length(restore)) {
    return(x[restore])
  }
  if (is.list(x)) {
    return(lapply(x, drm_julia_restore_value_order, restore = restore))
  }
  x
}

drm_julia_setup <- function(path = drm_julia_path()) {
  normalized_path <- if (nzchar(path)) {
    normalizePath(path, winslash = "/", mustWork = TRUE)
  } else {
    ""
  }
  if (
    isTRUE(drm_julia_setup_state$ready) &&
      identical(drm_julia_setup_state$path, normalized_path)
  ) {
    return(invisible(TRUE))
  }
  JuliaCall::julia_setup(installJulia = FALSE)
  if (nzchar(normalized_path)) {
    JuliaCall::julia_command(paste0(
      "import Pkg; Pkg.activate(",
      drm_julia_quote(normalized_path),
      "); using DRM"
    ))
  } else {
    JuliaCall::julia_command("using DRM")
  }
  JuliaCall::julia_command(
    paste(
      "drmTMB_drm_bridge(formula, family, data, tree, options) =",
      "DRM.drm_bridge(formula = formula, family = family, data = data, tree = tree, options = options)"
    )
  )
  JuliaCall::julia_command(
    paste(
      "drmTMB_drm_bridge_inference(formula, family, data, tree, options, method, level, B, seed, threads) =",
      "DRM.drm_bridge_inference(formula = formula, family = family, data = data, tree = tree, options = options, method = method, level = level, B = B, seed = seed, threads = threads)"
    )
  )
  drm_julia_setup_state$ready <- TRUE
  drm_julia_setup_state$path <- normalized_path
  invisible(TRUE)
}

drm_julia_path <- function() {
  explicit <- getOption("drmTMB.DRM.jl.path", "")
  if (is.character(explicit) && length(explicit) == 1L && nzchar(explicit)) {
    return(explicit)
  }
  env_path <- Sys.getenv("DRM_JL_PATH", "")
  if (nzchar(env_path)) {
    return(env_path)
  }
  sibling <- normalizePath(
    file.path(getwd(), "..", "DRM.jl"),
    winslash = "/",
    mustWork = FALSE
  )
  if (dir.exists(sibling)) {
    return(sibling)
  }
  ""
}

drm_julia_quote <- function(x) {
  paste0("\"", gsub("\\\\", "/", gsub("\"", "\\\\\"", x)), "\"")
}

new_drmTMB_julia <- function(
  result,
  call,
  formula,
  family,
  data,
  family_type,
  structured_sd_scales = NULL,
  bridge_payload = NULL
) {
  result <- as.list(result)
  coef_names <- as.character(result$coef_names)
  coefficients <- stats::setNames(
    as.numeric(unlist(result$coefficients, use.names = FALSE)),
    coef_names
  )
  structured_parameters <- drm_julia_structured_parameters(
    coefficients = coefficients,
    formula = formula,
    sd_scales = structured_sd_scales
  )
  fixed <- !startsWith(names(coefficients), "resd_")
  fixed_coefficients <- coefficients[fixed]
  coefficient_blocks <- split(
    fixed_coefficients,
    sub("_.*$", "", names(fixed_coefficients))
  )
  coefficient_blocks <- lapply(coefficient_blocks, function(x) {
    stats::setNames(x, sub("^[^_]+_", "", names(x)))
  })
  V_full <- drm_julia_vcov(result$vcov, coef_names)
  V <- V_full[fixed, fixed, drop = FALSE]
  finite_vcov <- length(V) > 0L && all(is.finite(V))
  finite_diag <- if (length(V) > 0L) {
    is.finite(diag(V))
  } else {
    logical()
  }
  partial_vcov <- any(finite_diag) && !finite_vcov
  finite_vcov_dpars <- unique(sub("_.*$", "", names(finite_diag)[finite_diag]))
  uncertainty_status <- if (finite_vcov) {
    "ok"
  } else if (partial_vcov) {
    "partial"
  } else {
    "unavailable"
  }
  out <- list(
    call = call,
    formula = formula,
    family = family,
    data = data,
    engine = "julia",
    model = list(
      model_type = family_type,
      dpars = names(coefficient_blocks),
      data = data
    ),
    bridge = result,
    bridge_payload = bridge_payload,
    coefficients = coefficient_blocks,
    coef_vector = fixed_coefficients,
    sdpars = structured_parameters$sdpars,
    structured_sd_scales = structured_sd_scales,
    corpars = list(),
    vcov = V,
    logLik = as.numeric(result$loglik),
    aic = as.numeric(result$aic),
    bic = as.numeric(result$bic),
    df = as.integer(result$df),
    nobs = as.integer(result$nobs),
    fitted = drm_julia_plain(result$fitted),
    residuals = drm_julia_plain(result$residuals),
    sigma = drm_julia_plain(result$sigma),
    corpairs = drm_julia_plain(result$corpairs),
    opt = list(convergence = if (isTRUE(result$converged)) 0L else 1L),
    uncertainty = list(
      status = uncertainty_status,
      se = finite_vcov,
      finite_dpars = finite_vcov_dpars,
      message = if (finite_vcov) {
        "DRM.jl bridge returned fixed-effect covariance."
      } else if (partial_vcov) {
        paste(
          "DRM.jl bridge returned a partial covariance matrix for",
          paste(finite_vcov_dpars, collapse = ", "),
          "coefficients; other fixed-effect or variance-component covariance",
          "entries are unavailable for this route."
        )
      } else {
        "DRM.jl bridge did not return finite fixed-effect covariance for this route."
      }
    )
  )
  class(out) <- "drmTMB_julia"
  out
}

drm_julia_profile_targets <- function(object) {
  values <- object$sdpars$mu
  if (is.null(values) || length(values) == 0L) {
    return(empty_profile_targets())
  }
  keep <- startsWith(names(values), "phylo(")
  if (!any(keep)) {
    return(empty_profile_targets())
  }

  values <- values[keep]
  term <- names(values)[[1L]]
  scale <- drm_julia_structured_sd_scale(object, term)
  profile_ready <- !is.null(object$bridge_payload) &&
    !is.null(object$bridge_payload$tree)
  out <- new_profile_target_row(
    parm = paste0("sd:mu:", term),
    target_class = "random-effect-sd",
    dpar = "mu",
    term = term,
    tmb_parameter = "resd",
    index = 1L,
    estimate = unname(values[[1L]]),
    link_estimate = log(unname(values[[1L]]) / scale),
    scale = "response",
    transformation = "exp",
    target_type = "direct",
    profile_ready = profile_ready,
    profile_note = if (profile_ready) {
      "ready"
    } else {
      "julia_bridge_payload_required"
    }
  )
  row.names(out) <- NULL
  validate_profile_targets(out)
}

drm_julia_structured_sd_scale <- function(object, term) {
  scales <- object$structured_sd_scales
  if (is.null(scales) && !is.null(object$bridge_payload)) {
    scales <- object$bridge_payload$structured_sd_scales
  }
  if (!is.null(scales) && term %in% names(scales)) {
    return(unname(scales[[term]]))
  }
  1
}

drm_julia_structured_parameters <- function(
  coefficients,
  formula,
  sd_scales = NULL
) {
  empty_sdpars <- list(mu = numeric(), sigma = numeric())
  structured <- coefficients[startsWith(names(coefficients), "resd_")]
  if (length(structured) == 0L) {
    return(list(sdpars = empty_sdpars))
  }

  terms <- unlist(
    lapply(formula$entries, function(entry) {
      Filter(
        function(term) identical(term$type, "phylo"),
        entry$structured
      )
    }),
    recursive = FALSE
  )
  labels <- sub("^resd_", "", names(structured))
  dpars <- rep("mu", length(structured))
  if (length(terms) == length(structured)) {
    labels <- vapply(terms, `[[`, character(1L), "label")
    dpars <- vapply(terms, `[[`, character(1L), "dpar")
  }

  sdpars <- empty_sdpars
  for (i in seq_along(structured)) {
    dpar <- dpars[[i]]
    if (is.null(sdpars[[dpar]])) {
      sdpars[[dpar]] <- numeric()
    }
    scale <- if (!is.null(sd_scales) && labels[[i]] %in% names(sd_scales)) {
      unname(sd_scales[[labels[[i]]]])
    } else {
      1
    }
    sdpars[[dpar]][[labels[[i]]]] <- exp(unname(structured[[i]])) * scale
  }
  list(sdpars = sdpars)
}

drm_julia_vcov <- function(x, coef_names) {
  if (is.matrix(x)) {
    out <- matrix(as.numeric(x), nrow = nrow(x), ncol = ncol(x))
  } else if (is.list(x) && length(x) == length(coef_names)) {
    rows <- lapply(x, function(row) as.numeric(unlist(row, use.names = FALSE)))
    out <- do.call(rbind, rows)
  } else {
    out <- matrix(
      as.numeric(unlist(x, use.names = FALSE)),
      nrow = length(coef_names),
      ncol = length(coef_names)
    )
  }
  dimnames(out) <- list(coef_names, coef_names)
  out
}

drm_julia_plain <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  if (is.matrix(x)) {
    return(x)
  }
  if (is.list(x)) {
    if (length(x) == 0L) {
      return(list())
    }
    if (!is.null(names(x)) && all(nzchar(names(x)))) {
      return(lapply(x, function(value) {
        as.numeric(unlist(value, use.names = FALSE))
      }))
    }
    return(as.numeric(unlist(x, use.names = FALSE)))
  }
  if (is.numeric(x) || is.logical(x)) {
    return(x)
  }
  x
}

#' @export
print.drmTMB_julia <- function(x, ...) {
  cli::cli_text("<drmTMB Julia-engine fit>")
  cli::cli_text("  observations: {x$nobs}")
  cli::cli_text("  logLik: {format(x$logLik, digits = 4)}")
  cli::cli_text("  convergence: {x$opt$convergence}")
  invisible(x)
}

#' @export
coef.drmTMB_julia <- function(object, dpar = NULL, ...) {
  if (is.null(dpar)) {
    return(object$coefficients)
  }
  dpar <- match.arg(dpar, names(object$coefficients))
  object$coefficients[[dpar]]
}

#' @export
fixef.drmTMB_julia <- function(object, ...) {
  coef.drmTMB_julia(object, ...)
}

#' @export
vcov.drmTMB_julia <- function(object, ...) {
  object$vcov
}

#' @export
confint.drmTMB_julia <- function(
  object,
  parm = NULL,
  level = 0.95,
  method = c("profile", "bootstrap"),
  R = 199L,
  seed = NULL,
  threads = FALSE,
  ...
) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort(
      "Additional arguments in {.arg ...} are not used by Julia-engine confidence intervals yet."
    )
  }
  method <- validate_interval_method(
    method,
    c("profile", "bootstrap"),
    "confint()"
  )
  validate_profile_level(level)
  threads <- drm_julia_validate_threads(threads)
  seed <- drm_julia_validate_seed(seed)
  if (identical(method, "bootstrap")) {
    R <- validate_bootstrap_replicates(R)
  } else {
    R <- 1L
  }

  targets <- profile_match_confint_targets(
    drm_julia_profile_targets(object),
    parm,
    fixed_only = FALSE
  )
  drm_julia_validate_inference_targets(targets)
  target <- targets[1L, , drop = FALSE]
  result <- drm_julia_call_inference(
    object = object,
    method = method,
    level = level,
    R = R,
    seed = seed,
    threads = threads
  )
  drm_julia_inference_confint_row(
    target = target,
    result = result,
    level = level,
    method = method
  )
}

drm_julia_validate_threads <- function(threads) {
  if (
    !is.logical(threads) ||
      length(threads) != 1L ||
      is.na(threads)
  ) {
    cli::cli_abort(
      "{.arg threads} must be a single {.code TRUE} or {.code FALSE}."
    )
  }
  isTRUE(threads)
}

drm_julia_validate_seed <- function(seed) {
  if (is.null(seed)) {
    return(NULL)
  }
  if (
    !is.numeric(seed) ||
      length(seed) != 1L ||
      is.na(seed) ||
      !is.finite(seed) ||
      seed != as.integer(seed)
  ) {
    cli::cli_abort("{.arg seed} must be {.code NULL} or one finite integer.")
  }
  as.integer(seed)
}

drm_julia_validate_inference_targets <- function(targets) {
  if (
    nrow(targets) != 1L ||
      !identical(targets$target_class[[1L]], "random-effect-sd") ||
      !identical(targets$dpar[[1L]], "mu") ||
      !startsWith(targets$term[[1L]], "phylo(") ||
      !identical(targets$tmb_parameter[[1L]], "resd")
  ) {
    cli::cli_abort(c(
      "Julia-engine profile and bootstrap intervals currently support exactly one Gaussian phylogenetic SD target.",
      i = "Use {.code parm = \"sd:mu:phylo(1 | species)\"} for the admitted bridge slice, or refit with {.code engine = \"tmb\"}."
    ))
  }
  if (!isTRUE(targets$profile_ready[[1L]])) {
    cli::cli_abort(c(
      "Julia-engine target {.val {targets$parm[[1L]]}} is not ready for profile or bootstrap intervals.",
      i = "Inventory note: {.val {targets$profile_note[[1L]]}}."
    ))
  }
}

drm_julia_inference_confint_row <- function(target, result, level, method) {
  result <- as.list(result)
  scale <- target$estimate[[1L]] / exp(target$link_estimate[[1L]])
  interval <- exp(c(
    as.numeric(result$lower),
    as.numeric(result$upper)
  )) *
    scale
  diagnostics <- profile_interval_diagnostics(
    interval,
    transformation = target$transformation[[1L]]
  )
  out <- data.frame(
    parm = target$parm,
    level = level,
    lower = interval[[1L]],
    upper = interval[[2L]],
    scale = target$scale,
    transformation = target$transformation,
    tmb_parameter = target$tmb_parameter,
    index = target$index,
    method = method,
    profile.engine = if (identical(method, "profile")) {
      "julia_profile_result"
    } else {
      NA_character_
    },
    conf.status = as.character(result$status),
    profile.boundary = diagnostics$boundary,
    profile.message = if (nzchar(as.character(result$message))) {
      as.character(result$message)
    } else {
      diagnostics$message
    },
    julia.threaded = isTRUE(result$threaded),
    julia.workers = as.integer(result$worker_threads),
    julia.threads = as.integer(result$julia_threads),
    julia.blas_threads = as.integer(result$blas_threads),
    julia.elapsed = as.numeric(result$elapsed),
    stringsAsFactors = FALSE
  )
  if (identical(method, "bootstrap")) {
    out$bootstrap.n <- as.integer(result$used)
    out$bootstrap.failed <- as.integer(result$failed)
    out$bootstrap.parallel <- if (isTRUE(result$threaded)) {
      "julia_threads"
    } else {
      "none"
    }
    out$bootstrap.workers <- as.integer(result$worker_threads)
  }
  row.names(out) <- NULL
  out
}

#' @export
logLik.drmTMB_julia <- function(object, ...) {
  out <- object$logLik
  attr(out, "df") <- object$df
  attr(out, "nobs") <- object$nobs
  class(out) <- "logLik"
  out
}

#' @export
nobs.drmTMB_julia <- function(object, ...) {
  object$nobs
}

#' @export
df.residual.drmTMB_julia <- function(object, ...) {
  object$nobs - object$df
}

#' @export
deviance.drmTMB_julia <- function(object, ...) {
  -2 * as.numeric(stats::logLik(object))
}

#' @export
fitted.drmTMB_julia <- function(object, ...) {
  object$fitted
}

#' @export
residuals.drmTMB_julia <- function(object, type = c("response"), ...) {
  match.arg(type)
  object$residuals
}

#' @export
sigma.drmTMB_julia <- function(object, ...) {
  object$sigma
}

#' @export
corpairs.drmTMB_julia <- function(object, ...) {
  object$corpairs
}

#' @export
rho12.drmTMB_julia <- function(object, ...) {
  pairs <- corpairs.drmTMB_julia(object, ...)
  if (is.list(pairs) && length(pairs) == 0L) {
    cli::cli_abort("This Julia-engine fit has no residual {.code rho12}.")
  }
  pairs
}

#' @export
is_converged.drmTMB_julia <- function(object, include_hessian = FALSE, ...) {
  isTRUE(object$opt$convergence == 0L)
}

#' @export
predict.drmTMB_julia <- function(
  object,
  newdata = NULL,
  dpar = NULL,
  type = c("response"),
  ...
) {
  match.arg(type)
  if (!is.null(newdata)) {
    cli::cli_abort(c(
      "{.fn predict} with {.arg newdata} is not implemented for Julia-engine fits yet.",
      i = "Refit with {.code engine = \"tmb\"}, or call DRM.jl directly for now."
    ))
  }
  if (is.null(dpar)) {
    dpar <- names(object$coefficients)[[1L]]
  }
  dpar <- match.arg(dpar, names(object$coefficients))
  if (dpar %in% c("mu", "mu1", "mu2")) {
    if (is.list(object$fitted)) {
      return(object$fitted[[dpar]])
    }
    return(object$fitted)
  }
  if (dpar %in% c("sigma", "sigma1", "sigma2")) {
    if (is.list(object$sigma)) {
      return(object$sigma[[dpar]])
    }
    return(object$sigma)
  }
  if (identical(dpar, "rho12")) {
    return(rho12.drmTMB_julia(object))
  }
  cli::cli_abort(
    "{.fn predict} for {.code engine = \"julia\"} has no stored response-scale values for {.arg dpar = \"{dpar}\"} yet."
  )
}
