# Collaboration and Website Plan

`drmTMB` should be friendly to human contributors and to multiple coding
agents, including Codex and Claude Code.

## Collaboration Rules

- The repository rules live in `AGENTS.md`.
- Design memory lives in `docs/design/`.
- Development memory lives in `docs/dev-log/`.
- Agents should leave concise check-log entries after meaningful work.
- One agent should act as integrator for each task.
- Use read-only sidecar agents for design review, likelihood review,
  documentation review, and validation planning.
- Use write-capable workers only when their file ownership is narrow and does
  not overlap with other active work.
- No agent should revert another agent's or human's work without explicit
  instruction.
- Likelihood and formula grammar changes require tests and design-doc updates.

## Starting A New Conversation

If a future Codex or Claude Code conversation starts outside this project, give
it the repository path:

```text
/Users/z3437171/Dropbox/Github Local/drmTMB
```

Then ask it to read:

- `AGENTS.md`;
- `CLAUDE.md` for Claude Code;
- `ROADMAP.md`;
- `docs/design/00-vision.md`;
- `docs/design/01-formula-grammar.md`;
- the latest files in `docs/dev-log/after-task/`;
- `docs/dev-log/check-log.md`.

The project should remain reproducible from repo files, not from hidden agent
memory. Important decisions should therefore be committed to design docs,
check logs, after-task notes, or issues before moving on.

## Current Agent Team

| Role name | Kind | Responsibility |
| --- | --- | --- |
| Ada | orchestrator and integrator | Decide the next slice, implement or delegate, and keep code, math, docs, tests, pkgdown, git, and CI consistent. |
| Boole | R/API reviewer | Formula parser, R API, S3 methods, and user-facing errors. |
| Gauss | TMB reviewer | Likelihoods, parameter transforms, Laplace/random-effect numerics, and optimizer risk. |
| Noether | mathematical consistency reviewer | Symbolic equations, formula taxonomy, family composition, `rho12` naming, and correlation namespaces. |
| Darwin | ecology/evolution audience reviewer | Biological examples, ecological interpretation, and gllvmTMB sibling positioning. |
| Fisher | statistical inference reviewer | Comparator-package checks, simulation recovery, profile-likelihood plans, and identifiability diagnostics. |
| Pat | applied user tester | Tutorial clarity, output interpretation, error recovery, and whether a new applied user can follow the workflow. |
| Jason | landscape and source-map scout | Related package capabilities, literature context, and what `drmTMB` should learn or avoid. |
| Curie | simulation and testing specialist | Recovery tests, edge cases, malformed-input tests, and CRAN-safe versus long-test balance. |
| Emmy | R package architecture reviewer | S3 structures, fit objects, extractors, internal APIs, and package coherence. |
| Grace | reproducibility engineer | GitHub Actions, pkgdown, CRAN checks, platform portability, and dependency risk. |
| Rose | systems auditor | After-task audits, stale wording, repeated mistakes, and discrepancies across files. |

Most of these are sidecars, not permanent processes. The durable version of
their advice must be copied into repository documents.

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
