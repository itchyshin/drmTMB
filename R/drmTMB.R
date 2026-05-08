#' Fit a distributional regression model with TMB
#'
#' `drmTMB()` is the main model-fitting entry point. The current implementation
#' supports univariate Gaussian location-scale models, including random
#' intercepts, independent numeric random slopes, and labelled or unlabelled
#' correlated numeric random intercept-slope blocks in the location formula,
#' known sampling covariance through `meta_known_V(V = V)`, residual-scale
#' random intercepts in the scale formula, and one or more group-level
#' random-effect scale formulae such as `sd(id) ~ x_group`, plus
#' intercept-only phylogenetic random effects in the univariate Gaussian
#' location formula, and fixed-effect bivariate Gaussian distributional models.
#'
#' @param formula A `drm_formula` object created by [drm_formula()] or [bf()].
#' @param family A response family, such as [stats::gaussian()] or
#'   [biv_gaussian()]. The current bivariate Gaussian engine also accepts
#'   `family = c(gaussian(), gaussian())` and
#'   `family = list(gaussian(), gaussian())`.
#' @param data A data frame.
#' @param control Optional list passed to [stats::nlminb()].
#' @param ... Reserved for future model options.
#'
#' @return A `drmTMB` fit object.
#' @export
drmTMB <- function(formula, family = stats::gaussian(), data, control = list(), ...) {
  if (!inherits(formula, "drm_formula")) {
    cli::cli_abort("{.arg formula} must be created with {.fn drm_formula} or {.fn bf}.")
  }
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort("{.fn drmTMB} does not use arguments in {.arg ...} yet.")
  }
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame.")
  }

  family_type <- drm_family_type(family)
  spec <- switch(
    family_type,
    gaussian = drm_build_gaussian_ls_spec(formula, data, env = parent.frame()),
    biv_gaussian = drm_build_biv_gaussian_spec(formula, data, env = parent.frame())
  )

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
    control = control
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
    logLik = -opt$objective,
    df = length(opt$par),
    nobs = spec$nobs
  )
  class(fit) <- "drmTMB"
  fit
}

drm_family_type <- function(family) {
  if (inherits(family, "family") && identical(family$family, "gaussian")) {
    return("gaussian")
  }
  if (inherits(family, "drm_family") && identical(family$name, "biv_gaussian")) {
    return("biv_gaussian")
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
    "Currently supported families are {.code gaussian()}, {.fn biv_gaussian}, {.code c(gaussian(), gaussian())}, and {.code list(gaussian(), gaussian())}."
  )
}

drm_composed_families <- function(family) {
  if (is.list(family) && !inherits(family, "family") &&
      !inherits(family, "drm_family") && length(family) >= 2L &&
      all(vapply(family, is_r_family_object, logical(1)))) {
    return(family)
  }
  if (!is.list(family) || inherits(family, "family") || inherits(family, "drm_family")) {
    return(NULL)
  }
  family_starts <- which(names(family) == "family")
  if (length(family_starts) < 2L || family_starts[[1L]] != 1L) {
    return(NULL)
  }
  family_ends <- c(family_starts[-1L] - 1L, length(family))
  families <- Map(function(start, end) {
    out <- family[seq.int(start, end)]
    class(out) <- "family"
    out
  }, family_starts, family_ends)
  if (!all(vapply(families, is_r_family_object, logical(1)))) {
    return(NULL)
  }
  families
}

is_r_family_object <- function(x) {
  inherits(x, "family") && is.character(x$family) && length(x$family) == 1L
}

