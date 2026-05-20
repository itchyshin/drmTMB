# After-Task Report: Slices 529-538 Example Promise Audit

## Active Perspectives

Ada audited the example promises. Pat checked whether a new user would mistake
planned syntax for runnable syntax. Darwin watched the biological-example
question, especially for future animal models. Rose recorded the status split
so the promise does not drift.

## Goal

Recheck the older requests for animal-model examples and Student-t or skewed
normal examples, then record what is already present versus what must remain
planned.

## Findings

- Student-t already has a worked tutorial in `vignettes/robust-student.Rmd`,
  including model equation, simulated seedling example, `check_drm()`,
  coefficient interpretation, and Gaussian comparison.
- Skew-normal and skew-t are not fitted families. The current docs correctly
  present skew-normal syntax as planned only, with recovery and identifiability
  gates before implementation.
- `animal()` has planned marker examples in the reference page and model-map
  material. There is no fitted animal-model example yet because the animal
  likelihood, diagnostics, profile targets, recovery tests, and biological
  example are not implemented.

## Changes Made

- Added a status section to
  `docs/design/37-worked-example-inventory.md` for animal, Student-t, and skew
  example promises.

## Checks Run

```sh
rg -n "animal\\(|relmat\\(|Student|student|skew|skew-normal|skewed|shape" README.md ROADMAP.md NEWS.md vignettes docs/design R man _pkgdown.yml
air format docs/design/37-worked-example-inventory.md
```

## Known Limitations

This was an inventory and promise-control slice, not a new fitted example. It
deliberately avoids adding a runnable animal or skew-normal tutorial before the
model code exists.

## Next Actions

When animal models are implemented, add a real biological example with
diagnostics and profile targets. When skew-normal is implemented, extend the
robust continuous-response tutorial from Student-t sensitivity to skewness
recovery rather than presenting design syntax as runnable analysis.
