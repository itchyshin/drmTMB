# Handover — missing-response arc closeout, 2026-07-12

Meta: Codex → next Codex / Claude / Shinichi · repository `drmTMB` · branch
`codex/mr-t7-missing-response-certification` · parent issue #761.

## Outcome

MR-T0–MR-T6 are merged through PR #770. MR-T7 is branch-local complete and has
three independent DONE verdicts. The authoritative ledger and live runtime
agree on 18 fitted response routes, 18 G3 recovery-verified, and zero G0–G2.
No missing-response implementation remains.

The public capability article now contains both views Shinichi requested:

1. the generated 18-route missing-response execution board; and
2. the preserved 18-family whole-package map with dpars, fixed/random effects,
   structured providers, REML, inference tier, and both missing-data axes.

## Exact local evidence

- capability generator: 30/30 outputs current;
- generator tests: 6/6;
- runtime oracle: 18 verified, zero G0–G2;
- repaired inventory guards: 18/18;
- combined missing-data suite: 1,314 pass, two known beta-binomial warnings,
  two unavailable-Julia skips, no empty test;
- final full suite under `NOT_CRAN=true`: 37,542 pass, 62 known warnings, 24
  unavailable-Julia skips, zero failures, 1,507.1 seconds;
- genuine CRAN-mode `--as-cran` with explicit `NOT_CRAN=false`: 0 errors, 0
  warnings, 0 notes, 5 minutes 51.8 seconds;
- final full pkgdown check/build/check: no problems;
- after-task structure validator and `git diff --check`: pass;
- independent Rose/Noether, Fisher/Curie, and Grace/Pat re-reviews:
  BRANCH-LOCAL DONE.

Full evidence and the repair history are in
`docs/dev-log/after-task/2026-07-12-mr-t7-missing-response-certification.md`.

## Remaining publication sequence

These are external gates, not missing implementation:

1. push the branch and open the focused MR-T7 PR;
2. require the exact-head Ubuntu R-CMD-check and repair any branch-specific
   failure;
3. squash-merge when green and synchronize local `main`;
4. dispatch the final-main three-OS `R-CMD-check.yaml` workflow;
5. dispatch one final-main `rhub.yaml` run with
   `config=clang-asan,clang-ubsan,gcc-asan`;
6. verify the pkgdown deployment and live capability article contain both
   capability views;
7. post all workflow/deployment URLs to #761, close it, and prove tracked-clean
   synchronized `main`.

Issue #761 is the authoritative post-merge record because final-main workflows
run after this tree is merged. Superseded CRAN PR #763 is closed; #764 already
merged the identical incoming-pretest fix. The `v0.5.0` tag remains frozen at
`095409c0`, and CRAN acceptance remains a separate external decision.

## Claim boundary

G3 means fixed-seed 25% MCAR recovery for every fitted dpar on the explicitly
named route. It is not replicated coverage. This arc does not add G4/G5,
blanket random/structured masking, response plus `mi()`, MNAR, non-Gaussian
REML, a public function, or formula grammar.

## Preserved user work

Do not stage or remove the untracked post-CRAN planning draft, G2 shard logs,
Ayumi drafts, recovery probes, or `scratchpad/function-map-draft/`. They are
unrelated user-owned work.
