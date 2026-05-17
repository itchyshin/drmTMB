# Pre-Phase-18 Slice Map

## Goal

Make the remaining pre-Phase-18 path visible after Slice 177, especially the
non-Gaussian gate from Slices 190-202 and the return to Phase 17 before
comprehensive simulations.

## Outcome

The roadmap now states that Phase 18 does not begin immediately after Slice
202. The path is:

```text
Slices 177-188 random-effect capacity gate
Slice 189 Gaussian double-hierarchical boundary wording
Slices 190-202 non-Gaussian gate
return to Phase 17 visualization and reader-facing inference closure
Phase 18 comprehensive simulation
```

The new Slices 190-202 table separates non-Gaussian `mu` random effects,
non-Gaussian scale, shape/skew parameters, zero-inflation and hurdle random
effects, ordinal mixed models, structured non-Gaussian random effects,
interval readiness, reader-facing docs, recovery tests, failure-ledger work,
and the final pre-simulation decision gate.

## Files Changed

- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-pre-phase18-slice-map.md`

## Validation

- `air format ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-pre-phase18-slice-map.md`:
  passed.
- `rg -n 'Slices 190-202|Pre-simulation decision gate|After Slice 202|Phase 18 comprehensive simulation starts only after' ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-pre-phase18-slice-map.md`:
  confirmed the roadmap and report carry the intended gate wording.
- `rg -n 'After Slice 202.*Phase 18|Phase 18 comprehensive simulation starts immediately|return to Phase 18 at Slice 203' ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes README.md NEWS.md --glob '!docs/dev-log/check-log.md' --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/after-phase/**' || true`:
  returned no direct-jump wording.
- `git diff --check`: passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with "No problems found."

## Team Notes

- Ada kept this as a roadmap-only clarification, not an implementation slice.
- Fisher kept the comprehensive-simulation entry gate tied to fitted surfaces
  and recovery evidence.
- Pat and Darwin get a clearer reader path: first know which models are fitted,
  then visualize and interpret them, then simulate broadly.
- Grace kept validation lightweight because no code or roxygen topics changed.
- Rose checked the common failure mode: jumping from Slice 202 directly into
  Phase 18 without the resumed Phase 17 visualization/inference closure.

## Next Action

Resume Slice 178 planning for ordinary q > 2 Gaussian `mu` random-slope blocks.
