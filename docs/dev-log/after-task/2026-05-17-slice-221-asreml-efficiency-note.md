# Slice 221 ASReml Efficiency Note

## Goal

Record design-level ASReml efficiency lessons for future `animal()` and
`relmat()` work without copying proprietary implementation code.

## What Changed

- Added `docs/design/42-asreml-efficiency-lessons.md`.
- Recorded lessons from the local ASReml-R archive metadata and public help
  topics, especially `ainverse`, `knownStruc`, and model constructors.
- Clarified that future `animal()` speed work should prioritize sparse
  precision matrices, row-name matching, matrix-orientation metadata, and
  honest ASReml comparisons.
- Updated `ROADMAP.md` and `NEWS.md`.

## Checks

- `air format docs/design/42-asreml-efficiency-lessons.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-221-asreml-efficiency-note.md`
- `git diff --check`

## Limitations

This is a design note only. It does not add `animal()` fitting, sparse
precision support, pedigree conversion, scaling benchmarks, or ASReml
comparators.

## Standing Roles

Jason scouted the ASReml archive at the documentation/interface level. Gauss
and Noether kept the lesson focused on covariance versus precision contracts.
Darwin kept the biological `animal()` surface visible. Grace watched dependency
and licensing risk. Rose kept the speed claim honest.
