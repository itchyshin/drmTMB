# Arc A — external-comparator evidence made visible in the ledger

Date: 2026-07-25 · Branch: `claude/arc-a-external-comparator-evidence` · Base: `origin/main` `eabca4fd`

## 1. Purpose

Cross-package validation was happening and was invisible to the capability ledger.
`tests/testthat/test-comparators.R` holds 1,245 lines of agreement tests against `lme4`,
`glmmTMB`, `metafor`, `MASS::glm.nb` and base `glm`, yet exactly one implemented cell
cited a comparator. There was no field such a result could be recorded in. This arc added
the field, recorded four results, landed the approved `meta_V` route row, corrected an
error in the governing comparator design doc, and triaged the whole `point_fit_recovery`
pool.

## 2. Boundary

**Does NOT cover.** No interval, coverage, bias, recovery or small-sample calibration
claim is made or implied. No cell was promoted. No simulation, recovery or coverage
campaign was run, and none is authorised by this work. No Totoro or DRAC compute was used.
No frontier route gained evidence, because no external comparator exists for structured,
scale-side, bivariate or phylogenetic routes.

**Two of Arc A's four scoped slices were not done.** The arc as briefed was: define the
tier, build the comparator mapping, **sweep the overlap region**, and **publish a
vignette**. Slices 1 and 2 shipped. Slices 3 and 4 did not. The 14 parity-eligible cells
with no comparator evidence are a backlog, not a validated capability.

## 3. What actually happened

The brief's premise did not survive checking, and the arc got smaller and more honest.

- The brief said 158 stuck cells could be retired cheaply by parity. In fact 122 are
  `structured`, 18 are `response_missingness`, and 7 are non-structured bivariate — none
  has an external comparator. **Parity can reach roughly 15 cells, not 158.** The
  throughput justification was dropped.
- 146 of the pool carry `next_gate = "Preserve the existing model-surface evidence tier."`
  The pool is largely *parked by intent*, not stuck.
- The brief named `meta_V` as the first target but claimed it needed a new route axis. An
  approved draft already on `main`
  (`docs/dev-log/handover/2026-07-21-mc-0260m-ledger-cell-draft.md`) showed the
  `route_modifier` discriminator already exists, making it a row insert. The reason for
  fencing it was wrong; the fence was lifted on the owner's decision.
- A candidate set of 8 cells was cut to 3 by a line-by-line audit (§5).

## 4. Diagnosis before repair

Three findings changed the design before any code was written.

1. **A tier was the wrong instrument.** `evidence_tier` is a single ordered scale of
   inferential strength and `TIER_ORDER` drives family-map selection. Comparator
   agreement is orthogonal to it: `mc-0227` and `mc-0242` are inference-ready with no
   comparator, while `mc-0260` has near-exact agreement and sits at `point_fit_recovery`.
   `evidence.tsv` already provided a one-to-many join and a `claim_boundary` field doing
   exactly the "what this does not cover" job. Recorded in
   `docs/design/242-external-comparator-evidence-class.md`.
2. **`parity_status` is already taken** — 31 occurrences in
   `tools/validate-mission-control.py`, meaning DRM.jl-bridge parity. Hence
   `external_comparator`.
3. **`docs/design/158` was wrong.** Its Gaussian row told readers to compare `sigma^2`
   against `glmmTMB`; `dispformula` coefficients are on `log(sigma)`, and
   `test-comparators.R:780-784` compares unsquared and passes. The test was right and the
   design doc was wrong, so any record built from doc 158 would have inherited the error.

## 5. Validation

Commands run in this worktree, all passing:

- `python3 tools/capability_ledger.py --check` → `OK (30 generated outputs)`, on an
  untouched tree **before** any edit and again after.
- `python3 -m unittest tools.tests.test_capability_ledger` → **41 tests OK** (38 at base).
- `Rscript tools/check-capability-runtime.R` → `OK (18 routes; verified=18)`.
- `NOT_CRAN=true Rscript -e 'devtools::test(filter="comparators")'` → **126 assertions,
  zero failures, zero skips**. The zero-skips result matters: `skip_if_not_installed()`
  guards these tests, so a missing package would have made them pass vacuously.
- Tier invariant checked directly by diffing every cell's tier between `origin/main` and
  `HEAD`: **zero pre-existing cells changed tier, zero removed, one added.**

