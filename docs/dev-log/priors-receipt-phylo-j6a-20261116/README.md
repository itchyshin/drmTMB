# Phylogenetic feature bridge receipt for Julia 6a1c

The runner used R feature source `8e341fc97e092a5e554abe49d4b1ddd005f14f85` and Julia feature source `6a1c5367bbb27441d4ddfef7a50e16db541a11c4` on Totoro with one thread. The no-prior Gaussian phylogenetic fixture had 12 labels and 72 observations. All eight checks passed and the checker rejected 12 deliberately mutated receipts. A local comparison matched 68 R source hashes, 127 Julia source hashes and the runner to the feature sources. Both tracked source trees were clean before and after, and the Julia environment hashes were unchanged.

The receipt records the native binary hash; an independent rebuild of that binary has not been performed. This one no-prior fixture does not establish prior support, other families, interval calibration or release readiness. A separate live prior test on these source commits passed; full release and feature checks remain pending.
