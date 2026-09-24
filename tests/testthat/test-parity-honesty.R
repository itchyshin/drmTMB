# Fixture-row tests for `pm_honest_state()` (tools/write-parity-matrix.R,
# S1a, 2026-09-24). Every state is exercised on a small in-memory row plus
# small in-memory `defects`/`fences` data frames -- no DRModels clone is
# needed, so these run in CI and inside `devtools::test()` unconditionally.
#
# Precedence (Pre-G0 amendment A4, first match wins): DEFECT, GREEN, FENCED,
# OWNER-DECISION, CITED-PARTIAL, CITED-LIMITED, UNCITED.

ph_test_tool_path <- function() {
  # Only reachable from a source checkout (tools/ is .Rbuildignore'd), the
  # same guard test-parity-matrix.R uses for its own tool-dependent tests.
  path <- testthat::test_path("..", "..", "tools", "write-parity-matrix.R")
  if (file.exists(path)) normalizePath(path) else ""
}

ph_test_source_tool <- function(path) {
  env <- new.env(parent = globalenv())
  sys.source(path, envir = env)
  env
}

# Minimal stand-ins for inst/extdata/julia-defects.tsv and
# inst/extdata/julia-fences.tsv: `pm_honest_state()` only reads `capability`
# (both) and `status` (fences), so the fixtures carry nothing else.
ph_defects <- function(capability = character()) {
  data.frame(capability = capability, stringsAsFactors = FALSE)
}
ph_fences <- function(capability = character(), status = character()) {
  data.frame(capability = capability, status = status, stringsAsFactors = FALSE)
}

# A cited claim_boundary (the shape `pm_family_entry()`/`pm_struct_entry()`
# always produce for a joined TSV row): a file:line anchor.
ph_cited <- "see claim_boundary at inst/extdata/julia-capabilities.tsv:10."

ph_state <- function(env, capability = "X", green = FALSE, gate_ids = character(0),
                     r_bridge_status = NA_character_, boundary = "",
                     native_scope_limited = FALSE, defects = ph_defects(),
                     fences = ph_fences()) {
  env$pm_honest_state(
    capability = capability, green = green, gate_ids = gate_ids,
    r_bridge_status = r_bridge_status, boundary = boundary,
    native_scope_limited = native_scope_limited, defects = defects, fences = fences
  )
}

test_that("pm_honest_state: DEFECT when the capability is listed in julia-defects.tsv", {
  tool <- ph_test_tool_path()
  skip_if(!nzchar(tool), "tools/write-parity-matrix.R is not reachable (installed package)")
  env <- ph_test_source_tool(tool)
  expect_identical(
    ph_state(env, capability = "X", green = TRUE, defects = ph_defects("X")),
    "DEFECT"
  )
})

test_that("pm_honest_state: GREEN is the existing mechanical rule, unchanged", {
  tool <- ph_test_tool_path()
  skip_if(!nzchar(tool), "tools/write-parity-matrix.R is not reachable (installed package)")
  env <- ph_test_source_tool(tool)
  expect_identical(ph_state(env, green = TRUE), "GREEN")
})

test_that("pm_honest_state: FENCED via an ordinary gate_id join", {
  tool <- ph_test_tool_path()
  skip_if(!nzchar(tool), "tools/write-parity-matrix.R is not reachable (installed package)")
  env <- ph_test_source_tool(tool)
  expect_identical(
    ph_state(env, gate_ids = "some_gate", boundary = "gate `some_gate` (inst/extdata/julia-gates.tsv:3)."),
    "FENCED"
  )
})

test_that("pm_honest_state: FENCED via a signed julia-fences.tsv row", {
  tool <- ph_test_tool_path()
  skip_if(!nzchar(tool), "tools/write-parity-matrix.R is not reachable (installed package)")
  env <- ph_test_source_tool(tool)
  expect_identical(
    ph_state(env, r_bridge_status = "experimental", boundary = ph_cited,
             fences = ph_fences("X", "signed")),
    "FENCED"
  )
})

test_that("pm_honest_state: OWNER-DECISION via a pending-owner julia-fences.tsv row", {
  tool <- ph_test_tool_path()
  skip_if(!nzchar(tool), "tools/write-parity-matrix.R is not reachable (installed package)")
  env <- ph_test_source_tool(tool)
  expect_identical(
    ph_state(env, r_bridge_status = "partial", boundary = ph_cited,
             fences = ph_fences("X", "pending-owner")),
    "OWNER-DECISION"
  )
})

