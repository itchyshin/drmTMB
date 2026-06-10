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
  if (drm_julia_is_cross_family(family)) {
    return(drmTMB_julia_xfam_bridge(
      formula = formula,
      family = family,
      data = data,
      env = env,
      weights_missing = weights_missing,
      control = control,
      impute = impute,
      missing = missing,
      call = call
    ))
  }
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
        all.vars(drm_julia_strip_phylo_tree(entry$rhs))
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
  rhs <- deparse1(drm_julia_strip_phylo_tree(entry$rhs))
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
  if (!identical(family_type, "gaussian")) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} can marshal {.fn phylo} only for univariate Gaussian bridge fits in this slice.",
      i = "Use native {.code engine = \"tmb\"} for bivariate or non-Gaussian phylogenetic fits until the bridge has parity tests."
    ))
  }
  if (length(phylo_terms) != 1L) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} currently supports one {.fn phylo} term.",
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
      "{.code engine = \"julia\"} uses DRM.jl's sparse all-node route for phylogenetic bridge fits, which currently requires {.code sigma ~ 1}.",
      i = "Use native {.code engine = \"tmb\"} for phylogenetic models with predictor-dependent residual scale until the sparse Julia route has parity tests."
    ))
  }
  if (!term$group %in% names(data)) {
    cli::cli_abort(
      "Phylogenetic grouping variable {.field {term$group}} was not found in {.arg data}."
    )
  }

  tree <- get(term$tree, envir = env, inherits = TRUE)
  species <- as.character(data[[term$group]])
  cache <- drm_julia_phylo_payload_cache
  if (
    !is.null(cache$full_tree) &&
      identical(cache$full_tree, tree) &&
      identical(cache$full_group, term$group) &&
      identical(cache$full_label, term$label) &&
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
    group = term$group,
    row_order = row_order,
    structured_sd_scales = stats::setNames(
      tree_payload$sd_scale,
      term$label
    )
  )
  cache$full_tree <- tree
  cache$full_group <- term$group
  cache$full_label <- term$label
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
  JuliaCall::julia_command(drm_julia_xfam_helper_source())
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

# ---------------------------------------------------------------------------
# Cross-family bivariate route (engine = "julia").
#
# Routes `family = c(faA, faB)` with faA / faB possibly DIFFERENT (e.g.
# c(poisson(), gaussian())) to DRM.fit_mixed_family, which fits
#   y1 ~ famA(eta1), y2 ~ famB(eta2),  eta_k = X_k beta_k + lambda_k u,  u ~ N(0, 1)
# and reports the dependence on the latent / link scale (Nakagawa & Schielzeth
# 2010). The Gaussian x Gaussian pair keeps the verified residual-rho12
# biv_gaussian route; this cross-family path is taken only when at least one
# axis is non-Gaussian. The TMB path never reaches here.
# ---------------------------------------------------------------------------

# R family -> DRM family tag. NULL means "not a cross-family-supported axis".
#
# Tier-1 axes (Gaussian / Poisson / Binomial) and Tier-2 axes (NB2 / Beta /
# Gamma) are both keyed off base-R `family` objects (class "family"), because
# the cross-family route is composed via `drm_composed_families()` /
# `is_r_family_object()`. The link guard for each axis matches the link the
# DRM.jl `_mf_obs_ll` likelihood assumes: log mean for Poisson / NB2 / Gamma,
# logit mean for Binomial / Beta, identity for Gaussian. DRM.jl fits each
# axis's dispersion internally (log sigma for Gaussian/Beta/Gamma, log size
# for NB2) and returns it, so there is no R-side dispersion to pass in.
#
# Constructors that produce the required base-R `family` objects:
#   gaussian()  poisson()  binomial()                       (Tier 1, stats)
#   glmmTMB::nbinom2()                  -> family "nbinom2"  (Tier 2, NB2)
#   MASS::negative.binomial(theta)      -> family "Negative Binomial(theta)"
#   glmmTMB::beta_family()              -> family "beta"     (Tier 2, Beta)
#   Gamma(link = "log")                 -> family "Gamma"    (Tier 2, Gamma)
drm_julia_xfam_family_tag <- function(family) {
  if (!is_r_family_object(family)) {
    return(NULL)
  }
  if (identical(family$family, "gaussian")) {
    return("gaussian")
  }
  if (identical(family$family, "poisson")) {
    if (!identical(family$link, "log")) {
      return(NULL)
    }
    return("poisson")
  }
  if (identical(family$family, "binomial")) {
    if (!identical(family$link, "logit")) {
      return(NULL)
    }
    return("binomial")
  }
  if (identical(family$family, "nbinom2") || drm_is_nbinom_family(family)) {
    if (!identical(family$link, "log")) {
      return(NULL)
    }
    return("nbinom2")
  }
  if (identical(family$family, "beta")) {
    if (!identical(family$link, "logit")) {
      return(NULL)
    }
    return("beta")
  }
  if (identical(family$family, "Gamma")) {
    # DRM.jl's Gamma axis uses a log mean link; base R Gamma() defaults to
    # "inverse", so only the log-link Gamma composes here.
    if (!identical(family$link, "log")) {
      return(NULL)
    }
    return("gamma")
  }
  NULL
}

