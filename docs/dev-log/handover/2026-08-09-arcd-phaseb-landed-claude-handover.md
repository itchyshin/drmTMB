# Session Handoff: Arc D landed (probit/cloglog) + Phase B (link-general MSPL Jeffreys)

Meta: 2026-08-09 · from Claude to whoever is next · two branches, both pushed, one PR open

**Cite by branch + SHA, never by path** — this repo has multiple same-dated handovers.

## Critical context

`binomial(link = "probit")` and `binomial(link = "cloglog")` **now fit.** Before today both
aborted. Verified against `glm()` to four decimals on every coefficient, converged, `pdHess = TRUE`.

| Lane | Branch @ SHA | State |
|---|---|---|
| Arc D | `claude/binomial-link-generalisation` @ **`b4ae15cb3`** | **PUSHED, PR [#973](https://github.com/itchyshin/drmTMB/pull/973) OPEN, not merged** |
| Phase B | `claude/mspl-binomial-inference-promotion` @ **`f1a7f6dea`** | **PUSHED, no PR — the PR is Shinichi's call** |

**Owner decision, 2026-08-09: probit/cloglog target 0.7.0**, superseding design 252's original
0.7.1. That made `--as-cran` a release-blocking gate and Emmy's review a go/no-go. Both cleared.

## Gates — both green, on the committed trees

| Gate | Result |
|---|---|
| Arc D `--as-cran` | **0 errors / 0 warnings / 1 NOTE** ("New submission") |
| Arc D `NOT_CRAN` full suite | **zero failures** |
| Phase B `--as-cran` | **0 / 0 / 1** |
| Phase B full suite | **zero failures** |
| Emmy (architecture, go/no-go) | **GO**-with-conditions — 3 of 4 met, 1 deferred with a written audit |
| Noether (Phase B math) | SOUND-with-fixes, all applied |
| Melissa (plan-vs-actual) | 6 adaptive / **0 drift** / 2 unclear (both since closed) |

## What is still fenced — do NOT do these without a fresh owner decision

- **Candidate preparation / release rung.** `AGENTS.md`'s standing NO-GO is untouched. The 0.7.0
  *content* decision is not authorization to prepare a candidate. `DESCRIPTION` is still **0.6.0**
  on both branches; no ledger, no census, no rung advanced.
- **The MSPL PR** — Shinichi's call, unchanged by this session.
- **The SE-calibration campaign** — designed, unbuilt, needs Totoro GO and a `PREREGISTRATION.md`.
- **Merging #973** — a separate call now that the gates are green.

## Claim boundary — read before writing anything public

**This is a fitting capability, not an interval or coverage claim.** Owner decision, now recorded in
design 252 §9: a new *link* **inherits** binomial's capability-ledger evidence cells — same
likelihood, same parameters, only `g(mu)` changes. No campaign was run, the census is unchanged, and
the ceiling stays `point_fit_recovery`. **MSPL remains logit-only** (§7): Kosmidis & Firth's
finiteness result is *fixed-effect* while drmTMB's MSPL is *mixed-effect*, and Sterzinger & Kosmidis
leave those bounds as future work. The Jeffreys helper is internal scaffolding, not public API.

## Five defects found, and what actually caught each

None was findable by a targeted test of the new links. This is the arc's main lesson.

| # | Defect | Caught by |
|---|---|---|
| 1 | `predict_parameters_inverse_link_derivative()` had no probit/cloglog arm — every probit SE would abort | pre-execution **plan review** |
| 2 | `%||%` absent from `R/`, base version needs R 4.4.0 vs a 4.1.0 floor | pre-execution **plan review** |
| 3 | Bivariate branch had no `link_code` — **223+ errors**, every bivariate fit dead | **full suite** |
| 4 | `test-phylo-utils.R` hand-built data list, same cause — 6 errors | **full suite** |
| 5 | `binomial_start()` hardcoded logit — probit started ~70% too far out | **Emmy, from inspection, without running code** |

Plus, in Phase B: cloglog's weight returned `+Inf` where the limit is `−Inf`, flipping at
`eta = −745.13` where `exp(eta)` underflows (**Noether**).

**The unifying lesson:** `make_tmb_data_core()` has **19** model_type declarations, not 17 — the
bivariate branch uses `switch()` rather than a literal `model_type = <n>L`, so the grep that found
the others could not match it. *Grep finds the sites that NAME a contract; it cannot find the sites
that ASSUME the old one.* Enumerate by behaviour — "who reads this value?" — not by pattern.

A repo-wide sweep confirms exactly **two** files hand-build a `model_type` data list
(`R/drmTMB.R`, `tests/testthat/test-phylo-utils.R`); both now carry `link_code`.

## Owed / next

1. **Merge #973** when you want it in — gates are green; that is now a decision, not a blocker.
2. **Emmy condition 1** — remove the `= 0` default at `src/drm_response_kernels.h:27` so omissions
   become compile errors. Deferred with a written audit (after-task §10) showing **0** binomial call
   sites currently rely on the default. Do it in the arc that next touches this kernel.
3. **Brain lessons** — drafted at `scratchpad/2026-08-09-brain-lessons-DRAFT.md`, gap-checked
   against `LESSONS.md` / `CROSS-REPO-GUARDS.md`. **Not written** — D-37 requires owner approval.
4. **Design 252 §4 is wrong** and is corrected in place: it prescribed `stats::make.link()$mu.eta`
   for the MSPL weight, which clamps to `[eps, 1-eps]` and would silently change the penalty value —
   the same probability-scale downgrade §3 refuses for the likelihood.

## Gotchas worth not rediscovering

- **Re-run every sub-agent claim.** An S0 scout reported writing a file it never wrote and
  over-reported two `profile.R` sites as defects (both are pre-existing limitations — neither switch
  has a `logit` arm either, so they already fail for *any* binomial fit).
- **A line-oriented grep gave a false positive too.** I reported a "silent wrong-model bug" in the
  C++ kernel and retracted it a minute later: the call spans lines and `link_code` sat on the next
  one. Use a brace-matching parser for a load-bearing inventory.
- **Don't chase bit-identity through source constants.** Both `dput()`'s 15 digits and
  `sprintf("%.17g")` lost ULPs. Pin a tight tolerance in the test; record the bit-identity
  verification (here: `identical()` across 200 random designs vs the pre-change function extracted
  with `git show HEAD:R/mspl.R`) in the after-task report.
- **`--as-cran` was restarted three times**, each after a real fix invalidated the run in flight.

## Environment

```sh
cd /Users/z3437171/local-scratch/worktrees/drmTMB-links          # Arc D
cd /Users/z3437171/local-scratch/worktrees/drmTMB-mspl-inference # Phase B
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'rcmdcheck::rcmdcheck(args="--as-cran", error_on="never")'
NOT_CRAN=true R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test()'
```

**Never `git add -A`.** The primary checkout (`~/Dropbox/Github Local/drmTMB`) stays PROTECTED and
dirty. A second Claude session was observed working in `drmTMB-missing-data-0809` — do not touch it.
