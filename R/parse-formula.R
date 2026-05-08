parse_drm_formula_entries <- function(calls, names) {
  entries <- vector("list", length(calls))
  for (i in seq_along(calls)) {
    entries[[i]] <- parse_drm_formula_entry(calls[[i]], names[[i]], i)
  }
  class(entries) <- "drm_formula_entries"
  entries
}

parse_drm_formula_entry <- function(expr, name, position) {
  if (!is_formula_call(expr)) {
    cli::cli_abort(
      "{.fn bf} inputs must be formulas; input {position} is not a formula."
    )
  }

  lhs <- formula_lhs(expr)
  rhs <- formula_rhs(expr)
  has_name <- nzchar(name)
  has_lhs <- !is.null(lhs)

  if (has_name && has_lhs && is_sd_lhs(lhs)) {
    cli::cli_abort(
      "{.fn sd} random-effect scale formulas should be unnamed, for example {.code sd(id) ~ x}."
    )
  }

  if (has_name) {
    dpar <- name
    response <- if (has_lhs) deparse1(lhs) else NA_character_
  } else if (has_lhs && is_sd_lhs(lhs)) {
    sd_lhs <- parse_sd_lhs(lhs)
    dpar <- sd_lhs$dpar
    response <- NA_character_
  } else if (has_lhs && is_dpar_lhs(lhs)) {
    dpar <- deparse1(lhs)
    response <- NA_character_
  } else if (has_lhs) {
    dpar <- "mu"
    response <- deparse1(lhs)
  } else {
    cli::cli_abort(
      "{.fn bf} input {position} is missing both a parameter name and a left-hand side."
    )
  }

  list(
    position = position,
    dpar = dpar,
    response = response,
    lhs = lhs,
    rhs = rhs,
    expr = expr,
    source_name = name
  )
}

is_formula_call <- function(expr) {
  is.call(expr) && identical(expr[[1L]], as.name("~"))
}

formula_lhs <- function(expr) {
  if (length(expr) < 3L) {
    return(NULL)
  }
  expr[[2L]]
}

formula_rhs <- function(expr) {
  expr[[length(expr)]]
}

is_dpar_lhs <- function(lhs) {
  lhs_text <- deparse1(lhs)
  lhs_text %in% drm_known_dpars() || is_sd_lhs(lhs)
}

drm_known_dpars <- function() {
  c(
    "mu", "mu1", "mu2",
    "sigma", "sigma1", "sigma2",
    "shape", "skew", "nu",
    "zi", "zoi", "coi", "hu",
    "rho12"
  )
}

is_sd_lhs <- function(lhs) {
  is.call(lhs) && identical(lhs[[1L]], as.name("sd"))
}

parse_sd_lhs <- function(lhs) {
  lhs <- strip_parens(lhs)
  args <- as.list(lhs)[-1L]
  arg_names <- names(args)
  if (is.null(arg_names)) {
    arg_names <- rep("", length(args))
  }
  arg_names[is.na(arg_names)] <- ""

  if (length(args) != 1L || nzchar(arg_names[[1L]])) {
    cli::cli_abort(c(
      "Random-effect scale formulas currently support only {.code sd(group)} on the left-hand side.",
      "x" = "Use syntax like {.code sd(id) ~ x_group}.",
      "i" = "Explicit targets such as {.code sd(id, dpar = \"mu\", coef = \"(Intercept)\")} are planned for a later phase."
    ))
  }
  if (!is.symbol(args[[1L]])) {
    cli::cli_abort(c(
      "The {.fn sd} target must be a simple grouping variable.",
      "x" = "Use syntax like {.code sd(id) ~ x_group}."
    ))
  }

  group <- as.character(args[[1L]])
  list(
    group = group,
    dpar = paste0("sd(", group, ")")
  )
}
