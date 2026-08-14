# Session Handover: response-missingness formula surface

Meta: 2026-08-14 · from Codex · target Claude · working branch
`codex/response-missing-formula-surface` at `e376eea32`.

## Critical Context

This is a response-only missing-data programme. The public call remains
`drmTMB(..., missing = miss_control(response = "include"))`; predictors,
weights, offsets, grouping inputs, structure inputs, MNAR, MI, coverage claims,
and Julia parity are out of scope.

The branch is clean and pushed. Do not describe the work as finished for every
formula: the generated matrix has 185 `formula_validated` cells, 15 remaining
univariate ML cells, and 90 bivariate cells needing formula evidence. Of those
bivariate cells, 40 are REML and one is dense known-`V` work; these are separate
programmes, not a reason to delay the remaining univariate ML cells.

This is one of several live drmTMB lanes. The snapshot pointer is deliberately
unchanged: use the coordination board and do not replace a sibling lane's
pointer.

## Goals / mission

Give every currently admitted native-TMB response formula an earned,
formula-cell claim for `miss_control(response = "include")`. A cell needs both
an observed-data masking/oracle check (G2) and a known-DGP recovery check (G3).
The public surface must be generated from the formula matrix, not stated as a
family-wide promise.

## What Was Accomplished

- Built and maintained the generated response-mask formula inventory:
  `tools/response_mask_formula_inventory.py` and
  `docs/dev-log/dashboard/capability-ledger/response-mask-formulas.tsv`.
  The generator check currently passes.
- Extended recovery-validated response masking across many univariate ML
  structured cells, including Poisson and NB2 provider/interactions,
  Beta animal effects, Student spatial/phylogenetic effects, hurdle NB2 relmat,
  and zero-one-beta `mu` plus phylogenetic/animal `sigma` effects.
- Each completed cell was tested using the same narrow contract: direct
  observed-data objective check, numerical gradient, sentinel invariance,
  masked-versus-observed-only agreement, and known-DGP parameter recovery.
- The branch has no local changes and is exactly synchronized with
  `origin/codex/response-missing-formula-surface`.

## Current Working State

- Working: common response-mask infrastructure and the generated inventory.
- In progress: remaining univariate ML formula cells; begin with grouped
  zero-one-beta endpoints rather than a separate edit/run/commit for every
  cell.
- Not working / deliberately deferred: bivariate response components, dense
  known-`V`, and REML. They need route-level observed-data likelihood/oracle
  work. Do not copy univariate evidence into them.

### Remaining univariate ML cells

| Family | Parameter / geometry | Cell IDs |
| --- | --- | --- |
| Gaussian | `mu`, phylogenetic interaction | `mc-0321` |
| zero-one-beta | `sigma`: relmat, spatial, phylogenetic interaction | `mc-0595`, `mc-0596`, `mc-0597` |
| zero-one-beta | `zoi`: phylo, animal, relmat, phylogenetic interaction | `mc-0603`, `mc-0604`, `mc-0605`, `mc-0607` |
| zero-one-beta | `coi`: phylo, animal, phylogenetic interaction | `mc-0613`, `mc-0614`, `mc-0617` |
| zero-inflated NB2 | `mu` spatial; `sigma` phylogenetic interaction | `mc-0641`, `mc-0653` |
| zero-inflated Poisson | `mu` spatial; `zi` spatial | `mc-0662`, `mc-0667` |

## Key Decisions & Rationale

- **Batch by reusable likelihood harness.** The previous per-cell cadence is
  what made progress look stalled. Finish the 15 univariate cells in coherent
  batches: zero-one-beta scale/atom endpoints, zero-inflated counts, then the
  Gaussian interaction.
- **Bivariate ML is a route-level task.** Build a parameterised component-level
  observed-data harness before marking any bivariate rows. Missing `y1`, missing
  `y2`, complete pairs, and neither observed are distinct likelihood patterns.
- **REML is separate.** It needs its own observed-response restricted-likelihood
  derivation and comparator. ML passing does not promote a REML cell.
- **DRAC is later.** These G2/G3 deterministic local fixtures do not need a
  campaign. Before a claim-bearing DRAC recovery run, do one local pre-run per
  likelihood mechanism and record measured runtime. Shinichi approved compute,
  but retain failures and use larger sample sizes for non-Gaussian models.

## Plans / roadmap

1. Close the 15 univariate ML cells with three reusable test/oracle batches.
2. Create the bivariate ML route-level harness and use it across ordinary
   bivariate cells.
3. Start a separate REML response-missingness design/derivation arc.
4. Only then prepare a compact DRAC array for the claim-bearing recovery
   campaign; this is recovery evidence, not an inference/coverage programme.

## Landing State

`~/shinichi-brain/tools/handoff_gate.sh` did not exit clean because it reports
431 unpushed commits on *other* local branches. This branch is not one of them:
it is clean and `git rev-list --left-right --count @{upstream}...HEAD` is `0 0`.
Those other branches are protected foreign work and must not be pushed, cleaned,
or reconciled from this handover.

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `codex/response-missing-formula-surface` at `e376eea32` | yes | yes | none | CARRIED-OVER |
| Other branches reported by `handoff_gate.sh` | mixed | no | mixed | PROTECTED FOREIGN |

