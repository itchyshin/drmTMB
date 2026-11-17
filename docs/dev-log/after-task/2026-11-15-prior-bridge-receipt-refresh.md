# Prior integration bridge receipt refresh

The merged prior work changed files on the labelled-phylogeny receipt's R call path. A fresh live R–Julia run replaces the stale current receipt, and the preceding receipt remains alongside it.

The run used R source `5d53eae0ba3ede53b3f43a78f690694e7f1133f0` and Julia source `21d07c5afc920d43de3eda2466efc2ad94c4a1c4`. All eight fixture checks passed, the receipt checker rejected 12 mutations, and an independent reviewer matched every recorded source file to those commits. The regenerated fixture and fitted values agree with the preceding receipt to numerical rounding. The staleness guard passes with both source trees supplied, as do its C14 and C17 checks.

An initial JuliaCall smoke crashed without Julia's bundled libunwind preload. A later wrapper failed only because equal dependency hashes had different path prefixes. The smoke failure log is retained. The wrapper exit was observed in execution output but was not retained as a separate log. This receipt covers one labelled Gaussian fixture; it does not establish general parity, interval calibration or release readiness.
