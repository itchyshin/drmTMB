# Session handoff — D-117 answered; recommendation with Shinichi; next arc is the 0.7.0 release lane

Meta: 2026-08-09 · from Claude to a fresh Claude session · **fresh lane required** (this session ran
the whole arc and is long)

**The committed repository is authoritative; the authoring chat is gone.** Reconcile every claim
below against git and GitHub before acting.

## Where D-117 stands

**Answered. Recommendation delivered. Awaiting Shinichi's decision.**

- **Coverage PASSES**: pooled **0.924800** (SE 0.000417) over **400,000 attempts**; per-cell
  0.9229 / 0.9257 / 0.9255 / 0.9251, all clearing `ss_floor(10) = 0.918` on **raw** coverage and on
  the stricter one-sided LCB. 100000/100000 finite intervals.
- **My pre-registered prediction (BORDERLINE / no discharge) was WRONG** — 0.9140 was a low
  Monte-Carlo draw, off by exactly 1.00 × MCSE. Recorded in `PREDICTION-OUTCOME.md`.
- **Recovery is measured but was never scoreable** — D-117 specified no bias criterion. Raw bias
  −15.76 / −9.31 / −10.26 / −8.34%, matching `lme4` to ~1e-6.
- **RECOMMENDATION: discharge**, with four conditions →
  [`../release-audits/2026-08-09-d117-FINAL-RECOMMENDATION.md`](../release-audits/2026-08-09-d117-FINAL-RECOMMENDATION.md)

**Do not treat discharge as decided.** Shinichi approved the *recommendation being made*; he has not
recorded the decision. Check `~/shinichi-brain/memory/DECISIONS.md` D-117 before assuming either way.

## Landing state

| Artifact | Pushed | PR | State |
|---|---|---|---|
| `claude/d117-discharge` (18 commits) | yes | **#974 OPEN** | evidence + recommendation; docs + 1 test only |
| `claude/d117-user-facing-numbers` | yes | **#975 OPEN, stacked on #974** | corrects shipped n=1000 figures; touches `R/` roxygen + regenerated `man/` |
| brain edit for D-117 | **no** | — | **staged, NOT written** (D-37). Draft: `scratchpad/PROPOSED-brain-D117-update.md` in the session dir — copy it somewhere durable before it is cleaned |
| raw campaign CSVs (~195 MB) | no | — | on Totoro `~/d117_100k/score/results/`, SHA-256 in `VERDICT-100K.md §9`; **not backed up** |

**Merge order: #974 first, then #975.** #974 carries a verified provenance property
(`git diff a2695a788..HEAD -- R/ src/ DESCRIPTION` empty); that is why the `R/` correction is a
separate branch.

## What the review actually said — do not overstate it

Three adversarial rounds: D-43 panel **2/3 NOT-DONE**, re-adjudication panel **3/3 NOT-DONE**,
correction verifier **OVER-CORRECTED**. **No round returned unanimous DONE.**

Every defect was in the *reasoning about* the result, never the result — three reviewers reproduced
the coverage figures independently from the raw rows, one bypassing the coverage column entirely.
All findings are dispositioned **resolved or explicitly refused** in the final recommendation.

The final edits implementing the verifier's prescription have **not** been re-reviewed. Stated, not
hidden.

## The trap this arc fell into twice — read before repairing anything

**Every defect was introduced while fixing a previous defect.** The repair of panel 1's blocking
finding suppressed the statistic that looked worst (citing the wrong column, a unit error, and a
fabricated "flooring" mechanism); the repair of *that* imported a `g = 256` bar as if it bound a
`g = 10` result. Send repairs back through review, and **freeze the tree before dispatching
reviewers** — this arc gave reviewers a moving target twice.

## Next arc — the 0.7.0 release lane (Shinichi's choice, 2026-08-09)

Three things, and the first is not mine to do:

1. **Adjudicate the two 0.7.0 candidates.** `a8f7c479` (preserved at
   `~/local-scratch/drmTMB-0.7.0-candidates/`, SHA verified) vs `d35c0b9e…` built at `7fccac0b9`
   per PR #959's body. **No record says which is canonical.**
2. **Decide `platform-clean`.** Dispatched runs exist but **none at the candidate's source**; a run
   at the final head is required before any platform claim.
3. **Repay the vignette code-coverage debt — but check first.** The handover chain says five
   vignettes moved to `vignettes/articles/` and are no longer executed by `R CMD check`. **On `main`
   that is NOT true**: `vignettes/articles/` does not exist and all 37 `.Rmd` are still built. The
   debt arrives only *with* PR #959. Verify before planning around it.

**Fenced, unchanged:** exact-candidate prep is **NO-GO** pending Shinichi's separate authorisation
(issues #61, #870). Do not merge #959 — merging it *is* the release action. No tag, no GitHub
release, no CRAN upload. D-89: submission is far away by choice; there is no clock.

## Environment

Worktree `/private/tmp/drmTMB-d117` (currently on `claude/d117-user-facing-numbers`). Run R as
`R_PROFILE_USER=/dev/null Rscript --no-init-file` — the `.Rprofile` R-4.5 lib segfaults R 4.6.
Totoro reachable via its existing ControlMaster (`ls ~/.ssh/cm-*totoro*`); no Duo needed. Campaign
workspace `~/d117_100k/`.

**Gotchas paid for here:** a cross-platform file-tree hash must sort the **hashes**, not the
filenames (locale collation manufactured a false provenance MISMATCH). `rnorm()` is **not**
bit-identical across platforms — ~1 ULP between x86_64/R4.5.3 and arm64/R4.6.0 — so no campaign
reproduces bit-exactly across machines. Never `git add -A`; explicit paths only.

## To report to Shinichi

1. **Stale `.git/index.lock`** (0 bytes) in the primary checkout — the harness blocks `.git`
   deletions, so it needs a human `rm`.
2. **Which 0.7.0 candidate is canonical** — still unanswered, and it blocks item 1 of the next arc.

## How to resume

```sh
cd /private/tmp/drmTMB-d117 && git status --short --branch && gh pr view 974 --json state,mergeable
```

---

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-09-d117-discharge-closeout.md. Reconcile against
git, confirm whether Shinichi has recorded the D-117 decision, then run the 0.7.0 release-lane arc.
```
