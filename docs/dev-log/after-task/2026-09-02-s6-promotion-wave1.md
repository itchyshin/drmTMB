# Bridge promotion wave 1 (S6)

## 1. Scope

Execute `docs/dev-log/plan/2026-09-01-bridge-promotion-wave1.md` exactly, now
that both its conditions have fired: drmTMB #1112 merged (13ac255a3) and
DRM.jl #579 merged. Move `r_bridge_status` from `experimental` to `partial`
for exactly four rows in `drm_julia_capability_comparison()`
(`R/julia-bridge.R`); touch no other row's `r_bridge_status` and no
`claim_status` anywhere.

## 2. Change

`r_bridge_status: experimental -> partial` for `base_gaussian_location_scale`,
`biv_gaussian_residual`, `plain_binomial_nonphylo`, `gaussian_response_mask`.
Each row's `claim_boundary` gained one appended sentence citing the wave-1
plan and its receipt:

- `base_gaussian_location_scale`: SE parity 1.498725653859e-07 abs /
  2.169e-06 rel (SE_PASS).
- `biv_gaussian_residual`: SE parity 9.17587137869158e-08 abs / 1.835e-06 rel
  (SE_PASS).
- `plain_binomial_nonphylo`: 1.26789215931788e-09 abs / 2.482e-08 rel,
  comparator hash f3e754a4.
- `gaussian_response_mask`: include==drop equality; cross-engine
  |Delta logLik| approx 4e-10; live-bridge R test.

All four additions end with the same qualifier: "partial, NOT covered:
bridge-side inference (profile/bootstrap through engine=\"julia\") remains
unqualified (G3)." `next_action` was touched only to remove one now-false
sentence (`biv_gaussian_residual` said "do not promote beyond experimental",
which the promotion contradicts) and to add "Qualify bridge-side inference
(G3) before any further move." to the four promoted rows.

`biv_q4_phylo_reml` was NOT moved (see §9).

## 3. Vocabulary decision (owner-facing, not silently absorbed)

`"partial"` was not previously an allowed `r_bridge_status` value (only
`supported`, `experimental`, `intentional_error`, `planned`, `unsupported`
existed). This is a schema addition, documented in two design docs rather
than added ad hoc:

- `docs/design/192-capability-comparison-regeneration.md`: `partial` defined
  as "same-target point+SE parity receipt verified on the committed fixture
  AND the route runs unopted in a non-interactive session; bridge-side
  inference (profile/bootstrap through `engine = "julia"`) unqualified (G3).
  Sits between experimental and supported."
- `docs/design/168-r-julia-finish-capability-matrix.md`: one paragraph in the
  Bridge Gate Registry Contract section stating the same rung, and noting
  that the word `"partial"` also exists as a `claim_status` value elsewhere
  in the same registry with the ledger's own distinct meaning (a capability
  claim gated by CRAN-facing governance, not by evidence) — the two axes are
  not the same claim and should not be conflated.

This is the kind of decision that belongs to the maintainer's sign-off
(D-203/D-204), not something to bury in a diff; it is called out here and in
the PR body explicitly.

## 4. Tests

`tests/testthat/test-julia-gate-vs-engine.R`:

- `"partial"` added to the allowed `r_bridge_status` set (was previously
  restricted to five values).
- The binomial lock was INVERTED, not silently edited: what used to be
  `expect_equal(binomial_row$r_bridge_status, "experimental")` is now
  `expect_equal(binomial_row$r_bridge_status, "partial")`, in the same style
  as the file's existing Phase 1.5 / Phase 1 inversions, so an accidental
  reversion fails loudly.
- A new locked block asserts exactly the four promoted rows read `"partial"`
  and that `biv_q4_phylo_reml` still reads `"experimental"`.

Ran `test-julia-gate-vs-engine.R` alone (0 failures) and the filtered suite
`filter = "julia-gate|julia-capab|capability"` (also exercises
`test-missing-data-capability-gate.R`; 0 failures). The full package suite
was not run (out of scope for this slice).

## 5. Regeneration

Both TSVs (`docs/dev-log/dashboard/julia-capabilities.tsv` and
`inst/extdata/julia-capabilities.tsv`) regenerated with
`Rscript tools/write-julia-capability-comparison.R`; not hand-edited.

## 6. What did NOT move, and why

- `biv_q4_phylo_reml`: stays `experimental`. Per the plan's CONDITIONS
  section, DRM.jl #575's bridge re-measure (coef/logLik GATE-PASS at
  1.9e-05 / 1.7e-04) did not produce a same-target SE receipt, and the row's
  own coverage evidence (phylocov off-diagonal under-coverage, documented at
  length in its own `claim_boundary`) independently argues against any
  status move. The plan is explicit: "q4 stays OUT of wave 1 until a
  same-target SE receipt exists AND #579 merges" — #579 merging alone is not
  sufficient without the SE receipt.
- `gaussian_phylo_mean`: listed in the plan as CANDIDATE, not auto-included —
  "promote only if the maintainer accepts the point-parity receipt as
  sufficient for partial." Left unmoved pending that explicit call.
- `phylo_count_large_p`, `phylo_gamma_beta_binomial`,
  `general_covariance_structured`, `location_scale_scale`: DEFERRED per the
  plan — receipts not yet same-target-verified on the bridge axis (their
  existing evidence is native-engine-vs-native-engine, not through the R
  `engine = "julia"` bridge).
- `cross_family_latent`: DEFERRED — no native comparator exists for a mixed
  family pair.
- `engine_control_surface`: unsupported by design (D-179 #3, permanent
  boundary), not a candidate for this axis at all.

## 7. Evidence limit — what this is NOT

This is a capability/bridge-route claim only. It is NOT:

- An interval or coverage claim. Every `interval_status` fence in the file is
  untouched.
- A `claim_status` move. No row's `claim_status` changed (verified by gate
  S6-G1: `claim_status` is byte-identical to origin/main for all twelve
  rows).
- A release or CRAN claim. D-164 continues to hold the release; this slice
  never touches it.
- A statement that bridge-side inference (profile/bootstrap through
  `engine = "julia"`) works. That axis (G3) is explicitly named as
  unqualified in every promoted row's boundary text.

## 8. Ownership

`R/julia-bridge.R` (`drm_julia_capability_comparison()` rows only),
`inst/extdata/julia-capabilities.tsv`,
`docs/dev-log/dashboard/julia-capabilities.tsv`,
`tests/testthat/test-julia-gate-vs-engine.R` (status locks only),
`docs/design/192-capability-comparison-regeneration.md`,
`docs/design/168-r-julia-finish-capability-matrix.md`, and this file — per
the S6 gate's OWNS line.

## 9. Sign-off

Per D-203/D-204: a Rose-scanned DRAFT PR plus the maintainer's merge is the
sign-off for this promotion; no per-row sentence is required from this
report. This branch (`claude/bridge-promotion-wave1`) is not pushed and no
PR is opened here — that is the coordinator's step after an adversarial scan.
