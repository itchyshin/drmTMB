# D-93 decision packet — the random-effect-SD interval, with the post-fix numbers

**2026-08-15 · assembled by Fisher (inference review) · lane `claude/07-cran-ladder` ·
`origin/main` = `e19cc0807`**

**Reader: Shinichi.** You placed the D-93 hold on drmTMB 0.7.0 on 2026-07-27 and have not
revisited it with the post-fix measurements in front of you. This packet puts them there. It
restates what you asked for, gives the coverage ladder from broken to current, says plainly
where the current number sits against nominal, reports what the literature does and does not
know about this regime, prices what closing the remaining gap would take, and separates the
boundary sub-problem from the overall coverage question because they have different answers.

It ends with one question and does not answer it. A recommendation is offered, labelled as
such, in a place where it cannot be mistaken for the decision.

Every number below is cited to a repository path. Where a figure in circulation could not be
verified, that is stated rather than repeated.

---

## 1. What D-93 demanded

From `~/shinichi-brain/memory/DECISIONS.md`, D-93 (2026-07-27, accepted):

> Asked to choose between shipping 0.7.0 with the measured undercoverage honestly documented,
> or holding the release until coverage is nominal, he chose to **hold**: *"we will need to fix
> it… but we do not publish 0.7 yet — we will fix it."* The recommendation on the table was the
> opposite (ship with a warning); he overrode it. **drmTMB's first public appearance will not
> carry known-weak inference.**

And the operative consequence, in the same entry:

> `confint()` warnings, NEWS wording and help-page caveats are **no longer the deliverable**.
> The deliverable is a random-effect-SD interval that actually covers.

Two things follow that shape this packet. First, the deliverable you named is a *number*, not a
disclosure. Second, D-93 says "until coverage is nominal" in the framing of the question but
"an interval that actually covers" in the statement of the deliverable, and those two phrasings
admit different bars. Section 7 is about exactly that gap, and only you can close it.

One piece of timing context, because it bears on how much pressure sits behind this: on
2026-08-04 you said *"0.7 is coming later"* (D-122), which removed urgency from the gate without
removing the hold. Nothing in this packet needs to be decided today.

---

## 2. The coverage ladder

All figures are coverage of a nominal 95% interval for the between-group random-effect standard
deviation `sd:mu:(1 | g)` in a Gaussian random-intercept model, `bf(y ~ x + (1 | g), sigma ~ 1)`,
truths `beta = 0.5`, residual `sigma = 0.7`.

| Stage | Route | Coverage | Replication | Primary source |
| --- | --- | --- | --- | --- |
| **The defect D-93 named** | conditional bootstrap (old default) | **0.5092** | 12,000 intervals | `docs/dev-log/simulation-artifacts/2026-07-25-a1-marginal-bootstrap-coverage/a1_coverage_summary.txt:15` |
| **After the A1 fix** | marginal bootstrap | **0.8714** | 12,000 intervals | same file, line 14 |
| — at 10 / 25 / 50 groups | marginal bootstrap | **0.8103 / 0.8888 / 0.9153** | 4,000 each | same file, lines 17–19 |
| **The profile route, committed campaign** | profile likelihood | **0.9400** (2820/3000) | 3 cells × 1,000 | `profile-vs-bootstrap-report.md` on `origin/codex/sd-bootstrap-r999-diagnosis` |
| — per cell at g = 10 / 25 / 50 | profile likelihood | **0.937 / 0.942 / 0.941** | 1,000 each | same report |
| **The 10-group corner (D-117 re-run)** | profile likelihood | **0.924800** (SE 0.000417) | **400,000 attempts** | `docs/dev-log/simulation-artifacts/2026-08-09-d117-100k-regate/VERDICT-100K.md:22` |
| — per cell | profile likelihood | **0.9229 / 0.9257 / 0.9255 / 0.9251** | 100,000 each | same, §1 table |
| Nominal | — | 0.95 | — | — |
| The `g`-tapered floor at g = 10 | — | **0.918** | — | `tools/gate-inference-ready.R:34-36` |

