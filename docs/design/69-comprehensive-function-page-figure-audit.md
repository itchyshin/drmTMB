# Comprehensive Function, Page, and Figure Audit Map

## Purpose

The comprehensive audit starts now, but it should not be one giant refactor.
The package has accumulated inconsistencies across exported functions,
reference pages, vignettes, model maps, status tables, interval wording, and
figures. This map turns that into bounded slices with visible evidence,
rendered outputs, and a durable ledger.

The audit has three rules:

1. inventory before editing;
2. render before declaring a page or figure fixed;
3. record every resolved inconsistency in the check log and after-task report.

## Audit Lanes

| Lane | Primary owner | Scope | Evidence required |
| --- | --- | --- | --- |
| Function and reference inventory | Emmy with Boole and Rose | Exported functions, S3 methods, aliases, `NAMESPACE`, `man/*.Rd`, `_pkgdown.yml`, examples, lifecycle wording, and unsupported-method errors. | Function table with exported name, help page, pkgdown location, example status, tests, and known limitations. |
| Inference and CI consistency | Fisher with Gauss, Noether, and Rose | `confint()`, `summary()`, `corpairs()`, `profile_targets()`, prediction-table intervals, bootstrap boundaries, Wald/profile/bootstrap status vocabulary, SD log-scale intervals, and correlation atanh/Fisher-z wording. | Stale-wording scan, targeted tests, and rendered model-workflow or reference pages showing the fast route. |
| User pages and model maps | Pat with Darwin and Rose | README, ROADMAP, implementation map, model map, model-workflow, formula grammar, distribution families, source map, and known limitations. | Page-level audit table naming the scientific question, supported syntax, implemented status, evidence tier, and next action. |
| Figure quality | Florence with Fisher, Pat, Grace, Curie, Rose, Boole, Noether, and Darwin | Figure gallery, model-workflow plots, simulation reports, covariance or correlation displays, raw-vs-fitted grain, uncertainty displays, alt text, legends, labels, and missing-cell displays. | Rendered figures inspected one by one, with a per-figure table: source chunk, visual data grain, uncertainty source, reader risk, verdict, and fix. |
| Simulation and validation surfaces | Curie with Fisher and Grace | Phase 18 simulation articles, result manifests, coverage summaries, skip/warning/error ledgers, and plots that summarize simulation evidence. | Simulation artifact inventory and a check that every figure names replicate grain, aggregate statistic, and MCSE or interval source. |
| Source-map and developer docs | Ada with Emmy, Gauss, Noether, and Rose | `src/` source map, helper extraction docs, likelihood parameterization docs, formula grammar, C++/R ABI boundaries, and provenance notes. | Source-map diff, C++ helper boundary check, and no unsupported claims about moved likelihood branches. |

The named roles are review perspectives, not spawned agents. Ada coordinates
the order and keeps the slices small.

## First Slice Set

Slice A is the CI and inference wording cleanup. It updates the model-workflow
article, ROADMAP rows, and design notes so the public story is coherent:
default Wald intervals are fast and cover direct fitted scale, SD, and
correlation targets; `profile_precision = "fast"` is the quick profile pass;
bootstrap exists through `confint()` for selected direct targets; and
`summary()`/`corpairs()`/derived summaries remain separate work.

Slice B is the sister-package audit note. It records what the local
`gllvmTMB` source actually does for profile, Fisher-z correlations, and
bootstrap so future work can learn from it without importing code or scope.

Slice C is the function/reference inventory. Build a table from
`NAMESPACE`, `R/`, `man/`, `_pkgdown.yml`, and focused tests. The first pass
should flag mismatches, not fix every mismatch immediately.

Slice D is the figure audit kickoff. Render the figure-heavy pages, inspect
each rendered image, and create a durable table under
`docs/dev-log/figure-audits/<date-or-slice>/`. The first pass should separate
poor visual design from unsupported statistical intervals. A line-only figure
can be correct if the table says `conf.status = "wald_unavailable"`; it is
not correct if the caption implies uncertainty that is not drawn.

## Initial Stale-Wording Scans

Run these scans before closing the first audit set, and paste the exact results
or a compact summary into the after-task report:

```sh
rg -n 'bootstrap intervals are not implemented|method = "bootstrap"|parametric-bootstrap intervals|unsupported bootstrap|direct random-effect SD.*Wald|fixed-effect intervals only|Fisher-z.*public|profile_precision' README.md ROADMAP.md NEWS.md docs/design vignettes R man tests/testthat -S
rg -n 'conf.status = "wald_unavailable"|no confidence band|no Wald interval|direct random-effect SD surface|uncertainty|confidence|profile|bootstrap' vignettes/figure-gallery.Rmd vignettes/model-workflow.Rmd docs/design/39-visualization-grammar.md -S
rg -n 'Current capability|implemented|planned|blocked|smoke|derived_interval_unavailable|profile_ready' README.md ROADMAP.md vignettes/implementation-map.Rmd vignettes/model-map.Rmd docs/design/46-pre-simulation-readiness-matrix.md -S
```

Historical after-task reports and older NEWS entries can remain true for their
date. Current reader-facing pages, current ROADMAP rows, current design notes,
and current generated reference pages must not contradict the live package.

## Figure Gate

Florence's gate is not cosmetic. A figure passes only when a reader can tell:

- what the estimand is;
- whether the marks are raw observations, fitted rows, simulation replicates,
  or aggregate summaries;
- what uncertainty source is shown, if any;
- why an interval or support cell is missing;
- what action the figure supports.

Figures should be rendered through pkgdown or `rmarkdown::render()`, then
inspected directly. A contact sheet can help navigation, but it is not enough
evidence by itself. The audit should not show raw-response points on a
`sigma`, `rho12`, SD, or correlation axis; use fitted-row predictions or
simulation summaries on their own named axis.

## Deliverables

The comprehensive audit should produce these artifacts:

1. `docs/dev-log/audits/<date>-function-reference-audit.md`
2. `docs/dev-log/audits/<date>-page-status-audit.md`
3. `docs/dev-log/figure-audits/<date-or-slice>/figure-audit.md`
4. check-log entries for each completed slice
5. after-task reports for any slice that changes user-facing pages,
   exported-function documentation, interval behaviour, or figures

## Done For The First Audit Set

The first audit set is done only when:

- the fast CI workflow is visible in a rendered article or reference page;
- the `gllvmTMB` audit note is committed as source-only evidence;
- stale public wording about bootstrap being unavailable is removed from
  current reader-facing surfaces;
- the next function/page/figure inventory files are created or explicitly
  queued in the after-task report;
- `git diff --check`, pkgdown checks, and focused tests for touched behaviour
  have passed or the failure is recorded with an exact blocker.
