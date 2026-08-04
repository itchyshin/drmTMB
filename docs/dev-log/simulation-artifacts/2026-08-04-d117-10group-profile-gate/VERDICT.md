# D-117 — the 10-group profile RE-SD coverage gate

> **STATUS: the measurement stands; the PASS claim is WITHHELD.**
>
> The pre-registered rule returns PASS on all four cells. A D-43 completion panel
> then returned **2 of 3 NOT-DONE**, which under the arc's own rule withholds the
> claim. Both dissents converge on the same defect, and I reproduced their
> arithmetic independently before accepting it. **This document has been rewritten
> to state what the evidence supports rather than what the rule alone returned.**
>
> **Disclosure:** the panel was in the arc's approved plan, positioned *before* the
> claim, and it **did not fire on time**. It was caught by plan-vs-actual
> reconciliation and fired only after the PASS had been committed, written to the
> check-log, and opened as a PR. Firing late materially weakens the gate: the
> burden inverts from *earn the claim* to *unpublish it*.

## 1. What was measured, and what the rule returned

Four 10-group cells, `n_rep = 1000` each, Gaussian scalar A1 DGP, estimand
`sd:mu:(1 | g)`, nominal 95%, all-attempt coverage, Totoro 90 cores.

| Cell | N | truth | coverage | exact 95% CI | cov+2·MCSE | floor | rule says |
|---|---:|---:|---:|---|---:|---:|---|
| `g10_n04_sd05` **worst corner** | 40 | 0.5 | **0.9140** | (0.8949, 0.9306) | 0.9317 | 0.918 | PASS |
| `g10_n04_sd10` | 40 | 1.0 | 0.9290 | (0.9113, 0.9441) | 0.9452 | 0.918 | PASS |
| `g10_n10_sd10` | 100 | 1.0 | 0.9310 | (0.9135, 0.9459) | 0.9470 | 0.918 | PASS |
| `g10_n10_sd05` *reproduction* | 100 | 0.5 | 0.9370 | (0.9201, 0.9513) | 0.9524 | 0.918 | PASS |

1000/1000 finite intervals per cell; convergence and `pdHess` 1.000 throughout.

**The harness is sound.** `g10_n10_sd05` reproduces the banked 2026-07-26 result on
**five independent statistics** — coverage 0.937, exact CI (0.920, 0.951),
1000/1000 valid, misses 10/53, and 63 zero-boundary endpoints. Matching the miss
decomposition and boundary count exactly cannot be coincidence. Both panel
reviewers re-derived every headline number from the raw CSVs, one of them
bypassing the stored `profile_covers` column entirely, and found **zero**
numerical defects, no rule-bending, and no complete-case filtering.

**So this is not a numbers problem.** It is a claim problem.

## 2. Why the claim is withheld

### 2.1 The pooled PASS averages two regimes with opposite verdicts — and the user can see which one they are in

`confint()` returns a `profile.boundary` column and a `near_sd_boundary` message
(`R/profile.R:3615-3648`). It is **not a simulation-only oracle**: a user who fits
this model and looks at their own output can see the flag. Applying **the arc's own
frozen gate** to the two halves of that mixture:

| Cell | at boundary | coverage \| boundary | score \| boundary | **verdict if gated alone** | coverage \| non-boundary |
|---|---:|---:|---:|---|---:|
| `g10_n04_sd05` | **495/1000 (49.5%)** | 0.8566 | 0.8881 | **BORDERLINE** | 0.9703 |
| `g10_n04_sd10` | 41/1000 | **0.0732** | 0.1545 | **FAIL** | 0.9656 |
| `g10_n10_sd05` | 63/1000 | 0.2540 | 0.3636 | **FAIL** | 0.9829 |
| `g10_n10_sd10` | 0/1000 | — | — | — | 0.9310 |

**This inverts the headline.** D-117 exists because the *marginal* route collapsed
to 0.829 at 10 groups. Conditional on the boundary flag, the **profile** route
reaches **0.0732 and 0.2540** — far worse than the number that disqualified the
marginal route. The failure mode is not absent from the profile route; it is
**concentrated in an identifiable sub-population**, and at N = 40 with
`sd_mu = 0.5` that sub-population is **half of all fits**.

Pooled coverage remains the right headline for "an experiment I run once and never
inspect." Conditional coverage is the right number for "the interval I am holding,
having just looked at its own diagnostic." The original verdict reported the
boundary split but never applied the gate to it, so a reader could not make that
call. That omission is the panel's central finding, and it is correct.

### 2.2 A large, significant point-estimate bias went entirely unreported

`estimate_sd` is in every row of the output. It was never analysed. Recomputed:

| Cell | truth | mean estimate | relative bias | one-sample t vs truth |
|---|---:|---:|---:|---|
| `g10_n04_sd05` | 0.5 | 0.4155 | **−16.9%** | t = −13.79, p = 9.4e-40 |
| `g10_n04_sd10` | 1.0 | 0.9088 | −9.1% | t = −11.53, p = 5.9e-29 |
| `g10_n10_sd05` | 0.5 | 0.4547 | −9.1% | t = −10.44, p = 2.8e-24 |
| `g10_n10_sd10` | 1.0 | 0.9084 | −9.2% | t = −12.42, p = 4.7e-33 |

