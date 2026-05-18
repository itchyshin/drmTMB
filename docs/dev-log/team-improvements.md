# Team Improvements

This log records improvements to the agent team's own operating process. Use it
when a task exposes a better way for Ada, Boole, Gauss, Noether, Darwin,
Florence, Fisher, Pat, Jason, Curie, Emmy, Grace, or Rose to work.

This file is for process improvements, not package feature requests. Product
or statistical-design changes still belong in roadmap files, design docs,
issues, or pull requests.

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

## 2026-05-17 - Family-Block TMB Data Wiring Check

- Improvement implemented: when a slice changes `make_tmb_data()` for one
  family, inspect the neighbouring family blocks with line numbers before
  testing. The Slice 191 Poisson random-intercept patch first wired
  random-effect TMB fields into the adjacent cumulative-logit block; a manual
  `MakeADFun()` probe and comparator tests caught the mismatch. Future family
  slices should confirm the intended block receives the new fields before
  broad validation.
