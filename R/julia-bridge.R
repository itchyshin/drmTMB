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

drm_julia_intentional_gates <- function() {
  data.frame(
    gate_id = c(
      "base_weights",
      "base_impute",
      "base_control",
      "base_missing_predictor_model",
      "base_missing_response_nongaussian",
      "base_unsupported_family",
      "base_nonphylo_count",
      "biv_partial_phylo_q4",
      "biv_rho12_phylo",
      "structured_unsupported_family",
      "structured_sigma_predictor",
      "structured_precision_slot",
      "xfam_missing_route",
      "xfam_rho12_formula",
      "xfam_dispersionless_sigma"
    ),
    route = c(
      rep("base", 7),
      rep("bivariate_phylo", 2),
      rep("structured", 3),
      rep("cross_family", 3)
    ),
    guard = c(
      "weights",
      "impute",
      "control",
      "missing predictor",
      "missing response",
      "family",
      "non-phylo family",
      "partial q4 phylo",
      "rho12 phylo",
      "structured family",
      "structured sigma",
      "structured matrix slot",
      "cross-family missing",
      "cross-family rho12",
      "cross-family dispersion"
    ),
    action = "error",
    evidence = c(
      "DRM.jl bridge payload has no weights slot.",
      "DRM.jl bridge payload has no imputation contract.",
      "Julia optimizer controls need an explicit engine_control surface.",
      "DRM.jl bridge receives complete predictor columns only.",
      "Observed-response masks are admitted only for Gaussian bridge cells.",
      "The R bridge has no coefficient-scale parity tests for this family.",
      "The Julia speed edge for these families is the large-p phylo route.",
      "DRM.jl q4 PLSM bridge expects phylo terms on mu1, mu2, sigma1, and sigma2.",
      "DRM.jl q4 PLSM does not take a phylogenetic residual-correlation axis.",
      "DRM.jl general-covariance bridge is limited to Gaussian, Poisson, NB2, and Gamma.",
      "DRM.jl general-covariance bridge currently requires sigma ~ 1.",
      "DRM.jl bridge consumes covariance/relatedness matrices, not precision slots.",
      "Cross-family bridge currently drops missing rows and requires complete axes.",
      "Cross-family dependence is latent rho from the engine, not an R rho12 formula.",
      "Poisson and Binomial cross-family axes have no dispersion sub-model."
    ),
    issue = "drmTMB#544",
    stringsAsFactors = FALSE
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
  REML = FALSE,
  call
) {
  REML <- drm_control_flag(REML, "REML")
  if (drm_julia_is_cross_family(family)) {
    drm_julia_warn_reml_unsupported(REML, "cross-family")
    return(drmTMB_julia_xfam_bridge(
      formula = formula,
      family = family,
      data = data,
      env = env,
      weights_missing = weights_missing,
      control = control,
      impute = impute,
      missing = missing,
      REML = REML,
      call = call
    ))
  }
  if (drm_julia_has_structured_term(formula)) {
    drm_julia_warn_reml_unsupported(REML, "structured-effect")
    return(drmTMB_julia_structured_bridge(
      formula = formula,
      family = family,
      data = data,
      env = env,
      weights_missing = weights_missing,
      control = control,
      impute = impute,
      missing = missing,
      REML = REML,
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
  family_type <- drm_julia_bridge_family_type(family)
  missing_control <- drm_parse_missing_control(missing)
  if (!drm_julia_missing_supported(missing_control, family_type)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} does not support this {.arg missing} route yet.",
      i = "Supported: {.code response = \"drop\"}, or {.code response = \"include\"} for Gaussian (observed-data fit, tree kept whole). Use {.code engine = \"tmb\"} for other missing-data models."
    ))
  }
  if (!drm_julia_default_control(control)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} currently accepts only default {.arg control}.",
      i = "Use the native {.code engine = \"tmb\"} path for TMB optimizer, storage, sparse, or aggregation controls."
    ))
  }

  has_phylo <- drm_julia_has_phylo_term(formula)
  family_tag <- drm_julia_family_tag(family_type, has_phylo = has_phylo)
  # REML forwards to DRM.jl's `drm(...; method = :REML)` for two univariate
  # Gaussian cells: the fixed-effect location-scale model, and the sigma-phylo
  # location-scale model (phylo on mu AND sigma), which DRM.jl now fits by
  # restricted maximum likelihood (Ayumi #2). The mean-only phylo Gaussian route
  # (sigma ~ 1) and the phylo-only families still return ML on the DRM.jl side,
  # so warn and fit ML rather than silently mislead. Bivariate q4 phylo
  # (`biv_gaussian` with phylo on all four axes) IS now supported — DRM.jl's
  # `drm(biv; method = :REML)` fits the q4 PLSM by Patterson-Thompson restricted
  # likelihood, and the bridge forwards `method = "REML"` to it via the payload.
  reml_supported <- drm_julia_reml_supported(
    formula = formula,
    family_type = family_type
  )
  if (isTRUE(REML) && !reml_supported) {
    drm_julia_warn_reml_unsupported(
      REML,
      drm_julia_reml_cell_label(
        formula = formula,
        family_type = family_type
      )
    )
  }
  bridge_payload <- drm_julia_bridge_payload(
    formula = formula,
    family_type = family_type,
    data = data,
    env = env,
    method = if (isTRUE(REML) && reml_supported) "REML" else "ML"
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
    bridge_payload = bridge_payload,
    requested_REML = isTRUE(REML),
    effective_REML = isTRUE(REML) && isTRUE(reml_supported)
  )
}

drm_julia_default_control <- function(control) {
  if (inherits(control, "drm_control")) {
    default <- drm_control()
    return(identical(control, default))
  }
  is.null(control) || (is.list(control) && length(control) == 0L)
}

# Missing-data routes the Julia engine supports. `response = "drop"` is always
# allowed. `response = "include"` is allowed for Gaussian responses: DRM.jl fits
# the OBSERVED responses while keeping the full tree / design, i.e. the Gaussian
# observed-data likelihood (the missing rows leave the likelihood but their
# phylogenetic positions still inform the covariance). This mirrors native TMB's
# Gaussian-only `response = "include"` scope. `predictor` must be "fail".
drm_julia_missing_supported <- function(missing_control, family_type) {
  identical(missing_control$predictor, "fail") &&
    (identical(missing_control$response, "drop") ||
      (identical(missing_control$response, "include") &&
        # response="include" works for univariate Gaussian AND the bivariate q=4
        # phylo engine (per-cell observed mask threaded through the exact gradient).
        family_type %in% c("gaussian", "biv_gaussian")))
}

# Bridge-local family classifier. drmTMB's native `drm_family_type()` is the
# source of truth for every family the TMB engine fits, but it has no branch for
# a plain base-R `binomial()` (native binomial support is via `beta_binomial()`).
# DRM.jl DOES fit a univariate Binomial phylo model, so the bridge recognizes a
# `binomial(link = "logit")` object here and maps it to the "binomial" tag;
# every other family defers to `drm_family_type()`. The logit-link guard mirrors
# DRM.jl's Binomial likelihood (logit mean); other links fall through to
# `drm_family_type()`, which rejects them with the standard message.
drm_julia_bridge_family_type <- function(family) {
  if (
    inherits(family, "family") &&
      identical(family$family, "binomial") &&
      identical(family$link, "logit")
  ) {
    return("binomial")
  }
  drm_family_type(family)
}

# Families that route through the Julia engine ONLY with a phylo(1 | group)
# random intercept. DRM.jl's sparse all-node Laplace is the large-p
# phylogenetic speed edge for these; a plain GLM without a phylo term stays on
# the native TMB path. Each tag string must match a `_bridge_family` case in
# DRM.jl's src/bridge.jl AND a family whose `drm(...)` method accepts `tree =`.
#   poisson / nbinom2 -> count phylo Laplace (verified large-p lane)
#   gamma / beta      -> non-Gaussian location-scale phylo Laplace (sigma ~ 1)
#   binomial          -> mean-only phylo Laplace
# beta_binomial is deliberately excluded: DRM.jl's BetaBinomial `drm()` has no
# `tree` kwarg, so a beta-binomial phylo fit has no Julia route yet.
drm_julia_phylo_only_families <- function() {
  c("poisson", "nbinom2", "gamma", "beta", "binomial")
}

# Families that support the coupled location-scale phylo route (cluster 4):
# a phylo(1|g) on the mean AND sigma, routed as a 2x2 group-level covariance
# via DRM.jl's coupled `(1|tag|phylo(g))` syntax. NB2 and Gamma both support
# this; Beta uses logit-scale sigma, which also works with _fit_locscale.
# Gaussian routes the both-phylo SHAPE (phylo on mean AND sigma) to DRM.jl's
# Gaussian location-scale phylo Laplace engine (separate-block) -- the capability
# the native TMB engine lacks (Ayumi #2).
drm_julia_locscale_phylo_families <- function() {
  c("gaussian", "nbinom2", "gamma", "beta")
}

# Families that support the structured slope phylo route (cluster 3):
# phylo(1+x|g) on the mean, routed to DRM.jl's _fit_corr_locscale via the
# `_parse_structured_slope` path. NB2, Gamma, Beta, and Poisson support this.
drm_julia_slope_phylo_families <- function() {
  c("nbinom2", "gamma", "beta", "poisson")
}

# Map drmTMB family_type -> DRM.jl bridge family tag, gating which families the
# Julia engine may route. Gaussian one-/two-response models route unconditionally
# (the verified base lane). The phylo-only families above route ONLY when the
# model carries a phylogenetic random intercept. Cluster 4 (locscale) and
# cluster 3 (slope) are gated by their own family sets and route via a phylo
# term as well; the tag is the same family string the bridge.jl family switch
# expects.
drm_julia_family_tag <- function(family_type, has_phylo = FALSE) {
  if (family_type %in% c("gaussian", "biv_gaussian")) {
    return(family_type)
  }
  phylo_only <- drm_julia_phylo_only_families()
  if (isTRUE(has_phylo) && family_type %in% phylo_only) {
    return(family_type)
  }
  if (family_type %in% phylo_only) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} routes {.val {family_type}} models only with a {.fn phylo} random intercept.",
      i = "DRM.jl's sparse all-node engine is the large-p phylogenetic speed edge; use {.code engine = \"tmb\"} for non-phylogenetic {.val {family_type}} models."
    ))
  }
  cli::cli_abort(c(
    "{.code engine = \"julia\"} currently supports Gaussian one-/two-response models and large-p phylogenetic Poisson, NB2, Gamma, Beta, or Binomial models.",
    i = "Use {.code engine = \"tmb\"} for other non-Gaussian drmTMB fits until the R bridge has coefficient-scale parity tests."
  ))
}

# TRUE when any formula entry carries a phylo() structured term.
drm_julia_has_phylo_term <- function(formula) {
  phylo_terms <- unlist(
    lapply(formula$entries, function(entry) {
      Filter(
        function(term) identical(term$type, "phylo"),
        entry$structured
      )
    }),
    recursive = FALSE
  )
  length(phylo_terms) > 0L
}

