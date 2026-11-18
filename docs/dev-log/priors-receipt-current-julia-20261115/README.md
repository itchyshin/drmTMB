# Current Julia main bridge receipt

The labelled-tree no-prior fixture was rerun against R `def81464aec6dfbf7fbba3b00abd06d9616ac24e` and Julia `5b005e0ffbc017e427f3c050f7ef45b38ff990ce` in separate clean checkouts on Totoro. The R commit differs from release candidate `e65cd0ac64edc425383cc6e8009267e98a0cd216` only in the receipt runner's explicit request for marginal Julia fitted values. Julia's default fitted values are conditional; the R bridge reports marginal values.

All eight checks passed and the checker rejected 12 mutated receipts. Independent review matched all 68 R and 127 Julia source hashes to the recorded commits. Maximum dense-oracle likelihood error was 1.43e-14; native/direct parameter differences were at most 7.74e-12 against a 4e-6 tolerance. Before and after source statuses were clean and the recorded Julia environment and loaded R DLL hashes matched. The Julia Manifest was copied from the earlier tested environment and was not tracked; these hashes do not attest every dependency or binary.

The R DLL was built from the `e65cd0ac` release tarball, installed in a separate Totoro library and copied to the source checkout. The sole subsequent R commit modified the runner, not compiled source. The run used R 4.6.1 and Julia 1.12.6, one thread, and Julia's bundled libunwind as a launch-only preload. From the R checkout the commands were:

```sh
Rscript --no-init-file tools/run-julia-phylo-labels-public.R /home/snakagaw/codex-release-receipt-e65-j5b-20261115/julia /home/snakagaw/codex-release-receipt-e65-j5b-20261115/receipt.json tree
Rscript --no-init-file tools/check-julia-phylo-labels-receipt.R /home/snakagaw/codex-release-receipt-e65-j5b-20261115/receipt.json --current --self-test
```

The receipt SHA-256 is `737a8094f25a4b328dfc945ea9a786823d17ca89e8462888f6691e7373e6bd98`. The fixture has no prior and is not broad bridge parity, a fitted-prior validation or interval calibration.
