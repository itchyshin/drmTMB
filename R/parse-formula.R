parse_drm_formula_entries <- function(calls, names) {
  entries <- vector("list", length(calls))
  for (i in seq_along(calls)) {
    entries[[i]] <- parse_drm_formula_entry(calls[[i]], names[[i]], i)
  }
  check_unique_plain_dpars(entries)
  class(entries) <- "drm_formula_entries"
  entries
}

# Enforce one formula per plain distributional parameter. Keyed terms that are
# legitimately given more than once are excluded: `corpair()` correlation-pair
# formulas (keyed by group and endpoints) and `sd*()` random-effect scale
# formulas (keyed by group). Everything else -- the plain dpar formulas such as
# `mu`, `sigma`, `nu`, `zi` -- must appear at most once. Without this guard a
# duplicate lets a downstream `entries[[which(dpars == "sigma")]]` do R
# recursive indexing instead of reporting the repeat (see #702).
check_unique_plain_dpars <- function(entries) {
  is_plain <- vapply(
    entries,
    function(entry) {
      is.null(entry$corpair) && !is_random_scale_lhs_entry(entry)
    },
    logical(1)
  )
  dpars <- vapply(entries, `[[`, character(1), "dpar")
  plain_dpars <- dpars[is_plain]
  dup <- unique(plain_dpars[duplicated(plain_dpars)])
  if (length(dup) > 0L) {
    cli::cli_abort(c(
      "Each distributional parameter accepts at most one formula.",
      "x" = "Parameter{?s} {.val {dup}} {?is/are} given more than once."
    ))
  }
  invisible(entries)
}

is_random_scale_lhs_entry <- function(entry) {
  !is.null(entry$lhs) && is_random_scale_lhs(entry$lhs)
}

