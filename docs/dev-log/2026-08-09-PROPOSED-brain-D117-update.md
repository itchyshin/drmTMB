# PROPOSED brain edit — NOT WRITTEN (D-37: stage and propose)

Paste-ready. Two changes to `~/shinichi-brain/memory/DECISIONS.md`, plus one new atomic note.
**Nothing has been written to the vault.**

---

## 1. Append to the D-117 entry (after the 2026-08-05 correction block)

```markdown
> **⚠ 2026-08-09 — the gate was RE-RUN at 100,000 replicates per cell; discharge RECOMMENDED.**
> The 2026-08-04 run cleared the floor only on a `+2×MCSE` margin that shrinks as `1/√n`, and
> `VERDICT.md:115` had already flagged the worst cell going BORDERLINE at n ≳ 19,700. Nobody had
> paid the ~20 minutes of Totoro compute to settle it.
>
> **Coverage PASSES.** Pooled **0.924800** (SE 0.000417) over **400,000 attempts**; per-cell
> 0.9229 / 0.9257 / 0.9255 / 0.9251, all clearing `ss_floor(10) = 0.918` on **raw** coverage and on
> the stricter one-sided LCB — which the n=1,000 data could not support in three of four cells.
> 100000/100000 finite intervals throughout. **The pre-registered prediction (BORDERLINE, no
> discharge) was WRONG**: 0.9140 was a low Monte-Carlo draw, off by exactly 1.00 × MCSE.
> The marginal route's 0.810 collapse at ten groups — the specific fear behind D-117 — is refuted
> at 0.925.
>
> **Recovery was measured but never made scoreable.** D-117 specified no bias criterion. Raw-scale
> bias −15.76 / −9.31 / −10.26 / −8.34%, consistent with expected ML behaviour at ten groups and
> matching `lme4` to ~1e-6.
>
> **RECOMMENDATION: discharge**, because D-117's operative sentence conditions the hold on
> *"until that number exists"* and it now exists for both halves. Four conditions attach; the shipped
> docs' superseded n=1,000 figures are corrected. Discharge publishes nothing — #61, `platform-clean`
> and the publish decision all remain in front.
> **Awaiting Shinichi's decision.** PRs [drmTMB#974] (evidence) and [drmTMB#975] (user-facing
> figures, stacked). Full reasoning:
> `docs/dev-log/release-audits/2026-08-09-d117-FINAL-RECOMMENDATION.md`.
>
> **Review chain, stated honestly: no round returned unanimous DONE.** A D-43 panel (2/3 NOT-DONE),
> a re-adjudication panel (3/3 NOT-DONE), and a correction verifier (OVER-CORRECTED). Every defect
> found was in the *reasoning about* the result, never the result — which three reviewers reproduced
> independently from the raw rows, one bypassing the coverage column entirely.
```

## 2. New atomic note — `memory/The most dangerous error is the one made while fixing an error.md`

```markdown
---
title: The most dangerous error is the one made while fixing an error
type: note
tags: [claims-discipline, verification, reusable-lesson, drmTMB]
---

# Repair work needs MORE adversarial scrutiny than original work, not less

drmTMB's D-117 arc, 2026-08-09. Three adversarial rounds; the original campaign survived all of
them untouched. **Every defect was introduced while fixing a previous defect.**

- **Panel 1** (2/3 NOT-DONE): only the coverage half of a "recovery/coverage" gate had been measured.
- The repair added a recovery section — which claimed the mean log-SD statistic was "unusable" and
  told readers **not to quote it**. It cited 49.7% of fits as near zero when that figure was a
  *different column* (true share 6.07%), blamed a spread on "flooring" when the two numbers were
  *different formulas*, and reported a log-ratio (−0.7740) as a percentage (−77.4% vs the true
  −53.88%). Net effect: **it suppressed the statistic that looked worst.** Written inside a section
  whose purpose was to close a goalpost-related finding.
- **Panel 2** (3/3 NOT-DONE) caught all of it.
- The repair of *that* imported the Beta-phylogenetic arc's absolute 0.10 log-scale bar as if
  binding — a bar frozen at **g = 256** on a different family, which `lme4` would fail identically
  at g = 10. **Over-corrected into an unwarranted FAIL.**
- **A verifier** caught that, and the conclusion finally rested where it belonged: the gate is
  under-specified (no recovery criterion was ever pre-registered), which is not the same as failed.

**What to do with this.**

1. **Send repairs back through review.** A fix is new, unreviewed work with the *appearance* of
   having been vetted, because it carries a reviewer's name.
2. **Check which column a number came from.** Reading a figure that supports the argument you are
   writing, without checking it measures what you claim, is how (a) happened.
3. **Suppressing a statistic and importing a foreign bar are the same error** in opposite
   directions. Both let the choice of measure decide the outcome.
4. **Freeze the tree before dispatching reviewers.** Editing mid-review invalidates the brief and
   gives reviewers a moving target — paid for twice in this arc.

> Related: [[DECISIONS#D-117|D-117]] · [[DECISIONS#D-43|D-43]] ·
> [[Imperfect coverage is the norm, not a defect — lme4 undercovers too]] · [[LESSONS]]
```

## 3. One-line addition to `memory/LESSONS.md`

```markdown
- **A criterion set after seeing results is a preference, not a gate.** drmTMB D-117's recovery half
  had no pre-registered threshold; on the same 400,000 rows, defensible statistics spanned −0.12 to
  −0.77 in log units. Whoever picks the statistic afterwards picks the outcome. Set the bar first,
  or say plainly that the thing is unscoreable.
```

---

**Also worth knowing, not proposed as a vault edit:** `rnorm()` is **not** bit-identical across
platforms — ~1 ULP between x86_64/R 4.5.3 and arm64/R 4.6.0 (4 of 10 values, max rel. diff 2.77e-16).
Any campaign whose reproducibility claim crosses machines needs this stated. Recorded in
`docs/dev-log/simulation-artifacts/2026-08-09-d117-100k-regate/PROVENANCE.md`.