**Width, for the first row.** The old conditional bootstrap was not merely under-covering, it was
under-wide: median interval width 0.2561 against the marginal route's 0.4812, about 53% of the
width it should have had (`a1_coverage_summary.txt:14-15`). "Roughly half the width" is accurate.

**Attrition.** 72,000 interval rows in the 2026-07-25 campaign with zero non-finite intervals and
zero bootstrap refit failures (`a1_coverage_summary.txt:6-9`). 400,000 attempts in the 2026-08-09
re-run with 100,000/100,000 finite intervals, convergence 1.000, `pdHess` 1.000 in every cell
(`VERDICT-100K.md:23`). Neither number is propped up by a favourable denominator.

**A provenance correction you should carry forward.** D-97 and the first version of D-117 cite
profile coverage as *"0.9368 across all 12 A1 cells, 11,988 retained attempts."* That citation is
mis-recorded and has been corrected in the brain (D-97, 2026-08-05 block). The committed profile
campaign is **3 cells / 3,000 attempts / 0.9400**; the 12-cell grid and its 0.8714 belong to the
*bootstrap* arm; "11,988" is 12 × 999, and 999 is the bootstrap resample count inside each
attempt, not a retained-attempt count. The evidence is
`docs/dev-log/simulation-artifacts/2026-08-04-d117-10group-profile-gate/D97-PROVENANCE.md`. The
direction of D-97's decision is unaffected. **Do not cite 0.9368 again.**

**One comparison to read carefully.** 0.9400 is pooled across g ∈ {10, 25, 50}; 0.9248 is g = 10
only. They are not the same estimand, and the difference between them is mostly the difference in
group count, not a deterioration. Against a like-for-like g = 10 comparator (0.9370, n = 1,000)
the 100,000-attempt figure sits at z = −1.586, which is not significant
(`VERDICT-100K.md:79-86`).

---

## 3. This is real undercoverage, and the floor is what prices it

**0.9248 against a nominal 0.95 is a shortfall of 2.5 percentage points, and it is measured
precisely enough that it is not noise.** The standard error is 0.000417, so the gap is roughly
60 standard errors wide. The arc's own verdict says this without hedging: *"It is also **not**
nominal-exact coverage: 0.9248 against a nominal 0.95 is real undercoverage, which is why the
floor is `g`-tapered in the first place"* (`VERDICT-100K.md:226-228`).

**The shortfall is one-sided, and that matters more than its size.** Across the four cells at
100,000 attempts each, lower-side misses number 1163 / 1089 / 1139 / 1083 while upper-side misses
number 6547 / 6344 / 6308 / 6407 — an upper-tail excess of roughly 5.5:1 to 5.9:1
(`docs/dev-log/simulation-artifacts/2026-08-09-d117-100k-regate/results/SUMMARY.csv`). The
interval is not symmetrically slightly narrow; it sits systematically too low. A user who reports
the upper bound will understate the random-effect SD more often than the nominal rate implies.
This is the interval-side signature of the point-estimate bias in the next paragraph.

**The point estimate runs low too, by 8–16%.** Raw-scale relative bias is
**−15.76 / −9.31 / −10.26 / −8.34%** across the four cells, MCSE ≤ 0.13%
(`VERDICT-100K.md:146-151`). `lme4::lmer` on the same DGP and the same seeds agrees on point
estimates to about 1e-6 (`2026-08-04-d117-10group-profile-gate/COMPARATOR.md:50`), so this is the
maximum-likelihood estimator at ten groups, not an implementation defect. **It is already
disclosed on `origin/main`, in four user-facing places**, phrased as `8.3%-15.8%`: `NEWS.md:186`,
the `confint()` roxygen at `R/profile.R:217`, `man/confint.drmTMB.Rd:271`, and
`vignettes/first-week-intervals.Rmd:122`. D-117's condition 1 — *"state the recovery bias in
user-facing terms"* (`2026-08-09-d117-FINAL-RECOMMENDATION.md:49-51`) — is therefore **satisfied**,
not outstanding. `NEWS.md:207` additionally states in public that *"0.9248 against a nominal 0.95
is real undercoverage"*.

