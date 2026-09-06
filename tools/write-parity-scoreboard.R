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
#   REFUSED             the matrix says the bridge REFUSES the route at
#                       drm_julia_family_tag(). A refusal is a determination
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
  list(
    `Cumulative logit (ordinal)` = "fe_cumulative_logit",
    `Skew-normal location-scale` = "fe_skew_normal",
    `Tweedie (compound Poisson-Gamma)` = "fe_tweedie",
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

sb_is_refused <- function(bridge_route) {
  grepl("REFUSED at drm_julia_family_tag\\(\\)", bridge_route, perl = TRUE)
}

# The `R/julia-bridge.R:<line>` the matrix gives for a refusal, so a REFUSED
# cell carries a file:line of its own rather than borrowing the matrix's prose.
sb_refusal_cite <- function(bridge_route) {
  m <- regmatches(bridge_route,
                  regexpr("R/julia-bridge\\.R:[0-9]+", bridge_route, perl = TRUE))
  if (!length(m) || !nzchar(m)) "" else m
}

sb_bridge_cell <- function(env, ctx, name, bridge_route) {
  ledger_ids <- sb_cited_tsv_ids(ctx, bridge_route)
  ledger_rec <- sb_receipts(env, ctx, ledger_ids)

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

sb_build <- function(env, ctx, mat) {
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

    b <- sb_bridge_cell(env, ctx, name, mat$bridge_route[[i]])

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

sb_render <- function(env, ctx, sb, drmtmb_sha) {
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
    c("RECEIPT", "RECEIPT-NOT-LEDGERED", "RECEIPT-NOT-PASS",
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
    "",
    "Both numbers below and every citation in the table are functions of those",
    "two commits and nothing else. Quote the shas whenever you quote the counts.",
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
    "| `RECEIPT-NOT-LEDGERED` | a passing receipt exists, but NO committed drmTMB ledger row connects it to this capability; the link is a declared alias in the generator |",
    "| `RECEIPT-NOT-PASS` | receipt rows exist but none passes (a negative control, or `NO_NATIVE_COMPARATOR`) |",
    "| `REFUSED` | drmTMB's bridge refuses the route at `drm_julia_family_tag()`, with the line |",
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
  sb <- sb_build(env, ctx, mat)
  lines <- sb_render(env, ctx, sb, sb_head_sha(root))
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
