# Refresh the current phylogenetic-label receipt

## Goal

Restore the source provenance of the current phylogenetic-label receipt after
documentation edits changed the bytes of `R/drmTMB.R`. Main workflow run
35530253643 reported one stale R source hash while the receipt's structural
checks and C17 compatibility checks passed.

## Implemented

Regenerated the receipt and raw log from integrated drmTMB source
`592aecaae8aac4f7f934693cdb389000bddcb576`, using the existing clean DRModels
checkout at `90fbb0e28306fa09a68dc2b03d74c981a74fe908`. No hashes were edited
by hand. The runner, checker, source code, workflows, and Julia pin are unchanged.

## Files Changed

The generated `docs/dev-log/evidence/julia-r-parity/lss-tip-identity/public-001.json`
and `public-001.log`, this report, and its dated `docs/dev-log/check-log.d/` row.

## Checks Run

The isolated checkout required a native DLL. After explicit authorization,
`Rscript --no-init-file -e 'pkgload::load_all(quiet=TRUE,recompile=TRUE)'`
built it from this checkout, with `MAKEFLAGS=-j4`, `OPENBLAS_NUM_THREADS=1`,
and `OMP_NUM_THREADS=1`. No existing binary was borrowed.

With Julia 1.13.0, `JULIA_NUM_THREADS=1`, and the same BLAS limit:

```sh
Rscript --no-init-file tools/run-julia-phylo-labels-public.R \
  /Users/z3437171/local-scratch/lanes/drmodels-receipt-origin-main \
  /private/tmp/drmtmb-receipt-20260920.oxxKf3/public-001.json tree
Rscript --no-init-file tools/check-julia-phylo-labels-receipt.R \
  /private/tmp/drmtmb-receipt-20260920.oxxKf3/public-001.json --current --self-test
```

The runner passed in 42.016 seconds. Build, runner, and independent verification
together finished in 69.366 seconds under a 600-second process-group cap.
After copying the generated JSON and raw log into their tracked paths,
`DRM_JL_PATH=/Users/z3437171/local-scratch/lanes/drmodels-receipt-origin-main bash tools/ci-receipt-staleness.sh`
passed: 54/54 R files and 95/95 Julia files matched; the runner matched;
the structural receipt reported 12 labels, 72 rows, and 8 passing checks;
C14/C17 compatibility passed. `git diff --check` passed.

## Tests Of The Tests

The independent verifier rejected all 12 in-memory mutations: order contract,
labels, rows, coefficients, likelihood, source, resource limits, Newick,
covariance, fitted values, nonfinite values, and malformed shape.

## Consistency Audit

Reviewed the full generated diff. It updates the `R/drmTMB.R` hash in both
manifests, native DLL provenance, elapsed time, and numerical rounding from the
fresh fit. All eight acceptance checks pass. The Julia source pin and its
manifest are unchanged. No public capability, API, or modelling claim widens.

## What Did Not Go Smoothly

The fresh clone contained no native DLL. Execution paused at that prerequisite
and resumed only after authorization for one bounded native build. The build
and first receipt run succeeded; no retries were needed.

## Team Learning

A whole-file source receipt also becomes stale after roxygen comment edits.
Regenerate after the final integrated R source state; changing recorded hashes
alone would not establish that the fitted workflow was executed.

## Design-document Updates

None: evidence provenance maintenance only.

## pkgdown/documentation Updates

No reader pages or rendered site artifacts changed.

## GitHub Issue Maintenance

Inspected open receipt issues. This repair relates to #1150; it does not close
that broader issue. No issue was created or edited.

## Known Limitations and Next Actions

This proves one deterministic Gaussian phylogenetic location-scale workflow
through native TMB, the Julia bridge, and direct DRModels. It does not replace
full package or cross-platform checks. The repair needs PR review and merge;
the historical failed main run remains a historical failure, and a subsequent
main workflow must confirm the merged receipt. Any later R source edit requires
another freshness check.
