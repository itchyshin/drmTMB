# After Task: missing-response G5 promotion, then the interval-availability arc (2026-08-11)

Two arcs in one session. The first closed the missing-data G4/G5 loop and promoted eight routes off
G3. The second took the first's headline finding — that 42 of 43 cell failures were interval
*availability*, not miscalibration — and replaced the calibration gate that produced it.

## 1. Goal

**Arc 1.** Run a fresh D-43 panel on the authenticated rorqual campaign (array `18777800`) and promote
what it earns. Eighteen `missing_response` rows were pinned at G3 solely because the first panel found
an incomplete admission set — 290 of 294 cells reconciled, the missing four unidentified.

**Arc 2.** Make interval availability a first-class reported quantity, diagnose the concentrated
failures, root-cause the six `point_estimate_outside_interval` records, and decide #967.

## 2. Implemented

**Arc 1 — `claude/g5-panel-and-promotion`, 6 commits.**
- Identified the four unreconciled cells: all `beta` at rung `2x`, truncated by an 8 h SLURM walltime
  (tasks `18777800_222`–`225`, `TIMEOUT`), `replicate` contiguous 1..N. Truncated runs, not filtered
  results.
- Established exhaustiveness externally: every registry cell of all candidate routes complete.
- Ran the D-43 panel — 3 fresh reviewers, 2 build + 1 ceiling, distinct lenses, selected **by tool
  set** because the review-lens agent types cannot `Write`.
- Promoted **8 routes** to `inference_ready_with_caveats` / G5: `gaussian`, `biv_gaussian`, `gamma`,
  `beta_binomial`, `binomial`, `zero_one_beta`, `zi_poisson`, `lognormal`.
- Gave each of the 10 held rows its own accurate `next_gate` reason, replacing a uniform placeholder
  that the promotion itself had falsified.

**Arc 2 — `claude/interval-availability`, 4 commits.**
- Diagnosed the four concentrated failure cells; three are genuine identifiability limits.
- Root-caused the `point_estimate_outside_interval` records and measured the detector's sensitivity.
- Produced the availability/coverage dose-response and the threshold evidence.
- Shipped **`mr-g5-calibration-v2`**: availability reported as a rate, coverage gated on an
  availability floor of 0.99, coverage machine-flagged conditional where availability < 1.
- Re-scored all 290 cells against the existing artifact — **no new compute**.

## 3. Evidence

Campaign artifact `rorqual:~/g5run/g5-reconciled-final.rds`, schema `mr-g4g5-v2`, cohort
`authenticated_uncentred`: 348,000 records, **0 UNAUTHENTICATED**, `design_state =
centre_random_effects=FALSE` on every record.

**Promotion.** All 8 routes: every cell 1200/1200 interval-usable, every coverage inside
[0.925, 0.975] at all three rungs. Closest to an edge and named explicitly in the ledger rather than
absorbed: `biv_gaussian fixef:mu2:(Intercept)` 1x = 0.9317 (MCSE 0.0073) and `lognormal
sd:mu:(1 | id)` 0.5x = 0.9317 (MCSE 0.0073).

**Noether's prior objection discharged by reproduction, not by the stamp** — four records reproduce
bit-exactly under `centre_random_effects=FALSE` and *fail* to reproduce under `TRUE`. It further
confirmed `lognormal` was genuinely exposed to the centring defect, so its unpinned intercept
coverages evidence the corrected design in the results and not only in the provenance field.

**Availability dose-response** (290 cells): mean coverage 0.4008 at availability ≤0.5, 0.7800 at
0.5–0.9, 0.9215 at 0.9–0.99, 0.9378 at 0.99–0.999, 0.9484 at exactly 1.

**Re-score, v1 → v2:** 247/43 → **272/18**. Flips: fail→pass 25, **pass→fail 0**. All 25 in the single
named near-miss population (availability ≥0.99, coverage already in band); lowest availability 0.9900.

## 3a. Decisions and Rejected Alternatives

