# After Task: Arc 7b — the profile-interval truth gate

## Task Goal

Install a machine-enforced truth gate across the 31-cell profile-interval
contract surface, demote the cells that fail it with the mechanism recorded,
and open a triage item for the family-level low bias the sweep exposed.

The defect: the reconcilers check interval **shape** exhaustively —
`conf_status`, `convergence`, `pdHess`, `profile_boundary`, `clamp_limited`,
`trace_complete`, `failure_reason` — and check interval **location** not at
all. They could not. The runner recorded the true parameter value only as
prose, e.g. `true_parameter_scale = "0.55 phylogenetic random-intercept SD on
log(sigma) (NB2 dispersion), independent of a 0.20 phylogenetic random-slope
SD ... 30 observations per tip"`. Four numbers in one sentence, one of which
is the truth, and no numeric field to compare `lower <= truth <= upper`
against.

`capability_ledger.py:205-208` already named this in a comment —
*"reconcile() never reads a true value -- only a human check against the DGP's
known truth caught this"* — but naming it is not enforcing it. **Five** cells
reached review holding an interval that excluded their own true value while
passing every shape check. `mc-0292`, `mc-0409` and `mc-0423` were caught by a
human reading the prose. `mc-0424` and `mc-0260m` were not, and shipped as
`interval_feasible` — which is what this arc withdraws.

## Files Created or Changed

**New (4):**

- `tools/profile_truth_gate.py` — the gate: manifest loading, per-seed
  bracketing, the per-cell magnitude/count rule, fail-closed errors.
- `tools/emit-profile-truth-manifest.R` — derives truth by sourcing the
  runner's own `cell_registry` and calling each contract's fixture builder;
  `--check` mode for CI drift detection.
- `tools/profile-truth-manifest.tsv` — the derived manifest, 30 rows.
- `tools/tests/test_profile_truth_gate.py` — 19 tests sweeping the surface.

**Changed (19)** — the substantive ones:

- `tools/run-arc2-profile-feasibility.R` — `true_value` accessor on all 25
  contracts; `true_value` and `brackets_truth` columns on new receipts.
- `tools/arc2_profile_reconcile.py` — pinned `information_rung` + `seeds` on
  all 26 contracts; gate called at reconcile time; `--seeds` may no longer
  narrow the denominator.
- `tools/arc1_profile_reconcile.py` — docstring recording why the Arc 1
  reconcilers deliberately do *not* call the gate.
- `tools/capability_ledger.py` — `mc-0424` unbound from `ARC3_TARGETS`,
  `mc-0260m` from `ARC1_ADDITIONAL_TARGETS`, `FROZEN_CENSUS_POINT_FIT_RECOVERY`
  58 → 59.
- `tests/testthat/test-reml-{bivariate,heteroscedastic,phylo-location}.R` —
  three fixtures that hardcoded their truth now expose it as a parameter.
- The three ledger TSVs, six regenerated dashboard outputs,
  `parity-triage.tsv`, `test_capability_ledger.py`, and the CI workflow.

## Checks Run and Exact Outcomes

The full CI sequence, run verbatim from `.github/workflows/R-CMD-check.yaml`:

```
python3 tools/capability_ledger.py --check          capability-ledger: OK (30 generated outputs)
python3 -m unittest .../test_capability_ledger.py   Ran 51 tests  OK
python3 -m unittest .../test_arc1_profile_reconcilers.py  Ran 3 tests  OK
python3 -m unittest .../test_b3_q6_target_promotion.py    Ran 3 tests  OK
python3 -m unittest .../test_profile_truth_gate.py        Ran 19 tests OK
Rscript tools/emit-profile-truth-manifest.R --check  profile-truth-manifest: OK (30 rows)
Rscript tools/check-capability-runtime.R             capability-runtime: OK (18 routes; verified=18)
```

Package tests for the three touched fixtures, run with `NOT_CRAN=true` (they
`skip_on_cran()` and pass vacuously without it — worth knowing):
`test-reml-bivariate.R` 33 assertions, `test-reml-heteroscedastic.R` 9,
`test-reml-phylo-location.R` 12. All pass.

