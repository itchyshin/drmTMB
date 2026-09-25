# Pure-R admission census for the R -> Julia bridge (Arc 1 slice S2).
#
# For one formula per (family x structure x RE-carrying dpar) cell, this file
# drives the REAL top-level `drmTMB(..., engine = "julia")` admission path --
# the same pre-Julia gates a user's call would hit -- with every Julia
# path/option cleared, so the call can NEVER boot a live Julia process:
# `drm_julia_setup()` (R/julia-bridge.R) throws its own "needs a local
# DRModels.jl (or legacy DRM.jl) checkout" abort BEFORE it ever calls
# `JuliaCall::julia_setup()`, and recognising that one message is how this
# file tells ADMIT (the call reached the Julia boundary) from REFUSE (an
# earlier gate fired). This is the same trick
# tests/testthat/test-julia-fe-only-fence.R uses (`withr::local_envvar(DRM_JL_PATH
# = NA, DRM_JL_PHYLO_PATH = NA)` then read `conditionMessage()`), generalised
# from one fence to the whole registry x structure grid.
#
# Any abort raised before that boundary is matched against
# `drmTMB:::drm_julia_intentional_gates()`'s own `message_pattern` column
# (the same data `inst/extdata/julia-gates.tsv` is generated from) to name the
# gate. An abort matching no gate's pattern is REFUSE_UNGATED -- a finding in
# its own right (an undocumented refusal), not a tool defect.
#
# The ledger join reuses tools/write-parity-matrix.R's OWN functions,
# sys.source()d into a private environment at run time (D-277: computed in
# process, never a stored list) -- never a second, independent matcher:
#   * the fixed-effect ("none") cell joins through `pm_tsv_rows_for_family()`
#     exactly as the matrix does;
#   * structured/random-effect cells have no single reusable join function in
#     the matrix tool either -- `pm_capability_entries()` hand-names each
#     `tsv_ids =` there -- so this file follows the SAME PRINCIPLE with the
#     SAME building blocks (`pm_family_constructor()`, `pm_syntax_calls()`,
#     plus the TSV's own `route` column and content) rather than a hand
#     list of capability ids. See `census_ledger_row()` below.

# ---- gates and the ADMIT boundary ------------------------------------------

# The exact prefix of `drm_julia_setup()`'s "no DRM.jl path configured" abort
# (R/julia-bridge.R): the one message that means "every pre-Julia gate this
# cell could hit passed, and the call reached the Julia boundary itself."
census_boot_message_pattern <- "needs a local DRModels\\.jl \\(or legacy DRM\\.jl\\) checkout"

census_gates <- function() {
  drmTMB:::drm_julia_intentional_gates()
}

# Classify one caught error against the ADMIT boundary, then the gate table.
# Returns list(decision, gate_id) where gate_id is "" for ADMIT, the matched
# gate_id for REFUSE, or the (single-line, truncated) message itself for
# REFUSE_UNGATED -- there is no separate "message" column in the pinned
# census.tsv header, so an ungated refusal's message lives in `gate_id`,
# always prefixed "UNGATED: " so it can never be mistaken for a real gate id.
census_classify <- function(msg, gates) {
  one_line <- function(x) {
    x <- gsub("[\r\n]+", " | ", x)
    if (nchar(x) > 300L) x <- paste0(substr(x, 1L, 300L), " ...")
    x
  }
  if (grepl(census_boot_message_pattern, msg, perl = TRUE)) {
    return(list(decision = "ADMIT", gate_id = ""))
  }
  for (i in seq_len(nrow(gates))) {
    if (grepl(gates$message_pattern[[i]], msg, perl = TRUE)) {
      return(list(decision = "REFUSE", gate_id = gates$gate_id[[i]]))
    }
  }
  list(decision = "REFUSE_UNGATED", gate_id = paste0("UNGATED: ", one_line(msg)))
}

