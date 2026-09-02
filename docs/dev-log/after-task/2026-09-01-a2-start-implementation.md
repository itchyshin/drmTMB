# 2026-09-01 — GREEN implementation of the public start contract (`claude/rev-parity-a2-start-impl`)

## What this is

Implements `drm_control(start = list(...))` per the "Public Start Contract
(DECIDED 2026-09-01)" section of
`docs/design/35-optimizer-start-map-multistart.md`, to make
`tests/testthat/test-start-contract.R` (written RED on
`claude/rev-parity-a1-start-tests`, untouched here) pass, and to make the
independent round-trip oracle
(`.unlazy/rev-parity/bin/start-roundtrip.R`) print `START ROUNDTRIP OK`.

## Approach: translation layer, not a new mechanism

Per the design doc and task brief, nothing new happens at the TMB boundary.
The existing private hook (`drm_apply_start_override()`, `R/drmTMB.R:614`
before this change, `~1176`) already validates, applies, and records
`spec$start_override_applied`; that code is untouched.

New code (`R/drmTMB.R`):

- `drm_translate_public_start_override(spec, start)` — for each labelled
  entry in `control$start`, parses the label, resolves it to an internal
  TMB start component + index, and accumulates a `spec$start_override`-shaped
  list. Multiple labels can target the same component (e.g. two `fixef:mu:`
  entries); the accumulator seeds each component from
  `spec$start[[component]]` (the family-builder default, i.e. the "cold fit"
  start) exactly once, then overwrites only the indices named by a label —
  this is what gives requirement (d), "a partial start updates only the
  named targets and leaves the family builders in charge of every remaining
  default," for free.
- `drm_parse_public_start_label(label)` — splits `"<family>:<dpar>:<target>"`
  on the first two colons via `regexec("^([^:]+):([^:]+):(.+)$", label)`, so
  a `target` containing no colon (all current label families) is captured in
  full, including labels like `"cor((Intercept),x | id)"`.
- `drm_resolve_public_start_target(spec, parsed, value, label)` — dispatches
  on `family`:
  - `"fixef"` → component `beta_<dpar>`, indexed by column name in
    `names(spec$start[[component]])`; value passed through unchanged (fixef
    starts are already on the model's internal/link scale, matching the
    design doc's own `"fixef:sigma:(Intercept)" = log(0.5)` example).
  - `"sd"` → component `log_sd_<dpar>`, indexed by
    `spec$random[[dpar]]$labels` (the same label vocabulary `sdpars()`
    already reports); value must be `> 0` and is `log()`-transformed.
  - `"cor"` → component `eta_cor_<dpar>`, indexed by
    `spec$random[[dpar]]$cor_labels` (the same vocabulary `corpars()`
    reports); value must be in `(-1, 1)` and is `atanh()`-transformed.
  - `"u"` → explicitly rejected with a message naming the latent-effect
    restriction (requirement (e)).
  - anything else (unparseable label, unknown family, unknown `dpar`/target)
    → `cli_abort()` naming the unknown label, before optimization ever
    starts (requirement (c)).

`R/drmTMB.R:drm_fit_spec()` (~614): if `control$start` is non-empty, calls
the translator and merges the result into `spec$start_override` via
`utils::modifyList()` before the existing `drm_apply_start_override(spec)`
call — unchanged from before. The merge (rather than a plain assignment)
matters only for the internal `drm_qgt2_staged_start_override()` diagnostic
path, which can pre-populate `spec$start_override` itself; ordinary
`drmTMB()` calls always see `spec$start_override` as `NULL` at this point, so
the merge is a strict superset there.

This dispatch pattern (`beta_<dpar>` / `log_sd_<dpar>` / `eta_cor_<dpar>`,
keyed by `spec$random[[dpar]]$labels` / `$cor_labels`) generalizes to every
`dpar` that already uses this naming convention — `mu`, `sigma`, `zoi`,
`coi`, and bivariate `mu1`/`mu2`/`sigma1`/`sigma2` — without extra
`dpar`-specific code, because the label itself carries the `dpar` name and
`spec$random`/`spec$start` are already keyed the same way throughout the
codebase. It does not reach the q>2 covariance-block components
(`log_sd_re_cov`, `theta_re_cov`) or structured-effect components
(`log_sd_phylo`, …) — those use a different keying scheme
(`drm_qgt2_member_start_keys()`) and are out of scope for "first landing"
per the design doc's stated scope (`fixef:`, `sd:`, `cor:` for the ordinary
random-effect blocks only). Not tested here; a later slice needing them
should extend the dispatch table rather than rewrite it.

## `R/control.R`

- `drm_control()` gains a `start = NULL` formal, validated by
  `drm_control_validate_start()`: `NULL` or a named list of single finite
  numbers. Formula/family-dependent validation (does this label exist in
  this model?) happens later, in `drm_translate_public_start_override()`,
  per requirement (a) ("validated AFTER formula parsing").
- `drm_control_reserved_names()` is **unchanged** in the end. My first pass
  removed the explicit `"start"` entry and excluded it from the
  `setdiff(names(formals(drm_control)), "optimizer")` derivation, which
  broke `test-optimizer-contract.R`'s `"future optimizer contract names are
  reserved in plain control lists"` test: `control = list(start = TRUE)`
  (the *raw*-list path, not `drm_control()`) must still reject `start` as
  reserved, because raw `control = list(...)` is documented as
  nlminb-optimizer-settings-only. Since `"start"` is now a real formal of
  `drm_control()`, it is already picked up by the unmodified
  `setdiff(names(formals(drm_control)), "optimizer")` line — the reserved-name
  check only guards `drm_control(optimizer = list(...))` and the raw
  `control = list(...)` path, never the named `start = ` argument to
  `drm_control()` itself, so no exclusion was needed. Reverted back to the
  original list literal after the regression surfaced.

