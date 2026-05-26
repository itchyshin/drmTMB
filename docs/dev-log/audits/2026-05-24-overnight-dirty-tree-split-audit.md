# Overnight Dirty-Tree Split Audit

Generated during the May 24, 2026 overnight autonomous run after the requested
Slices 556-605 validation block.

## Current State

The branch is `codex/non-gaussian-q1-planning-1-10`, ahead of origin by two
commits, with a broad dirty tree. The full package validation currently passes:

```text
devtools::test(): passed
pkgdown::check_pkgdown(): no problems
devtools::check(error_on = "never"): 0 errors, 0 warnings, 0 notes
git diff --check: clean
```

## Suggested Review Lanes

The tree should not be committed as one undifferentiated change. The safer split
is:

| Lane | Purpose | Representative files |
| --- | --- | --- |
| pkgdown home/logo polish | Visual homepage/header scale and evidence screenshots | `pkgdown/extra.css`, `docs/dev-log/figure-audits/2026-05-24-home-logo/`, `docs/dev-log/after-task/2026-05-24-pkgdown-home-logo-scale.md` |
| Phylogenetic direct-SD and `corpairs()` support | Extractor and diagnostic consistency for phylogenetic SD/correlation rows | `R/methods.R`, `R/random-effect-scale-formulas.R`, `tests/testthat/test-phylo-gaussian.R`, `docs/design/16-phylo-spatial-common-math.md`, `docs/design/20-coscale-correlation-pairs.md`, `docs/dev-log/after-task/2026-05-24-phylo-direct-sd-corpair-combination.md` |
| NB2 log-`sigma` random intercept | Ordinary NB2 grouped overdispersion support plus Phase 18 smoke grid | `R/drmTMB.R`, `src/drmTMB.cpp`, `tests/testthat/test-phase18-nbinom2-sigma-random-effect.R`, `inst/sim/dgp/sim_dgp_nbinom2_sigma_random_effect.R`, `inst/sim/fit/sim_summarise_nbinom2_sigma_random_effect.R`, `inst/sim/run/sim_*nbinom2_sigma_random_effect*`, `docs/design/73-phase-18-nbinom2-sigma-random-intercept-ademp.md` |
| NB2 phylogenetic q1 `mu` evidence | Ordinary NB2 q=1 phylogenetic `mu` support, formal-grid artifacts, comparator rows, and hold-smoke-only decision | `R/drmTMB.R`, `R/check.R`, `R/parse-formula.R`, `src/drmTMB.cpp`, `tests/testthat/test-phase18-nbinom2-phylo-q1.R`, `inst/sim/dgp/sim_dgp_nbinom2_phylo_q1.R`, `inst/sim/fit/sim_summarise_nbinom2_phylo_q1.R`, `inst/sim/run/sim_*nbinom2_phylo_q1*`, `docs/design/74-phase-18-nbinom2-phylo-q1-ademp.md`, `docs/design/75-phase-18-nbinom2-phylo-q1-formal-audit.md` |
| Ayumi/Santi developer handoff | Developer-only q2 runner, positive control, simulated no-real-data bundle, and protocol path | `tools/ayumi-santi-*.R`, `docs/design/76-ayumi-santi-phylo-model-improvement-path.md`, `docs/design/77-ayumi-santi-protocol-formula-gallery.md`, `docs/design/78-ayumi-santi-q2-objective1-positive-control.md`, `docs/design/79-ayumi-santi-no-real-data-sim-slices.md`, `docs/dev-log/ayumi-santi/` |
| Overnight validation and recovery | Requested Slices 556-605 revalidation evidence and checkpointing | `docs/design/80-phase-18-shared-runner-migration-audit.md`, `docs/design/81-phase-18-validation-slices-579-605.md`, `docs/dev-log/after-task/2026-05-24-phase18-*.md`, `docs/dev-log/recovery-checkpoints/` |

## Commit Order Recommendation

1. Commit the pkgdown home/logo polish first if screenshots and CSS are still
   wanted. It is visually separable from statistical code.
2. Commit phylogenetic direct-SD and `corpairs()` extractor work before the NB2
   Phase 18 evidence lanes, because the latter lean on stable extractor
   semantics.
3. Commit NB2 log-`sigma` random-intercept support and its smoke-grid evidence.
4. Commit NB2 phylogenetic q1 `mu` support and formal-admission artifacts.
5. Commit Ayumi/Santi developer-only handoff artifacts.
6. Commit overnight validation notes last, or fold them into the relevant
   evidence commits if the maintainer prefers fewer documentation-only commits.

## Checks To Repeat Before Staging

Before any staged commit, rerun at least:

```sh
git status --short --branch
git diff --stat
git diff --check
```

For the NB2 lanes, rerun the focused tests:

```sh
Rscript -e "devtools::test(filter = 'phase18-nbinom2-sigma-random-effect|phase18-nbinom2-phylo-q1|nbinom2-location-scale|nongaussian-scale-boundary', reporter = 'summary')"
```

For a final combined PR, the current green package-level evidence is:

```sh
Rscript -e "devtools::test(reporter = 'summary')"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::check(error_on = 'never')"
```

## Boundaries

Do not treat the dirty tree as approval to broaden the package surface. The
current evidence does not promote the NB2 q1 formal grid beyond
`hold_smoke_only`, does not fit NB2 `sigma` phylogeny, does not fit
zero-inflated NB2 phylogeny, and does not add q4 count covariance.
