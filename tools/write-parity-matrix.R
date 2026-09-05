#!/usr/bin/env Rscript
# THE MATRIX as a generated artefact (parity-joint A2, 2026-09-05).
#
# Joins five committed inputs into ONE table, docs/design/parity-matrix.md,
# with one row per drmTMB-native capability and every cell citing a file:line
# or a receipt id:
#
#   1. docs/design/capability-status.md            (drmTMB, native_R axis)
#   2. DRM.jl docs/design/capability-status.md     (native_Julia axis, read at
#      the pin COMMIT of the clone named by DRM_JL_PATH -- `git show`, never the
#      working tree, so the output is a function of committed inputs only)
#   3. inst/extdata/julia-capabilities.tsv         (the bridge ledger)
#   4. inst/extdata/julia-gates.tsv                (the intentional-refusal gates)
#   5. R/julia-family-registry.R                   (which families the bridge admits)
#
# WHY: the DRM.jl parity ledger says CLOSURE: PASS and drmTMB's bridge TSV has
# most rows below `covered`. Both are true and measure different things; the
# matrix is what makes "parity" one measurable claim.
#
# RULES THIS FILE ENFORCES (a violation aborts generation, it does not warn):
#   - exactly one row per capability named in drmTMB's capability-status.md,
#     and every one of those names exists byte-for-byte in DRM.jl's file;
#   - every cell is non-empty;
#   - a row that is not GREEN (native_R implemented AND native_Julia
#     implemented AND bridge claim_status covered, with no written override)
#     carries a boundary or a next action, and that text carries a citation
#     (a file:line, a receipt id, a gate id, or a docs/ or tests/ path);
#   - every citation anchor is found at generation time (`pm_grep_line()`
#     errors on a missing anchor), so a line number in the output can never be
#     stale relative to the commit that generated it;
#   - no timestamp and no drmTMB commit hash in the output: running the tool
#     twice on the same inputs yields byte-identical output.
#
# FAMILY ROUTES ARE JOINED, NOT NAMED. A TSV row evidences a family's
# fixed-effect route when its `route` is "base", its `syntax` column CALLS
# that family's constructor -- `poisson(` preceded by a non-identifier
# character -- and (for the plain, no-modifier route) its formula carries no
# `|` random-effect term: `gaussian_random_intercept_mu`'s syntax also has
# `route == "base"` and calls `gaussian(`, but it fits `y ~ x + (1 | g)`, a
# random-effect route with its OWN row below (`Gaussian random intercept
# (mean)`), not the plain fixed-effect one. Without the `|` guard the
# fixed-effect row silently absorbed all three ordinary-RE TSV rows and the
# RE rows read back "NO TSV row" despite A5 having ledgered exactly that.
# The join is on `syntax`, never on `capability_id`, because the row
# `phylo_gamma_beta_binomial` contains the substring `beta_binomial` while
# evidencing Gamma/Beta/Binomial phylo cells: a string-match reader reports
# beta_binomial as covered when the bridge refuses it.
# tests/testthat/test-parity-matrix.R carries that trap as a positive control
# and a twin of this matcher (the test must run from the installed package,
# where tools/ does not exist); a drift test asserts the twins agree.
#
# USAGE (from the drmTMB source checkout; no Julia is started):
#   DRM_JL_PATH=/path/to/DRM.jl-clone Rscript tools/write-parity-matrix.R
# Optional second form: Rscript tools/write-parity-matrix.R <drmjl-path> [<out>]

# ---- small helpers ---------------------------------------------------------

pm_read_lines <- function(path) {
  if (!file.exists(path)) {
    stop("input not found: ", path, call. = FALSE)
  }
  readLines(path, warn = FALSE, encoding = "UTF-8")
}

pm_git <- function(repo, ...) {
  out <- suppressWarnings(system2(
    "git", c("-C", shQuote(repo), ...), stdout = TRUE, stderr = FALSE
  ))
  status <- attr(out, "status")
  if (!is.null(status) && status != 0L) {
    stop("git ", paste(c(...), collapse = " "), " failed in ", repo, call. = FALSE)
  }
  as.character(out)
}

# Read a file as committed at `ref` (the pin), never the working tree.
pm_git_show <- function(repo, ref, path) {
  pm_git(repo, "show", shQuote(paste0(ref, ":", path)))
}

# The line number of the `which`-th line at or after `from` matching
# `pattern` (fixed string). A missing anchor is a generation error:
# citations must never rot silently.
pm_grep_line <- function(lines, pattern, file, which = 1L, from = 1L) {
  hits <- grep(pattern, lines, fixed = TRUE)
  hits <- hits[hits >= from]
  if (length(hits) < which) {
    stop(sprintf("citation anchor not found in %s: %s", file, pattern), call. = FALSE)
  }
  hits[[which]]
}

pm_cite <- function(file, line) sprintf("%s:%d", file, as.integer(line))

# Parse every `| Capability | Status |` row of a capability-status.md file.
# Rows are recognised by the status vocabulary, which keeps the row-count join
# table (`| rows in this file | 43 |`) out of the result.
pm_status_vocabulary <- function() {
  c("implemented", "scope-limited", "point-fit-recovery", "rejected",
    "planned", "missing", "experimental")
}

pm_parse_status_table <- function(lines) {
  is_row <- grepl("^\\|.*\\|.*\\|\\s*$", lines)
  out <- list()
  for (i in which(is_row)) {
    cells <- strsplit(sub("\\|\\s*$", "", sub("^\\s*\\|", "", lines[[i]])), "|", fixed = TRUE)[[1L]]
    cells <- trimws(cells)
    if (length(cells) != 2L) next
    if (!cells[[2L]] %in% pm_status_vocabulary()) next
    out[[length(out) + 1L]] <- data.frame(
      capability = cells[[1L]], status = cells[[2L]], line = i,
      stringsAsFactors = FALSE
    )
  }
  tab <- do.call(rbind, out)
  dup <- tab$capability[duplicated(tab$capability)]
  if (length(dup)) {
    stop("duplicate capability names in a status table: ", paste(dup, collapse = ", "), call. = FALSE)
  }
  tab
}

# `path` is a file path or a connection; `line` is the 1-based file line of
# each row (the header is line 1).
pm_read_tsv <- function(path) {
  tab <- utils::read.delim(
    path, stringsAsFactors = FALSE, check.names = FALSE, quote = "",
    encoding = "UTF-8"
  )
  tab[] <- lapply(tab, as.character)
  tab$line <- seq_len(nrow(tab)) + 1L
  tab
}

# ---- the family-route matcher (twin of the one in test-parity-matrix.R) ----
# Any change here must be mirrored there; the drift test fails otherwise.

pm_family_constructor <- function(family) {
  # drmTMB spells the Gamma family with stats::Gamma(); every other admitted
  # family's constructor shares the family_type string.
  if (identical(family, "gamma")) "Gamma" else family
}

pm_modifier_dpars <- function() c("zi", "hu", "zoi", "coi")

