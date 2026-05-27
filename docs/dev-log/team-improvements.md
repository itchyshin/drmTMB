# Team Improvements

This log records improvements to the agent team's own operating process. Use it
when a task exposes a better way for Ada, Boole, Gauss, Noether, Darwin,
Florence, Fisher, Pat, Jason, Curie, Emmy, Grace, or Rose to work.

This file is for process improvements, not package feature requests. Product
or statistical-design changes still belong in roadmap files, design docs,
issues, or pull requests.

## 2026-05-26 - First-Wave Surface Wiring Checklist

- Improvement implemented: when a new Phase 18 first-wave surface is added,
  Curie and Grace should check all four wiring points together: the per-surface
  source list, `phase18_run_first_wave_summary_smoke()`, the
  `phase18_first_wave_parallel_summary()` signature/row list, and the
  first-wave smoke-runner expected surface and row counts.
- Improvement implemented: a failed first-wave summary test showed that adding
  a grid output without updating the parallel summary connector is easy to
  miss. Future first-wave lanes should run the first-wave smoke-runner test
  before ledger closeout, not only the new per-surface tests.

## 2026-05-16 - Portable Agent Operating Kit

- Improvement implemented: added this team-improvement log so process lessons
  have one durable home instead of being scattered only through after-task
  reports.
- Improvement implemented: added a `Team Improvement Loop` rule to `AGENTS.md`
  and to the portable `AGENTS.md` template.
- Improvement implemented: generalized the `tmb-likelihood-review` idea into a
  portable `model-implementation-review` skill so sibling projects that are not
  TMB-based still have a numerical and implementation review lane.
- Improvement implemented: added a memory policy to the portable kit so agents
  treat repository files as authoritative and verify drift-prone facts.
- Pilot needed: install the kit in a sibling project, preferably `gllvmTMB`,
  and revise the templates after first-use friction.

## 2026-05-17 - Start-Of-Task Role Status

- Improvement implemented: every substantial `drmTMB` task should start with a
  short "who is working right now" update. The default visible roles are Ada,
  Pat, Fisher, Grace, and Rose; add Boole, Gauss, Noether, Darwin, Jason,
  Florence, Curie, or Emmy when the task touches their lane.
- Improvement implemented: if no spawned subagents are currently running, say
  so explicitly instead of letting the named perspectives sound like hidden
  background processes.
- Improvement implemented: meaningful after-task reports should preserve the
  same role perspective so the user can see who steered orchestration,
  usability, inference, reproducibility, and consistency.

## 2026-05-18 - Florence And Memory OS Guardrails

- Improvement implemented: Florence is now the standing scientific figure
  editor for visualization work. Add her whenever a slice touches plots,
  confidence bands, simulation figures, figure galleries, visual diagnostics, or
  publication-ready ggplot examples.
- Improvement implemented: the visualization grammar now has a Florence figure
  gate. A plot should show the fitted parameter, reporting scale, interval
  provenance, raw-data or diagnostic context, and accessibility choices before it
  is treated as reader-facing.
- Improvement implemented: the user-provided Memory OS PDF and starter pack
  informed a conservative memory rule for this project: durable decisions belong
  in `AGENTS.md`, design docs, check logs, after-task reports, or explicit memory
  notes with source, date, status, and confidence. Conversation alone is not a
  reliable project memory.
- Boundary: do not install Hermes, MemSearch hooks, or a new agent framework
  inside `drmTMB` without a separate design decision. Adopt the useful
  store-recall-audit habit first; keep repository files authoritative.

## 2026-05-18 - Reader-Facing Page Names And Sibling-Learning Checks

- Improvement implemented: public pkgdown article titles and navbar labels
  should be reader-facing first. Internal labels such as "Phase 18" or "Slice
  258" can appear in developer notes or provenance text, but they should not be
  the main route to a tutorial, gallery, or analysis workflow.
- Improvement implemented: distinguish a general figure gallery from a
  specialised simulation diagnostics report. The general gallery should show
  model interpretation, confidence bands, fitted correlation displays,
  variance/SD surfaces, and simulation operating-characteristic figures across
  continuous, proportion, count, bivariate, and structured-dependence examples
  as those surfaces become ready.
