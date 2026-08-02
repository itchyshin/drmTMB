# After Task: Arc 2 First Interval-Feasibility Tranche

Meta: 2026-08-02 · Claude · branch `claude/arc2-interval-feasibility` · base `origin/main@83055ec5`

## 1. Goal

Convert as many drmTMB model-surface cells as could be honestly earned from `point_fit_recovery` to
`interval_feasible`, reusing the Arc 1 (PR #896) one-profile receipt contract. This is an
interval-**existence** claim only; coverage and calibration are withheld throughout.

## 2. Implemented

Four cells promoted, model-surface tiers **161/77 → 165/73**:

| Cell | Target | Estimator | Totoro seeds | Estimates | Intervals |
|---|---|---|---|---|---|
| mc-0186 | `rho12` | REML | 3/3 | 0.368 / 0.387 / 0.360 | [0.221,0.499] [0.242,0.515] [0.212,0.492] |
| mc-0263 | `fixef:sigma:x` | REML | 3/3 | −0.020 / −0.081 / 0.048 | [−0.170,0.125] [−0.239,0.076] [−0.114,0.211] |
| mc-0274 | `sd:mu:phylo(1 \| species)` | REML | 3/3 | 0.939 / 0.698 / 0.725 | [0.586,1.495] [0.419,1.107] [0.422,1.214] |
| mc-0277 | `sd:sigma:phylo(1 \| species)` | REML | 3/3 | 0.860 / 0.477 / 0.556 | [0.598,1.221] [0.306,0.758] [0.370,0.851] |

`mc-0277` is the payoff from the §9 defect finding. It was prescribed a fixture with **no true
sigma-phylo signal**, under which its boundary-collapsing profile was a null-case artifact. Re-run on a
signal-bearing DGP (`tools/arc2-phylo-sigma-fixtures.R`, `n_tip = 60`, `n_each = 12`, true log-SD 0.7) it
satisfies the same contract 3/3, with the true value inside all three intervals. Had the manifest been
followed, this cell would have been recorded as a permanent capability STOP.

All nine runs: `convergence = 0`, `pdHess = TRUE`, `profile_boundary = FALSE`, `clamp_limited = FALSE`,
`trace_complete = TRUE`, `conf_status = "profile"`. True values: rho12 = 0.4; phylo SD = 0.6 (all three
mc-0274 intervals contain it); mc-0263's x-coefficient on sigma is exactly 0.

New tooling: `tools/run-arc2-profile-feasibility.R` (cell-parameterised runner with a contract registry
that rejects a CLI/registry mismatch), `tools/arc2_profile_reconcile.py`, `tools/run-arc2-totoro-campaign.sh`,
`tools/arc2-beta-animal-fixtures.R`.

## 3a. Decisions and Rejected Alternatives

**A fixed effect at zero is promotable; a variance component at zero is not.** mc-0263's target has true
value 0. Fisher accepted it because a fixed effect lives on an unconstrained real line, where 0 is an
interior point and profile regularity holds. A variance component's 0 sits at the boundary of `[0, ∞)`,
where the asymptotics are non-regular. That distinction is what separates mc-0263 (promoted) from
mc-0277/mc-0283 (withheld), and it is recorded in the claim boundary so no reader infers recovery.

**The frozen-census guard was strengthened, not relaxed.** Promoting frozen cells required moving
`FROZEN_CENSUS_POINT_FIT_RECOVERY` 77 → 74, following Arc 1's own precedent (`1b6fd3dbd`, 82 → 77).
Rather than only lowering the number, `ARC2_TARGETS` now binds each promoted cell to its exact target,
evidence row, and transition. Verified adversarially: flipping a fourth frozen cell still fails
`--check`.

**Rejected:** promoting mc-0013/mc-0015 (pass locally but on an 8-individual pedigree; mc-0013 estimates
0.280 against a true 0.55). Rejected: recording mc-0277/mc-0283 as capability STOPs (see §9).

## 4. Files Touched

`tools/run-arc2-*`, `tools/arc2_*`, `tools/capability_ledger.py` (guard), `tools/tests/test_capability_ledger.py`,
the three ledger TSVs, `parity-triage.tsv`, and the regenerated census/surface artifacts, plus receipts
under `docs/dev-log/interval-feasibility/results/83055ec5.../arc2-profile-feasibility/totoro/`.

**No `R/`, `src/`, `tests/testthat/`, `NEWS.md`, `README.md`, or vignette file was changed.** Package
behaviour is untouched, which is why no `R CMD check` was required for this tranche.

## 5. Checks Run

- `python3 -B tools/capability_ledger.py --check` → `OK (30 generated outputs)`
- `python3 -m unittest tools.tests.test_capability_ledger tools.tests.test_arc1_profile_reconcilers` → 53 tests, `OK`
- Per-cell reconciliation → `3/3 PASS` for each of the three cells
- Adversarial guard check → a fourth promotion fails: *"frozen census point_fit_recovery changed: 73 (expected 74)"*
- `git diff --check` → clean
- Fisher: GO per target, with required claim wording. Rose: GO-WITH-CHANGES, all three blocking items addressed.

## 6. Tests of the Tests

`arc2_profile_reconcile.py` was run against four deliberately mutated copies of a passing receipt trio —
estimator flipped REML→ML, target renamed, one endpoint shifted, runner hash zeroed. All four were
rejected. The adversarial frozen-census check above is the equivalent test for the ledger guard.

## 8. Consistency Audit

Rose searched README, NEWS, ROADMAP, known-limitations, parity-triage, and the claim boundaries. Three
statements contradicted the promotion and were **replaced, not appended** (Arc 1's after-task records
appending as its own defect): `cells.tsv`'s mc-0263 "exact under REML" annotation, and the "no
interval/coverage campaign is being pursued" sentences for mc-0186 and mc-0274.

## 9. What Did Not Go Smoothly

**The Arc 0 manifest prescribes fixtures without checking they carry the target.** Full write-up:
`scratchpad/2026-08-02-arc2-manifest-fixture-defect.md`. Four failure modes:

1. **Signal-free fixture for a variance component** — mc-0277 and mc-0283 were prescribed
   `reml_phylo_location_fixture()`, whose DGP puts the phylogenetic effect only on the mean, so the true
   sigma-phylo SD is exactly 0. Their boundary-collapsing profiles are correct-under-null, **not**
   capability limits, and must not be recorded as STOPs. With a signal-bearing DGP (n_tip 60, n_each 12,
   true 0.7) the same target profiles cleanly across three seeds.
2. **Cell absent from the fixture registry** — mc-0123's prescribed call errors; the frozen row is
   mc-0124/`mu2`, not mc-0123/`mu1`.
3. **Named coefficient absent from the cited model** — mc-0263 (benign here, but the ledger annotation
   was wrong and is now corrected).
4. **Fixture does not exist** — 7 cells.

Only **3 of the 18** "remaining executable" cells were executable as prescribed.

**Driver delimiter collision.** The campaign driver originally split its cell spec on `|`, which is a
literal character inside random-effect targets (`sd:mu:phylo(1 | species)`). Every field shifted and all
three mc-0274 runs died on argument validation. Changed to `^`. The Totoro smoke caught this before the
batch, which is exactly why the smoke-first rule exists.

**Two agent reports needed verification rather than trust.** One reported post-refactor estimates as
"unchanged" when they came from a different seed (reproducibility was intact — the label was wrong). One
reported ledger edits as complete when `--check` still failed on the frozen-census guard. Both were
caught by re-reading the artifacts directly.

## 7a. Issue Ledger

No issue opened, closed, or commented. Issue #682 ("profile likelihood as the featured CI method")
remains the nearest overlap; this tranche supplies internal target-level feasibility evidence and does
not change the public profile method.

## 10. Carried Over

- **mc-0013 / mc-0015** — pass locally; the 8-individual pedigree must be rebuilt at a larger design
  (Arc 1's SD targets used 30–48 groups) before feasibility can be assessed.
- **mc-0283** — the matched q2 sibling of mc-0277, same signal-free prescription. `arc2_phylo_sigma_fixture`
  now exists and could plausibly serve it after a q2 extension; must not be STOPped in the meantime.
- **mc-0123** — manifest binding must be corrected to mc-0124/`mu2` or a mu1 fixture written.
- **mc-0321, mc-0409, mc-0421–0424, mc-0205, mc-0206** — fixtures must be built. `sim3()` additionally
  monkey-patches `drm_validate_reml_spec_biv`; determine why that gate exists before promoting it.
- **mc-0417 / mc-0207** — bind-or-split decision outstanding; recommendation is split, per C14 precedent.
- **Prong B (zero-one-beta fences)** — recommend deferring to its own arc: 14 candidate cells (not 16;
  `coi` stays fenced), each needing `se = TRUE` and 30–50 seeds, roughly 420–700 fits. See
  `scratchpad/2026-08-02-arc2-s11-fence-audit.md`.
- Branch is pushed; **no PR opened and nothing merged.**

## 11. Compute state

Totoro scratch is **cleaned up**: the truncated 176 MB transfer bundle, the 528 MB worktree, all logs,
and the campaign outputs are removed (~705 MB reclaimed) after confirming all 79 evidence files and 4
reconciliations were pushed to `origin/claude/arc2-interval-feasibility`.

**One unintended side effect, recorded rather than glossed:** `R CMD INSTALL` ignored the
`R_LIBS_USER=~/hsq_work/arc2-Rlib` I set and installed into the shared user library `~/R/lib/drmTMB`,
overwriting whatever build was there. The replacement is built from `83055ec5`, which is current `main`,
so the practical effect is that the shared library is now current. The arc6 lane's own
`~/hsq_work/arc6-Rlib/drmTMB` (Jul 24) is untouched. To isolate properly next time, pass
`-l <lib>` to `R CMD INSTALL` rather than relying on `R_LIBS_USER`.

Re-creating the Totoro workspace costs one `git worktree add` plus three `scp`s; the compiled package
persists in the shared library, so the expensive step does not need repeating.
