# Arc 1 slice S3 (amendment A9): the live model-identity sweep.
#
# For every ADMIT cell in the S2 admission census (tools/julia-admission-census.R,
# docs/dev-log/evidence/julia-r-parity/arc1-admission-census/census.tsv), fit the
# NATIVE engine (engine = "tmb") and the BRIDGE (engine = "julia") on a small
# simulated fixture, in ONE persistent Julia session (one R process, so
# `drm_julia_setup_state$ready` caches across cells and only the FIRST cell
# pays Julia's ~30-40s boot + module-compile cost). Compare parameter-name
# sets, parameter count, df, and the integrator label -- NEVER parameter
# VALUES (D-234). See `sweep_classify()` for the five-way classification and
# `sweep_integrator_bridge()` for why the integrator label is a small,
# documented lookup rather than something read off the fit object (DRM.jl's
# `marginal` field never crosses the JuliaCall boundary; see that function's
# comment).
#
# D-139: `sweep_prerun()` times 3 cells first and writes a PRE-RUN line to
# receipt.md; the caller (main()) stops before the full sweep if the
# extrapolated total exceeds 30 minutes.

# ---- environment (belt and braces; the launcher also exports these) -------

sweep_set_env <- function() {
  Sys.setenv(
    JULIA_HOME = "/Users/z3437171/.julia/juliaup/julia-1.13.0+0.aarch64.apple.darwin14/Julia-1.13.app/Contents/Resources/julia/bin",
    DRM_JL_PATH = file.path(Sys.getenv("HOME"), "local-scratch/lanes/DRModels-pin-da8b3f871"),
    DRM_JL_PHYLO_PATH = file.path(Sys.getenv("HOME"), "local-scratch/lanes/DRModels-pin-da8b3f871"),
    DRMTMB_JULIA_TESTS = "true",
    NOT_CRAN = "true",
    OPENBLAS_NUM_THREADS = "1",
    OMP_NUM_THREADS = "1",
    JULIA_NUM_THREADS = "4"
  )
  julia_home <- Sys.getenv("JULIA_HOME")
  path <- Sys.getenv("PATH")
  if (!grepl(julia_home, path, fixed = TRUE)) {
    Sys.setenv(PATH = paste(julia_home, path, sep = .Platform$path.sep))
  }
  invisible(NULL)
}

# ---- reuse the S2 census tool's family/formula helpers ---------------------

sweep_source_census_tool <- function(root = ".") {
  path <- file.path(root, "tools", "julia-admission-census.R")
  env <- new.env(parent = globalenv())
  sys.source(path, envir = env)
  env
}

sweep_read_census <- function(root = ".") {
  path <- file.path(root, "docs", "dev-log", "evidence", "julia-r-parity", "arc1-admission-census", "census.tsv")
  tab <- utils::read.delim(path, stringsAsFactors = FALSE, check.names = FALSE, quote = "", encoding = "UTF-8")
  tab[] <- lapply(tab, as.character)
  tab
}