- Improvement implemented: Ada and Jason should periodically compare sibling
  packages and project reports for reusable lessons, while Rose records only
  the lessons that change `drmTMB` process, documentation, validation, or user
  routing. These checks should be occasional and scoped, not a distraction from
  the active slice.

## 2026-05-20 - Shared Figure Judgment Gate

- Improvement implemented: poor figures are now treated as a shared team
  failure mode rather than Florence's fault alone. Florence owns the final
  scientific-figure standard, but Fisher must check uncertainty and data grain,
  Pat must check reader interpretation, Rose must check repeated overclaims,
  Grace must require rendered per-figure evidence, Darwin must keep the
  biological question visible, and Boole/Noether must catch syntax or estimand
  labels that make planned features look fitted.
- Improvement implemented: added the project-local `figure-visual-audit` skill
  for rendered one-by-one figure review. Contact sheets may guide navigation,
  but they no longer count as sufficient evidence by themselves.
- Improvement implemented: the visualization grammar now states the positive
  standard as well as the error-prevention gate. Beautiful scientific figures
  should help users understand `drmTMB` models and help the package team catch
  failed intervals, missing support, incoherent labels, and wrong assumptions.
- Improvement implemented: rendered contact sheets are navigation aids only.
  A figure is not "checked" until at least one rendered output for that figure
  has been inspected for alignment, missing uncertainty, raw or replicate grain,
  label honesty, and whether it teaches the fitted model result.
- Improvement implemented: once a figure grammar is stable, every substantive
  worked example should include a model-output figure, not just a printed
  table. The display should name the estimand, reporting scale, uncertainty
  source, and whether it is raw data, fitted prediction, simulation replicate
  grain, Wald confidence, profile likelihood, bootstrap, or a support boundary.

## 2026-05-21 - First-Slice Claim Hygiene

- Improvement implemented: when a planned surface becomes a narrow first slice,
  Rose should search for both old false negatives and new false positives. The
  docs must stop saying "not fitted anywhere" while still preventing the
  opposite mistake: implying neighbouring families, dependence layers, slopes,
  or covariance blocks are also fitted.
- Improvement implemented: Fisher and Curie should name the evidence tier in
  the same paragraph as the fitted claim for new structural routes. A likelihood
  smoke test with extractors is useful, but it is not recovery or coverage
  evidence until an ADEMP sheet and grid artifacts exist.
- Improvement implemented: live-deploy figure review must still inspect
  individual rendered PNGs after `pkgdown` deploys. A local render or contact
  sheet can miss clipped subtitles, captions hanging off the image, or labels
  that become cramped at the deployed size; those are release-facing failures,
  not cosmetic trivia.

## 2026-05-21 - Planned-Only Snapshot Retirement

- Improvement implemented: when a planned structured-effect path becomes a
  fitted path, tests that existed only to snapshot the old unsupported error
  should be retired or converted to direct malformed-input assertions. Keeping
  the old snapshot shape creates false friction and can preserve stale
  user-facing wording after the feature is real.
- Improvement implemented: Rose should pair each feature-promotion slice with
  a stale-claim scan over NEWS, design docs, vignettes, R docs, and tests for
  old planned-only phrases.
- Trigger: Slice 39 promoted phylo, animal, and `relmat()` one-slope Gaussian
  `mu` effects from parser/planned status to fitted status. The old
  animal/relmat unsupported-slope snapshots were no longer useful evidence.

## 2026-05-21 - Map Authority And Evidence Tiers

- Improvement implemented: public status pages now need distinct jobs.
  `model-map` helps users choose a fitted route, `implementation-map` states
  fitted-versus-planned boundaries, `source-map` points contributors to code and
  tests, the validation-debt register records evidence, and `ROADMAP.md`
  records sequence and future work.
- Improvement implemented: Ada and Rose should label fitted first slices with
  an evidence tier, such as formal small grid, smoke/artifact only,
  interval-heavy opt-in, diagnostic/failure ledger, or planned/blocked. This
  prevents a fitted route such as constant spatial q4 from looking like formal
  coverage evidence.
- Trigger: the implementation map had become useful but historically heavy,
  and the spatial q4 fitted slice exposed stale q2-gate wording in roadmap and
  validation ledgers.

## 2026-05-21 - Active HTML Figure Inventory

