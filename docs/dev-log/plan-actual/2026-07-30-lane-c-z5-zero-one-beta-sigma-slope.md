# Lane C Z5 — plan versus actual

| Planned gate | Actual result |
| --- | --- |
| Exact sigma q1 slope formula | Repaired after review: fixed and random slopes must share the same numeric predictor. |
| Direct point-fit-only target | Verified as direct, visible, not profile-ready; default, direct, and endpoint calls fence before refitting. |
| Full-mixture oracle and gradient | Existing independent mixture-plus-normal-prior oracle and AD-versus-FD test passed on the exact slope fit. |
| Four retained local attempts | Rerun with 32 groups x 50 observations; 4/4 pass the predeclared local gate, with source SHA and runner MD5 retained. |
| Mixture and clamp diagnostics | Atom counts, per-group support, log-sigma extrema, clamp status, and a zero-true-SD diagnostic are retained. |
| Ledger promotion | Deferred until a fresh completion panel; `mc-0576` remains not implemented. |

The first compact runner omitted material diagnostics and the formula predicate
admitted a mismatched fixed/random slope. Both defects were retained, repaired,
and rerun rather than waived. This work establishes no interval, calibration,
or broader capability claim.