**Metric movement:** `model_surface` `interval_feasible` **184 → 182**;
`point_fit_recovery` 58 → 60 (whole model) and 58 → 59 (frozen ≤676 window).
The two counts diverge here for the first time, because `mc-0424` is
source_order 424 (inside the frozen window) and `mc-0260m` is 694 (outside).

## Tests of the Tests

Every guard was shown to fail before being trusted:

| Adversarial mutation | Expected | Observed |
| --- | --- | --- |
| Promote `mc-0422` to `inference_ready_with_caveats` in `cells.tsv` | `--check` fails | `mc-0422: Arc 3 target row changed`; all 51 ledger tests error |
| Change `arc3_..._relmat_fixture`'s `true_sd_intercept` 0.55 → 0.60 | manifest `--check` fails | `STALE`, exit 2 |
| Same, after regenerating the manifest | gate test fails | `mc-0424: derived truth disagrees with its own receipt prose` |
| Delete `profile-truth-manifest.tsv` | `--check` fails | `MISSING`, exit 2 |
| Blank / unparseable / non-finite / absent truth | `TruthGateError` | all four raise |
| Empty seed set, non-finite endpoint, inverted interval, zero truth with degenerate interval | `TruthGateError` | all four raise |

Exit codes were verified directly rather than through a pipeline (`tail`
swallows the status): OK → 0, STALE → 2, MISSING → 2.

The three known-bad cohorts fail the gate and the one repaired cohort passes,
asserted as tests rather than observed by eye: `mc-0423` (12.8% miss),
`mc-0424` (6.3%), `mc-0260m` (16.8%) fail; `mc-0409`'s repaired five-seed
`each24` family passes 5/5.

## The Triage Item, and a Correction to Its Headline Number

`docs/dev-log/after-task/2026-08-03-nbinom2-structured-sigma-family-low-bias.md`
records the family-level finding: 11 of 12 retained estimates across
`mc-0421`/`mc-0422`/`mc-0423`/`mc-0424` fall below the true 0.55, one-sided
sign test p = 0.0032 (two-sided 0.0063).

Fisher's review **qualifies that number, and the qualification is
first-order.** The twelve fits are not twelve independent draws. Verified
independently here, in base R with no drmTMB code involved: for each of the
three shared seeds, the raw `rnorm(80, sd = 0.55)` structured-intercept draw is
**numerically identical** between the phylo and relmat fixtures, and the
animal fixture's `rnorm(40, …)` is a **prefix of that same stream**. The four
cells share the seed labels, the DGP template, and the random-number entry
point; only the covariance transform differs.

At the defensible unit of replication — the cell, of which there are four —
all four are majority-below, and the one-sided sign test gives
**p = 1/16 = 0.0625**, which does not clear 0.05. So the evidence moves from
"p ≈ 0.003" to "p ≈ 0.06" once clustering is respected. That is a far larger
correction than the one-sided/two-sided choice (0.0032 vs 0.0063), and it is
the one that should be quoted alongside the headline.

The direction is consistent across every view (4/4 cells, mean signed
deviation −20.9%), so the pattern is real enough to chase; it is not yet
statistically established at the level the raw twelve make it look. Four
independent DGP designs are too few for any method to give a well-calibrated
p-value. The note carries five candidate explanations, each with the cheapest
discriminating experiment, and a drafted GitHub issue.

**A second provenance gap, same class as `mc-0282`.** Fisher found that
`mc-0423`'s retained receipts were produced under `n_founders = 4` (a
40-individual pedigree), not the `n_founders = 8` the runner now defaults to —
and that the receipts' `source_sha` cannot distinguish the two, because it
records `git rev-parse HEAD` at run time on a working tree that had
uncommitted edits. This is the same defect as `mc-0282`'s missing contract:
a receipt whose `source_sha` does not pin the code that produced it. Both are
reported, neither is fixed here.

## An Adjacent Defect Found While Verifying (not introduced here)

Running the Arc 2 reconciler end-to-end against retained receipts fails before
the truth gate is reached, at the `runner_sha256` check — the reconciler binds
each receipt to the *current* `run-arc2-profile-feasibility.R` on disk.

