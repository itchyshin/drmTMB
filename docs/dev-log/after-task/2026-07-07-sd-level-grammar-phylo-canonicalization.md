# After Task: `sd(..., level = "phylogenetic")` Grammar (Slice S2)

> **LANDING CORRECTION (Ada, 2026-07-07).** Gauss authored this report inside a worktree that
> `isolation:"worktree"` accidentally branched from a commit **predating the REML arc** (see §3),
> so all "REML-**rejection** parity" wording below reflects that stale base. On the actual landing
> branch `drmtmb/biv-scale-side-reml`, the phylogenetic direct-SD scale `sd_phylo(...) ~ predictors`
> **IS admitted under REML** (rung 2, v0.2.0). When integrating S2 onto the branch, the grammar
> diff (parser canonicalization, deprecation, DESCRIPTION `lifecycle`, NAMESPACE, docs) applied
> cleanly — the grammar files were byte-identical between the two bases — and the end-to-end
> tripwire was **strengthened from REML-rejection-parity to REML-ADMISSION-equivalence**: the new
> `sd(species, level="phylogenetic") ~ z` spelling fits BYTE-IDENTICALLY to legacy `sd_phylo()`
> under `REML = TRUE` (identical `summary()`/`vcov()`). Existing legacy-spelling REML tests were
> wrapped in `suppressWarnings()` (the deprecation is now live). Final suite on the branch:
> sd-level 32, reml 104, parse 72 — all PASS, 0 FAIL, 0 WARN.

## 1. Goal

Retire `sd_phylo()` / `sd_phylo1()` / `sd_phylo2()` as the only spelling for
phylogenetic direct-SD targets, in favour of a unified `sd(group, level = )`
grammar (`docs/design/01-formula-grammar.md:672-703`), while keeping the
legacy spellings as soft-deprecated working aliases and leaving every
downstream string-keyed branch in `R/drmTMB.R` untouched.

## 2. Implemented