- Improvement implemented: rendered pkgdown figure audits should inventory the
  active `<img>` references in the rebuilt HTML before counting PNGs in the
  ignored figure directory. The directory can retain stale files from earlier
  chunk labels, which makes the figure count look larger than the page a reader
  actually sees.
- Improvement implemented: when a figure uses a shared plotting helper, Fisher
  and Noether should still check that the displayed aesthetics match the fitted
  formula. A legend can imply an unsupported model term even when the plotted
  intervals and estimates are numerically correct.
- Trigger: the `model-workflow` page initially appeared to have 18 rendered
  PNGs, but only five were active in the HTML. The old `sigma` panels also
  coloured duplicate habitat rows even though the model was `sigma ~
  temperature`.

## 2026-05-22 - Confidence Eye Default

- Improvement implemented: Confidence Eye plots are the default visual grammar
  for finite-interval displays that need more than a flat CI bar. The default
  is a pale finite confidence region plus a hollow point-estimate circle. It
  does not use filled points, outer outlines, center bars, or separate CI bars.
  Optional CI lines or caps are acceptable only for explicitly labelled
  print-accessibility, diagnostic, or reader-preference variants.
- Improvement implemented: Fisher should keep the statistical provenance
  explicit: Wald intervals use the model scale or response scale stated in the
  figure, correlations use a Fisher-z/`atanh` scale when finite bounds are
  transformed, and the display is not a Bayesian posterior density.
- Trigger: the first figure-gallery Confidence Eye pass showed that adding
  bars and outlines by default made the display less memorable than the
  user-facing idea needed. The later failed render with duplicated axis labels
  showed that figure code is not evidence; every changed figure needs direct
  rendered-image inspection before prose is rewritten.
- Trigger: the follow-up correction briefly chased the wrong figure chunk. For
  figure QA, the active target must be named by rendered image path, chunk name,
  and title before edits begin, so Ada, Boole, Noether, Fisher, Pat, Grace,
  Florence, and Rose are judging the same artifact.
- Trigger: a later rendered check was over-interpreted as banning row guides.
  For Confidence Eye defaults, Florence and Fisher should allow subtle row
  guides when they help row tracking, but reject dark lines that read like CI
  bars or compete with the pale confidence region.
- Trigger: an older tracked audit PNG still showed the rejected filled-point
  and CI-line hybrid after the live article figure had been repaired. Rendered
  audit artifacts are part of the project surface when they are shown to the
  user; refresh them or label them as rejected/before-state evidence.
- Trigger: reusing the same PNG path in the chat caused the app to show a
  cached old thumbnail. When a visual correction is the point of the task, use
  a fresh evidence filename for the final proof image.
- Trigger: `pkgdown-site/dev/articles/figure-gallery_files/` still contained
  an older rejected PNG after `pkgdown::build_article()` refreshed only the
  public `pkgdown-site/articles/` copy. Grace should check both rendered mirrors
  before visual evidence is shown from local site files.
- Trigger: the mixed coefficient/SD/correlation display still looked wrong
  after the pure correlation figure was fixed. Florence should reject faceted
  or strip-labelled Confidence Eye examples unless the facets solve a genuine
  reader problem; the default should start from the clean reference image.
- Trigger: later comparison against the reference image showed that the
  coefficient and SD examples still used fatter eye geometry than the accepted
  correlation display. Florence should treat eye half-height and hollow-point
  size as part of the visual contract, not incidental ggplot tuning.
- Trigger: the variance-component Confidence Eye was the closest accepted
  example and used a bottom axis that helped anchor the scale. Keep bottom-axis
  treatment consistent across the Confidence Eye row-display family unless a
  specific figure has a stronger reason to omit it.
- Trigger: the repair discussion exposed a broader failure mode: turning one
  good figure into a universal rule. Use case-by-case visual grammar. Raw-data
  figures, fitted model estimates, row-wise interval summaries, simulation
  summaries, and support-boundary strips need different geometry, but each
  family should keep consistent colours, labels, uncertainty provenance, and
  axis language.

## 2026-05-26 - Tutorial-Gate Roadmap Scan

- Improvement implemented: tutorial-gate stale scans should include
  `ROADMAP.md`, generated ROADMAP HTML, getting-started, model-map, source-map,
  worked-example inventory, NEWS, and the relevant tutorial article.
