# Current phylogenetic label receipt

This receipt refreshes the current-source evidence for one Gaussian phylogenetic
location-scale-scale model. The 12 labels, 72 observations, tree-ordered direct
Julia input, formulas, and checks match the historical fixture. The new receipt
supersedes the current-source interpretation of
`docs/dev-log/evidence/julia-r-parity/lss-tip-identity/public-001.json`; that
historical file remains unchanged.

The runner used default maximum likelihood and requested no fixed-effect prior.
It compared native R, the R-to-Julia bridge, and direct Julia against an
independent likelihood calculation. All eight checks passed at the existing
thresholds; the receipt checker rejected 12 mutated receipts. The fixture
comparison and source manifests are in this directory. This is one fixture,
not a new admission, a calibration result, or a broad parity claim.

The run used R source `b86709e16b477c4d232eaec16e9567ec12e136fa` and Julia
source `f940fc4042ee2832c3343f7d334e830a96942f1b`. The generating host used
Julia's bundled libunwind as a launch-only preload. The CI-equivalent audit
checks the R hashes and runner when `DRM_JL_PATH` is unset; in that mode it
reports Julia source entries as unverified. A separate local audit with a Julia
checkout matched all 115 Julia source entries.

The November 7 refresh replaced `current.json`. The previous receipt and this
original README are preserved as `current-before-20261107.json` and
`README-before-20261107.md`. See `docs/dev-log/priors-receipt-refresh-20261107/`
for the new source pins and checks.

## 0.8.1 candidate refresh

On Totoro, the unchanged fixture passed all eight checks using R source `4d3917385` and Julia source `b20ccf2df`. The independent checker rejected all twelve mutated receipts. Labels, data, ordering, tree and group covariate matched the previous receipt. The first attempt stopped because the Julia manifest was absent; the failed receipt and log are retained alongside the successful retry. This remains evidence for one fixture.

After current main incorporated #1658, the same fixture was rerun on R source `a0043e420` and Julia source `0460f25ff`. All eight checks and twelve negative controls passed; the six stored fixture components matched the preceding candidate. Raw evidence is in `docs/dev-log/prior-release-081-20261107/`. This remains one fixture.

## Post-#1651 refresh

The same fixture was rerun on R source `51f94e61a3b1f652fcedfc891d6da7e7281c7799` after #1651 changed a documentation source pin in `R/drmTMB.R`. It used Julia source `0460f25ffd23c7b60c0fc09e9e6820a2881714c9`; all eight checks passed, and the checker rejected all twelve negative controls. Labels, data, order, tree and group covariate matched the prior fixture. The previous receipt and the runner/checker logs are preserved in `docs/dev-log/post1651-receipt-refresh/`. This remains evidence for one fixture, not broad parity.

## 2026-11-10 paired-source refresh

`current.json` now records the paired-source run described in
`docs/dev-log/priors-receipt-refresh-20261110/README.md`. The other 23 entries
listed in `SHA256SUMS` retain the earlier bundle's evidence; their logs and
source manifests describe that earlier run.

## Later 2026-11-10 Julia main refresh

The preceding paired-source section describes the earlier `83c4ea84` Julia
run. The current receipt now records the later `ed90ae2e` run described in
`docs/dev-log/priors-receipt-refresh-20261110/ed90.md`. The other bundle logs
and source manifests retain their historical provenance.
