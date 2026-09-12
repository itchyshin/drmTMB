#!/usr/bin/env Rscript
# THE SCOREBOARD as a generated artefact (parity-joint A11 preparation,
# 2026-09-05).
#
# One row per drmTMB-native capability, three axes, and an explicit
# denominator:
#
#   native_R      does the capability fit natively in R?
#   native_Julia  does it fit natively in Julia?
#   bridge        is it reachable through engine = "julia" WITH A RECEIPT?
#
# WHAT MAKES THIS DIFFERENT FROM `docs/design/parity-matrix.md`. The matrix
# reports what each ledger SAYS. The scoreboard reports what is CITED, and
# counts what is not. A cell that cannot be determined from a file:line or a
# receipt id reads `UNCITED` and is counted as such; it is never inferred and
# never left blank in a way a reader could mistake for coverage. The UNCITED
# count is the headline number: it is the honest size of the gap between what
# the programme claims and what it can point at.
#
# THE ROW SET AND THE JOIN COME FROM THE MATRIX GENERATOR. This file
# `sys.source()`s `tools/write-parity-matrix.R` and calls its
# `pm_load_context()` / `pm_build_matrix()`. That is deliberate: the
# capability-name -> TSV-row join is subtle (the `phylo_gamma_beta_binomial`
# substring trap, the `|` random-effect guard, the modifier-dpar routes) and a
# second, independent implementation of it would be a second chance to be
# confidently wrong. One matcher, two readers.
#
# CONSEQUENCE OF THAT REUSE (stated, not hidden): `pm_build_matrix()` aborts
# when a drmTMB capability name is absent from DRM.jl's capability-status.md,
# so this file can never report a drmTMB-only row. That case is the subject of
# `tools/write-capability-status-join.R` /
# `docs/design/capability-status-join.md`, which is generated independently and
# does not abort.
#
# THE BRIDGE AXIS, PRECISELY. A receipt is a row in one of DRM.jl's evidence
# tables at the read ref, reached by `capability_id`. Two tiers, reported
# separately because they are not the same claim:
#
#   LEDGERED  the capability's matrix row cites a
#             `inst/extdata/julia-capabilities.tsv:<line>` whose
#             `capability_id` names receipt rows. A committed ledger row
#             connects the capability to the evidence.
#   ALIAS     no ledger row connects them, but DRM.jl carries receipt rows
#             under an id this file DECLARES for the capability (see
#             `sb_receipt_aliases()`). Every alias is verified at generation
#             time -- an alias whose id has no receipt row aborts generation --
#             and the receipt's own `label` is printed so a reader can check
#             the receipt really describes that capability. An ALIAS cell is
#             evidence that exists and is NOT ledgered; it is reported as its
#             own verdict, never as a covered one.
#
# Verdict precedence on the bridge axis, highest first:
#
#   REFUSED             the matrix says the bridge REFUSES the route -- either
#                       at drm_julia_family_tag() (the family is unadmitted) or
#                       at a named pre-Julia guard backed by a registered gate.
#                       A refusal is a determination
#                       with a file:line, so it is NOT uncited. A refusal wins
#                       over a receipt: when DRM.jl carries a receipt for a
#                       route drmTMB still refuses, the row reads
#                       `REFUSED+UPSTREAM-RECEIPT` and is counted as a
#                       CONTRADICTION, which is the finding, not a footnote.
#   RECEIPT             at least one receipt row with a passing status.
#   RECEIPT-NOT-PASS    receipt rows exist but none passes (a negative control,
#                       or `NO_NATIVE_COMPARATOR`). Cited, not covered.
#   UNCITED             none of the above. Includes every row whose
#                       `bridge_route` merely ASSERTS "no bridge route" without
#                       a file:line -- an uncited assertion is exactly what
#                       this file exists to count.
#
# USAGE (from the drmTMB source checkout; no Julia is started):
#   DRM_JL_PATH=/path/to/DRM.jl-clone Rscript tools/write-parity-scoreboard.R
#   Rscript tools/write-parity-scoreboard.R <drmjl-path> [<out>]
#
# The DRM.jl clone is read at its HEAD with `git show`, never its working tree.
# Both shas -- drmTMB's HEAD and DRM.jl's -- are written into the output, so a
# reader can tell exactly what the numbers describe. Running this twice at the
# same two commits yields byte-identical output.

# ---- load the matrix generator's join, without running its main() ----------

sb_matrix_env <- function(root) {
  path <- file.path(root, "tools", "write-parity-matrix.R")
  if (!file.exists(path)) {
    stop("tools/write-parity-matrix.R not found under ", root, call. = FALSE)
  }
  env <- new.env(parent = globalenv())
  # sys.source() evaluates inside this call, so the generator's
  # `if (sys.nframe() == 0L) main()` guard does not fire.
  sys.source(path, envir = env)
  env
}

sb_head_sha <- function(repo) {
  out <- suppressWarnings(system2(
    "git", c("-C", shQuote(repo), "rev-parse", "HEAD"), stdout = TRUE, stderr = FALSE
  ))
  status <- attr(out, "status")
  if (!is.null(status) && status != 0L) {
    stop("git rev-parse HEAD failed in ", repo, call. = FALSE)
  }
  as.character(out)[[1L]]
}

# A receipt summary necessarily predates the commit that adds the tracked
# summary and generated Markdown.  Accept that fixed point only when the
# interval from the receipt pin to the current source has not touched an input
# that could change the classified evidence or how it is interpreted.
sb_ordinary_laplace_source_drift <- function(root, from, to) {
  valid_sha <- function(x) is.character(x) && length(x) == 1L &&
    grepl("^[0-9a-f]{40}$", x)
  if (!valid_sha(from) || !valid_sha(to)) {
    stop("ordinary-Laplace source-drift check needs full git shas", call. = FALSE)
  }
  ancestor <- suppressWarnings(system2(
    "git", c("-C", shQuote(root), "merge-base", "--is-ancestor", from, to),
    stdout = FALSE, stderr = FALSE
  ))
  if (!identical(ancestor, 0L)) return(TRUE)
  changed <- suppressWarnings(system2(
    "git", c("-C", shQuote(root), "diff", "--name-only", paste0(from, "..", to)),
    stdout = TRUE, stderr = FALSE
  ))
  status <- attr(changed, "status")
  if (!is.null(status) && status != 0L) {
    stop("git diff failed in ordinary-Laplace source-drift check", call. = FALSE)
  }
  protected <- c(
    "^R/", "^src/", "^(DESCRIPTION|NAMESPACE)$",
    "^inst/extdata/julia-capabilities\\.tsv$",
    "^tools/write-parity-matrix\\.R$",
    "^docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/(reconcile-four-fixture-(receipt|summary)\\.R|run-four-fixture-receipt\\.R)$"
  )
  any(grepl(paste(protected, collapse = "|"), changed))
}

