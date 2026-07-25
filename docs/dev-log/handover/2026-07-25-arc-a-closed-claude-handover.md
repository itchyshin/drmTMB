# Session Handoff: Arc A CLOSED (partial, by decision); next arc = C++ / numerical audit

**Meta:** 2026-07-25 · from Claude · target **Claude or Codex** · Arc A parity lane → closed

Read `AGENTS.md` first, then this. This doc stands alone.

---

## What Arc A was, and what it actually delivered

Arc A set out to make cross-package agreement visible in the capability ledger. Four
slices were scoped. **Two shipped. Two did not, and that was a deliberate call.**

| Slice | State |
| --- | --- |
| 1. Define the evidence mechanism | **DONE** — as an `evidence_class`, not a new tier |
| 2. Build the comparator mapping | **DONE** — reused doc 158 + a 177-cell triage |
| 3. Sweep the overlap region | **NOT DONE** — deliberately dropped |
| 4. Publish a vignette | **NOT DONE** — deliberately dropped |

**Do not describe Arc A as complete.** The instrument was built and four cells were wired
into it. The sweep was not run.

## The finding that closed the arc

**The brief's premise was false and the arithmetic does not work.** It claimed 158 stuck
cells could be retired cheaply by parity. In fact, of the 176-cell `point_fit_recovery`
pool: **122 are `structured`, 18 are `response_missingness`, 7 are non-structured
bivariate — none has any external comparator in existence.** The non-structured univariate
pool is 29, and after removing scale-side REs (gamlss absent), brms-only families (brms
absent) and bivariate LSS, **parity can reach roughly 15 cells, ever.**

A line-by-line audit then cut a candidate set of 8 to 3. Four cells now carry comparator
evidence. Finishing slice 3 would take that to ~18 out of 677. That is why the arc was
closed rather than completed: the remaining work is real but low-yield, and **80% of the
stuck pool is frontier, where parity is structurally incapable of reaching.**

## Why the next arc is the C++ / numerical audit

Parity covers the *overlap*. This arc measured how small the overlap is. The frontier —
structured effects, scale-side random effects, `sd()` regression, bivariate LSS,
phylogenetic structure on residual log-SD — has **no external implementation to compare
against at all**, and it is where `mc-0227` and `mc-0242` found real small-sample bias.
The C++ audit is the only instrument aimed there.

**Scope it correctness-first:** log-sum-exp and overflow paths, link and inverse-link edge
cases, boundary parameterizations, and finite-difference vs TMB AD gradient agreement.
**Any efficiency claim requires a profiler.** A model reading C++ can flag a suspicious
pattern but cannot tell you what is hot. Do not let it emit performance claims without one.

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `claude/arc-a-external-comparator-evidence` (11 commits) | yes | **yes** | opened | **LANDED to origin**; merge after CI is green |
| `codex/arc6-6-bernoulli-nb2-plan` | yes | **no (2 commits)** | none | **CARRIED-OVER FOREIGN.** Not this lane's work. Resume only on that branch with explicit scope confirmation: `git checkout codex/arc6-6-bernoulli-nb2-plan` |
| `codex/pkgdown-formal-closeout` | yes | **yes** | **#841 open** | **LANDED — no longer orphaned.** `c018908a` "docs: close pkgdown reader-surface audit", pushed 2026-07-25 with `origin/main` merged in. Its one conflict was `docs/dev-log/check-log.md`, resolved as a **union** with no log content dropped from either side. Touches `docs/dev-log/` only. Merge when CI is green. |
| root checkout `claude/handover-freshness-0718` | partial | no | none | **CARRIED-OVER FOREIGN.** ~65 uncommitted AGHQ/REML files, far behind `main`. **Do not touch.** Resume only in its own checkout. |
| PR #829, PR #836 (draft) | — | — | open | **FOREIGN.** Other owners. |
| PR #828 | — | — | open | **NEVER MERGE.** Standing instruction. |

## What shipped, concretely

