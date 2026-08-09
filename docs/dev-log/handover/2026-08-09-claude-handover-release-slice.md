# Session handoff — drmTMB 0.7.0 release slice

Meta: 2026-08-09 · from Claude to Claude · **new lane recommended** (the authoring session ran very long)

You are Claude, picking up the drmTMB 0.7.0 candidate lane. **The committed repository is
authoritative; the authoring chat is gone.** Read this document, reconcile it against the
current git state, then continue only the OWED steps in *Next Immediate Steps*.

## Goals / mission

Produce one exact, honest first-CRAN candidate for drmTMB **0.7.0** without broadening its
scientific claims. Trust capability by exact cell and evidence tier. Preserve the fail-closed
CRAN rung ladder: never say "CRAN ready", always report the **highest proven rung and the
next unproven one**.

**Stop before** D-43, an unsupported `platform-clean` write, final `cran-comments.md`, tag,
GitHub release, or CRAN upload. Those remain owner-gated.

## Critical context

- **A candidate exists and then was invalidated — twice, on purpose.** Two 0.7.0 tarballs
  were frozen and both passed the CRAN-lane check at Status 1 NOTE. Both are now predecessor
  evidence. Read `docs/dev-log/release/0.7.0-cran-gate/FREEZE-NOTES-0.7.0.md` before citing
  any hash.
- **The current release-slice source is AHEAD of the last frozen artifact.** `da9b2d76`
  was built at `14bc8ce89`; the branch has since taken documentation commits and now needs
  the boundary-surfacing merge. **There is currently NO valid frozen candidate.**
