# Contract for the interval-cellmap join (S1b, 2026-09-24;
# LOOP/lanes/arc1-honest-ledger/ultra-plan.md amendment A8; T11).
#
# `inst/extdata/julia-interval-cellmap.tsv` maps a DRModels interval `cell_id`
# to a drmTMB `capability_id`, so `docs/dev-log/evidence/parity-intervals.tsv`
# (keyed by `cell_id`, no `capability_id` column at this pin) can be joined to
# the scoreboard and the matrix WITHOUT the two generators re-deriving the
# join independently and risking disagreement (A8: "cannot disagree on these
# rows"). `tools/write-parity-matrix.R`'s `pm_cellmap_method_evidence()` and
# `pm_method_row()` compute the matrix side; `tools/write-parity-scoreboard.R`'s
# `sb_bridge_cell()` reads the SAME cellmap for "Profile-likelihood CIs" and
# "Parametric bootstrap CIs" (T11, Shinichi 2026-09-24). The tests below cover
# both with small in-memory fixtures -- no DRModels clone needed -- plus one
# live end-to-end check gated on DRM_JL_PATH.
#
# Adapted from the capability_id join design in the unmerged Codex branch
# codex/parity-scoreboard-join (f27c9a78a, 470bb7f29): that branch assumed
# DRM.jl's own parity-intervals.tsv would grow a `capability_id` column and
# tested the join directly on it. At this pin it has not, so these tests
# exercise drmTMB's own cellmap instead.

sb_test_tool_root <- function() {
  # Only reachable from a source checkout (tools/ is .Rbuildignore'd).
  path <- testthat::test_path("..", "..", "tools", "write-parity-matrix.R")
  if (file.exists(path)) normalizePath(testthat::test_path("..", "..")) else ""
}

# Both generator files, sys.source()d into ONE environment -- sb_bridge_cell()
# (write-parity-scoreboard.R) and pm_cellmap_method_evidence()/pm_cite()
# (write-parity-matrix.R) need to be reachable together, and
# write-parity-scoreboard.R only loads write-parity-matrix.R inside
# sb_matrix_env(), which is not called merely by sourcing the file.
sb_test_env <- function(root) {
  env <- new.env(parent = globalenv())
  sys.source(file.path(root, "tools", "write-parity-matrix.R"), envir = env)
  sys.source(file.path(root, "tools", "write-parity-scoreboard.R"), envir = env)
  env
}

# pm_load_context() refuses a DRModels checkout that is not at the programme
# pin (tools/parity-pin.R). A developer's everyday clone is usually NOT at the
# pin, so the at-pin tests SKIP on a mismatch -- naming both shas -- instead
# of erroring inside the generator.
sb_test_skip_unless_at_pin <- function(env, root, drmjl) {
  pin_env <- env$pm_pin_env(root)
  pin <- pin_env$pp_pin(root)
  head <- tryCatch(pin_env$pp_git_rev_parse(drmjl), error = function(e) NA_character_)
  if (!identical(head, pin)) {
    skip(sprintf("DRModels checkout at %s is on %s, not the programme pin %s", drmjl, head, pin))
  }
  invisible(pin)
}

# A minimal fixture `ctx`: just enough for pm_cellmap_method_evidence() and
# sb_bridge_cell() to run without pm_load_context()'s real files, package
# load, or DRModels clone. `cellmap_rows` and `interval_rows` are data.frames
# shaped like the real TSVs (pm_read_tsv() appends a 1-based `line`).
sb_test_ctx <- function(cellmap_rows, interval_rows) {
  drmjl_label <- function(path) sprintf("DRM.jl@testsha:%s", path)
  list(
    files = list(
      tsv = "inst/extdata/julia-capabilities.tsv",
      cellmap = "inst/extdata/julia-interval-cellmap.tsv",
      j_intervals = "docs/dev-log/evidence/parity-intervals.tsv"
    ),
    drmjl_label = drmjl_label,
    tsv = data.frame(capability_id = character(0), line = integer(0), stringsAsFactors = FALSE),
    cellmap = cellmap_rows,
    j_receipts = list(intervals = interval_rows)
  )
}