# MASS::negative.binomial(theta) tags its family as "Negative Binomial(<theta>)"
# rather than "nbinom2". Treat any such object as an NB2 axis; DRM.jl re-fits the
# size parameter, so the embedded theta is not used.
drm_is_nbinom_family <- function(family) {
  is.character(family$family) &&
    length(family$family) == 1L &&
    grepl("^Negative Binomial", family$family)
}

# TRUE when `family` is a two-element composed family that the cross-family
# Julia route should handle, i.e. both axes map to DRM families and the pair is
# NOT gaussian x gaussian (which keeps the verified biv_gaussian route).
drm_julia_is_cross_family <- function(family) {
  composed <- drm_composed_families(family)
  if (is.null(composed) || length(composed) != 2L) {
    return(FALSE)
  }
  tags <- lapply(composed, drm_julia_xfam_family_tag)
  if (any(vapply(tags, is.null, logical(1L)))) {
    return(FALSE)
  }
  tags <- vapply(tags, identity, character(1L))
  !identical(tags, c("gaussian", "gaussian"))
}

drmTMB_julia_xfam_bridge <- function(
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
      "{.code engine = \"julia\"} cross-family models do not support {.arg weights} yet."
    )
  }
  if (!is.null(impute)) {
    cli::cli_abort(
      "{.code engine = \"julia\"} cross-family models do not support {.arg impute} yet."
    )
  }
  missing_control <- drm_parse_missing_control(missing)
  if (
    !identical(missing_control$response, "drop") ||
      !identical(missing_control$predictor, "fail")
  ) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} cross-family models do not support {.arg missing} routes yet.",
      i = "Cross-family bivariate fits currently require complete responses and predictors."
    ))
  }
  if (!drm_julia_default_control(control)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} cross-family models currently accept only default {.arg control}.",
      i = "TMB optimizer / storage / sparse controls do not apply to the cross-family latent engine."
    ))
  }

  composed <- drm_composed_families(family)
  tags <- vapply(composed, drm_julia_xfam_family_tag, character(1L))
  axes <- drm_julia_xfam_axes(formula = formula, data = data, env = env)

  result <- drm_julia_call_xfam(
    y1 = axes$mu1$y,
    X1 = axes$mu1$X,
    fam1 = tags[[1L]],
    y2 = axes$mu2$y,
    X2 = axes$mu2$X,
    fam2 = tags[[2L]]
  )

  new_drmTMB_julia_xfam(
    result = result,
    call = call,
    formula = formula,
    family = family,
    families = tags,
    axes = axes,
    data = data
  )
}

# Build the (y, X) design for the mu1 and mu2 location formulas. Mirrors the
# native biv_gaussian extraction: each location entry carries a response and an
# RHS, which we turn into `response ~ rhs` and pass through model.frame /
# model.matrix on complete cases.
drm_julia_xfam_axes <- function(formula, data, env) {
  entries <- formula$entries
  dpars <- vapply(entries, `[[`, character(1L), "dpar")

  unsupported <- setdiff(unique(dpars), c("mu1", "mu2"))
  if (length(unsupported) > 0L) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} cross-family models currently support only {.code mu1} and {.code mu2} location formulas.",
      x = "Unsupported parameter{?s}: {.val {unsupported}}.",
      i = "Scale ({.code sigma1} / {.code sigma2}) and correlation ({.code rho12}) formulas are not wired into the cross-family latent engine yet."
    ))
  }
  for (required in c("mu1", "mu2")) {
    if (sum(dpars == required) != 1L) {
      cli::cli_abort(
        "{.code engine = \"julia\"} cross-family models require exactly one {.code {required}} formula."
      )
    }
  }

  mu1 <- drm_julia_xfam_axis(entries[[which(dpars == "mu1")]], data, env, "mu1")
  mu2 <- drm_julia_xfam_axis(entries[[which(dpars == "mu2")]], data, env, "mu2")
  if (length(mu1$y) != length(mu2$y)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} cross-family responses must have equal length after dropping missing rows.",
      x = "{.code mu1} has {length(mu1$y)} complete row{?s}; {.code mu2} has {length(mu2$y)}.",
      i = "Cross-family fits do not yet support per-axis missingness."
    ))
  }
  list(mu1 = mu1, mu2 = mu2)
}

