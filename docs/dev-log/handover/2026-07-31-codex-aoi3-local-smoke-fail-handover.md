# Session Handoff: AOI-3 local smoke failed — DRAC blocked

## State

The owner authorized AOI-3 local smoke and a DRAC campaign only if the smoke
passed. The private smoke source is commit
`e9a24c30350ca3b5c5fc783ae161840ded905a23`; its retained output is
`docs/dev-log/simulation-artifacts/2026-07-31-aoi3-local-smoke/`.

The reducer decision is `AOI3_LOCAL_SMOKE_FAIL_DRAC_BLOCKED`. Do not submit,
stage, resubmit, or reinterpret a DRAC calibration campaign under this failed
contract.

## Exact outcome

Of five `n = 720` outer draws, additive was `boundary_unresolved`; the other
four were interior/private-sandwich available. Additive's seven inner rows are
correctly `not_eligible`. The 28 eligible inner refits contain 26 interior and
two transformation `boundary_unresolved` rows. This is a local mechanical
gate result, not a calibration or public inference result.

## Correction retained

The first reducer attempt failed because formula-specific coefficient tables
had nonidentical columns. `tools/summarize-aoi3-bernoulli-nb2-smoke.R` now
unions schemas before its strict all-attempt checks; the raw smoke was not
rerun or altered.

## Boundaries

AOI-2 remains `HOLD_NO_POINT_RECOVERY_CLAIM`. No `vcov()`, `confint()`,
standard-error, interval, capability-ledger, public documentation, or public
association inference claim exists. Lane B, Arc D, and foreign Association PR
#854 remain untouched.

## Resume only with a new owner decision

Read the failed-smoke receipt, contract, and raw decision first. A new AOI-3
proposal must freeze a changed target/route, a new source SHA and seed map, and
a fresh local smoke. It must not select a better seed, discard failed rows, or
pool with the failed smoke.
