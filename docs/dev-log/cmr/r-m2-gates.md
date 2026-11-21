# R M2 fixed-effects CJS gate receipt — 2026-10-06

Acceptance ledger: `.unlazy/cmr-m2/GATES.md`. Final command:

```sh
UNLAZY_APPROVAL_DIR=/private/tmp/cmr-unlazy-20261006 node /Users/z3437171/.codex/skills/unlazy/scripts/gate-check.mjs --approve --reverify .unlazy/cmr-m2/GATES.md
```

Final status: **7/7 met**, reran all seven; shell `/bin/sh`; execution root `/private/tmp/cmr-drmtmb-20261006`. Every success requires exit zero and the declared marker.

| Gate | Check | Result |
|---|---|---|
| G1 prediction | `Rscript tools/check-cmr-m2.R --gate prediction` | `CMR_M2_PREDICTION_OK` |
| G2 conditional simulation | `Rscript tools/check-cmr-m2.R --gate simulation` | `CMR_M2_SIMULATION_OK` |
| G3 Wald guard | `Rscript tools/check-cmr-m2.R --gate wald` | `CMR_M2_WALD_OK` |
| G4 profile endpoints | `Rscript tools/check-cmr-m2.R --gate profile` | `CMR_M2_PROFILE_OK` |
| G5 bootstrap accounting | `Rscript tools/check-cmr-m2.R --gate bootstrap` | `CMR_M2_BOOTSTRAP_OK` |
| G6 smoke fits | `Rscript tools/check-cmr-m2.R --gate recovery` | `CMR_M2_RECOVERY_OK`; four of four converged, finite, and no worse in likelihood than their generating vectors |
| G7 integration and docs | `Rscript tools/check-cmr-m2.R --gate integration` | `CMR_M2_INTEGRATION_OK`; method, data, exact-kernel, contract, derivative, parity and documentation-source checks passed |

The integration run matched the pinned `marked` 1.2.8 likelihood exactly on its retained fixture. The source-checkout vignette rendered to `/private/tmp/cjs-first-capture.html`. The suite reports upstream `nobars` / `findbars` deprecation warnings from `reformulas`; they did not fail the gates.

The four-fit smoke is execution evidence only. It does not establish coefficient recovery, identification, interval availability, nominal coverage, calibration, or campaign performance.
