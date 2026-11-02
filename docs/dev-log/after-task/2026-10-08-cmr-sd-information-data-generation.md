# After Task: CMR individual-SD information diagnostic data

## 1. Goal

Prepare the frozen ten-dataset diagnostic at N=800 and N=1600 to examine whether increasing individual sample size improves recovery of process-specific log-SD coefficients. This step generates data only.

## 2. Implemented

Ran the pinned v6 generator without changing its source or the primary recovery manifest. It produced five datasets at each sample size using the reserved diagnostic seed range.

## 3a. Decisions and Rejected Alternatives

Kept this as a data-only step. No fitted estimates or model-comparison conclusions were produced before both current implementation snapshots are admitted.

## 4. Files Touched

The spec, generator, generation receipt, and compressed dataset bundle are retained in `docs/dev-log/cmr/sd-offset-repair-2026-10-08/information-diagnostic-candidate/`. The original scratch output remains at `/private/tmp/cmr-sd-increasing-information-data/`. This report, its check-log row, and the CMR checkpoint were updated.

## 5. Checks Run

The generator exited zero in about two seconds and reported ten datasets. An independent Python audit verified the pinned manifest and generator hashes, ten ordered seeds, the five-plus-five sample-size allocation, all 50 CSV hashes, every recorded CSV row count, the frozen coefficients and balanced covariate levels in all ten truth tables, and the exact contents of the 51-file archive without macOS metadata. The dataset archive SHA-256 is `71a6cdcb88559017bb886c81c76ae2f86a6f3236c010315ef140756afe86fba5`.

No model fit, benchmark, recovery run, or interval calculation was started.

## 6. Tests of the Tests

The audit recomputed hashes from the saved files and counted rows through `csv.DictReader`; it did not rely only on the generator's success marker. The primary manifest and generator hashes were checked against the frozen values in the diagnostic spec.

## 7a. Issue Ledger

No issue was changed for this data-only preparation step.

## 8. Consistency Audit

The generated files remain outside the primary recovery namespace and the spec retains the N=400 base cell and its prior attempts. The diagnostic is descriptive and cannot establish recovery, coverage, calibration, or identification. No public API, package docs, NEWS, or model contract changed.

## 9. What Did Not Go Smoothly

The originally named reader-fixed-snapshot path was absent. The spec uses the retained v6 bundle whose manifest hash matches the recorded v6 admission receipt. The first archive contained macOS `._` metadata sidecars; it was rebuilt with those disabled and then independently verified against all 50 CSV hashes and row counts.

## 10. Known Residuals

Fits remain pending current-source admission for both implementations and the paired pre-run. The diagnostic has ten datasets and will not qualify the method even if all fits are usable.

## 11. Team Learning

Preserve exact generated data and their provenance before considering any fitted diagnostic. Tie each language's fit receipt to the same literal inputs and extract SD coefficients by name.

## 12. Cross-Product Coverage

This preparation does NOT cover R or Julia fit behavior, cross-language parity, model recovery, identification, coverage, or interval calibration. It covers only literal-data generation and integrity checks.

## Next Actions

After the Julia source handoff, admit both source snapshots, verify paired fitter receipts on these literal datasets, and re-estimate the fit time. Keep the larger screening campaign behind its separate approval gate.
