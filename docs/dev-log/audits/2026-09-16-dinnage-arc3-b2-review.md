# Independent review note: PR #1375, Dinnage Arc 3 Wave B2 surfaces

Reviewer lane: Gauss (TMB / C17 recertification)
Date: 2026-09-16
PR: https://github.com/itchyshin/drmTMB/pull/1375
PR head at review: `9c5a90dd3c0a131a70a52ecb849f3763a4d62e02`

## D-263 REQUEST CHANGES (P0)

CI failed on all Ubuntu shards with `mc-0568` C17/C14 model-15 fingerprint drift:
`R/drmTMB.R` and `R/methods.R` changed on the PR without re-certifying the pinned
five-file blob.

## C17 resolution

Re-ran `tools/run-lane-c-c17c1-c14-model15-compatibility.R` at PR tip via
`tools/recertify-c17.py --label pr1375-b2`.

| cell_id | mean_tau_relative_error (prior A1 receipt) | mean_tau_relative_error (B2 tip) | \|change\| |
| --- | --- | --- | --- |
| mc-0568 | 0.099003177368826 | 0.099003177368826 | 0.000e+00 |
| mc-0569 | 0.166077467316735 | 0.166077467316735 | 0.000e+00 |
| mc-0576 | 0.0613049351664568 | 0.0613049351664568 | 0.000e+00 |

Measured behaviour is **inert** (bit-identical on all three cells). The ledger now
points at receipt
`docs/dev-log/implementation-recovery/2026-09-16-pr1375-b2-c17c2-c14-final-source-compatibility/`
with `current_source_sha=9c5a90dd3` and updated `source_fingerprint`
(`5ab7a964…`). Companion C17/C14 manifests were repointed to the same receipt.

`python3 tools/capability_ledger.py --check` and
`python3 -m unittest tools.tests.test_capability_ledger` pass locally, including
the fail-closed C17 failure-mode test.

## P2 doc fixes bundled

- `?confint.drmTMB` `@return` cross-links [as.matrix.drm_confint()].
- `R/control.R`: removed duplicate "admit admit" wording in the S7 documentation.

No merge performed. D-263 re-review remains for the independent reviewer; this
note does not self-ACCEPT D-263.
