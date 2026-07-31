# After Task: Lane C C1 count-q2 profile-status contract

## 1. Goal

Preserve the genuine labelled NB2/Poisson phylogenetic q2 point-estimate
contract while making its three direct targets visible but unavailable to
profile execution.

## 2. Implemented

For exactly labelled ordinary Poisson/NB2 `mu` intercept--slope q2 structured
fits, the two `log_sd_phylo` targets and `eta_cor_phylo` target remain direct
and extractable but now report `profile_ready = FALSE` and
`profile_note = "point_fit_only_count_q2"`.  No likelihood, extractor,
formula-admission, capability, or dashboard behaviour changed.

## 3a. Decisions and Rejected Alternatives

The user-visible target rows were retained rather than omitted, so users can
see the point-estimate estimands and their explicit non-profile status.  The
alternative of hiding rows would obscure that status; suppressing only one
`confint()` engine would leave another profile route active.  C0-08--C0-10
remain rejected and are not admitted by this contract.

## 4. Files Touched

- `R/profile.R` and generated `man/profile_targets.Rd`.
- Focused profile and count-structured target tests.
- This after-task report and its plan-versus-actual reconciliation.

Pre-existing untracked C3 forensic files and C9 receipts remain untouched and
are excluded from this C1 change set.

## 5. Checks Run

- Lane preflight: no Claude lane detected in the 12-hour remote window; weak
  evidence only.
- `tests/testthat/test-count-structured-mu.R`: passed.
- `tests/testthat/test-profile-targets.R`: passed.
- `devtools::document()`: regenerated `man/profile_targets.Rd`.
- `python3 tools/capability_ledger.py --check`: passed (30 generated outputs).
- `git diff --check`: passed.

## 6. Tests of the Tests

The labelled NB2 and Poisson tests retain the exact names, internal parameters,
target types, and point estimates.  They assert that the three rows are absent
from `ready_only = TRUE`; default `confint(method = "profile")` and
`profile()` reject before profiling; and a mock sentinel proves explicit
`profile_engine = "endpoint"` returns `profile_failed` without invoking the
endpoint refit routine.  Existing unlabelled q2 provider tests continue to
assert their profile-ready rows.

## 7a. Issue Ledger

No issue, capability, ledger, dashboard, or public support claim changed.  The
contract is a joint Lane B/C internal-status repair, not C0-08--C0-10 recovery.

## 8. Consistency Audit

The restriction predicate requires `model_type` Poisson or NB2 plus the exact
labelled same-`mu` scalar q2 grammar.  Thus q1, unlabelled q2, Gaussian and
bivariate q2, scale-side, and ordinary-RE targets retain their existing status.
The roxygen reference now describes the new controlled note.  The stale wording
scan used `rg -n "profile_ready|point_fit_only_count_q2|count q2" README.md
ROADMAP.md NEWS.md docs vignettes R tests`; only the intended registry/reference
surface required an update.

## 9. What Did Not Go Smoothly

The first review correctly required proof that explicit endpoint selection also
stops before a constrained refit.  The initial test covered only default
dispatch.  A mocked endpoint sentinel and a full `profile()` rejection test
were added; both focused suites then passed.

## 10. Known Residuals

- C0-08 spatial, C0-09 animal, and C0-10 relmat remain rejected.
- No profile, interval, bootstrap, recovery fixture, remote compute, or
  capability promotion occurred.
- Point-fit recovery evidence remains limited to the retained C0-04 and C0-07
  receipts; this status contract does not itself create a new receipt.

## 11. Team Learning

For a point-fit-only route, every profile entry point must be gated at target
discovery: default `confint()`, full `profile()`, and explicit endpoint mode.
Visible direct-but-not-ready rows make that restriction inspectable without
misrepresenting it as interval evidence.

## 12. Cross-Product Coverage

This contract covers only the labelled ordinary Poisson/NB2 phylogenetic q2
`mu` covariance targets.  It does NOT cover C0-08--C0-10
admission/recovery, NB2 scale q2, phylo-interaction, zero-one-beta, bivariate
association, interval feasibility, calibration, coverage, or capability
promotion.

## Next Actions

A new owner-approved Lane C recovery plan may now assess C0-08--C0-10 one
provider at a time against this established status contract.  It must still
provide provider-specific parser, dense-oracle, extractor, and retained
point-recovery evidence before any capability movement.