# ---- the matrix tool's join, reused (not re-derived) -----------------------

census_source_matrix_tool <- function(root = ".") {
  path <- file.path(root, "tools", "write-parity-matrix.R")
  if (!file.exists(path)) {
    return(NULL)
  }
  env <- new.env(parent = globalenv())
  sys.source(path, envir = env)
  env
}

census_read_capabilities_tsv <- function(mt, root = ".") {
  mt$pm_read_tsv(file.path(root, "inst", "extdata", "julia-capabilities.tsv"))
}

# Display names used in the TSV's PROSE (claim_boundary / syntax), for rows
# that name several families in text rather than calling every constructor
# (e.g. general_covariance_structured: "for supported one-response families",
# with "Gaussian, Poisson, NB2, and Gamma" only in claim_boundary). Matched as
# a whole word so "Gamma" cannot match inside "Gammaridae" or similar.
census_family_display <- c(
  gaussian = "Gaussian", poisson = "Poisson", nbinom2 = "NB2", gamma = "Gamma",
  beta = "Beta", binomial = "Binomial", biv_gaussian = "biv_gaussian",
  student = "Student", lognormal = "LogNormal",
  truncated_nbinom2 = "truncated_nbinom2", zero_one_beta = "zero_one_beta",
  tweedie = "Tweedie", beta_binomial = "BetaBinomial",
  cumulative_logit = "cumulative_logit", biv_student = "biv_student",
  skew_normal = "skew_normal", biv_lognormal = "biv_lognormal"
)

# Route a `structure` value to the TSV `route` value(s) a ledger row for that
# shape would carry, mirroring the routes the matrix's own hand-written
# `pm_capability_entries()` cites for each cluster (base for ordinary bars,
# phylo for `phylo()`, structured for relmat/animal/spatial, bivariate_phylo
# for the two- and four-axis bivariate phylo routes).
census_structure_routes <- function(structure) {
  switch(structure,
    "none" = "base",
    "(1|g)" = "base",
    "(1+x|g)" = "base",
    "phylo" = "phylo",
    "relmat" = "structured",
    "spatial" = "structured",
    "animal" = "structured",
    "bivariate q2 phylo" = "bivariate_phylo",
    "bivariate q4 dense phylo" = "bivariate_phylo",
    "bivariate q4 block-diagonal phylo" = "bivariate_phylo",
    stop("unknown structure: ", structure)
  )
}

# Marker regex a ledgered row for this structure must contain, applied to the
# HALF of `syntax` on the target dpar's side (before vs. at-or-after the
# first comma -- crude, but every existing structured/RE row's syntax is one
# short `bf(...)` line and this split places every known row correctly; see
# the file header). NULL means "no marker required beyond the route+family
# match" (used for "none", where `pm_tsv_rows_for_family()` is used directly
# instead of this helper).
census_structure_marker_regex <- function(structure) {
  switch(structure,
    "(1|g)" = "\\(1 \\| [A-Za-z_][A-Za-z0-9_.]*\\)",
    "(1+x|g)" = "\\(1 \\+ x \\| [A-Za-z_][A-Za-z0-9_.]*\\)",
    "phylo" = "phylo\\(1 \\|",
    "relmat" = "relmat\\(1 \\|",
    "spatial" = "spatial\\(1 \\|",
    "animal" = "animal\\(1 \\|",
    "bivariate q2 phylo" = "phylo\\(1 \\|",
    "bivariate q4 dense phylo" = "phylo\\(1 \\|",
    "bivariate q4 block-diagonal phylo" = "phylo\\(1 \\|",
    NULL
  )
}

# TRUE when `dpar` sits on the "mu side" of a `bf(...)` one-liner for the
# purpose of the crude comma split above.
census_dpar_is_mu_side <- function(dpar) {
  dpar %in% c("mu", "mu1", "mu2")
}