The candidate audit cut 8 cells to 3, independently confirmed by two reviewers:

| Cell | Verdict |
| --- | --- |
| mc-0265 (gaussian mu re-intercept REML) | wired — lme4, **strong** independence |
| mc-0429 (poisson mu re-intercept ML) | wired — lme4, **strong** |
| mc-0260 (gaussian mu fixed ML) | wired — glmmTMB, **weak** (shared TMB/AD stack) |
| mc-0261, mc-0263 | **dropped** — no REML fixed-effect comparator test exists at all |
| mc-0269 | **dropped** — nearest test fits a *correlated* slope; the cell is *independent* |
| mc-0431 | **dropped** — test fits `(1\|id) + (0+x\|id)`; the cell is slope-only |
| mc-0262 | **quarantined** by owner decision (open M=64 threshold objection) |

Plus `mc-0260m`, wired to five metafor tests — the strongest and most independent evidence
in the arc.

## 6. Claim discipline

Every `external_comparator` row states in its own `claim_boundary` that it establishes no
interval and no coverage claim and rests on a single-seed fit; a test enforces those words
are present. Badges render independence strength (`lme4 (strong)`, `glmmTMB (weak)`) and
the surface carries a legend saying a blank cell often means no comparator *exists*.
`reviewed_by` was left empty until the gate actually ran, rather than asserted in advance.

The public surface moved 676→677 cells, 306→307 implemented, 158→159 recovery-grade.
`supported` (4), `inference-ready` (27) and `interval-feasible` (44) are **unchanged**.

**Deviation from the stated discipline, declared.** The session goal said the
`point_fit_recovery == 158` assertion must be unchanged. It is now 159, because a row was
*inserted* at that tier. The invariant that matters — no cell moved tier — was verified
directly. Three hard-coded counts were updated deliberately, each with the reason in a
comment beside it.

## 7. Risks and limitations

- Comparator agreement is agreement between two *implementations*, not a check against
  truth. The inbound brief's phrase "bugs found against ground truth" was retired.
- `glmmTMB` shares drmTMB's TMB/AD stack, so `mc-0260`'s check is weaker than the lme4
  ones. Labelled, not hidden.
- `mc-0260m` discloses a measured degeneracy: at K=12 with true `tau = 0.10` the fitted
  `tau` pins near 1e-6 and `confint()` returns `[0, Inf]`. That warning currently survives
  only as prose; no machine gate enforces it, consistent with how the other
  `point_fit_recovery` cells are governed.
- The generated 12-column census omits `route_modifier`, so `mc-0260` and `mc-0260m` share
  a structural key. This is a pre-existing weakness — 46 such duplicate keys exist, 45 of
  them predating this branch — not a defect introduced here.

## 8. Corrections to my own record

- Commit `d018bc23`'s message is **wrong** and was superseded by `1ce82fab`. It says "176
  cells, parity_eligible 17, evidenced 3" and that `comparator_package` names glmmTMB for
  mc-0265/mc-0429. The committed file has **177 rows, 18 eligible, 4 evidenced**, and
  names **lme4** for both. History was not rewritten; this note is the correction.
- I asserted 146 parked cells; the reconciled figure is **132**. Fourteen preserve-tagged
  cells are also parity-eligible and are reported as eligible.
- I committed a partial triage file by running `git add -A` while an agent was still
  writing it. Split into its own commit and superseded.
- A reviewer reported that `schema.json` is generated by `--write` and that my hand-edit
  was unnecessary. That is **incorrect**: `SCHEMA` appears only in `load_sources()` (read
  and compare) and is written solely by `bootstrap()`, which refuses once the files exist.
  The hand-edit was required; it is now done by calling `schema_value()` directly.

## 9. Follow-up

- Sweep the overlap region: 14 parity-eligible cells have no comparator evidence yet.
- Write the user-facing vignette (Arc A slice 4).
- Resolve or close `mc-0262`'s M=64 threshold objection.
- Consider whether the census should carry `route_modifier`, given 46 duplicate keys.
- `docs/design/48-phase-18-meta-v-ademp.md` must be amended before any `meta_V` interval
  or coverage promotion, per `mc-0260m`'s `next_gate`.
