# General prior table article review

Date: 2026-11-23

## Scope

Expanded the drmTMB prior article to introduce the table interface across fixed
coefficients, residual SDs, supported independent random-intercept SDs, and
correlations. The examples show that Gamma SD rows use a normalized density on
the natural SD without a log-SD Jacobian. The article also states that Gamma
priors on SDs in correlated random-slope blocks are not currently supported.
Updated the pkgdown menu label to match the broader article.

## Checks

Passed:

- Rendered `vignettes/articles/fixed-effect-priors.Rmd` from the isolated
  drmTMB worktree based on commit `950b5e0c50647d11dab945782df65152585d6c53`.
  The render executed fixed-effect and SD-table examples, the random-slope
  correlation example, and the bivariate residual-rho12 example. It also
  verified the unpenalized data log-likelihood, log prior, and minimized
  negative penalized objective are reported with the correct signs. HTML SHA-256:
  `3a3462acf65a216f4b6471ee0272bb4d35e234d70a91220fa77b0e87a905787c`.
- `pkgdown::check_pkgdown()` completed with “No problems found.” Its site
  render reported only the repository-wide deprecated `--mathjax` option.
- `git diff --check` passed.
- `slop_check.py` reported 0 findings for the article.

Two initial render attempts exposed unsupported combinations: a random-SD
Gamma prior with a correlated random-slope block, and a residual-SD Gamma prior
with a varying sigma formula. The final examples separate those targets and
render successfully. The package full suite is running on the frozen code
candidate; this documentation-only worktree is not included in that run.