# ---- the fixture: one small simulated dataset per cell ---------------------
#
# Unlike the S2 census (whose formulas never reach Julia, so response
# CONTENT never matters), this sweep actually fits both engines, so the
# response must be a plausible draw for the family or the fit errors on
# validation before either engine's admission machinery is even exercised.
# D-234: parameter VALUES are never compared, so a converging, family-valid
# draw is the bar -- not accurate recovery. `group_effect` is i.i.d. by tip,
# not a true phylogenetic draw, for the same reason: this sweep asks whether
# the two engines report the SAME MODEL SHAPE, not whether either recovers
# the truth.
sweep_fixture <- function(family, n = 90L, ntip = 15L, seed = 20260924L) {
  set.seed(seed)
  tree <- ape::rcoal(ntip)
  tree$tip.label <- paste0("t", seq_len(ntip))
  grp <- factor(rep(tree$tip.label, each = n %/% ntip), levels = tree$tip.label)
  x <- stats::rnorm(n)
  group_effect <- stats::rnorm(nlevels(grp), 0, 0.4)[as.integer(grp)]
  eta1 <- 0.3 + 0.5 * x + group_effect
  eta2 <- -0.2 + 0.4 * x + group_effect

  mk_gaussian <- function(eta) eta + stats::rnorm(n, 0, 1)
  mk_lognormal <- function(eta) exp(0.3 * eta + stats::rnorm(n, 0, 0.3))
  mk_count <- function(eta) stats::rpois(n, pmax(exp(0.4 * eta + 1), 0.05))
  mk_trunc_count <- function(eta) {
    y <- mk_count(eta)
    y[y == 0L] <- 1L
    y
  }
  mk_gamma <- function(eta) stats::rgamma(n, shape = 4, rate = 4 / pmax(exp(0.3 * eta + 0.5), 0.05))
  mk_prop <- function(eta) {
    p <- stats::plogis(eta)
    pmin(pmax(stats::rbeta(n, p * 6 + 0.5, (1 - p) * 6 + 0.5), 1e-3), 1 - 1e-3)
  }
  mk_binary <- function(eta) stats::rbinom(n, 1, stats::plogis(eta))
  mk_tweedie <- function(eta) {
    stats::rgamma(n, shape = 2, rate = 2 / pmax(exp(0.3 * eta + 0.5), 0.05)) * stats::rbinom(n, 1, 0.7)
  }

  y1 <- switch(family,
    lognormal = ,
    biv_lognormal = mk_lognormal(eta1),
    poisson = ,
    nbinom2 = mk_count(eta1),
    truncated_nbinom2 = mk_trunc_count(eta1),
    gamma = mk_gamma(eta1),
    beta = ,
    zero_one_beta = mk_prop(eta1),
    binomial = mk_binary(eta1),
    tweedie = mk_tweedie(eta1),
    mk_gaussian(eta1)
  )
  y2 <- switch(family,
    biv_lognormal = mk_lognormal(eta2),
    mk_gaussian(eta2)
  )

  trials <- sample(8:20, n, replace = TRUE)
  s <- stats::rbinom(n, trials, stats::plogis(eta1))
  f <- trials - s

  cats <- cut(stats::plogis(eta1) + stats::rnorm(n, 0, 0.2), breaks = c(-Inf, 0.35, 0.65, Inf), labels = c("low", "medium", "high"))
  y_ordinal <- ordered(cats, levels = c("low", "medium", "high"))

  K <- diag(ntip)
  dimnames(K) <- list(tree$tip.label, tree$tip.label)
  A <- diag(ntip)
  dimnames(A) <- list(tree$tip.label, tree$tip.label)
  co <- data.frame(cx = stats::rnorm(ntip), cy = stats::rnorm(ntip), row.names = tree$tip.label)

  data <- data.frame(
    g = grp, id = grp, site = grp, sp = grp, x = x,
    y = y1, y1 = y1, y2 = y2, s = s, f = f, y_ordinal = y_ordinal
  )
  list(data = data, tree = tree, K = K, A = A, co = co)
}

# ---- parameter-name / count / df extraction, engine-agnostic --------------
#
# `coef(fit)`, `fit$sdpars`, and `fit$corpars` are structured the SAME way
# (a named list per dpar, a named vector inside) on BOTH engines -- confirmed
# live (2026-09-24): a native fit's vcov rownames read "mu:(Intercept)" and a
# bridge fit's read "mu_(Intercept)", pure formatting, not a structural
# difference. Building the "dpar:term" key ourselves from the SAME three
# structured fields on both sides avoids that formatting divergence
# entirely, rather than trying to normalise each engine's own separator.
sweep_flatten_named <- function(lst) {
  if (is.null(lst) || length(lst) == 0L) {
    return(character(0L))
  }
  out <- character(0L)
  for (dp in names(lst)) {
    inner <- lst[[dp]]
    if (is.null(inner) || length(inner) == 0L) next
    nm <- names(inner)
    if (is.null(nm)) nm <- as.character(seq_along(inner))
    out <- c(out, paste0(dp, ":", nm))
  }
  out
}

sweep_flatten_phylocov <- function(fit) {
  pc <- fit$phylocov
  if (is.null(pc) || length(pc) == 0L) {
    return(character(0L))
  }
  nm <- names(pc)
  if (is.null(nm)) nm <- as.character(seq_along(pc))
  paste0("phylocov:", nm)
}

