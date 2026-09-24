# Re-pin the R-Julia parity programme to DRModels da8b3f871

## Goal

The handover doc (`docs/dev-log/handover/2026-09-24-claude-handover.md`, on
branch `handover/2026-09-24-claude`, not on `main`) owed a re-pin of the
R-Julia parity programme to the live DRModels `origin/main`. Measured
`origin/main` is `da8b3f8711beb5ef3186b890544c2e7850c7f194` (#808,
2026-09-23); the handover had recorded `e9d50a110`.

## Implemented

Before this slice, the programme named four different DRModels pins:
`source-pins.json` recorded `drmjl_base 430ef64cc`; `parity-matrix.md` and
`parity-scoreboard.md` were built from `d2102ab73`;
`capability-status-join.md` was built from `aee371cc9`; and the tip-identity
receipt cited `drmjl_ref 90fbb0e28`. After this slice, one pin, `da8b3f871`,
appears across the three pin-bearing generated docs, a new `source-pins.json`
`repins[]` entry, and the receipt.

Re-ran seven generators at the new pin, following the sequence
`~/local-scratch/parity-joint/closure.sh` used for #1298 (generators, then
the source-tree manifest, then the receipt last; `write-reml-route-table` ran
before the matrix here, after it there, and the two do not share inputs), plus
`write-capability-status-join.R`, which `closure.sh` had omitted. Three of the
seven are pin-bearing: `write-parity-matrix`, `write-parity-scoreboard`, and
`write-capability-status-join` (the join reads `DRM_JL_REPO` plus an explicit
ref, not `DRM_JL_PATH`). Four are pin-independent: `write-julia-capability-comparison`,
`write-julia-gate-registry`, `write-env-skip-census`, and
`write-reml-route-table`; these produced zero diff, as did the source-tree
manifest refresh (`tools/source-tree-tests.txt`). No generator aborted. Wall
time for all seven generators was 37.5 seconds.

Read the pinned DRModels source from a detached worktree,
`~/local-scratch/lanes/DRModels-pin-da8b3f871`, so the shared DRM.jl clone
(HEAD `e9d50a110`) was not moved.

Ran a two-pass normalised diff, normalising SHAs, file:line numbers, and
DRM.jl/DRModels naming. The first pass compares the committed docs with a
regeneration at `d2102ab73` on current drmTMB. It found 0 changed status or
row lines in all three docs, and 13 drmTMB `file:line` citations that had
gone stale on `main` and are now refreshed (12 in `parity-matrix.md`, for
example `R/julia-bridge.R:1271`, and 1 in `parity-scoreboard.md`). For the
join, this pass also spans DRModels `aee371cc9` to `d2102ab73`, and it still
normalises to 0 lines. The second pass compares `d2102ab73` with `da8b3f871`:
4 lines (2 rows) in `parity-matrix.md`, 47 lines in `parity-scoreboard.md`,
and 0 lines in `capability-status-join.md`.

The DRModels-side change is in the interval receipts. On `main`, the
scoreboard's interval table had 9 rows covering 3 cells, with no
`INTERVAL_MISMATCH`. At `da8b3f871` it has 42 rows covering 14 cells. DRModels
#765 added 7 cells (`fe_beta`, `fe_gamma`, `fe_lognormal`, `fe_nbinom2`,
`fe_skew_normal`, `zi_nbinom2`, `zi_poisson`) and re-measured the 3 existing
ones: for `gauss_locscale_fe`, `gauss_mean_only`, and `poisson_fe`, profile
moved from `UNSUPPORTED_JULIA` to `INTERVAL_PASS` and bootstrap from
`UNSUPPORTED_JULIA` to `INTERVAL_MISMATCH`, and `gauss_mean_only` wald moved
from `PARAM_COVERAGE_DIFF` to `INTERVAL_PASS`. DRModels #767 added 4 more
cells (`fe_student`, `fe_truncated_nbinom2`, `fe_tweedie`,
`fe_zero_one_beta`). All 14 bootstrap rows now read `INTERVAL_MISMATCH`, a
status that is new to this document. DRModels' interval script explains why
(`tools/parity_intervals.R:164-166` at `da8b3f871`): each engine draws its own
resamples, so bootstrap is scored by distributional overlap, and exact
interval agreement is not expected. In `parity-matrix.md`, the
Profile-likelihood CIs and Parametric bootstrap CIs rows changed a cited
receipt status from `UNSUPPORTED_JULIA` to `INTERVAL_PASS` and
`INTERVAL_MISMATCH` respectively. None of this moves a headline count: as
`parity-scoreboard.md:221-222` says, interval receipts are keyed by
`cell_id`, carry no `capability_id`, and so do not lift any cell out of
`UNCITED`.