The carried-over branch is deliberately unmerged because it is a bounded
implementation/evidence lane, not a release or a completed broad claim.

## Files Created / Modified

The branch differs from `origin/main` in the following paths. Do not stage
unrelated files from another checkout.

- `R/drmTMB.R`; `man/drmTMB.Rd`; `docs/design/149-missing-data-design.md`.
- `tools/response_mask_formula_inventory.py`; `tools/capability_ledger.py`;
  `tools/tests/test_response_mask_formula_inventory.py`;
  `tools/run-response-mask-structured-q1-recovery.R`;
  `tools/run-response-mask-structured-q1-recovery-narval.sh`;
  `tools/submit-response-mask-structured-q1-recovery-narval.sbatch`.
- `docs/dev-log/2026-08-14-response-mask-formula-inventory.md`;
  `docs/dev-log/2026-08-14-structured-response-mask-recovery-prerun.md`;
  `docs/dev-log/2026-08-14-structured-response-mask-recovery-totoro.md`;
  `docs/dev-log/check-log.md`;
  `docs/dev-log/dashboard/capability-ledger/response-mask-formulas.tsv`;
  `docs/dev-log/dashboard/estimator-surface-conformance.tsv`; this handover.
- Tests: `tests/testthat/test-animal-relmat-gaussian.R`,
  `test-beta-phylo-direct-sd.R`, `test-control.R`,
  `test-count-multiprovider-structured-mu.R`, `test-count-structured-mu.R`,
  `test-cumulative-logit.R`, `test-hurdle-nbinom2-relmat-response-mask.R`,
  `test-missing-response-beta.R`, `test-missing-response-binomial.R`,
  `test-missing-response-biv-gaussian.R`, `test-missing-response-boundary.R`,
  `test-missing-response-continuous.R`, `test-missing-response-encoded.R`,
  `test-missing-response-gaussian.R`, `test-missing-response-nbinom2.R`,
  `test-missing-response-poisson.R`, `test-missing-response-recovery.R`,
  `test-missing-response-truncated-nbinom2.R`,
  `test-nbinom2-sigma-structured-recovery.R`,
  `test-nongaussian-structured-mu-slope.R`, `test-phylo-gaussian.R`,
  `test-phylo-interaction.R`, `test-poisson-mean.R`,
  `test-positive-continuous-structured-mu.R`, `test-reml-binomial-coxreid.R`,
  `test-reml-heteroscedastic.R`, `test-reml-phylo-location.R`,
  `test-reml-structured-location.R`, `test-spatial-gaussian.R`, and
  `test-zero-one-beta.R`.

## Blockers / Open Questions

- No technical blocker for the 15 univariate cells.
- Bivariate and REML require a new harness/derivation, rather than another
  family-level loop.
- The global handoff gate's foreign-branch warning remains for their owners;
  it does not make this pushed branch unavailable to Claude.

## Gotchas / Failed Approaches

- Do not claim all response formulas are ready from the earlier family-level
  18-route work. Effect geometry and estimator matter.
- Do not silently drop rows with missing responses; test retained-row maps,
  `nobs()`, fitted values, and `NA` residuals alongside objective equality.
- Do not turn local recovery fixtures into coverage or inference claims.
- The lane preflight helper is a shell script: use
  `bash ~/shinichi-brain/tools/lane_preflight.sh .`, not `python3 ...`.
- The shared primary checkout is not the implementation location. Work only in
  `/private/tmp/drmtmb-response-missing-formula-surface` unless state has been
  reconciled first.

## How to Resume

Claude should first classify this handover against the live state as `OWED`,
`DONE`, `RETRACTED`, or `PROTECTED`, then work only on the OWED univariate ML
batch. Claude can plan/refactor/prose and run logic checks; use Codex later for
live compiler-heavy fits or the DRAC campaign.

```sh
cd /private/tmp/drmtmb-response-missing-formula-surface
bash ~/shinichi-brain/tools/lane_preflight.sh .
git status --short --branch
python3 tools/response_mask_formula_inventory.py --check
```

Safe first verification:

```sh
python3 tools/response_mask_formula_inventory.py --check
```

**Paste-ready prompt:**

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-14-claude-handover-response-missing-formulas.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

## Mission-control summary

| Lane | Branch / PR | State | What shipped | Next by leverage |
| --- | --- | --- | --- | --- |
| Response-missing formula surface | `codex/response-missing-formula-surface` at `e376eea32`, pushed; no PR | CARRIED-OVER | 185 formula-validated cells and generated matrix | Finish 15 univariate ML cells in three harness batches |
| Bivariate response masking | not started on this branch | OWED later | no broad claim | Parameterised component-level observed-data harness |
| REML response masking | not started on this branch | OWED later | no broad claim | Restricted-likelihood derivation and exact comparator |
| 0.7 CRAN / reader-contract lanes | separate owners; see coordination board | PROTECTED | unrelated | Do not touch |