# Two MAPPED, non-convention cells, each with a passing profile receipt and a
# by-design-mismatching bootstrap receipt -- the shape every real cell at the
# da8b3f871 pin has today.
sb_test_two_cell_fixture <- function() {
  cellmap <- data.frame(
    cell_id = c("fam_a", "fam_b"), capability_id = c("cap_a", "cap_b"),
    status = c("MAPPED", "MAPPED"), convention = c("FALSE", "FALSE"),
    line = c(2L, 3L), stringsAsFactors = FALSE
  )
  intervals <- data.frame(
    cell_id = rep(c("fam_a", "fam_b"), each = 3L),
    method = rep(c("wald", "profile", "bootstrap"), times = 2L),
    status = rep(c("INTERVAL_PASS", "INTERVAL_PASS", "INTERVAL_MISMATCH"), times = 2L),
    line = 2:7, stringsAsFactors = FALSE
  )
  sb_test_ctx(cellmap, intervals)
}

# The red control: a cellmap with no MAPPED, non-convention row at all (a
# convention-flagged row and an UNMAPPED row, neither eligible).
sb_test_zero_eligible_fixture <- function() {
  cellmap <- data.frame(
    cell_id = c("rho12_cell", "gauss_mean_only"), capability_id = c("cap_c", ""),
    status = c("MAPPED", "UNMAPPED"), convention = c("TRUE", "FALSE"),
    line = c(2L, 3L), stringsAsFactors = FALSE
  )
  intervals <- data.frame(
    cell_id = c("rho12_cell", "rho12_cell"), method = c("profile", "bootstrap"),
    status = c("INTERVAL_PASS", "INTERVAL_MISMATCH"), line = c(2L, 3L),
    stringsAsFactors = FALSE
  )
  sb_test_ctx(cellmap, intervals)
}

# ---- D6 (Noether review item 5, follow-up slice, 2026-09-24) --------------
#
# The scoreboard and the matrix must agree: a capability the matrix reads as
# FENCED (a SIGNED `inst/extdata/julia-fences.tsv` row) or OWNER-DECISION (a
# PENDING-OWNER row) may never read UNCITED on the scoreboard's bridge axis.
# `sb_fence_verdict()` reads `ctx$fences` -- populated by `pm_load_context()`,
# the SAME committed file `pm_honest_state()` reads for the matrix -- as a
# FALLBACK ahead of the final UNCITED return, never as an override: a name
# that already resolves to REFUSED, RECEIPT, or RECEIPT-NOT-PASS keeps that
# verdict even when it also appears in the fence file.

sb_test_fences_ctx <- function(fences_rows) {
  ctx <- sb_test_ctx(
    cellmap_rows = data.frame(cell_id = character(0), capability_id = character(0),
                              status = character(0), convention = character(0),
                              line = integer(0), stringsAsFactors = FALSE),
    interval_rows = data.frame(cell_id = character(0), method = character(0),
                               status = character(0), line = integer(0),
                               stringsAsFactors = FALSE)
  )
  ctx$files$fences <- "inst/extdata/julia-fences.tsv"
  ctx$fences <- fences_rows
  ctx
}

sb_test_fences_rows <- function() {
  data.frame(
    capability = c("Fam Signed Row", "Fam Pending Row"),
    status = c("signed", "pending-owner"),
    decision = c("Signed scope decision, out of bounds for now.", "Ticket pending Shinichi's answer."),
    ticket = c("", "T9"), owner = c("", "Shinichi"),
    line = c(2L, 3L), stringsAsFactors = FALSE
  )
}

test_that("pm_cellmap_method_evidence: a MAPPED, non-convention cell with a matching receipt is eligible", {
  root <- sb_test_tool_root()
  skip_if(!nzchar(root), "tools/ is not reachable (installed package)")
  env <- sb_test_env(root)
  ctx <- sb_test_two_cell_fixture()

  profile_ev <- env$pm_cellmap_method_evidence(ctx, "profile")
  expect_identical(nrow(profile_ev), 2L)
  expect_setequal(profile_ev$capability_id, c("cap_a", "cap_b"))
  expect_true(all(profile_ev$receipt_status == "INTERVAL_PASS"))

  bootstrap_ev <- env$pm_cellmap_method_evidence(ctx, "bootstrap")
  expect_identical(nrow(bootstrap_ev), 2L)
  expect_true(all(bootstrap_ev$receipt_status == "INTERVAL_MISMATCH"))
})

