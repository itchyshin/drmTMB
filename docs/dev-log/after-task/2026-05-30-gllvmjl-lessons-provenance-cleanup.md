# After Task: GLLVM.jl Lessons Provenance Cleanup

## Goal

Turn the untracked GLLVM.jl lessons memo into a conservative repo artifact that
records provenance, current `drmTMB` status, and guardrails without treating
sister-repo benchmark results as direct `drmTMB` claims.

## Implemented

`docs/dev-log/lessons-from-gllvmjl-for-drmtmb.md` now reads as a
status-checked scouting memo. It records the local source checkouts, current
commits, dirty state, visible license, no-code-copied boundary, and future
`inst/COPYRIGHTS` requirement for any actual code port.

The memo now classifies the original lessons as already absorbed or
source-checked, plausible future design gates, hypotheses, or outside current
`drmTMB` scope. It removes the stale implementation-from-scratch framing for
sparse `phylo()`, removes the stale claim that Gaussian starts are
intercept-only zero slopes, and keeps relaxed-clock syntax fenced as a design
task rather than a proposed formula grammar change.

## Mathematical Contract

No equations, likelihood code, formula grammar, or fitted behavior changed.
This task changed a dev-log memo only. The cleanup keeps `sigma`, `rho12`,
`sd(group)`, `phylo()`, and `spatial()` as the current terms and warns against
introducing `phylo_relaxed()` or `tau ~` from the memo.

## Files Changed

- `docs/dev-log/lessons-from-gllvmjl-for-drmtmb.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-30-gllvmjl-lessons-provenance-cleanup.md`

## Checks Run

```sh
git -C /Users/z3437171/Dropbox/Github\ Local/gllvmTMB.jl rev-parse --short HEAD
git -C /Users/z3437171/Dropbox/Github\ Local/gllvmTMB.jl status --short --branch
git -C /Users/z3437171/Dropbox/Github\ Local/gllvmTMB-julia-bench rev-parse --short HEAD
git -C /Users/z3437171/Dropbox/Github\ Local/gllvmTMB-julia-bench status --short --branch
find /Users/z3437171/Dropbox/Github\ Local/gllvmTMB.jl /Users/z3437171/Dropbox/Github\ Local/gllvmTMB-julia-bench -maxdepth 2 \( -iname 'LICENSE*' -o -iname 'COPYING*' \) -print
rg -n 'note-to-russell|intercepts-only with zero|Add a `DATA_SPARSE_MATRIX|10×|100×|coverage improves|preserves the inference exactly|Expected gain|Suggested drmTMB path' docs/dev-log/lessons-from-gllvmjl-for-drmtmb.md
rg -n 'phylo_relaxed|tau ~|GLLVM.jl speedups as `drmTMB` speedups|GLLVM.jl coverage as `drmTMB` coverage|inst/COPYRIGHTS' docs/dev-log/lessons-from-gllvmjl-for-drmtmb.md
gh issue list --repo itchyshin/drmTMB --state open --search 'GLLVM.jl lessons provenance sparse phylo warm start bootstrap' --limit 20 --json number,title,state,url,labels
air format docs/dev-log/lessons-from-gllvmjl-for-drmtmb.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-gllvmjl-lessons-provenance-cleanup.md
git diff --check
```

The source-state checks found the local `GLLVM.jl` checkout path
`gllvmTMB.jl` at commit `6a0d090` with a clean `main...origin/main`;
`gllvmTMB-julia-bench` was at commit `9de254a` with a dirty working tree. Only
the local `GLLVM.jl` checkout exposed a local `LICENSE` file, and it is MIT
licensed by Shinichi Nakagawa.

The stale-overclaim scan returned one intentional `note-to-russell.md` hit
documenting that the cited file was absent; the other stale implementation and
overclaim phrases were gone. The guardrail scan found only intentional wording
that forbids `phylo_relaxed()`, `tau ~`, direct transfer of GLLVM.jl speed or
coverage claims, and code copying without `inst/COPYRIGHTS`. The issue search
found no exact open issue that needed an update. `air format` and
`git diff --check` passed.

## Tests Of The Tests

No tests were added because this was a prose/provenance cleanup. The useful
validation was source-state inspection, license inspection, stale-overclaim
searches, and guardrail searches.

## Consistency Audit

The cleaned memo now points to the after-task reports that already source-check
or supersede parts of the original memo:

- `2026-05-29-claude-gllvmjl-transfer-audit.md`
- `2026-05-29-sparse-phylo-source-map.md`
- `2026-05-29-gaussian-start-contract.md`
- `2026-05-29-bootstrap-log-scale-positive-intervals.md`

No README, NEWS, pkgdown, roxygen, or formula grammar updates were needed
because no user-facing behavior changed.

## GitHub Issue Maintenance

The search for GLLVM.jl lessons, provenance, sparse phylogeny, warm starts, and
bootstrap found no exact open issue that needed an update.

## What Did Not Go Smoothly

The original memo cited `report/note-to-russell.md`, but that file was absent
from both local sister checkouts. The cleaned memo records that absence and
uses source files plus `comparison-final.md` as the future-reading path.

## Team Learning

Ada kept the task to provenance cleanup. Jason checked the sister-repo evidence
map. Rose removed stale implementation instructions and unsupported transfer
claims. Grace kept the copyright boundary visible without adding a dependency.

No spawned subagents edited files.

## Known Limitations

This cleanup does not benchmark sparse `phylo()` scaling, implement
`sigma ~ 1` profile-out, add EM/SQUAREM, create relaxed-clock syntax, or make
any speed or coverage claim. It also does not resolve the dirty state in
`gllvmTMB-julia-bench`; future benchmark users must re-check that repository.

## Next Actions

1. Keep using the cleaned memo as a routing map, not an implementation plan.
2. If sparse-phylogeny speed becomes the next lane, start with a benchmark/API
   design slice for current `drmTMB` source.
3. If optimizer geometry becomes the next lane, design `sigma ~ 1` profile-out
   with equivalence tests before code changes.
