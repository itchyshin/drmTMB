# Row 87 (final cell) — scope + plan for 104/104

Meta: 2026-07-05 overnight · Claude · the LAST Q-Series row after row 105 (→103/104).
**For the maintainer's review — NOT started.** The representative choice is a
maintainer honesty call (per the overnight instruction), so this is scope + plan only.

## The row
`qseries_nongaussian_structured_slope_neighbors_planned` — a CATCH-ALL for
"**non-count OR labelled/multiple** structured non-Gaussian slope variants,"
explicitly **beyond ordinary Poisson/NB2 unlabelled mu one-slope**. Its
claim_boundary: a point-fit on one variant does NOT imply the family.

## Honesty correction (important — the scope probe got this wrong)
The tractability probe recommended the cheapest option — **Poisson slope-only
phylo** (a 1-line parser change). **Rejected as board-gaming.** It is ordinary,
count, unlabelled, single-slope — NONE of "non-count / labelled / multiple." It is
a provider-extension of the already-admitted Poisson slope-only *spatial* cell
(row 81), not a row-87 neighbor. Admitting it would move the count to 104 without
delivering the capability row 87 represents. This is exactly the completeness-
theater the project refuses.

## The honest lightest representative: a NON-COUNT family structured ONE-SLOPE
Verified state (R/drmTMB.R) — non-count families have a structured *intercept* but
NO structured *slope*:
- **Gamma**: structured `relmat` mu intercept exists (`validate_gamma_relmat_mu_structured_term`
  R/drmTMB.R:7644; local-fit row 94); ordinary slopes work; structured slope not implemented.
- **Student**: structured `spatial` mu intercept exists (`validate_student_spatial_mu_structured_term`
  R/drmTMB.R:7456; local-fit row 92); structured slope not implemented.
- **Beta**: structured `animal` mu intercept exists (`validate_beta_animal_mu_structured_term`
  R/drmTMB.R:7702); structured slope not implemented.

Extending any one of these to a structured one-slope `(1 + x | provider)` in mu is
the genuinely-new "non-count structured slope" capability = the honest row-87
target. **No C++** — non-count families use standard TMB densities (verified: no
custom kernel in src/). Effort: parser gate + a validation function (copy the count
one-slope pattern) + a recovery grid. **Moderate-low.**

## Recommendation
**Gamma `relmat(1 + x | id, K = K)` one-slope** (primary) or **Student
`spatial(1 + x | site, coords)` one-slope** (alternative) — both are clean
extensions of an existing structured-intercept route with no C++. Lean: Gamma
relmat (standard positive-continuous family + a clean relatedness provider, and a
local-fit intercept already exists to build from).

## Decision for the maintainer (5 AM)
1. **Framing:** is admitting ONE non-count structured-slope representative HONEST
   for the catch-all row 87 (family-rest explicitly planned), the same way row 105
   admitted one concrete cell? Or does row 87 warrant more than one axis?
2. **Which representative:** Gamma relmat / Student spatial / Beta animal?

Once chosen, the path is quick (no C++): RED test → parser + validation → recovery
ladder (local Mac; Totoro if scaling) → 4-lens gate → admit → **104/104**.

## Explicitly NOT done overnight
No engine change, no RED test committed for a specific family — building any one
representative presumes the maintainer's judgment call on framing + family. Scoped
and teed up only.
