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
      "{.fn drm_formula} inputs must be formulas; input {position} is not a formula."
    )
  }

  lhs <- formula_lhs(expr)
  rhs <- formula_rhs(expr)
  has_name <- nzchar(name)
  has_lhs <- !is.null(lhs)

  if (has_name && has_lhs && is_random_scale_lhs(lhs)) {
    cli::cli_abort(
      "Random-effect scale formulas should be unnamed, for example {.code sd(id) ~ x}."
    )
  }

  if (has_name) {
    dpar <- name
    response <- if (has_lhs) deparse1(lhs) else NA_character_
  } else if (has_lhs && is_random_scale_lhs(lhs)) {
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
      "{.fn drm_formula} input {position} is missing both a parameter name and a left-hand side."
    )
  }

  list(
    position = position,
    dpar = dpar,
    response = response,
    lhs = lhs,
    rhs = rhs,
    expr = expr,
    source_name = name,
    structured = collect_structured_effects(rhs, dpar)
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
  lhs_text %in% drm_known_dpars() || is_random_scale_lhs(lhs)
}

drm_known_dpars <- function() {
  c(
    "mu",
    "mu1",
    "mu2",
    "sigma",
    "sigma1",
    "sigma2",
    "shape",
    "skew",
    "nu",
    "zi",
    "zoi",
    "coi",
    "hu",
    "rho12"
  )
}

is_random_scale_lhs <- function(lhs) {
  is.call(lhs) &&
    random_scale_lhs_function(lhs) %in% random_scale_lhs_functions()
}

is_sd_lhs <- function(lhs) {
  is_random_scale_lhs(lhs)
}

random_scale_lhs_function <- function(lhs) {
  fun <- lhs[[1L]]
  if (is.symbol(fun)) {
    return(as.character(fun))
  }
  deparse1(fun)
}

random_scale_lhs_functions <- function() {
  c(
    "sd",
    "sd1",
    "sd2",
    "sd_phylo",
    "sd_phylo1",
    "sd_phylo2",
    "sd_spatial",
    "sd_spatial1",
    "sd_spatial2",
    "sd_sigma1",
    "sd_sigma2"
  )
}

parse_sd_lhs <- function(lhs) {
  lhs <- strip_parens(lhs)
  fun <- random_scale_lhs_function(lhs)
  if (
    fun %in%
      c(
        "sd_phylo",
        "sd_phylo1",
        "sd_phylo2",
        "sd_spatial",
        "sd_spatial1",
        "sd_spatial2"
      )
  ) {
    cli::cli_abort(c(
      "{.fn {fun}} random-effect SD models are planned but not implemented yet.",
      "i" = "This implementation currently supports {.code sd(group)} for univariate Gaussian location random effects and {.code sd1(group)} / {.code sd2(group)} for bivariate Gaussian location random effects."
    ))
  }
  if (fun %in% c("sd_sigma1", "sd_sigma2")) {
    cli::cli_abort(c(
      "{.fn {fun}} is not a supported drmTMB random-effect scale target.",
      "x" = "Direct {.fn sd} models target location random-effect SDs only.",
      "i" = "Use {.code sigma1 ~ ...} / {.code sigma2 ~ ...} for residual scale predictors, or use scale random effects inside the Family A formulation without a matching {.fn sd_sigma} target."
    ))
  }

  args <- as.list(lhs)[-1L]
  arg_names <- names(args)
  if (is.null(arg_names)) {
    arg_names <- rep("", length(args))
  }
  arg_names[is.na(arg_names)] <- ""

  if (length(args) != 1L || nzchar(arg_names[[1L]])) {
    cli::cli_abort(c(
      "Random-effect scale formulas currently support only {.code sd(group)}, {.code sd1(group)}, or {.code sd2(group)} on the left-hand side.",
      "x" = "Use syntax like {.code sd(id) ~ x_group} or {.code sd1(id) ~ x_group}.",
      "i" = "Explicit targets such as {.code sd(id, dpar = \"mu\", coef = \"(Intercept)\")} are planned for a later phase."
    ))
  }
  if (!is.symbol(args[[1L]])) {
    cli::cli_abort(c(
      "The {.fn {fun}} target must be a simple grouping variable.",
      "x" = "Use syntax like {.code {fun}(id) ~ x_group}."
    ))
  }

  group <- as.character(args[[1L]])
  list(
    group = group,
    fun = fun,
    dpar = paste0(fun, "(", group, ")")
  )
}

collect_structured_effects <- function(rhs, dpar) {
  terms <- flatten_plus_terms(rhs)
  structured <- list()
  for (term in terms) {
    term <- strip_parens(term)
    if (is_structured_marker_call(term, "phylo")) {
      structured[[length(structured) + 1L]] <- parse_structured_marker_call(
        term,
        "phylo",
        dpar
      )
      next
    }
    if (is_structured_marker_call(term, "spatial")) {
      structured[[length(structured) + 1L]] <- parse_structured_marker_call(
        term,
        "spatial",
        dpar
      )
      next
    }
    nested <- c("phylo", "spatial")[vapply(
      c("phylo", "spatial"),
      function(name) formula_contains_call(term, name),
      logical(1)
    )]
    if (length(nested) > 0L) {
      cli::cli_abort(c(
        "Structured-effect markers must be additive formula terms.",
        "x" = "The {.code {dpar}} formula contains nested marker{?s}: {.val {nested}}.",
        "i" = "Use syntax like {.code y ~ x + phylo(1 | species, tree = tree)} or {.code y ~ x + spatial(1 | site, coords = coords)}."
      ))
    }
  }
  structured
}