# `coef()`, `$sdpars`, and `$corpars` are structured the same way on both
# engines (see the header comment). The bivariate-phylo among-axis covariance
# block is the one EXCEPTION, and lives in a FOURTH, differently-shaped
# field on each side: the bridge reports it as one flat named vector,
# `fit$phylocov` (10 log-Cholesky entries "Sigma_a:L11", ... for a q4 fit --
# measured live, 2026-09-24); native decomposes the SAME 10-parameter block
# across `fit$corpars$phylo` (the among-axis correlations) and
# `fit$sdpars$mu` (the among-axis SDs). Both sides are included here so the
# PARAMETER COUNT lines up; the raw NAME TEXT still will not match for this
# one shape (log-Cholesky entries vs named correlations/SDs), which is a
# labelling-convention gap, not evidence of a different model by itself --
# see this sweep's `note` column and receipt.md's limitations section.
sweep_param_names <- function(fit) {
  coefs <- tryCatch(stats::coef(fit), error = function(e) NULL)
  c(
    sweep_flatten_named(coefs),
    sweep_flatten_named(fit$sdpars),
    sweep_flatten_named(fit$corpars),
    sweep_flatten_phylocov(fit)
  )
}

sweep_df <- function(fit) {
  as.numeric(attr(stats::logLik(fit), "df"))
}

# ---- the integrator label ---------------------------------------------------
#
# DRM.jl tags EVERY fit's internal `marginal` field `:LA` by default
# (src/gaussian_core.jl `_withmarginal`), and `:LA` is the label for BOTH true
# Laplace AND (on specific routes) K-node Gauss-Hermite quadrature -- src/
# poisson.jl's own doc comment: "(1 | g) GHQ under `:LA` (#443)". That field
# never crosses the JuliaCall boundary (DRM.jl's `_bridge_flatten()` in
# src/bridge.jl has no "marginal" key in the dict it hands back to R), so
# there is NOTHING on the R-visible fit object this sweep can read to
# recover it generically. `integrator_bridge()` is therefore a small,
# EXPLICIT, CITED lookup, not a derivation:
#   * Gaussian ordinary random intercept on `sigma` is GHQ-32 under `:LA`,
#     per the ledger row `gaussian_sigma_random_intercept`'s own
#     claim_boundary (inst/extdata/julia-capabilities.tsv): "32-node
#     Gauss-Hermite quadrature (src/gaussian_ranef.jl)"; confirmed by
#     reading src/gaussian_ranef.jl's `_fit_sigma_ranef_gaussian()` directly
#     (2026-09-24): it stamps no `marginal` field at all, and its comment
#     names the K-node Gauss-Hermite construction explicitly.
#   * The non-Gaussian ordinary-random-effect cohort admitted with NO ledger
#     row (poisson/nbinom2/binomial/gamma/beta `(1 | g)`/`(1 + x | g)`,
#     hypothesis (a)) is GHQ-32 under `:LA` for poisson BY DRM.jl's OWN
#     DOCUMENTATION (src/poisson.jl), and ultra-plan.md finding 6 predicts
#     the same for the rest of that cohort by the same mechanism (there is
#     no separate closed-form or Laplace machinery documented for their
#     ordinary random intercept). This sweep does NOT independently verify
#     that prediction for nbinom2/binomial/gamma/beta -- it applies the
#     documented Poisson fact to the family the plan already names, and
#     says so in receipt.md.
# Everything else defaults to "Laplace (:LA default)", the DOCUMENTED
# DRM.jl default -- not independently re-verified by this sweep either.
# Canonical, SHORT labels on purpose: these two values feed a direct
# `identical()` equality test in `sweep_run_cell()` (SAME_MODEL vs
# DIFFERENT_INTEGRATOR), so they must read as EQUAL whenever the documented
# method is the same and DIFFERENT only when it is not -- a decorated,
# per-family citation string here would make every cell compare unequal by
# construction (measured live, 2026-09-24: an earlier version embedded the
# citation directly in the label and every single cell read
# DIFFERENT_INTEGRATOR as a result). The citation lives in the comment above
# `sweep_integrator_bridge()`, not in the value.
sweep_integrator_native <- function() {
  "Laplace" # native drmTMB: a TMB model, always a Laplace approximation
}

sweep_ghq_nongaussian_families <- c("poisson", "nbinom2", "binomial", "gamma", "beta")

