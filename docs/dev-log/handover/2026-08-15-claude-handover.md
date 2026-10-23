# Session Handover: external-validation arc CLOSED (4 PRs merged)

Meta: 2026-08-15 · from Claude · target any lane · `origin/main` = `e19cc0807`.

## Critical Context

The external-validation arc is **DONE and fully landed**. Four PRs merged, each
verified on its exact head. Do not reopen it. The handover that started this arc
(`2026-08-14-claude-handover.md`) is now historical.

**Start a fresh session for whatever comes next.** This one ran long; the work
below is complete and needs no continuity beyond this file.

## What Landed

| PR | What | Merge |
| --- | --- | --- |
| #1030 | pkgdown reference index repaired — `main`'s site had stopped deploying | `859c0f6e6` |
| #1031 | non-vendored `lme4`/`glmmTMB` oracle harness; the repo's **first cross-package interval assertion** | `82cd00560` |
| #1035 | `ranef()`/`fixef()` dispatch regardless of package attach order | `7d756efc6` |
| #1034 | Phase 19: eight comparator workflows + reader article (issue #60) | `e19cc0807` |

All four were confirmed green **on their exact head SHA**, not on a nearby run —
two runs in this arc were pinned to superseded commits, so check
`gh run view <id> --json headSha` before trusting a badge.

## What Each PR Actually Claims

**#1031 — interval agreement.** drmTMB's profile endpoints match `lme4`'s shipped
`fm1P` reference on sleepstudy at a **5e-4 absolute** bound, worst case 3.11e-4.
The bound discriminates: a `REML = TRUE` refit misses three of four targets by
1.800 / 0.399 / 1.93e-2.

**Read this before citing that result.** An earlier claim that `fm1P` is
ML-derived was **withdrawn** under audit — a converged REML/`bobyqa` refit
reproduces it *better* than two of three ML reconstructions, so the reference's
estimator is **not recoverable**. The honest statement is agreement to within
lme4's own optimizer-to-optimizer reproducibility, **not** a matched-estimator
proof. No REML interval-parity claim is made anywhere, and no capability-ledger
row was added: `docs/design/242` requires every `external_comparator` row's
`claim_boundary` to say it does not cover intervals, so a conforming row would
have to assert something false. Doc 242 carries a dated amendment explaining that
the **point-agreement** block *could* carry a row today — withheld as a scope
choice, not a prohibition.

**#1034 — Phase 19.** Eight comparisons against `lme4`, `metafor`, `ordinal`,
`glmmTMB`, each verified by a real fit before write-up (ten proposed, ten fitted,
eight survived; the two rejected keep their blockers). Independence is stated per
comparison: `lme4`/`metafor` **STRONG**, `glmmTMB` **WEAK** (same TMB/AD stack).
`--as-cran` 0 errors / 0 warnings.

**#1035 — the S3 fix.** `library(drmTMB); library(glmmTMB)` used to make
`ranef(fit)` fail outright. `lme4` and `glmmTMB` re-export `nlme`'s generic, so
one registration in `.onLoad` covers all three. `sigma` never needed it — it is
already on `stats::sigma`.

## Open, Not Mine

- **#1032** `claude/julia-parity-evidence` — foreign, untouched.
- **#1033** `codex/response-missing-formula-surface` — the response-missingness
  lane the original handover fenced. Still fenced.
- **#959 / #955 / #858** — 0.7 CRAN ladder and Lane B. Untouched all session.

## Residuals — real, and none of them blocking

1. **Issue #60 is not closed.** #1034 is its implementation half. Its Definition
   of Done also names a comparator matrix and CI evidence; judge before closing.
2. **`nbinom2 theta = 1/sigma^2` was outside the audited range**, and beta `phi`,
   the tweedie `2 *` factor and the `rho12` guard are exercised nowhere in the
   Phase 19 artifacts — correctly absent, not wrongly asserted. Do not read the
   c04–c09 audit as covering them.
3. **`DESCRIPTION` pins no version floors** on `glmmTMB`/`lme4`/`metafor`/
   `metadat`/`ordinal`, while the article quotes version-sensitive tolerances. The
   new "Reproducing these numbers" section records the versions used; it does not
   pin them.
4. **One mutation was not caught** in the c04–c09 audit (M15: `nAGQ = 25` passes a
   1e-3 coefficient assertion). The auditor flagged the accompanying logLik catch
   as UNCERTAIN because lme4 2.0.1 reports an internally inconsistent 42-unit
   swing between `nAGQ` settings. Worth a look if that comparison ever matters.
5. **Rose's P2s and Melissa's minor drift rows** are recorded in
   `docs/dev-log/external-oracle/phase19/` and deliberately left open.

## Gotchas That Cost Real Time Here

- **`knitr::knit()` is not `rmarkdown::render()`.** `R CMD check` uses `render`.
  A vignette reported as "knits cleanly" then failed `render` **twice**, on two
  different defects. Never verify a vignette with `knit()`.
- **A PR based on a non-`main` branch gets NO CI**, and retargeting the base does
  not trigger it. Only a rebase + push did.
- **Adding a vignette needs FIVE coupled edits, not the four documented** —
  `docs/design/226` is enforced against the live vignette count, and needs a table
  row, not just a header bump. A sixth stale count inside that doc is not checked
  by its own test.
- **Never `library()` a comparator in a test or vignette.** One `library(glmmTMB)`
  broke eight downstream vignettes under `--as-cran`. #1035 fixes the package-side
  fragility; the calling discipline still stands.
- **`git add -A` swept build debris** (a `figure/` directory of stray PNGs) into a
  commit and cost a check NOTE. Stage scoped paths.
- Three separate checks in this arc **passed things that were wrong**: the ledger
  test passed an internally inconsistent doc 226, `knit()` passed a broken
  vignette, and five claims rounds passed an article its own test contradicted.

All five durable lessons are promoted to `docs/dev-log/team-improvements.md`.

## How to Resume

```sh
cd '/Users/z3437171/Dropbox/Github Local/drmTMB'
bash ~/shinichi-brain/tools/lane_preflight.sh .
git fetch --prune origin && git log --oneline origin/main -5
gh run list --branch main --limit 4        # confirm the post-merge run for e19cc0807
```

Worktrees from this session under `.worktrees/` (`external-oracle`, `phase19`,
`ranef-s3`, `handover-0815`) are all merged or handover-only and can be pruned.

**Paste-ready prompt for the next lane:**

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-15-claude-handover.md. The external-validation
arc is closed; do not reopen it. Confirm main's post-merge CI and pkgdown are green, then pick up
the next piece of work and tell me what you chose and why.
```