This is the expected direction for an **ML (non-REML)** RE-SD at small `g` — the
runner uses the package default `REML = FALSE` (`R/drmTMB.R:184`) — so it is not a
confound this arc introduced. But it is **the mechanism behind the upper-miss
asymmetry** the arc did report (71:15, 63:8, 53:10, 60:9): an estimate biased low
anchors the interval too low, so it misses from above. Reporting the symptom while
omitting the cause, in a document whose purpose is to certify small-sample
inference, is a real gap.

### 2.3 "Not materially worse than the pooled figure" was not supported

The original headline compared 0.914–0.937 against D-97's pooled 0.9368 and
concluded agreement. Tested: worst cell 0.9140 (MCSE 0.008866) vs 0.9368
(SE ≈ 0.002245) gives **difference −0.0228, z = −2.49, p = 0.013**. Pooled across
all four 10-group cells (3711/4000 = 0.92775) the gap is 0.9 pp at z = −1.94.
**All four cells sit at or below the pooled number; none is above it.**

The pre-registration *did* freeze that wording as the PASS consequence, so this was
rule-application rather than rationalisation — but pre-registering a sentence does
not make it true. It conflates two different comparisons: *"not significantly below
a floor of 0.918"* and *"not materially worse than 0.9368"*. The floor sits 1.9 pp
below the pooled figure, so a cell can clear the floor while being detectably below
the pooled number. That is exactly what happened.

**The defensible claim, which the evidence does support:**

> The profile route does not inherit the marginal route's 10-group *collapse*
> (0.829 vs 0.914–0.937). The corner is nonetheless **detectably below** D-97's
> pooled 0.9368 — worst cell 0.9140, a 2.3 pp gap at z ≈ 2.5. The gradient the gate
> was built to detect **is present**, at 1–2 pp rather than 5–12 pp.

### 2.4 The gate is a non-rejection, and its margin shrinks as evidence grows

`coverage + 2·MCSE ≥ floor` is anti-conservative *for declaring a PASS*: the more
replicates, the smaller the margin. At the observed 0.9140 the same point estimate
scores **BORDERLINE at n ≳ 19,700**; the margin at n = 1000 is 1.55 MCSE. The
approved plan recommended n = 1,200; the pre-registration chose 1,000 for
comparability with the banked cell — defensible, but the deviation was not flagged,
and the smaller n is the more permissive choice. This is the repo's own standing
convention (`tools/gate-inference-ready.R`, 2026-07-08) and refusing to re-tune it
was correct; the defect is in the convention, and this arc inherited it without
naming the direction.

## 3. Unresolved — and it changes what this arc *is*

**D-97's provenance contradicts this arc's central premise.** D-97
(`DECISIONS.md:2756`) records profile coverage 0.9368 *"across all 12 A1 cells
(11,988 retained attempts, 11,988 finite profiles)"*. The pre-registration's
premise was that **three of the four 10-group cells had never been measured on the
profile route**. Both cannot be true.

I searched and could not reconcile them: the 12-cell 2026-07-25 campaign is
**bootstrap-only** (`a1_coverage.R` calls `method = "bootstrap"`; its summary
contains zero occurrences of "profile", and its `parm` is `fixef:mu:x`), and the
2026-07-26 profile campaign is **3 cells × 1000 = 3,000 attempts**. Neither yields
11,988 (= 12 × 999). `git grep 0.9368` returns only this arc's own retellings.

**Either** D-97's pooled figure genuinely spans 12 profile cells — in which case
three of this arc's four cells are reproductions rather than firsts, and the
reframing the arc rests on is wrong — **or** the number Shinichi accepted as
adequate for the default has a mis-stated provenance nobody has caught.

> **RESOLVED — it is the second. See `D97-PROVENANCE.md`.**
> The committed profile campaign is **3 cells / 3,000 attempts**, pooling to
> **0.9400**, not 0.9368. "12 A1 cells" correctly describes the *bootstrap-only*
> campaign (0.8714, n = 12,000), and 11,988 = 12 × 999 where **999 is the bootstrap
> resample count**, not a retained-attempt count — every real campaign retained
> exactly 1,000 per cell with zero attrition. The 0.9368 figure traces to a single
> after-task report that exists **only in the brain vault**, describing a run in a
> now-deleted temp directory with a script matching nothing in this repo.
>
> **This arc's premise survives:** the committed profile campaign varies only
> `n_groups`, holding `n_per = 10` and `sd_mu = 0.5` fixed, so `n_per = 4` and
> `sd_mu = 1.0` genuinely were measured here for the first time.
>
> **§2.3's conclusion is unchanged and slightly strengthened.** Against the real
> committed comparator (0.9400) rather than 0.9368, the worst cell's gap is
> −0.026 with combined SE 0.00987, **z ≈ 2.63** (was 2.49).
>
> D-97's *direction* is not overturned — profile beats marginal on either figure.
> **Correcting the decision record is the owner's call**; do not cite 0.9368 again
> until it is settled.