# TRUE when `syntax` CALLS the constructor: `poisson(` preceded by start of
# string or a non-identifier character. `beta(` does not match `beta_binomial(`
# (the character after `beta` is `_`, not `(`), and `binomial(` inside
# `beta_binomial(` is preceded by `_`, an identifier character, so it does not
# match either.
pm_syntax_calls <- function(syntax, constructor) {
  grepl(paste0("(^|[^A-Za-z0-9_.])", constructor, "\\("), syntax, perl = TRUE)
}

# TRUE when `syntax` carries a formula for the modifier dpar: `zi ~ 1` or
# `zi = ~1` (both spellings drmTMB's bf() accepts).
pm_syntax_has_modifier <- function(syntax, dpar) {
  grepl(paste0("(^|[^A-Za-z0-9_.])", dpar, "\\s*(=\\s*)?~"), syntax, perl = TRUE)
}

# TSV rows (as a logical index) evidencing family `family` on the
# fixed-effect route, optionally with modifier dpar `modifier`. A plain
# family route is evidenced only by a row WITHOUT any modifier formula (a ZIP
# row evidences ZIP, not Poisson).
pm_tsv_rows_for_family <- function(tsv, family, modifier = NULL) {
  hit <- tsv$route == "base" & pm_syntax_calls(tsv$syntax, pm_family_constructor(family))
  any_mod <- Reduce(`|`, lapply(pm_modifier_dpars(), function(d) pm_syntax_has_modifier(tsv$syntax, d)))
  has_re_term <- grepl("|", tsv$syntax, fixed = TRUE)
  if (is.null(modifier)) {
    hit & !any_mod & !has_re_term
  } else {
    hit & pm_syntax_has_modifier(tsv$syntax, modifier)
  }
}

# Native model types that are a base family PLUS a modifier dpar formula
# (R/drmTMB.R's family message: "Zero-inflated Poisson and NB2 models use the
# same family route plus a `zi ~ ...` formula; hurdle NB2 models use
# truncated_nbinom2 plus a `hu ~ ...` formula"). `bridge_family` is the
# family the BRIDGE spells the route with: hurdle NB2 reaches DRM.jl as
# nbinom2() + `hu ~` because drm_julia_family_tag() admits nbinom2 and refuses
# truncated_nbinom2, while native drmTMB refuses nbinom2() + `hu` -- the
# cross-spelling A3 measured (docs/dev-log/after-task/2026-09-05-a3-unledgered-routes.md).
# A route is admitted through the bridge when its bridge_family is a registry
# `fe` family and its modifier is in julia_bridge_supported_dpars().
pm_modifier_routes <- function() {
  data.frame(
    model_type = c("zi_poisson", "zi_nbinom2", "hurdle_nbinom2"),
    native_family = c("poisson", "nbinom2", "truncated_nbinom2"),
    bridge_family = c("poisson", "nbinom2", "nbinom2"),
    modifier = c("zi", "zi", "hu"),
    stringsAsFactors = FALSE
  )
}

pm_route_id <- function(family, modifier = NULL) {
  if (is.null(modifier) || is.na(modifier)) family else paste0(family, "+", modifier)
}

# Every route the bridge admits today: the registry's fixed-effect families
# plus the modifier routes whose bridge family is admitted and whose modifier
# the bridge marshals. Returns a data.frame(route, family, modifier).
pm_admitted_routes <- function(registry, supported_dpars) {
  fe <- vapply(registry[vapply(registry, function(s) isTRUE(s$fe), logical(1L))], `[[`, character(1L), "family")
  routes <- data.frame(route = fe, family = fe, modifier = NA_character_, stringsAsFactors = FALSE)
  mods <- pm_modifier_routes()
  keep <- mods$bridge_family %in% fe & mods$modifier %in% supported_dpars
  if (any(keep)) {
    m <- mods[keep, , drop = FALSE]
    routes <- rbind(routes, data.frame(
      route = mapply(pm_route_id, m$bridge_family, m$modifier, USE.NAMES = FALSE),
      family = m$bridge_family, modifier = m$modifier, stringsAsFactors = FALSE
    ))
  }
  rownames(routes) <- NULL
  routes
}

pm_routes_without_row <- function(routes, tsv) {
  covered <- vapply(seq_len(nrow(routes)), function(i) {
    mod <- if (is.na(routes$modifier[[i]])) NULL else routes$modifier[[i]]
    any(pm_tsv_rows_for_family(tsv, routes$family[[i]], mod))
  }, logical(1L))
  routes$route[!covered]
}

# ---- context: every input, parsed once ------------------------------------

pm_load_context <- function(root, drmjl_path) {
  if (!isNamespaceLoaded("drmTMB")) {
    if (!requireNamespace("pkgload", quietly = TRUE)) {
      stop("pkgload is required to read the family registry from the development package.", call. = FALSE)
    }
    pkgload::load_all(root, quiet = TRUE)
  }
  ns <- asNamespace("drmTMB")

  pin <- pm_git(drmjl_path, "rev-parse", "HEAD")
  pin_short <- substr(pin, 1L, 8L)
  drmjl_label <- function(path) sprintf("DRM.jl@%s:%s", pin_short, path)

  files <- list(
    r_status = "docs/design/capability-status.md",
    tsv = "inst/extdata/julia-capabilities.tsv",
    gates = "inst/extdata/julia-gates.tsv",
    registry = "R/julia-family-registry.R",
    bridge = "R/julia-bridge.R",
    drmtmb = "R/drmTMB.R",
    plan = "docs/dev-log/loop/parity-joint-20260905/ultra-plan.md",
    j_status = "docs/design/capability-status.md",
    j_bridge = "src/bridge.jl",
    j_se = "docs/dev-log/evidence/parity-se.tsv",
    j_fixtures = "docs/dev-log/evidence/parity-fixtures.tsv",
    j_intervals = "docs/dev-log/evidence/parity-intervals.tsv",
    j_classc = "docs/dev-log/evidence/parity-classc.tsv",
    j_phylo_ng = "docs/dev-log/evidence/parity-phylo-nongaussian.tsv"
  )

  r_status_lines <- pm_read_lines(file.path(root, files$r_status))
  j_status_lines <- pm_git_show(drmjl_path, pin, files$j_status)

  ctx <- list(
    root = root, drmjl_path = drmjl_path, pin = pin, pin_short = pin_short,
    files = files, drmjl_label = drmjl_label,
    r_status = pm_parse_status_table(r_status_lines),
    j_status = pm_parse_status_table(j_status_lines),
    r_status_lines = r_status_lines,
    j_status_lines = j_status_lines,
    tsv = pm_read_tsv(file.path(root, files$tsv)),
    gates = pm_read_tsv(file.path(root, files$gates)),
    registry = ns$drm_julia_family_registry(),
    supported_dpars = ns$julia_bridge_supported_dpars(),
    registry_lines = pm_read_lines(file.path(root, files$registry)),
    bridge_lines = pm_read_lines(file.path(root, files$bridge)),
    drmtmb_lines = pm_read_lines(file.path(root, files$drmtmb)),
    plan_lines = pm_read_lines(file.path(root, files$plan)),
    j_bridge_lines = pm_git_show(drmjl_path, pin, files$j_bridge)
  )
  ctx$j_receipts <- lapply(
    c(se = "j_se", fixtures = "j_fixtures", intervals = "j_intervals",
      classc = "j_classc", phylo_ng = "j_phylo_ng"),
    function(key) pm_read_tsv(textConnection(pm_git_show(drmjl_path, pin, files[[key]])))
  )
  ctx
}