**What the floor is, stated honestly, because it is doing load-bearing work.** The gate's floor is
`ss_floor(g) = 0.95 − 0.04 × (8 / g)`, giving 0.918 at g = 10
(`tools/gate-inference-ready.R:34-36`). Three facts about it belong in front of you:

1. **It pre-existed this arc.** It is the repository's own two-tier gate, not a rule written for
   D-117, and the 2026-08-04 pre-registration adopted it by reference before any 10-group number
   existed (`2026-08-04-d117-10group-profile-gate/PREREGISTRATION.md:93`).
2. **It is descriptive, not normative.** Its own comment records its origin: *"From the banked
   g-sweep: g=8 profile ~0.91, g=32 profile ~nominal. Taper the df-narrowness margin as ~1/g"*
   (`tools/gate-inference-ready.R:30-33`). It was fitted to what the profile method actually
   achieves across g. Clearing it therefore says *"this behaves the way well-behaved profile
   intervals behave at this group count,"* not *"this coverage is adequate."* That distinction is
   the whole of the D-93 question.
3. **It ignores within-group replication.** `ss_floor` is a function of `g` alone, so the N = 40
   cells were held to the same bar as the N = 100 cells, and raw-scale bias grows 1.54× when
   `n_per` falls from 10 to 4 at `sd = 0.5` (`VERDICT-100K.md:211-215, 230-234`). The arc logged
   this before results precisely so it could not later look like a rescue, and the N = 40 cells
   cleared the bar anyway — but the floor does not price replication, and that is a known gap.

The same file defines the two tiers this decision runs on, in the repository's own words:
`inference_ready` is *"an HONEST interval at its achievable small-sample coverage (>= a
g-appropriate floor), skew documented"*; `supported` is *"NOMINAL-EXACT: |cov − nominal| <=
2*MCSE AND miss-balance"* (`tools/gate-inference-ready.R:18-22`). On that vocabulary the A1
10-group corner passes `inference_ready` and fails `supported`, and it fails `supported` on both
clauses — the 2.5-point gap and the 5.5:1-to-5.9:1 miss asymmetry.

**One observation, flagged rather than acted on.** Ledger row `mc-0264` (gaussian, `mu`,
`ordinary_re_intercept`, ML) carries `evidence_tier = supported`, but its `claim_boundary` reads
*"Board fit_status=supported for (1 | id) in mu; kept as the structured-RE arc's baseline
comparator"* — a legacy fit-status carry-over, not an interval or coverage claim
(`docs/dev-log/dashboard/capability-ledger/cells.tsv`). I have not edited the ledger and make no
claim about its tier semantics beyond quoting the row. If a reader could take that tier label as
an interval claim, that is worth a separate check by whoever owns the ledger vocabulary.

---

## 4. What the literature knows, and what it does not

Source: `~/shinichi-brain/projects/deep-research/dr20-reml-vs-aghq-distilled.md`, your own
~90-source NotebookLM harvest, built for this gate and interrogated 2026-08-03. Four findings
bear on D-93.

**REML and AGHQ correct two different downward biases, and using one leaves the other.** REML
corrects the finite-sample degrees-of-freedom bias from estimating fixed effects; AGHQ with k > 1
corrects the integration-approximation bias of the Laplace approximation. Software doing REML but
not AGHQ (the corpus names `glmmTMB` with `REML=TRUE`) keeps the integration bias; software doing
AGHQ but not REML (`lme4` with `nAGQ>1`, `GLMMadaptive`) keeps the dof bias. The corpus's stated
ideal — a unified REML-AGHQ estimator — is not what current software implements (dr20, finding 1).

