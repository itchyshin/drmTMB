# Check log: NotebookLM methods review, 2026-10-20

- NotebookLM CLI 0.8.5: `notebooklm auth check --test --json` reported `status=ok`, account `itchyshin@gmail.com`, and `checks.token_fetch=true`.
- Existing NotebookLM source list: 15 sources, all marked ready by the CLI. Several captured pages were title-only, metadata-only, or otherwise weak; they were excluded from substantive claims.
- NotebookLM synthesis saved as note `b8f1ac10-4a35-43b0-b07b-c8fedd915f70`; the CLI reported no structured citations. The synthesis was treated as a research lead, not as a cited source.
- Primary-source verification: Joe (2008) publisher page/abstract, Stringer (2024 preprint), CRAN `dhglm` 2.0 manual, `glmmTMB` covariance vignette. The Joe full text is access restricted; no numerical coverage percentages were adopted.
- Review note: `docs/dev-log/general-sd-regression/notebooklm-methods-review-20261020.md`.
- No package tests or fits were run for this research-only slice. No source code or public behavior changed.
- Statistical design correction recorded: one Bernoulli observation per group with a common logit intercept supplies one common marginal success probability and cannot identify both intercept and random-intercept SD. This is design-specific; it does not establish a universal result for all one-observation-per-group designs with varying predictors.
- Full feature recovery, likelihood-oracle checks, profile/bootstrap calibration, engine parity, broader family inventory, and package checks remain outstanding.
