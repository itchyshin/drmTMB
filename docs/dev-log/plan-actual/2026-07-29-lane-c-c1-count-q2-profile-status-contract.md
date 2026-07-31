# Plan versus actual: Lane C C1 count-q2 profile-status contract

## Plan receipt

Implement a visible direct-but-not-ready profile status for the three labelled
Poisson/NB2 phylogenetic q2 targets; preserve point-estimate identities and
exclude all provider admission, recovery, interval, and capability work.

## Actuals

| Axis | Planned | Actual | Disposition |
|---|---|---|---|
| Scope | Exact labelled count q2 status only | Four tracked code/test/reference files plus closeout receipts | matched |
| Contract | Direct, visible, not profile-ready | `point_fit_only_count_q2` direct rows | matched |
| Verification | Default/full/endpoint profile routes stop | Default and full routes error; endpoint mock proves zero refit calls | matched after repair |
| Evidence | Focused count and profile tests | Both focused files pass; ledger check and diff check pass | matched |
| Safety | Preserve C3/C9 forensic material | All remain untracked and excluded | matched |
| Public claims | No interval/capability statement | No ledger/dashboard/API addition or promotion | matched |

## Material deviation

The first test did not instrument endpoint dispatch.  Fisher raised the gap;
the added mock sentinel verified that `profile_ready = FALSE` stops endpoint
evaluation before `drm_profile_target_endpoint_confint()`.  Classification:
**adaptive repair**, not scope drift.

## Reconciliation verdict

No material plan drift remains.  Stage and commit only the C1-owned registry,
reference, tests, and these two C1 receipts; leave C3/C9 material unstaged.
