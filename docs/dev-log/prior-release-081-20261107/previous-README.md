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