sweep_integrator_bridge <- function(family, structure, dpar) {
  is_ordinary_bar <- structure %in% c("(1|g)", "(1+x|g)")
  if (is_ordinary_bar && (identical(dpar, "sigma") || identical(dpar, "sigma1"))) {
    return("GHQ-32") # non-closed-form scale RE, src/gaussian_ranef.jl; see header comment
  }
  if (is_ordinary_bar && dpar %in% c("mu", "mu1") && family %in% sweep_ghq_nongaussian_families) {
    return("GHQ-32") # documented for poisson in src/poisson.jl, extrapolated per finding 6
  }
  "Laplace" # DRM.jl's documented :LA default; not independently re-verified by this sweep
}

# ---- one cell ----------------------------------------------------------------

# Returns the `bf()` ARGUMENT LIST, not a constructed formula: `bf()` (R/bf.R
# `drm_formula()`) stamps `env <- parent.frame()` as the SINGLE environment
# every `phylo()`/`relmat()`/`animal()`/`spatial()` term resolves `tree`/`K`/
# `A`/`co` from (`drm_formula_env()`), captured at the moment `bf()` itself
# runs -- NOT at the moment the resulting formula is later handed to
# `drmTMB()`. Building the args here and calling `do.call(drmTMB::bf, args)`
# directly inside `sweep_run_cell()` (never through a nested helper) is
# therefore required, not stylistic: it is what makes `tree`/`K`/`A`/`co`
# resolve from `sweep_run_cell()`'s own frame, where `sweep_fixture()`'s
# output is bound. Measured live (2026-09-24): calling `bf()` from ONE frame
# removed (inside a `sweep_cell_formula()` wrapper) raised "object 'tree' not
# found" on every phylo/relmat/spatial/animal cell -- fixed by this move.
sweep_cell_formula_args <- function(census_env, family, structure, dpar, fam_obj) {
  if (identical(structure, census_env$census_hurdle_probe_structure)) {
    return(NULL) # handled by the caller via census_hurdle_cross_spelling_formula()
  }
  dpars <- census_env$census_family_dpars(family, fam_obj)
  if (structure %in% census_env$census_bivariate_structures) {
    census_env$census_biv_phylo_formula_args(dpars, structure)
  } else {
    census_env$census_formula_args(family, dpars, dpar, structure)
  }
}

sweep_fit_engine <- function(engine, formula, fam_obj, data) {
  tryCatch(
    list(fit = suppressWarnings(drmTMB::drmTMB(formula, family = fam_obj, data = data, engine = engine)), error = NULL),
    error = function(e) list(fit = NULL, error = gsub("[\r\n]+", " | ", conditionMessage(e)))
  )
}

sweep_classify <- function(bridge_err, native_err, names_match, count_match, df_match, integrator_match) {
  if (!is.null(bridge_err) && !is.null(native_err)) {
    return("ERROR")
  }
  if (!is.null(bridge_err)) {
    return("REFUSED")
  }
  if (!is.null(native_err)) {
    return("NO_NATIVE_TWIN")
  }
  # Model identity is read from df, the number of free parameters: a
  # different df is a different model (the q4 block-diagonal collapse, df 13
  # native vs 17 bridge). Equal df with differing parameter NAMES or reported
  # COUNT is a reporting difference on the same model (e.g. `mu:g` vs
  # `mu:(1 | g)`, or a bridge fit that does not report sdpars), so it reads
  # DIFFERENT_REPORTING and is never a refusal candidate. (Conductor
  # refinement of plan amendment A9, 2026-09-24, after the first sweep.)
  if (!df_match) {
    return("DIFFERENT_MODEL")
  }
  if (!integrator_match) {
    return("DIFFERENT_INTEGRATOR")
  }
  if (!names_match || !count_match) {
    return("DIFFERENT_REPORTING")
  }
  "SAME_MODEL"
}

# Re-derive `classification` for rows that fitted on both engines from the
# columns the sweep already recorded, so a rule refinement does not need a
# second live Julia run. Rows REFUSED / NO_NATIVE_TWIN / ERROR keep theirs.
sweep_reclassify_tsv <- function(path) {
  x <- utils::read.delim(path, colClasses = "character", check.names = FALSE,
                         na.strings = character())
  fitted <- !x$classification %in% c("REFUSED", "NO_NATIVE_TWIN", "ERROR")
  for (i in which(fitted)) {
    x$classification[i] <- sweep_classify(
      NULL, NULL,
      names_match = identical(x$param_names_match[i], "TRUE"),
      count_match = identical(x$native_n_params[i], x$bridge_n_params[i]),
      df_match = identical(x$native_df[i], x$bridge_df[i]),
      integrator_match = identical(x$integrator_native[i], x$integrator_bridge[i])
    )
  }
  utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "")
  invisible(x)
}

