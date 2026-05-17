# Team Improvements

This log records improvements to the agent team's own operating process. Use it
when a task exposes a better way for Ada, Boole, Gauss, Noether, Darwin,
Fisher, Pat, Jason, Curie, Emmy, Grace, or Rose to work.

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
  Curie, or Emmy when the task touches their lane.
- Improvement implemented: if no spawned subagents are currently running, say
  so explicitly instead of letting the named perspectives sound like hidden
  background processes.
- Improvement implemented: meaningful after-task reports should preserve the
  same role perspective so the user can see who steered orchestration,
  usability, inference, reproducibility, and consistency.

## 2026-05-17 - Family-Block TMB Data Wiring Check

- Improvement implemented: when a slice changes `make_tmb_data()` for one
  family, inspect the neighbouring family blocks with line numbers before
  testing. The Slice 191 Poisson random-intercept patch first wired
  random-effect TMB fields into the adjacent cumulative-logit block; a manual
  `MakeADFun()` probe and comparator tests caught the mismatch. Future family
  slices should confirm the intended block receives the new fields before
  broad validation.
