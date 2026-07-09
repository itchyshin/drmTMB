#' Fit a distributional regression model with TMB
#'
#' `drmTMB()` is the main model-fitting entry point. The current implementation
#' supports univariate Gaussian location-scale models,
#' univariate Student-t and skew-normal location-scale-shape models, lognormal
#' location-scale models, Gamma mean-CV models for positive responses,
#' Tweedie mean-scale-power models for non-negative semicontinuous responses,
#' beta mean-scale models for strict proportions,
#' zero-one beta mean-scale-boundary models for continuous proportions with
#' structural exact zeroes or ones,
#' beta-binomial mean-overdispersion models for success counts,
#' fixed-effect Bernoulli/binomial event-probability models,
#' fixed-effect cumulative-logit ordinal location models, fixed-effect Poisson
#' mean, zero-inflated Poisson, negative-binomial mean-dispersion,
#' zero-inflated negative-binomial mean-dispersion, zero-truncated
#' negative-binomial mean-dispersion, and hurdle negative-binomial
#' mean-dispersion models for counts. Student-t, lognormal, Gamma, beta,
#' ordinary Poisson, ordinary negative-binomial, beta-binomial, and
#' zero-truncated negative-binomial `mu` formulas support ordinary unlabelled
#' random intercepts and independent numeric slopes where
#' documented. Binomial `mu` formulas may include standard R `offset()` terms
#' on the logit-event-probability scale. Poisson, ordinary negative-binomial,
#' and zero-truncated negative-binomial `mu` formulas may include standard R
#' `offset(log(exposure))` terms for exposure or effort,
#' Gaussian random intercepts, independent numeric random slopes,
#' and labelled or unlabelled correlated numeric random intercept-slope blocks
#' in the location formula,
#' known sampling covariance through `meta_V(V = V)` with
#' deprecated `meta_known_V(V = V)` retained as a compatibility alias,
#' residual-scale
#' random intercepts and independent numeric random slopes in the scale formula,
#' labelled `mu`/`sigma`
#' random-intercept covariance blocks, and one or more group-level
#' random-effect scale formulae such as `sd(id) ~ x_group`, plus
#' phylogenetic random intercepts, one numeric phylogenetic random slope, and
#' `sd_phylo(species) ~ x_species` direct-SD models in univariate Gaussian
#' location formulas, Gaussian `mu` animal-model and user-supplied relatedness
#' random intercepts and one numeric random slope, matching
#' bivariate Gaussian `mu1`/`mu2` location formulas, and matching labelled
#' bivariate Gaussian `mu1`/`mu2`/`sigma1`/`sigma2` phylogenetic
#' location-scale blocks, coordinate-based spatial random intercepts and one
#' numeric coordinate-spatial slope in univariate Gaussian `mu`,
#' fixed-effect bivariate Gaussian distributional models, and matched labelled
#' bivariate Gaussian `mu1`/`mu2`, `sigma1`/`sigma2`, and same-response
#' `mu`/`sigma` random-intercept covariance blocks, including the first
#' matching slope-only `mu1`/`mu2` covariance block, the first all-four q=4
#' ordinary random-intercept covariance blocks, and
#' predictor-dependent q=2 ordinary or phylogenetic `corpair()` regressions.
#' Bivariate Gaussian location formulas may be written explicitly as
#' `mu1 = y1 ~ ...`, `mu2 = y2 ~ ...`, or with `mvbind(y1, y2) ~ ...` shorthand
#' when both responses share the same location predictors.
#'
#' @param formula A `drm_formula` object created by [drm_formula()] or [bf()].
#' @param family A response family, such as [stats::gaussian()], [student()],
#'   [skew_normal()], [lognormal()], [stats::Gamma()] with `link = "log"`,
#'   \code{\link[=tweedie]{tweedie()}}, [beta()], [zero_one_beta()],
#'   [beta_binomial()], [stats::binomial()] with `link = "logit"`,
#'   [cumulative_logit()], [stats::poisson()] with `link = "log"`, [nbinom2()],
#'   [truncated_nbinom2()], or [biv_gaussian()]. Adding
#'   `zi ~ predictors` to a Poisson or `nbinom2()` model fits the corresponding
#'   zero-inflated count model. Adding `hu ~ predictors` to a
#'   `truncated_nbinom2()` model fits a hurdle count model whose nonzero counts
#'   use the zero-truncated NB2 component. The current
#'   bivariate Gaussian engine also accepts
#'   `family = c(gaussian(), gaussian())` and
#'   `family = list(gaussian(), gaussian())`.
#' @param data A data frame.
#' @param weights Optional non-negative likelihood weights. These are row
#'   log-likelihood multipliers, not known sampling variances. For
#'   meta-analytic sampling variance or covariance, use [meta_V()] in the model
#'   formula instead.
#' @param control Optional list passed to [stats::nlminb()], or a
#'   [drm_control()] object when optimizer settings and fitted-object storage
#'   choices should be supplied together.
#' @param impute Optional one-element named list of predictor models for the
#'   current missing-predictor routes. Bare formulas such as `list(x = x ~ z)`
#'   define Gaussian models for numeric missing predictors. Use
#'   [impute_model()] for explicit predictor families, such as
#'   `list(treatment = impute_model(treatment ~ z, family = binomial()))` for
#'   a binary predictor, `list(score = impute_model(score ~ z, family =
#'   cumulative_logit()))` for an ordered predictor, or
#'   `list(habitat = impute_model(habitat ~ z, family = categorical()))` for
#'   an unordered predictor, or
#'   `list(cover = impute_model(cover ~ z, family = beta()))` for a strict
#'   proportion predictor in `(0, 1)`, or
#'   `list(cover = impute_model(cover ~ z, family = zero_one_beta()))` for a
#'   boundary proportion predictor in `[0, 1]`, or
#'   `list(cover = impute_model(success ~ z, family = beta_binomial(), trials =
#'   trials))` for a denominator-aware success/trial proportion predictor, or
#'   `list(abundance = impute_model(abundance ~ z, family = poisson()))` or
#'   `list(abundance = impute_model(abundance ~ z, family = nbinom2()))` for a
#'   count predictor, including
#'   `list(abundance = impute_model(abundance ~ z, family =
#'   truncated_nbinom2()))` for a positive zero-truncated count predictor, or
#'   `list(biomass = impute_model(biomass ~ z, family = lognormal()))` for a
#'   positive continuous predictor, or
#'   `list(biomass = impute_model(biomass ~ z, family = Gamma(link = "log")))`
#'   for a Gamma positive continuous predictor, or
#'   `list(biomass = impute_model(biomass ~ z, family = tweedie()))` for a
#'   non-negative semi-continuous predictor with exact zeros. Grouped Gaussian
#'   covariate models use syntax such as
#'   `list(x = x ~ z + (1 | group))`; structured Gaussian covariate models use
#'   explicit syntax such as `list(x = x ~ z + relmat(1 | line, Q = Q))`.
#'   Most fitted routes use a univariate Gaussian formula containing one `mi(x)`
#'   location term and `missing = miss_control(predictor = "model")`. The first
#'   non-Gaussian response route also supports `family = poisson()` with one
#'   fixed-effect binary `mi()` predictor modelled by `family = binomial()`.
#' @param missing Missing-data policy created by [miss_control()]. The default
#'   keeps the existing complete-case behaviour. In the current fitted slices,
#'   `missing = miss_control(response = "include")` is implemented only for
#'   univariate Gaussian response masks and bivariate Gaussian partial-response
#'   rows without dense known covariance. `missing =
#'   miss_control(predictor = "model")` is implemented for one `mi()`
#'   missing predictor in a univariate Gaussian location model: numeric
#'   Gaussian predictors may use a
#'   fixed-effect, one random-intercept, or one intercept-only structured
#'   Gaussian `impute` formula; binary, ordered categorical, unordered
#'   categorical, strict beta/proportion, zero-one beta boundary-proportion,
#'   beta-binomial denominator-aware proportion, Poisson, negative-binomial, or
#'   zero-truncated negative-binomial count, lognormal positive continuous,
#'   Gamma positive continuous, and Tweedie semi-continuous predictors may use
#'   one fixed-effect family-aware `impute_model()`. The first Poisson-response
#'   route supports one fixed-effect binary missing predictor with a
#'   Bernoulli/logit `impute_model()`, complete count responses, and no
#'   zero-inflation, random, or structured response terms.
#' @param engine Computational engine. The default `"tmb"` uses the native
#'   `drmTMB` TMB backend. The experimental `"julia"` route calls DRM.jl
#'   through JuliaCall for the supported bridge slice.
#' @param REML Logical; use restricted maximum likelihood where the selected
#'   engine supports it. Native `engine = "tmb"` supports: univariate Gaussian
#'   mixed models with ordinary dense `mu` fixed effects, ordinary `mu` random
#'   intercepts or slopes, a mean-side phylogenetic [phylo()] effect, diagonal or
#'   dense known sampling covariance through [meta_V()], non-unit likelihood
#'   `weights` (with diagonal or no known covariance), and a fixed-effect
#'   `sigma ~ predictors` (heteroscedastic) or intercept-only `sigma`; and
#'   bivariate Gaussian *fixed-effect* location models (`mu1`/`mu2`). It does not
#'   yet support aggregation, scale-side or non-phylogenetic structured effects,
#'   direct `sd()` scale formulae, scale random effects, or bivariate random or
#'   structured means.
#'   Experimental `engine = "julia"` forwards `REML = TRUE` only for supported
#'   Gaussian bridge cells, including fixed-effect location-scale models,
#'   Gaussian `sigma`-phylo location-scale models, and the bivariate q = 4
#'   phylogenetic location-scale route. Use the default `REML = FALSE` for
#'   likelihood-ratio tests, AIC/BIC comparisons across different fixed-effect
#'   formulas, non-Gaussian models, and currently unsupported extensions.
#' @param penalty Optional penalty / prior built by [drm_phylo_penalty()], or
#'   `NULL` (default) for plain maximum likelihood. A non-`NULL` penalty
#'   switches the fit to a penalized / maximum-a-posteriori (MAP) estimator that
#'   regularises a weakly-identified phylogenetic standard deviation; the fit is
#'   labeled `MAP` and `logLik()` returns the unpenalized data log-likelihood.
#'   Native `engine = "tmb"` only.
#' @param ... Reserved for future model options.
#'
#' @return A `drmTMB` fit object.
#' @export
#'
#' @examples
#' set.seed(20260525)
#' dat <- data.frame(
#'   y = 0.2 + 0.6 * seq(-1, 1, length.out = 24) + rnorm(24, sd = 0.5),
#'   x = seq(-1, 1, length.out = 24)
#' )
#' fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat)
#' fit
drmTMB <- function(
  formula,
  family = stats::gaussian(),
  data,
  weights = NULL,
  control = list(),
  impute = NULL,
  missing = miss_control(),
  engine = c("tmb", "julia"),
  REML = FALSE,
  penalty = NULL,
  ...
) {
  if (!inherits(formula, "drm_formula")) {
    cli::cli_abort(
      "{.arg formula} must be created with {.fn drm_formula} or {.fn bf}."
    )
  }
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("{.fn drmTMB} does not use arguments in {.arg ...} yet.")
  }
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame.")
  }
  engine <- match.arg(engine)
  formula_env <- drm_formula_env(formula, parent.frame())
  if (identical(engine, "julia")) {
    if (!is.null(penalty)) {
      cli::cli_abort(
        "{.arg penalty} is not supported with {.code engine = \"julia\"} yet."
      )
    }
    return(drmTMB_julia_bridge(
      formula = formula,
      family = family,
      data = data,
      env = formula_env,
      weights_missing = base::missing(weights),
      control = control,
      impute = impute,
      missing = missing,
      REML = drm_control_flag(REML, "REML"),
      call = match.call()
    ))
  }
  control <- drm_parse_control(control)
  missing_control <- drm_parse_missing_control(missing)
  REML <- drm_control_flag(REML, "REML")
  penalty <- drm_parse_phylo_penalty(penalty)

  weights_expr <- if (base::missing(weights)) NULL else substitute(weights)
  weights_full <- evaluate_likelihood_weights_arg(
    weights_expr = weights_expr,
    data = data,
    env = parent.frame()
  )

  family_type <- drm_family_type(family)
  if (isTRUE(REML) && !family_type %in% c("gaussian", "biv_gaussian")) {
    cli::cli_abort(c(
      "{.arg REML} is implemented only for univariate and bivariate Gaussian models.",
      "i" = "Use {.code family = gaussian()} or {.code family = biv_gaussian()}, or set {.code REML = FALSE}."
    ))
  }
  if (isTRUE(REML) && drm_reml_missing_engine_engages(
    missing_control,
    formula,
    data
  )) {
    cli::cli_abort(c(
      "{.arg REML} is not implemented with explicit missing-data engines yet.",
      "x" = "The model variables contain missing values and {.arg missing} requests a non-default engine.",
      "i" = "Use the default {.code missing = miss_control()}, drop the incomplete rows, or set {.code REML = FALSE}."
    ))
  }
  if (isTRUE(REML) && !is.null(penalty)) {
    cli::cli_abort(c(
      "{.arg REML} and {.arg penalty} cannot be combined.",
      "i" = "A penalized fit is a maximum-a-posteriori (MAP) estimator and REML is a restricted-likelihood estimator; they are different estimators of the variance components.",
      "i" = "Use one of {.code REML = TRUE} or {.code penalty = drm_phylo_penalty(...)}, not both."
    ))
  }
  if (
    identical(missing_control$response, "include") &&
      !family_type %in% c("gaussian", "biv_gaussian")
  ) {
    cli::cli_abort(c(
      "{.code miss_control(response = \"include\")} is implemented only for Gaussian response models in this missing-data slice.",
      "i" = "Use the default {.code missing = miss_control(response = \"drop\")} for this family until its observed-data likelihood slice lands."
    ))
  }
  if (
    identical(missing_control$predictor, "model") &&
      !family_type %in% c("gaussian", "poisson")
  ) {
    cli::cli_abort(c(
      "{.code miss_control(predictor = \"model\")} is implemented only for univariate Gaussian models and the first Poisson-response missing-predictor slice.",
      "i" = "Use complete predictors or {.code missing = miss_control(predictor = \"fail\")} for this family."
    ))
  }
  if (!family_type %in% c("gaussian", "poisson") && !is.null(impute)) {
    cli::cli_abort(
      "{.arg impute} is currently implemented only for univariate Gaussian and first-slice Poisson {.fn mi} predictor models."
    )
  }
  if (isTRUE(control$sparse_fixed) && !identical(family_type, "gaussian")) {
    cli::cli_abort(c(
      "Sparse fixed-effect matrices are implemented only for univariate Gaussian models in this phase.",
      "i" = "Use {.code family = gaussian()} with a fixed-effect {.code mu} formula, or set {.code sparse_fixed = FALSE}."
    ))
  }
  if (
    isTRUE(control$aggregate_gaussian) &&
      !identical(family_type, "gaussian")
  ) {
    cli::cli_abort(c(
      "Gaussian aggregation is implemented only for univariate Gaussian models in this phase.",
      "i" = "Use {.code family = gaussian()} with a fixed-effect {.code mu} formula, or set {.code aggregate_gaussian = FALSE}."
    ))
  }
  if (!identical(family_type, "biv_gaussian")) {
    reject_corpair_formula_entries(formula$entries)
  }
  spec <- switch(
    family_type,
    gaussian = drm_build_gaussian_ls_spec(
      formula,
      data,
      env = formula_env,
      weights = weights_full,
      control = control,
      impute = impute,
      missing = missing_control
    ),
    student = drm_build_student_ls_spec(
      formula,
      data,
      env = formula_env,
      weights = weights_full
    ),
    skew_normal = drm_build_skew_normal_ls_spec(
      formula,
      data,
      env = formula_env,
      weights = weights_full
    ),
    lognormal = drm_build_lognormal_ls_spec(
      formula,
      data,
      env = formula_env,
      weights = weights_full
    ),
    gamma = drm_build_gamma_ls_spec(
      formula,
      data,
      env = formula_env,
      weights = weights_full
    ),
    tweedie = drm_build_tweedie_ls_spec(
      formula,
      data,
      env = formula_env,
      weights = weights_full
    ),
    beta = drm_build_beta_ls_spec(
      formula,
      data,
      env = formula_env,
      weights = weights_full
    ),
    zero_one_beta = drm_build_zero_one_beta_spec(
      formula,
      data,
      env = formula_env,
      weights = weights_full
    ),
    beta_binomial = drm_build_beta_binomial_spec(
      formula,
      data,
      env = formula_env,
      weights = weights_full
    ),
    binomial = drm_build_binomial_spec(
      formula,
      data,
      env = formula_env,
      weights = weights_full
    ),
    cumulative_logit = drm_build_cumulative_logit_spec(
      formula,
      data,
      env = formula_env,
      weights = weights_full
    ),
    poisson = drm_build_poisson_spec(
      formula,
      data,
      env = formula_env,
      weights = weights_full,
      impute = impute,
      missing = missing_control
    ),
    nbinom2 = drm_build_nbinom2_spec(
      formula,
      data,
      env = formula_env,
      weights = weights_full
    ),
    truncated_nbinom2 = drm_build_truncated_nbinom2_spec(
      formula,
      data,
      env = formula_env,
      weights = weights_full
    ),
    biv_gaussian = drm_build_biv_gaussian_spec(
      formula,
      data,
      env = formula_env,
      weights = weights_full,
      missing = missing_control
    )
  )

  drm_fit_spec(
    spec = spec,
    formula = formula,
    family = family,
    control = control,
    REML = REML,
    penalty = penalty,
    fit_call = match.call()
  )
}

drm_fit_spec <- function(
  spec,
  formula,
  family,
  control,
  REML = FALSE,
  penalty = NULL,
  fit_call = NULL
) {
  if (is.null(fit_call)) {
    fit_call <- match.call()
  }

  spec$response_names <- drm_spec_response_names(spec)
  spec <- add_covariance_probe_parameter(spec)
  spec <- drm_apply_estimator_spec(spec, REML = REML)
  spec <- drm_apply_phylo_penalty_spec(spec, penalty)
  if (is.null(control$logsigma_clamp)) {
    spec$tmb_data$use_logsigma_clamp <- 0L
    spec$tmb_data$logsigma_clamp <- c(-12, 12, 3)
  } else {
    spec$tmb_data$use_logsigma_clamp <- 1L
    spec$tmb_data$logsigma_clamp <- c(
      control$logsigma_clamp[[1L]],
      control$logsigma_clamp[[2L]],
      control$logsigma_clamp_margin
    )
  }
  # Per-group direct-SD ADREPORT is opt-in: it makes the joint ADREPORT covariance
  # n_group x n_group, which `vcov()` reads under REML. See `drm_control()`.
  spec$tmb_data$report_group_sd <- as.integer(isTRUE(control$se_group_sd))
  spec <- drm_apply_start_override(spec)

  obj <- TMB::MakeADFun(
    data = spec$tmb_data,
    parameters = spec$start,
    map = spec$map,
    random = spec$tmb_random_names,
    DLL = "drmTMB",
    silent = TRUE
  )

  optimizer <- drm_optimize_with_preset_retry(obj, control)
  opt <- optimizer$opt
  drm_warn_if_not_converged(opt)
  drm_warn_if_nonfinite_objective(opt)
  drm_pin_tmb_object_to_optimum(obj, opt)
  drm_warn_if_clamp_active(obj, spec)
  tmb_state <- drm_tmb_selected_state(obj, opt)

  uncertainty <- drm_compute_uncertainty(obj, opt, control)
  sdr <- uncertainty$sdr
  par_list <- obj$env$parList(opt$par)
  par <- split_tmb_parameters(par_list, spec)
  missing_data <- drm_finalize_missing_data(spec$missing_data, par_list, spec)

  phylo_penalty_report <- obj$report()$phylo_penalty
  phylo_penalty_value <- if (is.null(phylo_penalty_report)) {
    0
  } else {
    as.numeric(phylo_penalty_report)
  }

  fit <- list(
    call = fit_call,
    formula = formula,
    family = family,
    data = spec$data,
    model = spec,
    obj = obj,
    opt = opt,
    sdr = sdr,
    sdreport = sdr,
    uncertainty = uncertainty$state,
    tmb_state = tmb_state,
    par = par,
    coefficients = par,
    sdpars = split_tmb_sdpars(par_list, spec),
    corpars = split_tmb_corpars(par_list, spec),
    random_effects = split_tmb_random_effects(par_list, spec),
    ordinal = ordinal_fit_info(par_list, spec),
    missing_data = missing_data,
    logLik = -opt$objective + phylo_penalty_value,
    df = drm_fit_df(spec, opt),
    nobs = spec$nobs,
    estimator = spec$estimator,
    penalty = spec$penalty,
    phylo_penalty = phylo_penalty_value,
    REML = isTRUE(REML),
    optimizer_used = optimizer$selected,
    optimizer_attempts = optimizer$attempts
  )
  class(fit) <- "drmTMB"
  drm_apply_storage_control(fit, control)
}

# Build the starting points for a multi-start fit: the principled start
# (unperturbed) followed by `n_start - 1` reproducibly perturbed starts. A fixed
# seed keeps fits reproducible; the global RNG state is saved and restored so a
# multi-start fit does not perturb the caller's random stream.
drm_perturbed_starts <- function(par, n_start) {
  if (n_start <= 1L || length(par) == 0L) {
    return(list(par))
  }
  out <- vector("list", n_start)
  out[[1L]] <- par
  saved <- if (exists(".Random.seed", envir = globalenv())) {
    get(".Random.seed", envir = globalenv())
  } else {
    NULL
  }
  on.exit(
    {
      if (is.null(saved)) {
        suppressWarnings(rm(".Random.seed", envir = globalenv()))
      } else {
        assign(".Random.seed", saved, envir = globalenv())
      }
    },
    add = TRUE
  )
  set.seed(20260616L)
  for (k in 2:n_start) {
    out[[k]] <- par + stats::rnorm(length(par), mean = 0, sd = 0.5)
  }
  out
}

# Run a single optimizer preset from `n_start` starting points and return the
# result with the lowest finite objective. With n_start == 1 this is exactly the
# single-start call, so the default fit is unchanged. If every start errors, the
# last error is re-raised for the caller's tryCatch to record.
drm_optimize_multistart <- function(obj, optimizer, control_opt, n_start) {
  starts <- drm_perturbed_starts(obj$par, n_start)
  best <- NULL
  last_error <- NULL
  for (start in starts) {
    res <- tryCatch(
      optimizer(
        start = start,
        objective = obj$fn,
        gradient = obj$gr,
        control = control_opt
      ),
      error = function(e) e
    )
    if (inherits(res, "error")) {
      last_error <- res
      next
    }
    obj_value <- if (length(res$objective) == 1L && is.finite(res$objective)) {
      res$objective
    } else {
      Inf
    }
    if (is.null(best) || obj_value < best$value) {
      best <- list(opt = res, value = obj_value)
    }
  }
  if (is.null(best)) {
    stop(last_error)
  }
  best$opt
}

drm_optimize_with_preset_retry <- function(
  obj,
  control,
  optimizer = stats::nlminb,
  fallback_fn = stats::optim,
  warn = TRUE
) {
  attempt_specs <- drm_optimizer_attempt_specs(control)
  n_start <- if (is.null(control$multi_start)) 1L else control$multi_start
  rows <- vector("list", length(attempt_specs))
  opts <- vector("list", length(attempt_specs))
  last_error <- NULL

  for (i in seq_along(attempt_specs)) {
    spec <- attempt_specs[[i]]
    elapsed_start <- proc.time()[["elapsed"]]
    result <- tryCatch(
      list(
        ok = TRUE,
        value = drm_optimize_multistart(
          obj,
          optimizer,
          spec$control,
          n_start
        )
      ),
      error = function(e) list(ok = FALSE, value = e)
    )
    elapsed <- proc.time()[["elapsed"]] - elapsed_start

    if (isTRUE(result$ok)) {
      opt <- result$value
      opts[[i]] <- opt
      converged <- identical(as.integer(opt$convergence), 0L) &&
        length(opt$objective) == 1L &&
        is.finite(opt$objective)
      rows[[i]] <- drm_optimizer_attempt_row(
        attempt = i,
        preset = spec$preset,
        control = spec$control,
        status = "ok",
        convergence = opt$convergence,
        message = opt$message,
        objective = opt$objective,
        elapsed_sec = elapsed,
        selected = converged
      )
      if (converged) {
        attempts <- drm_optimizer_attempts_frame(rows[seq_len(i)])
        selected <- drm_optimizer_selected_record(attempts[i, , drop = FALSE])
        if (isTRUE(warn) && i > 1L) {
          cli::cli_warn(c(
            "{.fn drmTMB} escalated {.fn stats::nlminb} to the {.val {spec$preset}} optimizer preset to reach convergence.",
            "i" = "An earlier preset errored or did not converge; inspect {.code fit$optimizer_attempts}."
          ))
        }
        return(list(opt = opt, selected = selected, attempts = attempts))
      }
      # A non-converged result (false convergence or non-finite objective) is not
      # accepted: escalate to the next preset in the ladder, keeping this attempt
      # as a candidate in case no preset converges cleanly.
      next
    }

    last_error <- result$value
    rows[[i]] <- drm_optimizer_attempt_row(
      attempt = i,
      preset = spec$preset,
      control = spec$control,
      status = "error",
      convergence = NA_integer_,
      message = conditionMessage(last_error),
      objective = NA_real_,
      elapsed_sec = elapsed,
      selected = FALSE
    )
  }

  # C3: optional fallback optimizer (for example optim BFGS) when no nlminb
  # preset converged. A different algorithm can succeed on a numerically awkward
  # but identified problem; opt-in via drm_control(fallback_optimizer = ).
  fallback <- control$fallback_optimizer
  if (!is.null(fallback)) {
    fb_attempt <- length(attempt_specs) + 1L
    fb_control <- list(maxit = 1000L)
    fb_start <- proc.time()[["elapsed"]]
    fb_res <- tryCatch(
      fallback_fn(
        par = obj$par,
        fn = obj$fn,
        gr = obj$gr,
        method = fallback,
        control = fb_control
      ),
      error = function(e) e
    )
    fb_elapsed <- proc.time()[["elapsed"]] - fb_start
    if (inherits(fb_res, "error")) {
      last_error <- fb_res
      rows[[fb_attempt]] <- drm_optimizer_attempt_row(
        attempt = fb_attempt,
        preset = paste0("fallback:", fallback),
        control = fb_control,
        status = "error",
        convergence = NA_integer_,
        message = conditionMessage(fb_res),
        objective = NA_real_,
        elapsed_sec = fb_elapsed,
        selected = FALSE
      )
    } else {
      fb_message <- if (is.null(fb_res$message)) {
        NA_character_
      } else {
        fb_res$message
      }
      fb_opt <- list(
        par = fb_res$par,
        objective = fb_res$value,
        convergence = fb_res$convergence,
        message = fb_message
      )
      opts[[fb_attempt]] <- fb_opt
      fb_converged <- identical(as.integer(fb_opt$convergence), 0L) &&
        length(fb_opt$objective) == 1L &&
        is.finite(fb_opt$objective)
      rows[[fb_attempt]] <- drm_optimizer_attempt_row(
        attempt = fb_attempt,
        preset = paste0("fallback:", fallback),
        control = fb_control,
        status = "ok",
        convergence = fb_opt$convergence,
        message = fb_message,
        objective = fb_opt$objective,
        elapsed_sec = fb_elapsed,
        selected = fb_converged
      )
      if (fb_converged) {
        attempts <- drm_optimizer_attempts_frame(rows)
        selected <- drm_optimizer_selected_record(
          attempts[attempts$attempt == fb_attempt, , drop = FALSE]
        )
        if (isTRUE(warn)) {
          cli::cli_warn(c(
            "{.fn drmTMB} converged with the {.val {fallback}} fallback optimizer after the {.fn stats::nlminb} presets did not.",
            "i" = "Inspect {.code fit$optimizer_attempts}."
          ))
        }
        return(list(opt = fb_opt, selected = selected, attempts = attempts))
      }
    }
  }

  # No preset converged cleanly. If any attempt produced a result, return the
  # best of them (lowest finite objective) so the user gets the most-converged
  # fit; the fit-time convergence warning then flags it. Only abort if every
  # attempt errored.
  ok_idx <- which(!vapply(opts, is.null, logical(1L)))
  if (length(ok_idx) > 0L) {
    objectives <- vapply(
      ok_idx,
      function(i) {
        value <- opts[[i]]$objective
        if (length(value) == 1L && is.finite(value)) value else Inf
      },
      numeric(1L)
    )
    best_i <- ok_idx[[which.min(objectives)]]
    for (j in seq_along(rows)) {
      if (!is.null(rows[[j]])) {
        rows[[j]]$selected <- j == best_i
      }
    }
    attempts <- drm_optimizer_attempts_frame(rows)
    selected_row <- attempts[attempts$attempt == best_i, , drop = FALSE]
    selected <- drm_optimizer_selected_record(selected_row)
    return(list(opt = opts[[best_i]], selected = selected, attempts = attempts))
  }

  attempts <- drm_optimizer_attempts_frame(rows)
  if (nrow(attempts) == 1L) {
    stop(last_error)
  }
  cli::cli_abort(
    c(
      "{.fn drmTMB} failed in all {.fn stats::nlminb} optimizer preset attempts.",
      "i" = "Attempted presets: {.val {attempts$optimizer_preset}}.",
      "i" = "Inspect model structure, starting values, and data scale before increasing optimizer complexity."
    ),
    parent = last_error
  )
}

drm_optimizer_attempt_specs <- function(control) {
  current <- control$optimizer_preset
  ladder <- c("default", "careful", "robust")
  current_index <- match(current, ladder)
  custom_optimizer <- length(control$optimizer) > 0L &&
    !identical(control$optimizer, drm_control_optimizer(list(), current))
  if (is.na(current_index) || isTRUE(custom_optimizer)) {
    return(list(list(preset = current, control = control$optimizer)))
  }
  lapply(ladder[current_index:length(ladder)], function(preset) {
    list(
      preset = preset,
      control = drm_control_optimizer(list(), preset)
    )
  })
}

drm_optimizer_attempt_row <- function(
  attempt,
  preset,
  control,
  status,
  convergence,
  message,
  objective,
  elapsed_sec,
  selected
) {
  data.frame(
    attempt = as.integer(attempt),
    optimizer = "nlminb",
    optimizer_preset = as.character(preset),
    status = as.character(status),
    convergence = as.integer(convergence),
    message = as.character(if (is.null(message)) NA_character_ else message),
    objective = as.numeric(objective),
    elapsed_sec = as.numeric(elapsed_sec),
    selected = as.logical(selected),
    stringsAsFactors = FALSE
  ) |>
    cbind(control = I(list(control)))
}

drm_optimizer_attempts_frame <- function(rows) {
  rows <- Filter(Negate(is.null), rows)
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

drm_optimizer_selected_record <- function(row) {
  list(
    optimizer = row$optimizer[[1L]],
    optimizer_preset = row$optimizer_preset[[1L]],
    attempt = row$attempt[[1L]],
    retried = row$attempt[[1L]] > 1L,
    convergence = row$convergence[[1L]],
    message = row$message[[1L]],
    objective = row$objective[[1L]],
    control = row$control[[1L]]
  )
}

drm_apply_estimator_spec <- function(spec, REML = FALSE) {
  if (!isTRUE(REML)) {
    spec$estimator <- "ML"
    spec$tmb_random_names <- spec$random_names
    return(spec)
  }

  drm_validate_reml_spec(spec)
  spec$estimator <- "REML"
  mean_fixed <- if (identical(spec$model_type, "biv_gaussian")) {
    c("beta_mu1", "beta_mu2")
  } else {
    "beta_mu"
  }
  # Scale-side REML (first slice, intercept-validated): when a sigma variance
  # component is present, also marginalize the sigma fixed effect(s) so TMB's
  # Laplace step restricts the likelihood for the scale coefficients too. This
  # is the Cox-Reid / adjusted-profile REML that debiases the downward-biased
  # sigma random-effect SD at small group counts (Noether math review,
  # 2026-07-06: the log-link Jacobian is captured by AD, so no analytic term is
  # missing). Gated on a sigma effect so mean-only REML is byte-identical.
  sigma_n_re <- spec$random$sigma$n_re
  has_sigma_re <- !is.null(sigma_n_re) && sigma_n_re > 0L
  if (!has_sigma_re && isTRUE(spec$structured$phylo_mu$has)) {
    eps <- tryCatch(
      phylo_mu_endpoint_dpars(spec$structured$phylo_mu),
      error = function(e) character()
    )
    has_sigma_re <- any(sub("[0-9]+$", "", eps) == "sigma")
  }
  scale_fixed <- if (has_sigma_re) {
    if (identical(spec$model_type, "biv_gaussian")) {
      c("beta_sigma1", "beta_sigma2")
    } else {
      "beta_sigma"
    }
  } else {
    character()
  }
  spec$tmb_random_names <- c(spec$random_names, mean_fixed, scale_fixed)
  spec
}

drm_start_override_empty_record <- function() {
  data.frame(
    parameter = character(),
    n_value = integer(),
    n_applied = integer(),
    n_mapped = integer(),
    stringsAsFactors = FALSE
  )
}

drm_apply_start_override <- function(spec) {
  override <- spec[["start_override"]]
  if (is.null(override)) {
    spec$start_override <- NULL
    spec$start_override_applied <- drm_start_override_empty_record()
    return(spec)
  }

  drm_validate_start_override(spec, override)

  applied <- vector("list", length(override))
  override_names <- names(override)
  for (i in seq_along(override)) {
    parameter <- override_names[[i]]
    target <- spec$start[[parameter]]
    value <- override[[i]]
    value <- drm_align_start_override_value(
      value = value,
      target = target,
      parameter = parameter
    )

    map <- if (is.null(spec$map)) {
      NULL
    } else {
      spec$map[[parameter]]
    }
    mapped <- drm_start_override_mapped_slots(
      map = map,
      n = length(target),
      parameter = parameter
    )
    candidate <- target
    candidate[!mapped] <- value[!mapped]
    spec$start[[parameter]] <- candidate

    applied[[i]] <- data.frame(
      parameter = parameter,
      n_value = length(value),
      n_applied = sum(!mapped),
      n_mapped = sum(mapped),
      stringsAsFactors = FALSE
    )
  }

  spec$start_override_applied <- do.call(rbind, applied)
  rownames(spec$start_override_applied) <- NULL
  spec
}

drm_validate_start_override <- function(spec, override) {
  if (!is.list(override) || is.data.frame(override)) {
    cli::cli_abort(
      "Internal start overrides must be a named list."
    )
  }

  override_names <- names(override)
  if (
    is.null(override_names) ||
      length(override_names) != length(override) ||
      anyNA(override_names) ||
      any(override_names == "")
  ) {
    cli::cli_abort(
      "Internal start overrides must name every TMB start component."
    )
  }
  duplicated_names <- unique(override_names[duplicated(override_names)])
  if (length(duplicated_names) > 0L) {
    cli::cli_abort(c(
      "Internal start overrides must not duplicate component names.",
      "x" = "Duplicated component{?s}: {.val {duplicated_names}}."
    ))
  }

  unknown <- setdiff(override_names, names(spec$start))
  if (length(unknown) > 0L) {
    cli::cli_abort(c(
      "Internal start overrides can only target existing TMB start components.",
      "x" = "Unknown component{?s}: {.val {unknown}}."
    ))
  }

  for (parameter in override_names) {
    value <- override[[parameter]]
    target <- spec$start[[parameter]]
    if (!is.atomic(value) || !is.numeric(value) || !is.null(dim(value))) {
      cli::cli_abort(c(
        "Internal start override values must be numeric vectors.",
        "x" = "Component {.val {parameter}} is not a numeric vector."
      ))
    }
    if (length(value) != length(target)) {
      cli::cli_abort(c(
        "Internal start override values must match existing start lengths.",
        "x" = "Component {.val {parameter}} has length {length(value)}; expected {length(target)}."
      ))
    }
    if (!all(is.finite(value))) {
      cli::cli_abort(c(
        "Internal start override values must be finite.",
        "x" = "Component {.val {parameter}} contains non-finite values."
      ))
    }
  }

  invisible(TRUE)
}

drm_align_start_override_value <- function(value, target, parameter) {
  target_names <- names(target)
  value_names <- names(value)
  if (!is.null(target_names) && !is.null(value_names)) {
    if (
      anyNA(value_names) ||
        any(value_names == "") ||
        ((any(duplicated(target_names)) || any(duplicated(value_names))) &&
          !identical(value_names, target_names)) ||
        (!any(duplicated(target_names)) &&
          !any(duplicated(value_names)) &&
          !identical(sort(value_names), sort(target_names)))
    ) {
      cli::cli_abort(c(
        "Named internal start overrides must match existing parameter names.",
        "x" = "Component {.val {parameter}} has names that do not match its target."
      ))
    }
    if (!any(duplicated(target_names)) && !any(duplicated(value_names))) {
      value <- value[target_names]
    }
  }
  if (!is.null(target_names)) {
    names(value) <- target_names
  }
  value
}

drm_start_override_mapped_slots <- function(map, n, parameter) {
  if (is.null(map)) {
    return(rep(FALSE, n))
  }
  if (length(map) == 1L && is.na(map[[1L]])) {
    return(rep(TRUE, n))
  }
  if (length(map) != n) {
    cli::cli_abort(c(
      "Internal start override map length does not match the start vector.",
      "x" = "Component {.val {parameter}} has map length {length(map)}; expected {n}."
    ))
  }
  is.na(map)
}

drm_qgt2_staged_start_override <- function(
  source_fit,
  target_spec,
  copy_theta_re_cov = FALSE,
  theta_re_cov_shrink = 0.85,
  strategy = "qgt2-staged-start"
) {
  if (isTRUE(copy_theta_re_cov)) {
    theta_re_cov_shrink <- drm_qgt2_validate_theta_shrink(
      theta_re_cov_shrink
    )
  }
  if (!is.list(source_fit) || !is.list(source_fit$model)) {
    cli::cli_abort(
      "Internal q>2 staged starts require a fitted source {.cls drmTMB} object."
    )
  }
  if (!is.list(target_spec) || !is.list(target_spec$start)) {
    cli::cli_abort(
      "Internal q>2 staged starts require a target model specification."
    )
  }

  fixed <- drm_qgt2_fixed_effect_start_override(source_fit, target_spec)
  sd <- drm_qgt2_log_sd_start_override(source_fit, target_spec)
  theta <- if (isTRUE(copy_theta_re_cov)) {
    drm_qgt2_theta_start_override(
      source_fit,
      target_spec,
      shrink = theta_re_cov_shrink
    )
  } else {
    list(
      override = list(),
      matches = drm_empty_qgt2_theta_match_table(),
      status = "not_requested"
    )
  }
  override <- c(fixed$override, sd$override, theta$override)
  override <- override[lengths(override) > 0L]

  list(
    override = override,
    provenance = list(
      strategy = strategy,
      source_model_type = drm_start_override_scalar(
        source_fit$model$model_type,
        NA_character_
      ),
      target_model_type = drm_start_override_scalar(
        target_spec$model_type,
        NA_character_
      ),
      fixed_effect_matches = fixed$matches,
      qgt2_sd_matches = sd$matches,
      qgt2_theta_matches = theta$matches,
      theta_re_cov = theta$status,
      theta_re_cov_shrink = if (isTRUE(copy_theta_re_cov)) {
        theta_re_cov_shrink
      } else {
        NA_real_
      }
    )
  )
}

drm_qgt2_staged_fit_diagnostic <- function(
  source_fit,
  target_spec,
  formula,
  family,
  control,
  REML = FALSE,
  penalty = NULL,
  copy_theta_re_cov = FALSE,
  theta_re_cov_shrink = 0.85,
  fit_spec = drm_fit_spec
) {
  if (!is.function(fit_spec)) {
    cli::cli_abort(
      "Internal q>2 staged fit diagnostics require a fit-spec function."
    )
  }

  mapped <- drm_qgt2_staged_start_override(
    source_fit = source_fit,
    target_spec = target_spec,
    copy_theta_re_cov = copy_theta_re_cov,
    theta_re_cov_shrink = theta_re_cov_shrink
  )

  cold <- drm_qgt2_capture_staged_fit(
    label = "cold",
    spec = target_spec,
    formula = formula,
    family = family,
    control = control,
    REML = REML,
    penalty = penalty,
    fit_spec = fit_spec
  )

  staged_spec <- target_spec
  staged_spec$start_override <- mapped$override
  staged <- drm_qgt2_capture_staged_fit(
    label = "staged",
    spec = staged_spec,
    formula = formula,
    family = family,
    control = control,
    REML = REML,
    penalty = penalty,
    fit_spec = fit_spec
  )

  list(
    strategy = "qgt2-staged-fit-diagnostic",
    provenance = mapped$provenance,
    fits = list(cold = cold, staged = staged),
    comparison = drm_qgt2_staged_fit_comparison(cold, staged)
  )
}

drm_qgt2_capture_staged_fit <- function(
  label,
  spec,
  formula,
  family,
  control,
  REML,
  penalty,
  fit_spec
) {
  captured_warnings <- character()
  elapsed_start <- proc.time()[["elapsed"]]
  fit <- tryCatch(
    withCallingHandlers(
      fit_spec(
        spec = spec,
        formula = formula,
        family = family,
        control = control,
        REML = REML,
        penalty = penalty,
        fit_call = substitute(
          drm_qgt2_staged_fit_diagnostic(label = value),
          list(value = label)
        )
      ),
      warning = function(w) {
        captured_warnings <<- c(captured_warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) e
  )
  elapsed <- proc.time()[["elapsed"]] - elapsed_start

  if (inherits(fit, "error")) {
    return(list(
      label = label,
      ok = FALSE,
      fit = NULL,
      metrics = drm_qgt2_staged_fit_metrics(
        fit = NULL,
        label = label,
        ok = FALSE,
        elapsed = elapsed,
        warnings = captured_warnings,
        error = conditionMessage(fit)
      )
    ))
  }

  list(
    label = label,
    ok = TRUE,
    fit = fit,
    metrics = drm_qgt2_staged_fit_metrics(
      fit = fit,
      label = label,
      ok = TRUE,
      elapsed = elapsed,
      warnings = captured_warnings,
      error = NA_character_
    )
  )
}

drm_qgt2_staged_fit_metrics <- function(
  fit,
  label,
  ok,
  elapsed,
  warnings,
  error
) {
  convergence <- NA_integer_
  pdHess <- NA
  objective <- NA_real_
  logLik <- NA_real_
  df <- NA_real_
  nobs <- NA_real_
  optimizer_preset <- NA_character_
  optimizer_attempt_count <- NA_integer_
  optimizer_selected_attempt <- NA_character_
  optimizer_retried <- NA
  optimizer_attempt_presets <- NA_character_
  optimizer_attempt_statuses <- NA_character_
  optimizer_message <- NA_character_
  iterations <- NA_real_
  function_evaluations <- NA_real_
  gradient_evaluations <- NA_real_
  iter_max <- NA_real_
  eval_max <- NA_real_
  budget_status <- NA_character_
  sdreport_status <- NA_character_
  sdreport_message <- NA_character_
  se_requested <- NA
  fixed_gradient_status <- NA_character_
  max_abs_gradient <- NA_real_
  max_gradient_component <- NA_character_
  gradient_tolerance <- 1e-4
  failure_mode <- NA_character_
  failure_detail <- NA_character_

  if (!isTRUE(ok)) {
    failure_mode <- "fit_error"
    failure_detail <- error
    budget_status <- "not_evaluated"
    sdreport_status <- "not_available"
    fixed_gradient_status <- "not_available"
  }

  if (isTRUE(ok)) {
    convergence <- as.integer(fit$opt$convergence)
    if (!is.null(fit$sdr) && !is.null(fit$sdr$pdHess)) {
      pdHess <- isTRUE(fit$sdr$pdHess)
    }
    objective <- as.numeric(fit$opt$objective)
    logLik <- tryCatch(
      as.numeric(stats::logLik(fit)),
      error = function(e) NA_real_
    )
    df <- as.numeric(fit$df)
    nobs <- as.numeric(fit$nobs)
    if (!is.null(fit$optimizer_used$optimizer_preset)) {
      optimizer_preset <- as.character(fit$optimizer_used$optimizer_preset)
    }
    attempts <- drm_qgt2_optimizer_attempts(fit)
    optimizer_attempt_count <- attempts$count
    optimizer_selected_attempt <- attempts$selected
    optimizer_retried <- isTRUE(attempts$count > 1L)
    optimizer_attempt_presets <- attempts$presets
    optimizer_attempt_statuses <- attempts$statuses
    optimizer_message <- drm_qgt2_scalar_character(fit$opt$message)
    iterations <- drm_qgt2_scalar_numeric(fit$opt$iterations)
    function_evaluations <- drm_qgt2_named_numeric(
      fit$opt$evaluations,
      "function"
    )
    if (is.na(function_evaluations)) {
      function_evaluations <- drm_qgt2_named_numeric(fit$opt$counts, "function")
    }
    gradient_evaluations <- drm_qgt2_named_numeric(
      fit$opt$evaluations,
      "gradient"
    )
    if (is.na(gradient_evaluations)) {
      gradient_evaluations <- drm_qgt2_named_numeric(fit$opt$counts, "gradient")
    }
    iter_max <- drm_qgt2_named_numeric(fit$control$optimizer, "iter.max")
    eval_max <- drm_qgt2_named_numeric(fit$control$optimizer, "eval.max")
    se_requested <- if (!is.null(fit$control$se)) {
      isTRUE(fit$control$se)
    } else {
      NA
    }
    sdreport_message <- drm_qgt2_scalar_character(fit$sdr$message)
    sdreport_status <- if (is.null(fit$sdr)) {
      "not_available"
    } else if (isTRUE(pdHess)) {
      "positive_hessian"
    } else {
      "nonpositive_hessian"
    }
    gradient <- tryCatch(
      fit$obj$gr(fit$opt$par),
      error = function(e) NA_real_
    )
    if (is.numeric(gradient) && any(is.finite(gradient))) {
      max_abs_gradient <- max(abs(gradient), na.rm = TRUE)
      max_index <- which.max(abs(gradient))
      gradient_names <- names(gradient)
      max_gradient_component <- if (
        !is.null(gradient_names) &&
          length(gradient_names) >= max_index &&
          !is.na(gradient_names[[max_index]]) &&
          nzchar(gradient_names[[max_index]])
      ) {
        gradient_names[[max_index]]
      } else {
        NA_character_
      }
      if (is.na(max_gradient_component)) {
        max_gradient_component <- as.character(max_index)
      }
      fixed_gradient_status <- if (max_abs_gradient <= gradient_tolerance) {
        "ok"
      } else {
        "warning"
      }
    } else {
      fixed_gradient_status <- "not_available"
    }
    budget_status <- drm_qgt2_budget_status(
      convergence = convergence,
      iterations = iterations,
      function_evaluations = function_evaluations,
      iter_max = iter_max,
      eval_max = eval_max
    )
    failure <- drm_qgt2_failure_status(
      convergence = convergence,
      pdHess = pdHess,
      fixed_gradient_status = fixed_gradient_status,
      warning_count = length(warnings),
      error = error
    )
    failure_mode <- failure$mode
    failure_detail <- failure$detail
  }

  data.frame(
    label = label,
    ok = isTRUE(ok),
    convergence = convergence,
    pdHess = pdHess,
    objective = objective,
    logLik = logLik,
    df = df,
    nobs = nobs,
    elapsed_sec = as.numeric(elapsed),
    optimizer_preset = optimizer_preset,
    optimizer_attempt_count = optimizer_attempt_count,
    optimizer_selected_attempt = optimizer_selected_attempt,
    optimizer_retried = optimizer_retried,
    optimizer_attempt_presets = optimizer_attempt_presets,
    optimizer_attempt_statuses = optimizer_attempt_statuses,
    optimizer_message = optimizer_message,
    iterations = iterations,
    function_evaluations = function_evaluations,
    gradient_evaluations = gradient_evaluations,
    iter_max = iter_max,
    eval_max = eval_max,
    budget_status = budget_status,
    sdreport_status = sdreport_status,
    sdreport_message = sdreport_message,
    se_requested = se_requested,
    fixed_gradient_status = fixed_gradient_status,
    max_abs_gradient = max_abs_gradient,
    max_gradient_component = max_gradient_component,
    gradient_tolerance = gradient_tolerance,
    failure_mode = failure_mode,
    failure_detail = failure_detail,
    warning_count = length(warnings),
    warnings = paste(warnings, collapse = " | "),
    error = error,
    stringsAsFactors = FALSE
  )
}

drm_qgt2_optimizer_attempts <- function(fit) {
  attempts <- fit$optimizer_attempts
  if (is.data.frame(attempts) && nrow(attempts) > 0L) {
    presets <- if ("optimizer_preset" %in% names(attempts)) {
      paste(attempts$optimizer_preset, collapse = " | ")
    } else {
      NA_character_
    }
    statuses <- if ("status" %in% names(attempts)) {
      paste(attempts$status, collapse = " | ")
    } else if ("convergence" %in% names(attempts)) {
      paste0("convergence=", paste(attempts$convergence, collapse = " | "))
    } else {
      NA_character_
    }
    return(list(
      count = nrow(attempts),
      selected = if ("optimizer_preset" %in% names(attempts)) {
        as.character(utils::tail(attempts$optimizer_preset, 1L))
      } else {
        NA_character_
      },
      presets = presets,
      statuses = statuses
    ))
  }
  list(
    count = 1L,
    selected = drm_qgt2_scalar_character(fit$optimizer_used$optimizer_preset),
    presets = drm_qgt2_scalar_character(fit$optimizer_used$optimizer_preset),
    statuses = NA_character_
  )
}

drm_qgt2_scalar_character <- function(x) {
  if (is.null(x) || length(x) == 0L || is.na(x[[1L]])) {
    return(NA_character_)
  }
  as.character(x[[1L]])
}

drm_qgt2_scalar_numeric <- function(x) {
  if (is.null(x) || length(x) == 0L || is.na(x[[1L]])) {
    return(NA_real_)
  }
  as.numeric(x[[1L]])
}

drm_qgt2_named_numeric <- function(x, name) {
  if (is.null(x) || !name %in% names(x)) {
    return(NA_real_)
  }
  as.numeric(x[[name]])
}

drm_qgt2_budget_status <- function(
  convergence,
  iterations,
  function_evaluations,
  iter_max,
  eval_max
) {
  if (identical(convergence, 0L)) {
    return("converged")
  }
  if (
    is.finite(iterations) &&
      is.finite(iter_max) &&
      iterations >= iter_max
  ) {
    return("iteration_budget_reached")
  }
  if (
    is.finite(function_evaluations) &&
      is.finite(eval_max) &&
      function_evaluations >= eval_max
  ) {
    return("evaluation_budget_reached")
  }
  "nonconverged_before_budget_or_unknown"
}

drm_qgt2_failure_status <- function(
  convergence,
  pdHess,
  fixed_gradient_status,
  warning_count,
  error
) {
  if (!is.na(error)) {
    return(list(mode = "fit_error", detail = error))
  }
  if (!identical(convergence, 0L)) {
    return(list(
      mode = "optimizer_nonconvergence",
      detail = paste0("convergence=", convergence)
    ))
  }
  if (!isTRUE(pdHess)) {
    return(list(mode = "nonpositive_hessian", detail = "pdHess is not TRUE"))
  }
  if (identical(fixed_gradient_status, "warning")) {
    return(list(
      mode = "fixed_gradient_warning",
      detail = fixed_gradient_status
    ))
  }
  if (warning_count > 0L) {
    return(list(
      mode = "warning",
      detail = paste0("warning_count=", warning_count)
    ))
  }
  list(mode = "none", detail = NA_character_)
}

drm_qgt2_staged_fit_comparison <- function(cold, staged) {
  metrics <- rbind(cold$metrics, staged$metrics)
  numeric_metrics <- c("objective", "logLik", "elapsed_sec")
  deltas <- lapply(numeric_metrics, function(metric) {
    cold_value <- cold$metrics[[metric]]
    staged_value <- staged$metrics[[metric]]
    data.frame(
      metric = metric,
      cold = cold_value,
      staged = staged_value,
      staged_minus_cold = staged_value - cold_value,
      stringsAsFactors = FALSE
    )
  })
  list(
    metrics = metrics,
    deltas = do.call(rbind, deltas)
  )
}

drm_qgt2_fixed_effect_start_override <- function(source_fit, target_spec) {
  dpar_parameter <- c(
    mu1 = "beta_mu1",
    mu2 = "beta_mu2",
    sigma1 = "beta_sigma1",
    sigma2 = "beta_sigma2",
    rho12 = "beta_rho12"
  )
  override <- list()
  match_rows <- list()
  for (dpar in names(dpar_parameter)) {
    parameter <- dpar_parameter[[dpar]]
    current <- target_spec$start[[parameter]]
    source <- source_fit$coefficients[[dpar]]
    if (is.null(current) || is.null(source)) {
      next
    }
    target_names <- names(current)
    if (is.null(target_names)) {
      target_names <- colnames(target_spec$X[[dpar]])
    }
    if (is.null(target_names)) {
      next
    }
    source_names <- names(source)
    if (is.null(source_names)) {
      source_names <- target_names[seq_len(min(
        length(target_names),
        length(source)
      ))]
      names(source) <- source_names
    }
    common <- intersect(target_names, source_names)
    proposed <- current
    if (length(common) > 0L) {
      proposed[match(common, target_names)] <- source[common]
    }
    names(proposed) <- names(current)
    override[[parameter]] <- proposed
    match_rows[[length(match_rows) + 1L]] <- data.frame(
      dpar = dpar,
      parameter = parameter,
      n_target = length(current),
      n_source = length(source),
      n_matched = length(common),
      matched = paste(common, collapse = ","),
      stringsAsFactors = FALSE
    )
  }
  list(
    override = override,
    matches = drm_rbind_or_empty(
      match_rows,
      c("dpar", "parameter", "n_target", "n_source", "n_matched", "matched")
    )
  )
}

drm_qgt2_log_sd_start_override <- function(source_fit, target_spec) {
  target_registry <- target_spec$random$covariance_blocks
  target_members <- qgt2_covariance_members(target_registry)
  if (nrow(target_members) == 0L || is.null(target_spec$start$log_sd_re_cov)) {
    return(list(
      override = list(),
      matches = drm_empty_qgt2_sd_match_table()
    ))
  }

  source_sd <- drm_qgt2_source_log_sd_by_key(source_fit)
  target_keys <- drm_qgt2_member_start_keys(target_members)
  proposed <- target_spec$start$log_sd_re_cov
  common <- intersect(target_keys, names(source_sd))
  if (length(common) > 0L) {
    proposed[match(common, target_keys)] <- source_sd[common]
  }
  names(proposed) <- names(target_spec$start$log_sd_re_cov)

  matches <- data.frame(
    key = target_keys,
    dpar = target_members$dpar,
    coef = target_members$coef,
    source_matched = target_keys %in% names(source_sd),
    stringsAsFactors = FALSE
  )
  list(
    override = list(log_sd_re_cov = proposed),
    matches = matches
  )
}

drm_qgt2_source_log_sd_by_key <- function(source_fit) {
  registry <- source_fit$model$random$covariance_blocks
  members <- qgt2_covariance_members(registry)
  if (nrow(members) == 0L) {
    return(stats::setNames(numeric(), character()))
  }
  keys <- drm_qgt2_member_start_keys(members)
  out <- rep(NA_real_, length(keys))
  for (i in seq_len(nrow(members))) {
    sd_value <- covariance_registry_member_sd(
      source_fit,
      members[i, , drop = FALSE]
    )
    if (is.finite(sd_value) && sd_value > 0) {
      out[[i]] <- log(sd_value)
    }
  }
  ok <- is.finite(out)
  stats::setNames(out[ok], keys[ok])
}

drm_qgt2_theta_start_override <- function(
  source_fit,
  target_spec,
  shrink = 0.85
) {
  shrink <- drm_qgt2_validate_theta_shrink(shrink)
  target_registry <- target_spec$random$covariance_blocks
  target_blocks <- qgt2_covariance_blocks(target_registry)
  if (
    nrow(target_blocks) == 0L ||
      is.null(target_spec$start$theta_re_cov) ||
      length(target_spec$start$theta_re_cov) == 0L
  ) {
    return(list(
      override = list(),
      matches = drm_empty_qgt2_theta_match_table(),
      status = "no_target_theta_re_cov"
    ))
  }

  source_cor <- drm_qgt2_source_cor_by_pair(source_fit)
  if (length(source_cor) == 0L) {
    return(list(
      override = list(),
      matches = drm_empty_qgt2_theta_match_table(),
      status = "no_source_correlations"
    ))
  }

  proposed <- target_spec$start$theta_re_cov
  target_pairs <- qgt2_covariance_pairs(target_registry)
  target_members <- qgt2_covariance_members(target_registry)
  match_rows <- list()
  theta_offset <- 0L
  for (block_i in seq_len(nrow(target_blocks))) {
    block <- target_blocks[block_i, , drop = FALSE]
    q <- block$n_members[[1L]]
    n_theta <- choose(q, 2L)
    block_members <- target_members[
      target_members$block_id0 == block$block_id0[[1L]],
      ,
      drop = FALSE
    ]
    block_pairs <- target_pairs[
      target_pairs$block_id0 == block$block_id0[[1L]],
      ,
      drop = FALSE
    ]
    block_corr <- diag(q)
    copied <- block_pairs$parameter %in% names(source_cor)
    if (any(copied)) {
      copied_values <- shrink * source_cor[block_pairs$parameter[copied]]
      copied_values <- drm_qgt2_guard_theta_correlations(copied_values)
      for (j in which(copied)) {
        from <- block_pairs$from_member_id0[[j]] + 1L
        to <- block_pairs$to_member_id0[[j]] + 1L
        block_corr[from, to] <- copied_values[[block_pairs$parameter[[j]]]]
        block_corr[to, from] <- block_corr[from, to]
      }
      regularized <- drm_qgt2_regularize_correlation_start(block_corr)
      theta <- correlation_matrix_to_tmb_unstructured_theta(
        regularized$corr
      )
      proposed[seq.int(theta_offset + 1L, length.out = n_theta)] <- theta
      reconstructed <- tmb_unstructured_corr_matrix(theta)
    } else {
      regularized <- list(corr = block_corr, shrink_factor = 1, min_eigen = 1)
      reconstructed <- block_corr
    }

    block_rows <- lapply(seq_len(nrow(block_pairs)), function(j) {
      from <- block_pairs$from_member_id0[[j]] + 1L
      to <- block_pairs$to_member_id0[[j]] + 1L
      parameter <- block_pairs$parameter[[j]]
      data.frame(
        parameter = parameter,
        from_key = drm_qgt2_member_start_keys(block_members[
          from,
          ,
          drop = FALSE
        ]),
        to_key = drm_qgt2_member_start_keys(block_members[to, , drop = FALSE]),
        source_matched = copied[[j]],
        source_correlation = if (copied[[j]]) {
          source_cor[[parameter]]
        } else {
          NA_real_
        },
        copied_correlation = block_corr[from, to],
        reconstructed_correlation = reconstructed[from, to],
        block_shrink_factor = regularized$shrink_factor,
        block_min_eigen = regularized$min_eigen,
        stringsAsFactors = FALSE
      )
    })
    match_rows <- c(match_rows, block_rows)
    theta_offset <- theta_offset + n_theta
  }

  names(proposed) <- names(target_spec$start$theta_re_cov)
  matches <- drm_rbind_or_empty(
    match_rows,
    c(
      "parameter",
      "from_key",
      "to_key",
      "source_matched",
      "source_correlation",
      "copied_correlation",
      "reconstructed_correlation",
      "block_shrink_factor",
      "block_min_eigen"
    )
  )
  if (!any(matches$source_matched)) {
    return(list(
      override = list(),
      matches = matches,
      status = "no_matching_pair_keys"
    ))
  }
  list(
    override = list(theta_re_cov = proposed),
    matches = matches,
    status = "copied_by_pair_key"
  )
}

drm_qgt2_source_cor_by_pair <- function(source_fit) {
  if (!is.list(source_fit$corpars)) {
    return(stats::setNames(numeric(), character()))
  }
  source_cor <- source_fit$corpars$re_cov
  if (is.null(source_cor) || length(source_cor) == 0L) {
    return(stats::setNames(numeric(), character()))
  }
  if (is.null(names(source_cor))) {
    source_pairs <- qgt2_covariance_pairs(
      source_fit$model$random$covariance_blocks
    )
    names(source_cor) <- source_pairs$parameter[seq_along(source_cor)]
  }
  ok <- is.finite(source_cor) &
    !is.na(names(source_cor)) &
    nzchar(names(source_cor))
  source_cor[ok]
}

drm_qgt2_validate_theta_shrink <- function(shrink) {
  if (
    !is.numeric(shrink) ||
      length(shrink) != 1L ||
      !is.finite(shrink) ||
      shrink <= 0 ||
      shrink > 1
  ) {
    cli::cli_abort(
      "{.arg theta_re_cov_shrink} must be one finite number in (0, 1]."
    )
  }
  shrink
}

drm_qgt2_guard_theta_correlations <- function(x, guard = 0.98) {
  pmax(pmin(x, guard), -guard)
}

drm_qgt2_regularize_correlation_start <- function(
  corr,
  min_eigen = 1e-6,
  shrink_step = 0.75,
  max_iter = 12L
) {
  offdiag <- corr
  diag(offdiag) <- 0
  for (i in seq_len(max_iter + 1L)) {
    factor <- shrink_step^(i - 1L)
    candidate <- diag(nrow(corr)) + factor * offdiag
    eigenvalues <- tryCatch(
      eigen(candidate, symmetric = TRUE, only.values = TRUE)$values,
      error = function(e) NA_real_
    )
    min_value <- min(eigenvalues)
    if (is.finite(min_value) && min_value > min_eigen) {
      return(list(
        corr = candidate,
        shrink_factor = factor,
        min_eigen = min_value
      ))
    }
  }
  list(
    corr = diag(nrow(corr)),
    shrink_factor = 0,
    min_eigen = 1
  )
}

correlation_matrix_to_tmb_unstructured_theta <- function(corr) {
  if (
    !is.matrix(corr) ||
      nrow(corr) != ncol(corr) ||
      any(!is.finite(corr))
  ) {
    cli::cli_abort(
      "Internal error: correlation-to-theta conversion requires a finite square matrix."
    )
  }
  if (!isTRUE(all.equal(diag(corr), rep(1, nrow(corr))))) {
    cli::cli_abort(
      "Internal error: correlation-to-theta conversion requires unit diagonal."
    )
  }
  lower_chol <- tryCatch(
    t(chol(corr)),
    error = function(e) e
  )
  if (inherits(lower_chol, "error")) {
    cli::cli_abort(
      "Internal error: correlation-to-theta conversion requires a positive-definite matrix."
    )
  }
  diagonal <- diag(lower_chol)
  if (any(!is.finite(diagonal)) || any(diagonal <= 0)) {
    cli::cli_abort(
      "Internal error: correlation-to-theta Cholesky factor has invalid diagonal."
    )
  }
  lower_unit <- sweep(lower_chol, 1L, diagonal, "/")
  lower <- which(lower.tri(lower_unit), arr.ind = TRUE)
  lower <- lower[order(lower[, "row"], lower[, "col"]), , drop = FALSE]
  theta <- lower_unit[lower]
  reconstructed <- tmb_unstructured_corr_matrix(theta)
  if (max(abs(reconstructed - corr)) > 1e-8) {
    cli::cli_abort(
      "Internal error: packed theta did not reconstruct the requested correlation matrix."
    )
  }
  theta
}

drm_qgt2_member_start_keys <- function(members) {
  if (!is.data.frame(members) || nrow(members) == 0L) {
    return(character())
  }
  paste0(
    "group=",
    members$group,
    ";block=",
    members$block_label,
    ";dpar=",
    members$dpar,
    ";coef=",
    members$coef
  )
}

drm_empty_qgt2_sd_match_table <- function() {
  data.frame(
    key = character(),
    dpar = character(),
    coef = character(),
    source_matched = logical(),
    stringsAsFactors = FALSE
  )
}

drm_empty_qgt2_theta_match_table <- function() {
  data.frame(
    parameter = character(),
    from_key = character(),
    to_key = character(),
    source_matched = logical(),
    source_correlation = numeric(),
    copied_correlation = numeric(),
    reconstructed_correlation = numeric(),
    block_shrink_factor = numeric(),
    block_min_eigen = numeric(),
    stringsAsFactors = FALSE
  )
}

drm_rbind_or_empty <- function(rows, columns) {
  if (length(rows) == 0L) {
    return(stats::setNames(
      data.frame(matrix(ncol = length(columns), nrow = 0L)),
      columns
    ))
  }
  do.call(rbind, rows)
}

drm_start_override_scalar <- function(x, default) {
  if (length(x) == 1L && !is.null(x)) {
    return(x)
  }
  default
}

# Does the requested missing-data engine actually ENGAGE on this data?
#
# `miss_control(response = "include")` and `miss_control(predictor = "model")` are
# exact no-ops when the model variables contain no missing values: the retained
# rows, the design, and the likelihood are identical to the defaults. The previous
# REML gate tested the *setting* rather than whether the engine engages, so it
# rejected complete-case fits that merely passed `missing =` explicitly (reported
# by A. Mizuno on drmTMB v0.2.0, 2026-07-08).
#
# Narrow the gate, do not remove it: an engine that really engages is still
# unvalidated under REML. If we cannot prove the absence of missingness (e.g. the
# formula's columns cannot be resolved), keep rejecting.
drm_reml_missing_engine_engages <- function(missing_control, formula, data) {
  default_response <- identical(missing_control$response, "drop")
  default_predictor <- identical(missing_control$predictor, "fail")
  if (default_response && default_predictor) {
    return(FALSE)
  }
  needed <- tryCatch(
    drm_julia_needed_columns(formula),
    error = function(e) NULL
  )
  if (is.null(needed) || !is.data.frame(data)) {
    return(TRUE)
  }
  present <- intersect(needed, names(data))
  if (length(present) == 0L) {
    return(TRUE)
  }
  anyNA(data[, present, drop = FALSE])
}

drm_validate_reml_spec <- function(spec) {
  if (identical(spec$model_type, "biv_gaussian")) {
    return(drm_validate_reml_spec_biv(spec))
  }
  if (!identical(spec$model_type, "gaussian")) {
    cli::cli_abort(
      "{.arg REML} is implemented only for univariate and bivariate Gaussian models."
    )
  }
  if (isTRUE(spec$sparse_fixed$mu)) {
    cli::cli_abort(c(
      "{.arg REML} is not implemented with sparse fixed-effect matrices yet.",
      "i" = "Use {.code control = drm_control(sparse_fixed = FALSE)} or set {.code REML = FALSE}."
    ))
  }
  gaussian_aggregation <- if (is.list(spec$aggregation)) {
    spec$aggregation$gaussian
  } else {
    NULL
  }
  if (is.list(gaussian_aggregation) && isTRUE(gaussian_aggregation$enabled)) {
    cli::cli_abort(c(
      "{.arg REML} is not implemented with Gaussian row aggregation yet.",
      "i" = "Use {.code control = drm_control(aggregate_gaussian = FALSE)} or set {.code REML = FALSE}."
    ))
  }
  # A fixed-effect `sigma ~ predictors` model is allowed under REML: REML restricts
  # the likelihood for the mean fixed effects regardless of the scale model, and the
  # restricted likelihood with a heteroscedastic residual (V = diag(sigma_i^2) +
  # random-effect covariance) is exact for a Gaussian.
  #
  # ORDINARY sigma random effects are ALSO admitted under REML (2026-07-08): a
  # residual-scale random intercept `(1 | id)`, an independent random slope
  # `(0 + x | id)`, and the matched mean-scale block `(1 | p | id)`. `beta_sigma` is
  # marginalized in drm_apply_estimator_spec, so the restricted likelihood adjusts for
  # the scale intercept and debiases the scale-side variance component. Recovery
  # ladders (scratchpad/reml_ordinary_sigma_re_probe.R) show REML debiases the
  # scale-RE SD vs ML with adequate within-group REPLICATION -- uniform across
  # intercept, slope, and correlated blocks: n_each >= ~8 -> REML less biased and both
  # converge; at n_each = 3 the component is weakly identified and REML UNDERPERFORMS
  # ML (use ML or add replication). q > 2 scale blocks stay rejected below.
  # q > 2 labelled covariance blocks (e.g. a mu-side `(1 + x1 + x2 | id)` q3 block) are
  # admitted under REML (2026-07-08). A recovery ladder
  # (scratchpad/reml_parity_gaps_3A_ladder.R, n_id=60) shows REML is CONSISTENTLY less
  # biased than ML on every block SD at n_each = 5 and 10 -- the classic REML
  # variance-component debiasing. Larger q blocks remain advanced, sample-size hungry
  # fits (see docs/dev-log/known-limitations.md); pdHess is a want, not a gate.
  # Phylogenetic direct-SD scale (`sd_phylo(...) ~ predictors`, heteroscedastic phylo
  # variance) is admitted under REML: it is a location-side variance component the
  # restricted likelihood debiases (validated 2026-07-07 -- runs, recovers, REML gamma
  # coefficients closer to truth than ML, pdHess=TRUE, finite Wald SEs via cov.fixed).
  # Ordinary direct-SD scale formulae remain unvalidated and rejected.
  if (spec$random_scale$mu$n_models > 0L) {
    cli::cli_abort(c(
      "{.arg REML} is not implemented with direct ordinary random-effect scale formulae yet.",
      "i" = "Use a phylogenetic direct-SD scale ({.code sd_phylo(...) ~ ...}), ordinary location random effects, or set {.code REML = FALSE}."
    ))
  }
  phylo_mu <- spec$structured$phylo_mu
  if (isTRUE(phylo_mu$has)) {
    # Scale-side (sigma-endpoint) spatial/animal/relatedness structured effects are
    # admitted under REML (2026-07-08, C1). Like the ordinary scale REs above,
    # `beta_sigma` is marginalized in drm_apply_estimator_spec, so the restricted
    # likelihood debiases the scale-side variance component; the fit mechanism is
    # unchanged (this is an R-side gate relaxation only). A recovery + coverage
    # campaign (Totoro; scratchpad/reml_provider_ladder_parallel.R N=400 recovery,
    # scratchpad/c1_coverage_driver.R N=300 profile coverage) shows REML debiases the
    # scale-side intercept SD 400/400 across spatial/animal/relmat with bias -> 0 as
    # g grows, and REML profile-CI coverage clears the small-g inference_ready floor
    # in every cell (>= 0.926 vs a 0.91 g=8 floor). MEAN-side non-phylo structured
    # effects, and non-phylo effects spanning both endpoints, remain unvalidated and
    # rejected; the bivariate path (drm_validate_reml_spec_biv) is unchanged.
    structured_type <- structured_mu_type(phylo_mu)
    scale_side_only <- length(phylo_mu_dpar_codes(phylo_mu)) > 0L &&
      all(phylo_mu_dpar_codes(phylo_mu) == 1L)
    if (!identical(structured_type, "phylo") && !scale_side_only) {
      cli::cli_abort(c(
        "{.arg REML} supports phylogenetic ({.fn phylo}) mean-side structured effects and scale-side ({.code sigma ~ spatial()/animal()/relmat()}) structured effects.",
        "i" = "Mean-side spatial, animal, and relatedness structured effects under REML are not validated yet; set {.code REML = FALSE}."
      ))
    }
    # A PURE scale-side phylo effect (a sigma endpoint, no mean endpoint) AND a
    # MATCHED mean-and-scale phylo effect (both endpoints -- the q2 2x2 block, e.g.
    # `1 | p | species`) are both admitted under REML. `beta_sigma` is marginalized
    # in drm_apply_estimator_spec, so the restricted likelihood already adjusts for
    # the coupled scale coefficients (Cox-Reid / adjusted-profile REML; Noether
    # 2026-07-06) -- no separate Cox-Reid term is needed. The earlier N=120 "REML
    # degrades the mean-side SD" arbiter (2026-07-06) was BELOW q2's N>=250
    # identifiability floor and is SUPERSEDED (2026-07-07): the sample-size ladder
    # (N=250..2000, 30 seeds, doc 221) shows REML is LESS biased than ML on sd_mu at
    # every n, debiases sd_sigma throughout, and recovers the loc-scale correlation
    # (needs N>=1000 to identify). pdHess concordance REML 0.97 > ML 0.93.
  }
  if (qr(as.matrix(spec$X$mu))$rank < ncol(spec$X$mu)) {
    cli::cli_abort(c(
      "{.arg REML} requires a full-rank dense {.code mu} fixed-effect design in this first slice.",
      "i" = "Remove aliased fixed-effect columns or set {.code REML = FALSE}."
    ))
  }
  invisible(TRUE)
}

# REML validation for the bivariate Gaussian model. TMB marginalises beta_mu1 and
# beta_mu2 (Laplace), which is exact for the Gaussian and gives an unbiased residual
# covariance AND unbiased phylo location-variance. MEAN-side random / structured
# (phylo) effects are admitted here, validated against an exact bivariate
# restricted-likelihood reference plus a sample-size recovery ladder (doc 221:
# biases collapse to 0 with n, REML debiases the variance components at every n, and
# REML/ML SEs agree). Rejected until separately validated: scale-side random effects,
# matched mean-and-scale phylo, direct random-effect scale formulae (sd_phylo ~ x),
# and q > 2 labelled blocks. (Checks mirror drm_validate_reml_spec for the shared,
# model-agnostic spec fields; kept inline to avoid touching the univariate path.)
drm_validate_reml_spec_biv <- function(spec) {
  if (isTRUE(spec$sparse_fixed$mu1) || isTRUE(spec$sparse_fixed$mu2)) {
    cli::cli_abort(c(
      "{.arg REML} is not implemented with sparse fixed-effect matrices yet.",
      "i" = "Use {.code control = drm_control(sparse_fixed = FALSE)} or set {.code REML = FALSE}."
    ))
  }
  # ORDINARY sigma random effects are admitted under REML for bivariate models too
  # (2026-07-08): a labelled scale-side block `(1 | s | id)` on `sigma1`/`sigma2`
  # (bivariate sigma REs require an explicit covariance-block label). `beta_sigma1`
  # and `beta_sigma2` are marginalized in drm_apply_estimator_spec. A bivariate
  # recovery ladder (scratchpad/reml_biv_sigma_re_probe.R, n_id=60) shows both
  # scale-RE SDs recover under ML and REML (REML at least as good; slightly better on
  # the scale-RE correlation at low replication), pdHess 1.00.
  #
  # Bivariate MEAN-scale (`mu`-`sigma`) random-effect correlations are ALSO admitted
  # (2026-07-08) -- e.g. a labelled `(1 | p | id)` block spanning `mu1` and `sigma1`.
  # A recovery ladder (scratchpad/reml_parity_gaps_3A_ladder.R, n_id=60) shows both SDs
  # and the mean-scale correlation recover under ML and REML with small biases (<=0.06),
  # REML at least as good on the scale-side SD.
  #
  # q > 2 labelled covariance blocks are likewise admitted under REML (2026-07-08); the
  # same ladder shows REML CONSISTENTLY less biased than ML on all block SDs (the
  # classic REML variance-component debiasing). Larger q blocks stay sample-size hungry
  # (see docs/dev-log/known-limitations.md); pdHess is a want, not a gate.
  # Phylogenetic direct-SD scale (`sd_phylo1/sd_phylo2 ~ predictors`) with location
  # `phylo` means is admitted under REML (Ayumi's corrected model; same location-side
  # debiasing as the univariate case). Ordinary direct-SD scale formulae stay rejected;
  # the q4-block guard (do not combine sd_phylo with a q=4 phylo block) is separate.
  if (spec$random_scale$mu$n_models > 0L) {
    cli::cli_abort(c(
      "{.arg REML} is not implemented with direct ordinary random-effect scale formulae for bivariate models yet.",
      "i" = "Use a phylogenetic direct-SD scale ({.code sd_phylo1/sd_phylo2 ~ ...}) with location {.fn phylo} terms, or set {.code REML = FALSE}."
    ))
  }
  phylo_mu <- spec$structured$phylo_mu
  if (isTRUE(phylo_mu$has)) {
    if (!identical(structured_mu_type(phylo_mu), "phylo")) {
      cli::cli_abort(c(
        "{.arg REML} currently supports only phylogenetic ({.fn phylo}) mean-side structured effects.",
        "i" = "Spatial, animal, and relatedness structured effects under REML are not validated yet; set {.code REML = FALSE}."
      ))
    }
    # Scale-side phylo endpoints are admitted under REML in ALL covariance layouts
    # (2026-07-08): block-diagonal, dense (unstructured) q4, and scale-only.
    #
    # BLOCK-DIAGONAL (phylo location block ⊥ phylo scale block -- distinct labels, e.g.
    # `1 | p | sp` on mu1/mu2 and `1 | ps | sp` on sigma1/sigma2): no mean-scale
    # cross-covariance, identifiable WITH per-group replication
    # (scratchpad/reml_blockdiag_replication_ladder.R: n_each >= 5 -> 100% pdHess,
    # biases -> 0).
    #
    # DENSE q4 (one shared label across all four endpoints, carrying the mean-scale
    # cross-covariances) is ALSO admitted. The earlier "sign-flip + always collapses"
    # verdict is SUPERSEDED: scratchpad/q4_signflip_diagnostic.R proves the
    # DGP<->endpoint mapping is CORRECT (a single nonzero DGP correlation lands on the
    # right pair with the right sign) -- the apparent sign-flip was a symptom of an
    # UNDER-POWERED fit whose variance component collapsed, leaving its correlations
    # unidentified. With adequate information (n_tip >= ~200 AND per-species
    # replication n_each >= ~10) the dense q4 converges and recovers, and REML is
    # STRICTLY BETTER than ML there: higher pdHess/convergence rate (0.75 vs 0.50 at
    # n_tip=200) and variance components debiased toward truth
    # (scratchpad/reml_dense_q4_ladder.R). Rejecting it under REML while ML admits it
    # would be an inverted gate.
    #
    # DATA CAVEAT (not a gate): at 1 obs/species, or n_tip/n_each below the above, the
    # dense q4 collapses (pdHess FALSE, nuisance correlations pinned at the boundary).
    # Use the block-diagonal layout or a FIXED sd_phylo1/sd_phylo2 scale (Model A+) for
    # species-mean data. pdHess is a want, not a gate -- route CIs through
    # profile/bootstrap.
  }
  if (
    qr(as.matrix(spec$X$mu1))$rank < ncol(spec$X$mu1) ||
      qr(as.matrix(spec$X$mu2))$rank < ncol(spec$X$mu2)
  ) {
    cli::cli_abort(c(
      "{.arg REML} requires full-rank dense {.code mu1} and {.code mu2} fixed-effect designs.",
      "i" = "Remove aliased fixed-effect columns or set {.code REML = FALSE}."
    ))
  }
  invisible(TRUE)
}

drm_fit_df <- function(spec, opt) {
  df <- length(opt$par)
  if (identical(spec$estimator, "REML")) {
    # Add back every fixed-effect block TMB marginalized into the Laplace `random`
    # block so `df` counts them as model parameters. `tmb_random_names`
    # (drm_apply_estimator_spec) is the record of what was marginalized: `beta_mu`
    # is always there under REML, and `beta_sigma` is there iff a sigma variance
    # component made the scale coefficients restricted too. Reading it -- rather
    # than re-deriving the `has_sigma_re` gate -- keeps `df` in lockstep with the
    # actual marginalization, so a scale-side REML fit's df (and hence AIC/BIC)
    # counts its sigma fixed effects instead of silently under-counting them.
    marginalized <- spec$tmb_random_names
    blocks <- if (identical(spec$model_type, "biv_gaussian")) {
      c(beta_mu1 = "mu1", beta_mu2 = "mu2",
        beta_sigma1 = "sigma1", beta_sigma2 = "sigma2")
    } else {
      c(beta_mu = "mu", beta_sigma = "sigma")
    }
    for (par_name in names(blocks)) {
      x_name <- blocks[[par_name]]
      if (par_name %in% marginalized && !is.null(spec$X[[x_name]])) {
        df <- df + ncol(spec$X[[x_name]])
      }
    }
  }
  df
}

drm_compute_uncertainty <- function(obj, opt, control) {
  if (!isTRUE(control$se)) {
    return(list(
      sdr = NULL,
      state = drm_uncertainty_state(
        status = "skipped",
        se = FALSE,
        message = paste(
          "TMB::sdreport() was skipped because",
          "drm_control(se = FALSE) was used."
        )
      )
    ))
  }

  # `getReportCovariance = TRUE` (TMB's default) builds the full covariance of
  # every ADREPORTed quantity. A direct-SD surface ADREPORTs one SD per group
  # (`sd_phylo_group`, src/drmTMB.cpp), so that matrix is n_group x n_group and
  # its cost is quadratic in the number of groups. Guard against a legacy plain
  # list `control` (field absent => NULL) silently flipping the TRUE default.
  report_covariance <- if (is.null(control$se_report_covariance)) {
    TRUE
  } else {
    isTRUE(control$se_report_covariance)
  }
  sdr <- tryCatch(
    TMB::sdreport(
      obj,
      par.fixed = opt$par,
      getReportCovariance = report_covariance,
      skip.delta.method = isTRUE(control$se_skip_delta_method)
    ),
    error = function(e) e
  )
  if (inherits(sdr, "error")) {
    return(list(
      sdr = NULL,
      state = drm_uncertainty_state(
        status = "failed",
        se = TRUE,
        message = paste("TMB::sdreport() failed:", conditionMessage(sdr)),
        sdr_error = conditionMessage(sdr)
      )
    ))
  }

  list(
    sdr = sdr,
    state = drm_uncertainty_state(
      status = "ok",
      se = TRUE,
      message = "TMB::sdreport() completed successfully."
    )
  )
}

drm_uncertainty_state <- function(
  status,
  se,
  message,
  sdr_error = NA_character_
) {
  list(
    status = status,
    se = se,
    message = message,
    sdr_error = sdr_error
  )
}

drm_tmb_selected_state <- function(obj, opt) {
  list(
    last.par = obj$env$last.par,
    last.par.best = obj$env$last.par.best,
    opt.par = opt$par
  )
}

drm_pin_tmb_object_to_optimum <- function(obj, opt, state = NULL) {
  if (
    is.null(obj) ||
      is.null(obj$env) ||
      is.null(opt) ||
      is.null(opt$par)
  ) {
    return(invisible(FALSE))
  }
  if (
    is.list(state) &&
      !is.null(state$last.par) &&
      !is.null(state$last.par.best)
  ) {
    obj$env$last.par <- state$last.par
    obj$env$last.par.best <- state$last.par.best
    return(invisible(TRUE))
  }
  fixed <- obj$env$lfixed()
  if (
    is.logical(fixed) &&
      length(fixed) == length(obj$env$last.par) &&
      sum(fixed) == length(opt$par)
  ) {
    last_par <- obj$env$last.par
    last_par[fixed] <- opt$par
    obj$env$last.par <- last_par
  } else if (length(obj$env$last.par) == length(opt$par)) {
    obj$env$last.par <- opt$par
  }

  if (length(obj$env$last.par.best) == length(opt$par)) {
    obj$env$last.par.best <- opt$par
  } else if (
    is.logical(fixed) &&
      length(fixed) == length(obj$env$last.par.best) &&
      sum(fixed) == length(opt$par)
  ) {
    last_par_best <- obj$env$last.par.best
    last_par_best[fixed] <- opt$par
    obj$env$last.par.best <- last_par_best
  }
  invisible(TRUE)
}

# Interpret an nlminb convergence code. Returns NULL when the optimizer reported
# convergence (code 0) and a short human label otherwise, surfacing the PORT
# message (for example "false convergence (8)").
drm_convergence_label <- function(convergence, message = NULL) {
  if (length(convergence) != 1L || is.na(convergence)) {
    return(NULL)
  }
  if (identical(as.integer(convergence), 0L)) {
    return(NULL)
  }
  has_message <- length(message) == 1L &&
    !is.na(message) &&
    nzchar(message)
  if (has_message) {
    sprintf(
      "optimizer reported non-convergence (code %s: %s)",
      convergence,
      message
    )
  } else {
    sprintf("optimizer reported non-convergence (code %s)", convergence)
  }
}

# Warn at fit time when the optimizer did not converge, so a non-converged fit
# is never returned looking fine. Suppressible like any warning.
drm_warn_if_not_converged <- function(opt) {
  label <- drm_convergence_label(opt$convergence, opt$message)
  if (is.null(label)) {
    return(invisible(FALSE))
  }
  cli::cli_warn(
    c(
      "{.fn drmTMB}: {label}.",
      "i" = "Treat the estimates and standard errors with caution. The optimizer escalates its preset ladder automatically, so inspect {.code fit$optimizer_attempts} and run {.fn check_drm} to diagnose; consider rescaling the data, within-group replication, or a penalized/MAP fit."
    ),
    class = "drmTMB_convergence_warning"
  )
  invisible(TRUE)
}

# Warn at fit time when the optimized objective is not finite. TMB normally
# returns a finite objective at the reported optimum, so this is a defensive
# guard: a non-finite objective means the fit never reached a usable optimum and
# its log-likelihood, estimates, and SEs are meaningless, but nlminb may not have
# thrown an error.
drm_warn_if_nonfinite_objective <- function(opt) {
  objective <- opt$objective
  if (length(objective) == 1L && is.finite(objective)) {
    return(invisible(FALSE))
  }
  cli::cli_warn(
    c(
      "{.fn drmTMB}: the optimized objective is not finite.",
      "i" = "The fit did not reach a usable optimum; its log-likelihood, estimates, and standard errors are unreliable. Inspect with {.fn check_drm}, rescale or simplify the model, or refit with {.code control = drm_control(optimizer_preset = \"robust\")}."
    ),
    class = "drmTMB_nonfinite_objective_warning"
  )
  invisible(TRUE)
}

# Detect whether the log(sigma) soft-clamp is active at the optimum, i.e. the
# fitted log_sigma reached or passed the identity band [lo, hi] and the clamp
# bent it. Returns NULL when the clamp is disabled or the scale is well inside
# the band, otherwise a list with the extreme |log_sigma| and the band. Reads
# every reported `log_sigma*` field so univariate and bivariate scales are
# covered.
# Model types whose main-likelihood scale is wrapped by the log(sigma) soft-clamp
# (Wave 2). Count families without a scale (poisson, zi_poisson, cumulative_logit)
# are excluded. Keep in sync with the clamp call sites in src/drmTMB.cpp.
drm_clamped_scale_families <- function() {
  c(
    "gaussian",
    "biv_gaussian",
    "student",
    "skew_normal",
    "lognormal",
    "gamma",
    "tweedie",
    "beta",
    "zero_one_beta",
    "beta_binomial",
    "nbinom2",
    "truncated_nbinom2",
    "hurdle_nbinom2",
    "zi_nbinom2"
  )
}

drm_logsigma_clamp_active <- function(report, tmb_data) {
  enabled <- tmb_data$use_logsigma_clamp
  if (length(enabled) != 1L || !identical(as.integer(enabled), 1L)) {
    return(NULL)
  }
  band <- tmb_data$logsigma_clamp
  if (length(band) < 2L || anyNA(band[1:2])) {
    return(NULL)
  }
  lo <- band[[1L]]
  hi <- band[[2L]]
  # Only the main-likelihood scales are soft-clamped; match their exact REPORT
  # names so the unclamped missing-predictor imputation scales (log_sigma_*_mi)
  # never trip the detector.
  fields <- report[
    names(report) %in% c("log_sigma", "log_sigma1", "log_sigma2")
  ]
  values <- unlist(fields, use.names = FALSE)
  values <- values[is.finite(values)]
  # Only the upper bound flags artificial convergence from a runaway scale
  # (sigma -> Inf / overflow). The lower bound (sigma -> 0) is the variance-zero
  # boundary, which is often a legitimate result (e.g. meta-analysis tau = 0) and
  # is handled by the random-effect SD / scale checks in check_drm().
  if (length(values) == 0L || !any(values > hi)) {
    return(NULL)
  }
  list(value = max(values), lo = lo, hi = hi)
}

# Warn at fit time when the log(sigma) clamp is active at the optimum. The clamp
# keeps a runaway scale finite, but a fit that settles on it may have converged
# artificially (flat saturated tail), so estimates and SEs there are unreliable.
drm_warn_if_clamp_active <- function(obj, spec) {
  # The clamp is applied in C++ for every scale-bearing family (Wave 2); gate on
  # those model types because use_logsigma_clamp is a data default on every model
  # (including count families without a scale), so checking it alone would flag
  # models where the clamp is never applied.
  if (!isTRUE(spec$model_type %in% drm_clamped_scale_families())) {
    return(invisible(FALSE))
  }
  report <- tryCatch(obj$report(), error = function(e) NULL)
  if (is.null(report)) {
    return(invisible(FALSE))
  }
  info <- drm_logsigma_clamp_active(report, spec$tmb_data)
  if (is.null(info)) {
    return(invisible(FALSE))
  }
  cli::cli_warn(
    c(
      "{.fn drmTMB}: the {.code log(sigma)} clamp is active at the optimum (the fitted {.code log(sigma)} reached {.val {round(info$value, 1)}}, above the band upper bound {.val {info$hi}}).",
      "i" = "The scale ran to the upper clamp, so the fit may have converged artificially: estimates and standard errors near the clamp are unreliable. Rescale the response, widen the band with {.code drm_control(logsigma_clamp = )}, add within-group replication, or use a penalized/MAP fit; {.fn check_drm} reports the fit state."
    ),
    class = "drmTMB_clamp_active_warning"
  )
  invisible(TRUE)
}

reject_corpair_formula_entries <- function(entries) {
  is_corpair <- vapply(
    entries,
    function(entry) is.list(entry$corpair),
    logical(1L)
  )
  if (!any(is_corpair)) {
    return(invisible(NULL))
  }
  labels <- vapply(
    entries[is_corpair],
    function(entry) entry$dpar,
    character(1L)
  )
  cli::cli_abort(c(
    "{.fn corpair} formula syntax is reserved but not implemented yet.",
    "x" = "Unsupported formula{?s}: {.val {labels}}.",
    "i" = "{.code rho12 = ~ x} models residual within-observation correlation; {.fn corpairs} extracts fitted latent random-effect correlations.",
    "i" = "Predictor-dependent latent random-effect correlations will come after constant ordinary q4 diagnostics are stable."
  ))
}

drm_spec_response_names <- function(spec) {
  response_dpars <- if (identical(spec$model_type, "biv_gaussian")) {
    c("mu1", "mu2")
  } else {
    "mu"
  }
  out <- stats::setNames(
    as.list(rep(NA_character_, length(response_dpars))),
    response_dpars
  )
  for (dpar in response_dpars) {
    mf <- spec$model_frame[[dpar]]
    if (is.data.frame(mf) && ncol(mf) > 0L) {
      out[[dpar]] <- names(mf)[[1L]]
    }
  }
  out
}

drm_family_type <- function(family) {
  if (inherits(family, "family") && identical(family$family, "gaussian")) {
    return("gaussian")
  }
  if (inherits(family, "family") && identical(family$family, "Gamma")) {
    if (!identical(family$link, "log")) {
      cli::cli_abort(c(
        "{.pkg drmTMB} Gamma models currently require {.code Gamma(link = \"log\")}.",
        "x" = "Received Gamma link {.val {family$link}}.",
        "i" = "The implemented Gamma contract is {.code log(mu) = X_mu beta_mu} and {.code log(sigma) = X_sigma beta_sigma}, where {.code sigma} is the coefficient of variation."
      ))
    }
    return("gamma")
  }
  if (inherits(family, "family") && identical(family$family, "poisson")) {
    if (!identical(family$link, "log")) {
      cli::cli_abort(c(
        "{.pkg drmTMB} Poisson models currently require {.code poisson(link = \"log\")}.",
        "x" = "Received Poisson link {.val {family$link}}.",
        "i" = "The implemented Poisson contract is {.code log(mu) = X_mu beta_mu}."
      ))
    }
    return("poisson")
  }
  if (inherits(family, "family") && identical(family$family, "binomial")) {
    if (!identical(family$link, "logit")) {
      cli::cli_abort(c(
        "{.pkg drmTMB} binomial models currently require {.code binomial(link = \"logit\")}.",
        "x" = "Received binomial link {.val {family$link}}.",
        "i" = "The first binomial-response contract is {.code logit(mu) = X_mu beta_mu}; use {.code cbind(successes, failures)} for trial denominators."
      ))
    }
    return("binomial")
  }
  if (inherits(family, "drm_family") && identical(family$name, "nbinom2")) {
    return("nbinom2")
  }
  if (inherits(family, "drm_family") && identical(family$name, "tweedie")) {
    return("tweedie")
  }
  if (
    inherits(family, "drm_family") &&
      identical(family$name, "truncated_nbinom2")
  ) {
    return("truncated_nbinom2")
  }
  if (inherits(family, "drm_family") && identical(family$name, "beta")) {
    return("beta")
  }
  if (
    inherits(family, "drm_family") && identical(family$name, "zero_one_beta")
  ) {
    return("zero_one_beta")
  }
  if (
    inherits(family, "drm_family") && identical(family$name, "beta_binomial")
  ) {
    return("beta_binomial")
  }
  if (
    inherits(family, "drm_family") && identical(family$name, "cumulative_logit")
  ) {
    return("cumulative_logit")
  }
  if (
    inherits(family, "drm_family") && identical(family$name, "biv_gaussian")
  ) {
    return("biv_gaussian")
  }
  if (inherits(family, "drm_family") && identical(family$name, "student")) {
    return("student")
  }
  if (inherits(family, "drm_family") && identical(family$name, "skew_normal")) {
    return("skew_normal")
  }
  if (inherits(family, "drm_family") && identical(family$name, "lognormal")) {
    return("lognormal")
  }
  composed <- drm_composed_families(family)
  if (!is.null(composed)) {
    family_names <- vapply(composed, `[[`, character(1), "family")
    if (length(family_names) != 2L) {
      cli::cli_abort(c(
        "{.pkg drmTMB} currently supports one-response and two-response models only.",
        "x" = "Received {length(family_names)} response families: {.val {family_names}}.",
        "i" = "Use a single family such as {.fn gaussian} or a two-response family such as {.code c(gaussian(), gaussian())}."
      ))
    }
    if (identical(family_names, c("gaussian", "gaussian"))) {
      return("biv_gaussian")
    }
    cli::cli_abort(c(
      "Mixed-response bivariate families are not implemented yet.",
      "x" = "Requested families: {.val {family_names}}.",
      "i" = "Only {.code family = c(gaussian(), gaussian())} or {.code family = list(gaussian(), gaussian())} is currently routed to the bivariate Gaussian engine."
    ))
  }
  cli::cli_abort(
    "Currently supported families are {.code gaussian()}, {.fn student}, {.fn skew_normal}, {.fn lognormal}, {.code Gamma(link = \"log\")}, {.fn tweedie}, {.fn beta}, {.fn zero_one_beta}, {.fn beta_binomial}, {.code binomial(link = \"logit\")}, {.fn cumulative_logit}, {.code poisson(link = \"log\")}, {.fn nbinom2}, {.fn truncated_nbinom2}, {.fn biv_gaussian}, {.code c(gaussian(), gaussian())}, and {.code list(gaussian(), gaussian())}. Zero-inflated Poisson and NB2 models use the same family route plus a {.code zi ~ ...} formula; hurdle NB2 models use {.fn truncated_nbinom2} plus a {.code hu ~ ...} formula."
  )
}

drm_composed_families <- function(family) {
  if (
    is.list(family) &&
      !inherits(family, "family") &&
      !inherits(family, "drm_family") &&
      length(family) >= 2L &&
      all(vapply(family, is_r_family_object, logical(1)))
  ) {
    return(family)
  }
  if (
    !is.list(family) ||
      inherits(family, "family") ||
      inherits(family, "drm_family")
  ) {
    return(NULL)
  }
  family_starts <- which(names(family) == "family")
  if (length(family_starts) < 2L || family_starts[[1L]] != 1L) {
    return(NULL)
  }
  family_ends <- c(family_starts[-1L] - 1L, length(family))
  families <- Map(
    function(start, end) {
      out <- family[seq.int(start, end)]
      class(out) <- "family"
      out
    },
    family_starts,
    family_ends
  )
  if (!all(vapply(families, is_r_family_object, logical(1)))) {
    return(NULL)
  }
  families
}

is_r_family_object <- function(x) {
  inherits(x, "family") && is.character(x$family) && length(x$family) == 1L
}

drm_build_gaussian_ls_spec <- function(
  formula,
  data,
  env = parent.frame(),
  weights = NULL,
  control = drm_control(),
  impute = NULL,
  missing = miss_control()
) {
  missing <- drm_parse_missing_control(missing)
  include_missing_response <- identical(missing$response, "include")
  entries <- formula$entries
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  is_sd_mu_dpar <- startsWith(dpars, "sd(")
  is_sd_phylo_dpar <- startsWith(dpars, "sd_phylo(")
  is_sd_dpar <- is_sd_mu_dpar | is_sd_phylo_dpar

  unsupported <- setdiff(dpars[!is_sd_dpar], c("mu", "sigma"))
  if (length(unsupported) > 0L) {
    cli::cli_abort(c(
      "Phase 1 Gaussian models only support {.code mu} and {.code sigma}.",
      "x" = "Unsupported parameter{?s}: {.val {unsupported}}."
    ))
  }

  if (sum(dpars[!is_sd_dpar] == "mu") != 1L) {
    cli::cli_abort(
      "A univariate Gaussian model requires exactly one location formula."
    )
  }
  if (sum(dpars[!is_sd_dpar] == "sigma") > 1L) {
    cli::cli_abort(
      "A univariate Gaussian model can have at most one residual {.code sigma} formula."
    )
  }
  mu_entry <- entries[[which(dpars == "mu")]]
  sigma_entry <- if (any(dpars == "sigma")) {
    entries[[which(dpars == "sigma")]]
  } else {
    default_dpar_entry("sigma", quote(1))
  }
  sd_mu_entries <- if (any(is_sd_mu_dpar)) {
    entries[is_sd_mu_dpar]
  } else {
    list()
  }
  sd_phylo_entries <- if (any(is_sd_phylo_dpar)) {
    entries[is_sd_phylo_dpar]
  } else {
    list()
  }

  if (is.na(mu_entry$response)) {
    cli::cli_abort(
      "The {.code mu} formula must include a response on the left-hand side."
    )
  }
  if (is_mvbind_lhs(mu_entry$lhs)) {
    cli::cli_abort(c(
      "{.fn mvbind} shorthand is only available for two-response Gaussian models.",
      "x" = "Use {.code family = c(gaussian(), gaussian())} or explicit formulas such as {.code mu1 = y1 ~ x} and {.code mu2 = y2 ~ x}."
    ))
  }

  meta <- extract_meta_known_v(mu_entry$rhs)
  mu_entry$rhs <- meta$rhs
  mu_phylo <- extract_gaussian_mu_phylo_term(mu_entry)
  mu_entry$rhs <- mu_phylo$rhs
  mu_phylo_interaction <- extract_gaussian_mu_phylo_interaction_term(mu_entry)
  mu_entry$rhs <- mu_phylo_interaction$rhs
  mu_spatial <- extract_gaussian_mu_spatial_term(mu_entry)
  mu_entry$rhs <- mu_spatial$rhs
  mu_animal <- extract_gaussian_mu_known_term(mu_entry, "animal")
  mu_entry$rhs <- mu_animal$rhs
  mu_relmat <- extract_gaussian_mu_known_term(mu_entry, "relmat")
  mu_entry$rhs <- mu_relmat$rhs
  sigma_phylo <- extract_gaussian_mu_phylo_term(sigma_entry, dpar = "sigma")
  sigma_entry$rhs <- sigma_phylo$rhs
  sigma_spatial <- extract_gaussian_mu_spatial_term(
    sigma_entry,
    dpar = "sigma"
  )
  sigma_entry$rhs <- sigma_spatial$rhs
  sigma_animal <- extract_gaussian_mu_known_term(
    sigma_entry,
    "animal",
    dpar = "sigma"
  )
  sigma_entry$rhs <- sigma_animal$rhs
  sigma_relmat <- extract_gaussian_mu_known_term(
    sigma_entry,
    "relmat",
    dpar = "sigma"
  )
  sigma_entry$rhs <- sigma_relmat$rhs
  raw_structured_terms <- list(
    phylo = list(mu = mu_phylo$term, sigma = sigma_phylo$term),
    phylo_interaction = list(mu = mu_phylo_interaction$term, sigma = NULL),
    spatial = list(mu = mu_spatial$term, sigma = sigma_spatial$term),
    animal = list(mu = mu_animal$term, sigma = sigma_animal$term),
    relmat = list(mu = mu_relmat$term, sigma = sigma_relmat$term)
  )
  active_structured <- names(raw_structured_terms)[
    vapply(
      raw_structured_terms,
      function(terms) {
        !is.null(terms$mu) || !is.null(terms$sigma)
      },
      logical(1)
    )
  ]
  if (length(active_structured) > 1L) {
    cli::cli_abort(c(
      "Only one structured effect type is implemented per univariate Gaussian model.",
      "x" = "The model contains structured effect types: {.val {active_structured}}.",
      "i" = "Fit one structured layer at a time until multiple structured layers have their own identifiability checks."
    ))
  }
  structured_terms <- lapply(
    names(raw_structured_terms),
    function(marker) {
      combine_univariate_structured_terms(
        raw_structured_terms[[marker]]$mu,
        raw_structured_terms[[marker]]$sigma,
        marker = marker
      )
    }
  )
  names(structured_terms) <- names(raw_structured_terms)
  structured_term <- if (length(active_structured) == 1L) {
    structured_terms[[active_structured]]
  } else {
    NULL
  }
  mu_phylo$term <- structured_terms$phylo
  mu_phylo_interaction$term <- structured_terms$phylo_interaction
  mu_spatial$term <- structured_terms$spatial
  mu_animal$term <- structured_terms$animal
  mu_relmat$term <- structured_terms$relmat
  mu_re <- extract_random_mu_terms(mu_entry$rhs, "mu")
  mu_entry$rhs <- mu_re$rhs
  sigma_re <- extract_random_sigma_terms(sigma_entry$rhs, "sigma")
  sigma_entry$rhs <- sigma_re$rhs
  sd_mu_targets <- parse_sd_mu_entries(sd_mu_entries, mu_re$terms)
  active_mu_terms <- remove_qgt2_random_mu_terms(mu_re$terms)
  sd_phylo_targets <- parse_sd_phylo_entries(
    sd_phylo_entries,
    mu_phylo$term
  )
  mi_setup <- drm_prepare_gaussian_mi_setup(mu_entry$rhs, impute, missing)
  include_missing_predictor <- isTRUE(mi_setup$enabled)
  sparse_mu <- isTRUE(control$sparse_fixed)
  aggregate_gaussian <- isTRUE(control$aggregate_gaussian)
  if (include_missing_predictor && sparse_mu) {
    cli::cli_abort(c(
      "Gaussian {.fn mi} predictor models are not implemented with sparse fixed-effect matrices in MD3a.",
      "i" = "Set {.code sparse_fixed = FALSE} for the current Gaussian {.fn mi} route."
    ))
  }
  if (include_missing_response && aggregate_gaussian) {
    cli::cli_abort(c(
      "Gaussian response-missingness masks are not implemented with Gaussian aggregation in MD1.",
      "i" = "Set {.code aggregate_gaussian = FALSE} or use the default {.code missing = miss_control(response = \"drop\")}."
    ))
  }
  if (include_missing_predictor && aggregate_gaussian) {
    cli::cli_abort(c(
      "Gaussian {.fn mi} predictor models are not implemented with Gaussian aggregation in MD3a.",
      "i" = "Set {.code aggregate_gaussian = FALSE} for the current Gaussian {.fn mi} route."
    ))
  }
  if (aggregate_gaussian) {
    validate_gaussian_aggregation_gaussian(
      meta = meta,
      mu_phylo = mu_phylo,
      mu_phylo_interaction = mu_phylo_interaction,
      mu_spatial = mu_spatial,
      mu_animal = mu_animal,
      mu_relmat = mu_relmat,
      mu_re = mu_re,
      sigma_re = sigma_re,
      sd_mu_entries = sd_mu_entries,
      sd_phylo_entries = sd_phylo_entries,
      sparse_mu = sparse_mu
    )
  }
  if (sparse_mu) {
    validate_sparse_fixed_gaussian(
      meta = meta,
      mu_phylo = mu_phylo,
      mu_phylo_interaction = mu_phylo_interaction,
      mu_spatial = mu_spatial,
      mu_animal = mu_animal,
      mu_relmat = mu_relmat,
      mu_re = mu_re,
      sigma_re = sigma_re,
      sd_mu_entries = sd_mu_entries,
      sd_phylo_entries = sd_phylo_entries,
      sigma_entry = sigma_entry
    )
  }

  drm_reject_phase1_terms(mu_entry$rhs, "mu")
  drm_reject_phase1_terms(sigma_entry$rhs, "sigma")
  for (sd_mu_entry in sd_mu_entries) {
    drm_reject_phase1_terms(sd_mu_entry$rhs, sd_mu_entry$dpar)
  }
  for (sd_phylo_entry in sd_phylo_entries) {
    drm_reject_phase1_terms(sd_phylo_entry$rhs, sd_phylo_entry$dpar)
  }

  f_mu <- drm_entry_formula(mu_entry, response = TRUE)
  f_sigma <- drm_entry_formula(sigma_entry, response = FALSE)
  f_sd_mu <- lapply(sd_mu_entries, drm_entry_formula, response = FALSE)
  f_sd_phylo <- lapply(sd_phylo_entries, drm_entry_formula, response = FALSE)

  mu_model_vars <- if (include_missing_response) {
    all.vars(stats::delete.response(stats::terms(f_mu)))
  } else {
    all.vars(f_mu)
  }
  if (include_missing_predictor) {
    mu_model_vars <- setdiff(mu_model_vars, mi_setup$variable)
  }
  impute_vars <- if (include_missing_predictor) {
    c(
      all.vars(stats::delete.response(stats::terms(mi_setup$formula))),
      mi_setup$trials_variable,
      if (is.list(mi_setup$random) && isTRUE(mi_setup$random$enabled)) {
        mi_setup$random$group
      },
      if (
        is.list(mi_setup$structured) &&
          isTRUE(mi_setup$structured$enabled)
      ) {
        structured_mu_vars(mi_setup$structured$term)
      }
    )
  } else {
    character(0)
  }
  if (include_missing_predictor) {
    response_vars <- all.vars(f_mu[[2L]])
    response_in_impute <- intersect(impute_vars, response_vars)
    if (length(response_in_impute) > 0L) {
      cli::cli_abort(c(
        "The first {.arg impute} slice does not allow response variables as predictor-model covariates.",
        "x" = "Remove response variable{?s} {.val {response_in_impute}} from the {.arg impute} formula."
      ))
    }
  }
  vars <- unique(c(
    mu_model_vars,
    all.vars(f_sigma),
    impute_vars,
    unlist(lapply(f_sd_mu, all.vars), use.names = FALSE),
    unlist(lapply(f_sd_phylo, all.vars), use.names = FALSE),
    structured_mu_vars(structured_term),
    vapply(sd_mu_targets, `[[`, character(1), "group"),
    vapply(sd_phylo_targets, `[[`, character(1), "group"),
    random_effect_vars(mu_re$terms),
    random_effect_vars(sigma_re$terms)
  ))
  if (length(vars) > 0L) {
    model_keep <- stats::complete.cases(data[, vars, drop = FALSE])
  } else {
    model_keep <- rep(TRUE, nrow(data))
  }
  if (
    (include_missing_response || include_missing_predictor) && any(!model_keep)
  ) {
    cli::cli_abort(c(
      "Missing predictors, grouping variables, or structured-effect inputs outside explicit {.fn mi} terms are not implemented for current missing-data slices.",
      "x" = "{sum(!model_keep)} data row{?s} {?has/have} missing model-input value{?s}.",
      "i" = "Keep ordinary predictors complete, or model one supported missing predictor with {.fn mi} and {.arg impute}."
    ))
  }

  V_known_full <- evaluate_known_v(meta$V, data, env)
  V_known_model <- subset_known_v(V_known_full, model_keep, validate = FALSE)
  keep <- model_keep
  keep[model_keep] <- known_v_complete(V_known_model)
  data_model <- data[keep, , drop = FALSE]
  V_known <- subset_known_v(V_known_full, keep)
  weights_model <- subset_likelihood_weights(
    weights,
    keep,
    nrow(data),
    sum(keep)
  )
  if (aggregate_gaussian) {
    drm_validate_gaussian_aggregation_weights(weights_model)
  }

  mf_mu <- stats::model.frame(
    f_mu,
    data = data_model,
    na.action = if (include_missing_response || include_missing_predictor) {
      stats::na.pass
    } else {
      stats::na.omit
    }
  )
  mf_sigma <- stats::model.frame(
    f_sigma,
    data = data_model,
    na.action = if (include_missing_response || include_missing_predictor) {
      stats::na.pass
    } else {
      stats::na.omit
    }
  )
  y_raw <- stats::model.response(mf_mu)
  observed_y <- !is.na(y_raw)
  if (!include_missing_response && any(!observed_y)) {
    cli::cli_abort(
      "Internal complete-case filter left a missing Gaussian response."
    )
  }
  if (!any(observed_y)) {
    cli::cli_abort(
      "At least one observed Gaussian response is required for fitting."
    )
  }
  response_sentinel <- if (include_missing_response) {
    drm_missing_response_sentinel()
  } else {
    NA_real_
  }
  y <- as.numeric(y_raw)
  if (include_missing_response) {
    y[!observed_y] <- response_sentinel
  }
  if (
    include_missing_response &&
      identical(V_known$type, "matrix") &&
      any(!observed_y)
  ) {
    cli::cli_abort(c(
      "Gaussian response-missingness masks are not implemented for dense known sampling covariance matrices in MD1.",
      "i" = "Use diagonal {.fn meta_V} variances, complete responses, or the default complete-case response policy."
    ))
  }
  if (
    include_missing_predictor &&
      identical(V_known$type, "matrix") &&
      mi_setup$family %in%
        c(
          "bernoulli",
          "ordinal",
          "categorical",
          "beta",
          "zero_one_beta",
          "beta_binomial",
          "poisson",
          "nbinom2",
          "truncated_nbinom2",
          "lognormal",
          "gamma",
          "tweedie"
        )
  ) {
    cli::cli_abort(c(
      "Non-Gaussian {.fn mi} predictor models are not implemented with dense known sampling covariance matrices.",
      "i" = "Use diagonal known variances, complete the non-Gaussian predictor, or fit a supported Gaussian {.fn mi} predictor model."
    ))
  }

  missing_predictor <- drm_build_gaussian_missing_predictor_model(
    mi_setup,
    data_model,
    env = env
  )
  if (include_missing_predictor) {
    missing_response_value <- if (is.null(missing_predictor$response_value)) {
      missing_predictor$x
    } else {
      missing_predictor$response_value
    }
    if (!missing_predictor$model_column %in% names(mf_mu)) {
      cli::cli_abort(
        "Internal {.fn mi} model-frame error: missing predictor column was not retained."
      )
    }
    mf_mu[[missing_predictor$model_column]] <- missing_response_value
  }

  terms_mu <- stats::delete.response(stats::terms(mf_mu))
  X_mu <- drm_fixed_effect_matrix(terms_mu, mf_mu, sparse = sparse_mu)
  if (include_missing_predictor) {
    if (missing_predictor$family %in% c("ordinal", "categorical")) {
      missing_predictor <- drm_missing_predictor_state_design(
        missing_predictor,
        mf_mu,
        terms_mu,
        X_mu
      )
    } else {
      missing_predictor$mu_col <- match(
        missing_predictor$model_column,
        colnames(X_mu)
      )
      if (is.na(missing_predictor$mu_col)) {
        cli::cli_abort(
          "Internal {.fn mi} design-matrix error: missing predictor coefficient column was not found."
        )
      }
    }
  }
  X_sigma <- stats::model.matrix(stats::terms(mf_sigma), mf_sigma)
  if (sparse_mu) {
    validate_sparse_fixed_gaussian_design(X_sigma)
  }
  gaussian_aggregation <- if (aggregate_gaussian) {
    drm_gaussian_aggregation(
      y = y,
      X_mu = X_mu,
      X_sigma = X_sigma,
      weights = weights_model
    )
  } else {
    empty_gaussian_aggregation()
  }
  re_mu_registry <- build_random_mu_structure(mu_re$terms, data_model)
  re_mu <- build_random_mu_structure(active_mu_terms, data_model)
  re_sigma <- build_random_sigma_structure(sigma_re$terms, data_model)
  re_mu_sigma <- build_mu_sigma_random_covariance(re_mu, re_sigma)
  re_cov_blocks <- build_labelled_covariance_block_registry(
    re_mu,
    re_sigma,
    re_mu_sigma,
    re_mu_full = re_mu_registry,
    re_mu_full_terms = mu_re$terms
  )
  sd_mu <- build_sd_mu_structure(
    sd_mu_entries,
    sd_mu_targets,
    re_mu,
    data_model
  )
  phylo_mu <- build_structured_mu_structure(structured_term, data_model, env)
  sd_phylo <- build_sd_phylo_structure(
    sd_phylo_entries,
    sd_phylo_targets,
    phylo_mu,
    data_model
  )

  if (length(y) != nrow(X_sigma)) {
    cli::cli_abort(
      "Internal model-frame mismatch between {.code mu} and {.code sigma}."
    )
  }

  if (length(y) == 0L) {
    cli::cli_abort(
      "No complete observations remain after applying model and known-variance missingness rules."
    )
  }

  start <- gaussian_ls_start(
    y,
    X_mu,
    X_sigma,
    V_known$diag,
    re_mu,
    re_sigma,
    sd_mu,
    re_mu_sigma,
    sd_phylo,
    re_cov_blocks,
    observed_y = observed_y
  )
  start <- c(start, gaussian_ls_dummy_start(phylo_mu, y = y[observed_y]))
  if (include_missing_predictor) {
    start$beta_mi <- missing_predictor$beta_start
    start$log_sigma_mi <- missing_predictor$log_sigma_start
    start$x_miss <- missing_predictor$x_miss_start
    start$u_mi_group <- missing_predictor$u_group_start
    start$log_sd_mi_group <- missing_predictor$log_sd_group_start
    start$u_mi_struct <- missing_predictor$u_structured_start
    start$log_sd_mi_struct <- missing_predictor$log_sd_structured_start
    if (identical(missing_predictor$family, "ordinal")) {
      start$theta_ord <- missing_predictor$theta_start
    }
    if (identical(missing_predictor$family, "zero_one_beta")) {
      start$beta_zoi <- missing_predictor$zoi_start
      start$beta_coi <- missing_predictor$coi_start
    }
  }
  predictor_metadata <- drm_missing_predictor_metadata(
    missing_predictor,
    original_row = which(keep)
  )
  missing_data <- new_drm_missing_data(
    control = missing,
    original_row = which(keep),
    model_row = seq_along(y),
    observed_y = observed_y,
    response_sentinel = response_sentinel,
    predictors = predictor_metadata,
    version = if (include_missing_predictor) {
      if (identical(missing_predictor$family, "bernoulli")) {
        "MD6a"
      } else if (identical(missing_predictor$family, "ordinal")) {
        "MD6b"
      } else if (identical(missing_predictor$family, "categorical")) {
        "MD6c"
      } else if (identical(missing_predictor$family, "beta")) {
        "MD7a"
      } else if (identical(missing_predictor$family, "poisson")) {
        "MD7b"
      } else if (identical(missing_predictor$family, "nbinom2")) {
        "MD7c"
      } else if (identical(missing_predictor$family, "zero_one_beta")) {
        "MD7d"
      } else if (identical(missing_predictor$family, "truncated_nbinom2")) {
        "MD7e"
      } else if (identical(missing_predictor$family, "beta_binomial")) {
        "MD7f"
      } else if (identical(missing_predictor$family, "lognormal")) {
        "MD8a"
      } else if (identical(missing_predictor$family, "gamma")) {
        "MD8b"
      } else if (identical(missing_predictor$family, "tweedie")) {
        "MD8c"
      } else if (isTRUE(missing_predictor$structured$enabled)) {
        "MD4"
      } else if (isTRUE(missing_predictor$random$enabled)) {
        "MD3b"
      } else {
        "MD3a"
      }
    } else {
      "MD1"
    }
  )

  spec <- list(
    model_type = "gaussian",
    y = as.numeric(y),
    weights = weights_model,
    V_known = V_known$V,
    V_known_diag = V_known$diag,
    V_known_type = V_known$type,
    has_known_v = !is.null(meta$V),
    X = c(
      list(mu = X_mu, sigma = X_sigma),
      sd_mu$X_list,
      sd_phylo$X_list
    ),
    terms = c(
      list(
        mu = terms_mu,
        sigma = stats::terms(mf_sigma)
      ),
      sd_mu$terms_list,
      sd_phylo$terms_list
    ),
    model_frame = c(
      list(mu = mf_mu, sigma = mf_sigma),
      sd_mu$model_frame_list,
      sd_phylo$model_frame_list
    ),
    random = list(
      mu = re_mu,
      sigma = re_sigma,
      mu_sigma = re_mu_sigma,
      covariance_blocks = re_cov_blocks
    ),
    aggregation = list(gaussian = gaussian_aggregation),
    random_scale = list(mu = sd_mu, phylo = sd_phylo),
    structured = list(phylo_mu = phylo_mu),
    missing_predictor = missing_predictor,
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = c("mu", "sigma", sd_mu$dpars, sd_phylo$dpars),
    start = start,
    map = {
      map <- gaussian_ls_map(
        re_mu,
        re_sigma,
        sd_mu,
        phylo_mu,
        re_mu_sigma,
        sd_phylo
      )
      if (
        include_missing_predictor &&
          identical(missing_predictor$family, "ordinal")
      ) {
        map$theta_ord <- NULL
      }
      map
    },
    random_names = c(
      if (re_mu$n_re > 0L) "u_mu",
      if (re_sigma$n_re > 0L) "u_sigma",
      if (re_cov_blocks$n_qgt2_re > 0L) "u_re_cov",
      if (isTRUE(phylo_mu$has)) "u_phylo",
      if (
        include_missing_predictor &&
          identical(missing_predictor$family, "gaussian")
      ) {
        "x_miss"
      },
      if (
        include_missing_predictor && isTRUE(missing_predictor$random$enabled)
      ) {
        "u_mi_group"
      },
      if (
        include_missing_predictor &&
          isTRUE(missing_predictor$structured$enabled)
      ) {
        "u_mi_struct"
      }
    ),
    sparse_fixed = list(mu = sparse_mu)
  )
  spec$missing_data <- missing_data
  check_weights_known_covariance(spec)
  spec$tmb_data <- add_covariance_block_tmb_data(
    make_tmb_data(spec),
    spec
  )
  spec$nobs <- spec$missing_data$counts$likelihood_rows
  spec
}

validate_sparse_fixed_gaussian <- function(
  meta,
  mu_phylo,
  mu_phylo_interaction = list(term = NULL),
  mu_spatial,
  mu_animal,
  mu_relmat,
  mu_re,
  sigma_re,
  sd_mu_entries,
  sd_phylo_entries,
  sigma_entry
) {
  if (!is.null(meta$V)) {
    cli::cli_abort(c(
      "Sparse fixed-effect matrices are not implemented with known sampling covariance yet.",
      "i" = "Refit without {.code meta_V()} or set {.code sparse_fixed = FALSE}."
    ))
  }
  structured_terms <- list(
    mu_phylo$term,
    mu_phylo_interaction$term,
    mu_spatial$term,
    mu_animal$term,
    mu_relmat$term
  )
  if (any(!vapply(structured_terms, is.null, logical(1)))) {
    cli::cli_abort(c(
      "Sparse fixed-effect matrices are not implemented with structured random effects yet.",
      "i" = "Fit the phylogenetic, spatial, animal, or relatedness model with dense fixed-effect matrices in this phase."
    ))
  }
  if (length(mu_re$terms) > 0L || length(sigma_re$terms) > 0L) {
    cli::cli_abort(c(
      "Sparse fixed-effect matrices are not implemented with ordinary random effects yet.",
      "i" = "Use a fixed-effect Gaussian location model first, or set {.code sparse_fixed = FALSE}."
    ))
  }
  if (length(sd_mu_entries) > 0L || length(sd_phylo_entries) > 0L) {
    cli::cli_abort(c(
      "Sparse fixed-effect matrices are not implemented with direct random-effect SD models yet.",
      "i" = "Use the dense path for {.code sd()} and {.code sd_phylo()} models in this phase."
    ))
  }
  if (!is_intercept_one(sigma_entry$rhs)) {
    cli::cli_abort(c(
      "Sparse fixed-effect matrices currently require intercept-only {.code sigma}.",
      "i" = "Use {.code sigma = ~ 1} or set {.code sparse_fixed = FALSE}."
    ))
  }
}

validate_sparse_fixed_gaussian_design <- function(X_sigma) {
  if (ncol(X_sigma) != 1L || !identical(colnames(X_sigma), "(Intercept)")) {
    cli::cli_abort(c(
      "Sparse fixed-effect matrices currently require intercept-only {.code sigma}.",
      "i" = "Use {.code sigma = ~ 1} or set {.code sparse_fixed = FALSE}."
    ))
  }
}

drm_build_student_ls_spec <- function(
  formula,
  data,
  env = parent.frame(),
  weights = NULL
) {
  entries <- formula$entries
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  is_sd_dpar <- startsWith(dpars, "sd(")

  unsupported <- setdiff(dpars[!is_sd_dpar], c("mu", "sigma", "nu"))
  if (length(unsupported) > 0L) {
    cli::cli_abort(c(
      "Student-t models only support {.code mu}, {.code sigma}, and {.code nu}.",
      "x" = "Unsupported parameter{?s}: {.val {unsupported}}."
    ))
  }
  if (any(is_sd_dpar)) {
    cli::cli_abort(c(
      "Random-effect scale formulae are not implemented for {.fn student} models yet.",
      "i" = "Start with fixed-effect Student-t formulas such as {.code bf(y ~ x, sigma ~ z, nu ~ 1)}."
    ))
  }
  if (sum(dpars == "mu") != 1L) {
    cli::cli_abort("A Student-t model requires exactly one location formula.")
  }
  for (optional in c("sigma", "nu")) {
    if (sum(dpars == optional) > 1L) {
      cli::cli_abort(
        "A Student-t model can have at most one {.code {optional}} formula."
      )
    }
  }

  mu_entry <- entries[[which(dpars == "mu")]]
  sigma_entry <- if (any(dpars == "sigma")) {
    entries[[which(dpars == "sigma")]]
  } else {
    default_dpar_entry("sigma", quote(1))
  }
  nu_entry <- if (any(dpars == "nu")) {
    entries[[which(dpars == "nu")]]
  } else {
    default_dpar_entry("nu", quote(1))
  }

  if (is.na(mu_entry$response)) {
    cli::cli_abort(
      "The {.code mu} formula must include a response on the left-hand side."
    )
  }
  if (is_mvbind_lhs(mu_entry$lhs)) {
    cli::cli_abort(c(
      "{.fn mvbind} shorthand is only available for two-response Gaussian models.",
      "x" = "Student-t models currently support one response."
    ))
  }

  meta <- extract_meta_known_v(mu_entry$rhs)
  if (!is.null(meta$V)) {
    cli::cli_abort(c(
      "{.fn meta_V} is not implemented for {.fn student} models yet.",
      "i" = "Use {.code family = gaussian()} for Gaussian meta-analysis with known sampling covariance."
    ))
  }
  mu_entry$rhs <- meta$rhs

  mu_spatial <- extract_gaussian_mu_known_term(mu_entry, "spatial")
  mu_entry$rhs <- mu_spatial$rhs
  validate_student_spatial_mu_structured_term(mu_spatial$term)
  nu_phylo <- extract_gaussian_mu_phylo_term(nu_entry, dpar = "nu")
  nu_entry$rhs <- nu_phylo$rhs
  if (!is.null(nu_phylo$term)) {
    nu_phylo$term$dpars <- "nu"
  }
  validate_student_phylo_nu_structured_term(nu_phylo$term)
  if (!is.null(mu_spatial$term) && !is.null(nu_phylo$term)) {
    cli::cli_abort(c(
      "{.fn student} structured effects currently admit only one endpoint-specific route at a time.",
      "x" = "The formula contains both {.code mu} spatial and {.code nu} phylo structured terms.",
      "i" = "Fit the Student location or shape structured recovery slice separately until location-shape recovery evidence exists."
    ))
  }
  mu_re <- extract_random_mu_terms(mu_entry$rhs, mu_entry$dpar)
  mu_entry$rhs <- mu_re$rhs
  validate_student_mu_random_terms(mu_re$terms)
  sigma_re <- extract_random_sigma_terms(sigma_entry$rhs, "sigma")
  sigma_entry$rhs <- sigma_re$rhs
  validate_student_sigma_random_terms(sigma_re$terms)

  for (entry in list(mu_entry, sigma_entry, nu_entry)) {
    drm_reject_phase1_terms(entry$rhs, entry$dpar)
  }

  f_mu <- drm_entry_formula(mu_entry, response = TRUE)
  f_sigma <- drm_entry_formula(sigma_entry, response = FALSE)
  f_nu <- drm_entry_formula(nu_entry, response = FALSE)

  vars <- unique(c(
    all.vars(f_mu),
    all.vars(f_sigma),
    all.vars(f_nu),
    random_effect_vars(mu_re$terms),
    structured_mu_vars(mu_spatial$term),
    structured_mu_vars(nu_phylo$term)
  ))
  if (length(vars) > 0L) {
    keep <- stats::complete.cases(data[, vars, drop = FALSE])
  } else {
    keep <- rep(TRUE, nrow(data))
  }
  data_model <- data[keep, , drop = FALSE]
  weights_model <- subset_likelihood_weights(
    weights,
    keep,
    nrow(data),
    sum(keep)
  )

  mf_mu <- stats::model.frame(
    f_mu,
    data = data_model,
    na.action = stats::na.omit
  )
  mf_sigma <- stats::model.frame(
    f_sigma,
    data = data_model,
    na.action = stats::na.omit
  )
  mf_nu <- stats::model.frame(
    f_nu,
    data = data_model,
    na.action = stats::na.omit
  )
  y <- stats::model.response(mf_mu)

  X_mu <- stats::model.matrix(
    stats::delete.response(stats::terms(mf_mu)),
    mf_mu
  )
  X_sigma <- stats::model.matrix(stats::terms(mf_sigma), mf_sigma)
  X_nu <- stats::model.matrix(stats::terms(mf_nu), mf_nu)

  if (length(y) == 0L) {
    cli::cli_abort(
      "No complete observations remain after applying model missingness rules."
    )
  }
  if (!all(c(nrow(X_sigma), nrow(X_nu)) == length(y))) {
    cli::cli_abort("Internal model-frame mismatch in Student-t model.")
  }
  re_mu <- build_random_mu_structure(mu_re$terms, data_model)
  student_structured_term <- if (!is.null(nu_phylo$term)) {
    nu_phylo$term
  } else {
    mu_spatial$term
  }
  phylo_mu <- build_structured_mu_structure(
    student_structured_term,
    data_model,
    env
  )

  spec <- list(
    model_type = "student",
    y = as.numeric(y),
    weights = weights_model,
    V_known = rep(0, length(y)),
    V_known_diag = rep(0, length(y)),
    V_known_type = "none",
    has_known_v = FALSE,
    X = list(mu = X_mu, sigma = X_sigma, nu = X_nu),
    terms = list(
      mu = stats::delete.response(stats::terms(mf_mu)),
      sigma = stats::terms(mf_sigma),
      nu = stats::terms(mf_nu)
    ),
    model_frame = list(mu = mf_mu, sigma = mf_sigma, nu = mf_nu),
    random = list(
      mu = re_mu,
      sigma = empty_random_sigma_structure(nrow(data_model))
    ),
    random_scale = list(mu = empty_sd_mu_structure(re_mu$n_re)),
    structured = list(phylo_mu = phylo_mu),
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = c("mu", "sigma", "nu"),
    start = student_ls_start(
      y,
      X_mu,
      X_sigma,
      X_nu,
      re_mu = re_mu,
      phylo_mu = phylo_mu
    ),
    map = student_ls_map(re_mu, phylo_mu),
    random_names = c(
      if (re_mu$n_re > 0L) "u_mu",
      if (isTRUE(phylo_mu$has)) "u_phylo"
    )
  )
  spec$tmb_data <- add_covariance_block_tmb_data(
    make_tmb_data(spec),
    spec
  )
  spec$nobs <- length(spec$y)
  spec
}

drm_build_skew_normal_ls_spec <- function(
  formula,
  data,
  env = parent.frame(),
  weights = NULL
) {
  entries <- formula$entries
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  is_sd_dpar <- startsWith(dpars, "sd(")

  unsupported <- setdiff(dpars[!is_sd_dpar], c("mu", "sigma", "nu"))
  if (length(unsupported) > 0L) {
    cli::cli_abort(c(
      "{.fn skew_normal} models only support {.code mu}, {.code sigma}, and {.code nu}.",
      "x" = "Unsupported parameter{?s}: {.val {unsupported}}.",
      "i" = "Use canonical residual-shape syntax such as {.code bf(y ~ x, sigma ~ z, nu ~ w)}; aliases such as {.code skew ~ w} or latent {.code skew(id) ~ w} remain planned."
    ))
  }
  if (any(is_sd_dpar)) {
    cli::cli_abort(c(
      "Random-effect scale formulae are not implemented for {.fn skew_normal} models.",
      "i" = "Start with fixed-effect skew-normal formulas such as {.code bf(y ~ x, sigma ~ z, nu ~ w)}."
    ))
  }
  mu_responses <- vapply(
    entries[dpars == "mu"],
    function(entry) {
      if (is.na(entry$response)) {
        return(NA_character_)
      }
      entry$response
    },
    character(1L)
  )
  unsupported_skew_response <- mu_responses[
    !is.na(mu_responses) & grepl("^skew\\(", mu_responses)
  ]
  if (length(unsupported_skew_response) > 0L) {
    cli::cli_abort(c(
      "{.fn skew_normal} models use {.code nu} for fixed-effect residual slant.",
      "x" = "Latent skewness syntax such as {.code {unsupported_skew_response[[1L]]} ~ ...} is not implemented.",
      "i" = "Use {.code bf(y ~ x, sigma ~ z, nu ~ w)} for the fixed-effect first slice."
    ))
  }
  if (sum(dpars == "mu") != 1L) {
    cli::cli_abort(
      "A {.fn skew_normal} model requires exactly one location formula."
    )
  }
  for (optional in c("sigma", "nu")) {
    if (sum(dpars == optional) > 1L) {
      cli::cli_abort(
        "A {.fn skew_normal} model can have at most one {.code {optional}} formula."
      )
    }
  }

  mu_entry <- entries[[which(dpars == "mu")]]
  sigma_entry <- if (any(dpars == "sigma")) {
    entries[[which(dpars == "sigma")]]
  } else {
    default_dpar_entry("sigma", quote(1))
  }
  nu_entry <- if (any(dpars == "nu")) {
    entries[[which(dpars == "nu")]]
  } else {
    default_dpar_entry("nu", quote(1))
  }

  if (is.na(mu_entry$response)) {
    cli::cli_abort(
      "The {.code mu} formula must include a response on the left-hand side."
    )
  }
  if (is_mvbind_lhs(mu_entry$lhs)) {
    cli::cli_abort(c(
      "{.fn mvbind} shorthand is only available for two-response Gaussian models.",
      "x" = "{.fn skew_normal} models currently support one continuous response."
    ))
  }
  if (is_cbind_lhs(mu_entry$lhs)) {
    cli::cli_abort(c(
      "{.fn skew_normal} models require a single continuous response.",
      "x" = "Denominator syntax such as {.code cbind(successes, failures)} belongs to denominator-aware count or proportion families."
    ))
  }
  if (!is.na(nu_entry$response)) {
    cli::cli_abort(
      "The {.code nu} formula must be one-sided, for example {.code nu ~ w}."
    )
  }

  meta <- extract_meta_known_v(mu_entry$rhs)
  if (!is.null(meta$V)) {
    cli::cli_abort(c(
      "{.fn meta_V} is not implemented for {.fn skew_normal} models.",
      "i" = "Use {.code family = gaussian()} for Gaussian meta-analysis with known sampling covariance."
    ))
  }
  mu_entry$rhs <- meta$rhs

  mu_re <- extract_random_mu_terms(mu_entry$rhs, mu_entry$dpar)
  mu_entry$rhs <- mu_re$rhs
  validate_skew_normal_random_terms(mu_re$terms, "mu")
  sigma_re <- extract_random_sigma_terms(sigma_entry$rhs, "sigma")
  sigma_entry$rhs <- sigma_re$rhs
  validate_skew_normal_random_terms(sigma_re$terms, "sigma")
  nu_re <- extract_random_mu_terms(nu_entry$rhs, "nu")
  nu_entry$rhs <- nu_re$rhs
  validate_skew_normal_random_terms(nu_re$terms, "nu")

  for (entry in list(mu_entry, sigma_entry, nu_entry)) {
    drm_reject_phase1_terms(entry$rhs, entry$dpar)
  }

  f_mu <- drm_entry_formula(mu_entry, response = TRUE)
  f_sigma <- drm_entry_formula(sigma_entry, response = FALSE)
  f_nu <- drm_entry_formula(nu_entry, response = FALSE)

  vars <- unique(c(all.vars(f_mu), all.vars(f_sigma), all.vars(f_nu)))
  if (length(vars) > 0L) {
    keep <- stats::complete.cases(data[, vars, drop = FALSE])
  } else {
    keep <- rep(TRUE, nrow(data))
  }
  data_model <- data[keep, , drop = FALSE]
  weights_model <- subset_likelihood_weights(
    weights,
    keep,
    nrow(data),
    sum(keep)
  )

  mf_mu <- stats::model.frame(
    f_mu,
    data = data_model,
    na.action = stats::na.omit
  )
  mf_sigma <- stats::model.frame(
    f_sigma,
    data = data_model,
    na.action = stats::na.omit
  )
  mf_nu <- stats::model.frame(
    f_nu,
    data = data_model,
    na.action = stats::na.omit
  )
  y <- stats::model.response(mf_mu)

  if (length(y) == 0L) {
    cli::cli_abort(
      "No complete observations remain after applying model missingness rules."
    )
  }
  if (!is.null(dim(y))) {
    cli::cli_abort(
      "{.fn skew_normal} models require a single continuous response."
    )
  }
  if (!all(is.finite(y))) {
    cli::cli_abort(c(
      "{.fn skew_normal} models require finite continuous response values.",
      "x" = "The response {.val {mu_entry$response}} contains non-finite values after missing-row filtering."
    ))
  }

  X_mu <- stats::model.matrix(
    stats::delete.response(stats::terms(mf_mu)),
    mf_mu
  )
  X_sigma <- stats::model.matrix(stats::terms(mf_sigma), mf_sigma)
  X_nu <- stats::model.matrix(stats::terms(mf_nu), mf_nu)

  if (!all(c(nrow(X_sigma), nrow(X_nu)) == length(y))) {
    cli::cli_abort("Internal model-frame mismatch in skew-normal model.")
  }

  spec <- list(
    model_type = "skew_normal",
    y = as.numeric(y),
    weights = weights_model,
    V_known = rep(0, length(y)),
    V_known_diag = rep(0, length(y)),
    V_known_type = "none",
    has_known_v = FALSE,
    X = list(mu = X_mu, sigma = X_sigma, nu = X_nu),
    terms = list(
      mu = stats::delete.response(stats::terms(mf_mu)),
      sigma = stats::terms(mf_sigma),
      nu = stats::terms(mf_nu)
    ),
    model_frame = list(mu = mf_mu, sigma = mf_sigma, nu = mf_nu),
    random = list(
      mu = empty_random_mu_structure(nrow(data_model)),
      sigma = empty_random_sigma_structure(nrow(data_model))
    ),
    random_scale = list(
      mu = empty_sd_mu_structure(0L),
      phylo = empty_sd_phylo_structure()
    ),
    structured = list(phylo_mu = empty_phylo_mu_structure()),
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = c("mu", "sigma", "nu"),
    start = skew_normal_ls_start(y, X_mu, X_sigma, X_nu),
    map = skew_normal_ls_map(),
    random_names = NULL
  )
  spec$tmb_data <- add_covariance_block_tmb_data(
    make_tmb_data(spec),
    spec
  )
  spec$nobs <- length(spec$y)
  spec
}

drm_build_lognormal_ls_spec <- function(
  formula,
  data,
  env = parent.frame(),
  weights = NULL
) {
  entries <- formula$entries
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  is_sd_dpar <- startsWith(dpars, "sd(")

  unsupported <- setdiff(dpars[!is_sd_dpar], c("mu", "sigma"))
  if (length(unsupported) > 0L) {
    cli::cli_abort(c(
      "Lognormal models only support {.code mu} and {.code sigma}.",
      "x" = "Unsupported parameter{?s}: {.val {unsupported}}."
    ))
  }
  if (any(is_sd_dpar)) {
    cli::cli_abort(c(
      "Random-effect scale formulae are not implemented for {.fn lognormal} models yet.",
      "i" = "Start with fixed-effect lognormal formulas such as {.code bf(y ~ x, sigma ~ z)}."
    ))
  }
  if (sum(dpars == "mu") != 1L) {
    cli::cli_abort("A lognormal model requires exactly one location formula.")
  }
  if (sum(dpars == "sigma") > 1L) {
    cli::cli_abort(
      "A lognormal model can have at most one residual {.code sigma} formula."
    )
  }

  mu_entry <- entries[[which(dpars == "mu")]]
  sigma_entry <- if (any(dpars == "sigma")) {
    entries[[which(dpars == "sigma")]]
  } else {
    default_dpar_entry("sigma", quote(1))
  }

  if (is.na(mu_entry$response)) {
    cli::cli_abort(
      "The {.code mu} formula must include a response on the left-hand side."
    )
  }
  if (is_mvbind_lhs(mu_entry$lhs)) {
    cli::cli_abort(c(
      "{.fn mvbind} shorthand is only available for two-response Gaussian models.",
      "x" = "Lognormal models currently support one positive response."
    ))
  }

  meta <- extract_meta_known_v(mu_entry$rhs)
  if (!is.null(meta$V)) {
    cli::cli_abort(c(
      "{.fn meta_V} is not implemented for {.fn lognormal} models yet.",
      "i" = "Use {.code family = gaussian()} for Gaussian meta-analysis with known sampling covariance."
    ))
  }
  mu_entry$rhs <- meta$rhs

  mu_re <- extract_random_mu_terms(mu_entry$rhs, mu_entry$dpar)
  mu_entry$rhs <- mu_re$rhs
  validate_positive_continuous_mu_random_terms(mu_re$terms, "{.fn lognormal}")
  sigma_re <- extract_random_sigma_terms(sigma_entry$rhs, "sigma")
  sigma_entry$rhs <- sigma_re$rhs
  validate_positive_continuous_sigma_random_terms(
    sigma_re$terms,
    "{.fn lognormal}"
  )

  for (entry in list(mu_entry, sigma_entry)) {
    drm_reject_phase1_terms(entry$rhs, entry$dpar)
  }

  f_mu <- drm_entry_formula(mu_entry, response = TRUE)
  f_sigma <- drm_entry_formula(sigma_entry, response = FALSE)

  vars <- unique(c(
    all.vars(f_mu),
    all.vars(f_sigma),
    random_effect_vars(mu_re$terms)
  ))
  if (length(vars) > 0L) {
    keep <- stats::complete.cases(data[, vars, drop = FALSE])
  } else {
    keep <- rep(TRUE, nrow(data))
  }
  data_model <- data[keep, , drop = FALSE]
  weights_model <- subset_likelihood_weights(
    weights,
    keep,
    nrow(data),
    sum(keep)
  )

  mf_mu <- stats::model.frame(
    f_mu,
    data = data_model,
    na.action = stats::na.omit
  )
  mf_sigma <- stats::model.frame(
    f_sigma,
    data = data_model,
    na.action = stats::na.omit
  )
  y <- stats::model.response(mf_mu)

  if (length(y) == 0L) {
    cli::cli_abort(
      "No complete observations remain after applying model missingness rules."
    )
  }
  if (!all(is.finite(y)) || any(y <= 0)) {
    cli::cli_abort(c(
      "Lognormal models require positive finite response values.",
      "x" = "The response {.val {mu_entry$response}} contains zero, negative, or non-finite values after missing-row filtering."
    ))
  }

  X_mu <- stats::model.matrix(
    stats::delete.response(stats::terms(mf_mu)),
    mf_mu
  )
  X_sigma <- stats::model.matrix(stats::terms(mf_sigma), mf_sigma)

  if (nrow(X_sigma) != length(y)) {
    cli::cli_abort("Internal model-frame mismatch in lognormal model.")
  }
  re_mu <- build_random_mu_structure(mu_re$terms, data_model)

  spec <- list(
    model_type = "lognormal",
    y = as.numeric(y),
    weights = weights_model,
    V_known = rep(0, length(y)),
    V_known_diag = rep(0, length(y)),
    V_known_type = "none",
    has_known_v = FALSE,
    X = list(mu = X_mu, sigma = X_sigma),
    terms = list(
      mu = stats::delete.response(stats::terms(mf_mu)),
      sigma = stats::terms(mf_sigma)
    ),
    model_frame = list(mu = mf_mu, sigma = mf_sigma),
    random = list(
      mu = re_mu,
      sigma = empty_random_sigma_structure(nrow(data_model))
    ),
    random_scale = list(mu = empty_sd_mu_structure(re_mu$n_re)),
    structured = list(phylo_mu = empty_phylo_mu_structure()),
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = c("mu", "sigma"),
    start = lognormal_ls_start(y, X_mu, X_sigma, re_mu = re_mu),
    map = lognormal_ls_map(re_mu),
    random_names = if (re_mu$n_re > 0L) "u_mu" else NULL
  )
  spec$tmb_data <- add_covariance_block_tmb_data(
    make_tmb_data(spec),
    spec
  )
  spec$nobs <- length(spec$y)
  spec
}

drm_build_gamma_ls_spec <- function(
  formula,
  data,
  env = parent.frame(),
  weights = NULL
) {
  entries <- formula$entries
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  is_sd_dpar <- startsWith(dpars, "sd(")

  unsupported <- setdiff(dpars[!is_sd_dpar], c("mu", "sigma"))
  if (length(unsupported) > 0L) {
    cli::cli_abort(c(
      "Gamma models only support {.code mu} and {.code sigma}.",
      "x" = "Unsupported parameter{?s}: {.val {unsupported}}."
    ))
  }
  if (any(is_sd_dpar)) {
    cli::cli_abort(c(
      "Random-effect scale formulae are not implemented for {.fn Gamma} models yet.",
      "i" = "Start with fixed-effect Gamma formulas such as {.code bf(y ~ x, sigma ~ z)}."
    ))
  }
  if (sum(dpars == "mu") != 1L) {
    cli::cli_abort("A Gamma model requires exactly one location formula.")
  }
  if (sum(dpars == "sigma") > 1L) {
    cli::cli_abort(
      "A Gamma model can have at most one residual {.code sigma} formula."
    )
  }

  mu_entry <- entries[[which(dpars == "mu")]]
  sigma_entry <- if (any(dpars == "sigma")) {
    entries[[which(dpars == "sigma")]]
  } else {
    default_dpar_entry("sigma", quote(1))
  }

  if (is.na(mu_entry$response)) {
    cli::cli_abort(
      "The {.code mu} formula must include a response on the left-hand side."
    )
  }
  if (is_mvbind_lhs(mu_entry$lhs)) {
    cli::cli_abort(c(
      "{.fn mvbind} shorthand is only available for two-response Gaussian models.",
      "x" = "Gamma models currently support one positive response."
    ))
  }

  meta <- extract_meta_known_v(mu_entry$rhs)
  if (!is.null(meta$V)) {
    cli::cli_abort(c(
      "{.fn meta_V} is not implemented for {.fn Gamma} models yet.",
      "i" = "Use {.code family = gaussian()} for Gaussian meta-analysis with known sampling covariance."
    ))
  }
  mu_entry$rhs <- meta$rhs

  mu_relmat <- extract_gaussian_mu_known_term(mu_entry, "relmat")
  mu_entry$rhs <- mu_relmat$rhs
  validate_gamma_relmat_mu_structured_term(mu_relmat$term)
  mu_re <- extract_random_mu_terms(mu_entry$rhs, mu_entry$dpar)
  mu_entry$rhs <- mu_re$rhs
  validate_positive_continuous_mu_random_terms(mu_re$terms, "{.fn Gamma}")
  sigma_re <- extract_random_sigma_terms(sigma_entry$rhs, "sigma")
  sigma_entry$rhs <- sigma_re$rhs
  validate_positive_continuous_sigma_random_terms(
    sigma_re$terms,
    "{.fn Gamma}"
  )

  for (entry in list(mu_entry, sigma_entry)) {
    drm_reject_phase1_terms(entry$rhs, entry$dpar)
  }

  f_mu <- drm_entry_formula(mu_entry, response = TRUE)
  f_sigma <- drm_entry_formula(sigma_entry, response = FALSE)

  vars <- unique(c(
    all.vars(f_mu),
    all.vars(f_sigma),
    random_effect_vars(mu_re$terms),
    structured_mu_vars(mu_relmat$term)
  ))
  if (length(vars) > 0L) {
    keep <- stats::complete.cases(data[, vars, drop = FALSE])
  } else {
    keep <- rep(TRUE, nrow(data))
  }
  data_model <- data[keep, , drop = FALSE]
  weights_model <- subset_likelihood_weights(
    weights,
    keep,
    nrow(data),
    sum(keep)
  )

  mf_mu <- stats::model.frame(
    f_mu,
    data = data_model,
    na.action = stats::na.omit
  )
  mf_sigma <- stats::model.frame(
    f_sigma,
    data = data_model,
    na.action = stats::na.omit
  )
  y <- stats::model.response(mf_mu)

  if (length(y) == 0L) {
    cli::cli_abort(
      "No complete observations remain after applying model missingness rules."
    )
  }
  if (!all(is.finite(y)) || any(y <= 0)) {
    cli::cli_abort(c(
      "Gamma models require positive finite response values.",
      "x" = "The response {.val {mu_entry$response}} contains zero, negative, or non-finite values after missing-row filtering."
    ))
  }

  X_mu <- stats::model.matrix(
    stats::delete.response(stats::terms(mf_mu)),
    mf_mu
  )
  X_sigma <- stats::model.matrix(stats::terms(mf_sigma), mf_sigma)

  if (nrow(X_sigma) != length(y)) {
    cli::cli_abort("Internal model-frame mismatch in Gamma model.")
  }
  re_mu <- build_random_mu_structure(mu_re$terms, data_model)
  phylo_mu <- build_structured_mu_structure(mu_relmat$term, data_model, env)

  spec <- list(
    model_type = "gamma",
    y = as.numeric(y),
    weights = weights_model,
    V_known = rep(0, length(y)),
    V_known_diag = rep(0, length(y)),
    V_known_type = "none",
    has_known_v = FALSE,
    X = list(mu = X_mu, sigma = X_sigma),
    terms = list(
      mu = stats::delete.response(stats::terms(mf_mu)),
      sigma = stats::terms(mf_sigma)
    ),
    model_frame = list(mu = mf_mu, sigma = mf_sigma),
    random = list(
      mu = re_mu,
      sigma = empty_random_sigma_structure(nrow(data_model))
    ),
    random_scale = list(mu = empty_sd_mu_structure(re_mu$n_re)),
    structured = list(phylo_mu = phylo_mu),
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = c("mu", "sigma"),
    start = gamma_ls_start(
      y,
      X_mu,
      X_sigma,
      re_mu = re_mu,
      phylo_mu = phylo_mu
    ),
    map = gamma_ls_map(re_mu, phylo_mu),
    random_names = c(
      if (re_mu$n_re > 0L) "u_mu",
      if (isTRUE(phylo_mu$has)) "u_phylo"
    )
  )
  spec$tmb_data <- add_covariance_block_tmb_data(
    make_tmb_data(spec),
    spec
  )
  spec$nobs <- length(spec$y)
  spec
}

drm_build_tweedie_ls_spec <- function(
  formula,
  data,
  env = parent.frame(),
  weights = NULL
) {
  entries <- formula$entries
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  is_sd_dpar <- startsWith(dpars, "sd(")

  unsupported <- setdiff(dpars[!is_sd_dpar], c("mu", "sigma", "nu"))
  if (length(unsupported) > 0L) {
    cli::cli_abort(c(
      "{.fn tweedie} models only support {.code mu}, {.code sigma}, and intercept-only {.code nu}.",
      "x" = "Unsupported parameter{?s}: {.val {unsupported}}."
    ))
  }
  if (any(is_sd_dpar)) {
    cli::cli_abort(c(
      "Random-effect scale formulae are not implemented for {.fn tweedie} models.",
      "i" = "Start with fixed-effect Tweedie formulas such as {.code bf(y ~ x, sigma ~ z, nu ~ 1)}."
    ))
  }
  if (sum(dpars == "mu") != 1L) {
    cli::cli_abort(
      "A {.fn tweedie} model requires exactly one location formula."
    )
  }
  for (optional in c("sigma", "nu")) {
    if (sum(dpars == optional) > 1L) {
      cli::cli_abort(
        "A {.fn tweedie} model can have at most one {.code {optional}} formula."
      )
    }
  }

  mu_entry <- entries[[which(dpars == "mu")]]
  sigma_entry <- if (any(dpars == "sigma")) {
    entries[[which(dpars == "sigma")]]
  } else {
    default_dpar_entry("sigma", quote(1))
  }
  nu_entry <- if (any(dpars == "nu")) {
    entries[[which(dpars == "nu")]]
  } else {
    default_dpar_entry("nu", quote(1))
  }

  if (is.na(mu_entry$response)) {
    cli::cli_abort(
      "The {.code mu} formula must include a response on the left-hand side."
    )
  }
  if (is_mvbind_lhs(mu_entry$lhs)) {
    cli::cli_abort(c(
      "{.fn mvbind} shorthand is only available for two-response Gaussian models.",
      "x" = "{.fn tweedie} models currently support one non-negative response."
    ))
  }
  if (is_cbind_lhs(mu_entry$lhs)) {
    cli::cli_abort(c(
      "{.fn tweedie} models require a single non-negative response.",
      "x" = "Denominator syntax such as {.code cbind(successes, failures)} belongs to denominator-aware count or proportion families."
    ))
  }
  if (!is.na(nu_entry$response)) {
    cli::cli_abort(
      "The {.code nu} formula must be one-sided, for example {.code nu ~ 1}."
    )
  }

  meta <- extract_meta_known_v(mu_entry$rhs)
  if (!is.null(meta$V)) {
    cli::cli_abort(c(
      "{.fn meta_V} is not implemented for {.fn tweedie} models.",
      "i" = "Use {.code family = gaussian()} for Gaussian meta-analysis with known sampling covariance."
    ))
  }
  mu_entry$rhs <- meta$rhs

  mu_re <- extract_random_mu_terms(mu_entry$rhs, mu_entry$dpar)
  mu_entry$rhs <- mu_re$rhs
  validate_tweedie_random_terms(mu_re$terms, "mu")
  sigma_re <- extract_random_sigma_terms(sigma_entry$rhs, "sigma")
  sigma_entry$rhs <- sigma_re$rhs
  validate_tweedie_random_terms(sigma_re$terms, "sigma")
  nu_re <- extract_random_mu_terms(nu_entry$rhs, "nu")
  nu_entry$rhs <- nu_re$rhs
  validate_tweedie_random_terms(nu_re$terms, "nu")

  for (entry in list(mu_entry, sigma_entry, nu_entry)) {
    drm_reject_phase1_terms(entry$rhs, entry$dpar)
  }

  f_mu <- drm_entry_formula(mu_entry, response = TRUE)
  f_sigma <- drm_entry_formula(sigma_entry, response = FALSE)
  f_nu <- drm_entry_formula(nu_entry, response = FALSE)

  vars <- unique(c(all.vars(f_mu), all.vars(f_sigma), all.vars(f_nu)))
  if (length(vars) > 0L) {
    keep <- stats::complete.cases(data[, vars, drop = FALSE])
  } else {
    keep <- rep(TRUE, nrow(data))
  }
  data_model <- data[keep, , drop = FALSE]
  weights_model <- subset_likelihood_weights(
    weights,
    keep,
    nrow(data),
    sum(keep)
  )

  mf_mu <- stats::model.frame(
    f_mu,
    data = data_model,
    na.action = stats::na.omit
  )
  mf_sigma <- stats::model.frame(
    f_sigma,
    data = data_model,
    na.action = stats::na.omit
  )
  mf_nu <- stats::model.frame(
    f_nu,
    data = data_model,
    na.action = stats::na.omit
  )
  y <- stats::model.response(mf_mu)

  if (length(y) == 0L) {
    cli::cli_abort(
      "No complete observations remain after applying model missingness rules."
    )
  }
  if (!is.null(dim(y))) {
    cli::cli_abort(
      "{.fn tweedie} models require a single non-negative response."
    )
  }
  if (!all(is.finite(y)) || any(y < 0)) {
    cli::cli_abort(c(
      "{.fn tweedie} models require non-negative finite response values.",
      "x" = "The response {.val {mu_entry$response}} contains negative or non-finite values after missing-row filtering."
    ))
  }

  X_mu <- stats::model.matrix(
    stats::delete.response(stats::terms(mf_mu)),
    mf_mu
  )
  X_sigma <- stats::model.matrix(stats::terms(mf_sigma), mf_sigma)
  X_nu <- stats::model.matrix(stats::terms(mf_nu), mf_nu)

  if (!all(c(nrow(X_sigma), nrow(X_nu)) == length(y))) {
    cli::cli_abort("Internal model-frame mismatch in Tweedie model.")
  }
  if (
    ncol(X_nu) != 1L ||
      !identical(colnames(X_nu), "(Intercept)")
  ) {
    cli::cli_abort(c(
      "{.fn tweedie} currently supports only intercept-only {.code nu ~ 1}.",
      "i" = "Predictor-dependent Tweedie power models are deferred until fixed-effect {.code mu}, {.code sigma}, and constant {.code nu} recovery is stable."
    ))
  }

  spec <- list(
    model_type = "tweedie",
    y = as.numeric(y),
    weights = weights_model,
    V_known = rep(0, length(y)),
    V_known_diag = rep(0, length(y)),
    V_known_type = "none",
    has_known_v = FALSE,
    X = list(mu = X_mu, sigma = X_sigma, nu = X_nu),
    terms = list(
      mu = stats::delete.response(stats::terms(mf_mu)),
      sigma = stats::terms(mf_sigma),
      nu = stats::terms(mf_nu)
    ),
    model_frame = list(mu = mf_mu, sigma = mf_sigma, nu = mf_nu),
    random = list(
      mu = empty_random_mu_structure(nrow(data_model)),
      sigma = empty_random_sigma_structure(nrow(data_model))
    ),
    random_scale = list(
      mu = empty_sd_mu_structure(0L),
      phylo = empty_sd_phylo_structure()
    ),
    structured = list(phylo_mu = empty_phylo_mu_structure()),
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = c("mu", "sigma", "nu"),
    start = tweedie_ls_start(y, X_mu, X_sigma, X_nu),
    map = tweedie_ls_map(),
    random_names = NULL
  )
  spec$tmb_data <- add_covariance_block_tmb_data(
    make_tmb_data(spec),
    spec
  )
  spec$nobs <- length(spec$y)
  spec
}

drm_build_beta_ls_spec <- function(
  formula,
  data,
  env = parent.frame(),
  weights = NULL
) {
  entries <- formula$entries
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  is_sd_dpar <- startsWith(dpars, "sd(")

  unsupported <- setdiff(dpars[!is_sd_dpar], c("mu", "sigma"))
  reject_planned_bounded_inflation(
    entries = entries,
    unsupported = unsupported,
    family_label = "beta()"
  )
  if (length(unsupported) > 0L) {
    cli::cli_abort(c(
      "Beta models only support {.code mu} and {.code sigma}.",
      "x" = "Unsupported parameter{?s}: {.val {unsupported}}."
    ))
  }
  if (any(is_sd_dpar)) {
    cli::cli_abort(c(
      "Random-effect scale formulae are not implemented for {.fn beta} models yet.",
      "i" = "Use beta formulas such as {.code bf(prop ~ x + (1 | id), sigma ~ z)}; group-level scale models need separate recovery tests."
    ))
  }
  if (sum(dpars == "mu") != 1L) {
    cli::cli_abort("A beta model requires exactly one location formula.")
  }
  if (sum(dpars == "sigma") > 1L) {
    cli::cli_abort(
      "A beta model can have at most one scale {.code sigma} formula."
    )
  }

  mu_entry <- entries[[which(dpars == "mu")]]
  sigma_entry <- if (any(dpars == "sigma")) {
    entries[[which(dpars == "sigma")]]
  } else {
    default_dpar_entry("sigma", quote(1))
  }

  if (is.na(mu_entry$response)) {
    cli::cli_abort(
      "The {.code mu} formula must include a response on the left-hand side."
    )
  }
  if (is_mvbind_lhs(mu_entry$lhs)) {
    cli::cli_abort(c(
      "{.fn mvbind} shorthand is only available for two-response Gaussian models.",
      "x" = "Beta models currently support one strict proportion response."
    ))
  }
  if (is_cbind_lhs(mu_entry$lhs)) {
    cli::cli_abort(c(
      "Beta models currently require a single strict proportion response.",
      "x" = "Denominator syntax such as {.code cbind(successes, failures)} is planned for {.fn beta_binomial}, not {.fn beta}."
    ))
  }

  meta <- extract_meta_known_v(mu_entry$rhs)
  if (!is.null(meta$V)) {
    cli::cli_abort(c(
      "{.fn meta_V} is not implemented for {.fn beta} models.",
      "i" = "Use {.code family = gaussian()} for Gaussian meta-analysis with known sampling covariance."
    ))
  }
  mu_entry$rhs <- meta$rhs

  mu_animal <- extract_gaussian_mu_known_term(mu_entry, "animal")
  mu_entry$rhs <- mu_animal$rhs
  validate_beta_animal_mu_structured_term(mu_animal$term)
  sigma_animal <- extract_gaussian_mu_known_term(
    sigma_entry,
    "animal",
    dpar = "sigma"
  )
  sigma_entry$rhs <- sigma_animal$rhs
  if (!is.null(sigma_animal$term)) {
    sigma_animal$term$dpars <- "sigma"
  }
  validate_beta_animal_sigma_structured_term(sigma_animal$term)
  if (!is.null(mu_animal$term) && !is.null(sigma_animal$term)) {
    cli::cli_abort(c(
      "{.fn beta} structured animal effects currently support one endpoint at a time.",
      "x" = "Both {.code mu} and {.code sigma} contain {.fn animal} terms.",
      "i" = "Fit either {.code animal(1 | id, ...)} in {.code mu} or in {.code sigma}; q2/q4 beta location-scale blocks remain post-v1.0 design work."
    ))
  }
  animal_term <- if (!is.null(mu_animal$term)) {
    mu_animal$term
  } else {
    sigma_animal$term
  }
  mu_re <- extract_random_mu_terms(mu_entry$rhs, mu_entry$dpar)
  mu_entry$rhs <- mu_re$rhs
  validate_beta_mu_random_terms(mu_re$terms)
  sigma_re <- extract_random_sigma_terms(sigma_entry$rhs, "sigma")
  sigma_entry$rhs <- sigma_re$rhs
  validate_beta_sigma_random_terms(sigma_re$terms)

  for (entry in list(mu_entry, sigma_entry)) {
    drm_reject_phase1_terms(entry$rhs, entry$dpar)
  }

  f_mu <- drm_entry_formula(mu_entry, response = TRUE)
  f_sigma <- drm_entry_formula(sigma_entry, response = FALSE)

  vars <- unique(c(
    all.vars(f_mu),
    all.vars(f_sigma),
    random_effect_vars(mu_re$terms),
    structured_mu_vars(mu_animal$term),
    structured_mu_vars(sigma_animal$term)
  ))
  if (length(vars) > 0L) {
    keep <- stats::complete.cases(data[, vars, drop = FALSE])
  } else {
    keep <- rep(TRUE, nrow(data))
  }
  data_model <- data[keep, , drop = FALSE]
  weights_model <- subset_likelihood_weights(
    weights,
    keep,
    nrow(data),
    sum(keep)
  )

  mf_mu <- stats::model.frame(
    f_mu,
    data = data_model,
    na.action = stats::na.omit
  )
  mf_sigma <- stats::model.frame(
    f_sigma,
    data = data_model,
    na.action = stats::na.omit
  )
  y <- stats::model.response(mf_mu)

  if (!is.null(dim(y))) {
    cli::cli_abort(c(
      "Beta models currently require a single strict proportion response.",
      "x" = "Denominator syntax such as {.code cbind(successes, failures)} is planned for {.fn beta_binomial}, not {.fn beta}."
    ))
  }
  if (length(y) == 0L) {
    cli::cli_abort(
      "No complete observations remain after applying model missingness rules."
    )
  }
  if (!all(is.finite(y)) || any(y <= 0) || any(y >= 1)) {
    cli::cli_abort(c(
      "Beta models require response values strictly between 0 and 1.",
      "x" = "The response {.val {mu_entry$response}} contains boundary, out-of-range, or non-finite values after missing-row filtering."
    ))
  }

  X_mu <- stats::model.matrix(
    stats::delete.response(stats::terms(mf_mu)),
    mf_mu
  )
  X_sigma <- stats::model.matrix(stats::terms(mf_sigma), mf_sigma)

  if (nrow(X_sigma) != length(y)) {
    cli::cli_abort("Internal model-frame mismatch in beta model.")
  }
  re_mu <- build_random_mu_structure(mu_re$terms, data_model)
  phylo_mu <- build_structured_mu_structure(animal_term, data_model, env)

  spec <- list(
    model_type = "beta",
    y = as.numeric(y),
    weights = weights_model,
    V_known = rep(0, length(y)),
    V_known_diag = rep(0, length(y)),
    V_known_type = "none",
    has_known_v = FALSE,
    X = list(mu = X_mu, sigma = X_sigma),
    terms = list(
      mu = stats::delete.response(stats::terms(mf_mu)),
      sigma = stats::terms(mf_sigma)
    ),
    model_frame = list(mu = mf_mu, sigma = mf_sigma),
    random = list(
      mu = re_mu,
      sigma = empty_random_sigma_structure(nrow(data_model))
    ),
    random_scale = list(mu = empty_sd_mu_structure(re_mu$n_re)),
    structured = list(phylo_mu = phylo_mu),
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = c("mu", "sigma"),
    start = beta_ls_start(y, X_mu, X_sigma, re_mu = re_mu, phylo_mu = phylo_mu),
    map = beta_ls_map(re_mu, phylo_mu),
    random_names = c(
      if (re_mu$n_re > 0L) "u_mu",
      if (isTRUE(phylo_mu$has)) "u_phylo"
    )
  )
  spec$tmb_data <- add_covariance_block_tmb_data(
    make_tmb_data(spec),
    spec
  )
  spec$nobs <- length(spec$y)
  spec
}

drm_build_zero_one_beta_spec <- function(
  formula,
  data,
  env = parent.frame(),
  weights = NULL
) {
  entries <- formula$entries
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  is_sd_dpar <- startsWith(dpars, "sd(")

  unsupported <- setdiff(dpars[!is_sd_dpar], c("mu", "sigma", "zoi", "coi"))
  if (length(unsupported) > 0L) {
    cli::cli_abort(c(
      "Zero-one beta models only support {.code mu}, {.code sigma}, {.code zoi}, and {.code coi}.",
      "x" = "Unsupported parameter{?s}: {.val {unsupported}}."
    ))
  }
  if (any(is_sd_dpar)) {
    cli::cli_abort(c(
      "Random-effect scale formulae are not implemented for {.fn zero_one_beta} models.",
      "i" = "The first zero-one beta slice is fixed-effect only for {.code mu}, {.code sigma}, {.code zoi}, and {.code coi}."
    ))
  }
  if (sum(dpars == "mu") != 1L) {
    cli::cli_abort(
      "A zero-one beta model requires exactly one location formula."
    )
  }
  for (optional in c("sigma", "zoi", "coi")) {
    if (sum(dpars == optional) > 1L) {
      cli::cli_abort(
        "A zero-one beta model can have at most one {.code {optional}} formula."
      )
    }
  }

  mu_entry <- entries[[which(dpars == "mu")]]
  sigma_entry <- if (any(dpars == "sigma")) {
    entries[[which(dpars == "sigma")]]
  } else {
    default_dpar_entry("sigma", quote(1))
  }
  zoi_entry <- if (any(dpars == "zoi")) {
    entries[[which(dpars == "zoi")]]
  } else {
    default_dpar_entry("zoi", quote(1))
  }
  coi_entry <- if (any(dpars == "coi")) {
    entries[[which(dpars == "coi")]]
  } else {
    default_dpar_entry("coi", quote(1))
  }

  if (is.na(mu_entry$response)) {
    cli::cli_abort(
      "The {.code mu} formula must include a response on the left-hand side."
    )
  }
  if (is_mvbind_lhs(mu_entry$lhs)) {
    cli::cli_abort(c(
      "{.fn mvbind} shorthand is only available for two-response Gaussian models.",
      "x" = "Zero-one beta models currently support one bounded proportion response."
    ))
  }
  if (is_cbind_lhs(mu_entry$lhs)) {
    cli::cli_abort(c(
      "Zero-one beta models require a single continuous bounded response.",
      "x" = "Denominator syntax such as {.code cbind(successes, failures)} belongs to {.fn beta_binomial}, not {.fn zero_one_beta}."
    ))
  }

  for (entry in list(mu_entry, sigma_entry, zoi_entry, coi_entry)) {
    drm_reject_phase1_terms(entry$rhs, entry$dpar)
  }

  f_mu <- drm_entry_formula(mu_entry, response = TRUE)
  f_sigma <- drm_entry_formula(sigma_entry, response = FALSE)
  f_zoi <- drm_entry_formula(zoi_entry, response = FALSE)
  f_coi <- drm_entry_formula(coi_entry, response = FALSE)

  vars <- unique(c(
    all.vars(f_mu),
    all.vars(f_sigma),
    all.vars(f_zoi),
    all.vars(f_coi)
  ))
  if (length(vars) > 0L) {
    keep <- stats::complete.cases(data[, vars, drop = FALSE])
  } else {
    keep <- rep(TRUE, nrow(data))
  }
  data_model <- data[keep, , drop = FALSE]
  weights_model <- subset_likelihood_weights(
    weights,
    keep,
    nrow(data),
    sum(keep)
  )

  mf_mu <- stats::model.frame(
    f_mu,
    data = data_model,
    na.action = stats::na.omit
  )
  mf_sigma <- stats::model.frame(
    f_sigma,
    data = data_model,
    na.action = stats::na.omit
  )
  mf_zoi <- stats::model.frame(
    f_zoi,
    data = data_model,
    na.action = stats::na.omit
  )
  mf_coi <- stats::model.frame(
    f_coi,
    data = data_model,
    na.action = stats::na.omit
  )
  y <- prepare_zero_one_beta_response(
    stats::model.response(mf_mu),
    response = mu_entry$response
  )

  X_mu <- stats::model.matrix(
    stats::delete.response(stats::terms(mf_mu)),
    mf_mu
  )
  X_sigma <- stats::model.matrix(stats::terms(mf_sigma), mf_sigma)
  X_zoi <- stats::model.matrix(stats::terms(mf_zoi), mf_zoi)
  X_coi <- stats::model.matrix(stats::terms(mf_coi), mf_coi)

  if (any(c(nrow(X_sigma), nrow(X_zoi), nrow(X_coi)) != length(y))) {
    cli::cli_abort("Internal model-frame mismatch in zero-one beta model.")
  }

  spec <- list(
    model_type = "zero_one_beta",
    y = as.numeric(y),
    weights = weights_model,
    V_known = rep(0, length(y)),
    V_known_diag = rep(0, length(y)),
    V_known_type = "none",
    has_known_v = FALSE,
    X = list(mu = X_mu, sigma = X_sigma, zoi = X_zoi, coi = X_coi),
    terms = list(
      mu = stats::delete.response(stats::terms(mf_mu)),
      sigma = stats::terms(mf_sigma),
      zoi = stats::terms(mf_zoi),
      coi = stats::terms(mf_coi)
    ),
    model_frame = list(
      mu = mf_mu,
      sigma = mf_sigma,
      zoi = mf_zoi,
      coi = mf_coi
    ),
    random = list(
      mu = empty_random_mu_structure(nrow(data_model)),
      sigma = empty_random_sigma_structure(nrow(data_model))
    ),
    random_scale = list(mu = empty_sd_mu_structure(0L)),
    structured = list(phylo_mu = empty_phylo_mu_structure()),
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = c("mu", "sigma", "zoi", "coi"),
    start = zero_one_beta_start(y, X_mu, X_sigma, X_zoi, X_coi),
    map = zero_one_beta_map(),
    random_names = NULL
  )
  spec$tmb_data <- add_covariance_block_tmb_data(
    make_tmb_data(spec),
    spec
  )
  spec$nobs <- length(spec$y)
  spec
}

drm_build_beta_binomial_spec <- function(
  formula,
  data,
  env = parent.frame(),
  weights = NULL
) {
  entries <- formula$entries
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  is_sd_dpar <- startsWith(dpars, "sd(")

  unsupported <- setdiff(dpars[!is_sd_dpar], c("mu", "sigma"))
  reject_planned_bounded_inflation(
    entries = entries,
    unsupported = unsupported,
    family_label = "beta_binomial()"
  )
  if (length(unsupported) > 0L) {
    cli::cli_abort(c(
      "Beta-binomial models only support {.code mu} and {.code sigma}.",
      "x" = "Unsupported parameter{?s}: {.val {unsupported}}."
    ))
  }
  if (any(is_sd_dpar)) {
    cli::cli_abort(c(
      "Random-effect scale formulae are not implemented for {.fn beta_binomial} models yet.",
      "i" = "Use denominator-aware formulas such as {.code bf(cbind(success, failure) ~ x + (1 | id), sigma ~ z)}; group-level scale models need separate recovery tests."
    ))
  }
  if (sum(dpars == "mu") != 1L) {
    cli::cli_abort(
      "A beta-binomial model requires exactly one location formula."
    )
  }
  if (sum(dpars == "sigma") > 1L) {
    cli::cli_abort(
      "A beta-binomial model can have at most one overdispersion {.code sigma} formula."
    )
  }

  mu_entry <- entries[[which(dpars == "mu")]]
  sigma_entry <- if (any(dpars == "sigma")) {
    entries[[which(dpars == "sigma")]]
  } else {
    default_dpar_entry("sigma", quote(1))
  }

  if (is.na(mu_entry$response)) {
    cli::cli_abort(
      "The {.code mu} formula must include a denominator-aware response on the left-hand side."
    )
  }
  if (is_mvbind_lhs(mu_entry$lhs)) {
    cli::cli_abort(c(
      "{.fn beta_binomial} models currently support one two-column count response.",
      "x" = "{.fn mvbind} shorthand is only available for two-response Gaussian models."
    ))
  }
  if (!is_cbind_lhs(mu_entry$lhs)) {
    cli::cli_abort(c(
      "{.fn beta_binomial} models require two-column count syntax on the left-hand side.",
      "i" = "Use {.code bf(cbind(successes, failures) ~ predictors, sigma ~ predictors)}."
    ))
  }

  meta <- extract_meta_known_v(mu_entry$rhs)
  if (!is.null(meta$V)) {
    cli::cli_abort(c(
      "{.fn meta_V} is not implemented for {.fn beta_binomial} models.",
      "i" = "Use {.code family = gaussian()} for Gaussian meta-analysis with known sampling covariance."
    ))
  }
  mu_entry$rhs <- meta$rhs

  mu_re <- extract_random_mu_terms(mu_entry$rhs, mu_entry$dpar)
  mu_entry$rhs <- mu_re$rhs
  validate_beta_binomial_mu_random_terms(mu_re$terms)
  sigma_re <- extract_random_sigma_terms(sigma_entry$rhs, "sigma")
  sigma_entry$rhs <- sigma_re$rhs
  validate_beta_binomial_sigma_random_terms(sigma_re$terms)

  for (entry in list(mu_entry, sigma_entry)) {
    drm_reject_phase1_terms(entry$rhs, entry$dpar)
  }

  f_mu <- drm_entry_formula(mu_entry, response = TRUE)
  f_sigma <- drm_entry_formula(sigma_entry, response = FALSE)

  vars <- unique(c(
    all.vars(f_mu),
    all.vars(f_sigma),
    random_effect_vars(mu_re$terms)
  ))
  if (length(vars) > 0L) {
    keep <- stats::complete.cases(data[, vars, drop = FALSE])
  } else {
    keep <- rep(TRUE, nrow(data))
  }
  data_model <- data[keep, , drop = FALSE]
  weights_model <- subset_likelihood_weights(
    weights,
    keep,
    nrow(data),
    sum(keep)
  )

  mf_mu <- stats::model.frame(
    f_mu,
    data = data_model,
    na.action = stats::na.omit
  )
  mf_sigma <- stats::model.frame(
    f_sigma,
    data = data_model,
    na.action = stats::na.omit
  )
  response <- prepare_betabinomial_response(
    stats::model.response(mf_mu),
    response = mu_entry$response
  )

  X_mu <- stats::model.matrix(
    stats::delete.response(stats::terms(mf_mu)),
    mf_mu
  )
  X_sigma <- stats::model.matrix(stats::terms(mf_sigma), mf_sigma)

  if (nrow(X_sigma) != length(response$successes)) {
    cli::cli_abort("Internal model-frame mismatch in beta-binomial model.")
  }
  re_mu <- build_random_mu_structure(mu_re$terms, data_model)

  spec <- list(
    model_type = "beta_binomial",
    y = as.numeric(response$successes),
    trials = as.numeric(response$trials),
    failures = as.numeric(response$failures),
    weights = weights_model,
    V_known = rep(0, length(response$successes)),
    V_known_diag = rep(0, length(response$successes)),
    V_known_type = "none",
    has_known_v = FALSE,
    X = list(mu = X_mu, sigma = X_sigma),
    terms = list(
      mu = stats::delete.response(stats::terms(mf_mu)),
      sigma = stats::terms(mf_sigma)
    ),
    model_frame = list(mu = mf_mu, sigma = mf_sigma),
    random = list(
      mu = re_mu,
      sigma = empty_random_sigma_structure(nrow(data_model))
    ),
    random_scale = list(mu = empty_sd_mu_structure(re_mu$n_re)),
    structured = list(phylo_mu = empty_phylo_mu_structure()),
    denominator = response[c("success_name", "failure_name", "trials")],
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = c("mu", "sigma"),
    start = beta_binomial_start(
      response$successes,
      response$failures,
      X_mu,
      X_sigma,
      re_mu = re_mu
    ),
    map = beta_binomial_map(re_mu),
    random_names = if (re_mu$n_re > 0L) "u_mu" else NULL
  )
  spec$tmb_data <- add_covariance_block_tmb_data(
    make_tmb_data(spec),
    spec
  )
  spec$nobs <- length(spec$y)
  spec
}

drm_build_binomial_spec <- function(
  formula,
  data,
  env = parent.frame(),
  weights = NULL
) {
  entries <- formula$entries
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  is_sd_dpar <- startsWith(dpars, "sd(")

  unsupported <- setdiff(dpars[!is_sd_dpar], "mu")
  reject_planned_bounded_inflation(
    entries = entries,
    unsupported = unsupported,
    family_label = "binomial()"
  )
  if (length(unsupported) > 0L) {
    cli::cli_abort(c(
      "Binomial models currently support only the {.code mu} event-probability formula.",
      "x" = "Unsupported parameter{?s}: {.val {unsupported}}.",
      "i" = "Use {.fn beta_binomial} for overdispersed success counts with a fitted {.code sigma} parameter."
    ))
  }
  if (any(is_sd_dpar)) {
    cli::cli_abort(c(
      "Random-effect scale formulae are not implemented for binomial models.",
      "i" = "The first binomial-response slice is fixed-effect {.code mu} only."
    ))
  }
  if (sum(dpars == "mu") != 1L) {
    cli::cli_abort("A binomial model requires exactly one location formula.")
  }

  mu_entry <- entries[[which(dpars == "mu")]]
  if (is.na(mu_entry$response)) {
    cli::cli_abort(
      "The {.code mu} formula must include a binomial response on the left-hand side."
    )
  }
  if (is_mvbind_lhs(mu_entry$lhs)) {
    cli::cli_abort(c(
      "{.fn mvbind} shorthand is only available for two-response Gaussian models.",
      "x" = "Binomial models currently support one response."
    ))
  }

  meta <- extract_meta_known_v(mu_entry$rhs)
  if (!is.null(meta$V)) {
    cli::cli_abort(c(
      "{.fn meta_V} is not implemented for binomial models.",
      "i" = "Use {.code family = gaussian()} for Gaussian meta-analysis with known sampling covariance."
    ))
  }
  mu_entry$rhs <- meta$rhs

  mu_re <- extract_random_mu_terms(mu_entry$rhs, mu_entry$dpar)
  mu_entry$rhs <- mu_re$rhs
  if (length(mu_re$terms) > 0L) {
    labels <- vapply(mu_re$terms, `[[`, character(1L), "label")
    cli::cli_abort(c(
      "Random effects are not implemented for binomial response models yet.",
      "x" = "Unsupported random-effect term{?s}: {.val {labels}}.",
      "i" = "Fit the first binomial slice as a fixed-effect model, or use a package with established binomial mixed-model support."
    ))
  }
  drm_reject_phase1_terms(mu_entry$rhs, mu_entry$dpar, allow_offset = TRUE)

  f_mu <- drm_entry_formula(mu_entry, response = TRUE)
  vars <- all.vars(f_mu)
  if (length(vars) > 0L) {
    keep <- stats::complete.cases(data[, vars, drop = FALSE])
  } else {
    keep <- rep(TRUE, nrow(data))
  }
  data_model <- data[keep, , drop = FALSE]
  weights_model <- subset_likelihood_weights(
    weights,
    keep,
    nrow(data),
    sum(keep)
  )

  mf_mu <- stats::model.frame(
    f_mu,
    data = data_model,
    na.action = stats::na.omit
  )
  response <- prepare_binomial_response(
    stats::model.response(mf_mu),
    response = mu_entry$response,
    has_weights = !is.null(weights)
  )
  offset_mu <- drm_model_offset(mf_mu, dpar = "mu")

  X_mu <- stats::model.matrix(
    stats::delete.response(stats::terms(mf_mu)),
    mf_mu
  )

  if (nrow(X_mu) != length(response$successes)) {
    cli::cli_abort("Internal model-frame mismatch in binomial model.")
  }

  spec <- list(
    model_type = "binomial",
    y = as.numeric(response$successes),
    trials = as.numeric(response$trials),
    failures = as.numeric(response$failures),
    weights = weights_model,
    V_known = rep(0, length(response$successes)),
    V_known_diag = rep(0, length(response$successes)),
    V_known_type = "none",
    has_known_v = FALSE,
    offset = list(mu = offset_mu),
    X = list(mu = X_mu),
    terms = list(mu = stats::delete.response(stats::terms(mf_mu))),
    model_frame = list(mu = mf_mu),
    random = list(
      mu = empty_random_mu_structure(nrow(data_model)),
      sigma = empty_random_sigma_structure(nrow(data_model))
    ),
    random_scale = list(
      mu = empty_sd_mu_structure(0L),
      phylo = empty_sd_phylo_structure()
    ),
    structured = list(phylo_mu = empty_phylo_mu_structure()),
    denominator = response[
      c("success_name", "failure_name", "trials", "encoding")
    ],
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = "mu",
    start = binomial_start(
      response$successes,
      response$failures,
      X_mu,
      offset_mu
    ),
    map = binomial_map(),
    random_names = NULL
  )
  spec$tmb_data <- add_covariance_block_tmb_data(
    make_tmb_data(spec),
    spec
  )
  spec$nobs <- length(spec$y)
  spec
}

drm_build_cumulative_logit_spec <- function(
  formula,
  data,
  env = parent.frame(),
  weights = NULL
) {
  entries <- formula$entries
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  is_sd_dpar <- startsWith(dpars, "sd(")

  unsupported <- setdiff(dpars[!is_sd_dpar], "mu")
  if (length(unsupported) > 0L) {
    cli::cli_abort(c(
      "{.fn cumulative_logit} models currently support only a {.code mu} location formula.",
      "x" = "Unsupported parameter{?s}: {.val {unsupported}}.",
      "i" = "Ordinal scale/discrimination formulas are planned after the identifiability contract is finalized."
    ))
  }
  if (any(is_sd_dpar)) {
    cli::cli_abort(c(
      "Random-effect scale formulae are not implemented for {.fn cumulative_logit} models.",
      "i" = "Start with fixed-effect ordinal formulas such as {.code bf(score ~ treatment)}."
    ))
  }
  if (sum(dpars == "mu") != 1L) {
    cli::cli_abort(
      "A {.fn cumulative_logit} model requires exactly one location formula."
    )
  }

  mu_entry <- entries[[which(dpars == "mu")]]
  if (is.na(mu_entry$response)) {
    cli::cli_abort(
      "The {.code mu} formula must include an ordinal response on the left-hand side."
    )
  }
  if (is_mvbind_lhs(mu_entry$lhs)) {
    cli::cli_abort(c(
      "{.fn cumulative_logit} models currently support one ordered response.",
      "x" = "{.fn mvbind} shorthand is only available for two-response Gaussian models."
    ))
  }
  if (is_cbind_lhs(mu_entry$lhs)) {
    cli::cli_abort(c(
      "{.fn cumulative_logit} models require a single ordered response.",
      "x" = "Denominator syntax such as {.code cbind(successes, failures)} is planned for beta-binomial models, not ordinal models."
    ))
  }

  meta <- extract_meta_known_v(mu_entry$rhs)
  if (!is.null(meta$V)) {
    cli::cli_abort(c(
      "{.fn meta_V} is not implemented for {.fn cumulative_logit} models.",
      "i" = "Use {.code family = gaussian()} for Gaussian meta-analysis with known sampling covariance."
    ))
  }
  mu_entry$rhs <- meta$rhs
  mu_phylo <- extract_gaussian_mu_phylo_term(mu_entry)
  mu_entry$rhs <- mu_phylo$rhs
  validate_ordinal_phylo_mu_structured_term(mu_phylo$term)
  if (formula_contains_structured_marker(mu_entry$rhs)) {
    drm_reject_phase1_terms(mu_entry$rhs, mu_entry$dpar)
  }
  if (formula_contains_call(mu_entry$rhs, "|")) {
    cli::cli_abort(c(
      "Ordinal random effects are not implemented.",
      "x" = "The {.code mu} formula contains a random-effect bar term.",
      "i" = "The first ordinal mixed-model target is a random intercept such as {.code bf(score ~ x + (1 | id))}.",
      "i" = "Random slopes should remain a later step after ordinal intercept recovery, cutpoint stability, extractor support, and interval checks are in place.",
      "i" = "{.pkg ordinal}'s {.fn clmm} is a useful benchmark, but matching it requires a separate likelihood and recovery slice."
    ))
  }
  drm_reject_phase1_terms(mu_entry$rhs, mu_entry$dpar)

  f_mu <- drm_entry_formula(mu_entry, response = TRUE)
  vars <- all.vars(f_mu)
  if (length(vars) > 0L) {
    keep <- stats::complete.cases(data[, vars, drop = FALSE])
  } else {
    keep <- rep(TRUE, nrow(data))
  }
  data_model <- data[keep, , drop = FALSE]
  weights_model <- subset_likelihood_weights(
    weights,
    keep,
    nrow(data),
    sum(keep)
  )

  mf_mu <- stats::model.frame(
    f_mu,
    data = data_model,
    na.action = stats::na.omit
  )
  y <- stats::model.response(mf_mu)
  if (length(y) == 0L) {
    cli::cli_abort(
      "No complete observations remain after applying ordinal model missingness rules."
    )
  }
  ordinal <- prepare_ordinal_response(y, response = mu_entry$response)

  terms_mu <- stats::delete.response(stats::terms(mf_mu))
  X_mu <- ordinal_mu_model_matrix(terms_mu, mf_mu)
  phylo_mu <- build_structured_mu_structure(mu_phylo$term, data_model, env)

  if (nrow(X_mu) != length(ordinal$y)) {
    cli::cli_abort("Internal model-frame mismatch in cumulative_logit model.")
  }

  spec <- list(
    model_type = "cumulative_logit",
    y = as.numeric(ordinal$y),
    weights = weights_model,
    V_known = rep(0, length(ordinal$y)),
    V_known_diag = rep(0, length(ordinal$y)),
    V_known_type = "none",
    has_known_v = FALSE,
    X = list(mu = X_mu),
    terms = list(mu = terms_mu),
    model_frame = list(mu = mf_mu),
    random = list(
      mu = empty_random_mu_structure(nrow(data_model)),
      sigma = empty_random_sigma_structure(nrow(data_model))
    ),
    random_scale = list(
      mu = empty_sd_mu_structure(1L),
      phylo = empty_sd_phylo_structure()
    ),
    structured = list(phylo_mu = phylo_mu),
    ordinal = ordinal[c("levels", "n_categories", "response")],
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = "mu",
    start = cumulative_logit_start(
      ordinal$y,
      X_mu,
      ordinal$n_categories,
      phylo_mu = phylo_mu
    ),
    map = cumulative_logit_map(phylo_mu),
    random_names = if (isTRUE(phylo_mu$has)) "u_phylo" else NULL
  )
  spec$tmb_data <- add_covariance_block_tmb_data(
    make_tmb_data(spec),
    spec
  )
  spec$nobs <- length(spec$y)
  spec
}

drm_build_poisson_spec <- function(
  formula,
  data,
  env = parent.frame(),
  weights = NULL,
  impute = NULL,
  missing = miss_control()
) {
  entries <- formula$entries
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  is_sd_dpar <- startsWith(dpars, "sd(")

  unsupported <- setdiff(dpars[!is_sd_dpar], c("mu", "zi"))
  if (length(unsupported) > 0L) {
    cli::cli_abort(c(
      "Poisson models only support {.code mu} and optional {.code zi}.",
      "x" = "Unsupported parameter{?s}: {.val {unsupported}}."
    ))
  }
  if (any(is_sd_dpar)) {
    cli::cli_abort(c(
      "Random-effect scale formulae are not implemented for Poisson models.",
      "i" = "Poisson models currently have no fitted {.code sigma} parameter."
    ))
  }
  if (sum(dpars == "mu") != 1L) {
    cli::cli_abort("A Poisson model requires exactly one location formula.")
  }
  if (sum(dpars == "zi") > 1L) {
    cli::cli_abort(
      "A Poisson model can have at most one zero-inflation {.code zi} formula."
    )
  }

  mu_entry <- entries[[which(dpars == "mu")]]
  zi_entry <- if (any(dpars == "zi")) {
    entries[[which(dpars == "zi")]]
  } else {
    NULL
  }
  if (is.na(mu_entry$response)) {
    cli::cli_abort(
      "The {.code mu} formula must include a response on the left-hand side."
    )
  }
  if (!is.null(zi_entry) && !is.na(zi_entry$response)) {
    cli::cli_abort(
      "The {.code zi} formula must be one-sided, for example {.code zi ~ habitat}."
    )
  }
  if (is_mvbind_lhs(mu_entry$lhs)) {
    cli::cli_abort(c(
      "{.fn mvbind} shorthand is only available for two-response Gaussian models.",
      "x" = "Poisson models currently support one count response."
    ))
  }

  meta <- extract_meta_known_v(mu_entry$rhs)
  if (!is.null(meta$V)) {
    cli::cli_abort(c(
      "{.fn meta_V} is not implemented for Poisson models.",
      "i" = "Use {.code family = gaussian()} for Gaussian meta-analysis with known sampling covariance."
    ))
  }
  mu_entry$rhs <- meta$rhs
  mu_phylo <- extract_gaussian_mu_phylo_term(mu_entry)
  mu_entry$rhs <- mu_phylo$rhs
  mu_phylo_interaction <- extract_gaussian_mu_phylo_interaction_term(mu_entry)
  mu_entry$rhs <- mu_phylo_interaction$rhs
  mu_spatial <- extract_gaussian_mu_spatial_term(mu_entry)
  mu_entry$rhs <- mu_spatial$rhs
  mu_animal <- extract_gaussian_mu_known_term(mu_entry, "animal")
  mu_entry$rhs <- mu_animal$rhs
  mu_relmat <- extract_gaussian_mu_known_term(mu_entry, "relmat")
  mu_entry$rhs <- mu_relmat$rhs
  zi_spatial <- list(rhs = NULL, term = NULL)
  if (!is.null(zi_entry)) {
    zi_spatial <- extract_gaussian_mu_spatial_term(zi_entry, dpar = "zi")
    zi_entry$rhs <- zi_spatial$rhs
    if (!is.null(zi_spatial$term)) {
      zi_spatial$term$dpars <- "zi"
    }
  }
  mu_structured_term <- select_count_mu_structured_term(
    list(
      phylo = mu_phylo$term,
      phylo_interaction = mu_phylo_interaction$term,
      spatial = mu_spatial$term,
      animal = mu_animal$term,
      relmat = mu_relmat$term
    ),
    family_label = "Poisson"
  )
  mu_re <- extract_random_mu_terms(mu_entry$rhs, mu_entry$dpar)
  mu_entry$rhs <- mu_re$rhs
  validate_poisson_mu_random_terms(mu_re$terms, has_zi = !is.null(zi_entry))
  validate_count_structured_mu_term(
    mu_structured_term,
    mu_re$terms,
    has_zi = !is.null(zi_entry),
    allow_structured_plus_ordinary = TRUE,
    structured_plus_ordinary_types = "spatial",
    allow_labelled_scalar_structured_mu = TRUE,
    labelled_scalar_structured_mu_types = "spatial",
    allow_zero_inflated_structured_mu = TRUE,
    zero_inflated_structured_mu_types = "spatial",
    allow_slope_only_structured_mu = TRUE,
    slope_only_structured_mu_types = "spatial",
    family_label = "Poisson",
    inflated_label = "Zero-inflated Poisson"
  )
  validate_poisson_spatial_zi_structured_term(
    zi_spatial$term,
    mu_re$terms,
    mu_structured_term
  )
  mi_setup <- drm_prepare_gaussian_mi_setup(mu_entry$rhs, impute, missing)
  include_missing_predictor <- isTRUE(mi_setup$enabled)
  if (include_missing_predictor && !identical(mi_setup$family, "bernoulli")) {
    cli::cli_abort(c(
      "The first Poisson-response {.fn mi} slice supports one binary missing predictor.",
      "x" = "The supplied predictor model uses family {.val {mi_setup$family}}.",
      "i" = "Use {.code impute_model(x ~ z, family = binomial())} for this slice."
    ))
  }
  if (include_missing_predictor && !is.null(zi_entry)) {
    cli::cli_abort(c(
      "Poisson-response {.fn mi} predictor models are not implemented with zero inflation yet.",
      "i" = "Fit the first non-Gaussian response missing-predictor slice without a {.code zi} formula."
    ))
  }
  if (
    include_missing_predictor &&
      (length(mu_re$terms) > 0L || !is.null(mu_structured_term))
  ) {
    cli::cli_abort(c(
      "Poisson-response {.fn mi} predictor models are fixed-effect only in the first slice.",
      "i" = "Remove random or structured terms from the Poisson {.code mu} formula, or fit the Gaussian-response missing-predictor route."
    ))
  }
  drm_reject_phase1_terms(mu_entry$rhs, mu_entry$dpar, allow_offset = TRUE)
  if (!is.null(zi_entry)) {
    drm_reject_phase1_terms(zi_entry$rhs, zi_entry$dpar)
  }

  f_mu <- drm_entry_formula(mu_entry, response = TRUE)
  f_zi <- if (!is.null(zi_entry)) {
    drm_entry_formula(zi_entry, response = FALSE)
  } else {
    NULL
  }
  mu_model_vars <- all.vars(f_mu)
  if (include_missing_predictor) {
    mu_model_vars <- setdiff(mu_model_vars, mi_setup$variable)
  }
  impute_vars <- if (include_missing_predictor) {
    all.vars(stats::delete.response(stats::terms(mi_setup$formula)))
  } else {
    character(0)
  }
  if (include_missing_predictor) {
    response_vars <- all.vars(f_mu[[2L]])
    response_in_impute <- intersect(impute_vars, response_vars)
    if (length(response_in_impute) > 0L) {
      cli::cli_abort(c(
        "The first Poisson-response {.arg impute} slice does not allow response variables as predictor-model covariates.",
        "x" = "Remove response variable{?s} {.val {response_in_impute}} from the {.arg impute} formula."
      ))
    }
  }
  vars <- unique(c(
    mu_model_vars,
    if (!is.null(f_zi)) all.vars(f_zi),
    impute_vars,
    structured_mu_vars(mu_structured_term),
    structured_mu_vars(zi_spatial$term),
    random_effect_vars(mu_re$terms)
  ))
  if (length(vars) > 0L) {
    keep <- stats::complete.cases(data[, vars, drop = FALSE])
  } else {
    keep <- rep(TRUE, nrow(data))
  }
  if (include_missing_predictor && any(!keep)) {
    cli::cli_abort(c(
      "Missing predictors, grouping variables, or structured-effect inputs outside explicit {.fn mi} terms are not implemented for the Poisson-response missing-predictor slice.",
      "x" = "{sum(!keep)} data row{?s} {?has/have} missing model-input value{?s}.",
      "i" = "Keep ordinary predictors complete, or model one supported binary missing predictor with {.fn mi} and {.arg impute}."
    ))
  }
  data_model <- data[keep, , drop = FALSE]
  weights_model <- subset_likelihood_weights(
    weights,
    keep,
    nrow(data),
    sum(keep)
  )

  mf_mu <- stats::model.frame(
    f_mu,
    data = data_model,
    na.action = if (include_missing_predictor) {
      stats::na.pass
    } else {
      stats::na.omit
    }
  )
  mf_zi <- if (!is.null(f_zi)) {
    stats::model.frame(f_zi, data = data_model, na.action = stats::na.omit)
  } else {
    NULL
  }
  y <- stats::model.response(mf_mu)
  offset_mu <- drm_model_offset(mf_mu, dpar = "mu")

  if (length(y) == 0L) {
    cli::cli_abort(
      "No complete observations remain after applying model missingness rules."
    )
  }
  count_tolerance <- sqrt(.Machine$double.eps)
  if (
    !all(is.finite(y)) || any(y < 0) || any(abs(y - round(y)) > count_tolerance)
  ) {
    cli::cli_abort(c(
      "Poisson models require non-negative integer count response values.",
      "x" = "The response {.val {mu_entry$response}} contains negative, non-integer, or non-finite values after missing-row filtering."
    ))
  }

  missing_predictor <- drm_build_gaussian_missing_predictor_model(
    mi_setup,
    data_model,
    env = env
  )
  if (include_missing_predictor) {
    if (!missing_predictor$model_column %in% names(mf_mu)) {
      cli::cli_abort(
        "Internal {.fn mi} model-frame error: missing predictor column was not retained."
      )
    }
    mf_mu[[missing_predictor$model_column]] <- missing_predictor$x
  }

  X_mu <- stats::model.matrix(
    stats::delete.response(stats::terms(mf_mu)),
    mf_mu
  )
  if (include_missing_predictor) {
    missing_predictor$mu_col <- match(
      missing_predictor$model_column,
      colnames(X_mu)
    )
    if (is.na(missing_predictor$mu_col)) {
      cli::cli_abort(
        "Internal {.fn mi} design-matrix error: missing predictor coefficient column was not found."
      )
    }
  }
  X_zi <- if (!is.null(mf_zi)) {
    stats::model.matrix(stats::terms(mf_zi), mf_zi)
  } else {
    NULL
  }
  if (!is.null(X_zi) && nrow(X_zi) != length(y)) {
    cli::cli_abort(
      "Internal model-frame mismatch in zero-inflated Poisson model."
    )
  }
  if (!is.null(X_zi) && ncol(X_zi) == 0L) {
    cli::cli_abort(c(
      "Cannot fit a zero-column {.code zi} formula in a zero-inflated Poisson model.",
      "i" = "Use a formula with an intercept or predictors, such as {.code zi ~ 1} or {.code zi ~ habitat}."
    ))
  }
  has_zi <- !is.null(X_zi)
  re_mu <- build_random_mu_structure(mu_re$terms, data_model)
  sd_mu <- empty_sd_mu_structure(re_mu$n_re)
  poisson_structured_term <- if (!is.null(zi_spatial$term)) {
    zi_spatial$term
  } else {
    mu_structured_term
  }
  phylo_mu <- build_structured_mu_structure(
    poisson_structured_term,
    data_model,
    env
  )
  start <- if (has_zi) {
    zi_poisson_start(y, X_mu, X_zi, offset_mu, phylo_mu = phylo_mu)
  } else {
    poisson_start(y, X_mu, offset_mu, re_mu = re_mu, phylo_mu = phylo_mu)
  }
  if (include_missing_predictor) {
    start$beta_mi <- missing_predictor$beta_start
  }
  missing_data <- if (include_missing_predictor) {
    new_drm_missing_data(
      control = missing,
      original_row = which(keep),
      model_row = seq_along(y),
      observed_y = rep(TRUE, length(y)),
      response_sentinel = NA_real_,
      predictors = drm_missing_predictor_metadata(
        missing_predictor,
        original_row = which(keep)
      ),
      version = "MD9a"
    )
  } else {
    NULL
  }

  spec <- list(
    model_type = if (has_zi) "zi_poisson" else "poisson",
    y = as.numeric(y),
    weights = weights_model,
    V_known = rep(0, length(y)),
    V_known_diag = rep(0, length(y)),
    V_known_type = "none",
    has_known_v = FALSE,
    offset = list(mu = offset_mu),
    X = if (has_zi) list(mu = X_mu, zi = X_zi) else list(mu = X_mu),
    terms = if (has_zi) {
      list(
        mu = stats::delete.response(stats::terms(mf_mu)),
        zi = stats::terms(mf_zi)
      )
    } else {
      list(mu = stats::delete.response(stats::terms(mf_mu)))
    },
    model_frame = if (has_zi) {
      list(mu = mf_mu, zi = mf_zi)
    } else {
      list(mu = mf_mu)
    },
    random = list(
      mu = re_mu,
      sigma = empty_random_sigma_structure(nrow(data_model))
    ),
    random_scale = list(mu = sd_mu, phylo = empty_sd_phylo_structure()),
    structured = list(phylo_mu = phylo_mu),
    missing_predictor = missing_predictor,
    missing_data = missing_data,
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = if (has_zi) c("mu", "zi") else "mu",
    start = start,
    map = if (has_zi) zi_poisson_map(phylo_mu) else poisson_map(re_mu, phylo_mu),
    random_names = c(
      if (re_mu$n_re > 0L) "u_mu",
      if (isTRUE(phylo_mu$has)) "u_phylo"
    )
  )
  spec$tmb_data <- add_covariance_block_tmb_data(
    make_tmb_data(spec),
    spec
  )
  spec$nobs <- if (include_missing_predictor) {
    spec$missing_data$counts$likelihood_rows
  } else {
    length(spec$y)
  }
  spec
}

drm_build_nbinom2_spec <- function(
  formula,
  data,
  env = parent.frame(),
  weights = NULL
) {
  entries <- formula$entries
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  is_sd_dpar <- startsWith(dpars, "sd(")

  unsupported <- setdiff(dpars[!is_sd_dpar], c("mu", "sigma", "zi"))
  if (length(unsupported) > 0L) {
    cli::cli_abort(c(
      "{.fn nbinom2} models only support {.code mu}, {.code sigma}, and optional {.code zi}.",
      "x" = "Unsupported parameter{?s}: {.val {unsupported}}."
    ))
  }
  if (any(is_sd_dpar)) {
    cli::cli_abort(c(
      "Random-effect scale formulae are not implemented for {.fn nbinom2} models.",
      "i" = "Start with fixed-effect count formulas such as {.code bf(count ~ x, sigma ~ z)}."
    ))
  }
  if (sum(dpars == "mu") != 1L) {
    cli::cli_abort(
      "An {.fn nbinom2} model requires exactly one location formula."
    )
  }
  if (sum(dpars == "sigma") > 1L) {
    cli::cli_abort(
      "An {.fn nbinom2} model can have at most one overdispersion {.code sigma} formula."
    )
  }
  if (sum(dpars == "zi") > 1L) {
    cli::cli_abort(
      "An {.fn nbinom2} model can have at most one zero-inflation {.code zi} formula."
    )
  }

  mu_entry <- entries[[which(dpars == "mu")]]
  sigma_entry <- if (any(dpars == "sigma")) {
    entries[[which(dpars == "sigma")]]
  } else {
    default_dpar_entry("sigma", quote(1))
  }
  zi_entry <- if (any(dpars == "zi")) {
    entries[[which(dpars == "zi")]]
  } else {
    NULL
  }

  if (is.na(mu_entry$response)) {
    cli::cli_abort(
      "The {.code mu} formula must include a response on the left-hand side."
    )
  }
  if (!is.null(zi_entry) && !is.na(zi_entry$response)) {
    cli::cli_abort(
      "The {.code zi} formula must be one-sided, for example {.code zi ~ habitat}."
    )
  }
  if (is_mvbind_lhs(mu_entry$lhs)) {
    cli::cli_abort(c(
      "{.fn mvbind} shorthand is only available for two-response Gaussian models.",
      "x" = "{.fn nbinom2} models currently support one count response."
    ))
  }

  meta <- extract_meta_known_v(mu_entry$rhs)
  if (!is.null(meta$V)) {
    cli::cli_abort(c(
      "{.fn meta_V} is not implemented for {.fn nbinom2} models.",
      "i" = "Use {.code family = gaussian()} for Gaussian meta-analysis with known sampling covariance."
    ))
  }
  mu_entry$rhs <- meta$rhs
  mu_phylo <- extract_gaussian_mu_phylo_term(mu_entry)
  mu_entry$rhs <- mu_phylo$rhs
  mu_phylo_interaction <- extract_gaussian_mu_phylo_interaction_term(mu_entry)
  mu_entry$rhs <- mu_phylo_interaction$rhs
  mu_spatial <- extract_gaussian_mu_spatial_term(mu_entry)
  mu_entry$rhs <- mu_spatial$rhs
  mu_animal <- extract_gaussian_mu_known_term(mu_entry, "animal")
  mu_entry$rhs <- mu_animal$rhs
  mu_relmat <- extract_gaussian_mu_known_term(mu_entry, "relmat")
  mu_entry$rhs <- mu_relmat$rhs
  # Scoped simultaneous two-provider location field (M5 row 105): a spatial
  # coordinate kernel plus a relatedness `Q`, each intercept-only, only in the
  # ordinary (non-zero-inflated) NB2 count model on `mu`.
  mu_structured_candidates <- list(
    phylo = mu_phylo$term,
    phylo_interaction = mu_phylo_interaction$term,
    spatial = mu_spatial$term,
    animal = mu_animal$term,
    relmat = mu_relmat$term
  )
  mu_structured_pair_types <- if (is.null(zi_entry)) {
    c("phylo", "spatial", "animal", "relmat")
  } else {
    character(0)
  }
  mu_structured_pair <- select_count_mu_structured_pair(
    mu_structured_candidates,
    allow_pair_types = mu_structured_pair_types
  )
  mu_structured_term <- select_count_mu_structured_term(
    mu_structured_candidates,
    family_label = "NB2",
    allow_pair_types = mu_structured_pair_types
  )
  mu_structured_term2 <- if (!is.null(mu_structured_pair)) {
    mu_structured_pair$secondary
  } else {
    NULL
  }
  sigma_phylo <- extract_gaussian_mu_phylo_term(sigma_entry, dpar = "sigma")
  sigma_entry$rhs <- sigma_phylo$rhs
  sigma_spatial <- extract_gaussian_mu_spatial_term(
    sigma_entry,
    dpar = "sigma"
  )
  sigma_entry$rhs <- sigma_spatial$rhs
  sigma_animal <- extract_gaussian_mu_known_term(
    sigma_entry,
    "animal",
    dpar = "sigma"
  )
  sigma_entry$rhs <- sigma_animal$rhs
  sigma_relmat <- extract_gaussian_mu_known_term(
    sigma_entry,
    "relmat",
    dpar = "sigma"
  )
  sigma_entry$rhs <- sigma_relmat$rhs
  sigma_structured_term <- select_count_sigma_structured_term(
    list(
      phylo = sigma_phylo$term,
      spatial = sigma_spatial$term,
      animal = sigma_animal$term,
      relmat = sigma_relmat$term
    ),
    family_label = "NB2"
  )
  if (!is.null(sigma_structured_term)) {
    sigma_structured_term$dpars <- "sigma"
  }
  mu_re <- extract_random_mu_terms(mu_entry$rhs, mu_entry$dpar)
  mu_entry$rhs <- mu_re$rhs
  validate_poisson_mu_random_terms(
    mu_re$terms,
    has_zi = !is.null(zi_entry),
    family_label = "NB2",
    inflated_label = "Zero-inflated NB2"
  )
  validate_count_structured_mu_term(
    mu_structured_term,
    mu_re$terms,
    has_zi = !is.null(zi_entry),
    allow_zero_inflated_structured_mu = TRUE,
    zero_inflated_structured_mu_types = "spatial",
    family_label = "NB2",
    inflated_label = "Zero-inflated NB2"
  )
  if (!is.null(mu_structured_term2)) {
    # The secondary field is admitted only alongside the primary (both
    # intercept-only, no zi); run it through the same guard so any residual
    # ordinary-RE / covariance-label combination is still rejected.
    validate_count_structured_mu_term(
      mu_structured_term2,
      mu_re$terms,
      has_zi = !is.null(zi_entry),
      family_label = "NB2",
      inflated_label = "Zero-inflated NB2"
    )
  }
  sigma_re <- extract_random_sigma_terms(sigma_entry$rhs, "sigma")
  sigma_entry$rhs <- sigma_re$rhs
  validate_count_structured_sigma_term(
    sigma_structured_term,
    sigma_terms = sigma_re$terms,
    mu_terms = mu_re$terms,
    mu_structured_term = mu_structured_term,
    has_zi = !is.null(zi_entry),
    family_label = "NB2",
    inflated_label = "Zero-inflated NB2"
  )
  validate_nbinom2_sigma_random_terms(
    sigma_re$terms,
    mu_terms = mu_re$terms,
    structured_term = mu_structured_term,
    has_zi = !is.null(zi_entry)
  )

  for (entry in c(
    list(mu_entry, sigma_entry),
    if (!is.null(zi_entry)) list(zi_entry)
  )) {
    drm_reject_phase1_terms(
      entry$rhs,
      entry$dpar,
      allow_offset = identical(entry$dpar, "mu")
    )
  }

  f_mu <- drm_entry_formula(mu_entry, response = TRUE)
  f_sigma <- drm_entry_formula(sigma_entry, response = FALSE)
  f_zi <- if (!is.null(zi_entry)) {
    drm_entry_formula(zi_entry, response = FALSE)
  } else {
    NULL
  }
  vars <- unique(c(
    all.vars(f_mu),
    all.vars(f_sigma),
    if (!is.null(f_zi)) all.vars(f_zi),
    structured_mu_vars(mu_structured_term),
    structured_mu_vars(mu_structured_term2),
    structured_mu_vars(sigma_structured_term),
    random_effect_vars(mu_re$terms),
    random_effect_vars(sigma_re$terms)
  ))
  if (length(vars) > 0L) {
    keep <- stats::complete.cases(data[, vars, drop = FALSE])
  } else {
    keep <- rep(TRUE, nrow(data))
  }
  data_model <- data[keep, , drop = FALSE]
  weights_model <- subset_likelihood_weights(
    weights,
    keep,
    nrow(data),
    sum(keep)
  )

  mf_mu <- stats::model.frame(
    f_mu,
    data = data_model,
    na.action = stats::na.omit
  )
  mf_sigma <- stats::model.frame(
    f_sigma,
    data = data_model,
    na.action = stats::na.omit
  )
  mf_zi <- if (!is.null(f_zi)) {
    stats::model.frame(f_zi, data = data_model, na.action = stats::na.omit)
  } else {
    NULL
  }
  y <- stats::model.response(mf_mu)
  offset_mu <- drm_model_offset(mf_mu, dpar = "mu")

  if (length(y) == 0L) {
    cli::cli_abort(
      "No complete observations remain after applying model missingness rules."
    )
  }
  count_tolerance <- sqrt(.Machine$double.eps)
  if (
    !all(is.finite(y)) || any(y < 0) || any(abs(y - round(y)) > count_tolerance)
  ) {
    cli::cli_abort(c(
      "{.fn nbinom2} models require non-negative integer count response values.",
      "x" = "The response {.val {mu_entry$response}} contains negative, non-integer, or non-finite values after missing-row filtering."
    ))
  }

  X_mu <- stats::model.matrix(
    stats::delete.response(stats::terms(mf_mu)),
    mf_mu
  )
  X_sigma <- stats::model.matrix(stats::terms(mf_sigma), mf_sigma)
  X_zi <- if (!is.null(mf_zi)) {
    stats::model.matrix(stats::terms(mf_zi), mf_zi)
  } else {
    NULL
  }

  if (nrow(X_sigma) != length(y)) {
    cli::cli_abort("Internal model-frame mismatch in nbinom2 model.")
  }
  if (!is.null(X_zi) && nrow(X_zi) != length(y)) {
    cli::cli_abort(
      "Internal model-frame mismatch in zero-inflated nbinom2 model."
    )
  }
  if (!is.null(X_zi) && ncol(X_zi) == 0L) {
    cli::cli_abort(c(
      "Cannot fit a zero-column {.code zi} formula in a zero-inflated nbinom2 model.",
      "i" = "Use a formula with an intercept or predictors, such as {.code zi ~ 1} or {.code zi ~ habitat}."
    ))
  }
  has_zi <- !is.null(X_zi)
  re_mu <- build_random_mu_structure(mu_re$terms, data_model)
  re_sigma <- build_random_sigma_structure(sigma_re$terms, data_model)
  sd_mu <- empty_sd_mu_structure(re_mu$n_re)
  count_structured_term <- if (!is.null(sigma_structured_term)) {
    sigma_structured_term
  } else {
    mu_structured_term
  }
  phylo_mu <- build_structured_mu_structure(
    count_structured_term,
    data_model,
    env
  )
  # Scoped second structured location field (its own group precision). It is only
  # populated for the admitted intercept-only two-provider NB2 combo; every
  # existing single-field path leaves it empty.
  phylo_mu2 <- if (!is.null(mu_structured_term2)) {
    build_structured_mu_structure(mu_structured_term2, data_model, env)
  } else {
    empty_phylo_mu_structure()
  }

  spec <- list(
    model_type = if (has_zi) "zi_nbinom2" else "nbinom2",
    y = as.numeric(y),
    weights = weights_model,
    V_known = rep(0, length(y)),
    V_known_diag = rep(0, length(y)),
    V_known_type = "none",
    has_known_v = FALSE,
    offset = list(mu = offset_mu),
    X = if (has_zi) {
      list(mu = X_mu, sigma = X_sigma, zi = X_zi)
    } else {
      list(mu = X_mu, sigma = X_sigma)
    },
    terms = if (has_zi) {
      list(
        mu = stats::delete.response(stats::terms(mf_mu)),
        sigma = stats::terms(mf_sigma),
        zi = stats::terms(mf_zi)
      )
    } else {
      list(
        mu = stats::delete.response(stats::terms(mf_mu)),
        sigma = stats::terms(mf_sigma)
      )
    },
    model_frame = if (has_zi) {
      list(mu = mf_mu, sigma = mf_sigma, zi = mf_zi)
    } else {
      list(mu = mf_mu, sigma = mf_sigma)
    },
    random = list(
      mu = re_mu,
      sigma = re_sigma
    ),
    random_scale = list(mu = sd_mu, phylo = empty_sd_phylo_structure()),
    structured = list(phylo_mu = phylo_mu, phylo_mu2 = phylo_mu2),
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = if (has_zi) c("mu", "sigma", "zi") else c("mu", "sigma"),
    start = if (has_zi) {
      zi_nbinom2_start(y, X_mu, X_sigma, X_zi, offset_mu, phylo_mu)
    } else {
      nbinom2_start(
        y,
        X_mu,
        X_sigma,
        offset_mu,
        re_mu = re_mu,
        re_sigma = re_sigma,
        phylo_mu = phylo_mu
      )
    },
    map = if (has_zi) {
      zi_nbinom2_map(phylo_mu)
    } else {
      nbinom2_map(re_mu, phylo_mu, re_sigma)
    },
    random_names = c(
      if (re_mu$n_re > 0L) "u_mu",
      if (re_sigma$n_re > 0L) "u_sigma",
      if (isTRUE(phylo_mu$has)) "u_phylo",
      if (isTRUE(phylo_mu2$has)) "u_phylo2"
    )
  )
  spec <- add_structured_mu2_parameters(spec, phylo_mu2, y)
  spec$tmb_data <- add_covariance_block_tmb_data(
    make_tmb_data(spec),
    spec
  )
  spec$nobs <- length(spec$y)
  spec
}

drm_build_truncated_nbinom2_spec <- function(
  formula,
  data,
  env = parent.frame(),
  weights = NULL
) {
  entries <- formula$entries
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  is_sd_dpar <- startsWith(dpars, "sd(")

  unsupported <- setdiff(dpars[!is_sd_dpar], c("mu", "sigma", "hu"))
  if (length(unsupported) > 0L) {
    cli::cli_abort(c(
      "{.fn truncated_nbinom2} models only support {.code mu}, optional {.code sigma}, and optional {.code hu}.",
      "x" = "Unsupported parameter{?s}: {.val {unsupported}}."
    ))
  }
  if (any(is_sd_dpar)) {
    cli::cli_abort(c(
      "Random-effect scale formulae are not implemented for {.fn truncated_nbinom2} models.",
      "i" = "Start with fixed-effect positive-count formulas such as {.code bf(count ~ x, sigma ~ z)}."
    ))
  }
  if (sum(dpars == "mu") != 1L) {
    cli::cli_abort(
      "A {.fn truncated_nbinom2} model requires exactly one location formula."
    )
  }
  if (sum(dpars == "sigma") > 1L) {
    cli::cli_abort(
      "A {.fn truncated_nbinom2} model can have at most one overdispersion {.code sigma} formula."
    )
  }
  if (sum(dpars == "hu") > 1L) {
    cli::cli_abort(
      "A {.fn truncated_nbinom2} model can have at most one hurdle {.code hu} formula."
    )
  }

  mu_entry <- entries[[which(dpars == "mu")]]
  sigma_entry <- if (any(dpars == "sigma")) {
    entries[[which(dpars == "sigma")]]
  } else {
    default_dpar_entry("sigma", quote(1))
  }
  hu_entry <- if (any(dpars == "hu")) {
    entries[[which(dpars == "hu")]]
  } else {
    NULL
  }

  if (is.na(mu_entry$response)) {
    cli::cli_abort(
      "The {.code mu} formula must include a response on the left-hand side."
    )
  }
  if (!is.null(hu_entry) && !is.na(hu_entry$response)) {
    cli::cli_abort(
      "The {.code hu} formula must be one-sided, for example {.code hu ~ survey_method}."
    )
  }
  if (is_mvbind_lhs(mu_entry$lhs)) {
    cli::cli_abort(c(
      "{.fn mvbind} shorthand is only available for two-response Gaussian models.",
      "x" = "{.fn truncated_nbinom2} models currently support one positive-count response."
    ))
  }
  if (is_cbind_lhs(mu_entry$lhs)) {
    cli::cli_abort(c(
      "{.fn truncated_nbinom2} models require a single positive-count response.",
      "x" = "Denominator syntax such as {.code cbind(successes, failures)} is planned for beta-binomial models, not zero-truncated count models."
    ))
  }

  meta <- extract_meta_known_v(mu_entry$rhs)
  if (!is.null(meta$V)) {
    cli::cli_abort(c(
      "{.fn meta_V} is not implemented for {.fn truncated_nbinom2} models.",
      "i" = "Use {.code family = gaussian()} for Gaussian meta-analysis with known sampling covariance."
    ))
  }
  mu_entry$rhs <- meta$rhs
  hu_relmat <- list(rhs = NULL, term = NULL)
  if (!is.null(hu_entry)) {
    hu_relmat <- extract_gaussian_mu_known_term(
      hu_entry,
      "relmat",
      dpar = "hu"
    )
    if (!is.null(hu_relmat$term)) {
      hu_relmat$term$dpars <- "hu"
    }
    hu_entry$rhs <- hu_relmat$rhs
    validate_truncated_nbinom2_relmat_hu_structured_term(hu_relmat$term)
  }

  if (!is.null(hu_entry) && formula_contains_call(mu_entry$rhs, "|")) {
    cli::cli_abort(c(
      "Hurdle {.fn truncated_nbinom2} random effects are not implemented.",
      "x" = "The {.code mu} formula contains a random-effect bar term while {.code hu} is present.",
      "i" = "Keep hurdle NB2 models fixed-effect for now, such as {.code bf(count ~ x, sigma ~ z, hu ~ w)}.",
      "i" = "Hurdle-side and positive-count random effects need likelihood, extractor, interval, and recovery-test support before they can be fitted together."
    ))
  }
  mu_re <- extract_random_mu_terms(mu_entry$rhs, mu_entry$dpar)
  mu_entry$rhs <- mu_re$rhs
  validate_truncated_nbinom2_mu_random_terms(
    mu_re$terms,
    has_hu = !is.null(hu_entry)
  )
  sigma_re <- extract_random_sigma_terms(sigma_entry$rhs, "sigma")
  sigma_entry$rhs <- sigma_re$rhs
  validate_truncated_nbinom2_sigma_random_terms(sigma_re$terms)

  for (entry in c(
    list(mu_entry, sigma_entry),
    if (!is.null(hu_entry)) list(hu_entry)
  )) {
    drm_reject_phase1_terms(entry$rhs, entry$dpar)
  }

  f_mu <- drm_entry_formula(mu_entry, response = TRUE)
  f_sigma <- drm_entry_formula(sigma_entry, response = FALSE)
  f_hu <- if (!is.null(hu_entry)) {
    drm_entry_formula(hu_entry, response = FALSE)
  } else {
    NULL
  }
  vars <- unique(c(
    all.vars(f_mu),
    all.vars(f_sigma),
    if (!is.null(f_hu)) all.vars(f_hu),
    structured_mu_vars(hu_relmat$term),
    random_effect_vars(mu_re$terms)
  ))
  if (length(vars) > 0L) {
    keep <- stats::complete.cases(data[, vars, drop = FALSE])
  } else {
    keep <- rep(TRUE, nrow(data))
  }
  data_model <- data[keep, , drop = FALSE]
  weights_model <- subset_likelihood_weights(
    weights,
    keep,
    nrow(data),
    sum(keep)
  )

  mf_mu <- stats::model.frame(
    f_mu,
    data = data_model,
    na.action = stats::na.omit
  )
  mf_sigma <- stats::model.frame(
    f_sigma,
    data = data_model,
    na.action = stats::na.omit
  )
  mf_hu <- if (!is.null(f_hu)) {
    stats::model.frame(f_hu, data = data_model, na.action = stats::na.omit)
  } else {
    NULL
  }
  y <- stats::model.response(mf_mu)

  if (length(y) == 0L) {
    cli::cli_abort(
      "No complete observations remain after applying model missingness rules."
    )
  }
  count_tolerance <- sqrt(.Machine$double.eps)
  has_hu <- !is.null(hu_entry)
  invalid_count <- !all(is.finite(y)) ||
    any(abs(y - round(y)) > count_tolerance)
  invalid_truncated <- invalid_count || any(y <= 0)
  invalid_hurdle <- invalid_count || any(y < 0)
  if ((!has_hu && invalid_truncated) || (has_hu && invalid_hurdle)) {
    cli::cli_abort(c(
      if (has_hu) {
        "{.fn truncated_nbinom2} hurdle models require non-negative integer count response values."
      } else {
        "{.fn truncated_nbinom2} models require positive integer count response values."
      },
      "x" = if (has_hu) {
        "The response {.val {mu_entry$response}} contains negative, non-integer, or non-finite values after missing-row filtering."
      } else {
        "The response {.val {mu_entry$response}} contains zero, negative, non-integer, or non-finite values after missing-row filtering."
      }
    ))
  }
  if (has_hu && !any(y > 0)) {
    cli::cli_abort(c(
      "{.fn truncated_nbinom2} hurdle models need at least one positive count after missing-row filtering.",
      "x" = "The positive-count NB2 component cannot be estimated from all-zero responses."
    ))
  }

  X_mu <- stats::model.matrix(
    stats::delete.response(stats::terms(mf_mu)),
    mf_mu
  )
  X_sigma <- stats::model.matrix(stats::terms(mf_sigma), mf_sigma)
  X_hu <- if (!is.null(mf_hu)) {
    stats::model.matrix(stats::terms(mf_hu), mf_hu)
  } else {
    NULL
  }
  if (nrow(X_sigma) != length(y)) {
    cli::cli_abort("Internal model-frame mismatch in truncated_nbinom2 model.")
  }
  if (!is.null(X_hu) && nrow(X_hu) != length(y)) {
    cli::cli_abort("Internal model-frame mismatch in hurdle nbinom2 model.")
  }
  if (!is.null(X_hu) && ncol(X_hu) == 0L) {
    cli::cli_abort(c(
      "Cannot fit a zero-column {.code hu} formula in a hurdle nbinom2 model.",
      "i" = "Use a formula with an intercept or predictors, such as {.code hu ~ 1} or {.code hu ~ survey_method}."
    ))
  }
  re_mu <- build_random_mu_structure(mu_re$terms, data_model)
  phylo_mu <- build_structured_mu_structure(hu_relmat$term, data_model, env)

  spec <- list(
    model_type = if (has_hu) "hurdle_nbinom2" else "truncated_nbinom2",
    y = as.numeric(y),
    weights = weights_model,
    V_known = rep(0, length(y)),
    V_known_diag = rep(0, length(y)),
    V_known_type = "none",
    has_known_v = FALSE,
    X = if (has_hu) {
      list(mu = X_mu, sigma = X_sigma, hu = X_hu)
    } else {
      list(mu = X_mu, sigma = X_sigma)
    },
    terms = if (has_hu) {
      list(
        mu = stats::delete.response(stats::terms(mf_mu)),
        sigma = stats::terms(mf_sigma),
        hu = stats::terms(mf_hu)
      )
    } else {
      list(
        mu = stats::delete.response(stats::terms(mf_mu)),
        sigma = stats::terms(mf_sigma)
      )
    },
    model_frame = if (has_hu) {
      list(mu = mf_mu, sigma = mf_sigma, hu = mf_hu)
    } else {
      list(mu = mf_mu, sigma = mf_sigma)
    },
    random = list(
      mu = re_mu,
      sigma = empty_random_sigma_structure(nrow(data_model))
    ),
    random_scale = list(
      mu = empty_sd_mu_structure(re_mu$n_re),
      phylo = empty_sd_phylo_structure()
    ),
    structured = list(phylo_mu = phylo_mu),
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = if (has_hu) c("mu", "sigma", "hu") else c("mu", "sigma"),
    start = if (has_hu) {
      hurdle_nbinom2_start(y, X_mu, X_sigma, X_hu, phylo_mu = phylo_mu)
    } else {
      truncated_nbinom2_start(y, X_mu, X_sigma, re_mu = re_mu)
    },
    map = if (has_hu) {
      hurdle_nbinom2_map(phylo_mu = phylo_mu)
    } else {
      truncated_nbinom2_map(re_mu)
    },
    random_names = c(
      if (re_mu$n_re > 0L) "u_mu",
      if (isTRUE(phylo_mu$has)) "u_phylo"
    )
  )
  spec$tmb_data <- add_covariance_block_tmb_data(
    make_tmb_data(spec),
    spec
  )
  spec$nobs <- length(spec$y)
  spec
}


drm_build_biv_gaussian_spec <- function(
  formula,
  data,
  env = parent.frame(),
  weights = NULL,
  missing = miss_control()
) {
  missing <- drm_parse_missing_control(missing)
  include_missing_response <- identical(missing$response, "include")

  entries <- expand_biv_mvbind_entries(formula$entries)
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  is_corpair_dpar <- vapply(
    entries,
    function(entry) is.list(entry$corpair),
    logical(1L)
  )
  corpair_entries <- entries[is_corpair_dpar]
  entries <- entries[!is_corpair_dpar]
  dpars <- dpars[!is_corpair_dpar]
  is_sd_mu_dpar <- startsWith(dpars, "sd1(") | startsWith(dpars, "sd2(")
  is_sd_phylo_dpar <- startsWith(dpars, "sd_phylo1(") |
    startsWith(dpars, "sd_phylo2(")
  is_sd_dpar <- is_sd_mu_dpar | is_sd_phylo_dpar
  allowed <- c("mu1", "mu2", "sigma1", "sigma2", "rho12")
  unsupported <- setdiff(dpars[!is_sd_dpar], allowed)
  if (length(unsupported) > 0L) {
    cli::cli_abort(c(
      "{.fn biv_gaussian} models only support {.code mu1}, {.code mu2}, {.code sigma1}, {.code sigma2}, {.code rho12}, bivariate ordinary location random-effect SD formulas {.code sd1(group)} / {.code sd2(group)}, bivariate phylogenetic location random-effect SD formulas {.code sd_phylo1(group)} / {.code sd_phylo2(group)}, and the first ordinary or phylogenetic location-location {.fn corpair} formulas.",
      "x" = "Unsupported parameter{?s}: {.val {unsupported}}."
    ))
  }
  for (required in c("mu1", "mu2")) {
    if (sum(dpars == required) != 1L) {
      cli::cli_abort(
        "{.fn biv_gaussian} requires exactly one {.code {required}} formula."
      )
    }
  }
  for (optional in c("sigma1", "sigma2", "rho12")) {
    if (sum(dpars == optional) > 1L) {
      cli::cli_abort(
        "{.fn biv_gaussian} can have at most one {.code {optional}} formula."
      )
    }
  }
  sd_mu_entries <- if (any(is_sd_mu_dpar)) {
    entries[is_sd_mu_dpar]
  } else {
    list()
  }
  sd_phylo_entries <- if (any(is_sd_phylo_dpar)) {
    entries[is_sd_phylo_dpar]
  } else {
    list()
  }

  mu1_entry <- entries[[which(dpars == "mu1")]]
  mu2_entry <- entries[[which(dpars == "mu2")]]
  sigma1_entry <- if (any(dpars == "sigma1")) {
    entries[[which(dpars == "sigma1")]]
  } else {
    default_dpar_entry("sigma1", quote(1))
  }
  sigma2_entry <- if (any(dpars == "sigma2")) {
    entries[[which(dpars == "sigma2")]]
  } else {
    default_dpar_entry("sigma2", quote(1))
  }
  rho12_entry <- if (any(dpars == "rho12")) {
    entries[[which(dpars == "rho12")]]
  } else {
    default_dpar_entry("rho12", quote(1))
  }

  if (is.na(mu1_entry$response) || is.na(mu2_entry$response)) {
    cli::cli_abort(
      "{.code mu1} and {.code mu2} formulas must include responses on the left-hand side."
    )
  }

  meta_mu1 <- extract_meta_known_v(mu1_entry$rhs)
  meta_mu2 <- extract_meta_known_v(mu2_entry$rhs)
  if (!is.null(meta_mu1$V) && !is.null(meta_mu2$V)) {
    cli::cli_abort(c(
      "Only one {.fn meta_V} term is supported in a bivariate model.",
      "i" = "{.fn meta_V} is a model-level known-covariance marker even if it appears in a location formula."
    ))
  }
  mu1_entry$rhs <- meta_mu1$rhs
  mu2_entry$rhs <- meta_mu2$rhs
  meta <- if (!is.null(meta_mu1$V)) meta_mu1 else meta_mu2

  structured_q4_terms <- list(
    phylo = detect_biv_phylo_q4_terms(
      mu1_entry,
      mu2_entry,
      sigma1_entry,
      sigma2_entry
    ),
    spatial = detect_biv_spatial_q4_terms(
      mu1_entry,
      mu2_entry,
      sigma1_entry,
      sigma2_entry
    ),
    animal = detect_biv_known_q4_terms(
      mu1_entry,
      mu2_entry,
      sigma1_entry,
      sigma2_entry,
      "animal"
    ),
    relmat = detect_biv_known_q4_terms(
      mu1_entry,
      mu2_entry,
      sigma1_entry,
      sigma2_entry,
      "relmat"
    )
  )
  active_structured_q4 <- names(structured_q4_terms)[
    vapply(structured_q4_terms, `[[`, logical(1L), "has")
  ]
  if (length(active_structured_q4) > 1L) {
    cli::cli_abort(c(
      "Bivariate q=4 structured location-scale blocks can use one structured source at a time.",
      "x" = "Structured q=4 sources supplied: {.val {active_structured_q4}}.",
      "i" = "Fit one of {.fn phylo}, {.fn spatial}, {.fn animal}, or {.fn relmat} first; combined structural layers need separate identifiability checks."
    ))
  }

  phylo_mu_terms <- NULL
  spatial_mu_terms <- NULL
  animal_mu_terms <- NULL
  relmat_mu_terms <- NULL
  if (length(active_structured_q4) == 1L) {
    q4_marker <- active_structured_q4[[1L]]
    q4_terms <- structured_q4_terms[[q4_marker]]
    if (identical(q4_marker, "phylo") && length(sd_phylo_entries) > 0L) {
      cli::cli_abort(c(
        "Do not combine bivariate {.fn sd_phylo1} / {.fn sd_phylo2} formulas with a phylogenetic q=4 location-scale block.",
        "x" = "The matching labelled {.fn phylo} terms across {.code mu1}, {.code mu2}, {.code sigma1}, and {.code sigma2} already define a Family A q=4 covariance block.",
        "i" = "Use bivariate {.fn sd_phylo1} / {.fn sd_phylo2} only with matching phylogenetic location terms in {.code mu1} and {.code mu2}."
      ))
    }
    mu1_entry$rhs <- remove_structured_marker_terms(mu1_entry$rhs, q4_marker)
    mu2_entry$rhs <- remove_structured_marker_terms(mu2_entry$rhs, q4_marker)
    sigma1_entry$rhs <- remove_structured_marker_terms(
      sigma1_entry$rhs,
      q4_marker
    )
    sigma2_entry$rhs <- remove_structured_marker_terms(
      sigma2_entry$rhs,
      q4_marker
    )
    q4_mu_terms <- list(
      mu1 = list(rhs = mu1_entry$rhs, term = NULL),
      mu2 = list(rhs = mu2_entry$rhs, term = NULL),
      term = q4_terms$term
    )
    phylo_mu_terms <- if (identical(q4_marker, "phylo")) {
      q4_mu_terms
    } else {
      list(
        mu1 = list(rhs = mu1_entry$rhs, term = NULL),
        mu2 = list(rhs = mu2_entry$rhs, term = NULL),
        term = NULL
      )
    }
    spatial_mu_terms <- if (identical(q4_marker, "spatial")) {
      q4_mu_terms
    } else {
      list(
        mu1 = list(rhs = mu1_entry$rhs, term = NULL),
        mu2 = list(rhs = mu2_entry$rhs, term = NULL),
        term = NULL
      )
    }
    animal_mu_terms <- if (identical(q4_marker, "animal")) {
      q4_mu_terms
    } else {
      list(
        mu1 = list(rhs = mu1_entry$rhs, term = NULL),
        mu2 = list(rhs = mu2_entry$rhs, term = NULL),
        term = NULL
      )
    }
    relmat_mu_terms <- if (identical(q4_marker, "relmat")) {
      q4_mu_terms
    } else {
      list(
        mu1 = list(rhs = mu1_entry$rhs, term = NULL),
        mu2 = list(rhs = mu2_entry$rhs, term = NULL),
        term = NULL
      )
    }
  }

  if (is.null(spatial_mu_terms)) {
    spatial_mu_terms <- guard_biv_spatial_mu_terms(mu1_entry, mu2_entry)
    mu1_entry$rhs <- spatial_mu_terms$mu1$rhs
    mu2_entry$rhs <- spatial_mu_terms$mu2$rhs
  }
  if (is.null(phylo_mu_terms)) {
    phylo_mu_terms <- guard_biv_phylo_mu_terms(mu1_entry, mu2_entry)
    mu1_entry$rhs <- phylo_mu_terms$mu1$rhs
    mu2_entry$rhs <- phylo_mu_terms$mu2$rhs
  }
  if (is.null(animal_mu_terms)) {
    animal_mu_terms <- guard_biv_known_mu_terms(mu1_entry, mu2_entry, "animal")
    mu1_entry$rhs <- animal_mu_terms$mu1$rhs
    mu2_entry$rhs <- animal_mu_terms$mu2$rhs
  }
  if (is.null(relmat_mu_terms)) {
    relmat_mu_terms <- guard_biv_known_mu_terms(mu1_entry, mu2_entry, "relmat")
    mu1_entry$rhs <- relmat_mu_terms$mu1$rhs
    mu2_entry$rhs <- relmat_mu_terms$mu2$rhs
  }

  active_structured_mu <- list(
    spatial = spatial_mu_terms$term,
    phylo = phylo_mu_terms$term,
    animal = animal_mu_terms$term,
    relmat = relmat_mu_terms$term
  )
  active_structured_mu <- names(active_structured_mu)[
    !vapply(active_structured_mu, is.null, logical(1L))
  ]
  if (length(active_structured_mu) > 1L) {
    cli::cli_abort(c(
      "Bivariate Gaussian models can use one structured location-covariance source at a time.",
      "x" = "Structured sources supplied: {.val {active_structured_mu}}.",
      "i" = "Fit one matched structured block at a time; combined phylogenetic, spatial, animal, or relatedness covariance layers need a separate identifiability design."
    ))
  }
  structured_mu_terms <- if (!is.null(spatial_mu_terms$term)) {
    spatial_mu_terms
  } else if (!is.null(phylo_mu_terms$term)) {
    phylo_mu_terms
  } else if (!is.null(animal_mu_terms$term)) {
    animal_mu_terms
  } else {
    relmat_mu_terms
  }

  mu1_re <- extract_random_mu_terms(mu1_entry$rhs, "mu1")
  mu1_entry$rhs <- mu1_re$rhs
  mu2_re <- extract_random_mu_terms(mu2_entry$rhs, "mu2")
  mu2_entry$rhs <- mu2_re$rhs
  sigma1_re <- extract_random_sigma_terms(sigma1_entry$rhs, "sigma1")
  sigma1_entry$rhs <- sigma1_re$rhs
  sigma2_re <- extract_random_sigma_terms(sigma2_entry$rhs, "sigma2")
  sigma2_entry$rhs <- sigma2_re$rhs
  q4_covariance_blocks <- detect_biv_q4_covariance_blocks(
    mu1_re$terms,
    mu2_re$terms,
    sigma1_re$terms,
    sigma2_re$terms
  )
  mu_qgt2_covariance_blocks <- if (length(q4_covariance_blocks) > 0L) {
    list()
  } else {
    detect_biv_mu_qgt2_covariance_blocks(
      mu1_re$terms,
      mu2_re$terms
    )
  }
  reject_biv_sd_mu_q4_mixture(sd_mu_entries, q4_covariance_blocks)
  if (
    !is.null(meta$V) &&
      (length(mu1_re$terms) > 0L ||
        length(mu2_re$terms) > 0L ||
        length(sigma1_re$terms) > 0L ||
        length(sigma2_re$terms) > 0L ||
        !is.null(structured_mu_terms$term))
  ) {
    cli::cli_abort(c(
      "Bivariate Gaussian random effects cannot yet be combined with {.fn meta_V}.",
      "i" = "Fit bivariate group-level covariance blocks without known sampling covariance first."
    ))
  }
  if (length(q4_covariance_blocks) == 0L) {
    reject_biv_cross_parameter_label_reuse(
      mu1_re$terms,
      mu2_re$terms,
      sigma1_re$terms,
      sigma2_re$terms
    )
  }
  active_qgt2_covariance_blocks <- c(
    q4_covariance_blocks,
    mu_qgt2_covariance_blocks
  )
  active_mu1_terms <- remove_biv_q4_terms(
    mu1_re$terms,
    active_qgt2_covariance_blocks
  )
  active_mu2_terms <- remove_biv_q4_terms(
    mu2_re$terms,
    active_qgt2_covariance_blocks
  )
  active_sigma1_terms <- remove_biv_q4_terms(
    sigma1_re$terms,
    q4_covariance_blocks
  )
  active_sigma2_terms <- remove_biv_q4_terms(
    sigma2_re$terms,
    q4_covariance_blocks
  )

  for (entry in list(
    mu1_entry,
    mu2_entry,
    sigma1_entry,
    sigma2_entry,
    rho12_entry
  )) {
    drm_reject_phase1_terms(entry$rhs, entry$dpar)
  }
  for (sd_mu_entry in sd_mu_entries) {
    drm_reject_phase1_terms(sd_mu_entry$rhs, sd_mu_entry$dpar)
  }
  for (sd_phylo_entry in sd_phylo_entries) {
    drm_reject_phase1_terms(sd_phylo_entry$rhs, sd_phylo_entry$dpar)
  }

  f_mu1 <- drm_entry_formula(mu1_entry, response = TRUE)
  f_mu2 <- drm_entry_formula(mu2_entry, response = TRUE)
  f_sigma1 <- drm_entry_formula(sigma1_entry, response = FALSE)
  f_sigma2 <- drm_entry_formula(sigma2_entry, response = FALSE)
  f_rho12 <- drm_entry_formula(rho12_entry, response = FALSE)
  f_sd_mu <- lapply(sd_mu_entries, drm_entry_formula, response = FALSE)
  f_sd_phylo <- lapply(sd_phylo_entries, drm_entry_formula, response = FALSE)
  f_corpair <- lapply(corpair_entries, drm_entry_formula, response = FALSE)
  mu1_model_vars <- if (include_missing_response) {
    all.vars(stats::delete.response(stats::terms(f_mu1)))
  } else {
    all.vars(f_mu1)
  }
  mu2_model_vars <- if (include_missing_response) {
    all.vars(stats::delete.response(stats::terms(f_mu2)))
  } else {
    all.vars(f_mu2)
  }
  sd_mu_groups <- vapply(
    sd_mu_entries,
    function(entry) parse_sd_lhs(entry$lhs)$group,
    character(1L)
  )
  sd_phylo_groups <- vapply(
    sd_phylo_entries,
    function(entry) parse_sd_lhs(entry$lhs)$group,
    character(1L)
  )
  corpair_groups <- vapply(
    corpair_entries,
    function(entry) entry$corpair$group,
    character(1L)
  )

  vars <- unique(c(
    mu1_model_vars,
    mu2_model_vars,
    all.vars(f_sigma1),
    all.vars(f_sigma2),
    all.vars(f_rho12),
    unlist(lapply(f_sd_mu, all.vars), use.names = FALSE),
    unlist(lapply(f_sd_phylo, all.vars), use.names = FALSE),
    unlist(lapply(f_corpair, all.vars), use.names = FALSE),
    structured_mu_vars(structured_mu_terms$term),
    sd_mu_groups,
    sd_phylo_groups,
    corpair_groups,
    random_effect_vars(mu1_re$terms),
    random_effect_vars(mu2_re$terms),
    random_effect_vars(sigma1_re$terms),
    random_effect_vars(sigma2_re$terms)
  ))
  keep <- stats::complete.cases(data[, vars, drop = FALSE])
  if (include_missing_response && any(!keep)) {
    cli::cli_abort(c(
      "Missing predictors, grouping variables, or structured-effect inputs are not implemented for bivariate Gaussian response masks in MD2.",
      "i" = "Use complete predictors with {.code missing = miss_control(response = \"include\")}, or keep the default complete-case response policy."
    ))
  }
  data_model <- data[keep, , drop = FALSE]
  V_known_full <- evaluate_biv_known_v(meta$V, data, env)
  V_known <- subset_biv_known_v(V_known_full, keep)
  weights_model <- subset_likelihood_weights(
    weights,
    keep,
    nrow(data),
    sum(keep)
  )

  model_na_action <- if (include_missing_response) {
    stats::na.pass
  } else {
    stats::na.omit
  }

  mf_mu1 <- stats::model.frame(
    f_mu1,
    data = data_model,
    na.action = model_na_action
  )
  mf_mu2 <- stats::model.frame(
    f_mu2,
    data = data_model,
    na.action = model_na_action
  )
  mf_sigma1 <- stats::model.frame(
    f_sigma1,
    data = data_model,
    na.action = model_na_action
  )
  mf_sigma2 <- stats::model.frame(
    f_sigma2,
    data = data_model,
    na.action = model_na_action
  )
  mf_rho12 <- stats::model.frame(
    f_rho12,
    data = data_model,
    na.action = model_na_action
  )

  y1_raw <- stats::model.response(mf_mu1)
  y2_raw <- stats::model.response(mf_mu2)
  observed_y1 <- !is.na(y1_raw)
  observed_y2 <- !is.na(y2_raw)
  if (!include_missing_response && any(!observed_y1 | !observed_y2)) {
    cli::cli_abort("Internal bivariate Gaussian complete-case filtering error.")
  }
  if (!any(observed_y1 | observed_y2)) {
    cli::cli_abort(
      "No observations with at least one observed response remain after applying bivariate response missingness rules."
    )
  }
  response_sentinel <- if (include_missing_response) {
    drm_missing_response_sentinel()
  } else {
    NA_real_
  }
  y1 <- as.numeric(y1_raw)
  y2 <- as.numeric(y2_raw)
  if (include_missing_response) {
    y1[!observed_y1] <- response_sentinel
    y2[!observed_y2] <- response_sentinel
  }
  if (
    include_missing_response &&
      identical(V_known$type, "matrix") &&
      any(!observed_y1 | !observed_y2)
  ) {
    cli::cli_abort(c(
      "Bivariate response-missingness masks are not implemented for dense known sampling covariance matrices in MD2.",
      "i" = "Use complete response pairs with {.fn meta_V}, or fit the independent-observation bivariate Gaussian slice first."
    ))
  }
  X_mu1 <- stats::model.matrix(
    stats::delete.response(stats::terms(mf_mu1)),
    mf_mu1
  )
  X_mu2 <- stats::model.matrix(
    stats::delete.response(stats::terms(mf_mu2)),
    mf_mu2
  )
  X_sigma1 <- stats::model.matrix(stats::terms(mf_sigma1), mf_sigma1)
  X_sigma2 <- stats::model.matrix(stats::terms(mf_sigma2), mf_sigma2)
  X_rho12 <- stats::model.matrix(stats::terms(mf_rho12), mf_rho12)
  if (include_missing_response) {
    drm_warn_weak_biv_rho12_identifiability(
      complete_pairs = sum(observed_y1 & observed_y2),
      rho12_parameter_count = ncol(X_rho12)
    )
  }
  re_mu_registry <- build_biv_mu_random_structure(
    mu1_re$terms,
    mu2_re$terms,
    data_model
  )
  re_sigma_registry <- build_biv_sigma_random_structure(
    sigma1_re$terms,
    sigma2_re$terms,
    data_model,
    allow_qgt2 = length(q4_covariance_blocks) > 0L
  )
  re_mu <- build_biv_mu_random_structure(
    active_mu1_terms,
    active_mu2_terms,
    data_model
  )
  phylo_mu <- build_structured_mu_structure(
    structured_mu_terms$term,
    data_model,
    env
  )
  re_mu$cor_model <- build_biv_mu_corpair_model(
    corpair_entries,
    f_corpair,
    re_mu,
    phylo_mu,
    data_model
  )
  sd_mu_targets <- parse_biv_sd_mu_entries(sd_mu_entries, re_mu)
  re_sigma <- build_biv_sigma_random_structure(
    active_sigma1_terms,
    active_sigma2_terms,
    data_model
  )
  sd_mu <- build_sd_mu_structure(
    sd_mu_entries,
    sd_mu_targets,
    re_mu,
    data_model
  )
  sd_phylo_targets <- parse_biv_sd_phylo_entries(
    sd_phylo_entries,
    phylo_mu
  )
  if (
    isTRUE(corpair_model_is_phylogenetic(re_mu$cor_model)) &&
      length(sd_phylo_entries) > 0L
  ) {
    cli::cli_abort(c(
      "Do not combine phylogenetic {.fn corpair} regression with bivariate {.fn sd_phylo1} / {.fn sd_phylo2} formulas in this phase.",
      "x" = "{.fn corpair} changes the phylogenetic location-location correlation surface, while {.fn sd_phylo1} / {.fn sd_phylo2} model direct location random-effect SD surfaces.",
      "i" = "Fit the predictor-dependent phylogenetic correlation route first with constant phylogenetic SDs."
    ))
  }
  sd_phylo <- build_sd_phylo_structure(
    sd_phylo_entries,
    sd_phylo_targets,
    phylo_mu,
    data_model
  )
  re_mu_sigma <- build_mu_sigma_random_covariance(re_mu, re_sigma)
  validate_biv_random_covariance_surface(re_mu, re_sigma, re_mu_sigma)
  re_cov_blocks <- build_labelled_covariance_block_registry(
    re_mu,
    re_sigma,
    re_mu_sigma,
    q4_blocks = q4_covariance_blocks,
    mu_qgt2_blocks = mu_qgt2_covariance_blocks,
    re_mu_full = re_mu_registry,
    re_sigma_full = re_sigma_registry
  )

  n <- length(y1)
  if (n == 0L) {
    cli::cli_abort(
      "No complete observations remain after applying bivariate model missingness rules."
    )
  }
  if (!all(c(length(y2), nrow(X_sigma1), nrow(X_sigma2), nrow(X_rho12)) == n)) {
    cli::cli_abort("Internal model-frame mismatch in bivariate Gaussian model.")
  }

  start <- biv_gaussian_start(
    y1,
    y2,
    X_mu1,
    X_mu2,
    X_sigma1,
    X_sigma2,
    X_rho12,
    V_known_diag = V_known$diag,
    re_mu = re_mu,
    re_sigma = re_sigma,
    re_mu_sigma = re_mu_sigma,
    phylo_mu = phylo_mu,
    sd_mu = sd_mu,
    sd_phylo = sd_phylo,
    re_cov_blocks = re_cov_blocks,
    observed_y1 = observed_y1,
    observed_y2 = observed_y2
  )
  missing_data <- new_drm_biv_missing_data(
    control = missing,
    original_row = which(keep),
    model_row = seq_along(y1),
    observed_y1 = observed_y1,
    observed_y2 = observed_y2,
    response_sentinel = response_sentinel
  )

  spec <- list(
    model_type = "biv_gaussian",
    y1 = as.numeric(y1),
    y2 = as.numeric(y2),
    weights = weights_model,
    V_known = V_known$V,
    V_known_diag = V_known$diag,
    V_known_type = V_known$type,
    has_known_v = !is.null(meta$V),
    X = c(
      list(
        mu1 = X_mu1,
        mu2 = X_mu2,
        sigma1 = X_sigma1,
        sigma2 = X_sigma2,
        rho12 = X_rho12
      ),
      sd_mu$X_list,
      sd_phylo$X_list,
      re_mu$cor_model$X_list
    ),
    terms = c(
      list(
        mu1 = stats::delete.response(stats::terms(mf_mu1)),
        mu2 = stats::delete.response(stats::terms(mf_mu2)),
        sigma1 = stats::terms(mf_sigma1),
        sigma2 = stats::terms(mf_sigma2),
        rho12 = stats::terms(mf_rho12)
      ),
      sd_mu$terms_list,
      sd_phylo$terms_list,
      re_mu$cor_model$terms_list
    ),
    model_frame = c(
      list(
        mu1 = mf_mu1,
        mu2 = mf_mu2,
        sigma1 = mf_sigma1,
        sigma2 = mf_sigma2,
        rho12 = mf_rho12
      ),
      sd_mu$model_frame_list,
      sd_phylo$model_frame_list,
      re_mu$cor_model$model_frame_list
    ),
    data = data_model,
    random = list(
      mu = re_mu,
      sigma = re_sigma,
      mu_sigma = re_mu_sigma,
      covariance_blocks = re_cov_blocks
    ),
    random_scale = list(mu = sd_mu, phylo = sd_phylo),
    structured = list(phylo_mu = phylo_mu),
    variables = vars,
    keep = keep,
    missing_data = missing_data,
    dpars = c(
      "mu1",
      "mu2",
      "sigma1",
      "sigma2",
      "rho12",
      sd_mu$dpars,
      sd_phylo$dpars,
      re_mu$cor_model$dpars
    ),
    start = start,
    map = biv_gaussian_map(
      re_mu,
      re_sigma,
      re_mu_sigma,
      phylo_mu,
      sd_mu,
      sd_phylo
    ),
    random_names = c(
      if (re_mu$n_re > 0L) "u_mu",
      if (re_sigma$n_re > 0L) "u_sigma",
      if (re_cov_blocks$n_qgt2_re > 0L) "u_re_cov",
      if (isTRUE(phylo_mu$has)) "u_phylo"
    )
  )
  check_weights_known_covariance(spec)
  spec$tmb_data <- add_covariance_block_tmb_data(
    make_tmb_data(spec),
    spec
  )
  spec$nobs <- spec$missing_data$counts$likelihood_rows
  spec
}

expand_biv_mvbind_entries <- function(entries) {
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  has_mvbind <- vapply(
    entries,
    function(entry) {
      is_mvbind_lhs(entry$lhs)
    },
    logical(1)
  )

  if (!any(has_mvbind)) {
    return(entries)
  }
  if (sum(has_mvbind) > 1L) {
    cli::cli_abort(
      "{.fn mvbind} shorthand can appear only once in a bivariate model."
    )
  }

  mvbind_index <- which(has_mvbind)
  if (!identical(dpars[[mvbind_index]], "mu")) {
    cli::cli_abort(
      "{.fn mvbind} shorthand must be an unnamed bivariate location formula."
    )
  }
  if (any(dpars %in% c("mu1", "mu2"))) {
    cli::cli_abort(c(
      "{.fn mvbind} shorthand cannot be combined with explicit {.code mu1} or {.code mu2} formulas.",
      "i" = "Use either {.code mvbind(y1, y2) ~ x} for identical location predictors or separate {.code mu1 = y1 ~ ...} and {.code mu2 = y2 ~ ...} formulas."
    ))
  }

  responses <- parse_mvbind_lhs(entries[[mvbind_index]]$lhs)
  mu1_entry <- mvbind_location_entry(
    entries[[mvbind_index]],
    "mu1",
    responses[[1L]]
  )
  mu2_entry <- mvbind_location_entry(
    entries[[mvbind_index]],
    "mu2",
    responses[[2L]]
  )

  before <- if (mvbind_index > 1L) {
    entries[seq_len(mvbind_index - 1L)]
  } else {
    list()
  }
  after <- if (mvbind_index < length(entries)) {
    entries[seq.int(mvbind_index + 1L, length(entries))]
  } else {
    list()
  }
  out <- c(before, list(mu1_entry, mu2_entry), after)
  class(out) <- class(entries)
  out
}

is_mvbind_lhs <- function(lhs) {
  lhs <- strip_parens(lhs)
  is.call(lhs) && identical(lhs[[1L]], as.name("mvbind"))
}

is_cbind_lhs <- function(lhs) {
  lhs <- strip_parens(lhs)
  is.call(lhs) && identical(lhs[[1L]], as.name("cbind"))
}

parse_mvbind_lhs <- function(lhs) {
  lhs <- strip_parens(lhs)
  args <- as.list(lhs)[-1L]
  arg_names <- names(args)
  if (is.null(arg_names)) {
    arg_names <- rep("", length(args))
  }
  arg_names[is.na(arg_names)] <- ""
  valid <- length(args) == 2L &&
    all(!nzchar(arg_names)) &&
    all(vapply(args, is.symbol, logical(1)))
  if (!valid) {
    cli::cli_abort(c(
      "{.fn mvbind} shorthand currently requires exactly two unnamed response variables.",
      "x" = "Use syntax like {.code mvbind(y1, y2) ~ x}.",
      "i" = "For different location predictors, use explicit {.code mu1 = y1 ~ ...} and {.code mu2 = y2 ~ ...} formulas."
    ))
  }
  vapply(args, as.character, character(1))
}

mvbind_location_entry <- function(entry, dpar, response) {
  entry$dpar <- dpar
  entry$response <- response
  entry$lhs <- as.name(response)
  entry$expr <- call("~", as.name(response), entry$rhs)
  entry$source_name <- dpar
  entry$structured <- collect_structured_effects(entry$rhs, dpar)
  entry
}

default_dpar_entry <- function(dpar, rhs) {
  list(
    position = NA_integer_,
    dpar = dpar,
    response = NA_character_,
    lhs = NULL,
    rhs = rhs,
    expr = call("~", rhs),
    source_name = dpar,
    structured = list()
  )
}

drm_entry_formula <- function(entry, response = FALSE) {
  if (response) {
    lhs <- if (!is.null(entry$lhs)) entry$lhs else as.name(entry$response)
    expr <- call("~", lhs, entry$rhs)
  } else {
    expr <- call("~", entry$rhs)
  }
  stats::as.formula(expr, env = parent.frame())
}

drm_reject_phase1_terms <- function(rhs, dpar, allow_offset = FALSE) {
  structured_markers <- structured_marker_names()
  structured <- structured_markers[vapply(
    structured_markers,
    function(name) formula_contains_call(rhs, name),
    logical(1)
  )]
  if (length(structured) > 0L) {
    message <- c(
      "Structured-effect syntax is planned, not implemented.",
      "x" = "The {.code {dpar}} formula contains structured marker{?s}: {.val {structured}}.",
      "i" = "Implemented structured paths cover the fitted Gaussian {.fn phylo}, {.fn spatial}, {.fn animal}, and {.fn relmat} slices, ordinary Poisson/NB2 q=1 {.code mu} intercept slices for {.fn phylo}, {.fn phylo_interaction}, {.fn spatial}, {.fn animal}, and {.fn relmat}, ordinary Poisson/NB2 q=1 {.code mu} unlabelled one-slope slices for {.fn phylo}, {.fn spatial}, {.fn animal}, and {.fn relmat}, and ordinary NB2 q=1 {.code sigma} unlabelled one-slope slices for {.fn phylo}, {.fn spatial}, {.fn animal}, and {.fn relmat}.",
      "i" = "Structured non-Gaussian paths beyond those count gates, including bounded, ordinal, shape, inflation, hurdle, labelled count covariance, structured count slope-only routes outside the admitted Poisson fixed-covariance spatial slope-only gate, multiple structured count slopes, and structured count scale routes outside the NB2 one-slope gate, remain deferred until family-specific recovery evidence is stable."
    )
    cli::cli_abort(message)
  }

  unsupported <- c("|", "meta_known_V", "meta_V", "gr", "phylo", "spatial")
  if (!isTRUE(allow_offset)) {
    unsupported <- c(unsupported, "offset")
  }
  hits <- unsupported[vapply(
    unsupported,
    function(name) formula_contains_call(rhs, name),
    logical(1)
  )]
  if (length(hits) > 0L) {
    if ("|" %in% hits && dpar %in% c("zi", "hu", "zoi", "coi")) {
      cli::cli_abort(c(
        "{inflation_random_effect_label(dpar)} random effects are not implemented.",
        "x" = "The {.code {dpar}} formula contains a random-effect bar term.",
        "i" = "Keep the {.code {dpar}} formula fixed-effect for now, such as {.code {dpar} ~ x}.",
        "i" = "Inflation, hurdle, and one-inflation random effects need family-specific likelihood, extractor, interval, and recovery-test support before fitting.",
        "i" = "Cross-parameter covariance with {.code mu}, {.code sigma}, or shape random effects remains future work after the separate random-effect paths are stable."
      ))
    }
    if ("|" %in% hits && dpar %in% c("nu", "tau")) {
      cli::cli_abort(c(
        "Shape random effects are not implemented.",
        "x" = "The {.code {dpar}} formula contains a random-effect bar term.",
        "i" = "Keep shape formulas fixed-effect for now, such as {.code nu ~ x}.",
        "i" = "Student-t {.code nu} models tail shape; skew-normal fixed-effect {.code nu} models residual slant; skew-normal and skew-t shape random effects need separate likelihood recovery before fitting.",
        "i" = "Latent group-level skewness, such as future {.code skew(id) ~ x}, remains design-only until simulations separate it from residual skewness and heteroscedasticity."
      ))
    }
    if ("|" %in% hits && identical(dpar, "sigma")) {
      cli::cli_abort(c(
        "Non-Gaussian {.code sigma} random effects are not implemented.",
        "x" = "The {.code sigma} formula contains a random-effect bar term.",
        "i" = "Keep non-Gaussian scale formulas fixed-effect for now, such as {.code sigma ~ z}.",
        "i" = "Gaussian residual-scale random effects are implemented separately; ordinary NB2 has only its first log-sigma random-intercept gate, while Student-t, lognormal, Gamma, beta, beta-binomial, truncated NB2, and hurdle NB2 scale random effects need family-specific likelihood and recovery tests before fitting."
      ))
    }
    if (
      "|" %in% hits && dpar %in% c("mu1", "mu2", "sigma1", "sigma2", "rho12")
    ) {
      cli::cli_abort(c(
        "This bivariate random-effect syntax is not implemented.",
        "x" = "The {.code {dpar}} formula contains unsupported model terms: {.val {hits}}.",
        "i" = "Implemented bivariate random-effect paths are matching labelled random intercepts in {.code mu1}/{.code mu2}, same-response {.code mu}/{.code sigma}, or {.code sigma1}/{.code sigma2}; matching slope-only {.code mu1}/{.code mu2}, same-response {.code mu}/{.code sigma}, or {.code sigma1}/{.code sigma2} blocks such as {.code (0 + x | p | id)}; and selected q > 2 location blocks.",
        "i" = "Residual {.code rho12} is a within-observation correlation, not a group-level random-effect correlation."
      ))
    }
    if ("|" %in% hits) {
      cli::cli_abort(c(
        "This formula contains unsupported model terms.",
        "x" = "The {.code {dpar}} formula contains unsupported term{?s}: {.val {hits}}.",
        "i" = "Only selected one-response non-Gaussian {.code mu} formulas fit ordinary unlabelled random intercepts and independent numeric slopes.",
        "i" = "Unsupported family paths and parameters retain explicit messages until their likelihood, extractor, diagnostic, and recovery tests exist."
      ))
    }
    cli::cli_abort(c(
      "This formula contains unsupported model terms.",
      "x" = "The {.code {dpar}} formula contains unsupported term{?s}: {.val {hits}}."
    ))
  }
}

formula_contains_structured_marker <- function(rhs) {
  any(vapply(
    structured_marker_names(),
    function(name) formula_contains_call(rhs, name),
    logical(1)
  ))
}

inflation_random_effect_label <- function(dpar) {
  switch(
    dpar,
    zi = "Zero-inflation",
    hu = "Hurdle",
    zoi = "Zero-one-inflation",
    coi = "One-inflation",
    "Inflation"
  )
}

reject_planned_bounded_inflation <- function(
  entries,
  unsupported,
  family_label
) {
  inflation <- intersect(unsupported, c("zoi", "coi"))
  if (length(inflation) == 0L) {
    return(invisible(NULL))
  }
  entry_dpars <- vapply(entries, `[[`, character(1), "dpar")
  inflation_entries <- entries[entry_dpars %in% inflation]
  has_random <- any(vapply(
    inflation_entries,
    function(entry) formula_contains_call(entry$rhs, "|"),
    logical(1)
  ))
  if (has_random) {
    cli::cli_abort(c(
      "Zero-one-inflated bounded-response random effects are not implemented.",
      "x" = "{family_label} models do not support distributional parameter{?s}: {.val {inflation}}.",
      "i" = "Implement fixed-effect {.code zoi} and {.code coi} likelihoods first for exact-zero and exact-one proportions.",
      "i" = "Random effects and cross-parameter covariance for {.code zoi} and {.code coi} come later, after bounded-response recovery tests and interval checks."
    ))
  }
  cli::cli_abort(c(
    "Zero-one-inflated bounded-response likelihoods are planned, not implemented.",
    "x" = "{family_label} models do not support distributional parameter{?s}: {.val {inflation}}.",
    "i" = "Use strict {.fn beta} or denominator-aware {.fn beta_binomial} models for data without exact boundary values.",
    "i" = "Future fixed-effect {.code zoi} and {.code coi} likelihoods must land before their random effects or covariance blocks."
  ))
}

extract_random_mu_terms <- function(rhs, dpar) {
  terms <- flatten_plus_terms(rhs)
  is_re <- vapply(terms, is_random_bar_call, logical(1))
  if (!any(is_re)) {
    return(list(rhs = rhs, terms = list()))
  }

  re_terms <- lapply(terms[is_re], parse_random_mu_term, dpar = dpar)
  clean_terms <- terms[!is_re]
  list(rhs = rebuild_plus_terms(clean_terms), terms = re_terms)
}

extract_random_sigma_terms <- function(rhs, dpar) {
  terms <- flatten_plus_terms(rhs)
  is_re <- vapply(terms, is_random_bar_call, logical(1))
  if (!any(is_re)) {
    return(list(rhs = rhs, terms = list()))
  }

  re_terms <- lapply(terms[is_re], parse_random_sigma_term, dpar = dpar)
  clean_terms <- terms[!is_re]
  list(rhs = rebuild_plus_terms(clean_terms), terms = re_terms)
}

validate_poisson_mu_random_terms <- function(
  terms,
  has_zi = FALSE,
  family_label = "Poisson",
  inflated_label = "Zero-inflated Poisson"
) {
  if (length(terms) == 0L) {
    return(invisible(terms))
  }
  family_label <- as.character(family_label)[[1L]]
  inflated_label <- as.character(inflated_label)[[1L]]
  if (isTRUE(has_zi)) {
    cli::cli_abort(c(
      "{family_label} {.code mu} random intercepts and slopes are implemented only for ordinary {family_label} models.",
      "x" = "{inflated_label} random effects are planned but not implemented.",
      "i" = "Fit {.code y ~ x + (1 | id) + (0 + x | id)} without a {.code zi} formula, or use a fixed-effect {.code zi ~ predictors} model."
    ))
  }
  unsupported <- vapply(
    terms,
    function(term) {
      !(term$type %in% c("intercept", "slope")) ||
        !is.null(term$covariance_label)
    },
    logical(1L)
  )
  if (any(unsupported)) {
    labels <- vapply(terms[unsupported], `[[`, character(1L), "label")
    cli::cli_abort(c(
      "Only independent {family_label} {.code mu} random intercepts and slopes are implemented in this slice.",
      "x" = "Unsupported random-effect term{?s}: {.code {labels}}.",
      "i" = "Use syntax like {.code count ~ x + (1 | id)} or {.code count ~ x + (0 + x | id)}.",
      "i" = "Correlated {family_label} random-slope blocks and labelled covariance blocks remain planned for a later non-Gaussian random-effect gate."
    ))
  }
  invisible(terms)
}

select_count_mu_structured_term <- function(
  structured_terms,
  family_label,
  allow_pair_types = character(0)
) {
  active_structured <- names(structured_terms)[
    !vapply(structured_terms, is.null, logical(1L))
  ]
  if (
    length(active_structured) == 2L &&
      count_mu_structured_pair_is_admissible(
        structured_terms[active_structured],
        allow_pair_types
      )
  ) {
    # Scoped two-provider location field (M5 row 105): exactly two intercept-only
    # structured `mu` fields, each carrying its OWN group precision (e.g. a
    # spatial coordinate kernel plus a relatedness `Q`). The canonical field
    # order is fixed by the caller's provider list so downstream naming
    # (`spatial_mu` vs `relmat_mu`, `log_sd_phylo` vs `log_sd_phylo2`) is stable.
    return(structured_terms[[active_structured[[1L]]]])
  }
  if (length(active_structured) > 1L) {
    family_label <- as.character(family_label)[[1L]]
    cli::cli_abort(c(
      "Only one structured {.code mu} effect type is implemented per {family_label} count model.",
      "x" = "The model contains structured effect types: {.val {active_structured}}.",
      "i" = "Fit one of {.fn phylo}, {.fn phylo_interaction}, {.fn spatial}, {.fn animal}, or {.fn relmat} at a time until combined structured-dependence recovery tests exist."
    ))
  }
  if (length(active_structured) == 0L) {
    return(NULL)
  }
  structured_terms[[active_structured]]
}

# Exactly-two-provider structured `mu` admission for the scoped second field.
# Both providers must be listed in `allow_pair_types`, be distinct types, and be
# intercept-only (q = 1). Any other combination stays rejected by the caller.
count_mu_structured_pair_is_admissible <- function(
  active_terms,
  allow_pair_types
) {
  if (length(active_terms) != 2L || length(allow_pair_types) < 2L) {
    return(FALSE)
  }
  types <- names(active_terms)
  if (!all(types %in% allow_pair_types) || length(unique(types)) != 2L) {
    return(FALSE)
  }
  all(vapply(active_terms, structured_term_is_intercept_only, logical(1L)))
}

# Select the ordered (primary, secondary) pair when two providers are admitted,
# else `NULL`. Field order follows the caller's provider list so that the first
# provider becomes the primary `phylo_mu` field and the second becomes the
# scoped `phylo_mu2` field.
select_count_mu_structured_pair <- function(
  structured_terms,
  allow_pair_types = character(0)
) {
  active_structured <- names(structured_terms)[
    !vapply(structured_terms, is.null, logical(1L))
  ]
  if (
    length(active_structured) != 2L ||
      !count_mu_structured_pair_is_admissible(
        structured_terms[active_structured],
        allow_pair_types
      )
  ) {
    return(NULL)
  }
  list(
    primary = structured_terms[[active_structured[[1L]]]],
    secondary = structured_terms[[active_structured[[2L]]]]
  )
}

validate_count_structured_mu_term <- function(
  term,
  ordinary_terms,
  has_zi = FALSE,
  allow_structured_plus_ordinary = FALSE,
  structured_plus_ordinary_types = character(0),
  allow_labelled_scalar_structured_mu = FALSE,
  labelled_scalar_structured_mu_types = character(0),
  allow_zero_inflated_structured_mu = FALSE,
  zero_inflated_structured_mu_types = character(0),
  allow_slope_only_structured_mu = FALSE,
  slope_only_structured_mu_types = character(0),
  family_label,
  inflated_label
) {
  if (is.null(term)) {
    return(invisible(NULL))
  }
  family_label <- as.character(family_label)[[1L]]
  inflated_label <- as.character(inflated_label)[[1L]]
  marker <- structured_mu_type(term)
  example <- switch(
    marker,
    phylo = "phylo(1 | species, tree = tree)",
    phylo_interaction = "phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree)",
    spatial = "spatial(1 | site, coords = coords)",
    animal = "animal(1 | id, Ainv = Ainv)",
    relmat = "relmat(1 | id, Q = Q)",
    paste0(marker, "(1 | id, ...)")
  )
  zero_inflated_structured_mu_allowed <- isTRUE(
    allow_zero_inflated_structured_mu
  ) && marker %in% zero_inflated_structured_mu_types
  structured_plus_ordinary_allowed <- isTRUE(
    allow_structured_plus_ordinary
  ) && marker %in% structured_plus_ordinary_types
  labelled_scalar_structured_mu_allowed <- isTRUE(
    allow_labelled_scalar_structured_mu
  ) &&
    marker %in% labelled_scalar_structured_mu_types &&
    !isTRUE(has_zi) &&
    structured_term_is_intercept_only(term)
  slope_only_structured_mu_allowed <- isTRUE(
    allow_slope_only_structured_mu
  ) && marker %in% slope_only_structured_mu_types &&
    structured_term_is_slope_only(term)
  if (isTRUE(has_zi) && !isTRUE(zero_inflated_structured_mu_allowed)) {
    cli::cli_abort(c(
      "{family_label} structured {.code mu} effects are implemented only for ordinary {family_label} models.",
      "x" = "{inflated_label} structured random effects are planned but not implemented.",
      "i" = "Fit {.code count ~ x + {example}} without a {.code zi} formula, or use fixed-effect {.code zi ~ predictors} until zero-inflated structured recovery tests exist."
    ))
  }
  if (
    isTRUE(has_zi) &&
      isTRUE(zero_inflated_structured_mu_allowed) &&
      !structured_term_is_intercept_only(term)
  ) {
    cli::cli_abort(c(
      "{inflated_label} structured {.code mu} effects currently support only the first {.fn {marker}} intercept gate.",
      "x" = "Requested structured coefficient{?s}: {.val {term$coef_names}}.",
      "i" = "Keep structured zero-inflated slopes, labelled q=2/q=4 covariance, intervals, coverage, REML, and AI-REML deferred until row-specific recovery evidence exists."
    ))
  }
  if (length(ordinary_terms) > 0L && !isTRUE(structured_plus_ordinary_allowed)) {
    cli::cli_abort(c(
      "{family_label} structured {.code mu} effects cannot be combined with ordinary {.code mu} random effects in this first gate.",
      "x" = "The formula contains both {.fn {marker}} and ordinary random-effect bar terms.",
      "i" = "Fit the structured count model or the ordinary grouped count model separately until combined-dependence recovery tests exist."
    ))
  }
  if (
    !is.null(term$covariance_label) &&
      !isTRUE(labelled_scalar_structured_mu_allowed)
  ) {
    cli::cli_abort(c(
      "{family_label} structured {.code mu} effects currently support only unlabelled q=1 intercepts.",
      "x" = "Requested labelled structured term: {.code {term$label}}.",
      "i" = "Use {.code {example}}; labelled q=2/q=4 and predictor-dependent structured correlation routes remain planned."
    ))
  }
  count_supported_term <- structured_term_is_intercept_only(term) ||
    structured_term_is_intercept_one_slope(term) ||
    slope_only_structured_mu_allowed
  if (!isTRUE(count_supported_term)) {
    cli::cli_abort(c(
      "{family_label} structured {.code mu} effects currently support only unlabelled intercept-only or one-slope structured terms.",
      "x" = "Requested structured coefficient{?s}: {.val {term$coef_names}}.",
      "i" = "Use {.code {example}} or the corresponding {.code 1 + x} one-slope form for this count structured-dependence gate; labelled count covariance, multiple slopes, and structured count scale routes remain planned."
    ))
  }
  invisible(NULL)
}

validate_poisson_spatial_zi_structured_term <- function(
  term,
  mu_terms,
  mu_structured_term
) {
  if (is.null(term)) {
    return(invisible(NULL))
  }
  marker <- structured_mu_type(term)
  if (!identical(marker, "spatial")) {
    cli::cli_abort(c(
      "Zero-inflated Poisson structured {.code zi} effects currently admit only the first {.fn spatial} intercept gate.",
      "x" = "Requested structured effect type: {.val {marker}}.",
      "i" = "Keep {.fn phylo}, {.fn animal}, {.fn relmat}, structured slopes, q2/q4, REML, and AI-REML deferred until row-specific recovery evidence exists."
    ))
  }
  if (length(mu_terms) > 0L || !is.null(mu_structured_term)) {
    cli::cli_abort(c(
      "Zero-inflated Poisson structured {.code zi} effects cannot be combined with {.code mu} random effects in this first zero-inflation gate.",
      "x" = "The formula contains a structured {.code zi} effect plus an ordinary or structured {.code mu} random effect.",
      "i" = "Fit the structured zero-inflation route or the count-location route separately until joint recovery tests exist."
    ))
  }
  if (!is.null(term$covariance_label)) {
    cli::cli_abort(c(
      "Zero-inflated Poisson {.fn spatial} {.code zi} effects currently support only unlabelled q=1 intercepts.",
      "x" = "Requested labelled structured term: {.code {term$label}}.",
      "i" = "Use {.code zi ~ spatial(1 | id, coords = coords)} for the v1.0 recovery gate."
    ))
  }
  if (!structured_term_is_intercept_only(term)) {
    cli::cli_abort(c(
      "Zero-inflated Poisson {.fn spatial} {.code zi} effects currently support only intercept-only structured terms.",
      "x" = "Requested structured coefficient{?s}: {.val {term$coef_names}}.",
      "i" = "Structured zero-inflation slopes, q2/q4 covariance, and count location-inflation blocks remain post-v1.0 design work."
    ))
  }
  invisible(NULL)
}

select_count_sigma_structured_term <- function(structured_terms, family_label) {
  active_structured <- names(structured_terms)[
    !vapply(structured_terms, is.null, logical(1L))
  ]
  if (length(active_structured) > 1L) {
    family_label <- as.character(family_label)[[1L]]
    cli::cli_abort(c(
      "Only one structured {.code sigma} effect type is implemented per {family_label} count model.",
      "x" = "The model contains structured effect types: {.val {active_structured}}.",
      "i" = "Fit one of {.fn phylo}, {.fn spatial}, {.fn animal}, or {.fn relmat} at a time until combined structured scale-dependence recovery tests exist."
    ))
  }
  if (length(active_structured) == 0L) {
    return(NULL)
  }
  structured_terms[[active_structured]]
}

validate_count_structured_sigma_term <- function(
  term,
  sigma_terms,
  mu_terms,
  mu_structured_term = NULL,
  has_zi = FALSE,
  family_label,
  inflated_label
) {
  if (is.null(term)) {
    return(invisible(NULL))
  }
  family_label <- as.character(family_label)[[1L]]
  inflated_label <- as.character(inflated_label)[[1L]]
  marker <- structured_mu_type(term)
  example <- switch(
    marker,
    phylo = "phylo(1 + x | species, tree = tree)",
    spatial = "spatial(1 + x | site, coords = coords)",
    animal = "animal(1 + x | id, Ainv = Ainv)",
    relmat = "relmat(1 + x | id, Q = Q)",
    paste0(marker, "(1 + x | id, ...)")
  )
  if (isTRUE(has_zi)) {
    cli::cli_abort(c(
      "{family_label} structured {.code sigma} effects are implemented only for ordinary {family_label} models.",
      "x" = "{inflated_label} structured scale effects are planned but not implemented.",
      "i" = "Fit {.code bf(count ~ x, sigma ~ {example})} without a {.code zi} formula, or use fixed-effect {.code zi ~ predictors} until zero-inflated structured-scale recovery tests exist."
    ))
  }
  if (length(mu_terms) > 0L || !is.null(mu_structured_term)) {
    cli::cli_abort(c(
      "{family_label} structured {.code sigma} effects cannot be combined with {.code mu} random effects in this first scale gate.",
      "x" = "The formula contains a structured {.code sigma} effect plus an ordinary or structured {.code mu} random effect.",
      "i" = "Fit the {family_label} mean random-effect model or the structured scale model separately until joint recovery tests exist."
    ))
  }
  if (length(sigma_terms) > 0L) {
    cli::cli_abort(c(
      "{family_label} structured {.code sigma} effects cannot be combined with ordinary {.code sigma} random effects in this first scale gate.",
      "x" = "The formula contains both {.fn {marker}} and ordinary scale random-effect bar terms.",
      "i" = "Use one structured scale term such as {.code sigma ~ {example}} until combined scale random-effect recovery tests exist."
    ))
  }
  if (!is.null(term$covariance_label)) {
    cli::cli_abort(c(
      "{family_label} structured {.code sigma} effects currently support only unlabelled independent one-slope terms.",
      "x" = "Requested labelled structured term: {.code {term$label}}.",
      "i" = "Use {.code {example}}; labelled scale covariance, q2/q4, and cross-parameter covariance routes remain planned."
    ))
  }
  if (!structured_term_is_intercept_one_slope(term)) {
    cli::cli_abort(c(
      "{family_label} structured {.code sigma} effects currently support only unlabelled intercept-plus-one-slope structured terms.",
      "x" = "Requested structured coefficient{?s}: {.val {term$coef_names}}.",
      "i" = "Use {.code {example}} for this count structured-scale gate; intercept-only, multiple slopes, labelled covariance, q2/q4, and structured count location-scale blocks remain planned."
    ))
  }
  invisible(NULL)
}

validate_nbinom2_sigma_random_terms <- function(
  terms,
  mu_terms = list(),
  structured_term = NULL,
  has_zi = FALSE
) {
  if (length(terms) == 0L) {
    return(invisible(terms))
  }
  if (isTRUE(has_zi)) {
    cli::cli_abort(c(
      "NB2 {.code sigma} random intercepts are implemented only for ordinary NB2 models.",
      "x" = "Zero-inflated NB2 {.code sigma} random effects are planned but not implemented.",
      "i" = "Fit {.code bf(count ~ x, sigma ~ z + (1 | id))} without a {.code zi} formula until zero-inflated overdispersion recovery tests exist."
    ))
  }
  if (length(mu_terms) > 0L || !is.null(structured_term)) {
    cli::cli_abort(c(
      "NB2 {.code sigma} random intercepts cannot be combined with {.code mu} random effects in this first gate.",
      "x" = "The formula contains a {.code sigma} random effect plus an ordinary or structured {.code mu} random effect.",
      "i" = "Fit the NB2 mean random-effect model or the NB2 overdispersion random-intercept model separately until joint recovery tests exist."
    ))
  }
  unsupported <- vapply(
    terms,
    function(term) {
      !identical(term$type, "intercept") ||
        !is.null(term$covariance_label)
    },
    logical(1L)
  )
  if (any(unsupported)) {
    labels <- vapply(terms[unsupported], `[[`, character(1L), "label")
    cli::cli_abort(c(
      "Only independent NB2 {.code sigma} random intercepts are implemented in this slice.",
      "x" = "Unsupported random-effect term{?s}: {.code {labels}}.",
      "i" = "Use syntax like {.code bf(count ~ x, sigma ~ z + (1 | id))}.",
      "i" = "NB2 {.code sigma} random slopes, labelled covariance blocks, and cross-parameter covariance remain planned until separate recovery tests exist."
    ))
  }
  invisible(terms)
}

validate_truncated_nbinom2_mu_random_terms <- function(
  terms,
  has_hu = FALSE
) {
  if (length(terms) == 0L) {
    return(invisible(terms))
  }
  if (isTRUE(has_hu)) {
    cli::cli_abort(c(
      "{.fn truncated_nbinom2} {.code mu} random intercepts are implemented only for ordinary zero-truncated NB2 models.",
      "x" = "Hurdle NB2 random effects are planned but not implemented.",
      "i" = "Fit {.code bf(count ~ x + (1 | id), sigma ~ z)} without a {.code hu} formula, or keep the hurdle model fixed-effect."
    ))
  }
  unsupported <- vapply(
    terms,
    function(term) {
      !(term$type %in% c("intercept", "slope")) ||
        !is.null(term$covariance_label)
    },
    logical(1L)
  )
  if (any(unsupported)) {
    labels <- vapply(terms[unsupported], `[[`, character(1L), "label")
    cli::cli_abort(c(
      "Only independent {.fn truncated_nbinom2} {.code mu} random intercepts and slopes are implemented in this slice.",
      "x" = "Unsupported random-effect term{?s}: {.code {labels}}.",
      "i" = "Use syntax like {.code bf(count ~ x + (1 | id) + (0 + x | id), sigma ~ z)}.",
      "i" = "Correlated slopes, labelled covariance blocks, structured effects, and hurdle random effects remain planned until separate recovery tests exist."
    ))
  }
  invisible(terms)
}

validate_truncated_nbinom2_sigma_random_terms <- function(terms) {
  if (length(terms) == 0L) {
    return(invisible(terms))
  }
  labels <- vapply(terms, `[[`, character(1L), "label")
  cli::cli_abort(c(
    "Non-Gaussian {.code sigma} random effects are not implemented for {.fn truncated_nbinom2}.",
    "x" = "Unsupported random-effect term{?s}: {.code {labels}}.",
    "i" = "This slice adds only ordinary positive-count {.code mu} random intercepts; overdispersion random effects need their own recovery tests."
  ))
}

validate_student_mu_random_terms <- function(terms) {
  if (length(terms) == 0L) {
    return(invisible(terms))
  }
  unsupported <- vapply(
    terms,
    function(term) {
      !(term$type %in% c("intercept", "slope")) ||
        !is.null(term$covariance_label)
    },
    logical(1L)
  )
  if (any(unsupported)) {
    labels <- vapply(terms[unsupported], `[[`, character(1L), "label")
    cli::cli_abort(c(
      "Only independent {.fn student} {.code mu} random intercepts and slopes are implemented in this slice.",
      "x" = "Unsupported random-effect term{?s}: {.code {labels}}.",
      "i" = "Use syntax like {.code bf(y ~ x + (1 | id) + (0 + x | id), sigma ~ z, nu ~ 1)}.",
      "i" = "The only structured Student-t gate is the row-specific {.code spatial(1 | id, coords = coords)} {.code mu} route; correlated Student-t slopes, labelled covariance blocks, other structured effects, scale random effects, and shape random effects remain planned until separate recovery tests exist."
    ))
  }
  invisible(terms)
}

validate_student_spatial_mu_structured_term <- function(term) {
  if (is.null(term)) {
    return(invisible(NULL))
  }
  marker <- structured_mu_type(term)
  if (!identical(marker, "spatial")) {
    cli::cli_abort(c(
      "{.fn student} structured {.code mu} effects currently admit only the first {.fn spatial} intercept gate.",
      "x" = "Requested structured effect type: {.val {marker}}.",
      "i" = "Keep {.fn phylo}, {.fn animal}, {.fn relmat}, structured slopes, scale routes, q2/q4, REML, and AI-REML deferred until row-specific recovery evidence exists."
    ))
  }
  if (!is.null(term$covariance_label)) {
    cli::cli_abort(c(
      "{.fn student} {.fn spatial} {.code mu} effects currently support only unlabelled q=1 intercepts.",
      "x" = "Requested labelled structured term: {.code {term$label}}.",
      "i" = "Use {.code spatial(1 | id, coords = coords)} for the v1.0 recovery gate."
    ))
  }
  if (
    !structured_term_is_intercept_only(term) &&
      !structured_term_is_intercept_one_slope(term)
  ) {
    cli::cli_abort(c(
      "{.fn student} {.fn spatial} {.code mu} effects currently support only unlabelled intercept-only or one-slope structured terms.",
      "x" = "Requested structured coefficient{?s}: {.val {term$coef_names}}.",
      "i" = "Use {.code spatial(1 | id, coords = coords)} or the {.code 1 + x} one-slope form; multiple or labelled Student-t slopes, q2/q4 covariance, and scale-side routes remain post-v1.0 design work."
    ))
  }
  invisible(NULL)
}

validate_student_phylo_nu_structured_term <- function(term) {
  if (is.null(term)) {
    return(invisible(NULL))
  }
  marker <- structured_mu_type(term)
  if (!identical(marker, "phylo")) {
    cli::cli_abort(c(
      "{.fn student} structured {.code nu} effects currently admit only the first {.fn phylo} intercept gate.",
      "x" = "Requested structured effect type: {.val {marker}}.",
      "i" = "Keep {.fn spatial}, {.fn animal}, {.fn relmat}, structured slopes, scale routes, q2/q4, REML, and AI-REML deferred until row-specific recovery evidence exists."
    ))
  }
  if (!is.null(term$covariance_label)) {
    cli::cli_abort(c(
      "{.fn student} {.fn phylo} {.code nu} effects currently support only unlabelled q=1 intercepts.",
      "x" = "Requested labelled structured term: {.code {term$label}}.",
      "i" = "Use {.code phylo(1 | id, tree = tree)} for the v1.0 recovery gate."
    ))
  }
  if (!structured_term_is_intercept_only(term)) {
    cli::cli_abort(c(
      "{.fn student} {.fn phylo} {.code nu} effects currently support only intercept-only structured terms.",
      "x" = "Requested structured coefficient{?s}: {.val {term$coef_names}}.",
      "i" = "Structured Student-t shape slopes, q2/q4 covariance, and location-shape blocks remain post-v1.0 design work."
    ))
  }
  invisible(NULL)
}

validate_ordinal_phylo_mu_structured_term <- function(term) {
  if (is.null(term)) {
    return(invisible(NULL))
  }
  marker <- structured_mu_type(term)
  if (!identical(marker, "phylo")) {
    cli::cli_abort(c(
      "{.fn cumulative_logit} structured {.code mu} effects currently admit only the first {.fn phylo} intercept gate.",
      "x" = "Requested structured effect type: {.val {marker}}.",
      "i" = "Keep {.fn spatial}, {.fn animal}, {.fn relmat}, ordinal structured slopes, q2/q4, scale/discrimination formulas, REML, and AI-REML deferred until row-specific recovery evidence exists."
    ))
  }
  if (!is.null(term$covariance_label)) {
    cli::cli_abort(c(
      "{.fn cumulative_logit} {.fn phylo} {.code mu} effects currently support only unlabelled q=1 intercepts.",
      "x" = "Requested labelled structured term: {.code {term$label}}.",
      "i" = "Use {.code phylo(1 | id, tree = tree)} for the v1.0 local fit-only gate."
    ))
  }
  if (!structured_term_is_intercept_only(term)) {
    cli::cli_abort(c(
      "{.fn cumulative_logit} {.fn phylo} {.code mu} effects currently support only intercept-only structured terms.",
      "x" = "Requested structured coefficient{?s}: {.val {term$coef_names}}.",
      "i" = "Ordinal structured slopes, q2/q4 covariance, scale-side routes, intervals, coverage, REML, and AI-REML remain post-v1.0 design work."
    ))
  }
  invisible(NULL)
}

validate_student_sigma_random_terms <- function(terms) {
  if (length(terms) == 0L) {
    return(invisible(terms))
  }
  labels <- vapply(terms, `[[`, character(1L), "label")
  cli::cli_abort(c(
    "Non-Gaussian {.code sigma} random effects are not implemented for {.fn student}.",
    "x" = "Unsupported random-effect term{?s}: {.code {labels}}.",
    "i" = "This slice adds only ordinary Student-t {.code mu} random intercepts; residual-scale random effects need their own likelihood and recovery tests."
  ))
}

validate_skew_normal_random_terms <- function(terms, dpar) {
  if (length(terms) == 0L) {
    return(invisible(terms))
  }
  labels <- vapply(terms, `[[`, character(1L), "label")
  cli::cli_abort(c(
    "{.fn skew_normal} random effects are not implemented in this first fixed-effect slice.",
    "x" = "The {.code {dpar}} formula contains unsupported random-effect term{?s}: {.code {labels}}.",
    "i" = "Use fixed-effect formulas such as {.code bf(y ~ x, sigma ~ z, nu ~ w)}.",
    "i" = "Residual-shape random effects, residual-scale random effects, ordinary grouped skew-normal random effects, and latent {.code skew(id)} syntax need separate likelihood, extractor, interval, and simulation-recovery evidence."
  ))
}

validate_positive_continuous_mu_random_terms <- function(terms, family_label) {
  if (length(terms) == 0L) {
    return(invisible(terms))
  }
  unsupported <- vapply(
    terms,
    function(term) {
      !(term$type %in% c("intercept", "slope")) ||
        !is.null(term$covariance_label)
    },
    logical(1L)
  )
  if (any(unsupported)) {
    labels <- vapply(terms[unsupported], `[[`, character(1L), "label")
    cli::cli_abort(c(
      "Only independent {family_label} {.code mu} random intercepts and slopes are implemented in this slice.",
      "x" = "Unsupported random-effect term{?s}: {.code {labels}}.",
      "i" = "Use syntax like {.code bf(y ~ x + (1 | id) + (0 + x | id), sigma ~ z)}.",
      "i" = "Correlated positive-continuous slopes, labelled covariance blocks, structured effects, and scale random effects remain planned until separate recovery tests exist."
    ))
  }
  invisible(terms)
}

validate_positive_continuous_sigma_random_terms <- function(
  terms,
  family_label
) {
  if (length(terms) == 0L) {
    return(invisible(terms))
  }
  labels <- vapply(terms, `[[`, character(1L), "label")
  cli::cli_abort(c(
    "Non-Gaussian {.code sigma} random effects are not implemented for {family_label}.",
    "x" = "Unsupported random-effect term{?s}: {.code {labels}}.",
    "i" = "This slice adds only ordinary positive-continuous {.code mu} random intercepts; residual-scale random effects need their own likelihood and recovery tests."
  ))
}

validate_tweedie_random_terms <- function(terms, dpar) {
  if (length(terms) == 0L) {
    return(invisible(terms))
  }
  labels <- vapply(terms, `[[`, character(1L), "label")
  cli::cli_abort(c(
    "{.fn tweedie} random effects are not implemented in this first fixed-effect slice.",
    "x" = "The {.code {dpar}} formula contains unsupported random-effect term{?s}: {.code {labels}}.",
    "i" = "Use fixed-effect formulas such as {.code bf(y ~ x, sigma ~ z, nu ~ 1)}.",
    "i" = "Tweedie random effects need their own likelihood, extractor, diagnostic, and simulation-recovery evidence."
  ))
}

validate_beta_mu_random_terms <- function(terms) {
  if (length(terms) == 0L) {
    return(invisible(terms))
  }
  unsupported <- vapply(
    terms,
    function(term) {
      !(term$type %in% c("intercept", "slope")) ||
        !is.null(term$covariance_label)
    },
    logical(1L)
  )
  if (any(unsupported)) {
    labels <- vapply(terms[unsupported], `[[`, character(1L), "label")
    cli::cli_abort(c(
      "Only independent {.fn beta} {.code mu} random intercepts and slopes are implemented in this slice.",
      "x" = "Unsupported random-effect term{?s}: {.code {labels}}.",
      "i" = "Use syntax like {.code bf(prop ~ x + (1 | id) + (0 + x | id), sigma ~ z)} for strict {.code (0, 1)} responses.",
      "i" = "The only structured beta gate is the row-specific unlabelled {.fn animal} intercept route in either {.code mu} or {.code sigma}; correlated beta slopes, labelled covariance blocks, other structured effects, exact-boundary mass, and mixed bounded-response models remain planned until separate recovery tests exist."
    ))
  }
  invisible(terms)
}

validate_gamma_relmat_mu_structured_term <- function(term) {
  if (is.null(term)) {
    return(invisible(NULL))
  }
  marker <- structured_mu_type(term)
  if (!identical(marker, "relmat")) {
    cli::cli_abort(c(
      "{.fn Gamma} structured {.code mu} effects currently admit only the first {.fn relmat} intercept gate.",
      "x" = "Requested structured effect type: {.val {marker}}.",
      "i" = "Keep {.fn phylo}, {.fn spatial}, {.fn animal}, structured slopes, scale routes, q2/q4, REML, and AI-REML deferred until row-specific recovery evidence exists."
    ))
  }
  if (!is.null(term$covariance_label)) {
    cli::cli_abort(c(
      "{.fn Gamma} {.fn relmat} {.code mu} effects currently support only unlabelled q=1 intercepts.",
      "x" = "Requested labelled structured term: {.code {term$label}}.",
      "i" = "Use {.code relmat(1 | id, K = K)} or {.code relmat(1 | id, Q = Q)} for the v1.0 recovery gate."
    ))
  }
  if (
    !structured_term_is_intercept_only(term) &&
      !structured_term_is_intercept_one_slope(term)
  ) {
    cli::cli_abort(c(
      "{.fn Gamma} {.fn relmat} {.code mu} effects currently support only unlabelled intercept-only or one-slope structured terms.",
      "x" = "Requested structured coefficient{?s}: {.val {term$coef_names}}.",
      "i" = "Use {.code relmat(1 | id, K = K)} or the {.code 1 + x} one-slope form; multiple or labelled Gamma slopes, q2/q4 covariance, and scale-side routes remain post-v1.0 design work."
    ))
  }
  invisible(NULL)
}

validate_truncated_nbinom2_relmat_hu_structured_term <- function(term) {
  if (is.null(term)) {
    return(invisible(NULL))
  }
  marker <- structured_mu_type(term)
  if (!identical(marker, "relmat")) {
    cli::cli_abort(c(
      "{.fn truncated_nbinom2} structured {.code hu} effects currently admit only the first {.fn relmat} intercept gate.",
      "x" = "Requested structured effect type: {.val {marker}}.",
      "i" = "Keep {.fn phylo}, {.fn spatial}, {.fn animal}, structured slopes, q2/q4, REML, and AI-REML deferred until row-specific recovery evidence exists."
    ))
  }
  if (!is.null(term$covariance_label)) {
    cli::cli_abort(c(
      "{.fn truncated_nbinom2} {.fn relmat} {.code hu} effects currently support only unlabelled q=1 intercepts.",
      "x" = "Requested labelled structured term: {.code {term$label}}.",
      "i" = "Use {.code hu ~ relmat(1 | id, K = K)} or {.code hu ~ relmat(1 | id, Q = Q)} for the v1.0 local-fit gate."
    ))
  }
  if (!structured_term_is_intercept_only(term)) {
    cli::cli_abort(c(
      "{.fn truncated_nbinom2} {.fn relmat} {.code hu} effects currently support only intercept-only structured terms.",
      "x" = "Requested structured coefficient{?s}: {.val {term$coef_names}}.",
      "i" = "Structured hurdle slopes, q2/q4 covariance, and cross-parameter routes remain post-v1.0 design work."
    ))
  }
  invisible(NULL)
}

validate_beta_animal_mu_structured_term <- function(term) {
  if (is.null(term)) {
    return(invisible(NULL))
  }
  marker <- structured_mu_type(term)
  if (!identical(marker, "animal")) {
    cli::cli_abort(c(
      "{.fn beta} structured {.code mu} effects currently admit only the first {.fn animal} intercept gate.",
      "x" = "Requested structured effect type: {.val {marker}}.",
      "i" = "Keep {.fn phylo}, {.fn spatial}, {.fn relmat}, structured slopes, q2/q4, and zero-one-inflated beta routes deferred until row-specific recovery evidence exists."
    ))
  }
  if (!is.null(term$covariance_label)) {
    cli::cli_abort(c(
      "{.fn beta} {.fn animal} {.code mu} effects currently support only unlabelled q=1 intercepts.",
      "x" = "Requested labelled structured term: {.code {term$label}}.",
      "i" = "Use {.code animal(1 | id, pedigree = ped)}, {.code animal(1 | id, A = A)}, or {.code animal(1 | id, Ainv = Ainv)} for the v1.0 recovery gate."
    ))
  }
  if (
    !structured_term_is_intercept_only(term) &&
      !structured_term_is_intercept_one_slope(term)
  ) {
    cli::cli_abort(c(
      "{.fn beta} {.fn animal} {.code mu} effects currently support only unlabelled intercept-only or one-slope structured terms.",
      "x" = "Requested structured coefficient{?s}: {.val {term$coef_names}}.",
      "i" = "Use {.code animal(1 | id, pedigree = ped)} or the {.code 1 + x} one-slope form; multiple or labelled beta slopes, q2/q4 covariance, and scale-side routes remain post-v1.0 design work."
    ))
  }
  invisible(NULL)
}

validate_beta_animal_sigma_structured_term <- function(term) {
  if (is.null(term)) {
    return(invisible(NULL))
  }
  marker <- structured_mu_type(term)
  if (!identical(marker, "animal")) {
    cli::cli_abort(c(
      "{.fn beta} structured {.code sigma} effects currently admit only the first {.fn animal} intercept gate.",
      "x" = "Requested structured effect type: {.val {marker}}.",
      "i" = "Keep {.fn phylo}, {.fn spatial}, {.fn relmat}, structured slopes, q2/q4, zero-one-inflated beta routes, REML, and AI-REML deferred until row-specific recovery evidence exists."
    ))
  }
  if (!is.null(term$covariance_label)) {
    cli::cli_abort(c(
      "{.fn beta} {.fn animal} {.code sigma} effects currently support only unlabelled q=1 intercepts.",
      "x" = "Requested labelled structured term: {.code {term$label}}.",
      "i" = "Use {.code sigma ~ animal(1 | id, pedigree = ped)}, {.code sigma ~ animal(1 | id, A = A)}, or {.code sigma ~ animal(1 | id, Ainv = Ainv)} for the v1.0 recovery gate."
    ))
  }
  if (!structured_term_is_intercept_only(term)) {
    cli::cli_abort(c(
      "{.fn beta} {.fn animal} {.code sigma} effects currently support only intercept-only structured terms.",
      "x" = "Requested structured coefficient{?s}: {.val {term$coef_names}}.",
      "i" = "Structured beta scale slopes, q2/q4 covariance, and multi-endpoint routes remain post-v1.0 design work."
    ))
  }
  invisible(NULL)
}

validate_beta_sigma_random_terms <- function(terms) {
  if (length(terms) == 0L) {
    return(invisible(terms))
  }
  labels <- vapply(terms, `[[`, character(1L), "label")
  cli::cli_abort(c(
    "Non-Gaussian {.code sigma} random effects are not implemented for {.fn beta}.",
    "x" = "Unsupported random-effect term{?s}: {.code {labels}}.",
    "i" = "Use the row-specific known-covariance gate {.code sigma ~ animal(1 | id, ...)} for the beta scale recovery smoke; ordinary beta scale random effects and other scale routes need separate recovery tests."
  ))
}

validate_beta_binomial_mu_random_terms <- function(terms) {
  if (length(terms) == 0L) {
    return(invisible(terms))
  }
  unsupported <- vapply(
    terms,
    function(term) {
      !(term$type %in% c("intercept", "slope")) ||
        !is.null(term$covariance_label)
    },
    logical(1L)
  )
  if (any(unsupported)) {
    labels <- vapply(terms[unsupported], `[[`, character(1L), "label")
    cli::cli_abort(c(
      "Only independent {.fn beta_binomial} {.code mu} random intercepts and slopes are implemented in this slice.",
      "x" = "Unsupported random-effect term{?s}: {.code {labels}}.",
      "i" = "Use syntax like {.code bf(cbind(success, failure) ~ x + (1 | id) + (0 + x | id), sigma ~ z)} for counted successes out of known trials.",
      "i" = "Correlated beta-binomial slopes, labelled covariance blocks, structured effects, scale random effects, zero-one inflation, and mixed bounded-response models remain planned until separate recovery tests exist."
    ))
  }
  invisible(terms)
}

validate_beta_binomial_sigma_random_terms <- function(terms) {
  if (length(terms) == 0L) {
    return(invisible(terms))
  }
  labels <- vapply(terms, `[[`, character(1L), "label")
  cli::cli_abort(c(
    "Non-Gaussian {.code sigma} random effects are not implemented for {.fn beta_binomial}.",
    "x" = "Unsupported random-effect term{?s}: {.code {labels}}.",
    "i" = "This slice adds only ordinary {.fn beta_binomial} {.code mu} random intercepts on the logit success-probability predictor; count-level overdispersion random effects need their own likelihood and recovery tests."
  ))
}

is_random_bar_call <- function(expr) {
  expr <- strip_parens(expr)
  is.call(expr) && identical(expr[[1L]], as.name("|"))
}

parse_random_sigma_term <- function(expr, dpar) {
  expr <- strip_parens(expr)
  lhs <- expr[[2L]]
  group <- expr[[3L]]
  covariance_label <- NULL

  if (is_random_bar_call(lhs)) {
    nested <- strip_parens(lhs)
    lhs <- nested[[2L]]
    covariance_label_expr <- nested[[3L]]
    if (!is.symbol(covariance_label_expr)) {
      cli::cli_abort(c(
        "Random-effect covariance-block labels must be simple names.",
        "x" = "Use syntax like {.code {dpar} ~ z + (1 | p | id)}."
      ))
    }
    covariance_label <- as.character(covariance_label_expr)
    validate_random_mu_covariance_label(covariance_label)
  }
  if (!is.symbol(group)) {
    cli::cli_abort(c(
      "Random-effect grouping terms must be simple variables.",
      "x" = "Use syntax like {.code {dpar} ~ z + (1 | id)}."
    ))
  }

  lhs <- strip_parens(lhs)
  if (is_intercept_one(lhs)) {
    group_name <- as.character(group)
    return(list(
      type = "intercept",
      variable = NA_character_,
      variables = NA_character_,
      coef_names = "(Intercept)",
      label = format_random_mu_label("1", group_name, covariance_label),
      group = group_name,
      covariance_label = covariance_label
    ))
  }
  if (!dpar %in% c("sigma", "sigma1", "sigma2")) {
    cli::cli_abort(c(
      "Only bivariate residual-scale random intercepts are implemented for {.code {dpar}}.",
      "x" = "Use matching terms such as {.code {dpar} = ~ z + (1 | p | id)}.",
      "i" = "Residual-scale random slopes in bivariate models remain planned.",
      "i" = "The ordinary all-four q8 diagnostic route requires matching one-slope terms in {.code mu1}, {.code mu2}, {.code sigma1}, and {.code sigma2}; this error is for a residual-scale-only or mismatched q8-shaped request."
    ))
  }

  coef <- parse_random_mu_lhs(
    lhs,
    dpar = dpar,
    group = as.character(group),
    covariance_label = covariance_label
  )
  # Correlated residual-scale intercept-slope blocks are implemented (2026-07-08):
  #   * univariate, UNLABELLED: `sigma ~ z + (1 + x | id)` (same-dpar sigma
  #     intercept <-> slope correlation; C++ model_type == 1 conditions u_sigma on its
  #     paired intercept exactly as the bivariate loop does), and the multi-slope
  #     `(1 + x1 + x2 | id)` generalisation.
  #   * bivariate, LABELLED: the existing cross-response `sigma1`/`sigma2` allowance.
  sigma_correlated_ok <-
    (identical(dpar, "sigma") &&
      is.null(covariance_label) &&
      coef$type %in% c("correlated_slope", "correlated_block")) ||
      (dpar %in%
        c("sigma1", "sigma2") &&
        !is.null(covariance_label) &&
        coef$type %in% c("correlated_slope", "correlated_block"))
  # Check the LABELLED univariate sigma case first: it is a more specific
  # rejection than the generic shape guard below, and `(1 + x | p | id)` would
  # otherwise be swallowed by it (`coef$type == "correlated_block"`), leaving
  # the user with generic advice instead of the labelled-block explanation.
  if (!is.null(covariance_label) && identical(dpar, "sigma")) {
    cli::cli_abort(c(
      "Labelled residual-scale random-slope covariance blocks are not implemented yet.",
      "x" = "Use an unlabelled independent slope such as {.code sigma ~ z + (0 + x | id)}.",
      "i" = "The first labelled slope covariance slice is bivariate and same-response only, such as {.code mu1} with {.code sigma1}."
    ))
  }
  if (!identical(coef$type, "slope") && !sigma_correlated_ok) {
    cli::cli_abort(c(
      "This residual-scale random-effect shape is not implemented for {.code sigma}.",
      "x" = "Use {.code sigma ~ z + (1 | id)}, {.code sigma ~ z + (0 + x | id)}, or a correlated block {.code sigma ~ z + (1 + x | id)}.",
      "i" = "Labelled univariate residual-scale slope covariance blocks remain planned."
    ))
  }

  c(
    coef,
    list(group = as.character(group), covariance_label = covariance_label)
  )
}

parse_random_mu_term <- function(expr, dpar) {
  expr <- strip_parens(expr)
  lhs <- expr[[2L]]
  group <- expr[[3L]]
  covariance_label <- NULL

  if (is_random_bar_call(lhs)) {
    nested <- strip_parens(lhs)
    lhs <- nested[[2L]]
    covariance_label_expr <- nested[[3L]]
    if (!is.symbol(covariance_label_expr)) {
      cli::cli_abort(c(
        "Random-effect covariance-block labels must be simple names.",
        "x" = "Use syntax like {.code (1 | p | id)} or {.code (1 + x | p | id)}."
      ))
    }
    covariance_label <- as.character(covariance_label_expr)
    validate_random_mu_covariance_label(covariance_label)
  }
  if (!is.symbol(group)) {
    cli::cli_abort(c(
      "Random-effect grouping terms must be simple variables.",
      "x" = "Use syntax like {.code (1 | id)}, {.code (0 + x | id)}, or {.code (1 + x | p | id)}."
    ))
  }

  group_name <- as.character(group)
  coef <- parse_random_mu_lhs(
    lhs,
    dpar = dpar,
    group = group_name,
    covariance_label = covariance_label
  )
  c(coef, list(group = group_name, covariance_label = covariance_label))
}

is_intercept_one <- function(expr) {
  is.numeric(expr) && length(expr) == 1L && identical(as.numeric(expr), 1)
}

is_zero_term <- function(expr) {
  is.numeric(expr) && length(expr) == 1L && identical(as.numeric(expr), 0)
}

parse_random_mu_lhs <- function(lhs, dpar, group, covariance_label = NULL) {
  lhs <- strip_parens(lhs)
  if (is_intercept_one(lhs)) {
    return(list(
      type = "intercept",
      variable = NA_character_,
      variables = NA_character_,
      coef_names = "(Intercept)",
      label = format_random_mu_label("1", group, covariance_label)
    ))
  }

  pieces <- flatten_plus_terms(lhs)
  zero <- vapply(pieces, is_zero_term, logical(1))
  non_zero <- pieces[!zero]
  if (any(zero) && length(non_zero) == 1L && is.symbol(non_zero[[1L]])) {
    variable <- as.character(non_zero[[1L]])
    return(list(
      type = "slope",
      variable = variable,
      variables = variable,
      coef_names = variable,
      label = format_random_mu_label(
        paste0("0 + ", variable),
        group,
        covariance_label
      )
    ))
  }

  one <- vapply(pieces, is_intercept_one, logical(1))
  symbol <- vapply(pieces, is.symbol, logical(1))
  if (
    !any(zero) &&
      sum(one) <= 1L &&
      sum(symbol) >= 1L &&
      length(pieces) == sum(one) + sum(symbol)
  ) {
    variables <- vapply(pieces[symbol], as.character, character(1L))
    lhs_label <- paste(c("1", variables), collapse = " + ")
    return(list(
      type = if (length(variables) == 1L) {
        "correlated_slope"
      } else {
        "correlated_block"
      },
      variable = if (length(variables) == 1L) variables else NA_character_,
      variables = variables,
      coef_names = c("(Intercept)", variables),
      label = format_random_mu_label(
        lhs_label,
        group,
        covariance_label
      )
    ))
  }

  cli::cli_abort(c(
    "Only random intercepts, independent random slopes, and correlated intercept-slope blocks are implemented for {.code {dpar}}.",
    "x" = "Use {.code (1 | id)} for a random intercept or {.code (0 + x | id)} for a random slope.",
    "i" = "Use {.code (1 + x | id)} or {.code (1 + x | p | id)} for a correlated random intercept and one numeric slope.",
    "i" = "Use {.code (1 + x1 + x2 | id)} for an ordinary Gaussian location block with two numeric slopes."
  ))
}

validate_random_mu_covariance_label <- function(label) {
  reserved <- c(
    "mu",
    "mu1",
    "mu2",
    "sigma",
    "sigma1",
    "sigma2",
    "rho",
    "rho12",
    "nu",
    "skew",
    "kurtosis",
    "shape",
    "zi",
    "hu",
    "zoi",
    "coi",
    "phi"
  )
  if (label %in% reserved) {
    cli::cli_abort(c(
      "Random-effect covariance-block labels cannot use reserved distributional parameter names.",
      "x" = "{.code {label}} is reserved for a model parameter.",
      "i" = "Use a neutral label such as {.code p}, {.code q}, or {.code block1}."
    ))
  }
  invisible(label)
}

format_random_mu_label <- function(lhs_label, group, covariance_label = NULL) {
  if (is.null(covariance_label)) {
    return(paste0("(", lhs_label, " | ", group, ")"))
  }
  paste0("(", lhs_label, " | ", covariance_label, " | ", group, ")")
}

format_random_mu_cor_label <- function(
  coef_names,
  group,
  covariance_label = NULL
) {
  group_label <- if (is.null(covariance_label)) {
    group
  } else {
    paste0(covariance_label, " | ", group)
  }
  paste0(
    "cor(",
    coef_names[[1L]],
    ",",
    coef_names[[2L]],
    " | ",
    group_label,
    ")"
  )
}

format_biv_mu_cor_label <- function(
  group,
  covariance_label,
  coef_name = "(Intercept)"
) {
  paste0(
    "cor(mu1:",
    coef_name,
    ",mu2:",
    coef_name,
    " | ",
    covariance_label,
    " | ",
    group,
    ")"
  )
}

format_biv_sigma_cor_label <- function(
  group,
  covariance_label,
  coef_name = "(Intercept)"
) {
  paste0(
    "cor(sigma1:",
    coef_name,
    ",sigma2:",
    coef_name,
    " | ",
    covariance_label,
    " | ",
    group,
    ")"
  )
}

format_mu_sigma_cor_label <- function(group, covariance_label) {
  format_cross_dpar_cor_label("mu", "sigma", group, covariance_label)
}

format_cross_dpar_cor_label <- function(
  from_dpar,
  to_dpar,
  group,
  covariance_label,
  from_coef = "(Intercept)",
  to_coef = "(Intercept)"
) {
  paste0(
    "cor(",
    from_dpar,
    ":",
    from_coef,
    ",",
    to_dpar,
    ":",
    to_coef,
    " | ",
    covariance_label,
    " | ",
    group,
    ")"
  )
}

random_effect_vars <- function(terms) {
  if (length(terms) == 0L) {
    return(character())
  }
  variables <- unlist(lapply(terms, `[[`, "variables"), use.names = FALSE)
  unique(c(
    vapply(terms, `[[`, character(1), "group"),
    variables[!is.na(variables)]
  ))
}

is_qgt2_random_mu_term <- function(term) {
  length(term$coef_names) > 2L
}

remove_qgt2_random_mu_terms <- function(terms) {
  if (length(terms) == 0L) {
    return(terms)
  }
  keep <- !vapply(terms, is_qgt2_random_mu_term, logical(1L))
  terms[keep]
}

extract_gaussian_mu_phylo_term <- function(entry, dpar = entry$dpar) {
  terms <- flatten_plus_terms(entry$rhs)
  is_phylo <- vapply(
    terms,
    is_structured_marker_call,
    logical(1),
    name = "phylo"
  )
  if (!any(is_phylo)) {
    return(list(rhs = entry$rhs, term = NULL))
  }
  if (sum(is_phylo) > 1L) {
    cli::cli_abort(c(
      "Only one phylogenetic structured effect is implemented in {.code {dpar}}.",
      "x" = "Use one term such as {.code phylo(1 | species, tree = tree)}."
    ))
  }

  phylo_terms <- Filter(
    function(term) identical(term$type, "phylo"),
    entry$structured
  )
  if (length(phylo_terms) != 1L) {
    cli::cli_abort(
      "Internal formula parser error while extracting {.fn phylo}."
    )
  }
  phylo_term <- phylo_terms[[1L]]
  valid_phylo_coef <- structured_term_is_intercept_only(phylo_term) ||
    structured_term_is_slope_only(phylo_term) ||
    structured_term_is_intercept_plus_slopes(phylo_term)
  if (!valid_phylo_coef) {
    cli::cli_abort(c(
      "Only intercept-only or one-slope phylogenetic {.code {dpar}} effects are implemented.",
      "x" = "Requested structured coefficient{?s}: {.val {phylo_term$coef_names}}.",
      "i" = "Use {.code phylo(1 | species, tree = tree)} or {.code phylo(1 + x | species, tree = tree)}."
    ))
  }

  list(rhs = rebuild_plus_terms(terms[!is_phylo]), term = phylo_term)
}

extract_gaussian_mu_spatial_term <- function(entry, dpar = entry$dpar) {
  terms <- flatten_plus_terms(entry$rhs)
  is_spatial <- vapply(
    terms,
    is_structured_marker_call,
    logical(1),
    name = "spatial"
  )
  if (!any(is_spatial)) {
    return(list(rhs = entry$rhs, term = NULL))
  }
  if (sum(is_spatial) > 1L) {
    cli::cli_abort(c(
      "Only one spatial structured effect is implemented in {.code {dpar}}.",
      "x" = "Use one term such as {.code spatial(1 | site, coords = coords)}."
    ))
  }

  spatial_terms <- Filter(
    function(term) identical(term$type, "spatial"),
    entry$structured
  )
  if (length(spatial_terms) != 1L) {
    cli::cli_abort(
      "Internal formula parser error while extracting {.fn spatial}."
    )
  }
  spatial_term <- spatial_terms[[1L]]
  valid_spatial_coef <- structured_term_is_intercept_only(spatial_term) ||
    structured_term_is_slope_only(spatial_term) ||
    structured_term_is_intercept_plus_slopes(spatial_term)
  if (!valid_spatial_coef) {
    cli::cli_abort(c(
      "Only intercept-only or one-slope spatial {.code {dpar}} effects are implemented.",
      "x" = "Requested structured coefficient{?s}: {.val {spatial_term$coef_names}}.",
      "i" = "Use {.code spatial(1 | site, coords = coords)} or {.code spatial(1 + x | site, coords = coords)}."
    ))
  }
  if (!identical(spatial_term$structure, "coords")) {
    cli::cli_abort(c(
      "Precomputed spatial mesh fitting is planned but not implemented yet.",
      "x" = "Requested {.code spatial(1 | {spatial_term$group}, mesh = {spatial_term$object})}.",
      "i" = "Use {.code spatial(1 | {spatial_term$group}, coords = coords)} for the first fitted coordinate-based spatial path."
    ))
  }

  list(rhs = rebuild_plus_terms(terms[!is_spatial]), term = spatial_term)
}

extract_gaussian_mu_known_term <- function(entry, marker, dpar = entry$dpar) {
  terms <- flatten_plus_terms(entry$rhs)
  is_known <- vapply(
    terms,
    is_structured_marker_call,
    logical(1),
    name = marker
  )
  if (!any(is_known)) {
    return(list(rhs = entry$rhs, term = NULL))
  }
  if (sum(is_known) > 1L) {
    cli::cli_abort(c(
      "Only one {.fn {marker}} structured effect is implemented in {.code {dpar}}.",
      "x" = "Use one term such as {.code {marker}(1 | id, Q = Q)}."
    ))
  }

  known_terms <- Filter(
    function(term) identical(term$type, marker),
    entry$structured
  )
  if (length(known_terms) != 1L) {
    cli::cli_abort(
      "Internal formula parser error while extracting {.fn {marker}}."
    )
  }
  known_term <- known_terms[[1L]]
  valid_known_coef <- structured_term_is_intercept_only(known_term) ||
    structured_term_is_slope_only(known_term) ||
    structured_term_is_intercept_plus_slopes(known_term)
  if (!valid_known_coef) {
    cli::cli_abort(c(
      "Only intercept-only or one-slope {.fn {marker}} {.code {dpar}} effects are implemented.",
      "x" = "Requested structured coefficient{?s}: {.val {known_term$coef_names}}.",
      "i" = "Use {.code {marker}(1 | {known_term$group}, {known_term$structure} = {known_term$object})} or {.code {marker}(1 + x | {known_term$group}, {known_term$structure} = {known_term$object})}."
    ))
  }

  list(rhs = rebuild_plus_terms(terms[!is_known]), term = known_term)
}

extract_gaussian_mu_phylo_interaction_term <- function(
  entry,
  dpar = entry$dpar
) {
  marker <- "phylo_interaction"
  terms <- flatten_plus_terms(entry$rhs)
  is_interaction <- vapply(
    terms,
    is_structured_marker_call,
    logical(1),
    name = marker
  )
  if (!any(is_interaction)) {
    return(list(rhs = entry$rhs, term = NULL))
  }
  if (sum(is_interaction) > 1L) {
    cli::cli_abort(c(
      "Only one {.fn phylo_interaction} structured effect is implemented in {.code {dpar}}.",
      "x" = "Use one term such as {.code phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree)}."
    ))
  }

  interaction_terms <- Filter(
    function(term) identical(term$type, marker),
    entry$structured
  )
  if (length(interaction_terms) != 1L) {
    cli::cli_abort(
      "Internal formula parser error while extracting {.fn phylo_interaction}."
    )
  }
  interaction_term <- interaction_terms[[1L]]
  if (!identical(interaction_term$coef_names, "(Intercept)")) {
    cli::cli_abort(c(
      "Only intercept-only {.fn phylo_interaction} {.code {dpar}} effects are implemented.",
      "x" = "Requested structured coefficient{?s}: {.val {interaction_term$coef_names}}.",
      "i" = "Use {.code phylo_interaction(1 | {interaction_term$group}, tree1 = {interaction_term$tree1}, tree2 = {interaction_term$tree2})}."
    ))
  }

  list(
    rhs = rebuild_plus_terms(terms[!is_interaction]),
    term = interaction_term
  )
}

combine_univariate_structured_terms <- function(mu_term, sigma_term, marker) {
  if (is.null(mu_term) && is.null(sigma_term)) {
    return(NULL)
  }
  if (!is.null(sigma_term)) {
    validate_univariate_sigma_structured_term(sigma_term, marker)
  }
  labelled_one_slope <- c(
    mu = structured_term_has_labelled_intercept_plus_slopes(mu_term),
    sigma = structured_term_has_labelled_intercept_plus_slopes(sigma_term)
  )
  if (any(labelled_one_slope)) {
    marker_title <- structured_marker_title(marker)
    bad <- names(labelled_one_slope)[labelled_one_slope]
    coef_names <- unique(c(mu_term$coef_names, sigma_term$coef_names))
    cli::cli_abort(c(
      "{marker_title} labelled intercept-plus-slope structured covariance is only implemented for the all-four bivariate Gaussian block in this slice.",
      "x" = "{.code {bad}} requested labelled structured coefficient{?s}: {.val {coef_names}}.",
      "i" = "Use unlabelled {.code {marker}(1 + x | group, ...)} for the independent univariate one-slope path, or put matching labelled terms in {.code mu1}, {.code mu2}, {.code sigma1}, and {.code sigma2} for the exact bivariate all-four block."
    ))
  }
  if (is.null(mu_term)) {
    q <- length(sigma_term$coef_names)
    sigma_term$dpars <- "sigma"
    sigma_term$q <- q
    sigma_term$covariance_mode <- "scalar"
    sigma_term$block_ids <- rep(1L, q)
    sigma_term$block_labels <- structured_term_default_block(sigma_term, marker)
    sigma_term$endpoint_blocks <- rep(sigma_term$block_labels[[1L]], q)
    sigma_term$endpoint_covariance_labels <- rep(
      structured_term_endpoint_label(sigma_term),
      q
    )
    sigma_term$label <- format_structured_label(
      marker,
      "1",
      sigma_term$group,
      sigma_term$covariance_label
    )
    return(sigma_term)
  }
  if (is.null(sigma_term)) {
    return(mu_term)
  }

  validate_univariate_sigma_structured_match(mu_term, sigma_term, marker)
  matched_one_slope <- structured_term_is_intercept_one_slope(mu_term) &&
    structured_term_is_intercept_one_slope(sigma_term)
  if (matched_one_slope) {
    mu_term$dpars <- c(
      rep("mu", length(mu_term$coef_names)),
      rep("sigma", length(sigma_term$coef_names))
    )
    mu_term$coef_names <- c(mu_term$coef_names, sigma_term$coef_names)
    mu_term$variables <- c(mu_term$variables, sigma_term$variables)
  } else {
    mu_term$dpars <- c("mu", "sigma")
  }
  mu_term$q <- length(mu_term$dpars)
  mu_term$covariance_mode <- "scalar"
  mu_term$block_ids <- rep(1L, mu_term$q)
  mu_term$block_labels <- structured_term_default_block(mu_term, marker)
  mu_term$endpoint_blocks <- rep(mu_term$block_labels[[1L]], mu_term$q)
  endpoint_label <- structured_term_endpoint_label(mu_term)
  mu_term$endpoint_covariance_labels <- rep(endpoint_label, mu_term$q)
  mu_term$label <- format_structured_label(
    marker,
    "1",
    mu_term$group,
    mu_term$covariance_label
  )
  mu_term
}

validate_univariate_sigma_structured_term <- function(term, marker) {
  marker_title <- structured_marker_title(marker)
  valid_open_one_slope <- marker %in%
    c("phylo", "spatial", "animal", "relmat") &&
    structured_term_is_intercept_one_slope(term)
  if (!structured_term_is_intercept_only(term) && !valid_open_one_slope) {
    cli::cli_abort(c(
      "{marker_title} residual-scale structured effects are intercept-only in this slice.",
      "x" = "{.code sigma} requested structured coefficient{?s}: {.val {term$coef_names}}.",
      "i" = "Use {.code sigma ~ {marker}(1 | {term$group}, ...)}; the first provider-specific residual-scale one-slope cells are open for {.fn phylo}, fixed-covariance {.fn spatial}, A-matrix {.fn animal}, and K/Q {.fn relmat}."
    ))
  }
}

validate_univariate_sigma_structured_match <- function(
  mu_term,
  sigma_term,
  marker
) {
  marker_title <- structured_marker_title(marker)
  matched_intercept <- structured_term_is_intercept_only(mu_term) &&
    structured_term_is_intercept_only(sigma_term)
  matched_one_slope <- structured_term_is_intercept_one_slope(mu_term) &&
    structured_term_is_intercept_one_slope(sigma_term) &&
    identical(mu_term$coef_names, sigma_term$coef_names) &&
    identical(mu_term$variables, sigma_term$variables)
  if (!matched_intercept && !matched_one_slope) {
    cli::cli_abort(c(
      "{marker_title} univariate location-scale blocks must use matching intercept-only or one-slope structured terms in this slice.",
      "x" = "{.code mu} requested structured coefficient{?s}: {.val {mu_term$coef_names}}.",
      "x" = "{.code sigma} requested structured coefficient{?s}: {.val {sigma_term$coef_names}}.",
      "i" = "Use matching terms such as {.code {marker}(1 | {mu_term$group}, ...)} or {.code {marker}(1 + x | {mu_term$group}, ...)} in both {.code mu} and {.code sigma}."
    ))
  }
  if (!structured_terms_same_source(mu_term, sigma_term, marker)) {
    cli::cli_abort(c(
      "Matched univariate {tolower(marker_title)} location-scale terms must use the same structured source.",
      "x" = "{.code mu} uses {.code {structured_term_source_label(mu_term, marker)}}.",
      "x" = "{.code sigma} uses {.code {structured_term_source_label(sigma_term, marker)}}.",
      "i" = "Use the same grouping variable and tree, coordinate object, pedigree, covariance, or precision matrix in both formulas."
    ))
  }
  if (!identical(mu_term$covariance_label, sigma_term$covariance_label)) {
    block_mu <- phylo_term_block(mu_term)
    block_sigma <- phylo_term_block(sigma_term)
    cli::cli_abort(c(
      "Matched univariate {tolower(marker_title)} location-scale terms must use the same covariance-block label.",
      "x" = "{.code mu} uses block {.code {block_mu}}.",
      "x" = "{.code sigma} uses block {.code {block_sigma}}.",
      "i" = "Use matching labels such as {.code {marker}(1 | p | {mu_term$group}, ...)} in both formulas, or leave both terms unlabelled."
    ))
  }
}

structured_term_is_intercept_only <- function(term) {
  identical(term$coef_names, "(Intercept)") &&
    identical(term$variables, NA_character_)
}

structured_term_is_intercept_one_slope <- function(term) {
  is.character(term$coef_names) &&
    length(term$coef_names) == 2L &&
    identical(term$coef_names[[1L]], "(Intercept)") &&
    identical(term$coef_names[[2L]], term$variables[[1L]])
}

# Intercept plus one or more slopes (`1 + x`, `1 + x + z`, ...). The two-slope
# form is the q6 bivariate location block; the one-slope form is the admitted
# q4 location block.
structured_term_is_intercept_plus_slopes <- function(term) {
  is.character(term$coef_names) &&
    length(term$coef_names) >= 2L &&
    identical(term$coef_names[[1L]], "(Intercept)") &&
    identical(term$coef_names[-1L], as.character(term$variables))
}

structured_term_is_slope_only <- function(term) {
  is.character(term$coef_names) &&
    length(term$coef_names) == 1L &&
    identical(term$coef_names[[1L]], term$variables[[1L]])
}

structured_term_has_labelled_intercept_one_slope <- function(term) {
  !is.null(term) &&
    !is.null(term$covariance_label) &&
    structured_term_is_intercept_one_slope(term)
}

structured_term_has_labelled_intercept_plus_slopes <- function(term) {
  !is.null(term) &&
    !is.null(term$covariance_label) &&
    structured_term_is_intercept_plus_slopes(term)
}

structured_terms_same_source <- function(term1, term2, marker) {
  same_group <- identical(term1$group, term2$group)
  if (identical(marker, "phylo")) {
    return(same_group && identical(term1$tree, term2$tree))
  }
  same_group &&
    identical(term1$structure, term2$structure) &&
    identical(term1$object, term2$object)
}

structured_term_source_label <- function(term, marker) {
  object <- if (identical(marker, "phylo")) term$tree else term$object
  structure <- if (identical(marker, "phylo")) "tree" else term$structure
  paste0(marker, "(1 | ", term$group, ", ", structure, " = ", object, ")")
}

structured_term_default_block <- function(term, marker) {
  if (is.null(term$covariance_label)) {
    return(marker)
  }
  term$covariance_label
}

structured_term_endpoint_label <- function(term) {
  if (is.null(term$covariance_label)) {
    return(NA_character_)
  }
  term$covariance_label
}

entry_phylo_structured_terms <- function(entry) {
  entry_structured_terms(entry, "phylo")
}

entry_structured_terms <- function(entry, marker) {
  Filter(
    function(term) identical(term$type, marker),
    entry$structured
  )
}

single_entry_phylo_structured_term <- function(entry) {
  single_entry_structured_term(entry, "phylo")
}

single_entry_structured_term <- function(entry, marker) {
  terms <- entry_structured_terms(entry, marker)
  if (length(terms) == 0L) {
    return(NULL)
  }
  if (length(terms) > 1L) {
    cli::cli_abort(c(
      "Only one {.fn {marker}} structured effect is allowed per distributional formula.",
      "x" = "{.code {entry$dpar}} contains {length(terms)} {.fn {marker}} terms.",
      "i" = "The q=4 structured block uses one intercept-only term per endpoint."
    ))
  }
  terms[[1L]]
}

remove_structured_marker_terms <- function(rhs, name) {
  terms <- flatten_plus_terms(rhs)
  is_marker <- vapply(
    terms,
    is_structured_marker_call,
    logical(1),
    name = name
  )
  rebuild_plus_terms(terms[!is_marker])
}

phylo_term_block <- function(term) {
  if (is.null(term) || is.null(term$covariance_label)) {
    return("phylo")
  }
  term$covariance_label
}

phylo_mu_block <- function(phylo_mu) {
  if (
    !is.list(phylo_mu) ||
      is.null(phylo_mu$block) ||
      is.na(phylo_mu$block) ||
      !nzchar(phylo_mu$block)
  ) {
    return("phylo")
  }
  phylo_mu$block
}

phylo_mu_covariance_mode <- function(phylo_mu) {
  mode <- phylo_mu$covariance_mode
  if (is.character(mode) && length(mode) == 1L && nzchar(mode)) {
    return(mode)
  }
  q <- structured_mu_q(phylo_mu)
  if (q > 2L) {
    return("unstructured")
  }
  "scalar"
}

phylo_mu_is_block_diagonal <- function(phylo_mu) {
  identical(phylo_mu_covariance_mode(phylo_mu), "block_diagonal")
}

phylo_mu_block_ids <- function(phylo_mu) {
  q <- structured_mu_q(phylo_mu)
  block_ids <- phylo_mu$block_ids
  if (
    is.numeric(block_ids) &&
      length(block_ids) == q &&
      all(is.finite(block_ids)) &&
      all(block_ids >= 1L)
  ) {
    return(as.integer(block_ids))
  }
  rep(1L, q)
}

phylo_mu_endpoint_blocks <- function(phylo_mu) {
  q <- structured_mu_q(phylo_mu)
  endpoint_blocks <- phylo_mu$endpoint_blocks
  if (is.character(endpoint_blocks) && length(endpoint_blocks) == q) {
    return(endpoint_blocks)
  }
  block_labels <- phylo_mu$block_labels
  block_ids <- phylo_mu_block_ids(phylo_mu)
  if (length(block_ids) == 0L) {
    return(character())
  }
  if (
    is.character(block_labels) &&
      length(block_labels) >= max(block_ids)
  ) {
    return(block_labels[block_ids])
  }
  rep(phylo_mu_block(phylo_mu), q)
}

phylo_mu_endpoint_covariance_labels <- function(phylo_mu) {
  q <- structured_mu_q(phylo_mu)
  labels <- phylo_mu$endpoint_covariance_labels
  if (is.character(labels) && length(labels) == q) {
    return(labels)
  }
  label <- phylo_mu$covariance_label
  if (is.null(label)) {
    return(rep(NA_character_, q))
  }
  rep(label, q)
}

phylo_mu_endpoint_labels <- function(phylo_mu) {
  q <- structured_mu_q(phylo_mu)
  covariance_labels <- phylo_mu_endpoint_covariance_labels(phylo_mu)
  vapply(
    seq_len(q),
    function(i) {
      covariance_label <- covariance_labels[[i]]
      if (is.na(covariance_label) || !nzchar(covariance_label)) {
        covariance_label <- NULL
      }
      format_structured_label(
        structured_mu_type(phylo_mu),
        "1",
        phylo_mu$group,
        covariance_label
      )
    },
    character(1L)
  )
}

phylo_mu_n_blocks <- function(phylo_mu) {
  block_ids <- phylo_mu_block_ids(phylo_mu)
  if (length(block_ids) == 0L) {
    return(0L)
  }
  max(block_ids)
}

phylo_mu_theta_count <- function(phylo_mu) {
  q <- structured_mu_q(phylo_mu)
  if (q <= 2L) {
    return(0L)
  }
  if (!phylo_mu_is_block_diagonal(phylo_mu)) {
    return(choose(q, 2L))
  }
  block_sizes <- tabulate(phylo_mu_block_ids(phylo_mu))
  sum(vapply(block_sizes, function(size) choose(size, 2L), numeric(1L)))
}

structured_mu_type <- function(phylo_mu) {
  type <- phylo_mu$type
  if (is.character(type) && length(type) == 1L && nzchar(type)) {
    return(type)
  }
  "phylo"
}

structured_mu_random_effect_key <- function(phylo_mu, model_type = NULL) {
  endpoint_dpars <- if (isTRUE(phylo_mu$has)) {
    unique(phylo_mu_endpoint_dpars(phylo_mu))
  } else {
    "mu"
  }
  suffix <- if (
    !is.null(model_type) && model_type %in% c("gaussian", "biv_gaussian")
  ) {
    # Gaussian location-scale keeps the generic `_mu` block regardless of which
    # endpoint the structured term attaches to (the main-era contract). Only
    # non-Gaussian families use endpoint-aware block names (e.g. `_sigma`,
    # `_nu`, `_zi`, `_hu`).
    "mu"
  } else if (length(endpoint_dpars) == 1L) {
    endpoint_dpars
  } else {
    "mu"
  }
  switch(
    structured_mu_type(phylo_mu),
    spatial = paste0("spatial_", suffix),
    animal = paste0("animal_", suffix),
    relmat = paste0("relmat_", suffix),
    phylo_interaction = paste0("phylo_interaction_", suffix),
    paste0("phylo_", suffix)
  )
}

structured_mu_correlation_key <- function(phylo_mu) {
  switch(
    structured_mu_type(phylo_mu),
    spatial = "spatial",
    animal = "animal",
    relmat = "relmat",
    phylo_interaction = "phylo_interaction",
    "phylo"
  )
}

structured_mu_corpair_level <- function(phylo_mu) {
  switch(
    structured_mu_type(phylo_mu),
    phylo = "phylogenetic",
    spatial = "spatial",
    animal = "animal",
    relmat = "relmat",
    phylo_interaction = "phylo_interaction",
    structured_mu_type(phylo_mu)
  )
}

phylo_mu_dpars <- function(phylo_mu) {
  dpars <- phylo_mu$dpars
  if (is.character(dpars) && length(dpars) > 0L) {
    return(dpars)
  }
  if (!is.null(phylo_mu$q) && identical(as.integer(phylo_mu$q), 2L)) {
    return(c("mu1", "mu2"))
  }
  "mu"
}

phylo_mu_endpoint_dpars <- function(phylo_mu) {
  q <- structured_mu_q(phylo_mu)
  dpars <- phylo_mu_dpars(phylo_mu)
  if (length(dpars) == q) {
    return(dpars)
  }
  if (length(dpars) == 1L) {
    return(rep(dpars, q))
  }
  dpars[seq_len(q)]
}

phylo_mu_dpar_codes <- function(phylo_mu) {
  if (!isTRUE(phylo_mu$has)) {
    return(0L)
  }
  family <- sub("[0-9]+$", "", phylo_mu_endpoint_dpars(phylo_mu))
  codes <- match(family, c("mu", "sigma", "nu", "zi", "hu")) - 1L
  if (anyNA(codes)) {
    cli::cli_abort(
      "Internal error: structured-effect endpoint has unknown distributional parameter {.val {family[is.na(codes)][[1L]]}}."
    )
  }
  as.integer(codes)
}

phylo_mu_response_codes <- function(phylo_mu) {
  if (!isTRUE(phylo_mu$has)) {
    return(0L)
  }
  suffix <- sub("^(mu|sigma)", "", phylo_mu_endpoint_dpars(phylo_mu))
  response <- suppressWarnings(as.integer(suffix))
  response[is.na(response)] <- 0L
  as.integer(response)
}

phylo_mu_has_cross_dpar <- function(phylo_mu) {
  if (!isTRUE(phylo_mu$has) || structured_mu_q(phylo_mu) != 2L) {
    return(FALSE)
  }
  length(unique(phylo_mu_dpar_codes(phylo_mu))) > 1L
}

phylo_mu_sd_labels <- function(phylo_mu, model_type) {
  if (identical(model_type, "biv_gaussian")) {
    return(paste0(
      phylo_mu_dpars(phylo_mu),
      ":",
      structured_mu_coef_labels(phylo_mu)
    ))
  }
  dpars <- phylo_mu_endpoint_dpars(phylo_mu)
  q <- structured_mu_q(phylo_mu)
  if (length(dpars) == q && length(unique(dpars)) > 1L) {
    return(paste0(
      dpars,
      ":",
      structured_mu_coef_labels(phylo_mu)
    ))
  }
  q <- structured_mu_q(phylo_mu)
  if (q > 1L) {
    return(structured_mu_coef_labels(phylo_mu))
  }
  label <- phylo_mu$label
  if (!is.character(label) || length(label) != 1L || !nzchar(label)) {
    label <- phylo_mu_endpoint_labels(phylo_mu)[[1L]]
  }
  label
}

structured_mu_q <- function(phylo_mu) {
  q <- phylo_mu$q
  if (is.numeric(q) && length(q) == 1L && is.finite(q) && q > 0L) {
    return(as.integer(q))
  }
  coef_names <- phylo_mu$coef_names
  if (is.character(coef_names) && length(coef_names) > 0L) {
    return(length(coef_names))
  }
  1L
}

structured_mu_coef_labels <- function(phylo_mu) {
  coef_names <- structured_mu_endpoint_coef_names(phylo_mu)
  vapply(
    coef_names,
    function(coef_name) {
      lhs <- if (identical(coef_name, "(Intercept)")) {
        "1"
      } else {
        paste0("0 + ", coef_name)
      }
      format_structured_label(
        structured_mu_type(phylo_mu),
        lhs,
        phylo_mu$group,
        phylo_mu$covariance_label
      )
    },
    character(1L),
    USE.NAMES = FALSE
  )
}

structured_mu_endpoint_coef_names <- function(phylo_mu) {
  q <- structured_mu_q(phylo_mu)
  coef_names <- phylo_mu$coef_names
  if (!is.character(coef_names) || length(coef_names) == 0L) {
    coef_names <- "(Intercept)"
  }
  if (length(coef_names) == q) {
    return(coef_names)
  }
  if (length(coef_names) == 1L) {
    return(rep(coef_names, q))
  }
  coef_names[seq_len(q)]
}

phylo_mu_pair_table <- function(phylo_mu) {
  dpars <- phylo_mu_dpars(phylo_mu)
  if (length(dpars) < 2L) {
    return(data.frame(
      from_index = integer(),
      to_index = integer(),
      from_dpar = character(),
      to_dpar = character(),
      block = character(),
      parameter = character(),
      stringsAsFactors = FALSE
    ))
  }
  pair_index <- utils::combn(seq_along(dpars), 2L)
  endpoint_blocks <- phylo_mu_endpoint_blocks(phylo_mu)
  if (phylo_mu_is_block_diagonal(phylo_mu)) {
    same_block <- endpoint_blocks[pair_index[1L, ]] ==
      endpoint_blocks[pair_index[2L, ]]
    pair_index <- pair_index[, same_block, drop = FALSE]
  }
  block <- endpoint_blocks[pair_index[1L, ]]
  group <- phylo_mu$group
  coef_names <- structured_mu_endpoint_coef_names(phylo_mu)
  data.frame(
    from_index = pair_index[1L, ],
    to_index = pair_index[2L, ],
    from_dpar = dpars[pair_index[1L, ]],
    to_dpar = dpars[pair_index[2L, ]],
    from_coef = coef_names[pair_index[1L, ]],
    to_coef = coef_names[pair_index[2L, ]],
    block = block,
    parameter = mapply(
      format_cross_dpar_cor_label,
      dpars[pair_index[1L, ]],
      dpars[pair_index[2L, ]],
      group = group,
      covariance_label = block,
      from_coef = coef_names[pair_index[1L, ]],
      to_coef = coef_names[pair_index[2L, ]],
      USE.NAMES = FALSE
    ),
    stringsAsFactors = FALSE
  )
}

detect_biv_phylo_q4_terms <- function(
  mu1_entry,
  mu2_entry,
  sigma1_entry,
  sigma2_entry
) {
  detect_biv_structured_q4_terms(
    mu1_entry,
    mu2_entry,
    sigma1_entry,
    sigma2_entry,
    marker = "phylo"
  )
}

detect_biv_known_q4_terms <- function(
  mu1_entry,
  mu2_entry,
  sigma1_entry,
  sigma2_entry,
  marker
) {
  detect_biv_structured_q4_terms(
    mu1_entry,
    mu2_entry,
    sigma1_entry,
    sigma2_entry,
    marker = marker
  )
}

detect_biv_spatial_q4_terms <- function(
  mu1_entry,
  mu2_entry,
  sigma1_entry,
  sigma2_entry
) {
  detect_biv_structured_q4_terms(
    mu1_entry,
    mu2_entry,
    sigma1_entry,
    sigma2_entry,
    marker = "spatial"
  )
}

detect_biv_structured_q4_terms <- function(
  mu1_entry,
  mu2_entry,
  sigma1_entry,
  sigma2_entry,
  marker
) {
  entries <- list(
    mu1 = mu1_entry,
    mu2 = mu2_entry,
    sigma1 = sigma1_entry,
    sigma2 = sigma2_entry
  )
  terms <- lapply(entries, single_entry_structured_term, marker = marker)
  has_marker <- !vapply(terms, is.null, logical(1L))
  if (!any(has_marker[c("sigma1", "sigma2")])) {
    return(list(has = FALSE, term = NULL))
  }

  marker_title <- structured_marker_title(marker)
  if (!all(has_marker)) {
    scale_only <- all(has_marker[c("sigma1", "sigma2")]) &&
      !any(has_marker[c("mu1", "mu2")])
    if (scale_only) {
      scale_terms <- terms[c("sigma1", "sigma2")]
      labels <- vapply(scale_terms, phylo_term_block, character(1L))
      explicit_labels <- vapply(
        scale_terms,
        function(term) !is.null(term$covariance_label),
        logical(1L)
      )
      groups <- vapply(scale_terms, `[[`, character(1L), "group")
      structures <- vapply(
        scale_terms,
        function(term) {
          if (!is.null(term$structure)) term$structure else "tree"
        },
        character(1L)
      )
      objects <- vapply(
        scale_terms,
        function(term) {
          if (!is.null(term$tree)) term$tree else term$object
        },
        character(1L)
      )
      intercept_only <- vapply(
        scale_terms,
        structured_term_is_intercept_only,
        logical(1L)
      )
      if (!all(intercept_only)) {
        bad <- names(intercept_only)[!intercept_only]
        cli::cli_abort(c(
          "{marker_title} scale-side q=2 blocks need matching intercept-only terms in this slice.",
          "x" = "{.code {bad}} requested unsupported structured coefficient{?s}.",
          "i" = "Use matching {.code {marker}(1 | ps | group, ...)} terms in {.code sigma1} and {.code sigma2}."
        ))
      }
      if (!all(explicit_labels)) {
        unlabeled <- names(explicit_labels)[!explicit_labels]
        cli::cli_abort(c(
          "{marker_title} scale-side q=2 blocks require an explicit covariance-block label.",
          "x" = "{.code {unlabeled}} use{?s} unlabelled {.fn {marker}} syntax.",
          "i" = "Use one shared label, for example {.code {marker}(1 | ps | group, ...)}, across {.code sigma1} and {.code sigma2}."
        ))
      }
      same_source_and_group <- length(unique(groups)) == 1L &&
        length(unique(structures)) == 1L &&
        length(unique(objects)) == 1L
      same_label <- length(unique(labels)) == 1L
      if (!same_source_and_group || !same_label) {
        cli::cli_abort(c(
          "{marker_title} scale-side q=2 terms need a supported block layout.",
          "x" = "Blocks: {.val {labels}}.",
          "x" = "Groups: {.val {groups}}.",
          "x" = "Inputs: {.val {objects}}.",
          "i" = "Use one shared label, such as {.code {marker}(1 | ps | group, ...)}, in both scale endpoints."
        ))
      }

      term <- scale_terms[[1L]]
      term$dpars <- names(scale_terms)
      term$q <- length(term$dpars)
      term$covariance_mode <- "scalar"
      term$block_ids <- rep(1L, term$q)
      term$block_labels <- labels[[1L]]
      term$endpoint_blocks <- rep(labels[[1L]], term$q)
      term$endpoint_covariance_labels <- term$endpoint_blocks
      term$label <- format_structured_label(
        marker,
        "1",
        groups[[1L]],
        labels[[1L]]
      )
      return(list(has = TRUE, term = term))
    }
    present <- names(has_marker)[has_marker]
    missing <- names(has_marker)[!has_marker]
    cli::cli_abort(c(
      "Partial {tolower(marker_title)} location-scale blocks are not implemented.",
      "x" = "{.code {present}} contain{?s} {.fn {marker}}, but {.code {missing}} do{?es} not.",
      "i" = "Use matching labelled intercepts in {.code mu1}, {.code mu2}, {.code sigma1}, and {.code sigma2}."
    ))
  }

  labels <- vapply(terms, phylo_term_block, character(1L))
  explicit_labels <- vapply(
    terms,
    function(term) !is.null(term$covariance_label),
    logical(1L)
  )
  groups <- vapply(terms, `[[`, character(1L), "group")
  structures <- vapply(
    terms,
    function(term) {
      if (!is.null(term$structure)) term$structure else "tree"
    },
    character(1L)
  )
  objects <- vapply(
    terms,
    function(term) {
      if (!is.null(term$tree)) term$tree else term$object
    },
    character(1L)
  )
  intercept_only <- vapply(
    terms,
    structured_term_is_intercept_only,
    logical(1L)
  )
  # Accept intercept + one OR MORE matching slopes across all four endpoints:
  # the q8 all-four one-slope block (`1 + x`) and the q12 all-four two-slope
  # block (`1 + x + z`). `all_one_slope` here means "all endpoints carry slopes"
  # (not intercept-only) -- the finalize below expands coef_names generically to
  # q = 4 * n_coef. Intercept-only stays the separate q4 path.
  intercept_one_slope <- vapply(
    terms,
    structured_term_is_intercept_plus_slopes,
    logical(1L)
  )
  all_intercept <- all(intercept_only)
  all_one_slope <- all(intercept_one_slope)

  if (!all_intercept && !all_one_slope) {
    bad <- names(intercept_only)[!intercept_only & !intercept_one_slope]
    cli::cli_abort(c(
      "{marker_title} q=4 location-scale blocks need matching intercept-only or intercept-plus-slope terms in this slice.",
      "x" = "{.code {bad}} requested unsupported structured coefficient{?s}.",
      "i" = "Use matching {.code {marker}(1 | p | group, ...)} terms in all four endpoints, or matching full-block {.code {marker}(1 + x | p | group, ...)} terms in all four endpoints."
    ))
  }
  if (all_one_slope) {
    coef_reference <- terms[[1L]]$coef_names
    variables_reference <- terms[[1L]]$variables
    same_coef <- vapply(
      terms,
      function(term) {
        identical(term$coef_names, coef_reference) &&
          identical(term$variables, variables_reference)
      },
      logical(1L)
    )
    if (!all(same_coef)) {
      bad <- names(same_coef)[!same_coef]
      cli::cli_abort(c(
        "{marker_title} q=4 location-scale slope blocks require the same structured coefficient in all four endpoints.",
        "x" = "{.code {bad}} do{?es} not match {.val {coef_reference}}.",
        "i" = "Use matching terms such as {.code {marker}(1 + x | p | group, ...)} in {.code mu1}, {.code mu2}, {.code sigma1}, and {.code sigma2}."
      ))
    }
  }
  if (!all(explicit_labels)) {
    unlabeled <- names(explicit_labels)[!explicit_labels]
    cli::cli_abort(c(
      "{marker_title} q=4 location-scale blocks require an explicit covariance-block label.",
      "x" = "{.code {unlabeled}} use{?s} unlabelled {.fn {marker}} syntax.",
      "i" = "Use one shared label, for example {.code {marker}(1 | p | group, ...)}, across {.code mu1}, {.code mu2}, {.code sigma1}, and {.code sigma2}."
    ))
  }
  same_source_and_group <- length(unique(groups)) == 1L &&
    length(unique(structures)) == 1L &&
    length(unique(objects)) == 1L
  full_q4 <- length(unique(labels)) == 1L
  block_diagonal_q4 <- identical(labels[["mu1"]], labels[["mu2"]]) &&
    identical(labels[["sigma1"]], labels[["sigma2"]]) &&
    !identical(labels[["mu1"]], labels[["sigma1"]])
  if (all_one_slope && !full_q4) {
    cli::cli_abort(c(
      "{marker_title} all-four intercept-plus-slope structured blocks require one shared covariance label in this slice.",
      "x" = "Blocks: {.val {labels}}.",
      "i" = "Use one full block, such as {.code {marker}(1 + x | p | group, ...)}, in {.code mu1}, {.code mu2}, {.code sigma1}, and {.code sigma2}.",
      "i" = "The block-diagonal intercept-plus-slope layout remains a separate planned q-series cell."
    ))
  }

  if (!same_source_and_group || !(full_q4 || block_diagonal_q4)) {
    cli::cli_abort(c(
      "{marker_title} q=4 location-scale terms need a supported block layout.",
      "x" = "Blocks: {.val {labels}}.",
      "x" = "Groups: {.val {groups}}.",
      "x" = "Inputs: {.val {objects}}.",
      "i" = "Use one full block, such as {.code {marker}(1 | p | group, ...)}, in all four endpoints.",
      "i" = "Or use the block-diagonal fallback with one label for {.code mu1}/{.code mu2} and one label for {.code sigma1}/{.code sigma2}."
    ))
  }

  term <- terms[[1L]]
  if (all_one_slope) {
    endpoint_names <- names(terms)
    coef_names <- terms[[1L]]$coef_names
    term$dpars <- rep(endpoint_names, each = length(coef_names))
    term$coef_names <- rep(coef_names, times = length(endpoint_names))
    term$variables <- ifelse(
      term$coef_names == "(Intercept)",
      NA_character_,
      term$coef_names
    )
  } else {
    term$dpars <- names(terms)
  }
  term$q <- length(term$dpars)
  term$covariance_mode <- if (full_q4) {
    "unstructured"
  } else {
    "block_diagonal"
  }
  term$block_ids <- if (full_q4) {
    rep(1L, term$q)
  } else if (all_one_slope) {
    rep(
      c(mu1 = 1L, mu2 = 1L, sigma1 = 2L, sigma2 = 2L),
      each = length(terms[[1L]]$coef_names)
    )
  } else {
    c(mu1 = 1L, mu2 = 1L, sigma1 = 2L, sigma2 = 2L)
  }
  term$block_labels <- if (full_q4) {
    labels[[1L]]
  } else {
    c(labels[["mu1"]], labels[["sigma1"]])
  }
  term$endpoint_blocks <- if (all_one_slope) {
    rep(labels, each = length(terms[[1L]]$coef_names))
  } else {
    labels
  }
  term$endpoint_covariance_labels <- term$endpoint_blocks
  term$label <- format_structured_label(
    marker,
    if (all_one_slope) {
      paste0("1 + ", paste(terms[[1L]]$variables, collapse = " + "))
    } else {
      "1"
    },
    groups[[1L]],
    labels[[1L]]
  )
  list(has = TRUE, term = term)
}

structured_marker_title <- function(marker) {
  switch(
    marker,
    phylo = "Phylogenetic",
    phylo_interaction = "Bipartite phylogenetic interaction",
    animal = "Animal-model",
    relmat = "relmat",
    spatial = "Spatial",
    marker
  )
}

structured_biv_q2_coef_name <- function(term, marker, dpar) {
  coef_names <- term$coef_names
  if (length(coef_names) == 1L) {
    return(coef_names[[1L]])
  }
  marker_example <- switch(
    marker,
    animal = paste0(marker, "(0 + x | p | id, A = A)"),
    relmat = paste0(marker, "(0 + x | p | id, Q = Q)"),
    spatial = paste0(marker, "(0 + x | p | site, coords = coords)"),
    paste0(marker, "(0 + x | p | species, tree = tree)")
  )
  cli::cli_abort(c(
    "Bivariate {.fn {marker}} q=2 location covariance supports exactly one structured coefficient per endpoint.",
    "x" = "{.code {dpar}} requested structured coefficients {.val {coef_names}}.",
    "i" = "Use intercept-only syntax such as {.code {marker}(1 | p | group, ...)} or slope-only syntax such as {.code {marker_example}}.",
    "i" = "Labelled intercept-plus-slope structured covariance remains a later q4/q8 slope-block gate."
  ))
}

validate_matching_structured_biv_location_coef <- function(
  term1,
  term2,
  marker
) {
  coef1 <- term1$coef_names
  coef2 <- term2$coef_names
  if (length(coef1) == 1L && length(coef2) == 1L) {
    coef1 <- structured_biv_q2_coef_name(term1, marker, "mu1")
    coef2 <- structured_biv_q2_coef_name(term2, marker, "mu2")
    if (!identical(coef1, coef2)) {
      cli::cli_abort(c(
        "Bivariate {.fn {marker}} q=2 location covariance requires the same structured coefficient in {.code mu1} and {.code mu2}.",
        "x" = "{.code mu1} uses {.val {coef1}}, but {.code mu2} uses {.val {coef2}}.",
        "i" = "Use matching slope-only terms such as {.code {marker}(0 + x | p | group, ...)} in both formulas."
      ))
    }
    return(coef1)
  }

  marker_title <- structured_marker_title(marker)
  both_intercept_plus_slopes <-
    structured_term_is_intercept_plus_slopes(term1) &&
    structured_term_is_intercept_plus_slopes(term2)
  if (!both_intercept_plus_slopes) {
    cli::cli_abort(c(
      "Bivariate {.fn {marker}} location covariance supports intercept-only, slope-only, or labelled intercept-plus-slope structured coefficients in this slice.",
      "x" = "{.code mu1} requested structured coefficients {.val {coef1}}.",
      "x" = "{.code mu2} requested structured coefficients {.val {coef2}}.",
      "i" = "Use intercept-only syntax such as {.code {marker}(1 | p | group, ...)}, slope-only syntax such as {.code {marker}(0 + x | p | group, ...)}, or matching labelled intercept-plus-slope syntax such as {.code {marker}(1 + x | p | group, ...)} or {.code {marker}(1 + x + z | p | group, ...)}."
    ))
  }
  if (!identical(coef1, coef2)) {
    cli::cli_abort(c(
      "{marker_title} bivariate location intercept-plus-slope blocks require the same structured coefficients in {.code mu1} and {.code mu2}.",
      "x" = "{.code mu1} uses {.val {coef1}}, but {.code mu2} uses {.val {coef2}}.",
      "i" = "Use matching terms such as {.code {marker}(1 + x | p | group, ...)} in both formulas."
    ))
  }
  if (!identical(term1$variables, term2$variables)) {
    cli::cli_abort(c(
      "{marker_title} bivariate location intercept-plus-slope blocks require the same slope variable in {.code mu1} and {.code mu2}.",
      "x" = "{.code mu1} uses {.val {term1$variables}}, but {.code mu2} uses {.val {term2$variables}}.",
      "i" = "Use matching one-slope terms in both location formulas."
    ))
  }
  if (is.null(term1$covariance_label) || is.null(term2$covariance_label)) {
    cli::cli_abort(c(
      "{marker_title} bivariate location intercept-plus-slope blocks require an explicit covariance-block label.",
      "i" = "Use matching labelled terms such as {.code {marker}(1 + x | p | group, ...)} in {.code mu1} and {.code mu2}."
    ))
  }
  coef1
}

finalize_biv_structured_mu_term <- function(term, marker) {
  coef_names <- term$coef_names
  block_label <- if (is.null(term$covariance_label)) {
    marker
  } else {
    term$covariance_label
  }
  if (length(coef_names) == 1L) {
    term$dpars <- c("mu1", "mu2")
    term$q <- 2L
    term$covariance_mode <- "scalar"
    term$block_ids <- c(1L, 1L)
    term$block_labels <- block_label
    term$endpoint_blocks <- rep(block_label, 2L)
    term$endpoint_covariance_labels <- if (is.null(term$covariance_label)) {
      rep(NA_character_, 2L)
    } else {
      rep(term$covariance_label, 2L)
    }
    return(term)
  }

  term$dpars <- rep(c("mu1", "mu2"), each = length(coef_names))
  term$coef_names <- rep(coef_names, times = 2L)
  term$variables <- ifelse(
    term$coef_names == "(Intercept)",
    NA_character_,
    term$coef_names
  )
  term$q <- length(term$dpars)
  term$covariance_mode <- "unstructured"
  term$block_ids <- rep(1L, term$q)
  term$block_labels <- block_label
  term$endpoint_blocks <- rep(block_label, term$q)
  term$endpoint_covariance_labels <- rep(term$covariance_label, term$q)
  term$label <- format_structured_label(
    marker,
    paste0("1 + ", paste(coef_names[-1L], collapse = " + ")),
    term$group,
    term$covariance_label
  )
  term
}

guard_biv_phylo_mu_terms <- function(mu1_entry, mu2_entry) {
  mu1_phylo <- extract_gaussian_mu_phylo_term(mu1_entry)
  mu2_phylo <- extract_gaussian_mu_phylo_term(mu2_entry)
  has_phylo <- c(
    mu1 = !is.null(mu1_phylo$term),
    mu2 = !is.null(mu2_phylo$term)
  )
  if (!any(has_phylo)) {
    return(list(mu1 = mu1_phylo, mu2 = mu2_phylo, term = NULL))
  }
  if (!all(has_phylo)) {
    missing <- names(has_phylo)[!has_phylo]
    present <- names(has_phylo)[has_phylo]
    cli::cli_abort(c(
      "Bivariate phylogenetic location terms must be matched in {.code mu1} and {.code mu2}.",
      "x" = "{.code {present}} contains {.fn phylo}, but {.code {missing}} does not.",
      "i" = "Use matching terms such as {.code mu1 = y1 ~ x + phylo(1 | species, tree = tree)} and {.code mu2 = y2 ~ x + phylo(1 | species, tree = tree)}."
    ))
  }

  term1 <- mu1_phylo$term
  term2 <- mu2_phylo$term
  validate_matching_structured_biv_location_coef(term1, term2, "phylo")
  if (
    !identical(term1$group, term2$group) ||
      !identical(term1$tree, term2$tree)
  ) {
    cli::cli_abort(c(
      "Matched bivariate phylogenetic location terms must use the same grouping variable and tree.",
      "x" = "{.code mu1} uses {.code phylo(1 | {term1$group}, tree = {term1$tree})}.",
      "x" = "{.code mu2} uses {.code phylo(1 | {term2$group}, tree = {term2$tree})}.",
      "i" = "The first fitted bivariate phylogenetic path will use one shared tree-derived precision for {.code mu1} and {.code mu2}."
    ))
  }
  if (!identical(term1$covariance_label, term2$covariance_label)) {
    block1 <- phylo_term_block(term1)
    block2 <- phylo_term_block(term2)
    cli::cli_abort(c(
      "Matched bivariate phylogenetic location terms must use the same covariance-block label.",
      "x" = "{.code mu1} uses block {.code {block1}}.",
      "x" = "{.code mu2} uses block {.code {block2}}.",
      "i" = "Use matching terms such as {.code phylo(1 | p | {term1$group}, tree = {term1$tree})} in both formulas, or leave both terms unlabelled."
    ))
  }

  term1 <- finalize_biv_structured_mu_term(term1, "phylo")
  list(mu1 = mu1_phylo, mu2 = mu2_phylo, term = term1)
}

guard_biv_spatial_mu_terms <- function(mu1_entry, mu2_entry) {
  mu1_spatial <- extract_gaussian_mu_spatial_term(mu1_entry)
  mu2_spatial <- extract_gaussian_mu_spatial_term(mu2_entry)
  has_spatial <- c(
    mu1 = !is.null(mu1_spatial$term),
    mu2 = !is.null(mu2_spatial$term)
  )
  if (!any(has_spatial)) {
    return(list(mu1 = mu1_spatial, mu2 = mu2_spatial, term = NULL))
  }
  if (!all(has_spatial)) {
    missing <- names(has_spatial)[!has_spatial]
    present <- names(has_spatial)[has_spatial]
    cli::cli_abort(c(
      "Bivariate spatial location terms must be matched in {.code mu1} and {.code mu2}.",
      "x" = "{.code {present}} contains {.fn spatial}, but {.code {missing}} does not.",
      "i" = "Use matching terms such as {.code mu1 = y1 ~ x + spatial(1 | site, coords = coords)} and {.code mu2 = y2 ~ x + spatial(1 | site, coords = coords)}."
    ))
  }

  term1 <- mu1_spatial$term
  term2 <- mu2_spatial$term
  validate_matching_structured_biv_location_coef(term1, term2, "spatial")
  if (
    !identical(term1$group, term2$group) ||
      !identical(term1$object, term2$object) ||
      !identical(term1$structure, term2$structure)
  ) {
    cli::cli_abort(c(
      "Matched bivariate spatial location terms must use the same grouping variable and coordinate object.",
      "x" = "{.code mu1} uses {.code spatial(1 | {term1$group}, coords = {term1$object})}.",
      "x" = "{.code mu2} uses {.code spatial(1 | {term2$group}, coords = {term2$object})}.",
      "i" = "The first fitted bivariate spatial path uses one shared coordinate-derived precision for {.code mu1} and {.code mu2}."
    ))
  }
  if (!identical(term1$covariance_label, term2$covariance_label)) {
    block1 <- phylo_term_block(term1)
    block2 <- phylo_term_block(term2)
    cli::cli_abort(c(
      "Matched bivariate spatial location terms must use the same covariance-block label.",
      "x" = "{.code mu1} uses block {.code {block1}}.",
      "x" = "{.code mu2} uses block {.code {block2}}.",
      "i" = "Use matching terms such as {.code spatial(1 | p | {term1$group}, coords = {term1$object})} in both formulas, or leave both terms unlabelled."
    ))
  }

  term1 <- finalize_biv_structured_mu_term(term1, "spatial")
  list(mu1 = mu1_spatial, mu2 = mu2_spatial, term = term1)
}

guard_biv_known_mu_terms <- function(mu1_entry, mu2_entry, marker) {
  mu1_known <- extract_gaussian_mu_known_term(mu1_entry, marker)
  mu2_known <- extract_gaussian_mu_known_term(mu2_entry, marker)
  example_matrix_arg <- if (identical(marker, "animal")) {
    "Ainv = Ainv"
  } else {
    "Q = Q"
  }
  has_known <- c(
    mu1 = !is.null(mu1_known$term),
    mu2 = !is.null(mu2_known$term)
  )
  if (!any(has_known)) {
    return(list(mu1 = mu1_known, mu2 = mu2_known, term = NULL))
  }
  if (!all(has_known)) {
    missing <- names(has_known)[!has_known]
    present <- names(has_known)[has_known]
    cli::cli_abort(c(
      "Bivariate {.fn {marker}} location terms must be matched in {.code mu1} and {.code mu2}.",
      "x" = "{.code {present}} contains {.fn {marker}}, but {.code {missing}} does not.",
      "i" = "Use matching terms such as {.code mu1 = y1 ~ x + {marker}(1 | p | id, {example_matrix_arg})} and {.code mu2 = y2 ~ x + {marker}(1 | p | id, {example_matrix_arg})}."
    ))
  }

  term1 <- mu1_known$term
  term2 <- mu2_known$term
  validate_matching_structured_biv_location_coef(term1, term2, marker)
  if (
    !identical(term1$group, term2$group) ||
      !identical(term1$object, term2$object) ||
      !identical(term1$structure, term2$structure)
  ) {
    cli::cli_abort(c(
      "Matched bivariate {.fn {marker}} location terms must use the same grouping variable and matrix object.",
      "x" = "{.code mu1} uses {.code {marker}(1 | {term1$group}, {term1$structure} = {term1$object})}.",
      "x" = "{.code mu2} uses {.code {marker}(1 | {term2$group}, {term2$structure} = {term2$object})}.",
      "i" = "The first fitted bivariate {.fn {marker}} path uses one shared known precision for {.code mu1} and {.code mu2}."
    ))
  }
  if (!identical(term1$covariance_label, term2$covariance_label)) {
    block1 <- phylo_term_block(term1)
    block2 <- phylo_term_block(term2)
    cli::cli_abort(c(
      "Matched bivariate {.fn {marker}} location terms must use the same covariance-block label.",
      "x" = "{.code mu1} uses block {.code {block1}}.",
      "x" = "{.code mu2} uses block {.code {block2}}.",
      "i" = "Use matching terms such as {.code {marker}(1 | p | {term1$group}, {term1$structure} = {term1$object})} in both formulas, or leave both terms unlabelled."
    ))
  }

  term1 <- finalize_biv_structured_mu_term(term1, marker)
  list(mu1 = mu1_known, mu2 = mu2_known, term = term1)
}

structured_mu_vars <- function(term) {
  if (is.null(term)) {
    return(character())
  }
  switch(
    term$type,
    spatial = spatial_mu_vars(term),
    animal = known_mu_vars(term),
    relmat = known_mu_vars(term),
    phylo_interaction = phylo_interaction_mu_vars(term),
    phylo_mu_vars(term)
  )
}

phylo_mu_vars <- function(term) {
  if (is.null(term)) {
    return(character())
  }
  term$group
}

spatial_mu_vars <- function(term) {
  if (is.null(term)) {
    return(character())
  }
  variables <- term$variables
  unique(c(term$group, variables[!is.na(variables)]))
}

known_mu_vars <- function(term) {
  if (is.null(term)) {
    return(character())
  }
  variables <- term$variables
  unique(c(term$group, variables[!is.na(variables)]))
}

phylo_interaction_mu_vars <- function(term) {
  if (is.null(term)) {
    return(character())
  }
  variables <- term$variables
  unique(c(term$group1, term$group2, variables[!is.na(variables)]))
}

empty_phylo_mu_structure <- function() {
  list(
    has = FALSE,
    type = "phylo",
    label = character(),
    group = NA_character_,
    block = "phylo",
    covariance_label = NULL,
    covariance_mode = "none",
    block_ids = integer(),
    block_labels = character(),
    endpoint_blocks = character(),
    endpoint_covariance_labels = character(),
    dpars = character(),
    q = 0L,
    coef_names = character(),
    tree = NA_character_,
    n_re = 0L,
    precision = NULL,
    value = matrix(0, nrow = 0L, ncol = 0L),
    observation_node_index = integer(),
    observation_node_index0 = 0L,
    node_labels = character(),
    species_levels = character(),
    group_levels = character()
  )
}

build_structured_mu_structure <- function(term, data, env) {
  if (is.null(term)) {
    return(empty_phylo_mu_structure())
  }
  switch(
    term$type,
    spatial = build_spatial_mu_structure(term, data, env),
    animal = build_known_precision_mu_structure(term, data, env),
    relmat = build_known_precision_mu_structure(term, data, env),
    phylo_interaction = build_phylo_interaction_mu_structure(term, data, env),
    phylo = build_phylo_mu_structure(term, data, env),
    cli::cli_abort(
      "Internal error: unknown structured-effect type {.val {term$type}}."
    )
  )
}

build_phylo_mu_structure <- function(term, data, env) {
  if (is.null(term)) {
    return(empty_phylo_mu_structure())
  }
  value <- structured_mu_design_matrix(term, data, marker = "phylo")
  dpars <- if (is.null(term$dpars)) {
    "mu"
  } else {
    term$dpars
  }
  q <- if (length(dpars) > 1L) {
    length(dpars)
  } else {
    ncol(value)
  }
  value <- expand_structured_endpoint_value(value, q, dpars, marker = "phylo")
  endpoint_covariance_labels <- if (!is.null(term$endpoint_covariance_labels)) {
    unname(as.character(term$endpoint_covariance_labels))
  } else if (is.null(term$covariance_label)) {
    rep(NA_character_, q)
  } else {
    rep(term$covariance_label, q)
  }
  block_ids <- if (!is.null(term$block_ids)) {
    as.integer(term$block_ids)
  } else {
    rep(1L, q)
  }
  block_ids <- match(block_ids, sort(unique(block_ids)))
  block_labels <- if (!is.null(term$block_labels)) {
    unname(as.character(term$block_labels))
  } else if (is.null(term$covariance_label)) {
    "phylo"
  } else {
    term$covariance_label
  }
  endpoint_blocks <- if (!is.null(term$endpoint_blocks)) {
    unname(as.character(term$endpoint_blocks))
  } else {
    block_labels[block_ids]
  }
  covariance_mode <- if (!is.null(term$covariance_mode)) {
    term$covariance_mode
  } else if (q > 2L) {
    "unstructured"
  } else {
    "scalar"
  }

  group <- term$group
  if (!group %in% names(data)) {
    cli::cli_abort(c(
      "Phylogenetic grouping variable {.field {group}} was not found in {.arg data}.",
      "x" = "Use syntax like {.code phylo(1 | species, tree = tree)} where {.field species} is a column in {.arg data}."
    ))
  }
  species <- as.character(data[[group]])
  if (length(unique(species)) < 2L) {
    cli::cli_abort(c(
      "Phylogenetic grouping variable {.field {group}} has fewer than two observed species.",
      "x" = "At least two species are needed to estimate a phylogenetic SD."
    ))
  }

  tree <- evaluate_phylo_tree(term$tree, env)
  precision <- drm_phylo_augmented_precision(tree, species = species)
  observation_node_index <- precision$species_node_index[
    precision$observation_species_index
  ]
  if (anyNA(observation_node_index)) {
    cli::cli_abort(
      "Internal error: failed to align observations with phylogenetic tip nodes."
    )
  }

  list(
    has = TRUE,
    type = "phylo",
    label = term$label,
    group = group,
    block = paste(unique(endpoint_blocks), collapse = "/"),
    covariance_label = term$covariance_label,
    covariance_mode = covariance_mode,
    block_ids = block_ids,
    block_labels = block_labels,
    endpoint_blocks = endpoint_blocks,
    endpoint_covariance_labels = endpoint_covariance_labels,
    dpars = dpars,
    q = q,
    coef_names = colnames(value),
    tree = term$tree,
    n_re = nrow(precision$precision),
    precision = precision,
    value = value,
    observation_node_index = unname(as.integer(observation_node_index)),
    observation_node_index0 = unname(as.integer(observation_node_index - 1L)),
    node_labels = precision$node_labels,
    species_levels = precision$species_levels,
    group_levels = precision$species_levels
  )
}

build_phylo_interaction_mu_structure <- function(term, data, env) {
  if (is.null(term)) {
    return(empty_phylo_mu_structure())
  }
  marker <- "phylo_interaction"
  group1 <- term$group1
  group2 <- term$group2
  missing_groups <- setdiff(c(group1, group2), names(data))
  if (length(missing_groups) > 0L) {
    cli::cli_abort(c(
      "{.fn phylo_interaction} grouping variable{?s} {.field {missing_groups}} {?was/were} not found in {.arg data}.",
      "x" = "Use syntax like {.code phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree)} where both pair variables are columns in {.arg data}."
    ))
  }

  partner1 <- as.character(data[[group1]])
  partner2 <- as.character(data[[group2]])
  if (length(unique(partner1)) < 2L || length(unique(partner2)) < 2L) {
    cli::cli_abort(c(
      "{.fn phylo_interaction} needs at least two observed levels in each partner clade.",
      "x" = "{.field {group1}} has {length(unique(partner1))} observed level{?s}; {.field {group2}} has {length(unique(partner2))} observed level{?s}."
    ))
  }

  tree1 <- evaluate_phylo_tree(term$tree1, env)
  tree2 <- evaluate_phylo_tree(term$tree2, env)
  precision1 <- drm_phylo_augmented_precision(tree1, species = partner1)
  precision2 <- drm_phylo_augmented_precision(tree2, species = partner2)
  node_index1 <- precision1$species_node_index[
    precision1$observation_species_index
  ]
  node_index2 <- precision2$species_node_index[
    precision2$observation_species_index
  ]
  if (anyNA(node_index1) || anyNA(node_index2)) {
    cli::cli_abort(
      "Internal error: failed to align observations with {.fn phylo_interaction} tip nodes."
    )
  }

  n1 <- nrow(precision1$precision)
  n2 <- nrow(precision2$precision)
  precision <- Matrix::kronecker(
    precision2$precision,
    precision1$precision,
    make.dimnames = FALSE
  )
  precision <- Matrix::drop0(Matrix::Matrix(precision, sparse = TRUE))
  observation_node_index <- (node_index2 - 1L) * n1 + node_index1
  node_grid <- expand.grid(
    partner1 = precision1$node_labels,
    partner2 = precision2$node_labels,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  node_labels <- paste0(node_grid$partner1, ":", node_grid$partner2)

  value <- structured_mu_design_matrix(term, data, marker = marker)
  dpars <- if (is.null(term$dpars)) {
    "mu"
  } else {
    term$dpars
  }
  q <- if (length(dpars) > 1L) {
    length(dpars)
  } else {
    ncol(value)
  }
  value <- expand_structured_endpoint_value(value, q, dpars, marker = marker)

  list(
    has = TRUE,
    type = marker,
    label = term$label,
    group = term$group,
    group1 = group1,
    group2 = group2,
    block = "phylo_interaction",
    covariance_label = term$covariance_label,
    covariance_mode = "scalar",
    block_ids = rep(1L, q),
    block_labels = "phylo_interaction",
    endpoint_blocks = rep("phylo_interaction", q),
    endpoint_covariance_labels = rep(NA_character_, q),
    dpars = dpars,
    q = q,
    coef_names = colnames(value),
    tree = NA_character_,
    tree1 = term$tree1,
    tree2 = term$tree2,
    n_re = nrow(precision),
    precision = list(
      precision = precision,
      log_det_precision = n2 *
        precision1$log_det_precision +
        n1 * precision2$log_det_precision
    ),
    value = value,
    observation_node_index = unname(as.integer(observation_node_index)),
    observation_node_index0 = unname(as.integer(observation_node_index - 1L)),
    node_labels = node_labels,
    species_levels = character(),
    group_levels = node_labels,
    partner1_levels = precision1$species_levels,
    partner2_levels = precision2$species_levels,
    partner1_node_labels = precision1$node_labels,
    partner2_node_labels = precision2$node_labels
  )
}

build_spatial_mu_structure <- function(term, data, env) {
  if (is.null(term)) {
    return(empty_phylo_mu_structure())
  }
  if (!identical(term$structure, "coords")) {
    cli::cli_abort(c(
      "Precomputed spatial mesh fitting is planned but not implemented yet.",
      "x" = "Requested {.code spatial(1 | {term$group}, mesh = {term$object})}.",
      "i" = "Use {.code spatial(1 | {term$group}, coords = coords)} for the first fitted coordinate-based spatial path."
    ))
  }

  group <- term$group
  if (!group %in% names(data)) {
    cli::cli_abort(c(
      "Spatial grouping variable {.field {group}} was not found in {.arg data}.",
      "x" = "Use syntax like {.code spatial(1 | site, coords = coords)} where {.field site} is a column in {.arg data}."
    ))
  }
  site <- as.character(data[[group]])
  if (length(unique(site)) < 2L) {
    cli::cli_abort(c(
      "Spatial grouping variable {.field {group}} has fewer than two observed sites.",
      "x" = "At least two sites are needed to estimate a spatial SD."
    ))
  }

  coords <- evaluate_spatial_coords(term$object, env)
  precision <- drm_spatial_coords_precision(coords, site = site, group = group)
  observation_node_index <- match(site, precision$site_levels)
  if (anyNA(observation_node_index)) {
    cli::cli_abort(
      "Internal error: failed to align observations with spatial coordinate nodes."
    )
  }
  value <- structured_mu_design_matrix(term, data, marker = "spatial")
  dpars <- if (is.null(term$dpars)) {
    "mu"
  } else {
    term$dpars
  }
  q <- if (length(dpars) > 1L) {
    length(dpars)
  } else {
    ncol(value)
  }
  value <- expand_structured_endpoint_value(value, q, dpars, marker = "spatial")
  endpoint_covariance_labels <- if (!is.null(term$endpoint_covariance_labels)) {
    unname(as.character(term$endpoint_covariance_labels))
  } else if (is.null(term$covariance_label)) {
    rep(NA_character_, q)
  } else {
    rep(term$covariance_label, q)
  }
  block_ids <- if (!is.null(term$block_ids)) {
    as.integer(term$block_ids)
  } else {
    rep(1L, q)
  }
  block_ids <- match(block_ids, sort(unique(block_ids)))
  block_labels <- if (!is.null(term$block_labels)) {
    unname(as.character(term$block_labels))
  } else if (is.null(term$covariance_label)) {
    "spatial"
  } else {
    term$covariance_label
  }
  endpoint_blocks <- if (!is.null(term$endpoint_blocks)) {
    unname(as.character(term$endpoint_blocks))
  } else {
    block_labels[block_ids]
  }
  covariance_mode <- if (!is.null(term$covariance_mode)) {
    term$covariance_mode
  } else {
    "scalar"
  }

  list(
    has = TRUE,
    type = "spatial",
    label = term$label,
    group = group,
    block = paste(unique(endpoint_blocks), collapse = "/"),
    covariance_label = term$covariance_label,
    covariance_mode = covariance_mode,
    block_ids = block_ids,
    block_labels = block_labels,
    endpoint_blocks = endpoint_blocks,
    endpoint_covariance_labels = endpoint_covariance_labels,
    dpars = dpars,
    q = q,
    coef_names = colnames(value),
    tree = NA_character_,
    structure = term$structure,
    object = term$object,
    n_re = nrow(precision$precision),
    precision = precision,
    value = value,
    observation_node_index = unname(as.integer(observation_node_index)),
    observation_node_index0 = unname(as.integer(observation_node_index - 1L)),
    node_labels = precision$site_levels,
    species_levels = character(),
    group_levels = precision$site_levels
  )
}

build_known_precision_mu_structure <- function(term, data, env) {
  if (is.null(term)) {
    return(empty_phylo_mu_structure())
  }
  marker <- term$type
  group <- term$group
  if (!group %in% names(data)) {
    cli::cli_abort(c(
      "{.fn {marker}} grouping variable {.field {group}} was not found in {.arg data}.",
      "x" = "Use syntax like {.code {marker}(1 | id, Q = Q)} where {.field id} is a column in {.arg data}."
    ))
  }
  group_values <- as.character(data[[group]])
  if (length(unique(group_values)) < 2L) {
    cli::cli_abort(c(
      "{.fn {marker}} grouping variable {.field {group}} has fewer than two observed levels.",
      "x" = "At least two levels are needed to estimate a structured SD."
    ))
  }

  if (identical(marker, "animal") && identical(term$structure, "pedigree")) {
    pedigree <- evaluate_animal_pedigree(term$object, env)
    precision <- drm_pedigree_relatedness_precision(
      pedigree,
      group = group_values,
      object = term$object,
      group_name = group
    )
  } else {
    object <- evaluate_known_relatedness_matrix(term$object, env, marker)
    matrix_type <- if (term$structure %in% c("Ainv", "Q")) {
      "precision"
    } else {
      "covariance"
    }
    precision <- drm_known_relatedness_precision(
      object,
      group = group_values,
      matrix_type = matrix_type,
      marker = marker,
      object = term$object,
      group_name = group
    )
  }
  observation_node_index <- precision$species_node_index[
    precision$observation_species_index
  ]
  if (anyNA(observation_node_index)) {
    cli::cli_abort(
      "Internal error: failed to align observations with {.fn {marker}} relatedness nodes."
    )
  }
  value <- structured_mu_design_matrix(term, data, marker = marker)
  dpars <- if (is.null(term$dpars)) {
    "mu"
  } else {
    term$dpars
  }
  q <- if (length(dpars) > 1L) {
    length(dpars)
  } else {
    ncol(value)
  }
  value <- expand_structured_endpoint_value(value, q, dpars, marker = marker)
  endpoint_covariance_labels <- if (!is.null(term$endpoint_covariance_labels)) {
    unname(as.character(term$endpoint_covariance_labels))
  } else if (is.null(term$covariance_label)) {
    rep(NA_character_, q)
  } else {
    rep(term$covariance_label, q)
  }
  block_ids <- if (!is.null(term$block_ids)) {
    as.integer(term$block_ids)
  } else {
    rep(1L, q)
  }
  block_ids <- match(block_ids, sort(unique(block_ids)))
  block_labels <- if (!is.null(term$block_labels)) {
    unname(as.character(term$block_labels))
  } else if (is.null(term$covariance_label)) {
    marker
  } else {
    term$covariance_label
  }
  endpoint_blocks <- if (!is.null(term$endpoint_blocks)) {
    unname(as.character(term$endpoint_blocks))
  } else {
    block_labels[block_ids]
  }
  covariance_mode <- if (!is.null(term$covariance_mode)) {
    term$covariance_mode
  } else {
    "scalar"
  }

  list(
    has = TRUE,
    type = marker,
    label = term$label,
    group = group,
    block = paste(unique(endpoint_blocks), collapse = "/"),
    covariance_label = term$covariance_label,
    covariance_mode = covariance_mode,
    block_ids = block_ids,
    block_labels = block_labels,
    endpoint_blocks = endpoint_blocks,
    endpoint_covariance_labels = endpoint_covariance_labels,
    dpars = dpars,
    q = q,
    coef_names = colnames(value),
    tree = NA_character_,
    structure = term$structure,
    object = term$object,
    n_re = nrow(precision$precision),
    precision = precision,
    value = value,
    observation_node_index = unname(as.integer(observation_node_index)),
    observation_node_index0 = unname(as.integer(observation_node_index - 1L)),
    node_labels = precision$node_labels,
    species_levels = precision$species_levels,
    group_levels = precision$node_labels
  )
}

expand_structured_endpoint_value <- function(value, q, dpars, marker) {
  if (ncol(value) == q) {
    return(value)
  }
  if (ncol(value) == 1L && length(dpars) == q) {
    out <- matrix(
      value[, 1L],
      nrow = nrow(value),
      ncol = q,
      dimnames = list(row.names(value), rep(colnames(value)[[1L]], q))
    )
    return(out)
  }
  cli::cli_abort(c(
    "Internal error: {.fn {marker}} structured design has incompatible endpoint dimensions.",
    "x" = "Design columns: {ncol(value)}; endpoints: {q}."
  ))
}

structured_mu_design_matrix <- function(term, data, marker) {
  coef_names <- term$coef_names
  if (!is.character(coef_names) || length(coef_names) == 0L) {
    coef_names <- "(Intercept)"
  }
  value <- matrix(1, nrow = nrow(data), ncol = length(coef_names))
  colnames(value) <- coef_names
  variables <- term$variables
  variables <- variables[!is.na(variables)]
  for (variable in variables) {
    if (!variable %in% names(data)) {
      cli::cli_abort(c(
        "{.fn {marker}} slope variable {.field {variable}} was not found in {.arg data}.",
        "x" = "Use syntax like {.code {marker}(1 + {variable} | {term$group}, coords = coords)} where {.field {variable}} is a numeric column in {.arg data}."
      ))
    }
    if (!is.numeric(data[[variable]])) {
      cli::cli_abort(c(
        "{.fn {marker}} slope variable {.field {variable}} must be numeric.",
        "x" = "Structured spatial slopes currently use a numeric design value for each observation."
      ))
    }
    if (any(!is.finite(data[[variable]]))) {
      cli::cli_abort(c(
        "{.fn {marker}} slope variable {.field {variable}} must contain finite values.",
        "x" = "Remove or recode missing, infinite, or non-finite slope values before fitting the structured slope."
      ))
    }
    columns <- which(colnames(value) == variable)
    if (length(columns) == 0L) {
      cli::cli_abort(
        "Internal error: structured slope variable {.field {variable}} was not in the coefficient design."
      )
    }
    value[, columns] <- data[[variable]]
  }
  value
}

evaluate_spatial_coords <- function(name, env) {
  if (!exists(name, envir = env, inherits = TRUE)) {
    cli::cli_abort(c(
      "Could not find spatial coordinate object {.field {name}}.",
      "x" = "{.fn spatial} terms use coordinate objects from the calling environment, for example {.code spatial(1 | site, coords = coords)}."
    ))
  }
  get(name, envir = env, inherits = TRUE)
}

evaluate_known_relatedness_matrix <- function(name, env, marker) {
  if (!exists(name, envir = env, inherits = TRUE)) {
    cli::cli_abort(c(
      "Could not find {.fn {marker}} matrix object {.field {name}}.",
      "x" = "{.fn {marker}} terms use matrix objects from the calling environment, for example {.code {marker}(1 | id, Q = Q)}."
    ))
  }
  get(name, envir = env, inherits = TRUE)
}

evaluate_animal_pedigree <- function(name, env) {
  if (!exists(name, envir = env, inherits = TRUE)) {
    cli::cli_abort(c(
      "Could not find {.fn animal} pedigree object {.field {name}}.",
      "x" = "{.fn animal} pedigree terms use objects from the calling environment, for example {.code animal(1 | id, pedigree = pedigree)}."
    ))
  }
  get(name, envir = env, inherits = TRUE)
}

drm_spatial_coords_precision <- function(
  coords,
  site,
  group = "site",
  jitter = 1e-6
) {
  coords <- standardize_spatial_coords(coords, site = site, group = group)
  distances <- stats::dist(coords)
  positive_distances <- as.numeric(distances)[as.numeric(distances) > 0]
  if (length(positive_distances) == 0L) {
    cli::cli_abort(c(
      "Spatial coordinates for {.field {group}} contain no positive distances.",
      "x" = "At least two sites must have distinct coordinates."
    ))
  }
  range <- stats::median(positive_distances)
  if (!is.finite(range) || range <= 0) {
    range <- max(positive_distances)
  }
  cov <- exp(-as.matrix(distances) / range)
  diag(cov) <- diag(cov) + jitter
  chol_cov <- tryCatch(
    chol(cov),
    error = function(e) NULL
  )
  if (is.null(chol_cov)) {
    diag(cov) <- diag(cov) + sqrt(jitter)
    chol_cov <- tryCatch(
      chol(cov),
      error = function(e) NULL
    )
  }
  if (is.null(chol_cov)) {
    cli::cli_abort(c(
      "Spatial coordinate covariance was not positive definite.",
      "x" = "Check for duplicated or nearly duplicated coordinates."
    ))
  }
  precision <- chol2inv(chol_cov)
  dimnames(precision) <- dimnames(cov)
  list(
    precision = Matrix::Matrix(precision, sparse = TRUE),
    log_det_precision = -2 * sum(log(diag(chol_cov))),
    site_levels = rownames(coords),
    coords = coords,
    range = range
  )
}

standardize_spatial_coords <- function(coords, site, group = "site") {
  if (is.data.frame(coords)) {
    coords <- as.matrix(coords)
  }
  if (!is.matrix(coords) || ncol(coords) < 2L) {
    cli::cli_abort(c(
      "{.arg coords} must be a matrix or data frame with at least two columns.",
      "x" = "Use one row per {.field {group}} level, or one row per observation with constant coordinates within each level."
    ))
  }
  coords <- coords[, seq_len(2L), drop = FALSE]
  coord_df <- as.data.frame(coords)
  if (!all(vapply(coord_df, is.numeric, logical(1)))) {
    cli::cli_abort("{.arg coords} must contain numeric coordinate columns.")
  }
  coords <- as.matrix(coord_df)
  if (anyNA(coords) || any(!is.finite(coords))) {
    cli::cli_abort("{.arg coords} must contain finite numeric values.")
  }

  site_levels <- unique(as.character(site))
  if (nrow(coords) == length(site_levels)) {
    if (!is.null(rownames(coords)) && all(site_levels %in% rownames(coords))) {
      coords <- coords[site_levels, , drop = FALSE]
    } else {
      rownames(coords) <- site_levels
    }
    return(coords)
  }

  if (nrow(coords) != length(site)) {
    cli::cli_abort(c(
      "{.arg coords} must have one row per {.field {group}} level or one row per observation.",
      "x" = "{.field {group}} has {length(site_levels)} observed levels and {length(site)} observations, but {.arg coords} has {nrow(coords)} rows."
    ))
  }

  out <- matrix(NA_real_, nrow = length(site_levels), ncol = ncol(coords))
  dimnames(out) <- list(site_levels, colnames(coords))
  for (level in site_levels) {
    rows <- which(site == level)
    level_coords <- unique(coords[rows, , drop = FALSE])
    if (nrow(level_coords) != 1L) {
      cli::cli_abort(c(
        "{.arg coords} vary within spatial group {.val {level}}.",
        "x" = "The first fitted {.fn spatial} path requires one coordinate pair per {.field {group}} level."
      ))
    }
    out[level, ] <- level_coords[1L, ]
  }
  out
}

evaluate_phylo_tree <- function(name, env) {
  if (!exists(name, envir = env, inherits = TRUE)) {
    cli::cli_abort(c(
      "Could not find phylogeny object {.field {name}}.",
      "x" = "{.fn phylo} terms use objects from the calling environment, for example {.code phylo(1 | species, tree = tree)}."
    ))
  }
  get(name, envir = env, inherits = TRUE)
}

parse_sd_mu_entry <- function(entry, mu_terms) {
  if (is.null(entry)) {
    return(NULL)
  }
  target <- parse_sd_lhs(entry$lhs)
  if (isTRUE(target$explicit)) {
    cli::cli_abort(c(
      "Explicit random-effect scale targets are reserved but not implemented yet.",
      "x" = "{.code {entry$dpar}} names a target distributional parameter, coefficient, or block.",
      "i" = "This implementation supports implicit {.code sd(group)} targets only when there is exactly one unlabelled Gaussian {.code mu} random intercept for the group."
    ))
  }
  target_group <- target$group
  matches <- which(vapply(
    mu_terms,
    function(term) identical(term$group, target_group),
    logical(1)
  ))

  if (length(matches) == 0L) {
    cli::cli_abort(c(
      "No random-effect term matches {.code {entry$dpar}}.",
      "x" = "Add {.code (1 | {target_group})} to the {.code mu} formula or remove the {.code {entry$dpar}} formula."
    ))
  }
  if (length(matches) > 1L) {
    coef_names <- unique(unlist(
      lapply(mu_terms[matches], `[[`, "coef_names"),
      use.names = FALSE
    ))
    cli::cli_abort(c(
      "Ambiguous random-effect scale target {.code {entry$dpar}}.",
      "x" = "Group {.field {target_group}} has multiple {.code mu} random-effect coefficients: {.val {coef_names}}.",
      "i" = "Explicit coefficient-specific {.fn sd} targets are planned for a later phase."
    ))
  }

  target_coef <- sum(vapply(
    mu_terms[seq_len(matches - 1L)],
    function(term) {
      length(term$coef_names)
    },
    integer(1)
  )) +
    1L
  term <- mu_terms[[matches]]
  if (
    !identical(term$type, "intercept") ||
      !identical(term$coef_names, "(Intercept)")
  ) {
    cli::cli_abort(c(
      "Ambiguous random-effect scale target {.code {entry$dpar}}.",
      "x" = "This phase supports only univariate Gaussian {.code mu} random intercepts such as {.code (1 | {target_group})}.",
      "i" = "Random-slope and correlated-block scale models are planned for a later phase."
    ))
  }
  if (!is.null(term$covariance_label)) {
    cli::cli_abort(c(
      "Labelled random-effect scale targets are not implemented yet.",
      "x" = "{.code {entry$dpar}} can target {.code (1 | {target_group})}, but not {.code (1 | {term$covariance_label} | {target_group})}."
    ))
  }

  list(
    dpar = entry$dpar,
    group = target_group,
    target_term = matches,
    target_coef = target_coef,
    label = term$label
  )
}

parse_sd_mu_entries <- function(entries, mu_terms) {
  if (length(entries) == 0L) {
    return(list())
  }
  targets <- lapply(entries, parse_sd_mu_entry, mu_terms = mu_terms)
  dpars <- vapply(targets, `[[`, character(1), "dpar")
  if (anyDuplicated(dpars)) {
    duplicate <- dpars[duplicated(dpars)][[1L]]
    cli::cli_abort(c(
      "Duplicate random-effect scale formula {.code {duplicate}}.",
      "x" = "Each unlabelled {.fn sd} target can have only one scale formula."
    ))
  }
  target_coef <- vapply(targets, `[[`, integer(1), "target_coef")
  if (anyDuplicated(target_coef)) {
    duplicate <- dpars[duplicated(target_coef)][[1L]]
    cli::cli_abort(c(
      "Duplicate random-effect scale target {.code {duplicate}}.",
      "x" = "Each {.code mu} random-effect coefficient can have only one scale formula."
    ))
  }
  targets
}

parse_sd_phylo_entry <- function(entry, phylo_term) {
  target <- parse_sd_lhs(entry$lhs)
  if (!identical(target$fun, "sd_phylo")) {
    cli::cli_abort(
      "Internal error: phylogenetic random-effect scale target {.code {entry$dpar}} is not an {.fn sd_phylo} target."
    )
  }
  if (isTRUE(target$explicit)) {
    cli::cli_abort(c(
      "Explicit phylogenetic random-effect SD targets are not implemented yet.",
      "x" = "{.code {entry$dpar}} names a target distributional parameter, coefficient, or block.",
      "i" = "Use {.code sd_phylo(species) ~ x_species} for the univariate phylogenetic location random-effect SD."
    ))
  }
  if (is.null(phylo_term)) {
    cli::cli_abort(c(
      "No phylogenetic location random-effect term matches {.code {entry$dpar}}.",
      "x" = "Add {.code phylo(1 | {target$group}, tree = tree)} to the {.code mu} formula or remove {.code {entry$dpar}}.",
      "i" = "{.fn sd_phylo} targets the SD of a univariate phylogenetic location random effect."
    ))
  }
  if (!all(phylo_mu_endpoint_dpars(phylo_term) == "mu")) {
    cli::cli_abort(c(
      "{.fn sd_phylo} direct-SD formulas are not implemented with phylogenetic residual-scale effects.",
      "x" = "{.code {entry$dpar}} was combined with a {.code sigma ~ phylo(...)} endpoint.",
      "i" = "Fit the constant phylogenetic location-scale block first, or remove the {.fn sd_phylo} formula."
    ))
  }
  if (!identical(phylo_term$coef_names, "(Intercept)")) {
    cli::cli_abort(c(
      "Phylogenetic random-effect scale formulas with structured slopes are not implemented yet.",
      "x" = "{.code {entry$dpar}} targets {.code {phylo_term$label}}, which has multiple structured coefficients.",
      "i" = "Use {.code sd_phylo({target$group}) ~ ...} with {.code phylo(1 | {target$group}, tree = tree)}, or fit {.code phylo(1 + x | {target$group}, tree = tree)} without a direct-SD formula."
    ))
  }
  if (!identical(target$group, phylo_term$group)) {
    cli::cli_abort(c(
      "Phylogenetic random-effect scale target {.code {entry$dpar}} does not match the {.fn phylo} grouping variable.",
      "x" = "{.fn sd_phylo} targets group {.field {target$group}}, but {.fn phylo} uses group {.field {phylo_term$group}}.",
      "i" = "Use the same species column in {.code phylo(1 | species, tree = tree)} and {.code sd_phylo(species) ~ x_species}."
    ))
  }

  list(
    dpar = entry$dpar,
    group = target$group,
    target_term = 1L,
    target_coef = 1L,
    label = phylo_term$label
  )
}

parse_sd_phylo_entries <- function(entries, phylo_term) {
  if (length(entries) == 0L) {
    return(list())
  }
  targets <- lapply(entries, parse_sd_phylo_entry, phylo_term = phylo_term)
  dpars <- vapply(targets, `[[`, character(1), "dpar")
  if (anyDuplicated(dpars)) {
    duplicate <- dpars[duplicated(dpars)][[1L]]
    cli::cli_abort(c(
      "Duplicate phylogenetic random-effect scale formula {.code {duplicate}}.",
      "x" = "Each {.fn sd_phylo} target can have only one scale formula."
    ))
  }
  if (length(targets) > 1L) {
    cli::cli_abort(
      "Only one univariate {.fn sd_phylo} scale formula is implemented."
    )
  }
  targets
}

parse_biv_sd_phylo_entry <- function(entry, phylo_mu) {
  target <- parse_sd_lhs(entry$lhs)
  if (!target$fun %in% c("sd_phylo1", "sd_phylo2")) {
    cli::cli_abort(
      "Internal error: bivariate phylogenetic random-effect scale target {.code {entry$dpar}} is not an {.fn sd_phylo1} or {.fn sd_phylo2} target."
    )
  }
  if (isTRUE(target$explicit)) {
    cli::cli_abort(c(
      "Explicit bivariate phylogenetic random-effect SD targets are not implemented yet.",
      "x" = "{.code {entry$dpar}} names a target distributional parameter, coefficient, or block.",
      "i" = "Use {.code sd_phylo1(species) ~ x_species} for {.code mu1} or {.code sd_phylo2(species) ~ x_species} for {.code mu2}."
    ))
  }
  target_dpar <- if (identical(target$fun, "sd_phylo1")) "mu1" else "mu2"
  if (!isTRUE(phylo_mu$has) || !identical(as.integer(phylo_mu$q), 2L)) {
    cli::cli_abort(c(
      "No bivariate phylogenetic location random-effect term matches {.code {entry$dpar}}.",
      "x" = "Add matching {.code phylo(1 | {target$group}, tree = tree)} terms to {.code mu1} and {.code mu2}, or remove {.code {entry$dpar}}.",
      "i" = "{.fn sd_phylo1} targets {.code mu1} phylogenetic location SDs; {.fn sd_phylo2} targets {.code mu2} phylogenetic location SDs."
    ))
  }
  if (!identical(target$group, phylo_mu$group)) {
    cli::cli_abort(c(
      "Bivariate phylogenetic random-effect scale target {.code {entry$dpar}} does not match the {.fn phylo} grouping variable.",
      "x" = "{.fn {target$fun}} targets group {.field {target$group}}, but {.fn phylo} uses group {.field {phylo_mu$group}}.",
      "i" = "Use the same species column in matching {.fn phylo} terms and {.code {target$fun}(species) ~ x_species}."
    ))
  }

  list(
    dpar = entry$dpar,
    group = target$group,
    target_dpar = target_dpar,
    target_endpoint = match(target_dpar, phylo_mu_dpars(phylo_mu)),
    target_term = match(target_dpar, phylo_mu_dpars(phylo_mu)),
    target_coef = match(target_dpar, phylo_mu_dpars(phylo_mu)),
    label = phylo_mu$label
  )
}

parse_biv_sd_phylo_entries <- function(entries, phylo_mu) {
  if (length(entries) == 0L) {
    return(list())
  }
  targets <- lapply(entries, parse_biv_sd_phylo_entry, phylo_mu = phylo_mu)
  dpars <- vapply(targets, `[[`, character(1), "dpar")
  if (anyDuplicated(dpars)) {
    duplicate <- dpars[duplicated(dpars)][[1L]]
    cli::cli_abort(c(
      "Duplicate bivariate phylogenetic random-effect scale formula {.code {duplicate}}.",
      "x" = "Each {.fn sd_phylo1} or {.fn sd_phylo2} target can have only one scale formula."
    ))
  }
  target_endpoint <- vapply(targets, `[[`, integer(1), "target_endpoint")
  if (anyDuplicated(target_endpoint)) {
    duplicate <- dpars[duplicated(target_endpoint)][[1L]]
    cli::cli_abort(c(
      "Duplicate bivariate phylogenetic random-effect scale target {.code {duplicate}}.",
      "x" = "Each bivariate phylogenetic location endpoint can have only one direct-SD formula."
    ))
  }
  targets
}

parse_biv_sd_mu_entry <- function(entry, re_mu) {
  target <- parse_sd_lhs(entry$lhs)
  if (!target$fun %in% c("sd1", "sd2")) {
    cli::cli_abort(
      "Internal error: bivariate random-effect scale target {.code {entry$dpar}} is not an {.fn sd1} or {.fn sd2} target."
    )
  }

  target_dpar <- if (identical(target$fun, "sd1")) "mu1" else "mu2"
  target_group <- target$group
  matches <- which(
    re_mu$dpars == target_dpar &
      re_mu$group_names == target_group
  )

  if (length(matches) == 0L) {
    cli::cli_abort(c(
      "No bivariate location random-effect term matches {.code {entry$dpar}}.",
      "x" = "Add a labelled random intercept such as {.code (1 | p | {target_group})} to the {.code {target_dpar}} formula or remove the {.code {entry$dpar}} formula.",
      "i" = "{.fn sd1} targets {.code mu1} location random-effect SDs; {.fn sd2} targets {.code mu2} location random-effect SDs."
    ))
  }
  if (length(matches) > 1L) {
    cli::cli_abort(c(
      "Ambiguous bivariate random-effect scale target {.code {entry$dpar}}.",
      "x" = "Group {.field {target_group}} has multiple {.code {target_dpar}} random-effect coefficients.",
      "i" = "Random-slope and coefficient-specific bivariate {.fn sd1} / {.fn sd2} targets are planned for a later phase."
    ))
  }
  if (!identical(re_mu$coef_names[[matches]], "(Intercept)")) {
    cli::cli_abort(c(
      "Ambiguous bivariate random-effect scale target {.code {entry$dpar}}.",
      "x" = "This phase supports only bivariate Gaussian location random intercepts.",
      "i" = "Random-slope bivariate random-effect SD models are planned for a later phase."
    ))
  }

  list(
    dpar = entry$dpar,
    group = target_group,
    target_term = matches,
    target_coef = matches,
    label = re_mu$labels[[matches]]
  )
}

parse_biv_sd_mu_entries <- function(entries, re_mu) {
  if (length(entries) == 0L) {
    return(list())
  }
  targets <- lapply(entries, parse_biv_sd_mu_entry, re_mu = re_mu)
  dpars <- vapply(targets, `[[`, character(1), "dpar")
  if (anyDuplicated(dpars)) {
    duplicate <- dpars[duplicated(dpars)][[1L]]
    cli::cli_abort(c(
      "Duplicate bivariate random-effect scale formula {.code {duplicate}}.",
      "x" = "Each {.fn sd1} or {.fn sd2} target can have only one scale formula."
    ))
  }
  target_coef <- vapply(targets, `[[`, integer(1), "target_coef")
  if (anyDuplicated(target_coef)) {
    duplicate <- dpars[duplicated(target_coef)][[1L]]
    cli::cli_abort(c(
      "Duplicate bivariate random-effect scale target {.code {duplicate}}.",
      "x" = "Each bivariate location random-effect coefficient can have only one scale formula."
    ))
  }
  targets
}

empty_random_mu_structure <- function(n) {
  list(
    n_terms = 0L,
    n_re = 0L,
    index = matrix(1L, nrow = n, ncol = 1L),
    index0 = matrix(0L, nrow = n, ncol = 1L),
    value = matrix(1, nrow = n, ncol = 1L),
    term_id0 = 0L,
    dpar_id0 = 0L,
    re_pos0 = 0L,
    re_cor_id0 = -1L,
    re_pair_index0 = -1L,
    n_cors = 0L,
    cor_labels = character(),
    labels = character(),
    dpars = character(),
    coef_names = character(),
    group_names = character(),
    covariance_labels = character(),
    groups = list(),
    value_names = character(),
    cor_model = empty_corpair_model()
  )
}

empty_random_sigma_structure <- function(n) {
  empty_random_mu_structure(n)
}

empty_corpair_model <- function() {
  list(
    n_models = 0L,
    dpars = character(),
    dpar = NA_character_,
    target_cor = integer(),
    X = matrix(0, nrow = 1L, ncol = 1L),
    X_tmb = matrix(0, nrow = 1L, ncol = 1L),
    X_list = list(),
    terms_list = list(),
    model_frame_list = list(),
    group = NA_character_,
    block = NA_character_,
    level = NA_character_,
    from = NA_character_,
    to = NA_character_
  )
}

empty_sd_mu_structure <- function(n_re = 1L) {
  list(
    n_models = 0L,
    dpars = character(),
    dpar = NA_character_,
    group = NA_character_,
    target_term = NA_integer_,
    target_coef = NA_integer_,
    target_label = NA_character_,
    X = matrix(0, nrow = 1L, ncol = 1L),
    X_list = list(),
    coef_index = list(),
    row_index = list(),
    terms = NULL,
    terms_list = list(),
    model_frame = NULL,
    model_frame_list = list(),
    coef_names = character(),
    coef_names_list = list(),
    group_levels = character(),
    group_levels_list = list(),
    re_sd_row0 = rep.int(-1L, n_re)
  )
}

empty_sd_phylo_structure <- function(n_re = 1L) {
  list(
    n_models = 0L,
    dpars = character(),
    dpar = NA_character_,
    group = NA_character_,
    target_dpar = NA_character_,
    target_endpoint = NA_integer_,
    target_label = NA_character_,
    X = matrix(0, nrow = 1L, ncol = 1L),
    X_list = list(),
    coef_index = list(),
    row_index = list(),
    terms = NULL,
    terms_list = list(),
    model_frame = NULL,
    model_frame_list = list(),
    coef_names = character(),
    coef_names_list = list(),
    group_levels = character(),
    group_levels_list = list(),
    observation_sd_row0 = 0L,
    observation_sd_row0_list = list(),
    node_sd_row0 = rep.int(-1L, n_re)
  )
}

build_random_mu_structure <- function(terms, data) {
  if (length(terms) == 0L) {
    return(empty_random_mu_structure(nrow(data)))
  }

  validate_random_mu_term_overlap(terms)

  coef_info <- expand_random_mu_terms(terms)
  labels <- coef_info$labels
  if (anyDuplicated(vapply(terms, `[[`, character(1), "label"))) {
    cli::cli_abort("Duplicate random-effect terms are not supported.")
  }

  index <- matrix(NA_integer_, nrow = nrow(data), ncol = length(labels))
  value <- matrix(1, nrow = nrow(data), ncol = length(labels))
  term_id0 <- integer()
  dpar_id0 <- integer()
  re_pos0 <- integer()
  re_cor_id0 <- integer()
  re_pair_index0 <- integer()
  groups <- vector("list", length(labels))
  names(groups) <- labels
  value_names <- character()
  coef_names <- character()
  group_names <- character()
  covariance_labels <- character()
  offset <- 0L
  coef_offset <- 0L
  cor_labels <- character()

  for (k in seq_along(terms)) {
    group_name <- terms[[k]]$group
    group <- factor(data[[group_name]])
    levels_k <- levels(group)
    if (length(levels_k) < 2L) {
      cli::cli_abort(c(
        "Random-effect grouping variable {.field {group_name}} has fewer than two levels.",
        "x" = "At least two groups are needed to estimate a random-effect SD."
      ))
    }
    if (all(tabulate(as.integer(group)) == 1L)) {
      cli::cli_abort(c(
        "Random-effect grouping variable {.field {group_name}} has only singleton groups.",
        "x" = "At least one group must have repeated observations in this initial random-effect implementation."
      ))
    }

    variables <- terms[[k]]$variables
    for (variable in variables[!is.na(variables)]) {
      if (!is.numeric(data[[variable]])) {
        cli::cli_abort(c(
          "Random-slope variable {.field {variable}} must be numeric.",
          "x" = "Factor and multi-column random slopes are planned for a later formula-grammar pass."
        ))
      }
    }

    q <- length(terms[[k]]$coef_names)
    group_index <- as.integer(group)
    cor_id0 <- -1L
    if (q == 2L) {
      cor_id0 <- length(cor_labels)
      cor_labels <- c(
        cor_labels,
        format_random_mu_cor_label(
          terms[[k]]$coef_names,
          group_name,
          terms[[k]]$covariance_label
        )
      )
    }

    for (p in seq_len(q)) {
      coef_id <- coef_offset + p
      index[, coef_id] <- offset + (p - 1L) * length(levels_k) + group_index
      if (!identical(terms[[k]]$coef_names[[p]], "(Intercept)")) {
        variable <- terms[[k]]$coef_names[[p]]
        value[, coef_id] <- as.numeric(data[[variable]])
      }
      term_id0 <- c(term_id0, rep.int(coef_id - 1L, length(levels_k)))
      dpar_id0 <- c(dpar_id0, rep.int(0L, length(levels_k)))
      re_pos0 <- c(re_pos0, rep.int(p - 1L, length(levels_k)))
      re_cor_id0 <- c(re_cor_id0, rep.int(cor_id0, length(levels_k)))
      if (q == 2L && p == 2L) {
        re_pair_index0 <- c(
          re_pair_index0,
          offset + seq_len(length(levels_k)) - 1L
        )
      } else {
        re_pair_index0 <- c(re_pair_index0, rep.int(-1L, length(levels_k)))
      }
      groups[[coef_id]] <- levels_k
      value_names <- c(value_names, paste0(labels[[coef_id]], ":", levels_k))
      coef_names <- c(coef_names, terms[[k]]$coef_names[[p]])
      group_names <- c(group_names, group_name)
      covariance_labels <- c(
        covariance_labels,
        if (is.null(terms[[k]]$covariance_label)) {
          NA_character_
        } else {
          terms[[k]]$covariance_label
        }
      )
    }
    offset <- offset + q * length(levels_k)
    coef_offset <- coef_offset + q
  }

  list(
    n_terms = length(labels),
    n_re = offset,
    index = index,
    index0 = index - 1L,
    value = value,
    term_id0 = term_id0,
    dpar_id0 = dpar_id0,
    re_pos0 = re_pos0,
    re_cor_id0 = re_cor_id0,
    re_pair_index0 = re_pair_index0,
    n_cors = length(cor_labels),
    cor_labels = cor_labels,
    labels = labels,
    dpars = rep("mu", length(labels)),
    coef_names = coef_names,
    group_names = group_names,
    covariance_labels = covariance_labels,
    groups = groups,
    value_names = value_names
  )
}

build_random_sigma_structure <- function(terms, data) {
  # The generic mu builder already emits the correlation slots (`n_cors`,
  # `cor_labels`, `re_cor_id0`, `re_pair_index0`) for a correlated intercept+slope
  # block. Since 2026-07-08 the univariate C++ likelihood consumes them for sigma
  # (`eta_cor_sigma`), so residual-scale correlations are no longer an internal error.
  re_sigma <- build_random_mu_structure(terms, data)
  re_sigma$dpars <- rep("sigma", re_sigma$n_terms)
  re_sigma
}

empty_mu_sigma_random_covariance <- function(n_sigma_re = 1L) {
  list(
    n_cors = 0L,
    cor_labels = character(),
    sigma_cross_cor_id0 = rep.int(-1L, max(1L, n_sigma_re)),
    sigma_cross_mu_index0 = rep.int(-1L, max(1L, n_sigma_re))
  )
}

build_mu_sigma_random_covariance <- function(re_mu, re_sigma) {
  if (re_sigma$n_re == 0L) {
    return(empty_mu_sigma_random_covariance(re_sigma$n_re))
  }

  labelled_sigma <- which(!is.na(re_sigma$covariance_labels))
  if (length(labelled_sigma) == 0L) {
    return(empty_mu_sigma_random_covariance(re_sigma$n_re))
  }

  sigma_keys <- paste(
    re_sigma$covariance_labels[labelled_sigma],
    re_sigma$group_names[labelled_sigma],
    sep = "\r"
  )
  sigma_key_counts <- table(sigma_keys)
  cross_sigma <- labelled_sigma[
    sigma_key_counts[sigma_keys] == 1L
  ]
  if (length(cross_sigma) == 0L) {
    return(empty_mu_sigma_random_covariance(re_sigma$n_re))
  }

  sigma_cross_cor_id0 <- rep.int(-1L, re_sigma$n_re)
  sigma_cross_mu_index0 <- rep.int(-1L, re_sigma$n_re)
  cor_labels <- character(length(cross_sigma))

  for (cor_id in seq_along(cross_sigma)) {
    labelled_sigma <- cross_sigma[[cor_id]]
    block_label <- re_sigma$covariance_labels[[labelled_sigma]]
    group_name <- re_sigma$group_names[[labelled_sigma]]
    matching_mu <- which(
      re_mu$covariance_labels == block_label &
        re_mu$group_names == group_name
    )
    if (length(matching_mu) == 0L) {
      cli::cli_abort(c(
        "Labelled residual-scale random effects require a matching labelled {.code mu} random effect.",
        "x" = "{.code sigma} uses block {.code {block_label}} for group {.field {group_name}}, but {.code mu} does not.",
        "i" = "Use matching labels such as {.code y ~ x + (1 | {block_label} | {group_name})} and {.code sigma ~ z + (1 | {block_label} | {group_name})}."
      ))
    }
    if (length(unique(re_mu$dpars[matching_mu])) > 1L) {
      cli::cli_abort(c(
        "Larger labelled covariance blocks are not implemented yet.",
        "x" = "Block {.code {block_label}} on group {.field {group_name}} would connect {.code {re_mu$dpars[matching_mu]}} with {.code {re_sigma$dpars[[labelled_sigma]]}}.",
        "i" = "Use a same-response pair such as {.code mu1} with {.code sigma1}, or wait for the positive-definite q > 2 block parameterization."
      ))
    }
    if (length(matching_mu) > 1L) {
      cli::cli_abort(c(
        "Larger labelled {.code mu}/{.code sigma} covariance blocks are not implemented yet.",
        "x" = "Block {.code {block_label}} on group {.field {group_name}} matched {.code mu} coefficients: {.val {re_mu$coef_names[matching_mu]}}.",
        "i" = "Use one matching coefficient, such as {.code (1 | p | id)} or {.code (0 + x | p | id)}, in one same-response {.code mu}/{.code sigma} pair."
      ))
    }
    if (
      !identical(
        re_mu$coef_names[[matching_mu]],
        re_sigma$coef_names[[labelled_sigma]]
      )
    ) {
      cli::cli_abort(c(
        "Labelled {.code mu}/{.code sigma} covariance blocks need matching coefficients.",
        "x" = "{.code {re_mu$dpars[[matching_mu]]}} uses {.val {re_mu$coef_names[[matching_mu]]}}, but {.code {re_sigma$dpars[[labelled_sigma]]}} uses {.val {re_sigma$coef_names[[labelled_sigma]]}}.",
        "i" = "Use matching terms such as {.code (0 + x | p | id)} in the same-response {.code mu} and {.code sigma} formulas."
      ))
    }
    if (
      !same_response_mu_sigma_dpars(
        re_mu$dpars[[matching_mu]],
        re_sigma$dpars[[labelled_sigma]]
      )
    ) {
      cli::cli_abort(c(
        "Bivariate cross-parameter covariance blocks are same-response only in this phase.",
        "x" = "Block {.code {block_label}} pairs {.code {re_mu$dpars[[matching_mu]]}} with {.code {re_sigma$dpars[[labelled_sigma]]}}.",
        "i" = "Use matching response terms such as {.code mu1} with {.code sigma1}, or {.code mu2} with {.code sigma2}."
      ))
    }
    if (
      !identical(re_mu$groups[[matching_mu]], re_sigma$groups[[labelled_sigma]])
    ) {
      cli::cli_abort(c(
        "Labelled {.code mu}/{.code sigma} covariance blocks need matching group levels.",
        "x" = "Block {.code {block_label}} on group {.field {group_name}} did not align after row filtering."
      ))
    }

    sigma_rows <- which(re_sigma$term_id0 == labelled_sigma - 1L)
    mu_rows <- which(re_mu$term_id0 == matching_mu - 1L)
    sigma_cross_cor_id0[sigma_rows] <- cor_id - 1L
    sigma_cross_mu_index0[sigma_rows] <- mu_rows - 1L
    cor_labels[[cor_id]] <- format_cross_dpar_cor_label(
      re_mu$dpars[[matching_mu]],
      re_sigma$dpars[[labelled_sigma]],
      group_name,
      block_label,
      from_coef = re_mu$coef_names[[matching_mu]],
      to_coef = re_sigma$coef_names[[labelled_sigma]]
    )
  }

  list(
    n_cors = length(cross_sigma),
    cor_labels = cor_labels,
    sigma_cross_cor_id0 = sigma_cross_cor_id0,
    sigma_cross_mu_index0 = sigma_cross_mu_index0
  )
}

detect_biv_q4_covariance_blocks <- function(
  mu1_terms,
  mu2_terms,
  sigma1_terms,
  sigma2_terms
) {
  terms_by_dpar <- list(
    mu1 = mu1_terms,
    mu2 = mu2_terms,
    sigma1 = sigma1_terms,
    sigma2 = sigma2_terms
  )
  if (!all(lengths(terms_by_dpar) == 1L)) {
    return(list())
  }
  terms <- lapply(terms_by_dpar, function(x) x[[1L]])
  labels <- vapply(
    terms,
    function(term) {
      if (is.null(term$covariance_label)) {
        NA_character_
      } else {
        term$covariance_label
      }
    },
    character(1L)
  )
  groups <- vapply(terms, `[[`, character(1L), "group")
  if (
    anyNA(labels) ||
      length(unique(labels)) != 1L ||
      length(unique(groups)) != 1L
  ) {
    return(list())
  }
  term_types <- vapply(terms, `[[`, character(1L), "type")
  coef_names <- lapply(terms, `[[`, "coef_names")
  shared_coef_names <- Reduce(
    function(x, y) {
      if (identical(x, y)) x else NULL
    },
    coef_names
  )
  if (is.null(shared_coef_names)) {
    cli::cli_abort(c(
      "Full bivariate location-scale covariance blocks require matching coefficients.",
      "x" = "Block {.code {labels[[1L]]}} on group {.field {groups[[1L]]}} uses coefficient sets: {.val {vapply(coef_names, paste, character(1L), collapse = ', ')}}.",
      "i" = "Use the same term, such as {.code (1 + x | p | group)}, in {.code mu1}, {.code mu2}, {.code sigma1}, and {.code sigma2}."
    ))
  }
  is_intercept <- vapply(
    terms,
    function(term) {
      identical(term$type, "intercept") &&
        identical(term$coef_names, "(Intercept)")
    },
    logical(1L)
  )
  is_one_slope_endpoint <- all(
    term_types == "correlated_slope",
    lengths(coef_names) == 2L,
    vapply(
      coef_names,
      function(x) identical(x[[1L]], "(Intercept)"),
      logical(1L)
    )
  )
  if (!all(is_intercept) && !is_one_slope_endpoint) {
    cli::cli_abort(c(
      "Full bivariate location-scale covariance blocks allow only intercept-only or one-slope endpoint terms in this phase.",
      "x" = "Block {.code {labels[[1L]]}} on group {.field {groups[[1L]]}} includes random slopes.",
      "i" = "Use {.code (1 | p | group)} across all four endpoints, or one shared q8 term such as {.code (1 + x | p | group)} across {.code mu1}, {.code mu2}, {.code sigma1}, and {.code sigma2}."
    ))
  }

  list(list(
    block_label = labels[[1L]],
    group = groups[[1L]],
    coef_names = shared_coef_names
  ))
}

detect_biv_mu_qgt2_covariance_blocks <- function(mu1_terms, mu2_terms) {
  if (length(mu1_terms) != 1L || length(mu2_terms) != 1L) {
    return(list())
  }

  terms <- list(mu1 = mu1_terms[[1L]], mu2 = mu2_terms[[1L]])
  labels <- vapply(
    terms,
    function(term) {
      if (is.null(term$covariance_label)) {
        NA_character_
      } else {
        term$covariance_label
      }
    },
    character(1L)
  )
  groups <- vapply(terms, `[[`, character(1L), "group")
  if (
    anyNA(labels) ||
      length(unique(labels)) != 1L ||
      length(unique(groups)) != 1L
  ) {
    return(list())
  }

  term_types <- vapply(terms, `[[`, character(1L), "type")
  if (!all(term_types %in% c("correlated_slope", "correlated_block"))) {
    return(list())
  }
  coef_names <- lapply(terms, `[[`, "coef_names")
  if (!identical(coef_names[[1L]], coef_names[[2L]])) {
    cli::cli_abort(c(
      "Bivariate location intercept-slope covariance blocks must use matching coefficients.",
      "x" = "{.code mu1} uses {.val {coef_names[[1L]]}}, but {.code mu2} uses {.val {coef_names[[2L]]}}.",
      "i" = "Use matching terms such as {.code (1 + x | p | id)} in both {.code mu1} and {.code mu2}."
    ))
  }
  list(list(
    block_label = labels[[1L]],
    group = groups[[1L]],
    coef_names = coef_names[[1L]]
  ))
}

reject_biv_sd_mu_q4_mixture <- function(entries, q4_blocks) {
  if (length(entries) == 0L || length(q4_blocks) == 0L) {
    return(invisible(FALSE))
  }

  q4_groups <- vapply(q4_blocks, `[[`, character(1L), "group")
  q4_labels <- vapply(q4_blocks, `[[`, character(1L), "block_label")
  target_groups <- vapply(
    entries,
    function(entry) parse_sd_lhs(entry$lhs)$group,
    character(1L)
  )
  mixed <- which(target_groups %in% q4_groups)
  if (length(mixed) == 0L) {
    return(invisible(FALSE))
  }

  entry <- entries[[mixed[[1L]]]]
  target <- parse_sd_lhs(entry$lhs)
  block_pos <- match(target$group, q4_groups)
  cli::cli_abort(c(
    "Do not combine Family A location-scale covariance blocks with Family B direct SD formulas for the same group.",
    "x" = "{.code {entry$dpar}} targets the {.code {if (identical(target$fun, \"sd1\")) \"mu1\" else \"mu2\"}} location random-effect SD for group {.field {target$group}}, but block {.code {q4_labels[[block_pos]]}} already estimates the joint {.code mu1}/{.code mu2}/{.code sigma1}/{.code sigma2} random-effect covariance for that group.",
    "i" = "Remove {.code {entry$dpar}}, or fit a location-only block if you want direct {.fn sd1} / {.fn sd2} scale regression."
  ))
}

remove_biv_q4_terms <- function(terms, q4_blocks) {
  if (length(terms) == 0L || length(q4_blocks) == 0L) {
    return(terms)
  }
  keep <- vapply(
    terms,
    function(term) {
      !any(vapply(
        q4_blocks,
        function(block) {
          identical(term$covariance_label, block$block_label) &&
            identical(term$group, block$group)
        },
        logical(1L)
      ))
    },
    logical(1L)
  )
  terms[keep]
}

empty_labelled_covariance_block_registry <- function() {
  list(
    n_blocks = 0L,
    n_qgt2_blocks = 0L,
    n_qgt2_re = 0L,
    n_qgt2_sd = 0L,
    n_qgt2_theta = 0L,
    blocks = data.frame(
      block_id0 = integer(),
      level = character(),
      group = character(),
      block_label = character(),
      n_members = integer(),
      n_groups = integer(),
      group_levels = I(list()),
      n_pairs = integer(),
      implemented = logical(),
      stringsAsFactors = FALSE
    ),
    members = data.frame(
      block_id0 = integer(),
      member_id0 = integer(),
      component = character(),
      dpar = character(),
      response_index = integer(),
      coef = character(),
      source_term_id0 = integer(),
      coef_pos0 = integer(),
      group = character(),
      block_label = character(),
      label = character(),
      n_groups = integer(),
      group_levels = I(list()),
      latent_index0 = I(list()),
      design_value = I(list()),
      cor_id0 = I(list()),
      pair_index0 = I(list()),
      stringsAsFactors = FALSE
    ),
    pairs = data.frame(
      block_id0 = integer(),
      pair_id0 = integer(),
      from_member_id0 = integer(),
      to_member_id0 = integer(),
      from_dpar = character(),
      to_dpar = character(),
      from_coef = character(),
      to_coef = character(),
      class = character(),
      parameter = character(),
      tmb_parameter = character(),
      tmb_index = integer(),
      stringsAsFactors = FALSE
    ),
    tmb_data = empty_labelled_covariance_block_tmb_data()
  )
}

build_labelled_covariance_block_registry <- function(
  re_mu,
  re_sigma,
  re_mu_sigma = empty_mu_sigma_random_covariance(re_sigma$n_re),
  q4_blocks = list(),
  mu_qgt2_blocks = list(),
  re_mu_full = re_mu,
  re_sigma_full = re_sigma,
  re_mu_full_terms = list(),
  re_sigma_full_terms = list()
) {
  registry <- empty_labelled_covariance_block_registry()
  registry <- add_q4_covariance_blocks(
    registry,
    re_mu_full,
    re_sigma_full,
    q4_blocks
  )
  registry <- add_biv_mu_qgt2_covariance_blocks(
    registry,
    re_mu_full,
    mu_qgt2_blocks
  )
  registry <- add_large_same_parameter_covariance_blocks(
    registry,
    re_mu_full,
    re_mu_full_terms
  )
  registry <- add_large_same_parameter_covariance_blocks(
    registry,
    re_sigma_full,
    re_sigma_full_terms
  )
  registry <- add_same_parameter_covariance_blocks(
    registry,
    re_mu,
    tmb_parameter = "eta_cor_mu"
  )
  registry <- add_same_parameter_covariance_blocks(
    registry,
    re_sigma,
    tmb_parameter = "eta_cor_sigma"
  )
  registry <- add_mu_sigma_covariance_blocks(
    registry,
    re_mu,
    re_sigma,
    re_mu_sigma
  )
  registry$n_blocks <- nrow(registry$blocks)
  registry <- update_qgt2_covariance_counts(registry)
  registry$tmb_data <- labelled_covariance_block_tmb_data(registry)
  registry
}

add_biv_mu_qgt2_covariance_blocks <- function(
  registry,
  re_mu,
  mu_qgt2_blocks
) {
  if (length(mu_qgt2_blocks) == 0L) {
    return(registry)
  }

  for (block in mu_qgt2_blocks) {
    member_terms <- which(
      re_mu$covariance_labels == block$block_label &
        re_mu$group_names == block$group
    )
    expected_q <- 2L * length(block$coef_names)
    if (length(member_terms) != expected_q) {
      cli::cli_abort(c(
        "Internal error: bivariate location covariance block metadata did not find the expected members.",
        "x" = "Block {.code {block$block_label}} on group {.field {block$group}} expected {expected_q} members but found {length(member_terms)}."
      ))
    }
    member_dpars <- re_mu$dpars[member_terms]
    member_coefs <- re_mu$coef_names[member_terms]
    expected_dpars <- rep(c("mu1", "mu2"), each = length(block$coef_names))
    expected_coefs <- rep(block$coef_names, times = 2L)
    if (
      !identical(member_dpars, expected_dpars) ||
        !identical(member_coefs, expected_coefs)
    ) {
      cli::cli_abort(c(
        "Internal error: bivariate location covariance block members are not in endpoint order.",
        "x" = "Found members: {.val {paste(member_dpars, member_coefs, sep = ':')}}."
      ))
    }
    pair_terms <- utils::combn(member_terms, 2L)
    pair_labels <- vapply(
      seq_len(ncol(pair_terms)),
      function(j) {
        from <- pair_terms[1L, j]
        to <- pair_terms[2L, j]
        format_cross_dpar_cor_label(
          re_mu$dpars[[from]],
          re_mu$dpars[[to]],
          group = block$group,
          covariance_label = block$block_label,
          from_coef = re_mu$coef_names[[from]],
          to_coef = re_mu$coef_names[[to]]
        )
      },
      character(1L)
    )
    n_pairs <- length(pair_labels)
    registry <- append_covariance_registry_block(
      registry,
      re_list = list(re_mu),
      member_terms = list(member_terms),
      parameter = pair_labels,
      tmb_parameter = rep("theta_re_cov", n_pairs),
      tmb_index = covariance_registry_next_theta_index(registry, n_pairs),
      implemented = TRUE
    )
  }

  registry
}

add_q4_covariance_blocks <- function(
  registry,
  re_mu,
  re_sigma,
  q4_blocks
) {
  if (length(q4_blocks) == 0L) {
    return(registry)
  }

  theta_offset <- 0L
  for (block in q4_blocks) {
    mu_terms <- which(
      re_mu$covariance_labels == block$block_label &
        re_mu$group_names == block$group
    )
    sigma_terms <- which(
      re_sigma$covariance_labels == block$block_label &
        re_sigma$group_names == block$group
    )
    coef_names <- block$coef_names
    if (is.null(coef_names)) {
      coef_names <- "(Intercept)"
    }
    expected_n <- 2L * length(coef_names)
    if (length(mu_terms) != expected_n || length(sigma_terms) != expected_n) {
      cli::cli_abort(c(
        "Internal error: endpoint covariance block metadata did not find the expected location and scale members.",
        "x" = "Block {.code {block$block_label}} on group {.field {block$group}} expected {expected_n} location and {expected_n} scale members but found {length(mu_terms)} and {length(sigma_terms)}."
      ))
    }
    member_dpars <- c(re_mu$dpars[mu_terms], re_sigma$dpars[sigma_terms])
    member_coefs <- c(
      re_mu$coef_names[mu_terms],
      re_sigma$coef_names[sigma_terms]
    )
    expected_dpars <- rep(
      c("mu1", "mu2", "sigma1", "sigma2"),
      each = length(coef_names)
    )
    expected_coefs <- rep(coef_names, times = 4L)
    if (
      !identical(member_dpars, expected_dpars) ||
        !identical(member_coefs, expected_coefs)
    ) {
      cli::cli_abort(c(
        "Internal error: endpoint covariance block members are not in endpoint order.",
        "x" = "Found members: {.val {paste(member_dpars, member_coefs, sep = ':')}}."
      ))
    }
    pair_terms <- utils::combn(seq_along(member_dpars), 2L)
    pair_labels <- vapply(
      seq_len(ncol(pair_terms)),
      function(j) {
        from <- pair_terms[1L, j]
        to <- pair_terms[2L, j]
        format_cross_dpar_cor_label(
          member_dpars[[from]],
          member_dpars[[to]],
          group = block$group,
          covariance_label = block$block_label,
          from_coef = member_coefs[[from]],
          to_coef = member_coefs[[to]]
        )
      },
      character(1L)
    )
    registry <- append_covariance_registry_block(
      registry,
      re_list = list(re_mu, re_sigma),
      member_terms = list(mu_terms, sigma_terms),
      parameter = pair_labels,
      tmb_parameter = rep("theta_re_cov", length(pair_labels)),
      tmb_index = theta_offset + seq_along(pair_labels),
      implemented = TRUE
    )
    theta_offset <- theta_offset + length(pair_labels)
  }
  registry
}

add_large_same_parameter_covariance_blocks <- function(
  registry,
  re,
  terms
) {
  if (length(terms) == 0L || re$n_terms == 0L) {
    return(registry)
  }

  term_sizes <- vapply(
    terms,
    function(term) length(term$coef_names),
    integer(1L)
  )
  term_starts <- c(1L, cumsum(term_sizes)[-length(term_sizes)] + 1L)

  for (k in which(term_sizes > 2L)) {
    q <- term_sizes[[k]]
    member_terms <- seq.int(term_starts[[k]], length.out = q)
    pair_coefs <- utils::combn(terms[[k]]$coef_names, 2L)
    pair_labels <- vapply(
      seq_len(ncol(pair_coefs)),
      function(j) {
        format_random_mu_cor_label(
          pair_coefs[, j],
          terms[[k]]$group,
          terms[[k]]$covariance_label
        )
      },
      character(1L)
    )
    n_pairs <- length(pair_labels)
    tmb_index <- covariance_registry_next_theta_index(registry, n_pairs)
    registry <- append_covariance_registry_block(
      registry,
      re_list = list(re),
      member_terms = list(member_terms),
      parameter = pair_labels,
      tmb_parameter = rep("theta_re_cov", n_pairs),
      tmb_index = tmb_index,
      implemented = TRUE
    )
  }

  registry
}

covariance_registry_next_theta_index <- function(registry, n) {
  if (n == 0L) {
    return(integer())
  }
  current <- if (nrow(registry$blocks) == 0L) {
    0L
  } else {
    sum(
      registry$blocks$n_pairs[
        registry$blocks$n_members > 2L &
          registry$blocks$implemented
      ]
    )
  }
  current + seq_len(n)
}

update_qgt2_covariance_counts <- function(registry) {
  if (registry$n_blocks == 0L) {
    registry$n_qgt2_blocks <- 0L
    registry$n_qgt2_re <- 0L
    registry$n_qgt2_sd <- 0L
    registry$n_qgt2_theta <- 0L
    return(registry)
  }
  qgt2 <- registry$blocks$n_members > 2L & registry$blocks$implemented
  registry$n_qgt2_blocks <- sum(qgt2)
  registry$n_qgt2_re <- sum(
    registry$blocks$n_members[qgt2] *
      registry$blocks$n_groups[qgt2]
  )
  registry$n_qgt2_sd <- sum(registry$blocks$n_members[qgt2])
  registry$n_qgt2_theta <- sum(registry$blocks$n_pairs[qgt2])
  registry
}

qgt2_covariance_blocks <- function(registry) {
  if (!is.list(registry) || registry$n_blocks == 0L) {
    return(registry$blocks[0L, , drop = FALSE])
  }
  registry$blocks[
    registry$blocks$n_members > 2L & registry$blocks$implemented,
    ,
    drop = FALSE
  ]
}

qgt2_covariance_members <- function(registry) {
  blocks <- qgt2_covariance_blocks(registry)
  if (nrow(blocks) == 0L) {
    return(registry$members[0L, , drop = FALSE])
  }
  out <- registry$members[
    registry$members$block_id0 %in% blocks$block_id0,
    ,
    drop = FALSE
  ]
  out[order(out$block_id0, out$member_id0), , drop = FALSE]
}

qgt2_covariance_pairs <- function(registry) {
  blocks <- qgt2_covariance_blocks(registry)
  if (nrow(blocks) == 0L) {
    return(registry$pairs[0L, , drop = FALSE])
  }
  out <- registry$pairs[
    registry$pairs$block_id0 %in% blocks$block_id0,
    ,
    drop = FALSE
  ]
  out[order(out$block_id0, out$pair_id0), , drop = FALSE]
}

add_same_parameter_covariance_blocks <- function(
  registry,
  re,
  tmb_parameter
) {
  if (re$n_cors == 0L) {
    return(registry)
  }

  for (cor_id in seq_len(re$n_cors)) {
    right_rows <- which(re$re_cor_id0 == cor_id - 1L)
    left_rows <- re$re_pair_index0[right_rows] + 1L
    left_rows <- left_rows[left_rows > 0L]
    member_terms <- unique(c(
      re$term_id0[left_rows] + 1L,
      re$term_id0[right_rows] + 1L
    ))
    registry <- append_covariance_registry_block(
      registry,
      re_list = list(re),
      member_terms = list(member_terms),
      parameter = re$cor_labels[[cor_id]],
      tmb_parameter = tmb_parameter,
      tmb_index = cor_id
    )
  }
  registry
}

add_mu_sigma_covariance_blocks <- function(
  registry,
  re_mu,
  re_sigma,
  re_mu_sigma
) {
  if (re_mu_sigma$n_cors == 0L) {
    return(registry)
  }

  for (cor_id in seq_len(re_mu_sigma$n_cors)) {
    sigma_rows <- which(re_mu_sigma$sigma_cross_cor_id0 == cor_id - 1L)
    mu_rows <- re_mu_sigma$sigma_cross_mu_index0[sigma_rows] + 1L
    mu_rows <- mu_rows[mu_rows > 0L]
    mu_terms <- unique(re_mu$term_id0[mu_rows] + 1L)
    sigma_terms <- unique(re_sigma$term_id0[sigma_rows] + 1L)
    registry <- append_covariance_registry_block(
      registry,
      re_list = list(re_mu, re_sigma),
      member_terms = list(mu_terms, sigma_terms),
      parameter = re_mu_sigma$cor_labels[[cor_id]],
      tmb_parameter = "eta_cor_mu_sigma",
      tmb_index = cor_id
    )
  }
  registry
}

append_covariance_registry_block <- function(
  registry,
  re_list,
  member_terms,
  parameter,
  tmb_parameter,
  tmb_index,
  implemented = TRUE
) {
  block_id0 <- nrow(registry$blocks)
  member_rows <- do.call(
    rbind,
    Map(
      function(re, terms, component) {
        do.call(
          rbind,
          lapply(
            terms,
            covariance_registry_member_row,
            re = re,
            component = component
          )
        )
      },
      re_list,
      member_terms,
      vapply(re_list, covariance_registry_component, character(1L))
    )
  )
  member_rows$block_id0 <- block_id0
  member_rows$member_id0 <- seq_len(nrow(member_rows)) - 1L

  block_groups <- unique(member_rows$group)
  block_labels <- unique(member_rows$block_label)
  block_label <- block_labels[!is.na(block_labels)]
  if (length(block_label) == 0L) {
    block_label <- NA_character_
  } else {
    block_label <- block_label[[1L]]
  }
  n_groups <- unique(member_rows$n_groups)
  if (length(n_groups) != 1L) {
    n_groups <- NA_integer_
  }
  group_levels <- member_rows$group_levels[[1L]]

  registry$blocks <- rbind(
    registry$blocks,
    data.frame(
      block_id0 = block_id0,
      level = "group",
      group = block_groups[[1L]],
      block_label = block_label,
      n_members = nrow(member_rows),
      n_groups = n_groups[[1L]],
      group_levels = I(list(group_levels)),
      n_pairs = as.integer(choose(nrow(member_rows), 2L)),
      implemented = implemented,
      stringsAsFactors = FALSE
    )
  )

  registry$members <- rbind(
    registry$members,
    member_rows[, names(registry$members), drop = FALSE]
  )

  registry$pairs <- rbind(
    registry$pairs,
    covariance_registry_pair_rows(
      block_id0,
      member_rows,
      parameter,
      tmb_parameter,
      tmb_index
    )
  )
  registry
}

covariance_registry_pair_rows <- function(
  block_id0,
  member_rows,
  parameter,
  tmb_parameter,
  tmb_index
) {
  if (nrow(member_rows) < 2L) {
    return(empty_labelled_covariance_block_registry()$pairs)
  }

  pair_members <- utils::combn(seq_len(nrow(member_rows)), 2L)
  n_pairs <- ncol(pair_members)
  parameter <- recycle_covariance_pair_field(parameter, n_pairs, "parameter")
  tmb_parameter <- recycle_covariance_pair_field(
    tmb_parameter,
    n_pairs,
    "tmb_parameter"
  )
  tmb_index <- recycle_covariance_pair_field(tmb_index, n_pairs, "tmb_index")
  from <- pair_members[1L, ]
  to <- pair_members[2L, ]

  data.frame(
    block_id0 = block_id0,
    pair_id0 = seq_len(n_pairs) - 1L,
    from_member_id0 = member_rows$member_id0[from],
    to_member_id0 = member_rows$member_id0[to],
    from_dpar = member_rows$dpar[from],
    to_dpar = member_rows$dpar[to],
    from_coef = member_rows$coef[from],
    to_coef = member_rows$coef[to],
    class = mapply(
      covariance_block_pair_class,
      member_rows$dpar[from],
      member_rows$coef[from],
      member_rows$dpar[to],
      member_rows$coef[to],
      USE.NAMES = FALSE
    ),
    parameter = parameter,
    tmb_parameter = tmb_parameter,
    tmb_index = tmb_index,
    stringsAsFactors = FALSE
  )
}

recycle_covariance_pair_field <- function(x, n, field) {
  if (length(x) == 1L) {
    return(rep(x, n))
  }
  if (length(x) == n) {
    return(x)
  }
  cli::cli_abort(c(
    "Internal error: covariance-block pair field {.field {field}} has incompatible length.",
    "x" = "Expected length 1 or {n}, but found {length(x)}."
  ))
}

covariance_registry_member_row <- function(term, re, component) {
  term_rows <- which(re$term_id0 == term - 1L)
  coef_index <- unique(re$re_pos0[term_rows] + 1L)
  if (length(coef_index) != 1L) {
    coef_index <- NA_integer_
  }
  n_groups <- length(re$groups[[term]])
  group_index0 <- re$index0[, term] %% n_groups
  data.frame(
    block_id0 = NA_integer_,
    member_id0 = NA_integer_,
    component = component,
    dpar = re$dpars[[term]],
    response_index = covariance_member_response_index(re$dpars[[term]]),
    coef = re$coef_names[[term]],
    source_term_id0 = term - 1L,
    coef_pos0 = coef_index - 1L,
    group = re$group_names[[term]],
    block_label = re$covariance_labels[[term]],
    label = re$labels[[term]],
    n_groups = n_groups,
    group_levels = I(list(re$groups[[term]])),
    latent_index0 = I(list(group_index0)),
    design_value = I(list(re$value[, term])),
    cor_id0 = I(list(re$re_cor_id0[term_rows])),
    pair_index0 = I(list(re$re_pair_index0[term_rows])),
    stringsAsFactors = FALSE
  )
}

covariance_registry_component <- function(re) {
  sub("[0-9]+$", "", re$dpars[[1L]])
}

empty_labelled_covariance_block_tmb_data <- function() {
  list(
    n_re_cov_blocks = 0L,
    re_cov_block_size = 0L,
    re_cov_block_group_count = 0L,
    re_cov_block_member_start = 0L,
    re_cov_block_pair_start = 0L,
    re_cov_member_component = 0L,
    re_cov_member_dpar = 0L,
    re_cov_member_response = -1L,
    re_cov_member_source_term = 0L,
    re_cov_member_coef_pos = 0L,
    re_cov_member_latent_index = matrix(0L, nrow = 1L, ncol = 1L),
    re_cov_member_design_value = matrix(0, nrow = 1L, ncol = 1L),
    re_cov_pair_from_member = 0L,
    re_cov_pair_to_member = 0L,
    re_cov_pair_parameter = 0L,
    re_cov_pair_parameter_index = 0L,
    re_cov_probe_theta = numeric(0),
    re_cov_probe_sd = numeric(0),
    re_cov_probe_x = numeric(0),
    re_cov_probe_z = numeric(0),
    re_cov_probe_covariance = matrix(0, nrow = 1L, ncol = 1L)
  )
}

labelled_covariance_block_tmb_data <- function(
  registry,
  allow_unimplemented = FALSE
) {
  if (registry$n_blocks == 0L) {
    return(empty_labelled_covariance_block_tmb_data())
  }

  blocks <- registry$blocks
  members <- registry$members
  pairs <- registry$pairs
  unimplemented_large <- blocks$n_members != 2L & !blocks$implemented
  if (any(unimplemented_large) && !allow_unimplemented) {
    cli::cli_abort(c(
      "Internal error: dormant covariance-block TMB data only supports implemented two-member blocks.",
      "x" = "Found block size{?s}: {.val {unique(blocks$n_members)}}.",
      "i" = "Add a positive-definite q > 2 parameterization before exporting larger blocks to TMB."
    ))
  }
  member_counts <- as.integer(blocks$n_members)
  pair_counts <- as.integer(blocks$n_pairs)
  if (nrow(pairs) != sum(pair_counts)) {
    cli::cli_abort(c(
      "Internal error: covariance-block pair table is incomplete.",
      "x" = "Block metadata advertises {sum(pair_counts)} pair{?s}, but the pair table has {nrow(pairs)} row{?s}."
    ))
  }
  member_start <- as.integer(c(
    0L,
    cumsum(member_counts)[-length(member_counts)]
  ))
  pair_start <- as.integer(c(0L, cumsum(pair_counts)[-length(pair_counts)]))
  member_response <- members$response_index
  member_response[is.na(member_response)] <- 0L
  pair_parameter <- covariance_parameter_code(pairs$tmb_parameter)
  pair_parameter[is.na(pair_parameter)] <- -1L
  pair_parameter_index <- pairs$tmb_index - 1L
  pair_parameter_index[is.na(pair_parameter_index)] <- -1L

  list(
    n_re_cov_blocks = registry$n_blocks,
    re_cov_block_size = member_counts,
    re_cov_block_group_count = blocks$n_groups,
    re_cov_block_member_start = member_start,
    re_cov_block_pair_start = pair_start,
    re_cov_member_component = covariance_component_code(members$component),
    re_cov_member_dpar = covariance_dpar_code(members$dpar),
    re_cov_member_response = member_response - 1L,
    re_cov_member_source_term = members$source_term_id0,
    re_cov_member_coef_pos = members$coef_pos0,
    re_cov_member_latent_index = do.call(cbind, members$latent_index0),
    re_cov_member_design_value = do.call(cbind, members$design_value),
    re_cov_pair_from_member = pairs$from_member_id0,
    re_cov_pair_to_member = pairs$to_member_id0,
    re_cov_pair_parameter = as.integer(pair_parameter),
    re_cov_pair_parameter_index = as.integer(pair_parameter_index),
    re_cov_probe_theta = numeric(0),
    re_cov_probe_sd = numeric(0),
    re_cov_probe_x = numeric(0),
    re_cov_probe_z = numeric(0),
    re_cov_probe_covariance = matrix(0, nrow = 1L, ncol = 1L)
  )
}

covariance_component_code <- function(component) {
  unname(match(component, c("mu", "sigma")) - 1L)
}

covariance_dpar_code <- function(dpar) {
  unname(match(dpar, c("mu", "sigma", "mu1", "mu2", "sigma1", "sigma2")) - 1L)
}

covariance_parameter_code <- function(parameter) {
  unname(
    match(
      parameter,
      c("eta_cor_mu", "eta_cor_mu_sigma", "eta_cor_sigma", "theta_re_cov")
    ) -
      1L
  )
}

covariance_member_response_index <- function(dpar) {
  suffix <- sub("^(mu|sigma)", "", dpar)
  if (suffix %in% c("1", "2")) {
    return(as.integer(suffix))
  }
  NA_integer_
}

covariance_block_pair_class <- function(
  from_dpar,
  from_coef,
  to_dpar,
  to_coef
) {
  from_family <- sub("[0-9]+$", "", from_dpar)
  to_family <- sub("[0-9]+$", "", to_dpar)
  from_intercept <- identical(from_coef, "(Intercept)")
  to_intercept <- identical(to_coef, "(Intercept)")
  if (identical(from_family, "mu") && identical(to_family, "mu")) {
    if (from_intercept && to_intercept) {
      return("mean-mean")
    }
    if (!from_intercept && !to_intercept) {
      return("slope-slope")
    }
    return("mean-slope")
  }
  if (identical(from_family, "sigma") && identical(to_family, "sigma")) {
    if (!identical(from_dpar, to_dpar)) {
      return("scale-scale")
    }
    if (from_intercept && to_intercept) {
      return("scale-scale")
    }
    if (!from_intercept && !to_intercept) {
      return("malleability")
    }
    return("scale-slope")
  }
  if (
    (identical(from_family, "mu") && identical(to_family, "sigma")) ||
      (identical(from_family, "sigma") && identical(to_family, "mu"))
  ) {
    if (from_intercept && to_intercept) {
      return("mean-scale")
    }
    if (identical(from_family, "mu") && !from_intercept && to_intercept) {
      return("slope-scale")
    }
    if (identical(from_family, "sigma") && from_intercept && !to_intercept) {
      return("slope-scale")
    }
    return("mean-scale-slope")
  }
  paste0(from_dpar, "-", to_dpar)
}

same_response_mu_sigma_dpars <- function(mu_dpar, sigma_dpar) {
  mu_suffix <- sub("^mu", "", mu_dpar)
  sigma_suffix <- sub("^sigma", "", sigma_dpar)
  identical(mu_suffix, sigma_suffix)
}

validate_biv_random_covariance_surface <- function(
  re_mu,
  re_sigma,
  re_mu_sigma
) {
  mu_cross_terms <- integer()
  if (re_mu_sigma$n_cors > 0L) {
    mu_rows <- unique(
      re_mu_sigma$sigma_cross_mu_index0[
        re_mu_sigma$sigma_cross_mu_index0 >= 0L
      ] +
        1L
    )
    mu_cross_terms <- unique(re_mu$term_id0[mu_rows] + 1L)
  }
  sigma_cross_terms <- unique(which(
    re_mu_sigma$sigma_cross_cor_id0 >= 0L
  ))
  if (length(sigma_cross_terms) > 0L) {
    sigma_cross_terms <- unique(re_sigma$term_id0[sigma_cross_terms] + 1L)
  }

  mu_same_terms <- if (re_mu$n_cors > 0L) seq_len(re_mu$n_terms) else integer()
  sigma_same_terms <- if (re_sigma$n_cors > 0L) {
    seq_len(re_sigma$n_terms)
  } else {
    integer()
  }
  labelled_mu <- which(!is.na(re_mu$covariance_labels))
  labelled_sigma <- which(!is.na(re_sigma$covariance_labels))
  unpaired_mu <- setdiff(labelled_mu, c(mu_same_terms, mu_cross_terms))
  unpaired_sigma <- setdiff(
    labelled_sigma,
    c(sigma_same_terms, sigma_cross_terms)
  )

  if (length(unpaired_mu) > 0L) {
    i <- unpaired_mu[[1L]]
    cli::cli_abort(c(
      "Bivariate labelled {.code mu} random effects must be part of an implemented covariance block.",
      "x" = "{.code {re_mu$dpars[[i]]}} uses block {.code {re_mu$covariance_labels[[i]]}} on group {.field {re_mu$group_names[[i]]}} without a supported partner.",
      "i" = "Use matching {.code mu1}/{.code mu2} terms for a mean-mean block or a same-response {.code mu}/ {.code sigma} pair for a response-specific mean-scale block."
    ))
  }
  if (length(unpaired_sigma) > 0L) {
    i <- unpaired_sigma[[1L]]
    cli::cli_abort(c(
      "Bivariate labelled {.code sigma} random effects must be part of an implemented covariance block.",
      "x" = "{.code {re_sigma$dpars[[i]]}} uses block {.code {re_sigma$covariance_labels[[i]]}} on group {.field {re_sigma$group_names[[i]]}} without a supported partner.",
      "i" = "Use matching {.code sigma1}/{.code sigma2} terms for a scale-scale block or a same-response {.code mu}/ {.code sigma} pair for a response-specific mean-scale block."
    ))
  }
  invisible(TRUE)
}

build_biv_mu_random_structure <- function(mu1_terms, mu2_terms, data) {
  build_biv_parameter_random_structure(
    mu1_terms,
    mu2_terms,
    data,
    dpars = c("mu1", "mu2"),
    pair = "mu1/mu2",
    cor_label = format_biv_mu_cor_label
  )
}

build_biv_sigma_random_structure <- function(
  sigma1_terms,
  sigma2_terms,
  data,
  allow_qgt2 = FALSE
) {
  build_biv_parameter_random_structure(
    sigma1_terms,
    sigma2_terms,
    data,
    dpars = c("sigma1", "sigma2"),
    pair = "sigma1/sigma2",
    cor_label = format_biv_sigma_cor_label,
    allow_qgt2 = allow_qgt2
  )
}

expand_biv_parameter_random_terms <- function(terms, term_dpars) {
  expanded_terms <- list()
  expanded_dpars <- character()
  for (i in seq_along(terms)) {
    term <- terms[[i]]
    coef_names <- term$coef_names
    if (length(coef_names) == 1L) {
      expanded_terms[[length(expanded_terms) + 1L]] <- term
      expanded_dpars <- c(expanded_dpars, term_dpars[[i]])
      next
    }

    for (coef_name in coef_names) {
      member <- term
      member$coef_names <- coef_name
      member$variable <- if (identical(coef_name, "(Intercept)")) {
        NA_character_
      } else {
        coef_name
      }
      member$variables <- member$variable
      member$label <- paste0(term$label, ":", coef_name)
      expanded_terms[[length(expanded_terms) + 1L]] <- member
      expanded_dpars <- c(expanded_dpars, term_dpars[[i]])
    }
  }

  list(terms = expanded_terms, dpars = expanded_dpars)
}

abort_unsupported_corpair_level <- function(entry, level) {
  if (identical(level, "phylogenetic")) {
    cli::cli_abort(c(
      "Predictor-dependent phylogenetic {.fn corpair} regression is implemented only for q=2 location-location blocks.",
      "x" = "{.code {entry$dpar}} targets a tree-coupled latent correlation.",
      "i" = "Use matching {.code mu1}/{.code mu2} {.fn phylo} terms and endpoint syntax {.code from = \"mu1\", to = \"mu2\"}.",
      "i" = "Phylogenetic location-scale and scale-scale correlation regressions are q=4 extensions."
    ))
  }
  if (identical(level, "spatial")) {
    cli::cli_abort(c(
      "Predictor-dependent spatial {.fn corpair} regression is planned but not fitted yet.",
      "x" = "{.code {entry$dpar}} targets a spatial latent correlation.",
      "i" = "The current spatial bivariate path fits only a constant q=2 {.code mu1}/{.code mu2} location covariance reported by {.fn corpairs}.",
      "i" = "A future implementation must choose a positive-definite spatial covariance contract before this formula can be optimized."
    ))
  }
  cli::cli_abort(c(
    "Only ordinary group-level {.fn corpair} regression is implemented in this slice.",
    "x" = "{.code {entry$dpar}} targets level {.val {level}}.",
    "i" = "Use {.code level = \"group\"}; structured latent correlation regressions are later slices."
  ))
}

build_biv_mu_corpair_model <- function(
  entries,
  formulas,
  re_mu,
  phylo_mu,
  data
) {
  if (length(entries) == 0L) {
    return(empty_corpair_model())
  }
  if (length(entries) > 1L) {
    labels <- vapply(entries, `[[`, character(1L), "dpar")
    cli::cli_abort(c(
      "Only one ordinary {.fn corpair} formula is implemented in this slice.",
      "x" = "Unsupported formulas: {.val {labels}}.",
      "i" = "Fit one endpoint pair first; multiple latent correlation regressions need a larger covariance parameterization."
    ))
  }

  entry <- entries[[1L]]
  target <- entry$corpair
  level <- if (is.na(target$level)) "group" else target$level
  if (identical(level, "phylogenetic")) {
    return(build_biv_phylo_corpair_model(
      entry,
      formulas[[1L]],
      phylo_mu,
      data
    ))
  }
  if (!identical(level, "group")) {
    abort_unsupported_corpair_level(entry, level)
  }
  if (is.na(target$from) || is.na(target$to)) {
    cli::cli_abort(c(
      "Fitted {.fn corpair} formulas must use endpoint-specific {.arg from} and {.arg to}.",
      "i" = "Use syntax such as {.code corpair(id, level = \"group\", block = \"p\", from = \"mu1\", to = \"mu2\") ~ x}."
    ))
  }
  if (!setequal(c(target$from, target$to), c("mu1", "mu2"))) {
    cli::cli_abort(c(
      "The first fitted ordinary {.fn corpair} route is location-location only.",
      "x" = "{.code {entry$dpar}} targets {.code {target$from}} and {.code {target$to}}.",
      "i" = "Use {.code from = \"mu1\", to = \"mu2\"}; location-scale and scale-scale correlation regressions come later."
    ))
  }
  if (is.na(target$block)) {
    cli::cli_abort(c(
      "Fitted ordinary {.fn corpair} formulas require a covariance-block label.",
      "i" = "Use the same label as the random effects, for example {.code (1 | p | id)} and {.code corpair(id, level = \"group\", block = \"p\", from = \"mu1\", to = \"mu2\") ~ x}."
    ))
  }
  if (
    re_mu$n_terms != 2L ||
      re_mu$n_cors != 1L ||
      !identical(re_mu$dpars, c("mu1", "mu2")) ||
      any(re_mu$coef_names != "(Intercept)")
  ) {
    cli::cli_abort(c(
      "Fitted ordinary {.fn corpair} requires one matching bivariate location random-intercept block.",
      "i" = "Use matching terms such as {.code mu1 = y1 ~ x + (1 | p | id)} and {.code mu2 = y2 ~ x + (1 | p | id)}."
    ))
  }
  if (!identical(unique(re_mu$group_names), target$group)) {
    cli::cli_abort(c(
      "{.fn corpair} group does not match the fitted bivariate location block.",
      "x" = "{.fn corpair} targets group {.field {target$group}}, but the fitted location block uses {.field {unique(re_mu$group_names)}}."
    ))
  }
  if (!identical(unique(re_mu$covariance_labels), target$block)) {
    cli::cli_abort(c(
      "{.fn corpair} block does not match the fitted bivariate location block.",
      "x" = "{.fn corpair} targets block {.code {target$block}}, but the fitted location block uses {.code {unique(re_mu$covariance_labels)}}."
    ))
  }

  formula <- formulas[[1L]]
  mf <- stats::model.frame(formula, data = data, na.action = stats::na.omit)
  X_full <- stats::model.matrix(stats::terms(mf), mf)
  if (nrow(X_full) != nrow(data)) {
    cli::cli_abort(
      "Internal error: {.fn corpair} model frame did not match filtered model rows."
    )
  }

  group <- factor(data[[target$group]], levels = re_mu$groups[[1L]])
  group_rows <- split(seq_len(nrow(data)), group)
  bad <- vapply(
    seq_len(ncol(X_full)),
    function(j) {
      values <- X_full[, j]
      any(vapply(
        group_rows,
        function(rows) {
          max(abs(values[rows] - values[rows[[1L]]])) >
            sqrt(.Machine$double.eps)
        },
        logical(1L)
      ))
    },
    logical(1L)
  )
  if (any(bad)) {
    cli::cli_abort(c(
      "{.fn corpair} predictors must be constant within each random-effect group.",
      "x" = "Non-constant model-matrix column{?s}: {.val {colnames(X_full)[bad]}}.",
      "i" = "Use group-level predictors, such as species ecology or site habitat summaries, for latent random-effect correlation regression."
    ))
  }

  first_rows <- vapply(group_rows, `[[`, integer(1L), 1L)
  X_group <- X_full[first_rows, , drop = FALSE]
  row.names(X_group) <- names(group_rows)

  stats::setNames(
    list(
      n_models = 1L,
      dpars = entry$dpar,
      dpar = entry$dpar,
      target_cor = 1L,
      X = X_group,
      X_tmb = X_group,
      X_list = stats::setNames(list(X_group), entry$dpar),
      terms_list = stats::setNames(list(stats::terms(mf)), entry$dpar),
      model_frame_list = stats::setNames(
        list(mf[first_rows, , drop = FALSE]),
        entry$dpar
      ),
      group = target$group,
      block = target$block,
      level = level,
      from = target$from,
      to = target$to
    ),
    c(
      "n_models",
      "dpars",
      "dpar",
      "target_cor",
      "X",
      "X_tmb",
      "X_list",
      "terms_list",
      "model_frame_list",
      "group",
      "block",
      "level",
      "from",
      "to"
    )
  )
}

build_biv_phylo_corpair_model <- function(entry, formula, phylo_mu, data) {
  target <- entry$corpair
  level <- if (is.na(target$level)) "group" else target$level
  if (!identical(level, "phylogenetic")) {
    abort_unsupported_corpair_level(entry, level)
  }
  if (is.na(target$from) || is.na(target$to)) {
    cli::cli_abort(c(
      "Fitted phylogenetic {.fn corpair} formulas must use endpoint-specific {.arg from} and {.arg to}.",
      "i" = "Use syntax such as {.code corpair(species, level = \"phylogenetic\", block = \"p\", from = \"mu1\", to = \"mu2\") ~ ecology}."
    ))
  }
  if (!setequal(c(target$from, target$to), c("mu1", "mu2"))) {
    cli::cli_abort(c(
      "The first fitted phylogenetic {.fn corpair} route is location-location only.",
      "x" = "{.code {entry$dpar}} targets {.code {target$from}} and {.code {target$to}}.",
      "i" = "Use {.code from = \"mu1\", to = \"mu2\"}; phylogenetic location-scale and scale-scale correlation regressions are q=4 extensions."
    ))
  }
  if (is.na(target$block)) {
    cli::cli_abort(c(
      "Fitted phylogenetic {.fn corpair} formulas require a covariance-block label.",
      "i" = "Use the same label as the {.fn phylo} terms, for example {.code phylo(1 | p | species, tree = tree)} and {.code corpair(species, level = \"phylogenetic\", block = \"p\", from = \"mu1\", to = \"mu2\") ~ ecology}."
    ))
  }
  if (!isTRUE(phylo_mu$has) || !identical(as.integer(phylo_mu$q), 2L)) {
    cli::cli_abort(c(
      "Fitted phylogenetic {.fn corpair} regression requires matching bivariate phylogenetic location terms.",
      "i" = "Use matching terms such as {.code mu1 = y1 ~ x + phylo(1 | p | species, tree = tree)} and {.code mu2 = y2 ~ x + phylo(1 | p | species, tree = tree)}."
    ))
  }
  if (!identical(target$group, phylo_mu$group)) {
    cli::cli_abort(c(
      "{.fn corpair} group does not match the fitted phylogenetic location block.",
      "x" = "{.fn corpair} targets group {.field {target$group}}, but the fitted phylogenetic block uses {.field {phylo_mu$group}}."
    ))
  }
  if (!identical(target$block, phylo_mu_block(phylo_mu))) {
    cli::cli_abort(c(
      "{.fn corpair} block does not match the fitted phylogenetic location block.",
      "x" = "{.fn corpair} targets block {.code {target$block}}, but the fitted phylogenetic block uses {.code {phylo_mu_block(phylo_mu)}}."
    ))
  }

  mf <- stats::model.frame(formula, data = data, na.action = stats::na.omit)
  X_full <- stats::model.matrix(stats::terms(mf), mf)
  if (nrow(X_full) != nrow(data)) {
    cli::cli_abort(
      "Internal error: {.fn corpair} model frame did not match filtered model rows."
    )
  }

  group <- factor(data[[target$group]], levels = phylo_mu$species_levels)
  group_rows <- split(seq_len(nrow(data)), group)
  bad <- vapply(
    seq_len(ncol(X_full)),
    function(j) {
      values <- X_full[, j]
      any(vapply(
        group_rows,
        function(rows) {
          max(abs(values[rows] - values[rows[[1L]]])) >
            sqrt(.Machine$double.eps)
        },
        logical(1L)
      ))
    },
    logical(1L)
  )
  if (any(bad)) {
    cli::cli_abort(c(
      "{.fn corpair} predictors must be constant within each phylogenetic species.",
      "x" = "Non-constant model-matrix column{?s}: {.val {colnames(X_full)[bad]}}.",
      "i" = "Use species-level predictors, such as ecological or life-history summaries, for phylogenetic latent correlation regression."
    ))
  }

  first_rows <- match(phylo_mu$species_levels, as.character(group))
  if (anyNA(first_rows)) {
    cli::cli_abort(
      "Internal error: failed to align {.fn corpair} rows with phylogenetic species."
    )
  }
  X_group <- X_full[first_rows, , drop = FALSE]
  row.names(X_group) <- phylo_mu$species_levels

  tip_nodes <- match(rownames(X_group), phylo_mu$node_labels)
  if (anyNA(tip_nodes)) {
    cli::cli_abort(
      "Internal error: failed to align {.fn corpair} species rows with phylogenetic tip nodes."
    )
  }
  X_tmb <- matrix(0, nrow = phylo_mu$n_re, ncol = ncol(X_group))
  dimnames(X_tmb) <- list(phylo_mu$node_labels, colnames(X_group))
  X_tmb[tip_nodes, ] <- X_group

  stats::setNames(
    list(
      n_models = 1L,
      dpars = entry$dpar,
      dpar = entry$dpar,
      target_cor = 1L,
      X = X_group,
      X_tmb = X_tmb,
      X_list = stats::setNames(list(X_group), entry$dpar),
      terms_list = stats::setNames(list(stats::terms(mf)), entry$dpar),
      model_frame_list = stats::setNames(
        list(mf[first_rows, , drop = FALSE]),
        entry$dpar
      ),
      group = target$group,
      block = target$block,
      level = level,
      from = target$from,
      to = target$to
    ),
    c(
      "n_models",
      "dpars",
      "dpar",
      "target_cor",
      "X",
      "X_tmb",
      "X_list",
      "terms_list",
      "model_frame_list",
      "group",
      "block",
      "level",
      "from",
      "to"
    )
  )
}

build_biv_parameter_random_structure <- function(
  terms1,
  terms2,
  data,
  dpars,
  pair,
  cor_label,
  allow_qgt2 = FALSE
) {
  n_terms <- stats::setNames(c(length(terms1), length(terms2)), dpars)
  if (sum(n_terms) == 0L) {
    return(empty_random_mu_structure(nrow(data)))
  }
  if (any(n_terms > 1L)) {
    cli::cli_abort(c(
      "Bivariate {.code {pair}} random effects currently allow at most one labelled random-effect term per formula.",
      "x" = "Found {n_terms[[1L]]} term{?s} in {.code {dpars[[1L]]}} and {n_terms[[2L]]} term{?s} in {.code {dpars[[2L]]}}."
    ))
  }

  terms <- list(terms1, terms2)
  present <- which(n_terms == 1L)
  terms <- lapply(present, function(i) terms[[i]][[1L]])
  term_dpars <- unname(dpars[present])
  term_types <- vapply(terms, `[[`, character(1L), "type")
  is_intercept_block <- all(term_types == "intercept")
  is_biv_mu_slope_block <- identical(unname(dpars), c("mu1", "mu2")) &&
    length(terms) == 2L &&
    all(term_types == "slope")
  is_biv_sigma_slope_block <- identical(unname(dpars), c("sigma1", "sigma2")) &&
    length(terms) == 2L &&
    all(term_types == "slope")
  is_biv_sigma_qgt2_block <- identical(unname(dpars), c("sigma1", "sigma2")) &&
    isTRUE(allow_qgt2) &&
    length(terms) == 2L &&
    all(term_types %in% c("correlated_slope", "correlated_block"))
  is_biv_mu_qgt2_block <- identical(unname(dpars), c("mu1", "mu2")) &&
    length(terms) == 2L &&
    all(term_types %in% c("correlated_slope", "correlated_block"))
  is_single_slope_block <- length(terms) == 1L &&
    all(term_types == "slope")
  if (
    !is_intercept_block &&
      !is_biv_mu_slope_block &&
      !is_biv_sigma_slope_block &&
      !is_biv_sigma_qgt2_block &&
      !is_biv_mu_qgt2_block &&
      !is_single_slope_block
  ) {
    cli::cli_abort(c(
      "Broader bivariate random-slope covariance blocks are planned but not implemented for {.code {pair}}.",
      "x" = "This phase fits matching labelled random intercepts such as {.code (1 | p | id)}, matching slope-only {.code mu1}/{.code mu2}, same-response {.code mu}/{.code sigma}, or {.code sigma1}/{.code sigma2} terms such as {.code (0 + x | p | id)}, and matching location intercept-slope blocks such as {.code (1 + x | p | id)}.",
      "i" = "All-four location-scale slope blocks require the same one-slope term, such as {.code (1 + x | p | id)}, in {.code mu1}, {.code mu2}, {.code sigma1}, and {.code sigma2}."
    ))
  }
  labels <- unname(vapply(
    terms,
    function(term) {
      if (is.null(term$covariance_label)) {
        NA_character_
      } else {
        term$covariance_label
      }
    },
    character(1L)
  ))
  if (anyNA(labels)) {
    cli::cli_abort(c(
      "Bivariate random-effect covariance blocks require covariance-block labels.",
      "i" = "Use syntax like {.code (1 | p | id)} rather than unlabelled {.code (1 | id)}."
    ))
  }
  groups_present <- vapply(terms, `[[`, character(1L), "group")
  same_parameter_cor <- FALSE
  if (length(terms) == 2L) {
    if (!identical(groups_present[[1L]], groups_present[[2L]])) {
      cli::cli_abort(c(
        "Bivariate {.code {pair}} random effects must use the same grouping variable.",
        "x" = "{.code {term_dpars[[1L]]}} uses {.field {groups_present[[1L]]}} but {.code {term_dpars[[2L]]}} uses {.field {groups_present[[2L]]}}."
      ))
    }
    if (
      (isTRUE(is_biv_mu_slope_block) ||
        isTRUE(is_biv_sigma_slope_block) ||
        isTRUE(is_biv_sigma_qgt2_block) ||
        isTRUE(is_biv_mu_qgt2_block)) &&
        !identical(terms[[1L]]$coef_names, terms[[2L]]$coef_names)
    ) {
      cli::cli_abort(c(
        "Bivariate {.code {pair}} random effects must use the same random-slope coefficient set.",
        "x" = "{.code {dpars[[1L]]}} uses coefficient {.val {terms[[1L]]$coef_names}}, but {.code {dpars[[2L]]}} uses {.val {terms[[2L]]$coef_names}}.",
        "i" = "Use matching terms such as {.code (0 + x | p | id)} in both formulas."
      ))
    }
    same_parameter_cor <- identical(labels[[1L]], labels[[2L]])
  }

  if (isTRUE(is_biv_mu_qgt2_block) || isTRUE(is_biv_sigma_qgt2_block)) {
    same_parameter_cor <- FALSE
  }
  expanded_terms <- expand_biv_parameter_random_terms(terms, term_dpars)
  terms <- expanded_terms$terms
  term_dpars <- expanded_terms$dpars
  group_name <- groups_present[[1L]]
  group <- factor(data[[group_name]])
  levels_group <- levels(group)
  if (length(levels_group) < 2L) {
    cli::cli_abort(c(
      "Random-effect grouping variable {.field {group_name}} has fewer than two levels.",
      "x" = "At least two groups are needed to estimate a bivariate group-level covariance."
    ))
  }
  if (all(tabulate(as.integer(group)) == 1L)) {
    cli::cli_abort(c(
      "Random-effect grouping variable {.field {group_name}} has only singleton groups.",
      "x" = "At least one group must have repeated observations in this bivariate random-effect implementation."
    ))
  }

  n_group <- length(levels_group)
  group_index <- as.integer(group)
  n_cols <- length(terms)
  term_dpar_id0 <- match(term_dpars, dpars) - 1L
  index <- matrix(NA_integer_, nrow = nrow(data), ncol = n_cols)
  value <- matrix(1, nrow = nrow(data), ncol = n_cols)
  base_labels <- unname(vapply(terms, `[[`, character(1L), "label"))
  labels_out <- paste0(term_dpars, ":", base_labels)
  groups <- rep(list(levels_group), n_cols)
  names(groups) <- labels_out

  term_id0 <- integer()
  dpar_id0 <- integer()
  re_pos0 <- integer()
  re_cor_id0 <- integer()
  re_pair_index0 <- integer()
  value_names <- character()
  for (j in seq_len(n_cols)) {
    offset <- (j - 1L) * n_group
    index[, j] <- offset + group_index
    if (!identical(terms[[j]]$coef_names, "(Intercept)")) {
      variable <- terms[[j]]$coef_names[[1L]]
      if (!is.numeric(data[[variable]])) {
        cli::cli_abort(c(
          "Bivariate random-slope variable {.field {variable}} must be numeric.",
          "x" = "Factor and multi-column bivariate random slopes are planned for a later formula-grammar pass."
        ))
      }
      value[, j] <- as.numeric(data[[variable]])
    }
    term_id0 <- c(term_id0, rep.int(j - 1L, n_group))
    dpar_id0 <- c(dpar_id0, rep.int(term_dpar_id0[[j]], n_group))
    re_pos0 <- c(re_pos0, rep.int(j - 1L, n_group))
    if (isTRUE(same_parameter_cor) && j == 2L) {
      re_cor_id0 <- c(re_cor_id0, rep.int(0L, n_group))
      re_pair_index0 <- c(re_pair_index0, seq_len(n_group) - 1L)
    } else {
      re_cor_id0 <- c(re_cor_id0, rep.int(-1L, n_group))
      re_pair_index0 <- c(re_pair_index0, rep.int(-1L, n_group))
    }
    value_names <- c(value_names, paste0(labels_out[[j]], ":", levels_group))
  }

  list(
    n_terms = n_cols,
    n_re = n_cols * n_group,
    index = index,
    index0 = index - 1L,
    value = value,
    term_id0 = term_id0,
    dpar_id0 = dpar_id0,
    re_pos0 = re_pos0,
    re_cor_id0 = re_cor_id0,
    re_pair_index0 = re_pair_index0,
    n_cors = if (isTRUE(same_parameter_cor)) 1L else 0L,
    cor_labels = if (isTRUE(same_parameter_cor)) {
      cor_label(group_name, labels[[1L]], terms[[1L]]$coef_names[[1L]])
    } else {
      character()
    },
    labels = labels_out,
    dpars = term_dpars,
    coef_names = unname(vapply(terms, `[[`, character(1L), "coef_names")),
    group_names = rep(group_name, n_cols),
    covariance_labels = unname(vapply(
      terms,
      function(term) {
        if (is.null(term$covariance_label)) {
          NA_character_
        } else {
          term$covariance_label
        }
      },
      character(1L)
    )),
    groups = groups,
    value_names = value_names
  )
}

reject_biv_cross_parameter_label_reuse <- function(
  mu1_terms,
  mu2_terms,
  sigma1_terms,
  sigma2_terms
) {
  terms <- list(
    mu1 = mu1_terms,
    mu2 = mu2_terms,
    sigma1 = sigma1_terms,
    sigma2 = sigma2_terms
  )
  if (!all(lengths(terms) == 1L)) {
    return(invisible(FALSE))
  }

  terms <- lapply(terms, function(term) term[[1L]])
  labels <- vapply(
    terms,
    function(term) {
      if (is.null(term$covariance_label)) {
        NA_character_
      } else {
        term$covariance_label
      }
    },
    character(1L)
  )
  groups <- vapply(terms, function(term) term$group, character(1L))
  if (anyNA(labels) || length(unique(labels)) != 1L) {
    return(invisible(FALSE))
  }
  if (length(unique(groups)) != 1L) {
    return(invisible(FALSE))
  }

  block_label <- labels[[1L]]
  group_name <- groups[[1L]]
  cli::cli_abort(c(
    "Unsupported bivariate covariance-block label reuse.",
    "x" = "Block {.code {block_label}} on group {.field {group_name}} was not recognized as a supported intercept-only covariance block.",
    "i" = "Supported all-four bivariate covariance uses matching {.code (1 | p | {group_name})} terms in {.code mu1}, {.code mu2}, {.code sigma1}, and {.code sigma2}.",
    "i" = "Use distinct labels such as {.code (1 | pm | {group_name})} for {.code mu1}/{.code mu2} and {.code (1 | ps | {group_name})} for {.code sigma1}/{.code sigma2} when you want two q=2 blocks."
  ))
}

build_sd_mu_structure <- function(entries, targets, re_mu, data) {
  if (length(entries) == 0L) {
    return(empty_sd_mu_structure(re_mu$n_re))
  }
  if (re_mu$n_re == 0L) {
    cli::cli_abort(
      "Internal error: {.code sd()} target was validated without a {.code mu} random effect."
    )
  }

  dpars <- vapply(entries, `[[`, character(1), "dpar")
  X_list <- vector("list", length(entries))
  terms_list <- vector("list", length(entries))
  model_frame_list <- vector("list", length(entries))
  coef_index <- vector("list", length(entries))
  row_index <- vector("list", length(entries))
  coef_names_list <- vector("list", length(entries))
  group_levels_list <- vector("list", length(entries))
  names(X_list) <- names(terms_list) <- names(model_frame_list) <- dpars
  names(coef_index) <- names(row_index) <- names(coef_names_list) <- dpars
  names(group_levels_list) <- dpars
  re_sd_row0 <- rep.int(-1L, re_mu$n_re)
  coef_offset <- 0L
  row_offset <- 0L

  for (i in seq_along(entries)) {
    entry <- entries[[i]]
    target <- targets[[i]]
    f_sd <- drm_entry_formula(entry, response = FALSE)
    mf_sd <- stats::model.frame(f_sd, data = data, na.action = stats::na.omit)
    group <- factor(
      data[[target$group]],
      levels = re_mu$groups[[target$target_coef]]
    )
    validate_sd_mu_group_constant(mf_sd, group, entry$dpar, target$group)

    group_first <- match(levels(group), as.character(group))
    if (anyNA(group_first)) {
      cli::cli_abort(
        "Internal error: failed to align {.code sd()} scale rows with random-effect groups."
      )
    }
    mf_group <- mf_sd[group_first, , drop = FALSE]
    X <- stats::model.matrix(stats::terms(mf_sd), mf_group)
    rownames(X) <- levels(group)

    p <- ncol(X)
    r <- nrow(X)
    coef_index[[entry$dpar]] <- seq.int(coef_offset + 1L, length.out = p)
    row_index[[entry$dpar]] <- seq.int(row_offset + 1L, length.out = r)
    coef_offset <- coef_offset + p
    row_offset <- row_offset + r

    target_re <- which(re_mu$term_id0 == target$target_coef - 1L)
    re_sd_row0[target_re] <- row_index[[entry$dpar]][seq_along(target_re)] - 1L

    X_list[[entry$dpar]] <- X
    terms_list[[entry$dpar]] <- stats::terms(mf_sd)
    model_frame_list[[entry$dpar]] <- mf_group
    coef_names_list[[entry$dpar]] <- colnames(X)
    group_levels_list[[entry$dpar]] <- rownames(X)
  }

  X <- block_diagonal_matrices(X_list, dpars)
  target_term <- stats::setNames(
    vapply(targets, `[[`, integer(1), "target_term"),
    dpars
  )
  target_coef <- stats::setNames(
    vapply(targets, `[[`, integer(1), "target_coef"),
    dpars
  )
  group <- stats::setNames(vapply(targets, `[[`, character(1), "group"), dpars)
  target_label <- stats::setNames(
    vapply(targets, `[[`, character(1), "label"),
    dpars
  )

  structure(
    list(
      n_models = length(entries),
      dpars = dpars,
      dpar = if (length(dpars) == 1L) dpars else NA_character_,
      group = group,
      target_term = target_term,
      target_coef = target_coef,
      target_label = target_label,
      X = X,
      X_list = X_list,
      coef_index = coef_index,
      row_index = row_index,
      terms = if (length(dpars) == 1L) terms_list[[1L]] else NULL,
      terms_list = terms_list,
      model_frame = if (length(dpars) == 1L) model_frame_list[[1L]] else NULL,
      model_frame_list = model_frame_list,
      coef_names = if (length(dpars) == 1L) {
        coef_names_list[[1L]]
      } else {
        colnames(X)
      },
      coef_names_list = coef_names_list,
      group_levels = if (length(dpars) == 1L) {
        group_levels_list[[1L]]
      } else {
        rownames(X)
      },
      group_levels_list = group_levels_list,
      re_sd_row0 = re_sd_row0
    ),
    class = "drm_sd_mu_structure"
  )
}

build_sd_phylo_structure <- function(entries, targets, phylo_mu, data) {
  if (length(entries) == 0L) {
    n_re <- if (isTRUE(phylo_mu$has)) phylo_mu$n_re else 1L
    return(empty_sd_phylo_structure(n_re))
  }
  if (!isTRUE(phylo_mu$has)) {
    cli::cli_abort(
      "Internal error: {.code sd_phylo()} target was validated without a phylogenetic {.code mu} random effect."
    )
  }

  dpars <- vapply(entries, `[[`, character(1), "dpar")
  target_dpar <- vapply(
    targets,
    function(target) {
      value <- target$target_dpar
      if (is.null(value) || is.na(value)) "mu" else value
    },
    character(1L)
  )
  target_endpoint <- vapply(
    seq_along(targets),
    function(i) {
      target <- targets[[i]]
      value <- target$target_endpoint
      if (is.null(value) || is.na(value)) {
        match(target_dpar[[i]], phylo_mu_dpars(phylo_mu))
      } else {
        as.integer(value)
      }
    },
    integer(1L)
  )

  X_list <- list()
  terms_list <- list()
  model_frame_list <- list()
  coef_names_list <- list()
  group_levels_list <- list()
  row_index <- list()
  coef_index <- list()
  observation_sd_row0_list <- list()
  node_sd_row0 <- rep.int(
    -1L,
    length(phylo_mu_dpars(phylo_mu)) * phylo_mu$n_re
  )
  col_offset <- 0L
  row_offset <- 0L

  for (i in seq_along(entries)) {
    entry <- entries[[i]]
    target <- targets[[i]]
    dpar <- entry$dpar
    f_sd <- drm_entry_formula(entry, response = FALSE)
    mf_sd <- stats::model.frame(f_sd, data = data, na.action = stats::na.omit)
    group <- factor(data[[target$group]], levels = phylo_mu$species_levels)
    validate_sd_mu_group_constant(mf_sd, group, entry$dpar, target$group)

    group_first <- match(levels(group), as.character(group))
    if (anyNA(group_first)) {
      cli::cli_abort(
        "Internal error: failed to align {.code sd_phylo()} scale rows with phylogenetic species."
      )
    }
    mf_group <- mf_sd[group_first, , drop = FALSE]
    X_i <- stats::model.matrix(stats::terms(mf_sd), mf_group)
    rownames(X_i) <- levels(group)

    observation_sd_row0 <- match(
      as.character(data[[target$group]]),
      rownames(X_i)
    ) -
      1L
    if (anyNA(observation_sd_row0)) {
      cli::cli_abort(
        "Internal error: failed to align observations with {.code sd_phylo()} species rows."
      )
    }

    tip_nodes <- match(rownames(X_i), phylo_mu$node_labels)
    if (anyNA(tip_nodes)) {
      cli::cli_abort(
        "Internal error: failed to align {.code sd_phylo()} species rows with phylogenetic tip nodes."
      )
    }
    endpoint_offset <- (target_endpoint[[i]] - 1L) * phylo_mu$n_re
    node_sd_row0[endpoint_offset + tip_nodes] <-
      row_offset + seq_len(nrow(X_i)) - 1L

    X_list[[dpar]] <- X_i
    terms_list[[dpar]] <- stats::terms(mf_sd)
    model_frame_list[[dpar]] <- mf_group
    coef_names_list[[dpar]] <- colnames(X_i)
    group_levels_list[[dpar]] <- rownames(X_i)
    row_index[[dpar]] <- row_offset + seq_len(nrow(X_i))
    coef_index[[dpar]] <- col_offset + seq_len(ncol(X_i))
    observation_sd_row0_list[[dpar]] <- unname(as.integer(observation_sd_row0))
    row_offset <- row_offset + nrow(X_i)
    col_offset <- col_offset + ncol(X_i)
  }

  X <- if (length(X_list) == 1L) {
    X_list[[1L]]
  } else {
    block_diagonal_matrices(X_list, names = names(X_list))
  }

  structure(
    list(
      n_models = length(entries),
      dpars = dpars,
      dpar = if (length(dpars) == 1L) dpars else NA_character_,
      group = stats::setNames(
        vapply(targets, `[[`, character(1), "group"),
        dpars
      ),
      target_dpar = stats::setNames(target_dpar, dpars),
      target_endpoint = stats::setNames(target_endpoint, dpars),
      target_label = stats::setNames(
        vapply(targets, `[[`, character(1), "label"),
        dpars
      ),
      X = X,
      X_list = X_list,
      coef_index = coef_index,
      row_index = row_index,
      terms = if (length(entries) == 1L) terms_list[[1L]] else NULL,
      terms_list = terms_list,
      model_frame = if (length(entries) == 1L) {
        model_frame_list[[1L]]
      } else {
        NULL
      },
      model_frame_list = model_frame_list,
      coef_names = if (length(entries) == 1L) {
        coef_names_list[[1L]]
      } else {
        colnames(X)
      },
      coef_names_list = coef_names_list,
      group_levels = if (length(entries) == 1L) {
        group_levels_list[[1L]]
      } else {
        rownames(X)
      },
      group_levels_list = group_levels_list,
      observation_sd_row0 = if (length(entries) == 1L) {
        observation_sd_row0_list[[1L]]
      } else {
        unlist(observation_sd_row0_list, use.names = FALSE)
      },
      observation_sd_row0_list = observation_sd_row0_list,
      node_sd_row0 = unname(as.integer(node_sd_row0))
    ),
    class = "drm_sd_phylo_structure"
  )
}

block_diagonal_matrices <- function(mats, names = names(mats)) {
  n_row <- sum(vapply(mats, nrow, integer(1)))
  n_col <- sum(vapply(mats, ncol, integer(1)))
  out <- matrix(0, nrow = n_row, ncol = n_col)
  row_names <- character(n_row)
  col_names <- character(n_col)
  row_offset <- 0L
  col_offset <- 0L
  for (i in seq_along(mats)) {
    mat <- mats[[i]]
    rows <- seq.int(row_offset + 1L, length.out = nrow(mat))
    cols <- seq.int(col_offset + 1L, length.out = ncol(mat))
    out[rows, cols] <- mat
    row_names[rows] <- paste0(names[[i]], ":", rownames(mat))
    col_names[cols] <- paste0(names[[i]], ":", colnames(mat))
    row_offset <- row_offset + nrow(mat)
    col_offset <- col_offset + ncol(mat)
  }
  dimnames(out) <- list(row_names, col_names)
  out
}

validate_sd_mu_group_constant <- function(
  model_frame,
  group,
  dpar,
  group_name
) {
  if (ncol(model_frame) == 0L) {
    return(invisible(model_frame))
  }
  for (variable in names(model_frame)) {
    values <- model_frame[[variable]]
    variable_ok <- vapply(
      split(values, group),
      function(x) {
        length(unique(x)) <= 1L
      },
      logical(1)
    )
    if (!all(variable_ok)) {
      bad_group <- names(variable_ok)[which(!variable_ok)[[1L]]]
      cli::cli_abort(c(
        "{.code {dpar}} formulas are group-level random-effect scale models.",
        "x" = "Predictor {.field {variable}} varies within {.field {group_name}} level {.val {bad_group}}.",
        "i" = "Use predictors that are constant within {.field {group_name}}, or use {.code sigma ~ {variable}} for observation-level residual scale."
      ))
    }
  }
  invisible(model_frame)
}

expand_random_mu_terms <- function(terms) {
  labels <- unlist(
    lapply(terms, function(term) {
      if (length(term$coef_names) == 1L) {
        return(term$label)
      }
      paste0(term$label, ":", term$coef_names)
    }),
    use.names = FALSE
  )
  list(labels = labels)
}

validate_random_mu_term_overlap <- function(terms) {
  keys <- unlist(
    lapply(terms, function(term) {
      coef_names <- term$coef_names
      paste(term$group, coef_names, sep = "::")
    }),
    use.names = FALSE
  )
  if (anyDuplicated(keys)) {
    cli::cli_abort(c(
      "Overlapping random-effect terms are not supported.",
      "x" = "Use either a correlated block such as {.code (1 + x | id)} or separate independent terms such as {.code (1 | id) + (0 + x | id)}, not both for the same group and coefficient."
    ))
  }
  invisible(terms)
}

extract_meta_known_v <- function(rhs) {
  terms <- flatten_plus_terms(rhs)
  is_meta <- vapply(terms, is_meta_known_v_call, logical(1))
  if (sum(is_meta) > 1L) {
    cli::cli_abort("Only one known sampling covariance term is supported.")
  }
  if (!any(is_meta)) {
    return(list(rhs = rhs, V = NULL))
  }

  meta_call <- terms[[which(is_meta)]]
  clean_terms <- terms[!is_meta]
  list(
    rhs = rebuild_plus_terms(clean_terms),
    V = extract_meta_known_v_arg(meta_call)
  )
}

flatten_plus_terms <- function(expr) {
  expr <- strip_parens(expr)
  if (is.call(expr) && identical(expr[[1L]], as.name("+"))) {
    c(flatten_plus_terms(expr[[2L]]), flatten_plus_terms(expr[[3L]]))
  } else {
    list(expr)
  }
}

rebuild_plus_terms <- function(terms) {
  if (length(terms) == 0L) {
    return(quote(1))
  }
  Reduce(function(left, right) call("+", left, right), terms)
}

is_meta_known_v_call <- function(expr) {
  expr <- strip_parens(expr)
  is.call(expr) && drm_call_name(expr) %in% c("meta_known_V", "meta_V")
}

extract_meta_known_v_arg <- function(expr) {
  fn_name <- drm_call_name(expr)
  args <- as.list(expr)[-1L]
  arg_names <- names(args)
  if (is.null(arg_names)) {
    arg_names <- rep("", length(args))
  }
  arg_names[is.na(arg_names)] <- ""

  if (identical(fn_name, "meta_V")) {
    if ("scale" %in% arg_names && "V" %in% arg_names && !"w" %in% arg_names) {
      cli::cli_abort(c(
        "{.arg scale} is not used for additive known sampling covariance.",
        "x" = "Use {.code meta_V(V = V)} without {.arg scale}; that is the exact additive known-`V` route.",
        "i" = "{.code meta_V(w = w, scale = \"proportional\")} remains reserved until a proportional sampling-variance likelihood is implemented."
      ))
    }
    if (any(arg_names %in% c("w", "scale"))) {
      cli::cli_abort(c(
        "{.fn meta_V} proportional sampling-variance arguments are reserved, not implemented.",
        "x" = "Use {.code meta_V(V = V)} without {.arg w} or {.arg scale} for additive known sampling covariance.",
        "i" = "{.code meta_V(w = w, scale = \"proportional\")} needs its own likelihood, diagnostics, and tests; it is not a wrapper around {.arg weights}."
      ))
    }
    valid <- length(args) == 1L && identical(arg_names[[1L]], "V")
  } else {
    valid <- length(args) == 1L && arg_names[[1L]] %in% c("", "V")
  }
  if (!valid) {
    cli::cli_abort(
      "{.fn {fn_name}} requires exactly one argument named {.arg V}."
    )
  }

  args[[1L]]
}

formula_contains_call <- function(expr, name) {
  expr <- strip_parens(expr)
  if (!is.call(expr)) {
    return(FALSE)
  }
  identical(drm_call_name(expr), name) ||
    any(vapply(
      as.list(expr)[-1L],
      function(part) formula_contains_call(part, name),
      logical(1)
    ))
}

strip_parens <- function(expr) {
  while (is.call(expr) && identical(expr[[1L]], as.name("("))) {
    expr <- expr[[2L]]
  }
  expr
}

drm_call_name <- function(expr) {
  expr <- strip_parens(expr)
  if (!is.call(expr)) {
    return(NA_character_)
  }
  fun <- expr[[1L]]
  if (is.symbol(fun)) {
    return(as.character(fun))
  }
  if (
    is.call(fun) &&
      drm_call_name(fun) %in% c("::", ":::") &&
      length(fun) >= 3L &&
      is.symbol(fun[[3L]])
  ) {
    return(as.character(fun[[3L]]))
  }
  NA_character_
}

evaluate_known_v <- function(expr, data, env) {
  if (is.null(expr)) {
    return(new_known_v(rep(0, nrow(data)), type = "none"))
  }
  value <- eval(expr, envir = data, enclos = env)
  if (is.matrix(value)) {
    if (nrow(value) != nrow(data) || ncol(value) != nrow(data)) {
      cli::cli_abort(
        "{.arg V} matrix must have one row and one column per observation."
      )
    }
    if (!is.numeric(value)) {
      cli::cli_abort("{.arg V} matrix must be numeric.")
    }
    if (is_diagonal_known_v(value)) {
      return(new_known_v(diag(value), type = "diagonal"))
    }
    return(new_known_v(value, type = "matrix"))
  }
  if (!is.numeric(value) || length(value) != nrow(data)) {
    cli::cli_abort(
      "{.arg V} must evaluate to a numeric vector of known sampling variances."
    )
  }
  new_known_v(as.numeric(value), type = "diagonal")
}

evaluate_biv_known_v <- function(expr, data, env) {
  n <- nrow(data)
  if (is.null(expr)) {
    return(new_known_v(rep(0, 2L * n), type = "none"))
  }
  value <- eval(expr, envir = data, enclos = env)
  if (!is.matrix(value) || nrow(value) != 2L * n || ncol(value) != 2L * n) {
    cli::cli_abort(c(
      "{.arg V} for bivariate {.fn meta_V} must evaluate to a {.code 2n} by {.code 2n} matrix.",
      "i" = "Use row-paired stacking: {.code y1[1], y2[1], y1[2], y2[2], ...}.",
      "i" = "For common bivariate meta-analysis, build this matrix with {.fn meta_vcov_bivariate}."
    ))
  }
  if (!is.numeric(value)) {
    cli::cli_abort("{.arg V} matrix must be numeric.")
  }
  new_known_v(value, type = "matrix")
}

known_v_complete <- function(V_known) {
  if (identical(V_known$type, "matrix")) {
    rep(TRUE, nrow(V_known$V))
  } else {
    is.finite(V_known$diag) & !is.na(V_known$diag)
  }
}

subset_biv_known_v <- function(V_known, keep, validate = TRUE) {
  if (!identical(V_known$type, "matrix")) {
    return(new_known_v(rep(0, 2L * sum(keep)), type = V_known$type))
  }
  pair_keep <- as.vector(rbind(keep, keep))
  out <- V_known$V[pair_keep, pair_keep, drop = FALSE]
  if (isTRUE(validate)) {
    validate_known_v_matrix(out)
  }
  new_known_v(out, type = "matrix")
}

subset_known_v <- function(V_known, keep, validate = TRUE) {
  if (identical(V_known$type, "matrix")) {
    out <- V_known$V[keep, keep, drop = FALSE]
    if (isTRUE(validate)) {
      validate_known_v_matrix(out)
    }
    return(new_known_v(out, type = "matrix"))
  }
  out <- V_known$diag[keep]
  if (isTRUE(validate)) {
    validate_known_v_diag(out)
  }
  new_known_v(out, type = V_known$type)
}

evaluate_likelihood_weights_arg <- function(weights_expr, data, env) {
  if (is.null(weights_expr)) {
    return(NULL)
  }
  value <- eval(weights_expr, envir = data, enclos = env)
  if (is.null(value)) {
    return(NULL)
  }
  if (!is.numeric(value) || is.matrix(value) || is.array(value)) {
    cli::cli_abort(c(
      "{.arg weights} must be a numeric vector.",
      "i" = "{.arg weights} are row log-likelihood multipliers, not known sampling variances or covariance matrices."
    ))
  }
  if (length(value) != nrow(data)) {
    cli::cli_abort(c(
      "{.arg weights} must have one value per row of {.arg data}.",
      "x" = "Received {length(value)} weight{?s} for {nrow(data)} data row{?s}."
    ))
  }
  as.numeric(value)
}

subset_likelihood_weights <- function(weights, keep, n_data, n_model) {
  if (is.null(weights)) {
    return(rep(1, n_model))
  }
  if (length(weights) != n_data) {
    cli::cli_abort(
      "Internal error: {.arg weights} length changed before row filtering."
    )
  }
  out <- weights[keep]
  bad <- !is.finite(out) | is.na(out)
  if (any(bad)) {
    cli::cli_abort(c(
      "{.arg weights} must be finite and non-missing for all modelled rows.",
      "x" = "After model-row filtering, {sum(bad)} weight value{?s} are missing or non-finite."
    ))
  }
  if (any(out < 0)) {
    cli::cli_abort(c(
      "{.arg weights} must be non-negative.",
      "x" = "After model-row filtering, {sum(out < 0)} weight value{?s} are negative."
    ))
  }
  if (!any(out > 0)) {
    cli::cli_abort(c(
      "{.arg weights} must include at least one positive modelled row.",
      "x" = "All modelled rows have weight zero."
    ))
  }
  out
}

drm_model_offset <- function(model_frame, dpar) {
  out <- stats::model.offset(model_frame)
  n <- nrow(model_frame)
  if (is.null(out)) {
    return(rep(0, n))
  }
  out <- as.numeric(out)
  if (length(out) != n || any(!is.finite(out))) {
    cli::cli_abort(c(
      "Offset terms must evaluate to one finite value per modelled row.",
      "x" = "The {.code {dpar}} formula contains a non-finite offset.",
      "i" = "For count exposure models, use {.code offset(log(exposure))} with positive finite exposure values."
    ))
  }
  out
}

check_weights_known_covariance <- function(spec) {
  if (!identical(spec$V_known_type, "matrix")) {
    return(invisible(spec))
  }
  if (is.null(spec$weights) || all(spec$weights == 1)) {
    return(invisible(spec))
  }
  cli::cli_abort(c(
    "{.arg weights} cannot currently be combined with a full known sampling covariance matrix.",
    "x" = "Full known covariance uses one joint multivariate likelihood block, not independent row contributions.",
    "i" = "Use {.code meta_V(V = V)} without {.arg weights}, or use diagonal known variances when row likelihood weighting is scientifically intended."
  ))
}

new_known_v <- function(value, type) {
  if (identical(type, "matrix")) {
    diag_value <- diag(value)
  } else {
    diag_value <- as.numeric(value)
  }
  structure(
    list(
      V = value,
      diag = diag_value,
      type = type
    ),
    class = "drm_known_v"
  )
}

validate_known_v_diag <- function(value) {
  if (any(!is.finite(value) | is.na(value))) {
    cli::cli_abort("{.arg V} must contain finite known sampling variances.")
  }
  if (any(value < 0)) {
    cli::cli_abort(
      "{.arg V} must contain non-negative known sampling variances."
    )
  }
  invisible(value)
}

validate_known_v_matrix <- function(value) {
  if (any(!is.finite(value) | is.na(value))) {
    cli::cli_abort("{.arg V} matrix must contain only finite values.")
  }
  # Scale-relative symmetry and PSD tolerances (issue #710.1): an absolute
  # threshold either spuriously rejects a valid large-scale V or admits a
  # genuinely indefinite small-scale V (e.g. standardized-effect variances near
  # 1e-6 with a negative eigenvalue of magnitude just below sqrt(eps)). Comparing
  # against the matrix magnitude gives a scale-invariant verdict before Omega
  # reaches the dense MVNORM Cholesky.
  tol <- sqrt(.Machine$double.eps)
  value_scale <- max(abs(value))
  # Scale the symmetry tolerance to the matrix magnitude, but never below the
  # absolute floor so an all-zero (or tiny) matrix still admits exact symmetry.
  sym_tol <- max(tol * value_scale, tol)
  if (max(abs(value - t(value))) > sym_tol) {
    cli::cli_abort("{.arg V} matrix must be symmetric.")
  }
  validate_known_v_diag(diag(value))
  ev <- eigen(
    (value + t(value)) / 2,
    symmetric = TRUE,
    only.values = TRUE
  )$values
  ev_scale <- max(abs(ev))
  # Reject a negative eigenvalue that is large relative to the spectral scale. A
  # pure relative bound (tol * max|ev|) catches small-scale indefiniteness
  # (variances near 1e-6 with a genuine negative eigenvalue) that an absolute
  # -sqrt(eps) bound admits, while still absorbing float rounding of a true zero
  # eigenvalue (rounding is O(max|ev| * eps) << tol * max|ev|). An all-zero matrix
  # has ev_scale == 0, giving neg_tol == 0 and min(ev) == 0, which passes.
  neg_tol <- tol * ev_scale
  if (min(ev) < -neg_tol) {
    cli::cli_abort("{.arg V} matrix must be positive semidefinite.")
  }
  invisible(value)
}

is_diagonal_known_v <- function(value) {
  off_diag <- value
  diag(off_diag) <- 0
  if (anyNA(off_diag)) {
    return(FALSE)
  }
  !any(abs(off_diag) > sqrt(.Machine$double.eps))
}

prepare_zero_one_beta_response <- function(y, response) {
  if (length(y) == 0L) {
    cli::cli_abort(
      "No complete observations remain after applying zero-one beta model missingness rules."
    )
  }
  if (!is.null(dim(y))) {
    cli::cli_abort(c(
      "{.fn zero_one_beta} requires a single continuous bounded response.",
      "x" = "Denominator syntax such as {.code cbind(successes, failures)} belongs to {.fn beta_binomial}."
    ))
  }
  if (!is.numeric(y) && !is.integer(y)) {
    cli::cli_abort(c(
      "Zero-one beta response values must be numeric.",
      "x" = "Response {.val {response}} has class {.val {class(y)}}."
    ))
  }
  if (!all(is.finite(y)) || any(y < 0) || any(y > 1)) {
    cli::cli_abort(c(
      "Zero-one beta models require response values in the closed interval [0, 1].",
      "x" = "The response {.val {response}} contains out-of-range or non-finite values after missing-row filtering."
    ))
  }
  if (!any(y > 0 & y < 1)) {
    cli::cli_abort(c(
      "Zero-one beta models require at least one interior response value.",
      "x" = "The response {.val {response}} contains only exact boundary values after missing-row filtering.",
      "i" = "Interior beta parameters {.code mu} and {.code sigma} need data with {.code 0 < y < 1}."
    ))
  }
  as.numeric(y)
}

prepare_betabinomial_response <- function(y, response) {
  if (length(y) == 0L) {
    cli::cli_abort(
      "No complete observations remain after applying beta-binomial model missingness rules."
    )
  }
  if (is.null(dim(y)) || ncol(y) != 2L) {
    cli::cli_abort(c(
      "{.fn beta_binomial} requires a two-column count response.",
      "i" = "Use {.code cbind(successes, failures)} on the left-hand side."
    ))
  }
  if (!is.numeric(y) && !is.integer(y)) {
    cli::cli_abort("Beta-binomial response counts must be numeric or integer.")
  }
  tolerance <- sqrt(.Machine$double.eps)
  if (!all(is.finite(y)) || any(y < 0) || any(abs(y - round(y)) > tolerance)) {
    cli::cli_abort(c(
      "Beta-binomial response counts must be finite non-negative integers.",
      "x" = "Response {.val {response}} contains negative, non-integer, or non-finite counts."
    ))
  }
  y_int <- round(y)
  trials <- rowSums(y_int)
  if (any(trials <= 0)) {
    cli::cli_abort(c(
      "Beta-binomial trials must be positive for every modelled row.",
      "x" = "Response {.val {response}} contains at least one row with zero total trials."
    ))
  }
  response_names <- colnames(y_int)
  if (is.null(response_names) || any(!nzchar(response_names))) {
    response_names <- c("successes", "failures")
  }
  list(
    successes = as.numeric(y_int[, 1L]),
    failures = as.numeric(y_int[, 2L]),
    trials = as.numeric(trials),
    success_name = response_names[[1L]],
    failure_name = response_names[[2L]]
  )
}

prepare_binomial_response <- function(y, response, has_weights = FALSE) {
  if (length(y) == 0L) {
    cli::cli_abort(
      "No complete observations remain after applying binomial model missingness rules."
    )
  }
  if (!is.null(dim(y))) {
    if (ncol(y) != 2L) {
      cli::cli_abort(c(
        "Binomial count responses require exactly two columns.",
        "i" = "Use {.code cbind(successes, failures)} on the left-hand side."
      ))
    }
    if (!is.numeric(y) && !is.integer(y)) {
      cli::cli_abort("Binomial response counts must be numeric or integer.")
    }
    tolerance <- sqrt(.Machine$double.eps)
    if (
      !all(is.finite(y)) ||
        any(y < 0) ||
        any(abs(y - round(y)) > tolerance)
    ) {
      cli::cli_abort(c(
        "Binomial response counts must be finite non-negative integers.",
        "x" = "Response {.val {response}} contains negative, non-integer, or non-finite counts."
      ))
    }
    y_int <- round(y)
    trials <- rowSums(y_int)
    if (any(trials <= 0)) {
      cli::cli_abort(c(
        "Binomial trials must be positive for every modelled row.",
        "x" = "Response {.val {response}} contains at least one row with zero total trials."
      ))
    }
    response_names <- colnames(y_int)
    if (is.null(response_names) || any(!nzchar(response_names))) {
      response_names <- c("successes", "failures")
    }
    return(list(
      successes = as.numeric(y_int[, 1L]),
      failures = as.numeric(y_int[, 2L]),
      trials = as.numeric(trials),
      success_name = response_names[[1L]],
      failure_name = response_names[[2L]],
      encoding = "cbind(successes, failures)"
    ))
  }

  if (is.factor(y)) {
    cli::cli_abort(c(
      "Binomial response values must be explicit 0/1 data, not a factor.",
      "x" = "Response {.val {response}} has class {.val {class(y)}}.",
      "i" = "Convert the event indicator yourself so the event level is unambiguous."
    ))
  }
  if (!is.numeric(y) && !is.integer(y) && !is.logical(y)) {
    cli::cli_abort(c(
      "Binomial response values must be logical or numeric 0/1 values.",
      "x" = "Response {.val {response}} has class {.val {class(y)}}."
    ))
  }
  y_num <- as.numeric(y)
  tolerance <- sqrt(.Machine$double.eps)
  if (!all(is.finite(y_num))) {
    cli::cli_abort(c(
      "Binomial response values must be finite.",
      "x" = "Response {.val {response}} contains non-finite values after missing-row filtering."
    ))
  }
  is_zero_one <- abs(y_num - 0) <= tolerance | abs(y_num - 1) <= tolerance
  if (!all(is_zero_one)) {
    if (isTRUE(has_weights) && all(y_num >= 0 & y_num <= 1)) {
      cli::cli_abort(c(
        "Proportion responses with {.arg weights} are not denominator syntax in {.pkg drmTMB}.",
        "x" = "The response {.val {response}} contains values between 0 and 1 that are not explicit 0/1 events.",
        "i" = "Use {.code cbind(successes, failures)} for binomial trial denominators; {.arg weights} remain row log-likelihood multipliers."
      ))
    }
    cli::cli_abort(c(
      "Single-column binomial responses must be 0/1 event indicators.",
      "x" = "Response {.val {response}} contains values other than 0 or 1.",
      "i" = "Use {.code cbind(successes, failures)} when each row summarizes multiple trials."
    ))
  }
  successes <- round(y_num)
  list(
    successes = successes,
    failures = 1 - successes,
    trials = rep(1, length(successes)),
    success_name = response,
    failure_name = paste0("1 - ", response),
    encoding = "0/1"
  )
}

prepare_ordinal_response <- function(y, response) {
  if (is.ordered(y)) {
    y_int <- as.integer(y)
    levels <- levels(y)
    if (anyNA(y_int)) {
      cli::cli_abort(
        "Ordinal response {.val {response}} contains missing levels after model-frame filtering."
      )
    }
    return(validate_ordinal_codes(y_int, levels = levels, response = response))
  }
  if (is.factor(y)) {
    cli::cli_abort(c(
      "Ordinal models require an ordered response.",
      "x" = "Response {.val {response}} is an unordered factor.",
      "i" = "Use {.code ordered({response})} or integer category scores 1, 2, ..., K."
    ))
  }
  if (!is.numeric(y) && !is.integer(y)) {
    cli::cli_abort(c(
      "Ordinal models require an ordered factor or integer category scores.",
      "x" = "Response {.val {response}} has class {.val {class(y)}}."
    ))
  }
  tolerance <- sqrt(.Machine$double.eps)
  if (!all(is.finite(y)) || any(y < 1) || any(abs(y - round(y)) > tolerance)) {
    cli::cli_abort(c(
      "Numeric ordinal responses must be finite integer category scores starting at 1.",
      "x" = "Response {.val {response}} contains non-integer, non-finite, or less-than-one values."
    ))
  }
  y_int <- as.integer(round(y))
  validate_ordinal_codes(
    y_int,
    levels = as.character(seq_len(max(y_int))),
    response = response
  )
}

validate_ordinal_codes <- function(y, levels, response) {
  n_categories <- length(levels)
  if (n_categories < 3L) {
    cli::cli_abort(c(
      "{.fn cumulative_logit} needs at least three ordered categories.",
      "x" = "Response {.val {response}} has {n_categories} categor{?y/ies} after filtering."
    ))
  }
  expected <- seq_len(n_categories)
  if (!all(y %in% expected)) {
    cli::cli_abort("Internal ordinal response coding is outside 1, ..., K.")
  }
  counts <- tabulate(y, nbins = n_categories)
  if (any(counts == 0L)) {
    empty <- levels[counts == 0L]
    cli::cli_abort(c(
      "Every ordinal category must appear at least once in the fitted data.",
      "x" = "Response {.val {response}} has empty categor{?y/ies}: {.val {empty}}.",
      "i" = "Drop unused ordered-factor levels or combine sparse categories before fitting."
    ))
  }
  list(
    y = y,
    levels = levels,
    n_categories = n_categories,
    response = response
  )
}

ordinal_mu_model_matrix <- function(terms, data) {
  X <- stats::model.matrix(terms, data)
  if ("(Intercept)" %in% colnames(X)) {
    X <- X[, colnames(X) != "(Intercept)", drop = FALSE]
  }
  X
}

# DerSimonian-Laird moment start for the residual (between-study) variance in a
# meta-analysis Gaussian fit (issue #710.3). Subtracting median(V) from an
# unweighted residual variance under- or over-shoots badly when the known
# sampling variances V_i are skewed. The variance-weighted DL estimator matches
# the meta model the fit targets and is robust to heterogeneous V. Falls back to
# the caller-supplied moment start when V carries no positive sampling variance
# (i.e. this is an ordinary Gaussian fit, not a meta-analysis) or when the DL
# formula is not well defined.
meta_dl_tau2_start <- function(resid, V, fallback) {
  V <- V[is.finite(V) & V > 0]
  if (length(V) < 2L) {
    return(fallback)
  }
  resid <- resid[is.finite(resid)]
  k <- length(resid)
  if (k < 2L || length(V) != k) {
    return(fallback)
  }
  w <- 1 / V
  sum_w <- sum(w)
  if (!is.finite(sum_w) || sum_w <= 0) {
    return(fallback)
  }
  mu_hat <- sum(w * resid) / sum_w
  Q <- sum(w * (resid - mu_hat)^2)
  denom <- sum_w - sum(w^2) / sum_w
  if (!is.finite(denom) || denom <= 0) {
    return(fallback)
  }
  tau2 <- (Q - (k - 1)) / denom
  if (!is.finite(tau2) || tau2 < 0) {
    return(fallback)
  }
  tau2
}

gaussian_ls_start <- function(
  y,
  X_mu,
  X_sigma,
  V_known = rep(0, length(y)),
  re_mu = empty_random_mu_structure(length(y)),
  re_sigma = empty_random_sigma_structure(length(y)),
  sd_mu = empty_sd_mu_structure(re_mu$n_re),
  re_mu_sigma = empty_mu_sigma_random_covariance(re_sigma$n_re),
  sd_phylo = empty_sd_phylo_structure(),
  re_cov_blocks = empty_labelled_covariance_block_registry(),
  observed_y = rep(TRUE, length(y))
) {
  observed_y <- as.logical(observed_y)
  if (length(observed_y) != length(y)) {
    cli::cli_abort(
      "Internal Gaussian start error: {.code observed_y} length does not match {.code y}."
    )
  }
  if (!any(observed_y)) {
    cli::cli_abort(
      "Internal Gaussian start error: at least one observed response is required."
    )
  }
  y_start <- y[observed_y]
  V_known_start <- V_known[observed_y]
  X_mu_start <- X_mu[observed_y, , drop = FALSE]
  if (inherits(X_mu, "sparseMatrix")) {
    beta_mu <- numeric(ncol(X_mu))
    names(beta_mu) <- colnames(X_mu)
    intercept <- match("(Intercept)", names(beta_mu), nomatch = 0L)
    if (intercept > 0L) {
      beta_mu[[intercept]] <- mean(y_start)
    }
  } else {
    lm_start <- stats::lm.fit(x = X_mu_start, y = y_start)
    beta_mu <- lm_start$coefficients
    beta_mu[is.na(beta_mu)] <- 0
  }

  resid <- y - as.vector(X_mu %*% beta_mu)
  resid[!observed_y] <- 0
  resid_observed <- resid[observed_y]
  resid_var <- stats::var(resid_observed)
  if (!is.finite(resid_var)) {
    resid_var <- 0
  }
  known_v0 <- stats::median(V_known_start, na.rm = TRUE)
  if (!is.finite(known_v0)) {
    known_v0 <- 0
  }
  y_scale <- stats::sd(y_start)
  if (!is.finite(y_scale) || y_scale <= 0) {
    y_scale <- 1
  }
  sigma_floor <- max(1e-4, 0.05 * y_scale)
  # For a pure meta-analysis (positive known V, no location random effects) use a
  # variance-weighted DerSimonian-Laird moment start for the between-study
  # variance (issue #710.3); otherwise keep the median(V) moment start.
  tau2_fallback <- max(resid_var - known_v0, sigma_floor^2)
  tau2_start <- if (re_mu$n_re == 0L && any(V_known_start > 0)) {
    max(
      meta_dl_tau2_start(resid_observed, V_known_start, tau2_fallback),
      sigma_floor^2
    )
  } else {
    tau2_fallback
  }
  sigma0 <- sqrt(tau2_start)
  if (!is.finite(sigma0) || sigma0 <= 0) {
    sigma0 <- stats::sd(y_start)
  }
  if (!is.finite(sigma0) || sigma0 <= 0) {
    sigma0 <- 1
  }

  beta_sigma <- gaussian_sigma_fixed_start(
    resid = resid,
    X_sigma = X_sigma,
    sigma0 = sigma0,
    sigma_floor = sigma_floor,
    observed_y = observed_y
  )

  mu_re_start <- gaussian_mu_re_start(resid, re_mu, y_scale)
  sigma_re_start <- gaussian_sigma_re_start(re_sigma)
  re_cov_start <- covariance_block_re_start(re_cov_blocks, y_scale)
  beta_sd_mu <- c(
    if (sd_mu$n_models > 0L) {
      gaussian_sd_mu_start(mu_re_start, sd_mu)
    },
    gaussian_sd_phylo_start(y_scale, sd_phylo)
  )
  if (length(beta_sd_mu) == 0L) {
    beta_sd_mu <- 0
  }

  list(
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    beta_sd_mu = beta_sd_mu,
    u_mu = mu_re_start$u_mu,
    log_sd_mu = mu_re_start$log_sd_mu,
    eta_cor_mu = mu_re_start$eta_cor_mu,
    eta_cor_mu_sigma = rep(0, max(1L, re_mu_sigma$n_cors)),
    eta_cor_sigma = sigma_re_start$eta_cor_sigma,
    u_sigma = sigma_re_start$u_sigma,
    log_sd_sigma = sigma_re_start$log_sd_sigma,
    u_re_cov = re_cov_start$u_re_cov,
    log_sd_re_cov = re_cov_start$log_sd_re_cov,
    theta_re_cov = re_cov_start$theta_re_cov
  )
}

gaussian_sigma_fixed_start <- function(
  resid,
  X_sigma,
  sigma0,
  sigma_floor,
  observed_y
) {
  beta_sigma <- numeric(ncol(X_sigma))
  names(beta_sigma) <- colnames(X_sigma)
  beta_sigma[[1L]] <- log(sigma0)
  if (ncol(X_sigma) <= 1L || sum(observed_y) <= ncol(X_sigma)) {
    return(beta_sigma)
  }

  resid_observed <- resid[observed_y]
  X_observed <- as.matrix(X_sigma[observed_y, , drop = FALSE])
  eta_sigma <- log(pmax(abs(resid_observed), sigma_floor)) +
    0.5 * log(pi / 2)
  candidate <- tryCatch(
    stats::lm.fit(x = X_observed, y = eta_sigma)$coefficients,
    error = function(e) NULL
  )
  if (is.null(candidate) || length(candidate) != ncol(X_sigma)) {
    return(beta_sigma)
  }
  candidate[is.na(candidate)] <- 0
  if (!all(is.finite(candidate))) {
    return(beta_sigma)
  }
  eta_candidate <- as.vector(X_observed %*% candidate)
  if (!all(is.finite(eta_candidate))) {
    return(beta_sigma)
  }
  # Shrink an over-large scale-slope start toward zero rather than discarding all
  # slopes: a legitimately strong scale-heterogeneity model keeps a usable,
  # bounded slope start (direction preserved) instead of a flat intercept-only
  # point. Only the slopes are shrunk; the intercept (baseline log-sigma) is kept.
  slopes <- candidate[-1L]
  eta_slopes <- as.vector(X_observed[, -1L, drop = FALSE] %*% slopes)
  spread <- if (length(eta_slopes) > 0L) diff(range(eta_slopes)) else 0
  max_slope <- if (length(slopes) > 0L) max(abs(slopes)) else 0
  shrink <- 1
  if (is.finite(spread) && spread > 8) {
    shrink <- min(shrink, 8 / spread)
  }
  if (is.finite(max_slope) && max_slope > 5) {
    shrink <- min(shrink, 5 / max_slope)
  }
  candidate[-1L] <- slopes * shrink
  if (!all(is.finite(candidate))) {
    return(beta_sigma)
  }
  names(candidate) <- colnames(X_sigma)
  candidate
}

gaussian_ls_dummy_start <- function(
  phylo_mu = empty_phylo_mu_structure(),
  y = NULL
) {
  phylo_start <- gaussian_phylo_start(y, phylo_mu)
  # eta_cor_mu_sigma / eta_cor_sigma are supplied by gaussian_ls_start(); do not
  # re-declare them here or spec$start carries duplicated names (issue #713.1).
  list(
    beta_nu = 0,
    beta_zi = 0,
    theta_ord = 0,
    beta_mu1 = 0,
    beta_mu2 = 0,
    beta_sigma1 = 0,
    beta_sigma2 = 0,
    beta_rho12 = 0,
    u_phylo = phylo_start$u_phylo,
    log_sd_phylo = phylo_start$log_sd_phylo,
    eta_cor_phylo = 0
  )
}

student_ls_start <- function(
  y,
  X_mu,
  X_sigma,
  X_nu,
  re_mu = empty_random_mu_structure(length(y)),
  phylo_mu = empty_phylo_mu_structure()
) {
  gaussian_start <- gaussian_ls_start(y, X_mu, X_sigma, re_mu = re_mu)
  eta_mu <- as.vector(X_mu %*% gaussian_start$beta_mu)
  phylo_start <- gaussian_phylo_start(y - eta_mu, phylo_mu)
  c(
    list(
      beta_mu = gaussian_start$beta_mu,
      beta_sigma = gaussian_start$beta_sigma,
      beta_nu = student_nu_start(y, X_mu, gaussian_start$beta_mu, X_nu)
    ),
    list(
      beta_zi = 0,
      theta_ord = 0,
      beta_sd_mu = 0,
      u_mu = gaussian_start$u_mu,
      log_sd_mu = gaussian_start$log_sd_mu,
      eta_cor_mu = gaussian_start$eta_cor_mu,
      eta_cor_mu_sigma = 0,
      eta_cor_sigma = 0,
      u_sigma = 0,
      log_sd_sigma = 0,
      beta_mu1 = 0,
      beta_mu2 = 0,
      beta_sigma1 = 0,
      beta_sigma2 = 0,
      beta_rho12 = 0,
      u_phylo = phylo_start$u_phylo,
      log_sd_phylo = phylo_start$log_sd_phylo,
      eta_cor_phylo = 0
    )
  )
}

student_nu_start <- function(y, X_mu, beta_mu, X_nu) {
  resid <- y - as.vector(X_mu %*% beta_mu)
  kurtosis <- mean((resid - mean(resid))^4) / stats::var(resid)^2
  nu0 <- if (is.finite(kurtosis) && kurtosis > 3.1) {
    4 + 6 / (kurtosis - 3)
  } else {
    10
  }
  nu0 <- max(min(nu0, 30), 3)
  beta_nu <- numeric(ncol(X_nu))
  beta_nu[[1L]] <- log(nu0 - 2)
  beta_nu
}

skew_normal_ls_start <- function(y, X_mu, X_sigma, X_nu) {
  gaussian_start <- gaussian_ls_start(y, X_mu, X_sigma)
  c(
    list(
      beta_mu = gaussian_start$beta_mu,
      beta_sigma = gaussian_start$beta_sigma,
      beta_nu = skew_normal_nu_start(
        y,
        X_mu,
        gaussian_start$beta_mu,
        X_sigma,
        gaussian_start$beta_sigma,
        X_nu
      )
    ),
    list(
      beta_zi = 0,
      theta_ord = 0,
      beta_sd_mu = 0,
      u_mu = 0,
      log_sd_mu = 0,
      eta_cor_mu = 0,
      eta_cor_mu_sigma = 0,
      eta_cor_sigma = 0,
      u_sigma = 0,
      log_sd_sigma = 0,
      beta_mu1 = 0,
      beta_mu2 = 0,
      beta_sigma1 = 0,
      beta_sigma2 = 0,
      beta_rho12 = 0,
      u_phylo = 0,
      log_sd_phylo = 0,
      eta_cor_phylo = 0
    )
  )
}

skew_normal_nu_start <- function(y, X_mu, beta_mu, X_sigma, beta_sigma, X_nu) {
  beta_nu <- numeric(ncol(X_nu))
  if (length(beta_nu) == 0L) {
    return(beta_nu)
  }
  mu <- as.vector(X_mu %*% beta_mu)
  sigma <- exp(as.vector(X_sigma %*% beta_sigma))
  standardized <- (y - mu) / sigma
  skewness <- mean((standardized - mean(standardized))^3) /
    stats::sd(standardized)^3
  if (!is.finite(skewness)) {
    skewness <- 0
  }
  start_sign <- if (skewness < 0) -1 else 1
  beta_nu[[1L]] <- start_sign * min(5, max(0.1, 2 * abs(skewness)))
  beta_nu
}

lognormal_ls_start <- function(
  y,
  X_mu,
  X_sigma,
  re_mu = empty_random_mu_structure(length(y))
) {
  gaussian_start <- gaussian_ls_start(log(y), X_mu, X_sigma, re_mu = re_mu)
  c(
    list(
      beta_mu = gaussian_start$beta_mu,
      beta_sigma = gaussian_start$beta_sigma
    ),
    list(
      beta_nu = 0,
      beta_zi = 0,
      theta_ord = 0,
      beta_sd_mu = 0,
      u_mu = gaussian_start$u_mu,
      log_sd_mu = gaussian_start$log_sd_mu,
      eta_cor_mu = gaussian_start$eta_cor_mu,
      eta_cor_mu_sigma = 0,
      eta_cor_sigma = 0,
      u_sigma = 0,
      log_sd_sigma = 0,
      beta_mu1 = 0,
      beta_mu2 = 0,
      beta_sigma1 = 0,
      beta_sigma2 = 0,
      beta_rho12 = 0,
      u_phylo = 0,
      log_sd_phylo = 0,
      eta_cor_phylo = 0
    )
  )
}

lognormal_ls_map <- function(
  re_mu = empty_random_mu_structure(1L),
  phylo_mu = empty_phylo_mu_structure()
) {
  out <- gaussian_ls_map(re_mu = re_mu, phylo_mu = phylo_mu)
  out$beta_nu <- factor(NA)
  out
}

gamma_ls_map <- function(
  re_mu = empty_random_mu_structure(1L),
  phylo_mu = empty_phylo_mu_structure()
) {
  lognormal_ls_map(re_mu = re_mu, phylo_mu = phylo_mu)
}

beta_ls_start <- function(
  y,
  X_mu,
  X_sigma,
  re_mu = empty_random_mu_structure(length(y)),
  phylo_mu = empty_phylo_mu_structure()
) {
  beta_mu <- tryCatch(
    suppressWarnings(
      stats::glm.fit(
        X_mu,
        y,
        family = stats::quasibinomial(link = "logit")
      )$coefficients
    ),
    error = function(e) rep(0, ncol(X_mu))
  )
  if (length(beta_mu) != ncol(X_mu) || any(!is.finite(beta_mu))) {
    beta_mu <- rep(0, ncol(X_mu))
    beta_mu[[1L]] <- stats::qlogis(min(max(mean(y), 1e-4), 1 - 1e-4))
  }
  eta_mu <- as.vector(X_mu %*% beta_mu)
  mu <- stats::plogis(eta_mu)
  ratio <- mean((y - mu)^2 / pmax(mu * (1 - mu), .Machine$double.eps))
  if (!is.finite(ratio) || ratio <= 0) {
    ratio <- 0.2
  }
  ratio <- min(max(ratio, 1e-4), 0.95)
  sigma0 <- sqrt(ratio / (1 - ratio))
  beta_sigma <- rep(0, ncol(X_sigma))
  beta_sigma[[1L]] <- log(max(sigma0, 1e-4))
  link_y <- stats::qlogis(pmin(pmax(y, 1e-4), 1 - 1e-4))
  y_scale <- stats::sd(link_y)
  if (!is.finite(y_scale) || y_scale <= 0) {
    y_scale <- 1
  }
  mu_re_start <- beta_mu_re_start(link_y - eta_mu, re_mu, y_scale)
  phylo_start <- gaussian_phylo_start(link_y - eta_mu, phylo_mu)
  c(
    list(
      beta_mu = beta_mu,
      beta_sigma = beta_sigma
    ),
    list(
      beta_nu = 0,
      beta_zi = 0,
      theta_ord = 0,
      beta_sd_mu = 0,
      u_mu = mu_re_start$u_mu,
      log_sd_mu = mu_re_start$log_sd_mu,
      eta_cor_mu = mu_re_start$eta_cor_mu,
      eta_cor_mu_sigma = 0,
      eta_cor_sigma = 0,
      u_sigma = 0,
      log_sd_sigma = 0,
      beta_mu1 = 0,
      beta_mu2 = 0,
      beta_sigma1 = 0,
      beta_sigma2 = 0,
      beta_rho12 = 0,
      u_phylo = phylo_start$u_phylo,
      log_sd_phylo = phylo_start$log_sd_phylo,
      eta_cor_phylo = 0
    )
  )
}

beta_mu_re_start <- function(resid, re_mu, y_scale) {
  start <- gaussian_mu_re_start(resid, re_mu, y_scale)
  if (re_mu$n_re == 0L) {
    return(start)
  }

  u_mu <- numeric(re_mu$n_re)
  for (k in seq_len(re_mu$n_terms)) {
    design_value <- re_mu$value[, k]
    group_index <- re_mu$index[, k]
    moment <- stats::aggregate(
      cbind(num = design_value * resid, den = design_value^2),
      by = list(group = group_index),
      FUN = sum
    )
    group_est <- ifelse(
      moment$den > sqrt(.Machine$double.eps),
      moment$num / moment$den,
      0
    )
    sd_current <- exp(start$log_sd_mu[[k]])
    if (!is.finite(sd_current) || sd_current <= 0) {
      sd_current <- 1
    }
    u_start <- group_est / sd_current
    u_start[!is.finite(u_start)] <- 0
    u_start <- pmax(pmin(u_start, 2), -2)
    u_mu[as.integer(moment$group)] <- u_start
  }
  start$u_mu <- u_mu
  start
}

beta_ls_map <- function(
  re_mu = empty_random_mu_structure(1L),
  phylo_mu = empty_phylo_mu_structure()
) {
  lognormal_ls_map(re_mu = re_mu, phylo_mu = phylo_mu)
}

beta_binomial_start <- function(
  successes,
  failures,
  X_mu,
  X_sigma,
  re_mu = empty_random_mu_structure(length(successes))
) {
  trials <- successes + failures
  beta_mu <- tryCatch(
    suppressWarnings(
      stats::glm.fit(
        X_mu,
        cbind(successes, failures),
        family = stats::quasibinomial(link = "logit")
      )$coefficients
    ),
    error = function(e) rep(0, ncol(X_mu))
  )
  if (length(beta_mu) != ncol(X_mu) || any(!is.finite(beta_mu))) {
    prop <- (successes + 0.5) / (trials + 1)
    beta_mu <- rep(0, ncol(X_mu))
    beta_mu[[1L]] <- stats::qlogis(min(max(mean(prop), 1e-4), 1 - 1e-4))
  }

  beta_sigma <- rep(0, ncol(X_sigma))
  names(beta_mu) <- colnames(X_mu)
  names(beta_sigma) <- colnames(X_sigma)
  beta_sigma[[1L]] <- log(0.35)
  eta_mu <- as.vector(X_mu %*% beta_mu)
  link_y <- stats::qlogis((successes + 0.5) / (trials + 1))
  y_scale <- stats::sd(link_y)
  if (!is.finite(y_scale) || y_scale <= 0) {
    y_scale <- 1
  }
  mu_re_start <- beta_mu_re_start(link_y - eta_mu, re_mu, y_scale)

  c(
    list(
      beta_mu = beta_mu,
      beta_sigma = beta_sigma
    ),
    list(
      beta_nu = 0,
      beta_zi = 0,
      theta_ord = 0,
      beta_sd_mu = 0,
      u_mu = mu_re_start$u_mu,
      log_sd_mu = mu_re_start$log_sd_mu,
      eta_cor_mu = mu_re_start$eta_cor_mu,
      eta_cor_mu_sigma = 0,
      eta_cor_sigma = 0,
      u_sigma = 0,
      log_sd_sigma = 0,
      beta_mu1 = 0,
      beta_mu2 = 0,
      beta_sigma1 = 0,
      beta_sigma2 = 0,
      beta_rho12 = 0,
      u_phylo = 0,
      log_sd_phylo = 0,
      eta_cor_phylo = 0
    )
  )
}

beta_binomial_map <- function(
  re_mu = empty_random_mu_structure(1L)
) {
  beta_ls_map(re_mu = re_mu)
}

binomial_start <- function(
  successes,
  failures,
  X_mu,
  offset_mu = rep(0, length(successes))
) {
  beta_mu <- tryCatch(
    suppressWarnings(
      stats::glm.fit(
        X_mu,
        cbind(successes, failures),
        family = stats::binomial(link = "logit"),
        offset = offset_mu
      )$coefficients
    ),
    error = function(e) rep(0, ncol(X_mu))
  )
  if (length(beta_mu) != ncol(X_mu) || any(!is.finite(beta_mu))) {
    trials <- successes + failures
    prop <- (successes + 0.5) / (trials + 1)
    beta_mu <- rep(0, ncol(X_mu))
    beta_mu[[1L]] <-
      stats::qlogis(min(max(mean(prop), 1e-4), 1 - 1e-4)) -
      mean(offset_mu)
  }
  names(beta_mu) <- colnames(X_mu)
  c(
    list(beta_mu = beta_mu),
    list(
      beta_sigma = 0,
      beta_nu = 0,
      beta_zi = 0,
      theta_ord = 0,
      beta_sd_mu = 0,
      u_mu = 0,
      log_sd_mu = 0,
      eta_cor_mu = 0,
      eta_cor_mu_sigma = 0,
      eta_cor_sigma = 0,
      u_sigma = 0,
      log_sd_sigma = 0,
      beta_mu1 = 0,
      beta_mu2 = 0,
      beta_sigma1 = 0,
      beta_sigma2 = 0,
      beta_rho12 = 0,
      u_phylo = 0,
      log_sd_phylo = 0,
      eta_cor_phylo = 0
    )
  )
}

binomial_map <- function() {
  poisson_map(
    re_mu = empty_random_mu_structure(1L),
    phylo_mu = empty_phylo_mu_structure()
  )
}

zero_one_beta_start <- function(y, X_mu, X_sigma, X_zoi, X_coi) {
  interior <- y > 0 & y < 1
  if (sum(interior) >= max(2L, ncol(X_mu), ncol(X_sigma))) {
    beta_start <- beta_ls_start(
      y[interior],
      X_mu[interior, , drop = FALSE],
      X_sigma[interior, , drop = FALSE]
    )
    beta_mu <- beta_start$beta_mu
    beta_sigma <- beta_start$beta_sigma
  } else {
    beta_mu <- numeric(ncol(X_mu))
    beta_sigma <- numeric(ncol(X_sigma))
    beta_mu[[1L]] <- stats::qlogis(
      min(max(mean(y[interior]), 1e-4), 1 - 1e-4)
    )
    beta_sigma[[1L]] <- log(0.5)
  }
  names(beta_mu) <- colnames(X_mu)
  names(beta_sigma) <- colnames(X_sigma)

  boundary <- y == 0 | y == 1
  zoi0 <- min(max(mean(boundary), 1e-3), 0.95)
  coi0 <- if (any(boundary)) {
    min(max(mean(y[boundary] == 1), 1e-3), 1 - 1e-3)
  } else {
    0.5
  }
  beta_zoi <- numeric(ncol(X_zoi))
  beta_coi <- numeric(ncol(X_coi))
  names(beta_zoi) <- colnames(X_zoi)
  names(beta_coi) <- colnames(X_coi)
  beta_zoi[[1L]] <- stats::qlogis(zoi0)
  beta_coi[[1L]] <- stats::qlogis(coi0)

  c(
    list(
      beta_mu = beta_mu,
      beta_sigma = beta_sigma,
      beta_zoi = beta_zoi,
      beta_coi = beta_coi
    ),
    list(
      beta_nu = 0,
      beta_zi = 0,
      theta_ord = 0,
      beta_sd_mu = 0,
      u_mu = 0,
      log_sd_mu = 0,
      eta_cor_mu = 0,
      eta_cor_mu_sigma = 0,
      eta_cor_sigma = 0,
      u_sigma = 0,
      log_sd_sigma = 0,
      beta_mu1 = 0,
      beta_mu2 = 0,
      beta_sigma1 = 0,
      beta_sigma2 = 0,
      beta_rho12 = 0,
      u_phylo = 0,
      log_sd_phylo = 0,
      eta_cor_phylo = 0
    )
  )
}

zero_one_beta_map <- function() {
  beta_ls_map(re_mu = empty_random_mu_structure(1L))
}

poisson_start <- function(
  y,
  X_mu,
  offset_mu = rep(0, length(y)),
  re_mu = empty_random_mu_structure(length(y)),
  phylo_mu = empty_phylo_mu_structure()
) {
  beta_mu <- tryCatch(
    suppressWarnings(
      stats::glm.fit(
        X_mu,
        y,
        family = stats::poisson(),
        offset = offset_mu
      )$coefficients
    ),
    error = function(e) rep(0, ncol(X_mu))
  )
  if (length(beta_mu) != ncol(X_mu) || any(!is.finite(beta_mu))) {
    beta_mu <- rep(0, ncol(X_mu))
    beta_mu[[1L]] <- log(max(mean(y), 1e-4)) - mean(offset_mu)
  }
  mu_re_start <- poisson_mu_re_start(re_mu)
  phylo_start <- gaussian_phylo_start(y, phylo_mu)
  c(
    list(beta_mu = beta_mu),
    list(
      beta_sigma = 0,
      beta_nu = 0,
      beta_zi = 0,
      theta_ord = 0,
      beta_sd_mu = 0,
      u_mu = mu_re_start$u_mu,
      log_sd_mu = mu_re_start$log_sd_mu,
      eta_cor_mu = mu_re_start$eta_cor_mu,
      eta_cor_mu_sigma = 0,
      eta_cor_sigma = 0,
      u_sigma = 0,
      log_sd_sigma = 0,
      beta_mu1 = 0,
      beta_mu2 = 0,
      beta_sigma1 = 0,
      beta_sigma2 = 0,
      beta_rho12 = 0,
      u_phylo = phylo_start$u_phylo,
      log_sd_phylo = phylo_start$log_sd_phylo,
      eta_cor_phylo = 0
    )
  )
}

poisson_mu_re_start <- function(re_mu) {
  if (re_mu$n_re == 0L) {
    return(list(u_mu = 0, log_sd_mu = 0, eta_cor_mu = 0))
  }
  list(
    u_mu = rep(0, re_mu$n_re),
    log_sd_mu = rep(log(0.35), re_mu$n_terms),
    eta_cor_mu = rep(0, max(1L, re_mu$n_cors))
  )
}

poisson_map <- function(
  re_mu = empty_random_mu_structure(1L),
  phylo_mu = empty_phylo_mu_structure()
) {
  out <- gaussian_ls_map(re_mu = re_mu, phylo_mu = phylo_mu)
  out$beta_sigma <- factor(NA)
  out
}

zi_poisson_start <- function(
  y,
  X_mu,
  X_zi,
  offset_mu = rep(0, length(y)),
  phylo_mu = empty_phylo_mu_structure()
) {
  poisson <- poisson_start(y, X_mu, offset_mu, phylo_mu = phylo_mu)
  beta_mu <- poisson$beta_mu
  mu <- exp(offset_mu + as.vector(X_mu %*% beta_mu))
  observed_zero <- mean(y == 0)
  poisson_zero <- mean(exp(-mu))
  zi0 <- if (
    is.finite(observed_zero) && is.finite(poisson_zero) && poisson_zero < 0.99
  ) {
    (observed_zero - poisson_zero) / (1 - poisson_zero)
  } else {
    0.1
  }
  zi0 <- min(max(zi0, 0.02), 0.8)
  beta_zi <- numeric(ncol(X_zi))
  beta_zi[[1L]] <- stats::qlogis(zi0)
  c(
    list(
      beta_mu = beta_mu,
      beta_zi = beta_zi
    ),
    list(
      beta_sigma = 0,
      beta_nu = 0,
      theta_ord = 0,
      beta_sd_mu = 0,
      u_mu = 0,
      log_sd_mu = 0,
      eta_cor_mu = 0,
      eta_cor_mu_sigma = 0,
      eta_cor_sigma = 0,
      u_sigma = 0,
      log_sd_sigma = 0,
      beta_mu1 = 0,
      beta_mu2 = 0,
      beta_sigma1 = 0,
      beta_sigma2 = 0,
      beta_rho12 = 0,
      u_phylo = poisson$u_phylo,
      log_sd_phylo = poisson$log_sd_phylo,
      eta_cor_phylo = 0
    )
  )
}

zi_poisson_map <- function(phylo_mu = empty_phylo_mu_structure()) {
  out <- poisson_map(phylo_mu = phylo_mu)
  out$beta_zi <- NULL
  out
}

nbinom2_start <- function(
  y,
  X_mu,
  X_sigma,
  offset_mu = rep(0, length(y)),
  re_mu = empty_random_mu_structure(length(y)),
  re_sigma = empty_random_sigma_structure(length(y)),
  phylo_mu = empty_phylo_mu_structure()
) {
  poisson <- poisson_start(
    y,
    X_mu,
    offset_mu,
    re_mu = re_mu,
    phylo_mu = phylo_mu
  )
  beta_mu <- poisson$beta_mu
  mu <- exp(offset_mu + as.vector(X_mu %*% beta_mu))
  moment_sigma2 <- stats::var(y) - mean(mu)
  mean_mu2 <- mean(mu^2)
  sigma0 <- if (
    is.finite(moment_sigma2) && is.finite(mean_mu2) && mean_mu2 > 0
  ) {
    sqrt(max(moment_sigma2 / mean_mu2, 1e-4))
  } else {
    0.3
  }
  sigma0 <- min(max(sigma0, 0.05), 2)
  beta_sigma <- numeric(ncol(X_sigma))
  beta_sigma[[1L]] <- log(sigma0)
  sigma_re_start <- gaussian_sigma_re_start(re_sigma)
  c(
    list(
      beta_mu = beta_mu,
      beta_sigma = beta_sigma
    ),
    list(
      beta_nu = 0,
      beta_zi = 0,
      theta_ord = 0,
      beta_sd_mu = 0,
      u_mu = poisson$u_mu,
      log_sd_mu = poisson$log_sd_mu,
      eta_cor_mu = poisson$eta_cor_mu,
      eta_cor_mu_sigma = 0,
      eta_cor_sigma = sigma_re_start$eta_cor_sigma,
      u_sigma = sigma_re_start$u_sigma,
      log_sd_sigma = sigma_re_start$log_sd_sigma,
      beta_mu1 = 0,
      beta_mu2 = 0,
      beta_sigma1 = 0,
      beta_sigma2 = 0,
      beta_rho12 = 0,
      u_phylo = poisson$u_phylo,
      log_sd_phylo = poisson$log_sd_phylo,
      eta_cor_phylo = 0
    )
  )
}

nbinom2_map <- function(
  re_mu = empty_random_mu_structure(1L),
  phylo_mu = empty_phylo_mu_structure(),
  re_sigma = empty_random_sigma_structure(1L)
) {
  out <- gaussian_ls_map(
    re_mu = re_mu,
    re_sigma = re_sigma,
    phylo_mu = phylo_mu
  )
  if (re_mu$n_re > 0L) {
    out$u_mu <- NULL
    out$log_sd_mu <- NULL
  }
  if (re_mu$n_cors > 0L) {
    out$eta_cor_mu <- NULL
  }
  if (re_sigma$n_re > 0L) {
    out$u_sigma <- NULL
    out$log_sd_sigma <- NULL
  }
  out
}

# Populate start values for the scoped second structured location field. The map
# is handled globally by `add_covariance_probe_parameter`; here we only supply
# non-trivial starts (an intercept-only q = 1 GMRF field) when it is active.
add_structured_mu2_parameters <- function(spec, phylo_mu2, y) {
  if (!isTRUE(phylo_mu2$has)) {
    return(spec)
  }
  phylo2_start <- gaussian_phylo_start(y, phylo_mu2)
  spec$start$u_phylo2 <- phylo2_start$u_phylo
  spec$start$log_sd_phylo2 <- phylo2_start$log_sd_phylo
  spec
}

truncated_nbinom2_start <- function(
  y,
  X_mu,
  X_sigma,
  re_mu = empty_random_mu_structure(length(y))
) {
  nb <- nbinom2_start(y, X_mu, X_sigma, re_mu = re_mu)
  mu <- exp(as.vector(X_mu %*% nb$beta_mu))
  sigma <- exp(as.vector(X_sigma %*% nb$beta_sigma))
  p0 <- stats::dnbinom(0, size = 1 / sigma^2, mu = mu)
  q <- pmin(pmax(1 - p0, 1e-6), 1)
  nb$beta_mu[[1L]] <- nb$beta_mu[[1L]] + log(mean(q))
  nb
}

truncated_nbinom2_map <- function(
  re_mu = empty_random_mu_structure(1L)
) {
  nbinom2_map(re_mu = re_mu)
}

hurdle_nbinom2_start <- function(
  y,
  X_mu,
  X_sigma,
  X_hu,
  phylo_mu = empty_phylo_mu_structure()
) {
  nb <- truncated_nbinom2_start(
    y[y > 0],
    X_mu[y > 0, , drop = FALSE],
    X_sigma[y > 0, , drop = FALSE]
  )
  phylo_start <- gaussian_phylo_start(as.numeric(y == 0), phylo_mu)
  hu0 <- min(max(mean(y == 0), 0.02), 0.8)
  beta_hu <- numeric(ncol(X_hu))
  beta_hu[[1L]] <- stats::qlogis(hu0)
  nb$beta_zi <- beta_hu
  nb$u_phylo <- phylo_start$u_phylo
  nb$log_sd_phylo <- phylo_start$log_sd_phylo
  nb
}

hurdle_nbinom2_map <- function(
  phylo_mu = empty_phylo_mu_structure()
) {
  out <- nbinom2_map(phylo_mu = phylo_mu)
  out$beta_zi <- NULL
  out
}

zi_nbinom2_start <- function(
  y,
  X_mu,
  X_sigma,
  X_zi,
  offset_mu = rep(0, length(y)),
  phylo_mu = empty_phylo_mu_structure()
) {
  nb <- nbinom2_start(y, X_mu, X_sigma, offset_mu, phylo_mu = phylo_mu)
  beta_mu <- nb$beta_mu
  beta_sigma <- nb$beta_sigma
  mu <- exp(offset_mu + as.vector(X_mu %*% beta_mu))
  sigma <- exp(as.vector(X_sigma %*% beta_sigma))
  observed_zero <- mean(y == 0)
  nb_zero <- mean(stats::dnbinom(0, size = 1 / sigma^2, mu = mu))
  zi0 <- if (is.finite(observed_zero) && is.finite(nb_zero) && nb_zero < 0.99) {
    (observed_zero - nb_zero) / (1 - nb_zero)
  } else {
    0.1
  }
  zi0 <- min(max(zi0, 0.02), 0.8)
  beta_zi <- numeric(ncol(X_zi))
  beta_zi[[1L]] <- stats::qlogis(zi0)
  nb$beta_zi <- beta_zi
  nb
}

zi_nbinom2_map <- function(phylo_mu = empty_phylo_mu_structure()) {
  out <- nbinom2_map(phylo_mu = phylo_mu)
  out$beta_zi <- NULL
  out
}

gamma_ls_start <- function(
  y,
  X_mu,
  X_sigma,
  re_mu = empty_random_mu_structure(length(y)),
  phylo_mu = empty_phylo_mu_structure()
) {
  beta_mu <- tryCatch(
    stats::lm.fit(X_mu, log(y))$coefficients,
    error = function(e) rep(0, ncol(X_mu))
  )
  beta_mu[!is.finite(beta_mu)] <- 0
  eta_mu <- as.vector(X_mu %*% beta_mu)
  mu <- exp(eta_mu)
  cv0 <- stats::sd((y - mu) / mu)
  if (!is.finite(cv0) || cv0 <= 0) {
    cv0 <- 0.5
  }
  y_scale <- stats::sd(log(y))
  if (!is.finite(y_scale) || y_scale <= 0) {
    y_scale <- 1
  }
  mu_re_start <- gaussian_mu_re_start(log(y) - eta_mu, re_mu, y_scale)
  phylo_start <- gaussian_phylo_start(log(y) - eta_mu, phylo_mu)
  beta_sigma <- rep(0, ncol(X_sigma))
  beta_sigma[[1L]] <- log(max(cv0, 1e-3))
  c(
    list(
      beta_mu = beta_mu,
      beta_sigma = beta_sigma
    ),
    list(
      beta_nu = 0,
      beta_zi = 0,
      theta_ord = 0,
      beta_sd_mu = 0,
      u_mu = mu_re_start$u_mu,
      log_sd_mu = mu_re_start$log_sd_mu,
      eta_cor_mu = mu_re_start$eta_cor_mu,
      eta_cor_mu_sigma = 0,
      eta_cor_sigma = 0,
      u_sigma = 0,
      log_sd_sigma = 0,
      beta_mu1 = 0,
      beta_mu2 = 0,
      beta_sigma1 = 0,
      beta_sigma2 = 0,
      beta_rho12 = 0,
      u_phylo = phylo_start$u_phylo,
      log_sd_phylo = phylo_start$log_sd_phylo,
      eta_cor_phylo = 0
    )
  )
}

tweedie_ls_start <- function(y, X_mu, X_sigma, X_nu) {
  y_positive <- y[y > 0]
  zero_floor <- if (length(y_positive) > 0L) {
    max(min(y_positive) * 0.5, .Machine$double.eps)
  } else {
    0.1
  }
  log_y <- log(pmax(y, zero_floor))
  beta_mu <- tryCatch(
    stats::lm.fit(X_mu, log_y)$coefficients,
    error = function(e) rep(0, ncol(X_mu))
  )
  beta_mu[!is.finite(beta_mu)] <- 0
  eta_mu <- as.vector(X_mu %*% beta_mu)
  mu <- exp(eta_mu)
  nu0 <- 1.5
  phi0 <- stats::var(y) / mean(pmax(mu, .Machine$double.eps)^nu0)
  if (!is.finite(phi0) || phi0 <= 0) {
    phi0 <- 0.5
  }
  sigma0 <- sqrt(min(max(phi0, 1e-4), 9))
  beta_sigma <- numeric(ncol(X_sigma))
  beta_sigma[[1L]] <- log(max(sigma0, 1e-4))
  beta_nu <- numeric(ncol(X_nu))
  beta_nu[[1L]] <- stats::qlogis(nu0 - 1)
  c(
    list(
      beta_mu = beta_mu,
      beta_sigma = beta_sigma,
      beta_nu = beta_nu
    ),
    list(
      beta_zi = 0,
      theta_ord = 0,
      beta_sd_mu = 0,
      u_mu = 0,
      log_sd_mu = 0,
      eta_cor_mu = 0,
      eta_cor_mu_sigma = 0,
      eta_cor_sigma = 0,
      u_sigma = 0,
      log_sd_sigma = 0,
      beta_mu1 = 0,
      beta_mu2 = 0,
      beta_sigma1 = 0,
      beta_sigma2 = 0,
      beta_rho12 = 0,
      u_phylo = 0,
      log_sd_phylo = 0,
      eta_cor_phylo = 0
    )
  )
}

tweedie_ls_map <- function() {
  out <- gaussian_ls_map()
  out$beta_nu <- NULL
  out
}

cumulative_logit_start <- function(
  y,
  X_mu,
  n_categories,
  phylo_mu = empty_phylo_mu_structure()
) {
  beta_mu <- rep(0, ncol(X_mu))
  names(beta_mu) <- colnames(X_mu)

  cumulative <- cumsum(tabulate(y, nbins = n_categories)) / length(y)
  cutpoints <- stats::qlogis(cumulative[-n_categories])
  theta_ord <- ordinal_raw_from_cutpoints(cutpoints)
  phylo_start <- gaussian_phylo_start(as.numeric(y), phylo_mu)

  c(
    list(
      beta_mu = beta_mu,
      theta_ord = theta_ord
    ),
    list(
      beta_sigma = 0,
      beta_nu = 0,
      beta_zi = 0,
      beta_sd_mu = 0,
      u_mu = 0,
      log_sd_mu = 0,
      eta_cor_mu = 0,
      eta_cor_mu_sigma = 0,
      eta_cor_sigma = 0,
      u_sigma = 0,
      log_sd_sigma = 0,
      beta_mu1 = 0,
      beta_mu2 = 0,
      beta_sigma1 = 0,
      beta_sigma2 = 0,
      beta_rho12 = 0,
      u_phylo = phylo_start$u_phylo,
      log_sd_phylo = phylo_start$log_sd_phylo,
      eta_cor_phylo = 0
    )
  )
}

ordinal_raw_from_cutpoints <- function(cutpoints) {
  if (length(cutpoints) == 0L) {
    return(numeric())
  }
  spacings <- diff(cutpoints)
  if (
    any(!is.finite(cutpoints)) ||
      any(!is.finite(spacings)) ||
      any(spacings <= 0)
  ) {
    cli::cli_abort(
      "Internal ordinal cutpoint starts must be finite and strictly increasing."
    )
  }
  c(cutpoints[[1L]], log(spacings))
}

ordinal_cutpoints_from_raw <- function(theta_ord) {
  if (length(theta_ord) == 0L) {
    return(numeric())
  }
  out <- numeric(length(theta_ord))
  out[[1L]] <- theta_ord[[1L]]
  if (length(theta_ord) > 1L) {
    for (j in 2:length(theta_ord)) {
      out[[j]] <- out[[j - 1L]] + exp(theta_ord[[j]])
    }
  }
  out
}

cumulative_logit_map <- function(phylo_mu = empty_phylo_mu_structure()) {
  out <- list(
    beta_sigma = factor(NA),
    beta_nu = factor(NA),
    beta_zi = factor(NA),
    beta_sd_mu = factor(NA),
    beta_mu1 = factor(NA),
    beta_mu2 = factor(NA),
    beta_sigma1 = factor(NA),
    beta_sigma2 = factor(NA),
    beta_rho12 = factor(NA),
    u_mu = factor(NA),
    log_sd_mu = factor(NA),
    eta_cor_mu = factor(NA),
    eta_cor_mu_sigma = factor(NA),
    eta_cor_sigma = factor(NA),
    u_sigma = factor(NA),
    log_sd_sigma = factor(NA),
    eta_cor_phylo = factor(NA)
  )
  if (!isTRUE(phylo_mu$has)) {
    out <- c(out, list(
      u_phylo = factor(NA),
      log_sd_phylo = factor(NA)
    ))
  }
  out
}

gaussian_phylo_start <- function(y, phylo_mu) {
  if (!isTRUE(phylo_mu$has)) {
    return(list(u_phylo = 0, log_sd_phylo = 0))
  }
  y_scale <- stats::sd(y)
  if (!is.finite(y_scale) || y_scale <= 0) {
    y_scale <- 1
  }
  q <- structured_mu_q(phylo_mu)
  endpoint_scale <- ifelse(
    sub("[0-9]+$", "", phylo_mu_endpoint_dpars(phylo_mu)) == "sigma",
    0.2,
    0.25 * y_scale
  )
  list(
    u_phylo = rep(0, q * phylo_mu$n_re),
    log_sd_phylo = log(pmax(endpoint_scale, 1e-4))
  )
}

gaussian_sd_phylo_start <- function(y_scale, sd_phylo) {
  if (sd_phylo$n_models == 0L) {
    return(numeric())
  }
  out <- numeric(ncol(sd_phylo$X))
  for (dpar in sd_phylo$dpars) {
    target <- sd_phylo$target_dpar[[dpar]]
    scale <- if (!is.null(names(y_scale)) && target %in% names(y_scale)) {
      y_scale[[target]]
    } else {
      y_scale[[1L]]
    }
    if (!is.finite(scale) || scale <= 0) {
      scale <- 1
    }
    coef_index <- sd_phylo$coef_index[[dpar]]
    intercept <- match(
      "(Intercept)",
      sd_phylo$coef_names_list[[dpar]],
      nomatch = 0L
    )
    if (intercept > 0L) {
      out[[coef_index[[intercept]]]] <- log(max(0.25 * scale, 1e-4))
    }
  }
  names(out) <- colnames(sd_phylo$X)
  out
}

biv_gaussian_phylo_start <- function(phylo_mu, y_scale) {
  if (!isTRUE(phylo_mu$has)) {
    return(list(
      u_phylo = 0,
      log_sd_phylo = 0,
      eta_cor_phylo = 0,
      theta_phylo = 0
    ))
  }
  q <- phylo_mu$q
  y_scale[!is.finite(y_scale) | y_scale <= 0] <- 1
  endpoint_scale <- vapply(
    phylo_mu_endpoint_dpars(phylo_mu),
    function(dpar) {
      family <- sub("[0-9]+$", "", dpar)
      if (identical(family, "sigma")) {
        return(0.2)
      }
      response <- suppressWarnings(as.integer(sub("^mu", "", dpar)))
      if (is.na(response) || response < 1L || response > length(y_scale)) {
        response <- 1L
      }
      y_scale[[response]]
    },
    numeric(1L)
  )
  list(
    u_phylo = rep(0, q * phylo_mu$n_re),
    log_sd_phylo = log(pmax(0.25 * endpoint_scale, 1e-4)),
    eta_cor_phylo = 0,
    theta_phylo = if (q > 2L) {
      rep(0, phylo_mu_theta_count(phylo_mu))
    } else {
      0
    }
  )
}

gaussian_mu_re_start <- function(resid, re_mu, y_scale) {
  if (re_mu$n_re == 0L) {
    return(list(u_mu = 0, log_sd_mu = 0, eta_cor_mu = 0))
  }

  log_sd_mu <- numeric(re_mu$n_terms)
  for (k in seq_len(re_mu$n_terms)) {
    design_value <- re_mu$value[, k]
    group <- re_mu$index[, k]
    if (isTRUE(all.equal(design_value, rep(1, length(design_value))))) {
      group_est <- stats::aggregate(
        resid,
        by = list(group = group),
        FUN = mean
      )$x
    } else {
      moment <- stats::aggregate(
        cbind(num = design_value * resid, den = design_value^2),
        by = list(group = group),
        FUN = sum
      )
      group_est <- ifelse(
        moment$den > sqrt(.Machine$double.eps),
        moment$num / moment$den,
        NA_real_
      )
      group_est <- group_est[is.finite(group_est)]
    }
    sd0 <- stats::sd(group_est)
    if (!is.finite(sd0) || sd0 <= 0) {
      sd0 <- 0.25 * y_scale
    }
    if (!is.finite(sd0) || sd0 <= 0) {
      sd0 <- 0.25
    }
    log_sd_mu[[k]] <- log(max(sd0, 1e-4))
  }

  list(
    u_mu = rep(0, re_mu$n_re),
    log_sd_mu = log_sd_mu,
    eta_cor_mu = rep(0, max(1L, re_mu$n_cors))
  )
}

gaussian_sigma_re_start <- function(re_sigma) {
  if (re_sigma$n_re == 0L) {
    return(list(u_sigma = 0, log_sd_sigma = 0, eta_cor_sigma = 0))
  }
  list(
    u_sigma = rep(0, re_sigma$n_re),
    log_sd_sigma = rep(log(0.2), re_sigma$n_terms),
    eta_cor_sigma = rep(0, max(1L, re_sigma$n_cors))
  )
}

gaussian_sd_mu_start <- function(mu_re_start, sd_mu) {
  if (sd_mu$n_models == 0L) {
    return(0)
  }
  out <- numeric(ncol(sd_mu$X))
  for (dpar in sd_mu$dpars) {
    coef_index <- sd_mu$coef_index[[dpar]]
    out[[coef_index[[1L]]]] <- mu_re_start$log_sd_mu[[sd_mu$target_coef[[
      dpar
    ]]]]
  }
  names(out) <- colnames(sd_mu$X)
  out
}

biv_gaussian_start <- function(
  y1,
  y2,
  X_mu1,
  X_mu2,
  X_sigma1,
  X_sigma2,
  X_rho12,
  V_known_diag = rep(0, 2L * length(y1)),
  re_mu = empty_random_mu_structure(length(y1)),
  re_sigma = empty_random_sigma_structure(length(y1)),
  re_mu_sigma = empty_mu_sigma_random_covariance(re_sigma$n_re),
  phylo_mu = empty_phylo_mu_structure(),
  sd_mu = empty_sd_mu_structure(re_mu$n_re),
  sd_phylo = empty_sd_phylo_structure(),
  re_cov_blocks = empty_labelled_covariance_block_registry(),
  observed_y1 = rep(TRUE, length(y1)),
  observed_y2 = rep(TRUE, length(y2))
) {
  observed_y1 <- as.logical(observed_y1)
  observed_y2 <- as.logical(observed_y2)
  if (length(observed_y1) != length(y1) || length(observed_y2) != length(y2)) {
    cli::cli_abort(
      "Internal bivariate Gaussian start error: response-mask lengths do not match response lengths."
    )
  }
  if (!any(observed_y1) || !any(observed_y2)) {
    cli::cli_abort(
      "Each bivariate Gaussian response needs at least one observed value for starting values."
    )
  }

  fit1 <- stats::lm.fit(
    x = X_mu1[observed_y1, , drop = FALSE],
    y = y1[observed_y1]
  )
  fit2 <- stats::lm.fit(
    x = X_mu2[observed_y2, , drop = FALSE],
    y = y2[observed_y2]
  )
  beta_mu1 <- fit1$coefficients
  beta_mu2 <- fit2$coefficients
  beta_mu1[is.na(beta_mu1)] <- 0
  beta_mu2[is.na(beta_mu2)] <- 0

  resid1 <- y1 - as.vector(X_mu1 %*% beta_mu1)
  resid2 <- y2 - as.vector(X_mu2 %*% beta_mu2)
  resid1[!observed_y1] <- 0
  resid2[!observed_y2] <- 0
  V1 <- V_known_diag[seq.int(1L, by = 2L, length.out = length(y1))]
  V2 <- V_known_diag[seq.int(2L, by = 2L, length.out = length(y1))]
  sigma_floor <- 1e-4
  # Between-study variance start per endpoint: use variance-weighted DL when this
  # is a meta-analysis (positive known V, no location random effects) and fall
  # back to the median(V) moment start otherwise (issue #710.3).
  no_location_re <- re_mu$n_re == 0L
  tau2_1_fallback <- max(
    stats::var(resid1[observed_y1]) -
      stats::median(V1[observed_y1], na.rm = TRUE),
    sigma_floor^2
  )
  tau2_2_fallback <- max(
    stats::var(resid2[observed_y2]) -
      stats::median(V2[observed_y2], na.rm = TRUE),
    sigma_floor^2
  )
  sigma1 <- sqrt(
    if (no_location_re && any(V1[observed_y1] > 0)) {
      max(
        meta_dl_tau2_start(
          resid1[observed_y1],
          V1[observed_y1],
          tau2_1_fallback
        ),
        sigma_floor^2
      )
    } else {
      tau2_1_fallback
    }
  )
  sigma2 <- sqrt(
    if (no_location_re && any(V2[observed_y2] > 0)) {
      max(
        meta_dl_tau2_start(
          resid2[observed_y2],
          V2[observed_y2],
          tau2_2_fallback
        ),
        sigma_floor^2
      )
    } else {
      tau2_2_fallback
    }
  )
  if (!is.finite(sigma1) || sigma1 <= 0) {
    sigma1 <- stats::sd(y1[observed_y1])
  }
  if (!is.finite(sigma2) || sigma2 <= 0) {
    sigma2 <- stats::sd(y2[observed_y2])
  }
  if (!is.finite(sigma1) || sigma1 <= 0) {
    sigma1 <- 1
  }
  if (!is.finite(sigma2) || sigma2 <= 0) {
    sigma2 <- 1
  }

  complete_pairs <- observed_y1 & observed_y2
  rho <- if (sum(complete_pairs) >= 2L) {
    stats::cor(resid1[complete_pairs], resid2[complete_pairs])
  } else {
    0
  }
  if (!is.finite(rho)) {
    rho <- 0
  }
  rho <- max(min(rho, 0.8), -0.8)

  beta_rho12 <- numeric(ncol(X_rho12))
  beta_sigma1 <- gaussian_sigma_fixed_start(
    resid = resid1,
    X_sigma = X_sigma1,
    sigma0 = sigma1,
    sigma_floor = sigma_floor,
    observed_y = observed_y1
  )
  beta_sigma2 <- gaussian_sigma_fixed_start(
    resid = resid2,
    X_sigma = X_sigma2,
    sigma0 = sigma2,
    sigma_floor = sigma_floor,
    observed_y = observed_y2
  )
  beta_rho12[1L] <- atanh(rho)

  y1_scale <- stats::sd(resid1[observed_y1])
  y2_scale <- stats::sd(resid2[observed_y2])
  if (!is.finite(y1_scale) || y1_scale <= 0) {
    y1_scale <- sigma1
  }
  if (!is.finite(y2_scale) || y2_scale <= 0) {
    y2_scale <- sigma2
  }
  if (!is.finite(y1_scale) || y1_scale <= 0) {
    y1_scale <- 1
  }
  if (!is.finite(y2_scale) || y2_scale <= 0) {
    y2_scale <- 1
  }
  mu_re_start <- biv_gaussian_mu_re_start(re_mu, c(y1_scale, y2_scale))
  beta_sd_mu <- c(
    if (sd_mu$n_models > 0L) {
      gaussian_sd_mu_start(mu_re_start, sd_mu)
    },
    gaussian_sd_phylo_start(c(mu1 = y1_scale, mu2 = y2_scale), sd_phylo)
  )
  if (length(beta_sd_mu) == 0L) {
    beta_sd_mu <- 0
  }
  sigma_re_start <- gaussian_sigma_re_start(re_sigma)
  re_cov_start <- covariance_block_re_start(
    re_cov_blocks,
    c(y1_scale, y2_scale)
  )
  phylo_start <- biv_gaussian_phylo_start(phylo_mu, c(y1_scale, y2_scale))

  c(
    list(
      beta_mu = 0,
      beta_sigma = 0,
      beta_nu = 0,
      beta_zi = 0,
      theta_ord = 0,
      beta_sd_mu = beta_sd_mu,
      u_mu = mu_re_start$u_mu,
      log_sd_mu = mu_re_start$log_sd_mu,
      eta_cor_mu = mu_re_start$eta_cor_mu,
      eta_cor_mu_sigma = rep(0, max(1L, re_mu_sigma$n_cors)),
      eta_cor_sigma = sigma_re_start$eta_cor_sigma,
      u_sigma = sigma_re_start$u_sigma,
      log_sd_sigma = sigma_re_start$log_sd_sigma,
      u_re_cov = re_cov_start$u_re_cov,
      log_sd_re_cov = re_cov_start$log_sd_re_cov,
      theta_re_cov = re_cov_start$theta_re_cov
    ),
    list(
      beta_mu1 = beta_mu1,
      beta_mu2 = beta_mu2,
      beta_sigma1 = beta_sigma1,
      beta_sigma2 = beta_sigma2,
      beta_rho12 = beta_rho12,
      beta_cor_mu = rep(
        0,
        if (re_mu$cor_model$n_models > 0L) ncol(re_mu$cor_model$X) else 1L
      )
    ),
    list(
      u_phylo = phylo_start$u_phylo,
      log_sd_phylo = phylo_start$log_sd_phylo,
      eta_cor_phylo = phylo_start$eta_cor_phylo,
      theta_phylo = phylo_start$theta_phylo
    )
  )
}

biv_gaussian_mu_re_start <- function(re_mu, y_scale) {
  if (re_mu$n_re == 0L) {
    return(list(u_mu = 0, log_sd_mu = 0, eta_cor_mu = 0))
  }
  dpar_index <- match(re_mu$dpars, c("mu1", "mu2"))
  log_sd_mu <- log(pmax(0.25 * y_scale[dpar_index], 1e-4))
  list(
    u_mu = rep(0, re_mu$n_re),
    log_sd_mu = log_sd_mu,
    eta_cor_mu = rep(0, max(1L, re_mu$n_cors))
  )
}

gaussian_ls_map <- function(
  re_mu = empty_random_mu_structure(1L),
  re_sigma = empty_random_sigma_structure(1L),
  sd_mu = empty_sd_mu_structure(re_mu$n_re),
  phylo_mu = empty_phylo_mu_structure(),
  re_mu_sigma = empty_mu_sigma_random_covariance(re_sigma$n_re),
  sd_phylo = empty_sd_phylo_structure()
) {
  out <- list(
    beta_mu1 = factor(NA),
    beta_mu2 = factor(NA),
    beta_sigma1 = factor(NA),
    beta_sigma2 = factor(NA),
    beta_rho12 = factor(NA),
    beta_cor_mu = factor(NA),
    beta_nu = factor(NA),
    beta_zi = factor(NA),
    theta_ord = factor(NA)
  )
  if (!isTRUE(phylo_mu$has)) {
    out$u_phylo <- factor(NA)
    out$log_sd_phylo <- factor(NA)
  }
  if (isTRUE(phylo_mu$has) && sd_phylo$n_models > 0L) {
    out$log_sd_phylo <- factor(NA)
  }
  if (!phylo_mu_has_cross_dpar(phylo_mu)) {
    out$eta_cor_phylo <- factor(NA)
  }
  if (re_mu$n_re == 0L) {
    out$u_mu <- factor(NA)
    out$log_sd_mu <- factor(NA)
  }
  if (re_mu$n_re > 0L && sd_mu$n_models > 0L) {
    log_sd_map <- seq_len(re_mu$n_terms)
    log_sd_map[unname(sd_mu$target_coef)] <- NA_integer_
    out$log_sd_mu <- factor(log_sd_map)
  }
  if (re_sigma$n_re == 0L) {
    out$u_sigma <- factor(NA)
    out$log_sd_sigma <- factor(NA)
  }
  if (re_mu$n_cors == 0L) {
    out$eta_cor_mu <- factor(NA)
  }
  if (re_mu_sigma$n_cors == 0L) {
    out$eta_cor_mu_sigma <- factor(NA)
  }
  if (re_sigma$n_cors == 0L) {
    out$eta_cor_sigma <- factor(NA)
  }
  if (sd_mu$n_models == 0L && sd_phylo$n_models == 0L) {
    out$beta_sd_mu <- factor(NA)
  }
  out
}

student_ls_map <- function(
  re_mu = empty_random_mu_structure(1L),
  phylo_mu = empty_phylo_mu_structure()
) {
  out <- gaussian_ls_map(re_mu = re_mu, phylo_mu = phylo_mu)
  out$beta_nu <- NULL
  out
}

skew_normal_ls_map <- function() {
  out <- gaussian_ls_map()
  out$beta_nu <- NULL
  out
}

covariance_block_re_start <- function(registry, y_scale = c(1, 1)) {
  if (
    !is.list(registry) ||
      is.null(registry$n_qgt2_re) ||
      registry$n_qgt2_re == 0L
  ) {
    return(list(
      u_re_cov = 0,
      log_sd_re_cov = 0,
      theta_re_cov = 0
    ))
  }

  member_rows <- qgt2_covariance_members(registry)
  sd0 <- vapply(
    member_rows$dpar,
    function(dpar) {
      if (grepl("^mu", dpar)) {
        response <- covariance_member_response_index(dpar)
        if (is.na(response)) {
          response <- 1L
        }
        return(pmax(0.25 * y_scale[[response]], 1e-4))
      }
      0.2
    },
    numeric(1L)
  )
  list(
    u_re_cov = rep(0, registry$n_qgt2_re),
    log_sd_re_cov = log(sd0),
    theta_re_cov = rep(0, registry$n_qgt2_theta)
  )
}

biv_gaussian_map <- function(
  re_mu = empty_random_mu_structure(1L),
  re_sigma = empty_random_sigma_structure(1L),
  re_mu_sigma = empty_mu_sigma_random_covariance(re_sigma$n_re),
  phylo_mu = empty_phylo_mu_structure(),
  sd_mu = empty_sd_mu_structure(re_mu$n_re),
  sd_phylo = empty_sd_phylo_structure()
) {
  out <- list(
    beta_mu = factor(NA),
    beta_sigma = factor(NA),
    beta_nu = factor(NA),
    beta_zi = factor(NA),
    theta_ord = factor(NA)
  )
  if (!isTRUE(phylo_mu$has)) {
    out$u_phylo <- factor(NA)
    out$log_sd_phylo <- factor(NA)
    out$eta_cor_phylo <- factor(NA)
    out$theta_phylo <- factor(NA)
  } else if (corpair_model_is_phylogenetic(re_mu$cor_model)) {
    out$eta_cor_phylo <- factor(NA)
    out$theta_phylo <- factor(NA)
  } else if (phylo_mu$q > 2L) {
    out$eta_cor_phylo <- factor(NA)
  } else if (sd_phylo$n_models > 0L) {
    out$theta_phylo <- factor(NA)
    log_sd_map <- seq_len(length(phylo_mu_dpars(phylo_mu)))
    log_sd_map[unname(sd_phylo$target_endpoint)] <- NA_integer_
    out$log_sd_phylo <- factor(log_sd_map)
  } else {
    out$theta_phylo <- factor(NA)
  }
  if (re_mu$n_re == 0L) {
    out$u_mu <- factor(NA)
    out$log_sd_mu <- factor(NA)
  }
  if (re_mu$n_re > 0L && sd_mu$n_models > 0L) {
    log_sd_map <- seq_len(re_mu$n_terms)
    log_sd_map[unname(sd_mu$target_coef)] <- NA_integer_
    out$log_sd_mu <- factor(log_sd_map)
  }
  if (re_mu$n_cors == 0L) {
    out$eta_cor_mu <- factor(NA)
  }
  if (re_mu$cor_model$n_models == 0L) {
    out$beta_cor_mu <- factor(NA)
  } else {
    out$eta_cor_mu <- factor(NA)
  }
  if (re_mu_sigma$n_cors == 0L) {
    out$eta_cor_mu_sigma <- factor(NA)
  }
  if (re_sigma$n_re == 0L) {
    out$u_sigma <- factor(NA)
    out$log_sd_sigma <- factor(NA)
  }
  if (re_sigma$n_cors == 0L) {
    out$eta_cor_sigma <- factor(NA)
  }
  if (sd_mu$n_models == 0L && sd_phylo$n_models == 0L) {
    out$beta_sd_mu <- factor(NA)
  }
  out
}

add_covariance_block_tmb_data <- function(tmb_data, spec) {
  tmb_data$observed_y <- drm_tmb_observed_y(spec)
  tmb_data$observed_y1 <- drm_tmb_observed_y1(spec)
  tmb_data$observed_y2 <- drm_tmb_observed_y2(spec)
  cov_blocks <- if (is.list(spec$random)) {
    spec$random$covariance_blocks
  } else {
    NULL
  }
  cov_tmb_data <- if (is.list(cov_blocks) && !is.null(cov_blocks$tmb_data)) {
    cov_blocks$tmb_data
  } else {
    empty_labelled_covariance_block_tmb_data()
  }
  c(
    tmb_data,
    structured_mu_tmb_data(spec),
    structured_mu2_tmb_data(spec),
    drm_sparse_fixed_tmb_data(spec),
    drm_gaussian_aggregation_tmb_data(spec),
    drm_tmb_missing_predictor_data(spec),
    cov_tmb_data,
    list(
      penalize_phylo = 0L,
      phylo_sd_penalty_rate = numeric(0),
      phylo_cor_penalty_sd = numeric(0),
      use_logsigma_clamp = 1L,
      logsigma_clamp = c(-12, 12, 3),
      qgt2_corr_parameterization = drm_qgt2_corr_parameterization()
    )
  )
}

# TMB data for the scoped second structured location field. Supplied globally
# (not per model branch) so the shared C++ signature always has the fields; when
# `phylo_mu2` is empty the fields are inert placeholders. The field is always a
# q = 1 intercept-only GMRF with its OWN group precision `Q_phylo2`.
structured_mu2_tmb_data <- function(spec) {
  phylo_mu2 <- if (is.list(spec$structured)) {
    spec$structured$phylo_mu2
  } else {
    NULL
  }
  dummy_sparse <- Matrix::sparseMatrix(
    i = integer(0),
    j = integer(0),
    x = numeric(0),
    dims = c(1L, 1L)
  )
  if (
    !is.list(phylo_mu2) ||
      !isTRUE(phylo_mu2$has) ||
      !is.matrix(phylo_mu2$value) ||
      nrow(phylo_mu2$value) == 0L
  ) {
    return(list(
      has_phylo_mu2 = 0L,
      phylo_mu2_node_index = 0L,
      phylo_mu2_value = matrix(0, nrow = 1L, ncol = 1L),
      Q_phylo2 = dummy_sparse,
      log_det_Q_phylo2 = 0
    ))
  }
  list(
    has_phylo_mu2 = 1L,
    phylo_mu2_node_index = phylo_mu2$observation_node_index0,
    phylo_mu2_value = phylo_mu2$value,
    Q_phylo2 = phylo_mu2$precision$precision,
    log_det_Q_phylo2 = phylo_mu2$precision$log_det_precision
  )
}

drm_qgt2_corr_parameterization <- function(
  value = getOption("drmTMB.internal.qgt2_corr_parameterization", 0L)
) {
  if (
    is.null(value) ||
      identical(value, FALSE) ||
      identical(value, 0L) ||
      identical(value, 0) ||
      identical(value, "0") ||
      identical(value, "unstructured")
  ) {
    return(0L)
  }
  if (
    identical(value, TRUE) ||
      identical(value, 1L) ||
      identical(value, 1) ||
      identical(value, "1") ||
      identical(value, "partial_cholesky")
  ) {
    return(1L)
  }
  cli::cli_abort(c(
    "Invalid internal q>2 correlation parameterization.",
    "i" = "Use {.val unstructured} or {.val partial_cholesky}.",
    "i" = "This is an internal diagnostic option, not a public control surface."
  ))
}

structured_mu_tmb_data <- function(spec) {
  phylo_mu <- if (is.list(spec$structured)) {
    spec$structured$phylo_mu
  } else {
    NULL
  }
  q <- if (is.list(phylo_mu) && isTRUE(phylo_mu$has)) {
    structured_mu_q(phylo_mu)
  } else {
    0L
  }
  phylo_mu_block_id <- if (q > 0L) {
    phylo_mu_block_ids(phylo_mu) - 1L
  } else {
    0L
  }
  phylo_mu_dpar <- if (q > 0L) {
    phylo_mu_dpar_codes(phylo_mu)
  } else {
    0L
  }
  phylo_mu_response <- if (q > 0L) {
    phylo_mu_response_codes(phylo_mu)
  } else {
    0L
  }
  n_phylo_mu_blocks <- if (q > 0L) {
    phylo_mu_n_blocks(phylo_mu)
  } else {
    0L
  }
  if (
    is.list(phylo_mu) &&
      isTRUE(phylo_mu$has) &&
      is.matrix(phylo_mu$value) &&
      nrow(phylo_mu$value) > 0L
  ) {
    return(list(
      phylo_mu_value = phylo_mu$value,
      phylo_mu_block_id = phylo_mu_block_id,
      phylo_mu_dpar = phylo_mu_dpar,
      phylo_mu_response = phylo_mu_response,
      phylo_mu_n_blocks = n_phylo_mu_blocks
    ))
  }
  list(
    phylo_mu_value = matrix(0, nrow = 1L, ncol = 1L),
    phylo_mu_block_id = 0L,
    phylo_mu_dpar = 0L,
    phylo_mu_response = 0L,
    phylo_mu_n_blocks = 0L
  )
}

add_covariance_probe_parameter <- function(spec) {
  has_qgt2_re_cov <- is.list(spec$random) &&
    is.list(spec$random$covariance_blocks) &&
    isTRUE(spec$random$covariance_blocks$n_qgt2_re > 0L)
  has_qgt2_phylo_cov <- is.list(spec$structured) &&
    is.list(spec$structured$phylo_mu) &&
    isTRUE(spec$structured$phylo_mu$has) &&
    isTRUE(spec$structured$phylo_mu$q > 2L) &&
    !identical(
      phylo_mu_covariance_mode(spec$structured$phylo_mu),
      "scalar"
    )
  has_cor_mu_model <- is.list(spec$random) &&
    is.list(spec$random$mu) &&
    is.list(spec$random$mu$cor_model) &&
    isTRUE(spec$random$mu$cor_model$n_models > 0L)
  has_mi <- is.list(spec$missing_predictor) &&
    isTRUE(spec$missing_predictor$enabled)
  has_gaussian_mi <- has_mi &&
    identical(spec$missing_predictor$family, "gaussian")
  has_sigma_mi <- has_mi &&
    spec$missing_predictor$family %in%
      c(
        "gaussian",
        "beta",
        "zero_one_beta",
        "beta_binomial",
        "lognormal",
        "gamma",
        "nbinom2",
        "truncated_nbinom2",
        "tweedie"
      )
  has_zero_one_beta_mi <- has_mi &&
    identical(spec$missing_predictor$family, "zero_one_beta")
  has_mi_group <- has_mi &&
    is.list(spec$missing_predictor$random) &&
    isTRUE(spec$missing_predictor$random$enabled)
  has_mi_struct <- has_mi &&
    is.list(spec$missing_predictor$structured) &&
    isTRUE(spec$missing_predictor$structured$enabled)
  if (is.null(spec$start$u_re_cov)) {
    spec$start$u_re_cov <- 0
  }
  if (is.null(spec$start$log_sd_re_cov)) {
    spec$start$log_sd_re_cov <- 0
  }
  if (is.null(spec$start$theta_re_cov)) {
    spec$start$theta_re_cov <- 0
  }
  if (is.null(spec$start$beta_cor_mu)) {
    spec$start$beta_cor_mu <- 0
  }
  if (is.null(spec$start$beta_zoi)) {
    spec$start$beta_zoi <- 0
  }
  if (is.null(spec$start$beta_coi)) {
    spec$start$beta_coi <- 0
  }
  if (is.null(spec$map)) {
    spec$map <- list()
  }
  if (is.null(spec$map$beta_cor_mu) && !has_cor_mu_model) {
    spec$map$beta_cor_mu <- factor(NA)
  }
  if (
    is.null(spec$map$beta_zoi) &&
      !identical(spec$model_type, "zero_one_beta") &&
      !has_zero_one_beta_mi
  ) {
    spec$map$beta_zoi <- factor(NA)
  }
  if (
    is.null(spec$map$beta_coi) &&
      !identical(spec$model_type, "zero_one_beta") &&
      !has_zero_one_beta_mi
  ) {
    spec$map$beta_coi <- factor(NA)
  }
  if (is.null(spec$map$u_re_cov) && !has_qgt2_re_cov) {
    spec$map$u_re_cov <- factor(NA)
  }
  if (is.null(spec$map$log_sd_re_cov) && !has_qgt2_re_cov) {
    spec$map$log_sd_re_cov <- factor(NA)
  }
  if (is.null(spec$map$theta_re_cov) && !has_qgt2_re_cov) {
    spec$map$theta_re_cov <- factor(NA)
  }
  if (is.null(spec$start$u_re_cov_probe)) {
    spec$start$u_re_cov_probe <- 0
  }
  if (is.null(spec$map$u_re_cov_probe)) {
    spec$map$u_re_cov_probe <- factor(NA)
  }
  if (is.null(spec$start$theta_phylo)) {
    spec$start$theta_phylo <- 0
  }
  if (is.null(spec$map$theta_phylo) && !has_qgt2_phylo_cov) {
    spec$map$theta_phylo <- factor(NA)
  }
  if (is.null(spec$start$beta_mi)) {
    spec$start$beta_mi <- 0
  }
  if (is.null(spec$start$log_sigma_mi)) {
    spec$start$log_sigma_mi <- 0
  }
  if (is.null(spec$start$x_miss)) {
    spec$start$x_miss <- 0
  }
  if (is.null(spec$start$u_mi_group)) {
    spec$start$u_mi_group <- 0
  }
  if (is.null(spec$start$log_sd_mi_group)) {
    spec$start$log_sd_mi_group <- 0
  }
  if (is.null(spec$start$u_mi_struct)) {
    spec$start$u_mi_struct <- 0
  }
  if (is.null(spec$start$log_sd_mi_struct)) {
    spec$start$log_sd_mi_struct <- 0
  }
  if (is.null(spec$map$beta_mi) && !has_mi) {
    spec$map$beta_mi <- factor(NA)
  }
  if (is.null(spec$map$log_sigma_mi) && !has_sigma_mi) {
    spec$map$log_sigma_mi <- factor(NA)
  }
  if (is.null(spec$map$x_miss) && !has_gaussian_mi) {
    spec$map$x_miss <- factor(NA)
  }
  if (is.null(spec$map$u_mi_group) && !has_mi_group) {
    spec$map$u_mi_group <- factor(NA)
  }
  if (is.null(spec$map$log_sd_mi_group) && !has_mi_group) {
    spec$map$log_sd_mi_group <- factor(NA)
  }
  if (is.null(spec$map$u_mi_struct) && !has_mi_struct) {
    spec$map$u_mi_struct <- factor(NA)
  }
  if (is.null(spec$map$log_sd_mi_struct) && !has_mi_struct) {
    spec$map$log_sd_mi_struct <- factor(NA)
  }
  # Scoped second structured location field. Every model declares its parameters
  # so the shared C++ signature is satisfied; they are mapped off unless the
  # admitted intercept-only two-provider combo populated `phylo_mu2`.
  has_phylo_mu2 <- is.list(spec$structured) &&
    is.list(spec$structured$phylo_mu2) &&
    isTRUE(spec$structured$phylo_mu2$has)
  if (is.null(spec$start$u_phylo2)) {
    spec$start$u_phylo2 <- 0
  }
  if (is.null(spec$start$log_sd_phylo2)) {
    spec$start$log_sd_phylo2 <- 0
  }
  if (is.null(spec$map$u_phylo2) && !has_phylo_mu2) {
    spec$map$u_phylo2 <- factor(NA)
  }
  if (is.null(spec$map$log_sd_phylo2) && !has_phylo_mu2) {
    spec$map$log_sd_phylo2 <- factor(NA)
  }
  spec
}

corpair_model_is_group <- function(model) {
  is.list(model) &&
    isTRUE(model$n_models > 0L) &&
    identical(model$level, "group")
}

corpair_model_is_phylogenetic <- function(model) {
  is.list(model) &&
    isTRUE(model$n_models > 0L) &&
    identical(model$level, "phylogenetic")
}

corpair_model_level_id <- function(model) {
  if (corpair_model_is_group(model)) {
    return(1L)
  }
  if (corpair_model_is_phylogenetic(model)) {
    return(2L)
  }
  0L
}

make_tmb_data <- function(spec) {
  dummy_matrix <- matrix(0, nrow = 1, ncol = 1)
  dummy_sparse <- Matrix::sparseMatrix(
    i = integer(0),
    j = integer(0),
    x = numeric(0),
    dims = c(1L, 1L)
  )
  offset_mu <- if (!is.null(spec$offset$mu)) spec$offset$mu else numeric(1)
  tmb_trials <- if (!is.null(spec$trials)) {
    spec$trials
  } else {
    rep(1, length(spec$y))
  }
  if (identical(spec$model_type, "gaussian")) {
    phylo_mu <- spec$structured$phylo_mu
    gaussian_aggregation <- if (is.list(spec$aggregation)) {
      spec$aggregation$gaussian
    } else {
      NULL
    }
    use_gaussian_aggregation <- is.list(gaussian_aggregation) &&
      isTRUE(gaussian_aggregation$enabled)
    return(list(
      model_type = 1L,
      y = if (use_gaussian_aggregation) numeric(1) else spec$y,
      trials = if (use_gaussian_aggregation) numeric(1) else tmb_trials,
      weights = if (use_gaussian_aggregation) numeric(1) else spec$weights,
      offset_mu = offset_mu,
      V_known = spec$V_known_diag,
      V_known_matrix = if (identical(spec$V_known_type, "matrix")) {
        spec$V_known
      } else {
        dummy_matrix
      },
      V_known_type = as.integer(
        match(spec$V_known_type, c("none", "diagonal", "matrix")) - 1L
      ),
      y1 = numeric(1),
      y2 = numeric(1),
      X_mu = if (isTRUE(spec$sparse_fixed$mu) || use_gaussian_aggregation) {
        dummy_matrix
      } else {
        spec$X$mu
      },
      X_sigma = if (use_gaussian_aggregation) dummy_matrix else spec$X$sigma,
      X_nu = dummy_matrix,
      X_zi = dummy_matrix,
      X_sd_mu = spec$random_scale$mu$X,
      has_sd_mu_model = as.integer(spec$random_scale$mu$n_models > 0L),
      X_sd_phylo = spec$random_scale$phylo$X,
      report_group_sd = 0L,
      has_sd_phylo_model = as.integer(
        spec$random_scale$phylo$n_models > 0L
      ),
      sd_phylo_beta_offset = if (spec$random_scale$mu$n_models > 0L) {
        ncol(spec$random_scale$mu$X)
      } else {
        0L
      },
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
      X_cor_mu = dummy_matrix,
      has_cor_mu_model = 0L,
      n_mu_re_terms = spec$random$mu$n_terms,
      n_mu_re_cors = spec$random$mu$n_cors,
      mu_re_index = spec$random$mu$index0,
      mu_re_value = spec$random$mu$value,
      mu_re_term = spec$random$mu$term_id0,
      mu_re_dpar = spec$random$mu$dpar_id0,
      mu_re_pos = spec$random$mu$re_pos0,
      mu_re_cor_id = spec$random$mu$re_cor_id0,
      mu_re_pair_index = spec$random$mu$re_pair_index0,
      mu_re_sd_row = spec$random_scale$mu$re_sd_row0,
      n_sigma_re_terms = spec$random$sigma$n_terms,
      n_sigma_re_cors = spec$random$sigma$n_cors,
      n_mu_sigma_re_cors = spec$random$mu_sigma$n_cors,
      sigma_re_index = spec$random$sigma$index0,
      sigma_re_value = spec$random$sigma$value,
      sigma_re_term = spec$random$sigma$term_id0,
      sigma_re_dpar = spec$random$sigma$dpar_id0,
      sigma_re_cor_id = spec$random$sigma$re_cor_id0,
      sigma_re_pair_index = spec$random$sigma$re_pair_index0,
      sigma_re_cross_cor = spec$random$mu_sigma$sigma_cross_cor_id0,
      sigma_re_cross_mu = spec$random$mu_sigma$sigma_cross_mu_index0,
      has_phylo_mu = as.integer(isTRUE(phylo_mu$has)),
      phylo_mu_sd_row = if (spec$random_scale$phylo$n_models > 0L) {
        spec$random_scale$phylo$observation_sd_row0
      } else {
        0L
      },
      phylo_mu_node_index = if (isTRUE(phylo_mu$has)) {
        phylo_mu$observation_node_index0
      } else {
        0L
      },
      Q_phylo = if (isTRUE(phylo_mu$has)) {
        phylo_mu$precision$precision
      } else {
        dummy_sparse
      },
      log_det_Q_phylo = if (isTRUE(phylo_mu$has)) {
        phylo_mu$precision$log_det_precision
      } else {
        0
      }
    ))
  }
  if (identical(spec$model_type, "student")) {
    re_mu <- spec$random$mu
    sd_mu <- spec$random_scale$mu
    phylo_mu <- spec$structured$phylo_mu
    return(list(
      model_type = 3L,
      y = spec$y,
      trials = tmb_trials,
      weights = spec$weights,
      offset_mu = offset_mu,
      V_known = spec$V_known_diag,
      V_known_matrix = dummy_matrix,
      V_known_type = 0L,
      y1 = numeric(1),
      y2 = numeric(1),
      X_mu = spec$X$mu,
      X_sigma = spec$X$sigma,
      X_nu = spec$X$nu,
      X_zi = dummy_matrix,
      X_sd_mu = sd_mu$X,
      has_sd_mu_model = 0L,
      X_sd_phylo = dummy_matrix,
      report_group_sd = 0L,
      has_sd_phylo_model = 0L,
      sd_phylo_beta_offset = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
      X_cor_mu = dummy_matrix,
      has_cor_mu_model = 0L,
      n_mu_re_terms = re_mu$n_terms,
      n_mu_re_cors = 0L,
      mu_re_index = re_mu$index0,
      mu_re_value = re_mu$value,
      mu_re_term = re_mu$term_id0,
      mu_re_dpar = re_mu$dpar_id0,
      mu_re_pos = re_mu$re_pos0,
      mu_re_cor_id = re_mu$re_cor_id0,
      mu_re_pair_index = re_mu$re_pair_index0,
      mu_re_sd_row = sd_mu$re_sd_row0,
      n_sigma_re_terms = 0L,
      n_sigma_re_cors = 0L,
      n_mu_sigma_re_cors = 0L,
      sigma_re_index = matrix(0L, nrow = 1L, ncol = 1L),
      sigma_re_value = dummy_matrix,
      sigma_re_term = 0L,
      sigma_re_dpar = 0L,
      sigma_re_cor_id = -1L,
      sigma_re_pair_index = -1L,
      sigma_re_cross_cor = 0L,
      sigma_re_cross_mu = 0L,
      has_phylo_mu = as.integer(isTRUE(phylo_mu$has)),
      phylo_mu_sd_row = 0L,
      phylo_mu_node_index = if (isTRUE(phylo_mu$has)) {
        phylo_mu$observation_node_index0
      } else {
        0L
      },
      Q_phylo = if (isTRUE(phylo_mu$has)) {
        phylo_mu$precision$precision
      } else {
        dummy_sparse
      },
      log_det_Q_phylo = if (isTRUE(phylo_mu$has)) {
        phylo_mu$precision$log_det_precision
      } else {
        0
      }
    ))
  }
  if (identical(spec$model_type, "skew_normal")) {
    re_mu <- spec$random$mu
    sd_mu <- spec$random_scale$mu
    return(list(
      model_type = 17L,
      y = spec$y,
      trials = tmb_trials,
      weights = spec$weights,
      offset_mu = offset_mu,
      V_known = spec$V_known_diag,
      V_known_matrix = dummy_matrix,
      V_known_type = 0L,
      y1 = numeric(1),
      y2 = numeric(1),
      X_mu = spec$X$mu,
      X_sigma = spec$X$sigma,
      X_nu = spec$X$nu,
      X_zi = dummy_matrix,
      X_sd_mu = sd_mu$X,
      has_sd_mu_model = 0L,
      X_sd_phylo = dummy_matrix,
      report_group_sd = 0L,
      has_sd_phylo_model = 0L,
      sd_phylo_beta_offset = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
      X_cor_mu = dummy_matrix,
      has_cor_mu_model = 0L,
      n_mu_re_terms = re_mu$n_terms,
      n_mu_re_cors = 0L,
      mu_re_index = re_mu$index0,
      mu_re_value = re_mu$value,
      mu_re_term = re_mu$term_id0,
      mu_re_dpar = re_mu$dpar_id0,
      mu_re_pos = re_mu$re_pos0,
      mu_re_cor_id = re_mu$re_cor_id0,
      mu_re_pair_index = re_mu$re_pair_index0,
      mu_re_sd_row = sd_mu$re_sd_row0,
      n_sigma_re_terms = 0L,
      n_sigma_re_cors = 0L,
      n_mu_sigma_re_cors = 0L,
      sigma_re_index = matrix(0L, nrow = 1L, ncol = 1L),
      sigma_re_value = dummy_matrix,
      sigma_re_term = 0L,
      sigma_re_dpar = 0L,
      sigma_re_cor_id = -1L,
      sigma_re_pair_index = -1L,
      sigma_re_cross_cor = 0L,
      sigma_re_cross_mu = 0L,
      has_phylo_mu = 0L,
      phylo_mu_sd_row = 0L,
      phylo_mu_node_index = 0L,
      Q_phylo = dummy_sparse,
      log_det_Q_phylo = 0
    ))
  }
  if (identical(spec$model_type, "lognormal")) {
    re_mu <- spec$random$mu
    sd_mu <- spec$random_scale$mu
    return(list(
      model_type = 4L,
      y = spec$y,
      trials = tmb_trials,
      weights = spec$weights,
      offset_mu = offset_mu,
      V_known = spec$V_known_diag,
      V_known_matrix = dummy_matrix,
      V_known_type = 0L,
      y1 = numeric(1),
      y2 = numeric(1),
      X_mu = spec$X$mu,
      X_sigma = spec$X$sigma,
      X_nu = dummy_matrix,
      X_zi = dummy_matrix,
      X_sd_mu = sd_mu$X,
      has_sd_mu_model = 0L,
      X_sd_phylo = dummy_matrix,
      report_group_sd = 0L,
      has_sd_phylo_model = 0L,
      sd_phylo_beta_offset = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
      X_cor_mu = dummy_matrix,
      has_cor_mu_model = 0L,
      n_mu_re_terms = re_mu$n_terms,
      n_mu_re_cors = 0L,
      mu_re_index = re_mu$index0,
      mu_re_value = re_mu$value,
      mu_re_term = re_mu$term_id0,
      mu_re_dpar = re_mu$dpar_id0,
      mu_re_pos = re_mu$re_pos0,
      mu_re_cor_id = re_mu$re_cor_id0,
      mu_re_pair_index = re_mu$re_pair_index0,
      mu_re_sd_row = sd_mu$re_sd_row0,
      n_sigma_re_terms = 0L,
      n_sigma_re_cors = 0L,
      n_mu_sigma_re_cors = 0L,
      sigma_re_index = matrix(0L, nrow = 1L, ncol = 1L),
      sigma_re_value = dummy_matrix,
      sigma_re_term = 0L,
      sigma_re_dpar = 0L,
      sigma_re_cor_id = -1L,
      sigma_re_pair_index = -1L,
      sigma_re_cross_cor = 0L,
      sigma_re_cross_mu = 0L,
      has_phylo_mu = 0L,
      phylo_mu_sd_row = 0L,
      phylo_mu_node_index = 0L,
      Q_phylo = dummy_sparse,
      log_det_Q_phylo = 0
    ))
  }
  if (identical(spec$model_type, "gamma")) {
    re_mu <- spec$random$mu
    sd_mu <- spec$random_scale$mu
    phylo_mu <- spec$structured$phylo_mu
    return(list(
      model_type = 5L,
      y = spec$y,
      trials = tmb_trials,
      weights = spec$weights,
      offset_mu = offset_mu,
      V_known = spec$V_known_diag,
      V_known_matrix = dummy_matrix,
      V_known_type = 0L,
      y1 = numeric(1),
      y2 = numeric(1),
      X_mu = spec$X$mu,
      X_sigma = spec$X$sigma,
      X_nu = dummy_matrix,
      X_zi = dummy_matrix,
      X_sd_mu = sd_mu$X,
      has_sd_mu_model = 0L,
      X_sd_phylo = dummy_matrix,
      report_group_sd = 0L,
      has_sd_phylo_model = 0L,
      sd_phylo_beta_offset = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
      X_cor_mu = dummy_matrix,
      has_cor_mu_model = 0L,
      n_mu_re_terms = re_mu$n_terms,
      n_mu_re_cors = 0L,
      mu_re_index = re_mu$index0,
      mu_re_value = re_mu$value,
      mu_re_term = re_mu$term_id0,
      mu_re_dpar = re_mu$dpar_id0,
      mu_re_pos = re_mu$re_pos0,
      mu_re_cor_id = re_mu$re_cor_id0,
      mu_re_pair_index = re_mu$re_pair_index0,
      mu_re_sd_row = sd_mu$re_sd_row0,
      n_sigma_re_terms = 0L,
      n_sigma_re_cors = 0L,
      n_mu_sigma_re_cors = 0L,
      sigma_re_index = matrix(0L, nrow = 1L, ncol = 1L),
      sigma_re_value = dummy_matrix,
      sigma_re_term = 0L,
      sigma_re_dpar = 0L,
      sigma_re_cor_id = -1L,
      sigma_re_pair_index = -1L,
      sigma_re_cross_cor = 0L,
      sigma_re_cross_mu = 0L,
      has_phylo_mu = as.integer(isTRUE(phylo_mu$has)),
      phylo_mu_sd_row = 0L,
      phylo_mu_node_index = if (isTRUE(phylo_mu$has)) {
        phylo_mu$observation_node_index0
      } else {
        0L
      },
      Q_phylo = if (isTRUE(phylo_mu$has)) {
        phylo_mu$precision$precision
      } else {
        dummy_sparse
      },
      log_det_Q_phylo = if (isTRUE(phylo_mu$has)) {
        phylo_mu$precision$log_det_precision
      } else {
        0
      }
    ))
  }
  if (identical(spec$model_type, "tweedie")) {
    re_mu <- spec$random$mu
    sd_mu <- spec$random_scale$mu
    return(list(
      model_type = 16L,
      y = spec$y,
      trials = tmb_trials,
      weights = spec$weights,
      offset_mu = offset_mu,
      V_known = spec$V_known_diag,
      V_known_matrix = dummy_matrix,
      V_known_type = 0L,
      y1 = numeric(1),
      y2 = numeric(1),
      X_mu = spec$X$mu,
      X_sigma = spec$X$sigma,
      X_nu = spec$X$nu,
      X_zi = dummy_matrix,
      X_sd_mu = sd_mu$X,
      has_sd_mu_model = 0L,
      X_sd_phylo = dummy_matrix,
      report_group_sd = 0L,
      has_sd_phylo_model = 0L,
      sd_phylo_beta_offset = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
      X_cor_mu = dummy_matrix,
      has_cor_mu_model = 0L,
      n_mu_re_terms = re_mu$n_terms,
      n_mu_re_cors = 0L,
      mu_re_index = re_mu$index0,
      mu_re_value = re_mu$value,
      mu_re_term = re_mu$term_id0,
      mu_re_dpar = re_mu$dpar_id0,
      mu_re_pos = re_mu$re_pos0,
      mu_re_cor_id = re_mu$re_cor_id0,
      mu_re_pair_index = re_mu$re_pair_index0,
      mu_re_sd_row = sd_mu$re_sd_row0,
      n_sigma_re_terms = 0L,
      n_sigma_re_cors = 0L,
      n_mu_sigma_re_cors = 0L,
      sigma_re_index = matrix(0L, nrow = 1L, ncol = 1L),
      sigma_re_value = dummy_matrix,
      sigma_re_term = 0L,
      sigma_re_dpar = 0L,
      sigma_re_cor_id = -1L,
      sigma_re_pair_index = -1L,
      sigma_re_cross_cor = 0L,
      sigma_re_cross_mu = 0L,
      has_phylo_mu = 0L,
      phylo_mu_sd_row = 0L,
      phylo_mu_node_index = 0L,
      Q_phylo = dummy_sparse,
      log_det_Q_phylo = 0
    ))
  }
  if (identical(spec$model_type, "beta")) {
    re_mu <- spec$random$mu
    sd_mu <- spec$random_scale$mu
    phylo_mu <- spec$structured$phylo_mu
    return(list(
      model_type = 10L,
      y = spec$y,
      trials = tmb_trials,
      weights = spec$weights,
      offset_mu = offset_mu,
      V_known = spec$V_known_diag,
      V_known_matrix = dummy_matrix,
      V_known_type = 0L,
      y1 = numeric(1),
      y2 = numeric(1),
      X_mu = spec$X$mu,
      X_sigma = spec$X$sigma,
      X_nu = dummy_matrix,
      X_zi = dummy_matrix,
      X_sd_mu = sd_mu$X,
      has_sd_mu_model = 0L,
      X_sd_phylo = dummy_matrix,
      report_group_sd = 0L,
      has_sd_phylo_model = 0L,
      sd_phylo_beta_offset = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
      X_cor_mu = dummy_matrix,
      has_cor_mu_model = 0L,
      n_mu_re_terms = re_mu$n_terms,
      n_mu_re_cors = 0L,
      mu_re_index = re_mu$index0,
      mu_re_value = re_mu$value,
      mu_re_term = re_mu$term_id0,
      mu_re_dpar = re_mu$dpar_id0,
      mu_re_pos = re_mu$re_pos0,
      mu_re_cor_id = re_mu$re_cor_id0,
      mu_re_pair_index = re_mu$re_pair_index0,
      mu_re_sd_row = sd_mu$re_sd_row0,
      n_sigma_re_terms = 0L,
      n_sigma_re_cors = 0L,
      n_mu_sigma_re_cors = 0L,
      sigma_re_index = matrix(0L, nrow = 1L, ncol = 1L),
      sigma_re_value = dummy_matrix,
      sigma_re_term = 0L,
      sigma_re_dpar = 0L,
      sigma_re_cor_id = -1L,
      sigma_re_pair_index = -1L,
      sigma_re_cross_cor = 0L,
      sigma_re_cross_mu = 0L,
      has_phylo_mu = as.integer(isTRUE(phylo_mu$has)),
      phylo_mu_sd_row = 0L,
      phylo_mu_node_index = if (isTRUE(phylo_mu$has)) {
        phylo_mu$observation_node_index0
      } else {
        0L
      },
      Q_phylo = if (isTRUE(phylo_mu$has)) {
        phylo_mu$precision$precision
      } else {
        dummy_sparse
      },
      log_det_Q_phylo = if (isTRUE(phylo_mu$has)) {
        phylo_mu$precision$log_det_precision
      } else {
        0
      }
    ))
  }
  if (identical(spec$model_type, "zero_one_beta")) {
    return(list(
      model_type = 15L,
      y = spec$y,
      trials = tmb_trials,
      weights = spec$weights,
      offset_mu = offset_mu,
      V_known = spec$V_known_diag,
      V_known_matrix = dummy_matrix,
      V_known_type = 0L,
      y1 = numeric(1),
      y2 = numeric(1),
      X_mu = spec$X$mu,
      X_sigma = spec$X$sigma,
      X_nu = spec$X$coi,
      X_zi = spec$X$zoi,
      X_sd_mu = dummy_matrix,
      has_sd_mu_model = 0L,
      X_sd_phylo = dummy_matrix,
      report_group_sd = 0L,
      has_sd_phylo_model = 0L,
      sd_phylo_beta_offset = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
      X_cor_mu = dummy_matrix,
      has_cor_mu_model = 0L,
      n_mu_re_terms = 0L,
      n_mu_re_cors = 0L,
      mu_re_index = matrix(0L, nrow = 1L, ncol = 1L),
      mu_re_value = dummy_matrix,
      mu_re_term = 0L,
      mu_re_dpar = 0L,
      mu_re_pos = 0L,
      mu_re_cor_id = -1L,
      mu_re_pair_index = -1L,
      mu_re_sd_row = -1L,
      n_sigma_re_terms = 0L,
      n_sigma_re_cors = 0L,
      n_mu_sigma_re_cors = 0L,
      sigma_re_index = matrix(0L, nrow = 1L, ncol = 1L),
      sigma_re_value = dummy_matrix,
      sigma_re_term = 0L,
      sigma_re_dpar = 0L,
      sigma_re_cor_id = -1L,
      sigma_re_pair_index = -1L,
      sigma_re_cross_cor = 0L,
      sigma_re_cross_mu = 0L,
      has_phylo_mu = 0L,
      phylo_mu_sd_row = 0L,
      phylo_mu_node_index = 0L,
      Q_phylo = dummy_sparse,
      log_det_Q_phylo = 0
    ))
  }
  if (identical(spec$model_type, "beta_binomial")) {
    re_mu <- spec$random$mu
    sd_mu <- spec$random_scale$mu
    return(list(
      model_type = 14L,
      y = spec$y,
      trials = tmb_trials,
      weights = spec$weights,
      offset_mu = offset_mu,
      V_known = spec$V_known_diag,
      V_known_matrix = dummy_matrix,
      V_known_type = 0L,
      y1 = numeric(1),
      y2 = numeric(1),
      X_mu = spec$X$mu,
      X_sigma = spec$X$sigma,
      X_nu = dummy_matrix,
      X_zi = dummy_matrix,
      X_sd_mu = sd_mu$X,
      has_sd_mu_model = 0L,
      X_sd_phylo = dummy_matrix,
      report_group_sd = 0L,
      has_sd_phylo_model = 0L,
      sd_phylo_beta_offset = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
      X_cor_mu = dummy_matrix,
      has_cor_mu_model = 0L,
      n_mu_re_terms = re_mu$n_terms,
      n_mu_re_cors = 0L,
      mu_re_index = re_mu$index0,
      mu_re_value = re_mu$value,
      mu_re_term = re_mu$term_id0,
      mu_re_dpar = re_mu$dpar_id0,
      mu_re_pos = re_mu$re_pos0,
      mu_re_cor_id = re_mu$re_cor_id0,
      mu_re_pair_index = re_mu$re_pair_index0,
      mu_re_sd_row = sd_mu$re_sd_row0,
      n_sigma_re_terms = 0L,
      n_sigma_re_cors = 0L,
      n_mu_sigma_re_cors = 0L,
      sigma_re_index = matrix(0L, nrow = 1L, ncol = 1L),
      sigma_re_value = dummy_matrix,
      sigma_re_term = 0L,
      sigma_re_dpar = 0L,
      sigma_re_cor_id = -1L,
      sigma_re_pair_index = -1L,
      sigma_re_cross_cor = 0L,
      sigma_re_cross_mu = 0L,
      has_phylo_mu = 0L,
      phylo_mu_sd_row = 0L,
      phylo_mu_node_index = 0L,
      Q_phylo = dummy_sparse,
      log_det_Q_phylo = 0
    ))
  }
  if (identical(spec$model_type, "binomial")) {
    return(list(
      model_type = 18L,
      y = spec$y,
      trials = tmb_trials,
      weights = spec$weights,
      offset_mu = offset_mu,
      V_known = spec$V_known_diag,
      V_known_matrix = dummy_matrix,
      V_known_type = 0L,
      y1 = numeric(1),
      y2 = numeric(1),
      X_mu = spec$X$mu,
      X_sigma = dummy_matrix,
      X_nu = dummy_matrix,
      X_zi = dummy_matrix,
      X_sd_mu = dummy_matrix,
      has_sd_mu_model = 0L,
      X_sd_phylo = dummy_matrix,
      report_group_sd = 0L,
      has_sd_phylo_model = 0L,
      sd_phylo_beta_offset = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
      X_cor_mu = dummy_matrix,
      has_cor_mu_model = 0L,
      n_mu_re_terms = 0L,
      n_mu_re_cors = 0L,
      mu_re_index = matrix(0L, nrow = 1L, ncol = 1L),
      mu_re_value = dummy_matrix,
      mu_re_term = 0L,
      mu_re_dpar = 0L,
      mu_re_pos = 0L,
      mu_re_cor_id = -1L,
      mu_re_pair_index = -1L,
      mu_re_sd_row = -1L,
      n_sigma_re_terms = 0L,
      n_sigma_re_cors = 0L,
      n_mu_sigma_re_cors = 0L,
      sigma_re_index = matrix(0L, nrow = 1L, ncol = 1L),
      sigma_re_value = dummy_matrix,
      sigma_re_term = 0L,
      sigma_re_dpar = 0L,
      sigma_re_cor_id = -1L,
      sigma_re_pair_index = -1L,
      sigma_re_cross_cor = 0L,
      sigma_re_cross_mu = 0L,
      has_phylo_mu = 0L,
      phylo_mu_sd_row = 0L,
      phylo_mu_node_index = 0L,
      Q_phylo = dummy_sparse,
      log_det_Q_phylo = 0
    ))
  }
  if (identical(spec$model_type, "cumulative_logit")) {
    phylo_mu <- spec$structured$phylo_mu
    return(list(
      model_type = 13L,
      y = spec$y,
      trials = tmb_trials,
      weights = spec$weights,
      offset_mu = offset_mu,
      V_known = spec$V_known_diag,
      V_known_matrix = dummy_matrix,
      V_known_type = 0L,
      y1 = numeric(1),
      y2 = numeric(1),
      X_mu = spec$X$mu,
      X_sigma = dummy_matrix,
      X_nu = dummy_matrix,
      X_zi = dummy_matrix,
      X_sd_mu = dummy_matrix,
      has_sd_mu_model = 0L,
      X_sd_phylo = dummy_matrix,
      report_group_sd = 0L,
      has_sd_phylo_model = 0L,
      sd_phylo_beta_offset = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
      X_cor_mu = dummy_matrix,
      has_cor_mu_model = 0L,
      n_mu_re_terms = 0L,
      n_mu_re_cors = 0L,
      mu_re_index = matrix(0L, nrow = 1L, ncol = 1L),
      mu_re_value = dummy_matrix,
      mu_re_term = 0L,
      mu_re_dpar = 0L,
      mu_re_pos = 0L,
      mu_re_cor_id = -1L,
      mu_re_pair_index = -1L,
      mu_re_sd_row = -1L,
      n_sigma_re_terms = 0L,
      n_sigma_re_cors = 0L,
      n_mu_sigma_re_cors = 0L,
      sigma_re_index = matrix(0L, nrow = 1L, ncol = 1L),
      sigma_re_value = dummy_matrix,
      sigma_re_term = 0L,
      sigma_re_dpar = 0L,
      sigma_re_cor_id = -1L,
      sigma_re_pair_index = -1L,
      sigma_re_cross_cor = 0L,
      sigma_re_cross_mu = 0L,
      has_phylo_mu = as.integer(isTRUE(phylo_mu$has)),
      phylo_mu_sd_row = 0L,
      phylo_mu_node_index = if (isTRUE(phylo_mu$has)) {
        phylo_mu$observation_node_index0
      } else {
        0L
      },
      Q_phylo = if (isTRUE(phylo_mu$has)) {
        phylo_mu$precision$precision
      } else {
        dummy_sparse
      },
      log_det_Q_phylo = if (isTRUE(phylo_mu$has)) {
        phylo_mu$precision$log_det_precision
      } else {
        0
      }
    ))
  }
  if (identical(spec$model_type, "poisson")) {
    phylo_mu <- spec$structured$phylo_mu
    return(list(
      model_type = 6L,
      y = spec$y,
      trials = tmb_trials,
      weights = spec$weights,
      offset_mu = offset_mu,
      V_known = spec$V_known_diag,
      V_known_matrix = dummy_matrix,
      V_known_type = 0L,
      y1 = numeric(1),
      y2 = numeric(1),
      X_mu = spec$X$mu,
      X_sigma = dummy_matrix,
      X_nu = dummy_matrix,
      X_zi = dummy_matrix,
      X_sd_mu = spec$random_scale$mu$X,
      has_sd_mu_model = 0L,
      X_sd_phylo = dummy_matrix,
      report_group_sd = 0L,
      has_sd_phylo_model = 0L,
      sd_phylo_beta_offset = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
      X_cor_mu = dummy_matrix,
      has_cor_mu_model = 0L,
      n_mu_re_terms = spec$random$mu$n_terms,
      n_mu_re_cors = spec$random$mu$n_cors,
      mu_re_index = spec$random$mu$index0,
      mu_re_value = spec$random$mu$value,
      mu_re_term = spec$random$mu$term_id0,
      mu_re_dpar = spec$random$mu$dpar_id0,
      mu_re_pos = spec$random$mu$re_pos0,
      mu_re_cor_id = spec$random$mu$re_cor_id0,
      mu_re_pair_index = spec$random$mu$re_pair_index0,
      mu_re_sd_row = spec$random_scale$mu$re_sd_row0,
      n_sigma_re_terms = 0L,
      n_sigma_re_cors = 0L,
      n_mu_sigma_re_cors = 0L,
      sigma_re_index = matrix(0L, nrow = 1L, ncol = 1L),
      sigma_re_value = dummy_matrix,
      sigma_re_term = 0L,
      sigma_re_dpar = 0L,
      sigma_re_cor_id = -1L,
      sigma_re_pair_index = -1L,
      sigma_re_cross_cor = 0L,
      sigma_re_cross_mu = 0L,
      has_phylo_mu = as.integer(isTRUE(phylo_mu$has)),
      phylo_mu_sd_row = 0L,
      phylo_mu_node_index = if (isTRUE(phylo_mu$has)) {
        phylo_mu$observation_node_index0
      } else {
        0L
      },
      Q_phylo = if (isTRUE(phylo_mu$has)) {
        phylo_mu$precision$precision
      } else {
        dummy_sparse
      },
      log_det_Q_phylo = if (isTRUE(phylo_mu$has)) {
        phylo_mu$precision$log_det_precision
      } else {
        0
      }
    ))
  }
  if (identical(spec$model_type, "zi_poisson")) {
    phylo_mu <- spec$structured$phylo_mu
    return(list(
      model_type = 8L,
      y = spec$y,
      trials = tmb_trials,
      weights = spec$weights,
      offset_mu = offset_mu,
      V_known = spec$V_known_diag,
      V_known_matrix = dummy_matrix,
      V_known_type = 0L,
      y1 = numeric(1),
      y2 = numeric(1),
      X_mu = spec$X$mu,
      X_sigma = dummy_matrix,
      X_nu = dummy_matrix,
      X_zi = spec$X$zi,
      X_sd_mu = dummy_matrix,
      has_sd_mu_model = 0L,
      X_sd_phylo = dummy_matrix,
      report_group_sd = 0L,
      has_sd_phylo_model = 0L,
      sd_phylo_beta_offset = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
      X_cor_mu = dummy_matrix,
      has_cor_mu_model = 0L,
      n_mu_re_terms = 0L,
      n_mu_re_cors = 0L,
      mu_re_index = matrix(0L, nrow = 1L, ncol = 1L),
      mu_re_value = dummy_matrix,
      mu_re_term = 0L,
      mu_re_dpar = 0L,
      mu_re_pos = 0L,
      mu_re_cor_id = -1L,
      mu_re_pair_index = -1L,
      mu_re_sd_row = -1L,
      n_sigma_re_terms = 0L,
      n_sigma_re_cors = 0L,
      n_mu_sigma_re_cors = 0L,
      sigma_re_index = matrix(0L, nrow = 1L, ncol = 1L),
      sigma_re_value = dummy_matrix,
      sigma_re_term = 0L,
      sigma_re_dpar = 0L,
      sigma_re_cor_id = -1L,
      sigma_re_pair_index = -1L,
      sigma_re_cross_cor = 0L,
      sigma_re_cross_mu = 0L,
      has_phylo_mu = as.integer(isTRUE(phylo_mu$has)),
      phylo_mu_sd_row = 0L,
      phylo_mu_node_index = if (isTRUE(phylo_mu$has)) {
        phylo_mu$observation_node_index0
      } else {
        0L
      },
      Q_phylo = if (isTRUE(phylo_mu$has)) {
        phylo_mu$precision$precision
      } else {
        dummy_sparse
      },
      log_det_Q_phylo = if (isTRUE(phylo_mu$has)) {
        phylo_mu$precision$log_det_precision
      } else {
        0
      }
    ))
  }
  if (identical(spec$model_type, "nbinom2")) {
    re_mu <- spec$random$mu
    re_sigma <- spec$random$sigma
    sd_mu <- spec$random_scale$mu
    phylo_mu <- spec$structured$phylo_mu
    return(list(
      model_type = 7L,
      y = spec$y,
      trials = tmb_trials,
      weights = spec$weights,
      offset_mu = offset_mu,
      V_known = spec$V_known_diag,
      V_known_matrix = dummy_matrix,
      V_known_type = 0L,
      y1 = numeric(1),
      y2 = numeric(1),
      X_mu = spec$X$mu,
      X_sigma = spec$X$sigma,
      X_nu = dummy_matrix,
      X_zi = dummy_matrix,
      X_sd_mu = sd_mu$X,
      has_sd_mu_model = 0L,
      X_sd_phylo = dummy_matrix,
      report_group_sd = 0L,
      has_sd_phylo_model = 0L,
      sd_phylo_beta_offset = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
      X_cor_mu = dummy_matrix,
      has_cor_mu_model = 0L,
      n_mu_re_terms = re_mu$n_terms,
      n_mu_re_cors = re_mu$n_cors,
      mu_re_index = re_mu$index0,
      mu_re_value = re_mu$value,
      mu_re_term = re_mu$term_id0,
      mu_re_dpar = re_mu$dpar_id0,
      mu_re_pos = re_mu$re_pos0,
      mu_re_cor_id = re_mu$re_cor_id0,
      mu_re_pair_index = re_mu$re_pair_index0,
      mu_re_sd_row = sd_mu$re_sd_row0,
      n_sigma_re_terms = re_sigma$n_terms,
      n_sigma_re_cors = re_sigma$n_cors,
      n_mu_sigma_re_cors = 0L,
      sigma_re_index = re_sigma$index0,
      sigma_re_value = re_sigma$value,
      sigma_re_term = re_sigma$term_id0,
      sigma_re_dpar = re_sigma$dpar_id0,
      sigma_re_cor_id = re_sigma$re_cor_id0,
      sigma_re_pair_index = re_sigma$re_pair_index0,
      sigma_re_cross_cor = 0L,
      sigma_re_cross_mu = 0L,
      has_phylo_mu = as.integer(isTRUE(phylo_mu$has)),
      phylo_mu_sd_row = 0L,
      phylo_mu_node_index = if (isTRUE(phylo_mu$has)) {
        phylo_mu$observation_node_index0
      } else {
        0L
      },
      Q_phylo = if (isTRUE(phylo_mu$has)) {
        phylo_mu$precision$precision
      } else {
        dummy_sparse
      },
      log_det_Q_phylo = if (isTRUE(phylo_mu$has)) {
        phylo_mu$precision$log_det_precision
      } else {
        0
      }
    ))
  }
  if (identical(spec$model_type, "truncated_nbinom2")) {
    re_mu <- spec$random$mu
    sd_mu <- spec$random_scale$mu
    return(list(
      model_type = 11L,
      y = spec$y,
      trials = tmb_trials,
      weights = spec$weights,
      offset_mu = offset_mu,
      V_known = spec$V_known_diag,
      V_known_matrix = dummy_matrix,
      V_known_type = 0L,
      y1 = numeric(1),
      y2 = numeric(1),
      X_mu = spec$X$mu,
      X_sigma = spec$X$sigma,
      X_nu = dummy_matrix,
      X_zi = dummy_matrix,
      X_sd_mu = sd_mu$X,
      has_sd_mu_model = 0L,
      X_sd_phylo = dummy_matrix,
      report_group_sd = 0L,
      has_sd_phylo_model = 0L,
      sd_phylo_beta_offset = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
      X_cor_mu = dummy_matrix,
      has_cor_mu_model = 0L,
      n_mu_re_terms = re_mu$n_terms,
      n_mu_re_cors = 0L,
      mu_re_index = re_mu$index0,
      mu_re_value = re_mu$value,
      mu_re_term = re_mu$term_id0,
      mu_re_dpar = re_mu$dpar_id0,
      mu_re_pos = re_mu$re_pos0,
      mu_re_cor_id = re_mu$re_cor_id0,
      mu_re_pair_index = re_mu$re_pair_index0,
      mu_re_sd_row = sd_mu$re_sd_row0,
      n_sigma_re_terms = 0L,
      n_sigma_re_cors = 0L,
      n_mu_sigma_re_cors = 0L,
      sigma_re_index = matrix(0L, nrow = 1L, ncol = 1L),
      sigma_re_value = dummy_matrix,
      sigma_re_term = 0L,
      sigma_re_dpar = 0L,
      sigma_re_cor_id = -1L,
      sigma_re_pair_index = -1L,
      sigma_re_cross_cor = 0L,
      sigma_re_cross_mu = 0L,
      has_phylo_mu = 0L,
      phylo_mu_sd_row = 0L,
      phylo_mu_node_index = 0L,
      Q_phylo = dummy_sparse,
      log_det_Q_phylo = 0
    ))
  }
  if (identical(spec$model_type, "hurdle_nbinom2")) {
    phylo_mu <- spec$structured$phylo_mu
    return(list(
      model_type = 12L,
      y = spec$y,
      trials = tmb_trials,
      weights = spec$weights,
      offset_mu = offset_mu,
      V_known = spec$V_known_diag,
      V_known_matrix = dummy_matrix,
      V_known_type = 0L,
      y1 = numeric(1),
      y2 = numeric(1),
      X_mu = spec$X$mu,
      X_sigma = spec$X$sigma,
      X_nu = dummy_matrix,
      X_zi = spec$X$hu,
      X_sd_mu = dummy_matrix,
      has_sd_mu_model = 0L,
      X_sd_phylo = dummy_matrix,
      report_group_sd = 0L,
      has_sd_phylo_model = 0L,
      sd_phylo_beta_offset = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
      X_cor_mu = dummy_matrix,
      has_cor_mu_model = 0L,
      n_mu_re_terms = 0L,
      n_mu_re_cors = 0L,
      mu_re_index = matrix(0L, nrow = 1L, ncol = 1L),
      mu_re_value = dummy_matrix,
      mu_re_term = 0L,
      mu_re_dpar = 0L,
      mu_re_pos = 0L,
      mu_re_cor_id = -1L,
      mu_re_pair_index = -1L,
      mu_re_sd_row = -1L,
      n_sigma_re_terms = 0L,
      n_sigma_re_cors = 0L,
      n_mu_sigma_re_cors = 0L,
      sigma_re_index = matrix(0L, nrow = 1L, ncol = 1L),
      sigma_re_value = dummy_matrix,
      sigma_re_term = 0L,
      sigma_re_dpar = 0L,
      sigma_re_cor_id = -1L,
      sigma_re_pair_index = -1L,
      sigma_re_cross_cor = 0L,
      sigma_re_cross_mu = 0L,
      has_phylo_mu = as.integer(isTRUE(phylo_mu$has)),
      phylo_mu_sd_row = 0L,
      phylo_mu_node_index = if (isTRUE(phylo_mu$has)) {
        phylo_mu$observation_node_index0
      } else {
        0L
      },
      Q_phylo = if (isTRUE(phylo_mu$has)) {
        phylo_mu$precision$precision
      } else {
        dummy_sparse
      },
      log_det_Q_phylo = if (isTRUE(phylo_mu$has)) {
        phylo_mu$precision$log_det_precision
      } else {
        0
      }
    ))
  }
  if (identical(spec$model_type, "zi_nbinom2")) {
    phylo_mu <- spec$structured$phylo_mu
    return(list(
      model_type = 9L,
      y = spec$y,
      trials = tmb_trials,
      weights = spec$weights,
      offset_mu = offset_mu,
      V_known = spec$V_known_diag,
      V_known_matrix = dummy_matrix,
      V_known_type = 0L,
      y1 = numeric(1),
      y2 = numeric(1),
      X_mu = spec$X$mu,
      X_sigma = spec$X$sigma,
      X_nu = dummy_matrix,
      X_zi = spec$X$zi,
      X_sd_mu = dummy_matrix,
      has_sd_mu_model = 0L,
      X_sd_phylo = dummy_matrix,
      report_group_sd = 0L,
      has_sd_phylo_model = 0L,
      sd_phylo_beta_offset = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
      X_cor_mu = dummy_matrix,
      has_cor_mu_model = 0L,
      n_mu_re_terms = 0L,
      n_mu_re_cors = 0L,
      mu_re_index = matrix(0L, nrow = 1L, ncol = 1L),
      mu_re_value = dummy_matrix,
      mu_re_term = 0L,
      mu_re_dpar = 0L,
      mu_re_pos = 0L,
      mu_re_cor_id = -1L,
      mu_re_pair_index = -1L,
      mu_re_sd_row = -1L,
      n_sigma_re_terms = 0L,
      n_sigma_re_cors = 0L,
      n_mu_sigma_re_cors = 0L,
      sigma_re_index = matrix(0L, nrow = 1L, ncol = 1L),
      sigma_re_value = dummy_matrix,
      sigma_re_term = 0L,
      sigma_re_dpar = 0L,
      sigma_re_cor_id = -1L,
      sigma_re_pair_index = -1L,
      sigma_re_cross_cor = 0L,
      sigma_re_cross_mu = 0L,
      has_phylo_mu = as.integer(isTRUE(phylo_mu$has)),
      phylo_mu_sd_row = 0L,
      phylo_mu_node_index = if (isTRUE(phylo_mu$has)) {
        phylo_mu$observation_node_index0
      } else {
        0L
      },
      Q_phylo = if (isTRUE(phylo_mu$has)) {
        phylo_mu$precision$precision
      } else {
        dummy_sparse
      },
      log_det_Q_phylo = if (isTRUE(phylo_mu$has)) {
        phylo_mu$precision$log_det_precision
      } else {
        0
      }
    ))
  }
  if (identical(spec$model_type, "biv_gaussian")) {
    phylo_mu <- spec$structured$phylo_mu
    return(list(
      model_type = 2L,
      y = numeric(1),
      trials = numeric(1),
      weights = spec$weights,
      offset_mu = offset_mu,
      V_known = spec$V_known_diag,
      V_known_matrix = if (identical(spec$V_known_type, "matrix")) {
        spec$V_known
      } else {
        dummy_matrix
      },
      V_known_type = as.integer(
        match(spec$V_known_type, c("none", "diagonal", "matrix")) - 1L
      ),
      y1 = spec$y1,
      y2 = spec$y2,
      X_mu = dummy_matrix,
      X_sigma = dummy_matrix,
      X_nu = dummy_matrix,
      X_zi = dummy_matrix,
      X_sd_mu = spec$random_scale$mu$X,
      has_sd_mu_model = as.integer(spec$random_scale$mu$n_models > 0L),
      X_sd_phylo = if (spec$random_scale$phylo$n_models > 0L) {
        spec$random_scale$phylo$X
      } else {
        dummy_matrix
      },
      report_group_sd = 0L,
      has_sd_phylo_model = as.integer(
        spec$random_scale$phylo$n_models > 0L
      ),
      sd_phylo_beta_offset = sd_phylo_beta_offset(spec),
      X_mu1 = spec$X$mu1,
      X_mu2 = spec$X$mu2,
      X_sigma1 = spec$X$sigma1,
      X_sigma2 = spec$X$sigma2,
      X_rho12 = spec$X$rho12,
      n_mu_re_terms = spec$random$mu$n_terms,
      n_mu_re_cors = spec$random$mu$n_cors,
      mu_re_index = spec$random$mu$index0,
      mu_re_value = spec$random$mu$value,
      mu_re_term = spec$random$mu$term_id0,
      mu_re_dpar = spec$random$mu$dpar_id0,
      mu_re_pos = spec$random$mu$re_pos0,
      mu_re_cor_id = spec$random$mu$re_cor_id0,
      mu_re_pair_index = spec$random$mu$re_pair_index0,
      mu_re_sd_row = spec$random_scale$mu$re_sd_row0,
      X_cor_mu = spec$random$mu$cor_model$X_tmb,
      has_cor_mu_model = corpair_model_level_id(spec$random$mu$cor_model),
      n_sigma_re_terms = spec$random$sigma$n_terms,
      n_sigma_re_cors = spec$random$sigma$n_cors,
      n_mu_sigma_re_cors = spec$random$mu_sigma$n_cors,
      sigma_re_index = spec$random$sigma$index0,
      sigma_re_value = spec$random$sigma$value,
      sigma_re_term = spec$random$sigma$term_id0,
      sigma_re_dpar = spec$random$sigma$dpar_id0,
      sigma_re_cor_id = spec$random$sigma$re_cor_id0,
      sigma_re_pair_index = spec$random$sigma$re_pair_index0,
      sigma_re_cross_cor = spec$random$mu_sigma$sigma_cross_cor_id0,
      sigma_re_cross_mu = spec$random$mu_sigma$sigma_cross_mu_index0,
      has_phylo_mu = as.integer(isTRUE(phylo_mu$has)),
      phylo_mu_sd_row = if (spec$random_scale$phylo$n_models > 0L) {
        spec$random_scale$phylo$node_sd_row0
      } else {
        0L
      },
      phylo_mu_node_index = if (isTRUE(phylo_mu$has)) {
        phylo_mu$observation_node_index0
      } else {
        0L
      },
      Q_phylo = if (isTRUE(phylo_mu$has)) {
        phylo_mu$precision$precision
      } else {
        dummy_sparse
      },
      log_det_Q_phylo = if (isTRUE(phylo_mu$has)) {
        phylo_mu$precision$log_det_precision
      } else {
        0
      }
    ))
  }

  model_type <- if (is.null(spec$model_type)) {
    "<NULL>"
  } else {
    as.character(spec$model_type)[[1L]]
  }
  cli::cli_abort(
    "Internal error: unknown {.pkg drmTMB} model type {.val {model_type}}."
  )
}

split_tmb_parameters <- function(par, spec) {
  if (identical(spec$model_type, "poisson")) {
    beta_mu <- unname(par$beta_mu)
    names(beta_mu) <- colnames(spec$X$mu)
    out <- list(mu = beta_mu)
    if (
      is.list(spec$missing_predictor) &&
        isTRUE(spec$missing_predictor$enabled)
    ) {
      beta_mi <- unname(par$beta_mi)
      names(beta_mi) <- spec$missing_predictor$coef_names
      out[[paste0("mi_", spec$missing_predictor$variable)]] <- beta_mi
    }
    return(out)
  }
  if (identical(spec$model_type, "binomial")) {
    beta_mu <- unname(par$beta_mu)
    names(beta_mu) <- colnames(spec$X$mu)
    return(list(mu = beta_mu))
  }
  if (identical(spec$model_type, "zi_poisson")) {
    beta_mu <- unname(par$beta_mu)
    beta_zi <- unname(par$beta_zi)
    names(beta_mu) <- colnames(spec$X$mu)
    names(beta_zi) <- colnames(spec$X$zi)
    return(list(mu = beta_mu, zi = beta_zi))
  }
  if (identical(spec$model_type, "zi_nbinom2")) {
    beta_mu <- unname(par$beta_mu)
    beta_sigma <- unname(par$beta_sigma)
    beta_zi <- unname(par$beta_zi)
    names(beta_mu) <- colnames(spec$X$mu)
    names(beta_sigma) <- colnames(spec$X$sigma)
    names(beta_zi) <- colnames(spec$X$zi)
    return(list(mu = beta_mu, sigma = beta_sigma, zi = beta_zi))
  }
  if (identical(spec$model_type, "hurdle_nbinom2")) {
    beta_mu <- unname(par$beta_mu)
    beta_sigma <- unname(par$beta_sigma)
    beta_hu <- unname(par$beta_zi)
    names(beta_mu) <- colnames(spec$X$mu)
    names(beta_sigma) <- colnames(spec$X$sigma)
    names(beta_hu) <- colnames(spec$X$hu)
    return(list(mu = beta_mu, sigma = beta_sigma, hu = beta_hu))
  }
  if (identical(spec$model_type, "cumulative_logit")) {
    beta_mu <- unname(par$beta_mu)
    names(beta_mu) <- colnames(spec$X$mu)
    return(list(mu = beta_mu))
  }
  if (identical(spec$model_type, "zero_one_beta")) {
    beta_mu <- unname(par$beta_mu)
    beta_sigma <- unname(par$beta_sigma)
    beta_zoi <- unname(par$beta_zoi)
    beta_coi <- unname(par$beta_coi)
    names(beta_mu) <- colnames(spec$X$mu)
    names(beta_sigma) <- colnames(spec$X$sigma)
    names(beta_zoi) <- colnames(spec$X$zoi)
    names(beta_coi) <- colnames(spec$X$coi)
    return(list(
      mu = beta_mu,
      sigma = beta_sigma,
      zoi = beta_zoi,
      coi = beta_coi
    ))
  }

  if (
    identical(spec$model_type, "gaussian") ||
      identical(spec$model_type, "student") ||
      identical(spec$model_type, "skew_normal") ||
      identical(spec$model_type, "lognormal") ||
      identical(spec$model_type, "gamma") ||
      identical(spec$model_type, "tweedie") ||
      identical(spec$model_type, "beta") ||
      identical(spec$model_type, "beta_binomial") ||
      identical(spec$model_type, "nbinom2") ||
      identical(spec$model_type, "truncated_nbinom2")
  ) {
    beta_mu <- unname(par$beta_mu)
    beta_sigma <- unname(par$beta_sigma)
    names(beta_mu) <- colnames(spec$X$mu)
    names(beta_sigma) <- colnames(spec$X$sigma)
    out <- list(mu = beta_mu, sigma = beta_sigma)
    if (
      identical(spec$model_type, "student") ||
        identical(spec$model_type, "skew_normal") ||
        identical(spec$model_type, "tweedie")
    ) {
      beta_nu <- unname(par$beta_nu)
      names(beta_nu) <- colnames(spec$X$nu)
      out$nu <- beta_nu
      return(out)
    }
    if (spec$random_scale$mu$n_models > 0L) {
      beta_sd_mu <- unname(par$beta_sd_mu[seq_len(ncol(
        spec$random_scale$mu$X
      ))])
      for (dpar in spec$random_scale$mu$dpars) {
        coef_index <- spec$random_scale$mu$coef_index[[dpar]]
        beta_sd_mu_dpar <- beta_sd_mu[coef_index]
        names(beta_sd_mu_dpar) <- spec$random_scale$mu$coef_names_list[[dpar]]
        out[[dpar]] <- beta_sd_mu_dpar
      }
    }
    if (
      is.list(spec$random_scale$phylo) &&
        spec$random_scale$phylo$n_models > 0L
    ) {
      offset <- sd_phylo_beta_offset(spec)
      beta_sd_phylo <- unname(par$beta_sd_mu[
        offset + seq_len(ncol(spec$random_scale$phylo$X))
      ])
      for (dpar in spec$random_scale$phylo$dpars) {
        coef_index <- spec$random_scale$phylo$coef_index[[dpar]]
        beta_sd_phylo_dpar <- beta_sd_phylo[coef_index]
        names(beta_sd_phylo_dpar) <-
          spec$random_scale$phylo$coef_names_list[[dpar]]
        out[[dpar]] <- beta_sd_phylo_dpar
      }
    }
    if (
      identical(spec$model_type, "gaussian") &&
        is.list(spec$missing_predictor) &&
        isTRUE(spec$missing_predictor$enabled)
    ) {
      beta_mi <- unname(par$beta_mi)
      names(beta_mi) <- spec$missing_predictor$coef_names
      out[[paste0("mi_", spec$missing_predictor$variable)]] <- beta_mi
      if (
        spec$missing_predictor$family %in%
          c(
            "gaussian",
            "beta",
            "zero_one_beta",
            "beta_binomial",
            "lognormal",
            "gamma",
            "nbinom2",
            "truncated_nbinom2",
            "tweedie"
          )
      ) {
        out[[paste0("sigma_mi_", spec$missing_predictor$variable)]] <-
          stats::setNames(
            exp(unname(par$log_sigma_mi)),
            spec$missing_predictor$variable
          )
      }
      if (identical(spec$missing_predictor$family, "zero_one_beta")) {
        out[[paste0("zoi_mi_", spec$missing_predictor$variable)]] <-
          stats::setNames(
            stats::plogis(unname(par$beta_zoi)),
            spec$missing_predictor$variable
          )
        out[[paste0("coi_mi_", spec$missing_predictor$variable)]] <-
          stats::setNames(
            stats::plogis(unname(par$beta_coi)),
            spec$missing_predictor$variable
          )
      }
      if (
        is.list(spec$missing_predictor$random) &&
          isTRUE(spec$missing_predictor$random$enabled)
      ) {
        out[[paste0("sd_mi_group_", spec$missing_predictor$variable)]] <-
          stats::setNames(
            exp(unname(par$log_sd_mi_group)),
            spec$missing_predictor$random$group
          )
      }
      if (
        is.list(spec$missing_predictor$structured) &&
          isTRUE(spec$missing_predictor$structured$enabled)
      ) {
        out[[paste0(
          "sd_mi_",
          spec$missing_predictor$structured$type,
          "_",
          spec$missing_predictor$variable
        )]] <- stats::setNames(
          exp(unname(par$log_sd_mi_struct)),
          spec$missing_predictor$structured$group
        )
      }
    }
    return(out)
  }

  beta_mu1 <- unname(par$beta_mu1)
  beta_mu2 <- unname(par$beta_mu2)
  beta_sigma1 <- unname(par$beta_sigma1)
  beta_sigma2 <- unname(par$beta_sigma2)
  beta_rho12 <- unname(par$beta_rho12)
  names(beta_mu1) <- colnames(spec$X$mu1)
  names(beta_mu2) <- colnames(spec$X$mu2)
  names(beta_sigma1) <- colnames(spec$X$sigma1)
  names(beta_sigma2) <- colnames(spec$X$sigma2)
  names(beta_rho12) <- colnames(spec$X$rho12)

  out <- list(
    mu1 = beta_mu1,
    mu2 = beta_mu2,
    sigma1 = beta_sigma1,
    sigma2 = beta_sigma2,
    rho12 = beta_rho12
  )
  if (has_modelled_corpair_model(spec)) {
    beta_cor_mu <- unname(par$beta_cor_mu[seq_len(ncol(
      spec$random$mu$cor_model$X
    ))])
    names(beta_cor_mu) <- colnames(spec$random$mu$cor_model$X)
    out[[spec$random$mu$cor_model$dpar]] <- beta_cor_mu
  }
  if (spec$random_scale$mu$n_models > 0L) {
    beta_sd_mu <- unname(par$beta_sd_mu[seq_len(ncol(
      spec$random_scale$mu$X
    ))])
    for (dpar in spec$random_scale$mu$dpars) {
      coef_index <- spec$random_scale$mu$coef_index[[dpar]]
      beta_sd_mu_dpar <- beta_sd_mu[coef_index]
      names(beta_sd_mu_dpar) <- spec$random_scale$mu$coef_names_list[[dpar]]
      out[[dpar]] <- beta_sd_mu_dpar
    }
  }
  if (
    is.list(spec$random_scale$phylo) &&
      spec$random_scale$phylo$n_models > 0L
  ) {
    offset <- sd_phylo_beta_offset(spec)
    beta_sd_phylo <- unname(par$beta_sd_mu[
      offset + seq_len(ncol(spec$random_scale$phylo$X))
    ])
    for (dpar in spec$random_scale$phylo$dpars) {
      coef_index <- spec$random_scale$phylo$coef_index[[dpar]]
      beta_sd_phylo_dpar <- beta_sd_phylo[coef_index]
      names(beta_sd_phylo_dpar) <-
        spec$random_scale$phylo$coef_names_list[[dpar]]
      out[[dpar]] <- beta_sd_phylo_dpar
    }
  }
  out
}

sd_phylo_beta_offset <- function(spec) {
  if (
    is.list(spec$random_scale) &&
      is.list(spec$random_scale$mu) &&
      spec$random_scale$mu$n_models > 0L
  ) {
    return(ncol(spec$random_scale$mu$X))
  }
  0L
}

ordinal_fit_info <- function(par, spec) {
  if (!identical(spec$model_type, "cumulative_logit")) {
    return(NULL)
  }
  cutpoints <- ordinal_cutpoints_from_raw(unname(par$theta_ord))
  names(cutpoints) <- ordinal_cutpoint_names(spec$ordinal$levels)
  list(
    response = spec$ordinal$response,
    levels = spec$ordinal$levels,
    n_categories = spec$ordinal$n_categories,
    cutpoints = cutpoints,
    theta_raw = stats::setNames(unname(par$theta_ord), names(cutpoints))
  )
}

ordinal_cutpoint_names <- function(levels) {
  paste0(levels[-length(levels)], "|", levels[-1L])
}

split_tmb_sdpars <- function(par, spec) {
  if (
    !spec$model_type %in%
      c(
        "gaussian",
        "biv_gaussian",
        "student",
        "skew_normal",
        "lognormal",
        "gamma",
        "tweedie",
        "beta",
        "beta_binomial",
        "cumulative_logit",
        "poisson",
        "zi_poisson",
        "nbinom2",
        "zi_nbinom2",
        "truncated_nbinom2",
        "hurdle_nbinom2"
      )
  ) {
    return(list())
  }
  out <- list()
  if (spec$random$mu$n_re > 0L) {
    unmodelled <- seq_len(spec$random$mu$n_terms)
    if (spec$random_scale$mu$n_models > 0L) {
      unmodelled <- setdiff(
        unmodelled,
        unname(spec$random_scale$mu$target_coef)
      )
      for (dpar in spec$random_scale$mu$dpars) {
        sd_group <- sd_mu_group_values(par, spec$random_scale$mu, dpar = dpar)
        names(sd_group) <- paste0(
          dpar,
          ":",
          spec$random_scale$mu$group_levels_list[[dpar]]
        )
        out[[dpar]] <- sd_group
      }
    }
    if (length(unmodelled) > 0L) {
      sd_mu <- exp(unname(par$log_sd_mu[unmodelled]))
      names(sd_mu) <- spec$random$mu$labels[unmodelled]
      out$mu <- sd_mu
    }
  }
  if (spec$random$sigma$n_re > 0L) {
    sd_sigma <- exp(unname(par$log_sd_sigma[seq_len(
      spec$random$sigma$n_terms
    )]))
    names(sd_sigma) <- spec$random$sigma$labels
    out$sigma <- sd_sigma
  }
  if (is.list(spec$random$covariance_blocks)) {
    qgt2_members <- qgt2_covariance_members(spec$random$covariance_blocks)
    if (nrow(qgt2_members) > 0L) {
      sd_re_cov <- exp(unname(par$log_sd_re_cov[seq_len(nrow(qgt2_members))]))
      for (i in seq_len(nrow(qgt2_members))) {
        key <- covariance_registry_member_sd_key(qgt2_members[
          i,
          ,
          drop = FALSE
        ])
        out[[key]] <- c(
          out[[key]],
          stats::setNames(sd_re_cov[[i]], qgt2_members$label[[i]])
        )
      }
    }
  }
  if (isTRUE(spec$structured$phylo_mu$has)) {
    phylo_names <- phylo_mu_sd_labels(
      spec$structured$phylo_mu,
      spec$model_type
    )
    phylo_dpars <- phylo_mu_endpoint_dpars(spec$structured$phylo_mu)
    if (
      is.list(spec$random_scale$phylo) &&
        spec$random_scale$phylo$n_models > 0L
    ) {
      for (dpar in spec$random_scale$phylo$dpars) {
        sd_group <- sd_phylo_group_values(par, spec, dpar = dpar)
        names(sd_group) <- paste0(
          dpar,
          ":",
          spec$random_scale$phylo$group_levels_list[[dpar]]
        )
        out[[dpar]] <- sd_group
      }
      unmodelled <- setdiff(
        seq_along(phylo_names),
        unname(spec$random_scale$phylo$target_endpoint)
      )
      if (length(unmodelled) > 0L) {
        sd_phylo <- stats::setNames(
          exp(unname(par$log_sd_phylo[unmodelled])),
          phylo_names[unmodelled]
        )
        out$mu <- c(out$mu, sd_phylo)
      }
    } else if (identical(spec$model_type, "biv_gaussian")) {
      # Bivariate Gaussian keeps all structured location-scale SDs in the flat
      # `mu` block (endpoint encoded in the names), matching the q4/q8 summary
      # and profile-target contract.
      sd_phylo <- stats::setNames(
        exp(unname(par$log_sd_phylo[seq_along(phylo_names)])),
        phylo_names
      )
      out$mu <- c(out$mu, sd_phylo)
    } else {
      # Univariate Gaussian and non-Gaussian families use per-dpar blocks
      # (`mu`/`sigma`/`nu`/`zi`/`hu`) so scale-side structured SDs are addressable
      # by endpoint.
      sd_phylo <- exp(unname(par$log_sd_phylo[seq_along(phylo_names)]))
      for (dpar in unique(phylo_dpars)) {
        endpoint <- which(phylo_dpars == dpar)
        out[[dpar]] <- c(
          out[[dpar]],
          stats::setNames(sd_phylo[endpoint], phylo_names[endpoint])
        )
      }
    }
  }
  if (isTRUE(spec$structured$phylo_mu2$has)) {
    # Scoped second structured field: a single q = 1 location SD carried on its
    # own internal `log_sd_phylo2` scale and summarised in the flat `mu` block.
    phylo2_names <- phylo_mu_sd_labels(
      spec$structured$phylo_mu2,
      spec$model_type
    )
    sd_phylo2 <- stats::setNames(
      exp(unname(par$log_sd_phylo2[seq_along(phylo2_names)])),
      phylo2_names
    )
    out$mu <- c(out$mu, sd_phylo2)
  }
  out
}

split_tmb_corpars <- function(par, spec) {
  if (!spec$model_type %in% c("gaussian", "biv_gaussian")) {
    return(list())
  }

  out <- list()
  if (spec$random$mu$n_cors > 0L) {
    if (has_modelled_mu_correlation(spec)) {
      # Report one correlation per group level, not a scalar mean. Averaging
      # back-transformed correlations across groups is incoherent and hides
      # sign/heterogeneity (see issue #698): consumers such as the boundary
      # diagnostic in check.R read this vector and would otherwise see a single
      # collapsed value that masks correlations pegged near +/-1.
      rho_mu <- modelled_corpair_values(par, spec)
      names(rho_mu) <- modelled_mu_correlation_labels(spec, length(rho_mu))
    } else {
      rho_mu <- 0.999999 *
        tanh(unname(par$eta_cor_mu[seq_len(spec$random$mu$n_cors)]))
      names(rho_mu) <- spec$random$mu$cor_labels
    }
    out$mu <- rho_mu
  }

  re_mu_sigma <- spec$random$mu_sigma
  if (is.null(re_mu_sigma)) {
    re_mu_sigma <- empty_mu_sigma_random_covariance(spec$random$sigma$n_re)
  }
  if (re_mu_sigma$n_cors > 0L) {
    rho_mu_sigma <- 0.999999 *
      tanh(unname(par$eta_cor_mu_sigma[seq_len(re_mu_sigma$n_cors)]))
    names(rho_mu_sigma) <- re_mu_sigma$cor_labels
    out$mu_sigma <- rho_mu_sigma
  }
  if (spec$random$sigma$n_cors > 0L) {
    rho_sigma <- 0.999999 *
      tanh(unname(par$eta_cor_sigma[seq_len(spec$random$sigma$n_cors)]))
    names(rho_sigma) <- spec$random$sigma$cor_labels
    out$sigma <- rho_sigma
  }
  rho_re_cov <- covariance_block_correlations_from_par(
    par,
    spec$random$covariance_blocks
  )
  if (length(rho_re_cov) > 0L) {
    out$re_cov <- rho_re_cov
  }
  if (
    identical(spec$model_type, "biv_gaussian") &&
      isTRUE(spec$structured$phylo_mu$has)
  ) {
    phylo_pairs <- phylo_mu_pair_table(spec$structured$phylo_mu)
    cor_key <- structured_mu_correlation_key(spec$structured$phylo_mu)
    if (spec$structured$phylo_mu$q > 2L) {
      theta <- unname(par$theta_phylo[seq_len(nrow(phylo_pairs))])
      if (phylo_mu_is_block_diagonal(spec$structured$phylo_mu)) {
        rho_phylo <- 0.999999 * tanh(theta)
      } else {
        corr <- tmb_unstructured_corr_matrix(theta)
        rho_phylo <- numeric(nrow(phylo_pairs))
        for (i in seq_len(nrow(phylo_pairs))) {
          rho_phylo[[i]] <- corr[
            phylo_pairs$from_index[[i]],
            phylo_pairs$to_index[[i]]
          ]
        }
      }
      names(rho_phylo) <- phylo_pairs$parameter
    } else if (has_modelled_phylo_correlation(spec)) {
      # Report one correlation per phylogenetic level, not a scalar mean.
      # Averaging back-transformed correlations across levels is incoherent and
      # hides sign/heterogeneity (issue #698, phylogenetic sibling of the group
      # mu fix): the boundary diagnostic in check.R reads max|corpars$phylo| and
      # would otherwise see a single collapsed value that masks per-level
      # correlations pegged near +/-1. corpairs() still summarises this as one
      # row via the registry path (label/profile loops iterate the
      # representative index for a modelled phylogenetic correlation).
      rho_phylo <- modelled_corpair_values(par, spec)
      names(rho_phylo) <- modelled_phylo_correlation_labels(
        spec,
        phylo_pairs,
        length(rho_phylo)
      )
    } else {
      rho_phylo <- 0.999999 * tanh(unname(par$eta_cor_phylo))
      names(rho_phylo) <- phylo_pairs$parameter
    }
    out[[cor_key]] <- rho_phylo
  } else if (
    identical(spec$model_type, "gaussian") &&
      isTRUE(spec$structured$phylo_mu$has) &&
      phylo_mu_has_cross_dpar(spec$structured$phylo_mu)
  ) {
    phylo_pairs <- phylo_mu_pair_table(spec$structured$phylo_mu)
    cor_key <- structured_mu_correlation_key(spec$structured$phylo_mu)
    rho_phylo <- 0.999999 * tanh(unname(par$eta_cor_phylo))
    names(rho_phylo) <- phylo_pairs$parameter
    out[[cor_key]] <- rho_phylo
  }

  out
}

modelled_corpair_values <- function(par, spec) {
  model <- spec$random$mu$cor_model
  if (!has_modelled_corpair_model(spec)) {
    return(numeric())
  }
  eta <- as.vector(model$X %*% unname(par$beta_cor_mu[seq_len(ncol(model$X))]))
  0.999999 * tanh(eta)
}

# Per-level labels for a modelled group mu correlation. Each fitted correlation
# corresponds to one random-effect group level (a row of the corpair design), so
# names combine the block-level correlation label with the group level. The
# n_values fallback keeps names aligned even if the design carries no row names.
modelled_mu_correlation_labels <- function(spec, n_values) {
  base <- spec$random$mu$cor_labels
  if (length(base) != 1L) {
    base <- if (length(base) == 0L) "cor:mu" else base[[1L]]
  }
  model <- spec$random$mu$cor_model
  levels <- rownames(model$X)
  if (is.null(levels) || length(levels) != n_values) {
    levels <- as.character(seq_len(n_values))
  }
  paste0(base, "[", levels, "]")
}

# Per-level labels for a modelled phylogenetic correlation. Each fitted
# correlation corresponds to one phylogenetic level (a row of the corpair
# design), so names combine the pair parameter label with the level. The
# n_values fallback keeps names aligned even if the design carries no row names.
modelled_phylo_correlation_labels <- function(spec, phylo_pairs, n_values) {
  base <- phylo_pairs$parameter
  if (length(base) != 1L) {
    base <- if (length(base) == 0L) "cor:phylo" else base[[1L]]
  }
  model <- spec$random$mu$cor_model
  levels <- rownames(model$X)
  if (is.null(levels) || length(levels) != n_values) {
    levels <- as.character(seq_len(n_values))
  }
  paste0(base, "[", levels, "]")
}

has_modelled_corpair_model <- function(spec) {
  is.list(spec$random) &&
    is.list(spec$random$mu) &&
    is.list(spec$random$mu$cor_model) &&
    length(spec$random$mu$cor_model$n_models) == 1L &&
    isTRUE(spec$random$mu$cor_model$n_models > 0L)
}

has_modelled_mu_correlation <- function(spec) {
  has_modelled_corpair_model(spec) &&
    corpair_model_is_group(spec$random$mu$cor_model)
}

has_modelled_phylo_correlation <- function(spec) {
  has_modelled_corpair_model(spec) &&
    corpair_model_is_phylogenetic(spec$random$mu$cor_model)
}

covariance_block_correlations_from_par <- function(par, registry) {
  pairs <- qgt2_covariance_pairs(registry)
  blocks <- qgt2_covariance_blocks(registry)
  if (nrow(pairs) == 0L) {
    return(numeric())
  }

  theta <- unname(par$theta_re_cov[seq_len(registry$n_qgt2_theta)])
  out <- numeric(nrow(pairs))
  names(out) <- pairs$parameter
  theta_offset <- 0L
  for (block_i in seq_len(nrow(blocks))) {
    block <- blocks[block_i, , drop = FALSE]
    q <- block$n_members[[1L]]
    n_theta <- choose(q, 2L)
    theta_block <- theta[seq.int(theta_offset + 1L, length.out = n_theta)]
    corr <- tmb_unstructured_corr_matrix(theta_block)
    block_pairs <- pairs[
      pairs$block_id0 == block$block_id0[[1L]],
      ,
      drop = FALSE
    ]
    for (j in seq_len(nrow(block_pairs))) {
      row <- which(
        pairs$block_id0 == block_pairs$block_id0[[j]] &
          pairs$pair_id0 == block_pairs$pair_id0[[j]]
      )
      from <- block_pairs$from_member_id0[[j]] + 1L
      to <- block_pairs$to_member_id0[[j]] + 1L
      out[[row]] <- corr[from, to]
    }
    theta_offset <- theta_offset + n_theta
  }
  out
}

tmb_unstructured_corr_matrix <- function(theta) {
  q <- (1 + sqrt(1 + 8 * length(theta))) / 2
  if (!isTRUE(all.equal(q, as.integer(q)))) {
    cli::cli_abort(
      "Internal error: unstructured correlation parameter vector has invalid length."
    )
  }
  L <- diag(as.integer(q))
  lower <- which(lower.tri(L), arr.ind = TRUE)
  lower <- lower[order(lower[, "row"], lower[, "col"]), , drop = FALSE]
  L[lower] <- theta
  stats::cov2cor(L %*% t(L))
}

tmb_vecscale_sqrt_cov_scale <- function(theta, sd, z) {
  corr <- tmb_unstructured_corr_matrix(theta)
  as.vector(sd * (t(chol(corr)) %*% z))
}

split_tmb_random_effects <- function(par, spec) {
  if (
    !spec$model_type %in%
      c(
        "gaussian",
        "biv_gaussian",
        "student",
        "lognormal",
        "gamma",
        "tweedie",
        "beta",
        "beta_binomial",
        "cumulative_logit",
        "poisson",
        "zi_poisson",
        "nbinom2",
        "zi_nbinom2",
        "truncated_nbinom2",
        "hurdle_nbinom2"
      )
  ) {
    return(list())
  }

  out <- list()
  re_mu_sigma <- spec$random$mu_sigma
  if (is.null(re_mu_sigma)) {
    re_mu_sigma <- empty_mu_sigma_random_covariance(spec$random$sigma$n_re)
  }
  if (spec$random$mu$n_re > 0L) {
    latent <- unname(par$u_mu[seq_len(spec$random$mu$n_re)])
    values <- transform_mu_random_effects(
      latent,
      par,
      spec$random$mu,
      spec$random_scale$mu
    )
    out$mu <- format_random_effect_values(latent, values, spec$random$mu)
  }
  if (spec$random$sigma$n_re > 0L) {
    latent <- unname(par$u_sigma[seq_len(spec$random$sigma$n_re)])
    values <- if (identical(spec$model_type, "biv_gaussian")) {
      transform_biv_sigma_random_effects(
        latent,
        par,
        spec$random$sigma,
        re_mu_sigma
      )
    } else {
      transform_sigma_random_effects(
        latent,
        par,
        spec$random$sigma,
        re_mu_sigma
      )
    }
    out$sigma <- format_random_effect_values(latent, values, spec$random$sigma)
  }
  if (is.list(spec$random$covariance_blocks)) {
    qgt2_re <- transform_covariance_block_random_effects(
      par,
      spec$random$covariance_blocks
    )
    if (!is.null(qgt2_re)) {
      out$covariance_blocks <- qgt2_re
    }
  }
  if (isTRUE(spec$structured$phylo_mu$has)) {
    n_phylo <- spec$structured$phylo_mu$n_re
    random_effect_key <- structured_mu_random_effect_key(
      spec$structured$phylo_mu,
      spec$model_type
    )
    if (identical(spec$model_type, "biv_gaussian")) {
      dpars <- phylo_mu_dpars(spec$structured$phylo_mu)
      latent <- unname(par$u_phylo[seq_len(length(dpars) * n_phylo)])
      names(latent) <- as.vector(vapply(
        dpars,
        function(dpar) {
          paste0(dpar, ":", spec$structured$phylo_mu$node_labels)
        },
        character(n_phylo)
      ))
      values <- latent
      if (
        is.list(spec$random_scale$phylo) &&
          spec$random_scale$phylo$n_models > 0L
      ) {
        values <- latent * biv_phylo_node_sd_values(par, spec)
      }
      terms <- lapply(seq_along(dpars), function(i) {
        idx <- (i - 1L) * n_phylo + seq_len(n_phylo)
        values[idx]
      })
      names(terms) <- phylo_mu_sd_labels(
        spec$structured$phylo_mu,
        spec$model_type
      )
      out[[random_effect_key]] <- list(
        values = values,
        latent = latent,
        terms = terms
      )
    } else {
      q <- structured_mu_q(spec$structured$phylo_mu)
      labels <- phylo_mu_sd_labels(
        spec$structured$phylo_mu,
        spec$model_type
      )
      latent <- unname(par$u_phylo[seq_len(q * n_phylo)])
      if (q == 1L) {
        names(latent) <- spec$structured$phylo_mu$node_labels
      } else {
        names(latent) <- as.vector(vapply(
          labels,
          function(label) {
            paste0(label, ":", spec$structured$phylo_mu$node_labels)
          },
          character(n_phylo)
        ))
      }
      values <- latent
      if (
        identical(spec$model_type, "gaussian") &&
          q == 1L &&
          is.list(spec$random_scale$phylo) &&
          spec$random_scale$phylo$n_models > 0L
      ) {
        sd_node <- rep(NA_real_, n_phylo)
        sd_group <- sd_phylo_group_values(par, spec)
        node_row <- spec$random_scale$phylo$node_sd_row0
        has_sd <- node_row >= 0L
        sd_node[has_sd] <- sd_group[node_row[has_sd] + 1L]
        values <- latent * sd_node
      }
      names(values) <- names(latent)
      terms <- lapply(seq_len(q), function(i) {
        idx <- (i - 1L) * n_phylo + seq_len(n_phylo)
        term_values <- values[idx]
        names(term_values) <- spec$structured$phylo_mu$node_labels
        term_values
      })
      names(terms) <- labels
      out[[random_effect_key]] <- list(
        values = values,
        latent = latent,
        terms = terms
      )
    }
  }
  if (isTRUE(spec$structured$phylo_mu2$has)) {
    # Scoped second structured field: always q = 1 intercept-only on `mu` with
    # its own group precision, so the block is the simple scalar-GMRF form.
    phylo_mu2 <- spec$structured$phylo_mu2
    n_phylo2 <- phylo_mu2$n_re
    random_effect_key2 <- structured_mu_random_effect_key(
      phylo_mu2,
      spec$model_type
    )
    labels2 <- phylo_mu_sd_labels(phylo_mu2, spec$model_type)
    latent2 <- unname(par$u_phylo2[seq_len(n_phylo2)])
    names(latent2) <- phylo_mu2$node_labels
    values2 <- latent2
    terms2 <- list(values2)
    names(terms2) <- labels2
    out[[random_effect_key2]] <- list(
      values = values2,
      latent = latent2,
      terms = terms2
    )
  }
  out
}

transform_covariance_block_random_effects <- function(par, registry) {
  blocks <- qgt2_covariance_blocks(registry)
  members <- qgt2_covariance_members(registry)
  if (nrow(blocks) == 0L) {
    return(NULL)
  }

  theta <- unname(par$theta_re_cov[seq_len(registry$n_qgt2_theta)])
  log_sd <- unname(par$log_sd_re_cov[seq_len(registry$n_qgt2_sd)])
  latent_standard <- unname(par$u_re_cov[seq_len(registry$n_qgt2_re)])
  values <- numeric(registry$n_qgt2_re)
  value_names <- character(registry$n_qgt2_re)
  contribution <- matrix(
    0,
    nrow = nrow(registry$tmb_data$re_cov_member_design_value),
    ncol = nrow(members)
  )
  colnames(contribution) <- members$label

  theta_offset <- 0L
  sd_offset <- 0L
  u_offset <- 0L
  member_offset <- 0L
  for (block_i in seq_len(nrow(blocks))) {
    block <- blocks[block_i, , drop = FALSE]
    q <- block$n_members[[1L]]
    n_groups <- block$n_groups[[1L]]
    n_theta <- choose(q, 2L)
    theta_block <- theta[seq.int(theta_offset + 1L, length.out = n_theta)]
    sd_block <- exp(log_sd[seq.int(sd_offset + 1L, length.out = q)])
    member_cols <- seq.int(member_offset + 1L, length.out = q)
    for (g in seq_len(n_groups)) {
      z_index <- seq.int(u_offset + (g - 1L) * q + 1L, length.out = q)
      latent <- tmb_vecscale_sqrt_cov_scale(
        theta_block,
        sd_block,
        latent_standard[z_index]
      )
      values[z_index] <- latent
      value_names[z_index] <- paste0(
        members$label[member_cols],
        ":",
        block$group_levels[[1L]][[g]]
      )
      for (m in seq_len(q)) {
        member <- members[member_cols[[m]], , drop = FALSE]
        obs <- registry$tmb_data$re_cov_member_latent_index[, member_cols[[
          m
        ]]] ==
          g - 1L
        contribution[obs, member_cols[[m]]] <-
          registry$tmb_data$re_cov_member_design_value[obs, member_cols[[m]]] *
          latent[[m]]
      }
    }
    theta_offset <- theta_offset + n_theta
    sd_offset <- sd_offset + q
    u_offset <- u_offset + n_groups * q
    member_offset <- member_offset + q
  }
  names(values) <- value_names
  names(latent_standard) <- value_names
  list(
    values = values,
    latent = latent_standard,
    members = members,
    contribution = contribution
  )
}

transform_mu_random_effects <- function(
  latent,
  par,
  re_mu,
  sd_mu = empty_sd_mu_structure(re_mu$n_re)
) {
  sd_by_index <- mu_sd_by_random_effect(par, re_mu, sd_mu)
  rho <- if (re_mu$n_cors > 0L) {
    0.999999 * tanh(unname(par$eta_cor_mu[seq_len(re_mu$n_cors)]))
  } else {
    numeric()
  }
  values <- numeric(re_mu$n_re)
  for (idx in seq_len(re_mu$n_re)) {
    term <- re_mu$term_id0[[idx]] + 1L
    cor_id <- re_mu$re_cor_id0[[idx]] + 1L
    is_cor_slope <- cor_id > 0L && re_mu$re_pos0[[idx]] == 1L
    if (is_cor_slope) {
      pair <- re_mu$re_pair_index0[[idx]] + 1L
      rho_i <- rho[[cor_id]]
      values[[idx]] <- sd_by_index[[idx]] *
        (rho_i * latent[[pair]] + sqrt(1 - rho_i^2) * latent[[idx]])
    } else {
      values[[idx]] <- sd_by_index[[idx]] * latent[[idx]]
    }
  }
  values
}

mu_sd_by_random_effect <- function(par, re_mu, sd_mu) {
  scalar_sd <- exp(unname(par$log_sd_mu[seq_len(re_mu$n_terms)]))
  out <- scalar_sd[re_mu$term_id0 + 1L]
  if (sd_mu$n_models > 0L) {
    group_sd <- sd_mu_group_values(par, sd_mu)
    target <- which(sd_mu$re_sd_row0 >= 0L)
    out[target] <- group_sd[sd_mu$re_sd_row0[target] + 1L]
  }
  out
}

sd_mu_group_values <- function(par, sd_mu, dpar = NULL) {
  eta <- as.vector(sd_mu$X %*% unname(par$beta_sd_mu[seq_len(ncol(sd_mu$X))]))
  out <- exp(eta)
  names(out) <- sd_mu$group_levels
  if (!is.null(dpar)) {
    row_index <- sd_mu$row_index[[dpar]]
    out <- out[row_index]
    names(out) <- sd_mu$group_levels_list[[dpar]]
  }
  out
}

sd_phylo_group_values <- function(par, spec, dpar = NULL) {
  sd_phylo <- spec$random_scale$phylo
  offset <- sd_phylo_beta_offset(spec)
  beta <- unname(par$beta_sd_mu[
    offset + seq_len(ncol(sd_phylo$X))
  ])
  eta <- as.vector(sd_phylo$X %*% beta)
  out <- exp(eta)
  names(out) <- sd_phylo$group_levels
  if (!is.null(dpar)) {
    row_index <- sd_phylo$row_index[[dpar]]
    out <- out[row_index]
    names(out) <- sd_phylo$group_levels_list[[dpar]]
  }
  out
}

biv_phylo_node_sd_values <- function(par, spec) {
  phylo_mu <- spec$structured$phylo_mu
  sd_phylo <- spec$random_scale$phylo
  dpars <- phylo_mu_dpars(phylo_mu)
  n_phylo <- phylo_mu$n_re
  scalar_sd <- exp(unname(par$log_sd_phylo[seq_along(dpars)]))
  out <- rep(scalar_sd, each = n_phylo)
  sd_group <- sd_phylo_group_values(par, spec)
  node_row <- sd_phylo$node_sd_row0
  direct <- node_row >= 0L
  out[direct] <- sd_group[node_row[direct] + 1L]
  endpoint <- rep(seq_along(dpars), each = n_phylo)
  out[!direct & endpoint %in% unname(sd_phylo$target_endpoint)] <- NA_real_
  out
}

transform_independent_random_effects <- function(latent, log_sd, re) {
  sd_by_term <- exp(unname(log_sd[seq_len(re$n_terms)]))
  values <- numeric(re$n_re)
  for (idx in seq_len(re$n_re)) {
    term <- re$term_id0[[idx]] + 1L
    values[[idx]] <- sd_by_term[[term]] * latent[[idx]]
  }
  values
}

transform_sigma_random_effects <- function(
  latent,
  par,
  re_sigma,
  re_mu_sigma = empty_mu_sigma_random_covariance(re_sigma$n_re)
) {
  sd_by_term <- exp(unname(par$log_sd_sigma[seq_len(re_sigma$n_terms)]))
  rho_mu_sigma <- if (re_mu_sigma$n_cors > 0L) {
    0.999999 * tanh(unname(par$eta_cor_mu_sigma[seq_len(re_mu_sigma$n_cors)]))
  } else {
    numeric()
  }
  mu_latent <- unname(par$u_mu)

  values <- numeric(re_sigma$n_re)
  for (idx in seq_len(re_sigma$n_re)) {
    term <- re_sigma$term_id0[[idx]] + 1L
    u_cond <- latent[[idx]]
    cross_cor_id <- re_mu_sigma$sigma_cross_cor_id0[[idx]] + 1L
    if (cross_cor_id > 0L) {
      rho_i <- rho_mu_sigma[[cross_cor_id]]
      mu_idx <- re_mu_sigma$sigma_cross_mu_index0[[idx]] + 1L
      u_cond <- rho_i * mu_latent[[mu_idx]] + sqrt(1 - rho_i^2) * latent[[idx]]
    }
    values[[idx]] <- sd_by_term[[term]] * u_cond
  }
  values
}

transform_biv_sigma_random_effects <- function(
  latent,
  par,
  re_sigma,
  re_mu_sigma = empty_mu_sigma_random_covariance(re_sigma$n_re)
) {
  sd_by_term <- exp(unname(par$log_sd_sigma[seq_len(re_sigma$n_terms)]))
  rho_sigma <- if (re_sigma$n_cors > 0L) {
    0.999999 * tanh(unname(par$eta_cor_sigma[seq_len(re_sigma$n_cors)]))
  } else {
    numeric()
  }
  rho_mu_sigma <- if (re_mu_sigma$n_cors > 0L) {
    0.999999 * tanh(unname(par$eta_cor_mu_sigma[seq_len(re_mu_sigma$n_cors)]))
  } else {
    numeric()
  }
  mu_latent <- unname(par$u_mu)

  values <- numeric(re_sigma$n_re)
  for (idx in seq_len(re_sigma$n_re)) {
    term <- re_sigma$term_id0[[idx]] + 1L
    u_cond <- latent[[idx]]
    cor_id <- re_sigma$re_cor_id0[[idx]] + 1L
    if (cor_id > 0L) {
      rho_i <- rho_sigma[[cor_id]]
      pair <- re_sigma$re_pair_index0[[idx]] + 1L
      u_cond <- rho_i * latent[[pair]] + sqrt(1 - rho_i^2) * latent[[idx]]
    }
    cross_cor_id <- re_mu_sigma$sigma_cross_cor_id0[[idx]] + 1L
    if (cross_cor_id > 0L) {
      rho_i <- rho_mu_sigma[[cross_cor_id]]
      mu_idx <- re_mu_sigma$sigma_cross_mu_index0[[idx]] + 1L
      u_cond <- rho_i * mu_latent[[mu_idx]] + sqrt(1 - rho_i^2) * u_cond
    }
    values[[idx]] <- sd_by_term[[term]] * u_cond
  }
  values
}

format_random_effect_values <- function(latent, values, re) {
  names(values) <- re$value_names
  by_term <- vector("list", re$n_terms)
  names(by_term) <- re$labels
  start <- 1L
  for (k in seq_len(re$n_terms)) {
    n_group <- length(re$groups[[k]])
    idx <- seq.int(start, length.out = n_group)
    by_term[[k]] <- values[idx]
    names(by_term[[k]]) <- re$groups[[k]]
    start <- start + n_group
  }

  names(latent) <- re$value_names
  list(values = values, latent = latent, terms = by_term)
}
