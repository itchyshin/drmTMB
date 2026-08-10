# D-117 — final recommendation

**2026-08-09 · `claude/d117-discharge` · supersedes the recommendation in
`2026-08-09-d117-discharge-decision-packet.md`, whose §6 was conditioned on a panel that has since
reported.**

This document exists because the arc's earlier closing deferred the decision instead of
recommending one. Shinichi decides; my job is to say what I would do and why, so he can overrule a
position rather than construct one.

---

## RECOMMENDATION: **DISCHARGE D-117 and release the 0.7.0 hold.** Confidence: moderate-to-high.

### The reason is D-117's own operative sentence

> *"Before drmTMB 0.7.0 publishes, Curie runs a single fixed-seed 10-group recovery/coverage gate on
> the profile random-effect SD interval. **0.7.0 stays held until that number exists.**"*

The hold is conditioned on **the number existing**, not on a threshold being cleared. D-117 was
written to stop 0.7.0 publishing on an *unmeasured* smallest-group corner — the worry being that the
profile route might repeat the marginal route's collapse (0.810 at 10 groups). That worry is now
answered, and answered against:

- **the number exists for both halves**, at **400,000 attempts** — 400× the replication D-117
  contemplated;
- **coverage passes its pre-registered criterion** decisively: pooled **0.924800** (SE 0.000417),
  every cell clearing `ss_floor(10) = 0.918` on **raw** coverage, and passing the stricter one-sided
  LCB that the n=1,000 data could not support in three of four cells;
- **the profile route does not collapse** the way the marginal route did — 0.925 vs 0.810. That is
  the specific question D-117 was built to settle, and it settles in the package's favour;
- **recovery is measured**: −15.76 / −9.31 / −10.26 / −8.34% raw-scale, MCSE ≤ 0.13%.

### Why the recovery half should not extend the hold

1. **It has no pre-registered criterion, and inventing one now decides the outcome.** On the same
   400,000 rows, defensible statistics span −0.12 to −0.77 in log units (mean vs median, raw vs log,
   trimmed vs untrimmed). A threshold chosen after seeing that spread is not a gate, it is a
   preference.
2. **The magnitude is the expected ML property, not a defect.** Downward bias in a variance
   component at ten groups is textbook, and `lme4` on the same DGP and seeds agrees on point
   estimates to **~1e-6**. A bar this fails is a bar `lme4` fails identically — it is evidence about
   maximum likelihood at ten groups, not about drmTMB.
3. **Holding for it would be internally inconsistent.** The coverage floor is deliberately
   `g`-tapered *because* small `g` is expected to underperform. Applying a `g`-flat recovery bar
   imported from a `g = 256` arc contradicts the reasoning already accepted for the other half.

### What must ship with the discharge (these are conditions, not garnish)

1. **State the recovery bias in user-facing terms.** A user fitting this design should be told their
   random-effect SD estimate runs low by roughly **8–16%**. It belongs in the capability claim, not
   only in a dev-log.
2. **Keep the claim inside the tested corner.** A1 scalar Gaussian, `g = 10`, ML, `TRUE_BETA = 0.5`,
   residual `sigma = 0.7`, `n_per ∈ {4,10}`, `sd_mu ∈ {0.5,1.0}`. Not other families, providers,
   slopes, bivariate models, or group counts.
3. **Do not let discharge read as nominal-exact coverage.** 0.9248 against nominal 0.95 is real
   undercoverage; the `g`-tapered floor exists precisely to price that.
4. **The boundary caveat stays visible.** Conditional-on-boundary coverage is
   0.868 / 0.102 / 0.239 / 0.000, contributing 85% / 45% / 78% / 1% of each cell's miss. Already
   warned at point of use (`drmTMB_profile_boundary_warning`) and documented in `NEWS.md`,
   `man/confint.drmTMB.Rd` and the vignettes — that documentation is load-bearing for this
   recommendation and must not regress.

### The strongest argument against my recommendation

**If you read "recovery/coverage gate" as requiring a *pass* on both halves, D-117 does not
discharge**, and the correct action is to set a recovery criterion — pre-registered, `g`-aware,
ideally validated against `lme4` so it discriminates implementation from estimator class — and score
against it before releasing the hold.

I do not think that reading is the better one, because the sentence conditions the hold on the
number existing and because no recovery threshold was ever specified even in principle. But it is a
legitimate reading of your own words, and it is the one that would overturn this recommendation. It
is a one-word correction if I have read you wrong.

### What would change my recommendation

A recovery criterion that (a) you set independently of these results, and (b) these results fail.
Nothing in the current evidence does that on its own.

---

## Both paths, priced

