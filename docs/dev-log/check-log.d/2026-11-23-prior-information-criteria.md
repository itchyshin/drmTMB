# Prior-fit information-criterion and comparison checks

This isolated drmTMB candidate adds warning-labeled AIC, BIC, and AICc diagnostics for MAP fits, while retaining the refusal of likelihood-ratio tests. A MAP likelihood-ratio request now warns before refusing. The warning explains that the likelihood-ratio statistic has no usual chi-square reference and directs users to unpenalized refits.

## Focused validation

Source base: `c7f6e7a2f0e7ec51aaa1e8077efc93c9452d200b`.

Tested source patch fingerprint: `ed9f6fa29e9972a92114469388baba264491f87e0c6e3547008ec55c87a5e511`.

Command:

```sh
Rscript --vanilla -e 'devtools::test(filter="lrt-boundary|sd-prior-public-inference|model-comparison|prior-table", stop_on_failure=TRUE)'
```

Result: exit 0 in 25.8 seconds; 965 assertions passed, with zero failures and zero unexpected warnings. Seven tests skipped because the external Julia engines and live bridge switches were not enabled. In particular, this run does not validate a live R-to-Julia bridge.

`devtools::document()` completed with exit 0 and wrote the updated `lrt-boundary.Rd`, `model-comparison.Rd`, and `model-fit-extractors.Rd` pages. `git diff --check` passed.

The run also checked AICc's warning and returned value, prior to observation-count and REML checks for direct MAP likelihood-ratio requests, and the MAP anova refusal when both fits have equal parameter counts. Two earlier attempts were retained in the evidence folder: one exposed an outdated error-message expectation, and one exposed a warning expectation that needed to follow the new MAP guard ordering. The corrected run passed.

Full package validation is still pending on the exact final candidate. A separate drmTMB full-suite run is active on the earlier prior/convergence candidate and does not include this information-criterion patch.
