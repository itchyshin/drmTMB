# Handover — parity-joint lane (drmTMB ↔ DRM.jl), 2026-09-07

Reader: whoever picks this lane up — Claude, Codex, Cursor, or Shinichi reading it
cold. Everything here is measured and re-checkable. Where something is a lead rather
than evidence, it says so.

## RESUME

```
Read, in order: docs/dev-log/plan-actual/2026-09-05-parity-joint.md (what actually
landed, 23 arcs) -> docs/dev-log/after-task/2026-09-06-parity-joint.md (how it went
wrong and what fixed it) -> this file. Then: check whether the closure PR merged;
if it did, the lane is closed and the next work is the open-issue list in §5.
```

## 1. What this lane was for

Shinichi, 2026-09-05: *"make sure all the models can be run in both, and all the
models can be run through `engine = "julia"`."* One Claude lane over both repos, at
0.7.0, then the backlog.

## 2. Where it got to

The lane ran 2026-09-05 → 09-07 and merged **73 drmTMB and 41 DRM.jl PRs**. The
approved plan accounts for roughly 30 of them; the other ~84 are in the
plan-vs-actual's "executed but not planned" table, which has **32 rows**. That table
being large is a finding, not a boast — the plan under-described the work by a
factor of about three, and the biggest single reason is that structural CI repair
was never an arc.

The headline capability number, read from `inst/extdata/julia-capabilities.tsv` on
drmTMB `main`:

| `r_bridge_status` | count |
|---|---|
| supported | 5 |
| partial | 18 |
| experimental | 13 |
| unsupported | 1 |

All four **wave-1** routes reached `supported` — `base_gaussian_location_scale`,
`plain_binomial_nonphylo`, `gaussian_response_mask`, `biv_gaussian_residual` — which
closes the G3 bridge-side-inference fence whose text had been repeated verbatim in
four rows. The last of them landed as #1187 on 2026-09-07.

## 3. CARRIED OVER — in flight when this was written

| item | state | what to do |
|---|---|---|
| DRM.jl #653 (Gaussian mean-only phylo cell by REML, #624 item (c)) | merged? **CHECK IT** — it was OPEN with auto-merge armed, 11/12 checks green, `Julia 1 - shard 2/4` hung at 86 min against a 20-min twin | if still stuck: `gh run cancel 34128844563 -R itchyshin/DRM.jl` then `gh run rerun 34128844563 -R itchyshin/DRM.jl --failed` (re-runs the one shard + `ci-ok`, not all ten) |
| drmTMB #1199 (R side admitting that route) | OPEN, all 6 checks green, CLEAN, deliberately **held** | it claims the capability #653 delivers; do not merge it until #653's content is on DRM.jl main. `~/local-scratch/parity-joint/land-1199.sh` does exactly this and refuses if the content is absent |
| the closure PR | branch `claude/parity-closure-20260907` | see §4 |

## 4. The closure, and why its order is not arbitrary

`~/local-scratch/parity-joint/closure.sh`, run only when both queues are quiet:

1. **re-pin** the DRM.jl clone at `~/local-scratch/parity-joint/drmjl-main-now`. It
   was measured 13 commits behind DRM.jl main; every artifact regenerated before the
   re-pin describes the wrong engine.
2. **regenerate** all six generated artifacts. Never hand-edit any of them.
3. **the tip-identity receipt LAST.** It hashes every `R/*.R`, so anything touching
   `R/` after it re-stales it. It was stale on main for exactly this reason.
4. source-tree lane, then open one PR.

Already committed on the closure branch, ahead of that:

- **`tools/write-parity-matrix.R` was BROKEN on main** from the moment #1187
  merged — #1187 rewrote the line the generator anchors a citation to, and
  `pm_grep_line()` aborts on a missing anchor. It failed closed, which is right, but
  nothing was red: the only end-to-end test skips without `DRM_JL_PATH`, and CI has
  no DRM.jl clone. Anchor repaired, the two boundary strings it fed rewritten from
  #1187's own receipt (they still asserted a fence #1187 removed), and a **new test
  resolves every citation anchor with no DRM.jl clone**, so this class fails in CI
  next time. Red control exercised: breaking one anchor gives exactly 1 failure.

## 5. Still open — nothing here is blocked on this lane

- **Issues #1083, #1081, #1150** remain OPEN although A1's PR (#1163) merged. Check
  what each still wants before assuming the arc closed them.
- **#1188** (mask-preserving bootstrap replicates) is OPEN although both sides
  landed — drmTMB #1226 and DRM.jl's `_restore_response_mask!`. Probably closable.
- **DRM.jl #467 / #609** (factors, `I()`, `poly()`, varying-scale `g_tol`) — the A6
  arc found parity already existed and delivered a refusal of non-treatment
  contrasts instead; the original issues stand.
- `anova()`'s LRT is **refused on both engines** and `drm_lrtest` is internal only.
  That is an owner decision, not an oversight.
- **`source-pins.json` is stale** at `430ef64cc`; the rows that cite it say so.

## 6. Do not repeat — the expensive ones

1. **Verify CONTENT, never merge status.** Resolving a conflict "to main" silently
   dropped four functions this week while leaving their call sites standing. Every
   merge in this lane now runs a definition-level diff against both parents.
2. **`git push origin <branch>` from a DETACHED HEAD pushes the branch ref, not your
   work, and exits 0.** Use `push origin HEAD:refs/heads/<branch>`.
3. **`gh pr merge --auto` fails open** where auto-merge is disabled: it merges
   immediately and reports success. Use `tools/pr_merge_when_green.sh`, and confirm
   `mergedAt` afterwards.
4. **A generator is the only correct oracle for a generated table.** Literal line
   counts understate columns built with `rep()`; `data.frame()` refuses a misaligned
   table for real.
5. **Never read a main checkout's working tree as source truth** — use
   `git show origin/main:<path>`. ~30 worktrees share that checkout.
6. **A green suite that never called Julia is not parity evidence.** The source-tree
   lane prints 24477 PASS and, in the same breath, *"the LIVE ENGINE was not
   exercised in this configuration."*

## 7. Housekeeping

Two detached worktrees are left under `~/local-scratch/`
(`verify-main-20260907-073050`, holding two uncommitted regenerated files, and
`verify-main-tests-20260907`). `git worktree remove` on them exceeded two minutes
and was abandoned; the repo is unlocked and responsive. Retry when convenient.

DRM.jl carries an annotated `v0.7.1` tag (2026-09-06, the owner's git identity, by
arrangement with the other lane). **drmTMB is deliberately untagged** at v0.7.0 —
version bumped and NEWS written, tag not applied. Tagging is the owner's.