test_that("pm_cellmap_method_evidence RED CONTROL: a convention cell and an UNMAPPED cell are never eligible", {
  root <- sb_test_tool_root()
  skip_if(!nzchar(root), "tools/ is not reachable (installed package)")
  env <- sb_test_env(root)
  ctx <- sb_test_zero_eligible_fixture()

  expect_identical(nrow(env$pm_cellmap_method_evidence(ctx, "profile")), 0L)
  expect_identical(nrow(env$pm_cellmap_method_evidence(ctx, "bootstrap")), 0L)
})

test_that("pm_method_row: CITED-LIMITED-eligible boundary when at least one cell is eligible, citing the cellmap and the receipt", {
  root <- sb_test_tool_root()
  skip_if(!nzchar(root), "tools/ is not reachable (installed package)")
  env <- sb_test_env(root)
  ctx <- sb_test_two_cell_fixture()

  entry <- env$pm_method_row(ctx, "Profile-likelihood CIs", "profile", route_note = "route note")
  expect_identical(entry$r_bridge_status_raw, "experimental")
  expect_true(env$pm_is_cited(entry$boundary))
  expect_true(grepl("cap_a", entry$boundary, fixed = TRUE))
  expect_true(grepl("julia-interval-cellmap.tsv:2", entry$boundary, fixed = TRUE))
})

test_that("pm_method_row RED CONTROL: zero eligible cells stays UNCITED (no r_bridge_status_raw set)", {
  root <- sb_test_tool_root()
  skip_if(!nzchar(root), "tools/ is not reachable (installed package)")
  env <- sb_test_env(root)
  ctx <- sb_test_zero_eligible_fixture()

  entry <- env$pm_method_row(ctx, "Profile-likelihood CIs", "profile", route_note = "route note")
  expect_true(is.na(entry$r_bridge_status_raw))
  expect_true(grepl("UNCITED BY DESIGN", entry$boundary, fixed = TRUE))
})

test_that("sb_bridge_cell: the two generic method rows are NOT UNCITED when the cellmap has eligible cells", {
  root <- sb_test_tool_root()
  skip_if(!nzchar(root), "tools/ is not reachable (installed package)")
  env <- sb_test_env(root)
  ctx <- sb_test_two_cell_fixture()

  profile <- env$sb_bridge_cell(env, ctx, "Profile-likelihood CIs", "route note, no ledger citation")
  expect_identical(profile$verdict, "RECEIPT-NOT-LEDGERED")
  expect_false(profile$contradiction)

  bootstrap <- env$sb_bridge_cell(env, ctx, "Parametric bootstrap CIs", "route note, no ledger citation")
  # Every eligible cell's bootstrap receipt is INTERVAL_MISMATCH BY DESIGN
  # (independent resamples), so evidence is CONNECTED but none of it passes.
  expect_identical(bootstrap$verdict, "RECEIPT-NOT-PASS")
  expect_false(bootstrap$contradiction)
})

test_that("sb_bridge_cell RED CONTROL: the two generic method rows read UNCITED when the cellmap has zero eligible cells", {
  root <- sb_test_tool_root()
  skip_if(!nzchar(root), "tools/ is not reachable (installed package)")
  env <- sb_test_env(root)
  ctx <- sb_test_zero_eligible_fixture()

  profile <- env$sb_bridge_cell(env, ctx, "Profile-likelihood CIs", "route note, no ledger citation")
  expect_identical(profile$verdict, "UNCITED")

  bootstrap <- env$sb_bridge_cell(env, ctx, "Parametric bootstrap CIs", "route note, no ledger citation")
  expect_identical(bootstrap$verdict, "UNCITED")
})

test_that("an ordinary capability row's cellmap-joined interval receipt is folded into sb_receipts()", {
  root <- sb_test_tool_root()
  skip_if(!nzchar(root), "tools/ is not reachable (installed package)")
  env <- sb_test_env(root)
  ctx <- sb_test_two_cell_fixture()

  rec <- env$sb_receipts(env, ctx, "cap_a")
  expect_true(nrow(rec) >= 1L)
  expect_true("cap_a" %in% rec$id)
  expect_true(any(grepl("cellmap-joined", rec$label, fixed = TRUE)))
})

