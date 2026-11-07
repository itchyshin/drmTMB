# 2026-10-27: Native Poisson correlated q2 predictor-dependent SD

The native Poisson adapter now permits separate predictor-dependent SD formulas for both coefficients in one ordinary, unlabelled correlated q2 intercept-slope block. The model keeps a constant intercept-slope correlation. A q3 request is refused. The broader support claim is limited to this specific complete-data, non-zero-inflated shape.

Checks:

- `Rscript -e 'devtools::test(filter = "poisson-correlated-q2-sd")'`: 13 passed, 0 failed, 0 warnings, 0 skipped.
- `Rscript -e 'devtools::test(filter = "poisson-(mean|ordinary-correlated-q2|correlated-q2-sd)")'`: 174 passed, 0 failed, 0 warnings, 0 skipped.
- The focused test has a fixed-seed 160-group by 32-observation recovery DGP, formula-keyed group SD assertions, independent 20 by 20 Gauss-Hermite likelihood comparison, constant-SD equivalence, and a q3 refusal check.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: `EVIDENCE_RECONCILIATION_PASS candidate_rows=19678 linked_rows=157 unlinked_rows=19521 evidence_records=177`. The frozen candidate rows remain unchanged.
- `pkgdown::check_pkgdown()`: no problems found. The two affected vignettes rendered to `/tmp`; Pandoc emitted its existing math-option deprecation warnings.
- `gh issue list --state open --search '"correlated Poisson" "SD"' --limit 20`: no matching open issue.

The source manifest and receipt hash-pin the dirty candidate used for the fit. The result is one synthetic point-recovery cell. It does not establish interval coverage, Julia public integration, or broader family and random-effect support.