# The ledgered capability_id(s) for one admitted cell, or character(0) when
# none join -- an UNLEDGERED ADMIT, the thing S5 exists to fix. `mt` is the
# environment `census_source_matrix_tool()` returned; `tsv` is
# `census_read_capabilities_tsv()`'s result.
census_ledger_row <- function(mt, tsv, family, structure, dpar) {
  if (identical(structure, "none")) {
    if (!census_dpar_is_mu_side(dpar)) {
      return(character(0L))
    }
    hit <- mt$pm_tsv_rows_for_family(tsv, family, modifier = NULL)
    return(tsv$capability_id[hit])
  }
  routes <- census_structure_routes(structure)
  marker <- census_structure_marker_regex(structure)
  constructor <- mt$pm_family_constructor(family)
  in_route <- tsv$route %in% routes
  # Two ways a row can cover this family: it literally CALLS the family's
  # constructor in `syntax` (pm_syntax_calls, the same test the fixed-effect
  # matcher uses), or -- for the multi-family structured/phylo rows that
  # describe several families in PROSE instead ("for supported one-response
  # families") -- its `syntax` + `claim_boundary` text names the family's
  # display word. Either is enough; both are read from the TSV at run time.
  syntax_hit <- mt$pm_syntax_calls(tsv$syntax, constructor)
  disp <- census_family_display[[family]]
  text_hit <- if (is.null(disp)) {
    rep(FALSE, nrow(tsv))
  } else {
    grepl(paste0("\\b", disp, "\\b"), paste(tsv$syntax, tsv$claim_boundary))
  }
  fam_hit <- syntax_hit | text_hit
  marker_hit <- if (is.null(marker)) {
    rep(TRUE, nrow(tsv))
  } else {
    # Crude mu-side/sigma-side split: everything up to (and for the mu side,
    # excluding) the first comma is the mu clause; the rest is everything
    # else. Every existing structured/RE row is one `bf(...)` line, so this
    # places the marker correctly for all of them (see the file header).
    first_comma <- regexpr(",", tsv$syntax, fixed = TRUE)
    mu_clause <- ifelse(first_comma > 0L, substr(tsv$syntax, 1L, first_comma - 1L), tsv$syntax)
    rest_clause <- ifelse(first_comma > 0L, substring(tsv$syntax, first_comma + 1L), "")
    half <- if (census_dpar_is_mu_side(dpar)) mu_clause else rest_clause
    grepl(marker, half, perl = TRUE)
  }
  hit <- in_route & fam_hit & marker_hit
  tsv$capability_id[hit]
}

# ---- family / dpar bookkeeping ---------------------------------------------

census_bivariate_families <- c("biv_gaussian", "biv_student", "biv_lognormal")

census_family_object <- function(family) {
  switch(family,
    gaussian = stats::gaussian(),
    poisson = stats::poisson(link = "log"),
    binomial = stats::binomial(link = "logit"),
    gamma = stats::Gamma(link = "log"),
    beta = drmTMB::beta_family(),
    get(family, envir = asNamespace("drmTMB"), mode = "function")()
  )
}

census_family_dpars <- function(family, fam_obj) {
  if (family %in% c("gaussian", "gamma")) {
    return(c("mu", "sigma"))
  }
  if (family %in% c("poisson", "binomial")) {
    return("mu")
  }
  fam_obj$dpars
}

# The one/two RE-carrying dpar slots this census tests: "mu"/"mu1" always,
# "sigma"/"sigma1" only when the family has that dpar (a dispersionless
# family such as poisson/binomial/cumulative_logit does not).
census_re_dpars <- function(dpars, is_biv) {
  if (is_biv) {
    c("mu1", if ("sigma1" %in% dpars) "sigma1")
  } else {
    c("mu", if ("sigma" %in% dpars) "sigma")
  }
}

