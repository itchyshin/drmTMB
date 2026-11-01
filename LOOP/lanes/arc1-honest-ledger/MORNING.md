# Morning report: drmTMB parity Arc 1 (written before the overnight run; updated as work lands)

Shinichi left at ~16:55 MDT 2026-09-24: "work autonomously and keep working to finish". Overnight the lane runs
every reversible step and stops only at: merge, GitHub comment or close, claim_status change, a run over 30 min
(D-139), or a refusal that would remove a working route.

## Where things stand (16:55 MDT)
- Draft PR-A #1425 (part 1: honest-state column, honesty gate, pin helper, interval cellmap, admission census,
  model-identity sweep, issue census, #1304 note): CI green. Honesty gate at the pin: uncited=0 defect=0.
- Draft PR-D #1426 (#1304 evidence fold with provenance): CI green.
- A3a (R-side refusals and gate rows in R/julia-bridge.R) built and under adversarial review (workflow
  wf_614d50ff-9ff). Measured: 22 routes that crashed inside Julia or fitted the wrong model are now refused in R
  with named gates; no working route removed (reviewer confirmed); gate table 16 -> 29 rows; census 61 -> 39 ADMIT.
- Corrections made on evidence, flagged for your review:
  - truncated_nbinom2() + hu is NOT refused: at this pin it fits the same model on both engines (the plan's
    reason to refuse it was stale).
  - The census script had been exercising the installed drmTMB (an older build) when run as a script; fixed
    (load_all), census regenerated from the dev tree. PR-A's first census numbers came from the installed build.
  - One local-only pre-existing test error on main (test-julia-bridge.R, fixef on a mock julia fit) is excluded
    by name from one gate; CI passes it.

## Overnight progress
- 19:00 MDT: A3a workflow done (12 agents, 3 adversarial review rounds, ~3.5 h). Beyond the plan, the reviewers
  found and the builder confirmed live two more routes that silently fitted a different model: (1) a Gaussian
  structured marker (phylo/relmat/animal/spatial) plus an ordinary bar, where the bridge dropped the ordinary
  effect (df 4 vs native 5); (2) meta_V() plus a random effect, where the bridge dropped the study effect (df 3 vs
  4). Both are now refused in R with gates. A first version of the fix over-reached and blocked the working
  multi-component sd() router; round 2 caught it and the router is restored (identical logLik on both engines).
  Round 3: no blocking findings; two message/text fixes are in a short finish pass.

## Waiting for you (G3)
- Close or comment on #499, #1116, #1118, #1146, #1201, #1224 (drafts in docs/dev-log/loop/arc1-honest-ledger/issue-census.md).
- Comment on #1304 (draft in the PR-D provenance note).
- Merge order when you are ready: #1425, then #1426 (regenerate tools/source-tree-tests.txt and
  inst/extdata/env-skip-census.tsv on whichever merges second), then PR-B (part 2).

## Overnight plan
A3a fix round -> commit -> A3b workflow (ledger rows for 8 admitted-but-unledgered cells, T5 summary() note,
fences signed) -> close workflow (regenerate, live sweep re-run ~23 min, tip receipt LAST, D1-D7, Rose/Noether/
Fisher review, Melissa, after-task) -> draft PR-B stacked on #1425.