# TRUE when any formula entry carries a phylo() term on the `sigma` axis. This
# marks the Gaussian location-scale phylo cell (phylo on mu AND sigma), the one
# phylogenetic route DRM.jl now fits by restricted maximum likelihood
# (`drm(...; method = :REML)`) -- the sigma-phylo capability the native TMB engine
# lacks (Ayumi #2). Mean-only phylo Gaussian (sigma ~ 1) and the phylo-only
# families have no `sigma` phylo term, so REML stays gated for them.
drm_julia_has_sigma_phylo_term <- function(formula) {
  sigma_phylo_terms <- unlist(
    lapply(formula$entries, function(entry) {
      Filter(
        function(term) {
          identical(term$type, "phylo") &&
            identical(term$dpar, "sigma")
        },
        entry$structured
      )
    }),
    recursive = FALSE
  )
  length(sigma_phylo_terms) > 0L
}

drm_julia_reml_supported <- function(formula, family_type) {
  has_phylo <- drm_julia_has_phylo_term(formula)
  sigma_phylo <- drm_julia_has_sigma_phylo_term(formula)
  (identical(family_type, "gaussian") &&
    (!isTRUE(has_phylo) || isTRUE(sigma_phylo))) ||
    (identical(family_type, "biv_gaussian") && isTRUE(has_phylo))
}

drm_julia_reml_cell_label <- function(formula, family_type) {
  if (!family_type %in% c("gaussian", "biv_gaussian")) {
    return(paste0("non-Gaussian (", family_type, ")"))
  }
  if (identical(family_type, "biv_gaussian")) {
    return("bivariate Gaussian")
  }
  if (drm_julia_has_phylo_term(formula)) {
    return("mean-only phylogenetic Gaussian")
  }
  "Gaussian"
}

