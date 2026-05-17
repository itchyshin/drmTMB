# After-Task Report: Animal and Known-Relatedness Roadmap Boundary

## Scope

This design slice recorded the animal-model and user-supplied relatedness
boundary after the project owner asked whether pedigree-based animal models can
join the existing phylogenetic and spatial structured-effect programme.

No fitted `animal()` or `relmat()` likelihood was added. The task was a roadmap
and grammar hardening slice so later implementation work does not treat
phylogeny, spatial dependence, animal models, and known relatedness as unrelated
special cases.

## Team Perspective

- Ada kept the slice scoped to roadmap and design changes after Slice 194
  merged.
- Boole separated public syntax from the shared engine: `phylo()`, `spatial()`,
  and future `animal()` stay visible to users, while a lower-level `relmat()`
  remains only a design candidate and should replace rather than duplicate the
  older reserved `gr()` wording if exposed.
- Jason connected the wording to MCMCglmm's structured random-effect framing,
  where pedigrees, phylogenies, and user-defined covariance structures are one
  mathematical class with different matrix sources.
- Gauss and Noether kept the mathematical contract at
  `z ~ MVN(0, sigma_z^2 K)`, with `A_phylo`, `M`, `A_ped`, or `K_user`
  supplying the known structure.
- Fisher flagged the validation gate: dense `A` versus sparse `Ainv`, ID
  matching, weak additive variance, and separation from sampling covariance need
  recovery tests before implementation is advertised.
- Grace kept dependency risk out of this slice; no new package dependency or
  runnable syntax was introduced.
- Pat and Darwin kept the audience distinction visible: animal models are
  additive genetic or pedigree relatedness, not simply "phylo with another
  object".
- Rose checked that `A`/`Ainv`/`K`/`Q` for relatedness stay separate from `V`
  for the preferred `meta_V(..., V = V)` meta-analysis design.

## Files Changed

- `ROADMAP.md`
- `R/formula-markers.R`
- `docs/design/01-formula-grammar.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/34-validation-debt-register.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-animal-known-relatedness-roadmap.md`
- `man/gr.Rd`

## What Changed

- Renamed the Phase 5 heading to "Phylogenetic, Spatial, and
  Known-Relatedness Dependence".
- Added planned syntax rows for:
  - `phylo(1 | species, A = A)` and `phylo(1 | species, Ainv = Ainv)`;
  - `animal(1 | id, pedigree = ped)`;
  - `animal(1 | id, A = A)` and `animal(1 | id, Ainv = Ainv)`;
  - possible lower-level `relmat(1 | id, K = K)` or `relmat(1 | id, Q = Q)`.
- Updated the common-math design note so the shared structured-effect template
  covers phylogenetic, spatial, animal-model, and user-supplied relatedness
  sources.
- Added a validation-debt row and section for animal-model and user-supplied
  relatedness effects.
- Added a known-limitations entry stating that `animal()` and `relmat()` are
  not implemented and remain distinct from `meta_V(..., V = V)`.
- Updated `gr()` documentation to say it is an older reserved marker, while
  `relmat()` is the clearer lower-level candidate if the project exposes a
  user-supplied relatedness route.
- Updated the meta-analysis design wording in the touched docs so
  `meta_V(V = V)` is the preferred roadmap spelling, while the current
  implemented marker remains `meta_known_V(V = V)` until an alias/rename slice.

## Validation

- `air format R/formula-markers.R ROADMAP.md docs/design/01-formula-grammar.md docs/design/16-phylo-spatial-common-math.md docs/design/34-validation-debt-register.md docs/dev-log/known-limitations.md docs/dev-log/after-task/2026-05-17-animal-known-relatedness-roadmap.md`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated `man/gr.Rd`.
- `Rscript -e "devtools::test(filter = 'package-skeleton|meta-known-v', reporter = 'summary')"`:
  passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `rg -n 'animal.*Implemented|Implemented.*animal|relmat.*Implemented|Implemented.*relmat|animal.*is implemented|relmat.*is implemented|meta_V\(V = V\).*Implemented|Implemented.*meta_V\(V = V\)' ... || true`:
  returned only the intentional line saying top-level weights are implemented
  while `meta_V(V = V)` is a preferred replacement design.
- `git diff --check`: passed.

## Remaining Risks

- The exact public alias set still needs a parser design decision before
  implementation. `A`/`Ainv` are the recommended first names; `vcv` and `corr`
  should only become aliases if their scale semantics are explicit.
- Pedigree-to-precision conversion needs either a small internal helper with
  comparator tests or an optional helper package; this slice intentionally did
  not choose an implementation dependency.
- Phase 18 simulations should include this lane only after fitted code,
  extractor labels, diagnostics, and recovery tests exist.