drm_julia_xfam_axis <- function(entry, data, env, dpar) {
  if (is.na(entry$response)) {
    cli::cli_abort(
      "The {.code {dpar}} formula must include a response on the left-hand side."
    )
  }
  rhs <- deparse1(entry$rhs)
  f <- stats::as.formula(
    paste(entry$response, "~", rhs),
    env = env
  )
  mf <- stats::model.frame(f, data = data, na.action = stats::na.omit)
  y <- as.numeric(stats::model.response(mf))
  X <- stats::model.matrix(
    stats::delete.response(stats::terms(mf)),
    mf
  )
  if (length(y) == 0L) {
    cli::cli_abort(
      "No complete observations remain for {.code {dpar}} after dropping missing rows."
    )
  }
  list(
    response = entry$response,
    y = y,
    X = X,
    coef_names = colnames(X)
  )
}

drm_julia_call_xfam <- function(y1, X1, fam1, y2, X2, fam2) {
  if (!requireNamespace("JuliaCall", quietly = TRUE)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} cross-family models require the {.pkg JuliaCall} package.",
      i = "Install it with {.code install.packages(\"JuliaCall\")}, then retry."
    ))
  }
  drm_julia_setup()
  JuliaCall::julia_call(
    "drmTMB_mixed_family",
    as.double(y1),
    drm_julia_as_matrix(X1),
    fam1,
    as.double(y2),
    drm_julia_as_matrix(X2),
    fam2
  )
}

drm_julia_as_matrix <- function(x) {
  out <- as.matrix(x)
  storage.mode(out) <- "double"
  dimnames(out) <- NULL
  out
}

# Julia-side helper, registered once in drm_julia_setup(). Maps family tag
# strings to DRM family instances and calls DRM.fit_mixed_family with the
# profile-likelihood CI on the latent-scale correlation.
drm_julia_xfam_helper_source <- function() {
  paste(
    "function drmTMB_mixed_family(y1, X1, fam1::AbstractString, y2, X2, fam2::AbstractString)",
    "    _fam(s) = s == \"gaussian\" ? DRM.Gaussian() :",
    "             s == \"poisson\"  ? DRM.Poisson() :",
    "             s == \"binomial\" ? DRM.Binomial() :",
    "             s == \"nbinom2\"  ? DRM.NegBinomial2() :",
    "             s == \"beta\"     ? DRM.Beta() :",
    "             s == \"gamma\"    ? DRM.Gamma() :",
    "             error(\"unsupported cross-family tag: \" * s)",
    "    r = DRM.fit_mixed_family(; y1 = Float64.(vec(y1)), X1 = Float64.(X1), fam1 = _fam(fam1),",
    "                               y2 = Float64.(vec(y2)), X2 = Float64.(X2), fam2 = _fam(fam2),",
    "                               profile = true, B = 0)",
    "    return Dict{String,Any}(",
    "        \"rho_latent\"        => r.rho_latent,",
    "        \"rho_ci_wald_lower\" => r.rho_ci_wald[1],",
    "        \"rho_ci_wald_upper\" => r.rho_ci_wald[2],",
    "        \"rho_ci_prof_lower\" => r.rho_ci_profile[1],",
    "        \"rho_ci_prof_upper\" => r.rho_ci_profile[2],",
    "        \"beta1\"             => collect(r.β1),",
    "        \"beta2\"             => collect(r.β2),",
    "        \"lambda1\"           => r.λ1,",
    "        \"lambda2\"           => r.λ2,",
    "        \"sigma1\"            => r.σ1,",
    "        \"sigma2\"            => r.σ2,",
    "        \"loglik\"            => r.loglik,",
    "        \"converged\"         => r.converged,",
    "        \"iterations\"        => r.iterations)",
    "end",
    sep = "\n"
  )
}

