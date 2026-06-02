# After Task: Missing Data Design

## Goal

Replace the mixed missing-data and bipartite-phylogeny status note with a
missing-data-only design contract for future `drmTMB` work.

## Implemented

Added `docs/design/149-missing-data-design.md`. The note records the current
complete-case boundary, defines the planned response-missingness and
predictor-missingness terminology, and splits the work into MD0 through MD5
implementation slices.

No likelihood or formula parser code changed. `miss_control()`, `mi()`,
`impute`, response masks, and `imputed()` remain planned syntax, not exported
features.

## Mathematical Contract

The design keeps the missing-data path frequentist. Missing responses use an
observed-response likelihood: missing response cells add no direct response
likelihood contribution, while observed cells still contribute through the
fitted distributional parameters. Missing predictors require an explicit
covariate model and become latent quantities integrated over by TMB/Laplace.

For bivariate Gaussian response missingness, the design separates complete
response pairs from one-response rows. Complete pairs identify the residual
coscale parameter `rho12` directly; one-response rows contribute the appropriate
univariate marginal likelihood for `mu1`/`sigma1` or `mu2`/`sigma2`.

## Files Changed

- `docs/design/149-missing-data-design.md`
- `docs/dev-log/after-task/2026-05-31-missing-data-design.md`
- `docs/dev-log/check-log.md`

The previous untracked mixed-scope files
`docs/design/149-missing-data-and-bipartite-phylo-status.md` and
`docs/dev-log/after-task/2026-05-31-missing-data-bipartite-phylo-status.md`
were replaced before they were treated as durable project records.

## Checks Run

```sh
nl -ba /Users/z3437171/.codex/attachments/702eb90e-fa5b-4bcf-b84b-5ab04f2bf224/pasted-text.txt | sed -n '1,260p'
nl -ba /Users/z3437171/.codex/attachments/702eb90e-fa5b-4bcf-b84b-5ab04f2bf224/pasted-text.txt | sed -n '260,520p'
rg -n "missing data|missing-data|miss_control|observed-data|FIML|mi\\(|missing row|missing-row|complete-case|complete case" docs R tests NEWS.md ROADMAP.md
rg -n "bipartite|Hadfield|host-parasite|missing-data-and-bipartite" docs/design/149-missing-data-design.md docs/dev-log/after-task/2026-05-31-missing-data-design.md docs/dev-log/check-log.md
git diff --check -- docs/design/149-missing-data-design.md docs/dev-log/after-task/2026-05-31-missing-data-design.md docs/dev-log/check-log.md
```

The bipartite/Hadfield scan found only intentional scope exclusions, superseded
draft filenames, and older unrelated check-log history. `git diff --check`
passed for the touched Markdown files.

R tests were not run because this task changed only design and dev-log
Markdown.

## Tests Of The Tests

No tests were added in this design-only pass. The design note states the tests
required before each missing-data slice can be called fitted support.

## Consistency Audit

The design keeps complete-case support separate from planned observed-response
likelihood support. It also keeps missing predictors separate from response
missingness. The note uses `rho12` for bivariate residual coscale and keeps
posterior, MCMC, and credible-interval language out of the frequentist design.

## GitHub Issue Maintenance

Searched open GitHub issues in `itchyshin/drmTMB` for
`missing data miss_control mi impute complete-case`; no matching open issues
were returned. No issue was opened or closed in this pass.

## What Did Not Go Smoothly

The first note combined two future lanes. This pass narrowed the durable record
to missing data only so future agents do not accidentally treat bipartite
phylogenetic location models as part of the missing-data work.

## Team Learning

- Ada: keep the next implementation slice small; MD1 should not smuggle in
  predictor imputation.
- Boole: `miss_control()` and `mi()` are syntax changes and need formula-grammar
  documentation before export.
- Gauss: TMB/Laplace is the general engine for latent missing predictors; EM is
  only a future Gaussian helper.
- Fisher: one-response bivariate Gaussian rows do not directly identify
  residual `rho12`; complete pairs carry that direct evidence.
- Rose: record fitted, planned, and missing surfaces separately so design notes
  do not become accidental support claims.

## Known Limitations

This task did not implement missing-data fitting. `drmTMB` still uses the
existing complete-case paths until a future MD implementation changes code,
tests, documentation, and generated reference materials together.

## Next Actions

Start with MD0 source audit or MD1 univariate Gaussian response masks. Do not
start with missing predictors, structured `mi()`, or bivariate dense known
covariance.
