# D-117 discharge decision packet — Fisher (statistical inference review)

**For Shinichi. He decides; this prices the options. Written 2026-08-09,
`claude/d117-discharge` off `origin/main @ a2695a788`.**

---

> **⚠ SUPERSEDED FIGURES — read with `VERDICT-100K.md §6b`.** This packet was written
> *before* the recovery half was recomputed on the 100,000-replicate data, and before the
> D-43 panel reported. Two corrections apply throughout:
>
> 1. **Every recovery/bias number below is the n = 1,000 figure** (-16.90 / -9.12 / -9.05 /
>    -9.16%). The current values, from the 400,000 rows, are
>    **-15.76 / -9.31 / -10.26 / -8.34%** (`VERDICT-100K.md` §6b). All four changed;
>    `g10_n10_sd05` moved a full point.
> 2. **The panel has now run: 2 of 3 NOT-DONE, so the composite claim is WITHHELD.** This
>    packet's §6 conditions its recommendation on that panel; the condition resolved
>    *against* it. The blocking findings are repaired but have **not** been re-adjudicated.
>
>    The packet's *reasoning* stands; its numbers and its confidence statement do not.
>
> 3. **Its §6 recommendation is SUPERSEDED.** It was conditioned on a panel that has since reported
>    NOT-DONE, which made it non-actionable as written. The operative recommendation now lives in
>    **[`2026-08-09-d117-FINAL-RECOMMENDATION.md`](2026-08-09-d117-FINAL-RECOMMENDATION.md)**:
>    **discharge D-117**, with four conditions, both paths priced, and every finding dispositioned.

## 1. What D-117 asked for, and whether it was delivered

D-117's own text (`~/shinichi-brain/memory/DECISIONS.md`, `### D-117`):

> "Before drmTMB 0.7.0 publishes, **Curie runs a single fixed-seed 10-group
> recovery/coverage gate** on the *profile* random-effect SD interval. 0.7.0 stays
> **held** until that number exists."

**The coverage half is satisfied.** The number exists: pooled coverage **0.924800
(SE 0.000417)** over 400,000 attempts, every one of the four pre-registered cells
clears `ss_floor(10) = 0.918` on raw coverage, not just on the `+2·MCSE` margin
(`docs/dev-log/simulation-artifacts/2026-08-09-d117-100k-regate/VERDICT-100K.md:9-29`).

**The recovery half is measured, not clean.** Point-estimate bias for `estimate_sd`
is `-16.90% / -9.12% / -9.05% / -9.16%` across the four cells, `p < 1e-23` throughout
(`.../PANEL-FINDINGS-2-3-4.md:36-43`), and it is the documented mechanism behind the
interval's upper-side miss asymmetry (`.../2026-08-04.../VERDICT.md:83-87`). D-117 did
not specify a bias bar, so this does not by itself withhold discharge, but "recovery"
was named in the gate and a materially biased point estimate is part of what was
asked for, not a side note.

**Literally read, D-117 is satisfied**: the number exists, on the frozen
pre-registered rule, with both cited integrity controls passing. Whether that
number is *sufficient to publish* is a separate judgement — see §3 and §6.

---

## 2. The case FOR discharge

- **Pooled coverage clears the floor with margin to spare.** 0.9248 vs floor 0.918,
  every cell 0.9229–0.9257, spread 0.0028 (was 0.023 at n=1,000)
  (`VERDICT-100K.md:15-22,66-68`).
- **The strict cross-check also passes.** One-sided LCB `p̂ − 1.645·SE` clears 0.918
  in all four cells (0.9215/0.9243/0.9242/0.9237); exact `binom.test` gives `p = 1`
  in all four (`VERDICT-100K.md:26-29`). The `+2·MCSE` margin the 2026-08-04 verdict
  called anti-conservative (`.../2026-08-04.../VERDICT.md:111-121`) is not doing any
  work here.
- **Two integrity controls, both passed.** Bit-exact prefix reproduction against the
  banked 2026-08-04 campaign — `max|diff| = 0.000e+00` on `estimate_sd`,
  `profile_lower`, `profile_upper`; 0/1000 disagreements on `profile_covers`,
  `profile_boundary`, `fit_converged`, `pdHess` — across a rebuild that intervened
  the boundary-warning commit `4b601a448` (`VERDICT-100K.md:49-58`). Local/Totoro
  environment parity on the S0 smoke, identical to 12 significant figures
  (`VERDICT-100K.md:60-61`).
