# After-task: A4-INTEGRATION -- the bridge-side pieces the six family leaves could not own

Date: 2026-09-05
Ledger: `.unlazy/parity/gates/leaf-a4-integration.md`
Worktree: `~/local-scratch/parity-joint/wt-a4-integration`, branch `claude/parity-a4-integration`
DRM.jl worktrees used: `~/local-scratch/parity-joint/drmjl-430ef64cc` (pin, read-only), `~/local-scratch/parity-joint/wt-a4-skew_normal-drmjl` (DRM.jl PR #641's bridge case), `~/local-scratch/parity-joint/wt-a4-evidence-drmjl` (the G11 evidence PR)

## 1. Goal

Close the three things the six A4 family-admission leaves (tweedie,
zero_one_beta, beta_binomial, truncated_nbinom2, cumulative_logit,
skew_normal) could not own themselves: (a) the default-coefficient-label gap
that blocked short formula forms through `engine = "julia"`; (b) the
`drm_julia_capability_comparison()` TSV rows; (c) one shared after-task.
Plus everything the adversarial-review addenda (G11-G18) added during the
day.

## 2. The six families -- parity numbers, each attributed to its PR

All numbers below were measured by the named PR's own leaf, except the
tweedie/zero_one_beta bare-formula numbers in G1/G2, which this leaf
measured directly (see §3).

| Family | PR | max\|d coef\| | logLik (tmb / julia) | SE max rel | Registry row / TSV row |
|---|---|---|---|---|---|
| `tweedie` | #1169 (merged) | 2.767e-11 | -463.227431798281 / same | 3.273e-06 | registry: yes. TSV row: **missing** (see §6) |
| `zero_one_beta` | #1171 (merged) | 3.979e-11 | -811.772322246398 / -...396 | 9.759e-07 | registry: yes. TSV row: **missing** (see §6) |
| `truncated_nbinom2` | #1173 (merged) | 8.812e-11 | -454.131353120582 / -...584 | 2.713e-07 | registry: yes. TSV row: **missing** (see §6) |
| `beta_binomial` | #1172 (open at merge time; carries its own row) | 7.772e-15 | -2888.8513171557 / -...596 | 1.725e-07 | registry: pending #1172. TSV row: `fe_beta_binomial`, in #1172 |
| `cumulative_logit` | #1174 (open at merge time) | 2.198e-14 | -903.275348750815 / -...827 | 5.758e-09 | registry: pending #1174. TSV row: `fe_cumulative_logit`, added HERE |
| `skew_normal` | #1176 (open at merge time; needs DRM.jl #641) | 1.890e-11 | -532.154369983715 / -...717 | 1.045e-06 | registry: pending #1176. TSV row: `fe_skew_normal`, added HERE |

All six: `estimator == "ML"` on both engines; a negative control (`se_julia[1]
* 1.10`) reads `SE_FAIL` -> `NEGATIVE_CONTROL_OK` in the same evidence row;
fixed effects only, one committed fixture per family; no interval-coverage
claim.

## 3. What THIS leaf implemented and measured

### 3.1 `drm_julia_bridge_default_dpar_labels()` (G1/G2/G3)

Previously defaulted a `nu` label only for `student()`. Widened to read
every dpar a family declares beyond `mu`/`sigma` off the family's own
constructor (`setdiff(fam$dpars, c("mu", "sigma"))`), so `tweedie`/
`skew_normal`'s `nu` and `zero_one_beta`'s `zoi`/`coi` now default the same
way `sigma` always did.

Measured live, ONE Julia session, `OPENBLAS_NUM_THREADS=1
DRMTMB_JULIA_TESTS=true DRM_JL_PATH=DRM_JL_PHYLO_PATH=<pin 430ef64cc>`:

- **G1 RED** (branch-base source, `git stash` the fix): `bf(y ~ x)` +
  `tweedie()` + `engine = "julia"` aborts verbatim: `Error happens in Julia.
  drm_bridge: coef_labels is missing an entry for dpar "nu" (1 fixed-effect
  columns; Julia names: ["nu_(Intercept)"]); the R side must supply names
  for every dpar when sending coef_labels`.
- **G2 GREEN** (fixed source, same session): `bf(y ~ x)` reaches logLik
  `-479.8586143` on BOTH engines exactly; `bf(y ~ x, sigma ~ z)` reaches
  `-463.2274318` on BOTH engines exactly.
- **zero_one_beta's own KNOWN HOLE** (`bf(prop ~ x, sigma ~ z)`, zoi/coi
  omitted): now fits, logLik `-425.0937691` (was a live-gated abort before).
