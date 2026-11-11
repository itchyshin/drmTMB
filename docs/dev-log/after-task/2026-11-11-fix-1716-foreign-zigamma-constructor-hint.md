# After Task: #1716 constructor-call hint (Code Reviewer revision)

## Goal

Revise draft PR #1723 so the Code Reviewer items on head
`3325bac313caf67aa16c1ad091d15c8f77be9893` are gone: type or delete the
untyped Gamma errors, stop treating drmTMB's own `truncated_nbinom2` and
`lognormal` strings/uncalled functions as foreign inflation families,
merge `origin/main` if #1722 landed, and leave the PR body unedited.

The reader is the Code Reviewer who asked for a typed constructor-call
hint rather than a misleading foreign-inflation error.

## Implemented

`drm_eval_family_arg()` remains the family admission chokepoint. Before
the foreign-inflation matcher runs, string names and uncalled functions
that are drmTMB's own `truncated_nbinom2` and `lognormal` constructors
abort with class `drmTMB_family_constructor_call` and the hint
`Call drmTMB::<name>()`. Foreign `truncated_nbinom1` and a local
function named `ziGamma` still use `drmTMB_foreign_inflation_family`.

There is no supported-families condition class in `R/family.R`. The two
untyped `expect_error` calls on `family = "Gamma"` and
`family = stats::Gamma` were deleted; the entry point still returns the
string `"Gamma"` and the uncalled `stats::Gamma` function, so they cannot
take the silent Gamma-object misfit branch.

When the family argument is the namespaced call `glmmTMB::ziGamma(...)`,
the label is `glmmTMB::ziGamma` even though that object's closures live
in stats.

PR #1722 is on main. This branch merged `origin/main` and kept both NEWS
bullets.

## Mathematical Contract

No likelihood or formula-grammar contract changed. Called
`truncated_nbinom2()` and `lognormal()` still classify as
`"truncated_nbinom2"` and `"lognormal"`.

## Files Changed

- `NEWS.md` (merge of #1703 plus a constructor-call sentence on #1716)
- `R/family.R`
- `man/foreign-inflation-families.Rd`
- `tests/testthat/test-fix-1716-foreign-zigamma.R`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.d/2026-11-11-fix-1716-foreign-zigamma-constructor-hint.md`
- `docs/dev-log/after-task/2026-11-11-fix-1716-foreign-zigamma-constructor-hint.md`

Not edited: `R/drmTMB.R`, `R/methods.R`, `src/drmTMB.cpp`,
`tests/testthat/test-zero-one-beta.R`,
`tools/run-lane-c-c17c1-c14-model15-compatibility.R`. The PR body is
unchanged.

## Checks Run

R 4.3.3. Ledger: `python3 tools/capability_ledger.py --check` OK;
`--check-c14-receipt-equivalence` OK with C17 current-source compatibility
PASS. All five C17 watchlist files are byte-identical to `origin/main`.
`test-fix-1716-foreign-zigamma.R`: 15 tests, 46 passed expectations, 0
fail, 2 skip (`glmmTMB` absent). Family tests: link-contract 4/92,
control-family-validators 9/83, gamma-location-scale 7/76, family-dpq
5/23, batchA 14/131, batchB 6/63 (2 skip), batchC 12/122 (2 skip),
batchD 12/74 (3 skip); all 0 fail.

## Tests Of The Tests

On the previous head, `eval_family("truncated_nbinom2")` and
`eval_family(truncated_nbinom2)` threw `drmTMB_foreign_inflation_family`.
After this revision they throw `drmTMB_family_constructor_call` and the
message contains `drmTMB::truncated_nbinom2`. The same pair holds for
`lognormal`. `"truncated_nbinom1"` still throws the foreign-inflation
class. The deleted Gamma `expect_error` calls already failed closed on
main with an unclassed supported-families abort, so they were not a
#1716 regression.

## Consistency Audit

`rg` patterns: `meta_gaussian|tau ~|rho ~` (no hits in edited files);
`drm_family_type <- local` (none); `glmmTMB::beta()` (only the existing
test that asserts that label is absent). Status inventory: NEWS and
known-limitations updated; README, roadmap, and formula-grammar unchanged
because this is still a refusal, not a new family.

## GitHub Issue Maintenance

#1716 stays open on draft PR #1723. No extra issue was opened. The owner
decision to refuse is already recorded on the issue. This revision does
not edit the PR body and does not merge.

## What Did Not Go Smoothly

`{glmmTMB}` 1.1.15 now pulls `RTMB` / `doBy` / `pbkrtest`, and `doBy`
needs CRAN `Deriv`, which is not available for R 4.3.3 here. The live
`glmmTMB::ziGamma` label assertion therefore skips on this VM. The
hand-built namespaced-call path is the cheap substitute: recover the
package from `expr` when closures live in stats.

## Team Learning

A name matcher that treats `^truncated_` and `"lognormal"` as foreign
will also hit drmTMB's own constructors when they arrive as strings or
uncalled functions. Admit those names to the existing
`Call drmTMB::<name>()` hint before the foreign-inflation abort.

## Known Limitations

There is still no zero-inflated Gamma family. Stored
`fam <- glmmTMB::ziGamma(link = "log")` objects still refuse, but the
label falls back to the generic Gamma-plus-ziformula wording unless the
call expression itself is namespaced. String `"Gamma"` and uncalled
`stats::Gamma` remain unclassed later errors.

## Next Actions

Keep PR #1723 as a draft for re-review. Do not merge. Do not edit the PR
body. Do not edit `R/drmTMB.R` without a C17 recertify and Shinichi's
approval.