drm_julia_bridge_payload <- function(
  formula,
  family_type,
  data,
  env,
  method = "ML"
) {
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
    options = drm_julia_bridge_options(phylo_payload, method = method),
    row_order = if (is.null(phylo_payload)) NULL else phylo_payload$row_order,
    structured_sd_scales = if (is.null(phylo_payload)) {
      NULL
    } else {
      phylo_payload$structured_sd_scales
    },
    bivariate = if (is.null(phylo_payload)) {
      FALSE
    } else {
      isTRUE(phylo_payload$bivariate)
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

drm_julia_bridge_options <- function(phylo_payload, method = "ML") {
  # `method = "REML"` reaches DRM.jl's `drm(...; method = :REML)` via
  # bridge.jl's `options[:method]` hook (src/bridge.jl:118-120). It is forwarded
  # on the non-phylo Gaussian path and on the Gaussian sigma-phylo location-scale
  # path and on the bivariate q4 phylogenetic route (the caller gates both);
  # the default "ML" leaves the non-REML payload byte-identical to the
  # parity-tested baseline.
  reml <- identical(method, "REML")
  if (is.null(phylo_payload)) {
    if (reml) {
      return(list(method = "REML"))
    }
    return(list())
  }
  if (isTRUE(phylo_payload$bivariate)) {
    # The q=4 PLSM route uses DRM.jl's own optimizer defaults (no g_tol
    # override): the direct-fit parity check matched the bridge to 0 with
    # defaults. REML still has to be forwarded explicitly.
    if (reml) {
      return(list(method = "REML"))
    }
    return(list())
  }

  # The sparse all-node Gaussian phylo route is L-BFGS-based in DRM.jl's
  # current default. The direct AVONET/Hackett benchmark shows the exact-gradient
  # sparse route is insensitive to this tolerance over the bridge-smoke range,
  # while keeping the R payload explicit and reproducible. The sigma-phylo
  # location-scale cell adds `method = "REML"` here when the caller forwards it.
  if (reml) {
    return(list(g_tol = 1e-4, method = "REML"))
  }
  list(g_tol = 1e-4)
}

# Emit a single warning (and fall back to ML) when REML is requested for a
# Julia-engine cell that DRM.jl does not yet fit by restricted maximum
# likelihood. REML remains a Gaussian-only claim: unsupported cells fall back to
# ML instead of implying that a nearby TMB or Julia path is a full REML fallback.
drm_julia_warn_reml_unsupported <- function(REML, cell) {
  if (!isTRUE(REML)) {
    return(invisible(FALSE))
  }
  cli::cli_warn(c(
    "{.code engine = \"julia\"} does not support {.code REML = TRUE} for {cell} models yet; fitting by maximum likelihood (ML) instead.",
    i = "REML is currently a Gaussian-only drmTMB/DRM.jl capability. Use {.code REML = FALSE} for this cell, or simplify to a documented Gaussian REML cell; native {.code engine = \"tmb\"} is only a fallback for its documented univariate Gaussian REML slice."
  ))
  invisible(TRUE)
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
  # Univariate Gaussian keeps the verified sparse all-node route. Poisson, NB2,
  # Gamma, Beta, and Binomial add the non-Gaussian phylo (count / location-scale /
  # mean-only) routes; bivariate Gaussian (q=4 PLSM) admits intercept phylo on
  # mu1/mu2/sigma1/sigma2 sharing ONE tree + grouping factor. All marshal the same
  # tree + group payload. The phylo-only set is shared with `drm_julia_family_tag`.
  phylo_families <- c("gaussian", drm_julia_phylo_only_families())
  if (family_type %in% phylo_families) {
    mu_phylo_terms <- Filter(
      function(term) {
        identical(term$type, "phylo") && identical(term$dpar, "mu")
      },
      phylo_terms
    )
    sigma_phylo_terms <- Filter(
      function(term) {
        identical(term$type, "phylo") && identical(term$dpar, "sigma")
      },
      phylo_terms
    )

    # Cluster 4: location-scale phylo (phylo on mu + phylo on sigma sharing the
    # same group and tree). This routes to DRM.jl's coupled `(1|tag|phylo(g))`
    # engine for NB2/Gamma/Beta. Validated BEFORE the intercept-only guard below
    # so the check on sigma phylo terms is bypassed for this sub-path.
    if (
      length(mu_phylo_terms) == 1L &&
        length(sigma_phylo_terms) == 1L &&
        family_type %in% drm_julia_locscale_phylo_families()
    ) {
      mu_term <- mu_phylo_terms[[1L]]
      sigma_term <- sigma_phylo_terms[[1L]]
      if (
        !identical(mu_term$coef_names, "(Intercept)") ||
          !identical(sigma_term$coef_names, "(Intercept)")
      ) {
        cli::cli_abort(c(
          "{.code engine = \"julia\"} location-scale phylo (cluster 4) supports only intercept phylo terms on mu and sigma.",
          i = "Use {.code phylo(1 | group, tree = tree)} on both {.code mu} and {.code sigma}."
        ))
      }
      if (
        !identical(mu_term$group, sigma_term$group) ||
          !identical(mu_term$tree, sigma_term$tree)
      ) {
        cli::cli_abort(c(
          "{.code engine = \"julia\"} location-scale phylo (cluster 4) requires the mu and sigma {.fn phylo} terms to share the same group and tree.",
          i = "Use the same {.fn phylo} call in both {.code mu} and {.code sigma} formulas."
        ))
      }
      rep_term <- mu_term
      labels <- c(mu_term$label, sigma_term$label)
      bivariate <- FALSE
      locscale_mode <- "phylo_locscale"
    } else {
      # Standard intercept-only phylo on mu (mean-only or simple sigma ~ 1).
      if (length(phylo_terms) != 1L) {
        cli::cli_abort(c(
          "{.code engine = \"julia\"} currently supports one {.fn phylo} term.",
          i = "Use native {.code engine = \"tmb\"} for multiple phylogenetic terms."
        ))
      }
      term <- phylo_terms[[1L]]

      # Cluster 3: structured slope phylo(1+x|g) on mu for NB2/Gamma/Beta/Poisson.
      # Allow multi-entry coef_names (intercept + slope) for the slope families.
      slope_families <- drm_julia_slope_phylo_families()
      is_slope <- identical(term$dpar, "mu") &&
        length(term$coef_names) == 2L &&
        identical(term$coef_names[[1L]], "(Intercept)") &&
        family_type %in% slope_families
      if (
        !identical(term$dpar, "mu") ||
          (!identical(term$coef_names, "(Intercept)") && !is_slope)
      ) {
        cli::cli_abort(c(
          "{.code engine = \"julia\"} currently supports {.code phylo(1 | group, tree = tree)} or {.code phylo(1+x | group, tree = tree)} in the {.code mu} formula.",
          i = "Use native {.code engine = \"tmb\"} for residual-scale phylogenetic effects or direct-SD formulas."
        ))
      }
      if (!is_slope) {
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
        locscale_mode <- "mean_only"
      } else {
        locscale_mode <- "phylo_slope"
      }
      rep_term <- term
      labels <- term$label
      bivariate <- FALSE
    }
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
    if (
      !all(vapply(
        phylo_terms,
        function(t) identical(t$coef_names, "(Intercept)"),
        logical(1L)
      ))
    ) {
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
      "{.code engine = \"julia\"} can marshal {.fn phylo} only for univariate Gaussian, Poisson, NB2, Gamma, Beta, Binomial, or bivariate Gaussian (q=4) fits.",
      i = "Use native {.code engine = \"tmb\"} for other phylogenetic fits until the bridge has parity tests."
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

# Structured markers that carry an auxiliary object (tree / matrix / coords) as a
# named kwarg that DRM.jl receives separately, NOT in the formula. Each marker's
# entry lists the kwarg names to strip before deparsing the formula for the Julia
# bridge: `phylo(1 | g, tree = t)` -> `phylo(1 | g)`,
# `relmat(1 | g, K = K)` -> `relmat(1 | g)`, etc. Stripping also removes the
# object symbol from `all.vars`, so the bridge does not look for the matrix in
# `data`.
drm_julia_structured_marker_kwargs <- function() {
  list(
    phylo = "tree",
    relmat = c("K", "Q"),
    animal = c("A", "Ainv", "pedigree"),
    spatial = c("coords", "mesh")
  )
}

# Back-compat name kept for the phylo route; now strips the auxiliary-object
# kwarg from any structured marker (phylo / relmat / animal / spatial).
drm_julia_strip_phylo_tree <- function(expr) {
  drm_julia_strip_structured_kwargs(expr)
}

drm_julia_strip_structured_kwargs <- function(expr) {
  if (!is.call(expr)) {
    return(expr)
  }
  call <- as.list(expr)
  marker_kwargs <- drm_julia_structured_marker_kwargs()
  head <- call[[1L]]
  marker <- if (is.name(head)) as.character(head) else NULL
  if (!is.null(marker) && marker %in% names(marker_kwargs)) {
    drop <- marker_kwargs[[marker]]
    names_call <- names(call)
    if (is.null(names_call)) {
      keep <- rep(TRUE, length(call))
    } else {
      keep <- !(names_call %in% drop)
      keep[is.na(keep)] <- TRUE
    }
    call <- call[keep]
  } else {
    call[-1L] <- lapply(call[-1L], drm_julia_strip_structured_kwargs)
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
        is.call(bar) &&
          identical(bar[[1L]], as.name("|")) &&
          length(bar) == 3L &&
          is.call(bar[[2L]]) &&
          identical(bar[[2L]][[1L]], as.name("|")) &&
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
  # General-covariance structured route: the user-supplied K / A / coords matrix
  # crosses as a Julia array (or `nothing`) and is forwarded to DRM.drm_bridge,
  # which routes relmat -> K, animal -> A, spatial -> coords (Gaussian) / K
  # (counts/Gamma) into the matching `drm()` keyword.
  JuliaCall::julia_command(
    paste(
      "drmTMB_drm_bridge_structured(formula, family, data, K, A, coords, options) =",
      "DRM.drm_bridge(formula = formula, family = family, data = data, K = K, A = A, coords = coords, options = options)"
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
  bridge_payload = NULL,
  requested_REML = NULL,
  effective_REML = NULL
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
  payload_method <- if (
    is.list(bridge_payload) &&
      is.list(bridge_payload$options) &&
      identical(bridge_payload$options$method, "REML")
  ) {
    "REML"
  } else {
    "ML"
  }
  if (is.null(effective_REML)) {
    effective_REML <- identical(payload_method, "REML")
  }
  if (is.null(requested_REML)) {
    requested_REML <- isTRUE(effective_REML)
  }
  estimator <- if (isTRUE(effective_REML)) "REML" else "ML"
  out <- list(
    call = call,
    formula = formula,
    family = family,
    data = data,
    engine = "julia",
    estimator = estimator,
    REML = isTRUE(effective_REML),
    requested_REML = isTRUE(requested_REML),
    effective_REML = isTRUE(effective_REML),
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
  # Bivariate biv_gaussian q=4 path: four axes mu1/mu2/sigma1/sigma2, each with
  # a phylo SD stored in sdpars[[dpar]]. A biv_gaussian fit IS the bivariate case;
  # drm_julia_profile_targets_biv returns empty targets if no phylo SD is present
  # (e.g. a residual-only bivariate fit), so the gate is just model_type.
  is_biv <- identical(object$model$model_type, "biv_gaussian")
  if (is_biv) {
    return(drm_julia_profile_targets_biv(object))
  }

  # Univariate path (original behaviour): single phylo SD on dpar == "mu".
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

# Bivariate profile targets: one row per axis (mu1, mu2, sigma1, sigma2).
# Each axis has its phylo SD in sdpars[[dpar]], keyed by the axis's phylo term
# label. The Julia `param` names are "sd_<dpar>" (e.g. "sd_mu1") and are used
# later in drm_julia_inference_confint_row to join rows to the Julia result.
drm_julia_profile_targets_biv <- function(object) {
  biv_dpars <- c("mu1", "mu2", "sigma1", "sigma2")
  bp <- object$bridge_payload
  # No phylo tree -> no among-axis SDs to profile (e.g. a residual-only bivariate fit);
  # fall back so confint() reports the supported-targets message.
  if (is.null(bp) || is.null(bp$tree)) {
    return(empty_profile_targets())
  }
  # The bivariate q4 julia fit does NOT populate sdpars (the among-axis Sigma_a
  # lives in the phylocov block). Reconstruct the fitted axis SDs from that
  # stored covariance so profile_targets() remains a truthful target inventory;
  # DRM.jl's drm_bridge_inference later re-derives the interval bounds from the
  # formula + data + tree.
  Sigma_a <- drm_julia_phylocov_matrix(object)
  if (is.null(Sigma_a)) {
    return(empty_profile_targets())
  }
  axis_sd <- sqrt(diag(Sigma_a))
  if (
    length(axis_sd) != length(biv_dpars) ||
      any(!is.finite(axis_sd)) ||
      any(axis_sd <= 0)
  ) {
    return(empty_profile_targets())
  }
  names(axis_sd) <- biv_dpars

  # Term label for the four axis rows. The phylo term shares ONE group across the
  # four axes; its rendered label ("phylo(1 | <group>)") is carried on the fit's
  # structured_sd_scales names, which the bridge populates on BOTH the live fit and
  # the synthetic fixtures — so use that as the primary source. Fall back to the
  # parsed formula's phylo group, then bp$group, then a literal. This labels the
  # confint() parm rows with the real grouping variable instead of "group".
  scales <- object$structured_sd_scales
  if (is.null(scales)) {
    scales <- bp$structured_sd_scales
  }
  scale_label <- if (
    !is.null(scales) && length(scales) && !is.null(names(scales))
  ) {
    names(scales)[[1]]
  } else {
    NULL
  }
  term <- if (!is.null(scale_label) && nzchar(scale_label)) {
    scale_label
  } else {
    phylo_terms <- unlist(
      lapply(bp$formula$entries, function(entry) {
        Filter(function(term) identical(term$type, "phylo"), entry$structured)
      }),
      recursive = FALSE
    )
    group <- if (length(phylo_terms) && !is.null(phylo_terms[[1]]$group)) {
      phylo_terms[[1]]$group
    } else if (!is.null(bp$group)) {
      bp$group
    } else {
      "group"
    }
    paste0("phylo(1 | ", group, ")")
  }
  rows <- vector("list", length(biv_dpars))
  for (i in seq_along(biv_dpars)) {
    dpar <- biv_dpars[[i]]
    rows[[i]] <- new_profile_target_row(
      parm = paste0("sd:", dpar, ":", term),
      target_class = "random-effect-sd",
      dpar = dpar,
      term = term,
      tmb_parameter = paste0("resd_", dpar),
      index = i,
      estimate = unname(axis_sd[[dpar]]),
      link_estimate = log(unname(axis_sd[[dpar]])),
      scale = "response",
      transformation = "exp",
      target_type = "direct",
      profile_ready = TRUE,
      profile_note = "ready"
    )
  }
  out <- do.call(rbind, rows)
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

  # Structured terms that yield a `resd_<group>` SD block on the Julia side:
  # the phylo route plus the general-covariance relmat / animal / spatial route.
  # Keying the SD by each term's formula label (e.g. "relmat(1 | id)") matches
  # the native drmTMB extractor naming.
  structured_types <- c("phylo", drm_julia_structured_marker_types())
  terms <- unlist(
    lapply(formula$entries, function(entry) {
      Filter(
        function(term) term$type %in% structured_types,
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
  if (!is.null(x$estimator)) {
    cli::cli_text("  estimator: {x$estimator}")
  }
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

#' Confidence intervals for a Julia-engine `drmTMB` fit
#'
#' `confint()` on a `engine = "julia"` fit exposes two interval families:
#'
#' * `method = "wald"` (the default) builds symmetric Wald intervals for the
#'   fixed-effect coefficients (mu, sigma, ...) on the linear-predictor (link)
#'   scale, using the fixed-effect covariance DRM.jl marshals back through the
#'   bridge (`vcov(object)`). This mirrors the native drmTMB Wald path, whose
#'   fixed-effect rows are also reported on the link scale.
#' * `method = "profile"` / `method = "bootstrap"` re-enter DRM.jl's inference
#'   primitive for supported phylogenetic SD targets, transformed back to the
#'   positive response scale. The current R bridge exposes the univariate
#'   Gaussian `sd:mu:phylo(1 | species)` target and the four bivariate q = 4
#'   targets `sd:mu1:*`, `sd:mu2:*`, `sd:sigma1:*`, and `sd:sigma2:*`.
#'
#' @param object A `drmTMB_julia` fit.
#' @param parm Optional target selection. For `"wald"`, compact coefficient
#'   labels (`"mu:x"`) or full names (`"fixef:mu:x"`); for `"profile"` /
#'   `"bootstrap"`, supported SD target names such as
#'   `"sd:mu:phylo(1 | species)"` or, for q = 4 bivariate fits,
#'   `"sd:sigma1:phylo(1 | species)"`.
#' @param level Confidence level.
#' @param method `"wald"` (default), `"profile"`, or `"bootstrap"`.
#' @param R Bootstrap replicate count (used only when `method = "bootstrap"`).
#' @param seed Optional bootstrap seed.
#' @param threads Logical; request Julia-side threaded inference for the
#'   profile / bootstrap path.
#' @param ... Unused.
#'
#' @return A confidence-interval data frame with the shared `parm`, `level`,
#'   `lower`, `upper`, `scale`, `transformation`, `tmb_parameter`, `index`,
#'   `method`, and `conf.status` columns.
#' @export
confint.drmTMB_julia <- function(
  object,
  parm = NULL,
  level = 0.95,
  method = c("wald", "profile", "bootstrap"),
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
    c("wald", "profile", "bootstrap"),
    "confint()"
  )
  validate_profile_level(level)

  if (identical(method, "wald")) {
    return(drm_julia_wald_confint(object, parm = parm, level = level))
  }

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
  result <- drm_julia_call_inference(
    object = object,
    method = method,
    level = level,
    R = R,
    seed = seed,
    threads = threads
  )
  # Multi-row (bivariate) path: DRM.jl returns result$multi == TRUE with
  # equal-length vectors for param/estimate/lower/upper/etc. Map each Julia
  # param name ("sd_mu1", …) to the matching target row by dpar, then build
  # one confint row per axis and rbind them.
  if (isTRUE(as.logical(result$multi))) {
    return(drm_julia_inference_confint_multi(
      targets = targets,
      result = result,
      level = level,
      method = method
    ))
  }
  # Univariate path: single target row, scalar lower/upper.
  drm_julia_inference_confint_row(
    target = targets[1L, , drop = FALSE],
    result = result,
    level = level,
    method = method
  )
}

# Wald confidence intervals for the fixed-effect coefficients of a Julia-engine
# fit. The DRM.jl bridge already marshals the fixed-effect coefficient vector
# (`object$coef_vector`, on the link / linear-predictor scale) and the matching
# fixed-effect covariance block (`object$vcov`). This builds the same confint
# table the native Wald path returns, on the link scale, so a routed Poisson /
# NB2 / Gamma / Beta / Binomial / Gaussian phylo fit reports finite coefficient
# intervals wherever DRM.jl returned a finite covariance.
drm_julia_wald_confint <- function(object, parm = NULL, level = 0.95) {
  validate_profile_level(level)
  targets <- drm_julia_wald_targets(object)
  targets <- profile_match_confint_targets(targets, parm, fixed_only = FALSE)
  if (nrow(targets) == 0L) {
    return(empty_confint_table(method = "wald"))
  }

  V <- object$vcov
  z <- stats::qnorm((1 + level) / 2)
  variances <- rep(NA_real_, nrow(targets))
  if (is.matrix(V) && length(V) > 0L) {
    pos <- match(targets$tmb_parameter, rownames(V))
    in_cov <- !is.na(pos)
    variances[in_cov] <- V[cbind(pos[in_cov], pos[in_cov])]
  }
  se <- profile_wald_standard_errors(variances)
  interval_ready <- is.finite(targets$link_estimate) & is.finite(se)
  lower <- rep(NA_real_, nrow(targets))
  upper <- rep(NA_real_, nrow(targets))
  if (any(interval_ready)) {
    lower[interval_ready] <- targets$link_estimate[interval_ready] -
      z * se[interval_ready]
    upper[interval_ready] <- targets$link_estimate[interval_ready] +
      z * se[interval_ready]
  }

  out <- data.frame(
    parm = targets$parm,
    level = level,
    lower = lower,
    upper = upper,
    scale = targets$scale,
    transformation = targets$transformation,
    tmb_parameter = targets$tmb_parameter,
    index = targets$index,
    method = "wald",
    profile.engine = NA_character_,
    conf.status = ifelse(interval_ready, "wald", "wald_unavailable"),
    profile.boundary = NA,
    profile.message = NA_character_,
    stringsAsFactors = FALSE
  )
  row.names(out) <- NULL
  out
}

# Fixed-effect Wald targets for a Julia-engine fit. One row per fixed-effect
# coefficient, keyed by the bridge covariance name (`"<dpar>_<term>"`) so the
# variance can be read straight off `object$vcov`. `scale` / `transformation`
# match the native fixed-effect rows (link scale, identity transform).
drm_julia_wald_targets <- function(object) {
  blocks <- object$coefficients
  if (is.null(blocks) || length(blocks) == 0L) {
    return(empty_profile_targets())
  }
  rows <- list()
  for (dpar in names(blocks)) {
    beta <- blocks[[dpar]]
    if (length(beta) == 0L) {
      next
    }
    terms <- names(beta)
    for (i in seq_along(beta)) {
      rows[[length(rows) + 1L]] <- new_profile_target_row(
        parm = paste0("fixef:", dpar, ":", terms[[i]]),
        target_class = "fixed-effect",
        dpar = dpar,
        term = terms[[i]],
        tmb_parameter = paste0(dpar, "_", terms[[i]]),
        index = i,
        estimate = unname(beta[[i]]),
        link_estimate = unname(beta[[i]]),
        scale = "link",
        transformation = "linear_predictor",
        target_type = "direct",
        profile_ready = FALSE,
        profile_note = "missing_tmb_parameter"
      )
    }
  }
  if (length(rows) == 0L) {
    return(empty_profile_targets())
  }
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  validate_profile_targets(out)
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
  biv_dpars <- c("mu1", "mu2", "sigma1", "sigma2")

  # Bivariate case: exactly 4 rows, one per axis, all phylo RE-SDs.
  is_biv_targets <- nrow(targets) == 4L &&
    all(targets$target_class == "random-effect-sd") &&
    identical(sort(targets$dpar), sort(biv_dpars)) &&
    all(startsWith(targets$term, "phylo(")) &&
    all(startsWith(targets$tmb_parameter, "resd_"))
  if (is_biv_targets) {
    not_ready <- !targets$profile_ready
    if (any(not_ready)) {
      first_bad <- which(not_ready)[[1L]]
      cli::cli_abort(c(
        "Julia-engine bivariate target {.val {targets$parm[[first_bad]]}} is not ready for profile or bootstrap intervals.",
        i = "Inventory note: {.val {targets$profile_note[[first_bad]]}}."
      ))
    }
    return(invisible(NULL))
  }

  # Univariate case: exactly 1 row, dpar == "mu", tmb_parameter == "resd".
  if (
    nrow(targets) != 1L ||
      !identical(targets$target_class[[1L]], "random-effect-sd") ||
      !identical(targets$dpar[[1L]], "mu") ||
      !startsWith(targets$term[[1L]], "phylo(") ||
      !identical(targets$tmb_parameter[[1L]], "resd")
  ) {
    cli::cli_abort(c(
      "Julia-engine profile and bootstrap intervals currently support exactly one Gaussian phylogenetic SD target (univariate) or all four axes (bivariate biv_gaussian).",
      i = "Use {.code parm = \"sd:mu:phylo(1 | species)\"} for the admitted univariate bridge slice, or one of {.code sd:mu1:*}, {.code sd:mu2:*}, {.code sd:sigma1:*}, or {.code sd:sigma2:*} for a bivariate q = 4 bridge fit."
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

# Bivariate multi-row confint builder.
#
# DRM.jl returns a multi-row payload (result$multi == TRUE) with equal-length
# vectors: param ("sd_mu1", "sd_mu2", "sd_sigma1", "sd_sigma2"), lower, upper,
# estimate, std_error (NaN for profile), bounded (profile only), status,
# message, elapsed (scalar). We join by dpar: "sd_mu1" -> dpar "mu1", etc.
# `upper` may be Inf on a flat/collapsed axis — left as-is, never coerced to NA.
# `std_error` may be NaN for profile — ignored (only lower/upper matter).
drm_julia_inference_confint_multi <- function(targets, result, level, method) {
  result <- as.list(result)

  # Julia returns param names like "sd_mu1"; strip leading "sd_" to get dpar.
  julia_params <- as.character(unlist(result$param, use.names = FALSE))
  julia_dpar <- sub("^sd_", "", julia_params)
  julia_lower <- as.numeric(unlist(result$lower, use.names = FALSE))
  julia_upper <- as.numeric(unlist(result$upper, use.names = FALSE))
  julia_estimate <- as.numeric(unlist(result$estimate, use.names = FALSE))
  julia_status <- as.character(unlist(result$status, use.names = FALSE))
  julia_message <- as.character(unlist(result$message, use.names = FALSE))
  # bounded is profile-only; may be absent for bootstrap.
  julia_bounded <- if (!is.null(result$bounded)) {
    as.logical(unlist(result$bounded, use.names = FALSE))
  } else {
    rep(TRUE, length(julia_params))
  }

  # Scalar diagnostics (elapsed, thread counts) come from the top-level result.
  # NULL-safe scalars: the profile payload omits the bootstrap/threading fields, so
  # as.integer(NULL) would give a length-0 column and break data.frame() ("1, 0 rows").
  .int1 <- function(v) {
    if (is.null(v) || length(v) == 0L) NA_integer_ else as.integer(v)[[1L]]
  }
  .num1 <- function(v) {
    if (is.null(v) || length(v) == 0L) NA_real_ else as.numeric(v)[[1L]]
  }
  elapsed <- .num1(result$elapsed)
  threaded <- isTRUE(result$threaded)
  worker_threads <- .int1(result$worker_threads)
  julia_threads <- .int1(result$julia_threads)
  blas_threads <- .int1(result$blas_threads)
  bootstrap_used <- .int1(result$used)
  bootstrap_failed <- .int1(result$failed)

  rows <- vector("list", nrow(targets))
  for (i in seq_len(nrow(targets))) {
    target <- targets[i, , drop = FALSE]
    dpar_i <- target$dpar[[1L]]
    # Match target dpar to Julia param ("mu1" -> "sd_mu1").
    ji <- match(dpar_i, julia_dpar)
    if (is.na(ji)) {
      cli::cli_abort(c(
        "Bivariate confint: DRM.jl result has no entry for axis {.val {dpar_i}}.",
        i = "Julia returned params: {.val {julia_params}}."
      ))
    }
    # DRM.jl returns the among-axis SD bounds ALREADY on the SD (response) scale —
    # do NOT exp()/scale them (that is the univariate log-SD convention). `upper` may
    # be Inf on a flat/collapsed axis; let it propagate (never coerce to NA).
    lo <- julia_lower[[ji]]
    hi <- julia_upper[[ji]]
    is_bounded <- isTRUE(julia_bounded[[ji]])
    # status/message are SCALAR for the whole call (one profile/bootstrap run), so
    # recycle them across axes rather than indexing per-axis.
    status_i <- if (length(julia_status) >= ji) {
      julia_status[[ji]]
    } else if (length(julia_status) >= 1L) {
      julia_status[[1L]]
    } else {
      NA_character_
    }
    message_i <- if (length(julia_message) >= ji) {
      julia_message[[ji]]
    } else if (length(julia_message) >= 1L) {
      julia_message[[1L]]
    } else {
      ""
    }
    diagnostics <- if (all(is.finite(c(lo, hi)))) {
      profile_interval_diagnostics(
        c(lo, hi),
        transformation = target$transformation[[1L]]
      )
    } else {
      list(
        boundary = TRUE,
        message = "upper bound unbounded (flat / collapsed axis)"
      )
    }
    row_i <- data.frame(
      parm = target$parm,
      level = level,
      lower = lo,
      upper = hi,
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
      conf.status = status_i,
      profile.boundary = if (identical(method, "profile")) {
        !is_bounded
      } else {
        diagnostics$boundary
      },
      profile.message = if (nzchar(message_i)) {
        message_i
      } else {
        diagnostics$message
      },
      julia.threaded = threaded,
      julia.workers = worker_threads,
      julia.threads = julia_threads,
      julia.blas_threads = blas_threads,
      julia.elapsed = elapsed,
      stringsAsFactors = FALSE
    )
    if (identical(method, "bootstrap")) {
      row_i$bootstrap.n <- bootstrap_used
      row_i$bootstrap.failed <- bootstrap_failed
      row_i$bootstrap.parallel <- if (threaded) "julia_threads" else "none"
      row_i$bootstrap.workers <- worker_threads
    }
    rows[[i]] <- row_i
  }
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

#' Summarise a Julia-engine `drmTMB` fit
#'
#' Builds a fixed-effect coefficient table (estimate, standard error, z value,
#' and two-sided p value, all on the linear-predictor / link scale) from the
#' coefficients and fixed-effect covariance DRM.jl marshals back through the
#' bridge. Standard errors are the square roots of the diagonal of
#' `vcov(object)`; when DRM.jl did not return a finite covariance for a route
#' the SE / z / p columns are `NA` and `uncertainty$status` records why. The
#' random-effect SD block (e.g. a phylogenetic SD) is reported on its positive
#' response scale.
#'
#' Set `conf.int = TRUE` to append Wald (default) or profile confidence-interval
#' columns. Profile / bootstrap intervals are available only for the Gaussian
#' phylogenetic SD target; see [confint.drmTMB_julia()].
#'
#' @param object A `drmTMB_julia` fit.
#' @param conf.int Logical; append confidence-interval columns.
#' @param level Confidence level for the interval columns.
#' @param method `"wald"` (default) or `"profile"`; only used when
#'   `conf.int = TRUE`.
#' @param ... Unused.
#'
#' @return An object of class `summary.drmTMB_julia` with `coefficients`,
#'   `random` (random-effect SDs), and fit-summary scalars.
#' @export
summary.drmTMB_julia <- function(
  object,
  conf.int = FALSE,
  level = 0.95,
  method = c("wald", "profile"),
  ...
) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort(
      "Additional arguments in {.arg ...} are not used by the Julia-engine summary yet."
    )
  }
  if (!is.logical(conf.int) || length(conf.int) != 1L || is.na(conf.int)) {
    cli::cli_abort(
      "{.arg conf.int} must be a single {.code TRUE} or {.code FALSE}."
    )
  }
  validate_profile_level(level)
  method <- validate_interval_method(method, c("wald", "profile"), "summary()")

  coefficients <- drm_julia_summary_coefficients(object)
  if (conf.int && nrow(coefficients) > 0L) {
    ci <- if (identical(method, "wald")) {
      drm_julia_wald_confint(object, parm = NULL, level = level)
    } else {
      tryCatch(
        confint.drmTMB_julia(
          object,
          parm = NULL,
          level = level,
          method = method
        ),
        error = function(e) NULL
      )
    }
    coefficients <- drm_julia_summary_attach_ci(coefficients, ci, level)
  }

  out <- list(
    call = object$call,
    family = object$family,
    engine = "julia",
    coefficients = coefficients,
    random = drm_julia_summary_random(object),
    sigma = object$sigma,
    logLik = object$logLik,
    aic = object$aic,
    bic = object$bic,
    df = object$df,
    nobs = object$nobs,
    converged = isTRUE(object$opt$convergence == 0L),
    uncertainty = object$uncertainty
  )
  class(out) <- "summary.drmTMB_julia"
  out
}

# Fixed-effect coefficient table (link scale) for the Julia-engine summary.
drm_julia_summary_coefficients <- function(object) {
  beta <- object$coef_vector
  if (is.null(beta) || length(beta) == 0L) {
    return(data.frame(
      dpar = character(),
      term = character(),
      estimate = numeric(),
      std.error = numeric(),
      statistic = numeric(),
      p.value = numeric(),
      stringsAsFactors = FALSE
    ))
  }
  nm <- names(beta)
  V <- object$vcov
  se <- rep(NA_real_, length(beta))
  if (is.matrix(V) && length(V) > 0L) {
    pos <- match(nm, rownames(V))
    in_cov <- !is.na(pos)
    variances <- rep(NA_real_, length(beta))
    variances[in_cov] <- V[cbind(pos[in_cov], pos[in_cov])]
    se <- profile_wald_standard_errors(variances)
  }
  estimate <- unname(beta)
  statistic <- estimate / se
  p.value <- 2 * stats::pnorm(-abs(statistic))
  data.frame(
    dpar = sub("_.*$", "", nm),
    term = sub("^[^_]+_", "", nm),
    estimate = estimate,
    std.error = se,
    statistic = statistic,
    p.value = p.value,
    stringsAsFactors = FALSE
  )
}

# Append lower / upper interval columns from a confint table onto the
# coefficient table, matching on the `fixef:<dpar>:<term>` key.
drm_julia_summary_attach_ci <- function(coefficients, ci, level) {
  coefficients$conf.low <- NA_real_
  coefficients$conf.high <- NA_real_
  coefficients$conf.level <- level
  if (is.null(ci) || nrow(ci) == 0L) {
    return(coefficients)
  }
  key <- paste0("fixef:", coefficients$dpar, ":", coefficients$term)
  idx <- match(key, ci$parm)
  found <- !is.na(idx)
  coefficients$conf.low[found] <- ci$lower[idx[found]]
  coefficients$conf.high[found] <- ci$upper[idx[found]]
  coefficients
}

# Random-effect SD block (response scale) for the Julia-engine summary.
drm_julia_summary_random <- function(object) {
  sdpars <- object$sdpars
  if (is.null(sdpars)) {
    return(data.frame(
      dpar = character(),
      term = character(),
      sd = numeric(),
      stringsAsFactors = FALSE
    ))
  }
  rows <- list()
  for (dpar in names(sdpars)) {
    values <- sdpars[[dpar]]
    if (is.null(values) || length(values) == 0L) {
      next
    }
    rows[[length(rows) + 1L]] <- data.frame(
      dpar = dpar,
      term = names(values),
      sd = unname(values),
      stringsAsFactors = FALSE
    )
  }
  if (length(rows) == 0L) {
    return(data.frame(
      dpar = character(),
      term = character(),
      sd = numeric(),
      stringsAsFactors = FALSE
    ))
  }
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

#' @export
print.summary.drmTMB_julia <- function(x, ...) {
  cli::cli_text("<drmTMB Julia-engine fit summary>")
  cli::cli_text("  observations: {x$nobs}")
  cli::cli_text("  logLik: {format(x$logLik, digits = 4)}")
  cli::cli_text(
    "  convergence: {if (isTRUE(x$converged)) 'converged' else 'not converged'}"
  )
  if (!is.null(x$uncertainty) && !is.null(x$uncertainty$status)) {
    cli::cli_text("  uncertainty: {x$uncertainty$status}")
  }
  cli::cli_text("")
  cli::cli_text("Fixed effects (link scale):")
  print(x$coefficients, row.names = FALSE)
  if (!is.null(x$random) && nrow(x$random) > 0L) {
    cli::cli_text("")
    cli::cli_text("Random effects (SD, response scale):")
    print(x$random, row.names = FALSE)
  }
  invisible(x)
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

# Raw residual rho12 vector as returned by the bridge (per-observation
# `tanh(Xrho . beta_rho)`; constant when `rho12 ~ 1`). This backs `rho12()` and
# `predict(dpar = "rho12")`; it is NOT the public `corpairs()` table. Returns a
# zero-length numeric for fits with no residual correlation block.
drm_julia_rho12_values <- function(object) {
  rho <- object$corpairs
  if (is.null(rho) || (is.list(rho) && length(rho) == 0L)) {
    return(numeric())
  }
  as.numeric(rho)
}

#' @export
corpairs.drmTMB_julia <- function(
  object,
  level = NULL,
  group = NULL,
  block = NULL,
  class = NULL,
  ...
) {
  rows <- list()

  rho <- drm_julia_rho12_values(object)
  if (length(rho) > 0L) {
    rows[[length(rows) + 1L]] <- drm_julia_residual_rho12_corpair(object, rho)
  }

  phylo_rows <- drm_julia_phylo_corpairs(object)
  if (length(phylo_rows) > 0L) {
    rows <- c(rows, phylo_rows)
  }

  out <- if (length(rows) == 0L) {
    empty_corpairs()
  } else {
    do.call(rbind, rows)
  }

  if (!is.null(level)) {
    out <- out[out$level %in% level, , drop = FALSE]
  }
  if (!is.null(group)) {
    out <- out[out$group %in% group, , drop = FALSE]
  }
  if (!is.null(block)) {
    out <- out[out$block %in% block, , drop = FALSE]
  }
  if (!is.null(class)) {
    class <- normalize_corpairs_class_filter(class)
    out <- out[out$class %in% class, , drop = FALSE]
  }
  row.names(out) <- NULL
  corpairs_add_default_interval_provenance(out)
}

# Response names (e.g. "y1" / "y2") carried by the bridge formula entries, used
# to label corpairs rows. Falls back to "y1" / "y2" if an entry is missing.
drm_julia_response_names <- function(object) {
  responses <- stats::setNames(rep(NA_character_, 2L), c("mu1", "mu2"))
  entries <- object$formula$entries
  if (!is.null(entries)) {
    for (entry in entries) {
      if (
        !is.null(entry$dpar) &&
          entry$dpar %in% names(responses) &&
          is.character(entry$response) &&
          length(entry$response) == 1L &&
          !is.na(entry$response)
      ) {
        responses[[entry$dpar]] <- entry$response
      }
    }
  }
  if (is.na(responses[["mu1"]])) {
    responses[["mu1"]] <- "y1"
  }
  if (is.na(responses[["mu2"]])) {
    responses[["mu2"]] <- "y2"
  }
  responses
}

drm_julia_response_for_dpar <- function(responses, dpar) {
  if (dpar %in% c("mu1", "sigma1")) {
    return(unname(responses[["mu1"]]))
  }
  if (dpar %in% c("mu2", "sigma2")) {
    return(unname(responses[["mu2"]]))
  }
  NA_character_
}

# Residual between-response correlation as a one-row corpairs table, mirroring
# `residual_rho12_corpair()` on the native path but reading the raw per-row rho12
# vector the bridge already returns.
drm_julia_residual_rho12_corpair <- function(object, rho) {
  responses <- drm_julia_response_names(object)
  n_coef <- length(object$coefficients[["rho12"]])
  eta <- atanh(pmax(pmin(rho, 1 - 1e-12), -1 + 1e-12))
  new_corpair_row(
    level = "residual",
    group = NA_character_,
    block = NA_character_,
    from_dpar = "residual",
    to_dpar = "residual",
    from_coef = NA_character_,
    to_coef = NA_character_,
    from_response = unname(responses[["mu1"]]),
    to_response = unname(responses[["mu2"]]),
    class = "residual",
    parameter = "rho12",
    estimate = mean(rho),
    min = min(rho),
    max = max(rho),
    n_values = length(rho),
    link_estimate = mean(eta),
    link_min = min(eta),
    link_max = max(eta),
    modelled = n_coef > 1L
  )
}

# Among-axis phylogenetic correlations for a q=4 bivariate location-scale bridge
# fit. The four shared-phylogenetic axes (mu1, mu2, sigma1, sigma2) carry a 4x4
# group-level covariance Sigma_a, stored on the fit by the bridge as the 10
# log-Cholesky entries `phylocov$"Sigma_a:Lij"` (diagonal on the log scale,
# off-diagonals raw; Sigma_a = L L'). This reconstructs Sigma_a, converts it to
# the among-axis correlation matrix, and emits one corpairs row per cross-axis
# pair -- the interpretable coevolution correlations (mean1-mean2 etc.) that the
# native `corpairs.drmTMB` surfaces via `phylo_mu_corpairs()`. The bridge never
# populates `object$corpars`, so this rebuilds the rows directly from Sigma_a.
# Returns an empty list for any non-q=4 / non-phylo fit.
drm_julia_phylo_corpairs <- function(object) {
  Sigma_a <- drm_julia_phylocov_matrix(object)
  if (is.null(Sigma_a)) {
    return(list())
  }
  info <- drm_julia_phylo_block_info(object)
  if (is.null(info)) {
    return(list())
  }
  axes <- c("mu1", "mu2", "sigma1", "sigma2")
  responses <- drm_julia_response_names(object)

  d <- sqrt(diag(Sigma_a))
  if (any(!is.finite(d)) || any(d <= 0)) {
    return(list())
  }
  R <- Sigma_a / outer(d, d)

  pair_index <- utils::combn(seq_along(axes), 2L)
  lapply(seq_len(ncol(pair_index)), function(k) {
    i <- pair_index[1L, k]
    j <- pair_index[2L, k]
    from_dpar <- axes[[i]]
    to_dpar <- axes[[j]]
    estimate <- R[i, j]
    new_corpair_row(
      level = "phylogenetic",
      group = info$group,
      block = info$block,
      from_dpar = from_dpar,
      to_dpar = to_dpar,
      from_coef = "(Intercept)",
      to_coef = "(Intercept)",
      from_response = drm_julia_response_for_dpar(responses, from_dpar),
      to_response = drm_julia_response_for_dpar(responses, to_dpar),
      class = random_correlation_class(
        from_dpar,
        "(Intercept)",
        "(Intercept)",
        to_dpar = to_dpar
      ),
      parameter = format_cross_dpar_cor_label(
        from_dpar,
        to_dpar,
        group = info$group,
        covariance_label = info$block
      ),
      estimate = estimate,
      min = estimate,
      max = estimate,
      n_values = 1L,
      link_estimate = guarded_correlation_link(estimate, guard = 0.999999),
      link_min = guarded_correlation_link(estimate, guard = 0.999999),
      link_max = guarded_correlation_link(estimate, guard = 0.999999),
      modelled = FALSE
    )
  })
}

# Reconstruct the 4x4 among-axis covariance Sigma_a from the bridge's stored
# log-Cholesky factor, or NULL if this fit has no q=4 `phylocov` block. The 10
# entries are named "Sigma_a:L11", "Sigma_a:L21", ... "Sigma_a:L44"; the diagonal
# is exponentiated (working scale), off-diagonals are taken as-is.
drm_julia_phylocov_matrix <- function(object) {
  if (!identical(object$model$model_type, "biv_gaussian")) {
    return(NULL)
  }
  phylocov <- object$coefficients[["phylocov"]]
  if (is.null(phylocov) || length(phylocov) != 10L) {
    return(NULL)
  }
  L <- matrix(0, 4L, 4L)
  for (col in seq_len(4L)) {
    for (rw in col:4L) {
      nm <- sprintf("Sigma_a:L%d%d", rw, col)
      value <- phylocov[[nm]]
      if (is.null(value) || !is.finite(value)) {
        return(NULL)
      }
      L[rw, col] <- if (rw == col) exp(value) else value
    }
  }
  L %*% t(L)
}

# Shared group and covariance-block labels for the q=4 phylo location-scale
# block, read off the fit's phylo() formula terms. The bridge guard guarantees
# all four axes share one grouping factor and tree, so the first phylo term is
# representative. `block` is the explicit covariance label (e.g. "p"); NA when
# the term was written without one. Returns NULL if no phylo term is present.
drm_julia_phylo_block_info <- function(object) {
  entries <- object$formula$entries
  if (is.null(entries)) {
    return(NULL)
  }
  for (entry in entries) {
    for (term in entry$structured) {
      if (identical(term$type, "phylo")) {
        block <- term$covariance_label
        if (is.null(block) || !nzchar(block)) {
          block <- NA_character_
        }
        return(list(group = term$group, block = block))
      }
    }
  }
  NULL
}

#' @export
rho12.drmTMB_julia <- function(object, ...) {
  rho <- drm_julia_rho12_values(object)
  if (length(rho) == 0L) {
    cli::cli_abort("This Julia-engine fit has no residual {.code rho12}.")
  }
  rho
}

#' @export
is_converged.drmTMB_julia <- function(object, include_hessian = FALSE, ...) {
  isTRUE(object$opt$convergence == 0L)
}

# Locate the formula entry that supplies a distributional parameter's mean
# sub-model (`mu` / `mu1` / `mu2`). The fixed-effect coefficient vector and the
# entry's right-hand side together describe the linear predictor, so this is the
# anchor for a newdata prediction. Errors if the parameter has no entry.
drm_julia_predict_entry <- function(object, dpar) {
  entries <- object$formula$entries
  for (entry in entries) {
    if (identical(entry$dpar, dpar)) {
      return(entry)
    }
  }
  cli::cli_abort(
    "{.fn predict} could not find a {.code {dpar}} formula entry on this Julia-engine fit."
  )
}

# Build the mean-model design matrix for `newdata`, reconstructing the model
# terms from the fit's TRAINING data so factor contrasts and column ordering
# match the fitted coefficients. Structured (phylo / spatial) terms are
# group-level and contribute nothing to the population-level linear predictor;
# they are dropped from the right-hand side before the design is built, so the
# returned columns are exactly the fixed-effect regressors named in
# `object$coefficients[[dpar]]`. Random effects are held at zero (population
# level) -- a newdata row need not belong to any fitted group.
drm_julia_predict_design <- function(object, entry, newdata) {
  rhs <- drm_strip_structured_terms(entry$rhs)
  train <- object$data
  if (is.null(train)) {
    cli::cli_abort(
      "{.fn predict} with {.arg newdata} needs the original {.arg data}; this Julia-engine fit did not store it."
    )
  }
  fixed_formula <- stats::reformulate(deparse1(rhs))
  train_terms <- stats::terms(
    stats::model.frame(fixed_formula, data = train)
  )
  xlev <- stats::.getXlevels(
    train_terms,
    stats::model.frame(train_terms, train)
  )
  newdata_frame <- stats::model.frame(
    train_terms,
    data = newdata,
    na.action = stats::na.pass,
    xlev = xlev
  )
  stats::model.matrix(train_terms, newdata_frame, xlev = xlev)
}

# Drop phylo() / spatial() / relmat() / animal() structured markers from a
# right-hand side, leaving only the population-level fixed-effect terms. Returns
# the intercept (`1`) when nothing else remains.
drm_strip_structured_terms <- function(rhs) {
  labels <- attr(stats::terms(stats::reformulate(deparse1(rhs))), "term.labels")
  markers <- c("phylo", "spatial", "relmat", "animal")
  is_structured <- vapply(
    labels,
    function(lab) {
      parsed <- tryCatch(str2lang(lab), error = function(e) NULL)
      is.call(parsed) &&
        is.name(parsed[[1L]]) &&
        as.character(parsed[[1L]]) %in% markers
    },
    logical(1L)
  )
  kept <- labels[!is_structured]
  if (length(kept) == 0L) {
    return(quote(1))
  }
  stats::reformulate(kept)[[2L]]
}

# Inverse-link for the mean of a location parameter, used by `type = "response"`.
# A univariate fit carries the link the linear predictor lives on directly in
# `object$family$linkinv`. A cross-family fit stores a per-axis family TAG in
# `object$families`, so the mu1 / mu2 inverse link is looked up from that tag.
drm_julia_predict_linkinv <- function(object, dpar) {
  if (dpar %in% c("mu1", "mu2") && !is.null(object$families)) {
    tag <- object$families[[if (identical(dpar, "mu1")) 1L else 2L]]
    return(drm_julia_tag_linkinv(tag))
  }
  fam <- object$family
  if (is.list(fam) && is.function(fam$linkinv)) {
    return(fam$linkinv)
  }
  cli::cli_abort(
    "{.fn predict} could not resolve an inverse link for {.code {dpar}} on this Julia-engine fit; use {.code type = \"link\"}."
  )
}

# Mean inverse-link for a DRM.jl cross-family axis tag. Mirrors the links the
# bridge enforces for each family (see `drm_julia_xfam_family_tag`).
drm_julia_tag_linkinv <- function(tag) {
  switch(
    tag,
    gaussian = stats::gaussian()$linkinv,
    poisson = stats::poisson()$linkinv,
    nbinom2 = stats::poisson()$linkinv,
    gamma = stats::poisson()$linkinv,
    binomial = stats::binomial()$linkinv,
    beta = stats::binomial()$linkinv,
    cli::cli_abort(
      "{.fn predict} has no response-scale inverse link for cross-family axis {.val {tag}} yet; use {.code type = \"link\"}."
    )
  )
}

#' Predict from a Julia-engine `drmTMB` fit
#'
#' With `newdata = NULL`, `predict()` returns the stored fitted values for the
#' requested distributional parameter. With `newdata` supplied, it returns a
#' **population-level, fixed-effect** prediction for the location parameter
#' (`mu` / `mu1` / `mu2`): the linear predictor `X %*% beta` built from the
#' fit's fixed-effect coefficients and a design matrix constructed from
#' `newdata` using the training-data model terms. Group-level random effects
#' (phylogenetic / spatial / study) are held at **zero** -- a `newdata` row need
#' not belong to any fitted group -- so the result is the marginal mean at the
#' population level, matching the native [predict.drmTMB()] contract for
#' `newdata`. `type = "link"` returns the linear predictor; `type = "response"`
#' applies the model's inverse link.
#'
#' Predicting `sigma` / `rho12` for fresh `newdata` is not implemented; refit
#' with `engine = "tmb"` for those.
#'
#' @param object A `drmTMB_julia` fit.
#' @param newdata Optional data frame. When supplied, predictions are
#'   population-level (random effects set to zero).
#' @param dpar Distributional parameter to predict. Defaults to the first
#'   (`mu`). With `newdata`, must be a location parameter (`mu` / `mu1` /
#'   `mu2`).
#' @param type `"response"` (default) or `"link"`.
#' @param ... Reserved.
#'
#' @return A numeric vector of predictions, length `nrow(newdata)` when
#'   `newdata` is supplied.
#' @export
predict.drmTMB_julia <- function(
  object,
  newdata = NULL,
  dpar = NULL,
  type = c("response", "link"),
  ...
) {
  type <- match.arg(type)
  if (is.null(dpar)) {
    dpar <- names(object$coefficients)[[1L]]
  }
  dpar <- match.arg(dpar, names(object$coefficients))

  if (!is.null(newdata)) {
    if (!dpar %in% c("mu", "mu1", "mu2")) {
      cli::cli_abort(c(
        "{.fn predict} with {.arg newdata} for {.code engine = \"julia\"} supports only the location parameter ({.code mu} / {.code mu1} / {.code mu2}).",
        i = "Refit with {.code engine = \"tmb\"} to predict {.code {dpar}} on fresh {.arg newdata}."
      ))
    }
    entry <- drm_julia_predict_entry(object, dpar)
    X <- drm_julia_predict_design(object, entry, newdata)
    beta <- object$coefficients[[dpar]]
    common <- intersect(colnames(X), names(beta))
    if (length(common) != length(beta) || length(common) != ncol(X)) {
      cli::cli_abort(c(
        "{.fn predict} could not align the {.arg newdata} design with the fitted {.code {dpar}} coefficients.",
        i = "{.arg newdata} must use the same predictors as the fitted model."
      ))
    }
    eta <- as.numeric(X[, common, drop = FALSE] %*% beta[common])
    if (identical(type, "link")) {
      return(eta)
    }
    linkinv <- drm_julia_predict_linkinv(object, dpar)
    return(linkinv(eta))
  }

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
# Univariate structured (general-covariance) route via engine = "julia".
#
# Routes a univariate `relmat(1 | g)` / `animal(1 | g)` / `spatial(1 | g)` mean
# random intercept to DRM.jl's general-covariance sparse Laplace. Unlike the
# phylo route -- which serializes a tree and lets DRM.jl rebuild the precision --
# these markers carry a USER-SUPPLIED covariance matrix that crosses JuliaCall as
# a plain numeric matrix and is handed to `drm(...)` through the matching keyword:
#
#   relmat(1 | g, K = K)   -> drm(...; K = K)        (relatedness / GRM / kernel)
#   animal(1 | g, A = A)   -> drm(...; A = A)        (additive relationship matrix)
#   spatial(1 | g, coords) -> drm(...; coords = ..)  (Gaussian: coordinate spatial)
#   spatial(1 | g, K = K)  -> drm(...; K = K)        (counts/Gamma: precomputed cov)
#
# DRM.jl rescales the covariance to a unit-diagonal correlation, so the recovered
# `resd_<group>` block is the random-effect SD directly on the response scale (no
# tree-depth SD rescaling -- structured SD scale is 1). The matrix's rows must be
# ordered as the grouping levels first appear in `data` (DRM.jl's convention); the
# bridge passes `data` unreordered, so no row permutation is applied.
#
# Supported families are exactly DRM.jl's general-covariance set: Gaussian,
# Poisson, NB2, and Gamma. Beta / Binomial support only `phylo()` in DRM.jl and
# are rejected here. `Q` (precision), `Ainv`, `pedigree`, and `mesh` marker forms
# are rejected because `drm()` consumes only K / A / coords for these routes.
# ---------------------------------------------------------------------------

# Families that route through the Julia engine with a general-covariance
# structured term (relmat / animal / spatial). This is DRM.jl's user-supplied
# covariance set and is DISTINCT from the phylo-only set: Beta and Binomial fit
# phylo but have no relmat/animal/spatial `drm()` route, so they are excluded.
drm_julia_structured_families <- function() {
  c("gaussian", "poisson", "nbinom2", "gamma")
}

# Structured-marker types this route marshals. Excludes "phylo" (its own
# tree-serializing route) and "phylo_interaction" (Kronecker pair precision, no
# single-matrix bridge form yet).
drm_julia_structured_marker_types <- function() {
  c("relmat", "animal", "spatial")
}

# TRUE when any formula entry carries a relmat / animal / spatial structured term.
drm_julia_has_structured_term <- function(formula) {
  length(drm_julia_collect_structured_terms(formula)) > 0L
}

drm_julia_collect_structured_terms <- function(formula) {
  marker_types <- drm_julia_structured_marker_types()
  unlist(
    lapply(formula$entries, function(entry) {
      Filter(
        function(term) term$type %in% marker_types,
        entry$structured
      )
    }),
    recursive = FALSE
  )
}

drmTMB_julia_structured_bridge <- function(
  formula,
  family,
  data,
  env,
  weights_missing,
  control,
  impute,
  missing,
  REML = FALSE,
  call
) {
  if (!isTRUE(weights_missing)) {
    cli::cli_abort(
      "{.code engine = \"julia\"} structured models do not support {.arg weights} yet."
    )
  }
  if (!is.null(impute)) {
    cli::cli_abort(
      "{.code engine = \"julia\"} structured models do not support {.arg impute} yet."
    )
  }
  family_type <- drm_julia_bridge_family_type(family)
  missing_control <- drm_parse_missing_control(missing)
  if (!drm_julia_missing_supported(missing_control, family_type)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} structured models do not support this {.arg missing} route yet.",
      i = "Supported: {.code response = \"drop\"}, or {.code response = \"include\"} for Gaussian (observed-data fit, tree kept whole). Use {.code engine = \"tmb\"} otherwise."
    ))
  }
  if (!drm_julia_default_control(control)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} structured models currently accept only default {.arg control}.",
      i = "Use the native {.code engine = \"tmb\"} path for TMB optimizer, storage, sparse, or aggregation controls."
    ))
  }

  family_tag <- drm_julia_structured_family_tag(family_type)
  payload <- drm_julia_structured_payload(
    formula = formula,
    family_type = family_type,
    data = data,
    env = env
  )

  result <- drm_julia_call_structured(
    formula = payload$formula,
    family = family_tag,
    data = payload$data,
    matrix = payload$matrix,
    kwarg = payload$kwarg,
    options = payload$options
  )
  new_drmTMB_julia(
    result = result,
    call = call,
    formula = formula,
    family = family,
    data = data,
    family_type = family_type,
    structured_sd_scales = payload$structured_sd_scales,
    bridge_payload = NULL,
    requested_REML = isTRUE(REML),
    effective_REML = FALSE
  )
}

# Gate which families route with a general-covariance structured term. Mirrors
# `drm_julia_family_tag` but for the relmat/animal/spatial set; structured terms
# never appear in a bivariate bridge fit, so only the univariate tags pass.
drm_julia_structured_family_tag <- function(family_type) {
  structured_families <- drm_julia_structured_families()
  if (family_type %in% structured_families) {
    return(family_type)
  }
  cli::cli_abort(c(
    "{.code engine = \"julia\"} routes {.fn relmat} / {.fn animal} / {.fn spatial} structured terms only for univariate Gaussian, Poisson, NB2, or Gamma fits.",
    i = "DRM.jl fits these general-covariance random intercepts for those families; use {.code engine = \"tmb\"} for {.val {family_type}} structured models."
  ))
}

# Validate the single structured term and marshal its user-supplied matrix.
# Returns the DRM.jl formula spec (marker matrix kwarg stripped), the column
# table, the numeric matrix, the `drm()` keyword it maps to ("K" / "A" /
# "coords"), the structured SD scale (always 1 here), and the options list.
drm_julia_structured_payload <- function(formula, family_type, data, env) {
  terms <- drm_julia_collect_structured_terms(formula)
  if (length(terms) != 1L) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} currently supports one {.fn relmat} / {.fn animal} / {.fn spatial} structured term.",
      i = "Use native {.code engine = \"tmb\"} for multiple structured terms."
    ))
  }
  term <- terms[[1L]]

  if (
    !identical(term$dpar, "mu") ||
      !identical(term$coef_names, "(Intercept)")
  ) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} currently supports only {.code {term$type}(1 | group, ...)} in the {.code mu} formula.",
      i = "Use native {.code engine = \"tmb\"} for structured slopes, residual-scale structured effects, or direct-SD formulas."
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
      "{.code engine = \"julia\"} uses DRM.jl's general-covariance sparse route, which currently requires {.code sigma ~ 1}.",
      i = "Use native {.code engine = \"tmb\"} for structured models with predictor-dependent residual scale."
    ))
  }
  if (!term$group %in% names(data)) {
    cli::cli_abort(
      "Structured grouping variable {.field {term$group}} was not found in {.arg data}."
    )
  }

  resolved <- drm_julia_structured_matrix(
    term = term,
    family_type = family_type,
    env = env,
    data = data
  )

  list(
    formula = drm_julia_formula_spec(formula),
    data = drm_julia_bridge_data(data, formula),
    matrix = resolved$matrix,
    kwarg = resolved$kwarg,
    options = list(),
    structured_sd_scales = stats::setNames(1, term$label)
  )
}

# Resolve a structured term's user-supplied matrix to the (numeric matrix,
# `drm()` keyword) pair the Julia bridge needs. The parser stores the marker's
# matrix slot as `structure` (the keyword the USER wrote: "K"/"Q"/"A"/"Ainv"/
# "coords"/"mesh") and `object` (the symbol to look up in `env`). Only the slots
# DRM.jl's `drm()` consumes for these routes are accepted; precision ("Q",
# "Ainv"), pedigree, and mesh forms are rejected with a pointer to `engine="tmb"`.
drm_julia_structured_matrix <- function(term, family_type, env, data) {
  type <- term$type
  slot <- term$structure
  obj_name <- term$object

  if (identical(type, "relmat")) {
    if (!identical(slot, "K")) {
      drm_julia_structured_reject_slot(type, slot, "K", "covariance")
    }
    kwarg <- "K"
  } else if (identical(type, "animal")) {
    if (!identical(slot, "A")) {
      drm_julia_structured_reject_slot(type, slot, "A", "relatedness")
    }
    kwarg <- "A"
  } else {
    # spatial: DRM.jl estimates the spatial range jointly from raw `coords`, which
    # is a GAUSSIAN-only path. The drmTMB grammar only lets `spatial()` carry
    # `coords` / `mesh` (never `K`), so a non-Gaussian spatial fit has no bridge
    # form -- pass the precomputed spatial covariance through `relmat(1 | g, K = K)`
    # instead (DRM.jl fits an identical general-covariance random intercept).
    if (!identical(family_type, "gaussian")) {
      cli::cli_abort(c(
        "{.code engine = \"julia\"} routes {.fn spatial} only for Gaussian fits (coordinate-based range estimation is Gaussian-only in DRM.jl).",
        i = "For a {.val {family_type}} spatial random intercept, pass a precomputed spatial covariance as {.code relmat(1 | {term$group}, K = K)}, or use {.code engine = \"tmb\"}."
      ))
    }
    if (!identical(slot, "coords")) {
      cli::cli_abort(c(
        "{.code engine = \"julia\"} Gaussian {.fn spatial} models require {.arg coords}.",
        x = "Got {.code spatial(1 | {term$group}, {slot} = ...)}.",
        i = "Use {.code spatial(1 | {term$group}, coords = coords)}; {.arg mesh} is not wired into the bridge yet."
      ))
    }
    kwarg <- "coords"
  }

  value <- get(obj_name, envir = env, inherits = TRUE)
  if (!is.matrix(value) && !is.data.frame(value)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} could not marshal {.fn {type}} {.arg {slot}} object {.val {obj_name}}.",
      x = "Expected a numeric matrix or data frame, got {.cls {class(value)}}.",
      i = "Sparse precision objects, pedigrees, and meshes are not marshalled by this route yet."
    ))
  }
  matrix <- drm_julia_as_matrix(value)
  if (!all(is.finite(matrix))) {
    cli::cli_abort(
      "{.code engine = \"julia\"} requires finite values in the {.fn {type}} {.arg {slot}} matrix."
    )
  }
  if (identical(kwarg, "coords")) {
    if (ncol(matrix) < 1L) {
      cli::cli_abort(
        "{.code engine = \"julia\"} {.fn spatial} {.arg coords} must have at least one coordinate column."
      )
    }
  } else if (nrow(matrix) != ncol(matrix)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} {.fn {type}} {.arg {slot}} must be a square covariance/relatedness matrix.",
      x = "Got a {nrow(matrix)} x {ncol(matrix)} matrix."
    ))
  }
  list(matrix = matrix, kwarg = kwarg)
}

