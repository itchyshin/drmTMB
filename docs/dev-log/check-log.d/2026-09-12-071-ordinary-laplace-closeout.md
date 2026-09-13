# 0.7.1 ordinary-Laplace parity closeout

The full local test suite completed with exit 0.  The source-pinned matrix test
was then run with `DRM_JL_PATH=/private/tmp/drmjl-071-pinned-b2`; it passed,
with only the existing zero-one-beta ledger skip.  The canonical
`tools/write-parity-matrix.R` was rerun after the capability-row insertion so
that its cited TSV line numbers are byte-identical to the committed matrix.

The retained evidence boundary is unchanged: drmTMB
`453cff782900aa55211d3f5971c229fc485d291e`, DRM.jl
`b2caf00f23f080fe89028966a4bfb098ef095510`, four frozen fixtures, 500 paired
seeds each, and all outcome strata retained in the unconditional denominator.
No campaign task was submitted or rerun.