**Rejected: gate on coverage alone.** This was the arc's stated approach and the obvious code change
(drop `& calibration_available`). Rejected on evidence: it admits 33 cells, 8 from the 0.9–0.99 zone
where mean coverage is 0.9215 and only 9 of 13 sit in band. Coverage is computed *conditional on the
interval being usable*, so a coverage-only gate would judge a 702/1200 cell on its 498 survivors.

**Adopted: an availability floor of 0.99**, justified by the dose-response rather than convenience.

**The decisive argument arrived late and is not the one the arc started with.** If a parameter
legitimately touches a boundary on a fraction *p* of draws, a 1200-replicate cell yields 1200 usable
intervals with probability (1−*p*)¹²⁰⁰ — 0.30 at *p*=0.001. The all-1200 rule was not strict but
**incoherent** for any parameter that can approach a boundary. That, not admitting 25 cells, is why
it changed.

**`cumulative_logit` held 2/2 on container grounds, with its evidence explicitly sound.** Its 3
measured cells (`fixef:mu:x`, all rungs) pass cleanly, and Noether verified the estimand against
`MASS::polr` — which stores cutpoints as raw values rather than log-increments — with slopes agreeing
to 1.35e-06. The obstacle is that the ledger row asserts `dpar = "all fitted dpars"` while both
`ordinal:theta_ord:*` targets carry zero G5 evidence. **A per-target claim needs a per-target key, not
a per-route key plus prose**, because `claim_boundary` is free text and not part of the key.

**#979 abandoned mid-implementation.** Another lane's PR #998 closed it while our slice was running,
and rejected the narrowing approach on better grounds: the anchored fingerprint reads only
`R/drmTMB.R` and `src/drmTMB.cpp`, but the receipt grades `mode_correlation` via `ranef.drmTMB()` in
`R/methods.R` plus unanchored fitting plumbing, so narrowing would drop real coverage *silently*. The
244 uncommitted insertions were deliberately **not** committed — a rejected approach should not enter
history looking viable.

## 4. Files Touched

Arc 1 (`claude/g5-panel-and-promotion`): `docs/dev-log/dashboard/capability-ledger/{cells,evidence,
transitions}.tsv`, `schema.json`, `tools/capability_ledger.py`, `tools/tests/test_capability_ledger.py`,
`vignettes/includes/capability-ledger-*.md`, three panel reports under `docs/dev-log/release-audits/`,
the exhaustiveness note, and the 290-row panel CSV.

Arc 2 (`claude/interval-availability`): `inst/sim/R/sim_missing_response_g4g5.R`,
`tests/testthat/test-missing-response-g4g5-foundation.R`, and five notes under
`docs/dev-log/interval-availability/`.

## 5. Checks Run

- `python3 tools/capability_ledger.py --write` then `--check` — OK, 31 generated outputs
- `python3 -m unittest tools/tests/test_capability_ledger.py` — 67 tests, OK
- `devtools::test(filter="missing")` — **1569 pass, 0 fail, 2 skip**
- C14 receipt equivalence + C17 current-source compatibility — PASS
- Independent verification by the orchestrator of the tier state, the exclusion-list cleanup, the
  placeholder removal, and the `poisson` coverage cell, rather than accepting agent reports

## 6. Tests of the Tests

The v2 gate ships with tests covering availability exactly 1.0, exactly at the 0.99 floor (must pass),
just below it (must fail, **with an availability reason and not a coverage reason**), in-band coverage
at 0.5 availability (must fail), and out-of-band coverage at full availability (must fail on
coverage). The reason-label assertions matter more than the pass/fail ones: the defect being fixed is
a *mislabelling*, so a test that only checked the boolean would not detect a regression.

One generated-surface test was inverted deliberately: it previously asserted the stale placeholder
sentence was present; it now asserts it can never reappear.

## 7a. Issue Ledger

Not filed — surfaced for the maintainer, all discovered this session:
- **Vacuous completeness check.** Incomplete cells are dropped from the artifact's embedded registry
  *before* `calibration_complete` runs, so it passes over the surviving subset and the artifact cannot
  certify its own exhaustiveness.
- **Unguarded `interval_method`.** Derived at runtime from `profile_targets(fit)$profile_ready`; the
  validator's check is a tautology against the same expression.