drm_julia_structured_reject_slot <- function(type, slot, expected, kind) {
  cli::cli_abort(c(
    "{.code engine = \"julia\"} routes {.fn {type}} only with a {kind} matrix supplied as {.arg {expected}}.",
    x = "Got {.code {type}(1 | group, {slot} = ...)}.",
    i = "Precision / inverse forms ({.arg Q}, {.arg Ainv}) and pedigrees are not marshalled by the bridge; supply the {kind} matrix as {.arg {expected}}, or use {.code engine = \"tmb\"}."
  ))
}

drm_julia_call_structured <- function(
  formula,
  family,
  data,
  matrix,
  kwarg,
  options = list()
) {
  if (!requireNamespace("JuliaCall", quietly = TRUE)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} requires the {.pkg JuliaCall} package.",
      i = "Install it with {.code install.packages(\"JuliaCall\")}, then retry."
    ))
  }

  drm_julia_setup()
  K <- if (identical(kwarg, "K")) matrix else NULL
  A <- if (identical(kwarg, "A")) matrix else NULL
  coords <- if (identical(kwarg, "coords")) matrix else NULL
  JuliaCall::julia_call(
    "drmTMB_drm_bridge_structured",
    formula,
    family,
    as.list(data),
    K,
    A,
    coords,
    if (length(options) == 0L) NULL else options
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
  REML = FALSE,
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
  axes <- drm_julia_xfam_axes(
    formula = formula,
    data = data,
    env = env,
    tags = tags
  )

  result <- drm_julia_call_xfam(
    y1 = axes$mu1$y,
    X1 = axes$mu1$X,
    fam1 = tags[[1L]],
    y2 = axes$mu2$y,
    X2 = axes$mu2$X,
    fam2 = tags[[2L]],
    Xsigma1 = axes$sigma1$X,
    Xsigma2 = axes$sigma2$X
  )

  new_drmTMB_julia_xfam(
    result = result,
    call = call,
    formula = formula,
    family = family,
    families = tags,
    axes = axes,
    data = data,
    requested_REML = isTRUE(REML)
  )
}