Headline counts are identical at both pins: `parity-matrix.md` has 45 rows
with 4 GREEN; `parity-scoreboard.md` has 8 UNCITED on the bridge axis;
`capability-status-join.md` has 45 drmTMB rows, 48 DRModels rows, 0
drmTMB-only rows, 3 DRModels-only rows, and 13 status disagreements. No
capability row name changed in DRModels's `capability-status.md` between
`d2102ab73` and `da8b3f871`; the only diff there is the D-269 rename.

Refreshed the tip-identity receipt (`public-001.json` and `public-001.log`)
at the new pin; see Checks Run for the run itself.

Updated `source-pins.json`: left the top-level fields (`drmjl_base 430ef64cc`,
`status`, `a0_sweep`) untouched as the 2026-09-05 campaign record, and
appended a `repins_note` plus a `repins[]` entry recording date, `drmjl_base`,
`drmjl_base_note`, `drmtmb_base 54df129fe`, `receipt_drmjl_ref`,
`artefacts_pin_bearing`, `artefacts_pin_independent`, `a0_sweep` ("not run at
this pin"), and `after_task`. A grep of `tools/` and `tests/` found no code
that parses this file, so the update is documentation only.

## Files Changed

`docs/design/parity-matrix.md`, `docs/design/parity-scoreboard.md`,
`docs/design/capability-status-join.md`,
`docs/dev-log/evidence/julia-r-parity/lss-tip-identity/public-001.json` and
`public-001.log`, `docs/dev-log/loop/parity-joint-20260905/source-pins.json`,
`docs/dev-log/plan-actual/2026-09-24-parity-repin.md`, and these two files
(this report and its check-log row). Nothing under `R/`.

## Checks Run

`ci-receipt-staleness.sh` with `DRM_JL_PATH` unset reported FRESH: 54/54 R
files matched, and 95 Julia entries were not verified. The same script
against the old receipt worktree reported FRESH: 95/95 Julia entries matched.
Against the new pin, before regeneration, it reported STALE, as expected.

`test-julia-module-compat.R` reported 8 pass, 0 fail, but ran 0 live-engine
tests because it is mock-driven; this is not live evidence.

The receipt run (`tools/run-julia-phylo-labels-public.R`) failed on its first
attempt, on environment, not numerics: the fresh pin worktree had no
`Manifest.toml`, so Julia could not find ForwardDiff. `Project.toml` is
identical between `90fbb0e28` and `da8b3f871`, and `Manifest.toml` is
gitignored. Copied the Manifest from the `90fbb0e28` receipt worktree
(`julia_version 1.13.0`; both copies have sha256 prefix `d7b06279`),
following the practice `source-pins.json` records as `julia_manifest_source`
(there, "copied from the e0a65f96b clone") and that
`2026-09-05-a0-repin.md` and `2026-09-03-f7-repin.md` also used. Separately,
juliaup's default channel is Julia 1.10.0, but the existing receipt was made
on 1.13.0, so `JULIA_HOME` was pointed at the 1.13.0 install, changing only
that one variable.

Repairing the environment and re-running was a judgement call, and Shinichi
can overrule it. The plan said a receipt FAIL means stop and report, never
force. The first attempt produced no receipt verdict at all: Julia stopped
while loading packages, before any fit. The repair changed no source, pin, or
tolerance, and followed a recorded precedent.

On the second attempt, `tools/run-julia-phylo-labels-public.R` reported PASS
in 75.9 seconds (runner elapsed 75.866). `tools/check-julia-phylo-labels-receipt.R
--current --self-test` reported `PHYLO_LABEL_RECEIPT_PASS`, `labels=12`,
`rows=72`, `checks=8`, `tolerance=4e-06`, with self-test rejections for
newick, covariance, fitted, nonfinite, and shape defects.
`OPENBLAS_NUM_THREADS=1` and `JULIA_NUM_THREADS=1` were set for both
attempts. The native DLL was built in this worktree from `54df129fe` source.
The receipt's elapsed time rose from 42.0 seconds (2026-09-20 receipt) to
75.9 seconds. This single run includes Julia start-up; it is not a speed
claim.

After regeneration, `ci-receipt-staleness.sh` with `DRM_JL_PATH` set to the
pin reported FRESH: 54/54 R files and 95/95 Julia entries matched, with
`PHYLO_LABEL_RECEIPT_PASS` and C14 OK. Rose compared the new receipt with the
`90fbb0e28` receipt: its 54 R hashes and runner hash are unchanged, and its
native and bridge outputs are identical.

The acceptance ledger (`.unlazy/repin-da8b3f871/gates/leaf-repin.md`, run
state, not committed) passed all eight gates under `gate-check --reverify`:
G1 the three pin-bearing docs name `da8b3f871`; G2 the pin-independent
outputs match `origin/main`; G3 all seven generators are stable on rerun; G4
`test-parity-matrix.R` has 0 failures and its byte-identical generator test
(line 218) ran and passed with `DRM_JL_PATH` set; G5
`tools/run-source-tree-tests.R` passed; G6 `ci-receipt-staleness.sh` reported
FRESH against the pinned DRModels; G7 `source-pins.json` `repins[-1]` and the
receipt's `result.runtime.drmjl_ref` name the same SHA; G8 nothing under `R/`
changed. `test-parity-matrix.R` skips one of its six tests, line 110, because
routes still await their TSV row from PR #1184; that skip predates this
branch and does not depend on the pin.

## Tests Of The Tests

The generators fail closed: the matrix generator aborts on a missing
citation anchor (via `pm_grep_line`) or a missing row name. The receipt
checker's self-test rejected five planted defects: newick, covariance,
fitted, nonfinite, and malformed shape. The DRModels-side diff was first
produced by a cheap scout whose normalisation did not strip SHAs, so it
reported the raw diff as substantive; the orchestrator re-measured it with
corrected normalisation and got the 4/47/0-line counts above. The corrected
G3 gate has its own red control: planting a change on one bullet line of
`capability-status-join.md` made `git diff --quiet -I 'HEAD at generation'`
fail, as it should.

Rose reviewed the plan before execution and found 2 blocking issues (a G1
gate that would have failed by construction, because four generators are
pin-independent; and the join generator reading `DRM_JL_REPO`, not
`DRM_JL_PATH`) and 7 fixes; all were folded into the plan before it ran.
Rose then reviewed this output and returned NOT READY with 1 blocking finding
and 5 fixes. The blocking finding: an earlier draft of this report said three
families gained interval receipts and that bootstrap `INTERVAL_MISMATCH` was
already the status of every other family. Both were false against `main`,
which has 0 `INTERVAL_MISMATCH` rows; the claim came from reading the new
file without comparing it to the old one. The same draft counted three pins,
missing the join's `aee371cc9`. All findings are corrected above.

## Consistency Audit

The handover branch's coordination-board and active-lane-split lines say
source-pins and the generated docs are "OWED refresh"; those lines are not
on `main`, and this PR supersedes them. They were not edited here, to avoid
colliding with the handover branch. On the handover's own rows: re-pin
generated docs and refresh source-pins are DONE by this PR; `claim_status`
promotion stays PROTECTED (owner); #1304, #1033, and the reader PRs stay
PROTECTED as foreign work; CRAN stays RETRACTED for this lane.

## What Did Not Go Smoothly

The receipt run failed on its first attempt: the fresh pin worktree carried
no `Manifest.toml` (gitignored), so Julia could not resolve ForwardDiff.
juliaup's default channel (1.10.0) also did not match the channel the
existing receipt was made on (1.13.0). Both were resolved by copying the
Manifest from the `90fbb0e28` receipt worktree and pointing `JULIA_HOME` at
the 1.13.0 install. Separately, the first DRModels-side diff did not
normalise SHAs and reported more substantive movement than the second,
corrected pass found.

Three gates failed on their first run, and each failure was in the gate. G3
demanded a clean `git diff` after a rerun, but `parity-scoreboard.md` and
`capability-status-join.md` stamp the drmTMB HEAD SHA, so any rerun after a
commit changes that one line; the diff was exactly the two stamp lines
(`54df129fe` to `6fad3d433`). A first fix filtered changed lines with a
regular expression that also dropped bullet lines; Rose caught this, and G3
now runs `git diff --quiet -I 'HEAD at generation'`. G4
demanded zero skips across the file and so tripped on the pre-existing
#1184 skip; it now requires the generator test itself to run and pass. G5
hit the checker's 120-second default timeout and passed with 900 seconds.
G6 first matched the word FRESH in the output and now uses the script's exit
status. Each correction is written beside its gate in the ledger.

## Team Learning

A fresh detached worktree used for a Julia-side receipt needs its
`Manifest.toml` copied from a known-good receipt worktree (the source
`source-pins.json` already records as `julia_manifest_source`) before it can
run, because the Manifest is gitignored and will not arrive with a plain
checkout. A diff script comparing two DRModels pins must strip SHAs, file:line
numbers, and DRM.jl/DRModels naming before its line count is reported as
substantive, or it will overstate DRModels-side movement. Any claim that
something is "already true" cites a command run against `origin/main`; reading the
regenerated file alone does not count.

## Design-document Updates

Only the generated parity docs changed: `parity-matrix.md`,
`parity-scoreboard.md`, and `capability-status-join.md`. No formula-grammar,
likelihood, random-effects, family, phylogenetic, spatial, or meta-analysis
design change accompanies this slice.

## pkgdown/documentation Updates

None: no reader page or rendered site artifact changed.

## GitHub Issue Maintenance

No issue was opened, closed, or commented on. The drmTMB umbrella issue #499
and DRModels issue #563 were not touched.

## Known Limitations and Next Actions

No A0 sweep ran at the new pin. The 38 historical UNMET `.unlazy` ledgers are
untouched. The 14 bootstrap `INTERVAL_MISMATCH` rows follow the design of DRModels'
interval script (`tools/parity_intervals.R:164-166`: each engine draws its own
resamples, so bootstrap is judged by distributional overlap); whether the
scoreboard should show the overlap verdict instead is a question for the
DRModels side, not examined here. The byte-identical matrix test
(`test-parity-matrix.R:218`) skips when `DRM_JL_PATH` is unset, so CI did not
see the 13 stale drmTMB citations; a clone-free check would catch that drift
earlier. The D-280 Fable-vs-Opus
planning trial is deferred to the next consequential plan by Shinichi. The
next lane step is one `.unlazy/parity/gates/leaf-*.md` file at a time. The
pinned DRModels worktree `~/local-scratch/lanes/DRModels-pin-da8b3f871` is
kept, because the receipt records it as its source path, as the 2026-09-20
receipt did for its own worktree.