# ---- axis vocabularies -----------------------------------------------------

# The status word each twin's capability-status.md gives a row, mapped to a
# fits-natively verdict. An unknown status word aborts: a silent fall-through
# is how a scoreboard starts lying.
sb_native_verdict <- function(status) {
  switch(status,
    implemented = "FITS",
    `scope-limited` = "PARTIAL",
    `point-fit-recovery` = "PARTIAL",
    experimental = "PARTIAL",
    rejected = "NO",
    planned = "NO",
    missing = "NO",
    stop("unknown capability status word: ", status, call. = FALSE)
  )
}

# Receipt statuses that count as evidence the route WORKS. Anything else
# (NEGATIVE_CONTROL_OK proves the check can fail; NO_NATIVE_COMPARATOR proves
# there was nothing to compare against) is a receipt but not a passing one.
sb_pass_statuses <- function() c("SE_PASS", "PARITY_PASS")

# Evidence tables keyed by `capability_id`. parity-intervals.tsv is keyed by
# `cell_id` and carries no capability_id, so it cannot be joined this way; it
# is not consulted here, and rows that depend on it read UNCITED.
sb_receipt_tables <- function() c("se", "fixtures", "classc", "phylo_ng")

# DECLARED capability-name -> receipt capability_id aliases: DRM.jl carries
# receipt rows under these ids and no committed drmTMB ledger row connects them
# to the capability. Every id here is verified at generation time. Adding an
# entry is a claim a reader can check against the receipt's printed label.
sb_receipt_aliases <- function() {
  # PRUNED 2026-09-06. Three entries died when their families gained committed ledger
  # rows -- fe_cumulative_logit, fe_skew_normal and fe_tweedie -- and this function's own
  # rule at the alias check below is that an alias must ADD something: "if a ledger row
  # already reaches the same id the alias is dead weight and should be deleted, not
  # carried". The generator ABORTED on the first of them, so the scoreboard could not be
  # regenerated on main at all. All five were checked against
  # drm_julia_capability_comparison() rather than only the one that happened to abort.
  # The two below still earn their place: DRM.jl carries their receipts under ids with no
  # `fe_` prefix, and no ledger row reaches them.
  list(
    `Truncated NB2 (zero-truncated counts)` = "truncated_nbinom2",
    `Zero-one-inflated beta` = "zero_one_beta"
  )
}

# ---- the joins -------------------------------------------------------------

# The bridge ledger capability_ids a matrix row cites, read from the
# `inst/extdata/julia-capabilities.tsv:<line>` anchors the matrix generator
# emits. Line numbers, not names: a name substring match is the trap this
# programme has already been caught by.
sb_cited_tsv_ids <- function(ctx, bridge_route) {
  pat <- paste0(gsub(".", "\\.", ctx$files$tsv, fixed = TRUE), ":([0-9]+)")
  hits <- regmatches(bridge_route, gregexpr(pat, bridge_route, perl = TRUE))[[1L]]
  if (!length(hits)) return(character(0L))
  lines <- as.integer(sub("^.*:", "", hits))
  ids <- ctx$tsv$capability_id[match(lines, ctx$tsv$line)]
  if (anyNA(ids)) {
    stop("matrix cites a julia-capabilities.tsv line with no row: ",
         paste(lines[is.na(ids)], collapse = ", "), call. = FALSE)
  }
  unique(ids)
}

# Every receipt row in DRM.jl's capability_id-keyed evidence tables, for the
# given ids, as a data.frame(id, status, label, cite).
sb_receipts <- function(env, ctx, ids) {
  if (!length(ids)) {
    return(data.frame(id = character(0L), status = character(0L),
                      label = character(0L), cite = character(0L),
                      stringsAsFactors = FALSE))
  }
  out <- list()
  for (key in sb_receipt_tables()) {
    tab <- ctx$j_receipts[[key]]
    if (is.null(tab) || !"capability_id" %in% names(tab)) next
    keep <- which(tab$capability_id %in% ids)
    if (!length(keep)) next
    file <- ctx$files[[paste0("j_", key)]]
    out[[length(out) + 1L]] <- data.frame(
      id = tab$capability_id[keep],
      status = tab$status[keep],
      label = tab$label[keep],
      cite = env$pm_cite(ctx$drmjl_label(file), tab$line[keep]),
      stringsAsFactors = FALSE
    )
  }
  if (!length(out)) {
    return(data.frame(id = character(0L), status = character(0L),
                      label = character(0L), cite = character(0L),
                      stringsAsFactors = FALSE))
  }
  do.call(rbind, out)
}

# One short, citation-carrying summary of a receipt set: the passing rows if
# there are any, otherwise every row, capped so the cell stays readable and
# always naming how many were elided.
sb_receipt_text <- function(rec, max_show = 3L) {
  pass <- rec[rec$status %in% sb_pass_statuses(), , drop = FALSE]
  use <- if (nrow(pass)) pass else rec
  shown <- utils::head(use, max_show)
  txt <- sprintf("receipt capability_id=%s status=%s \"%s\" (%s)",
                 shown$id, shown$status, shown$label, shown$cite)
  if (nrow(use) > nrow(shown)) {
    txt <- c(txt, sprintf("+%d more receipt row(s)", nrow(use) - nrow(shown)))
  }
  paste(txt, collapse = "; ")
}

# Every capability_id that carries a receipt row at the ref, with its tables.
sb_all_receipt_ids <- function(ctx) {
  ids <- unlist(lapply(sb_receipt_tables(), function(key) {
    tab <- ctx$j_receipts[[key]]
    if (is.null(tab) || !"capability_id" %in% names(tab)) return(character(0L))
    tab$capability_id
  }), use.names = FALSE)
  sort(unique(ids))
}