- Gate H is cleared: the separation lane merged as **DEFER** (PR #956, `8d441a32d`), no
  package code touched.
- **D-93 was DISCHARGED by Shinichi on 2026-08-09.** D-117's PASS claim remains **withheld**
  and is untouched.

## What was accomplished

Stage A (orientation) and most of Stage B (candidate assembly), plus two feature arcs:

1. **Stage A packet** — gate orientation, instrument salvage, product contract, rights
   ledger, fail-closed ledger, and a stale-evidence quarantine note written *into* the old
   evidence directory. `docs/dev-log/release-audits/2026-08-09-07-*`.
2. **`offset()` for every univariate family** (PR #958) — ten families, correctness pinned by
   a link-agnostic identity (a constant offset `c` lowers the intercept by exactly `c`),
   red-tested.
3. **B1 dispatch self-location fix** (PR #957) — the sole error in a 43,342-test run.
4. **0.7.0 release bytes** — `DESCRIPTION` bump, spelling and file-URI fixes, README install
   repair, version-consistency repairs.
5. **Boundary surfacing** (branch `claude/boundary-surfacing`, **no PR yet**) — closes both
   HIGH traps from the pre-release reader review.

Full detail: `docs/dev-log/after-task/2026-08-09-offset-univariate-families.md`,
`docs/dev-log/release-audits/2026-08-09-07-candidate-decision-packet.md`.

## Current working state

**Working** — `claude/07-release-slice` @ `d3a20fb42`, pushed, clean. Draft PR #959.
`claude/boundary-surfacing` @ `8245449f2`, pushed, clean, **no PR**.

**In progress / OWED** — the boundary-surfacing merge and a full rebuild → re-check →
re-freeze → re-dispatch cycle. Roughly 30 minutes.

**Blocked on the owner** —

- **`inst/doc` is 11.11 MB against CRAN's stated 5MB documentation maximum.** The policy says
  *"authors will be asked to trim their documentation to a maximum of 5MB."* `R CMD check`
  reports it only as an `INFO` line. **This is the likeliest submission blocker and it is a
  product decision about which vignettes ship.** See
  `docs/dev-log/release-audits/2026-08-09-07-cran-policy-refresh.md`.
- `platform-clean` **rung** write · win-builder submission · D-43 panel (owner deferred it
  until platform evidence exists) · merging any PR.

## Key decisions and rationale

- **D-49 was applied twice at real cost.** Both invalidations were deliberate: `d35c0b9e`
  because the README still told users to install the unsupported `v0.5.0` tag, and the
  current source because boundary surfacing touches `R/`. A candidate is not worth keeping if
  keeping it means shipping a known defect.
- **`inst/WORDLIST` cannot suppress the DESCRIPTION spelling NOTE.** It fires on CRAN
  incoming, which does not read that file — which is why it appeared on win-builder and never
  in the local `--as-cran` log. Fixed by adjusting prose.
- **Offsets for truncated/hurdle NB2 and bivariate families stay deferred**, with the reason
  recorded: their observed mean renormalises over a restricted support, so an exposure term
  would not scale the reported mean.
- **The bootstrap boundary detector must use the bootstrap's own signal.** Reusing the Wald
  detector fails — it reads the point estimate, and on the demonstrated case that estimate is
  0.1936, nowhere near the 1e-4 threshold.

## Files created / modified

`git diff --name-only origin/main...claude/07-release-slice` and `...claude/boundary-surfacing`
give the exact set. Highlights:

- `R/drmTMB.R`, `src/drmTMB.cpp`, `man/drmTMB.Rd` — offset support, 10 families
- `R/profile.R`, `R/check.R` — boundary surfacing
- `DESCRIPTION`, `NEWS.md`, `README.md`, `vignettes/formula-grammar.Rmd`,
  `vignettes/function-map-cheatsheet.Rmd`
- `tests/testthat/test-offset-families.R`, `test-boundary-surfacing.R`,
  `test-b1-dispatch-self-location.R`
- `docs/design/{01,02,06,19}-*.md`
- `docs/dev-log/release-audits/2026-08-09-07-*` (8 files),
  `docs/dev-log/release/0.7.0-cran-gate/{FREEZE-NOTES-0.7.0,RENDERED-SITE-0.7.0,STALE-EVIDENCE-QUARANTINE}.md`
- `docs/dev-log/dashboard/capability-ledger/2026-08-08-c17c2-c14-final-source-compatibility.tsv`
  and `docs/dev-log/implementation-recovery/2026-08-09-07-offset-arc-model15-compatibility/`
- this handover

## Landing state

| Artifact | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `claude/07-release-slice` @ `d3a20fb42` | yes | yes | **#959 DRAFT** | ACTIVE — do not merge; merging it is the release action |
| `claude/boundary-surfacing` @ `8245449f2` | yes | yes | **none** | **CARRIED-OVER** — open a PR, then merge into the release slice |
| `claude/offset-univariate-families` @ `9f0000877` | yes | yes | #958 | open, not merged |
| `claude/fix-b1-dispatch-self-location` @ `9c6a63223` | yes | yes | #957 | open, not merged |
| `claude/07-candidate-preparation-staged` @ `0faf5c36a` | yes | yes | none | Stage A record; merged into the release slice already |
| ~15 `codex/*` and `hopper/*` branches with unpushed commits | mixed | no | — | **PROTECTED FOREIGN** — pre-existing, not this session's. Do not push, clean, or reconcile. `codex/lane-b-q1-preflight-admission` alone has 226. |
| five repository stashes | n/a | n/a | — | **PROTECTED** — do not pop or drop |
| Primary checkout `claude/handover-freshness-0718` | dirty/stale | no | — | **PROTECTED** — never work or stage there |
| #858, #937, historical #947 | — | — | open/merged | **PROTECTED FOREIGN** |

`handoff_gate.sh` fails closed on the foreign branches above. That state predates this
session and is declared here rather than cleaned.

## Next immediate steps — OWED, in order

1. **Lane preflight and reconcile.** `bash ~/shinichi-brain/tools/lane_preflight.sh '<repo>'`,
   then classify every item above `OWED` / `DONE` / `RETRACTED` / `PROTECTED`.
2. **Open a PR for `claude/boundary-surfacing`** and merge it into `claude/07-release-slice`
   (not into `main`).
3. **Rebuild the candidate** from the release slice with a clean worktree:
   `Rscript -e "pkgbuild::build('.', dest_path='<dir>', vignettes=TRUE, manual=FALSE)"`.
4. **Re-check the exact artifact**: `R CMD check --as-cran --run-donttest <tarball>`, CRAN
   incoming enabled, `_R_CHECK_FORCE_SUGGESTS_` **not** disabled. Expect **Status: 1 NOTE**
   (`New submission`). Anything else is a finding.
5. **Re-freeze**: SHA-256, byte size, entry count, inventory, forbidden-path scan, immutable
   hash-qualified copy. Update `FREEZE-NOTES-0.7.0.md` and the ledger; re-run
   `python3 ~/shinichi-brain/tools/cran_release_gate.py <ledger.json>`.
6. **Re-dispatch the platform matrix** at the final source:
   `gh workflow run R-CMD-check --ref claude/07-release-slice` and same for `R-hub`.
7. **Return the decision packet and STOP.** Do not fire D-43, write `platform-clean`,
   finalize `cran-comments.md`, tag, release, or upload.

## Blockers / open questions

- **The 11.11 MB documentation question** — owner decision, likeliest submission blocker.
- `DESCRIPTION:19` still says "Skewness … staged for later phases" while `skew_normal()` is
  fitted. An **understatement**, so no CRAN risk; flagged, not changed — it is product copy.
- Whether to submit to win-builder (the only real Windows vignette-timing measurement).
- CRAN submission portal was noted offline until ~2026-08-19.

## Gotchas and failed approaches

- **A timeout kill logs as `conclusion: cancelled`**, identical to a concurrency cancel.
  Compare job duration against the 75-minute ceiling; never trust the conclusion string. Run
  `31328483445` shows `cancelled` at `771b2a3d6` and is almost certainly a concurrency cancel
  from the next push — verify, do not assume.
- **`capability_ledger.py --check` is NOT the ledger guard.** The fingerprint guard lives in
  `tools/tests/test_capability_ledger.py`, which CI runs. Editing `R/drmTMB.R` or
  `src/drmTMB.cpp` invalidates the C17 model-15 fingerprint; the remedy is to **re-run**
  `tools/run-lane-c-c17c1-c14-model15-compatibility.R` (env `C17_COMPAT_RUN_ID`), not to
  re-pin the hash. This cost the authoring session a CI failure.
- **Reading source is not reading the reader surface.** The stale `v0.5.0` install command
  survived a targeted README fix and was only caught by building pkgdown and reading
  `pkgdown-site/index.html`.
- **Boundary detectors are not interchangeable.** Wald reads the point estimate; profile
  discovers the bound while profiling; bootstrap must use the share of resamples on the
  bound, computed on the **natural** scale (link-scale draws made `log(0.9) < 1e-4` flag a
  healthy model). A minimum of 20 retained draws is required or `R = 2` plumbing tests trip
  it. All three mistakes were made and caught by negative controls.
- Never `git add -A` in this repository.
- Run R as `R_PROFILE_USER=/dev/null Rscript --no-init-file …`.

## How to resume

```sh
cd /private/tmp/drmTMB-07-release && git status --short --branch
```

If that worktree is gone:

```sh
git worktree add -b <new> /private/tmp/drmTMB-07-release-2 origin/claude/07-release-slice
```

Toolchain verified on this machine: R 4.6.0, TMB 1.9.21, devtools 2.5.2,
`pkgbuild::has_build_tools()` TRUE, `pdflatex` present. Full local suite takes ~45 min;
`R CMD check --as-cran` with vignettes takes ~15 min; the candidate build ~9 min.

Safe verification command (changes nothing):

```sh
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'suppressMessages(pkgload::load_all(".")); testthat::test_dir("tests/testthat", filter="^(offset-families|boundary-surfacing)$", reporter="summary")'
```

---

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-09-claude-handover-release-slice.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
