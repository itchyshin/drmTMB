# SD-regression merge and receipt closeout, 2026-11-04

Reader: Shinichi and the next maintainer checking the merged lane.

## 1. Goal

Merge DRModels.jl PR #1250, then drmTMB PR #1670, verify their main workflows, and refresh the Gaussian phylogenetic label receipt against the new Julia main. Calibration remains deferred.

## 2. Implemented

Both PRs merged through the existing ordered gates. The Julia PR used GitHub auto-merge; the existing chain script waited for that merge before invoking `pr_merge_when_green.sh` for the R PR. No source fix was needed during this pickup.

The receipt refresh retains the previous receipt, runner log and checker log under `historical-pre-1250-1670-2026-11-04/`. A failed environment attempt is retained under `failed-attempt-missing-julia-2026-11-04/`. The replacement runs the existing example against Julia main `f4fa3aed451636b6ffa442ce2632515513d23b1f` and R main `8d30ed99a1d6c621dc23ce7fbb067ce7dc4cdcee`, without changing a runner, tolerance or scientific admission rule.

## 3a. Decisions and Rejected Alternatives

Kept the inherited merge order and existing live gate, rather than starting a duplicate gate. Refreshed the receipt even though the R main CI job passed: CI cannot verify Julia hashes when `DRM_JL_PATH` is unset. With that path set to the new Julia main, 36 of the 113 previously recorded Julia source entries differ.

No full-suite main dispatch was added. The configured Julia push workflow builds and deploys docs; the R push workflow checks receipt staleness. Full package suites ran on the PRs. Their scope is stated separately below.

Assumptions made without asking: reused the clean receipt-refresh checkout handed over by Claude, creating `codex/sd-merge-receipt-20261104` from fetched R main. The scratch Julia main clone was clean before its fast-forward. Foreign changes in the merge-probe clone were preserved.

## 4. Files Touched

- `docs/dev-log/evidence/julia-r-parity/lss-tip-identity/public-001.json`, `public-001.log`, `checker-001.log`: refreshed evidence.
- `docs/dev-log/evidence/julia-r-parity/lss-tip-identity/historical-pre-1250-1670-2026-11-04/`: previous evidence, retained verbatim.
- `docs/dev-log/evidence/julia-r-parity/lss-tip-identity/failed-attempt-missing-julia-2026-11-04/`: failed environment attempt, retained.
- `docs/dev-log/check-log.d/2026-11-04-sd-merge-closeout.md` and this report.
- `docs/dev-log/evidence/julia-r-parity/lss-tip-identity/closeout-assessment-20261104.json`: separate prose assessment.
- Local status receipts and the original pickup checkpoint in `/Users/z3437171/Documents/Codex/2026-11-03-sd-merge-pickup/`.

The clean scratch Julia main clone was fast-forwarded to the merged ref. No engine, formula, public API, workflow, NEWS, protected lane file or foreign dirty file was edited.

## 5. Checks Run

### Merge evidence (UTC)

