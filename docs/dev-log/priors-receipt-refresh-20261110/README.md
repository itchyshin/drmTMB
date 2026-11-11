# Bridge-label receipt refresh, 2026-11-10

The current phylogenetic label receipt was regenerated on drmTMB source `8f649bc81a15c1ff5d413bec1d38791805c99e45` and DRModels.jl source `83c4ea84a48acf51fe05d0feb4e84a618f79604e`. The latter has source tree `0b31ba3c5a7fb54bb3b7056dc4fa7cc2bf707a90`. The run exercised the existing shuffled-row Gaussian phylogenetic example with 12 labels and 72 observations. It used tree-ordered direct Julia input, one Julia thread and one BLAS thread. All eight checks passed in 53.567 seconds.

The new `current.json` has SHA-256 `ca2fa8486ea9f4c4baae69b5ac9f5b6f4f5f05e86b7605388c1f3ae28a1e0d53`. The predecessor has SHA-256 `fad9cb5abb5db9f25a5e601386a1fdbd718323bfbbd3afde2508ffb717a22800` and remains available in Git history. The checker passed `--current --self-test` on the fresh source checkouts and rejected all 12 mutations. The staleness check matched the recorded R and Julia source files and passed the C17 current-source compatibility check.

Compared with the predecessor, labels, tree structure and row ordering agree. The maximum absolute difference in regenerated numeric fixture values was `4.440892098500626e-16`; the maximum fitted-component difference was `7.105427357601002e-14` for the native log likelihood. This is evidence for the one recorded example.

The JSON records Julia files under the neutral temporary source checkout used for the run. The checker's `--current` mode needs those recorded paths to remain available. The CI staleness check can map the Julia file suffixes using an explicitly supplied `DRM_JL_PATH`. The older run logs and source manifests in the receipt bundle describe their earlier generation, not this refresh.
