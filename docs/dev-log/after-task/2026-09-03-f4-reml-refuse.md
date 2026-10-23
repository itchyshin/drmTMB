# f4 — the Julia route refuses REML it cannot deliver

Date: 2026-09-03 · Branch: `claude/followup-f4-reml-refuse` · Owner instruction: *"fix the silent ML fallback - make it refuse"*

## What was wrong

`drm_julia_warn_reml_unsupported()` warned and then fitted by maximum likelihood
when `REML = TRUE` was requested on a cell drmTMB believes DRM.jl cannot fit by
restricted maximum likelihood.

That is a change of estimator announced by a warning. Warnings are routinely not
read, and nothing downstream in the fit object says the number in front of you
answers a different question than the one you asked — only `effective_REML`, which
is not part of any normal workflow. The affected quantities are the worst possible
ones: REML exists to remove the downward bias in variance components, so the
silent substitution lands on the variance components themselves and on every ratio
built from them (`heritability()`, `repeatability()`, `icc()`).

## What changed

One function, renamed to `drm_julia_refuse_reml_unsupported()`, `cli_warn` →
`cli_abort`. Four call sites, all pre-existing. No other file under `R/`.

The refusal fires **before** anything is marshalled to Julia — the tests assert
this by checking the mocked bridge call's captured options stay `NULL`, so an
unsupported request costs no fit rather than a wasted one.

## A claim I made to the owner that was wrong

I reported that three routes hard-code `effective_REML = FALSE` and reach ML
"without even the warning", and described that as a worse problem than the one
being fixed. **That was wrong.** Reading the dispatch sites shows all three —
cross-family (`:384`), bivariate q2 known-covariance structured (`:408`), general
structured-effect (`:426`) — call the condition helper before dispatching, with the
`drm_julia_reml_supported()` gate at `:478` as the fourth. There is one choke
point, not one plus three holes. That makes the fix smaller and uniform: renaming
the single helper reported exactly `4 call sites renamed`.

## Why this did not wait for the support census

The original ledger ordered the census before the refusal, on the reasoning that
refusing a cell which would have worked is the opposite of the fix. That ordering
was wrong, because the two failure directions are not symmetric:

| gate is | user gets | recoverable? |
|---|---|---|
| too **narrow** (refuses a cell DRM.jl could REML-fit) | a visible error naming two routes that work | yes, in one line |
| too **wide** (forwards REML where DRM.jl downgrades) | ML output labelled REML | no — nothing tells them to look |

The refusal changes behaviour **only** on cells the gate already calls unsupported,
turning "silently wrong estimator" into "visible error". It cannot create a
too-wide fault, and it strictly improves the too-narrow one. The census is a
precondition for *widening* the gate, which is a separate change. Recorded in
`.unlazy/followup/gates/leaf-f4.md` rather than made silently.

Census batch 1 (4 cells, pin 77513aa0, `3cac19829`) agrees with the current gate on
every cell, and found no instance of the dangerous wide direction.

## The `engine = "tmb"` pointer is deliberately bounded

A pre-existing test asserted the old warning did **not** overclaim a native TMB
fallback — outside Gaussian, TMB has only a diagnostic-only binomial REML route.
That guard is carried onto the error path rather than dropped, and the message says
explicitly that TMB "does not offer a general REML fit for every cell this bridge
refuses". Replacing a silent wrong answer with a confident wrong pointer would not
have been an improvement.

## Verification

`.unlazy/followup/gates/leaf-f4.md`. RED control: reverting `cli_abort` to
`cli_warn` fails 4 test blocks / 8 assertions; restored byte-identically (`diff`
empty). Refusal file 52 passed / 0 failed. Collateral sweep over every test file
pairing `REML = TRUE` with the Julia bridge — objective-at-bridge, mspl-estimator,
phylo-q4-corpairs, julia-bridge, biv-student, joint-missing, structured,
gate-vs-engine — 637 passed / 0 failed / 0 errors.

## What this does NOT cover

- **Census batches 2 and 3 are not done**, and batch 1 was measured at the old pin
  77513aa0. The gate is therefore verified against 4 cells, not the full grid. A
  cell where DRM.jl silently downgrades would still be forwarded; batch 1 found
  none, which is evidence, not proof.
- **The gate is not widened.** Any cell DRM.jl can REML-fit but
  `drm_julia_reml_supported()` calls unsupported now errors where it previously
  returned an ML fit. That is the intended direction of the trade, but it is a
  real usability cost for any such cell, and the census is what will find them.
- The TMB engine's own REML behaviour is untouched.