| PR | Checked head | Merged at | Merge commit |
| --- | --- | --- | --- |
| [DRModels.jl #1250](https://github.com/itchyshin/DRModels.jl/pull/1250) | `d8c8f8137d492d424787052dd746c3a291fcfa11` | 2026-11-04 02:56:35 | `f4fa3aed451636b6ffa442ce2632515513d23b1f` |
| [drmTMB #1670](https://github.com/itchyshin/drmTMB/pull/1670) | `0cecd7a9ab720a77d33ef992bbfe0f7022ad954c` | 2026-11-04 02:57:02 | `8d30ed99a1d6c621dc23ce7fbb067ce7dc4cdcee` |

| PR | Settled check names | Conclusions |
| --- | --- | --- |
| #1250 | changes; Julia 1 shards 1/4, 2/4, 3/4, 4/4; ci-ok | SUCCESS for each |
| #1250 | docs; docs-preview; documenter/deploy | SUCCESS for each |
| #1250 | scaling-sweep; docs-deploy | SKIPPED for each |
| #1670 | os-matrix; source-tree tests (blind spot); ubuntu-latest (release) shards 1/4, 2/4, 3/4, 4/4 | SUCCESS for each |

Julia PR evidence: [CI run 41743509803](https://github.com/itchyshin/DRModels.jl/actions/runs/41743509803) and [docs run 41743509831](https://github.com/itchyshin/DRModels.jl/actions/runs/41743509831). R PR evidence: [run 41608213257](https://github.com/itchyshin/drmTMB/actions/runs/41608213257) and the chain gate's printed settled-check table. The gate reported `MERGED #1670 after verifying every check settled green`.

### Main after the two merges

- Julia [Documenter run 41763957656](https://github.com/itchyshin/DRModels.jl/actions/runs/41763957656), on `f4fa3aed4`: SUCCESS. Docs build, rendered documentation audit and deploy passed; preview skipped. TagBot skipped.
- R [receipt-staleness run 41764001394](https://github.com/itchyshin/drmTMB/actions/runs/41764001394), on `8d30ed99a`: SUCCESS. Its Julia source hashes were not verified because the CI job has no pinned Julia checkout.

### Local receipt validation

- `tools/run-julia-phylo-labels-public.R` completed with `PHYLO_LABEL_PUBLIC_PASS` in 72.337 seconds on Julia 1.13.0, one Julia thread and one BLAS thread.
- `Rscript tools/check-julia-phylo-labels-receipt.R .../public-001.json --current`: `PHYLO_LABEL_RECEIPT_PASS labels=12 rows=72 checks=8 tolerance=4e-06`.
- `DRM_JL_PATH=<pinned-new-Julia-main> bash tools/ci-receipt-staleness.sh`: FRESH, 64/64 R and 114/114 Julia source entries match, runner hash matches, C14 receipt equivalence and C17 current-source compatibility pass.
- All eight checks pass. Native versus direct differences are at most 7.74e-12 across coefficients and log likelihood; bridge versus direct differences are zero. Likelihood oracle errors are 7.82e-14 or smaller. These differences and oracle errors equal the previous receipt exactly.
- The receipt and this report accompany a follow-up PR. Its merge/check receipt is recorded in the final pickup status files and chat after the gate finishes; it is not evidence for a rerun of the full package suites.

## 6. Tests of the Tests

The pre-refresh `tools/ci-receipt-staleness.sh` run, with `DRM_JL_PATH` set to the new Julia main, reports STALE and identifies the changed Julia files. It simultaneously reports 64 matching R files and a structural receipt pass. This distinguishes a stale source record from a malformed numerical result. The post-refresh run passes the same checker with the same Julia path and tolerance.

No new tests or mutation checks were needed for generated evidence. The retained environment failure demonstrates that the live runner records ERROR and exits nonzero when Julia cannot be found.

## 7a. Issue Ledger

PRs #1250 and #1670 are merged. The receipt refresh accompanies this report in a separate PR. No new implementation issue was opened. Calibration G5 and the REML objective policy D-342 remain deferred or awaiting the owner's separate decision, as recorded in the handover.

## 8. Consistency Audit

Compared PR heads, settled checks, merge commits and merge times with the chain log and main run SHAs. Checked both workflow trigger policies before interpreting the lack of push-triggered full-suite jobs. Checked the receipt's R and Julia source entries separately. The R native `src/` files are unchanged between the previous refresh checkout and the merged R main.

Rose perspective, self-review: merge evidence supports the ordered merges and configured main workflows. It does not support a new coverage, calibration or broad parity claim. No independent spawned reviewers ran in this pickup.

## 9. What Did Not Go Smoothly

The first live receipt attempt could not locate Julia because the executable was absent from this shell's PATH. It stopped after 3.465 seconds and recorded ERROR. The successful retry supplied `JULIA_HOME` explicitly. No package or runner edit was made to hide the environment error.

`graft` was unavailable in this shell. The receipt runner and checker were read directly at their named paths. The report compiler initially listed unrelated dirty brain files because it was invoked outside the R checkout; those paths were removed from this report and were never staged.

## 10. Known Residuals

The handover discloses two tolerance changes already present in #1250: the Poisson oracle Newton cutoff changed from 1e-12 to 1e-10 relative; the crossed Binomial oracle accepts a line-search stall only when `dot(grad, step) < 1e-9`. This pickup did not change or independently recalibrate either threshold.

Inherited numerical limits, not investigated in this pickup: plain NB2 `animal(1|g)` stalls at a worse optimum on about 35 to 50 percent of fixture draws; some weakly identified mesh Binomial draws do not converge; one Binomial SD test reported convergence with an SD intercept of -26.9; two boundary-heavy ZeroOneBeta slope seeds stop at the standard-error Hessian despite converged estimates; NB2 stores its log likelihood from the last objective evaluation, differing by about 1e-5.

Inherited output limits: Julia stored-row `predict()` is population-level; phylogenetic, mesh, crossed and REML structured routes are not exported through the conditional bridge. D-342 remains unresolved. None of these limitations was removed by passing CI or refreshing this one receipt.

## 11. Team Learning

Memory receipt: loaded the repo AGENTS, handover, LOAD-FIRST route manifest, merge-when-green skill and efficiency protocol. Their ownership, exact-head verification, source-bound receipt and narrow-claim rules shaped this pickup. Brain search located the prior SD lane log; repository and live GitHub state supplied technical evidence. No new durable scientific decision was made.

Golden Set: no engine or formula fix was made, so numerical bug regression checks were not in scope. The relevant merge-wait failure class was covered by the existing gate's settled-check table. The source-hash negative control above covers the receipt-staleness class.

A receipt can pass main CI while its Julia-side manifest is stale. When Julia changes, run the checker locally against the pinned new Julia main before treating the receipt as current for both repositories.

## 12. Cross-Product Coverage

Covers: the two ordered PR merges, their configured post-merge main workflows, and one shuffled-row Gaussian phylogenetic location-scale-scale workflow across native TMB, Julia bridge and direct Julia, including label transport and row restoration.

Does NOT cover: calibration G5, interval coverage, a full family-by-provider parity grid, new releases, a new full-suite main dispatch, removal of inherited numerical or export limitations, or other lanes' work.
