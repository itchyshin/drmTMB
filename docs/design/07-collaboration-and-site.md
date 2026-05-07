# Collaboration and Website Plan

`drmTMB` should be friendly to human contributors and to multiple coding
agents, including Codex and Claude Code.

## Collaboration Rules

- The repository rules live in `AGENTS.md`.
- Design memory lives in `docs/design/`.
- Development memory lives in `docs/dev-log/`.
- Agents should leave concise check-log entries after meaningful work.
- No agent should revert another agent's or human's work without explicit
  instruction.
- Likelihood and formula grammar changes require tests and design-doc updates.

## Claude Code

Claude Code can help with implementation, documentation, testing, and review.
It should be treated as another contributor operating through the same repo
rules. It should not introduce a separate project architecture or dependency.

## pkgdown Goals

The pkgdown site should become the public face of `drmTMB`, similar in spirit
to other ecology/evolution modelling package sites:

- clear homepage with the package identity and flagship syntax;
- reference index grouped by user task;
- getting-started article;
- location-scale tutorial;
- meta-analysis tutorial using `meta_known_V(V = V)`;
- bivariate location-coscale tutorial;
- phylogenetic and spatial dependence article;
- distribution-family guide;
- developer articles for formula grammar, adding families, and testing
  likelihoods;
- changelog/news.

## Planned Articles

- `drmTMB`: package overview.
- `location-scale`: Gaussian location-scale models.
- `meta-analysis`: Gaussian meta-regression with known sampling covariance and
  heterogeneous heterogeneity.
- `bivariate-coscale`: bivariate Gaussian models with `rho12 ~ predictors`.
- `phylogenetic-spatial`: A-inverse and SPDE plans for dependent data.
- `distribution-families`: choosing families for continuous, count,
  proportion, percentage, and ordinal responses.
- `formula-grammar`: formula syntax and validation.
- `adding-families`: developer workflow for new families.
- `testing-likelihoods`: simulation recovery and numerical diagnostics.

## Deployment

The intended site URL is:

```text
https://itchyshin.github.io/drmTMB/
```

GitHub Actions should build and deploy pkgdown once the GitHub repository is
connected and Pages permissions are configured.

The repository Pages setting should use **GitHub Actions** as the source. The
pkgdown workflow should configure Pages, build into `pkgdown-site`, upload that
artifact, and deploy it through `actions/deploy-pages`. Generated site output
stays ignored in git.
