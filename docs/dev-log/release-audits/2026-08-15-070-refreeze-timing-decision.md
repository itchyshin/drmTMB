# Decision: do not re-freeze the 0.7.0 candidate yet

**2026-08-15 · decided by Shinichi · lane `claude/07-cran-ladder` · `origin/main` = `e19cc0807`**

## The decision

**Do not cut a new 0.7.0 candidate now.** Keep the existing frozen tarball as the recorded
`tarball-clean` artifact, treat its platform evidence as **predecessor-only**, and cut exactly one
new candidate later — after the tree is deliberately quiesced and the owner holds are resolved.

This answers the question the 2026-08-12 re-freeze notice left open
(`docs/dev-log/handover/2026-08-12-refreeze-notice-for-cran-lane.md`), which framed the choice as
"re-freeze now" versus "defer the MSPL arc and re-cut from an earlier point". **Neither was taken.**
The chosen option is a third: defer the freeze itself.

## Why

**The release is held by two owner decisions, not by engineering.** `D-93` holds 0.7.0 undischarged.
`D-117` is measured — pooled coverage 0.924800 (SE 0.000417) over 400,000 attempts, every cell
clearing `ss_floor(10) = 0.918` — with discharge **RECOMMENDED with four conditions and NOT
DECIDED**. Repo `AGENTS.md` and the brain's `memory/DECISIONS.md` agree on this; see the 2026-08-15
after-task report, which retracts an earlier claim that the two sources conflicted.

No candidate frozen today can be submitted while those holds stand.

**So a freeze cut now would be spent twice.** Because `src/drmTMB.cpp` moved after the freeze
(PR #1012, `55fc08abc`, +23/−4), platform evidence keys to bytes that no longer exist, and any new
candidate needs a **complete new platform-matrix campaign** — 3-OS, R-hub sanitizers, valgrind, and
win-builder. Running that campaign against bytes that will drift again before the holds lift buys
nothing durable. The campaign should run **once**, against the bytes that will actually ship.

## What this decision does NOT do

- It does **not** advance `status_claim`. The rung stays **`tarball-clean`**, and the gate
  (`cran_release_gate.py`) fails closed above it while `platform_matrix` and `external_logs` are
  absent from the ledger.
- It does **not** retract or invalidate the existing candidate record. `a75c3c901` /
  `2176e4b81b887e8d944456e4a74fa581afda959d0d2a5468c89bc700d693cda9` (9,925,713 bytes) remains the
  identified artifact for the `tarball-clean` claim, verified by hash on 2026-08-15.
- It does **not** defer the MSPL non-logit arc (#1006/#1012/#1020) to 0.7.1. Those changes stay on
  `main` and are expected to ship in 0.7.0.
- It does **not** discharge D-93 or D-117, and it does **not** authorise any campaign or submission.

## Standing hazard while this decision holds

`DESCRIPTION` on `main` reads `Version: 0.7.0` — the same string the frozen candidate carries — while
**60 shipped files** now differ from it (vignettes 23, tests 16, `R/` 9, `man/` 6, `inst/` 3, `src/`
1, `NEWS.md` 1, `DESCRIPTION` 1). A tarball built from `main` today would be a *different 0.7.0* with
no version-string signal that anything moved. **Do not build an ad-hoc tarball from `main` and treat
it as the candidate.** The drift was 17 files on 2026-08-12; it grows.

## What has to be true before the next freeze

1. **D-93 and D-117 resolved** by Shinichi — the gating condition for the whole ladder.
2. **The tree deliberately quiesced** — agree a cut point rather than racing merges.
3. **Ledger gaps closed**: `rights_and_consent_is_stale` (the 2026-08-09 `inst/COPYRIGHTS` borrowing
   is documented but never rights-reviewed) and `gate1_unresolved_items` (2 unresolved Gate 1 items).
4. **`8245449f2` re-landed or explicitly excluded** — the bootstrap-route boundary flag
   (`bootstrap_at_boundary`), currently absent from `main` and preserved on
   `claude/boundary-surfacing`. It closes a user-facing honesty gap on an interval route; shipping
   0.7.0 without it is a choice worth making deliberately.
5. **Then, and only then**, cut one candidate and run the platform matrix against it — win-builder
   included, which has never run against the candidate's exact bytes.

> Related: `docs/dev-log/handover/2026-08-12-refreeze-notice-for-cran-lane.md` ·
> `docs/dev-log/after-task/2026-08-15-070-cran-ladder-rehydration.md` ·
> `docs/dev-log/release-audits/2026-08-11-070-cran-release-ledger.json` ·
> `docs/dev-log/release/0.7.0-cran-gate/RUNG-REPORT-0.7.0.md` · brain `DECISIONS.md` D-49/D-93/D-117