**Bias survives to 25 clusters even with REML correction, cited by name.** *"Maestrini et al.
tested these R implementations down to m = 25 clusters and reported that even with REML
corrections, all approximate REML methods still exhibited a non-negligible amount of bias."* No
source in the corpus tested REML-corrected methods below m = 25 (dr20, finding 2). If bias
persists at 25 groups, the corpus gives no reason to expect it to have vanished at 10.

**There is no interval-coverage benchmark for a variance component below 10–15 groups, anywhere
in the corpus.** Asked directly, it surfaced only an explicit absence: Josephy et al. (2016),
quoted, *"coverage rates for τ are not provided, as not all estimation procedures provide this
interval."* The corpus has extensive small-cluster coverage data for *fixed-effect* coefficients
down to 6–12 clusters, and **no systematic table of variance-component interval coverage at few
groups for any method** (dr20, finding 4). The 10-group gate is therefore generating evidence the
general literature does not have, and there is no external figure to sanity-check it against.

**The honest reading, and its limit.** The corpus does **not** show that ~0.92 at g = 10 is
*good*. It shows the frontier is unmapped, and that bias persists at 2.5× the group count even
with the correction most often prescribed for it. That reframes D-93 from *"wait until it is
fixed"* to *"decide what bar is achievable"* — because nothing in the literature establishes that
a nominal-exact variance-component interval at ten groups is a solved problem, or even a measured
one. It does not license the conclusion that shipping weak inference is fine. Absence of a
benchmark is absence of evidence in both directions.

**The transfer question, stated plainly because it cuts against the above.** dr20's corpus is
about **non-Gaussian GLMM** variance components; the D-117 A1 cell is a **scalar Gaussian** linear
mixed model. My judgement on how much transfers:

- The **AGHQ half does not transfer at all.** For a Gaussian LMM with a scalar random intercept
  the Laplace approximation is exact — there is no integration-approximation bias to correct.
  Every AGHQ-flavoured finding in dr20 is irrelevant to this cell.
- The **REML/dof half transfers well**, because it is a property of estimating fixed effects
  alongside a variance component and is if anything cleaner in the Gaussian case, where the
  restricted likelihood is exact rather than approximate.
- The **absence finding (no coverage benchmark below 10–15 groups) transfers**, because it is a
  statement about what the field has published, and dr20 records the gap for variance-component
  intervals generally, not only for non-Gaussian ones.
- The **Maestrini m = 25 finding transfers only as a caution, not as a prediction.** It was
  measured on approximate REML for non-Gaussian models. Exact Gaussian REML at g = 10 could
  plausibly do better. Reading it as a forecast for the A1 cell would overstate it.

Net: dr20 legitimately establishes that the frontier is unmapped and that the obvious correction
is not a guaranteed cure. It does not establish that 0.9248 is the best attainable for *this*
cell, and the section below is where that question actually lives.

---

## 5. What reaching nominal-exact would take

This is the section that determines whether "hold until it is fixed" has a finite path. The
repository has already tried four things. Two failed and are measured; one works but does not
reach this cell; one is available, directly relevant, and **has never been run on this target**.

**Tried and measured as insufficient: the marginal bootstrap.** 0.8714 pooled, 0.8103 at 10
groups (`a1_coverage_summary.txt:14,17`). Increasing bootstrap resamples from R = 199 to R = 999
changed coverage by +0.001 at 10 groups and +0.003 at 50 groups, with paired CIs crossing zero —
so finite resample resolution is not the explanation
(`profile-vs-bootstrap-report.md`, "All-attempt calibration"). A1 was necessary and large. It was
not sufficient, and more of it does not help.

**Tried and measured as failing: single-level parametric-bootstrap bias correction.** It
estimates a log-bias of about −0.01 against the oracle's −0.13 — one tenth — because the
bootstrap measures the estimator's bias *at* `theta_hat`, where the log-SD ML estimator is nearly
median-unbiased, not the bias at the true parameter
(`docs/design/218-structured-q-series-completion-map.md:239-250`;
`docs/dev-log/simulation-artifacts/2026-06-27-bootstrap-bias-prototype/`).