test_that("sb_bridge_cell: a SIGNED fence row reads FENCED, citing the decision and file:line, when otherwise UNCITED (D6)", {
  root <- sb_test_tool_root()
  skip_if(!nzchar(root), "tools/ is not reachable (installed package)")
  env <- sb_test_env(root)
  ctx <- sb_test_fences_ctx(sb_test_fences_rows())

  cell <- env$sb_bridge_cell(env, ctx, "Fam Signed Row", "route note, no ledger citation")
  expect_identical(cell$verdict, "FENCED")
  expect_true(grepl("julia-fences.tsv:2", cell$cell, fixed = TRUE))
  expect_true(grepl("Signed scope decision, out of bounds for now.", cell$cell, fixed = TRUE))
})

test_that("sb_bridge_cell: a PENDING-OWNER fence row reads OWNER-DECISION, citing ticket and owner, when otherwise UNCITED (D6)", {
  root <- sb_test_tool_root()
  skip_if(!nzchar(root), "tools/ is not reachable (installed package)")
  env <- sb_test_env(root)
  ctx <- sb_test_fences_ctx(sb_test_fences_rows())

  cell <- env$sb_bridge_cell(env, ctx, "Fam Pending Row", "route note, no ledger citation")
  expect_identical(cell$verdict, "OWNER-DECISION")
  expect_true(grepl("julia-fences.tsv:3", cell$cell, fixed = TRUE))
  expect_true(grepl("T9", cell$cell, fixed = TRUE))
  expect_true(grepl("Shinichi", cell$cell, fixed = TRUE))
})

test_that("sb_bridge_cell RED CONTROL: a row absent from the fence file still reads UNCITED (D6)", {
  root <- sb_test_tool_root()
  skip_if(!nzchar(root), "tools/ is not reachable (installed package)")
  env <- sb_test_env(root)
  ctx <- sb_test_fences_ctx(sb_test_fences_rows())

  cell <- env$sb_bridge_cell(env, ctx, "Not In The Fence File", "route note, no ledger citation")
  expect_identical(cell$verdict, "UNCITED")
})

test_that("sb_bridge_cell: a fence-file row is a FALLBACK, never an override, of an existing RECEIPT verdict (D6)", {
  root <- sb_test_tool_root()
  skip_if(!nzchar(root), "tools/ is not reachable (installed package)")
  env <- sb_test_env(root)
  ctx <- sb_test_two_cell_fixture()
  ctx$files$fences <- "inst/extdata/julia-fences.tsv"
  # A fence entry under the SAME name a passing cellmap receipt already
  # resolves through pm_method_row()'s "Profile-likelihood CIs" join: if the
  # fence check ran BEFORE the receipt check, this decision would wrongly
  # replace real evidence with a generic ticket.
  ctx$fences <- data.frame(
    capability = "Profile-likelihood CIs", status = "pending-owner",
    decision = "should never be reached", ticket = "T99", owner = "Nobody",
    line = 9L, stringsAsFactors = FALSE
  )

  cell <- env$sb_bridge_cell(env, ctx, "Profile-likelihood CIs", "route note, no ledger citation")
  expect_identical(cell$verdict, "RECEIPT-NOT-LEDGERED")
  expect_false(grepl("T99", cell$cell, fixed = TRUE))
})

