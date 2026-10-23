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

## Addendum 2026-09-01: two adversarial-pass defects, fixed

An independent adversarial pass found two defects in the landed
implementation above that A1's ten blocks did not cover. Both are fixed on
this branch; new tests were added to `tests/testthat/test-start-contract.R`
(I was authorized to edit that file for this follow-up only — the "producer
must not touch its own tests" gate had already been independently verified
against A1's committed version before this addendum; no existing block was
altered).

### Defect A2-D1 — root cause and fix

**Repro:** `drm_control(start = list("fixef:sigma:(Intercept)" = 50), se = FALSE)`
on an intercept-only-`sigma` Gaussian fit. `nlminb` reports `convergence = 0`
("relative convergence"), `check_drm()`'s `optimizer_convergence` and
`fixed_gradient` rows both read `ok`, and the log-likelihood sits far from
the true optimum (in my repro, ~1800 units off on a 120-row fixture; the
coordinator's own repro measured ~4400 on a different fixture).

**Root cause (confirmed, not assumed):** I evaluated `obj$gr()` **at the
supplied start itself**, before any optimizer step, and it was already
`~1e-9`–`~1e-13` in every coordinate. `src/drmTMB.cpp`'s
`drm_softclamp_log_sigma_one()` maps `log(sigma)` through
`hi + margin * tanh((x - hi) / margin)` once `x` exceeds the configured band;
at `x = 50` with the default band `(-12, 12, margin = 3)`,
`tanh((50-12)/3) = tanh(12.67) ≈ 1` to double precision, so the derivative
`1 - tanh(z)^2 ≈ 0`. The softclamp is not merely bent there, it is *flat* in
floating point. `nlminb` sees a ~0 gradient at iteration 0 and declares
convergence without taking a real step — "converged" is arithmetically true
(the gradient genuinely is ~0 in that clamped coordinate) and scientifically
false (the fit never moved from a bad point). This is exactly the mechanism
the task brief predicted, now confirmed by direct gradient evaluation rather
than inferred from symptoms.

**Why this matters for what the slice exists to do:** design 35's motivating
case (DRM.jl#575) is "start engine A at engine B's fitted point and see
whether it climbs away." A silent "converged at your point" is precisely the
wrong answer to that question — it would let someone conclude two engines
agree at a point neither optimizer actually explored.

**A pre-existing, partially-overlapping mechanism:** `drm_warn_if_clamp_active()`
(existing code, not part of this slice, called unconditionally in
`drm_fit_spec()`) already warns post-hoc when the *fitted* `log(sigma)`
exceeds the upper band bound, and `check_drm()`'s `logsigma_clamp_active`
row already surfaces it as a persistent status. In my first repro this
warning did fire and `check_drm()` did show `logsigma_clamp_active: warning`
— so the coordinator's report is not "nothing detects this at all," it is
"the two check rows most people would look at (`optimizer_convergence`,
`fixed_gradient`) still read `ok`, and the generic clamp warning doesn't
mention the start at all, so a reader has no direct causal link from 'I
supplied a bad start' to 'this warning fired.'" That generic warning is also
upper-bound-only by design (its own comment: the lower bound is often a
legitimate zero-variance boundary), so a `sigma` start driven deep below the
lower band would not be caught by it at all — though my one attempt at that
scenario (`-50`) instead produced `singular convergence (7)` and a
`fixed_gradient: warning`, i.e. a different, already-visible failure
signature, not a silent one.

**Fix (shape: detect and report, never move the start):**
`drm_warn_if_start_saturates_logsigma_clamp(spec, override)`, called from
`drm_translate_public_start_override()` before optimization runs. It
computes the actual per-row `log(sigma)` linear predictor implied by the
*proposed* start (baseline family-builder defaults plus the override, via
`spec$X[[dpar]] %*% override[[component]]`) for each of `beta_sigma`,
`beta_sigma1`, `beta_sigma2` present in the override, and warns with a new
class `drmTMB_start_clamp_saturated_warning` — naming the label's `dpar`,
the configured band, and the reached value — whenever that predictor lies
outside the band, for any family in `drm_clamped_scale_families()` (the
existing family gate reused, not reinvented) and whenever
`use_logsigma_clamp == 1` (the default). Checking against the design matrix
rather than the raw scalar value means this also catches a `sigma ~ x`
slope-driven start, not just an intercept. This is purely additive: it does
not alter `nlminb`'s convergence code, does not touch `opt$par`, and does
not move the user's supplied start value — `saturated$model$start$beta_sigma`
still reads exactly `50` after the fit, asserted directly in the new test.

I deliberately did not attempt to make the optimizer itself escape the flat
region (e.g. by silently repositioning the start inside the band) — the
task brief is explicit that doing so "would violate the contract you just
implemented," and I agree: the whole point of `start=` is that the user's
point is what gets evaluated.

### Defect A2-D2 — REML decision: **error**, not warn

**Repro:** `drm_control(start = list("fixef:mu:(Intercept)" = 99))` on a
`REML = TRUE` Gaussian fit with a random intercept. `spec$model$start$beta_mu[1]`
did read back as `99` (the override mechanism worked correctly at the level
this slice controls), but `fit$coefficients$mu[1]` came back at the true
MLE-equivalent REML estimate (~1.07), completely uninfluenced by the
supplied start.

**Root cause:** `drm_apply_estimator_spec()` (pre-existing code, called
before the start-translation call in `drm_fit_spec()`) folds `beta_mu` (and
`beta_sigma` when a `sigma` random effect makes REML restrict the scale
fixed effects too) into `spec$tmb_random_names` under `REML = TRUE` — i.e.
these coefficients are integrated out via the Laplace approximation on every
outer iteration, not held as free outer-objective coordinates the way they
are under `REML = FALSE`. A `fixef:` start's only lever, `spec$start[[component]]`,
is therefore just the *inner* solver's initial guess, re-solved to the same
joint mode regardless of where it starts (assuming the inner problem is
well-posed) — the public label has no fixed point to seed, by construction
of REML itself, not as a bug in the override plumbing.

**Decision: error, matching `objective_at()`.** The coordinator reported
that `objective_at()` (a separate, not-yet-landed-in-this-worktree A3 slice)
already refuses the same `fixef:`-under-REML labels. I chose **error** over
**warn-and-ignore** for two reasons beyond "match the sibling verb": (1) a
silently-ignored start is the one option the task brief calls "not
defensible," and a warning that a label did nothing is easy to miss in the
same way the original silent-acceptance was; (2) an error surfaces exactly
at the moment a user would want to know — before spending a fit's worth of
compute on a start that was never going to matter — and is the cheaper
failure to correct (drop the label or set `REML = FALSE`).

**Fix:** `drm_resolve_public_start_target()`'s `"fixef"` branch checks
`component %in% spec$tmb_random_names` (the exact set
`drm_apply_estimator_spec()` already computes for this purpose) and errors
naming the `dpar`, the REML mechanism, and the two ways out (`REML = FALSE`,
or omit the label). No new REML-detection logic was written; this reuses the
existing REML/estimator-spec bookkeeping.

### Item recorded for the note only, not fixed in code

Per instruction, not touched: `fixef()` on a Student-t fit emits a `nu`
block whose coefficient labels (I did not independently re-derive the exact
label text; the coordinator's report is the source for this item) the start
label vocabulary's `fixef:<dpar>:<column>` matching does not resolve,
because the vocabulary only recognizes `dpar`s with a `spec$start$beta_<dpar>`
naming match and a validated `beta_<dpar>` component of that name. This
breaks the natural `build-at-from-fixef()` idiom (`labels_of(fixef(fit))` in
the round-trip oracle's own helper) specifically for `student()` fits with a
`nu` block. Widening the label vocabulary to guarantee every `fixef()` block
name round-trips through `start=` is a separate design decision — it touches
which `dpar`s the family builders expose as addressable components, not the
translation layer this slice owns — and is out of scope here.

### Verification (real numbers)

- New tests confirmed **RED** against pre-fix code: temporarily reverted
  only `R/drmTMB.R` to the pre-addendum commit (`git stash push --keep-index
  -- R/drmTMB.R`, keeping the new tests staged) and re-ran
  `test-start-contract.R`: `[ FAIL 3 | WARN 1 | SKIP 0 | PASS 28 ]` — the
  A2-D1 test failed because the generic clamp-active warning's class
  (`drmTMB_clamp_active_warning`) does not match the new, more specific
  class the test asserts (`drmTMB_start_clamp_saturated_warning`); the
  A2-D2 test failed because the REML fit returned a `drmTMB` object instead
  of erroring. Restored the fix (`git stash pop`).
- **GREEN** after restoring the fix:
  `Rscript -e 'devtools::load_all("."); testthat::test_file("tests/testthat/test-start-contract.R")'`
  → `[ FAIL 0 | WARN 1 | SKIP 0 | PASS 31 ]` (12 blocks now, 31
  expectations; the 1 `WARN` is `testthat` surfacing the *other*,
  pre-existing generic clamp warning that co-fires alongside the new one in
  the A2-D1 test — `expect_warning()` only captures the class it names, and
  a second, additional warning during the same call is reported as an
  informational `WARN`, not a failure).
- Oracle: `Rscript ".unlazy/rev-parity/bin/start-roundtrip.R"` →
  `START ROUNDTRIP OK` (unaffected; it never touches `sigma` starts outside
  the clamp band or REML).
- Filtered regression suite,
  `testthat::test_dir("tests/testthat", filter="start|control|optimizer")`:
  all files pass — `control`, `julia-batch-startup`, `missing-data-control`,
  `multi-start`, `optimizer-contract`, `optimizer-escalation`,
  `sigma-slope-start`, `start-contract` — with only the same 7 pre-existing
  "On CRAN" skips and the same 1 pre-existing `sd_phylo()` deprecation
  warning as before, plus the 1 expected co-firing warning above. No new
  failures.
- Did not run the full suite (another lane's run was already in progress
  per the coordinator's instruction).

### Files (addendum)

- `R/drmTMB.R` — `drm_warn_if_start_saturates_logsigma_clamp()` (new) +
  call site in `drm_translate_public_start_override()`; REML check added to
  `drm_resolve_public_start_target()`'s `"fixef"` branch.
- `tests/testthat/test-start-contract.R` — two new `test_that()` blocks
  appended (A2-D1, A2-D2); no existing block altered.
- `NEWS.md` — addendum bullet under the existing "Public start contract"
  heading.
- This note.