**Tried and measured as making things worse: the Self–Liang chi-bar-squared cutoff at the
boundary.** Because the profile interval is a pure level set, the χ̄² 95% interval is exactly the
ordinary 90% interval, so it nests strictly inside the shipped one and coverage can only fall. It
did, on 4000/4000 replicates: conditional-on-boundary coverage moved 0.8566 → 0.7657, 0.0732 →
0.0488, 0.2540 → 0.0159, and unconditional coverage fell 5–7 points in every cell
(`docs/dev-log/simulation-artifacts/2026-08-05-d117-chibar-cutoff-arm/VERDICT.md:65-78`). The
prediction was committed before the run. This candidate is closed.

**Works, but does not reach this cell: the calibrated bias-corrected Wald interval.** `confint()`
already ships a small-sample correction — a `t(g − 1)` width plus a `+log(g/(g−1))` centre shift —
which lifted pooled coverage from 0.884 to **0.954** at g = 8 on the structured q2 mu-slope cells
(`docs/design/219-structured-re-small-sample-bias-correction.md`, "Evidence"). Three reasons it
does not answer D-93 as currently built:

1. **It is a Wald-path correction only.** `bias_correct` is consumed in `drm_wald_confint()`
   (`drm_wald_confint()`, `R/profile.R:2025-2080`); the profile route, which is the recommended
   route for random-effect SDs (`NEWS.md:121-123`), never sees it.
2. **It applies only to *structured* SD targets by default.** With the default
   `bias_correct = "location"`, `wald_target_log_bias()` passes `structured_only = TRUE`, so a
   plain `(1 | g)` iid target returns `NA` and receives no shift (`R/profile.R:2270-2303`). The
   A1 cell is outside its scope by construction.
3. **Design 219 states the magnitude is simulation-calibrated per model class, not derived**, and
   explicitly warns that in the boundary regime *"neither the centre shift nor the t-width
   restores nominal coverage (Self & Liang 1987; Stram & Lee 1994),"* noting that the calibrated
   cells sit at SD truth ~0.9–1.05, well away from the boundary. The A1 g = 10 cells hit the
   boundary on 0.09% to 49.7% of replicates. Transplanting the correction here would be exactly
   the kind of uncalibrated transfer the doc forbids.

**Available, directly relevant, and never run on this target: REML.** This is the concrete open
lever.

- REML **is implemented** for this exact route. Ledger row `mc-0265` — gaussian, `mu`,
  `ordinary_re_intercept`, estimator REML — is `capability_status = implemented`, and its
  `claim_boundary` records that *"coverage and calibration were not evaluated"*
  (`docs/dev-log/dashboard/capability-ledger/cells.tsv`).
- The one repository measurement of REML's effect on profile-interval coverage is encouraging and
  is **not** on this target. On an ordinary *sigma*-axis random intercept, `sd:sigma:(1 | id)` with
  truth 0.5, the paired ML-vs-REML campaign measured at g = 10, `n_each = 10`: ML **0.9240** →
  REML **0.9510**, paired Δ +0.0270 (SE 0.0057); and at g = 10, `n_each = 3`: ML 0.9082 → REML
  **0.9576**, Δ +0.0494 (SE 0.0076) from a *narrower* interval, which cannot be a width artifact
  (`docs/dev-log/simulation-artifacts/2026-08-05-reml-interval-coverage/VERDICT.md:30-37, 70-80`).
- **That campaign's own headline claim was NOT ADMITTED** under its pre-registered rule, because
  its falsifier fired: REML was predicted not to help at `n_each = 3` and it did. The
  investigation cleared the harness on four independent checks, and the author records that the
  falsifier was mis-specified — it tested interval coverage against a probe about point estimates
  — while stating that reinterpreting one's own rule after seeing results is the move
  pre-registration exists to prevent (`VERDICT.md:39-95`). So the measurement stands; the claim
  does not.
