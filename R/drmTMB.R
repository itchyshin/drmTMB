#' Fit a distributional regression model with TMB
#'
#' `drmTMB()` is the main model-fitting entry point. The current implementation
#' supports univariate Gaussian location-scale models, fixed-effect
#' univariate Student-t location-scale-shape models, fixed-effect lognormal
#' location-scale models, Gamma mean-CV models for positive responses,
#' fixed-effect beta mean-scale models for strict proportions,
#' fixed-effect beta-binomial mean-overdispersion models for success counts,
#' fixed-effect cumulative-logit ordinal location models, fixed-effect Poisson
#' mean, zero-inflated Poisson, negative-binomial mean-dispersion,
#' zero-inflated negative-binomial mean-dispersion, zero-truncated
#' negative-binomial mean-dispersion, and hurdle negative-binomial
#' mean-dispersion models for counts. Poisson and
#' negative-binomial `mu` formulas may include standard R
#' `offset(log(exposure))` terms for exposure or effort,
#' Gaussian random intercepts, independent numeric random slopes,
#' and labelled or unlabelled correlated numeric random intercept-slope blocks
#' in the location formula,
#' known sampling covariance through `meta_known_V(V = V)`, residual-scale
#' random intercepts and independent numeric random slopes in the scale formula,
#' labelled `mu`/`sigma`
#' random-intercept covariance blocks, and one or more group-level
#' random-effect scale formulae such as `sd(id) ~ x_group`, plus
#' intercept-only phylogenetic random effects in the univariate Gaussian
#' location formula, fixed-effect bivariate Gaussian distributional models, and
#' matched labelled bivariate Gaussian `mu1`/`mu2`, `sigma1`/`sigma2`, and
#' same-response `mu`/`sigma` random-intercept covariance blocks.
#' Bivariate Gaussian location formulas may be written explicitly as
#' `mu1 = y1 ~ ...`, `mu2 = y2 ~ ...`, or with `mvbind(y1, y2) ~ ...` shorthand
#' when both responses share the same location predictors.
#'
#' @param formula A `drm_formula` object created by [drm_formula()] or [bf()].
#' @param family A response family, such as [stats::gaussian()], [student()],
#'   [lognormal()], [stats::Gamma()] with `link = "log"`, [beta()],
#'   [beta_binomial()], [cumulative_logit()], [stats::poisson()] with `link = "log"`,
#'   [nbinom2()], [truncated_nbinom2()], or [biv_gaussian()]. Adding
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
#'   meta-analytic sampling variance or covariance, use [meta_known_V()] in the
#'   model formula instead.
#' @param control Optional list passed to [stats::nlminb()], or a
#'   [drm_control()] object when optimizer settings and fitted-object storage
#'   choices should be supplied together.
#' @param ... Reserved for future model options.
#'
#' @return A `drmTMB` fit object.
#' @export
drmTMB <- function(
  formula,
  family = stats::gaussian(),
  data,
  weights = NULL,
  control = list(),
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
  control <- drm_parse_control(control)

  weights_expr <- if (missing(weights)) NULL else substitute(weights)
  weights_full <- evaluate_likelihood_weights_arg(
    weights_expr = weights_expr,
    data = data,
    env = parent.frame()
  )

  family_type <- drm_family_type(family)
  spec <- switch(
    family_type,
    gaussian = drm_build_gaussian_ls_spec(
      formula,
      data,
      env = parent.frame(),
      weights = weights_full
    ),
    student = drm_build_student_ls_spec(
      formula,
      data,
      env = parent.frame(),
      weights = weights_full
    ),
    lognormal = drm_build_lognormal_ls_spec(
      formula,
      data,
      env = parent.frame(),
      weights = weights_full
    ),
    gamma = drm_build_gamma_ls_spec(
      formula,
      data,
      env = parent.frame(),
      weights = weights_full
    ),
    beta = drm_build_beta_ls_spec(
      formula,
      data,
      env = parent.frame(),
      weights = weights_full
    ),
    beta_binomial = drm_build_beta_binomial_spec(
      formula,
      data,
      env = parent.frame(),
      weights = weights_full
    ),
    cumulative_logit = drm_build_cumulative_logit_spec(
      formula,
      data,
      env = parent.frame(),
      weights = weights_full
    ),
    poisson = drm_build_poisson_spec(
      formula,
      data,
      env = parent.frame(),
      weights = weights_full
    ),
    nbinom2 = drm_build_nbinom2_spec(
      formula,
      data,
      env = parent.frame(),
      weights = weights_full
    ),
    truncated_nbinom2 = drm_build_truncated_nbinom2_spec(
      formula,
      data,
      env = parent.frame(),
      weights = weights_full
    ),
    biv_gaussian = drm_build_biv_gaussian_spec(
      formula,
      data,
      env = parent.frame(),
      weights = weights_full
    )
  )

  spec$response_names <- drm_spec_response_names(spec)

  obj <- TMB::MakeADFun(
    data = spec$tmb_data,
    parameters = spec$start,
    map = spec$map,
    random = spec$random_names,
    DLL = "drmTMB",
    silent = TRUE
  )

  opt <- stats::nlminb(
    start = obj$par,
    objective = obj$fn,
    gradient = obj$gr,
    control = control$optimizer
  )

  sdr <- TMB::sdreport(obj, par.fixed = opt$par)
  par_list <- obj$env$parList(opt$par)
  par <- split_tmb_parameters(par_list, spec)

  fit <- list(
    call = match.call(),
    formula = formula,
    family = family,
    data = spec$data,
    model = spec,
    obj = obj,
    opt = opt,
    sdr = sdr,
    par = par,
    coefficients = par,
    sdpars = split_tmb_sdpars(par_list, spec),
    corpars = split_tmb_corpars(par_list, spec),
    random_effects = split_tmb_random_effects(par_list, spec),
    ordinal = ordinal_fit_info(par_list, spec),
    logLik = -opt$objective,
    df = length(opt$par),
    nobs = spec$nobs
  )
  class(fit) <- "drmTMB"
  drm_apply_storage_control(fit, control)
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
  if (inherits(family, "drm_family") && identical(family$name, "nbinom2")) {
    return("nbinom2")
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
    "Currently supported families are {.code gaussian()}, {.fn student}, {.fn lognormal}, {.code Gamma(link = \"log\")}, {.fn beta}, {.fn beta_binomial}, {.fn cumulative_logit}, {.code poisson(link = \"log\")}, {.fn nbinom2}, {.fn truncated_nbinom2}, {.fn biv_gaussian}, {.code c(gaussian(), gaussian())}, and {.code list(gaussian(), gaussian())}. Zero-inflated Poisson and NB2 models use the same family route plus a {.code zi ~ ...} formula; hurdle NB2 models use {.fn truncated_nbinom2} plus a {.code hu ~ ...} formula."
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
  weights = NULL
) {
  entries <- formula$entries
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  is_sd_dpar <- startsWith(dpars, "sd(")

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
  sd_mu_entries <- if (any(is_sd_dpar)) {
    entries[is_sd_dpar]
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
  mu_re <- extract_random_mu_terms(mu_entry$rhs, "mu")
  mu_entry$rhs <- mu_re$rhs
  sigma_re <- extract_random_sigma_terms(sigma_entry$rhs, "sigma")
  sigma_entry$rhs <- sigma_re$rhs
  sd_mu_targets <- parse_sd_mu_entries(sd_mu_entries, mu_re$terms)

  drm_reject_phase1_terms(mu_entry$rhs, "mu")
  drm_reject_phase1_terms(sigma_entry$rhs, "sigma")
  for (sd_mu_entry in sd_mu_entries) {
    drm_reject_phase1_terms(sd_mu_entry$rhs, sd_mu_entry$dpar)
  }

  f_mu <- drm_entry_formula(mu_entry, response = TRUE)
  f_sigma <- drm_entry_formula(sigma_entry, response = FALSE)
  f_sd_mu <- lapply(sd_mu_entries, drm_entry_formula, response = FALSE)

  vars <- unique(c(
    all.vars(f_mu),
    all.vars(f_sigma),
    unlist(lapply(f_sd_mu, all.vars), use.names = FALSE),
    phylo_mu_vars(mu_phylo$term),
    vapply(sd_mu_targets, `[[`, character(1), "group"),
    random_effect_vars(mu_re$terms),
    random_effect_vars(sigma_re$terms)
  ))
  if (length(vars) > 0L) {
    model_keep <- stats::complete.cases(data[, vars, drop = FALSE])
  } else {
    model_keep <- rep(TRUE, nrow(data))
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

  X_mu <- stats::model.matrix(
    stats::delete.response(stats::terms(mf_mu)),
    mf_mu
  )
  X_sigma <- stats::model.matrix(stats::terms(mf_sigma), mf_sigma)
  re_mu <- build_random_mu_structure(mu_re$terms, data_model)
  re_sigma <- build_random_sigma_structure(sigma_re$terms, data_model)
  re_mu_sigma <- build_mu_sigma_random_covariance(re_mu, re_sigma)
  re_cov_blocks <- build_labelled_covariance_block_registry(
    re_mu,
    re_sigma,
    re_mu_sigma
  )
  sd_mu <- build_sd_mu_structure(
    sd_mu_entries,
    sd_mu_targets,
    re_mu,
    data_model
  )
  phylo_mu <- build_phylo_mu_structure(mu_phylo$term, data_model, env)

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
    re_mu_sigma
  )
  start <- c(start, gaussian_ls_dummy_start(phylo_mu, y = y))

  spec <- list(
    model_type = "gaussian",
    y = as.numeric(y),
    weights = weights_model,
    V_known = V_known$V,
    V_known_diag = V_known$diag,
    V_known_type = V_known$type,
    has_known_v = !is.null(meta$V),
    X = c(list(mu = X_mu, sigma = X_sigma), sd_mu$X_list),
    terms = c(
      list(
        mu = stats::delete.response(stats::terms(mf_mu)),
        sigma = stats::terms(mf_sigma)
      ),
      sd_mu$terms_list
    ),
    model_frame = c(list(mu = mf_mu, sigma = mf_sigma), sd_mu$model_frame_list),
    random = list(
      mu = re_mu,
      sigma = re_sigma,
      mu_sigma = re_mu_sigma,
      covariance_blocks = re_cov_blocks
    ),
    random_scale = list(mu = sd_mu),
    structured = list(phylo_mu = phylo_mu),
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = c("mu", "sigma", sd_mu$dpars),
    start = start,
    map = gaussian_ls_map(re_mu, re_sigma, sd_mu, phylo_mu, re_mu_sigma),
    random_names = c(
      if (re_mu$n_re > 0L) "u_mu",
      if (re_sigma$n_re > 0L) "u_sigma",
      if (isTRUE(phylo_mu$has)) "u_phylo"
    )
  )
  check_weights_known_covariance(spec)
  spec$tmb_data <- add_covariance_block_tmb_data(
    make_tmb_data(spec),
    spec
  )
  spec$nobs <- length(spec$y)
  spec
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
      "{.fn meta_known_V} is not implemented for {.fn student} models yet.",
      "i" = "Use {.code family = gaussian()} for Gaussian meta-analysis with known sampling covariance."
    ))
  }
  mu_entry$rhs <- meta$rhs

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
      mu = empty_random_mu_structure(nrow(data_model)),
      sigma = empty_random_sigma_structure(nrow(data_model))
    ),
    random_scale = list(mu = empty_sd_mu_structure(1L)),
    structured = list(phylo_mu = empty_phylo_mu_structure()),
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = c("mu", "sigma", "nu"),
    start = student_ls_start(y, X_mu, X_sigma, X_nu),
    map = student_ls_map(),
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
      "{.fn meta_known_V} is not implemented for {.fn lognormal} models yet.",
      "i" = "Use {.code family = gaussian()} for Gaussian meta-analysis with known sampling covariance."
    ))
  }
  mu_entry$rhs <- meta$rhs

  for (entry in list(mu_entry, sigma_entry)) {
    drm_reject_phase1_terms(entry$rhs, entry$dpar)
  }

  f_mu <- drm_entry_formula(mu_entry, response = TRUE)
  f_sigma <- drm_entry_formula(sigma_entry, response = FALSE)

  vars <- unique(c(all.vars(f_mu), all.vars(f_sigma)))
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
      mu = empty_random_mu_structure(nrow(data_model)),
      sigma = empty_random_sigma_structure(nrow(data_model))
    ),
    random_scale = list(mu = empty_sd_mu_structure(1L)),
    structured = list(phylo_mu = empty_phylo_mu_structure()),
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = c("mu", "sigma"),
    start = lognormal_ls_start(y, X_mu, X_sigma),
    map = lognormal_ls_map(),
    random_names = NULL
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
      "{.fn meta_known_V} is not implemented for {.fn Gamma} models yet.",
      "i" = "Use {.code family = gaussian()} for Gaussian meta-analysis with known sampling covariance."
    ))
  }
  mu_entry$rhs <- meta$rhs

  for (entry in list(mu_entry, sigma_entry)) {
    drm_reject_phase1_terms(entry$rhs, entry$dpar)
  }

  f_mu <- drm_entry_formula(mu_entry, response = TRUE)
  f_sigma <- drm_entry_formula(sigma_entry, response = FALSE)

  vars <- unique(c(all.vars(f_mu), all.vars(f_sigma)))
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
      mu = empty_random_mu_structure(nrow(data_model)),
      sigma = empty_random_sigma_structure(nrow(data_model))
    ),
    random_scale = list(mu = empty_sd_mu_structure(1L)),
    structured = list(phylo_mu = empty_phylo_mu_structure()),
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = c("mu", "sigma"),
    start = gamma_ls_start(y, X_mu, X_sigma),
    map = gamma_ls_map(),
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
  if (length(unsupported) > 0L) {
    cli::cli_abort(c(
      "Beta models only support {.code mu} and {.code sigma}.",
      "x" = "Unsupported parameter{?s}: {.val {unsupported}}."
    ))
  }
  if (any(is_sd_dpar)) {
    cli::cli_abort(c(
      "Random-effect scale formulae are not implemented for {.fn beta} models yet.",
      "i" = "Start with fixed-effect beta formulas such as {.code bf(prop ~ x, sigma ~ z)}."
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
      "{.fn meta_known_V} is not implemented for {.fn beta} models.",
      "i" = "Use {.code family = gaussian()} for Gaussian meta-analysis with known sampling covariance."
    ))
  }
  mu_entry$rhs <- meta$rhs

  for (entry in list(mu_entry, sigma_entry)) {
    drm_reject_phase1_terms(entry$rhs, entry$dpar)
  }

  f_mu <- drm_entry_formula(mu_entry, response = TRUE)
  f_sigma <- drm_entry_formula(sigma_entry, response = FALSE)

  vars <- unique(c(all.vars(f_mu), all.vars(f_sigma)))
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
      mu = empty_random_mu_structure(nrow(data_model)),
      sigma = empty_random_sigma_structure(nrow(data_model))
    ),
    random_scale = list(mu = empty_sd_mu_structure(1L)),
    structured = list(phylo_mu = empty_phylo_mu_structure()),
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = c("mu", "sigma"),
    start = beta_ls_start(y, X_mu, X_sigma),
    map = beta_ls_map(),
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
  if (length(unsupported) > 0L) {
    cli::cli_abort(c(
      "Beta-binomial models only support {.code mu} and {.code sigma}.",
      "x" = "Unsupported parameter{?s}: {.val {unsupported}}."
    ))
  }
  if (any(is_sd_dpar)) {
    cli::cli_abort(c(
      "Random-effect scale formulae are not implemented for {.fn beta_binomial} models yet.",
      "i" = "Start with fixed-effect denominator-aware formulas such as {.code bf(cbind(success, failure) ~ x, sigma ~ z)}."
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
      "{.fn meta_known_V} is not implemented for {.fn beta_binomial} models.",
      "i" = "Use {.code family = gaussian()} for Gaussian meta-analysis with known sampling covariance."
    ))
  }
  mu_entry$rhs <- meta$rhs

  for (entry in list(mu_entry, sigma_entry)) {
    drm_reject_phase1_terms(entry$rhs, entry$dpar)
  }

  f_mu <- drm_entry_formula(mu_entry, response = TRUE)
  f_sigma <- drm_entry_formula(sigma_entry, response = FALSE)

  vars <- unique(c(all.vars(f_mu), all.vars(f_sigma)))
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
      mu = empty_random_mu_structure(nrow(data_model)),
      sigma = empty_random_sigma_structure(nrow(data_model))
    ),
    random_scale = list(mu = empty_sd_mu_structure(1L)),
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
      X_sigma
    ),
    map = beta_binomial_map(),
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
      "{.fn meta_known_V} is not implemented for {.fn cumulative_logit} models.",
      "i" = "Use {.code family = gaussian()} for Gaussian meta-analysis with known sampling covariance."
    ))
  }
  mu_entry$rhs <- meta$rhs
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
    random_scale = list(mu = empty_sd_mu_structure(1L)),
    structured = list(phylo_mu = empty_phylo_mu_structure()),
    ordinal = ordinal[c("levels", "n_categories", "response")],
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = "mu",
    start = cumulative_logit_start(ordinal$y, X_mu, ordinal$n_categories),
    map = cumulative_logit_map(),
    random_names = NULL
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
  weights = NULL
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
      "{.fn meta_known_V} is not implemented for Poisson models.",
      "i" = "Use {.code family = gaussian()} for Gaussian meta-analysis with known sampling covariance."
    ))
  }
  mu_entry$rhs <- meta$rhs
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
  vars <- unique(c(all.vars(f_mu), if (!is.null(f_zi)) all.vars(f_zi)))
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

  X_mu <- stats::model.matrix(
    stats::delete.response(stats::terms(mf_mu)),
    mf_mu
  )
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
      mu = empty_random_mu_structure(nrow(data_model)),
      sigma = empty_random_sigma_structure(nrow(data_model))
    ),
    random_scale = list(mu = empty_sd_mu_structure(1L)),
    structured = list(phylo_mu = empty_phylo_mu_structure()),
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = if (has_zi) c("mu", "zi") else "mu",
    start = if (has_zi) {
      zi_poisson_start(y, X_mu, X_zi, offset_mu)
    } else {
      poisson_start(y, X_mu, offset_mu)
    },
    map = if (has_zi) zi_poisson_map() else poisson_map(),
    random_names = NULL
  )
  spec$tmb_data <- add_covariance_block_tmb_data(
    make_tmb_data(spec),
    spec
  )
  spec$nobs <- length(spec$y)
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
      "{.fn meta_known_V} is not implemented for {.fn nbinom2} models.",
      "i" = "Use {.code family = gaussian()} for Gaussian meta-analysis with known sampling covariance."
    ))
  }
  mu_entry$rhs <- meta$rhs

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
    if (!is.null(f_zi)) all.vars(f_zi)
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
      mu = empty_random_mu_structure(nrow(data_model)),
      sigma = empty_random_sigma_structure(nrow(data_model))
    ),
    random_scale = list(mu = empty_sd_mu_structure(1L)),
    structured = list(phylo_mu = empty_phylo_mu_structure()),
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = if (has_zi) c("mu", "sigma", "zi") else c("mu", "sigma"),
    start = if (has_zi) {
      zi_nbinom2_start(y, X_mu, X_sigma, X_zi, offset_mu)
    } else {
      nbinom2_start(y, X_mu, X_sigma, offset_mu)
    },
    map = if (has_zi) zi_nbinom2_map() else nbinom2_map(),
    random_names = NULL
  )
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
      "{.fn meta_known_V} is not implemented for {.fn truncated_nbinom2} models.",
      "i" = "Use {.code family = gaussian()} for Gaussian meta-analysis with known sampling covariance."
    ))
  }
  mu_entry$rhs <- meta$rhs

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
    if (!is.null(f_hu)) all.vars(f_hu)
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
      mu = empty_random_mu_structure(nrow(data_model)),
      sigma = empty_random_sigma_structure(nrow(data_model))
    ),
    random_scale = list(mu = empty_sd_mu_structure(1L)),
    structured = list(phylo_mu = empty_phylo_mu_structure()),
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = if (has_hu) c("mu", "sigma", "hu") else c("mu", "sigma"),
    start = if (has_hu) {
      hurdle_nbinom2_start(y, X_mu, X_sigma, X_hu)
    } else {
      truncated_nbinom2_start(y, X_mu, X_sigma)
    },
    map = if (has_hu) hurdle_nbinom2_map() else truncated_nbinom2_map(),
    random_names = NULL
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
  weights = NULL
) {
  entries <- expand_biv_mvbind_entries(formula$entries)
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  allowed <- c("mu1", "mu2", "sigma1", "sigma2", "rho12")
  unsupported <- setdiff(dpars, allowed)
  if (length(unsupported) > 0L) {
    cli::cli_abort(c(
      "{.fn biv_gaussian} models only support {.code mu1}, {.code mu2}, {.code sigma1}, {.code sigma2}, and {.code rho12}.",
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
      "Only one {.fn meta_known_V} term is supported in a bivariate model.",
      "i" = "{.fn meta_known_V} is a model-level known-covariance marker even if it appears in a location formula."
    ))
  }
  mu1_entry$rhs <- meta_mu1$rhs
  mu2_entry$rhs <- meta_mu2$rhs
  meta <- if (!is.null(meta_mu1$V)) meta_mu1 else meta_mu2

  mu1_re <- extract_random_mu_terms(mu1_entry$rhs, "mu1")
  mu1_entry$rhs <- mu1_re$rhs
  mu2_re <- extract_random_mu_terms(mu2_entry$rhs, "mu2")
  mu2_entry$rhs <- mu2_re$rhs
  sigma1_re <- extract_random_sigma_terms(sigma1_entry$rhs, "sigma1")
  sigma1_entry$rhs <- sigma1_re$rhs
  sigma2_re <- extract_random_sigma_terms(sigma2_entry$rhs, "sigma2")
  sigma2_entry$rhs <- sigma2_re$rhs
  if (
    !is.null(meta$V) &&
      (length(mu1_re$terms) > 0L ||
        length(mu2_re$terms) > 0L ||
        length(sigma1_re$terms) > 0L ||
        length(sigma2_re$terms) > 0L)
  ) {
    cli::cli_abort(c(
      "Bivariate Gaussian random effects cannot yet be combined with {.fn meta_known_V}.",
      "i" = "Fit bivariate group-level covariance blocks without known sampling covariance first."
    ))
  }
  reject_biv_cross_parameter_label_reuse(
    mu1_re$terms,
    mu2_re$terms,
    sigma1_re$terms,
    sigma2_re$terms
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

  f_mu1 <- drm_entry_formula(mu1_entry, response = TRUE)
  f_mu2 <- drm_entry_formula(mu2_entry, response = TRUE)
  f_sigma1 <- drm_entry_formula(sigma1_entry, response = FALSE)
  f_sigma2 <- drm_entry_formula(sigma2_entry, response = FALSE)
  f_rho12 <- drm_entry_formula(rho12_entry, response = FALSE)

  vars <- unique(c(
    all.vars(f_mu1),
    all.vars(f_mu2),
    all.vars(f_sigma1),
    all.vars(f_sigma2),
    all.vars(f_rho12),
    random_effect_vars(mu1_re$terms),
    random_effect_vars(mu2_re$terms),
    random_effect_vars(sigma1_re$terms),
    random_effect_vars(sigma2_re$terms)
  ))
  keep <- stats::complete.cases(data[, vars, drop = FALSE])
  data_model <- data[keep, , drop = FALSE]
  V_known_full <- evaluate_biv_known_v(meta$V, data, env)
  V_known <- subset_biv_known_v(V_known_full, keep)
  weights_model <- subset_likelihood_weights(
    weights,
    keep,
    nrow(data),
    sum(keep)
  )

  mf_mu1 <- stats::model.frame(
    f_mu1,
    data = data_model,
    na.action = stats::na.omit
  )
  mf_mu2 <- stats::model.frame(
    f_mu2,
    data = data_model,
    na.action = stats::na.omit
  )
  mf_sigma1 <- stats::model.frame(
    f_sigma1,
    data = data_model,
    na.action = stats::na.omit
  )
  mf_sigma2 <- stats::model.frame(
    f_sigma2,
    data = data_model,
    na.action = stats::na.omit
  )
  mf_rho12 <- stats::model.frame(
    f_rho12,
    data = data_model,
    na.action = stats::na.omit
  )

  y1 <- stats::model.response(mf_mu1)
  y2 <- stats::model.response(mf_mu2)
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
  re_mu <- build_biv_mu_random_structure(
    mu1_re$terms,
    mu2_re$terms,
    data_model
  )
  re_sigma <- build_biv_sigma_random_structure(
    sigma1_re$terms,
    sigma2_re$terms,
    data_model
  )
  re_mu_sigma <- build_mu_sigma_random_covariance(re_mu, re_sigma)
  validate_biv_random_covariance_surface(re_mu, re_sigma, re_mu_sigma)
  re_cov_blocks <- build_labelled_covariance_block_registry(
    re_mu,
    re_sigma,
    re_mu_sigma
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
    re_mu_sigma = re_mu_sigma
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
    X = list(
      mu1 = X_mu1,
      mu2 = X_mu2,
      sigma1 = X_sigma1,
      sigma2 = X_sigma2,
      rho12 = X_rho12
    ),
    terms = list(
      mu1 = stats::delete.response(stats::terms(mf_mu1)),
      mu2 = stats::delete.response(stats::terms(mf_mu2)),
      sigma1 = stats::terms(mf_sigma1),
      sigma2 = stats::terms(mf_sigma2),
      rho12 = stats::terms(mf_rho12)
    ),
    model_frame = list(
      mu1 = mf_mu1,
      mu2 = mf_mu2,
      sigma1 = mf_sigma1,
      sigma2 = mf_sigma2,
      rho12 = mf_rho12
    ),
    data = data_model,
    random = list(
      mu = re_mu,
      sigma = re_sigma,
      mu_sigma = re_mu_sigma,
      covariance_blocks = re_cov_blocks
    ),
    random_scale = list(mu = empty_sd_mu_structure(re_mu$n_re)),
    structured = list(phylo_mu = empty_phylo_mu_structure()),
    variables = vars,
    keep = keep,
    dpars = c("mu1", "mu2", "sigma1", "sigma2", "rho12"),
    start = start,
    map = biv_gaussian_map(re_mu, re_sigma, re_mu_sigma),
    random_names = c(
      if (re_mu$n_re > 0L) "u_mu",
      if (re_sigma$n_re > 0L) "u_sigma"
    )
  )
  check_weights_known_covariance(spec)
  spec$tmb_data <- add_covariance_block_tmb_data(
    make_tmb_data(spec),
    spec
  )
  spec$nobs <- length(spec$y1)
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
  structured <- c("phylo", "spatial")[vapply(
    c("phylo", "spatial"),
    function(name) formula_contains_call(rhs, name),
    logical(1)
  )]
  if (length(structured) > 0L) {
    cli::cli_abort(c(
      "Structured-effect syntax is planned, not implemented.",
      "x" = "The {.code {dpar}} formula contains structured marker{?s}: {.val {structured}}.",
      "i" = "The implemented structured path is intercept-only {.code mu} syntax {.code phylo(1 | species, tree = tree)}; spatial terms and structured effects in other parameters are still planned."
    ))
  }

  unsupported <- c("|", "meta_known_V", "gr", "phylo", "spatial")
  if (!isTRUE(allow_offset)) {
    unsupported <- c(unsupported, "offset")
  }
  hits <- unsupported[vapply(
    unsupported,
    function(name) formula_contains_call(rhs, name),
    logical(1)
  )]
  if (length(hits) > 0L) {
    if (
      "|" %in% hits && dpar %in% c("mu1", "mu2", "sigma1", "sigma2", "rho12")
    ) {
      cli::cli_abort(c(
        "This bivariate random-effect syntax is not implemented.",
        "x" = "The {.code {dpar}} formula contains unsupported model terms: {.val {hits}}.",
        "i" = "Implemented bivariate random-effect paths are matching labelled random intercepts in {.code mu1}/{.code mu2} or {.code sigma1}/{.code sigma2}.",
        "i" = "Residual {.code rho12} is a within-observation correlation, not a group-level random-effect correlation."
      ))
    }
    cli::cli_abort(c(
      "This formula contains unsupported model terms.",
      "x" = "The {.code {dpar}} formula contains unsupported term{?s}: {.val {hits}}."
    ))
  }
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
  if (!identical(dpar, "sigma")) {
    cli::cli_abort(c(
      "Only bivariate residual-scale random intercepts are implemented for {.code {dpar}}.",
      "x" = "Use matching terms such as {.code {dpar} = ~ z + (1 | p | id)}.",
      "i" = "Residual-scale random slopes in bivariate models remain planned."
    ))
  }

  coef <- parse_random_mu_lhs(
    lhs,
    dpar = dpar,
    group = as.character(group),
    covariance_label = covariance_label
  )
  if (!identical(coef$type, "slope")) {
    cli::cli_abort(c(
      "Only independent residual-scale random slopes are implemented for {.code sigma}.",
      "x" = "Use {.code sigma ~ z + (1 | id)} for a random intercept or {.code sigma ~ z + (0 + x | id)} for an independent random slope.",
      "i" = "Correlated residual-scale intercept-slope blocks such as {.code sigma ~ z + (1 + x | id)} are planned for a later phase."
    ))
  }
  if (!is.null(covariance_label)) {
    cli::cli_abort(c(
      "Labelled residual-scale random-slope covariance blocks are not implemented yet.",
      "x" = "Use an unlabelled independent slope such as {.code sigma ~ z + (0 + x | id)}.",
      "i" = "Shared labelled {.code mu}/{.code sigma} slope covariance will follow after the independent residual-scale slope path is stable."
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
      sum(symbol) == 1L &&
      length(pieces) == sum(one) + sum(symbol)
  ) {
    variable <- as.character(pieces[[which(symbol)]])
    return(list(
      type = "correlated_slope",
      variable = variable,
      variables = variable,
      coef_names = c("(Intercept)", variable),
      label = format_random_mu_label(
        paste0("1 + ", variable),
        group,
        covariance_label
      )
    ))
  }

  cli::cli_abort(c(
    "Only random intercepts, independent random slopes, and correlated intercept-slope blocks are implemented for {.code {dpar}}.",
    "x" = "Use {.code (1 | id)} for a random intercept or {.code (0 + x | id)} for a random slope.",
    "i" = "Use {.code (1 + x | id)} or {.code (1 + x | p | id)} for a correlated random intercept and slope."
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
    "zi"
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

format_biv_mu_cor_label <- function(group, covariance_label) {
  paste0(
    "cor(mu1:(Intercept),mu2:(Intercept) | ",
    covariance_label,
    " | ",
    group,
    ")"
  )
}

format_biv_sigma_cor_label <- function(group, covariance_label) {
  paste0(
    "cor(sigma1:(Intercept),sigma2:(Intercept) | ",
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
  covariance_label
) {
  paste0(
    "cor(",
    from_dpar,
    ":(Intercept),",
    to_dpar,
    ":(Intercept) | ",
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

extract_gaussian_mu_phylo_term <- function(entry) {
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
      "Only one phylogenetic structured effect is implemented in {.code mu}.",
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
  if (!identical(phylo_term$coef_names, "(Intercept)")) {
    cli::cli_abort(c(
      "Only intercept-only phylogenetic {.code mu} effects are implemented.",
      "x" = "Requested structured coefficient{?s}: {.val {phylo_term$coef_names}}.",
      "i" = "Use {.code phylo(1 | species, tree = tree)}. Phylogenetic random slopes are planned after intercept-only recovery tests."
    ))
  }

  list(rhs = rebuild_plus_terms(terms[!is_phylo]), term = phylo_term)
}

phylo_mu_vars <- function(term) {
  if (is.null(term)) {
    return(character())
  }
  term$group
}

empty_phylo_mu_structure <- function() {
  list(
    has = FALSE,
    label = character(),
    group = NA_character_,
    tree = NA_character_,
    n_re = 0L,
    precision = NULL,
    observation_node_index = integer(),
    observation_node_index0 = 0L,
    node_labels = character(),
    species_levels = character()
  )
}

build_phylo_mu_structure <- function(term, data, env) {
  if (is.null(term)) {
    return(empty_phylo_mu_structure())
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
    label = paste0("phylo(1 | ", group, ")"),
    group = group,
    tree = term$tree,
    n_re = nrow(precision$precision),
    precision = precision,
    observation_node_index = unname(as.integer(observation_node_index)),
    observation_node_index0 = unname(as.integer(observation_node_index - 1L)),
    node_labels = precision$node_labels,
    species_levels = precision$species_levels
  )
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
    value_names = character()
  )
}

empty_random_sigma_structure <- function(n) {
  empty_random_mu_structure(n)
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
  re_sigma <- build_random_mu_structure(terms, data)
  re_sigma$dpars <- rep("sigma", re_sigma$n_terms)
  if (re_sigma$n_cors > 0L) {
    cli::cli_abort(
      "Internal error: residual sigma random-effect correlations are not implemented."
    )
  }
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
  if (length(cross_sigma) > 1L) {
    cli::cli_abort(c(
      "Only one labelled {.code mu}/{.code sigma} covariance block is implemented in this phase.",
      "i" = "Start with one matching random-intercept pair such as {.code mu1 = y1 ~ x + (1 | p | id)} and {.code sigma1 = ~ z + (1 | p | id)}."
    ))
  }

  labelled_sigma <- cross_sigma
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
      "i" = "Use one same-response pair such as {.code mu1} with {.code sigma1}, or wait for the positive-definite q > 2 block parameterization."
    ))
  }
  if (
    length(matching_mu) > 1L ||
      !identical(re_mu$coef_names[[matching_mu]], "(Intercept)")
  ) {
    cli::cli_abort(c(
      "Labelled {.code mu}/{.code sigma} covariance blocks are intercept-only in this phase.",
      "x" = "The matching {.code mu} block has coefficient{?s}: {.val {re_mu$coef_names[matching_mu]}}.",
      "i" = "Fit {.code (1 | p | id)} first; random-slope scale covariance will follow after recovery tests."
    ))
  }
  if (!identical(re_sigma$coef_names[[labelled_sigma]], "(Intercept)")) {
    cli::cli_abort(
      "Internal error: labelled {.code sigma} covariance block is not intercept-only."
    )
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

  sigma_cross_cor_id0 <- rep.int(-1L, re_sigma$n_re)
  sigma_cross_mu_index0 <- rep.int(-1L, re_sigma$n_re)
  sigma_rows <- which(re_sigma$term_id0 == labelled_sigma - 1L)
  mu_rows <- which(re_mu$term_id0 == matching_mu - 1L)
  sigma_cross_cor_id0[sigma_rows] <- 0L
  sigma_cross_mu_index0[sigma_rows] <- mu_rows - 1L
  list(
    n_cors = 1L,
    cor_labels = format_cross_dpar_cor_label(
      re_mu$dpars[[matching_mu]],
      re_sigma$dpars[[labelled_sigma]],
      group_name,
      block_label
    ),
    sigma_cross_cor_id0 = sigma_cross_cor_id0,
    sigma_cross_mu_index0 = sigma_cross_mu_index0
  )
}

empty_labelled_covariance_block_registry <- function() {
  list(
    n_blocks = 0L,
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
  re_mu_sigma = empty_mu_sigma_random_covariance(re_sigma$n_re)
) {
  registry <- empty_labelled_covariance_block_registry()
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
  registry$tmb_data <- labelled_covariance_block_tmb_data(registry)
  registry
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
    n_groups = length(re$groups[[term]]),
    group_levels = I(list(re$groups[[term]])),
    latent_index0 = I(list(re$index0[, term])),
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
    re_cov_pair_parameter_index = 0L
  )
}

labelled_covariance_block_tmb_data <- function(registry) {
  if (registry$n_blocks == 0L) {
    return(empty_labelled_covariance_block_tmb_data())
  }

  blocks <- registry$blocks
  members <- registry$members
  pairs <- registry$pairs
  if (any(blocks$n_members != 2L)) {
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
    re_cov_pair_parameter = covariance_parameter_code(pairs$tmb_parameter),
    re_cov_pair_parameter_index = pairs$tmb_index - 1L
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
    match(parameter, c("eta_cor_mu", "eta_cor_mu_sigma", "eta_cor_sigma")) - 1L
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
      "i" = "Use matching {.code mu1}/{.code mu2} terms for a mean-mean block or a same-response {.code mu}/ {.code sigma} pair for the first mean-scale block."
    ))
  }
  if (length(unpaired_sigma) > 0L) {
    i <- unpaired_sigma[[1L]]
    cli::cli_abort(c(
      "Bivariate labelled {.code sigma} random effects must be part of an implemented covariance block.",
      "x" = "{.code {re_sigma$dpars[[i]]}} uses block {.code {re_sigma$covariance_labels[[i]]}} on group {.field {re_sigma$group_names[[i]]}} without a supported partner.",
      "i" = "Use matching {.code sigma1}/{.code sigma2} terms for a scale-scale block or a same-response {.code mu}/ {.code sigma} pair for the first mean-scale block."
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

build_biv_sigma_random_structure <- function(sigma1_terms, sigma2_terms, data) {
  build_biv_parameter_random_structure(
    sigma1_terms,
    sigma2_terms,
    data,
    dpars = c("sigma1", "sigma2"),
    pair = "sigma1/sigma2",
    cor_label = format_biv_sigma_cor_label
  )
}

build_biv_parameter_random_structure <- function(
  terms1,
  terms2,
  data,
  dpars,
  pair,
  cor_label
) {
  n_terms <- stats::setNames(c(length(terms1), length(terms2)), dpars)
  if (sum(n_terms) == 0L) {
    return(empty_random_mu_structure(nrow(data)))
  }
  if (any(n_terms > 1L)) {
    cli::cli_abort(c(
      "Bivariate {.code {pair}} random effects currently allow at most one random-intercept term per formula.",
      "x" = "Found {n_terms[[1L]]} term{?s} in {.code {dpars[[1L]]}} and {n_terms[[2L]]} term{?s} in {.code {dpars[[2L]]}}."
    ))
  }

  terms <- list(terms1, terms2)
  present <- which(n_terms == 1L)
  terms <- lapply(present, function(i) terms[[i]][[1L]])
  term_dpars <- unname(dpars[present])
  if (
    any(vapply(
      terms,
      function(term) !identical(term$type, "intercept"),
      logical(1L)
    ))
  ) {
    cli::cli_abort(c(
      "Only bivariate random intercepts are implemented for {.code {pair}} covariance blocks.",
      "x" = "Random slopes and broader bivariate covariance blocks remain planned.",
      "i" = "Use labelled random-intercept terms such as {.code (1 | p | id)}."
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
  if (length(terms) == 2L) {
    if (!identical(groups_present[[1L]], groups_present[[2L]])) {
      cli::cli_abort(c(
        "Bivariate {.code {pair}} random effects must use the same grouping variable.",
        "x" = "{.code {term_dpars[[1L]]}} uses {.field {groups_present[[1L]]}} but {.code {term_dpars[[2L]]}} uses {.field {groups_present[[2L]]}}."
      ))
    }
    if (!identical(labels[[1L]], labels[[2L]])) {
      cli::cli_abort(c(
        "Bivariate {.code {pair}} same-parameter covariance blocks must use the same covariance-block label.",
        "x" = "Use one response-specific {.code mu}/ {.code sigma} cross-parameter block at a time, or matching labels in both {.code {dpars[[1L]]}} and {.code {dpars[[2L]]}} for a same-parameter block."
      ))
    }
  }

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
  index <- matrix(NA_integer_, nrow = nrow(data), ncol = n_cols)
  value <- matrix(1, nrow = nrow(data), ncol = n_cols)
  base_labels <- unname(vapply(
    labels,
    function(block_label) format_random_mu_label("1", group_name, block_label),
    character(1L)
  ))
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
    term_id0 <- c(term_id0, rep.int(j - 1L, n_group))
    dpar_id0 <- c(dpar_id0, rep.int(present[[j]] - 1L, n_group))
    re_pos0 <- c(re_pos0, rep.int(j - 1L, n_group))
    if (n_cols == 2L && j == 2L) {
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
    n_cors = if (n_cols == 2L) 1L else 0L,
    cor_labels = if (n_cols == 2L) {
      cor_label(group_name, labels[[1L]])
    } else {
      character()
    },
    labels = labels_out,
    dpars = term_dpars,
    coef_names = rep("(Intercept)", n_cols),
    group_names = rep(group_name, n_cols),
    covariance_labels = labels,
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
  is_intercept <- vapply(
    terms,
    function(term) identical(term$type, "intercept"),
    logical(1L)
  )
  if (!all(is_intercept)) {
    return(invisible(FALSE))
  }

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
    "Reusing one bivariate covariance-block label across {.code mu1}/{.code mu2} and {.code sigma1}/{.code sigma2} is not implemented.",
    "x" = "Block {.code {block_label}} on group {.field {group_name}} would imply a full cross-parameter bivariate covariance block.",
    "i" = "Use distinct labels such as {.code (1 | pm | {group_name})} for {.code mu1}/{.code mu2} and {.code (1 | ps | {group_name})} for {.code sigma1}/{.code sigma2}.",
    "i" = "Full cross-parameter bivariate covariance across {.code mu1}, {.code mu2}, {.code sigma1}, and {.code sigma2} remains planned."
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
    cli::cli_abort("Only one {.fn meta_known_V} term is supported.")
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
  is.call(expr) && identical(expr[[1L]], as.name("meta_known_V"))
}

extract_meta_known_v_arg <- function(expr) {
  args <- as.list(expr)[-1L]
  arg_names <- names(args)
  if (is.null(arg_names)) {
    arg_names <- rep("", length(args))
  }
  arg_names[is.na(arg_names)] <- ""

  valid <- length(args) == 1L && arg_names[[1L]] %in% c("", "V")
  if (!valid) {
    cli::cli_abort(
      "{.fn meta_known_V} requires exactly one argument named {.arg V}."
    )
  }

  args[[1L]]
}

formula_contains_call <- function(expr, name) {
  expr <- strip_parens(expr)
  if (!is.call(expr)) {
    return(FALSE)
  }
  identical(expr[[1L]], as.name(name)) ||
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
      "{.arg V} for bivariate {.fn meta_known_V} must evaluate to a {.code 2n} by {.code 2n} matrix.",
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
    "{.arg weights} cannot currently be combined with a full {.fn meta_known_V} covariance matrix.",
    "x" = "Full known covariance uses one joint multivariate likelihood block, not independent row contributions.",
    "i" = "Use {.fn meta_known_V} without {.arg weights}, or use diagonal known variances when row likelihood weighting is scientifically intended."
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
  if (
    !isTRUE(all.equal(value, t(value), tolerance = sqrt(.Machine$double.eps)))
  ) {
    cli::cli_abort("{.arg V} matrix must be symmetric.")
  }
  validate_known_v_diag(diag(value))
  ev <- eigen(
    (value + t(value)) / 2,
    symmetric = TRUE,
    only.values = TRUE
  )$values
  if (min(ev) < -sqrt(.Machine$double.eps)) {
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

gaussian_ls_start <- function(
  y,
  X_mu,
  X_sigma,
  V_known = rep(0, length(y)),
  re_mu = empty_random_mu_structure(length(y)),
  re_sigma = empty_random_sigma_structure(length(y)),
  sd_mu = empty_sd_mu_structure(re_mu$n_re),
  re_mu_sigma = empty_mu_sigma_random_covariance(re_sigma$n_re)
) {
  lm_start <- stats::lm.fit(x = X_mu, y = y)
  beta_mu <- lm_start$coefficients
  beta_mu[is.na(beta_mu)] <- 0

  resid <- y - as.vector(X_mu %*% beta_mu)
  resid_var <- stats::var(resid)
  known_v0 <- stats::median(V_known, na.rm = TRUE)
  y_scale <- stats::sd(y)
  if (!is.finite(y_scale) || y_scale <= 0) {
    y_scale <- 1
  }
  sigma_floor <- max(1e-4, 0.05 * y_scale)
  sigma0 <- sqrt(max(resid_var - known_v0, sigma_floor^2))
  if (!is.finite(sigma0) || sigma0 <= 0) {
    sigma0 <- stats::sd(y)
  }
  if (!is.finite(sigma0) || sigma0 <= 0) {
    sigma0 <- 1
  }

  beta_sigma <- numeric(ncol(X_sigma))
  beta_sigma[1L] <- log(sigma0)

  mu_re_start <- gaussian_mu_re_start(resid, re_mu, y_scale)
  sigma_re_start <- gaussian_sigma_re_start(re_sigma)
  beta_sd_mu <- gaussian_sd_mu_start(mu_re_start, sd_mu)

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
    log_sd_sigma = sigma_re_start$log_sd_sigma
  )
}

gaussian_ls_dummy_start <- function(
  phylo_mu = empty_phylo_mu_structure(),
  y = NULL
) {
  phylo_start <- gaussian_phylo_start(y, phylo_mu)
  list(
    beta_nu = 0,
    beta_zi = 0,
    theta_ord = 0,
    beta_mu1 = 0,
    beta_mu2 = 0,
    beta_sigma1 = 0,
    beta_sigma2 = 0,
    beta_rho12 = 0,
    eta_cor_mu_sigma = 0,
    eta_cor_sigma = 0,
    u_phylo = phylo_start$u_phylo,
    log_sd_phylo = phylo_start$log_sd_phylo
  )
}

student_ls_start <- function(y, X_mu, X_sigma, X_nu) {
  gaussian_start <- gaussian_ls_start(y, X_mu, X_sigma)
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
      log_sd_phylo = 0
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

lognormal_ls_start <- function(y, X_mu, X_sigma) {
  gaussian_start <- gaussian_ls_start(log(y), X_mu, X_sigma)
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
      log_sd_phylo = 0
    )
  )
}

lognormal_ls_map <- function() {
  out <- student_ls_map()
  out$beta_nu <- factor(NA)
  out
}

gamma_ls_map <- function() {
  lognormal_ls_map()
}

beta_ls_start <- function(y, X_mu, X_sigma) {
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
  mu <- stats::plogis(as.vector(X_mu %*% beta_mu))
  ratio <- mean((y - mu)^2 / pmax(mu * (1 - mu), .Machine$double.eps))
  if (!is.finite(ratio) || ratio <= 0) {
    ratio <- 0.2
  }
  ratio <- min(max(ratio, 1e-4), 0.95)
  sigma0 <- sqrt(ratio / (1 - ratio))
  beta_sigma <- rep(0, ncol(X_sigma))
  beta_sigma[[1L]] <- log(max(sigma0, 1e-4))
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
      log_sd_phylo = 0
    )
  )
}

beta_ls_map <- function() {
  lognormal_ls_map()
}

beta_binomial_start <- function(successes, failures, X_mu, X_sigma) {
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
      log_sd_phylo = 0
    )
  )
}

beta_binomial_map <- function() {
  beta_ls_map()
}

poisson_start <- function(y, X_mu, offset_mu = rep(0, length(y))) {
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
      log_sd_phylo = 0
    )
  )
}

poisson_map <- function() {
  out <- lognormal_ls_map()
  out$beta_sigma <- factor(NA)
  out
}

zi_poisson_start <- function(y, X_mu, X_zi, offset_mu = rep(0, length(y))) {
  poisson <- poisson_start(y, X_mu, offset_mu)
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
      u_phylo = 0,
      log_sd_phylo = 0
    )
  )
}

zi_poisson_map <- function() {
  out <- poisson_map()
  out$beta_zi <- NULL
  out
}

nbinom2_start <- function(y, X_mu, X_sigma, offset_mu = rep(0, length(y))) {
  poisson <- poisson_start(y, X_mu, offset_mu)
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
      log_sd_phylo = 0
    )
  )
}

nbinom2_map <- function() {
  lognormal_ls_map()
}

truncated_nbinom2_start <- function(y, X_mu, X_sigma) {
  nb <- nbinom2_start(y, X_mu, X_sigma)
  mu <- exp(as.vector(X_mu %*% nb$beta_mu))
  sigma <- exp(as.vector(X_sigma %*% nb$beta_sigma))
  p0 <- stats::dnbinom(0, size = 1 / sigma^2, mu = mu)
  q <- pmin(pmax(1 - p0, 1e-6), 1)
  nb$beta_mu[[1L]] <- nb$beta_mu[[1L]] + log(mean(q))
  nb
}

truncated_nbinom2_map <- function() {
  nbinom2_map()
}

hurdle_nbinom2_start <- function(y, X_mu, X_sigma, X_hu) {
  nb <- truncated_nbinom2_start(
    y[y > 0],
    X_mu[y > 0, , drop = FALSE],
    X_sigma[y > 0, , drop = FALSE]
  )
  hu0 <- min(max(mean(y == 0), 0.02), 0.8)
  beta_hu <- numeric(ncol(X_hu))
  beta_hu[[1L]] <- stats::qlogis(hu0)
  nb$beta_zi <- beta_hu
  nb
}

hurdle_nbinom2_map <- function() {
  out <- nbinom2_map()
  out$beta_zi <- NULL
  out
}

zi_nbinom2_start <- function(
  y,
  X_mu,
  X_sigma,
  X_zi,
  offset_mu = rep(0, length(y))
) {
  nb <- nbinom2_start(y, X_mu, X_sigma, offset_mu)
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

zi_nbinom2_map <- function() {
  out <- nbinom2_map()
  out$beta_zi <- NULL
  out
}

gamma_ls_start <- function(y, X_mu, X_sigma) {
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
      log_sd_phylo = 0
    )
  )
}

cumulative_logit_start <- function(y, X_mu, n_categories) {
  beta_mu <- rep(0, ncol(X_mu))
  names(beta_mu) <- colnames(X_mu)

  cumulative <- cumsum(tabulate(y, nbins = n_categories)) / length(y)
  cutpoints <- stats::qlogis(cumulative[-n_categories])
  theta_ord <- ordinal_raw_from_cutpoints(cutpoints)

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
      u_phylo = 0,
      log_sd_phylo = 0
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

cumulative_logit_map <- function() {
  list(
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
    u_phylo = factor(NA),
    log_sd_phylo = factor(NA)
  )
}

gaussian_phylo_start <- function(y, phylo_mu) {
  if (!isTRUE(phylo_mu$has)) {
    return(list(u_phylo = 0, log_sd_phylo = 0))
  }
  y_scale <- stats::sd(y)
  if (!is.finite(y_scale) || y_scale <= 0) {
    y_scale <- 1
  }
  list(
    u_phylo = rep(0, phylo_mu$n_re),
    log_sd_phylo = log(max(0.25 * y_scale, 1e-4))
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
  re_mu_sigma = empty_mu_sigma_random_covariance(re_sigma$n_re)
) {
  fit1 <- stats::lm.fit(x = X_mu1, y = y1)
  fit2 <- stats::lm.fit(x = X_mu2, y = y2)
  beta_mu1 <- fit1$coefficients
  beta_mu2 <- fit2$coefficients
  beta_mu1[is.na(beta_mu1)] <- 0
  beta_mu2[is.na(beta_mu2)] <- 0

  resid1 <- y1 - as.vector(X_mu1 %*% beta_mu1)
  resid2 <- y2 - as.vector(X_mu2 %*% beta_mu2)
  V1 <- V_known_diag[seq.int(1L, by = 2L, length.out = length(y1))]
  V2 <- V_known_diag[seq.int(2L, by = 2L, length.out = length(y1))]
  sigma_floor <- 1e-4
  sigma1 <- sqrt(max(
    stats::var(resid1) - stats::median(V1, na.rm = TRUE),
    sigma_floor^2
  ))
  sigma2 <- sqrt(max(
    stats::var(resid2) - stats::median(V2, na.rm = TRUE),
    sigma_floor^2
  ))
  if (!is.finite(sigma1) || sigma1 <= 0) {
    sigma1 <- stats::sd(y1)
  }
  if (!is.finite(sigma2) || sigma2 <= 0) {
    sigma2 <- stats::sd(y2)
  }
  if (!is.finite(sigma1) || sigma1 <= 0) {
    sigma1 <- 1
  }
  if (!is.finite(sigma2) || sigma2 <= 0) {
    sigma2 <- 1
  }

  rho <- stats::cor(resid1, resid2)
  if (!is.finite(rho)) {
    rho <- 0
  }
  rho <- max(min(rho, 0.8), -0.8)

  beta_sigma1 <- numeric(ncol(X_sigma1))
  beta_sigma2 <- numeric(ncol(X_sigma2))
  beta_rho12 <- numeric(ncol(X_rho12))
  beta_sigma1[1L] <- log(sigma1)
  beta_sigma2[1L] <- log(sigma2)
  beta_rho12[1L] <- atanh(rho)

  y1_scale <- stats::sd(resid1)
  y2_scale <- stats::sd(resid2)
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
  sigma_re_start <- gaussian_sigma_re_start(re_sigma)

  c(
    list(
      beta_mu = 0,
      beta_sigma = 0,
      beta_nu = 0,
      beta_zi = 0,
      theta_ord = 0,
      beta_sd_mu = 0,
      u_mu = mu_re_start$u_mu,
      log_sd_mu = mu_re_start$log_sd_mu,
      eta_cor_mu = mu_re_start$eta_cor_mu,
      eta_cor_mu_sigma = rep(0, max(1L, re_mu_sigma$n_cors)),
      eta_cor_sigma = sigma_re_start$eta_cor_sigma,
      u_sigma = sigma_re_start$u_sigma,
      log_sd_sigma = sigma_re_start$log_sd_sigma
    ),
    list(
      beta_mu1 = beta_mu1,
      beta_mu2 = beta_mu2,
      beta_sigma1 = beta_sigma1,
      beta_sigma2 = beta_sigma2,
      beta_rho12 = beta_rho12
    ),
    list(
      u_phylo = 0,
      log_sd_phylo = 0
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
  re_mu_sigma = empty_mu_sigma_random_covariance(re_sigma$n_re)
) {
  out <- list(
    beta_mu1 = factor(NA),
    beta_mu2 = factor(NA),
    beta_sigma1 = factor(NA),
    beta_sigma2 = factor(NA),
    beta_rho12 = factor(NA),
    beta_nu = factor(NA),
    beta_zi = factor(NA),
    theta_ord = factor(NA)
  )
  if (!isTRUE(phylo_mu$has)) {
    out$u_phylo <- factor(NA)
    out$log_sd_phylo <- factor(NA)
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
  if (sd_mu$n_models == 0L) {
    out$beta_sd_mu <- factor(NA)
  }
  out
}

student_ls_map <- function() {
  list(
    beta_sd_mu = factor(NA),
    beta_mu1 = factor(NA),
    beta_mu2 = factor(NA),
    beta_sigma1 = factor(NA),
    beta_sigma2 = factor(NA),
    beta_rho12 = factor(NA),
    beta_zi = factor(NA),
    theta_ord = factor(NA),
    u_mu = factor(NA),
    log_sd_mu = factor(NA),
    eta_cor_mu = factor(NA),
    eta_cor_mu_sigma = factor(NA),
    eta_cor_sigma = factor(NA),
    u_sigma = factor(NA),
    log_sd_sigma = factor(NA),
    u_phylo = factor(NA),
    log_sd_phylo = factor(NA)
  )
}

biv_gaussian_map <- function(
  re_mu = empty_random_mu_structure(1L),
  re_sigma = empty_random_sigma_structure(1L),
  re_mu_sigma = empty_mu_sigma_random_covariance(re_sigma$n_re)
) {
  out <- list(
    beta_mu = factor(NA),
    beta_sigma = factor(NA),
    beta_nu = factor(NA),
    beta_zi = factor(NA),
    theta_ord = factor(NA),
    beta_sd_mu = factor(NA),
    u_phylo = factor(NA),
    log_sd_phylo = factor(NA)
  )
  if (re_mu$n_re == 0L) {
    out$u_mu <- factor(NA)
    out$log_sd_mu <- factor(NA)
  }
  if (re_mu$n_cors == 0L) {
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
  out
}

add_covariance_block_tmb_data <- function(tmb_data, spec) {
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
  c(tmb_data, cov_tmb_data)
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
    return(list(
      model_type = 1L,
      y = spec$y,
      trials = tmb_trials,
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
      y1 = numeric(1),
      y2 = numeric(1),
      X_mu = spec$X$mu,
      X_sigma = spec$X$sigma,
      X_nu = dummy_matrix,
      X_zi = dummy_matrix,
      X_sd_mu = spec$random_scale$mu$X,
      has_sd_mu_model = as.integer(spec$random_scale$mu$n_models > 0L),
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
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
      X_sd_mu = dummy_matrix,
      has_sd_mu_model = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
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
      phylo_mu_node_index = 0L,
      Q_phylo = dummy_sparse,
      log_det_Q_phylo = 0
    ))
  }
  if (identical(spec$model_type, "lognormal")) {
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
      X_sd_mu = dummy_matrix,
      has_sd_mu_model = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
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
      phylo_mu_node_index = 0L,
      Q_phylo = dummy_sparse,
      log_det_Q_phylo = 0
    ))
  }
  if (identical(spec$model_type, "gamma")) {
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
      X_sd_mu = dummy_matrix,
      has_sd_mu_model = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
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
      phylo_mu_node_index = 0L,
      Q_phylo = dummy_sparse,
      log_det_Q_phylo = 0
    ))
  }
  if (identical(spec$model_type, "beta")) {
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
      X_sd_mu = dummy_matrix,
      has_sd_mu_model = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
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
      phylo_mu_node_index = 0L,
      Q_phylo = dummy_sparse,
      log_det_Q_phylo = 0
    ))
  }
  if (identical(spec$model_type, "beta_binomial")) {
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
      X_sd_mu = dummy_matrix,
      has_sd_mu_model = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
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
      phylo_mu_node_index = 0L,
      Q_phylo = dummy_sparse,
      log_det_Q_phylo = 0
    ))
  }
  if (identical(spec$model_type, "cumulative_logit")) {
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
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
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
      phylo_mu_node_index = 0L,
      Q_phylo = dummy_sparse,
      log_det_Q_phylo = 0
    ))
  }
  if (identical(spec$model_type, "poisson")) {
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
      X_sd_mu = dummy_matrix,
      has_sd_mu_model = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
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
      phylo_mu_node_index = 0L,
      Q_phylo = dummy_sparse,
      log_det_Q_phylo = 0
    ))
  }
  if (identical(spec$model_type, "zi_poisson")) {
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
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
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
      phylo_mu_node_index = 0L,
      Q_phylo = dummy_sparse,
      log_det_Q_phylo = 0
    ))
  }
  if (identical(spec$model_type, "nbinom2")) {
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
      X_sd_mu = dummy_matrix,
      has_sd_mu_model = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
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
      phylo_mu_node_index = 0L,
      Q_phylo = dummy_sparse,
      log_det_Q_phylo = 0
    ))
  }
  if (identical(spec$model_type, "truncated_nbinom2")) {
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
      X_sd_mu = dummy_matrix,
      has_sd_mu_model = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
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
      phylo_mu_node_index = 0L,
      Q_phylo = dummy_sparse,
      log_det_Q_phylo = 0
    ))
  }
  if (identical(spec$model_type, "hurdle_nbinom2")) {
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
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
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
      phylo_mu_node_index = 0L,
      Q_phylo = dummy_sparse,
      log_det_Q_phylo = 0
    ))
  }
  if (identical(spec$model_type, "zi_nbinom2")) {
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
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
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
      phylo_mu_node_index = 0L,
      Q_phylo = dummy_sparse,
      log_det_Q_phylo = 0
    ))
  }
  if (identical(spec$model_type, "biv_gaussian")) {
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
      X_sd_mu = dummy_matrix,
      has_sd_mu_model = 0L,
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
      has_phylo_mu = 0L,
      phylo_mu_node_index = 0L,
      Q_phylo = dummy_sparse,
      log_det_Q_phylo = 0
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

  if (
    identical(spec$model_type, "gaussian") ||
      identical(spec$model_type, "student") ||
      identical(spec$model_type, "lognormal") ||
      identical(spec$model_type, "gamma") ||
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
    if (identical(spec$model_type, "student")) {
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

  list(
    mu1 = beta_mu1,
    mu2 = beta_mu2,
    sigma1 = beta_sigma1,
    sigma2 = beta_sigma2,
    rho12 = beta_rho12
  )
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
  if (!spec$model_type %in% c("gaussian", "biv_gaussian")) {
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
  if (isTRUE(spec$structured$phylo_mu$has)) {
    sd_phylo <- stats::setNames(
      exp(unname(par$log_sd_phylo)),
      spec$structured$phylo_mu$label
    )
    out$mu <- c(out$mu, sd_phylo)
  }
  out
}

split_tmb_corpars <- function(par, spec) {
  if (!spec$model_type %in% c("gaussian", "biv_gaussian")) {
    return(list())
  }

  out <- list()
  if (spec$random$mu$n_cors > 0L) {
    rho_mu <- 0.999999 *
      tanh(unname(par$eta_cor_mu[seq_len(spec$random$mu$n_cors)]))
    names(rho_mu) <- spec$random$mu$cor_labels
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

  out
}

split_tmb_random_effects <- function(par, spec) {
  if (!spec$model_type %in% c("gaussian", "biv_gaussian")) {
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
  if (isTRUE(spec$structured$phylo_mu$has)) {
    latent <- unname(par$u_phylo[seq_len(spec$structured$phylo_mu$n_re)])
    names(latent) <- spec$structured$phylo_mu$node_labels
    out$phylo_mu <- list(
      values = latent,
      latent = latent,
      terms = stats::setNames(
        list(latent),
        spec$structured$phylo_mu$label
      )
    )
  }
  out
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
