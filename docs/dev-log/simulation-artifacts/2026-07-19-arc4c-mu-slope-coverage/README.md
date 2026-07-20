# Arc 4c ordinary `mu` random-slope coverage

## Purpose and result

This campaign tests the standard drmTMB ML-Laplace profile interval for the
natural-scale SD of one independent `mu` slope, `sd:mu:(0 + x | id)`, at true
SD 0.50. It adds no family, formula grammar, estimator, or public function.

The frozen gate promotes all three cells to `inference_ready_with_caveats` at
M >= 16. M=16 is a boundary-overlap result for every family, so none earns a
`supported` or generally nominal claim.

| Cell | Family | M=16 coverage (exact 95% CI) | M=32 | M=64 | Verdict |
|---|---|---|---|---|---|
| `mc-0464` | skew-normal | 0.9275 (0.9113-0.9415) | 0.9317 (0.9159-0.9453) | 0.9575 (0.9445-0.9682) | promote; floor 16 |
| `mc-0539` | Tweedie | 0.9267 (0.9104-0.9408) | 0.9425 (0.9278-0.9550) | 0.9475 (0.9333-0.9594) | promote; floor 16 |
| `mc-0575` | zero-one beta | 0.9292 (0.9132-0.9430) | 0.9400 (0.9250-0.9528) | 0.9517 (0.9380-0.9631) | promote; floor 16 |

Each non-exploratory cell retained 1,200 attempted replicates and 1,200 finite
profiles. Coverage uses `hits / 1200`; unavailable intervals cannot improve the
primary score. See `aggregate/arc4c-summary.tsv` and
`aggregate/arc4c-family-verdict.tsv` for the unrounded results.

## Frozen design and compute authorization

The design and decision rule were frozen before compute in
`docs/dev-log/2026-07-19-arc4c-three-cell-mu-slope-drac-s0.md`. Shinichi gave
explicit compute approval in the Codex task on 2026-07-19 after PR A was merged.
The campaign ran on Fir, never GitHub Actions, under account
`def-snakagaw_cpu`, normal QOS, one CPU per task, and a global array ceiling of
96. All BLAS, FlexiBLAS, BLIS, MKL, OpenMP, and TMB thread counts were pinned to
one.

The authenticated source was clean commit
`46affaeea8eca55d31bb8411812a5621e1379f53` in:

```text
/project/def-snakagaw/snakagaw/drmTMB-arc4c/46affaeea8eca55d31bb8411812a5621e1379f53
```

The compute-node preflight recorded R 4.4.0, GCC 12.3.1, TMB 1.9.21, source
tree SHA-256 `743916720ef6be5eb4993a84b6c555c336b2023bee56a5671339cc64f5980f83`,
and compiled DLL SHA-256
`4ad38053318b110c7e5887e140d6d27394291a683b5c6ec908676116a08a05e6`.
The full receipt, module list, and `sessionInfo()` are under `preflight/`.

| Stage | Slurm job | Result |
|---|---:|---|
| fresh-clone preflight/build | 49628010 | completed, exit 0 |
| 12-cell N=1 smoke | 49628496 | completed, exit 0 |
| smoke aggregation/selection | 49629086 | completed, exit 0 |
| 1,320-task certification array (`%96`) | 49629827 | 1,320/1,320 completed, exit 0 |
| independent full aggregation | 49640984 | completed, exit 0 |

`slurm-jobs.tsv` retains the top-level accounting receipt. Full shard logs and
all 1,320 atomic shard/checksum pairs remain at the durable `/project` run root;
they were not uploaded as GitHub Actions artifacts.

An earlier smoke at the pre-repair PR-A SHA failed before any fit because its
worker exported the isolated R library too late. That infrastructure-only run
is retained at its separate `/project` root and documented in
`docs/dev-log/after-task/2026-07-19-arc4c-fir-rlib-repair.md`. No row from it
enters this campaign.

## Smoke selection and row accounting

All non-exploratory smokes passed. Skew-normal and zero-one beta also passed
M=8. The Tweedie M=8 smoke produced a finite profile whose lower endpoint was
exactly zero, so the frozen mechanical rule excluded only Tweedie M=8. The full
manifest therefore contains eleven family-by-M cells and 1,320 ten-replicate
shards.