test_that("interval receipts join family-specific capabilities end to end at the pin", {
  drmjl <- Sys.getenv("DRM_JL_PATH", unset = "")
  skip_if(!nzchar(drmjl) || !dir.exists(drmjl), "DRM_JL_PATH must name the DRModels checkout at the pin")
  root <- sb_test_tool_root()
  skip_if(!nzchar(root), "tools/ is not reachable (installed package)")
  env <- sb_test_env(root)
  sb_test_skip_unless_at_pin(env, root, drmjl)
  ctx <- env$pm_load_context(root, drmjl)

  expect_true(all(c("cell_id", "capability_id", "status", "convention") %in% names(ctx$cellmap)))
  mapped <- ctx$cellmap[ctx$cellmap$status == "MAPPED", , drop = FALSE]
  expect_true(nrow(mapped) > 0L)
  expect_true("gauss_mean_only" %in% ctx$cellmap$cell_id[ctx$cellmap$status == "UNMAPPED"])

  mat <- env$pm_build_matrix(ctx)
  sb <- env$sb_build(env, ctx, mat)
  generic <- sb[sb$capability %in% c("Profile-likelihood CIs", "Parametric bootstrap CIs"), , drop = FALSE]
  expect_identical(nrow(generic), 2L)
  # A8: the matrix and the scoreboard read the SAME cellmap, so neither may
  # report these two rows as having no connected evidence when the other
  # does.
  matrix_state <- mat$honest_state[mat$capability %in% c("Profile-likelihood CIs", "Parametric bootstrap CIs")]
  expect_true(all(matrix_state == "CITED-LIMITED"))
  expect_false(any(generic$bridge == "UNCITED"))
})

test_that("D6 at the pin: fence-file rows the matrix reads FENCED/OWNER-DECISION are not UNCITED on the scoreboard", {
  drmjl <- Sys.getenv("DRM_JL_PATH", unset = "")
  skip_if(!nzchar(drmjl) || !dir.exists(drmjl), "DRM_JL_PATH must name the DRModels checkout at the pin")
  root <- sb_test_tool_root()
  skip_if(!nzchar(root), "tools/ is not reachable (installed package)")
  env <- sb_test_env(root)
  sb_test_skip_unless_at_pin(env, root, drmjl)
  ctx <- env$pm_load_context(root, drmjl)
  mat <- env$pm_build_matrix(ctx)
  sb <- env$sb_build(env, ctx, mat)

  fenced_or_owner <- mat$capability[mat$honest_state %in% c("FENCED", "OWNER-DECISION")]
  # The known D6 targets (Noether review item 5, follow-up slice): every one
  # of these is FENCED or OWNER-DECISION on the matrix via a julia-fences.tsv
  # row, and every one used to read UNCITED on the scoreboard.
  targets <- c("Cross-family bivariate (different families for y1 y2)",
               "Missing-predictor imputation (mi())",
               "R to Julia bridge (engine=julia)",
               "AGHQ adaptive-quadrature marginal estimator",
               "Variational (VA/ELBO) marginal estimator")
  expect_true(all(targets %in% fenced_or_owner))
  sb_targets <- sb[sb$capability %in% targets, , drop = FALSE]
  expect_identical(nrow(sb_targets), length(targets))
  expect_false(any(sb_targets$bridge == "UNCITED"))
  expect_true(all(sb_targets$bridge %in% c("FENCED", "OWNER-DECISION")))

  # A row already correct via evidence (a real receipt or a named pre-Julia
  # refusal) keeps that reading even though it ALSO appears in the fence
  # file: the fence check is a fallback, never an override.
  unaffected <- c(`Model comparison suite (LRT/anova/AICc/weights/update)` = "RECEIPT",
                  `Heritability/repeatability/ICC accessors` = "REFUSED",
                  `Gaussian phylogenetic random intercept + slope, two SDs (mean)` = "REFUSED")
  for (nm in names(unaffected)) {
    expect_identical(sb$bridge[sb$capability == nm], unname(unaffected[[nm]]))
  }

  # The one row the coordinator named as a LEGITIMATE remaining disagreement:
  # "Non-Gaussian phylogenetic location-scale (mu + log sigma)" is
  # CITED-LIMITED on the matrix through its native-side scope note alone (no
  # julia-fences.tsv row, no bridge evidence). The bridge does NOT refuse this
  # route: the coupled mu + sigma phylo shape is ADMITTED for nbinom2, gamma
  # and beta with no ledger row (Arc 1 part 2 ledgers or gates it). The
  # scoreboard's UNCITED is the honest reading, not papered over.
  residual <- "Non-Gaussian phylogenetic location-scale (μ + log σ)"
  expect_false(residual %in% ctx$fences$capability)
  expect_identical(sb$bridge[sb$capability == residual], "UNCITED")
})

cat("SCOREBOARD_CELLMAP_CONTRACT_PASS\n")
