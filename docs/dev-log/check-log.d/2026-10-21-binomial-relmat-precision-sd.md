# Check log: Binomial relatedness precision SD regression

## Scope

The native Binomial `relmat()` direct-SD path now has a focused equivalence test
for precision input `Q`, alongside the existing covariance-input `K` test. The
new fixture uses the same generated latent field and deliberately reorders the
precision matrix nodes.

## Checks

- Estimated runtime before fitting: about one minute.
- `Rscript --no-init-file -e 'devtools::test(filter = "binomial-relmat-precision-sd")'`: PASS, 9 assertions, 0 failures, 0 warnings, 0 skips, 13.6 seconds.
- `Rscript --no-init-file -e 'devtools::test(filter = "binomial-relmat-precision-sd|binomial-relmat-sd")'`: PASS, 31 assertions, 0 failures, 0 warnings, 0 skips, 31.5 seconds.
- The test checks that both fits converge, their log likelihoods and SD coefficients agree, the SD slope is near its generating value, and group-level predictions agree after matching group names.
- A preceding fit-only smoke check also matched the `K` and permuted `Q` fits; the raw prediction vectors use different node orderings, so positional comparison is invalid.
- Corrected three position-sensitive assertions in the existing covariance-input test to align SD outputs by group name; model assembly and returned names remain unchanged.
- The live Julia engine was not exercised.
- The after-task structure check passed. Its acceptance-ledger probe warned that
  the ledger is present but not runnable because this worktree lacks the
  gate-check entry point; goal gates remain unknown/open.

## Documentation and issue review

Updated the Bernoulli row in `docs/dev-log/general-sd-regression/inventory.md`
and the partial G3 evidence in `.unlazy/general-sd-regression/GATES.md`.
No formula, model, NEWS, or public guide changed because the user-facing syntax
and builder behavior were already present. Open issue searches for Binomial
`relmat()` SD regression found no directly matching implementation issue; the
general simulation-framework issue is broader and was left unchanged.

## Limits

This establishes one native Binomial/logit q1 relatedness-matrix precision
input equivalence cell. It does not establish other response families,
structured providers, slopes, Julia parity, calibrated uncertainty, or
programme completion.
