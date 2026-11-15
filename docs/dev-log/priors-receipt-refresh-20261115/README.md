# Prior integration bridge receipt refresh

The post-merge staleness check found that the phylogenetic-label receipt no longer matched the R call path. This run refreshes that one Gaussian location-scale-scale fixture using R source `5d53eae0ba3ede53b3f43a78f690694e7f1133f0` and Julia source `21d07c5afc920d43de3eda2466efc2ad94c4a1c4`. Both were clean shallow checkouts on Totoro. The Julia Manifest was copied from the earlier tested environment; the Project and Manifest hash values matched before and after the run.

The runner passed its eight checks and the checker rejected 12 mutations. An independent reviewer matched all 68 R and 125 Julia source hashes in the receipt to those source commits. Labels, tree and ordering match the preceding fixture. Numeric fixture values differ by at most 4.45e-16 and fitted log likelihoods by at most 7.11e-14. The results do not establish broad bridge parity or interval calibration.

The first JuliaCall smoke crashed without a preload, including in a minimal JuliaCall-only reproduction. A separate smoke and the live receipt run passed with Julia's bundled `libunwind` preloaded. The wrapper exit and its path-prefix diff were observed in the execution output but not retained as a separate log. The recorded before and after hash values match. The failed smoke and successful retry logs are retained here. The current receipt and its predecessor are in `docs/dev-log/priors-lane-20261105/release-default-bridge-recheck/`.

The successful runner used R 4.6.1, Julia 1.12.6, `R_LIBS_USER=/home/snakagaw/R/lib`, `NOT_CRAN=true`, and one BLAS, OpenMP and Julia thread. `JULIA_HOME` pointed at the Julia 1.12.6 binary directory; `LD_PRELOAD` pointed at that installation's `lib/julia/libunwind.so`. From the R checkout, the commands were:

```sh
Rscript --no-init-file tools/run-julia-phylo-labels-public.R /home/snakagaw/codex-receipt-r5d-j21-20261115/julia /home/snakagaw/codex-receipt-r5d-j21-20261115/new-receipt.json tree
Rscript --no-init-file tools/check-julia-phylo-labels-receipt.R /home/snakagaw/codex-receipt-r5d-j21-20261115/new-receipt.json --current --self-test
```
