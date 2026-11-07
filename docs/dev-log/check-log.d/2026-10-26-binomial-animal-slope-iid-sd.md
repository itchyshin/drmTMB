# Check log: native Binomial animal slope plus IID intercept SDs

The focused native test file passed after extending the R builder's admission predicate. It checks the q1 animal slope loading in the structured TMB payload, separate animal and site SD designs, recovery of both log-SD slopes, output lengths, and save/reload. This is native TMB point/workflow evidence only; Julia parity and interval coverage remain untested.

Command:

```sh
NOT_CRAN=true Rscript -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-binomial-animal-iid-sd-regression.R", reporter = "summary")'
```

The final run ended with `══ DONE ══` and no failed expectations. Two earlier runs failed only because assembly assertions looked for the structured design at the wrong wrapper level. No Julia tests ran in this native-only check.

Final output:

```text
ℹ Loading drmTMB
binomial-animal-iid-sd-regression: .................................................................

══ DONE ════════════════════════════════════════════════════════════════════════
Julia bridge: 0 live tests ran, 0 skipped; the LIVE ENGINE was not exercised in this configuration.
```