# ---- citation helpers bound to a context ----------------------------------

pm_cite_r <- function(ctx, file_key, pattern, which = 1L) {
  lines <- switch(file_key,
    registry = ctx$registry_lines, bridge = ctx$bridge_lines,
    drmtmb = ctx$drmtmb_lines, r_status = ctx$r_status_lines,
    plan = ctx$plan_lines,
    stop("unknown file key ", file_key)
  )
  pm_cite(ctx$files[[file_key]], pm_grep_line(lines, pattern, ctx$files[[file_key]], which = which))
}

pm_cite_j <- function(ctx, pattern, which = 1L) {
  pm_cite(ctx$drmjl_label(ctx$files$j_bridge),
          pm_grep_line(ctx$j_bridge_lines, pattern, ctx$files$j_bridge, which = which))
}

pm_cite_jstatus <- function(ctx, pattern) {
  pm_cite(ctx$drmjl_label(ctx$files$j_status),
          pm_grep_line(ctx$j_status_lines, pattern, ctx$files$j_status))
}

pm_cite_tsv_rows <- function(ctx, idx) {
  paste(pm_cite(ctx$files$tsv, ctx$tsv$line[idx]), collapse = ", ")
}

pm_cite_tsv <- function(ctx, ids) {
  idx <- match(ids, ctx$tsv$capability_id)
  if (anyNA(idx)) stop("TSV capability_id not found: ", paste(ids[is.na(idx)], collapse = ", "), call. = FALSE)
  paste(sprintf("`%s` (%s)", ids, pm_cite(ctx$files$tsv, ctx$tsv$line[idx])), collapse = "; ")
}

pm_cite_gates <- function(ctx, ids) {
  idx <- match(ids, ctx$gates$gate_id)
  if (anyNA(idx)) stop("gate_id not found: ", paste(ids[is.na(idx)], collapse = ", "), call. = FALSE)
  paste(sprintf("gate `%s` (%s)", ids, pm_cite(ctx$files$gates, ctx$gates$line[idx])), collapse = "; ")
}

# A receipt id must exist in the named DRM.jl evidence table at the pin.
# `where` narrows to one row when an id spans several (parity-intervals.tsv
# has one row per method for each cell_id).
pm_receipt <- function(ctx, table, id_col, id, where = list()) {
  tab <- ctx$j_receipts[[table]]
  file <- ctx$files[[paste0("j_", table)]]
  keep <- tab[[id_col]] == id
  for (col in names(where)) keep <- keep & tab[[col]] == where[[col]]
  if (sum(keep) != 1L) {
    stop(sprintf("receipt %s=%s%s matches %d rows in %s at the pin (need exactly 1)", id_col, id,
                 if (length(where)) paste0(" [", paste(names(where), where, sep = "=", collapse = ","), "]") else "",
                 sum(keep), file), call. = FALSE)
  }
  qual <- if (length(where)) paste0(" ", paste(names(where), where, sep = "=", collapse = " ")) else ""
  sprintf("receipt %s=%s%s (%s, %s)", id_col, id, qual, tab$status[keep],
          pm_cite(ctx$drmjl_label(file), tab$line[keep]))
}

pm_registry_row <- function(ctx, family) {
  for (s in ctx$registry) if (identical(s$family, family)) return(s)
  NULL
}

pm_status_cell <- function(tab, name, file_label) {
  i <- match(name, tab$capability)
  if (is.na(i)) stop("capability not found in ", file_label, ": ", name, call. = FALSE)
  sprintf("%s (%s)", tab$status[[i]], pm_cite(file_label, tab$line[[i]]))
}

# DRM.jl's `_bridge_family` case for a tag, searched ONLY inside that function
# (from its `function` line to its `unsupported family` throw).
pm_drmjl_tag_cite <- function(ctx, tag) {
  from <- pm_grep_line(ctx$j_bridge_lines, "function _bridge_family(", ctx$files$j_bridge)
  to <- pm_grep_line(ctx$j_bridge_lines, "unsupported family", ctx$files$j_bridge, from = from)
  hits <- grep(sprintf("\"%s\"", tag), ctx$j_bridge_lines[from:to], fixed = TRUE)
  if (length(hits)) {
    sprintf("DRM.jl `_bridge_family` accepts `%s` (%s)", tag,
            pm_cite(ctx$drmjl_label(ctx$files$j_bridge), from + hits[[1L]] - 1L))
  } else {
    sprintf("DRM.jl `_bridge_family` has NO case for `%s` at the pin (throws at %s)", tag,
            pm_cite(ctx$drmjl_label(ctx$files$j_bridge), to))
  }
}

pm_plan_leaf <- function(ctx, leaf) {
  sprintf("leaf %s (%s)", leaf, pm_cite_r(ctx, "plan", sprintf("| **%s** |", leaf)))
}

# ---- the rows --------------------------------------------------------------

