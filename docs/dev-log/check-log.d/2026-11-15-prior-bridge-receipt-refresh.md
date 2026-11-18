# Prior integration bridge receipt refresh

The post-merge receipt-staleness run failed because seven R files on the receipt runner's call path had changed and `R/prior-table.R` was new. The previous receipt is preserved as `pre-prior-table-20261115.json`.

A live run on Totoro used clean R source `5d53eae0ba3ede53b3f43a78f690694e7f1133f0` and Julia source `21d07c5afc920d43de3eda2466efc2ad94c4a1c4`. It passed all eight fixture checks; the checker rejected all 12 mutation controls. An independent reviewer matched 68 R and 125 Julia source hashes to those commits. Labels, tree and order matched the previous receipt exactly; numeric fixture values differed by at most 4.45e-16 and fitted log likelihoods by at most 7.11e-14. This is one labelled Gaussian fixture, not general bridge validation.

The initial JuliaCall smoke crashed without a preload; Julia's bundled libunwind allowed the smoke and receipt run to pass. A wrapper compared identical dependency hashes with different path prefixes and exited 1; comparing the hash values confirmed they matched. The smoke failure log is retained; the wrapper exit and path-prefix difference were observed in execution output but not retained as a separate log.

`DRM_JL_PATH=... bash tools/ci-receipt-staleness.sh` then passed with 68 R and 125 Julia files matched, along with the C14 and C17 checks. The release branch changes only documentation and metadata relative to the R source used for the receipt. Full release-candidate CI remains open.
