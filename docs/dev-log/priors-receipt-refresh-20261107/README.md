# Phylogenetic bridge receipt refresh

The main-branch receipt check failed because `R/methods.R` changed after the previous fixture run. This refresh reran the existing 12-label, 72-row Gaussian phylogenetic fixture on Totoro with R source `623eed27b37d53dab4af56564f1e87624929d40e` and Julia source `f940fc4042ee2832c3343f7d334e830a96942f1b`. The prior receipt remains in Git history.

The runner reported eight passing checks and unchanged source hashes. Its fixture matched the historical labels, order, data, tree and group covariate. The receipt self-test passed on Totoro with the pinned Julia source. The local CI-equivalent staleness check passed for 66 R files and the runner; it explicitly did not verify 115 Julia entries because the pinned Julia checkout is on Totoro. A direct local checker invocation failed because that remote checkout path is not available locally. The successful Totoro checker and the local CI result are distinct evidence.

This is evidence for one fixture, not broad R–Julia parity or calibrated intervals. `current-candidate.json` is byte-identical to the refreshed current receipt. The original transfer bundle failed before running a fit; a full bundle supplied the exact R commit for the successful reproduction.