- **The pre-registered hypothesis that motivated the re-run was falsified, on the
  record, before the fact.** The prediction (BORDERLINE, `.../PREREGISTRATION.md:43`)
  was written and committed (`ab83638f5`) before the 100k fit ran, named its own
  falsification condition, and that condition was met
  (`.../PREDICTION-OUTCOME.md:12-24`). This is not merely a PASS; it is a PASS that
  survived an adversarial, pre-committed test of itself.
- **Panel findings #2, #3, #6 resolved; #4 resolved for the arc's premise.**
  `VERDICT-100K.md:145`. Full derivations in `.../PANEL-FINDINGS-2-3-4.md`.
- **The corner is not significantly below a like-for-like comparator.** Against
  the `g = 10`-only 2026-07-26 subset (0.9370, `n = 1,000`), `z = -1.586`, not
  significant. It is significantly below (`z = -3.490`) only a comparator **pooled
  across `g ∈ {10,25,50}`** (`VERDICT-100K.md:75-83`) — precisely the structural
  error D-117 exists to prevent (using a pooled-across-group-count figure to judge
  a specific group-count corner).

---

## 3. The case AGAINST discharge

This is not a strawman pass. Four points, none of them resolved by the 100k number
itself.

**(a) The boundary sub-population is the dominant source of the miss, and it is
worse in three of four cells than anything the pooled figure shows.** Conditional
on `profile.boundary` (`profile_lower == 0` exactly):

| cell | boundary incidence | conditional coverage | share of total miss |
|---|---:|---:|---:|
| `g10_n04_sd05` | 49.70% | 0.8683 | **85%** |
| `g10_n04_sd10` | 3.70% | 0.1021 | 45% |
| `g10_n10_sd05` | 7.63% | 0.2387 | 78% |
| `g10_n10_sd10` | 0.09% | **0.0000** (0/89) | 1% |

(`VERDICT-100K.md:95-100`). A user who fits this model and reads `confint()`'s own
`profile.boundary` column is, in three of four regimes, looking at an interval whose
*conditional* coverage is 10–24%, not 92%. The pooled 0.9248 is a genuine population
average; it is also true, simultaneously, that the sub-population identifiable from
the fit's own output is badly miscovered. Both statements hold at once — pooling
does not resolve the tension, it states it.

**(b) `g10_n10_sd10`'s 0/89 is newly visible, not newly reassuring.** At `n = 1,000`
this cell had **zero** boundary events, so its conditional coverage was unmeasurable
(`.../PREREGISTRATION.md:76-80`). At `n = 100,000` it is 0/89 covered — every single
boundary event in this cell missed
(`VERDICT-100K.md:100,108-111`). Its 0.09% incidence keeps the *pooled* effect
negligible (moves the headline by 0.0009), but "0 for 89, once we could finally see
it" is not a number that should be filed under "no material change" without saying
so plainly. `VERDICT-100K.md` does say so (§6, points 1–2) — but the aggregate
recommendation in §8 does not carry the distinction that this is the one cell where
conditional coverage is not merely bad but total.

**(c) 0.9248 against nominal 0.95 is real undercoverage.** `VERDICT-100K.md` states
this itself (line 133-134): "It is also not nominal-exact coverage... which is why
the floor is `g`-tapered in the first place." The `ss_floor` construction is a design
decision to accept a known gap at small `g`, not a demonstration that the gap is
small in absolute terms. A reader who wants "95% means 95%" is not being served by
this evidence; nobody claims otherwise, but it belongs stated for the discharge
question specifically.

**(d) The tested surface is a single narrow corner, and it is treated as
representative of a 0.7.0-wide claim.** `TRUE_BETA = 0.5`, residual `sigma = 0.7`,
one mean formula, `n_per ∈ {4,10}`, `sd_mu ∈ {0.5,1.0}`, `g = 10` fixed, Gaussian
family, ML estimator only (`VERDICT-100K.md:129-134`). Not tested: any non-Gaussian
family, any provider other than the default, slopes, bivariate models, other group
counts, or REML. D-117's own wording says "a single fixed-seed 10-group... gate" —
so this is in-scope for what was asked, but a reader of the release notes should not
infer that random-effect-SD profile intervals are broadly characterized. They are
characterized at exactly this corner.

