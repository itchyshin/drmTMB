# Session Handover: the 0.7.0 release lane — platform matrix green, win-builder collection pending

Meta: 2026-08-16 · from **Claude** (session closing; Shinichi moving fully to Cursor) · target
**Cursor** (fresh agent) · lane `claude/07-freeze-3-evidence`, **fully merged to `origin/main`
via #1051 — 0 unmerged commits** · sibling handover (separate lane, do not merge the two):
[`2026-08-16-cursor-handover-mspl-boundary.md`](2026-08-16-cursor-handover-mspl-boundary.md).

You are Cursor, picking up the drmTMB 0.7.0 CRAN ladder. **Critical: the Claude session that ran
this lane had an automated polling/cascade loop. That loop is DEAD — it does not survive the
session. Everything it would have done automatically is now a manual checklist, written out below
in full.** Trust the repo over this narrative.

## Where the ladder stands — verify by execution, not by reading

```sh
python3 ~/shinichi-brain/tools/cran_release_gate.py \
  docs/dev-log/release-audits/2026-08-15-070-cran-release-ledger-2.json
# expect: READY FOR CLAIMED RUNG   (status_claim = tarball-clean)
```

**Candidate (second freeze, 2026-08-15):** commit `302ac2579`, tarball
`drmTMB_0.7.0.tar.gz`, SHA-256
`0d150ef38b8d3b8b2d3dca084a62f8242832048b01e60caa4b08c5388b95e075`, 10,087,906 bytes. Immutable
write-protected primary `/Users/z3437171/drmTMB-release-artifacts/0.7.0-302ac2579/` + hash-verified
Totoro copy `~/drmTMB_0.7.0_cand3_302ac2579.tar.gz`. The 2026-08-11 candidate is predecessor
evidence only.

**Platform evidence — everything self-serve is DONE and green/adjudicated** (all filed under
`docs/dev-log/release/0.7.0-cran-gate/candidate-302ac2579/`):
exact-bytes local `--as-cran` (**1 NOTE, New submission only**) · exact-bytes Totoro valgrind
7-file subset (**CLEAN**, zero `drmTMB.so` frames) · 3-OS all green at the exact commit ·
clang-ubsan Status OK incl. vignettes · gcc-asan clean · clang-asan zero findings (vignette
NaN-quirk adjudicated) · rchk noise re-confirmed. The ledger carries `platform_matrix`; the
`platform-clean` probe fails on **exactly one key: `external_logs`** — win-builder.

## The one blocker, and why the last session could not see it

All three win-builder lanes were uploaded against the **exact frozen bytes** (R-release + R-devel
2026-08-16T00:06Z, R-oldrelease 00:49Z; receipts committed; upload queues confirmed drained
~01:25Z, so the checker took the files). Results were then silent for 9+ hours — **because the
session was polling the wrong mailbox.** Results go to the maintainer address in DESCRIPTION,
**`itchyshin@gmail.com`**; the connected Gmail was `snakagaw@ualberta.ca`, which provably does not
receive that mail. The results may have arrived long ago.

**Collection is therefore Shinichi's step, not yours.** Ask him to check `itchyshin@gmail.com` for
the three win-builder emails and either paste the bodies, give you the Status lines + `checking
tests` timings, or forward them to an address you can read. **If nothing is there**, win-builder
occasionally drops weekend jobs — the re-upload is pre-written and cheap (the bytes are immutable):

```sh
F=/Users/z3437171/drmTMB-release-artifacts/0.7.0-302ac2579/drmTMB_0.7.0.tar.gz
shasum -a 256 "$F"   # MUST equal 0d150ef3...b95e075 before any upload
curl -sS -T "$F" ftp://win-builder.r-project.org/R-release/
curl -sS -T "$F" ftp://win-builder.r-project.org/R-devel/
```
Get Shinichi's go before re-uploading (external submission; his call).

## The manual cascade — was automated, now yours, in this exact order

**Authorisation state, recorded in
`docs/dev-log/release-audits/2026-08-16-platform-clean-authorisation.md`:** Shinichi has
**pre-authorised** advancing `status_claim` → `platform-clean`, conditional on the evidence
existing and the gate passing mechanically. **Submission is FORBIDDEN** ("not submit yet")
regardless of rung or panel state — that is a separate future decision of his.

1. **File the results.** Save each email body verbatim to
   `docs/dev-log/release/0.7.0-cran-gate/candidate-302ac2579/winbuilder-{release|devel|oldrelease}.txt`.
   Verify each names `drmTMB_0.7.0.tar.gz`; record the Status line and the `checking tests`
   timing (the one number nothing else measures — the GHA Windows job runs the larger
   `NOT_CRAN=true` lane).
2. **If R-release AND R-devel are clean** (Status: 1 NOTE "New submission", 0 E / 0 W): add
   `evidence.external_logs` (typed: kind/value/repo_path, like the other entries) to
   `docs/dev-log/release-audits/2026-08-15-070-cran-release-ledger-2.json`; run the gate at
   `platform-clean`; if READY, **advance `status_claim` to `platform-clean`** (this is the
   pre-authorised step), re-run the gate to confirm, commit + push on a branch, PR, merge
   (docs-only).