# A family row on the fixed-effect route (optionally with a modifier dpar).
#   boundary      always-true scope text, placed before the TSV pointer
#   refused_note  used ONLY while the bridge refuses the family; dropped the
#                 moment a registry row admits it (so admission cannot leave
#                 stale "only the bridge refuses" prose behind)
#   green_override a written reason the row must not be GREEN even when the
#                 mechanical rule says so
pm_family_entry <- function(ctx, name, family, modifier = NULL, boundary = "",
                            refused_note = "", next_action = "", green_override = "") {
  reg <- pm_registry_row(ctx, family)
  tag <- if (!is.null(reg)) reg$drmjl_tag else family
  j_tag <- pm_drmjl_tag_cite(ctx, tag)
  dpars_cite <- pm_cite_r(ctx, "bridge", "julia_bridge_supported_dpars <- function(")
  mod_cite <- if (!is.null(modifier)) {
    if (!modifier %in% ctx$supported_dpars) stop("modifier not marshalled by the bridge: ", modifier, call. = FALSE)
    sprintf("; modifier `%s` is in julia_bridge_supported_dpars() (%s) and DRM.jl's bridge vocabulary (%s)", modifier,
            dpars_cite, pm_cite_j(ctx, "k in (:mu, :sigma, :nu, :zi, :hu, :zoi, :coi)"))
  } else ""
  hit <- pm_tsv_rows_for_family(ctx$tsv, family, modifier)
  route_id <- pm_route_id(family, modifier)
  fam_tag_cite <- pm_cite_r(ctx, "bridge", "drm_julia_family_tag <- function(")

  if (!is.null(reg) && isTRUE(reg$fe)) {
    fe_cite <- pm_cite_r(ctx, "registry", sprintf("spec(\"%s\"", family))
    admitted <- sprintf("admitted at drm_julia_family_tag() (%s) by the registry `fe` row (%s); %s%s",
                        fam_tag_cite, fe_cite, j_tag, mod_cite)
    if (any(hit)) {
      ids <- ctx$tsv$capability_id[hit]
      bridge_route <- sprintf("%s; TSV %s", admitted, pm_cite_tsv(ctx, ids))
      r_bridge_status <- paste(sprintf("%s (%s)", ctx$tsv$r_bridge_status[hit], pm_cite(ctx$files$tsv, ctx$tsv$line[hit])), collapse = "; ")
      claim_status <- paste(sprintf("%s (%s)", ctx$tsv$claim_status[hit], pm_cite(ctx$files$tsv, ctx$tsv$line[hit])), collapse = "; ")
      boundary <- trimws(paste(boundary, sprintf("see claim_boundary at %s.", pm_cite_tsv_rows(ctx, which(hit)))))
    } else {
      bridge_route <- sprintf("%s; NO TSV ROW", admitted)
      r_bridge_status <- "unledgered (no TSV row)"
      claim_status <- "unledgered (no TSV row)"
      boundary <- trimws(paste(
        sprintf("ADMITTED WITHOUT A LEDGER ROW: route `%s` fits through engine = \"julia\" and neither ledger records it (tests/testthat/test-parity-matrix.R fails on it by design).", route_id),
        boundary
      ))
      if (!nzchar(next_action)) next_action <- sprintf("ledger the route with receipts (%s)", pm_plan_leaf(ctx, "A3"))
    }
  } else {
    no_row_cite <- pm_cite_r(ctx, "registry", "NOT admitted today")
    bridge_route <- sprintf("REFUSED at drm_julia_family_tag() (%s): no registry `fe` row (%s); %s%s",
                            fam_tag_cite, no_row_cite, j_tag, mod_cite)
    r_bridge_status <- sprintf("refused (%s)", fam_tag_cite)
    claim_status <- "none (refused)"
    boundary <- trimws(paste(
      sprintf("only the bridge refuses this family (%s).", fam_tag_cite), refused_note, boundary
    ))
    if (!nzchar(next_action)) {
      next_action <- if (grepl("NO case", j_tag, fixed = TRUE)) {
        sprintf("admit the family on BOTH sides: a DRM.jl `_bridge_family` case plus one registry row and receipts (%s)", pm_plan_leaf(ctx, "A4.1\u2013A4.9"))
      } else {
        sprintf("admit the family: one registry row plus receipts (%s)", pm_plan_leaf(ctx, "A4.1\u2013A4.9"))
      }
    }
  }
  list(name = name, bridge_route = bridge_route, r_bridge_status = r_bridge_status,
       claim_status = claim_status, boundary = boundary, next_action = next_action,
       green_override = green_override)
}

# A structural row: named TSV rows and/or gates, plus a route note.
pm_struct_entry <- function(ctx, name, tsv_ids = character(), gate_ids = character(),
                            route_note = "", boundary = "", next_action = "", green_override = "") {
  parts <- character()
  if (length(tsv_ids)) parts <- c(parts, paste("TSV", pm_cite_tsv(ctx, tsv_ids)))
  if (length(gate_ids)) parts <- c(parts, pm_cite_gates(ctx, gate_ids))
  if (nzchar(route_note)) parts <- c(parts, route_note)
  bridge_route <- paste(parts, collapse = "; ")
  if (length(tsv_ids)) {
    idx <- match(tsv_ids, ctx$tsv$capability_id)
    r_bridge_status <- paste(sprintf("%s (%s)", ctx$tsv$r_bridge_status[idx], pm_cite(ctx$files$tsv, ctx$tsv$line[idx])), collapse = "; ")
    claim_status <- paste(sprintf("%s (%s)", ctx$tsv$claim_status[idx], pm_cite(ctx$files$tsv, ctx$tsv$line[idx])), collapse = "; ")
    boundary <- trimws(paste(boundary, sprintf("see claim_boundary at %s.", pm_cite_tsv_rows(ctx, idx))))
  } else if (length(gate_ids)) {
    idx <- match(gate_ids, ctx$gates$gate_id)
    r_bridge_status <- paste(sprintf("%s (%s)", ctx$gates$r_bridge_status[idx], pm_cite(ctx$files$gates, ctx$gates$line[idx])), collapse = "; ")
    claim_status <- "none (gated refusal)"
  } else {
    r_bridge_status <- "unledgered (no TSV row)"
    claim_status <- "unledgered (no TSV row)"
  }
  list(name = name, bridge_route = bridge_route, r_bridge_status = r_bridge_status,
       claim_status = claim_status, boundary = boundary, next_action = next_action,
       green_override = green_override)
}