census_univariate_structures <- c(
  "none", "(1|g)", "(1+x|g)", "phylo", "relmat", "spatial", "animal"
)
census_bivariate_structures <- c(
  "bivariate q2 phylo", "bivariate q4 dense phylo",
  "bivariate q4 block-diagonal phylo"
)
census_all_structures <- c(census_univariate_structures, census_bivariate_structures)

# A one-off probe outside the family x structure x dpar grid; see
# `census_hurdle_cross_spelling_formula()` and finding 7 (row 62).
census_hurdle_probe_structure <- "hu modifier (finding 7 cross-spelling probe)"

# ---- fixture: one small, shared shape for every cell -----------------------

# n = 40 across 8 groups; ntip = 8 species/sites for phylo/relmat/spatial/
# animal, sharing the SAME 8 levels under different grouping-column names so
# each marker's own syntax (`phylo(1 | sp, ...)`, `relmat(1 | id, ...)`,
# `spatial(1 | site, ...)`, `animal(1 | id, ...)`) finds the column it names.
# Content is never fitted (Julia never boots), so response shapes only need
# to satisfy each family's LHS parsing, not its likelihood -- the same
# discipline tests/testthat/test-julia-fe-only-fence.R already relies on
# (a single generic `rnorm()` response works for families whose native
# content validation the R-side admission gates never reach).
census_fixture <- function(n = 40L, ntip = 8L) {
  set.seed(20260924L)
  grp <- factor(rep(seq_len(ntip), each = n %/% ntip))
  # rcoal(), not rtree(): the phylo() marshaller requires an ultrametric
  # tree, and rtree() draws non-ultrametric branch lengths.
  tree <- ape::rcoal(ntip)
  tree$tip.label <- paste0("t", seq_len(ntip))
  levels(grp) <- tree$tip.label
  x <- stats::rnorm(n)
  data <- data.frame(
    g = grp, id = grp, site = grp, sp = grp,
    x = x,
    y = stats::rnorm(n),
    y1 = stats::rnorm(n),
    y2 = stats::rnorm(n)
  )
  trials <- sample(8:20, n, replace = TRUE)
  successes <- pmin(sample(0:5, n, replace = TRUE), trials)
  data$s <- successes
  data$f <- trials - successes
  data$y_ordinal <- ordered(
    sample(c("low", "medium", "high"), n, replace = TRUE),
    levels = c("low", "medium", "high")
  )
  K <- diag(ntip)
  A <- diag(ntip)
  co <- data.frame(
    cx = stats::rnorm(ntip), cy = stats::rnorm(ntip),
    row.names = tree$tip.label
  )
  list(data = data, tree = tree, K = K, A = A, co = co)
}

# The lhs a family's location dpar(s) use. Every family gets the generic `y`
# (or `y1`/`y2`) EXCEPT the two whose response shape a generic continuous
# draw cannot parse at all: beta_binomial (`cbind(successes, failures)`) and
# cumulative_logit (an ordered factor). Mirrors
# tests/testthat/test-julia-fe-only-fence.R's `fe_only_fence_lhs_overrides`.
census_lhs <- function(family, dpar) {
  if (identical(family, "beta_binomial")) {
    return("cbind(s, f)")
  }
  if (identical(family, "cumulative_logit")) {
    return("y_ordinal")
  }
  if (identical(dpar, "mu1")) {
    return("y1")
  }
  if (identical(dpar, "mu2")) {
    return("y2")
  }
  "y"
}

census_structure_suffix <- function(structure) {
  switch(structure,
    "none" = "",
    "(1|g)" = " + (1 | g)",
    "(1+x|g)" = " + (1 + x | g)",
    "phylo" = " + phylo(1 | sp, tree = tree)",
    "relmat" = " + relmat(1 | id, K = K)",
    "spatial" = " + spatial(1 | site, coords = co)",
    "animal" = " + animal(1 | id, A = A)",
    stop("no plain-dpar suffix for structure: ", structure)
  )
}

