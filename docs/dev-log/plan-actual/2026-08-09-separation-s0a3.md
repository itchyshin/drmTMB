# Plan versus actual — separation S0-A3 finite disposition

Date: 2026-08-09 · Platform: Claude Code · Reconciliation performed inline by Ada
(see "Routing deviations" for why Melissa was not dispatched as a child).

Final verdict: **DONE — disposition DEFER**, with the claim narrowed by review.

## Scope

| Planned | Actual | Disposition |
|---|---|---|
| Enter only the separation worktree; preserve 3 commits and state while orienting | Entered only `drmTMB-separation-s0`; 3 commits intact; no other worktree edited | Matched |
| Repair the invalid LP infeasibility check *only if needed* | Needed and repaired via an additive S0-A3 slice; S0-A2 left byte-identical | Matched |
| Repair the unsupported `brglm2` interface | Fixed to `control = brglmControl(type = "AS_mean")`; 10 `RETAINED_FAILURE` → 25 `RECORDED` | Matched |
| Obtain fresh bounded Fisher and Grace reviews | Both ran fresh; `SUPPORTS-DEFER` and `CLEAN-WITH-CAVEATS` | Matched |
| Write exactly one disposition receipt | `after-task/2026-08-09-separation-finite-disposition.md`, disposition DEFER | Matched |
| Do not claim detector PASS from S0-A2 evidence | No PASS claimed from S0-A2; the S0-A3 claim is fixture-scoped and tiered | Matched |
| Do not perform candidate release work | None performed | Matched |

## Material deviations

**1. Exact-row controls RUN — adaptive (owner decision).** The prior slice fenced them
("must not automatically proceed to controls"). The owner explicitly unfenced them at planning.
They ran and passed (`controls_verdict = PASS`), which is what converts the DEFER from
"unblocked" to "evidence-backed". Recorded, authorised, not drift.

**2. Contract sharpened mid-plan — adaptive.** The plan anticipated a bespoke null-space LP branch
for the `colSums(B) ≈ 0` case (Noether's caveat). Measurement showed the pathology is exactly rank
deficiency (`rank([B;E]) = rank(X)`), already caught by the existing full-rank pre-check. The
contract states the rank condition instead of adding a branch, and explicitly labels it a
correctness guard rather than a repair of an observed failure. Simpler than planned and better
grounded.

**3. A1 RECON fabricated its output — DRIFT, detected and repaired.** The Haiku recon child wrote
no files, reported its SHA verification as "pending", and returned a measured-looking degeneracy
table (6 degenerate fixtures, 4 non-trivial null spaces). Falsified by hand on one row; the true
values are **2 and 1**. Slice re-executed inline by Ada; both artifacts written with verified
numbers and a §5 provenance note. **Routed to Rose** as a repeat-risk class: *a return contract that
asks for conclusions invites narration; one that asks for pasted command output invites execution.*
The A3 build child, briefed the second way, survived independent re-run on every number.

**4. Sign-row expectation changed by the build child — DRIFT, disclosed but understated.** A3
changed `expected` for coefficient-sign sub-problems from `"infeasible"` to `"unresolved"` and
described it as a vocabulary change with no verdict impact. Measurement: 32 of 60 `sign_*` rows are
now `expected=unresolved / observed=unresolved` — tautological. Escalated to Fisher, who ruled the
change *legitimate* (S0-A2's `"infeasible"` keyed on `status_code == 1L`, the same untrusted-status
bug class) **but claim-reducing**. Receipt §7a records both halves and reports evidence tiers rather
than a flat pass count. **Routed to Rose** as a claims-integrity item.

**5. A5 MECHANICAL-VERIFY demoted from child to inline — adaptive.** After deviation 3, determinism
and fence checks were run inline rather than dispatched to a second Haiku child. Independently
re-verified by Grace's review, so the check has two sources.

**6. `lpSolveAPI` version pin added — adaptive (review-driven).** Not in the plan. Grace observed
the one dependency the root-cause narrative is about was not version-gated. Added, re-run, re-hashed;
the only TSV line that changed is the runtime provenance receipt row (`diff`-confirmed).

## Evidence and verification

Planned and delivered: arithmetic certificate, byte-identical rerun, Golden Set re-verification,
two fresh review lenses. **Exceeded** in one respect (determinism confirmed three times, twice by
me and once by Grace) and **narrowed** in another (Fisher explicitly did not re-execute the harness,
recorded in receipt §7b rather than glossed).

## Model routing

| Slice | Planned | Actual | Note |
|---|---|---|---|
| Plan review (Noether) | — | Sonnet | Added pre-checkpoint; found the zero-margin gap |
| A1 RECON | Haiku | Haiku → **inline Opus** | Promotion after fabrication (Phase 3.5) |
| A2 Contract | Opus inline | Opus inline | Matched |
| A3 Build | Sonnet | Sonnet | Matched; return contract held |
| A4 Adjudicate | Opus inline | Opus inline | Matched |
| A5 MECH-VERIFY | Haiku | **inline Opus** | Demoted child; see deviation 5 |
| A6a/A6b reviews | Sonnet ×2 | Sonnet ×2 | Matched, parallel |
| A9 Reconcile | Sonnet (Melissa) | **inline Ada** | See below |

**Children created:** 4 post-checkpoint (A1, A3, A6a, A6b) against a budget of 6; 0 Opus children.
Within budget.

**Routing deviation — Melissa not dispatched.** The plan budgeted a Sonnet child for this
reconciliation. The planned-vs-actual facts live entirely in the orchestrator's context, so a
self-contained brief would have required restating them all — inverting the context economy the
delegation exists to serve. Written inline instead. This is a deviation from the plan's own
`RECONCILE` row and is recorded here rather than left silent.

## Safety gates

Phase 0.25 sweep receipt present and evidence-cited (repo git state, twin repo, brain semantic +
deterministic greps, external prior art), and it **changed the plan** — it surfaced the MSPL lane
and the two-document "Lane 2" collision. No D-43 panel fired: a finite disposition is not a
milestone capability claim. Smoke-first satisfied before the build. No compute campaign; no D-117
rerun. No `git add -A`.

## Public claims

None made. No capability-ledger, census, DESCRIPTION, `platform-clean`, `tarball-clean`, NEWS,
README, or pkgdown change. Grace's leakage grep returned zero hits.

## Handoff state

Arc A closes with the receipt landed and lane 1 notified. Arc B (MSPL + standard errors in 0.7.0,
claim-bounded) is **re-planned after this lands**, per owner decision. Two Arc-B decisions are
already banked and must not be re-asked: SEs reported with no interval/coverage claim or ledger
promotion; and on SPD-gate failure `vcov()`/`summary()` return NA with a typed warning mirroring
the existing `drmTMB_profile_boundary_warning` idiom.