| | **DISCHARGE** (recommended) | **HOLD** |
| --- | --- | --- |
| What happens now | 0.7.0's D-117 blocker clears; release proceeds under its own separate gates (#61 candidate prep, `platform-clean`, your publish decision) | 0.7.0 stays held |
| Additional work | ~1–2 h: fold the 8–16% bias and the corner scope into the capability claim and release notes | Set a pre-registered, `g`-aware recovery criterion, validate it against `lme4` so it separates estimator from implementation, then score. **~0.5–1 day of design, minutes of compute** — the data already exists |
| Risk taken on | Publishing with a documented, `lme4`-shared negative bias at ten groups and known boundary undercoverage | Delay; and the risk that any criterion set now is fitted to results already seen |
| Reversibility | A release cannot be unshipped — but D-89 records that submission is far away by choice, so discharge ≠ submission | Fully reversible |
| Evidence still missing | None that this arc can supply | A criterion, which is a decision not a measurement |

**Note the asymmetry that makes discharge the safer-looking call less obviously right:** discharging
D-117 does **not** publish anything. It clears one blocker on a release that still sits behind
issue #61 (candidate prep, NO-GO without your authorisation), an unproven `platform-clean` rung, and
your own publish decision. The irreversible step is several gates further on.

---

## Disposition of every open finding — resolved or explicitly refused

| # | Finding | Disposition |
| --- | --- | --- |
| 2026-08-04 #1 | Pooled PASS averages two regimes | **RESOLVED by owner decision** — pooled is the gate, conditional a reported diagnostic (2026-08-09) |
| #2 | Unreported point-estimate bias | **RESOLVED** — measured at 100k (§6b), attributed to ML via paired `lme4` |
| #3 | "Not materially worse" at z ≈ 2.5 | **RESOLVED, and inverted** — against a like-for-like `g=10` comparator z = −1.586, not significant |
| #4 | D-97 provenance vs the arc's premise | **RESOLVED for the premise**; the residual — that the corrected comparator is itself pooled across `g` — is **quantified** in §5 and **REFUSED as a blocker**, since the like-for-like comparison is the one that governs |
| #5 | After-task failed the hub validator | **RESOLVED** — verified by running `check-after-task.R`; this arc's own report also passes |
| #6 | No user-facing boundary warning | **RESOLVED** — fires on the real user path, silent otherwise, regression test 9 PASS |
| Panel-2 Rose #1 | Recovery half unmeasured at 100k | **RESOLVED** — §6b |
| Panel-2 Rose #1b | No after-task shipped | **RESOLVED** |
| Panel-2 Rose #2/#3 | §8 headline; lme4 scope bound dropped | **RESOLVED** |
| Panel-2 Rose #4 | Stale commit counts (×3) | **RESOLVED** — the count is no longer hard-coded |
| Panel-2 Rose #5 | Roadmap commit off-scope for this lane | **REFUSED** — content is accurate and the landmine was live; lane purity does not justify leaving a fresh session pointed at an aborted arc |
| Panel-2 Fisher | §6b mechanism errors; no bias bar | **RESOLVED** (errors corrected) and **REFUSED as a blocker** (the absent bar is the finding, not a defect to fix) |
| Panel-2 Grace | Compiler / `RNGkind` / locale absent | **RESOLVED** — `PROVENANCE.md`, plus a measured cross-platform ULP result |
| Verifier | Over-correction: unfair precedent-bar transplant | **RESOLVED** — demoted to a labelled non-binding cross-reference |
| Residual | `package_commit = NA`; no `sessionInfo()` in harness; Totoro not backed up | **REFUSED for this arc** — all three require editing the frozen 2026-08-04 runner or infrastructure outside this lane. Recorded in `PROVENANCE.md` as open |
| Residual | lme4 comparator not re-run at 100k | **REFUSED as a blocker** — cheap and worth doing, but the attribution claim is bounded to n=1,000 in writing and does not carry the recommendation |

**Nothing is left silently open.** Every item above is either resolved with evidence or refused with
a stated reason.

---

## Honest status of the review chain

Three adversarial rounds ran: a D-43 panel (2/3 NOT-DONE), a re-adjudication panel (3/3 NOT-DONE),
and a correction verifier (OVER-CORRECTED). **No round returned unanimous DONE**, and I am not
claiming one did.

What that chain established, which matters more than a clean verdict:

- the **coverage result is right** — reproduced from the raw 400,000 rows by three independent
  reviewers, one bypassing the coverage column entirely;
- every defect found was in **my reasoning about the result**, not in the result;
- the last two rounds found errors in **repairs**, in opposite directions — first too permissive
  (suppressing a bad-looking statistic), then too harsh (importing an unfair bar). The measurement
  never moved.

The final edits implementing the verifier's prescription have not themselves been re-reviewed. I
judge further rounds to have crossed into diminishing returns: the conclusion's *direction* has been
stable across the last two rounds and only its *reason* changed, and each additional panel now
critiques wording rather than evidence. That is a judgement, and it is the one place a reader should
apply their own discount.
