# General predictor-dependent random-effect SD regression

Approved by Shinichi on 2026-10-17. This goal remains open until every required
gate passes. Re-read this file at the beginning of each execution arc.

Deliver predictor-dependent latent random-effect SDs across supported response
distributions, effect types and native TMB/Julia engines wherever identifiable.
The first delivery is Bernoulli using independent synthetic examples. The finish
line includes recovery, calibrated uncertainty, consistent public methods and
documentation. Fixed predictors only on SD right-hand sides. Use Totoro and DRAC
for substantive simulation and NotebookLM for the reviewed methods synthesis.

## Invariants

- One or two responses only. No collaborator data or study examples.
- Preserve existing kernel normalization, correlations and constant-SD fits.
- Missing implementation is not non-identifiability. Required cells cannot vanish.
- Keep all attempted fits and failures in validation denominators.
- Existing calibrated Beta phylogenetic evidence does not validate a new cell.
- No push, merge, release, email or public capability claim without its named gate.
- No production campaign estimated above three hours before a timed pre-run and
  Shinichi's approval. Local CPU about four cores; Totoro at most 150 cores.
- No credential or permission changes. NotebookLM currently needs reconnection.

## Where truth lives

- Branch: codex/general-sd-regression, initially d89db50975d96d9c2bcb13046453ae34c7fcf49b.
- Kit: LOOP/lanes/general-sd-regression/.
- Plan: ultra-plan.md in this kit. Progress: arcs.md and checkpoint.md.
- Scientific contract and receipts: docs/dev-log/general-sd-regression/.
- Runtime acceptance ledger: .unlazy/general-sd-regression/GATES.md.

The full approved plan was supplied in this chat. The accompanying plan retains
its scope, dependencies, acceptance criteria and approval boundaries.