pm_capability_entries <- function(ctx) {
  r <- function(...) pm_cite_r(ctx, ...)
  rs <- function(pattern) pm_cite_r(ctx, "r_status", pattern)
  js <- function(name) {
    i <- match(name, ctx$j_status$capability)
    pm_cite(ctx$drmjl_label(ctx$files$j_status), ctx$j_status$line[[i]])
  }
  jsl <- function(pattern) pm_cite_jstatus(ctx, pattern)
  rec <- function(...) pm_receipt(ctx, ...)
  fam <- function(...) pm_family_entry(ctx, ...)
  st <- function(...) pm_struct_entry(ctx, ...)
  tsv_line <- function(id) pm_cite(ctx$files$tsv, ctx$tsv$line[match(id, ctx$tsv$capability_id)])

  sigma_ranef_limits <- r("bridge", "drm_julia_check_ordinary_sigma_ranef_route_limits <- function(")
  refuse_reml <- r("bridge", "drm_julia_refuse_reml_unsupported <- function(")
  ri_spec <- r("bridge", "drm_julia_conditional_gaussian_ri_spec <- function(")
  structured_types <- r("bridge", "drm_julia_structured_marker_types <- function(")
  xfam_bridge <- r("bridge", "drmTMB_julia_xfam_bridge <- function(")
  locscale_phylo <- r("bridge", "drm_julia_locscale_phylo_families <- function(")
  slope_phylo <- r("bridge", "drm_julia_slope_phylo_families <- function(")
  wald_confint <- r("bridge", "drm_julia_wald_confint <- function(")
  interval_targets <- r("bridge", "Julia-engine profile and bootstrap intervals currently support one fixed-effect coefficient")
  binomial_logit <- r("bridge", "drm_julia_bridge_family_type <- function(")
  hurdle_msg <- r("drmtmb", "hurdle NB2 models use {.fn truncated_nbinom2} plus a {.code hu ~ ...} formula")
  nb2_hu_refusal <- r("drmtmb", "{.fn nbinom2} models only support {.code mu}, {.code sigma}, and optional {.code zi}")
  g3 <- sprintf("bridge-side profile/bootstrap inference is unqualified (G3) on every promoted TSV row (claim_boundary at %s)", tsv_line("base_gaussian_location_scale"))
  a5 <- pm_plan_leaf(ctx, "A5")
  a7 <- function(x) sprintf("port to native R (%s)", pm_plan_leaf(ctx, x))

  list(
    # ---- Response families (18) --------------------------------------------
    fam("Gaussian location-scale (ML)", "gaussian",
        boundary = sprintf("%s; %s; NOT interval coverage.", rec("se", "cell_id", "se_gaussian_location_scale"), rec("fixtures", "capability_id", "base_gaussian_location_scale")),
        next_action = g3),
    fam("Bivariate Gaussian coscale (rho12)", "biv_gaussian",
        boundary = sprintf("%s; one fixed-effects draw, NOT interval coverage.", rec("se", "cell_id", "se_biv_gaussian_rho12")),
        next_action = g3),
    fam("Student-t location-scale", "student"),
    fam("LogNormal location-scale", "lognormal"),
    fam("Gamma location-scale", "gamma",
        boundary = sprintf("fixed-effect Gamma(link = \"log\") only here; the phylo and relmat Gamma cells are ledgered on the structure rows below (%s);", pm_cite_tsv(ctx, c("phylo_gamma_beta_binomial", "general_covariance_structured")))),
    fam("Poisson counts", "poisson",
        boundary = sprintf("fixed-effect Poisson only here; phylo/relmat Poisson cells are ledgered on the structure rows (%s);", pm_cite_tsv(ctx, c("phylo_count_large_p", "general_covariance_structured")))),
    fam("NegBinomial2 (NB2) counts", "nbinom2",
        boundary = sprintf("fixed-effect NB2 only here; phylo/relmat NB2 cells are ledgered on the structure rows (%s);", pm_cite_tsv(ctx, c("phylo_count_large_p", "general_covariance_structured")))),
    fam("Zero-inflated Poisson (ZIP)", "poisson", modifier = "zi",
        boundary = sprintf("ZIP is poisson() plus a `zi ~` formula on both engines (%s);", hurdle_msg)),
    fam("Zero-inflated NB2 (ZINB)", "nbinom2", modifier = "zi",
        boundary = sprintf("ZINB is nbinom2() plus a `zi ~` formula on both engines (%s);", hurdle_msg)),
    fam("Beta proportions", "beta",
        boundary = sprintf("fixed-effect beta() only here; the phylo Beta cell is ledgered on the non-Gaussian phylo row (%s); relmat on beta() is refused (%s);", pm_cite_tsv(ctx, "phylo_gamma_beta_binomial"), pm_cite_gates(ctx, "structured_unsupported_family"))),
    fam("Truncated NB2 (zero-truncated counts)", "truncated_nbinom2"),
    fam("Hurdle NB2", "nbinom2", modifier = "hu",
        boundary = sprintf(paste0(
          "CROSS-SPELLING: native drmTMB spells hurdle NB2 as truncated_nbinom2() + `hu ~` (%s) and refuses nbinom2() + `hu` (%s); ",
          "the bridge refuses truncated_nbinom2() and reaches DRM.jl only as nbinom2() + `hu ~`, so no identical call fits on both engines;"),
          hurdle_msg, nb2_hu_refusal),
        next_action = sprintf("admit truncated_nbinom2 through the bridge so the native spelling works on both engines (%s)", pm_plan_leaf(ctx, "A4.1\u2013A4.9")),
        green_override = "no identical call fits on both engines"),
    fam("Cumulative logit (ordinal)", "cumulative_logit",
        refused_note = "Cutpoints need a coefficient-label contract before the bridge can return them (docs/design/258-coefficient-naming-contract.md)."),
    fam("Beta-binomial proportions", "beta_binomial",
        refused_note = sprintf("The refusal is also a registered gate: %s.", pm_cite_gates(ctx, "base_unsupported_family")),
        boundary = sprintf("NAMING TRAP: TSV row `phylo_gamma_beta_binomial` (%s) evidences Gamma/Beta/Binomial phylo cells, not beta_binomial; this matrix joins on `syntax`, never on `capability_id`.", tsv_line("phylo_gamma_beta_binomial"))),
    fam("Zero-one-inflated beta", "zero_one_beta",
        refused_note = sprintf("The bridge already marshals the `zoi`/`coi` dpars (%s); the family itself is unadmitted.", r("bridge", "julia_bridge_supported_dpars <- function("))),
    fam("Tweedie (compound Poisson-Gamma)", "tweedie"),
    fam("Skew-normal location-scale", "skew_normal"),
    fam("Binomial (logistic)", "binomial",
        boundary = sprintf("%s; logit link only through the bridge (%s); NOT interval coverage.", rec("se", "cell_id", "se_binomial_trials"), binomial_logit),
        next_action = g3),

    # ---- Random-effect structure (11) --------------------------------------
    st("Gaussian random intercept (mean)", tsv_ids = "gaussian_random_intercept_mu",
       route_note = sprintf("ordinary `(1 \\| g)` marshalled by the conditional-Gaussian RI route (%s)", ri_spec),
       boundary = "ML and REML both fit with same-target coef/logLik/SE parity (SE_PASS both methods); the REML gap between methods (2.78 logLik units) is a genuine restriction, not a relabelled ML fit;"),
    st("Gaussian random slope (mean)", tsv_ids = "gaussian_random_slope_mu",
       boundary = sprintf("ML fits with same-target coef/SE parity (SE_PASS) but the Julia fit's sdpars/corpars are empty for this shape (a reporting gap, not a fit failure); REML is refused by the ENGINE itself at the pin, not only drmTMB's pre-check (%s);", jsl("retains the random-slope rejection")),
       next_action = "file the REML ArgumentError-passthrough gate defect against #1155's follow-up (ledgered in the TSV row's own next_action)"),
    st("Gaussian random effect on sigma (scale)", tsv_ids = "gaussian_sigma_random_intercept",
       route_note = sprintf("pre-Julia route-limit refusals for sigma-RE + REML and mu-RE + sigma-RE (%s)", sigma_ranef_limits),
       boundary = sprintf("ML fits but is NOT same-target parity at the 1e-4 bar (PARITY_FAIL/SE_FAIL): drmTMB integrates the sigma-RE by Laplace and DRM.jl by 32-node Gauss-Hermite quadrature, a converged-but-different-approximation gap established by an R transcription of the Julia GHQ marginal (ghq-check.tsv), not a wrong answer; REML is refused both by drmTMB's own pre-check and by the engine itself (%s; docs/dev-log/after-task/2026-09-03-f1-julia-route-surface.md);", sigma_ranef_limits)),
    st("Gaussian phylogenetic random intercept (mean)", tsv_ids = "gaussian_phylo_mean",
       boundary = sprintf("native R is scope-limited (%s); the bridge row is covered but NOT interval coverage (solver failure rate, claim_boundary at %s);", rs("phylo=scope-limited (implemented 4"), tsv_line("gaussian_phylo_mean"))),
    st("Gaussian spatial random intercept (mean)", tsv_ids = "general_covariance_structured",
       gate_ids = c("structured_sigma_predictor", "structured_precision_slot"),
       route_note = sprintf("spatial() marshalled as a covariance matrix (%s)", structured_types),
       boundary = sprintf("no spatial-marker receipt exists at the pin; the row's receipts are relmat cells (%s);", rec("classc", "cell_id", "gaussian_relmat")),
       next_action = "bank a spatial-marker same-target receipt before calling this axis green",
       green_override = "the covered TSV row carries relmat receipts only"),
    st("Gaussian animal-model random intercept (mean)", tsv_ids = "general_covariance_structured",
       gate_ids = c("structured_sigma_predictor", "structured_precision_slot"),
       route_note = sprintf("animal() marshalled as a covariance matrix (%s)", structured_types),
       boundary = sprintf("no animal-marker receipt exists at the pin; the row's receipts are relmat cells (%s);", rec("classc", "cell_id", "gaussian_relmat")),
       next_action = "bank an animal-marker same-target receipt before calling this axis green",
       green_override = "the covered TSV row carries relmat receipts only"),
    st("Gaussian relmat random intercept (mean)", tsv_ids = "general_covariance_structured",
       gate_ids = c("structured_sigma_predictor", "structured_precision_slot"),
       boundary = sprintf("%s; sigma ~ 1 only; NOT interval coverage;", rec("classc", "cell_id", "gaussian_relmat"))),
    st("Non-Gaussian phylogenetic random intercept (mean)",
       tsv_ids = c("phylo_count_large_p", "phylo_gamma_beta_binomial"),
       boundary = sprintf("native R is scope-limited (%s); %s; %s; NOT interval coverage;", rs("mixes `scope-limited` (lognormal, gamma, poisson"), rec("classc", "cell_id", "poisson_phylo_p3000"), rec("phylo_ng", "cell_id", "phylo_gamma"))),
    st("Non-Gaussian phylogenetic location-scale (\u03bc + log \u03c3)",
       route_note = sprintf("coupled mu+sigma phylo route admitted for the registry's locscale_phylo families (%s; %s) and the slope route (%s); NO TSV row names either", locscale_phylo, r("registry", "spec(\"nbinom2\""), slope_phylo),
       boundary = sprintf("native R is scope-limited: implemented for nbinom2 only, rejected for the rest (%s); the bridge admits nbinom2/gamma/beta on this route without a ledger row -- an admitted-without-row class the fixed-effect test does NOT cover.", rs("`Non-Gaussian")),
       next_action = "ledger the coupled and slope phylo routes with receipts, or fence them"),
    st("Tweedie random intercept (mean)",
       route_note = "no bridge route: fits natively on both sides, nothing to marshal",
       boundary = sprintf("native R admits an ordinary `(1 \\| g)` intercept and an independent `(0 + x \\| g)` slope on `mu` for tweedie() (%s), fit and recovered by tests/testthat/test-tweedie-location-scale.R:456-483; DRM.jl fits the same shape independently (%s). Not Julia-ahead: identified as a drmTMB documentation gap by the 2026-09-05 Julia-ahead census (docs/dev-log/evidence/julia-r-parity/2026-09-05-julia-ahead-census.md), not a missing route.", r("drmtmb", "validate_tweedie_mu_random_terms <- function("), jsl("Tweedie random intercept (mean)"))),
    st("Gaussian phylogenetic random intercept + slope, two SDs (mean)",
       route_note = "no bridge route: fits natively on both sides, nothing to marshal",
       boundary = sprintf("`phylo(1 + x | species, tree = tree)` (%s) fits the independent two-SD model for Gaussian mu because `has_phylo_mu_q2_covariance` is only set for `nbinom2`/`poisson` (%s), the same five-free-parameter model DRM.jl's `#620` replicates (%s). Not Julia-ahead: also identified as a drmTMB documentation gap by the 2026-09-05 Julia-ahead census (docs/dev-log/evidence/julia-r-parity/2026-09-05-julia-ahead-census.md); the Poisson/NegBinomial2 CORRELATED two-SD model under the same formula is a separate, already-known asymmetry.", r("drmtmb", "phylo = \"phylo(1 + x | species, tree = tree)\""), r("drmtmb", "has_phylo_mu_q2_covariance = as.integer("), jsl("Gaussian phylogenetic random intercept + slope, two SDs (mean)"))),

    # ---- Estimation and inference (11) -------------------------------------
    st("REML (Gaussian fixed-effect location-scale)",
       route_note = sprintf("REML is marshalled for documented Gaussian cells and refused elsewhere (%s); NO dedicated TSV row", refuse_reml),
       boundary = sprintf("native R is point-fit-recovery (%s): no interval claim on either side.", rs("mc-0261/mc-0263")),
       next_action = "a same-target REML receipt on the fixed-effect Gaussian cell would ledger the bridge axis"),
    st("REML with ordinary random effects (Gaussian mean)",
       route_note = sprintf("`(1 \\| g)` + REML reaches DRM.jl; sigma-RE + REML refused before Julia (%s); NO TSV row", sigma_ranef_limits),
       boundary = sprintf("native R is point-fit-recovery (%s); DRM.jl admits REML for a single mean intercept only (%s).", rs("mc-0265/mc-0267"), jsl("admits a single Gaussian mean intercept")),
       next_action = sprintf("measure with the estim_method oracle (%s)", a5)),
    st("REML bivariate phylogenetic location-scale (q4, all axes)", tsv_ids = "biv_q4_phylo_reml",
       boundary = sprintf("native R is scope-limited (%s); the bridge row is covered on coef/logLik and carries a documented coverage split (claim_boundary at %s);", rs("no single verified claim that a REML correction"), tsv_line("biv_q4_phylo_reml"))),
    st("Wald SEs and CIs (observed information)",
       route_note = sprintf("Wald intervals through the bridge come from drm_julia_wald_confint() (%s); receipts live in DRM.jl's parity-se.tsv per row; NO dedicated TSV row", wald_confint),
       boundary = sprintf("%s; %s.", rec("se", "cell_id", "se_gaussian_location_scale"), rec("intervals", "cell_id", "gauss_locscale_fe", where = list(method = "wald"))),
       next_action = "none pending on this axis; per-row SE receipts are the next_action of each family row"),
    st("Profile-likelihood CIs",
       route_note = sprintf("bridge profile intervals support one fixed-effect coefficient, one Gaussian phylo SD target, or all four q4 axes (%s)", interval_targets),
       boundary = sprintf("%s -- the pinned receipt predates the per-coefficient route and no coverage claim exists on the bridge.", rec("intervals", "cell_id", "gauss_locscale_fe", where = list(method = "profile"))),
       next_action = g3),
    st("Parametric bootstrap CIs",
       route_note = sprintf("bridge bootstrap intervals support one fixed-effect coefficient, one Gaussian phylo SD target, or all four q4 axes (%s)", interval_targets),
       boundary = sprintf("%s -- the pinned receipt predates the per-coefficient route and no coverage claim exists on the bridge.", rec("intervals", "cell_id", "gauss_locscale_fe", where = list(method = "bootstrap"))),
       next_action = g3),
    st("AGHQ adaptive-quadrature marginal estimator",
       route_note = "no bridge route: nothing to marshal on the R side",
       boundary = sprintf("native R has no implementation (%s); DRM.jl's is Poisson `(1 \\| g)` only (%s).", rs("`AGHQ`, chi-bar-square boundary tests"), jsl("Poisson `(1 | g)` only")),
       next_action = "owner decision: port or fence (not on any leaf)"),
    st("Variational (VA/ELBO) marginal estimator",
       route_note = "no bridge route: nothing to marshal on the R side",
       boundary = sprintf("planned on both sides (%s; %s).", rs("| Variational (VA/ELBO) marginal estimator |"), js("Variational (VA/ELBO) marginal estimator")),
       next_action = "owner decision: not on any leaf"),
    st("Chi-bar-square boundary LRT p-value",
       route_note = "no bridge route: nothing to marshal on the R side",
       boundary = sprintf("native R only flags wald_at_boundary (%s); DRM.jl exports chibar_pvalue/lrt_boundary (%s).", rs("`conf.status = \"wald_at_boundary\"`"), jsl("exports `chibar_pvalue`/`lrt_boundary`")),
       next_action = a7("A7")),
    st("Model comparison suite (LRT/anova/AICc/weights/update)",
       route_note = "no bridge route: nothing to marshal on the R side",
       boundary = sprintf("no exported symbol in R (%s); DRM.jl's `weights` member is prior weights, not model weights (%s).", rs("no exported symbol in `NAMESPACE`"), jsl("It is **not** Akaike / model weights")),
       next_action = a7("A7")),
    st("Heritability/repeatability/ICC accessors",
       route_note = "no bridge route: accessors run on native fit objects",
       boundary = sprintf("native R is point-fit-recovery (%s): delta-method Wald interval with a small-N sanity check, no coverage study.", rs("`Heritability/repeatability/ICC accessors` moved to")),
       next_action = sprintf("coverage campaign (owner decision D-139); DRM.jl-side coevolution accessors are ported under %s", pm_plan_leaf(ctx, "A7"))),

    # ---- Bivariate structure and missing data (5) --------------------------
    st("Bivariate structured random effect on all four axes (q4 PLSM)",
       tsv_ids = "biv_q4_phylo_reml", gate_ids = c("biv_invalid_partial_phylo", "biv_rho12_phylo"),
       boundary = sprintf("native R is point-fit-recovery (%s); the only ledgered bridge cell is the REML q4 row; the ML q4 route has no TSV row of its own;", rs("predominantly `diagnostic_only`")),
       next_action = "ledger the ML q4 bridge route (tests/testthat/test-julia-phylo-q4-corpairs.R exercises it)"),
    st("Cross-family bivariate (different families for y1 y2)",
       tsv_ids = "cross_family_latent", gate_ids = c("xfam_missing_route", "xfam_rho12_formula", "xfam_dispersionless_sigma"),
       route_note = sprintf("reachable from R via drmTMB_julia_xfam_bridge (%s)", xfam_bridge),
       boundary = sprintf("native R has no mixed pair (%s) so no native comparator can exist; DRM.jl lists it `missing` by its own non-promotion call (%s);", rs("`Cross-family"), jsl("No promotion")),
       next_action = "none: the boundary is signed (D-179 #3); do not spend simulation-recovery compute here"),
    st("Missing-response handling (native, per fitted route)",
       tsv_ids = "gaussian_response_mask", gate_ids = "base_missing_response_nongaussian",
       boundary = sprintf("the bridge covers Gaussian masks only; non-Gaussian masks are gated; DRM.jl's native row is `missing` because outside the q4 engine it is auto listwise deletion (%s);", jsl("the same underlying operation as `drm_listwise`"))),
    st("Missing-predictor imputation (mi())",
       gate_ids = c("base_impute", "base_missing_predictor_model"),
       route_note = "the joint mi() payload reaches DRM.jl through the joint bridge (tests/testthat/test-julia-joint-call.R); NO TSV row",
       boundary = sprintf("DRM.jl fences mi() out of the twin claim (D-181/D-209 \u00a73, %s); no R-parity claim is made for the route.", jsl("D-181 (2026-08-28, reaffirmed by")),
       next_action = "owner decision: the fence is recorded, not pending"),
    st("R to Julia bridge (engine=julia)",
       tsv_ids = "engine_control_surface",
       route_note = sprintf("the whole bridge ledger: %d TSV rows (%s) and %d gates (%s)", nrow(ctx$tsv), ctx$files$tsv, nrow(ctx$gates), ctx$files$gates),
       boundary = sprintf("the bridge exists on both sides (%s); its control surface stays experimental by design;", js("R to Julia bridge (engine=julia)")),
       next_action = "design engine_control explicitly before relaxing the gate (TSV next_action)")
  )
}