drm_build_gaussian_ls_spec <- function(formula, data, env = parent.frame()) {
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
    cli::cli_abort("A univariate Gaussian model requires exactly one location formula.")
  }
  if (sum(dpars[!is_sd_dpar] == "sigma") > 1L) {
    cli::cli_abort("A univariate Gaussian model can have at most one residual {.code sigma} formula.")
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
    cli::cli_abort("The {.code mu} formula must include a response on the left-hand side.")
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

  mf_mu <- stats::model.frame(f_mu, data = data_model, na.action = stats::na.omit)
  mf_sigma <- stats::model.frame(f_sigma, data = data_model, na.action = stats::na.omit)
  y <- stats::model.response(mf_mu)

  X_mu <- stats::model.matrix(stats::delete.response(stats::terms(mf_mu)), mf_mu)
  X_sigma <- stats::model.matrix(stats::terms(mf_sigma), mf_sigma)
  re_mu <- build_random_mu_structure(mu_re$terms, data_model)
  re_sigma <- build_random_sigma_structure(sigma_re$terms, data_model)
  sd_mu <- build_sd_mu_structure(sd_mu_entries, sd_mu_targets, re_mu, data_model)
  phylo_mu <- build_phylo_mu_structure(mu_phylo$term, data_model, env)

  if (length(y) != nrow(X_sigma)) {
    cli::cli_abort("Internal model-frame mismatch between {.code mu} and {.code sigma}.")
  }

  if (length(y) == 0L) {
    cli::cli_abort("No complete observations remain after applying model and known-variance missingness rules.")
  }

  start <- gaussian_ls_start(y, X_mu, X_sigma, V_known$diag, re_mu, re_sigma, sd_mu)
  start <- c(start, gaussian_ls_dummy_start(phylo_mu, y = y))

  spec <- list(
    model_type = "gaussian",
    y = as.numeric(y),
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
    random = list(mu = re_mu, sigma = re_sigma),
    random_scale = list(mu = sd_mu),
    structured = list(phylo_mu = phylo_mu),
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = c("mu", "sigma", sd_mu$dpars),
    start = start,
    map = gaussian_ls_map(re_mu, re_sigma, sd_mu, phylo_mu),
    random_names = c(
      if (re_mu$n_re > 0L) "u_mu",
      if (re_sigma$n_re > 0L) "u_sigma",
      if (isTRUE(phylo_mu$has)) "u_phylo"
    )
  )
  spec$tmb_data <- make_tmb_data(spec)
  spec$nobs <- length(spec$y)
  spec
}

drm_build_biv_gaussian_spec <- function(formula, data, env = parent.frame()) {
  entries <- formula$entries
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
      cli::cli_abort("{.fn biv_gaussian} requires exactly one {.code {required}} formula.")
    }
  }
  for (optional in c("sigma1", "sigma2", "rho12")) {
    if (sum(dpars == optional) > 1L) {
      cli::cli_abort("{.fn biv_gaussian} can have at most one {.code {optional}} formula.")
    }
  }

  mu1_entry <- entries[[which(dpars == "mu1")]]
  mu2_entry <- entries[[which(dpars == "mu2")]]
  sigma1_entry <- if (any(dpars == "sigma1")) entries[[which(dpars == "sigma1")]] else default_dpar_entry("sigma1", quote(1))
  sigma2_entry <- if (any(dpars == "sigma2")) entries[[which(dpars == "sigma2")]] else default_dpar_entry("sigma2", quote(1))
  rho12_entry <- if (any(dpars == "rho12")) entries[[which(dpars == "rho12")]] else default_dpar_entry("rho12", quote(1))

  if (is.na(mu1_entry$response) || is.na(mu2_entry$response)) {
    cli::cli_abort("{.code mu1} and {.code mu2} formulas must include responses on the left-hand side.")
  }

  for (entry in list(mu1_entry, mu2_entry, sigma1_entry, sigma2_entry, rho12_entry)) {
    if (formula_contains_call(entry$rhs, "meta_known_V")) {
      cli::cli_abort("{.fn biv_gaussian} does not support {.fn meta_known_V} yet.")
    }
    drm_reject_phase1_terms(entry$rhs, entry$dpar)
  }

  f_mu1 <- drm_entry_formula(mu1_entry, response = TRUE)
  f_mu2 <- drm_entry_formula(mu2_entry, response = TRUE)
  f_sigma1 <- drm_entry_formula(sigma1_entry, response = FALSE)
  f_sigma2 <- drm_entry_formula(sigma2_entry, response = FALSE)
  f_rho12 <- drm_entry_formula(rho12_entry, response = FALSE)

  vars <- unique(c(
    all.vars(f_mu1), all.vars(f_mu2), all.vars(f_sigma1),
    all.vars(f_sigma2), all.vars(f_rho12)
  ))
  keep <- stats::complete.cases(data[, vars, drop = FALSE])
  data_model <- data[keep, , drop = FALSE]

  mf_mu1 <- stats::model.frame(f_mu1, data = data_model, na.action = stats::na.omit)
  mf_mu2 <- stats::model.frame(f_mu2, data = data_model, na.action = stats::na.omit)
  mf_sigma1 <- stats::model.frame(f_sigma1, data = data_model, na.action = stats::na.omit)
  mf_sigma2 <- stats::model.frame(f_sigma2, data = data_model, na.action = stats::na.omit)
  mf_rho12 <- stats::model.frame(f_rho12, data = data_model, na.action = stats::na.omit)

  y1 <- stats::model.response(mf_mu1)
  y2 <- stats::model.response(mf_mu2)
  X_mu1 <- stats::model.matrix(stats::delete.response(stats::terms(mf_mu1)), mf_mu1)
  X_mu2 <- stats::model.matrix(stats::delete.response(stats::terms(mf_mu2)), mf_mu2)
  X_sigma1 <- stats::model.matrix(stats::terms(mf_sigma1), mf_sigma1)
  X_sigma2 <- stats::model.matrix(stats::terms(mf_sigma2), mf_sigma2)
  X_rho12 <- stats::model.matrix(stats::terms(mf_rho12), mf_rho12)

  n <- length(y1)
  if (n == 0L) {
    cli::cli_abort("No complete observations remain after applying bivariate model missingness rules.")
  }
  if (!all(c(length(y2), nrow(X_sigma1), nrow(X_sigma2), nrow(X_rho12)) == n)) {
    cli::cli_abort("Internal model-frame mismatch in bivariate Gaussian model.")
  }

  start <- biv_gaussian_start(y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12)

  spec <- list(
    model_type = "biv_gaussian",
    y1 = as.numeric(y1),
    y2 = as.numeric(y2),
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
      mu = empty_random_mu_structure(nrow(data_model)),
      sigma = empty_random_sigma_structure(nrow(data_model))
    ),
    random_scale = list(mu = empty_sd_mu_structure(1L)),
    structured = list(phylo_mu = empty_phylo_mu_structure()),
    variables = vars,
    keep = keep,
    dpars = c("mu1", "mu2", "sigma1", "sigma2", "rho12"),
    start = start,
    map = biv_gaussian_map(),
    random_names = NULL
  )
  spec$tmb_data <- make_tmb_data(spec)
  spec$nobs <- length(spec$y1)
  spec
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
    expr <- call("~", as.name(entry$response), entry$rhs)
  } else {
    expr <- call("~", entry$rhs)
  }
  stats::as.formula(expr, env = parent.frame())
}

