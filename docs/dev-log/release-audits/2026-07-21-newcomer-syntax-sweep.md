# Newcomer-syntax sweep — 0.6.0 pre-CRAN (rung 1b)

**Date:** 2026-07-21 · **Method:** toy fits against installed `drmTMB 0.6.0.9000`, asking what happens
when a reader arrives from `lme4`, `glmmTMB`, `brms`, `gamlss`, or base `glm` and types what they already
know. Classification: **FITS**, **CLEAN** (error names the problem and a way forward), **RAW** (internal R
error that helps nobody). No compute campaign; no capability claim.

PR #810 changed no R code, so the installed parser matches the release candidate for formula handling.

## Result

**14 of 17 attempts are FITS or CLEAN. Three defects, one of them worth fixing before a first release.**

The headline is mostly reassuring: the random-effects grammar, the brms-style `sigma ~ x`, `poly()`,
`offset()`, and `cbind()` all behave, and the two most likely user mistakes (nested `(1 | g1/g2)` and
`dispformula =`) already produce good errors.

| # | Attempt | From | Verdict | Message / note |
|---|---|---|---|---|
| 1 | `(1 \| g)` | lme4 | FITS | |
| 2 | `(1 + x \| g)` correlated | lme4 | FITS | |
| 3 | `(1 \| g) + (0 + x \| g)` | drmTMB doc | FITS | the documented uncorrelated form |
| 4 | **`(1 + x \|\| g)`** | lme4/brms | **RAW** | `'length = N' in coercion to 'logical(1)'` |
| 5 | `(x \| g)` implicit intercept | lme4 | FITS | |
| 6 | `(1 \| g1/g2)` nested | lme4 | CLEAN | "grouping terms must be simple variables" + shows supported spellings |
| 7 | `(1 \| g1:g2)` interaction | lme4 | CLEAN | same good message |
| 8 | `(0 + x \| g)` slope only | lme4 | FITS | |
| 9 | `dispformula =` | glmmTMB | CLEAN | "`formula` must be created with `drm_formula()` or `bf()`" |
| 10 | `ziformula =` | glmmTMB | CLEAN | same |
| 11 | `sigma.formula` in `bf()` | gamlss | **CLEAN-ish** | leaks internal jargon: "**Phase 1** Gaussian models only support…" |
| 12 | bare formula, no `bf()` | lme4/glmmTMB | CLEAN | same as 9 |
| 13 | `poly(x, 2)` | base | FITS | |
| 14 | `offset(log(off))` | base/glm | FITS | |
| 15 | `cbind(succ, fail)` | glm | FITS | |
| 16 | **`s(x)` smooth** | mgcv/gamlss | **RAW** | `could not find function "s"` |
| 17 | `sigma ~ x` | brms | FITS | |

## Defect 1 (fix before release) — `||` falls through to the fixed-effect design matrix

Root cause is exact, not inferred. `terms(y ~ x + (1 + x || g1))` returns term labels:

```
[1] "x"            "1 + x || g1"
```

The random-term parser recognises `|` only, so `||` is never seen as a bar. The term survives as a
**fixed-effect** label, the design matrix evaluates `1 + x || g1` as a logical-or over length-N vectors,
and R aborts with `'length = N' in coercion to 'logical(1)'` (`conditionCall` is literally
`1 + x || g1`). The N in the message is the row count, which is why it looks like a size problem and
isn't.

**This reclassifies #776.** `||` is not new capability. In lme4 `(1 + x || g)` *means* exactly
`(1 | g) + (0 + x | g)` for a numeric slope — a form drmTMB already fits and has already certified. So
first-class `||` is a **pure formula desugaring onto an existing supported route**: no likelihood, no TMB
change, no new evidence, no coverage campaign. That puts it in rung 1b, not post-0.6.

Two options, both cheap:

- **(a)** Detect a `||` call during random-term parsing and `cli::cli_abort` naming the two-term form.
- **(b)** Desugar `(1 + x || g)` → `(1 | g) + (0 + x | g)` and gain twin-alignment with gllvmTMB and
  lme4/brms. Caveat worth honouring: for a **factor** slope, lme4's `||` does not fully decorrelate, so
  either restrict desugaring to numeric slopes or error explicitly for factors rather than silently
  copying lme4's known wart.

Recommendation: **(b)**, restricted to numeric slopes, with (a)'s clean error as the factor fallback.
It closes #776, removes the worst first-impression defect, and adds no evidence burden.

## Defect 2 (small) — internal phase jargon in a user-facing error

Attempt 11 returns "**Phase 1** Gaussian models only support `mu` and `sigma`." "Phase 1" is internal
roadmap vocabulary and means nothing to a reader. Reword to name the supported distributional parameters
without the internal phase label. Worth a grep for other `Phase \d` strings in user-facing messages.

## Defect 3 (small) — `s(x)` gives a base-R error

`could not find function "s"` is R's, not drmTMB's. A gamlss/mgcv user trying a smooth deserves "smooth
terms are not supported; use `poly()` or splines from `splines::`". Same class as defect 1 but far less
likely to be hit, since the user has to import `s` from somewhere first.

## What this does NOT cover

Formula/error surface only. No claim about estimator correctness, coverage, or any capability tier. Run
against installed `0.6.0.9000`; re-run against the frozen release candidate as part of rung 2.