test_that("pm_honest_state: CITED-PARTIAL is r_bridge_status partial with a cited boundary (D-233)", {
  tool <- ph_test_tool_path()
  skip_if(!nzchar(tool), "tools/write-parity-matrix.R is not reachable (installed package)")
  env <- ph_test_source_tool(tool)
  expect_identical(
    ph_state(env, r_bridge_status = "partial", boundary = ph_cited),
    "CITED-PARTIAL"
  )
})

test_that("pm_honest_state: a cited supported row held below covered reads CITED-PARTIAL, and needs its citation", {
  # The #1299/#1300 family rows: bridge evidence at the stronger `supported`
  # bar, claim_status still `partial` because promotion is maintainer-only.
  tool <- ph_test_tool_path()
  skip_if(!nzchar(tool), "tools/write-parity-matrix.R is not reachable (installed package)")
  env <- ph_test_source_tool(tool)
  expect_identical(ph_state(env, r_bridge_status = "supported", boundary = ph_cited), "CITED-PARTIAL")
  expect_identical(ph_state(env, r_bridge_status = "supported", boundary = "no anchor here"), "UNCITED")
})

test_that("pm_honest_state: CITED-LIMITED via r_bridge_status experimental/unsupported with a cited boundary", {
  tool <- ph_test_tool_path()
  skip_if(!nzchar(tool), "tools/write-parity-matrix.R is not reachable (installed package)")
  env <- ph_test_source_tool(tool)
  expect_identical(ph_state(env, r_bridge_status = "experimental", boundary = ph_cited), "CITED-LIMITED")
  expect_identical(ph_state(env, r_bridge_status = "unsupported", boundary = ph_cited), "CITED-LIMITED")
})

test_that("pm_honest_state: CITED-LIMITED via a scope-limited native side alone", {
  tool <- ph_test_tool_path()
  skip_if(!nzchar(tool), "tools/write-parity-matrix.R is not reachable (installed package)")
  env <- ph_test_source_tool(tool)
  expect_identical(
    ph_state(env, r_bridge_status = "supported", boundary = ph_cited, native_scope_limited = TRUE),
    "CITED-LIMITED"
  )
})

test_that("pm_honest_state: UNCITED is the catch-all for a row matching none of the named states", {
  tool <- ph_test_tool_path()
  skip_if(!nzchar(tool), "tools/write-parity-matrix.R is not reachable (installed package)")
  env <- ph_test_source_tool(tool)
  # An unledgered row (no r_bridge_status) with no citation, no gate, no fence
  # and no defect matches no named state. (A cited `supported` row is NOT this
  # case: it reads CITED-PARTIAL, tested above.)
  expect_identical(ph_state(env, r_bridge_status = NA_character_, boundary = ""), "UNCITED")
  expect_identical(ph_state(env, r_bridge_status = NA_character_, boundary = ph_cited), "UNCITED")
})

test_that("pm_honest_state precedence: a gated row that is also partial reads FENCED, not CITED-PARTIAL", {
  tool <- ph_test_tool_path()
  skip_if(!nzchar(tool), "tools/write-parity-matrix.R is not reachable (installed package)")
  env <- ph_test_source_tool(tool)
  expect_identical(
    ph_state(env, gate_ids = "some_gate", r_bridge_status = "partial",
             boundary = "gate `some_gate` (inst/extdata/julia-gates.tsv:3)."),
    "FENCED"
  )
})

test_that("pm_honest_state precedence: a defect row that would be GREEN reads DEFECT, not GREEN", {
  tool <- ph_test_tool_path()
  skip_if(!nzchar(tool), "tools/write-parity-matrix.R is not reachable (installed package)")
  env <- ph_test_source_tool(tool)
  expect_identical(
    ph_state(env, green = TRUE, defects = ph_defects("X")),
    "DEFECT"
  )
})

test_that("pm_honest_state RED CONTROL: dropping the boundary's citation changes the state", {
  tool <- ph_test_tool_path()
  skip_if(!nzchar(tool), "tools/write-parity-matrix.R is not reachable (installed package)")
  env <- ph_test_source_tool(tool)
  cited <- ph_state(env, r_bridge_status = "partial", boundary = ph_cited)
  expect_identical(cited, "CITED-PARTIAL")
  uncited <- ph_state(env, r_bridge_status = "partial", boundary = "no citation here at all")
  expect_identical(uncited, "UNCITED")
  expect_false(identical(cited, uncited))
})