- **Read that ML column carefully.** ML at g = 10 on that sigma-axis cell is 0.9240, within noise
  of the A1 mu-axis 0.9248. The two are different targets and different axes and I am not
  asserting they are the same phenomenon. But the coincidence is the reason a REML arm on the
  D-117 A1 cell is the obvious next measurement rather than a speculative one.

**So the concrete path to a materially better number, if you want one, is a REML arm on the exact
D-117 A1 cell**, pre-registered, paired on the same seeds, scored against a criterion set before
the run. The harness exists
(`2026-08-04-d117-10group-profile-gate/d117_profile_gate.R`), the campaign regenerates in about
20 minutes at 90 cores (`VERDICT-100K.md:333`), and the estimator is already implemented for this
route. What is *not* established is that it would reach nominal: dr20's finding 2 is precisely the
caution that REML alone may not, and the sigma-axis result is a different target.

**And if REML is not enough, what remains is research, not engineering.** Design 218 records the
conclusion after Wald-t, percentile bootstrap and bootstrap bias correction had all failed to
deliver the centre fix: *"`supported` at deployment-g is reachable in principle (the centre fix
reaches nominal) but requires a research-grade bias-correction derivation — a maintainer
commission, not an autonomous engineering task this cycle"*
(`docs/design/218-structured-q-series-completion-map.md:255-259`). The candidates it names are a
closed-form analytic or REML small-sample log-SD bias correction, or a double/iterated bootstrap;
it notes the scale-side restricted likelihood is underived. The package's AGHQ + Cox–Reid work
(`R/aghq-coxreid.R`, `docs/design/224-aghq-coxreid-nongaussian-reml-alignment.md`) is aimed at
*non-Gaussian* families and explicitly *"does not change any coverage tier or authorize a new
campaign"*; it is not a route to this Gaussian cell.

---

## 6. The boundary sub-problem is a different question with a different answer

Conditional on `profile.boundary` — a column `confint()` returns to the user — coverage is
**0.8683 / 0.1021 / 0.2387 / 0.0000**, at boundary incidence 49.70% / 3.70% / 7.63% / 0.09%, and
that sub-population contributes **85% / 45% / 78% / 1%** of each cell's total miss
(`VERDICT-100K.md:99-104`;
`docs/dev-log/simulation-artifacts/2026-08-09-d117-100k-regate/CROSSCHECKS.csv`). The mirror image
is that the *interior* over-covers: non-boundary coverage is **0.9769 / 0.9574 / 0.9823 /
0.9259** (same CSV). The pooled 0.9248 is an average over a well-covered interior and a badly
covered boundary sub-population, not a uniform 0.9248 everywhere.

Four things separate this from the overall coverage question.

**It is not a drmTMB defect.** `lme4::lmer` on the same DGP and the same seeds agreed on boundary
incidence 4000/4000, matched conditional coverage to four decimal places including the alarming
0.0732, agreed on point estimates to ~1e-6, and in the single divergence out of 4,000 returned an
interval that excluded its own MLE while drmTMB's did not
(`2026-08-04-d117-10group-profile-gate/COMPARATOR.md:39-74`). Scope caveat, stated because it is
easy to over-read: that comparator ran at 1,000 replicates per cell and was **not** re-run at
100,000, so 396,000 of the 400,000 new attempts have no `lme4` counterpart
(`VERDICT-100K.md:125-132`).

**It is a selection effect, not a calibration error.** Conditioning on `profile.boundary` selects
replicates whose SD estimate collapsed toward zero; those have low upper endpoints and miss a
non-zero truth almost by construction. This is post-selection inference, and the chibar arc states
the consequence directly: *"No cutoff choice repairs it"*
(`2026-08-05-d117-chibar-cutoff-arm/VERDICT.md:93-98`).