This is **pre-existing**, not a consequence of this arc. The retained arc3
receipts record `runner_sha256 = a88195f2…`, and `origin/main`'s runner already
hashed to `76f62be4…` before any edit in this arc. Retained receipts also
disagree among themselves (`mc-0423`'s record `fc4fc368…`, `mc-0421`/`mc-0424`'s
`a88195f2…`), so no single runner version reconciles the whole surface. Editing
the runner here moved the hash again, from `76f62be4…` to `3d9167f7…`, but the
reconciler was already unable to reconcile these cohorts.

Nothing in CI depends on it: CI runs the *Arc 1* reconcilers (whose runners were
not touched — 3 tests still pass) and the new sweep, which reads receipts
directly rather than through the Arc 2 reconciler.

To prove the gate really is reached and not merely unit-tested, the three
cohorts were copied to a temp tree with **only** `runner_sha256` repointed at
the current runner, leaving every fixture/trace/interval hash untouched and
self-consistent:

```
mc-0421   rc=0  mc-0421  sd:sigma:phylo(1 | species)  3/3  PASS
mc-0424   rc=1  Arc 2 truth gate: mc-0424: interval excludes truth 0.55 by more
                than 5% of scale at seed(s) 2026080301 (6.3%)
mc-0423   rc=1  Arc 2 truth gate: mc-0423: ... at seed(s) 2026080302 (12.8%)
```

Whether the Arc 2 reconciler should pin a historical `source_sha` the way the
Arc 1 scripts do — rather than requiring the live file to match — is an owner
decision and is **not** resolved here. It is the same class of question as the
un-wired B4-CI `BASE_COMMIT` pins.

## Consistency Audit

Exact patterns run:

```sh
grep -rn "184 interval\|184 interval-feasible\|interval_feasible.*184" --include="*.md" --include="*.Rmd" --include="*.yml" .
grep -rn "mc-0424\|mc-0260m" --include="*.md" --include="*.Rmd" --include="*.yml" --include="*.R" .
grep -n "interval-feasible\|interval_feasible" README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md
grep -n "184" ROADMAP.md docs/design/{248,82,218,41}-*.md
```

Findings: no hand-authored file states a tier count of 184
(`ROADMAP.md:1758`'s "184" is a numbered roadmap item; the design-doc hits are
unrelated). `AGENTS.md:129` mentions `mc-0260m` but describes its row landing,
not its tier. The `mc-0424` references in
`tools/arc3-nbinom2-sigma-provider-fixtures.R` are historical design
commentary and remain accurate as history.

One stale text **was** found and fixed: `parity-triage.tsv`'s `mc-0260m` row
asserted under a "DATED SUPERSESSION (2026-08-02)" clause that the meta_V
contract "supports interval_feasible". `validate()` enforced that wording
(`capability_ledger.py:2106-2129`) only while `mc-0260m` sat in
`ARC1_ADDITIONAL_TARGETS`; unbinding it would have left the false sentence
unchecked. It now records the withdrawal.

Two comments in `tools/arc2-phylo-sigma-fixtures.R:90` and
`run-arc2-profile-feasibility.R:239` say `reml_phylo_location_fixture()` has
"NO true sigma-phylo signal". Checked: still accurate — the fixture gained a
mu-side `true_sd_phylo`, and the comments are about the sigma side.

## What Did Not Go Smoothly

**Seed pinning alone was not enough, and nearly shipped that way.**
`mc-0409`'s superseded `n_each=8` cohort and its repaired `n_each=24` family
use the *same seed numbers* (2026080401–05). A seed-only pin silently
readmits the cohort the repair replaced, and one of those receipts misses
truth. The discriminator is `execution_information_rung`, and the contract now
pins both. This was caught by enumerating cohorts per cell before writing the
pins, not by the tests.

**`mc-0263` would have been silently skipped.** Its true `fixef:sigma:x` is a
structural zero — the DGP puts the sigma effect on `z`, not `x` — so its
truth prose does not begin with a number and any "parse the leading number"
heuristic drops it. An early draft of the sweep did exactly that and reported
a vacuous pass. The gate now fails closed on unusable truth, and the zero case
scales misses by the interval half-width instead of by `|truth|`.

