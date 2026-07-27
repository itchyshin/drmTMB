# After Task: B1 DRAC breadth validation

## Goal

Run a broad, execution-only validation census for 16 scalar `sd()` or fixed
parameter routes, retaining every attempted fit across three information rungs.
This task explicitly excludes capability promotion, public/default claims,
Arc D, bootstrap methods, association, missing response, and Arc 4c cells.

## Implemented

`tools/b1-breadth-contract.R` freezes 16 cell IDs, three rungs, 200 replicates
per cell/rung, deterministic seeds, and 960 ten-replicate shards. Fixture
adapters, a one-task worker, Fir dispatch planner, strict aggregator, and
single-CPU Slurm template were added. The worker now converts multiline fit
errors to one TSV field before atomic publication.

## Mathematical Contract

This is not a coverage or recovery promotion study. For each immutable cell,
rung, and seed, B1 records a fit outcome, convergence, route-appropriate
`pdHess` diagnostic, scalar target estimate, optional profile readiness, and
elapsed time. A finite result or `pdHess` value is not interpreted as interval
calibration or an inference-tier claim.

## Files Changed

- `tools/b1-breadth-contract.R`
- `tools/b1-breadth-adapters.R`
- `tools/run-b1-breadth-validation.R`
- `tools/prepare-b1-drac-dispatch.R`
- `tools/summarize-b1-breadth-validation.R`
- `tools/slurm/b1-breadth-validation.sbatch`
- `tools/slurm/install-b1-ape.sbatch`
- `tests/testthat/test-b1-breadth-contract.R`
- `tests/testthat/test-b1-breadth-adapters.R`
- `tests/testthat/test-b1-breadth-dispatch.R`
- `docs/dev-log/2026-07-26-b1-drac-breadth-campaign-report.md`

## Checks Run

- Targeted contract, adapter, and dispatch tests: all passed locally.
- Local one-replicate worker smoke: all 16 selected cells completed.
- Fir source preflight: passed for source `061c2891cdc617113334d128425228f4b4145753`, clean tree, installed DLL hash, R 4.4.0, and TMB 1.9.21.
- Fir smoke: all 16 first attempts retained. Four phylogenetic adapters initially lacked the R-4.4-compatible `ape` dependency; `ape` 5.8.1 was installed only in B1's isolated R library, and a separate replay completed all 16 routes.
- Full benchmark: one ten-replicate low-rung shard per cell completed in 7--15 seconds and about 198--269 MB RSS.
- Full Fir array: 960 single-CPU tasks completed with exit code zero.
- Full replay structural audit: 960 shard files, each with 10 retained attempt rows and a valid terminal status.
- Full aggregation: 9,600 retained rows and 48 cell/rung summaries at `/project/def-snakagaw/snakagaw/drmTMB-b1-breadth-399cba13/full-replay/summary/`.
- Post-hoc canonical-evidence gate: passed. It binds canonical manifest SHA `08d92b25c03b58afbfe0281e9ab125c82f642cb812df430b7160bdeb5ac5b972`, all 9,600 raw rows/seeds, 960 task provenance files, archived/current receipts, and the sole permitted task-41 replay difference.

## Tests Of The Tests

The high-rung `mc-0005` seed `2026073008` generated a real response-boundary
fit error. Its initial multiline diagnostic created a 13-line file, and the
full-file audit rejected aggregation. The repaired worker writes that exact
error as a single TSV row; the replayed shard has 11 physical lines (header
plus ten attempts). This verifies the all-attempt serialization guard on a
real failure path.

## Consistency Audit

No user-facing model behaviour changed. Exact status-inventory scan:

```sh
rg -n "B1|b1-breadth|Arc D|missing-response|association" README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml
```

The matches concern pre-existing association/missing-response surfaces; none
was modified. No README, NEWS, roadmap, formula grammar, vignette, or pkgdown
claim was added or changed.

## GitHub Issue Maintenance

No issue was opened, closed, or commented on. This was a local/Fir execution
lane with no product or public-surface change.

## What Did Not Go Smoothly

The initial Fir environment lacked `pkgload`, then the default project library
lacked the package imports. A standard `R CMD INSTALL` preflight plus a
read-only dependency base resolved that. Four phylogenetic smoke routes then
revealed the missing R-4.4 `ape` dependency, which was installed in B1's own
library. The content-hash preflight sweep was too slow on project storage and
was replaced by a deterministic tracked-index checksum alongside the Git tree
SHA. Finally, the retained TSV audit exposed the multiline-error defect above.

## Team Learning

For a distributed R campaign, source preflight must verify the package install
environment, not only source checkout. Retained text fields need explicit
single-row serialization. A replay must use a distinct result root so initial
attempts remain auditable. Fir does not accept dependencies on already-finalized
array elements, so aggregation was submitted only after `sacct` had verified
all prerequisite elements succeeded and their retained rows were present.

Independent inference review confirmed that the retained rows have no truth,
bias, interval endpoint, coverage, comparator, or Monte Carlo uncertainty
quantity. It therefore supports only the bounded execution statement. The
systems review initially withheld closeout because source lineage, canonical-map
equality, receipt enforcement, and replay comparison were not explicit; the
post-hoc canonical-evidence gate and local incremental source bundle address
those provenance findings for this run.

## Known Limitations

B1 supplies execution diagnostics only. It does not assess parameter recovery,
profile shape, confidence-interval calibration, coverage, or a capability tier.
`pdHess` and profile readiness remain route-specific diagnostics; several
structured and `se = FALSE` routes intentionally have no such ready signal.
The single retained Beta boundary error is part of the result, not a removed
failure. The original array workers verified the source/manifest provenance
record but did not independently recheck the installed-DLL and R-library
receipt fields on every task; the final post-hoc gate binds those receipts to
the retained task records. A future runner should make that full receipt check
live at worker start.

## Next Actions

Keep all B1 evidence execution-only. Any future recovery or inference decision
requires a separately approved estimator and cell-specific analysis; this task
makes none. The remote reproducibility anchors are the Fir campaign directory,
the manifest/receipt hashes above, and the locally banked incremental source
bundle named in the campaign report.
