# Authorisation: advance `status_claim` to `platform-clean` when its evidence exists

**2026-08-16 (early) · Shinichi, in session: "1 authorize 2 fine 3 not submit yet 4 good", answering
the four-item list (1 = the D-49 status-claim advance · 2 = the Gate 7 panel · 3 = submission ·
4 = housekeeping: brain deltas / quiesce lift / vignette PR).**

## What is authorised

Under D-49, advancing `status_claim` from `tarball-clean` to **`platform-clean`** in
`docs/dev-log/release-audits/2026-08-15-070-cran-release-ledger-2.json` is **authorised in
advance, conditional on the evidence actually existing**: the win-builder results (R-release +
R-devel) filed as `evidence.external_logs`, and `cran_release_gate.py` passing the
`platform-clean` claim mechanically. The advance happens only when the gate says READY at that
claim — a fail-closed check, not a promise.

The Gate 7 panel (Grace/Rose/Pat, fresh contexts, default NOT READY) proceeds as planned once
win-builder results are clean.

## What is explicitly NOT authorised

**Submission: "not submit yet."** No CRAN upload regardless of gate, panel, or rung state. The
`submission-ready` claim, if the panel supports it, may be *assembled as evidence* but the upload
is a separate future decision of Shinichi's.

## Housekeeping approved in the same reply

- The staged D-93 / D-117 discharge deltas are written to the brain vault (D-37 approval given).
- The quiesce lifts when the platform matrix completes — its own condition, unchanged.
- The vignette-hardening PR merges only after the quiesce lifts and on its own review.
