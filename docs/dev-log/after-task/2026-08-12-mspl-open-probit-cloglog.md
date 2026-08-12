# After-task — the MSPL fence is open for probit and cloglog

**2026-08-12 · Claude · `claude/mspl-open-probit-cloglog` · commits `619372a62`, `e9fec67d4`**

## 1. What was asked, and what shipped

Open the MSPL guard for probit and cloglog, as a complete arc rather than a code change.

`estimator = "mspl"` required `binomial(link = "logit")` exactly. It now also accepts `probit` and
`cloglog`. Nothing else about the route moved: `engine = "tmb"`, one ordinary `q = 1` or correlated
`q = 2` grouping block, no REML, no penalty interface, no intervals.

## 2. The basis

Kosmidis & Firth (2021) Theorem 1 with §3.1 prove the Jeffreys penalty gives finite estimates for any
link whose working weight vanishes in both tails; logit, probit and cloglog all do. That is existence.
What was missing was drmTMB's own numerical evidence, which the 2026-08-11 arc supplied — four
pre-registered campaigns, **460,000 fits**, four distinct seed streams, merged as PR #1019:

| gate | result |
|---|---|
| G0 / G0b | R kernels match `glm()` IRLS weights (4.8e−8) and an independent Jeffreys determinant (5.6e−10); the compiled objective matches them along a separation ray in both tails |
| G1b | **0 non-finite estimates in 43,972 completed fits** |
| G3 | standard errors **calibrated** in the identified regime — probit `[0.946, 1.008]`, cloglog `[0.957, 1.027]` |
| G2 | the logit-calibrated `c_n` costs **~1% of one standard error** |

## 3. Two decisions worth recording

**`c_n` stays as shipped.** It is a logit delta-method constant and is knowably mis-calibrated for the
other two links (they want 1.2533 and 1.3108 against the shipped 2). Design 253 §5 rejects modifying
it, because a per-link constant defines a *different estimator*. That left an uncomfortable position —
a knowably wrong constant that we are forbidden to fix — until G2 measured the cost of leaving it
alone. It is immaterial, so §5's rejection now rests on evidence rather than principle.

**Start values changed for all three links, which is the riskier half.** The MSPL intercept now starts
at the link of the observed event rate rather than 0. At `β = 0` cloglog implies a 0.632 event rate,
so a rare-event design began ~4.8 log units from its own intercept and the optimizer could reach NaN.
Shipping cloglog without this would have handed users avoidable failures. It affects the **shipped
logit route** too: measured, cloglog optimizer failures 33 → 28 at full replication, with 120
previously-passing fits re-checked and `β` moving at a median ~1e−7.

## 4. The review panel earned its place

D-43 panel on `619372a62`: **Noether NOT-DONE, Fisher DONE.** Noether's findings were right.

1. **A backwards factual claim in user-facing documentation.** The roxygen said the standard error is
   unavailable *"more often for probit and cloglog than for logit."* It is the other way round —
   logit's worst cell is **98.3%**, the highest of the four. I verified it against the raw G3 data
   before changing it. This would have shipped to users in `man/drmTMB.Rd`.
2. **Two unscoped claims.** G2 measured `c_n` materiality at `q1`, `p = 2` only, while the guard
   admits `q2`; the ~1% figure appeared unscoped in the roxygen, `NEWS.md` and design 253 Addendum 4.
   Fisher independently added that the SE-calibration evidence used Bernoulli responses with two
   fixed-effect columns, so grouped-binomial and wider designs inherit the pre-existing `n_eff`
   extrapolation without measurement.
3. **A dropped weight.** The intercept start computed the observed rate as `sum(y)/sum(trials)`,
   ignoring `frequency`, while every other MSPL quantity uses `trials * frequency`. Frequency-weighted
   rows are a supported, tested path, so the start described a different dataset than the one being
   fitted.

Noether also found that `G3-cell-results.csv` — cited in `VERDICT-G3-SE.md`'s provenance — was never
committed, which is why finding 1 could not be checked from primary data. Regenerated and landed on
the evidence branch.

All fixed in `e9fec67d4`. Suite unchanged at **399 pass, 0 fail, 0 error** across seven files, since a
start value moves no fitted answer.

## 5. Not fixed, recorded

- Design 251's *"the admitted binomial-logit surface"* line is now stale. The Wald-covariance
  mathematics there is link-independent, so this is cosmetic.
- The adversarial corner never tested small `c_n` **and** deep separation jointly, for any link. The
  G1 verdict already self-flags this; it predates and is unaffected by this change.
- log-log and cauchit satisfy KF2021's condition and are **not** admitted: drmTMB has no `link_code`
  for them and no evidence was gathered.

## 6. Release timing is the maintainer's call, and it is not free

This touches `R/`, `man/` and `NEWS.md` while **0.7.0 is frozen**. The candidate already required a
re-freeze (recorded in the CRAN lane's own snapshot); this adds a **shipped-source** change to that
list, so merging before submission means re-cutting the tarball and re-running platform evidence —
including win-builder, which has not run against the current candidate at all.

**Deferring this to 0.7.1 or 0.8.0 is entirely reasonable** and is a release decision, not an
engineering one. The branch is complete and will keep. Nothing about it degrades by waiting.

## 7. Files

`R/mspl-estimator.R` (the guard) · `R/drmTMB.R` (start values + roxygen) · `man/drmTMB.Rd` ·
`NEWS.md` · `docs/design/252-binomial-link-generalisation.md` (§7 SUPERSEDED in place) ·
`docs/design/253-mspl-nonlogit-links-derivation.md` (Addendum 4) · `docs/dev-log/check-log.md` ·
`tests/testthat/test-mspl-nonlogit-links.R` (new) · `test-mspl-estimator.R` and
`test-mspl-link-dispatch.R` (two assertions inverted, each with a SUPERSEDED note so the contract
change is visible in history rather than silently deleted) · this report.