# ---- build + render --------------------------------------------------------

# A boundary or next action counts as CITED when it carries a file:line, a
# receipt id, a gate id, or a docs/ or tests/ path.
pm_is_cited <- function(x) {
  grepl(":[0-9]+\\b|receipt |gate `|docs/|tests/", x, perl = TRUE)
}

pm_build_matrix <- function(ctx) {
  entries <- pm_capability_entries(ctx)
  names_r <- ctx$r_status$capability
  got <- vapply(entries, `[[`, character(1L), "name")
  if (!identical(sort(got), sort(names_r))) {
    stop("entry table and capability-status.md disagree: missing ",
         paste(setdiff(names_r, got), collapse = ", "), "; extra ",
         paste(setdiff(got, names_r), collapse = ", "), call. = FALSE)
  }
  only_j <- setdiff(ctx$j_status$capability, names_r)
  only_r <- setdiff(names_r, ctx$j_status$capability)
  if (length(only_r)) {
    stop("drmTMB capability names absent from DRM.jl's file: ", paste(only_r, collapse = ", "), call. = FALSE)
  }
  entries <- entries[match(names_r, got)]
  j_label <- ctx$drmjl_label(ctx$files$j_status)
  rows <- lapply(entries, function(e) {
    nr <- pm_status_cell(ctx$r_status, e$name, ctx$files$r_status)
    nj <- pm_status_cell(ctx$j_status, e$name, j_label)
    mechanical_green <- ctx$r_status$status[match(e$name, ctx$r_status$capability)] == "implemented" &&
      ctx$j_status$status[match(e$name, ctx$j_status$capability)] == "implemented" &&
      grepl("^covered \\(", e$claim_status)
    green <- mechanical_green && !nzchar(e$green_override)
    boundary <- e$boundary
    if (mechanical_green && nzchar(e$green_override)) {
      boundary <- paste0("NOT GREEN despite a covered row: ", e$green_override, ". ", boundary)
    }
    boundary <- sub(";\\s*$", ".", boundary)
    if (nzchar(e$next_action)) boundary <- paste0(boundary, " NEXT: ", e$next_action, ".")
    if (!green && !pm_is_cited(boundary)) {
      stop("non-green row without a cited boundary or next action: ", e$name, call. = FALSE)
    }
    data.frame(
      capability = e$name, green = green, native_R = nr, native_Julia = nj,
      bridge_route = e$bridge_route, r_bridge_status = e$r_bridge_status,
      claim_status = e$claim_status, boundary = boundary,
      stringsAsFactors = FALSE
    )
  })
  mat <- do.call(rbind, rows)
  empty <- vapply(mat, function(col) any(!nzchar(trimws(as.character(col)))), logical(1L))
  if (any(empty)) {
    stop("empty cells in column(s): ", paste(names(mat)[empty], collapse = ", "), call. = FALSE)
  }
  attr(mat, "drmjl_only") <- only_j
  mat
}