**The one candidate fix was tried and made it worse**, as §5 records.

**It is already disclosed at the point of use.** `confint(method = "profile")` warns with class
`drmTMB_profile_boundary_warning` when it returns a usable interval at a boundary, with a
regression test (`tests/testthat/test-d117-boundary-warning.R`), and the caveat and its numbers
appear on `origin/main` at `NEWS.md:124-128` and `NEWS.md:176-208`,
`man/confint.drmTMB.Rd:240-243, 266-272`, and `vignettes/first-week-intervals.Rmd:122`. The claim
is that it is disclosed, not that it is fixed.

**So the boundary sub-problem does not have a fix available and is not one drmTMB introduced.**
If your bar is that every sub-population a user can condition on must cover at nominal, that bar
is not attainable by any implementation of profile likelihood at a variance boundary that this
repository or the corpus knows of — including `lme4`. That is a genuinely different situation
from the overall 0.9248, where a named, implemented, untested lever (REML) still exists.

---

## 7. The question

The measured position, in one paragraph. The defect D-93 named has been repaired from 0.509 to
0.9248 at the 10-group corner, on 400,000 attempts with zero attrition, with the point estimate
running 8–16% low and the misses running 5.5:1 to 5.9:1 upper-heavy. That clears the repository's
`g`-tapered floor of 0.918 on raw coverage and on the strict one-sided test, and it does not reach
nominal 0.95. The floor it clears was fitted to what profile intervals achieve at small `g`, so
clearing it is a statement about typical method behaviour, not an independent finding of adequacy.
The literature has no benchmark to compare against below 10–15 groups and reports residual bias at
25 groups even with REML, so there is no external evidence that nominal-exact is attainable here —
and none that it is not. One concrete lever, REML on this exact target, is implemented and has
never been measured.

**This is a bar question, not a transparency question.** Every user-facing statement Reading B
would require is already on `origin/main` — the 8.3%–15.8% point bias in four places (§3), the
boundary caveat and its conditional coverage in three (§6), and an explicit public sentence that
0.9248 is real undercoverage (`NEWS.md:207`). Neither reading below turns on writing more
documentation. They differ only on what number is good enough.

**The two readings of your own words, priced.**

*Reading A — the nominal-exact bar.* "Until coverage is nominal" means what it says: `supported`
in the repository's vocabulary, |coverage − 0.95| ≤ 2·MCSE with balanced misses. **Consequence:**
0.7.0 stays held. The next step is the pre-registered REML arm on the A1 cell, and if that does
not close the gap, design 218's research-grade bias-correction derivation — a maintainer
commission on an open timeline, with no guarantee of success, since no source in dr20's corpus
demonstrates a nominal variance-component interval at ten groups by any method. The boundary
sub-population would remain outside any such bar regardless, because no cutoff repairs it.

*Reading B — the g-tapered-floor bar.* "An interval that actually covers" means an honest interval
at its achievable small-sample coverage, with the shortfall, the 8–16% point bias, the miss
asymmetry and the boundary caveat all stated in user-facing terms — `inference_ready`, not
`supported`. **That documentation already exists** (§3, §6), so this reading has no outstanding
disclosure work; what remains is a scope check that the capability guide names this exact cell.
**Consequence:** the D-93 hold lifts on the inference question, and 0.7.0 proceeds
under its own separate gates (#61 candidate prep, the unrun platform matrix, and your publish
decision — none of which this packet touches). drmTMB's first public appearance would then carry
a documented 2.5-point shortfall at ten groups on one route, shared with `lme4`, rather than
known-weak inference in the sense D-93 meant. The risk you accept is that "documented" is doing
the work "fixed" was supposed to do — which is close to the trade you declined on 2026-07-27, and
is the reason this is your call and not mine.