# Build the (y, X) design for the mu1 / mu2 location formulas and the optional
# Xsigma1 / Xsigma2 dispersion (log-sigma sub-model) designs. Mirrors the native
# biv_gaussian extraction: each location entry carries a response and an RHS,
# which we turn into `response ~ rhs` and pass through model.frame / model.matrix
# on complete cases.
#
# A `sigma_k` entry carries only an RHS (no response), so we pair it with its
# axis's mu response to build `mu_response ~ sigma_rhs`; na.omit then drops the
# SAME rows the mu axis dropped, keeping the dispersion design row-aligned with
# its location design. An absent `sigma_k` formula yields an intercept-only
# Xsigma (the current scalar-dispersion behaviour). `tags` is the per-axis DRM
# family tag (e.g. "gaussian", "poisson"); a `sigma_k` formula on a
# dispersionless axis (Poisson / Binomial) is rejected, since DRM.jl carries no
# dispersion sub-model there.
drm_julia_xfam_axes <- function(formula, data, env, tags) {
  entries <- formula$entries
  dpars <- vapply(entries, `[[`, character(1L), "dpar")

  unsupported <- setdiff(
    unique(dpars),
    c("mu1", "mu2", "sigma1", "sigma2")
  )
  if (length(unsupported) > 0L) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} cross-family models currently support only {.code mu1} / {.code mu2} location and {.code sigma1} / {.code sigma2} dispersion formulas.",
      x = "Unsupported parameter{?s}: {.val {unsupported}}.",
      i = "Correlation ({.code rho12}) formulas are not wired into the cross-family latent engine yet."
    ))
  }
  for (required in c("mu1", "mu2")) {
    if (sum(dpars == required) != 1L) {
      cli::cli_abort(
        "{.code engine = \"julia\"} cross-family models require exactly one {.code {required}} formula."
      )
    }
  }
  for (optional in c("sigma1", "sigma2")) {
    if (sum(dpars == optional) > 1L) {
      cli::cli_abort(
        "{.code engine = \"julia\"} cross-family models accept at most one {.code {optional}} formula."
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

  sigma1 <- drm_julia_xfam_sigma(
    entry = if (any(dpars == "sigma1")) {
      entries[[which(dpars == "sigma1")]]
    } else {
      NULL
    },
    mu = mu1,
    tag = tags[[1L]],
    data = data,
    env = env,
    dpar = "sigma1"
  )
  sigma2 <- drm_julia_xfam_sigma(
    entry = if (any(dpars == "sigma2")) {
      entries[[which(dpars == "sigma2")]]
    } else {
      NULL
    },
    mu = mu2,
    tag = tags[[2L]],
    data = data,
    env = env,
    dpar = "sigma2"
  )

  list(mu1 = mu1, mu2 = mu2, sigma1 = sigma1, sigma2 = sigma2)
}

# Build one axis's Xsigma design (the log-sigma sub-model regressors). An absent
# `entry` (no sigma_k formula) returns an intercept-only design over the mu
# axis's rows, reproducing the scalar-dispersion default. A present entry must
# land on a dispersion-carrying axis (Gaussian / NB2 / Beta / Gamma); on a
# dispersionless axis (Poisson / Binomial) it is rejected. The design is built
# from `mu_response ~ sigma_rhs` so na.omit drops the same rows the mu axis did,
# keeping Xsigma row-aligned with X.
drm_julia_xfam_sigma <- function(entry, mu, tag, data, env, dpar) {
  dispersionless <- c("poisson", "binomial")
  if (is.null(entry)) {
    return(list(
      X = matrix(1, nrow = length(mu$y), ncol = 1L),
      coef_names = "(Intercept)"
    ))
  }
  if (tag %in% dispersionless) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} cross-family models cannot fit a {.code {dpar}} dispersion sub-model on a {.val {tag}} axis.",
      i = "{.val {tag}} has no dispersion parameter; drop the {.code {dpar}} formula."
    ))
  }
  if (!is.na(entry$response)) {
    cli::cli_abort(
      "The {.code {dpar}} formula must be one-sided (no response on the left-hand side)."
    )
  }
  rhs <- deparse1(entry$rhs)
  f <- stats::as.formula(
    paste(mu$response, "~", rhs),
    env = env
  )
  mf <- stats::model.frame(f, data = data, na.action = stats::na.omit)
  X <- stats::model.matrix(
    stats::delete.response(stats::terms(mf)),
    mf
  )
  if (nrow(X) != length(mu$y)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} cross-family {.code {dpar}} design must align row-for-row with its {.code mu} axis.",
      x = "{.code {dpar}} has {nrow(X)} complete row{?s}; its {.code mu} axis has {length(mu$y)}.",
      i = "Cross-family fits do not yet support per-axis missingness."
    ))
  }
  list(X = X, coef_names = colnames(X))
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