sweep_note <- function(x, limit = 400L) {
  if (is.null(x) || !nzchar(x)) {
    return("")
  }
  if (nchar(x) > limit) x <- paste0(substr(x, 1L, limit), " ...")
  x
}

sweep_run_cell <- function(census_env, family, structure, dpar, control) {
  fam_obj <- census_env$census_family_object(family)
  fixture <- sweep_fixture(family)
  data <- fixture$data
  tree <- fixture$tree
  K <- fixture$K
  A <- fixture$A
  co <- fixture$co

  # bf() must be called HERE, in this frame -- see sweep_cell_formula_args()'s
  # header comment: it stamps this frame as the environment tree/K/A/co
  # resolve from.
  if (identical(structure, census_env$census_hurdle_probe_structure)) {
    formula <- census_env$census_hurdle_cross_spelling_formula()
  } else {
    args <- sweep_cell_formula_args(census_env, family, structure, dpar, fam_obj)
    formula <- do.call(drmTMB::bf, args)
  }

  bridge <- sweep_fit_engine("julia", formula, fam_obj, data)
  native <- if (is.null(bridge$error)) sweep_fit_engine("tmb", formula, fam_obj, data) else list(fit = NULL, error = NULL)

  note <- ""
  native_df <- NA_real_
  bridge_df <- NA_real_
  native_n <- NA_integer_
  bridge_n <- NA_integer_
  names_match <- NA
  integrator_native <- sweep_integrator_native()
  integrator_bridge <- sweep_integrator_bridge(family, structure, dpar)

  if (!is.null(bridge$error) && !is.null(native$error)) {
    note <- sprintf("bridge: %s || native: %s", sweep_note(bridge$error), sweep_note(native$error))
    classification <- "ERROR"
  } else if (!is.null(bridge$error)) {
    note <- sweep_note(bridge$error)
    classification <- "REFUSED"
  } else if (!is.null(native$error)) {
    note <- sweep_note(native$error)
    classification <- "NO_NATIVE_TWIN"
    bridge_df <- sweep_df(bridge$fit)
    bridge_n <- length(sweep_param_names(bridge$fit))
  } else {
    native_names <- sweep_param_names(native$fit)
    bridge_names <- sweep_param_names(bridge$fit)
    native_df <- sweep_df(native$fit)
    bridge_df <- sweep_df(bridge$fit)
    native_n <- length(native_names)
    bridge_n <- length(bridge_names)
    names_match <- isTRUE(setequal(native_names, bridge_names))
    count_match <- identical(native_n, bridge_n)
    df_match <- isTRUE(!is.na(native_df) && !is.na(bridge_df) && native_df == bridge_df)
    integrator_match <- identical(integrator_native, integrator_bridge)
    classification <- sweep_classify(NULL, NULL, names_match, count_match, df_match, integrator_match)
    if (!names_match) {
      note <- sprintf(
        "native names: %s || bridge names: %s",
        paste(sort(native_names), collapse = ","), paste(sort(bridge_names), collapse = ",")
      )
    }
  }

  data.frame(
    cell_id = paste(family, structure, dpar, sep = "|"),
    control = control,
    family = family, structure = structure, dpar = dpar,
    formula = paste(deparse(formula), collapse = " "),
    native_df = native_df, bridge_df = bridge_df,
    native_n_params = native_n, bridge_n_params = bridge_n,
    param_names_match = if (isTRUE(names_match)) "TRUE" else if (isFALSE(names_match)) "FALSE" else "",
    integrator_native = integrator_native, integrator_bridge = integrator_bridge,
    classification = classification, note = note,
    stringsAsFactors = FALSE
  )
}

# ---- the grid: every census ADMIT cell, plus the #1267 probe --------------

sweep_grid <- function(census) {
  admit <- census[census$decision == "ADMIT", , drop = FALSE]
  grid <- data.frame(
    family = admit$family, structure = admit$structure, dpar = admit$dpar,
    control = "", stringsAsFactors = FALSE
  )
  grid$control[grid$family == "biv_gaussian" & grid$structure == "bivariate q4 block-diagonal phylo"] <- "positive"
  grid$control[grid$family == "gaussian" & grid$structure == "none" & grid$dpar == "mu"] <- "negative"
  grid$control[grid$family == "gaussian" & grid$structure == "(1|g)" & grid$dpar == "sigma"] <- "negative"
  # The #1267 probe (poisson() + hu ~ 1) is NOT appended here: it is not a
  # census ADMIT cell (it was never tested there) and its formula does not
  # fit the generic per-cell dispatch in sweep_run_cell() (no census
  # structure/dpar key). main() runs it separately via
  # sweep_run_1267_probe() and writes its row after the main grid.
  grid
}

