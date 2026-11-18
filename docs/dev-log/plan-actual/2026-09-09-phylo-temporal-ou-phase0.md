# Plan versus actual: phylogenetic-temporal OU Phase 0

## Planned

Materialize and self-test the P1 and source-map gate runners; create a bounded
NotebookLM source map; record source/R/TMB/native provenance; leave model code
and campaign computation untouched.

## Actual

Both runners were materialized and passed direct and testthat checks. The cited
source map records three processed public sources and one processed primary
phylogenetic reference. The primary covariance-parameterisation lead could not
be verified through NotebookLM because the accessible publisher record was
paywalled. The receipt therefore labels it unverified. The worktree has no
built native library, so the fingerprint records that absence and hashes
`src/drmTMB.cpp` instead.

## Difference and decision

The original runner design was strengthened after its negative controls exposed
heading-only validation and caller-working-directory dependence. This is a
bootstrap improvement, not a scope expansion. No P1 model file was edited and
no compute authority was exercised.