# Build the `bf()` argument list for one univariate-structure cell: every
# dpar plain (location dpars carry `x`; everything else is intercept-only)
# except `target_dpar`, which additionally carries `structure`'s marker.
census_formula_args <- function(family, dpars, target_dpar, structure) {
  suffix <- census_structure_suffix(structure)
  args <- vector("list", length(dpars))
  names(args) <- dpars
  for (dpar in dpars) {
    is_loc <- census_dpar_is_mu_side(dpar)
    base_cov <- if (is_loc) "x" else "1"
    rhs <- if (identical(dpar, target_dpar)) paste0(base_cov, suffix) else base_cov
    args[[dpar]] <- if (is_loc) {
      stats::as.formula(sprintf("%s ~ %s", census_lhs(family, dpar), rhs))
    } else {
      stats::as.formula(sprintf("~ %s", rhs))
    }
  }
  args
}

# Build the `bf()` argument list for the three coupled bivariate-phylo
# structures (finding 5's shape): q2 places `phylo(1 | sp, tree = tree)` on
# `mu1`/`mu2` only; the two q4 variants add matching sigma1/sigma2 phylo
# terms, using ONE covariance-block tag (dense, `p` on all four axes) or TWO
# (block-diagonal, `p` on the means and `ps` on the scales) --
# `drm_julia_biv_phylo_dimension()` classifies by the DPAR SET alone and
# ignores the tag, which is exactly finding 5/hypothesis (b).
census_biv_phylo_formula_args <- function(dpars, structure) {
  args <- vector("list", length(dpars))
  names(args) <- dpars
  for (dpar in dpars) {
    rhs <- if (identical(structure, "bivariate q2 phylo")) {
      if (dpar %in% c("mu1", "mu2")) "x + phylo(1 | sp, tree = tree)" else "1"
    } else if (identical(structure, "bivariate q4 dense phylo")) {
      if (dpar %in% c("mu1", "mu2")) {
        "x + phylo(1 | p | sp, tree = tree)"
      } else if (dpar %in% c("sigma1", "sigma2")) {
        "1 + phylo(1 | p | sp, tree = tree)"
      } else "1"
    } else { # block-diagonal
      if (dpar %in% c("mu1", "mu2")) {
        "x + phylo(1 | p | sp, tree = tree)"
      } else if (dpar %in% c("sigma1", "sigma2")) {
        "1 + phylo(1 | ps | sp, tree = tree)"
      } else "1"
    }
    args[[dpar]] <- if (identical(dpar, "mu1")) {
      stats::as.formula(sprintf("y1 ~ %s", rhs))
    } else if (identical(dpar, "mu2")) {
      stats::as.formula(sprintf("y2 ~ %s", rhs))
    } else {
      stats::as.formula(sprintf("~ %s", rhs))
    }
  }
  args
}

census_deparse_args <- function(args) {
  paste(
    vapply(names(args), function(nm) {
      sprintf("%s = %s", nm, paste(deparse(args[[nm]]), collapse = " "))
    }, character(1L)),
    collapse = ", "
  )
}

# ---- one cell ---------------------------------------------------------------