**The requested "31-cell contract surface" initially looked wrong.** The arc2
reconciler has 26 contracts, and a first count reported 26, not 31. The
missing five are the Arc 1 cells spread across four separate
`reconcile-arc1-*.py` scripts. The figure was right; the first count was one
reconciler family short.

## Team Learning and Process Improvements

**A guard's definition of done includes the line in CI that runs it** — the
standing lesson from `2026-08-03-b4-ci-mc-0207-pin-drift.md`, applied here in
the same change that wrote the guard, not after it. The workflow's header
comment was updated from "seven test files, three wired" to "eight, four".

**Fail-closed beats fail-quiet, and the difference is invisible in a green
run.** A skipped cell and a passing cell look identical in test output. Every
"cannot evaluate" path here raises.

**An exemption list is how a gate stops gating.** `mc-0282` cannot be gated
(below), so it sits in an `UNGATED` set — with a test asserting that set is
*exactly* `{"mc-0282"}`, so a second entry is a reviewable edit rather than a
silent omission.

## Design-Doc Updates

None required. This arc changes no grammar, likelihood, family, random-effect,
phylogenetic, spatial, or meta-analysis behaviour — it adds a check over
existing evidence and withdraws two claims. The reasoning that would otherwise
belong in a design note is recorded where it binds: the gate rule and its
calibration in `tools/profile_truth_gate.py`'s module docstring, the Arc 1
non-wiring decision in `tools/arc1_profile_reconcile.py`'s.

## pkgdown / Documentation Updates

None. No user-facing function, argument, or vignette changed. The regenerated
`capability-surface.{md,html}` and census TSVs are build artifacts of
`capability_ledger.py --write`, not hand-authored docs.

## GitHub Issue Maintenance

**No issue was opened or closed by this task**, and no existing open issue
matched it — this was a tooling/guard change surfaced from within the
interval-feasibility programme rather than a tracked feature request.

Two items **should** become issues and are drafted rather than filed, because
opening them is the owner's call:

1. **The nbinom2 structured-sigma family low bias** — 11 of 12 estimates below
   truth across `mc-0421`/`mc-0422`/`mc-0423`/`mc-0424`, one-sided sign test
   p = 0.0032. Drafted in
   `docs/dev-log/after-task/2026-08-03-nbinom2-structured-sigma-family-low-bias.md`,
   which carries its own Issue Ledger with a proposed title and body.
2. **`mc-0282` has no committed runner contract** (below).

## Known Limitations and Next Actions

**`mc-0282` is ungated, and the reason is a real gap.** It holds an
`interval_feasible` claim on five retained receipts whose `binding_source`
names `tools/run-arc2-profile-feasibility.R` — but that runner has **never**,
in any commit, carried an `mc-0282` registry entry (verified across the
runner's history). Its receipts were produced by a contract that was never
committed, so there is no committed accessor to derive truth from, and writing
one here would be *declaring* a truth rather than deriving it — the exact
practice this arc removes.

Checked by hand against the truth its fixture does expose
(`arc2_phylo_sigma_q2_fixture`'s `true_sd_mu = 0.6`, the mu-side sibling of the
value `mc-0283` uses): **all five seeds bracket it**, so the claim is not in
doubt and the count stays at 182. The gap is reproducibility, not correctness.
Restoring the runner entry needs someone who can confirm what actually ran.

**The gate scores retained receipts, not coverage.** Bracketing 3–5 seeds is
not a coverage claim and must not be read as one. Nothing here licenses a
coverage, calibration, inference-ready, or CRAN statement.

**Two demoted cells could return.** Both keep their point-level evidence and
would be re-promotable on a re-run cohort that brackets truth on every
retained seed. For `mc-0424` the family-level bias question should be settled
first, since a systematic downward bias would make a passing re-run less
informative than it looks.

**Housekeeping:** `tools/profile-truth-manifest.tsv.bak`, a scratch artifact
identical to the live manifest, is present and untracked. The harness blocked
its deletion; it needs a human `rm` and must not be staged.

**Not in this arc, unchanged:** any `R/` source change (Prong B), the 14-cell
Tier-1 campaign, the Tier-2 `zoi` and structured-`mu` pilots, any `coi` fence,
the q12 policy decision, and re-running the four diagnosed STOPs.