sweep_run_1267_probe <- function(census_env) {
  fam_obj <- stats::poisson(link = "log")
  formula <- drmTMB::bf(y ~ x, hu ~ 1)
  fixture <- sweep_fixture("poisson")
  data <- fixture$data
  bridge <- sweep_fit_engine("julia", formula, fam_obj, data)
  native <- sweep_fit_engine("tmb", formula, fam_obj, data)
  if (is.null(bridge$error) && is.null(native$error)) {
    names_match <- isTRUE(setequal(sweep_param_names(native$fit), sweep_param_names(bridge$fit)))
    note <- "both engines FIT poisson() + hu ~ 1 -- see param_names_match for whether it is the same model"
    native_df <- sweep_df(native$fit)
    bridge_df <- sweep_df(bridge$fit)
    native_n <- length(sweep_param_names(native$fit))
    bridge_n <- length(sweep_param_names(bridge$fit))
    # The probe records no integrator label; both engines use Laplace here.
    classification <- sweep_classify(NULL, NULL, names_match, identical(native_n, bridge_n),
                                     isTRUE(all.equal(native_df, bridge_df)), TRUE)
  } else if (!is.null(bridge$error) && !is.null(native$error)) {
    classification <- "ERROR"
    note <- sprintf("bridge: %s || native: %s", sweep_note(bridge$error), sweep_note(native$error))
    native_df <- bridge_df <- NA_real_
    native_n <- bridge_n <- NA_integer_
    names_match <- NA
  } else if (!is.null(bridge$error)) {
    classification <- "REFUSED"
    note <- sweep_note(bridge$error)
    native_df <- bridge_df <- NA_real_
    native_n <- bridge_n <- NA_integer_
    names_match <- NA
  } else {
    classification <- "NO_NATIVE_TWIN"
    note <- sweep_note(native$error)
    native_df <- NA_real_
    bridge_df <- sweep_df(bridge$fit)
    native_n <- NA_integer_
    bridge_n <- length(sweep_param_names(bridge$fit))
    names_match <- NA
  }
  data.frame(
    cell_id = "poisson|hu modifier (#1267 probe)|hu",
    control = "", family = "poisson", structure = "hu modifier (#1267 probe)", dpar = "hu",
    formula = paste(deparse(formula), collapse = " "),
    native_df = native_df, bridge_df = bridge_df,
    native_n_params = native_n, bridge_n_params = bridge_n,
    param_names_match = if (isTRUE(names_match)) "TRUE" else if (isFALSE(names_match)) "FALSE" else "",
    integrator_native = sweep_integrator_native(), integrator_bridge = sweep_integrator_bridge("poisson", "hu modifier (#1267 probe)", "hu"),
    classification = classification, note = note,
    stringsAsFactors = FALSE
  )
}

# ---- streaming runner --------------------------------------------------------

sweep_open_tsv <- function(path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  con <- file(path, open = "wt")
  writeLines(
    paste(
      c(
        "cell_id", "control", "family", "structure", "dpar", "formula",
        "native_df", "bridge_df", "native_n_params", "bridge_n_params",
        "param_names_match", "integrator_native", "integrator_bridge",
        "classification", "note"
      ),
      collapse = "\t"
    ),
    con
  )
  flush(con)
  con
}

sweep_write_row <- function(con, row) {
  cols <- c(
    "cell_id", "control", "family", "structure", "dpar", "formula",
    "native_df", "bridge_df", "native_n_params", "bridge_n_params",
    "param_names_match", "integrator_native", "integrator_bridge",
    "classification", "note"
  )
  vals <- vapply(cols, function(cn) {
    v <- row[[cn]]
    if (is.na(v)) "" else gsub("[\t\r\n]", " ", as.character(v))
  }, character(1L))
  writeLines(paste(vals, collapse = "\t"), con)
  flush(con)
}