Independent accounting of `aggregate/arc4c-raw.tsv` found:

- 13,200 rows and eleven cells with exactly 1,200 rows each;
- no duplicate replicate IDs, missing IDs, bad seed mappings, or bad shard
  mappings;
- 13,197 eligible fits and three bad-Hessian fits, all three at exploratory
  skew-normal M=8;
- one nonfinite profile, also at exploratory skew-normal M=8;
- matching MD5/SHA-256 sidecars for every copied aggregate, selection,
  manifest, preflight, and replay receipt.

The independent aggregator used `afterok:49629827` and rebuilt the summaries
only after validating the manifest, shard set, schemas, mappings, and checksums.

## Diagnostics and family-specific caveats

The immutable campaign has a reporting defect: `sd_hat`, its Wald bounds, and
Wald coverage are `NA` in all rows. The original extractor required exactly one
row named `log_sd_mu` in `summary(fit$sdr)`, while a live fit reports two
identical rows with that name. This did not change a fit, profile endpoint,
profile status, hit, denominator, exact interval, calibration label, or family
verdict. The profile gate is therefore usable, but this campaign makes no point
bias or Wald-coverage claim and the missing values are not backfilled.

The prospective repair reads the unique fixed `log_sd_mu` parameter and its
variance from `fit$sdr$par.fixed` and `fit$sdr$cov.fixed`. A regression test
covers duplicate report-row names. Replay-only SD estimates remain separate
from the immutable campaign table.

Family caveats are also part of the claim:

- Skew-normal M=8 undercovered at 0.9017 (exact CI 0.8834-0.9179). The
  near-zero fitted-slant rate was 18.4%, 15.6%, and 8.25% at M=16, 32, and 64,
  so slant identification remains a material caveat.
- Tweedie M=8 was excluded by smoke. At M=16, 156 finite profiles touched the
  natural zero lower boundary; this fell to six at M=32 and zero at M=64. No
  all-zero cluster occurred.
- Zero-one beta allocated exactly 15% of rows to balanced labelled structural
  zeros and ones. Its interior `rbeta()` draws nevertheless produced 50, 87,
  and 193 machine-exact ones across all M=16, 32, and 64 replicates. The fit
  consequently saw a slightly larger, predictor-dependent boundary mass. The
  evidence describes this executed generator; it does not establish an exactly
  15% observed-boundary design.

## Replay and D-43 review

Replicate 1 was replayed locally for every promoted family-by-M cell at M=16,
32, and 64. All nine profile statuses matched. The largest absolute endpoint
difference was `1.56e-10`, well inside the predeclared `1e-4` tolerance; see
`replay-verification.tsv`. Reference `sd_hat` comparison was impossible because
of the immutable diagnostic defect above and is marked unavailable rather than
inferred.

Fresh memo-blind D-43 reviews returned:

- Fisher: PROMOTE all three, floor M=16;
- Rose: PROMOTE all three, floor M=16;
- Noether: PROMOTE skew-normal and Tweedie, floor M=16; WITHHOLD zero-one beta
  pending a strictly-interior sampler and rerun.

The frozen D-43 rule requires at least two WITHHOLD verdicts to block a
promotion. Zero-one beta therefore promotes by the predeclared rule, with
Noether's generator objection preserved as a caveat and next gate rather than
silently erased.

## Claim boundary and next gates

The promotion covers only ML-Laplace profile intervals for the natural-scale SD
of one ordinary independent `mu` slope `(0 + x | id)`, true SD 0.50, the frozen
family-specific formulas and constants, the fixed seed sequence, and M >= 16.
It excludes other SD values, observation counts, group grids, fixtures,
families, random intercepts, correlated or labelled slopes, scale-side random
effects, structured effects, REML, AGHQ/O3, and `supported` claims.

The next calibration gate is a broader predeclared design grid. For zero-one
beta, first replace machine-exact endpoint leakage with a deterministic strictly
interior sampler and rerun that cell under new compute approval. For
skew-normal, vary slant and information. For Tweedie, vary dispersion, power,
and zero mass. None of those future gates changes this campaign retrospectively.
