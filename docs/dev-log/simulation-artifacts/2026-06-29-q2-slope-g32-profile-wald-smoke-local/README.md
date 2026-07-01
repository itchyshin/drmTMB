# Q2 slope g=32 profile/Wald smoke

The spatial artifacts in this directory are the valid local g=32 smoke rows:

- `04-spatial-mu1_x-summary.tsv`
- `05-spatial-mu2_x-summary.tsv`
- `06-spatial-cor_mu1_mu2_x-summary.tsv`

The animal artifacts in this directory are retained only as invalidated audit
records. They were produced with `GSWEEP_N_GROUPS=32`, but the animal data
generator uses a fixed 8-animal pedigree. Before the 2026-06-29 runner guard,
the animal path recycled group labels against the longer `x` vector. The
dashboard therefore records no usable animal g=32 evidence from these files.

The clean animal correlation holdout smoke is tracked separately in:

- `docs/dev-log/dashboard/structured-re-q2-animal-correlation-holdout-diagnostic.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-q2-animal-correlation-holdout-diagnostic-local/`
