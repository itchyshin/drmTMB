# 0.7.1 S7 source-subset reconciliation repair

Purpose: replace the invalid live-tree comparison with a source-pinned,
fail-closed proof for the retained Nibi campaign archives.

Passed locally:

```sh
bash docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/test-source-commit-proof.sh
bash -n docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/verify-source-commit.sh \
  docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-fir-reconcile.sh
Rscript -e 'devtools::test(filter = "071-four-fixture-summary", reporter = "summary")'
git diff --check
```

The source-proof fixture includes positive exact/full and subset cases,
wrapped and wrapper-free archive forms, altered-file rejection,
missing-required-root rejection, and a foreign-bundle rejection.  The focused
R test passed with two expected `DRM_JL_PATH`-unset scoreboard skips.

Read-only retained evidence checked on Nibi:

- `receipts/s7-source-commit-proof-21753825.tsv` records subset-proof PASS for
  drmTMB `453cff782900aa55211d3f5971c229fc485d291e` and DRM.jl
  `b2caf00f23f080fe89028966a4bfb098ef095510`.
- The retained drmTMB archive contains all declared required roots:
  `DESCRIPTION`, `NAMESPACE`, `R`, `src`, `inst`, and the 0.7.1 evidence root.

No campaign task was submitted or rerun.