drm_julia_call_xfam <- function(
  y1,
  X1,
  fam1,
  y2,
  X2,
  fam2,
  Xsigma1 = matrix(1, nrow = length(y1), ncol = 1L),
  Xsigma2 = matrix(1, nrow = length(y2), ncol = 1L)
) {
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
    fam2,
    drm_julia_as_matrix(Xsigma1),
    drm_julia_as_matrix(Xsigma2)
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
    "function drmTMB_mixed_family(y1, X1, fam1::AbstractString, y2, X2, fam2::AbstractString, Xsigma1, Xsigma2)",
    "    _fam(s) = s == \"gaussian\" ? DRM.Gaussian() :",
    "             s == \"poisson\"  ? DRM.Poisson() :",
    "             s == \"binomial\" ? DRM.Binomial() :",
    "             s == \"nbinom2\"  ? DRM.NegBinomial2() :",
    "             s == \"beta\"     ? DRM.Beta() :",
    "             s == \"gamma\"    ? DRM.Gamma() :",
    "             error(\"unsupported cross-family tag: \" * s)",
    "    r = DRM.fit_mixed_family(; y1 = Float64.(vec(y1)), X1 = Float64.(X1), fam1 = _fam(fam1),",
    "                               y2 = Float64.(vec(y2)), X2 = Float64.(X2), fam2 = _fam(fam2),",
    "                               Xsigma1 = Float64.(Xsigma1), Xsigma2 = Float64.(Xsigma2),",
    "                               profile = true, B = 0)",
    "    return Dict{String,Any}(",
    "        \"rho_latent\"        => r.rho_latent,",
    "        \"rho_ci_wald_lower\" => r.rho_ci_wald[1],",
    "        \"rho_ci_wald_upper\" => r.rho_ci_wald[2],",
    "        \"rho_ci_prof_lower\" => r.rho_ci_profile[1],",
    "        \"rho_ci_prof_upper\" => r.rho_ci_profile[2],",
    "        \"beta1\"             => collect(r.\u{03b2}1),",
    "        \"beta2\"             => collect(r.\u{03b2}2),",
    "        \"sigma_coef1\"       => collect(r.\u{03b2}\u{03c3}1),",
    "        \"sigma_coef2\"       => collect(r.\u{03b2}\u{03c3}2),",
    "        \"lambda1\"           => r.\u{03bb}1,",
    "        \"lambda2\"           => r.\u{03bb}2,",
    "        \"sigma1\"            => r.\u{03c3}1,",
    "        \"sigma2\"            => r.\u{03c3}2,",
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
  data,
  requested_REML = FALSE
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

  # Dispersion (log-sigma) sub-model coefficients, one block per axis. The engine
  # returns an empty vector for a dispersionless axis (Poisson / Binomial), in
  # which case the block is a zero-length named numeric. Otherwise the names are
  # the Xsigma design columns ("(Intercept)" + any sigma_k covariates).
  sigma_coef_axis <- function(raw, coef_names) {
    vals <- as.numeric(unlist(raw, use.names = FALSE))
    if (length(vals) == length(coef_names)) {
      stats::setNames(vals, coef_names)
    } else {
      vals
    }
  }
  sigma_coef <- list(
    sigma1 = sigma_coef_axis(result$sigma_coef1, axes$sigma1$coef_names),
    sigma2 = sigma_coef_axis(result$sigma_coef2, axes$sigma2$coef_names)
  )

  out <- list(
    call = call,
    formula = formula,
    family = family,
    families = families,
    data = data,
    engine = "julia",
    estimator = "ML",
    REML = FALSE,
    requested_REML = isTRUE(requested_REML),
    effective_REML = FALSE,
    model = list(
      model_type = "cross_family",
      families = families,
      responses = c(axes$mu1$response, axes$mu2$response),
      dpars = c("mu1", "mu2")
    ),
    bridge = result,
    coefficients = coefficients,
    sigma_coef = sigma_coef,
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
    "  families: {x$families[[1]]} \u{00d7} {x$families[[2]]}"
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
  # Location blocks (mu1 / mu2) plus, when present, the log-sigma dispersion
  # sub-model blocks (sigma1 / sigma2). The latter are zero-length for a
  # dispersionless axis (Poisson / Binomial).
  blocks <- c(object$coefficients, object$sigma_coef)
  dpar <- match.arg(dpar, names(blocks))
  blocks[[dpar]]
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
is_converged.drmTMB_julia_xfam <- function(
  object,
  include_hessian = FALSE,
  ...
) {
  isTRUE(object$opt$convergence == 0L)
}

#' Latent-scale correlation from a cross-family Julia fit
#'
#' @param object A `drmTMB_julia_xfam` cross-family fit.
#' @param ... Unused.
#' @return The latent / link-scale correlation between the two responses.
#' @export
#'
#' @examples
#' \dontrun{
#' # Requires the DRM.jl engine (engine = "julia").
#' set.seed(20260610)
#' n <- 150
#' x <- rnorm(n)
#' u <- rnorm(n)
#' dat <- data.frame(
#'   y1 = 0.5 + 0.8 * x + 0.7 * u + rnorm(n, sd = 0.5),
#'   y2 = rpois(n, exp(0.4 + 0.3 * x + 0.4 * u)),
#'   x = x
#' )
#'
#' fit <- drmTMB(
#'   bf(mu1 = y1 ~ x, mu2 = y2 ~ x),
#'   family = c(gaussian(), poisson()),
#'   data = dat,
#'   engine = "julia"
#' )
#'
#' rho_latent(fit)
#' }
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
