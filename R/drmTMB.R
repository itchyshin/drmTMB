#' Fit a distributional regression model with TMB
#'
#' `drmTMB()` is the main model-fitting entry point. The current implementation
#' supports univariate Gaussian location-scale models, including random
#' intercepts in the location formula, and fixed-effect bivariate Gaussian
#' distributional models.
#'
#' @param formula A `drm_formula` object created by [bf()].
#' @param family A response family, such as [stats::gaussian()] or
#'   [biv_gaussian()].
#' @param data A data frame.
#' @param control Optional list passed to [stats::nlminb()].
#' @param ... Reserved for future model options.
#'
#' @return A `drmTMB` fit object.
#' @export
drmTMB <- function(formula, family = stats::gaussian(), data, control = list(), ...) {
  if (!inherits(formula, "drm_formula")) {
    cli::cli_abort("{.arg formula} must be created with {.fn bf}.")
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
  cli::cli_abort(
    "Currently supported families are {.code gaussian()} and {.fn biv_gaussian}."
  )
}

drm_build_gaussian_ls_spec <- function(formula, data, env = parent.frame()) {
  entries <- formula$entries
  dpars <- vapply(entries, `[[`, character(1), "dpar")

  unsupported <- setdiff(dpars, c("mu", "sigma"))
  if (length(unsupported) > 0L) {
    cli::cli_abort(c(
      "Phase 1 Gaussian models only support {.code mu} and {.code sigma}.",
      "x" = "Unsupported parameter{?s}: {.val {unsupported}}."
    ))
  }

  if (sum(dpars == "mu") != 1L) {
    cli::cli_abort("A univariate Gaussian model requires exactly one location formula.")
  }
  if (sum(dpars == "sigma") > 1L) {
    cli::cli_abort("A univariate Gaussian model can have at most one residual {.code sigma} formula.")
  }

  mu_entry <- entries[[which(dpars == "mu")]]
  sigma_entry <- if (any(dpars == "sigma")) {
    entries[[which(dpars == "sigma")]]
  } else {
    default_dpar_entry("sigma", quote(1))
  }

  if (is.na(mu_entry$response)) {
    cli::cli_abort("The {.code mu} formula must include a response on the left-hand side.")
  }

  meta <- extract_meta_known_v(mu_entry$rhs)
  mu_entry$rhs <- meta$rhs
  mu_re <- extract_random_intercepts(mu_entry$rhs, "mu")
  mu_entry$rhs <- mu_re$rhs

  drm_reject_phase1_terms(mu_entry$rhs, "mu")
  drm_reject_phase1_terms(sigma_entry$rhs, "sigma")

  f_mu <- drm_entry_formula(mu_entry, response = TRUE)
  f_sigma <- drm_entry_formula(sigma_entry, response = FALSE)

  vars <- unique(c(all.vars(f_mu), all.vars(f_sigma), random_intercept_vars(mu_re$terms)))
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
  re_mu <- build_random_intercept_structure(mu_re$terms, data_model)

  if (length(y) != nrow(X_sigma)) {
    cli::cli_abort("Internal model-frame mismatch between {.code mu} and {.code sigma}.")
  }

  if (length(y) == 0L) {
    cli::cli_abort("No complete observations remain after applying model and known-variance missingness rules.")
  }

  start <- gaussian_ls_start(y, X_mu, X_sigma, V_known$diag, re_mu)
  start <- c(start, gaussian_ls_dummy_start())

  spec <- list(
    model_type = "gaussian",
    y = as.numeric(y),
    V_known = V_known$V,
    V_known_diag = V_known$diag,
    V_known_type = V_known$type,
    has_known_v = !is.null(meta$V),
    X = list(mu = X_mu, sigma = X_sigma),
    terms = list(
      mu = stats::delete.response(stats::terms(mf_mu)),
      sigma = stats::terms(mf_sigma)
    ),
    model_frame = list(mu = mf_mu, sigma = mf_sigma),
    random = list(mu = re_mu),
    data = data_model,
    variables = vars,
    keep = keep,
    dpars = c("mu", "sigma"),
    start = start,
    map = gaussian_ls_map(re_mu),
    random_names = if (re_mu$n_re > 0L) "u_mu" else NULL
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
    random = list(mu = empty_random_intercept_structure(nrow(data_model))),
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
    source_name = dpar
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

extract_random_intercepts <- function(rhs, dpar) {
  terms <- flatten_plus_terms(rhs)
  is_re <- vapply(terms, is_random_bar_call, logical(1))
  if (!any(is_re)) {
    return(list(rhs = rhs, terms = list()))
  }

  re_terms <- lapply(terms[is_re], parse_random_intercept_term, dpar = dpar)
  clean_terms <- terms[!is_re]
  list(rhs = rebuild_plus_terms(clean_terms), terms = re_terms)
}

is_random_bar_call <- function(expr) {
  expr <- strip_parens(expr)
  is.call(expr) && identical(expr[[1L]], as.name("|"))
}

parse_random_intercept_term <- function(expr, dpar) {
  expr <- strip_parens(expr)
  lhs <- expr[[2L]]
  group <- expr[[3L]]

  if (is_random_bar_call(lhs)) {
    cli::cli_abort(c(
      "Only simple random intercepts are implemented for {.code {dpar}}.",
      "x" = "Correlated-block syntax such as {.code (1 | p | id)} is planned later."
    ))
  }
  if (!is_intercept_one(lhs)) {
    cli::cli_abort(c(
      "Only random intercepts are implemented for {.code {dpar}}.",
      "x" = "Use syntax like {.code (1 | id)}."
    ))
  }
  if (!is.symbol(group)) {
    cli::cli_abort(c(
      "Random-intercept grouping terms must be simple variables.",
      "x" = "Use syntax like {.code (1 | id)}."
    ))
  }

  group_name <- as.character(group)
  list(
    group = group_name,
    label = paste0("(1 | ", group_name, ")")
  )
}

is_intercept_one <- function(expr) {
  is.numeric(expr) && length(expr) == 1L && identical(as.numeric(expr), 1)
}

random_intercept_vars <- function(terms) {
  vapply(terms, `[[`, character(1), "group")
}

empty_random_intercept_structure <- function(n) {
  list(
    n_terms = 0L,
    n_re = 0L,
    index = matrix(1L, nrow = n, ncol = 1L),
    index0 = matrix(0L, nrow = n, ncol = 1L),
    term_id0 = 0L,
    labels = character(),
    groups = list(),
    value_names = character()
  )
}

build_random_intercept_structure <- function(terms, data) {
  if (length(terms) == 0L) {
    return(empty_random_intercept_structure(nrow(data)))
  }

  labels <- vapply(terms, `[[`, character(1), "label")
  if (anyDuplicated(labels)) {
    cli::cli_abort("Duplicate random-intercept terms are not supported.")
  }

  index <- matrix(NA_integer_, nrow = nrow(data), ncol = length(terms))
  term_id0 <- integer()
  groups <- vector("list", length(terms))
  names(groups) <- labels
  value_names <- character()
  offset <- 0L

  for (k in seq_along(terms)) {
    group_name <- terms[[k]]$group
    group <- factor(data[[group_name]])
    levels_k <- levels(group)
    if (length(levels_k) < 2L) {
      cli::cli_abort(c(
        "Random-intercept grouping variable {.field {group_name}} has fewer than two levels.",
        "x" = "At least two groups are needed to estimate a random-effect SD."
      ))
    }
    if (all(tabulate(as.integer(group)) == 1L)) {
      cli::cli_abort(c(
        "Random-intercept grouping variable {.field {group_name}} has only singleton groups.",
        "x" = "At least one group must have repeated observations in this initial random-intercept implementation."
      ))
    }

    group_index <- as.integer(group)
    index[, k] <- offset + group_index
    term_id0 <- c(term_id0, rep.int(k - 1L, length(levels_k)))
    groups[[k]] <- levels_k
    value_names <- c(value_names, paste0(labels[[k]], ":", levels_k))
    offset <- offset + length(levels_k)
  }

  list(
    n_terms = length(terms),
    n_re = offset,
    index = index,
    index0 = index - 1L,
    term_id0 = term_id0,
    labels = labels,
    groups = groups,
    value_names = value_names
  )
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
                              re_mu = empty_random_intercept_structure(length(y))) {
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

  re_start <- gaussian_mu_re_start(resid, re_mu, y_scale)

  list(
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    u_mu = re_start$u_mu,
    log_sd_mu = re_start$log_sd_mu
  )
}

gaussian_ls_dummy_start <- function() {
  list(
    beta_mu1 = 0,
    beta_mu2 = 0,
    beta_sigma1 = 0,
    beta_sigma2 = 0,
    beta_rho12 = 0
  )
}

gaussian_mu_re_start <- function(resid, re_mu, y_scale) {
  if (re_mu$n_re == 0L) {
    return(list(u_mu = 0, log_sd_mu = 0))
  }

  log_sd_mu <- numeric(re_mu$n_terms)
  for (k in seq_len(re_mu$n_terms)) {
    group_means <- stats::aggregate(
      resid,
      by = list(group = re_mu$index[, k]),
      FUN = mean
    )$x
    sd0 <- stats::sd(group_means)
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
    log_sd_mu = log_sd_mu
  )
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
    list(beta_mu = 0, beta_sigma = 0, u_mu = 0, log_sd_mu = 0),
    list(
      beta_mu1 = beta_mu1,
      beta_mu2 = beta_mu2,
      beta_sigma1 = beta_sigma1,
      beta_sigma2 = beta_sigma2,
      beta_rho12 = beta_rho12
    )
  )
}

gaussian_ls_map <- function(re_mu = empty_random_intercept_structure(1L)) {
  out <- list(
    beta_mu1 = factor(NA),
    beta_mu2 = factor(NA),
    beta_sigma1 = factor(NA),
    beta_sigma2 = factor(NA),
    beta_rho12 = factor(NA)
  )
  if (re_mu$n_re == 0L) {
    out$u_mu <- factor(NA)
    out$log_sd_mu <- factor(NA)
  }
  out
}

biv_gaussian_map <- function() {
  list(
    beta_mu = factor(NA),
    beta_sigma = factor(NA),
    u_mu = factor(NA),
    log_sd_mu = factor(NA)
  )
}

make_tmb_data <- function(spec) {
  dummy_matrix <- matrix(0, nrow = 1, ncol = 1)
  if (identical(spec$model_type, "gaussian")) {
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
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
      n_mu_re_terms = spec$random$mu$n_terms,
      mu_re_index = spec$random$mu$index0,
      mu_re_term = spec$random$mu$term_id0
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
    X_mu1 = spec$X$mu1,
    X_mu2 = spec$X$mu2,
    X_sigma1 = spec$X$sigma1,
    X_sigma2 = spec$X$sigma2,
    X_rho12 = spec$X$rho12,
    n_mu_re_terms = 0L,
    mu_re_index = matrix(0L, nrow = 1L, ncol = 1L),
    mu_re_term = 0L
  )
}

split_tmb_parameters <- function(par, spec) {
  if (identical(spec$model_type, "gaussian")) {
    beta_mu <- unname(par$beta_mu)
    beta_sigma <- unname(par$beta_sigma)
    names(beta_mu) <- colnames(spec$X$mu)
    names(beta_sigma) <- colnames(spec$X$sigma)
    return(list(mu = beta_mu, sigma = beta_sigma))
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
  if (!identical(spec$model_type, "gaussian") || spec$random$mu$n_re == 0L) {
    return(list())
  }
  sd_mu <- exp(unname(par$log_sd_mu[seq_len(spec$random$mu$n_terms)]))
  names(sd_mu) <- spec$random$mu$labels
  list(mu = sd_mu)
}

split_tmb_random_effects <- function(par, spec) {
  if (!identical(spec$model_type, "gaussian") || spec$random$mu$n_re == 0L) {
    return(list())
  }

  latent <- unname(par$u_mu[seq_len(spec$random$mu$n_re)])
  sd_by_term <- exp(unname(par$log_sd_mu[seq_len(spec$random$mu$n_terms)]))
  values <- latent * sd_by_term[spec$random$mu$term_id0 + 1L]
  names(values) <- spec$random$mu$value_names
  by_term <- vector("list", spec$random$mu$n_terms)
  names(by_term) <- spec$random$mu$labels
  start <- 1L
  for (k in seq_len(spec$random$mu$n_terms)) {
    n_group <- length(spec$random$mu$groups[[k]])
    idx <- seq.int(start, length.out = n_group)
    by_term[[k]] <- values[idx]
    names(by_term[[k]]) <- spec$random$mu$groups[[k]]
    start <- start + n_group
  }

  names(latent) <- spec$random$mu$value_names
  list(mu = list(values = values, latent = latent, terms = by_term))
}