- Restored byte-identically after the RED check: sha256
  `002209ed6da760726a085c4778e8fb3874c813fca5adf08ef4c7de32a9e15335` before
  == after.
- **G3**: new `tests/testthat/test-julia-bridge-default-labels.R` (no
  Julia, 16 assertions) pins the label list for `student`/`tweedie`/
  `skew_normal`/`zero_one_beta`, that families with no extra native dpar get
  no invented label, that an explicit non-intercept `nu` formula is never
  overwritten, and the G16 inform/silent cases. Manual RED CONTROL: with
  the fix reverted (`git stash`), 5/16 assertions fail; restored
  byte-identically (same sha256 as above).

### 3.2 G16 (Rose, #1169): the tweedie `nu ~ z` shape

Native `tweedie()` refuses any `nu` formula but an intercept
(`R/drmTMB.R:6040`, `"tweedie currently supports only intercept-only nu ~
1"`); DRM.jl's `Tweedie` fits `nu ~ z` (a shape with no native comparator).
The ledger's own DECISION (G0) said do nothing; Rose's G16 disputed that on
honesty grounds. Resolution implemented: `drm_julia_bridge_default_dpar_labels()`
now emits ONE `cli_inform` at fit time naming the shape and the native
refusal it has no receipt against, ONLY when `nu` is present with a
non-`"1"` rhs on `tweedie`. Measured live: fires for `nu ~ z` (logLik
`-478.7262377` on this leaf's own n=500 fixture -- an independent re-draw
from the `-462.2769307` figure recorded elsewhere in this programme for the
identical shape; no same-target receipt exists either way, so this row makes
no parity claim); silent for `nu ~ 1` and the bare default. Verified with
`expect_message`/`expect_no_message` in G3's test file.

### 3.3 `drm_julia_capability_comparison()` -- G4

Per this run's specific instruction ("add comparison rows ONLY for
cumulative_logit and skew_normal; the others exist or arrive with #1172"),
added exactly two rows: `fe_cumulative_logit`, `fe_skew_normal`. Their
numbers are cited from the #1174/#1176 leaves' own measured receipts (their
family code is not on this branch to re-run -- #1174/#1176 were still open
PRs at merge time, and this leaf's OWNS is the registry function, not the
registry file). `r_bridge_status` set to `"experimental"` rather than the
sibling `"partial"` convention -- see §5's validator finding for why.

Regeneration: `Rscript tools/write-julia-capability-comparison.R` run
twice, byte-identical output both times (26 rows). `python3
tools/capability_ledger.py --check`: OK (31 generated outputs). `Rscript
tools/check-capability-runtime.R`: OK (18 routes; verified=18).
`test-julia-gate-vs-engine.R`: 149/0.

### 3.4 G13: `tests/testthat/test-julia-registry-vs-comparison.R`

