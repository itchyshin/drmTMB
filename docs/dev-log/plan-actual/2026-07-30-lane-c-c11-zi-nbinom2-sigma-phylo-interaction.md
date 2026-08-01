# C11 plan-versus-actual reconciliation

## Planned outcome

C11 planned one exact point-fit decision for `mc-0653`: ML zero-inflated NB2
with a q1 phylogenetic interaction in `sigma`, fixed `mu`, and `zi ~ 1`.
Promotion required a closed endpoint dispatch, independent mixture-plus-
Kronecker oracle, profile fence, four structured attempts, and four ZINB IID
pair-random-intercept control attempts.

## Actual outcome

The narrow R/C++ route was built. Model type 9 now routes endpoint code 0 to
`eta_mu`, code 1 to `log_sigma`, and hard-errors unknown codes. The exact
formula, extractor, visible-but-not-profile-ready target, rejection matrix,
endpoint sentinel, objective/AD-gradient oracle, and profile fence pass their
focused tests.

The primary clean-source structured fixture (`run-2`) passes all four
attempts. The required IID control does not fit: all four attempts are
rejected before optimization because `sigma ~ (1 | pair), zi ~ 1` remains a
separate unimplemented zero-inflated ordinary sigma-RE route.

| Gate | Result | Consequence |
|---|---|---|
| Exact C11 formula and oracle | PASS | narrow implementation retained |
| Structured four-seed recovery | PASS | not sufficient alone |
| ZINB IID pair-RE control | BLOCK | no ledger transition |
| `mc-0653` ledger action | none | remains not_implemented |

## Deviation and decision

No gate was relaxed. The first dirty-source runner is retained as `run-1` but
its seed-resampling sequence could overlap between attempts; `run-2` fixes
that mechanical defect and is the decision receipt. The IID control failure is
architectural, not an optimization failure. Adding the ordinary ZINB sigma-RE
formula merely to satisfy the control would violate C11's formula boundary, so
the correct result is a durable blocker. No ledger, Mission Control,
Future-extension audit, profile, interval, coverage, remote-compute, Lane A,
or Lane B change occurred.