is_structured_marker_call <- function(expr, name) {
  expr <- strip_parens(expr)
  is.call(expr) && identical(expr[[1L]], as.name(name))
}

parse_structured_marker_call <- function(expr, marker, dpar) {
  args <- as.list(expr)[-1L]
  arg_names <- names(args)
  if (is.null(arg_names)) {
    arg_names <- rep("", length(args))
  }
  arg_names[is.na(arg_names)] <- ""

  term_pos <- which(arg_names %in% c("", "term"))
  if (length(term_pos) != 1L) {
    cli::cli_abort(c(
      "{.fn {marker}} requires exactly one structured random-effect term.",
      "x" = "Use syntax like {.code {marker}(1 | group, tree = tree)} or {.code {marker}(1 | group, coords = coords)}."
    ))
  }

  term <- parse_structured_bar_term(args[[term_pos]], marker)
  marker_args <- args[-term_pos]
  marker_arg_names <- arg_names[-term_pos]
  if (identical(marker, "phylo")) {
    extra <- setdiff(marker_arg_names, "tree")
    if (
      length(marker_args) != 1L ||
        !identical(marker_arg_names, "tree") ||
        length(extra) > 0L
    ) {
      cli::cli_abort(c(
        "{.fn phylo} requires a single named {.arg tree} argument.",
        "x" = "Use syntax like {.code phylo(1 | species, tree = tree)}.",
        "i" = "The public phylogeny API will build a sparse A-inverse from an ultrametric tree with branch lengths."
      ))
    }
    if (!is.symbol(marker_args[[1L]])) {
      cli::cli_abort(c(
        "{.arg tree} must be the name of a phylogeny object.",
        "x" = "Use syntax like {.code phylo(1 | species, tree = tree)}."
      ))
    }
    return(c(
      list(type = "phylo", dpar = dpar),
      term,
      list(tree = as.character(marker_args[[1L]]))
    ))
  }

  bad <- setdiff(marker_arg_names, c("coords", "mesh"))
  has_coords <- any(marker_arg_names == "coords")
  has_mesh <- any(marker_arg_names == "mesh")
  if (length(bad) > 0L || identical(has_coords, has_mesh)) {
    cli::cli_abort(c(
      "{.fn spatial} requires exactly one of {.arg coords} or {.arg mesh}.",
      "x" = "Use syntax like {.code spatial(1 | site, coords = coords)} or {.code spatial(1 | site, mesh = mesh)}."
    ))
  }
  structure_arg <- marker_args[[which(
    marker_arg_names %in% c("coords", "mesh")
  )]]
  if (!is.symbol(structure_arg)) {
    cli::cli_abort(c(
      "{.arg coords} and {.arg mesh} must name objects.",
      "x" = "Use syntax like {.code spatial(1 | site, coords = coords)}."
    ))
  }
  c(
    list(type = "spatial", dpar = dpar),
    term,
    list(
      structure = marker_arg_names[[which(
        marker_arg_names %in% c("coords", "mesh")
      )]],
      object = as.character(structure_arg)
    )
  )
}

parse_structured_bar_term <- function(expr, marker) {
  expr <- strip_parens(expr)
  if (!is_random_bar_call(expr)) {
    cli::cli_abort(c(
      "{.fn {marker}} terms must use random-effect syntax.",
      "x" = "Use syntax like {.code {marker}(1 | group, ...)} or {.code {marker}(1 + x | group, ...)}."
    ))
  }
  lhs <- strip_parens(expr[[2L]])
  group <- expr[[3L]]
  if (!is.symbol(group)) {
    cli::cli_abort(c(
      "{.fn {marker}} grouping terms must be simple variables.",
      "x" = "Use syntax like {.code {marker}(1 | species, ...)}."
    ))
  }

  group_name <- as.character(group)
  if (is_intercept_one(lhs)) {
    return(list(
      group = group_name,
      variables = NA_character_,
      coef_names = "(Intercept)",
      label = paste0(marker, "(1 | ", group_name, ")")
    ))
  }

  pieces <- flatten_plus_terms(lhs)
  one <- vapply(pieces, is_intercept_one, logical(1))
  symbol <- vapply(pieces, is.symbol, logical(1))
  if (
    !any(vapply(pieces, is_zero_term, logical(1))) &&
      sum(one) == 1L &&
      sum(symbol) == 1L &&
      length(pieces) == sum(one) + sum(symbol)
  ) {
    variable <- as.character(pieces[[which(symbol)]])
    return(list(
      group = group_name,
      variables = variable,
      coef_names = c("(Intercept)", variable),
      label = paste0(marker, "(1 + ", variable, " | ", group_name, ")")
    ))
  }

  cli::cli_abort(c(
    "{.fn {marker}} currently reserves only intercept and one-slope structured terms.",
    "x" = "Use {.code {marker}(1 | group, ...)} or {.code {marker}(1 + x | group, ...)}.",
    "i" = "Multiple structured slopes and interactions are planned only after intercept-only structured effects are tested."
  ))
}