- **`mc-0260m`** — the `meta_V` route row, landed from its approved 2026-07-21 draft. A
  row insert via the existing `route_modifier` column, **not** a schema migration.
- **`evidence_class = "external_comparator"`** in `capability-ledger/evidence.tsv`, four
  rows: metafor (mc-0260m), lme4 (mc-0265, mc-0429), glmmTMB (mc-0260).
- A per-cell **External comparator** column on the capability surface, rendering
  independence strength, with a legend.
- `docs/design/242-external-comparator-evidence-class.md` — the policy record.
- `docs/design/158` Gaussian scale-conversion **error corrected**.
- `docs/dev-log/dashboard/parity-triage.tsv` — all 177 cells classified.

## Key decisions

- **An `evidence_class`, not a tier.** `evidence_tier` is a single *ordered* scale of
  inferential strength; comparator agreement is orthogonal to it. `mc-0227`/`mc-0242` are
  inference-ready with no comparator; `mc-0260` has near-exact agreement at
  `point_fit_recovery`. A tier would force a false comparison and rewrite the family map.
- **Independence is not uniform.** lme4 and metafor share no engine with drmTMB (**strong**);
  glmmTMB shares the TMB/AD stack (**weak**). Recorded per row, rendered on the surface.
- **Parity licenses the overlap, never the frontier.** Enforced by tests, not memory.
- **`meta_V` was un-fenced** on the owner's decision, on the correct grounds.
- **`mc-0262` stays quarantined** — open M=64 threshold objection.

## Gotchas

- **The `158` guard is now a frozen-census invariant. Do not "fix" it by raising a number.**
  The original 676 `model_surface` rows (`source_order <= 676`) must hold exactly **158**
  `point_fit_recovery` cells, permanently. The *total* is 159 and may grow only by an
  approved insert. Both are enforced in `validate()`, so `--check` catches a promotion
  hidden behind a compensating insert. Raising 158 is how a promotion gets laundered.
- **`schema.json` is a source file, not a generated output.** `--write` does not touch it;
  it is written only by `bootstrap()`, which refuses once the files exist. Change
  `MODEL_SURFACE_COUNT` and you must regenerate it by calling `schema_value()` directly.
- **A csv round-trip of `cells.tsv`/`evidence.tsv` silently re-quotes existing rows.**
  Append raw lines instead; assert the new fields contain no tab, newline or double-quote.
- **`skip_if_not_installed()` means a green comparator suite can be vacuous.** Always
  confirm **zero skips**, not just zero failures.
- **Do not run campaigns on GitHub Actions** (D-50). Totoro or DRAC; results stay local.

## Verification at close

`--check` clean (30 generated outputs) · 41 unit tests · `check-capability-runtime.R` OK ·
after-task validator passes · comparator suite **126 assertions, zero failures, zero
skips** · **zero pre-existing cells changed tier**.

**Gates:** Fisher **SIGN-OFF: yes**, Rose **SIGN-OFF: yes**, each after a second pass.
Rose's first pass was NOT-DONE with six blocking findings; all were fixed.

## Next steps

1. Merge the Arc A PR once CI is green.
2. **Start the C++ / numerical audit**, correctness-first, profiler required for any
   efficiency claim.
3. Merge PR #841 (the pkgdown closeout) once CI is green. It is no longer orphaned.
4. Backlog, not urgent: 14 parity-eligible cells with no comparator evidence; `mc-0262`'s
   M=64 objection; whether the 12-column census should carry `route_modifier` (46
   duplicate structural keys, 45 of them pre-dating this branch).

**One-command resume:**

```
claude "Read docs/dev-log/handover/2026-07-25-arc-a-closed-claude-handover.md + the AGENTS.md snapshot, then ultra-plan the drmTMB C++/numerical audit: correctness-first (log-sum-exp and overflow paths, link/inverse-link edge cases, boundary parameterizations, finite-difference vs TMB AD gradient agreement), aimed at the frontier region parity cannot reach. No efficiency claims without a profiler. Plan only — Fisher + Rose before anything runs."
```
