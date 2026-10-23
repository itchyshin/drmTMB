# Missing-predictor uncertainty coordinates

Native public coefficients contain natural predictor scales and mixture
probabilities. Their covariance now maps the exact fitted raw slots and applies
the derivative on both axes, including cross-covariance with ordinary regression
coefficients. Profile targets retain raw log/logit estimates. Wald intervals are
constructed there and transformed once; summary SEs remain on the public scale.
Gaussian predictor-SD intervals in the R Julia adapter use the same log-Wald
construction while retaining delta-method public covariance. Interval metadata
conventions are not yet identical across engines.

`native-mi-transform-receipt-001.json` stamps unchanged R source and tests,
the loaded native DLL, and a 9.432-second bounded run including package startup.
It passes 194 transformed-covariance assertions, 101 existing regression covariance
assertions, 47 bridge adapter assertions and seven ordinary profile/Wald/bootstrap
neighbour tests (100 assertions). This is not a warm benchmark or coverage study.
RED logs retain 41 initial failures, five boundary/bootstrap-review failures and
three bridge interval failures. The earliest RED's summary-row lookup mistake
was corrected before final tests.

Grouped/structured predictor SDs keep boundary warnings; residual predictor scale
is regular. Rounded logistic tails and raw-versus-natural ADREPORT selection are
tested. The synthetic REML-source plumbing sentinel does not admit joint REML.

Review also found native bootstrap refits omit the imputation/missingness contract
and simulate only the response. Joint missing-predictor bootstrap now fails
explicitly before compute. Implementing and validating joint simulation/refitting
remains REQUIRED; this safety guard does not complete bootstrap parity. The Julia
joint bridge still refuses profile and bootstrap. Other Julia-engine inference
workflows, including Ayumi-san's reported case, require separate reproduction.
Her tree report is tracked in the Julia repository's `polytomy/` evidence.

Rose approved the bounded covariance/interval implementation after the boundary
and bootstrap-refusal repairs. No estimator, likelihood, optimizer, frozen
comparator, parity tolerance or foreign bridge change was altered.

## Live Julia adapter refresh

`joint-public-006.json` records real Gaussian/Bernoulli predictor workflows after
the log-Wald repair: both adapter checks pass, both strict native4e-6 comparisons
fail. `finite-public-006.json` also passes both ordinal/categorical adapters while
retaining both native failures. Source-before equals source-after in both receipts.
Independent Julia-side receipt checks reject21joint and17finite corruptions normally
and underPython-O. R fit objects are kept only here, not in the MIT Julia repo.
Elapsed25.403/21.053seconds includes startup and is not warm benchmark evidence.