# A capability name is code-spanned unless it already carries backticks
# (DRM.jl's `... (`algorithm = :em`)` rows), which would nest and mis-render.
pm_md_name <- function(x) {
  if (grepl("`", x, fixed = TRUE)) x else paste0("`", x, "`")
}

pm_md_cell <- function(x) {
  x <- gsub("\r?\n", " ", x)
  # `\|` is already an escaped pipe in a route note; escape only bare pipes.
  gsub("(?<!\\\\)\\|", "\\\\|", x, perl = TRUE)
}

pm_render <- function(ctx, mat) {
  only_j <- attr(mat, "drmjl_only")
  routes <- pm_admitted_routes(ctx$registry, ctx$supported_dpars)
  missing_routes <- pm_routes_without_row(routes, ctx$tsv)
  n_green <- sum(mat$green)
  cols <- c("capability", "native_R", "native_Julia", "bridge_route", "r_bridge_status", "claim_status", "boundary")
  header <- paste0("| ", paste(cols, collapse = " | "), " |")
  sep <- paste0("|", paste(rep("---", length(cols)), collapse = "|"), "|")
  body <- vapply(seq_len(nrow(mat)), function(i) {
    cells <- vapply(cols, function(cn) pm_md_cell(mat[[cn]][[i]]), character(1L))
    cells[["capability"]] <- paste0(if (mat$green[[i]]) "GREEN " else "", pm_md_name(mat$capability[[i]]))
    paste0("| ", paste(cells, collapse = " | "), " |")
  }, character(1L))
  c(
    "# drmTMB <-> DRM.jl parity matrix",
    "",
    "GENERATED by `tools/write-parity-matrix.R` -- do not edit by hand. Regenerate with",
    "`DRM_JL_PATH=<DRM.jl clone at the pin> Rscript tools/write-parity-matrix.R`",
    "from the drmTMB source checkout (no Julia is started). Running it twice on the",
    "same inputs yields byte-identical output; `tests/testthat/test-parity-matrix.R`",
    "checks that, and fails when a family the bridge admits has no ledger row.",
    "",
    "## Inputs",
    "",
    sprintf("- drmTMB `%s` (native_R axis; %d rows)", ctx$files$r_status, nrow(ctx$r_status)),
    sprintf("- DRM.jl `%s` at pin `%s` (native_Julia axis; %d rows), read with `git show`, never the working tree", ctx$files$j_status, ctx$pin, nrow(ctx$j_status)),
    sprintf("- `%s` (bridge ledger; %d rows) and `%s` (intentional gates; %d rows)", ctx$files$tsv, nrow(ctx$tsv), ctx$files$gates, nrow(ctx$gates)),
    sprintf("- `%s` (family registry; %d rows, %d admitted on the fixed-effect route)", ctx$files$registry, length(ctx$registry), sum(is.na(routes$modifier))),
    "- receipts: DRM.jl `docs/dev-log/evidence/parity-{se,fixtures,intervals,classc,phylo-nongaussian}.tsv` at the same pin",
    "",
    "## Row-name join",
    "",
    "| | count |",
    "|---|---:|",
    sprintf("| rows in drmTMB's file | %d |", nrow(ctx$r_status)),
    sprintf("| rows in DRM.jl's file | %d |", nrow(ctx$j_status)),
    sprintf("| matched exactly (byte-for-byte row name) | %d |", nrow(mat)),
    sprintf("| present only in DRM.jl's file | %d |", length(only_j)),
    "",
    "DRM.jl-only rows:",
    "",
    sprintf("- %s (%s)", vapply(only_j, pm_md_name, character(1L)), vapply(only_j, function(n) pm_cite(ctx$drmjl_label(ctx$files$j_status), ctx$j_status$line[match(n, ctx$j_status$capability)]), character(1L))),
    "",
    "## Reading the table",
    "",
    "- `native_R` / `native_Julia`: the status word each twin's capability-status.md",
    "  gives the row, with the line it came from.",
    "- `bridge_route`: how `engine = \"julia\"` reaches (or refuses) the capability --",
    "  TSV rows joined on their `syntax` column, gates from the gate registry,",
    "  registry lines, and bridge functions, each cited.",
    "- `r_bridge_status` / `claim_status`: copied from the cited TSV row(s);",
    "  `unledgered` means no TSV row exists; `refused` means the bridge refuses",
    "  the capability before Julia starts.",
    "- `boundary`: why the row is not GREEN, with a citation or a receipt id, and",
    "  the next action that would move it. Receipt ids name rows in DRM.jl's",
    "  evidence tables at the pin.",
    sprintf("- GREEN = native_R `implemented` AND native_Julia `implemented` AND bridge `claim_status` `covered`, unless the row states a written override: **%d of %d** rows.", n_green, nrow(mat)),
    "",
    "## The matrix",
    "",
    header, sep, body,
    "",
    "## Admitted through the bridge, ledgered nowhere",
    "",
    sprintf("Routes `drm_julia_family_tag()` admits on the fixed-effect route (registry `fe`), plus the native modifier routes whose bridge family is admitted and whose modifier the bridge marshals -- %d routes in all: %s.",
            nrow(routes), paste0("`", routes$route, "`", collapse = ", ")),
    "",
    if (length(missing_routes)) {
      c(sprintf("**%d of them have NO TSV row** (the fixed-effect join finds no `route == \"base\"` row whose `syntax` calls the family's constructor and, for a modifier route, carries its `dpar ~` formula):", length(missing_routes)),
        "", sprintf("- `%s`", missing_routes))
    } else {
      "Every admitted route has a TSV row."
    },
    "",
    "`tests/testthat/test-parity-matrix.R` fails while this list is non-empty. That is",
    "the red control for the leaf that ledgers these routes, not a defect in this file."
  )
}

pm_write_matrix <- function(root, drmjl_path, out = file.path(root, "docs", "design", "parity-matrix.md")) {
  ctx <- pm_load_context(root, drmjl_path)
  mat <- pm_build_matrix(ctx)
  lines <- pm_render(ctx, mat)
  dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, out, useBytes = TRUE)
  message("wrote ", nrow(mat), " parity-matrix rows (", sum(mat$green), " GREEN) to ", out,
          " at DRM.jl pin ", ctx$pin_short)
  invisible(mat)
}

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  drmjl_path <- if (length(args) >= 1L) args[[1L]] else Sys.getenv("DRM_JL_PATH", unset = "")
  if (!nzchar(drmjl_path) || !dir.exists(drmjl_path)) {
    stop("Set DRM_JL_PATH (or pass it as the first argument) to a DRM.jl clone at the pin.", call. = FALSE)
  }
  out <- if (length(args) >= 2L) args[[2L]] else file.path("docs", "design", "parity-matrix.md")
  pm_write_matrix(".", drmjl_path, out)
}

if (sys.nframe() == 0L) {
  main()
}
