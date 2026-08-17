# Overnight gap-fill board — 2026-08-16 / 17

**Reader:** Shinichi at 05:00 America/Denver, plus any sibling Cursor / Claude / Codex lane that wakes before then.  
**Coordinator lane:** `cursor/overnight-gapfill-board` (this docs-only branch).  
**Window:** 18:42 MDT 2026-08-16 → stop ~04:45 MDT 2026-08-17.  
**origin/main at board open:** `d9fddfa28` (Merge PR #1058).  
**CRAN:** parked. Do not `submit_cran`. Do not email Ligges. Do not touch #1033.

Handover (write ~04:45 MDT):
[`docs/dev-log/handover/2026-08-17-overnight-gapfill-handover.md`](../handover/2026-08-17-overnight-gapfill-handover.md)
once that file exists.

## Quiesce (hard)

Do **not** merge shipped `R/` or `src/` to `main`.  
Do **not** merge #1059, #1060, NB2, lognormal, Gamma, or #1061 overnight.  
#1061 ships tests (Julia CRAN-lane filter); owner-only.  
Docs-only PRs for **mc-0576 ADEMP** and **REML honesty 4a** may merge to `main` if CI is green, with explicit path staging.  
#1057 is also docs-only and CI-green; leave it for the owner unless a sibling already requested the merge.

## Coordinator lane

| Item | Value |
| --- | --- |
| Taken | `cursor/overnight-gapfill-board` (docs) then `cursor/ng-correlated-slope-lognormal` (Wave 3) |
| Worktree | `/Users/z3437171/local-scratch/lanes/drmTMB-overnight-gapfill-board` |
| Not taken | NB2, ADEMP, REML 4a, Wave 2, Wave 1, #1061, #1033, #1049, dirty Dropbox checkout `claude/handover-freshness-0718` |

The Dropbox checkout is a dirty July branch. All overnight writes go through local-scratch worktrees.

## Overnight queue

| # | Work | Branch | Status at 18:53 MDT | Merge? |
| --- | --- | --- | --- | --- |
| 0 | This board | `cursor/overnight-gapfill-board` | writing | draft PR (docs) |
| 1 | Wave 1 binomial `mc-0717` | `cursor/ng-correlated-slope-impl` | draft **#1059** at `ae307f4b1`: constant-x abort `3399e7eda` + Totoro 27-fit bank `ae307f4b1`. MERGEABLE. os-matrix green; ubuntu **in progress** | **no** |
| 2 | Wave 2 Poisson `mc-0718` | `cursor/ng-correlated-slope-wave2` | draft **#1060** still at `aef4c8601` (does **not** contain 1059 tip). Now **CONFLICTING**. Sibling rebasing onto `ae307f4b1` | **no** |
| 3 | Wave 2.5 NB2 `mc-0719` | `cursor/ng-correlated-slope-nb2` | **no PR**. Dirty worktree still tracking old Wave 2 tip. Sibling rebasing with #1060 | **no** |
| 4 | Wave 3 lognormal `mc-0720` | `cursor/ng-correlated-slope-lognormal` | wait for stack refresh, then start | **no** |
| 5 | Wave 3 Gamma | `cursor/ng-correlated-slope-gamma` | after lognormal if time | **no** |
| 6 | mc-0576 ADEMP docs | `cursor/mc0576-ademp-freeze` | **no PR**. Worktree now has uncommitted ADEMP freeze docs. Do not touch files | merge only if a later **docs-only** PR is green |
| 7 | REML honesty 4a docs | `cursor/ng-reml-honesty-4a` | **no PR**. Clean at `origin/main` | merge only if a later **docs-only** PR is green |
| 8 | Julia CRAN filter | `cursor/070-winbuilder-julia-skip` | draft **#1061** CONFLICTING | **no** |
| 9 | Design 257 | `cursor/ng-correlated-slope-design` | draft **#1057** MERGEABLE; CI green; docs-only | owner call |
| 10 | Missing-data | `codex/response-missing-formula-surface` | **#1033** CONFLICTING | **do not touch** |
| 11 | 05:00 handover | see path above | write ~04:45 MDT | this docs branch |

## Open PRs (polled 18:53 MDT)

| PR | Head | Draft | Mergeable | CI | URL |
| --- | --- | --- | --- | --- | --- |
| [#1061](https://github.com/itchyshin/drmTMB/pull/1061) | `cursor/070-winbuilder-julia-skip` | yes | CONFLICTING | none | https://github.com/itchyshin/drmTMB/pull/1061 |
| [#1060](https://github.com/itchyshin/drmTMB/pull/1060) | `cursor/ng-correlated-slope-wave2` @ `aef4c8601` | yes | CONFLICTING | os-matrix SUCCESS; ubuntu-latest **FAILURE** ([31972360870](https://github.com/itchyshin/drmTMB/actions/runs/31972360870)) | https://github.com/itchyshin/drmTMB/pull/1060 |
| [#1059](https://github.com/itchyshin/drmTMB/pull/1059) | `cursor/ng-correlated-slope-impl` @ `ae307f4b1` | yes | MERGEABLE | os-matrix SUCCESS; ubuntu **IN_PROGRESS** ([31983261975](https://github.com/itchyshin/drmTMB/actions/runs/31983261975)) | https://github.com/itchyshin/drmTMB/pull/1059 |
| [#1057](https://github.com/itchyshin/drmTMB/pull/1057) | `cursor/ng-correlated-slope-design` | yes | MERGEABLE | green | https://github.com/itchyshin/drmTMB/pull/1057 |
| [#1049](https://github.com/itchyshin/drmTMB/pull/1049) | `claude/binomial-phylo` | no | MERGEABLE | ubuntu FAIL | https://github.com/itchyshin/drmTMB/pull/1049 |
| [#1033](https://github.com/itchyshin/drmTMB/pull/1033) | `codex/response-missing-formula-surface` | no | CONFLICTING | none | https://github.com/itchyshin/drmTMB/pull/1033 |
| [#858](https://github.com/itchyshin/drmTMB/pull/858) | `codex/lane-b-e0-readiness` | yes | MERGEABLE | stale ubuntu FAIL | https://github.com/itchyshin/drmTMB/pull/858 |

No ADEMP, REML-honesty, NB2, lognormal, Gamma, or overnight-board PRs at this poll.

## #1059 new commits (this update)

| SHA | What |
| --- | --- |
| `3399e7eda` | `fix(binomial): reject constant-within-group x on correlated q2` — Design 257 rejection: a slope that does not vary within any group leaves `sd1` and `rho_re` unidentified. Abort before TMB. |
| `ae307f4b1` | `docs(mc-0717): bank Totoro 27-fit smoke artifacts` — named 27-fit smoke (9/9 recovery, glmmTMB oracle ~1e-5). Still `point_fit_recovery`. Do not merge. |

Wave 2 / NB2 siblings are rebasing onto that tip. Coordinator must **not** rebase those branches. Wave 3 stacks after the refreshed tip.

## Wave 3 plan (lognormal first)

Design 257 Wave 3 is one family per PR. First family = **lognormal**. Ceiling = `point_fit_recovery`. Reserved cell **`mc-0720`** (NB2 sibling owns **`mc-0719`**). Independent-slope cell `mc-0380` stays untouched.

```r
drmTMB(
  bf(y ~ x + (1 + x | id)),
  family = lognormal(),
  data = dat
)
```

| Symbol | Extractor | Truth (reuse Wave 2 fixture) |
| --- | --- | --- |
| `sd0` | `sdpars$mu["(1 + x \| id):(Intercept)"]` | 0.65 |
| `sd1` | `sdpars$mu["(1 + x \| id):x"]` | 0.42 |
| `rho_re` | `corpars$mu["cor((Intercept),x \| id)"]` | 0.45 |

**Alignment (write before flipping the gate).** Poisson Wave 2 reused an existing compiled design-17 map (`model_type == 6`: `ρ = 0.999999 tanh(η)`). Lognormal `model_type == 4` still applies independent `sd * u` and does **not** read `eta_cor_mu`. Gamma `model_type == 5` is the same. Wave 3 therefore needs a C++ design-17 row in the lognormal branch, plus:

- `validate_positive_continuous_mu_random_terms()` wedge for `{.fn lognormal}` only (Gamma stays rejected)
- missing-response abort in `drm_build_lognormal_ls_spec()`
- `split_tmb_corpars()` allowlist for `"lognormal"`
- constant-within-group `x` abort (inherit the #1059 helper if the rebase exposes it)
- rejection matrix: REML, missing-response, mixed `(1|g)+(1+x|g)`, labelled, Gamma neighbour
- ledger `mc-0720` at `ordinary_correlated_q2` / `point_fit_recovery`

Group-level correlation is `rho_re`, never residual `rho12`. Stack after NB2 tip if a PR exists, else after refreshed Wave 2 tip. Draft PR. Do not merge. Skip new Totoro smokes if the host is busy.

## Compute

Ask “Totoro or DRAC?” before any recovery campaign (D-50). Overnight default: **no new smoke** if Totoro is busy with #1060 / NB2. Local focused tests only.

## Live updates

| MDT | What changed |
| --- | --- |
| 18:50 | Board opened. No NB2 / ADEMP / 4a / lognormal PRs. #1060 ubuntu red. #1061 conflicting. |
| 18:53 | #1059 gained `3399e7eda` (constant-x abort) + `ae307f4b1` (Totoro 27-fit bank). Head `ae307f4b1`. Ubuntu CI re-running. #1060 now CONFLICTING vs that tip; sibling rebasing #1060/NB2. ADEMP worktree has uncommitted freeze docs; no PR yet. Coordinator waits for stack refresh, then starts Wave 3 lognormal. |

## Stop rules

- 04:45 MDT: freeze new code; write the 05:00 handover.
- If a sibling is mid-edit on a file, do not “help” that file.
- If Totoro is overloaded, keep coding drafts; do not launch smokes.
- A draft PR with a failing local recovery is a STOP, not a silent ledger row.
