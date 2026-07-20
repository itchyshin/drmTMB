# Handover (2026-07-20): D2 done (PR #801, awaiting merge) → release evidence & truth freeze next

You are continuing the drmTMB pre-release close-out in **one continuous Claude lane**. This doc stands
alone. Read `AGENTS.md`, then this, then the ultra-plan at `~/.claude/plans/cosmic-foraging-quail.md`.

## Where things stand

**Arc A (D2, issue #58) is complete and pushed; PR #801 is open awaiting Shinichi's merge approval.**
Arc B (the 0.6.0 release evidence & truth freeze) has not started — it is gated on PR #801 merging and
a fresh `origin/main` fetch.

## Workspace — IMPORTANT, differs from the original brief

Work happens in a **fresh standalone clone OUTSIDE Dropbox**:
`~/worktrees/drmTMB-release-arcs` (own `.git`, no object alternates, no eviction exposure).

This supersedes the brief's `../drmTMB-wt-d2` and the coordination note's `~/worktrees/drmTMB-d2` —
that path was occupied by the daily-brain-check lane's moved worktree, whose `.git` still points back
into the Dropbox-synced repo the brain lane measured degrading. Do **not** use it. Do **not**
`git worktree add` under `Github Local/` (D-69).

The Dropbox repo root (`~/Dropbox/Github Local/drmTMB`, branch `claude/handover-freshness-0718`) is
another session's dirty tree — never touch it.

## PR #801 — what is in it

Branch `claude/docs-figure-gallery-58`, 4 commits, all pushed:

1. `e7a05770` — install Tufte (figure-design engineer) in `.claude/` + `.codex/` + `CLAUDE.md`
2. `9a3d61fe` — the gallery: all six plotting functions demonstrated, fixtures made self-declaring
3. `051c8057` — figure-audit evidence (8 PNGs + `figure-audit.md`)
4. `5dc2bbb1` — after-task report

Gates, all green (logs read, not inferred from exit codes):
- `devtools::test()` → FAIL 0, ERROR 0, PASS 39466, WARN 62, SKIP 24 (documented baseline)
- `pkgdown::check_pkgdown()` → No problems found
- Full `pkgdown::build_site()` → 33 articles, no problems
- 27 PNGs inspected individually → 24 PASS / 3 FAIL first pass, all fixed and re-rendered
- fence audit clean; `git diff --check` clean

## Merge sequence (do this when Shinichi approves PR #801)

1. Merge PR #801.
2. `cd ~/worktrees/drmTMB-release-arcs && git fetch origin && git switch main && git reset --hard origin/main`
   — or `git switch -c <release-branch> origin/main` directly.
3. **Re-verify from the merged main**, not from the branch: `git log origin/main -1`.
4. Only then cut the Arc B branch **in this same clone**.

## Two things Arc A hands to Arc B (do not lose these)

1. **`corpairs(conf.int = TRUE)` cannot produce an interval for a regression-parameterised `rho12`.**
   Smoke (2026-07-20) showed `conf.status = "newdata_required"`, `NA` bounds, and supplying `newdata`
   did not rescue it; only a constant-correlation (`rho12 ~ 1`) model yielded a real profile interval.
   `R/` was fenced in Arc A. **Needs a GitHub issue and a line in the release-scope manifest's negative
   space.** This is a genuine capability gap, not a doc gap.

2. **`sd_hat` is NA throughout the Arc 4c artifact** (`docs/dev-log/simulation-artifacts/2026-07-19-arc4c-mu-slope-coverage/`), so the point-bias diagnostic the frozen S0 *required* (lines 25, 33) does not
   exist. Belongs in the manifest's negative space independent of the zero-one-beta decision.

## Arc B — the plan in one paragraph

Freeze the honest 0.6.0 capability boundary. The repo currently claims **two version numbers**:
`DESCRIPTION` = `0.6.0.9000` and `NEWS.md` = `0.6.0 (development)`, while `README.md`, `_pkgdown.yml`
and `ROADMAP.md:109-110` still say `0.5.0`. Regenerate the ledger, diff every public claim surface
against it, classify all 26 open issues (release-blocking / accepted-limitation / post-0.6.0 /
obsolete / needs-decision), and produce one durable release-scope manifest with six sections and seven
fields per inference claim. See ultra-plan §8–§11.

**Zero-one-beta is DECIDED (ultra-plan §10):** keep `mc-0575` at `inference_ready_with_caveats`,
generator-qualified, no compute. Fisher would not sign "the leak did not bias coverage" — the
strictly-interior subset comparison is an arithmetic identity with no power. Publish the stratified
table as evidence of *dependence*, preserve Noether's WITHHOLD, name the defect in reader-facing text.
**No compute in either arc.**

Fences for Arc B: touch `R/`, `src/`, `tests/` **not at all**; do **not** bump `DESCRIPTION` Version
(that is Phase 20's call, not the freeze's). Every figure R chunk is off-limits.

## Stop points (Shinichi approval required)

- Before merging PR #801 (now).
- Before applying **any** GitHub issue/label/milestone edit — propose in the manifest first.
- Before merging the Arc B PR.
- Any compute — not expected; if ever needed, full stop for a prospective spec + fresh Fisher/Noether/
  Rose review + explicit approval, on DRAC/Totoro, never GitHub Actions.

## Routing note carried from Arc A

Installing an agent file makes it **present, not available** — the registry only picks up
`figure_design_engineer` (Tufte) after a session reload. Arc A's visual sweep therefore ran the Tufte
brief through a general agent. Next session should be able to launch Tufte natively; verify with a
trivial dispatch before relying on it.

## Resume command

```
Rehydrate from docs/dev-log/handover/2026-07-20-d2-to-release-freeze-handover.md plus
~/.claude/plans/cosmic-foraging-quail.md. If PR #801 is merged, fetch origin/main in
~/worktrees/drmTMB-release-arcs, verify from merged main, cut the release-freeze branch there, and
start Arc B at slice B1 (ledger regenerate + verify). If PR #801 is not yet merged, stop and report.
```