3. **Lift the quiesce** on `docs/dev-log/coordination-board.md` (its condition — matrix complete —
   is met once `external_logs` lands). Record two things with it: the peer lane's held test-guard
   `4699cf934` (branch `claude/eloquent-driscoll-521fa1`, pushed, unmerged, no PR by design)
   belongs to the **next** candidate; and PR **#1050** merged 10 shipped files during the quiesce
   (breach recorded factually; whether sanctioned is Shinichi's call). Also surface the standing
   proposal: `main` reads `Version: 0.7.0` while drifted from the candidate again — **re-bump to
   `0.7.0.9000`** is recommended and awaits Shinichi's word.
4. **Gate 7 D-43 panel** — only after the win-builder evidence exists, three FRESH agents on the
   frozen artifact, default NOT READY, two NOT-READY votes withhold `submission-ready`:
   - **Grace** (reproducibility lens): CRAN/platform/dependency/timing/inventory against the
     ledger. **Rose** (systems-audit lens): claim/licensing/provenance/status consistency + stale
     surfaces. *Tooling caveat that bit three times on 2026-08-16: review-lens agent types often
     carry NO Write tool — have them RETURN verdict text for you to file.*
   - **Pat** (fresh applied-user lens): clean install from the exact tarball **on Totoro** (copy
     already at `~/drmTMB_0.7.0_cand3_302ac2579.tar.gz`; ≤50 cores, `OPENBLAS_NUM_THREADS=1` —
     keep the local machine quiet), first workflow, help pages, vignettes.
5. **If any win-builder result is NOT clean:** file it, do **not** advance the rung, do **not**
   run the panel; present the finding with adjudication options and stop.
6. Close with the platform-arc after-task
   (`python3 ~/shinichi-brain/tools/closeout.py new/check`), and report: rung reached, panel
   verdicts, timings — **submission still awaits Shinichi's separate go.**

## What Was Accomplished (this lane, all landed through PRs #1039–#1046, #1051)

Both owner holds lifted and recorded (D-93 Reading B; D-117 discharged; brain deltas written with
approval) · the REML arm measured (0.9248 → 0.9463, pre-registered, five-decimal control) · second
candidate frozen + proven at `tarball-clean` · full self-serve platform matrix + adjudications ·
win-builder uploads (exact bytes, receipts) · `cran-comments.md` refreshed for the live candidate ·
the conditional pre-authorisation recorded · the MSPL transfer packet (now the sibling lane).

## Landing State

| Item | State |
| --- | --- |
| `claude/07-freeze-3-evidence` | **LANDED — 0 unmerged** (#1051 merged the tail) |
| `claude/07-cran-ladder`, `claude/07-freeze-3`, `candidate-302ac2579` (branch) | LANDED/retained; the candidate branch also anchors the exact-commit CI runs |
| win-builder results | **CARRIED-OVER, external** — in `itchyshin@gmail.com`, unreadable from the authoring session; collection procedure above |
| Frozen artifacts (`~/drmTMB-release-artifacts/0.7.0-302ac2579/`, Totoro copy) | **PROTECTED — immutable; never rebuild** (`R CMD build` embeds timestamps; the bytes cannot be recreated) |
| Peer lane `claude/eloquent-driscoll-521fa1` (4 commits; test-guard `4699cf934` held) | **PROTECTED FOREIGN** — pushed, unmerged, no PR by design until the quiesce lifts |
| Primary checkout: unstaged `AGENTS.md` edit | **PROTECTED — never stage from the primary checkout** (deliberate pigauto-lane D-37-citation fix) |
| MSPL lane `claude/mspl-boundary-s0-s1` | **SIBLING LANE** — own handover; S2 gated on design 256's two sign-off boxes |
| Raw REML-arm CSVs (~220 MB) | CARRIED-OVER on Totoro `~/d117_reml/results/`, SHA-256s in that VERDICT |

## Gotchas (paid for in this session — do not repay)

- **Verify the premise, not just the mechanism**: a working Gmail query polled a mailbox that could
  never hold the answer, for nine hours. Positive-control every "no results" channel.
- "No email yet" and "the query failed" are indistinguishable in an empty result — assert
  positively (a control query with known hits) before trusting silence.
- The rung is proven by **running the gate in both directions** (READY at the claim; NOT READY one
  rung up), never by reading documents — including this one.
- Evidence classes stay distinct: **exact-bytes** (local `--as-cran`, Totoro valgrind) vs
  **same-commit** (GHA, R-hub build their own tarballs). `cran-comments.md` keeps them separate;
  preserve that.
- The win-builder timing figure is the *only* measurement of the Windows CRAN lane — do not
  substitute the green GHA Windows job for it.

## How to Resume

```sh
cd '/Users/z3437171/Dropbox/Github Local/drmTMB'
bash ~/shinichi-brain/tools/lane_preflight.sh .
git fetch --prune origin
git worktree add .worktrees/cran-cursor origin/main   # fresh worktree; NEVER the primary checkout
```

R: `R_PROFILE_USER=/dev/null Rscript --no-init-file` (the repo `.Rprofile` segfaults R 4.6).
Totoro: ControlMaster socket live, no Duo, ≤150 cores (D-143), threads pinned. No new campaign is
authorised by this handover; the panel's Pat-install is not a campaign.

**Paste-ready prompt:**

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-16-cursor-handover-070-release.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