- Trigger: the zero-one beta reader follow-through initially synchronized the
  vignettes and source map, but the roadmap still described zero-one beta as a
  future family in current Phase 8/9 status text.

## 2026-05-26 - One-SD Simulation Helpers

- Improvement implemented: Phase 18 DGP helpers with a single random-effect SD
  should use a one-value validator, not the two-value `phase18_named_pair()`
  helper used by intercept-plus-slope surfaces.
- Trigger: the first bounded-response random-intercept smoke test initially
  produced no summaries because the one-SD `sd` vector was routed through a
  two-parameter validation helper before any model fit ran.

## 2026-05-26 - Bounded-Response Status Sync

- Improvement implemented: when a first-slice non-Gaussian random-effect route
  lands, update both the design-ledger tables and the public implementation-map
  table before starting the next neighbouring-family gate.
- Trigger: the zero-one bounded-response design gate found that
  `vignettes/implementation-map.Rmd` still listed beta-binomial random effects
  as `none`, even though beta-binomial ordinary `mu` random intercepts were
  already fitted and documented elsewhere.

## 2026-05-20 - Installed-Layout Runner Tests

- Improvement implemented: tests for `inst/` runner scripts must exercise the
  installed-package layout as well as the source-tree layout. Use
  `system.file()` for the installed path and source-tree fallbacks only for
  local development.
- Improvement implemented: paths passed to `Rscript` from tests should be
  quoted with `shQuote()`. Local paths can include spaces, and CI failures from
  unquoted paths are avoidable noise.
- Trigger: PR #264 R-CMD-check run `26171357996` failed because
  `tests/testthat/test-phase18-actions-runner.R` called a source-tree-relative
  `../../inst/sim/run/sim_run_actions_cell.R` path that did not exist after
  installation.

## 2026-05-20 - Targeted Formatting In Release Slices

- Improvement implemented: release-candidate slices should run `air format` on
  the touched R files, not `air format .`, unless the task explicitly owns a
  repository-wide formatting pass.
- Trigger: the `0.1.3` candidate run briefly produced unrelated formatting churn
  in simulation helpers and older tests. Ada reversed that churn and kept only
  the spatial q=2, release metadata, documentation, and ledger files dirty.
- Grace and Rose should check `git status --short` immediately after formatting
  and trim accidental churn before running final release checks.

## 2026-05-20 - After-Task Issue Maintenance

- Improvement implemented: meaningful after-task reports should now inspect
  overlapping open GitHub issues before the task is called closed.
- Improvement implemented: Ada and Rose should prefer updating an existing
  issue over opening a duplicate, and the report should record whether the
  task commented on an issue, opened a new one, closed one, or deliberately left
  the tracker unchanged.
- Trigger: structural-dependence parity, figure-quality promises, animal-model
  examples, bootstrap intervals, and Ayumi convergence work were spread across
  chat, docs, and issues. The issue tracker needs to stay part of the same
  memory loop as check logs and after-task reports.

## 2026-05-20 - CI-Wait Learning Loop

- Improvement implemented: long GitHub Actions waits should become bounded
  learning or audit time. Grace keeps watching the workflow state while Ada
  asks Jason, Florence, Fisher, Pat, Curie, or Rose to do a scoped sidecar
  check only when it can produce a concrete artifact, issue update, or design
  correction.
- Improvement implemented: sibling-package scouting should have a clear
  exchange. `gllvmTMB` showed the value of manual long-run matrix workflows
  with per-cell artifacts and retention controls; `drmTMB` contributes the
  stricter artifact-grain, interval-provenance, and admitted-surface gates
  before results are plotted.
- Boundary: the wait-time loop is not permission to start broad feature work
  while CI is pending. If the sidecar check would change likelihoods, formula
  grammar, or public API, it must become a normal slice with tests and review.

## 2026-05-17 - Family-Block TMB Data Wiring Check

- Improvement implemented: when a slice changes `make_tmb_data()` for one
  family, inspect the neighbouring family blocks with line numbers before
  testing. The Slice 191 Poisson random-intercept patch first wired
  random-effect TMB fields into the adjacent cumulative-logit block; a manual
  `MakeADFun()` probe and comparator tests caught the mismatch. Future family
  slices should confirm the intended block receives the new fields before
  broad validation.
