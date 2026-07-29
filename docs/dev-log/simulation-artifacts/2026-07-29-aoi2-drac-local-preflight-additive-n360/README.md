# AOI-2 local preflight — additive, n = 360

## Authority and provenance

This is the first local, source-loaded shard after owner authorization of the
AOI-2 DRAC point-recovery campaign.  It ran on 2026-07-29 from merged
`origin/main` source SHA `aa599095fa03ca575b8833e268fa108f01b0abf7`.

Command:

```sh
Rscript --vanilla tools/run-aoi2-bernoulli-nb2-recovery.R \
  --out-dir=docs/dev-log/simulation-artifacts/2026-07-29-aoi2-drac-local-preflight-additive-n360 \
  --formula-id=additive --n=360 --replicate-start=1 --replicate-end=1
```

## Result

The one retained attempt was `interior`; the Bernoulli and ordinary-NB2 margin
fits both had `pdHess = TRUE`; its alpha estimates, fixed-newdata link targets,
elapsed time, session information, and source SHA are retained beside this
receipt.  It is an execution-path preflight only, not point-recovery evidence.

## Follow-up correction

Attempting to analyse this intentionally incomplete one-cell preflight exposed
a schema-union defect in the AOI-2 analyser.  The analyser was repaired before
any DRAC submission.  The next local shard must rerun from that committed,
pinned campaign source; this receipt remains as provenance for the detected
pre-submission defect.