parse_drm_formula_entry <- function(expr, name, position) {
  if (!is_formula_call(expr)) {
    cli::cli_abort(
      "{.fn drm_formula} inputs must be formulas; input {position} is not a formula."
    )
  }

  lhs <- formula_lhs(expr)
  rhs <- formula_rhs(expr)
  if (formula_contains_call(expr, "meta_known_V")) {
    warn_meta_known_v_deprecated()
  }
  has_name <- nzchar(name)
  has_lhs <- !is.null(lhs)
  corpair_lhs <- NULL

  if (has_name && has_lhs && is_random_scale_lhs(lhs)) {
    cli::cli_abort(
      "Random-effect scale formulas should be unnamed, for example {.code sd(id) ~ x}."
    )
  }
  if (has_name && has_lhs && is_corpair_lhs(lhs)) {
    cli::cli_abort(
      "Correlation-pair formulas should be unnamed, for example {.code corpair(species, level = \"phylogenetic\", block = \"p\", from = \"mu1\", to = \"mu2\") ~ x}."
    )
  }

  if (has_name) {
    dpar <- name
    response <- if (has_lhs) deparse1(lhs) else NA_character_
  } else if (has_lhs && is_random_scale_lhs(lhs)) {
    sd_lhs <- parse_sd_lhs(lhs)
    dpar <- sd_lhs$dpar
    response <- NA_character_
  } else if (has_lhs && is_corpair_lhs(lhs)) {
    corpair_lhs <- parse_corpair_lhs(lhs)
    dpar <- corpair_lhs$dpar
    response <- NA_character_
  } else if (has_lhs && is_nonlocation_dpar_lhs(lhs)) {
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
    corpair = corpair_lhs,
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

# An unnamed formula whose LHS is a bare distributional-parameter symbol is
# treated as a parameterless dpar formula only for non-location parameters
# (for example `sigma ~ x`). Location parameters (`mu`, `mu1`, `mu2`) always
# carry a response, so a bare-symbol location LHS is a response, not a dpar:
# `bf(mu ~ x)` parses as `dpar = "mu"`, `response = "mu"`. This prevents a
# response column literally named `mu`/`mu1`/`mu2` from being silently
# reinterpreted as a parameterless location formula (see #696).
is_nonlocation_dpar_lhs <- function(lhs) {
  lhs_text <- deparse1(lhs)
  lhs_text %in% drm_nonlocation_dpars() || is_random_scale_lhs(lhs)
}

drm_location_dpars <- function() {
  c("mu", "mu1", "mu2")
}

drm_known_dpars <- function() {
  c(
    drm_location_dpars(),
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

drm_nonlocation_dpars <- function() {
  setdiff(drm_known_dpars(), drm_location_dpars())
}

is_random_scale_lhs <- function(lhs) {
  is.call(lhs) &&
    random_scale_lhs_function(lhs) %in% random_scale_lhs_functions()
}

is_sd_lhs <- function(lhs) {
  is_random_scale_lhs(lhs)
}

is_corpair_lhs <- function(lhs) {
  lhs <- strip_parens(lhs)
  is.call(lhs) && identical(drm_call_name(lhs), "corpair")
}

random_scale_lhs_function <- function(lhs) {
  drm_call_name(lhs)
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

parse_corpair_lhs <- function(lhs) {
  lhs <- strip_parens(lhs)
  args <- as.list(lhs)[-1L]
  arg_names <- names(args)
  if (is.null(arg_names)) {
    arg_names <- rep("", length(args))
  }
  arg_names[is.na(arg_names)] <- ""

  target_pos <- which(arg_names %in% c("", "group"))
  if (length(target_pos) != 1L) {
    cli::cli_abort(c(
      "{.fn corpair} requires exactly one grouping variable.",
      "x" = "Use syntax like {.code corpair(species, level = \"phylogenetic\", block = \"p\", from = \"mu1\", to = \"mu2\") ~ x}."
    ))
  }
  group_arg <- args[[target_pos]]
  if (!is.symbol(group_arg)) {
    cli::cli_abort(c(
      "The {.fn corpair} target must be a simple grouping variable.",
      "x" = "Use syntax like {.code corpair(species, level = \"phylogenetic\", block = \"p\", from = \"mu1\", to = \"mu2\") ~ x}."
    ))
  }

  optional_names <- arg_names[-target_pos]
  optional_args <- args[-target_pos]
  bad <- setdiff(optional_names, c("level", "block", "class", "from", "to"))
  if (length(bad) > 0L || any(!nzchar(optional_names))) {
    cli::cli_abort(c(
      "{.fn corpair} currently accepts only {.arg level}, {.arg block}, {.arg class}, {.arg from}, and {.arg to} options.",
      "x" = "Use syntax like {.code corpair(species, level = \"phylogenetic\", block = \"p\", from = \"mu1\", to = \"mu2\") ~ x}."
    ))
  }
  if (any(duplicated(optional_names))) {
    cli::cli_abort(
      "{.fn corpair} options cannot be repeated: {.val {unique(optional_names[duplicated(optional_names)])}}."
    )
  }

  group <- as.character(group_arg)
  level <- parse_corpair_string_arg(optional_args, optional_names, "level")
  block <- parse_corpair_string_arg(optional_args, optional_names, "block")
  class <- parse_corpair_string_arg(optional_args, optional_names, "class")
  from <- parse_corpair_string_arg(optional_args, optional_names, "from")
  to <- parse_corpair_string_arg(optional_args, optional_names, "to")
  allowed_levels <- c("group", "phylogenetic", "spatial")
  if (!is.na(level) && !level %in% allowed_levels) {
    cli::cli_abort(c(
      "{.arg level} must name a latent random-effect correlation level.",
      "x" = "Supported planned levels are {.val {allowed_levels}}."
    ))
  }
  allowed_classes <- c("location-location", "location-scale", "scale-scale")
  if (!is.na(class) && !class %in% allowed_classes) {
    cli::cli_abort(c(
      "{.arg class} must name a latent random-effect correlation class.",
      "x" = "Supported planned classes are {.val {allowed_classes}}."
    ))
  }
  if (xor(is.na(from), is.na(to))) {
    cli::cli_abort(c(
      "{.arg from} and {.arg to} in {.fn corpair} must be supplied together.",
      "x" = "Use syntax like {.code corpair(species, level = \"phylogenetic\", block = \"p\", from = \"mu1\", to = \"mu2\") ~ x}."
    ))
  }
  if (!is.na(class) && !is.na(from)) {
    cli::cli_abort(c(
      "{.fn corpair} accepts either {.arg class} or endpoint-specific {.arg from} / {.arg to}, not both.",
      "x" = "Use endpoint-specific syntax for fitted correlation-regression targets."
    ))
  }
  allowed_endpoints <- c("mu1", "mu2", "sigma1", "sigma2")
  endpoints <- c(from, to)
  bad_endpoints <- endpoints[
    !is.na(endpoints) & !endpoints %in% allowed_endpoints
  ]
  if (length(bad_endpoints) > 0L) {
    cli::cli_abort(c(
      "{.arg from} and {.arg to} must name distributional-parameter endpoints.",
      "x" = "Supported planned endpoints are {.val {allowed_endpoints}}."
    ))
  }
  if (!is.na(from) && identical(from, to)) {
    cli::cli_abort(c(
      "{.arg from} and {.arg to} in {.fn corpair} must name two different endpoints.",
      "x" = "Use syntax like {.code corpair(species, level = \"phylogenetic\", block = \"p\", from = \"mu1\", to = \"mu2\") ~ x}."
    ))
  }

  dpar <- paste0(
    "corpair(",
    group,
    if (!is.na(level)) paste0(", level = \"", level, "\"") else "",
    if (!is.na(block)) paste0(", block = \"", block, "\"") else "",
    if (!is.na(class)) paste0(", class = \"", class, "\"") else "",
    if (!is.na(from)) paste0(", from = \"", from, "\"") else "",
    if (!is.na(to)) paste0(", to = \"", to, "\"") else "",
    ")"
  )
  list(
    group = group,
    level = level,
    block = block,
    class = class,
    from = from,
    to = to,
    dpar = dpar
  )
}

parse_corpair_string_arg <- function(args, arg_names, name) {
  pos <- which(arg_names == name)
  if (length(pos) == 0L) {
    return(NA_character_)
  }
  value <- args[[pos]]
  if (!is.character(value) || length(value) != 1L || is.na(value)) {
    cli::cli_abort(c(
      "{.arg {name}} in {.fn corpair} must be a single string.",
      "x" = "Use syntax like {.code corpair(id, {name} = \"p\") ~ x}."
    ))
  }
  value
}

parse_sd_lhs <- function(lhs) {
  lhs <- strip_parens(lhs)
  fun <- random_scale_lhs_function(lhs)
  if (
    fun %in%
      c(
        "sd_spatial",
        "sd_spatial1",
        "sd_spatial2"
      )
  ) {
    cli::cli_abort(c(
      "{.fn {fun}} random-effect SD models are planned but not implemented yet.",
      "i" = "This implementation currently supports {.code sd(group)} for univariate Gaussian location random effects, {.code sd1(group)} / {.code sd2(group)} for bivariate Gaussian location random effects, {.code sd_phylo(species)} for univariate phylogenetic location random effects, and {.code sd_phylo1(species)} / {.code sd_phylo2(species)} for bivariate phylogenetic location random effects."
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

  target_pos <- which(arg_names %in% c("", "group"))
  if (length(target_pos) != 1L) {
    cli::cli_abort(c(
      "Random-effect scale formulas require exactly one grouping variable.",
      "x" = "Use syntax like {.code sd(id) ~ x_group} or {.code sd1(id) ~ x_group}.",
      "i" = "Explicit targets such as {.code sd(id, dpar = \"mu\", coef = \"(Intercept)\")} are planned for a later phase."
    ))
  }
  if (!is.symbol(args[[target_pos]])) {
    cli::cli_abort(c(
      "The {.fn {fun}} target must be a simple grouping variable.",
      "x" = "Use syntax like {.code {fun}(id) ~ x_group}."
    ))
  }

  optional_names <- arg_names[-target_pos]
  optional_args <- args[-target_pos]
  bad <- setdiff(optional_names, c("dpar", "coef", "block"))
  if (length(bad) > 0L || any(!nzchar(optional_names))) {
    cli::cli_abort(c(
      "{.fn {fun}} currently accepts only {.arg dpar}, {.arg coef}, and {.arg block} options.",
      "x" = "Use syntax like {.code sd(id, dpar = \"mu\", coef = \"(Intercept)\") ~ x_group}."
    ))
  }
  if (any(duplicated(optional_names))) {
    cli::cli_abort(
      "{.fn {fun}} options cannot be repeated: {.val {unique(optional_names[duplicated(optional_names)])}}."
    )
  }

  target_dpar <- parse_sd_string_arg(optional_args, optional_names, "dpar")
  target_coef <- parse_sd_string_arg(optional_args, optional_names, "coef")
  target_block <- parse_sd_string_arg(optional_args, optional_names, "block")
  explicit <- any(!is.na(c(target_dpar, target_coef, target_block)))
  if (explicit && !identical(fun, "sd")) {
    hint <- if (fun %in% c("sd1", "sd2")) {
      "Use {.code sd1(id) ~ x_group} or {.code sd2(id) ~ x_group} for implemented bivariate location random-effect SD models."
    } else if (identical(fun, "sd_phylo")) {
      "Use {.code sd_phylo(species) ~ x_species} for the univariate phylogenetic direct-SD model."
    } else {
      "Use the shorthand form without explicit target options."
    }
    cli::cli_abort(c(
      "{.fn {fun}} does not accept explicit target options yet.",
      "i" = hint
    ))
  }
  if (!is.na(target_dpar) && !identical(target_dpar, "mu")) {
    cli::cli_abort(c(
      "{.arg dpar} in explicit {.fn sd} targets is reserved for location random effects.",
      "x" = "The supported planned value is {.val mu}, not {.val {target_dpar}}.",
      "i" = "Use residual-scale formulas such as {.code sigma ~ ...} for residual variation."
    ))
  }

  group <- as.character(args[[target_pos]])
  list(
    group = group,
    fun = fun,
    dpar = format_sd_lhs_dpar(
      fun,
      group,
      target_dpar,
      target_coef,
      target_block
    ),
    target_dpar = target_dpar,
    target_coef = target_coef,
    target_block = target_block,
    explicit = explicit
  )
}

parse_sd_string_arg <- function(args, arg_names, name) {
  pos <- which(arg_names == name)
  if (length(pos) == 0L) {
    return(NA_character_)
  }
  value <- args[[pos]]
  if (!is.character(value) || length(value) != 1L || is.na(value)) {
    cli::cli_abort(c(
      "{.arg {name}} in {.fn sd} must be a single string.",
      "x" = "Use syntax like {.code sd(id, {name} = \"mu\") ~ x_group}."
    ))
  }
  value
}

format_sd_lhs_dpar <- function(fun, group, dpar, coef, block) {
  paste0(
    fun,
    "(",
    group,
    if (!is.na(dpar)) paste0(", dpar = \"", dpar, "\"") else "",
    if (!is.na(coef)) paste0(", coef = \"", coef, "\"") else "",
    if (!is.na(block)) paste0(", block = \"", block, "\"") else "",
    ")"
  )
}

collect_structured_effects <- function(rhs, dpar) {
  terms <- flatten_plus_terms(rhs)
  structured <- list()
  for (term in terms) {
    term <- strip_parens(term)
    marker <- structured_marker_call_name(term)
    if (!is.null(marker)) {
      structured[[length(structured) + 1L]] <- parse_structured_marker_call(
        term,
        marker,
        dpar
      )
      next
    }
    nested <- structured_marker_names()[vapply(
      structured_marker_names(),
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

structured_marker_names <- function() {
  c("animal", "phylo", "phylo_interaction", "spatial", "relmat")
}

structured_marker_call_name <- function(expr) {
  hits <- structured_marker_names()[vapply(
    structured_marker_names(),
    function(name) is_structured_marker_call(expr, name),
    logical(1)
  )]
  if (length(hits) == 0L) {
    return(NULL)
  }
  hits[[1L]]
}

is_structured_marker_call <- function(expr, name) {
  expr <- strip_parens(expr)
  is.call(expr) && identical(drm_call_name(expr), name)
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

  term <- if (identical(marker, "phylo_interaction")) {
    parse_phylo_interaction_bar_term(args[[term_pos]], marker)
  } else {
    parse_structured_bar_term(args[[term_pos]], marker)
  }
  marker_args <- args[-term_pos]
  marker_arg_names <- arg_names[-term_pos]

  if (identical(marker, "animal")) {
    selected <- marker_arg_names %in% c("pedigree", "A", "Ainv")
    bad <- setdiff(marker_arg_names, c("pedigree", "A", "Ainv"))
    if (length(bad) > 0L || sum(selected) != 1L) {
      cli::cli_abort(c(
        "{.fn animal} requires exactly one of {.arg pedigree}, {.arg A}, or {.arg Ainv}.",
        "x" = "Use syntax like {.code animal(1 | id, pedigree = pedigree)} or {.code animal(1 | id, Ainv = Ainv)}."
      ))
    }
    structure_arg <- marker_args[[which(selected)]]
    if (!is.symbol(structure_arg)) {
      cli::cli_abort(c(
        "{.arg pedigree}, {.arg A}, and {.arg Ainv} must name objects.",
        "x" = "Use syntax like {.code animal(1 | id, pedigree = pedigree)}."
      ))
    }
    return(c(
      list(type = "animal", dpar = dpar),
      term,
      list(
        structure = marker_arg_names[[which(selected)]],
        object = as.character(structure_arg)
      )
    ))
  }

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

  if (identical(marker, "phylo_interaction")) {
    extra <- setdiff(marker_arg_names, c("tree1", "tree2"))
    if (
      length(marker_args) != 2L ||
        length(extra) > 0L ||
        !all(c("tree1", "tree2") %in% marker_arg_names)
    ) {
      cli::cli_abort(c(
        "{.fn phylo_interaction} requires named {.arg tree1} and {.arg tree2} arguments.",
        "x" = "Use syntax like {.code phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree)}.",
        "i" = "Use {.fn relmat} with a user-built {.arg Q} for lower-level pair precision experiments."
      ))
    }
    tree1_arg <- marker_args[[match("tree1", marker_arg_names)]]
    tree2_arg <- marker_args[[match("tree2", marker_arg_names)]]
    if (!is.symbol(tree1_arg) || !is.symbol(tree2_arg)) {
      cli::cli_abort(c(
        "{.arg tree1} and {.arg tree2} must name phylogeny objects.",
        "x" = "Use syntax like {.code phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree)}."
      ))
    }
    return(c(
      list(type = "phylo_interaction", dpar = dpar),
      term,
      list(
        tree1 = as.character(tree1_arg),
        tree2 = as.character(tree2_arg)
      )
    ))
  }

  if (identical(marker, "relmat")) {
    selected <- marker_arg_names %in% c("K", "Q")
    bad <- setdiff(marker_arg_names, c("K", "Q"))
    if (length(bad) > 0L || sum(selected) != 1L) {
      cli::cli_abort(c(
        "{.fn relmat} requires exactly one of {.arg K} or {.arg Q}.",
        "x" = "Use syntax like {.code relmat(1 | id, K = K)} or {.code relmat(1 | id, Q = Q)}."
      ))
    }
    structure_arg <- marker_args[[which(selected)]]
    if (!is.symbol(structure_arg)) {
      cli::cli_abort(c(
        "{.arg K} and {.arg Q} must name objects.",
        "x" = "Use syntax like {.code relmat(1 | id, K = K)}."
      ))
    }
    return(c(
      list(type = "relmat", dpar = dpar),
      term,
      list(
        structure = marker_arg_names[[which(selected)]],
        object = as.character(structure_arg)
      )
    ))
  }

  if (!identical(marker, "spatial")) {
    cli::cli_abort(
      "Internal error: unhandled structured marker {.val {marker}}."
    )
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
  covariance_label <- NULL

  if (is_random_bar_call(lhs)) {
    nested <- strip_parens(lhs)
    lhs <- strip_parens(nested[[2L]])
    covariance_label_expr <- nested[[3L]]
    if (!is.symbol(covariance_label_expr)) {
      cli::cli_abort(c(
        "{.fn {marker}} covariance-block labels must be simple names.",
        "x" = "Use syntax like {.code {marker}(1 | p | group, ...)}."
      ))
    }
    covariance_label <- as.character(covariance_label_expr)
    validate_random_mu_covariance_label(covariance_label)
  }
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
      label = format_structured_label(
        marker,
        "1",
        group_name,
        covariance_label
      ),
      covariance_label = covariance_label
    ))
  }

  pieces <- flatten_plus_terms(lhs)
  zero <- vapply(pieces, is_zero_term, logical(1))
  non_zero <- pieces[!zero]
  if (any(zero) && length(non_zero) == 1L && is.symbol(non_zero[[1L]])) {
    variable <- as.character(non_zero[[1L]])
    return(list(
      group = group_name,
      variables = variable,
      coef_names = variable,
      label = format_structured_label(
        marker,
        paste0("0 + ", variable),
        group_name,
        covariance_label
      ),
      covariance_label = covariance_label
    ))
  }

  one <- vapply(pieces, is_intercept_one, logical(1))
  symbol <- vapply(pieces, is.symbol, logical(1))
  if (
    !any(zero) &&
      sum(one) == 1L &&
      sum(symbol) == 1L &&
      length(pieces) == sum(one) + sum(symbol)
  ) {
    variable <- as.character(pieces[[which(symbol)]])
    return(list(
      group = group_name,
      variables = variable,
      coef_names = c("(Intercept)", variable),
      label = format_structured_label(
        marker,
        paste0("1 + ", variable),
        group_name,
        covariance_label
      ),
      covariance_label = covariance_label
    ))
  }

  cli::cli_abort(c(
    "{.fn {marker}} currently reserves only intercept and one-slope structured terms.",
    "x" = "Use {.code {marker}(1 | group, ...)} or {.code {marker}(1 + x | group, ...)}.",
    "i" = "Multiple structured slopes and interactions are planned only after intercept-only structured effects are tested."
  ))
}

parse_phylo_interaction_bar_term <- function(expr, marker) {
  expr <- strip_parens(expr)
  if (!is_random_bar_call(expr)) {
    cli::cli_abort(c(
      "{.fn {marker}} terms must use random-effect syntax.",
      "x" = "Use syntax like {.code phylo_interaction(1 | partner1:partner2, tree1 = tree1, tree2 = tree2)}."
    ))
  }

  lhs <- strip_parens(expr[[2L]])
  group <- strip_parens(expr[[3L]])
  if (!is_intercept_one(lhs)) {
    cli::cli_abort(c(
      "{.fn {marker}} currently supports only an intercept-only pair effect.",
      "x" = "Use {.code phylo_interaction(1 | partner1:partner2, tree1 = tree1, tree2 = tree2)}.",
      "i" = "Structured pair slopes need separate syntax, simulations, and extractor checks before fitting."
    ))
  }
  if (!is.call(group) || !identical(group[[1L]], as.name(":"))) {
    cli::cli_abort(c(
      "{.fn {marker}} grouping terms must be a pair of simple variables joined by {.code :}.",
      "x" = "Use syntax like {.code phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree)}."
    ))
  }
  partner1 <- strip_parens(group[[2L]])
  partner2 <- strip_parens(group[[3L]])
  if (!is.symbol(partner1) || !is.symbol(partner2)) {
    cli::cli_abort(c(
      "{.fn {marker}} pair members must be simple variables.",
      "x" = "Use syntax like {.code phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree)}."
    ))
  }
  partner1 <- as.character(partner1)
  partner2 <- as.character(partner2)
  if (identical(partner1, partner2)) {
    cli::cli_abort(c(
      "{.fn {marker}} requires two different partner variables.",
      "x" = "The pair term used {.field {partner1}} on both sides of {.code :}."
    ))
  }

  group_name <- paste0(partner1, ":", partner2)
  list(
    group = group_name,
    group1 = partner1,
    group2 = partner2,
    variables = NA_character_,
    coef_names = "(Intercept)",
    label = format_structured_label(
      marker,
      "1",
      group_name,
      covariance_label = NULL
    ),
    covariance_label = NULL
  )
}

format_structured_label <- function(
  marker,
  lhs_label,
  group,
  covariance_label = NULL
) {
  group_label <- if (is.null(covariance_label)) {
    group
  } else {
    paste0(covariance_label, " | ", group)
  }
  paste0(marker, "(", lhs_label, " | ", group_label, ")")
}
