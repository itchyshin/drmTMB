# Predecessor instrument salvage — what to reuse, what to retire

**Date:** 2026-08-09 · **Lane:** Claude task 1, Stage A · **Baseline:** `origin/main@ac363cadb`

## The salvage finding

The handover instructed me to salvage instruments from `cursor/07-cran-readiness` and
`cursor/07-tarball-clean`. Measured, both branches are **behind main and carry only two
branch-only commits each** — because **their work already merged**. Every instrument
they built is on `main` today:

| Branch | Branch-only commits | Drift | State |
| --- | --- | --- | --- |
| `cursor/07-cran-readiness` (`bff30dded`) | 2 | 39 behind | instruments merged; nothing to cherry-pick |
| `cursor/07-tarball-clean` (`f065fc905`) | 2 | 37 behind | instruments merged; nothing to cherry-pick |

**So there is no salvage operation to perform.** The instruments need no porting. What
they need is the opposite: an explicit statement of which parts are reusable tooling
and which parts are expired evidence — because both live in the same directory and
look alike. That statement is
[`STALE-EVIDENCE-QUARANTINE.md`](../release/0.7.0-cran-gate/STALE-EVIDENCE-QUARANTINE.md),
written into the evidence directory itself so it is unmissable.

## Instrument reuse map

### REUSE — tooling, structure, conventions

| Instrument | Path | Reuse as |
| --- | --- | --- |
| Fail-closed ledger schema | `docs/dev-log/release-audits/2026-08-07-07-cran-release-ledger.json` | Field structure for the new ledger. **Copy the shape, not the values.** |
| Gate checker | `~/shinichi-brain/tools/cran_release_gate.py` | The executable gate. Selftest re-run 2026-08-09: **14/14 negative controls fail closed**. Healthy. |
| Ledger template | `~/shinichi-brain/protocols/cran-release-ledger.template.json` | Canonical starting point. |
| Tarball inventory format | `docs/dev-log/release/0.7.0-cran-gate/tarball-inventory.txt` | 922-path listing convention + forbidden-path scan. Regenerate for the candidate; the format is good. |
| Freeze-notes structure | `…/FREEZE-NOTES.md` | Excellent template — source commit, clean status, hash, size, inventory count, check status, installed size, exercises, independent verification, rungs. Reuse verbatim as a skeleton. |
| Platform matrix table | `…/platform/PLATFORM-NOT-READY.md` | Cell-by-cell matrix with per-job evidence links. Good shape for Stage B4. |
| Product-contract structure | `…/2026-08-07-07-product-contract.md` | Section layout reused; **contents superseded** (see below). |
| Rights-skim structure | `…/2026-08-07-07-rights-skim.md` | Section layout reused; contents re-derived. |
| Policy-refresh doc | `…/2026-08-07-07-cran-policy-refresh.md` | Retained as the instrument for Stage B's fresh policy read. |
| `cran-comments.md` draft | `cran-comments.md` (build-excluded) | Already honestly self-limiting — it states it is *not* submission-ready evidence. Keep as the Stage B starting draft. |

### RETIRE — evidence bound to a superseded hash

| Evidence | Why retired |
| --- | --- |
| `tarball.sha256` / `tarball.size.txt` (`2e5234bd…`, 9,831,204) | Built from `ad475cc39`; 15 build-included files have changed since |
| `00check.log`, `local-as-cran-check.log`, `build.log`, `probe-driver.log` | Same artifact |
| `tarball-inventory.txt` (as a *result*) | Same artifact — the **format** is reused, the **listing** is not |
| `platform/winbuilder-*-fixed-00check.log` | A **third** hash (`f9b9588e…`, 9,818,425) |
| `platform/rhub-*`, `gha-3os-matrix.md` | Predecessor source tips |
| `2026-08-07-07-product-contract.md` census (187/55, frozen 54) | Predates #953 capability-truth reconciliation |
| `2026-08-07-07-cran-release-ledger.json` `status_claim: tarball-clean` | True for its artifact; **not** for current `main` |

### PRESERVE — unchanged, not this lane's to touch

`platform/PLATFORM-NOT-READY.md`'s standing owner question (authorize
`platform-clean`?) remains **open and unanswered**. Stage A does not answer it, and the
default stated there — keep `tarball-clean`, `DESCRIPTION` `0.6.0`, no upload — still
governs. The `rhub-rchk-adjudication.md` noise adjudication (TMB headers) is retained
reasoning that will likely apply again; re-confirm on the candidate's own run rather
than inheriting the verdict.

## What Stage B inherits from this map

1. Start the new ledger from the **template**, not from a copy of the 2026-08-07 file.
   Copying and changing only the SHA is the explicit anti-pattern the handover names.
2. Regenerate **every** identity-bearing artifact: hash, size, inventory,
   forbidden-path scan, check log, timings.
3. Reuse the freeze-notes skeleton and the platform-matrix table shape as-is.
4. Re-read the incoming NOTE set on the candidate's own logs. The predecessor NOTE
   list is a **prediction**, and it is already known to be incomplete — Stage A found a
   fourth issue (the `offset()` documentation overclaim) that no check log reports,
   because it is a docs-vs-code mismatch no automated check inspects.

## Honest limitation of this salvage

I inspected the two cursor branches by `git log` / `git diff --stat` against `main`,
and read the merged artifacts on `main`. I did **not** check out either branch or
diff their file contents line-by-line against the merged versions. The claim "their
instruments are already on main" rests on the commit-level evidence that their
branch-only commits are the two documented receipt commits, plus the merged files
being present with matching names and structure. If Stage B finds a needed instrument
missing, check those two branches before rebuilding it.