## 4. The most actionable output, currently invisible to users

`confint()` **actively warns** when a *Wald* interval sits at a variance-component
boundary and tells the user to prefer `method = "profile"`
(`R/profile.R:1941-1957`). There is **no analogous warning** when
`profile.boundary = TRUE` — even though this arc's data show profile coverage
collapses to 7–25% exactly there. A user is therefore steered out of Wald and into
a regime this arc measured as worse, with no signal.

Nothing in `NEWS.md`, `man/confint*`, or the interval vignettes says this. **That
gap, not the PASS, is this arc's most valuable finding**, and closing it is a
code/doc change outside this measurement arc's scope.

## 5. What is established

- **The measurement exists**, fixed-seed, reproducible, with receipts — the narrow
  thing D-117 asked for.
- **The profile route is markedly better than the marginal route** at 10 groups
  (0.914–0.937 vs 0.829), pooled.
- **The harness is validated** by exact reproduction of the banked cell on five
  statistics.
- **Census unchanged: 182 `interval_feasible` / 60 `point_fit_recovery`.** No
  ledger cell promoted, D-97 not reopened, no `supported` claim.

## 6. What is NOT established

- That the 10-group corner is safe **for a user who can see the boundary flag** —
  by the arc's own gate that population is BORDERLINE/FAIL/FAIL.
- That D-117 is discharged for the **Prong B routes** (count, zero-one-beta); this
  measured the A1 **scalar Gaussian** corner only.
- That the profile interval is **correct**, as opposed to *stable*. The
  reproduction check is a drift check; a systematically wrong interval reproduces
  itself perfectly.

> **UPDATE — the external comparator has now been run; see `COMPARATOR.md`.**
> `lme4` on the same DGP and the **same seeds** reproduces drmTMB's boundary
> behaviour essentially exactly: boundary incidence agrees on **4000/4000**
> replicates, conditional coverage is identical to four decimals (0.8566 / 0.0732 /
> 0.2540 in both engines), and coverage outcomes agree on 3999/4000. The one
> disagreement is an lme4 profile-bracketing failure that returned an interval
> **excluding its own point estimate**; drmTMB was correct there.
>
> **So §2.1's finding stands as a statistical fact but is NOT a drmTMB defect** — it
> is a property of profile-likelihood intervals for a variance component near zero,
> reproduced by the reference implementation. That refutes the competing
> "root-finder bug" hypothesis and means **the remedy is the user-facing warning in
> §4, not an engine fix.** It does not establish that the method is *correct* in an
> absolute sense: two implementations agreeing shows the implementations agree.

## 7. Provenance

Totoro, 90 cores (≤100 cap), `OPENBLAS_NUM_THREADS=1`; D-50 honoured. Package
rsynced from `7c1f98020` (code-identical to `main` `5a9662110`) to an isolated path
and loaded with `pkgload::load_all`. Seeds `20260727 + 100000 × cell_i + r`, indices
4/5/6 disjoint from banked 1/2/3; index 1 reused deliberately to reproduce.
Pre-registration committed `e9bccb26b` at 17:35:16 UTC; first production fit
17:49:08 UTC — genuinely prior, independently anchored by in-CSV timestamps.

SHA-256: `g10_n04_sd05.csv` `e8e31cc4…37437d24` · `g10_n04_sd10.csv` `ceba24d2…2e5adb8b` ·
`g10_n10_sd05.csv` `c419d05e…d35703ae` · `g10_n10_sd10.csv` `c3a22e7b…fa299512`
(full values in `results/SUMMARY.csv` lineage and the campaign log).

**Not committed, so the following rest on narrative only:** the smoke receipt, the
cross-platform ~1e-12 agreement, the broken `~/drm_work/drmTMB` checkout finding,
and a verified package **hash** (the CSVs carry `DRMTMB_COMMIT` as a label the
runner is told, not a hash it checks). The 2026-07-26 lineage committed all of
these; this arc did not.

## 8. For the owner

1. **0.7.0 publication.** The measurement D-117 required exists. Whether it
   *discharges* the gate is now a judgement call, not a formality, because the
   conditional-coverage finding is adverse. **Recommend: do not treat D-117 as
   discharged until §3 is resolved and §4 has a user-facing warning.**
2. **Resolve the D-97 provenance contradiction (§3).** One targeted search; the
   answer changes what this arc is.
3. **The boundary warning (§4)** — the highest-value follow-up.
4. **Lane authority.** The reassignment of D-117 from the codex lane to Claude is
   recorded here in passive voice with no cited authority; D-117 says assigning it
   is Shinichi's call (D-87). Recorded as unattributed.
5. The banked 2026-07-26 evidence remains **unpushed** on
   `codex/sd-bootstrap-r999-diagnosis` (`4cc837a85`), on no remote.