# The 0.7.1 ordinary-Laplace arc is deliberately NOT a generic PARITY_PASS/
# SE_PASS receipt.  Its retained evidence is a source-pinned reconciliation of
# profile terminal classifications, including the coupled L22 non-finite
# endpoint.  Read the tiny committed summary, never the raw sidecars, and
# fail closed if it is absent, stale, or changes the frozen denominator.
sb_ordinary_laplace_summary <- function(root, ctx, drmtmb_sha, historical = FALSE) {
  path <- file.path(root, "docs", "dev-log", "evidence", "julia-r-parity",
                    "071-ordinary-laplace", "reconciled-summary.tsv")
  empty <- data.frame(capability_id = character(), stringsAsFactors = FALSE)
  if (!file.exists(path)) return(empty)
  tab <- utils::read.delim(path, stringsAsFactors = FALSE, check.names = FALSE)
  required <- c("capability_id", "fixtures", "fixture_count", "declared_target_count",
                "engine_target_count", "finite_profile_count", "nonfinite_endpoint_count",
                "other_terminal_count", "classification", "drmtmb_commit", "drm_jl_commit",
                "runner_sha256")
  if (!identical(names(tab), required) || nrow(tab) != 2L || anyDuplicated(tab$capability_id)) {
    stop("0.7.1 ordinary-Laplace summary schema drift: ", path, call. = FALSE)
  }
  expected <- data.frame(
    capability_id = c("ordinary_ri_scalar_laplace", "ordinary_nb2_coupled_laplace"),
    fixtures = c("binomial_ri,poisson_ri,nb2_ri", "nb2_coupled"),
    fixture_count = c(3L, 1L), declared_target_count = c(10L, 7L),
    engine_target_count = c(20L, 14L), finite_profile_count = c(20L, 12L),
    nonfinite_endpoint_count = c(0L, 2L), other_terminal_count = c(0L, 0L),
    classification = c("CLASSIFIED_FINITE", "CLASSIFIED_WITH_RETAINED_NONFINITE_ENDPOINT"),
    stringsAsFactors = FALSE
  )
  tab <- tab[match(expected$capability_id, tab$capability_id), , drop = FALSE]
  summary_sha <- unique(tab$drmtmb_commit)
  stale <- length(summary_sha) != 1L || sb_ordinary_laplace_source_drift(root, summary_sha, drmtmb_sha) ||
    any(tab$drm_jl_commit != ctx$pin)
  if (!identical(tab[names(expected)], expected) || (!historical && stale)) {
    stop("0.7.1 ordinary-Laplace summary is stale or changes the frozen denominator", call. = FALSE)
  }
  runner <- file.path(root, "docs", "dev-log", "evidence", "julia-r-parity",
                      "071-ordinary-laplace", "run-four-fixture-receipt.R")
  if (!file.exists(runner) || any(tab$runner_sha256 != unname(tools::sha256sum(runner)[[1L]]))) {
    stop("0.7.1 ordinary-Laplace summary runner hash is stale", call. = FALSE)
  }
  tab
}

# The S7 campaign is a separate, retained 500-seed profile-coverage study. It
# deliberately does not replace the one-draw G4 classification above and does
# not enter the generic point/SE receipt denominator below.
sb_ordinary_laplace_s7_columns <- function() {
  c(
    "capability_id", "fixture", "engine", "parm", "target_class", "truth",
    "attempt_count", "unconditional_covered", "unconditional_coverage",
    "unconditional_mcse", "unconditional_wilson_lower", "unconditional_wilson_upper",
    "finite_endpoint_count", "conditional_covered", "conditional_coverage",
    "conditional_mcse", "conditional_wilson_lower", "conditional_wilson_upper",
    "fit_failed_count", "profile_failed_count", "nonfinite_endpoint_count",
    "truth_outside_count", "drmtmb_commit", "drm_jl_commit",
    "campaign_metadata_sha256", "drmtmb_archive_sha256", "drm_jl_archive_sha256",
    "source_pins_sha256", "runtime_sha256", "source_tree_check_sha256", "collector_sha256", "contract_sha256"
  )
}

sb_ordinary_laplace_s7_validate_plan <- function(root, tab) {
  helper <- file.path(root, "docs", "dev-log", "evidence", "julia-r-parity",
                      "071-ordinary-laplace", "prepare-s7-campaign-manifest.R")
  if (!file.exists(helper)) stop("S7 coverage validator cannot find frozen-plan helper", call. = FALSE)
  env <- new.env(parent = globalenv())
  sys.source(helper, envir = env)
  plan <- env$r071_s7_profile_plan()
  key <- function(x) paste(x$fixture, x$engine, x$parm, sep = "\r")
  observed_key <- key(tab)
  expected_key <- key(plan)
  if (nrow(plan) != 34L || anyDuplicated(observed_key) || !setequal(observed_key, expected_key)) {
    stop("S7 ordinary-Laplace coverage summary does not match the frozen profile plan", call. = FALSE)
  }
  expected <- plan[match(observed_key, expected_key), c("target_class", "truth"), drop = FALSE]
  if (!identical(as.character(tab$target_class), as.character(expected$target_class)) ||
      !isTRUE(all.equal(as.numeric(tab$truth), as.numeric(expected$truth), tolerance = 1e-12))) {
    stop("S7 ordinary-Laplace coverage summary changes frozen target metadata", call. = FALSE)
  }
  invisible(tab)
}

sb_ordinary_laplace_s7_validate_numeric <- function(tab) {
  near <- function(x, y) all(is.finite(x) & is.finite(y) & abs(x - y) <= 1e-12)
  finite <- tab$finite_endpoint_count > 0L
  conditional_bad <- FALSE
  if (any(finite)) {
    conditional_bad <- !near(tab$conditional_coverage[finite],
                              tab$conditional_covered[finite] / tab$finite_endpoint_count[finite]) ||
      !near(tab$conditional_mcse[finite], sqrt(tab$conditional_coverage[finite] *
        (1 - tab$conditional_coverage[finite]) / tab$finite_endpoint_count[finite])) ||
      any(tab$conditional_wilson_lower[finite] < 0 | tab$conditional_wilson_upper[finite] > 1 |
          tab$conditional_wilson_lower[finite] > tab$conditional_coverage[finite] |
          tab$conditional_wilson_upper[finite] < tab$conditional_coverage[finite])
  }
  if (any(!finite)) {
    conditional_bad <- conditional_bad || any(tab$conditional_covered[!finite] != 0L) ||
      any(!is.na(tab$conditional_coverage[!finite])) ||
      any(!is.na(tab$conditional_mcse[!finite])) ||
      any(!is.na(tab$conditional_wilson_lower[!finite])) ||
      any(!is.na(tab$conditional_wilson_upper[!finite]))
  }
  if (any(tab$unconditional_covered < 0L | tab$unconditional_covered > tab$attempt_count) ||
      any(tab$finite_endpoint_count < 0L | tab$finite_endpoint_count > tab$attempt_count) ||
      any(tab$conditional_covered < 0L | tab$conditional_covered > tab$finite_endpoint_count) ||
      !near(tab$unconditional_coverage, tab$unconditional_covered / tab$attempt_count) ||
      !near(tab$unconditional_mcse, sqrt(tab$unconditional_coverage *
                                           (1 - tab$unconditional_coverage) / tab$attempt_count)) ||
      any(tab$unconditional_wilson_lower < 0 | tab$unconditional_wilson_upper > 1 |
          tab$unconditional_wilson_lower > tab$unconditional_coverage |
          tab$unconditional_wilson_upper < tab$unconditional_coverage) ||
      conditional_bad) {
    stop("S7 ordinary-Laplace coverage summary has inconsistent numeric evidence", call. = FALSE)
  }
  invisible(tab)
}

