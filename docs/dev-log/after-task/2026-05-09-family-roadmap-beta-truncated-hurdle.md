# After Task: Family Roadmap Contract for Beta, Truncated Counts, Hurdles, and Ordinal Models

## Goal

Clarify the next distribution-family sequence before adding another likelihood,
so the R grammar, symbolic equations, user guidance, and implementation roadmap
all point in the same direction.

## Implemented

- `beta()` is now the next planned family for strict continuous proportions in
  `(0, 1)`.
- The beta contract uses public `sigma` and internal beta precision
  `phi = 1 / sigma^2`, so larger `sigma` means more variation.
- Count-family priority now puts `truncated_nbinom2()` before hurdle NB2.
- Hurdle NB2 is planned as `family = truncated_nbinom2()` plus
  `hu ~ predictors`; `hu` is the hurdle-zero probability.
- Beta-binomial denominator syntax is explicitly unresolved, with
  `cbind(successes, failures)` recorded as one candidate.
- First-pass ordinal scope is univariate cumulative-logit syntax with ordered
  cutpoints.
- The family-link contract now lists implemented ZIP/ZINB2 `zi` rows.

## Mathematical Contract

Planned strict beta:

```text
y_i | mu_i, sigma_i ~ Beta(alpha_i, beta_i)
logit(mu_i) = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
phi_i = 1 / sigma_i^2
alpha_i = mu_i phi_i
beta_i = (1 - mu_i) phi_i
E[y_i] = mu_i
Var[y_i] = mu_i (1 - mu_i) / (phi_i + 1)
```

Planned truncated NB2:

```text
y_i | y_i > 0, mu_i, sigma_i ~ truncated NB2(mu_i, sigma_i)
Pr_trunc(y_i) = Pr_NB2(y_i) / (1 - Pr_NB2(0))
```

Here `mu` and `sigma` describe the untruncated NB2 count component. The
expected observed positive count is the NB2 mean conditional on `y > 0`.

Planned hurdle NB2:

```text
logit(hu_i) = X_hu[i, ] beta_hu
Pr(y_i = 0) = hu_i
Pr(y_i = k > 0) = (1 - hu_i) Pr_trunc(k | mu_i, sigma_i)
```

## Files Changed

- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/design/19-family-link-contract.md`
- `vignettes/distribution-families.Rmd`
- `vignettes/formula-grammar.Rmd`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e "rmarkdown::render('vignettes/distribution-families.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/formula-grammar.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `git diff --check`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `air format .` failed because `air` is not installed locally.
- `Rscript -e "pkgdown::build_site()" && Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "devtools::check()"`

Results: the two vignettes rendered, `pkgdown::check_pkgdown()` found no
problems, full tests passed with 981 successes, pkgdown built successfully, and
`devtools::check()` returned 0 errors, 0 warnings, and 0 notes.

## Tests Of The Tests

No fitted likelihood changed, so there is no new parameter-recovery test in this
slice. The test of the test is a consistency audit:

- stale-wording scans found no old undecided beta precision wording, old
  COM-Poisson priority, old continuous-family heading, malformed variance
  bracket, or hurdle-crossing wording;
- positive scans found planned rows in the formula grammar, the `zi` contract
  row, the roadmap-syntax warning, and generated pkgdown pages;
- Pat reviewed the planned examples from an applied-user perspective;
- Rose reviewed source-of-truth consistency and stale wording.

## Consistency Audit

`ROADMAP.md`, `docs/design/06-distribution-roadmap.md`,
`docs/design/19-family-link-contract.md`, `docs/design/01-formula-grammar.md`,
`vignettes/distribution-families.Rmd`, and `vignettes/formula-grammar.Rmd` now
agree that `beta()`, `beta_binomial()`, `truncated_nbinom2()`, `hu`, and
`cumulative_logit()` are planned syntax, not implemented fitting paths.

Generated pkgdown pages were rebuilt and checked for the same wording.

## What Did Not Go Smoothly

The first draft introduced planned syntax in the distribution-family article and
family-link contract but missed the formula-grammar source of truth. Rose caught
that as a P1 issue. Pat also caught that roadmap examples looked runnable unless
the planned-status warning was stated before the first code block.

## Team Learning

Planned syntax is still syntax. If it appears in an article, the formula grammar
must be updated in the same task. Pat should review planned user-facing examples
whenever they look like copy-pasteable code, and Rose should check that all
source-of-truth documents move together.

## Known Limitations

- `beta()`, `beta_binomial()`, `truncated_nbinom2()`, `hu`, and
  `cumulative_logit()` are not implemented yet.
- Beta-binomial denominator syntax is not settled.
- COM-Poisson and generalized Poisson remain later because their comparator and
  mean/dispersion contracts need more design work.

## Next Actions

1. Implement strict fixed-effect `beta()` with `mu` and `sigma`.
2. Add beta simulation recovery, hand-coded likelihood checks, and a
   mean-precision comparator transform.
3. Only then implement `truncated_nbinom2()` and use that likelihood as the
   base for a future `hu` hurdle component.
