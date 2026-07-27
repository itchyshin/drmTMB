# Session Handoff: Lane B E1 exact-binding recovery

## Landing state

E1 is a documentation-only packet on the E0 branch. It adds a corrected #857
source map, an eight-row non-canonical count-q1 source-target matrix, a
planning-only adjudication, validation receipt, reconciliation, and after-task
report. No code, canonical binding table, smoke receipt, schedule, pregrid,
compute, ledger, public/default behavior, association, bootstrap, or
missing-response route changed.

`handoff_gate.sh` was run before the E1 commit. Its only Lane-B unlanded state
was this seven-file staged packet; it also reported protected foreign unpushed
branches, which this lane did not modify:

| Branch | Why carried over | Owner-safe resume command |
| --- | --- | --- |
| `claude/arc-a-external-comparator-evidence` | 12 unpushed; foreign external-comparator lane | `git -C '/Users/z3437171/Dropbox/Github Local/drmTMB' switch claude/arc-a-external-comparator-evidence` |
| `codex/arc-d-design1-overflow-guard` | 3 unpushed; foreign historical Design-1 lane | `git -C '/Users/z3437171/Dropbox/Github Local/drmTMB' switch codex/arc-d-design1-overflow-guard` |
| `codex/arc6-6-bernoulli-nb2-plan` | 2 unpushed; foreign association plan | `git -C '/Users/z3437171/Dropbox/Github Local/drmTMB' switch codex/arc6-6-bernoulli-nb2-plan` |
| `codex/sd-bootstrap-r999-diagnosis` | 11 unpushed; foreign diagnostic | `git -C '/Users/z3437171/Dropbox/Github Local/drmTMB' switch codex/sd-bootstrap-r999-diagnosis` |
| `codex/staged-eta-godambe-se` | 3 unpushed; foreign association lane | `git -C '/Users/z3437171/Dropbox/Github Local/drmTMB' switch codex/staged-eta-godambe-se` |

## Result

The accepted proposed candidates are `mc-0410`--`mc-0413`, `mc-0435`,
`mc-0441`, `mc-0448`, and `mc-0452`: all name the direct `0 + x` slope-SD
target, truth 0.45 on the relevant log-mu scale, archived DGP/formula/source,
and one retained 8-by-20 information rung. They are not canonical bindings or
profile/coverage evidence. `mc-0411` retains its 2/80 `pdHess = FALSE` caveat.

## Reviews and checks

Fisher: CONDITIONAL GO; preserve the proposed-only and lower-bound caveats.
Rose: GO; commit before calling the packet landed. `Rscript
tools/verify-lane-b-e0-readiness.R`, TSV structure checks, and `git diff
--check` passed; `pregrid_authorized=FALSE` remains true.

## Source-map correction

The authoritative Design-2 implementation is #857 / `f6cc6fe52250827d1b9cfc54912e4954b7093f50`.
`docs/design/246-marginal-bootstrap-coverage.md` is unrelated Arc-A material
and must not be cited as Design 2. The trace contract applies to the full
`tmbprofile` route only; no clamp claim transfers to endpoint profiles.

## CARRIED-OVER / next gate

**No execution authority carries over.** Before any binding-table edit, local
smoke, schedule, or pregrid request, review the eight candidate strings against
their archived functions and complete reviewed exact bindings for every
non-foreign E0 candidate. A future pregrid packet must then supply source SHA,
manifest hashes, 150-attempt schedule, resources, output path, validation
command, and no-ledger boundary. Shinichi must explicitly approve Totoro/DRAC
after that packet.

## Resume prompt

```text
Rehydrate from docs/dev-log/handover/2026-07-27-codex-lane-b-e1-handover.md.
You are Lane B only. Review, do not yet alter, the proposed count-q1 slope
contracts against their archived source functions and the remaining E0 cohort.
Do not create canonical bindings, run a smoke, schedule a pregrid, request
compute, or touch association/bootstrap/missing-response/ledger/public routes
without Shinichi's later explicit approval.
```