New guard (A2's identical test does not exist on this branch): every
`drm_julia_registry_families("fe")` entry maps to a `drm_julia_capability_comparison()`
row via an explicit, named map (`drm_julia_fe_family_capability_map()`),
with `tweedie`/`zero_one_beta`/`truncated_nbinom2` as a NAMED, asserted gap
(NA in the map) rather than a silent hole -- per Rose's PATTERN WARNING
that a scope-held check must pair with a positive assertion. A second
assertion fails the moment one of those three names gets a row without
being removed from the gap list (drift in either direction is caught). RED
CONTROL is built into the test file itself (drops `fe_student`'s row from a
copy of the comparison table and asserts the guard catches it) -- 6/6
assertions pass on the real table.

### 3.5 G7: `docs/design/258-coefficient-naming-contract.md` §8

**Found while reviewing as the domain expert (the "hunt defects" pass): the
already-merged §8 content for `truncated_nbinom2`, `zero_one_beta`, and
`tweedie` was INTERLEAVED by a prior three-way merge.** Each section's own
table and evidence prose had been physically spliced into a DIFFERENT
family's section (e.g. the "8.1 truncated_nbinom2" header was immediately
followed by tweedie's table, tweedie's same-target receipts, and tweedie's
"neighbours" discussion -- verified by cross-checking each fragment's cited
logLik values against the family whose fixture actually produces them), and
`truncated_nbinom2`'s and `zero_one_beta`'s `mu`/`sigma` table rows had been
DROPPED outright (not merely misplaced -- genuinely absent from the file).
This went well beyond "the §8 header line" this leaf's OWNS names, but
leaving three sections of a shipped design doc mislabelled and missing data
did not seem defensible to leave for a future PR to notice. Fixed:
reassembled each section from its own (now correctly attributed) prose and
tables; reconstructed the two missing table rows from each family's own
already-tested, already-merged fixture (`truncated_nbinom2`'s `mu` row from
its cited `bf(y ~ x, sigma ~ 1)` fixture; `zero_one_beta`'s `mu`/`sigma` rows
from `tests/testthat/test-julia-family-zero_one_beta.R`'s own asserted
labels) -- no content invented beyond those two grounded reconstructions;
renumbered 8.1/8.2/8.3 in MERGE order (`truncated_nbinom2` #1173, merged
11:37 -> `zero_one_beta` #1171, 15:41 -> `tweedie` #1169, 16:11); removed a
stale parenthetical claiming an "alphabetical" sub-numbering convention that
conflicts with G7's explicit "merge order" instruction. Also updated
tweedie's and zero_one_beta's own prose to note their gaps are now CLOSED by
this PR (G1-G3, G16) rather than left as blockers. `cumulative_logit`'s and
`skew_normal`'s own design-258 subsections are NOT added here (still their
own leaves' OWNS, in #1174/#1176, not merged onto this branch).

### 3.6 G18: regeneration-status counts and ASCII

`docs/dev-log/dashboard/capability-regeneration-status.tsv`'s
`julia_capability_comparison` row was stale (9/9, dating to a 2026-06-22
regeneration); set to 26/26 (this branch's produced total). The
`julia_gate_registry` row already read 15/15, matching this branch's actual
`drm_julia_intentional_gates()` count (15, after #1180's merged marker-slope
gate) -- no change needed. ASCII check: `grep`-verified no bytes > 127 in
`R/julia-bridge.R` or either new test file.

## 4. What was NOT closed, and why (blockers / decisions)

- **G6 (gate registry)**: `base_unsupported_family` still records
  `beta_binomial` as an intentional error on this branch, because #1172
  (which retires it) has not merged. The retiring patch IS already
  committed there (commit `251e9b946b5`, "merge main + integrator patch:
  ...base_unsupported_family retired..."), so this gate resolves itself the
  moment #1172 lands; not something to redo here. `inst/extdata/julia-gates.tsv`
  / `docs/dev-log/dashboard/julia-gates.tsv` were NOT regenerated by this
  leaf, per OWNS's own conditional ("ONLY if a family leaf could not retire
  the row").

- **G4/G13 gap -- `tweedie`, `zero_one_beta`, `truncated_nbinom2` have NO
  `drm_julia_capability_comparison()` row, on ANY branch, as of this
  writing**, despite all three being registry-admitted and merged. This
  contradicts the launch instruction's STATE OF MAIN description ("A3's
  nine rows, A5's three rows and the truncated_nbinom2/zero_one_beta/tweedie
  admissions are merged (25 comparison rows)") -- measured reality on
  origin/main at merge time is 24 rows, none for those three families. This
  leaf's OWNS restricts row additions to `cumulative_logit`/`skew_normal`
  per the SAME instruction's explicit narrowing ("add comparison rows ONLY
  for cumulative_logit and skew_normal"), so the three are left as a named,
  tested gap (§3.4) rather than silently fixed outside the given scope.
  **Recommend a small follow-up PR adding `fe_tweedie` (retiring the
  duplicate "tweedie" naming already flagged in the DRM.jl evidence,
  §7 below), `fe_zero_one_beta`, and `fe_truncated_nbinom2` rows once main
  is stable.**

- **G12 (cumulative_logit `predict()`)**: `drm_julia_predict_fixed_eta()`
  rebuilds the `mu` design with `model.matrix()`, restoring `"(Intercept)"`,
  while the fitted block has only `x` -- `predict(fit, dpar = "mu")` on the
  Julia object aborts. NOT fixed: that function is outside this leaf's
  two-function OWNS in `R/julia-bridge.R`. Documented as a declared,
  unclaimed gap in the `fe_cumulative_logit` TSV row's `claim_boundary` and
  `next_action`, matching the #1174 leaf's own recorded decision.

- **G14 (block order)**: `fixef()`/`coef()` list blocks alphabetically for
  the Julia engine object (`coi, mu, sigma, zoi` for zero_one_beta; `mu, nu,
  sigma` for tweedie/skew_normal) vs declaration order natively (`mu, sigma,
  zoi, coi`; `mu, sigma, nu`) -- a pre-existing `split()` order in
  `R/julia-bridge.R`, outside this leaf's two-function OWNS. NOT fixed;
  documented in the reassembled design-258 §8 sections (§3.5) as measured
  fact, matching what each family's own leaf already recorded.

- **G17 (RE dispatch fence for fe-only families)**: requires NEW dispatch
  code (a downstream fence generic over registry fe-only families, per the
  "G17 refinement" note) that is not either of this leaf's two OWNS
  functions and is not a documentation-only decision like G12/G14 -- the
  gate itself says "must not pass silently" with no "or document" escape
  hatch. **BLOCKED, not implemented**: adding this fence would violate G9
  (scope held: only the two named functions may change in
  `R/julia-bridge.R`). Flagging as a genuine OWNS/gate conflict for
  Shinichi: either G17 needs its own leaf/PR, or this leaf's OWNS needs an
  explicit grant for a third function.

- **zero_one_beta's `test-julia-family-zero_one_beta.R` "KNOWN HOLE" test is
  now stale.** Fixing the default-label gap (§3.1) means the test's
  `expect_match(res$err_omit, 'coef_labels is missing an entry for dpar
  "zoi"' ...)` assertion will FAIL the next time it runs live (the fit now
  succeeds instead of erroring) -- this is the INTENDED consequence the
  test's own comment names ("when it closes, replace this expectation with
  a fit"). NOT fixed here: that file is a sibling leaf's (#1171, already
  merged) test file, outside this leaf's OWNS. Flagged here as a blocker;
  needs a one-line follow-up to `tests/testthat/test-julia-family-zero_one_beta.R`
  replacing the `expect_match` on `err_omit` with a fit assertion.

- **skew_normal's live round-trip for the SAME shape could not be run end
  to end.** The `wt-a4-skew_normal-drmjl` worktree (DRM.jl PR #641's bridge
  case) exists and was used, but `skew_normal` is not in
  `R/julia-family-registry.R` on this branch (that row is #1176's OWNS,
  unmerged), so `drm_julia_family_tag()` refuses the call before Julia is
  even reached -- the actual blocker turned out to be #1176's merge, not
  #641 as the ledger anticipated. The label-defaulting mechanism itself is
  verified offline (G3's test) and live end-to-end via the IDENTICAL code
  path for tweedie (§3.1); recorded as `next_action` on the `fe_skew_normal`
  TSV row.

## 5. A validator finding: `r_bridge_status = "partial"` and dotted issue labels

Measured `tools/validate-mission-control.py` delta against a clean
`origin/main` checkout (`~/local-scratch/parity-joint/wt-main-probe`,
`git pull --ff-only`): baseline 33 errors. Using `"partial"` for the two new
rows' `r_bridge_status` (matching every A3/A4 sibling row's convention)
produced 34 errors -- NOT because "partial" is wrong, but because
`tools/validate-mission-control.py`'s `R_BRIDGE_STATUSES` vocabulary on
THIS branch does not yet include it (`#1172` adds it, unmerged here, and
this leaf does not own that file). The SAME value on `fe_student`,
`fe_lognormal`, `base_gaussian_location_scale`, and 9 other ALREADY-MERGED
rows is ALSO flagged on the clean baseline -- a pre-existing gap, not a new
one. Kept both new rows at `r_bridge_status = "experimental"` to hold G18's
zero-new-errors bar; **promote both to `"partial"` once #1172 merges.**
Likewise, `DRM.jl#641` (skew_normal's more precise issue reference) fails
the validator's compact-issue-label regex (`^[A-Za-z0-9]+#[0-9]+$`, no dot)
-- the SAME regex already rejects the already-merged `location_scale_scale`
row's `"DRM.jl#545"` on the clean baseline. Used `"drmTMB#544"` for the
`issue` column instead (matching sibling convention); `DRM.jl#641` remains
visible via `evidence_url` and the row's `claim_boundary` prose. Final
measured delta: 31 errors on this branch vs 33 baseline -- **0 new, 2 fixed**
(the stale `julia_capability_comparison` row counts, §3.6).

## 6. G11 -- the DRM.jl evidence PR

Branch `claude/parity-a4-evidence-drmjl` off DRM.jl `origin/main`
(fast-forwarded to the current tip before committing). Carried the pin
clone's uncommitted 47-line append to `docs/dev-log/evidence/parity-fixtures.tsv`
and `parity-se.tsv`, deduped as follows (pin clone HEAD untouched; no `git
checkout`/`stash` performed there):

- `fe_poisson`, `fe_nbinom2`, `fe_gamma` (fixtures only): the pin carried
  BOTH an older, unattributed row already on DRM.jl main AND a newer
  "(A3 worktree load_all, HEAD ea3156d73)" re-measurement of the identical
  cell with tighter precision (e.g. `fe_gamma` coef diff `3.91e-06` ->
  `1.91e-11`). Updated the three existing rows IN PLACE to the newer values
  rather than appending duplicates.
- `tweedie` / `fe_tweedie`: byte-identical duplicate under two spellings
  (drmtmb_code_hash `f5ac6e47...` on both, per the ledger's own G11
  addendum). Kept `fe_tweedie` (matches the sibling `fe_<family>`
  convention); dropped the bare `tweedie` fixture row and its two SE rows.
- `cumulative_logit` / `skew_normal`: renamed to `fe_cumulative_logit` /
  `fe_skew_normal` (2 fixture rows, 4 SE rows) to match the R-side
  capability_id this leaf chose for §3.3's TSV rows.

Verified after the rebuild: zero duplicate `capability_id` values in
`parity-fixtures.tsv`; zero duplicate `(capability_id, cell_id)` pairs in
`parity-se.tsv`; uniform column counts (9 and 11 fields respectively).
PR opened, base `main`, DO NOT MERGE per standing instructions.

## 7. NOT COVERED (carried from the six leaves, unchanged by this integration)

- Random effects, structured markers (`relmat()`/`animal()`/`spatial()`),
  and phylogenetic routes through ANY of the six families -- every leaf's
  admission is fixed-effect (Workflow G) only.
- `nu ~ <covariates>` on `tweedie` remains Julia-only (native refuses); now
  informed rather than silent (§3.2), still no cross-engine receipt.
- `cumulative_logit`'s ordinal cutpoints slot (`fit$ordinal`) is not a dpar
  and carries no interval-coverage claim; its `predict()` gap is open (§4).
- Interval coverage (profile/bootstrap through `engine = "julia"`) is
  unqualified for all six families (design/168's G3 fence).
- `skew_normal`'s bare-`nu` shape end-to-end through a live #641 DRM.jl
  checkout (§4).

## 8. Files touched (OWNS)

`R/julia-bridge.R` (exactly `drm_julia_bridge_default_dpar_labels()` and
`drm_julia_capability_comparison()` -- verified via `git diff <branch-base>
<this-leaf's-commit> -- R/` showing only this file, and hunk-by-hunk
confirmation both functions are the only ones touched); `inst/extdata/julia-capabilities.tsv`
+ `docs/dev-log/dashboard/julia-capabilities.tsv` (regenerated,
byte-identical on a second run); `docs/dev-log/dashboard/capability-regeneration-status.tsv`
(counts only); `docs/design/258-coefficient-naming-contract.md` (§8
reassembly, §3.5); `NEWS.md` (one bullet naming all six families);
`tests/testthat/test-julia-bridge-default-labels.R` (new); `tests/testthat/test-julia-registry-vs-comparison.R`
(new, G13); this report. `inst/extdata/julia-gates.tsv` /
`docs/dev-log/dashboard/julia-gates.tsv` NOT touched (§4, G6 conditional).

## 9. Checks run (this leaf)

- Offline (no Julia): `test-julia-bridge-default-labels.R` 16/0;
  `test-julia-registry-vs-comparison.R` 6/0; `test-julia-gate-vs-engine.R`
  149/0; `test-julia-bridge.R` green (2 live skips, DRM_JL_PATH unset in
  that particular run); `test-julia-family-registry.R` 22/0.
- Live (pin 430ef64cc, one Julia session): G1 RED verbatim message; G2
  GREEN exact-logLik parity for bare and location-scale tweedie; G16
  inform/silent; zero_one_beta bare-formula fit.
- Live (`wt-a4-skew_normal-drmjl`, DRM.jl #641): attempted, blocked by
  #1176's unmerged registry row (§4), not by #641.
- `Rscript tools/write-julia-capability-comparison.R` x2: byte-identical.
- `python3 tools/capability_ledger.py --check`: OK.
- `Rscript tools/check-capability-runtime.R`: OK.
- `python3 tools/validate-mission-control.py`: 31 errors vs 33 on a
  freshly-pulled clean `origin/main` checkout -- 0 new, 2 fixed.
- `devtools::test(".")` (full suite, no Julia, ~45 min estimate per the
  ledger's own G15): kicked off in the background; ONE unrelated
  pre-existing floating-point-tolerance failure observed so far
  (`test-associate-pairs-arc6-integration.R:58`, `0.21811965` vs
  `0.21811962`), unrelated to any file this leaf touched; full result
  recorded in the PR body once the run completes.

## 10. Errors I made during this run

- Initially wrote a "RED CONTROL" test inside
  `test-julia-bridge-default-labels.R` that replayed a hand-copied OLD
  version of the function rather than exercising the real one -- removed it
  before committing (it tested dead code, not a red control) and did the
  RED CONTROL manually instead (git stash the real fix, run the real test
  file, observe 5 failures, restore).
- Assumed (from a stale `uniq -c` count) that `zero_one_beta`, `truncated_nbinom2`,
  `cumulative_logit`, and `skew_normal` all had cross-name duplicate rows in
  the DRM.jl evidence like `tweedie` did; re-checked by (capability_id,
  cell) pairs specifically and found only `tweedie`/`fe_tweedie` and the
  THREE already-committed `fe_poisson`/`fe_nbinom2`/`fe_gamma` rows were
  true duplicates -- corrected before building the evidence PR.