- **A detector at 0.7% sensitivity.** 764 records have a profile evaluation below the fitted
  objective; 245 kept a retained, coverage-counted, unflagged interval at coverage 0.890 vs 0.948. The
  shipped diagnostic caught 5. Fix is to the detector, not the interval — a profile that beats the fit
  means the fit is wrong.
- **`TMB::tmbprofile()` bracket-search overflow** producing a spurious sentinel for `student nu`.
- **Cross-reference rot in the per-route ledger.** A partial promotion falsifies text in rows it does
  not touch, in both directions.
- **#967 action**, per its memo: per-target scope-out, a first-cutpoint carve-out, and
  `theta_ord[j>1]` deferred as a genuine open capability gap.

## 8. Consistency Audit

The promoted rows, the generated vignette includes, the schema metadata, and the reader-facing surface
were checked against each other after the change, not only before. That is what surfaced the false
`next_gate` text and the stale `lognormal` exclusion lists — neither of which any test could catch,
because both strings remained syntactically valid.

## 9. What Did Not Go Smoothly

**Three orchestrator claims were wrong and were corrected by the agents.**
- `n_attempt` was said to be asserted from registry intent. It is measured (`nrow(x)`). The error came
  from reading the head of a 290-row `str()` — whose leading rows are *complete* cells — and
  generalising to cells absent from that frame. Two reviewers caught it independently.
- "Profile intervals only" was called false on Rose's code reading. Noether measured the records: 0 of
  348,000 used Wald. The code claim was right, the data claim was wrong, and I had repeated the code
  reading as if it described the data.
- The non-convergence mechanism was adopted for the heavy cells and then refuted by a from-scratch
  reprofile at the reported MLE (`|Δnll| < 0.01`).

**An inherited candidate list cost two routes a promotion.** The seven-route list came from the prior
panel; it was carried into the admission-set doc as a "candidate" tag, and Rose then excluded
`cumulative_logit` *citing that tag*. Circular. `lognormal` was excluded with no stated reason at all
and was subsequently promoted 3/3.

**Entering plan mode with four subagents live** blocked their writes and forced a resume cycle.

## 10. Known Residuals

- **Beta resume in flight** — array `18826926`, resuming the four truncated 2x cells from checkpoint on
  the same deterministic seeds. One cell complete; ~3.5 h remaining on the longest. Campaign reaches
  294/294 on completion. Does **not** gate the promotion.
- Both branches are based on `a2c4941db`; `origin/main` has since moved to `256e586e5`. **Merge main
  before any PR.** Nothing pushed.
- `claude/979-c17-narrow-pin` holds ~244 uncommitted insertions, deliberately unlanded.
- `claude/mi-response-leaves` is now unblocked by #979's closure; 123 commits behind main.
- Everything in §7a is diagnosed and unimplemented.

## 11. Team Learning

**Ask reviewers to verify your claims, not to accept them.** Every one of the three orchestrator
errors was caught because the brief said "verify this independently — it is load-bearing." None would
have been caught by a brief that simply asserted them as background.

**Interrogate *why* a reviewer said something, not just *what*.** The `cumulative_logit` exclusion
looked like a considered judgement until its stated reason was read; it turned out to be deference to
a label. Reading the reasoning, not the verdict, is what recovered two routes.

**Routing paid off in both directions.** The ceiling model on the six-record slice turned "an edge case
that failed closed" into a 764-record finding about a detector with 0.7% sensitivity. A Haiku scout
misreported the ledger TSVs as generated; the Sonnet implementer caught it by reading the README the
scout had summarised.

**A partial change falsifies the text of what it does not touch.** Twice in one promotion. Nothing
mechanical detects it.

## 12. Cross-Product Coverage

`missing_response` axis only. The promotion does not touch model-inference maturity, the
`missing_predictor` axis, or MD7f. The v2 gate changes scoring for the G4/G5 missing-response campaign
and nothing else; DEFER-fenced items (MAR/MNAR, REML, MD7f, the 0.7 release ladder) were not touched.