# Run one (family, structure, dpar) admission cell with NO live Julia: every
# Julia path/option is cleared first (the same belt-and-braces
# `test-julia-fe-only-fence.R` uses), `drmTMB(engine = "julia")` is called
# DIRECTLY (no wrapping thunk) so `tree`/`K`/`A`/`co` resolve by ordinary R
# scoping from this function's own frame, and the caught error (there is
# always one -- ADMIT means the boot-message abort, not a returned fit) is
# classified against the gate table.
census_run_cell <- function(family, structure, dpar, gates, fixture) {
  withr::local_envvar(c(
    DRM_JL_PATH = NA, DRM_JL_PHYLO_PATH = NA, DRMODELS_JL_PATH = NA
  ))
  withr::local_options(list(
    drmTMB.DRModels.jl.path = NULL, drmTMB.DRM.jl.path = NULL,
    # cli wraps an abort message at 80 columns by default, which can break a
    # literal-space run (e.g. "DRModels.jl (or legacy DRM.jl) checkout")
    # across a newline; Inf keeps every message on one line so the boot-
    # message check and the gates' own `message_pattern`s match reliably.
    cli.condition_width = Inf
  ))
  # drm_julia_path() (R/julia-bridge.R) has one more fallback the scrub above
  # cannot clear: a sibling `../DRModels.jl` or `../DRM.jl` of getwd(). Run
  # from a maintainer's repository root, that sibling usually exists, and the
  # "no live Julia" promise would silently break (ADMIT cells would boot
  # JuliaCall). So each cell runs from a fresh empty directory, and the tool
  # refuses to continue unless the bridge now resolves no checkout at all.
  cell_dir <- tempfile("admission-census-cwd-")
  dir.create(cell_dir)
  withr::defer(unlink(cell_dir, recursive = TRUE, force = TRUE))
  withr::local_dir(cell_dir)
  resolved <- utils::getFromNamespace("drm_julia_path", "drmTMB")()
  if (nzchar(resolved)) {
    stop(
      "admission census refuses to run: drmTMB would still resolve a Julia ",
      "checkout (", resolved, ") after clearing every path; the census must ",
      "never boot a live Julia process.",
      call. = FALSE
    )
  }
  data <- fixture$data
  tree <- fixture$tree
  K <- fixture$K
  A <- fixture$A
  co <- fixture$co

  if (identical(structure, census_hurdle_probe_structure)) {
    fam_obj <- drmTMB::truncated_nbinom2()
    formula <- census_hurdle_cross_spelling_formula()
    formula_text <- "bf(y ~ x, sigma ~ 1, hu ~ 1)"
  } else {
    fam_obj <- census_family_object(family)
    dpars <- census_family_dpars(family, fam_obj)
    if (structure %in% census_bivariate_structures) {
      args <- census_biv_phylo_formula_args(dpars, structure)
    } else {
      args <- census_formula_args(family, dpars, dpar, structure)
    }
    formula <- do.call(drmTMB::bf, args)
    formula_text <- sprintf("bf(%s)", census_deparse_args(args))
  }

  err <- tryCatch(
    {
      # suppressWarnings(): the registry's own family-object lookup resolves
      # "beta" to the deprecated `beta()` alias rather than `beta_family()`
      # (both drmTMB package-internal, upstream of this census); harmless to
      # admission classification, just noisy on every beta-family cell.
      suppressWarnings(
        drmTMB::drmTMB(formula, family = fam_obj, data = data, engine = "julia")
      )
      NULL
    },
    error = function(e) e
  )
  if (is.null(err)) {
    # No fit can complete with no Julia path configured; a NULL error means
    # something upstream of `drm_julia_setup()` returned instead of
    # aborting, which the boot-message check above cannot classify as
    # ADMIT/REFUSE. Surfacing it as REFUSE_UNGATED keeps the census honest
    # rather than silently mislabelling it.
    cls <- list(decision = "REFUSE_UNGATED", gate_id = "UNGATED: no error raised with no Julia path configured")
  } else {
    cls <- census_classify(conditionMessage(err), gates)
  }
  list(formula_text = formula_text, decision = cls$decision, gate_id = cls$gate_id)
}

# ---- the grid ---------------------------------------------------------------