**Recommendation (mine, labelled, and not the decision).** I would take Reading B *conditional on
the REML arm being run first* — because it is cheap (about 20 minutes of Totoro compute on an
existing harness), because it is the one named lever nobody has measured on this target, and
because lifting the hold without it means retiring D-93 while the obvious next experiment sits
undone. If REML reaches nominal, Reading A's bar is met and the question dissolves. If it does
not, you would be deciding Reading B on strictly better information than you have now. I hold
this at moderate confidence and note the argument against it: an unmeasured lever is also an
argument for keeping the hold, and you have already overridden one recommendation on this exact
question.

**The question, which I am not answering:**

> **Is the bar for D-93 nominal-exact coverage (0.95 within Monte-Carlo error, with balanced
> misses), or an honest interval at its achievable small-sample coverage — the `g`-tapered floor
> of 0.918 that the measured 0.9248 clears — with the shortfall, the 8–16% point bias, the
> upper-tail miss asymmetry, and the boundary caveat documented in user-facing terms?**

---

## Numbers I could not verify

- **Nothing in §2's ladder is unverified.** Every figure was read from the cited primary file.
- **The 3-cell profile campaign is not on this branch.** `0.9400` and its per-cell 0.937 / 0.942 /
  0.941 were read from `profile-vs-bootstrap-report.md` on `origin/codex/sd-bootstrap-r999-diagnosis`;
  the directory is absent from `main` and from this worktree. It is on a remote, so it is
  retrievable, but it is not in the release lane's tree.
- **The raw per-replicate rows behind 0.9248 are not committed.** Four CSVs, ~195 MB, retained on
  Totoro with SHA-256 hashes recorded in `VERDICT-100K.md:326-331`. I verified the derived
  `SUMMARY.csv` and `CROSSCHECKS.csv`, which are committed and internally consistent, and the
  arc records three independent reviewers reproducing the headline from the raw rows. I did not
  re-derive from raw data myself.
- **The `lme4` comparator was never re-run at 100,000.** The parity claim rests on 4,000 paired
  fits at n = 1,000 per cell. Stated in `VERDICT-100K.md:125-132`; repeated here because the
  boundary attribution in §6 leans on it.
- **`ss_floor`'s functional form has no derivation I could locate.** The comment at
  `tools/gate-inference-ready.R:30-33` cites a banked g-sweep and an ~1/g taper; I found no
  document deriving the 0.04 coefficient or the 8/g form from theory. Treated throughout as an
  empirical convention, which is how §3 describes it.
- **`mc-0264`'s `supported` tier.** I quote the row and its `claim_boundary` verbatim and make no
  claim about what the tier means in the ledger's vocabulary. Flagged for whoever owns it.
- **All `NEWS.md`, `R/` and `man/` line numbers cite `origin/main`** and were re-verified against
  it after a concurrent slice — which had briefly added a second, differently-rounded statement of
  the same bias figure — was reverted. Those three files are byte-identical to `origin/main` as of
  2026-08-15 11:20. `DESCRIPTION` on this branch reads `0.7.0.9000` rather than `0.7.0`; that bump
  implements the 2026-08-15 no-re-freeze decision by stopping `main` from carrying the frozen
  candidate's exact version string while 60 shipped files differ from it, and the freeze will set
  it back.
- **No claim is made about routes outside the tested corner.** Everything above is A1 scalar
  Gaussian, `g = 10` for the D-117 figures, ML, `TRUE_BETA = 0.5`, residual `sigma = 0.7`,
  `n_per ∈ {4, 10}`, `sd_mu ∈ {0.5, 1.0}`. Not other families, providers, slopes, bivariate
  models, or group counts.

> Related: `~/shinichi-brain/memory/DECISIONS.md` D-93 / D-97 / D-117 / D-122 ·
> `~/shinichi-brain/memory/OPEN_QUESTIONS.md` CI-17 ·
> `docs/dev-log/release-audits/2026-08-09-d117-FINAL-RECOMMENDATION.md` ·
> `docs/dev-log/release-audits/2026-08-15-070-refreeze-timing-decision.md`