`sd(group, level = "phylogenetic")`, `sd1(group, level = "phylogenetic")`,
and `sd2(group, level = "phylogenetic")` now parse to the byte-identical
`sd_phylo(group)` / `sd_phylo1(group)` / `sd_phylo2(group)` dpar strings the
legacy spellings already emit, so `startsWith(dpars, "sd_phylo(")` and its
`sd_phylo1(`/`sd_phylo2(` siblings in `R/drmTMB.R` (~2485, ~6078) keep
working unmodified. `level` is consumed and validated entirely inside
`parse_sd_lhs()`/`canonicalize_sd_lhs_fun()` and never leaks into the dpar
string. `level = "spatial"`/`"animal"`/`"relmat"` are recognised and rejected
as not-yet-implemented (mirroring the existing `sd_spatial*()` and
`corpair(level = )` not-implemented aborts). `level` on an already
`sd_phylo*()` spelling is rejected as redundant. Parsing a legacy
`sd_phylo*()` spelling fires `lifecycle::deprecate_warn("0.3.0", ...)` once
per session (lifecycle's default throttle), which also satisfies "must not
fire on every re-parse during a single fit" since `parse_sd_lhs()` is called
many times per fit (`R/drmTMB.R:10265,10358,10431,10496,11072` and the
`vapply`/`lapply` call sites around 6404-6429, 11063).

## 3. Decisions and Deviations

- **`lifecycle::deprecate_warn()`'s `with` argument must stay single-argument
  style.** The task brief's literal example,
  `lifecycle::deprecate_warn("0.3.0", "sd_phylo()", 'sd(level = "phylogenetic")')`,
  is exactly right; a `with` string carrying two named arguments (I initially
  tried `'sd(group, level = "phylogenetic")'`) makes `lifecycle::spec()` try
  to introspect a real R function bound to the name and error
  (`"Function in `what` (sd) must have 1 argument, not 2."`). The one-argument
  form triggers lifecycle's built-in "argument rename" message style
  ("Please use the `level` argument of `sd()` instead."), which is exactly
  the desired user-facing text.
- **No `\lifecycle{deprecated}` Rd badge.** The task brief asked for one, but
  this package has no `usethis::use_lifecycle()` scaffolding
  (`man-roxygen/lifecycle-*.Rd`), so the raw macro would break Rd rendering.
  Followed the package's existing plain-prose deprecation-doc convention
  instead (see `meta_known_V()` in `R/formula-markers.R:47-74`) — a
  "Deprecated spellings" note in the `random_effect_scale_formulas` help page
  and a code comment above `warn_sd_phylo_legacy_deprecated()`.
- **Branch/worktree mismatch discovered mid-task (see §9).** The brief
  assumed this worktree tracks `drmtmb/biv-scale-side-reml` (REML-for-
  direct-SD-scale work, `tests/testthat/test-reml-direct-sd-phylo.R`). It
  does not: `git branch --show-current` here is
  `worktree-agent-ab6aa6ad75dbee7f0` at `6c89feaa` (PR #738 merge), and
  `test-reml-direct-sd-phylo.R` does not exist in this history.
  `drm_validate_reml_spec()` on this branch unconditionally rejects
  `sd_phylo`/`sd` direct random-effect scale formulae under `REML = TRUE`
  (`R/drmTMB.R:1960-1968`). The end-to-end equivalence test was adapted
  accordingly (see §5); this is a deviation forced by the environment, not a
  design choice.

## 4. Files Touched

- `R/parse-formula.R` — `parse_sd_lhs()` accepts `level` as a third optional
  arg name (`:376`); new `canonicalize_sd_lhs_fun()` helper maps
  `sd`/`sd1`/`sd2` + `level = "phylogenetic"` to `sd_phylo`/`sd_phylo1`/
  `sd_phylo2`, validates/rejects other `level` values, and fires the legacy
  deprecation. `format_sd_lhs_dpar()` call unchanged in shape, now always
  receives the canonical fun.
- `R/random-effect-scale-formulas.R` — doc page updated to lead with the
  generic `level = "phylogenetic"` spelling and describe the legacy
  spellings as deprecated (soft); new `warn_sd_phylo_legacy_deprecated()`.
- `R/drmTMB-package.R` — `@importFrom lifecycle deprecate_warn`.
- `DESCRIPTION` — `lifecycle` added to `Imports`.
- `tests/testthat/test-sd-level-grammar.R` — new file (parser equivalence,
  error cases, deprecation, end-to-end fit equivalence, REML-rejection
  parity).
- `docs/design/01-formula-grammar.md:673-690` — updated from "planned" to
  "implemented for phylogenetic; reserved for spatial/animal/relmat".

## 5. Checks Run

- `devtools::document()` — clean, `NAMESPACE` gained
  `importFrom(lifecycle,deprecate_warn)`; `devtools::check_man()` — no
  warnings.
- `testthat::test_file("tests/testthat/test-sd-level-grammar.R")` —
  **30/30 PASS, 0 FAIL**.
- `testthat::test_dir(filter = "reml")` — **all pass** (rung-1/rung-2 REML
  tests present on this branch: `reml-bias-simulation`, `reml-bivariate`,
  `reml-heteroscedastic`, `reml-penalty-guard`, `reml-phylo-location`,
  `julia-sigma-phylo-reml`); one pre-existing Julia-engine skip, unrelated.
- `testthat::test_dir(filter = "parse")` — **all pass**
  (`parse-formula`, `sparse-fixed-effects`).
- `testthat::test_dir(filter = "phylo|sd-level|check-drm|control|biv-gaussian|corpairs")`
  — **0 FAIL** across ~35 files including every existing `sd_phylo`/
  `sd_phylo1`/`sd_phylo2` consumer (`test-check-drm.R`, `test-control.R`,
  `test-phylo-gaussian.R`, `test-biv-gaussian.R`). Three tests in that sweep
  now surface the new deprecation warning (they use legacy spellings
  directly) — expected, not a failure.
- Grepped every remaining `$fun` consumer of `parse_sd_lhs()`'s return value
  in `R/drmTMB.R` (`:10359,10432,10444,10455-10456,10497,10503,11076`) and
  confirmed each compares against the canonical name only, so they are
  unaffected by either spelling.

## 6. Tests of the Tests

- The end-to-end equivalence test fits the same simulated phylo dataset
  twice — once with `sd(species, level = "phylogenetic") ~ z_species`, once
  with `sd_phylo(species) ~ z_species` — and asserts `summary()` (call field
  excluded), `vcov()`, `coef(fit, "mu")`, and
  `coef(fit, "sd_phylo(species)")` are exactly equal, not just close. This
  fails loudly if canonicalization ever drifts (e.g. if `level` leaked into
  the dpar string, the two fits would produce differently-named coefficient
  rows and `vcov()` dimnames would already diverge before any numeric
  comparison).
- The REML-rejection-parity test confirms the new and legacy spellings hit
  the *identical* rejection message under `REML = TRUE` on this branch,
  rather than silently skipping the REML path.
- `reset_lifecycle_deprecation_cache()` clears `lifecycle`'s internal
  per-session dedup environment before each `expect_deprecated()` check, so
  the deprecation tests are hermetic regardless of whether earlier test
  files in a full-suite run already tripped the same warning.

## 7. Issue Ledger

No GitHub issue; tracked via this after-task report only (slice S2 of the
"structured q-space" REML arc, per the launching brief).

## 8. Consistency Audit

The invariant the brief called out as load-bearing —
`startsWith(dpars, "sd_phylo(")` / `"sd_phylo1("` / `"sd_phylo2("` in
`R/drmTMB.R` — was not touched, and the dpar-string byte-identity was
verified both by direct string assertion (`f_new$entries[[1]]$dpar ==
"sd_phylo(sp)"` etc.) and by the end-to-end fit producing identically-named
`vcov()`/`coef()` rows.

## 9. What Did Not Go Smoothly

- **Worktree/branch mismatch (see §3).** The brief's file:line citations for
  the design doc matched this worktree, but the REML-arc test file and the
  REML capability it described did not exist here. Diagnosed via
  `git branch --show-current`, `git merge-base`, and `git worktree list`
  rather than assuming the brief was correct; adapted the end-to-end test to
  what this branch actually supports (ML fit equivalence + REML-rejection
  parity) instead of silently dropping the tripwire or fabricating REML
  support.
- **`lifecycle::deprecate_warn()`'s `with` argument syntax.** Passing a
  two-argument call string as `with` produces an opaque internal error from
  `lifecycle:::spec()` (see §3); resolved by using the exact single-argument
  form from the brief's own example.

## 10. Known Residuals

- The generic `level = "spatial"` / `"animal"` / `"relmat"` grammar is
  parsed and validated (rejects as not-yet-implemented) but has no fitted
  path, matching the design doc's stated scope for this slice.
- This worktree's branch does not carry the `drmtmb/biv-scale-side-reml`
  REML-for-direct-SD-scale work; the end-to-end REML equivalence test
  documents the current (rejecting) behaviour rather than the eventual fitted
  behaviour once that arc lands here. Re-running
  `tests/testthat/test-sd-level-grammar.R`'s REML test after a merge from
  that branch should be revisited — it may need to switch from asserting
  parity of the rejection message to asserting parity of fitted coefficients.

## 11. Team Learning

- When a task brief cites a specific test file by path, verify it exists in
  the actual worktree before relying on its fixtures — `git branch
  --show-current` + `git merge-base HEAD <cited-commit>` is a fast way to
  detect a stale/mismatched worktree.
- `lifecycle::deprecate_warn()`'s `with` argument has two distinct behaviours
  keyed on argument count in the call string (whole-function replacement vs.
  argument-rename shorthand); always test the exact literal call from a
  design brief in isolation before wiring it into package code.