# One row per (family, structure, dpar) cell, ADMIT/REFUSE/REFUSE_UNGATED/
# NOT_APPLICABLE, in registry order x the task's own structure order. Every
# family in `drm_julia_family_registry()` appears at least once (leaf-S2 G1).
census_grid <- function() {
  reg <- drmTMB:::drm_julia_family_registry()
  rows <- list()
  for (row in reg) {
    family <- row$family
    is_biv <- family %in% census_bivariate_families
    fam_obj <- census_family_object(family)
    dpars <- census_family_dpars(family, fam_obj)
    re_dpars <- census_re_dpars(dpars, is_biv)
    mu_slot <- re_dpars[[1L]]
    sigma_slot <- if (length(re_dpars) >= 2L) re_dpars[[2L]] else NA_character_

    sigma_dpar <- if (is_biv) "sigma1" else "sigma"
    for (structure in census_univariate_structures) {
      for (dpar in c(mu_slot, sigma_dpar)) {
        is_sigma_dpar <- identical(dpar, sigma_dpar)
        na_reason <- if (is_sigma_dpar && is.na(sigma_slot)) {
          "NOT_APPLICABLE: family has no sigma dpar (dispersionless)"
        } else if (is_sigma_dpar && identical(structure, "none")) {
          "NOT_APPLICABLE: 'none' carries no RE term; only the mu-side plain formula is tested"
        } else {
          NA_character_
        }
        rows[[length(rows) + 1L]] <- if (!is.na(na_reason)) {
          data.frame(
            family = family, structure = structure, dpar = dpar,
            formula = na_reason,
            decision = "NOT_APPLICABLE", gate_id = "", ledger_row = "",
            stringsAsFactors = FALSE
          )
        } else {
          data.frame(
            family = family, structure = structure, dpar = dpar,
            formula = NA_character_, decision = NA_character_, gate_id = NA_character_,
            ledger_row = NA_character_, stringsAsFactors = FALSE
          )
        }
      }
    }

    for (structure in census_bivariate_structures) {
      dpar_label <- if (identical(structure, "bivariate q2 phylo")) {
        "mu1,mu2"
      } else {
        "mu1,mu2,sigma1,sigma2"
      }
      if (!is_biv) {
        rows[[length(rows) + 1L]] <- data.frame(
          family = family, structure = structure, dpar = dpar_label,
          formula = "NOT_APPLICABLE: bivariate structure on a univariate-only family",
          decision = "NOT_APPLICABLE", gate_id = "", ledger_row = "",
          stringsAsFactors = FALSE
        )
      } else {
        rows[[length(rows) + 1L]] <- data.frame(
          family = family, structure = structure, dpar = dpar_label,
          formula = NA_character_, decision = NA_character_, gate_id = NA_character_,
          ledger_row = NA_character_, stringsAsFactors = FALSE
        )
      }
    }
  }
  # One targeted extra cell, outside the family x structure x dpar cross
  # product: finding 7 (hurdle NB2 cross-spelling, row 62). Native drmTMB
  # spells a hurdle NB2 model `family = truncated_nbinom2()` plus `hu ~ ...`;
  # the bridge tags this family as "nbinom2" for DRM.jl (R/julia-bridge.R),
  # which has no `hu` case and fails INSIDE Julia with "unknown dpar `hu`" --
  # loud, but late. This census cannot boot Julia to see that failure, but it
  # CAN check the R-admission half of hypothesis (c): does any pre-Julia gate
  # refuse this formula? `structure`/`dpar` are free text here, not part of
  # the regular grid, and this cell's decision is looked up by exact key in
  # tests/testthat/test-julia-admission-census.R.
  rows[[length(rows) + 1L]] <- data.frame(
    family = "truncated_nbinom2",
    structure = census_hurdle_probe_structure,
    dpar = "hu",
    formula = NA_character_, decision = NA_character_, gate_id = NA_character_,
    ledger_row = NA_character_, stringsAsFactors = FALSE
  )

  do.call(rbind, rows)
}

census_hurdle_cross_spelling_formula <- function() {
  drmTMB::bf(y ~ x, sigma ~ 1, hu ~ 1)
}

# ---- the whole census -------------------------------------------------------

