# Scalar A1 ML-versus-REML Totoro campaign receipt

## Execution

Shinichi approved this campaign in writing on 2026-07-26.  Totoro ran the
three-cell scalar Gaussian iid random-intercept study at 1,000 paired outer
attempts per cell.  The raw shards remain at
`~/drm_work/a1_ml_reml_20260726/results_a1_ml_reml_full_20260726/` on Totoro;
they were neither sent to GitHub Actions nor stored as GitHub artifacts.

The initial launcher exited before producing any result because Totoro's normal
R startup loaded an older drmTMB installation.  The corrected launcher uses
`R_LIBS` and `Rscript --vanilla`, and the clean three-cell smoke then loaded the
pinned tarball and retained all six rows.  The successful campaign began at
`2026-07-26T20:19:42Z` and completed at `2026-07-26T20:19:59Z`.

## Integrity

| Check | Result |
| --- | --- |
| Raw shard pattern | 300 shards: 3 cells x 100 ten-attempt shards |
| Attempt accounting | 1,000 retained ML rows and 1,000 retained REML rows per cell |
| Error-log scan | 0 matching `Error`, `Execution halted`, or `fatal` logs |
| Lock/cap mechanism | one atomic launcher lock and `xargs -P 100`; BLAS/OpenMP/MKL threads set to 1 |
| Direct peak observation | not available: the campaign completed before the first post-launch poll |
| After-completion state | lock absent; one unrelated R process remained |

The configured ceiling is mechanically enforced by the launcher.  This receipt
does not claim an independently sampled peak-worker count.

## Pinned provenance

| Item | SHA-256 |
| --- | --- |
| package tarball | `9fc6ad979ce0fcdffe83134e27352bb3af8efb4470c63ec4a5f303ffe731237c` |
| campaign manifest | `8cb47d70d9808a5389222885c0bb0f176feee60f7e9389d7989306d678d67887` |
| paired-decision analyser | `4b5a943627a10cd719fdef9f7b79155d47a93798f78d13daab7eaf46e4bacce5` |
| raw 300-shard checksum manifest | `e1713822b7430003cd8cb6281aade15a71af08140e27c3444b0b5f6a27371fdf` |
| summary CSV | `a3fb5a75480a24f68ad1d6ce19c8c8684fedd309e83aebf8aea8141a2874030d` |
| paired-decision CSV | `6cdb4cfbcb21bc32d96e9e9fa8c84fbd339749c8f7b9583fde80eda8eb035c92` |
| paired-decision sidecar | `087affab0f73c7e25c00cfb07c5345a3a80026d1f3807fab5695100d5702a6aa` |

The sidecar records the exact analysis invocation and parent-manifest hash.

## Boundary

This is scalar Gaussian iid random-intercept evidence only.  It does not alter
the public interval hierarchy, defaults, Arc D clamp semantics, association
work, bootstrap construction, or any structured/non-Gaussian claim.
