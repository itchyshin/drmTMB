# After Task: Arc 3 — Fixture Construction

Meta: 2026-08-02 · Claude · branch `claude/arc3-fixture-construction` · PR #900

## 1. Goal

Build or repair the fixtures blocking the remaining reachable Prong A cells, then promote whichever earn
it under the Arc 2 contract — with a **point-fit recovery gate passed before any profile is run**.
Arc 2 had established that these cells were blocked on fixtures, not compute: Totoro sat idle throughout it.

## 2. Implemented

**Six cells promoted**, model-surface tiers **167/71 → 173/66** (the denominator moved mid-arc when
`main` gained cells from PRs #893 and #901; the arithmetic was re-derived from merged data, not assumed).

| Cell | Target | Est | Seeds | Result |
|---|---|---|---|---|
| mc-0283 | `sd:sigma:sigma:phylo(1 \| p \| species)` | REML | 3 | 0.673 / 0.580 / 0.811, true 0.7 |
| mc-0421 | `sd:sigma:phylo(1 \| species)` | ML | 3 | 0.560 / 0.489 / 0.377, true 0.55 |
| mc-0422 | `sd:sigma:spatial(1 \| site)` | ML | 3 | 0.483 / 0.416 / 0.437, true 0.55 |
| mc-0424 | `sd:sigma:relmat(1 \| id)` | ML | 3 | 0.371 / 0.490 / 0.396, true 0.55 |
| mc-0321 | `sd:mu:phylo_interaction(1 \| plant:pollinator)` | REML | 5 | all bracket true 0.6 |
| mc-0409 | same target, nbinom2 | ML | 5 | all bracket true 0.6 |

**One cell retained as a diagnosed STOP: `mc-0423`** (`sd:sigma:animal(1 | id)`).

New fixtures: `tools/arc3-nbinom2-sigma-provider-fixtures.R` (four provider-specific NB2 DGPs),
`tools/arc3-phylo-interaction-fixtures.R`, and a q2 extension in `tools/arc2-phylo-sigma-fixtures.R`.

## 3a. Decisions and Rejected Alternatives

**The contract checks interval *shape*; it cannot check interval *location*.** This is the arc's central
lesson. Both `mc-0423` and `mc-0409` reconciled mechanically (3/3 and 5/5, `conf_status = "profile"`,
`pdHess` TRUE, unclamped) while containing a member interval that **excluded the true value**. Only
Fisher's review caught them.

That produced a **tightened standing contract**, adopted mid-arc:
- **minimum five seeds**, not three;
- the point-fit gate and the promoted campaign must **share one seed family** (mc-0423's gate had run on
  seeds 423/523/623 while its campaign ran 2026080301-03, so its fragile seed was never gated at all);
- **any single seed** with >0.35 relative error *or* an interval excluding the true value triggers
  mandatory root-cause diagnosis before promotion — even if the mean passes.

The rule caught `mc-0409` on its first application.

**Redesigning a DGP after a failure is legitimate only under conditions.** Fisher ruled it acceptable
here because (a) each failure was root-caused with an independent falsifiable diagnostic rather than
re-rolled until green, (b) the true parameter value was held fixed, and (c) rejected alternatives were
documented. It would **not** hold if the redesign moved the target scale, or if post-redesign evidence
reused only seeds already known to pass.

## 4. Files Touched

`tools/arc3-*`, `tools/arc2-phylo-sigma-fixtures.R`, `tools/run-arc2-profile-feasibility.R`,
`tools/arc2_profile_reconcile.py`, `tools/capability_ledger.py` (guard), `tools/tests/test_capability_ledger.py`,
the three ledger TSVs, and receipts under `docs/dev-log/interval-feasibility/results/`.
**No `R/`, `src/`, `tests/testthat/`, `NEWS.md`, `README.md` or vignette file was changed.**

## 5. Checks Run

`python3 -B tools/capability_ledger.py --check` → OK (30 generated outputs) · tooling tests → OK ·
per-cell reconciliation → PASS · adversarial guard check after **every** batch (a further promotion
always fails; most recently *"71 (expected 72)"*) · Fisher target-level review · Rose closeout (Arc 2).

## 6. Tests of the Tests

The guard was verified adversarially four separate times as the constant walked 71 → 73 → 66 → 73 → 72,
each time by flipping a real un-promoted frozen cell and confirming `--check` fails. On one occasion the
probe used `mc-0421` — the very cell that had failed its first cohort.

## 9. What Did Not Go Smoothly

**Three root-caused DGP defects**, each a numerical-conditioning problem rather than an estimator bug:

1. **`ape::rcoal()` coalescent trees are intrinsically ill-conditioned** for `sd:sigma:phylo` — condition
   number 98,563; a 61-seed scan found 33,000–540,000 for *every* alternative, and raising `n_tip` made it
   **worse** (up to 540,883), because near-tip coalescent events pile into near-duplicate tip pairs.
   Grafen branch lengths: 183.
2. **Finite-sample correlation between independently drawn intercept and slope effects** (`mc-0424`,
   max |cor| 0.457 at `n_id = 40`) produced an alternate local optimum mid-sweep that broke profile
   interpolation. `n_id` → 80 reduced it to 0.135.
3. **An NB2 dispersion/SD confound** (`mc-0409`, `cor(sigma_hat, sd_hat) = −0.74`): the failing seed paired
   a low dispersion estimate with the highest SD estimate. `n_each` 8 → 24 resolved it.

A spiral spatial layout was also rejected in design for collapsing the intercept SD; the 9×9 grid is
load-bearing.

**`mc-0423` remains undiagnosed and is honestly recorded as such.** The relmat mechanism was **ruled out** —
its cor(v0,v1) at the failing seed was −0.142, unremarkable against a 10-seed max of 0.515, and the
pedigree's condition number is 66.7. Enlarging `n_founders` improved the worst case from 49% to 40% error
but still fails 4/5 on the bracketing gate. It is kept as an improvement, not a fix.

**A provenance inconsistency worth fixing later:** receipts carry an internal `source_sha` equal to the
git HEAD at run time, while the ledger records `ARC3_SOURCE_SHA`. These differ (e.g. `973db75b` and
`438f873c` vs `a34bb750`) because `--check` requires one anchor for all `ARC3_TARGETS` rows. Two separate
agents flagged it independently. The raw receipts preserve the true SHA, so nothing is lost, but the
convention should be reconciled.

## 7a. Issue Ledger

No issue opened, closed or commented.

## 10. Carried Over

- **`mc-0423`** — needs a mechanism beyond the two already ruled out.
- **`mc-0123`** — a real distinct cell (`mu1` vs `mu2` of a q6 spatial block; `mc-0124` is its already-
  promoted sibling). The Arc 0 manifest cites `tools/b2-q6-q12-admission-contracts.R`, which **does not
  exist in this tree** — a further manifest defect. It needs its own `mu1` fixture.
- **`mc-0417`** — decision: **BIND** to spatial+relmat, matching the only existing recovery evidence.
  Splitting would add five cells with none.
- **`mc-0207`** — decision: **SPLIT**, per the C14 precedent. Raises the denominator, so the post-split
  census must be reported rather than pre-promised.
- **`mc-0205`/`mc-0206`** — `sim3()` monkey-patches `drm_validate_reml_spec_biv`; determine why that gate
  exists before treating anything built through it as evidence.
- **Prong B** — 14 zero-one-beta fence cells; its own arc (420–700 fits plus a package change).

Ceiling remains **193**.