# Compute the census in process (D-277): grid + one drmTMB() call per
# to-be-run cell + one ledger join per admitted cell, no live Julia, no
# stored list. `out_path`, if given, is written ROW BY ROW with an immediate
# flush after every cell (never batched at the end), so a stop or crash
# midway leaves partial, honest evidence on disk rather than nothing.
census_run <- function(root = ".", out_path = NULL, progress = NULL) {
  gates <- census_gates()
  mt <- census_source_matrix_tool(root)
  tsv <- if (!is.null(mt)) census_read_capabilities_tsv(mt, root) else NULL
  fixture <- census_fixture()
  grid <- census_grid()

  con <- NULL
  if (!is.null(out_path)) {
    dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)
    con <- file(out_path, open = "wt")
    writeLines(
      paste(c("family", "structure", "dpar", "formula", "decision", "gate_id", "ledger_row"), collapse = "\t"),
      con
    )
    flush(con)
  }
  log_con <- NULL
  if (!is.null(progress)) {
    dir.create(dirname(progress), recursive = TRUE, showWarnings = FALSE)
    log_con <- file(progress, open = "wt")
  }

  out_rows <- vector("list", nrow(grid))
  for (i in seq_len(nrow(grid))) {
    g <- grid[i, ]
    if (identical(g$decision, "NOT_APPLICABLE")) {
      row <- g
    } else {
      res <- census_run_cell(g$family, g$structure, g$dpar, gates, fixture)
      ledger <- if (!identical(res$decision, "ADMIT") || is.null(tsv)) {
        ""
      } else if (identical(g$structure, census_hurdle_probe_structure)) {
        # The finding-7 probe's ledger row is the one already keyed by
        # capability_id "hurdle_nbinom2" (pm_modifier_routes() names it the
        # bridge_family = "nbinom2" + modifier = "hu" route) -- looked up
        # directly by that id rather than through the general family/route
        # matcher, which is built for the regular grid's plain dpar/structure
        # shapes, not this one-off modifier probe.
        if ("hurdle_nbinom2" %in% tsv$capability_id) "hurdle_nbinom2" else ""
      } else {
        paste(census_ledger_row(mt, tsv, g$family, g$structure, g$dpar), collapse = ";")
      }
      row <- data.frame(
        family = g$family, structure = g$structure, dpar = g$dpar,
        formula = res$formula_text, decision = res$decision,
        gate_id = res$gate_id, ledger_row = ledger,
        stringsAsFactors = FALSE
      )
    }
    out_rows[[i]] <- row
    if (!is.null(con)) {
      writeLines(
        paste(
          gsub("[\t\r\n]", " ", c(row$family, row$structure, row$dpar, row$formula, row$decision, row$gate_id, row$ledger_row)),
          collapse = "\t"
        ),
        con
      )
      flush(con)
    }
    if (!is.null(log_con)) {
      writeLines(sprintf("[%d/%d] %s x %s x %s -> %s", i, nrow(grid), row$family, row$structure, row$dpar, row$decision), log_con)
      flush(log_con)
    }
  }
  if (!is.null(con)) close(con)
  if (!is.null(log_con)) close(log_con)
  do.call(rbind, out_rows)
}

# ---- script entry point -----------------------------------------------------

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  out <- if (length(args) >= 1L) args[[1L]] else file.path(
    "docs", "dev-log", "evidence", "julia-r-parity", "arc1-admission-census", "census.tsv"
  )
  log <- file.path(dirname(out), "census.log")
  tab <- census_run(root = ".", out_path = out, progress = log)
  message(
    "wrote ", nrow(tab), " admission-census rows to ", out, " (",
    sum(tab$decision == "ADMIT"), " ADMIT, ",
    sum(tab$decision == "REFUSE"), " REFUSE, ",
    sum(tab$decision == "REFUSE_UNGATED"), " REFUSE_UNGATED, ",
    sum(tab$decision == "NOT_APPLICABLE"), " NOT_APPLICABLE)"
  )
  invisible(tab)
}

if (sys.nframe() == 0L) {
  main()
}