drm_reject_phase1_terms <- function(rhs, dpar) {
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
  hits <- unsupported[vapply(
    unsupported,
    function(name) formula_contains_call(rhs, name),
    logical(1)
  )]
  if (length(hits) > 0L) {
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

  if (is_random_bar_call(lhs)) {
    cli::cli_abort(c(
      "Labelled covariance blocks are not implemented for {.code {dpar}} random effects yet.",
      "x" = "Use unlabelled residual-scale random intercepts such as {.code sigma ~ z + (1 | id)}."
    ))
  }
  if (!is.symbol(group)) {
    cli::cli_abort(c(
      "Random-effect grouping terms must be simple variables.",
      "x" = "Use syntax like {.code sigma ~ z + (1 | id)}."
    ))
  }

  lhs <- strip_parens(lhs)
  if (!is_intercept_one(lhs)) {
    cli::cli_abort(c(
      "Only random intercepts are implemented for residual {.code sigma} random effects.",
      "x" = "Use {.code sigma ~ z + (1 | id)}.",
      "i" = "Residual-scale random slopes are planned for a later phase."
    ))
  }

  group_name <- as.character(group)
  list(
    type = "intercept",
    variable = NA_character_,
    variables = NA_character_,
    coef_names = "(Intercept)",
    label = format_random_mu_label("1", group_name),
    group = group_name,
    covariance_label = NULL
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
      label = format_random_mu_label(paste0("0 + ", variable), group, covariance_label)
    ))
  }

  one <- vapply(pieces, is_intercept_one, logical(1))
  symbol <- vapply(pieces, is.symbol, logical(1))
  if (!any(zero) && sum(one) <= 1L && sum(symbol) == 1L &&
      length(pieces) == sum(one) + sum(symbol)) {
    variable <- as.character(pieces[[which(symbol)]])
    return(list(
      type = "correlated_slope",
      variable = variable,
      variables = variable,
      coef_names = c("(Intercept)", variable),
      label = format_random_mu_label(paste0("1 + ", variable), group, covariance_label)
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
    "mu", "mu1", "mu2",
    "sigma", "sigma1", "sigma2",
    "rho", "rho12",
    "nu", "skew", "kurtosis", "shape",
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

format_random_mu_cor_label <- function(coef_names, group, covariance_label = NULL) {
  group_label <- if (is.null(covariance_label)) {
    group
  } else {
    paste0(covariance_label, " | ", group)
  }
  paste0("cor(", coef_names[[1L]], ",", coef_names[[2L]], " | ", group_label, ")")
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
  is_phylo <- vapply(terms, is_structured_marker_call, logical(1), name = "phylo")
  if (!any(is_phylo)) {
    return(list(rhs = entry$rhs, term = NULL))
  }
  if (sum(is_phylo) > 1L) {
    cli::cli_abort(c(
      "Only one phylogenetic structured effect is implemented in {.code mu}.",
      "x" = "Use one term such as {.code phylo(1 | species, tree = tree)}."
    ))
  }

  phylo_terms <- Filter(function(term) identical(term$type, "phylo"), entry$structured)
  if (length(phylo_terms) != 1L) {
    cli::cli_abort("Internal formula parser error while extracting {.fn phylo}.")
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
    cli::cli_abort("Internal error: failed to align observations with phylogenetic tip nodes.")
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
    coef_names <- unique(unlist(lapply(mu_terms[matches], `[[`, "coef_names"), use.names = FALSE))
    cli::cli_abort(c(
      "Ambiguous random-effect scale target {.code {entry$dpar}}.",
      "x" = "Group {.field {target_group}} has multiple {.code mu} random-effect coefficients: {.val {coef_names}}.",
      "i" = "Explicit coefficient-specific {.fn sd} targets are planned for a later phase."
    ))
  }

  target_coef <- sum(vapply(mu_terms[seq_len(matches - 1L)], function(term) {
    length(term$coef_names)
  }, integer(1))) + 1L
  term <- mu_terms[[matches]]
  if (!identical(term$type, "intercept") || !identical(term$coef_names, "(Intercept)")) {
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
    re_pos0 = 0L,
    re_cor_id0 = -1L,
    re_pair_index0 = -1L,
    n_cors = 0L,
    cor_labels = character(),
    labels = character(),
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
  re_pos0 <- integer()
  re_cor_id0 <- integer()
  re_pair_index0 <- integer()
  groups <- vector("list", length(labels))
  names(groups) <- labels
  value_names <- character()
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
      re_pos0 <- c(re_pos0, rep.int(p - 1L, length(levels_k)))
      re_cor_id0 <- c(re_cor_id0, rep.int(cor_id0, length(levels_k)))
      if (q == 2L && p == 2L) {
        re_pair_index0 <- c(re_pair_index0, offset + seq_len(length(levels_k)) - 1L)
      } else {
        re_pair_index0 <- c(re_pair_index0, rep.int(-1L, length(levels_k)))
      }
      groups[[coef_id]] <- levels_k
      value_names <- c(value_names, paste0(labels[[coef_id]], ":", levels_k))
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
    re_pos0 = re_pos0,
    re_cor_id0 = re_cor_id0,
    re_pair_index0 = re_pair_index0,
    n_cors = length(cor_labels),
    cor_labels = cor_labels,
    labels = labels,
    groups = groups,
    value_names = value_names
  )
}

build_random_sigma_structure <- function(terms, data) {
  re_sigma <- build_random_mu_structure(terms, data)
  if (re_sigma$n_cors > 0L) {
    cli::cli_abort("Internal error: residual sigma random-effect correlations are not implemented.")
  }
  re_sigma
}

build_sd_mu_structure <- function(entries, targets, re_mu, data) {
  if (length(entries) == 0L) {
    return(empty_sd_mu_structure(re_mu$n_re))
  }
  if (re_mu$n_re == 0L) {
    cli::cli_abort("Internal error: {.code sd()} target was validated without a {.code mu} random effect.")
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
    group <- factor(data[[target$group]], levels = re_mu$groups[[target$target_coef]])
    validate_sd_mu_group_constant(mf_sd, group, entry$dpar, target$group)

    group_first <- match(levels(group), as.character(group))
    if (anyNA(group_first)) {
      cli::cli_abort("Internal error: failed to align {.code sd()} scale rows with random-effect groups.")
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
      coef_names = if (length(dpars) == 1L) coef_names_list[[1L]] else colnames(X),
      coef_names_list = coef_names_list,
      group_levels = if (length(dpars) == 1L) group_levels_list[[1L]] else rownames(X),
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

validate_sd_mu_group_constant <- function(model_frame, group, dpar, group_name) {
  if (ncol(model_frame) == 0L) {
    return(invisible(model_frame))
  }
  for (variable in names(model_frame)) {
    values <- model_frame[[variable]]
    variable_ok <- vapply(split(values, group), function(x) {
      length(unique(x)) <= 1L
    }, logical(1))
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
  labels <- unlist(lapply(terms, function(term) {
    if (length(term$coef_names) == 1L) {
      return(term$label)
    }
    paste0(term$label, ":", term$coef_names)
  }), use.names = FALSE)
  list(labels = labels)
}

validate_random_mu_term_overlap <- function(terms) {
  keys <- unlist(lapply(terms, function(term) {
    coef_names <- term$coef_names
    paste(term$group, coef_names, sep = "::")
  }), use.names = FALSE)
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
      cli::cli_abort("{.arg V} matrix must have one row and one column per observation.")
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
    cli::cli_abort("{.arg V} must evaluate to a numeric vector of known sampling variances.")
  }
  new_known_v(as.numeric(value), type = "diagonal")
}

known_v_complete <- function(V_known) {
  if (identical(V_known$type, "matrix")) {
    rep(TRUE, nrow(V_known$V))
  } else {
    is.finite(V_known$diag) & !is.na(V_known$diag)
  }
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
    cli::cli_abort("{.arg V} must contain non-negative known sampling variances.")
  }
  invisible(value)
}

validate_known_v_matrix <- function(value) {
  if (any(!is.finite(value) | is.na(value))) {
    cli::cli_abort("{.arg V} matrix must contain only finite values.")
  }
  if (!isTRUE(all.equal(value, t(value), tolerance = sqrt(.Machine$double.eps)))) {
    cli::cli_abort("{.arg V} matrix must be symmetric.")
  }
  validate_known_v_diag(diag(value))
  ev <- eigen((value + t(value)) / 2, symmetric = TRUE, only.values = TRUE)$values
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

gaussian_ls_start <- function(y, X_mu, X_sigma, V_known = rep(0, length(y)),
                              re_mu = empty_random_mu_structure(length(y)),
                              re_sigma = empty_random_sigma_structure(length(y)),
                              sd_mu = empty_sd_mu_structure(re_mu$n_re)) {
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
    u_sigma = sigma_re_start$u_sigma,
    log_sd_sigma = sigma_re_start$log_sd_sigma
  )
}

gaussian_ls_dummy_start <- function(phylo_mu = empty_phylo_mu_structure(),
                                    y = NULL) {
  phylo_start <- gaussian_phylo_start(y, phylo_mu)
  list(
    beta_mu1 = 0,
    beta_mu2 = 0,
    beta_sigma1 = 0,
    beta_sigma2 = 0,
    beta_rho12 = 0,
    u_phylo = phylo_start$u_phylo,
    log_sd_phylo = phylo_start$log_sd_phylo
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
      group_est <- ifelse(moment$den > sqrt(.Machine$double.eps), moment$num / moment$den, NA_real_)
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
    return(list(u_sigma = 0, log_sd_sigma = 0))
  }
  list(
    u_sigma = rep(0, re_sigma$n_re),
    log_sd_sigma = rep(log(0.2), re_sigma$n_terms)
  )
}

gaussian_sd_mu_start <- function(mu_re_start, sd_mu) {
  if (sd_mu$n_models == 0L) {
    return(0)
  }
  out <- numeric(ncol(sd_mu$X))
  for (dpar in sd_mu$dpars) {
    coef_index <- sd_mu$coef_index[[dpar]]
    out[[coef_index[[1L]]]] <- mu_re_start$log_sd_mu[[sd_mu$target_coef[[dpar]]]]
  }
  names(out) <- colnames(sd_mu$X)
  out
}

biv_gaussian_start <- function(y1, y2, X_mu1, X_mu2, X_sigma1, X_sigma2, X_rho12) {
  fit1 <- stats::lm.fit(x = X_mu1, y = y1)
  fit2 <- stats::lm.fit(x = X_mu2, y = y2)
  beta_mu1 <- fit1$coefficients
  beta_mu2 <- fit2$coefficients
  beta_mu1[is.na(beta_mu1)] <- 0
  beta_mu2[is.na(beta_mu2)] <- 0

  resid1 <- y1 - as.vector(X_mu1 %*% beta_mu1)
  resid2 <- y2 - as.vector(X_mu2 %*% beta_mu2)
  sigma1 <- stats::sd(resid1)
  sigma2 <- stats::sd(resid2)
  if (!is.finite(sigma1) || sigma1 <= 0) sigma1 <- stats::sd(y1)
  if (!is.finite(sigma2) || sigma2 <= 0) sigma2 <- stats::sd(y2)
  if (!is.finite(sigma1) || sigma1 <= 0) sigma1 <- 1
  if (!is.finite(sigma2) || sigma2 <= 0) sigma2 <- 1

  rho <- stats::cor(resid1, resid2)
  if (!is.finite(rho)) rho <- 0
  rho <- max(min(rho, 0.8), -0.8)

  beta_sigma1 <- numeric(ncol(X_sigma1))
  beta_sigma2 <- numeric(ncol(X_sigma2))
  beta_rho12 <- numeric(ncol(X_rho12))
  beta_sigma1[1L] <- log(sigma1)
  beta_sigma2[1L] <- log(sigma2)
  beta_rho12[1L] <- atanh(rho)

  c(
    list(
      beta_mu = 0,
      beta_sigma = 0,
      beta_sd_mu = 0,
      u_mu = 0,
      log_sd_mu = 0,
      eta_cor_mu = 0,
      u_sigma = 0,
      log_sd_sigma = 0
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

gaussian_ls_map <- function(re_mu = empty_random_mu_structure(1L),
                            re_sigma = empty_random_sigma_structure(1L),
                            sd_mu = empty_sd_mu_structure(re_mu$n_re),
                            phylo_mu = empty_phylo_mu_structure()) {
  out <- list(
    beta_mu1 = factor(NA),
    beta_mu2 = factor(NA),
    beta_sigma1 = factor(NA),
    beta_sigma2 = factor(NA),
    beta_rho12 = factor(NA)
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
  if (sd_mu$n_models == 0L) {
    out$beta_sd_mu <- factor(NA)
  }
  out
}

biv_gaussian_map <- function() {
  list(
    beta_mu = factor(NA),
    beta_sigma = factor(NA),
    beta_sd_mu = factor(NA),
    u_mu = factor(NA),
    log_sd_mu = factor(NA),
    eta_cor_mu = factor(NA),
    u_sigma = factor(NA),
    log_sd_sigma = factor(NA),
    u_phylo = factor(NA),
    log_sd_phylo = factor(NA)
  )
}

make_tmb_data <- function(spec) {
  dummy_matrix <- matrix(0, nrow = 1, ncol = 1)
  dummy_sparse <- Matrix::sparseMatrix(
    i = integer(0),
    j = integer(0),
    x = numeric(0),
    dims = c(1L, 1L)
  )
  if (identical(spec$model_type, "gaussian")) {
    phylo_mu <- spec$structured$phylo_mu
    return(list(
      model_type = 1L,
      y = spec$y,
      V_known = spec$V_known_diag,
      V_known_matrix = if (identical(spec$V_known_type, "matrix")) spec$V_known else dummy_matrix,
      V_known_type = as.integer(
        match(spec$V_known_type, c("none", "diagonal", "matrix")) - 1L
      ),
      y1 = numeric(1),
      y2 = numeric(1),
      X_mu = spec$X$mu,
      X_sigma = spec$X$sigma,
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
      mu_re_pos = spec$random$mu$re_pos0,
      mu_re_cor_id = spec$random$mu$re_cor_id0,
      mu_re_pair_index = spec$random$mu$re_pair_index0,
      mu_re_sd_row = spec$random_scale$mu$re_sd_row0,
      n_sigma_re_terms = spec$random$sigma$n_terms,
      sigma_re_index = spec$random$sigma$index0,
      sigma_re_value = spec$random$sigma$value,
      sigma_re_term = spec$random$sigma$term_id0,
      has_phylo_mu = as.integer(isTRUE(phylo_mu$has)),
      phylo_mu_node_index = if (isTRUE(phylo_mu$has)) phylo_mu$observation_node_index0 else 0L,
      Q_phylo = if (isTRUE(phylo_mu$has)) phylo_mu$precision$precision else dummy_sparse,
      log_det_Q_phylo = if (isTRUE(phylo_mu$has)) phylo_mu$precision$log_det_precision else 0
    ))
  }
  list(
    model_type = 2L,
    y = numeric(1),
    V_known = numeric(1),
    V_known_matrix = dummy_matrix,
    V_known_type = 0L,
    y1 = spec$y1,
    y2 = spec$y2,
    X_mu = dummy_matrix,
    X_sigma = dummy_matrix,
    X_sd_mu = dummy_matrix,
    has_sd_mu_model = 0L,
    X_mu1 = spec$X$mu1,
    X_mu2 = spec$X$mu2,
    X_sigma1 = spec$X$sigma1,
    X_sigma2 = spec$X$sigma2,
    X_rho12 = spec$X$rho12,
    n_mu_re_terms = 0L,
    n_mu_re_cors = 0L,
    mu_re_index = matrix(0L, nrow = 1L, ncol = 1L),
    mu_re_value = dummy_matrix,
    mu_re_term = 0L,
    mu_re_pos = 0L,
    mu_re_cor_id = -1L,
    mu_re_pair_index = -1L,
    mu_re_sd_row = -1L,
    n_sigma_re_terms = 0L,
    sigma_re_index = matrix(0L, nrow = 1L, ncol = 1L),
    sigma_re_value = dummy_matrix,
    sigma_re_term = 0L,
    has_phylo_mu = 0L,
    phylo_mu_node_index = 0L,
    Q_phylo = dummy_sparse,
    log_det_Q_phylo = 0
  )
}

split_tmb_parameters <- function(par, spec) {
  if (identical(spec$model_type, "gaussian")) {
    beta_mu <- unname(par$beta_mu)
    beta_sigma <- unname(par$beta_sigma)
    names(beta_mu) <- colnames(spec$X$mu)
    names(beta_sigma) <- colnames(spec$X$sigma)
    out <- list(mu = beta_mu, sigma = beta_sigma)
    if (spec$random_scale$mu$n_models > 0L) {
      beta_sd_mu <- unname(par$beta_sd_mu[seq_len(ncol(spec$random_scale$mu$X))])
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

split_tmb_sdpars <- function(par, spec) {
  if (!identical(spec$model_type, "gaussian")) {
    return(list())
  }
  out <- list()
  if (spec$random$mu$n_re > 0L) {
    unmodelled <- seq_len(spec$random$mu$n_terms)
    if (spec$random_scale$mu$n_models > 0L) {
      unmodelled <- setdiff(unmodelled, unname(spec$random_scale$mu$target_coef))
      for (dpar in spec$random_scale$mu$dpars) {
        sd_group <- sd_mu_group_values(par, spec$random_scale$mu, dpar = dpar)
        names(sd_group) <- paste0(dpar, ":", spec$random_scale$mu$group_levels_list[[dpar]])
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
    sd_sigma <- exp(unname(par$log_sd_sigma[seq_len(spec$random$sigma$n_terms)]))
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
  if (!identical(spec$model_type, "gaussian") || spec$random$mu$n_cors == 0L) {
    return(list())
  }
  rho_mu <- 0.999999 * tanh(unname(par$eta_cor_mu[seq_len(spec$random$mu$n_cors)]))
  names(rho_mu) <- spec$random$mu$cor_labels
  list(mu = rho_mu)
}

split_tmb_random_effects <- function(par, spec) {
  if (!identical(spec$model_type, "gaussian")) {
    return(list())
  }

  out <- list()
  if (spec$random$mu$n_re > 0L) {
    latent <- unname(par$u_mu[seq_len(spec$random$mu$n_re)])
    values <- transform_mu_random_effects(latent, par, spec$random$mu, spec$random_scale$mu)
    out$mu <- format_random_effect_values(latent, values, spec$random$mu)
  }
  if (spec$random$sigma$n_re > 0L) {
    latent <- unname(par$u_sigma[seq_len(spec$random$sigma$n_re)])
    values <- transform_independent_random_effects(
      latent,
      par$log_sd_sigma,
      spec$random$sigma
    )
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

transform_mu_random_effects <- function(latent, par, re_mu, sd_mu = empty_sd_mu_structure(re_mu$n_re)) {
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
