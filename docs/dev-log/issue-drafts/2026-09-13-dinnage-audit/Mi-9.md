TITLE: [Dinnage audit Mi-9] The `default:` branch of `drm_response_log_density()` silently returns a likelihood contribution of 1 for an unhandled family
LABELS: audit-dinnage, bug, minor
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4, Appendix A row Mi-9; severity minor).
Supporting working: two independent readers traced all current call sites.

## What Russell found
`drm_response_log_density()`'s `default:` branch returns `Type(0.0)` -- a likelihood contribution of 1 --
for an unhandled family. Both readers who traced it confirmed all 27 call sites are reachable-safe today;
the cost is the *next* family wired into an `mi()` two-point sum before its case is added, which would
silently contribute nothing to the mixture likelihood rather than erroring.

## Where (at 945da24f)
`src/drm_response_kernels.h:138`.

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. The `switch` statement's `default:` case at `src/drm_response_kernels.h:138` is unchanged:
`default: // Non-Gaussian response leaves are added in P3; unreachable in P2 (only the model_type == 1
mi() block calls this helper). return Type(0.0);` -- still a silent fallback rather than a `Rf_error`/CppAD
abort. `git log --oneline 945da24f..HEAD -- src/drm_response_kernels.h` shows no commit changing this
branch. No existing-issue match: `gh issue list --search "drm_response_log_density"` and `--search
"default: branch"` return nothing.

## Proposed fix (Russell's, if stated)
"1 `error()` line" -- replace the silent `Type(0.0)` with an abort naming the unhandled model type, so a
future family added to the `mi()` two-point sum without a case here fails loudly instead of contributing a
spurious log-density of 0.

## Acceptance
- [ ] a test that fails on 945da24f-behaviour and passes after: calling the two-point `mi()` mixture path
      with a model type absent from the switch aborts rather than silently returning a likelihood
      contribution of 1
- [ ] NEWS.md entry crediting the report