new_drmTMB_julia_xfam <- function(
  result,
  call,
  formula,
  family,
  families,
  axes,
  data
) {
  result <- as.list(result)
  scalar <- function(x) as.numeric(x)[[1L]]
  rho_latent <- scalar(result$rho_latent)
  rho_ci_wald <- c(
    lower = scalar(result$rho_ci_wald_lower),
    upper = scalar(result$rho_ci_wald_upper)
  )
  rho_ci_profile <- c(
    lower = scalar(result$rho_ci_prof_lower),
    upper = scalar(result$rho_ci_prof_upper)
  )

  coefficients <- list(
    mu1 = stats::setNames(
      as.numeric(unlist(result$beta1, use.names = FALSE)),
      axes$mu1$coef_names
    ),
    mu2 = stats::setNames(
      as.numeric(unlist(result$beta2, use.names = FALSE)),
      axes$mu2$coef_names
    )
  )

  out <- list(
    call = call,
    formula = formula,
    family = family,
    families = families,
    data = data,
    engine = "julia",
    model = list(
      model_type = "cross_family",
      families = families,
      responses = c(axes$mu1$response, axes$mu2$response),
      dpars = c("mu1", "mu2")
    ),
    bridge = result,
    coefficients = coefficients,
    loadings = c(
      lambda1 = scalar(result$lambda1),
      lambda2 = scalar(result$lambda2)
    ),
    sigma = c(
      sigma1 = scalar(result$sigma1),
      sigma2 = scalar(result$sigma2)
    ),
    rho_latent = rho_latent,
    rho_ci_wald = rho_ci_wald,
    rho_ci_profile = rho_ci_profile,
    logLik = scalar(result$loglik),
    nobs = length(axes$mu1$y),
    opt = list(convergence = if (isTRUE(result$converged)) 0L else 1L)
  )
  class(out) <- c("drmTMB_julia_xfam", "drmTMB_julia")
  out
}

#' @export
print.drmTMB_julia_xfam <- function(x, ...) {
  cli::cli_text("<drmTMB Julia-engine cross-family fit>")
  cli::cli_text(
    "  families: {x$families[[1]]} × {x$families[[2]]}"
  )
  cli::cli_text("  observations: {x$nobs}")
  cli::cli_text("  logLik: {format(x$logLik, digits = 4)}")
  cli::cli_text(
    "  latent rho: {format(x$rho_latent, digits = 4)}"
  )
  cli::cli_text("  convergence: {x$opt$convergence}")
  invisible(x)
}

#' @export
coef.drmTMB_julia_xfam <- function(object, dpar = NULL, ...) {
  if (is.null(dpar)) {
    return(object$coefficients)
  }
  dpar <- match.arg(dpar, names(object$coefficients))
  object$coefficients[[dpar]]
}

#' @export
logLik.drmTMB_julia_xfam <- function(object, ...) {
  out <- object$logLik
  attr(out, "nobs") <- object$nobs
  class(out) <- "logLik"
  out
}

#' @export
nobs.drmTMB_julia_xfam <- function(object, ...) {
  object$nobs
}

#' @export
is_converged.drmTMB_julia_xfam <- function(object, include_hessian = FALSE, ...) {
  isTRUE(object$opt$convergence == 0L)
}

#' Latent-scale correlation from a cross-family Julia fit
#'
#' @param object A `drmTMB_julia_xfam` cross-family fit.
#' @param ... Unused.
#' @return The latent / link-scale correlation between the two responses.
#' @export
rho_latent <- function(object, ...) {
  UseMethod("rho_latent")
}

#' @export
rho_latent.drmTMB_julia_xfam <- function(object, ...) {
  object$rho_latent
}

#' @export
confint.drmTMB_julia_xfam <- function(
  object,
  parm = "rho_latent",
  level = 0.95,
  method = c("profile", "wald"),
  ...
) {
  method <- match.arg(method)
  if (!identical(level, 0.95)) {
    cli::cli_abort(c(
      "Cross-family Julia fits currently return a fixed 95% interval for {.code rho_latent}.",
      i = "The latent-correlation CIs are computed at {.code level = 0.95} inside DRM.fit_mixed_family."
    ))
  }
  if (!is.null(parm) && !identical(parm, "rho_latent")) {
    cli::cli_abort(c(
      "Cross-family Julia fits currently expose a confidence interval only for {.code rho_latent}.",
      i = "Use {.code parm = \"rho_latent\"} (the latent-scale residual correlation)."
    ))
  }
  interval <- if (identical(method, "profile")) {
    object$rho_ci_profile
  } else {
    object$rho_ci_wald
  }
  data.frame(
    parm = "rho_latent",
    level = level,
    lower = unname(interval[["lower"]]),
    upper = unname(interval[["upper"]]),
    scale = "latent",
    method = method,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}