## Map-preservation red control: (ii) ABANDON, with a concrete falsification, not just A1's a priori argument

Task brief required doing (i) find a real fixture and red-test the
preservation branch, or (ii) record an honest `ABANDON` with evidence, not
silently mark the guard satisfied.

I went further than re-stating A1's finding. A1 (see
`docs/dev-log/after-task/2026-09-01-a1-start-contract-tests.md`) argued
a priori that no public label can currently address a map-fixed index. I
confirmed this **concretely** by deliberately breaking the masking logic and
watching the test suite stay green:

1. Ran the full 10-block suite clean (26/26 pass) against the real
   `drm_start_override_mapped_slots()` masking.
2. Edited `drm_apply_start_override()` in place —
   `candidate[!mapped] <- value[!mapped]` → `candidate[TRUE] <- value`
   (i.e. deleted the masking entirely: every position, mapped or not, gets
   overwritten by the override value) — and re-ran the same 10-block suite.
3. **Still 26/26 pass**, including block 6 (`"a slot fixed by spec$map is
   preserved, not overwritten, when its sibling is targeted"`), with masking
   completely removed.
4. Reverted the edit (verified `git diff --stat R/drmTMB.R` returned to the
   pre-edit `+125` line count with no other changes).

Why block 6 stays green either way: my translator seeds
`override[[component]]` from `spec$start[[component]]` (the unmodified
family-builder default) and only overwrites the index matched by the
label's own target (`"(1 | id2)"` → index 2 in this fixture). The map-fixed
index (index 1, `"(1 | id)"`, driven by `sd(id) ~ w`) is never touched by
the override vector at all — its value in `override[[component]]` is, by
construction, byte-identical to `target[[1]]` regardless of whether masking
runs. So block 6 is a genuine, non-vacuous integration test of "the
translation layer builds a full-length override vector without corrupting
or erroring on a map-fixed sibling" (which is real and useful), but it
cannot and does not exercise "a slot fixed by `spec$map` is preserved, not
overwritten, when *that same slot* is named by a label" — because no public
label can ever name that slot, so no such collision is constructible from
this translation layer's public surface.

**ABANDON: A2-G4** — the "a label naming a `map`-fixed slot is preserved"
guard is not reachable from any public start label today, confirmed by a
delete-and-restore experiment (not just inspection): removing the masking
branch entirely left the full test suite green. The masking code in
`drm_apply_start_override()` remains in place (it protects the *internal*
`spec$start_override` API used directly by `drm_qgt2_staged_start_override()`,
which can and does address such indices), but no test in
`test-start-contract.R`, including block 6, currently falsifies its removal
via the public `start =` surface. This is not a regression introduced here;
it is a structural fact about which internal slots public labels can name,
matching A1's prediction, now demonstrated rather than argued.

## Verification (real numbers)

- `Rscript -e 'devtools::load_all("."); testthat::test_file("tests/testthat/test-start-contract.R")'`
  → `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 26 ]` (10/10 blocks, 26 expectations).
- `Rscript ".unlazy/rev-parity/bin/start-roundtrip.R"` → `START ROUNDTRIP OK`.
- `devtools::document()` — regenerated `man/drm_control.Rd` for the new
  `start` argument. It also touched `man/confint.drmTMB.Rd` (a pure
  `\code{}`-wrapping roxygen2-version drift unrelated to this change,
  confirmed by `git diff`) and produced two previously-uncommitted man pages
  (`drm_julia_joint_prepare.Rd`, `drm_julia_joint_result.Rd`) for unrelated
  functions already in the tree. None of that is part of this slice's
  surface; reverted by hand back to the committed text so the diff stays to
  `man/drm_control.Rd` only.
- Filtered regression suite,
  `testthat::test_dir("tests/testthat", filter="start|control|optimizer")`:
  first run surfaced 2 real failures in
  `test-optimizer-contract.R:157/165` (the reserved-names regression
  described above); after reverting `drm_control_reserved_names()`, re-ran
  clean: all `control`, `julia-batch-startup`, `missing-data-control`,
  `multi-start`, `optimizer-contract`, `optimizer-escalation`,
  `sigma-slope-start`, and `start-contract` test files pass, with only the
  pre-existing 7 "On CRAN" skips and 1 pre-existing `sd_phylo()` deprecation
  warning (unrelated to this change).
- Did **not** run the full `devtools::test()` suite (43-46 min), per task
  instruction.

## Files

- `R/control.R` — `start` formal + validator on `drm_control()`.
- `R/drmTMB.R` — translation layer (3 new functions) + one call site before
  `drm_apply_start_override()`.
- `man/drm_control.Rd` — regenerated for the new `start` parameter.
- `NEWS.md` — new "Public start contract" entry under 0.7.0.
- This note.

## Explicitly out of scope (per task brief)

- `start_from = <a fitted model>` — stays reserved; not implemented.
- `docs/design/35-optimizer-start-map-multistart.md` — not edited; the
  "Public Start Contract" section already describes the shipped behaviour
  (it was written pre-implementation and is now accurate, not
  aspirational). No further design update was requested or needed.
- `tests/testthat/test-start-contract.R` — not edited.

## Commit

Branch `claude/rev-parity-a2-start-impl`, on top of A1's `049a60c21`.