sweep_log <- function(con, ...) {
  if (is.null(con)) {
    return(invisible(NULL))
  }
  writeLines(sprintf(...), con)
  flush(con)
}

# D-139: time `cells` grid rows (in order) inside the SAME persistent
# session, return elapsed seconds and each row's result.
sweep_prerun <- function(census_env, grid, cells, log_con = NULL) {
  rows <- vector("list", length(cells))
  t0 <- Sys.time()
  for (i in seq_along(cells)) {
    idx <- cells[[i]]
    g <- grid[idx, ]
    sweep_log(log_con, "PRE-RUN [%d/%d] %s x %s x %s", i, length(cells), g$family, g$structure, g$dpar)
    rows[[i]] <- sweep_run_cell(census_env, g$family, g$structure, g$dpar, g$control)
  }
  elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  list(elapsed = elapsed, rows = do.call(rbind, rows))
}

main <- function() {
  sweep_set_env()
  root <- "."
  outdir <- file.path(root, "docs", "dev-log", "evidence", "julia-r-parity", "arc1-model-identity")
  dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
  sweep_path <- file.path(outdir, "sweep.tsv")
  receipt_path <- file.path(outdir, "receipt.md")
  log_path <- file.path(outdir, "sweep.log")
  log_con <- file(log_path, open = "wt")
  on.exit(close(log_con), add = TRUE)

  suppressMessages(pkgload::load_all(root, quiet = TRUE))
  census_env <- sweep_source_census_tool(root)
  census <- sweep_read_census(root)
  grid <- sweep_grid(census)
  sweep_log(log_con, "grid built: %d cells (%d positive/negative controls)", nrow(grid), sum(nzchar(grid$control)))

  positive_idx <- which(grid$control == "positive")
  negative_idx <- which(grid$control == "negative")
  binomial_idx <- which(grid$family == "binomial" & grid$structure == "(1|g)" & grid$dpar == "mu")
  prerun_cells <- c(positive_idx[1], negative_idx[1], binomial_idx[1])

  pr <- sweep_prerun(census_env, grid, prerun_cells, log_con)
  extrapolated_min <- pr$elapsed / length(prerun_cells) * nrow(grid) / 60

  receipt_lines <- c(
    "# Arc 1 slice S3: live model-identity sweep receipt",
    "",
    sprintf("PRE-RUN: cells=%d elapsed_s=%.3f extrapolated_total_min=%.3f", length(prerun_cells), pr$elapsed, extrapolated_min)
  )
  writeLines(receipt_lines, receipt_path)
  sweep_log(log_con, "PRE-RUN elapsed_s=%.3f extrapolated_total_min=%.3f", pr$elapsed, extrapolated_min)

  if (extrapolated_min > 30) {
    cat(sprintf(
      "STOP (D-139): extrapolated_total_min=%.3f > 30. Full sweep NOT run.\n",
      extrapolated_min
    ))
    return(invisible(NULL))
  }

  con <- sweep_open_tsv(sweep_path)
  on.exit(close(con), add = TRUE)
  all_rows <- list()
  # Re-run the pre-run cells' rows into the stream (they already ran once
  # above to get the timing; re-running keeps the session state identical to
  # a plain top-to-bottom pass and costs only a few seconds now the module
  # is compiled).
  seen <- rep(FALSE, nrow(grid))
  for (i in prerun_cells) {
    g <- grid[i, ]
    row <- pr$rows[pr$rows$family == g$family & pr$rows$structure == g$structure & pr$rows$dpar == g$dpar, ][1, ]
    sweep_write_row(con, row)
    all_rows[[length(all_rows) + 1L]] <- row
    seen[i] <- TRUE
  }
  remaining <- which(!seen)
  for (j in seq_along(remaining)) {
    i <- remaining[j]
    g <- grid[i, ]
    sweep_log(log_con, "[%d/%d] %s x %s x %s", length(prerun_cells) + j, nrow(grid), g$family, g$structure, g$dpar)
    row <- sweep_run_cell(census_env, g$family, g$structure, g$dpar, g$control)
    sweep_write_row(con, row)
    all_rows[[length(all_rows) + 1L]] <- row
  }
  sweep_log(log_con, "[%d/%d] #1267 probe: poisson() + hu ~ 1", nrow(grid) + 1L, nrow(grid) + 1L)
  probe_row <- sweep_run_1267_probe(census_env)
  sweep_write_row(con, probe_row)
  all_rows[[length(all_rows) + 1L]] <- probe_row

  sweep_tab <- do.call(rbind, all_rows)

  counts <- table(sweep_tab$classification)
  different_model <- sweep_tab[sweep_tab$classification == "DIFFERENT_MODEL", , drop = FALSE]
  errors <- sweep_tab[sweep_tab$classification == "ERROR", , drop = FALSE]
  positive_row <- sweep_tab[sweep_tab$control == "positive", , drop = FALSE]

  drmjl_ref <- tryCatch(
    system2("git", c("-C", shQuote(Sys.getenv("DRM_JL_PATH")), "rev-parse", "HEAD"), stdout = TRUE),
    error = function(e) NA_character_
  )
  julia_version <- tryCatch(
    system2(file.path(Sys.getenv("JULIA_HOME"), "julia"), "--version", stdout = TRUE),
    error = function(e) NA_character_
  )

  more_lines <- c(
    sprintf("POSITIVE-CONTROL-BEFORE-S4: %s", if (nrow(positive_row) == 1L) positive_row$classification else "MISSING"),
    "",
    "## Summary",
    "",
    "Full sweep ran (extrapolated total was within the 30-minute D-139 budget).",
    "",
    "Counts by classification:",
    paste(sprintf("- %s: %d", names(counts), as.integer(counts)), collapse = "\n"),
    "",
    sprintf("Total cells: %d (including the #1267 probe, not part of the census).", nrow(sweep_tab)),
    "",
    "## DIFFERENT_MODEL cells",
    if (nrow(different_model) > 0L) {
      paste(sprintf(
        "- %s | %s | %s: native_df=%s bridge_df=%s native_n=%s bridge_n=%s names_match=%s (%s)",
        different_model$family, different_model$structure, different_model$dpar,
        different_model$native_df, different_model$bridge_df,
        different_model$native_n_params, different_model$bridge_n_params,
        different_model$param_names_match, different_model$note
      ), collapse = "\n")
    } else {
      "(none)"
    },
    "",
    "## ERROR cells (message quoted)",
    if (nrow(errors) > 0L) {
      paste(sprintf("- %s | %s | %s: %s", errors$family, errors$structure, errors$dpar, errors$note), collapse = "\n")
    } else {
      "(none)"
    },
    "",
    "## #1267 probe (poisson() + hu ~ 1)",
    {
      p <- sweep_tab[sweep_tab$structure == "hu modifier (#1267 probe)", , drop = FALSE]
      if (nrow(p) == 1L) {
        sprintf(
          "classification=%s native_df=%s bridge_df=%s names_match=%s note=%s",
          p$classification, p$native_df, p$bridge_df, p$param_names_match, p$note
        )
      } else {
        "(missing)"
      }
    },
    "",
    "## Environment",
    sprintf("- Julia: %s", paste(julia_version, collapse = " ")),
    sprintf("- DRModels.jl pin (measured): %s", paste(drmjl_ref, collapse = "")),
    sprintf("- DRM_JL_PATH: %s", Sys.getenv("DRM_JL_PATH")),
    sprintf(
      "- threads: OPENBLAS_NUM_THREADS=%s OMP_NUM_THREADS=%s JULIA_NUM_THREADS=%s",
      Sys.getenv("OPENBLAS_NUM_THREADS"), Sys.getenv("OMP_NUM_THREADS"), Sys.getenv("JULIA_NUM_THREADS")
    ),
    "",
    "## Limitations",
    "",
    "Values are never compared (D-234); this sweep only compares parameter-name",
    "sets, parameter count, and df. The integrator label is a small, documented",
    "lookup (see `sweep_integrator_bridge()` in tools/julia-model-identity-sweep.R),",
    "not a field read off the fit object -- DRM.jl's internal `marginal` tag",
    "never crosses the JuliaCall boundary, so this sweep cannot independently",
    "verify the GHQ claim for nbinom2/binomial/gamma/beta ordinary random",
    "effects; it applies the Poisson-documented, plan-predicted fact to that",
    "cohort and says so here rather than silently assuming it."
  )
  writeLines(c(readLines(receipt_path), more_lines), receipt_path)

  cat(sprintf("wrote %d sweep rows to %s\n", nrow(sweep_tab), sweep_path))
  print(counts)
  invisible(sweep_tab)
}

if (sys.nframe() == 0L) {
  main()
}
