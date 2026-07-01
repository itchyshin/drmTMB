# Q2 Animal Correlation Miss Diagnostic

This directory stores the retained-denominator miss taxonomy for the fixed-8
animal q2 correlation SR150 pregrid.

Source replicate TSV:

```text
docs/dev-log/simulation-artifacts/2026-06-29-q2-animal-correlation-pregrid-local/11-animal-cor_mu1_mu2_x-replicates.tsv
```

Generated artifact:

```text
animal-cor-miss-rows.tsv
```

The diagnostic filters rows where the Wald interval missed, the endpoint
profile interval missed, or the replicate had a retained boundary/convergence
flag. It records 19 miss-or-boundary rows: 13 shared upper-tail misses, 4 shared
lower-tail misses, 1 Wald-only upper miss, and the retained boundary seed
733197.

This is blocker evidence only. It does not promote the linked Q-Series row,
interval status, coverage status, `inference_ready`, `supported`, q4/q8, REML,
AI-REML, broad bridge support, or public support.
