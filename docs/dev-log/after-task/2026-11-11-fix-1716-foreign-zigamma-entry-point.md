# After Task: #1716 foreign ziGamma refusal (entry-point revision)

## Goal

Revise draft PR #1723 so the Code Reviewer blockers on head
`37021149e3c1b94b76b00a3c0e6bfb5a8ea8a1e4` are gone: stop rebinding
`drm_family_type()` at load time, call the guard from the family entry
point, fix source-package detection, and cover the other family-argument
shapes that can reach a foreign inflation family.

The reader is the Code Reviewer (and the next agent on this PR) who asked
for a path-proof that the guard does not belong in `R/drmTMB.R`.

## Implemented

`drm_maybe_abort_foreign_inflation_family()` is called from
`drm_eval_family_arg()` after the expression is evaluated. That function is
the family entry point for `drmTMB()`, `impute_model()`, and
`drm_resolve_priors()`. The top-level `drm_family_type <- local({...})`
wrap in `R/family.R` is gone, so the classifier in `R/drmTMB.R` is
untouched.

`drm_stats_family_source_package()` now uses
`environmentName(topenv(environment(fn)))` and returns `NULL` for `base`,
`stats`, and `R_GlobalEnv`. A hand-built `ziGamma` family whose `variance`
function lives in `utils` reports `utils` and the refusal label contains
`utils::ziGamma`.

String names (`"ziGamma"`, `"truncated_nbinom1"`, `"hurdlePoisson"`),
uncalled constructors named `ziGamma`, two-element family lists,
`biv_associate()`, and `impute_model()` are refused with class
`drmTMB_foreign_inflation_family`. `family = "Gamma"` and
`family = stats::Gamma` (the function, not the call) still fail closed
later: `drmTMB()` does not coerce names or call family constructors, so
they cannot take the silent Gamma-object misfit branch.

## Mathematical Contract

No likelihood or formula-grammar contract changed. Plain
`Gamma(link = "log")`, `beta_family()`, and `lognormal()` still classify
as `"gamma"`, `"beta"`, and `"lognormal"`.

## Files Changed

- `R/family.R`
- `tests/testthat/test-fix-1716-foreign-zigamma.R`
- `docs/dev-log/check-log.d/2026-11-11-fix-1716-foreign-zigamma-entry-point.md`
- `docs/dev-log/after-task/2026-11-11-fix-1716-foreign-zigamma-entry-point.md`

Not edited: `R/drmTMB.R`, `R/methods.R`, `src/drmTMB.cpp`,
`tests/testthat/test-zero-one-beta.R`,
`tools/run-lane-c-c17c1-c14-model15-compatibility.R`. The PR body is
unchanged.

## Path-proof (Code Reviewer item 1)

`drm_eval_family_arg()` is the only evaluator of a user-supplied `family`
argument. The three call sites are `drmTMB()` (`R/drmTMB.R`),
`impute_model()` (`R/missing-data.R`), and `drm_resolve_priors()`
(`R/fixed-priors-workflow.R`). `biv_associate()` and
`drm_phylo_penalty_sweep()` pass family objects into `drmTMB()`. Methods
such as `simulate()` reuse `object$family` from a fit that already passed
the entry point. There is no `update.drmTMB()`.

Putting the guard on `drm_family_type()` would miss `impute_model()`,
which classifies through `drm_impute_family_type()` and has the same
`family = "Gamma"` branch. Direct `drm_family_type()` on a Gamma family
whose `initialize` mentions `ziformula` still returns `"gamma"`; that is
the C17-watchlist classifier left in place, and the test file asserts
both the entry-point refusal and that unwrapped classification.

## Checks Run

R 4.3.3. Ledger: `python3 tools/capability_ledger.py --check` OK;
`--check-c14-receipt-equivalence` OK with C17 current-source compatibility
PASS. `R/drmTMB.R` SHA `5be5ba5480117fd8527e28b1bba7670d4e09cbca` matches
`origin/main`. Branch `test-fix-1716-foreign-zigamma.R`: 13 tests, 43
passed expectations, 0 skips (`glmmTMB` 1.1.8 present).
`test-env-skip-census.R` 5/0. Related family tests: link-contract 92,
control-family-validators 83, gamma-location-scale 76, all 0 fail.

## Tests Of The Tests

On this branch, `drm_eval_family_arg()` throws
`drmTMB_foreign_inflation_family` for a Gamma family whose `initialize`
mentions `ziformula`, while `drm_family_type()` still returns `"gamma"`.
That pair fails if the wrap is restored, and the first half fails on
`main` because `drm_eval_family_arg()` only evaluated the argument. The
`utils::head` source-package test fails if `topenv()` is not used or if
`utils` is treated as an ignored namespace. The string `"Gamma"` test
fails if drmTMB starts coercing family names the way `glm()` does.

## Consistency Audit

`rg` patterns: `meta_gaussian|tau ~|rho ~` (no new hits in edited files);
`drm_family_type <- local` (no remaining wrap); `glmmTMB::beta()` (only
the existing test that asserts that label is absent). Status inventory:
NEWS and known-limitations already describe the refusal; README, roadmap,
and formula-grammar unchanged because this is still a refusal, not a new
family.

## GitHub Issue Maintenance

#1716 stays open on draft PR #1723. No extra issue was opened. The owner
decision to refuse is already recorded on the issue. This revision does
not edit the PR body and does not merge.

## What Did Not Go Smoothly

The previous revision rebound `drm_family_type()` after `R/drmTMB.R` was
sourced so the C17 watchlist file would stay byte-identical. That wrap
was the Code Reviewer's first blocker: it is a load-time monkey-patch,
and it is the wrong chokepoint because `impute_model()` never calls
`drm_family_type()`.

## Team Learning

When a watchlist file owns the classifier, put admission guards on the
evaluator that every user-facing family argument already passes, then
prove the call graph. A wrap of the classifier looks like a chokepoint
and still misses sibling classifiers.

## Known Limitations

There is still no zero-inflated Gamma family. String `"Gamma"` and
uncalled `stats::Gamma` are not foreign inflation objects; they fail
later with the existing supported-families error rather than being
called as `Gamma(link = "log")`. Flattened `c(family, family)` objects
are reconstructed through `drm_composed_families()` inside the same
guard.

## Next Actions

Keep PR #1723 as a draft for re-review. Do not merge. Do not edit
`R/drmTMB.R` without a C17 recertify and Shinichi's approval.