**(e) `ss_floor` prices `g` alone, not `n_per` or total `N`.** `ss_floor(g) = 0.95 -
0.04 × (8/g)` is a function of `g` only (`score_d117_gate.R:16`,
`.../PREREGISTRATION.md:84-98`). `g10_n04_sd05` (`N = 40`) is held to the identical
0.918 bar as `g10_n10_sd05` (`N = 100`, 2.5× the data). Both cleared it, so this did
not change the verdict this time, but it means the floor cannot currently
distinguish "10 groups of 40 total observations" from "10 groups of 100" — a
genuinely different inferential situation for a variance component. Recorded before
results specifically so it could not look like a rescue (`.../PREREGISTRATION.md:95-98`),
and it remains unresolved as a floor-design question.

**(f) Two caveats from the panel's own re-analysis do not appear anywhere in
`VERDICT-100K.md`.** `.../PANEL-FINDINGS-2-3-4.md:127-133` (RULING #2) identifies
two things as "genuinely new and not yet in `VERDICT.md`": (i) the conventional
log-SD bias statistic is unstable in the boundary-heavy cell — mean log bias implies
**-55.5%** multiplicative bias vs a median-based **-13.7%**, driven entirely by a
near-zero tail (63/1000 estimates `< 1e-3`, minimum `1.0e-5`); (ii) the point-estimate
bias is not a function of `g` alone — it roughly doubles (-16.9% vs -9.1%) when
`n_per` drops from 10 to 4 at fixed `g = 10`, a mechanism the ruling calls "a
plausible mechanism, not a verified one" for lack of a citation
(`.../PANEL-FINDINGS-2-3-4.md:112-125`). `VERDICT-100K.md` was written after this
ruling and does not carry either point forward into its own text or its §7
establishes/does-not-establish summary. That is a gap in the document that is
about to be used to justify a release decision, not a new empirical problem.

**(g) The like-for-like comparator that clears the corner (§2, `z = -1.586`) is
itself low-powered.** Its SE is 0.00768, from `n = 1,000` (`.../PANEL-FINDINGS-2-3-4.md:185`),
against the 100k figure's SE of 0.000417. A true gap of 1–2 percentage points
between the corner and the wider profile route would not reliably produce a
significant `z` against a comparator this imprecise. "Not significantly below" is
correct as reported, but it is a failure to reject, not a demonstration of
equivalence, and the *only* reason the corner is significantly below anything is a
comparator (pooled-across-`g`, `z = -3.490`) that the arc itself says is the wrong
comparator to use. Put plainly: the evidence base cannot currently tell the
difference between "the corner behaves like the rest of the profile route" and "the
corner is 1-2pp worse but we don't have the power to see it."

**(h) `VERDICT-100K.md`'s own precondition for acting on its recommendation has not
been met.** §8 (lines 152-155) explicitly asks for "**a fresh D-43 panel — with
Bash and git**... before the recommendation is acted on," naming the 2026-08-04
panel's Read/Grep/Glob-only Noether seat as the reason the prior panel could not be
trusted end to end. Checking `git log` on this branch: the most recent commit is
`14958bed0` (the VERDICT-100K.md commit itself); the only review since then is
`8b962c16b`, a single-reviewer Fisher pass on findings #2/#3/#4 — not the
three-reviewer D-43 panel the document calls for. **This packet is not that panel
either**, and does not substitute for it.

---

## 4. Residual risk of discharging now

Concretely, what could a user experience that this evidence does not rule out:

- A user fits a scalar Gaussian random-intercept model at `g ≈ 10`, gets a
  point estimate for the RE-SD, and does not read the `profile.boundary` column.
  If their true SD is small relative to their design (the `sd_mu = 0.5`, `n_per = 4`
  regime), there is a ~50% chance their fit is at the boundary
  (`VERDICT-100K.md:97`), and conditional on that, their nominal-95% interval covers
  the truth about 87% of the time in the best of these cells and as low as 0-24% in
  the others (§3a). The pooled 0.9248 figure is not what they experience; the
  conditional figure is.
- A user in a slightly different corner — non-Gaussian family, a slope rather than
  an intercept, `g` between 10 and 25, REML instead of ML, a bivariate model — has
  zero direct evidence either way. Nothing here generalizes past the tested corner
  (§3d), and D-117 never asked it to.
- A user who reads only the pooled coverage number in the vignette or NEWS entry
  and not the boundary warning at the point of use forms a materially wrong picture
  of reliability in the specific sub-population where it matters most. This risk is
  mitigated, not eliminated, by the warning (§5) — mitigation depends on the warning
  firing and being read, not on the underlying coverage having improved.

None of these are new risks created by discharging; they are the residual risk that
was always going to exist once the corner was measured rather than assumed. The 100k
run does not add new risk; it also does not remove the risk described in §3.

---

## 5. What ships with it either way

- **The `confint()` boundary warning fires, verified by execution, not by
  description.** `warn_profile_boundary()` (`R/profile.R:1869` on
  `origin/main @ a2695a788`) is reached from both `confint()` paths and fires on
  this arc's own boundary seed (`20660728`, cell 4, `profile_lower = 0`) with class
  `drmTMB_profile_boundary_warning`, and stays silent on the paired non-boundary
  seed (`20660729`) — no false positive
  (`.../2026-08-04.../VERDICT.md:248-267`). I re-ran the regression test myself in
  this worktree (`pkgload::load_all()` then `testthat::test_file()`):
  `tests/testthat/test-d117-boundary-warning.R` — **9/9 PASS**, confirmed by
  execution in this session, not taken on the document's word alone.
- `NEWS.md:33-37,85-108` and `man/confint.drmTMB.Rd:96-100,169-173,237-239` document
  the regime: read `profile.boundary`/`conf.status`, the warning class, and the
  statement that the warning "does not repair coverage."
- **`lme4` behaves identically on the same DGP and seeds** — boundary incidence
  agrees 4000/4000, conditional coverage matches to four decimal places in every
  affected cell including 0.0732, coverage outcomes agree 3999/4000
  (`COMPARATOR.md:30-55`). This is real evidence that §3's collapse is a property of
  profile likelihood near a variance-component boundary, not a drmTMB root-finder
  defect, and it is why the fix implemented is a warning rather than an engine
  change (`COMPARATOR.md:76-85`).
- **The inverse trap, stated so it is not silently relied on:** "`lme4` does it too"
  explains *where the behaviour comes from*. It does not discharge the duty to warn
  and document it — `lme4` itself does not warn at this boundary (it is drmTMB that
  added the warning `lme4` lacks). A comparator that shares your defect is evidence
  about causation, not permission to leave it undocumented. `COMPARATOR.md:89-99`
  makes the same distinction: agreement "narrows the cause; it does not validate the
  method."

---

## 6. Recommendation

**Discharge D-117 as literally worded — the single fixed-seed 10-group
recovery/coverage gate exists, on the frozen rule, with both integrity controls
passing and the pre-registered adversarial prediction against it falsified.**
**Do not treat that as "the profile RE-SD interval is safe" more broadly** — hold
the release-readiness question open pending (i) the fresh three-reviewer D-43 panel
`VERDICT-100K.md` itself calls for (§3h), and (ii) folding the two unresolved
recovery-side caveats (§3f: log-SD instability, non-`g`-only bias) into the document
before it is cited as the basis for a public claim.

**Confidence: moderate-high on the coverage number itself (it is well-measured and
adversarially tested), moderate on "ready to act on" (the document's own
precondition for action is outstanding).**

**The single piece of evidence that would most change this recommendation:** the
fresh three-reviewer D-43 panel (with Bash/git access, unlike 2026-08-04's
Noether seat) actually running and returning verdicts on the 100k evidence. If it
returns ≥2 DONE, this packet's moderate confidence should rise; if it returns ≥2
NOT-DONE (the arc's own frozen rule, `D43-PANEL.md:3`), the discharge recommendation
above should be withdrawn, not merely qualified.

---

## 7. What is NOT authorised by this packet

- Candidate release prep (issue #61 remains NO-GO).
- Merging PR #959.
- Any platform-clean claim, tagging, or CRAN upload.
- **D-89 stands**: drmTMB's first CRAN submission is far away *by choice*
  ("we want to do a lot of checking etc.," `~/shinichi-brain/memory/DECISIONS.md`
  D-89). There is no clock. Nothing in the 100k result changes that; it is a
  reason to run the fresh panel properly (§3h, §6), not a reason to skip it.
- Re-scoring the gate, moving the floor, or dropping a cell — all frozen per
  `PREREGISTRATION.md:64-70` and untouched by this packet.