sb_ordinary_laplace_s7_aggregate <- function(tab) {
  required <- sb_ordinary_laplace_s7_columns()
  if (!is.data.frame(tab) || !identical(names(tab), required) || nrow(tab) != 34L ||
      anyDuplicated(tab[c("fixture", "engine", "parm")]) ||
      any(tab$attempt_count != 500L) || any(!is.finite(tab$truth))) {
    stop("S7 ordinary-Laplace coverage summary schema or denominator drift", call. = FALSE)
  }
  scalar <- c("binomial_ri", "poisson_ri", "nb2_ri")
  expected_capability <- ifelse(tab$fixture %in% scalar,
                                "ordinary_ri_scalar_laplace",
                                ifelse(tab$fixture == "nb2_coupled",
                                       "ordinary_nb2_coupled_laplace", NA_character_))
  fixture_counts <- table(tab$fixture)
  if (anyNA(expected_capability) || any(tab$capability_id != expected_capability) ||
      !identical(names(fixture_counts), c("binomial_ri", "nb2_coupled", "nb2_ri", "poisson_ri")) ||
      !identical(as.integer(fixture_counts), c(6L, 14L, 8L, 6L)) ||
      any(tab$unconditional_covered + tab$fit_failed_count + tab$profile_failed_count +
          tab$nonfinite_endpoint_count + tab$truth_outside_count != tab$attempt_count) ||
      any(tab$conditional_covered + tab$truth_outside_count != tab$finite_endpoint_count)) {
    stop("S7 ordinary-Laplace coverage summary changes the frozen target set", call. = FALSE)
  }
  provenance <- c("drmtmb_commit", "drm_jl_commit", "campaign_metadata_sha256",
                  "drmtmb_archive_sha256", "drm_jl_archive_sha256", "source_pins_sha256",
                  "runtime_sha256", "source_tree_check_sha256", "collector_sha256", "contract_sha256")
  if (any(vapply(provenance, function(name) length(unique(tab[[name]])) != 1L,
                 logical(1L)))) {
    stop("S7 ordinary-Laplace coverage summary has mixed provenance", call. = FALSE)
  }
  rows <- lapply(split(tab, tab$capability_id), function(x) {
    data.frame(
      capability_id = x$capability_id[[1L]],
      fixture_count = length(unique(x$fixture)),
      declared_target_count = nrow(x) / 2L,
      engine_target_count = nrow(x),
      per_target_attempt_count = unique(x$attempt_count),
      attempt_count = sum(x$attempt_count),
      unconditional_covered = sum(x$unconditional_covered),
      finite_endpoint_count = sum(x$finite_endpoint_count),
      fit_failed_count = sum(x$fit_failed_count),
      profile_failed_count = sum(x$profile_failed_count),
      nonfinite_endpoint_count = sum(x$nonfinite_endpoint_count),
      truth_outside_count = sum(x$truth_outside_count),
      classification = "S7_COVERAGE_CLASSIFIED",
      as.list(x[1L, provenance, drop = FALSE]),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })
  out <- do.call(rbind, rows)
  expected <- c("ordinary_ri_scalar_laplace", "ordinary_nb2_coupled_laplace")
  out <- out[match(expected, out$capability_id), , drop = FALSE]
  if (!identical(as.integer(out$fixture_count), c(3L, 1L)) ||
      !identical(as.integer(out$declared_target_count), c(10L, 7L)) ||
      !identical(as.integer(out$engine_target_count), c(20L, 14L))) {
    stop("S7 ordinary-Laplace coverage summary has the wrong capability totals", call. = FALSE)
  }
  row.names(out) <- NULL
  out
}

sb_ordinary_laplace_s7_source_drift <- function(root, from, to) {
  if (sb_ordinary_laplace_source_drift(root, from, to)) return(TRUE)
  changed <- suppressWarnings(system2(
    "git", c("-C", shQuote(root), "diff", "--name-only", paste0(from, "..", to)),
    stdout = TRUE, stderr = FALSE
  ))
  status <- attr(changed, "status")
  if (!is.null(status) && status != 0L) stop("git diff failed in S7 source-drift check", call. = FALSE)
  s7_inputs <- paste0(
    "^docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/(",
    "prepare-s7-campaign-(manifest|bundle)\\.R|s7-(attempt-contract|campaign-fixture|fit-attempt|fit-diagnostics|",
    "live-fit-factory|run-task|task-dispatch|fir-array|fir-worker|fir-preflight|reconcile-campaign)\\.(R|sh))$"
  )
  any(grepl(s7_inputs, changed))
}

# The campaign normally records the frozen writer's digest.  Its successful
# reconciliation used one explicitly retained orchestration wrapper to source
# the collector into the global environment; that wrapper is admissible only
# when its exact, versioned bytes match the digest carried by the coverage row.
sb_ordinary_laplace_s7_collectors <- function(root) {
  evidence <- file.path(root, "docs", "dev-log", "evidence", "julia-r-parity",
                        "071-ordinary-laplace")
  paths <- c(
    writer = file.path(evidence, "s7-write-coverage-summary.R"),
    scopefix = file.path(evidence, "s7-write-coverage-summary-scopefix.R")
  )
  absent <- names(paths)[!file.exists(paths)]
  if (length(absent)) {
    stop("S7 coverage collector provenance is incomplete: ",
         paste(absent, collapse = ", "), call. = FALSE)
  }
  vapply(paths, function(path) unname(tools::sha256sum(path)[[1L]]), character(1L))
}

sb_ordinary_laplace_s7_summary <- function(root, ctx, drmtmb_sha) {
  path <- file.path(root, "docs", "dev-log", "evidence", "julia-r-parity",
                    "071-ordinary-laplace", "s7-coverage-summary.tsv")
  empty <- data.frame(capability_id = character(), stringsAsFactors = FALSE)
  if (!file.exists(path)) return(empty)
  tab <- utils::read.delim(path, stringsAsFactors = FALSE, check.names = FALSE)
  sidecar <- paste0(path, ".sha256")
  if (!file.exists(sidecar) || length(lines <- readLines(sidecar, warn = FALSE)) != 1L ||
      !identical(lines[[1L]], paste(unname(tools::sha256sum(path)[[1L]]), basename(path), sep = "  "))) {
    stop("S7 ordinary-Laplace coverage summary checksum is missing or stale", call. = FALSE)
  }
  sb_ordinary_laplace_s7_validate_plan(root, tab)
  sb_ordinary_laplace_s7_validate_numeric(tab)
  aggregated <- sb_ordinary_laplace_s7_aggregate(tab)
  if (any(aggregated$drm_jl_commit != ctx$pin) ||
      sb_ordinary_laplace_s7_source_drift(root, aggregated$drmtmb_commit[[1L]], drmtmb_sha)) {
    stop("S7 ordinary-Laplace coverage summary is stale or changes campaign inputs", call. = FALSE)
  }
  contract <- file.path(root, "docs", "dev-log", "evidence", "julia-r-parity",
                        "071-ordinary-laplace", "s7-attempt-contract.R")
  collectors <- sb_ordinary_laplace_s7_collectors(root)
  if (!file.exists(contract) ||
      any(!aggregated$collector_sha256 %in% unname(collectors)) ||
      any(aggregated$contract_sha256 != unname(tools::sha256sum(contract)[[1L]]))) {
    stop("S7 ordinary-Laplace coverage summary collector or contract hash is stale", call. = FALSE)
  }
  aggregated
}

# WIDENED 2026-09-05 (leaf uncited-random-effects). Until this change the only
# refusal this file could see was the family-tag one, so a capability the
# bridge refuses at a REGISTERED GATE -- with the guard named, the
# `R/julia-bridge.R:<line>` printed, and a measured receipt row behind it --
# still counted as UNCITED. That is the opposite of what this file is for: its
# own rule is that "a refusal is a determination with a file:line, so it is NOT
# uncited", and a gated refusal is exactly that. Both phrasings are emitted by
# `tools/write-parity-matrix.R` and nowhere else, so this predicate stays a
# match on the generator's own words rather than a guess about prose.
sb_refusal_patterns <- function() {
  c(
    # pm_family_entry(): the family is not in the registry `fe` list.
    "REFUSED at drm_julia_family_tag\\(\\)",
    # pm_struct_entry(): a registered gate refuses the route pre-Julia.
    "the bridge REFUSES this route before Julia starts, at [A-Za-z0-9_.]+\\(\\)",
    # accessor-level FENCE (leaf `uncited-accessors`): the route exists but a
    # named accessor refuses on a `drmTMB_julia` object, cited at any R/*.R line.
    "FENCED at R/[A-Za-z0-9_.-]+\\.R:[0-9]+"
  )
}

sb_is_refused <- function(bridge_route) {
  any(vapply(sb_refusal_patterns(),
             function(p) grepl(p, bridge_route, perl = TRUE),
             logical(1L)))
}

# The `R/julia-bridge.R:<line>` the matrix gives for a refusal, so a REFUSED
# cell carries a file:line of its own rather than borrowing the matrix's prose.
sb_refusal_cite <- function(bridge_route) {
  m <- regmatches(bridge_route,
                  regexpr("R/[A-Za-z0-9_.-]+\\.R:[0-9]+", bridge_route, perl = TRUE))
  if (!length(m) || !nzchar(m)) "" else m
}

sb_bridge_cell <- function(env, ctx, name, bridge_route, ordinary_summary, s7_summary) {
  ledger_ids <- sb_cited_tsv_ids(ctx, bridge_route)
  ledger_rec <- sb_receipts(env, ctx, ledger_ids)

  ordinary <- ordinary_summary[ordinary_summary$capability_id %in% ledger_ids, , drop = FALSE]
  if (nrow(ordinary) > 1L) stop("multiple ordinary-Laplace summaries reach ", name, call. = FALSE)
  s7 <- s7_summary[s7_summary$capability_id %in% ledger_ids, , drop = FALSE]
  if (nrow(s7) > 1L) stop("multiple S7 ordinary-Laplace summaries reach ", name, call. = FALSE)

  alias <- sb_receipt_aliases()[[name]]
  alias_rec <- if (is.null(alias)) {
    sb_receipts(env, ctx, character(0L))
  } else {
    r <- sb_receipts(env, ctx, alias)
    if (!nrow(r)) {
      stop("declared receipt alias has no receipt row at the ref: ", name,
           " -> ", alias, call. = FALSE)
    }
    # An alias must add something. If a ledger row already reaches the same
    # id the alias is dead weight and should be deleted, not carried.
    if (alias %in% ledger_ids) {
      stop("receipt alias is redundant (a ledger row already cites it): ",
           name, " -> ", alias, call. = FALSE)
    }
    r
  }

  refused <- sb_is_refused(bridge_route)
  all_rec <- rbind(ledger_rec, alias_rec)
  has_pass <- any(all_rec$status %in% sb_pass_statuses())
  reached <- paste(unique(c(ledger_ids, if (is.null(alias)) character(0L) else alias)),
                   collapse = ";")

  if (refused) {
    cite <- sb_refusal_cite(bridge_route)
    if (!nzchar(cite)) {
      stop("refused row without an R/julia-bridge.R line: ", name, call. = FALSE)
    }
    if (nrow(all_rec)) {
      return(list(
        verdict = "REFUSED+UPSTREAM-RECEIPT",
        tier = if (nrow(ledger_rec)) "ledgered" else "alias",
        cell = sprintf("refused by drmTMB at %s, yet DRM.jl carries %s", cite,
                       sb_receipt_text(all_rec)),
        contradiction = TRUE, reached = reached
      ))
    }
    return(list(verdict = "REFUSED", tier = "-",
                cell = sprintf("refused at %s", cite), contradiction = FALSE,
                reached = reached))
  }

  if (nrow(s7)) {
    x <- s7[1L, , drop = FALSE]
    predecessor <- if (nrow(ordinary)) {
      p <- ordinary[1L, , drop = FALSE]
      sprintf("; retained historical G4 classification at drmTMB %s: %s, %d finite profile(s), %d retained non-finite endpoint(s)",
              p$drmtmb_commit[[1L]], p$classification[[1L]], p$finite_profile_count[[1L]],
              p$nonfinite_endpoint_count[[1L]])
    } else ""
    return(list(
      verdict = "ORDINARY-LAPLACE-COVERAGE-CLASSIFIED", tier = "s7-coverage-summary",
      cell = sprintf("0.7.1 retained S7 coverage classification: %s; %d fixture(s), %d declared outer target(s), %d engine-target cells x %d paired seeds = %d attempts; %d unconditional covered, %d finite-endpoint returns, retained failures: fit=%d, profile=%d, non-finite=%d, truth-outside=%d%s (docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-coverage-summary.tsv:%d)",
                     x$classification[[1L]], x$fixture_count[[1L]], x$declared_target_count[[1L]],
                     x$engine_target_count[[1L]], x$per_target_attempt_count[[1L]],
                     x$attempt_count[[1L]], x$unconditional_covered[[1L]],
                     x$finite_endpoint_count[[1L]], x$fit_failed_count[[1L]],
                     x$profile_failed_count[[1L]], x$nonfinite_endpoint_count[[1L]],
                     x$truth_outside_count[[1L]], predecessor,
                     which(s7_summary$capability_id == x$capability_id[[1L]]) + 1L),
      contradiction = FALSE, reached = reached
    ))
  }

  if (nrow(ordinary)) {
    x <- ordinary[1L, , drop = FALSE]
    return(list(
      verdict = "ORDINARY-LAPLACE-CLASSIFIED", tier = "reconciled-summary",
      cell = sprintf("0.7.1 frozen reconciliation: %s; %d fixture(s), %d declared outer target(s), %d retained engine-target attempts; %d finite profile(s), %d retained non-finite endpoint(s), %d other terminal classification(s) (docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/reconciled-summary.tsv:%d)",
                     x$classification[[1L]], x$fixture_count[[1L]], x$declared_target_count[[1L]],
                     x$engine_target_count[[1L]], x$finite_profile_count[[1L]],
                     x$nonfinite_endpoint_count[[1L]], x$other_terminal_count[[1L]],
                     which(ordinary_summary$capability_id == x$capability_id[[1L]]) + 1L),
      contradiction = FALSE, reached = reached
    ))
  }

  if (has_pass) {
    tier <- if (any(ledger_rec$status %in% sb_pass_statuses())) "ledgered" else "alias"
    return(list(
      verdict = if (identical(tier, "ledgered")) "RECEIPT" else "RECEIPT-NOT-LEDGERED",
      tier = tier,
      cell = sb_receipt_text(if (identical(tier, "ledgered")) ledger_rec else alias_rec),
      contradiction = FALSE, reached = reached
    ))
  }

  if (nrow(all_rec)) {
    return(list(verdict = "RECEIPT-NOT-PASS",
                tier = if (nrow(ledger_rec)) "ledgered" else "alias",
                cell = sb_receipt_text(all_rec), contradiction = FALSE,
                reached = reached))
  }

  list(verdict = "UNCITED", tier = "-",
       cell = sprintf("UNCITED -- no receipt reaches this capability%s",
                      if (length(ledger_ids)) {
                        sprintf(" (ledger row(s) %s carry no receipt row at the ref)",
                                paste0("`", ledger_ids, "`", collapse = ", "))
                      } else {
                        " (its matrix `bridge_route` cites no ledger row)"
                      }),
       contradiction = FALSE, reached = reached)
}

# ---- build -----------------------------------------------------------------

sb_build <- function(env, ctx, mat, ordinary_summary, s7_summary) {
  j_label <- ctx$drmjl_label(ctx$files$j_status)
  rows <- lapply(seq_len(nrow(mat)), function(i) {
    name <- mat$capability[[i]]
    r_i <- match(name, ctx$r_status$capability)
    j_i <- match(name, ctx$j_status$capability)
    if (is.na(r_i)) stop("capability absent from drmTMB's file: ", name, call. = FALSE)

    r_status <- ctx$r_status$status[[r_i]]
    r_cell <- sprintf("%s (%s, `%s`)", sb_native_verdict(r_status),
                      env$pm_cite(ctx$files$r_status, ctx$r_status$line[[r_i]]), r_status)

    if (is.na(j_i)) {
      j_verdict <- "UNCITED"
      j_cell <- "UNCITED -- no row of this name in DRM.jl's capability-status.md"
    } else {
      j_status <- ctx$j_status$status[[j_i]]
      j_verdict <- sb_native_verdict(j_status)
      j_cell <- sprintf("%s (%s, `%s`)", j_verdict,
                        env$pm_cite(j_label, ctx$j_status$line[[j_i]]), j_status)
    }

    b <- sb_bridge_cell(env, ctx, name, mat$bridge_route[[i]], ordinary_summary, s7_summary)

    data.frame(
      capability = name,
      native_R = sb_native_verdict(r_status), native_R_cell = r_cell,
      native_Julia = j_verdict, native_Julia_cell = j_cell,
      bridge = b$verdict, bridge_tier = b$tier, bridge_cell = b$cell,
      contradiction = b$contradiction, reached_ids = b$reached,
      stringsAsFactors = FALSE
    )
  })
  sb <- do.call(rbind, rows)

  # No cell may be blank, and no cell may be blank-but-not-UNCITED: an empty
  # string is the failure this file exists to prevent.
  for (col in c("native_R_cell", "native_Julia_cell", "bridge_cell")) {
    if (any(!nzchar(trimws(sb[[col]])))) {
      stop("blank cell in ", col, call. = FALSE)
    }
  }
  # Every non-UNCITED cell must carry a citation: a file:line or a receipt id.
  cited <- function(x) grepl(":[0-9]+", x) | grepl("receipt capability_id=", x, fixed = TRUE)
  for (pair in list(c("native_R", "native_R_cell"),
                    c("native_Julia", "native_Julia_cell"),
                    c("bridge", "bridge_cell"))) {
    bad <- sb[[pair[[1L]]]] != "UNCITED" & !cited(sb[[pair[[2L]]]])
    if (any(bad)) {
      stop("uncited cell not marked UNCITED in ", pair[[1L]], ": ",
           paste(sb$capability[bad], collapse = ", "), call. = FALSE)
    }
  }
  sb
}

# ---- render ----------------------------------------------------------------

sb_count_table <- function(values, levels_order) {
  tab <- table(factor(values, levels = levels_order))
  keep <- tab > 0L
  data.frame(verdict = names(tab)[keep], n = as.integer(tab[keep]),
             stringsAsFactors = FALSE)
}

sb_render <- function(env, ctx, sb, drmtmb_sha, ordinary_summary, s7_summary) {
  n <- nrow(sb)
  uncited <- c(
    sum(sb$native_R == "UNCITED"),
    sum(sb$native_Julia == "UNCITED"),
    sum(sb$bridge == "UNCITED")
  )
  n_uncited_cells <- sum(uncited)
  n_rows_any_uncited <- sum(sb$native_R == "UNCITED" |
                              sb$native_Julia == "UNCITED" |
                              sb$bridge == "UNCITED")
  n_contra <- sum(sb$contradiction)
  n_receipt <- sum(sb$bridge == "RECEIPT")
  n_ordinary_laplace <- nrow(ordinary_summary)
  n_s7_ordinary_laplace <- sum(sb$bridge == "ORDINARY-LAPLACE-COVERAGE-CLASSIFIED")

  md <- function(x) {
    x <- gsub("\r?\n", " ", x)
    gsub("(?<!\\\\)\\|", "\\\\|", x, perl = TRUE)
  }
  name_cell <- function(x) if (grepl("`", x, fixed = TRUE)) x else paste0("`", x, "`")

  cols <- c("capability", "native_R", "native_Julia", "bridge",
            "native_R_cell", "native_Julia_cell", "bridge_cell")
  header <- paste0("| ", paste(c("capability", "native_R", "native_Julia",
                                 "bridge", "native_R evidence",
                                 "native_Julia evidence", "bridge evidence"),
                               collapse = " | "), " |")
  sep <- paste0("|", paste(rep("---", length(cols)), collapse = "|"), "|")
  body <- vapply(seq_len(n), function(i) {
    cells <- vapply(cols, function(cn) md(sb[[cn]][[i]]), character(1L))
    cells[["capability"]] <- name_cell(sb$capability[[i]])
    paste0("| ", paste(cells, collapse = " | "), " |")
  }, character(1L))

  bridge_counts <- sb_count_table(sb$bridge,
    c("RECEIPT", "ORDINARY-LAPLACE-CLASSIFIED", "ORDINARY-LAPLACE-COVERAGE-CLASSIFIED", "RECEIPT-NOT-LEDGERED", "RECEIPT-NOT-PASS",
      "REFUSED", "REFUSED+UPSTREAM-RECEIPT", "UNCITED"))
  native_r_counts <- sb_count_table(sb$native_R, c("FITS", "PARTIAL", "NO", "UNCITED"))
  native_j_counts <- sb_count_table(sb$native_Julia, c("FITS", "PARTIAL", "NO", "UNCITED"))

  uncited_rows <- sb[sb$bridge == "UNCITED", , drop = FALSE]

  reached_ids <- unique(unlist(strsplit(sb$reached_ids[nzchar(sb$reached_ids)], ";", fixed = TRUE)))
  orphan_ids <- setdiff(sb_all_receipt_ids(ctx), reached_ids)

  c(
    "# drmTMB <-> DRM.jl parity SCOREBOARD",
    "",
    "GENERATED by `tools/write-parity-scoreboard.R` -- do not edit by hand.",
    "Regenerate with `DRM_JL_PATH=<DRM.jl clone> Rscript tools/write-parity-scoreboard.R`",
    "from the drmTMB source checkout (no Julia is started).",
    "",
    "## What this file was generated against",
    "",
    "| input | sha |",
    "|---|---|",
    sprintf("| drmTMB (this repo, HEAD at generation) | `%s` |", drmtmb_sha),
    sprintf("| DRM.jl (read with `git show`, never the working tree) | `%s` |", ctx$pin),
    if (nrow(ordinary_summary)) sprintf(
      "| ordinary-Laplace reconciliation source pin | `%s` in `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/reconciled-summary.tsv` |",
      ordinary_summary$drmtmb_commit[[1L]]
    ) else "| ordinary-Laplace reconciliation source pin | no committed summary |",
    if (nrow(s7_summary)) sprintf(
      "| ordinary-Laplace S7 campaign source pin | `%s` in `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-coverage-summary.tsv` |",
      s7_summary$drmtmb_commit[[1L]]
    ) else "| ordinary-Laplace S7 campaign source pin | no committed summary |",
    "",
    "The ordinary-Laplace summary retains its own source pin, DRM.jl pin, and receipt-runner hash.",
    "It is rejected when a protected evidence input changed after that source pin; later documentation",
    "and scoreboard-compiler commits do not rewrite the retained receipt evidence. Quote both drmTMB shas",
    "whenever you quote the ordinary-Laplace counts.",
    "",
    "## THE DENOMINATOR",
    "",
    sprintf("**%d** drmTMB-native capabilities -- every `| Capability | Status |` row of", n),
    sprintf("`%s` (%d rows), each matched byte-for-byte to a row of DRM.jl's file",
            ctx$files$r_status, nrow(ctx$r_status)),
    sprintf("(%d rows).", nrow(ctx$j_status)),
    "",
    sprintf("**UNCITED cells: %d of %d** (%d capabilities x 3 axes). %d of the %d capabilities",
            n_uncited_cells, 3L * n, n, n_rows_any_uncited, n),
    "carry at least one UNCITED cell.",
    "",
    sprintf("Per axis: native_R %d UNCITED, native_Julia %d UNCITED, **bridge %d UNCITED**.",
            uncited[[1L]], uncited[[2L]], uncited[[3L]]),
    "",
    sprintf("**%d of %d** capabilities are reachable through `engine = \"julia\"` with a", n_receipt, n),
    "PASSING receipt reached through a committed ledger row (verdict `RECEIPT`).",
    "That is the number a closure may quote as bridge coverage. Every other",
    "verdict is something weaker, and is named below.",
    sprintf("**%d of %d** capability rows carry a separately classified 0.7.1 ordinary-Laplace", n_ordinary_laplace, n),
    "frozen receipt. This is not included in the generic point/SE-parity `RECEIPT` count.",
    sprintf("**%d of %d** capability rows carry a separately classified 0.7.1 retained S7", n_s7_ordinary_laplace, n),
    "profile-coverage receipt. It is a frozen-scenario evidence exception, not a general coverage or engine-equality claim.",
    "",
    if (n_contra > 0L) {
      c(sprintf("**%d CONTRADICTION(S)**: drmTMB's bridge refuses a route for which DRM.jl", n_contra),
        "already carries a receipt. Listed in full after the table.", "")
    } else {
      c("No contradictions: no capability is refused by drmTMB's bridge while DRM.jl carries a receipt for it.", "")
    },
    "## Verdict vocabulary",
    "",
    "`native_R` / `native_Julia` -- from each twin's `docs/design/capability-status.md`:",
    "`FITS` = `implemented`; `PARTIAL` = `scope-limited`, `point-fit-recovery` or",
    "`experimental`; `NO` = `rejected`, `planned` or `missing`; `UNCITED` = no row",
    "of that name in that file.",
    "",
    "`bridge` -- is the capability reachable through `engine = \"julia\"` with a receipt?",
    "",
    "| verdict | meaning |",
    "|---|---|",
    "| `RECEIPT` | a passing receipt row in a DRM.jl evidence table, reached through a committed `inst/extdata/julia-capabilities.tsv` row the matrix cites |",
    "| `ORDINARY-LAPLACE-CLASSIFIED` | a source-pinned, committed 0.7.1 four-fixture profile-classification summary reached through a ledger row; it is NOT a generic point/SE-parity receipt and NOT interval coverage |",
    "| `ORDINARY-LAPLACE-COVERAGE-CLASSIFIED` | a source-pinned, retained 500-seed-per-fixture profile-coverage classification on the named frozen scenarios; all failures remain in the unconditional denominator. It is not a generic receipt, general calibration claim, or cross-engine coverage-equality claim |",
    "| `RECEIPT-NOT-LEDGERED` | a passing receipt exists, but NO committed drmTMB ledger row connects it to this capability; the link is a declared alias in the generator |",
    "| `RECEIPT-NOT-PASS` | receipt rows exist but none passes (a negative control, or `NO_NATIVE_COMPARATOR`) |",
    "| `REFUSED` | drmTMB's bridge refuses the route -- at `drm_julia_family_tag()` for an unadmitted family, or at a named pre-Julia guard behind a registered gate -- with the line |",
    "| `REFUSED+UPSTREAM-RECEIPT` | refused by drmTMB, yet DRM.jl carries a receipt -- a contradiction, counted above |",
    "| `UNCITED` | no receipt and no cited refusal. Includes every row whose `bridge_route` only ASSERTS \"no bridge route\" with no file:line behind it |",
    "",
    "`UNCITED` is never an inference and never a blank. It is the count of cells",
    "the programme cannot point at.",
    "",
    "## Counts",
    "",
    "| axis | verdict | n |",
    "|---|---|---:|",
    sprintf("| native_R | `%s` | %d |", native_r_counts$verdict, native_r_counts$n),
    sprintf("| native_Julia | `%s` | %d |", native_j_counts$verdict, native_j_counts$n),
    sprintf("| bridge | `%s` | %d |", bridge_counts$verdict, bridge_counts$n),
    "",
    "## The scoreboard",
    "",
    header, sep, body,
    "",
    "## Every UNCITED bridge cell, with what is missing",
    "",
    if (nrow(uncited_rows)) {
      c(sprintf("%d of %d capabilities have no receipt and no cited refusal on the bridge axis:",
                nrow(uncited_rows), n),
        "",
        sprintf("- %s -- %s", vapply(uncited_rows$capability, name_cell, character(1L)),
                uncited_rows$bridge_cell))
    } else {
      "None: every capability carries a receipt or a cited refusal on the bridge axis."
    },
    "",
    "## Contradictions",
    "",
    if (n_contra > 0L) {
      contra <- sb[sb$contradiction, , drop = FALSE]
      sprintf("- %s -- %s", vapply(contra$capability, name_cell, character(1L)),
              contra$bridge_cell)
    } else {
      "None."
    },
    "",
    "## Evidence that exists and lifts nothing",
    "",
    "Receipt rows DRM.jl carries at this sha that no capability above reaches --",
    "either because no ledger row and no declared alias connects them, or because",
    "the table they live in is not joinable by `capability_id`. They are listed so",
    "the UNCITED count above cannot be read as \"no evidence exists\"; it means no",
    "evidence is CONNECTED.",
    "",
    if (length(orphan_ids)) {
      c(sprintf("`capability_id`s with receipt rows that no capability row reaches (%d):",
                length(orphan_ids)),
        "",
        sprintf("- `%s`", orphan_ids))
    } else {
      "Every receipt `capability_id` is reached by some capability row."
    },
    "",
    sprintf("`%s` is keyed by `cell_id`, carries no `capability_id`, and is therefore",
            ctx$files$j_intervals),
    "not joined at all. Its rows at this sha:",
    "",
    "| cell_id | method | status |",
    "|---|---|---|",
    sprintf("| `%s` | `%s` | `%s` |", ctx$j_receipts$intervals$cell_id,
            ctx$j_receipts$intervals$method, ctx$j_receipts$intervals$status),
    "",
    "## What this file does NOT claim",
    "",
    "- A `RECEIPT` verdict is POINT/SE parity against a native TMB fit on the cells",
    "  the receipt names. It is not interval coverage, not a claim about every cell",
    "  of the capability, and not a statement that the route is fast or robust.",
    "- `native_R` and `native_Julia` are re-projections of each twin's own status",
    "  file. When that file and the underlying cell census disagree, the census",
    "  wins and this file is wrong.",
    sprintf("- `%s` is keyed by `cell_id` and carries no `capability_id`, so it is not",
            ctx$files$j_intervals),
    "  joined here. Interval receipts therefore do not lift any cell out of",
    "  `UNCITED`.",
    "- A drmTMB capability with no row of that name in DRM.jl's file cannot appear",
    "  here at all: the shared join aborts on it. `docs/design/capability-status-join.md`",
    "  is the artefact that reports those."
  )
}

sb_write <- function(root, drmjl_path,
                     out = file.path(root, "docs", "design", "parity-scoreboard.md")) {
  env <- sb_matrix_env(root)
  ctx <- env$pm_load_context(root, drmjl_path)
  mat <- env$pm_build_matrix(ctx)
  drmtmb_sha <- sb_head_sha(root)
  s7_summary <- sb_ordinary_laplace_s7_summary(root, ctx, drmtmb_sha)
  ordinary_summary <- sb_ordinary_laplace_summary(root, ctx, drmtmb_sha,
                                                    historical = nrow(s7_summary) > 0L)
  sb <- sb_build(env, ctx, mat, ordinary_summary, s7_summary)
  lines <- sb_render(env, ctx, sb, drmtmb_sha, ordinary_summary, s7_summary)
  dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, out, useBytes = TRUE)
  message("wrote ", nrow(sb), " scoreboard rows to ", out,
          " (", sum(sb$bridge == "UNCITED"), " UNCITED on the bridge axis) at DRM.jl ",
          ctx$pin_short)
  invisible(sb)
}

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  drmjl_path <- if (length(args) >= 1L) args[[1L]] else Sys.getenv("DRM_JL_PATH", unset = "")
  if (!nzchar(drmjl_path) || !dir.exists(drmjl_path)) {
    stop("Set DRM_JL_PATH (or pass it as the first argument) to a DRM.jl clone.", call. = FALSE)
  }
  out <- if (length(args) >= 2L) args[[2L]] else file.path("docs", "design", "parity-scoreboard.md")
  sb_write(".", drmjl_path, out)
}

if (sys.nframe() == 0L) {
  main()
}
