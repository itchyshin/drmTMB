# S0-A3 literature cites

Grounded 2026-08-09. Every line below was located by `grep` in the named file at
the named line. Nothing here is supplied from model knowledge; an item that could
not be grounded is marked NOT FOUND rather than filled in.

Vault root: `/Users/z3437171/Dropbox/Github Local/Shinichi`

## 1. Albert & Anderson (1984) — existence ⟺ overlap

`memory/ENGINEERING-NOTEBOOK.md:984`

> "overlap ⇒ MLE exists and is unique"

Recorded there as Theorem 3 (via Silvapulle 1981), with the note that overlap is
*necessary and sufficient* for MLE existence, so the complete / quasi-complete /
overlap trichotomy is exhaustive. **This is the estimand the S0-A3 cone test
targets**, and it is why certifying the overlap negative control matters: without
it, the harness cannot claim the trichotomy was exercised.

## 2. Konis (2007) — LP detection and its cost

`memory/ENGINEERING-NOTEBOOK.md:1198`

> "about the same time as one IRLS"

Detection scales roughly linearly in `n` and `p` and costs about one IRLS fit,
so it is cheap enough as a routine pre-fit gate. Shipped in `detectseparation` /
`brglm2` — which is why S0-A2 uses `detectseparation 0.4.0` as the maintained
comparator rather than reimplementing detection.

## 3. Firth (1993) / Jeffreys penalty — finiteness, equivariance

`memory/lane-notes/FOR-DRM-LANE-2026-08-08-separation-borrowable-from-the-literature.md:83`

> "provably finite, **equivariant**, **no tuning parameter**"

Attributed there to Kosmidis & Firth Theorem 1.

## 4. Kosmidis & Firth (2021) — the Wald coverage warning ⚠

`projects/deep-research/dr32-separation-rare-species-jsdm-distilled.md:121`
(verbatim quotation of the paper inside the distilled note):

> "will fail to cover regardless of the nominal level"

The note records that this failure **persists even for profile penalized-likelihood
CIs**, and `projects/deep-research/README.md:53` summarises the consequence as
"no remedy ships with Wald intervals". Corroborated at
`memory/ENGINEERING-NOTEBOOK.md:1071`, which adds the mechanism: because the
penalized estimator *and its SE* are always finite over a finite set of possible
responses, the pathology follows from finiteness itself, not only from separation.

**Why this is in a separation receipt at all:** it bears directly on the adjacent
MSPL lane, whose stated first inference target is a Wald covariance. Flagged as a
cited finding for that lane's owner. It is **not** acted on here, and it implies
nothing about the disposition of this experiment.

A sibling repo has already written this down —
`projects/gllvmTMB/separation-capability-plan.md:81` quotes the same wording — so
the constraint is cross-repo, not a drmTMB-only concern.

## 5. Sterzinger & Kosmidis (2023) — MSPL composite penalty

`memory/ENGINEERING-NOTEBOOK.md:1392`

> "a composite penalty (Jeffreys-invariant prior on fixed effects + a negative-Huber-loss penalty on"

`:1406` adds that the negative-Huber term acts on the lower-triangular Cholesky
entries ψ of Σ. This matches design note 250 in the MSPL lane, which frames
`estimator = "mspl"` around exactly this construction.

## 6. Where separation bites in drmTMB; boundary vs separation

`memory/lane-notes/FOR-DRM-LANE-2026-08-08-separation-borrowable-from-the-literature.md:32–49`

- `zi ~ predictors` and `hu ~ predictors` **are logistic regressions**, so they can
  separate — the high-value, low-obviousness target, since it is framed as
  zero-inflation rather than binary regression. Marked `AGENT-INFERRED` in the
  source that this is currently undiagnosed; treated here as a lead, not a fact.
- The binomial / Bernoulli / beta-binomial mean submodel is the classic case.
- σ → 0 and ρ₁₂ → ±1 are **boundary** problems, *not* separation — the note says
  plainly "do not conflate them". S0-A3 stays on the fixed-design binomial mean
  and makes no boundary claim.

The same file records that the separation literature assumes a **fixed design
matrix**, which drmTMB has and gllvmTMB does not, so "the theory applies to
drmTMB verbatim" and drmTMB is the proving ground.

## Grounding tally

6 of 6 items grounded to a file and line. 0 NOT FOUND.

**Correction to the discarded first pass:** it attributed the Kosmidis & Firth
quotation to `ENGINEERING-NOTEBOOK.md:1068–1073`. The verbatim quotation lives in
`dr32-…:121`; line 1071 of the notebook carries a *paraphrase* with the finiteness
mechanism. Both are real, but only the former is quotable as the paper's wording.
